//========
//Anti redundancy class.
//Handles logic for zeds.
//========
class PawnHelper extends Object;

//Burn affliction data
struct BurnAfflictionData
{
	var float BurnPrimaryModifier;
	var float BurnSecondaryModifier;
	var float BurnDuration;
	var float BurnRatio;
	var int Priority;
};

//Master container for all afflictions.
struct AfflictionData
{
	var BurnAfflictionData Burn;
	var float HarpoonModifier;
};

//Meant to score burn priorities.
struct AfflictionBurnPriorityData
{
	var class<KFWeaponDamageType> DamageType;
	var BurnAfflictionData Burn;
};

const PrimarySpeedReduction = 0.8f;
const SecondarySpeedReduction = 0.3f;
const HarpoonSpeedReduction = 0.75f;

var array<AfflictionBurnPriorityData> FirePriorityList;

static final function ZombieCrispUp(KFMonster KFM)
{
	KFM.bAshen = true;
	KFM.bCrispified = true;

	KFM.SetBurningBehavior();

	if ( KFM.Level.NetMode == NM_DedicatedServer || class'GameInfo'.static.UseLowGore() )
	{
		Return;
	}

	KFM.Skins[0]=Combiner'PatchTex.Common.BurnSkinEmbers_cmb';
	KFM.Skins[1]=Combiner'PatchTex.Common.BurnSkinEmbers_cmb';
	KFM.Skins[2]=Combiner'PatchTex.Common.BurnSkinEmbers_cmb';
	KFM.Skins[3]=Combiner'PatchTex.Common.BurnSkinEmbers_cmb';
}

static final function SetBurningBehavior(KFMonster KFM, AfflictionData AD)
{
	if(KFM == None)
	{
		return;
	}

	if(KFM.bHarpoonStunned)
	{
		SetHarpoonedBehaviour(KFM, AD);
		return;
	}

	if(KFM.Role == Role_Authority)
	{
		KFM.SetGroundSpeed(KFM.GetOriginalGroundSpeed());
		KFM.AirSpeed = KFM.default.AirSpeed * static.GetSpeedModifier(KFM, AD);
		KFM.WaterSpeed = KFM.default.WaterSpeed * static.GetSpeedModifier(KFM, AD);

		if( KFM.Controller != none )
		{
			MonsterController(KFM.Controller).Accuracy = -20;
		}
	}
}

static final function SetHarpoonedBehaviour(KFMonster KFM, AfflictionData AD)
{
	if(KFM == None)
	{
		return;
	}

	if(KFM.Role == Role_Authority)
	{
		KFM.Intelligence = BRAINS_Retarded;

		KFM.SetGroundSpeed(KFM.GetOriginalGroundSpeed());
		KFM.AirSpeed = KFM.default.AirSpeed * static.GetSpeedModifier(KFM, AD);
		KFM.WaterSpeed = KFM.default.WaterSpeed * static.GetSpeedModifier(KFM, AD);

		if( KFM.Controller != none )
		{
		   MonsterController(KFM.Controller).Accuracy = -20;
		}
	}

	KFM.MovementAnims[0] = KFM.BurningWalkFAnims[Rand(3)];
	KFM.WalkAnims[0] = KFM.BurningWalkFAnims[Rand(3)];

	KFM.MovementAnims[1] = KFM.BurningWalkAnims[0];
	KFM.WalkAnims[1] = KFM.BurningWalkAnims[0];
	KFM.MovementAnims[2] = KFM.BurningWalkAnims[1];
	KFM.WalkAnims[2] = KFM.BurningWalkAnims[1];
	KFM.MovementAnims[3] = KFM.BurningWalkAnims[2];
	KFM.WalkAnims[3] = KFM.BurningWalkAnims[2];
}

static final function UnSetBurningBehavior(KFMonster KFM, AfflictionData AD)
{
	if(KFM == None)
	{
		return;
	}

    if(!KFM.bHarpoonStunned)
    {
    	UnSetHarpoonedBehaviour(KFM, AD);
        return;
    }

	if (KFM.Role == Role_Authority )
	{
		if( !KFM.bZapped )
		{
    		KFM.SetGroundSpeed(KFM.GetOriginalGroundSpeed());
    		KFM.AirSpeed = KFM.default.AirSpeed * static.GetSpeedModifier(KFM, AD);
    		KFM.WaterSpeed = KFM.default.WaterSpeed * static.GetSpeedModifier(KFM, AD);
        }

		if ( KFM.Controller != none )
		{
		   MonsterController(KFM.Controller).Accuracy = MonsterController(KFM.Controller).default.Accuracy;
		}
	}

	KFM.bAshen = False;
}

static final function UnSetHarpoonedBehaviour(KFMonster KFM, AfflictionData AD)
{
	local int i;

	if (KFM.Role == Role_Authority )
	{
		KFM.Intelligence = KFM.default.Intelligence;

		if( !KFM.bZapped )
		{
    		KFM.SetGroundSpeed(KFM.GetOriginalGroundSpeed());
    		KFM.AirSpeed = KFM.default.AirSpeed * static.GetSpeedModifier(KFM, AD);
    		KFM.WaterSpeed = KFM.default.WaterSpeed * static.GetSpeedModifier(KFM, AD);
        }

		if ( KFM.Controller != none )
		{
		   MonsterController(KFM.Controller).Accuracy = MonsterController(KFM.Controller).default.Accuracy;
		}
	}

	for ( i = 0; i < 4; i++ )
	{
		KFM.MovementAnims[i] = KFM.default.MovementAnims[i];
		KFM.WalkAnims[i] = KFM.default.WalkAnims[i];
	}

	KFM.bAshen = False;
}

static final function bool UpdateStunProperties(KFMonster KFM, float LastStunCount, out float UnstunTime, bool bUnstunTimeReady)
{
	if (LastStunCount == KFM.StunsRemaining)
	{
		return bUnstunTimeReady;
	}

	UnstunTime = KFM.Level.TimeSeconds + KFM.StunTime;
	bUnstunTimeReady = true;

	if (KFM.BurnDown <= 0)
	{
		//Don't uncomment this - is responsible for flinch slow raging.
		//KFM.SetTimer(-1.f, false);
	}
	else
	{
		//Need to avoid a case where SetTimer() resets itself instead of just starting a new timer.
		if ((1.f - KFM.TimerCounter) < 0.0001f)
		{
			KFM.Timer();
		}
		else
		{
			//AActor::TimerCounter is the amount of time that the current timer has elapsed.
			KFM.SetTimer(1.f - KFM.TimerCounter, false); //burn timer is not a var and always 1 second.
		}
	}

	return bUnstunTimeReady;
}

static final function bool ShouldPlayDirectionalHit(KFMonster KFM)
{
	return !static.IsFireDamageType(KFM.LastDamagedByType);
}

static final function bool IsFireDamageType(class<DamageType> DT)
{
	return ClassIsChildOf(DT, class'DamTypeBurned')
		|| DT == class'DamTypeTrenchgun' || DT == class'DamTypeMAC10MPInc'
		|| DT == class'DamTypeFlamethrower' || DT == class'DamTypeHuskGunProjectileImpact';
}

static final function float GetOriginalGroundSpeed(KFMonster KFM, AfflictionData AD)
{
	return KFM.OriginalGroundSpeed * GetSpeedModifier(KFM, AD);
}

static final function float GetSpeedModifier(KFMonster KFM, AfflictionData AD)
{
	local float Multiplier;
	Multiplier = 1.f;

	if(KFM.bHarpoonStunned)
	{
		Multiplier *= static.GetHarpoonSpeedMultiplier(AD);
	}

	if( KFM.bBurnified && ShouldApplyBurn(AD))
	{
		Multiplier *= static.GetBurnSpeedMultiplier(AD);
	}

	return Multiplier;
}

static final function TakeDamage(int Damage, Pawn InstigatedBy, Vector HitLocation, Vector Momentum, class<DamageType> DamageType, int HitIndex, out AfflictionData AD)
{
	UpdateBurnData(DamageType, AD);
}

static final function UpdateBurnData(class<DamageType> DamageType, out AfflictionData AD)
{
	local int Index;

	if (AD.Burn.Priority == 0)
	{
		return;
	}

	for (Index = 0; Index < default.FirePriorityList.Length; Index++)
	{
		if (default.FirePriorityList[Index].DamageType != DamageType)
		{
			continue;
		}

		if (default.FirePriorityList[Index].Burn.Priority >= AD.Burn.Priority)
		{
			break;
		}

		AD.Burn.BurnPrimaryModifier = default.FirePriorityList[Index].Burn.BurnPrimaryModifier;
		AD.Burn.BurnSecondaryModifier = default.FirePriorityList[Index].Burn.BurnSecondaryModifier;
		AD.Burn.BurnDuration = default.FirePriorityList[Index].Burn.BurnDuration;
		AD.Burn.Priority = default.FirePriorityList[Index].Burn.Priority;
		AD.Burn.BurnRatio = 0.f;
		break;
	}
}

static final function int GetFakedPlayerAdjustedCount(LevelInfo Level)
{
	local Controller C;
	local int FakedPlayers;
	local int PlayerCount;
	FakedPlayers = 0;
	PlayerCount = 0;

	if(KFProGameType(Level.Game) != None)
	{
		FakedPlayers = KFProGameType(Level.Game).FakedPlayerHealth;
	}

	for( C=Level.ControllerList; C!=None; C=C.NextController )
    {
        if( C.bIsPlayer && C.Pawn!=None && C.Pawn.Health > 0 )
        {
            PlayerCount++;
        }
    }

    if(FakedPlayers > PlayerCount)
    {
    	PlayerCount = FakedPlayers;
    }

	return PlayerCount;
}

static final function float GetBodyHealthModifier(KFMonster KFM, LevelInfo Level)
{
	local int AdjustedPlayerCount;
    local float AdjustedModifier;
	AdjustedPlayerCount = GetFakedPlayerAdjustedCount(Level);
    AdjustedModifier = 1.f;

    if( AdjustedPlayerCount > 1 )
    {
        AdjustedModifier += (AdjustedPlayerCount - 1) * KFM.PlayerCountHealthScale;
    }

    return AdjustedModifier;
}

static final function float GetHeadHealthModifier(KFMonster KFM, LevelInfo Level)
{
	local int AdjustedPlayerCount;
	local float AdjustedModifier;

	AdjustedPlayerCount = GetFakedPlayerAdjustedCount(Level);
    AdjustedModifier = 1.f;

    if( AdjustedPlayerCount > 1 )
    {
        AdjustedModifier += (AdjustedPlayerCount - 1) * KFM.PlayerNumHeadHealthScale;
    }

    return AdjustedModifier;
}

static final function TickAfflictionData(float DeltaTime, KFMonster KFM, out AfflictionData AD)
{
    if(KFM.bBurnified && AD.Burn.BurnRatio < 1.f)
    {
        AD.Burn.BurnRatio += (DeltaTime / AD.Burn.BurnDuration);
    }
}

static final function bool ShouldApplyBurn(AfflictionData AD)
{
	return AD.Burn.BurnRatio < 1.f;
}

static final function float GetBurnSpeedMultiplier(AfflictionData AD)
{
	return Lerp(AD.Burn.BurnRatio, AD.Burn.BurnPrimaryModifier, AD.Burn.BurnSecondaryModifier, true);
}

static final function float GetHarpoonSpeedMultiplier(AfflictionData AD)
{
	return 1.f - AD.HarpoonModifier;
}

static final function float GetBurnPrimaryModifier(AfflictionData AD)
{
	return AD.Burn.BurnPrimaryModifier;
}

static final function float GetBurnSecondaryModifier(AfflictionData AD)
{
	return AD.Burn.BurnSecondaryModifier;
}

static final function float GetBurnDuration(AfflictionData AD)
{
	return AD.Burn.BurnDuration;
}

static final function float GetBurnRatio(AfflictionData AD)
{
	return AD.Burn.BurnRatio;
}

static final function float GetHarpoonModifier(AfflictionData AD)
{
	return AD.HarpoonModifier;
}

//NOTE: No special destroy code is needed. EZCollision is already destroyed on any zed that has it (not role-dependent).
static final function SpawnClientExtendedZCollision(KFMonster KFM)
{
	local vector AttachPos;

	//Auth has already created this hitbox.
	if(KFM.Role == ROLE_Authority)
	{
		return;
	}

	if (KFM.bUseExtendedCollision && KFM.MyExtCollision == none )
	{
		KFM.MyExtCollision = KFM.Spawn(class'ClientExtendedZCollision', KFM);
		//Slightly smaller version for non auth clients
		KFM.MyExtCollision.SetCollisionSize(KFM.ColRadius * 0.9f, KFM.ColHeight * 0.9f);

		KFM.MyExtCollision.bHardAttach = true;

		AttachPos = KFM.Location + (KFM.ColOffset >> KFM.Rotation);
		
		KFM.MyExtCollision.SetLocation(AttachPos);
		KFM.MyExtCollision.SetPhysics(PHYS_None);
		KFM.MyExtCollision.SetBase(KFM);
		KFM.SavedExtCollision = KFM.MyExtCollision.bCollideActors;
	}
}

static final function DisablePawnCollision(Pawn P)
{
	P.bBlockActors = false;
	P.bBlockPlayers = false;
	P.bBlockProjectiles = false;
	P.bProjTarget = false;
	P.bBlockZeroExtentTraces = false;
	P.bBlockNonZeroExtentTraces = false;
	P.bBlockHitPointTraces = false;
}

defaultproperties
{
     FirePriorityList(0)=(DamageType=Class'KFMod.DamTypeHuskGun',Burn=(BurnPrimaryModifier=0.250000,BurnSecondaryModifier=0.500000,BurnDuration=6.000000))
     FirePriorityList(1)=(DamageType=Class'KFMod.DamTypeTrenchgun',Burn=(BurnPrimaryModifier=0.300000,BurnSecondaryModifier=0.600000,BurnDuration=5.500000,Priority=1))
     FirePriorityList(2)=(DamageType=Class'KFMod.DamTypeFlareRevolver',Burn=(BurnPrimaryModifier=0.800000,BurnSecondaryModifier=0.900000,BurnDuration=4.500000,Priority=2))
     FirePriorityList(3)=(DamageType=Class'KFMod.DamTypeMAC10MPInc',Burn=(BurnPrimaryModifier=0.850000,BurnSecondaryModifier=0.950000,BurnDuration=4.250000,Priority=3))
     FirePriorityList(4)=(DamageType=Class'KFMod.DamTypeFlamethrower',Burn=(BurnPrimaryModifier=0.900000,BurnSecondaryModifier=1.000000,BurnDuration=4.000000,Priority=4))
     FirePriorityList(5)=(DamageType=Class'KFMod.DamTypeBurned',Burn=(BurnPrimaryModifier=0.900000,BurnSecondaryModifier=1.000000,BurnDuration=4.000000,Priority=5))
}

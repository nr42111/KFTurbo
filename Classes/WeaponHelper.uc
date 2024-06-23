//========
//Anti redundancy class.
//Handles logic for weapons.
//========
class WeaponHelper extends Object;


enum ETraceResult
{
	TR_Block,
	TR_Hit,
	TR_None
};

static final function PenetratingWeaponTrace(Vector TraceStart, KFWeapon Weapon, KFFire Fire, int PenetrationMax, float PenetrationMultiplier)
{
	local Actor HitActor;
	local array<Actor> IgnoreActors;
	local Vector TraceEnd, MomentumVector;
	local Vector HitLocation;
	local int HitCount;
	HitCount = 0;
	PenetrationMax++;

	GetTraceInfo(Weapon, Fire, TraceStart, TraceEnd, MomentumVector);

	while(HitCount < PenetrationMax)
	{
		switch(WeaponTrace(TraceStart, TraceEnd, MomentumVector, Weapon, Fire, HitActor, HitLocation, (PenetrationMultiplier * float(HitCount))))
		{
		case TR_Block:
			HitCount = PenetrationMax + 1;
			EnableCollision(IgnoreActors);
			return;
		case TR_Hit:
		case TR_None:
			HitCount++;
			break;
		}

		if(HitActor != None)
		{
			if(ExtendedZCollision(HitActor) != None && HitActor.Owner != None)
			{
				HitActor.Owner.SetCollision(false);
				IgnoreActors[IgnoreActors.Length] = HitActor.Owner;
			}

			if(KFMonster(HitActor) != None && KFMonster(HitActor).MyExtCollision != None)
			{
				KFMonster(HitActor).MyExtCollision.SetCollision(false);
				IgnoreActors[IgnoreActors.Length] = KFMonster(HitActor).MyExtCollision;				
			}

			HitActor.SetCollision(false);
			IgnoreActors[IgnoreActors.Length] = HitActor;
		}

		TraceStart = HitLocation;

		if(VSize(TraceStart - TraceEnd) < 0.1)
		{
			break;
		}
	}

	EnableCollision(IgnoreActors);
}

static final function ETraceResult WeaponTrace(Vector TraceStart, Vector TraceEnd, Vector MomentumVector, KFWeapon Weapon, KFFire Fire, out Actor HitActor, out Vector HitLocation, optional float DamageReduction)
{
	local KFPawn HitPawn;
	local Vector HitNormal;
	local array<int> HitPoints;

/*	out vector      HitLocation,
	out vector      HitNormal,
	vector          TraceEnd,
	out array<int>  HitPoints,
	optional vector TraceStart,
	optional vector Extent,
	optional int WhizType,
	optional out material Material*/

	HitActor = Fire.Instigator.HitPointTrace(HitLocation, HitNormal, TraceEnd, HitPoints, TraceStart, vect(0,0,0), 1);

	//One Minus the value to get the actual multiplier.
	DamageReduction = 1.0 - DamageReduction;

	if(ShouldSkipActor(HitActor, Fire.Instigator))
	{
		return TR_None;
	}

	if(IsWorldHit(HitActor))
	{
		if(KFWeaponAttachment(Weapon.ThirdPersonActor) != None)
		{
			KFWeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(HitActor, HitLocation, HitNormal);		
		}

		return TR_Block;
	}

	HitPawn = KFPawn(HitActor);

	if ( HitPawn != none )
	{
		if(!HitPawn.bDeleteMe)
		{
			HitPawn.ProcessLocationalDamage(int(Fire.DamageMax * DamageReduction), Fire.Instigator, HitLocation, MomentumVector, Fire.DamageType, HitPoints);
		}
	}
    else
    {
		HitActor.TakeDamage(int(Fire.DamageMax * DamageReduction), Fire.Instigator, HitLocation, MomentumVector, Fire.DamageType);
	}

	return TR_Hit;
}

//Gets the trace endpoint and momentum vector given a Weapon and KFFire.
static final function GetTraceInfo(Weapon Weapon, KFFire Fire, Vector Start, out Vector TraceEnd, out Vector Momentum)
{
	local Vector X, Y, Z;
	Weapon.GetViewAxes(X, Y, Z);

	Fire.MaxRange();

	TraceEnd = Start + Fire.TraceRange * X;
	Momentum = Fire.Momentum * X;
}

//Returns true if this actor is a world object.
static final function bool IsWorldHit(Actor Other)
{
	if(Other == None)
	{
		return false;
	}

	return Other.bWorldGeometry || Other == Other.Level;
}

static final function bool ShouldSkipActor(Actor Other, Pawn Instigator)
{
	return Other == None || Other == Instigator || Other.Base == Instigator; 
}

static final function EnableCollision(Array<Actor> IgnoreList)
{
	local int i;

	for (i = 0; i < IgnoreList.Length; i++)
	{
		if(IgnoreList[i] != None)
		{
      		IgnoreList[i].SetCollision(true);
		}
	}
}

static final function NotifyPostProjectileSpawned(Projectile SpawnedProjectile)
{
	if (SpawnedProjectile == None || SpawnedProjectile.Role != ROLE_Authority)
	{
		return;
	}

	if (SpawnedProjectile.Instigator == None || SpawnedProjectile.Instigator.Weapon == None)
	{
		return;
	}

	if (BaseProjectileFire(SpawnedProjectile.Instigator.Weapon.GetFireMode(0)) == None)
	{
		return;
	}

	BaseProjectileFire(SpawnedProjectile.Instigator.Weapon.GetFireMode(0)).PostSpawnProjectile(SpawnedProjectile);
}

static final function bool AlreadyHitPawn(out Actor HitActor, out array<Pawn> HitPawnList)
{
	local int Index;
	local Pawn Pawn;

	if (Pawn(HitActor.Base) != None)
	{
		HitActor = HitActor.Base;
	}

	Pawn = Pawn(HitActor);

	if (Pawn == None)
	{
		return false;
	}

	for (Index = 0; Index < HitPawnList.Length; Index++)
	{
		if (Pawn == HitPawnList[Index])
		{
			return true;
		}
	}

	HitPawnList[HitPawnList.Length] = Pawn;
	return false;
}

static final function float GetMedicGunChargeBar(KFMedicGun Weapon)
{
	return FClamp(float(Weapon.HealAmmoCharge) / float(Weapon.default.HealAmmoCharge), 0, 1);
}

static final function TickMedicGunRecharge(KFMedicGun Weapon, float DeltaTime, out float HealAmmoAmount)
{
	local float RegenAmount;

	if (Weapon.Role != ROLE_Authority)
	{
		return;
	}

	if (HealAmmoAmount >= float(Weapon.default.HealAmmoCharge))
	{
		return;
	}

	RegenAmount = 10.f;

	if (GetVeterancyFromWeapon(Weapon) != None)
	{
		RegenAmount *= GetVeterancyFromWeapon(Weapon).Static.GetSyringeChargeRate(KFPlayerReplicationInfo(Weapon.Instigator.PlayerReplicationInfo));
	}

	HealAmmoAmount += (RegenAmount * DeltaTime) / Weapon.AmmoRegenRate;
}

static final function bool ConsumeMedicGunAmmo(KFMedicGun Weapon, int Mode, float Amount, out float HealAmmoAmount, out byte Status)
{
	if (Mode == 1)
	{
		Status = 0;

		if (Amount > HealAmmoAmount)
		{
			Status = 1;
		}

		HealAmmoAmount -= Amount;
		return true;
	}

	return false;
}

static final function class<KFVeterancyTypes> GetVeterancyFromWeapon(Weapon Weapon)
{
	if (Weapon == None || Weapon.Instigator == None || KFPlayerReplicationInfo(Weapon.Instigator.PlayerReplicationInfo) == None)
	{
		return None;
	}

	return KFPlayerReplicationInfo(Weapon.Instigator.PlayerReplicationInfo).ClientVeteranSkill;
}

defaultproperties
{
}

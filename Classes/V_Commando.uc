class V_Commando extends SRVetCommando
	abstract;


static function AddCustomStats(ClientPerkRepLink Other)
{
	Super.AddCustomStats(Other);

	Other.AddCustomValue(class'VP_BullpupDamage');
}

static function int GetPerkProgressInt(ClientPerkRepLink StatOther, out int FinalInt, byte CurLevel, byte ReqNum)
{
	switch (CurLevel)
	{
	case 0:
		FinalInt = 10000;
		break;
	case 1:
		FinalInt = 25000;
		break;
	case 2:
		FinalInt = 100000;
		break;
	case 3:
		FinalInt = 500000;
		break;
	case 4:
		FinalInt = 1500000;
		break;
	case 5:
		FinalInt = 3500000;
		break;
	case 6:
		FinalInt = 5500000;
		break;
	default:
		FinalInt = 5500000 + GetScaledRequirement(CurLevel - 5, 500000);
	}

	return Min(StatOther.RBullpupDamageStat + StatOther.GetCustomValueInt(class'VP_BullpupDamage'), FinalInt);
}

static function SpecialHUDInfo(KFPlayerReplicationInfo KFPRI, Canvas C)
{
	local KFMonster KFEnemy;
	local HUDKillingFloor HKF;
	local Pawn P;

	if (KFPRI.ClientVeteranSkillLevel > 0)
	{
		HKF = HUDKillingFloor(C.ViewPort.Actor.myHUD);
		P = Pawn(C.ViewPort.Actor.ViewTarget);
		if (HKF == none || P == none || P.Health <= 0)
			return;

		foreach P.CollidingActors(class'KFMonster', KFEnemy, LerpStat(KFPRI, 0.f, 800.f))
		{
			if (KFEnemy.Health > 0 && (!KFEnemy.Cloaked() || KFEnemy.bZapped || KFEnemy.bSpotted))
				HKF.DrawHealthBar(C, KFEnemy, KFEnemy.Health, KFEnemy.HealthMax, 50.0);
		}
	}
}

static function bool ShowStalkers(KFPlayerReplicationInfo KFPRI)
{
	return Super.ShowStalkers(KFPRI);
}

static function float GetStalkerViewDistanceMulti(KFPlayerReplicationInfo KFPRI)
{
	return LerpStat(KFPRI, 0.0625f, 1.f);
}

//GetMagCapacityMod
static function float GetMagCapacityMod(KFPlayerReplicationInfo KFPRI, KFWeapon Other)
{
	local float Multiplier;

	Multiplier = 1.f;

	if (Bullpup(Other) != none || AK47AssaultRifle(Other) != none ||
		SCARMK17AssaultRifle(Other) != none || M4AssaultRifle(Other) != none
		|| FNFAL_ACOG_AssaultRifle(Other) != none || MKb42AssaultRifle(Other) != none
		|| ThompsonSMG(Other) != none || ThompsonDrumSMG(Other) != none
		|| SPThompsonSMG(Other) != none)
	{
		Multiplier = LerpStat(KFPRI, 1.f, 1.25f);
	}

	if (W_FNFAL_Weap(Other) != None)
	{
		Multiplier = LerpStat(KFPRI, 1.f, 1.2f);
	}

	GetAdjustedMagCapacityModifier(KFPRI, Other, Multiplier);

	return Multiplier;
}

static function GetAdjustedMagCapacityModifier(KFPlayerReplicationInfo KFPRI, KFWeapon Other, out float Multiplier)
{
	if (!IsHighDifficulty(KFPRI))
	{
		return;
	}

	if(SCARMK17AssaultRifle(Other) != None)
	{
		Multiplier *= 1.2f;
	}
	else if(Multiplier > 1.f)
	{
		Multiplier *= 1.25f;
	}
}

static function float GetAmmoPickupMod(KFPlayerReplicationInfo KFPRI, KFAmmunition Other)
{
	local float Multiplier;

	Multiplier = 1.f;

	if ((BullpupAmmo(Other) != none || AK47Ammo(Other) != none ||
		SCARMK17Ammo(Other) != none || M4Ammo(Other) != none
		|| FNFALAmmo(Other) != none || MKb42Ammo(Other) != none
		|| ThompsonAmmo(Other) != none || GoldenAK47Ammo(Other) != none
		|| ThompsonDrumAmmo(Other) != none || SPThompsonAmmo(Other) != none
		|| CamoM4Ammo(Other) != none || NeonAK47Ammo(Other) != none) &&
		KFPRI.ClientVeteranSkillLevel > 0)
	{
		Multiplier = LerpStat(KFPRI, 1.f, 1.25f);
	}

	if (FNFALAmmo(Other) != None)
	{
		Multiplier = LerpStat(KFPRI, 1.f, 1.2f);
	}

	GetAdjustedAmmoPickupMod(KFPRI, Other, Multiplier);

	return Multiplier;
}

static function GetAdjustedAmmoPickupMod(KFPlayerReplicationInfo KFPRI, KFAmmunition Other, out float Multiplier)
{
	if (!IsHighDifficulty(KFPRI))
	{
		return;
	}

	if(Multiplier > 1.f)
	{
		Multiplier *= 1.5f;
	}
}

static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, class<Ammunition> AmmoType)
{
	local float Multiplier;

	Multiplier = 1.f;

	switch (AmmoType)
	{
	case class'BullpupAmmo' :
	case class'SCARMK17Ammo' :

	case class'W_AK47_Ammo' :
	case class'W_ThompsonDrum_Ammo' :
	case class'W_M4203_Ammo_Bullet' :
	case class'W_FNFAL_Ammo' :

		Multiplier = LerpStat(KFPRI, 1.f, 1.25f);
		break;
	}

	AddAdjustedExtraAmmoFor(KFPRI, AmmoType, Multiplier);

	return Multiplier;
}

static function AddAdjustedExtraAmmoFor(KFPlayerReplicationInfo KFPRI, class<Ammunition> AmmoType, out float Multiplier)
{
	if (!IsHighDifficulty(KFPRI))
	{
		return;
	}

	if(Multiplier > 1.f)
	{
		Multiplier *= 1.5f;
	}
	else if(AmmoType == class'FragAmmo')
	{
		Multiplier *= LerpStat(KFPRI, 1.f, 1.6f);
	}
}

static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn Instigator, int InDamage, class<DamageType> DmgType)
{
	switch (DmgType)
	{
	case class'DamTypeBullpup' :
	case class'DamTypeAK47AssaultRifle' :
	case class'DamTypeSCARMK17AssaultRifle' :
	case class'DamTypeAK47AssaultRifle' :
	case class'DamTypeM4AssaultRifle' :

	case class'W_M4203_DT_Bullet' :
	case class'W_FNFAL_DT' :
	case class'W_ThompsonDrum_DT' :
		return float(InDamage) * LerpStat(KFPRI, 1.05f, 1.5f);
	case class'W_MAC10_DT' :
		return float(InDamage) * LerpStat(KFPRI, 1.05f, 1.15f);
	}

	return InDamage;
}

static function float ModifyRecoilSpread(KFPlayerReplicationInfo KFPRI, WeaponFire Other, out float Recoil)
{
	if (Bullpup(Other.Weapon) != none || AK47AssaultRifle(Other.Weapon) != none ||
		SCARMK17AssaultRifle(Other.Weapon) != none || M4AssaultRifle(Other.Weapon) != none
		|| FNFAL_ACOG_AssaultRifle(Other.Weapon) != none || MKb42AssaultRifle(Other.Weapon) != none
		|| ThompsonSMG(Other.Weapon) != none || ThompsonDrumSMG(Other.Weapon) != none
		|| SPThompsonSMG(Other.Weapon) != none || MAC10MP(Other.Weapon) != none)
	{
		Recoil = LerpStat(KFPRI, 0.95f, 0.6f);
		return Recoil;
	}

	Recoil = 1.f;
	return Recoil;
	//wtf is this syntax (by ref and return???)
}

static function float GetReloadSpeedModifier(KFPlayerReplicationInfo KFPRI, KFWeapon Other)
{
	return LerpStat(KFPRI, 1.05f, 1.35f);
}

static function int ZedTimeExtensions(KFPlayerReplicationInfo KFPRI)
{
	return LerpStat(KFPRI, 0, 4);
}

static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
	switch (Item)
	{
	case class 'BullpupPickup':

	case class'W_AK47_Pickup' :
	case class'W_M4203_Pickup' :
	case class'W_ThompsonDrum_Pickup':
	case class'W_FNFAL_Pickup' :
	case class'W_SCARMK17_Pickup' :
		return LerpStat(KFPRI, 0.9f, 0.3f);
		break;
	default:
		break;
	}

	return 1.f;
}

static function AddDefaultInventory(KFPlayerReplicationInfo KFPRI, Pawn P)
{
	KFHumanPawn(P).CreateInventoryVeterancy(string(class'W_AK47_Weap'), default.StartingWeaponSellPriceLevel6);
}

static function string GetCustomLevelInfo(byte Level)
{
	return default.SRLevelEffects[6];
}

defaultproperties
{
     StartingWeaponSellPriceLevel5=255.000000
     StartingWeaponSellPriceLevel6=255.000000
     OnHUDGoldIcon=Texture'KFTurbo.Perks.Commando_D'
}

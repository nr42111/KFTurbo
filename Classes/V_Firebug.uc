class V_Firebug extends SRVetFirebug
	abstract;

static function AddCustomStats(ClientPerkRepLink Other)
{
	Super.AddCustomStats(Other);

	Other.AddCustomValue(class'VP_FlamethrowerDamage');
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
	return Min(StatOther.RFlameThrowerDamageStat + StatOther.GetCustomValueInt(class'VP_FlamethrowerDamage'), FinalInt);
}

static function float GetMagCapacityMod(KFPlayerReplicationInfo KFPRI, KFWeapon Other) //this definitely does not change mac10 ammo capacity
{
	if (Flamethrower(Other) != None || MAC10MP(Other) != None) //did you mean || isntead of &&?
		return LerpStat(KFPRI, 1.f, 1.6f);
	return 1.0;
}

static function float GetAmmoPickupMod(KFPlayerReplicationInfo KFPRI, KFAmmunition Other)
{
	if ((FlameAmmo(Other) != none || MAC10Ammo(Other) != none || HuskGunAmmo(Other) != none || TrenchgunAmmo(Other) != none || FlareRevolverAmmo(Other) != none) && KFPRI.ClientVeteranSkillLevel > 0)
		return LerpStat(KFPRI, 1.f, 1.6f);
	return 1.0;
}

static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, Class<Ammunition> AmmoType)
{
	if ((AmmoType == class'FlameAmmo' || AmmoType == class'MAC10Ammo' || AmmoType == class'HuskGunAmmo' || AmmoType == class'TrenchgunAmmo' || AmmoType == class'FlareRevolverAmmo' || AmmoType == class'GoldenFlameAmmo') && KFPRI.ClientVeteranSkillLevel > 0)
		return LerpStat(KFPRI, 1.f, 1.6f);
	return 1.0;
}

static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType)
{
	switch (DmgType)
	{
	case class'W_MAC10_DT' :
	case class'DamTypeTrenchgun' :
		return float(InDamage) * Lerp(KFPRI.ClientVeteranSkillLevel, 1.f, 1.15, true);
	}

	if (class<DamTypeBurned>(DmgType) != none || class<DamTypeFlamethrower>(DmgType) != none || class<DamTypeHuskGunProjectileImpact>(DmgType) != none || class<DamTypeFlareProjectileImpact>(DmgType) != none)
	{
		return float(InDamage) * LerpStat(KFPRI, 1.05f, 1.6f);
	}

	return InDamage;
}

static function int ExtraRange(KFPlayerReplicationInfo KFPRI)
{
	switch (KFPRI.ClientVeteranSkillLevel)
	{
	case 0:
	case 1:
	case 2:
		return 0;
	case 3:
	case 4:
		return 1;
	}

	return 2;
}

static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
	if (class<DamTypeBurned>(DmgType) != none || class<DamTypeFlamethrower>(DmgType) != none || class<DamTypeHuskGunProjectileImpact>(DmgType) != none || class<DamTypeFlareProjectileImpact>(DmgType) != none)
	{
		return float(InDamage) * LerpStat(KFPRI, 0.5f, 0.f);
	}

	return InDamage;
}

static function class<Grenade> GetNadeType(KFPlayerReplicationInfo KFPRI)
{
	return Super.GetNadeType(KFPRI);
}

static function float GetReloadSpeedModifier(KFPlayerReplicationInfo KFPRI, KFWeapon Other)
{
	if (Flamethrower(Other) != none || MAC10MP(Other) != none || Trenchgun(Other) != none || FlareRevolver(Other) != none || DualFlareRevolver(Other) != none)
	{
		return LerpStat(KFPRI, 1.f, 1.6f);
	}
	return 1.0;
}

static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
	switch (Item)
	{
	case class'W_FlameThrower_Pick' :
	case class'W_MAC10_Pickup' :
	case class'W_Huskgun_Pickup' :
	case class'W_Trenchgun_Pickup' :
	case class'FlareRevolverPickup' :
	case class'DualFlareRevolverPickup' :
		return LerpStat(KFPRI, 0.9f, 0.3f);
	}

	return 1.0;
}

static function AddDefaultInventory(KFPlayerReplicationInfo KFPRI, Pawn P)
{
		KFHumanPawn(P).CreateInventoryVeterancy(string(class'KFTurbo.W_MAC10_Weap'), default.StartingWeaponSellPriceLevel6);
}

static function class<DamageType> GetMAC10DamageType(KFPlayerReplicationInfo KFPRI)
{
	return class'W_MAC10_DT';
}

static function string GetCustomLevelInfo(byte Level)
{
	return default.SRLevelEffects[6];
}

defaultproperties
{
     StartingWeaponSellPriceLevel5=255.000000
     StartingWeaponSellPriceLevel6=255.000000
     OnHUDGoldIcon=Texture'KFTurbo.Perks.Firebug_D'
}

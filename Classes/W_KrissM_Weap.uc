class W_KrissM_Weap extends KrissMMedicGun;

var float HealAmmoAmount;

simulated function float ChargeBar()
{
	return class'WeaponHelper'.static.GetMedicGunChargeBar(self);
}

simulated function Tick(float dt)
{
	class'WeaponHelper'.static.TickMedicGunRecharge(self, dt, HealAmmoAmount);

	if (Role == ROLE_Authority)
	{
		HealAmmoCharge = HealAmmoAmount;
	}
}

simulated function bool ConsumeAmmo(int Mode, float Load, optional bool bAmountNeededIsMax)
{
	local byte Status;
	if (class'WeaponHelper'.static.ConsumeMedicGunAmmo(self, Mode, Load, HealAmmoAmount, Status))
	{
		HealAmmoCharge = HealAmmoAmount;
		return Status == 0;
	}

	return Super(KFWeapon).ConsumeAmmo(Mode, Load, bAmountNeededIsMax);
}

defaultproperties
{
     HealAmmoAmount=500.000000
     HealBoostAmount=20
     HealAmmoCharge=500
     AmmoRegenRate=0.300000
     Weight=4.000000
     FireModeClass(0)=Class'KFTurbo.W_KrissM_Fire'
     FireModeClass(1)=Class'KFTurbo.W_KrissM_Fire_Alt'
     PickupClass=Class'KFTurbo.W_KrissM_Pickup'
}

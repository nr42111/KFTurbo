class W_MP5M_Weap extends MP5MMedicGun;

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
     HealAmmoAmount=650.000000
     MagCapacity=30
     ReloadRate=3.400000
     ReloadAnimRate=1.118000
     FireModeClass(0)=Class'KFTurbo.W_MP5M_Fire'
     FireModeClass(1)=Class'KFTurbo.W_MP5M_Fire_Alt'
     PickupClass=Class'KFTurbo.W_MP5M_Pickup'
}

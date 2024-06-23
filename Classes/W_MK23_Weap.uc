class W_MK23_Weap extends MK23Pistol;

simulated function bool PutDown()
{
	if ( Instigator.PendingWeapon.class == class'W_DualMK23_Weap' )
	{
		bIsReloading = false;
	}

	return Super(KFWeapon).PutDown();
}

defaultproperties
{
     ReloadRate=2.400000
     ReloadAnimRate=1.090000
     FireModeClass(0)=Class'KFTurbo.W_MK23_Fire'
     PickupClass=Class'KFTurbo.W_MK23_Pickup'
}

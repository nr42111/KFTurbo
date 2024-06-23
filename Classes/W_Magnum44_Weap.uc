class W_Magnum44_Weap extends Magnum44Pistol;


simulated function bool PutDown()
{
	if ( Instigator.PendingWeapon.class == class'W_Dual44_Weap' )
	{
		bIsReloading = false;
	}

	return Super(KFWeapon).PutDown();
}

defaultproperties
{
     ReloadRate=2.500000
     Weight=3.000000
     FireModeClass(0)=Class'KFTurbo.W_Magnum44_Fire'
     PickupClass=Class'KFTurbo.W_Magnum44_Pickup'
}

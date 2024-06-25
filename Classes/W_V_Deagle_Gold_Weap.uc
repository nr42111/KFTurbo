class W_V_Deagle_Gold_Weap extends GoldenDeagle;

function bool HandlePickupQuery(pickup Item)
{
	local int Index;
	local bool bIsSingleVariant;
	local class<KFWeaponPickup> WeaponPickup;

	WeaponPickup = class<KFWeaponPickup>(PickupClass);
	bIsSingleVariant = false;

	for (Index = 0; Index < WeaponPickup.default.VariantClasses.Length; Index++)
	{
		if (WeaponPickup.default.VariantClasses[Index] == default.PickupClass)
		{
			bIsSingleVariant = true;
			break;
		}
	}

	if (bIsSingleVariant)
	{
		if (KFPlayerController(Instigator.Controller) != none)
		{
			KFPlayerController(Instigator.Controller).PendingAmmo = WeaponPickup(Item).AmmoAmount[0];
		}

		return false; // Allow to "pickup" so this weapon can be replaced with dual deagle.
	}

	return Super.HandlePickupQuery(Item);
}

simulated function bool PutDown()
{
	if (DualDeagle(Instigator.PendingWeapon) != None)
	{
		bIsReloading = false;
	}

	return super(KFWeapon).PutDown();
}

defaultproperties
{
     FireModeClass(0)=Class'KFTurbo.W_V_Deagle_Gold_Fire'
     PickupClass=Class'KFTurbo.W_V_Deagle_Gold_Pickup'
}

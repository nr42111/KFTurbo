class KFPGUIBuyable extends GUIBuyable;

var array< class<Pickup> > VariantClasses;
var array< byte > VariantStatus;
var int VariantSelection;

function class<Pickup> GetPickup()
{
	if (VariantSelection == -1 || VariantClasses.Length <= VariantSelection)
	{
		return ItemPickupClass;
	}

	return VariantClasses[VariantSelection];
}

function class<KFWeapon> GetWeapon()
{
	if (GetPickup() == None || class<KFWeapon>(GetPickup().default.InventoryType) == None)
	{
		return ItemWeaponClass;
	}

	return class<KFWeapon>(GetPickup().default.InventoryType);
}

defaultproperties
{
     VariantSelection=-1
}

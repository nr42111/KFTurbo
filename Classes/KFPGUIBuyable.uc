class KFPGUIBuyable extends GUIBuyable;

var array<KFTurboRepLinkSettings.VariantWeapon> VariantList;
var int VariantSelection;

function class<Pickup> GetPickup()
{
	if (VariantSelection == -1 || VariantList.Length <= VariantSelection)
	{
		return ItemPickupClass;
	}

	return VariantList[VariantSelection].VariantClass;
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

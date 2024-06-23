class KFPGUIBuyWeaponInfoPanel extends GUIBuyWeaponInfoPanel;

function Display(GUIBuyable NewBuyable)
{
	local KFPGUIBuyable KFPBuyable;
	local class<KFWeaponPickup> PickupClass;
	
	Super.Display(NewBuyable);

	KFPBuyable = KFPGUIBuyable(NewBuyable);

	if (KFPBuyable == None)
	{
		return;
	}

	PickupClass = class<KFWeaponPickup>(KFPBuyable.GetPickup());

	ItemName.Caption = PickupClass.default.ItemName;
	ItemImage.Image = class<KFWeapon>(PickupClass.default.InventoryType).default.TraderInfoTexture;
}

defaultproperties
{
}

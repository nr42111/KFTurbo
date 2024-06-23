class KFPBuyMenuSaleListBox extends SRBuyMenuSaleListBox;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	DefaultListClass = string(Class'KFPBuyMenuSaleList');
	Super(KFBuyMenuSaleListBox).InitComponent(MyController, MyOwner);
}

defaultproperties
{
}

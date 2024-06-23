class KFPBuyMenuInvListBox extends SRKFBuyMenuInvListBox;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	DefaultListClass = string(Class'KFPBuyMenuInvList');
	Super(KFBuyMenuInvListBox).InitComponent(MyController,MyOwner);
}

defaultproperties
{
}

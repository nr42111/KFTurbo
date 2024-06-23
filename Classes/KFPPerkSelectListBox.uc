class KFPPerkSelectListBox extends SRPerkSelectListBox;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	DefaultListClass = string(Class'KFPPerkSelectList');
	Super(KFPerkSelectListBox).InitComponent(MyController,MyOwner);
}

defaultproperties
{
}

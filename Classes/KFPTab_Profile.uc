class KFPTab_Profile extends SRTab_Profile;

function OnPerkSelected(GUIComponent Sender)
{
	local ClientPerkRepLink ST;
	local byte Idx;
	local string S;

	ST = Class'ClientPerkRepLink'.Static.FindStats(PlayerOwner());

	if ( ST==None || ST.CachePerks.Length==0 )
	{
		if( ST!=None )
			ST.ServerRequestPerks();

		lb_PerkEffects.SetContent("Please wait while your client is loading the perks...");
	}
	else
	{
		Idx = lb_PerkSelect.GetIndex();

		if( ST.CachePerks[Idx].CurrentLevel==0 )
			S = ST.CachePerks[Idx].PerkClass.Static.GetVetInfoText(0,1);
		else if( ST.CachePerks[Idx].CurrentLevel==ST.MaximumLevel )
			S = ST.CachePerks[Idx].PerkClass.Static.GetVetInfoText(ST.CachePerks[Idx].CurrentLevel-1,1);
		else S = ST.CachePerks[Idx].PerkClass.Static.GetVetInfoText(ST.CachePerks[Idx].CurrentLevel-1,1)$Class'KFPTab_MidGamePerks'.Default.NextInfoStr$ST.CachePerks[Idx].PerkClass.Static.GetVetInfoText(ST.CachePerks[Idx].CurrentLevel,1);
		
		lb_PerkEffects.SetContent(S);
		lb_PerkProgress.List.PerkChanged(KFStatsAndAchievements, Idx);
	}
}

defaultproperties
{
     Begin Object Class=KFPPerkSelectListBox Name=PerkSelectList
         OnCreateComponent=PerkSelectList.InternalOnCreateComponent
         WinTop=0.082969
         WinLeft=0.323418
         WinWidth=0.318980
         WinHeight=0.654653
     End Object
     lb_PerkSelect=KFPPerkSelectListBox'KFTurbo.KFPTab_Profile.PerkSelectList'

}

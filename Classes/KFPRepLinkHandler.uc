class KFPRepLinkHandler extends Actor
    dependson(KFPRepLink);

var array<ServerStStats> PendingReplicationLinkList;

function OnServerStatsAdded(ServerStStats Stats)
{
    PendingReplicationLinkList[PendingReplicationLinkList.Length] = Stats;
    SetTimer(0.1, false);
}

function Timer()
{
	local int i;
    local KFPlayerController CurrentPlayerController;
    local LinkedReplicationInfo LastLinkedReplicationInfo;
    local KFPRepLink NewRepLink;
	
	for(i = (PendingReplicationLinkList.Length - 1); i>=0; --i)
	{
        CurrentPlayerController = KFPlayerController(PendingReplicationLinkList[i].Owner);

        if (CurrentPlayerController == none)
        {
            continue;
        }

        if (CurrentPlayerController.PlayerReplicationInfo == none)
        {
            continue;
        }

        LastLinkedReplicationInfo = CurrentPlayerController.PlayerReplicationInfo.CustomReplicationInfo;

        if (LastLinkedReplicationInfo == none)
        {
            NewRepLink = Spawn(class'KFPRepLink', CurrentPlayerController);
            NewRepLink.OwningController = CurrentPlayerController;
            NewRepLink.OwningReplicationInfo = KFPlayerReplicationInfo(CurrentPlayerController.PlayerReplicationInfo);

            CurrentPlayerController.PlayerReplicationInfo.CustomReplicationInfo = NewRepLink;
            NewRepLink.GotoState('RepSetup');
        }
        else
        {
            while (LastLinkedReplicationInfo.NextReplicationInfo != none)
            {
                LastLinkedReplicationInfo = LastLinkedReplicationInfo.NextReplicationInfo;
            }

            NewRepLink = Spawn(class'KFPRepLink', CurrentPlayerController);
            NewRepLink.OwningController = CurrentPlayerController;
            NewRepLink.OwningReplicationInfo = KFPlayerReplicationInfo(CurrentPlayerController.PlayerReplicationInfo);

            LastLinkedReplicationInfo.NextReplicationInfo = NewRepLink;
            NewRepLink.GotoState('RepSetup');
        }
	}

	PendingReplicationLinkList.Length = 0;
}
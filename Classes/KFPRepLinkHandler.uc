class KFPRepLinkHandler extends Actor;

var KFTurboMut KFTurboMutator;
var array<ServerStStats> PendingReplicationLinkList;

event PostBeginPlay()
{
    KFTurboMutator = KFTurboMut(Owner);
    Super.PostBeginPlay();
}

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
    local array<LinkedReplicationInfo> NewRepLinkList;
    
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
            NewRepLink.KFTurboMutator = KFTurboMutator;
            NewRepLink.OwningController = CurrentPlayerController;
            NewRepLink.OwningReplicationInfo = KFPlayerReplicationInfo(CurrentPlayerController.PlayerReplicationInfo);

            CurrentPlayerController.PlayerReplicationInfo.CustomReplicationInfo = NewRepLink;
            NewRepLink.InitializeRepSetup();
        }
        else
        {
            while (LastLinkedReplicationInfo.NextReplicationInfo != none)
            {
                LastLinkedReplicationInfo = LastLinkedReplicationInfo.NextReplicationInfo;
            }

            NewRepLink = Spawn(class'KFPRepLink', CurrentPlayerController);
            NewRepLink.KFTurboMutator = KFTurboMutator;
            NewRepLink.OwningController = CurrentPlayerController;
            NewRepLink.OwningReplicationInfo = KFPlayerReplicationInfo(CurrentPlayerController.PlayerReplicationInfo);

            LastLinkedReplicationInfo.NextReplicationInfo = NewRepLink;
            NewRepLink.InitializeRepSetup();
        }

        NewRepLinkList[NewRepLinkList.Length] = NewRepLink;
    }

    PendingReplicationLinkList.Length = 0;

    for(i = (NewRepLinkList.Length - 1); i>=0; --i)
    {
        KFPRepLink(NewRepLinkList[i]).SetupPlayerInfo();
    }
}

defaultproperties
{

}
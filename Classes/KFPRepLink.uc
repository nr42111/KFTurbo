class KFPRepLink extends LinkedReplicationInfo
    dependson(KFTurboRepLinkSettings);

//This local player's variant list.
var array<KFTurboRepLinkSettings.WeaponVariantData> PlayerVariantList;

var KFTurboMut KFTurboMutator;
var KFPlayerController OwningController;
var KFPlayerReplicationInfo OwningReplicationInfo;
var String PlayerID;
var array<String> PlayerGroups;

var int WeaponIndex;
var int VariantIndex;

var int FailureCount;

replication
{
    reliable if (Role == ROLE_Authority)
        Client_Reliable_SendVariant, Client_Reliable_SendComplete;
}

state RepSetup
{
Begin:
    if (Level.NetMode == NM_Client)
    {
        Stop;
    }

    Sleep(0.1f);

    while (OwningController == None)
    {
        FailureCount++;
        if (FailureCount % 20 == 0)
        {
            log("WARNING FAILURE LIMIT REACHED " $ FailureCount $ " TIMES ON " $ string(Self) $ ".", 'KFTurbo');
        }

        Sleep(1.f);
    }

    SetupPlayerInfo();
    Sleep(1.f);

    if (NetConnection(OwningController.Player) == None)
    {
        GenerateVariantStatus();
        Stop;
    }

    for (WeaponIndex = 0; WeaponIndex < PlayerVariantList.Length; WeaponIndex++)
    {
        for (VariantIndex = 0; VariantIndex < PlayerVariantList[WeaponIndex].VariantList.Length; VariantIndex++)
        {
            Client_Reliable_SendVariant(PlayerVariantList[WeaponIndex].WeaponPickup, PlayerVariantList[WeaponIndex].VariantList[VariantIndex]);
        }
        Sleep(0.1f);
    }

    Client_Reliable_SendComplete();

    Sleep(1.f);
}

simulated function InitializeRepSetup()
{
    GotoState('RepSetup');
}

function SetupPlayerInfo()
{
    PlayerID = OwningController.GetPlayerIDHash();
    KFTurboMutator.RepLinkSettings.GeneratePlayerVariantData(PlayerID, PlayerVariantList);
}

simulated function GenerateVariantStatus()
{
    local int i, j;

    for (i = 0; i < PlayerVariantList.Length; i++)
    {
        for (j = 0; j < PlayerVariantList[i].VariantList.Length; j++)
        {
            PlayerVariantList[i].VariantList[j].ItemStatus = 255;
        }
    }

    Spawn(Class'KFPSteamStatsGet', Owner).Link = Self;
}

simulated function DebugVariantInfo(bool bFilterStatus)
{
    local int i, j;
    local string VariantSet;

    for(i = 0; i < PlayerVariantList.Length; i++)
    {
        VariantSet = "Pickup: " $ PlayerVariantList[i].WeaponPickup;

        for(j = 0; j < PlayerVariantList[i].VariantList.Length; j++)
        {
            if (bFilterStatus && PlayerVariantList[i].VariantList[j].ItemStatus != 0)
            {
                continue;
            }

            VariantSet = VariantSet $ " | " $ j $ ": " $ PlayerVariantList[i].VariantList[j].VariantClass $ " (" $ PlayerVariantList[i].VariantList[j].ItemStatus $ ")";
        }

        log(VariantSet, 'KFTurbo');
    }

    if (PlayerVariantList.Length == 0)
    {
        log("WARNING: PlayerVariantList was empty!", 'KFTurbo');
    }
}

simulated function Client_Reliable_SendVariant(class<KFWeaponPickup> Pickup, KFTurboRepLinkSettings.VariantWeapon Variant)
{
    local int i;

    for (i = 0; i < PlayerVariantList.Length; i++)
    {
        if (PlayerVariantList[i].WeaponPickup != Pickup)
        {
            continue;
        }

        PlayerVariantList[i].VariantList[PlayerVariantList[i].VariantList.Length] = Variant;
        return;
    }

    i = PlayerVariantList.Length;
    PlayerVariantList.Length = i + 1;

    PlayerVariantList[i].WeaponPickup = Pickup;
    PlayerVariantList[i].VariantList[0] = Variant;
}

simulated function Client_Reliable_SendComplete()
{
    GenerateVariantStatus();
}

simulated function GetVariantsForWeapon(class<KFWeaponPickup> Pickup, out array<KFTurboRepLinkSettings.VariantWeapon> VariantList)
{
    local int i;

    for (i = 0; i < PlayerVariantList.Length; i++)
    {
        if (PlayerVariantList[i].WeaponPickup != Pickup)
        {
            continue;
        }

        VariantList = PlayerVariantList[i].VariantList;
        break;
    }
}

static function KFPRepLink GetKFPRepLink(PlayerReplicationInfo PRI)
{
    local LinkedReplicationInfo LRI;
    local KFPRepLink KFPLRI;

    if (PRI == None)
    {
        return None;
    }

    for (LRI = PRI.CustomReplicationInfo; LRI != None; LRI = LRI.NextReplicationInfo)
    {
        if (KFPRepLink(LRI) != None)
        {
            return KFPRepLink(LRI);
        }
    }

    foreach PRI.DynamicActors(class'KFPRepLink', KFPLRI)
    {
        if (KFPLRI.OwningReplicationInfo == PRI)
        {
            return KFPLRI;
        }
    }

    return None;
}

defaultproperties
{
    bOnlyRelevantToOwner=True
    bAlwaysRelevant=False
}

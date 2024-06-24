class KFTurboRepLinkSettings extends Object;

//User and Group configuration.
var editinline array<KFTurboRepLinkSettingsUser> UserList;
var editinline array<KFTurboRepLinkSettingsGroup> GroupList;

//Mutator context.
var ServerPerksMut ServerPerksMut;
var KFTurboMut KFTurboMutator;

struct VariantWeapon
{
    var class<KFWeaponPickup> VariantClass;
    var string VariantID;
    var int ItemStatus;
};

struct WeaponVariantData
{
    var class<KFWeaponPickup> WeaponPickup;
    var array<VariantWeapon> VariantList;
};
var array<WeaponVariantData> VariantWeaponList;

// Built-in Variant Set Names:
//Common variants - accessible to all players.
var const String DefaultID; //All non-variants.
var const String GoldVariantID; //Gold skins.
var const String CamoVariantID; //Camo skins.
var const String TurboVariantID; //KFTurbo sticker skins.
var const String VMVariantID; //VM sticker skins.
var const String WLVariantID; //Westlondon sticker skins.

//Special variants - accessible to specific players.
var const String RetartVariantID;
var const String ScuddlesVariantID;
var const String CubicVariantID;
var const String SMPVariantID;


static final function DebugLog(string DebugString)
{
    log(DebugString, 'KFTurbo');
}

//For the given PlayerSteamID, provides back a list of all the Variant IDs they have access to.
function GetPlayerVariantIDList(String PlayerSteamID, out array<String> PlayerVariantIDList)
{
    local int PlayerIndex, GroupIDIndex;
    local int GroupIndex;
    local KFTurboRepLinkSettingsUser UserObject;
    local KFTurboRepLinkSettingsGroup GroupObject;
    local array<String> UserGroupIDList;
    local bool bFoundGroupID;

    PlayerVariantIDList.Length = 0;

    for (PlayerIndex = 0; PlayerIndex < UserList.Length; PlayerIndex++)
    {
        if (UserList[PlayerIndex].PlayerSteamID != PlayerSteamID)
        {
            continue;
        }

        UserObject = UserList[PlayerIndex];
        PlayerVariantIDList = UserObject.VariantIDList;
        UserGroupIDList = UserObject.GroupIDList; //Cache group ID list.
        break;
    }

    for (GroupIndex = 0; GroupIndex < GroupList.Length; GroupIndex++)
    {
        GroupObject = GroupList[GroupIndex];

        if (!GroupObject.bDefaultGroup)
        {
            bFoundGroupID = false;

            for (GroupIDIndex = 0; GroupIDIndex < UserGroupIDList.Length; GroupIDIndex++)
            {
                if (GroupObject.GroupID == UserGroupIDList[GroupIDIndex])
                {
                    bFoundGroupID = true;
                    break;
                }
            }

            if (!bFoundGroupID)
            {
                continue;
            }
        }

        AppendPlayerVariantIDList(PlayerVariantIDList, GroupObject.VariantIDList);
    }
}

static final function AppendPlayerVariantIDList(out array<string> PlayerVariantIDList, array<string> NewVariantIDList)
{
    local int VariantIDIndex, PlayerVariantIDIndex;
    local bool bAlreadyInPlayerList;

    for (VariantIDIndex = NewVariantIDList.Length - 1; VariantIDIndex >= 0; VariantIDIndex--)
    {
        bAlreadyInPlayerList = false;
        for (PlayerVariantIDIndex = PlayerVariantIDList.Length - 1; PlayerVariantIDIndex >= 0; PlayerVariantIDIndex--)
        {
            if (NewVariantIDList[VariantIDIndex] == PlayerVariantIDList[PlayerVariantIDIndex])
            {
                bAlreadyInPlayerList = true;
                break;
            }
        }

        if (bAlreadyInPlayerList)
        {
            continue;
        }

        PlayerVariantIDList[PlayerVariantIDList.Length] = NewVariantIDList[VariantIDIndex];
    }
}

function GeneratePlayerVariantData(String PlayerSteamID, out array<WeaponVariantData> PlayerVariantWeaponList)
{
    local array<String> PlayerVariantIDList;
    local int VariantWeaponListIndex;
    local int VariantIndex;
    local int PlayerVariantIDIndex;
    local class<KFWeaponPickup> WeaponPickup;
    local array<VariantWeapon> PlayerVariantList;

    StopWatch(false);

    GetPlayerVariantIDList(PlayerSteamID, PlayerVariantIDList);

    //DebugLog("Just called KFTurboRepLinkSettings::GetPlayerVariantIDList. Printing out variant ID access.");
    for (VariantWeaponListIndex = PlayerVariantIDList.Length - 1; VariantWeaponListIndex >= 0; VariantWeaponListIndex--)
    {
        //DebugLog("| - "$PlayerVariantIDList[VariantWeaponListIndex]);
    }

    PlayerVariantWeaponList.Length = 0;

    for (VariantWeaponListIndex = VariantWeaponList.Length - 1; VariantWeaponListIndex >= 0; VariantWeaponListIndex--)
    {
        PlayerVariantList.Length = 0;

        WeaponPickup = VariantWeaponList[VariantWeaponListIndex].WeaponPickup;
    
        for (VariantIndex = VariantWeaponList[VariantWeaponListIndex].VariantList.Length - 1; VariantIndex >= 0; VariantIndex--)
        {
            for (PlayerVariantIDIndex = PlayerVariantIDList.Length - 1; PlayerVariantIDIndex >= 0; PlayerVariantIDIndex--)
            {
                if (VariantWeaponList[VariantWeaponListIndex].VariantList[VariantIndex].VariantID == PlayerVariantIDList[PlayerVariantIDIndex])
                {
                    PlayerVariantList.Insert(PlayerVariantList.Length, 1);
                    PlayerVariantList[PlayerVariantList.Length - 1] = VariantWeaponList[VariantWeaponListIndex].VariantList[VariantIndex];
                }
            }
        }

        PlayerVariantWeaponList.Insert(PlayerVariantWeaponList.Length, 1);
        PlayerVariantWeaponList[PlayerVariantWeaponList.Length - 1].WeaponPickup = WeaponPickup;
        PlayerVariantWeaponList[PlayerVariantWeaponList.Length - 1].VariantList = PlayerVariantList;
    }

    StopWatch(true);
    log("The above time is KFTurboRepLinkSettings::GeneratePlayerVariantData duration.", 'KFTurbo');
}

//Setup a cache of all variant weapons and their associated IDs. This will prevent needing to refigure out what variants are available each time a player joins.
function Initialize()
{
    local int LoadInventoryIndex, LoadInventoryVariantIndex;
    local int NewVariantIndex;
    local class<KFWeaponPickup> KFWeaponPickupClass, KFWeaponVariantPickupClass;
    local VariantWeapon VariantWeaponEntry;

    StopWatch(false);

    KFTurboMutator = KFTurboMut(Outer);

    foreach KFTurboMutator.Level.AllActors( class'ServerPerksMut', ServerPerksMut )
		break;

    for (LoadInventoryIndex = ServerPerksMut.LoadInventory.Length - 1;  LoadInventoryIndex >= 0; LoadInventoryIndex--)
    {
        KFWeaponPickupClass = class<KFWeaponPickup>(ServerPerksMut.LoadInventory[LoadInventoryIndex]);

        if (KFWeaponPickupClass == none || KFWeaponPickupClass.default.VariantClasses.Length == 0)
        {
            continue;
        }

        VariantWeaponList.Insert(VariantWeaponList.Length, 1);
        NewVariantIndex = VariantWeaponList.Length - 1;

        VariantWeaponList[NewVariantIndex].WeaponPickup = KFWeaponPickupClass;
        
        //DebugLog("KFTurboRepLinkSettings::Initialize | Generating cache for: "$KFWeaponPickupClass$" (Has "$KFWeaponPickupClass.default.VariantClasses.Length$" variants.)");

        for (LoadInventoryVariantIndex = KFWeaponPickupClass.default.VariantClasses.Length - 1; LoadInventoryVariantIndex >= 0; LoadInventoryVariantIndex--)
        {
            KFWeaponVariantPickupClass = class<KFWeaponPickup>(KFWeaponPickupClass.default.VariantClasses[LoadInventoryVariantIndex]);

            //DebugLog("KFTurboRepLinkSettings::Initialize | |- Trying variant "$KFWeaponVariantPickupClass);

            if (KFWeaponVariantPickupClass == none)
            {
                continue;
            }

            if (KFWeaponVariantPickupClass == KFWeaponPickupClass)
            {
                VariantWeaponEntry.VariantClass = KFWeaponVariantPickupClass;
                VariantWeaponEntry.VariantID = DefaultID;
                VariantWeaponEntry.ItemStatus = 0; //Don't bother?
                VariantWeaponList[NewVariantIndex].VariantList[VariantWeaponList[NewVariantIndex].VariantList.Length] = VariantWeaponEntry;
                continue;
            }
            else
            {
                VariantWeaponEntry.VariantClass = KFWeaponVariantPickupClass;
                VariantWeaponEntry.ItemStatus = 255;
                AssignEntryVariantID(VariantWeaponEntry);

                VariantWeaponList[NewVariantIndex].VariantList[VariantWeaponList[NewVariantIndex].VariantList.Length] = VariantWeaponEntry;
            }

            //DebugLog("KFTurboRepLinkSettings::Initialize | | |- Result: VariantID "$VariantWeaponEntry.VariantID$" | Status "$VariantWeaponEntry.ItemStatus);
        }
    }

    StopWatch(true);
    log("The above time is KFTurboRepLinkSettings::Initialize duration.", 'KFTurbo');
}

function AssignEntryVariantID(out VariantWeapon Entry)
{
    Entry.VariantID = "";

    if (AssignSpecialVariantID(Entry))
    {
        return;
    }

    if (IsGenericGoldSkin(Entry.VariantClass))
    {
        Entry.VariantID = GoldVariantID;
    }
    else if (IsGenericCamoSkin(Entry.VariantClass))
    {
        Entry.VariantID = CamoVariantID;
    }
    else if (IsGenericTurboSkin(Entry.VariantClass))
    {
        Entry.VariantID = TurboVariantID;
    }
    else if (IsGenericVMSkin(Entry.VariantClass))
    {
        Entry.VariantID = VMVariantID;
    }
    else if (IsGenericWestLondonSkin(Entry.VariantClass))
    {
        Entry.VariantID = WLVariantID;
    }
}

function bool AssignSpecialVariantID(out VariantWeapon Entry)
{
    switch (Entry.VariantClass)
    {
        case class'W_V_M4203_Retart_Pickup' :
            Entry.VariantID = RetartVariantID;
            break;
        case class'W_V_M4203_Scuddles_Pickup' :
            Entry.VariantID = RetartVariantID;
            break;
        case class'W_V_M14_Cubic_Pickup' :
            Entry.VariantID = RetartVariantID;
            break;
        case class'W_V_M14_SMP_Pickup' :
            Entry.VariantID = SMPVariantID;
            break;
    }
    return Entry.VariantID != "";
}

static final function bool IsGenericGoldSkin(class<Pickup> PickupClass)
{
	return InStr(Caps(PickupClass), "_GOLD_") != -1;
}

static final function bool IsGenericCamoSkin(class<Pickup> PickupClass)
{
	return InStr(Caps(PickupClass), "_CAMO_") != -1;
}

static final function bool IsGenericTurboSkin(class<Pickup> PickupClass)
{
	return InStr(Caps(PickupClass), "_TURBO_") != -1;
}

static final function bool IsGenericVMSkin(class<Pickup> PickupClass)
{
	return InStr(Caps(PickupClass), "_VM_") != -1;
}

static final function bool IsGenericWestLondonSkin(class<Pickup> PickupClass)
{
	return InStr(Caps(PickupClass), "_WL_") != -1;
}

defaultproperties
{
    DefaultID = "DEF"
    GoldVariantID = "GOLD"
    CamoVariantID = "CAMO"
    TurboVariantID = "TURBO"
    VMVariantID = "VM"
    WLVariantID = "WEST"

    RetartVariantID = "RET"
    ScuddlesVariantID = "SCUD"
    CubicVariantID = "CUBIC"
    SMPVariantID = "SHOWME"

    //Default group that gives all players access to a set weapon skins.
    Begin Object Class=KFTurboRepLinkSettingsGroup Name=RepLinkDefaultGroup
        DisplayName="DefaultGroup"
        bDefaultGroup=true
        VariantIDList(0)="DEF"
        VariantIDList(1)="GOLD"
        VariantIDList(2)="CAMO"
        VariantIDList(3)="TURBO"
        VariantIDList(4)="VM"
        VariantIDList(5)="WEST"
    End Object
    GroupList(0)=KFTurboRepLinkSettingsGroup'KFTurbo.KFTurboRepLinkSettings.RepLinkDefaultGroup'

    Begin Object Class=KFTurboRepLinkSettingsUser Name=RepLinkTestUser
        PlayerSteamID="20b300195d48c2ccc2651885cfea1a2f"
        DisplayName="Retard"
        VariantIDList(0)="RET"
        VariantIDList(1)="SCUD"
        VariantIDList(2)="CUBIC"
        VariantIDList(3)="SHOWME"
    End Object
    UserList(0)=KFTurboRepLinkSettingsUser'KFTurbo.KFTurboRepLinkSettings.RepLinkTestUser'

}
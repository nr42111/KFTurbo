class KFTurboRepLinkSettings extends Object;

//User and Group configuration.
var array<KFTurboRepLinkSettingsUser> UserList;
var array<KFTurboRepLinkSettingsGroup> GroupList;

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

//For the given PlayerSteamID, provides back a list of all the Variant IDs they have access to.
function GetPlayerVariantIDList(String PlayerSteamID, out array<String> PlayerVariantIDList)
{
    local int PlayerIndex, GroupIDIndex;
    local int GroupIndex, GroupVariantIDIndex;
    local KFTurboRepLinkSettingsUser UserObject;
    local KFTurboRepLinkSettingsGroup GroupObject;
    local array<String> GroupIDList;

    PlayerVariantIDList.Length = 0;

    for (PlayerIndex = 0; PlayerIndex < UserList.Length; PlayerIndex++)
    {
        if (UserList[PlayerIndex].PlayerSteamID != PlayerSteamID)
        {
            continue;
        }

        UserObject = UserList[PlayerIndex];
        PlayerVariantIDList = UserObject.VariantIDList;
        GroupIDList = UserObject.GroupIDList;

        for (GroupIDIndex = 0; GroupIDIndex < GroupIDList.Length; GroupIDIndex++)
        {
            for (GroupIndex = 0; GroupIndex < GroupList.Length; GroupIndex++)
            {
                if (GroupIDList[GroupIDIndex] != GroupList[GroupIndex].GroupID)
                {
                    continue;
                }

                GroupObject = GroupList[GroupIndex];

                for (GroupVariantIDIndex = 0; GroupVariantIDIndex < GroupObject.VariantIDList.Length; GroupVariantIDIndex++)
                {
                    PlayerVariantIDList[PlayerVariantIDList.Length] = GroupObject.VariantIDList[GroupVariantIDIndex];
                }
                break;
            }
        }

        break;
    }

}

function GetPlayerVariantData(String PlayerSteamID, out array<WeaponVariantData> PlayerVariantWeaponList)
{
    local array<String> PlayerVariantIDList;
    local int VariantWeaponListIndex;
    local int VariantIndex;
    local int PlayerVariantIDIndex;
    local class<KFWeaponPickup> WeaponPickup;
    local array<VariantWeapon> PlayerVariantList;

    GetPlayerVariantIDList(PlayerSteamID, PlayerVariantIDList);

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
                    PlayerVariantList[PlayerVariantList.Length] = VariantWeaponList[VariantWeaponListIndex].VariantList[VariantIndex];
                }
            }
        }

        PlayerVariantWeaponList[PlayerVariantWeaponList.Length].WeaponPickup = WeaponPickup;
        PlayerVariantWeaponList[PlayerVariantWeaponList.Length - 1].VariantList = PlayerVariantList;
    }
}

//Setup a cache of all variant weapons and their associated IDs. This will prevent needing to refigure out what variants are available each time a player joins.
function Initialize()
{
    local int LoadInventoryIndex, LoadInventoryVariantIndex;
    local int NewVariantIndex;
    local class<KFWeaponPickup> KFWeaponPickupClass, KFWeaponVariantPickupClass;
    local VariantWeapon VariantWeaponEntry;

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

        NewVariantIndex = VariantWeaponList.Length;

        VariantWeaponList[NewVariantIndex].WeaponPickup = KFWeaponPickupClass;

        for (LoadInventoryVariantIndex = KFWeaponPickupClass.default.VariantClasses.Length - 1; LoadInventoryVariantIndex >= 0; LoadInventoryVariantIndex--)
        {
            KFWeaponVariantPickupClass = class<KFWeaponPickup>(KFWeaponPickupClass.default.VariantClasses[LoadInventoryVariantIndex]);

            if (KFWeaponVariantPickupClass == none)
            {
                continue;
            }

            VariantWeaponEntry.VariantClass = KFWeaponVariantPickupClass;
            AssignEntryVariantID(VariantWeaponEntry);

            VariantWeaponList[NewVariantIndex].VariantList[VariantWeaponList[NewVariantIndex].VariantList.Length] = VariantWeaponEntry;
        }
    }
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
    GoldVariantID = "GOLD"
    CamoVariantID = "CAMO"
    TurboVariantID = "TURBO"
    VMVariantID = "VM"
    WLVariantID = "WEST"

    RetartVariantID = "RET"
    ScuddlesVariantID = "SCUD"
    CubicVariantID = "CUBIC"
    SMPVariantID = "SHOWME"
}
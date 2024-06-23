class KFPRepLink extends LinkedReplicationInfo
	config(KFPro);

enum EMetaGroup
{
	Developer,
	Contributor,
	Regular,
	Default
};

struct GroupData
{
	var EMetaGroup Group;
	var bool bCanOptIn;
	var array<string> PlayerList;
};

var config array<GroupData> Groups;

struct SkinVariantData
{
	var class<KFWeaponPickup> WeaponPickup;
	var array< class<KFWeaponPickup> > VariantClasses;
	var array<byte> VariantStatus;
};
//Master list of all variants.
var array<SkinVariantData> VariantData;

struct VariantSelection
{
	var byte Index;
	var int Mask;
};
struct PlayerSkinContainer
{
	var string PlayerID;
	var array<VariantSelection> Data;
};
struct GroupSkinContainer
{
	var EMetaGroup Group;
	var array<VariantSelection> Data;
};
var config array<PlayerSkinContainer> PlayerSkins;
var config array<GroupSkinContainer> GroupSkins;

//This local player's variant list.
var array<SkinVariantData> PlayerVariantList;

var KFPlayerController OwningController;
var KFPlayerReplicationInfo OwningReplicationInfo;
var String PlayerID;
var array<EMetaGroup> PlayerGroups;

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
	NetUpdateFrequency = 0.5f;

	if (NetConnection(OwningController.Player) == None)
	{
		GenerateVariantStatus();
		Stop;
	}

	for (WeaponIndex = 0; WeaponIndex < PlayerVariantList.Length; WeaponIndex++)
	{
		for (VariantIndex = 0; VariantIndex < PlayerVariantList[WeaponIndex].VariantClasses.Length; VariantIndex++)
		{
			Client_Reliable_SendVariant(PlayerVariantList[WeaponIndex].WeaponPickup, PlayerVariantList[WeaponIndex].VariantClasses[VariantIndex]);
		}
		Sleep(0.1f);
	}

	Client_Reliable_SendComplete();
}

simulated function SetupPlayerInfo()
{
	local int GroupIndex;
	local int i;

	PlayerID = OwningController.GetPlayerIDHash();
	log("Initializing Rep Link For Player ID: " $ PlayerID, 'KFTurbo');

	for (i = 0; i < PlayerSkins.Length; i++)
	{
		if (PlayerSkins[i].PlayerID == PlayerID)
		{
			AppendVariantSelectionList(PlayerVariantList, PlayerSkins[i].Data);
			break;
		}
	}

	//If GroupSkins has a Default list, append it now.
	AppendVariantSelectionList(PlayerVariantList, GetDataFromGroup(Default));

	for (GroupIndex = 0; GroupIndex < Groups.Length; GroupIndex++)
	{
		if (EMetaGroup.Default == Groups[GroupIndex].Group)
		{
			continue;
		}

		for (i = 0; i < Groups[GroupIndex].PlayerList.Length; i++)
		{
			if (Groups[GroupIndex].PlayerList[i] == PlayerID)
			{
				PlayerGroups[PlayerGroups.Length] = Groups[GroupIndex].Group;
				AppendVariantSelectionList(PlayerVariantList, GetDataFromGroup(Groups[GroupIndex].Group));
				break;
			}
		}
	}
	
	SaveConfig();
}

simulated function array<VariantSelection> GetDataFromGroup(EMetaGroup Group)
{
	local array<VariantSelection> VariantSelectionList;
	local int i;

	for (i = 0; i < GroupSkins.Length; i++)
	{
		if (GroupSkins[i].Group == Group)
		{
			return GroupSkins[i].Data;
		}
	}
	
	return VariantSelectionList;
}

simulated function GenerateVariantStatus()
{
	local int i, j;

	for (i = 0; i < PlayerVariantList.Length; i++)
	{
		PlayerVariantList[i].VariantStatus.Length = PlayerVariantList[i].VariantClasses.Length;

		for (j = 0; j < PlayerVariantList[i].VariantClasses.Length; j++)
		{
			PlayerVariantList[i].VariantStatus[j] = 255;
		}
	}

	Spawn(Class'KFPSteamStatsGet', Owner).Link = Self;
}

simulated final function bool GetSkinDataFromVariantSelection(out VariantSelection Selection, out SkinVariantData SVD)
{
	local int i;

	if (Selection.Index >= VariantData.Length)
	{
		return false;
	}

	SVD.WeaponPickup = VariantData[Selection.Index].WeaponPickup;

	for (i = 0; i < VariantData[Selection.Index].VariantClasses.Length; i++)
	{
		if (((2 ** i) & Selection.Mask) != (2 ** i))
		{
			continue;
		}

		SVD.VariantClasses[SVD.VariantClasses.Length] = VariantData[Selection.Index].VariantClasses[i];
	}

	return true;
}

simulated final function AppendVariantSelectionList(out array<SkinVariantData> ArrayTarget, out array<VariantSelection> SelectionList)
{
	local int i;
	local SkinVariantData SVD;

	for (i = 0; i < SelectionList.Length; i++)
	{
		SVD.WeaponPickup = None;
		SVD.VariantClasses.Length = 0;

		if (!GetSkinDataFromVariantSelection(SelectionList[i], SVD))
		{
			continue;
		}

		AppendSkinVariantData(ArrayTarget, SVD);
	}
}

simulated function DebugVariantInfo(bool bFilterStatus)
{
	local int i, j;
	local string VariantSet;

	for(i = 0; i < PlayerVariantList.Length; i++)
	{
		VariantSet = "Pickup: " $ PlayerVariantList[i].WeaponPickup;

		for(j = 0; j < PlayerVariantList[i].VariantClasses.Length; j++)
		{
			if (bFilterStatus && PlayerVariantList[i].VariantStatus[j] != 0)
			{
				continue;
			}

			VariantSet = VariantSet $ " | " $ j $ ": " $ PlayerVariantList[i].VariantClasses[j] $ " (" $ PlayerVariantList[i].VariantStatus[j] $ ")";
		}

		log(VariantSet);
	}
}

//Both declared as ref as a potential optimization since we're heavily nesting loops here...
static final function AppendSkinVariantData(out array<SkinVariantData> AppendTarget, out SkinVariantData AppendPayload)
{
	local int TI;

	for (TI = 0; TI < AppendTarget.Length; TI++)
	{
		if (AppendTarget[TI].WeaponPickup == AppendPayload.WeaponPickup)
		{
			AppendVariants(AppendTarget[TI].VariantClasses, AppendPayload.VariantClasses);
			return;
		}
	}

	AppendTarget.Length = AppendTarget.Length + 1;
	AppendTarget[AppendTarget.Length - 1].WeaponPickup = AppendPayload.WeaponPickup;
	AppendTarget[AppendTarget.Length - 1].VariantClasses = AppendPayload.VariantClasses;
}

//Both declared as ref as a potential optimization since we're heavily nesting loops here...
static final function AppendVariants(out array< class<KFWeaponPickup> > AppendTarget, out array< class<KFWeaponPickup> > AppendPayload)
{
	local int TI, PI;
	local bool bAlreadyExists;

	for (PI = 0; PI < AppendPayload.Length; PI++)
	{
		bAlreadyExists = false;
		for (TI = 0; TI < AppendTarget.Length; TI++)
		{
			if (AppendTarget[TI] == AppendPayload[PI])
			{
				bAlreadyExists = true;
				break;
			}
		}

		if (bAlreadyExists)
		{
			continue;
		}

		AppendTarget[AppendTarget.Length] = AppendPayload[PI];
	}
}

simulated function Client_Reliable_SendVariant(class<KFWeaponPickup> Pickup, class<KFWeaponPickup> Variant)
{
	local int i;

	for (i = 0; i < PlayerVariantList.Length; i++)
	{
		if (PlayerVariantList[i].WeaponPickup != Pickup)
		{
			continue;
		}

		PlayerVariantList[i].VariantClasses[PlayerVariantList[i].VariantClasses.Length] = Variant;
		return;
	}

	i = PlayerVariantList.Length;
	PlayerVariantList.Length = i + 1;

	PlayerVariantList[i].WeaponPickup = Pickup;
	PlayerVariantList[i].VariantClasses[0] = Variant;
}

simulated function Client_Reliable_SendComplete()
{
	GenerateVariantStatus();
}

simulated function GetVariantsForWeapon(class<KFWeaponPickup> Pickup, out array< class<Pickup> > VariantList, out array<byte> VariantStatus)
{
	local int i;

	for (i = 0; i < PlayerVariantList.Length; i++)
	{
		if (PlayerVariantList[i].WeaponPickup != Pickup)
		{
			continue;
		}

		VariantList = PlayerVariantList[i].VariantClasses;
		VariantStatus = PlayerVariantList[i].VariantStatus;
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

static function Texture GetIconForPickup(class<Pickup> PickupClass)
{
	switch (PickupClass)
	{
	//Default weapon
	case class'W_FlameThrower_Pick' :
	case class'W_M4203_Pickup' :
	case class'W_M14_Pickup' :
	case class'W_Shotgun_Pickup' :
	case class'W_AK47_Pickup' :
	case class'W_Deagle_Pickup' :
	case class'W_DualDeagle_Pickup' :
	case class'W_Katana_Pickup' :
	case class'W_Benelli_Pickup' :
	case class'W_MP5M_Pickup' :
	case class'W_M32_Pickup' :
	case class'W_BlowerThrower_Pickup' :
	case class'W_FNFAL_Pickup' :
	case class'W_LAR_Pickup' :
	case class'W_LAW_Pick' :
	case class'W_M99_Pickup' :
	case class'W_MK23_Pickup' :
	case class'W_SCARMK17_Pickup' :
		return Texture'KFTurbo.HUD.NoSkinIcon_D';

	//Gold weapon
	case class'W_FlameThrower_Pick_G' :
	case class'W_V_AK47_Gold_Pickup' :
	case class'W_Deagle_Pickup_G' :
	case class'W_DualDeagle_Pickup_G' :
	case class'W_V_Katana_Gold_Pickup' :
	case class'W_V_Benelli_Gold_Pickup' :
		return Texture'KFTurbo.HUD.GoldIcon_D';

	//Camo weapon
	case class'W_V_M4203_Camo_Pickup' :
	case class'W_V_Shotgun_Camo_Pickup' :
	case class'W_V_MP5M_Camo_Pickup' :
	case class'W_V_M32_Camo_Pickup' :
		return Texture'KFTurbo.HUD.CamoIcon_D';

	//KFTurbo Stickers
	case class'W_V_AK47_Turbo_Pickup' :
	case class'W_V_FNFAL_Turbo_Pickup' :
	case class'W_V_LAR_Turbo_Pickup' :
	case class'W_V_LAW_Turbo_Pickup' :
	case class'W_V_M14_Turbo_Pickup' :
	case class'W_V_M32_Turbo_Pickup' :
	case class'W_V_M4203_Turbo_Pickup' :
	case class'W_V_M99_Turbo_Pickup' :
	case class'W_V_MK23_Turbo_Pickup' :
	case class'W_V_SCARMK17_Turbo_Pickup' :
		return Texture'KFTurbo.HUD.TurboIcon_D';

	//Invidual Stickers
	case class'W_V_M4203_Retart_Pickup' :
		return Texture'KFTurbo.HUD.LevelIcon_D';
	case class'W_V_M4203_Scuddles_Pickup' :
		return Texture'KFTurbo.HUD.ScrubblesIcon_D';
	case class'W_V_M14_Cubic_Pickup' :
		return Texture'KFTurbo.HUD.SkellIcon_D';
	case class'W_V_M14_SMP_Pickup' :
		return Texture'KFTurbo.HUD.ShowMeProIcon_D';
	case class'W_V_BlowerThrower_VM_Pickup' :
	case class'W_V_Katana_VM_Pickup' :
		return Texture'KFTurbo.HUD.VMIcon_D';
	case class'W_V_Shotgun_WL_Pickup' :
		return Texture'KFTurbo.HUD.WestLondonIcon_D';
	}

	return Texture'KFTurbo.HUD.StickerIcon_D';
}

static function String GetHintForPickup(class<Pickup> PickupClass)
{
	switch (PickupClass)
	{
	//Default weapon
	case class'W_FlameThrower_Pick' :
	case class'W_M4203_Pickup' :
	case class'W_M14_Pickup' :
	case class'W_Shotgun_Pickup' :
	case class'W_AK47_Pickup' :
	case class'W_Deagle_Pickup' :
	case class'W_DualDeagle_Pickup' :
	case class'W_Katana_Pickup' :
	case class'W_Benelli_Pickup' :
	case class'W_MP5M_Pickup' :
	case class'W_M32_Pickup' :
	case class'W_BlowerThrower_Pickup' :
	case class'W_FNFAL_Pickup' :
	case class'W_LAR_Pickup' :
	case class'W_LAW_Pick' :
	case class'W_M99_Pickup' :
	case class'W_MK23_Pickup' :
	case class'W_SCARMK17_Pickup' :
		return "Default";

	//Gold weapon
	case class'W_FlameThrower_Pick_G' :
	case class'W_V_AK47_Gold_Pickup' :
	case class'W_Deagle_Pickup_G' :
	case class'W_DualDeagle_Pickup_G' :
	case class'W_V_Katana_Gold_Pickup' :
	case class'W_V_Benelli_Gold_Pickup' :
		return "Gold";

	//Camo weapon
	case class'W_V_M4203_Camo_Pickup' :
	case class'W_V_Shotgun_Camo_Pickup' :
	case class'W_V_MP5M_Camo_Pickup' :
	case class'W_V_M32_Camo_Pickup' :
		return "Camo";
	}

	return "Sticker";
}

defaultproperties
{
     VariantData(0)=(WeaponPickup=Class'KFTurbo.W_FlameThrower_Pick',VariantClasses=(Class'KFTurbo.W_FlameThrower_Pick',Class'KFTurbo.W_FlameThrower_Pick_G'))
     VariantData(1)=(WeaponPickup=Class'KFTurbo.W_M4203_Pickup',VariantClasses=(Class'KFTurbo.W_M4203_Pickup',Class'KFTurbo.W_V_M4203_Camo_Pickup',Class'KFTurbo.W_V_M4203_Turbo_Pickup',Class'KFTurbo.W_V_M4203_Retart_Pickup',Class'KFTurbo.W_V_M4203_Scuddles_Pickup'))
     VariantData(2)=(WeaponPickup=Class'KFTurbo.W_M14_Pickup',VariantClasses=(Class'KFTurbo.W_M14_Pickup',Class'KFTurbo.W_V_M14_Turbo_Pickup',Class'KFTurbo.W_V_M14_Cubic_Pickup',Class'KFTurbo.W_V_M14_SMP_Pickup'))
     VariantData(3)=(WeaponPickup=Class'KFTurbo.W_Shotgun_Pickup',VariantClasses=(Class'KFTurbo.W_Shotgun_Pickup',Class'KFTurbo.W_V_Shotgun_Camo_Pickup',Class'KFTurbo.W_V_Shotgun_WL_Pickup'))
     VariantData(4)=(WeaponPickup=Class'KFTurbo.W_AK47_Pickup',VariantClasses=(Class'KFTurbo.W_AK47_Pickup',Class'KFTurbo.W_V_AK47_Gold_Pickup',Class'KFTurbo.W_V_AK47_Turbo_Pickup'))
     VariantData(5)=(WeaponPickup=Class'KFTurbo.W_Deagle_Pickup',VariantClasses=(Class'KFTurbo.W_Deagle_Pickup',Class'KFTurbo.W_Deagle_Pickup_G'))
     VariantData(6)=(WeaponPickup=Class'KFTurbo.W_DualDeagle_Pickup',VariantClasses=(Class'KFTurbo.W_DualDeagle_Pickup',Class'KFTurbo.W_DualDeagle_Pickup_G'))
     VariantData(7)=(WeaponPickup=Class'KFTurbo.W_Katana_Pickup',VariantClasses=(Class'KFTurbo.W_Katana_Pickup',Class'KFTurbo.W_V_Katana_Gold_Pickup',Class'KFTurbo.W_V_Katana_VM_Pickup'))
     VariantData(8)=(WeaponPickup=Class'KFTurbo.W_Benelli_Pickup',VariantClasses=(Class'KFTurbo.W_Benelli_Pickup',Class'KFTurbo.W_V_Benelli_Gold_Pickup'))
     VariantData(9)=(WeaponPickup=Class'KFTurbo.W_MP5M_Pickup',VariantClasses=(Class'KFTurbo.W_MP5M_Pickup',Class'KFTurbo.W_V_MP5M_Camo_Pickup'))
     VariantData(10)=(WeaponPickup=Class'KFTurbo.W_M32_Pickup',VariantClasses=(Class'KFTurbo.W_M32_Pickup',Class'KFTurbo.W_V_M32_Camo_Pickup',Class'KFTurbo.W_V_M32_Turbo_Pickup'))
     VariantData(11)=(WeaponPickup=Class'KFTurbo.W_BlowerThrower_Pickup',VariantClasses=(Class'KFTurbo.W_BlowerThrower_Pickup',Class'KFTurbo.W_V_BlowerThrower_VM_Pickup'))
     VariantData(12)=(WeaponPickup=Class'KFTurbo.W_FNFAL_Pickup',VariantClasses=(Class'KFTurbo.W_FNFAL_Pickup',Class'KFTurbo.W_V_FNFAL_Turbo_Pickup'))
     VariantData(13)=(WeaponPickup=Class'KFTurbo.W_LAR_Pickup',VariantClasses=(Class'KFTurbo.W_LAR_Pickup',Class'KFTurbo.W_V_LAR_Turbo_Pickup'))
     VariantData(14)=(WeaponPickup=Class'KFTurbo.W_LAW_Pick',VariantClasses=(Class'KFTurbo.W_LAW_Pick',Class'KFTurbo.W_V_LAW_Turbo_Pickup'))
     VariantData(15)=(WeaponPickup=Class'KFTurbo.W_M99_Pickup',VariantClasses=(Class'KFTurbo.W_M99_Pickup',Class'KFTurbo.W_V_M99_Turbo_Pickup'))
     VariantData(16)=(WeaponPickup=Class'KFTurbo.W_MK23_Pickup',VariantClasses=(Class'KFTurbo.W_MK23_Pickup',Class'KFTurbo.W_V_MK23_Turbo_Pickup'))
     VariantData(17)=(WeaponPickup=Class'KFTurbo.W_SCARMK17_Pickup',VariantClasses=(Class'KFTurbo.W_SCARMK17_Pickup',Class'KFTurbo.W_V_SCARMK17_Turbo_Pickup'))
     GroupSkins(0)=(Group=Default,Data=((Mask=3),(Index=1,Mask=7),(Index=2,Mask=3),(Index=3,Mask=3),(Index=4,Mask=7),(Index=5,Mask=3),(Index=6,Mask=3),(Index=7,Mask=3),(Index=8,Mask=3),(Index=9,Mask=3),(Index=10,Mask=7),(Index=11),(Index=12,Mask=3),(Index=13,Mask=3),(Index=14,Mask=3),(Index=15,Mask=3),(Index=16,Mask=3),(Index=17,Mask=3)))
     GroupSkins(1)=(Data=((Mask=255),(Index=1,Mask=255),(Index=2,Mask=255),(Index=3,Mask=255),(Index=4,Mask=255),(Index=5,Mask=255),(Index=6,Mask=255),(Index=7,Mask=255),(Index=8,Mask=255),(Index=9,Mask=255),(Index=10,Mask=255),(Index=11,Mask=255),(Index=12,Mask=255),(Index=13,Mask=255),(Index=14,Mask=255),(Index=15,Mask=255),(Index=16,Mask=255),(Index=17,Mask=255)))
     bOnlyRelevantToOwner=True
     bAlwaysRelevant=False
}

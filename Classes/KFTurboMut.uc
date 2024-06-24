//Core of the KFTurbo mod. Needed for UI changes (as well as some other functionality).
class KFTurboMut extends Mutator
	config(KFPro);

#exec obj load file="..\Animations\KFTurboContent.ukx" package=KFTurbo

var array<KFGameType.SpecialSquad> FinalSquads;			// Squads that spawn with the Patriarch
var array<KFGameType.SpecialSquad> ShortSpecialSquads;		// The special squad array for a short game
var array<KFGameType.SpecialSquad> NormalSpecialSquads;	// The special squad array for a normal game
var array<KFGameType.SpecialSquad> LongSpecialSquads;		// The special squad array for a long game

var KFPClassyGorefastHandler ClassyGorefastHandler;
var KFPRepLinkHandler RepLinkHandler;

var config String RepLinkSettingsClassString;
var class<KFTurboRepLinkSettings> RepLinkSettingsClass;
var KFTurboRepLinkSettings RepLinkSettings;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	if(Role == ROLE_Authority)
	{
		UpdateMonsters();

		if (!ClassIsChildOf(Level.Game.PlayerControllerClass, class'KFPPlayerController'))
		{
			Level.Game.PlayerControllerClass = class'KFPPlayerController';
			Level.Game.PlayerControllerClassName = string(class'KFPPlayerController');
		}

		DeathMatch(Level.Game).LoginMenuClass = string(class'KFPInvasionLoginMenu');

		//Every 5 seconds check if our queued spawn has a replaceable zed.
		ClassyGorefastHandler = Spawn(class'KFPClassyGorefastHandler', self);

		//Manages the creation of KFPRepLink for players joining.
		RepLinkHandler = Spawn(class'KFPRepLinkHandler', self);
	}
}

//Apply the monster collections, special squads, and anything else the gamemode needs to know about.
function UpdateMonsters()
{
	local KFGameType GameType;

	GameType = KFGameType(Level.Game);

	if(GameType == None)
	{
		return;
	}

	//If KFProGameType is being used, these operations can be ignored.
	if(KFProGameType(GameType) != None)
	{
		return;
	}

	GameType.SpecialEventMonsterCollections[0] = class'MC_DEF';
    GameType.SpecialEventMonsterCollections[1] = class'MC_SUM';
    GameType.SpecialEventMonsterCollections[2] = class'MC_HAL';
    GameType.SpecialEventMonsterCollections[3] = class'MC_XMA';

    GameType.MonsterCollection = GameType.SpecialEventMonsterCollections[GameType.GetSpecialEventType()];

    //I don't know why these squads are configured in KFProGameType but we'll do it.
    UpdateSpecialSquadList(GameType.ShortSpecialSquads, ShortSpecialSquads);
    UpdateSpecialSquadList(GameType.NormalSpecialSquads, NormalSpecialSquads);
    UpdateSpecialSquadList(GameType.LongSpecialSquads, LongSpecialSquads);
    UpdateSpecialSquadList(GameType.FinalSquads, FinalSquads);
}

//Helper function to adapt KFPro squad changes.
static final function UpdateSpecialSquadList(out array<KFGameType.SpecialSquad> ModifiedSquadList,  array<KFGameType.SpecialSquad> TargetSquadList)
{
	local int Index;

	if(ModifiedSquadList.Length < TargetSquadList.Length)
    {
		ModifiedSquadList.Length = TargetSquadList.Length;
    }

	for(Index = 0; Index < TargetSquadList.Length; Index++)
	{
		if(TargetSquadList[Index].ZedClass.Length == 0)
		{
			continue;
		}

		ModifiedSquadList[Index] = TargetSquadList[Index];
	}
}

//Called every time a ServerStStats is made (but we only want to do this once).
function InitializeKFPRepLinkSettings()
{
	if (RepLinkSettings != none)
	{
		return;
	}

	RepLinkSettingsClass = class<KFTurboRepLinkSettings>(DynamicLoadObject(RepLinkSettingsClassString, class'Class'));

	if (RepLinkSettingsClass == none)
	{
		RepLinkSettingsClass = class'KFTurboRepLinkSettings';
	}

	RepLinkSettings = new(self) RepLinkSettingsClass;
	RepLinkSettings.Initialize();
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	if (KFRandomItemSpawn(Other) != None)
	{
		UpdateRandomItemPickup(KFRandomItemSpawn(Other));
	}

	if (RepLinkHandler != none && ServerStStats(Other) != None)
	{
		InitializeKFPRepLinkSettings();
		RepLinkHandler.OnServerStatsAdded(ServerStStats(Other));
	}

	return true;
}

function UpdateRandomItemPickup(KFRandomItemSpawn PickupSpawner)
{
	//PickupSpawner.PickupClasses[0]=Class'KFTurbo.DualiesPickup'
	PickupSpawner.PickupClasses[1] = Class'W_Shotgun_Pickup';
	//PickupSpawner.PickupClasses[2]=Class'KFTurbo.BullpupPickup'
	PickupSpawner.PickupClasses[3] = Class'W_Deagle_Pickup';
	//PickupSpawner.PickupClasses[4]=Class'KFTurbo.WinchesterPickup'
	PickupSpawner.PickupClasses[5] = Class'W_Axe_Pickup';
	//PickupSpawner.PickupClasses[6]=Class'KFTurbo.MachetePickup'
	//PickupSpawner.PickupClasses[7]=Class'KFTurbo.Vest'
}

function ModifyPlayer(Pawn Other)
{
	Super.ModifyPlayer(Other);

	AddChatWatcher(Other);
}

function AddChatWatcher(Pawn Other)
{
	local ChatWatcher ChatWatcherInv;

	if (!Other.IsHumanControlled())
	{
		return;
	}

	ChatWatcherInv = Spawn(class'ChatWatcher', Other);

	if (ChatWatcherInv == None)
	{
		return;
	}

	Other.AddInventory(ChatWatcherInv);
}

function GetServerDetails(out GameInfo.ServerResponseLine ServerState)
{
	local int i;

	Super.GetServerDetails(ServerState);

	for (i = ServerState.ServerInfo.Length - 1; i >= 00; i--)
	{
		if (ServerState.ServerInfo[i].Key == "Veterancy" || Left(ServerState.ServerInfo[i].Key, 9) == "SP: Perk ")
		{
			ServerState.ServerInfo.Remove(i, 1);
		}
	}
}

defaultproperties
{
	FinalSquads(0)=(ZedClass=("KFTurbo.P_Clot_STA"),NumZeds=(4))
	FinalSquads(1)=(ZedClass=("KFTurbo.P_Clot_STA","KFTurbo.P_Crawler_STA"),NumZeds=(3,1))
	FinalSquads(2)=(ZedClass=("KFTurbo.P_Clot_STA","KFTurbo.P_Stalker_STA","KFTurbo.P_Crawler_STA"),NumZeds=(3,1,1))
	ShortSpecialSquads(2)=(ZedClass=("KFTurbo.P_Bloat_STA","KFTurbo.P_Siren_STA","KFTurbo.P_SC_STA","KFTurbo.P_FP_STA"),NumZeds=(1,2,1,1))
	ShortSpecialSquads(3)=(ZedClass=("KFTurbo.P_Bloat_STA","KFTurbo.P_Siren_STA","KFTurbo.P_SC_STA","KFTurbo.P_FP_STA"),NumZeds=(1,2,1,2))
	NormalSpecialSquads(3)=(ZedClass=("KFTurbo.P_FP_HAL"),NumZeds=(1))
	NormalSpecialSquads(4)=(ZedClass=("KFTurbo.P_Bloat_STA","KFTurbo.P_Siren_STA","KFTurbo.P_FP_STA"),NumZeds=(1,1,1))
	NormalSpecialSquads(5)=(ZedClass=("KFTurbo.P_Bloat_STA","KFTurbo.P_Siren_STA","KFTurbo.P_SC_STA","KFTurbo.P_FP_STA"),NumZeds=(1,2,1,1))
	NormalSpecialSquads(6)=(ZedClass=("KFTurbo.P_Bloat_STA","KFTurbo.P_Siren_STA","KFTurbo.P_SC_STA","KFTurbo.P_FP_STA"),NumZeds=(1,2,1,2))
	LongSpecialSquads(4)=(ZedClass=("KFTurbo.P_Crawler_STA","KFTurbo.P_Gorefast_XMA","KFTurbo.P_Stalker_STA","KFTurbo.P_SC_HAL"),NumZeds=(2,2,1,1))
	LongSpecialSquads(6)=(ZedClass=("KFTurbo.P_FP_HAL"),NumZeds=(1))
	LongSpecialSquads(7)=(ZedClass=("KFTurbo.P_Bloat_STA","KFTurbo.P_Siren_STA","KFTurbo.P_FP_STA"),NumZeds=(1,1,1))
	LongSpecialSquads(8)=(ZedClass=("KFTurbo.P_Bloat_STA","KFTurbo.P_Siren_STA","KFTurbo.P_SC_STA","KFTurbo.P_FP_STA"),NumZeds=(1,2,1,1))
	LongSpecialSquads(9)=(ZedClass=("KFTurbo.P_Bloat_STA","KFTurbo.P_Siren_STA","KFTurbo.P_SC_STA","KFTurbo.P_FP_STA"),NumZeds=(1,2,1,2))
	bAddToServerPackages=True
	GroupName="KF-KFTurboMut"
	FriendlyName="Killing Floor Turbo Mut"
	Description="Mutator for KFTurbo."
}
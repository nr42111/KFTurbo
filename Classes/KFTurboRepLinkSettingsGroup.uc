//Instance of a group for the usage of informing a KFPRepLink about unlocks for a given group of players.
class KFTurboRepLinkSettingsGroup extends Object;

var() string GroupID;
var() string DisplayName;

var() array<string> PlayerSteamIDList;
var() bool bDefaultGroup; //If true, all players are considered as in this group.

var() bool bUnlocksAll; //If true, this group unlocks all skins.

var() array<string> VariantIDList;

defaultproperties
{

}
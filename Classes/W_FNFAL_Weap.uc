class W_FNFAL_Weap extends FNFAL_ACOG_AssaultRifle;

simulated function DoToggle()
{

}

function ServerChangeFireMode(bool bNewWaitForRelease)
{

}

defaultproperties
{
     MagCapacity=12
     ReloadRate=3.200000
     ReloadAnimRate=1.125000
     FireModeClass(0)=Class'KFTurbo.W_FNFAL_Fire'
     PickupClass=Class'KFTurbo.W_FNFAL_Pickup'
}

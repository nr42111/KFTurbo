class W_Benelli_Weap extends BenelliShotgun;

var float CachedMagAmmoRemaining;

simulated function AddReloadedAmmo()
{
	Super.AddReloadedAmmo();

	ConditionallyRollBackReload();
}

simulated function WeaponTick(float dt)
{
	Super.WeaponTick(dt);

	if (Role < ROLE_Authority && CachedMagAmmoRemaining != MagAmmoRemaining)
	{
		ConditionallyRollBackReload();
		CachedMagAmmoRemaining = MagAmmoRemaining;
	}
}

simulated function ConditionallyRollBackReload()
{
	local Name SequenceName;
	local float OutFrame, OutRate;

	GetAnimParams(0, SequenceName, OutFrame, OutRate);

	OutFrame *= 174.f;

	if (SequenceName != ReloadAnim)
	{
		return;
	}

	if (OutFrame < 130.f)
	{
		return;
	}

	SetAnimFrame(OutFrame - 23.89, 0, 1);
}

defaultproperties
{
     MagCapacity=8
     FireModeClass(0)=Class'KFTurbo.W_Benelli_Fire'
     PickupClass=Class'KFTurbo.W_Benelli_Pickup'
     AttachmentClass=Class'KFTurbo.W_Benelli_Attachment'
}

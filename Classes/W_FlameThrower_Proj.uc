class W_FlameThrower_Proj extends FlameTendril;

var int BaseTime;

simulated function Timer()
{
	Velocity =  Default.Speed * Normal(Velocity);

	if ( Trail != none )
	{
		Trail.mSizeRange[0] *= 1.8;
		Trail.mSizeRange[1] *= 1.8;
	}

	if ( FlameTrail != none )
	{
		FlameTrail.SetDrawScale(FlameTrail.DrawScale * 1.5);
	}

	TimerRunCount++;
	if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
	{
		if ( TimerRunCount >= BaseTime + KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.ExtraRange(KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo)) )
		{
			Explode(Location,VRand());
		}
	}
	else if ( TimerRunCount >= BaseTime )
	{
		Explode(Location,VRand());
	}
}

defaultproperties
{
     BaseTime=2
     Damage=6.000000
}

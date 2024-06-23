class W_M4203_DT_Bullet extends DamTypeM4203AssaultRifle
	abstract;

static function AwardDamage(KFSteamStatsAndAchievements KFStatsAndAchievements, int Amount)
{
	KFStatsAndAchievements.AddBullpupDamage(Amount);
}

defaultproperties
{
     WeaponClass=Class'KFTurbo.W_M4203_Weap'
}

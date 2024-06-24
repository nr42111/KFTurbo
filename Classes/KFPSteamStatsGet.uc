Class KFPSteamStatsGet extends KFSteamStatsAndAchievements
	transient;

var KFPRepLink Link;

simulated event PostBeginPlay()
{
	PCOwner = Level.GetLocalPlayerController();
	Initialize(PCOwner);
	GetStatsAndAchievements();
}

simulated event PostNetBeginPlay();

simulated event OnStatsAndAchievementsReady()
{
	local int WeaponIndex, VariantIndex, WeaponLockID;
	local class<KFWeapon> WeaponClass;

	InitStatInt(OwnedWeaponDLC, GetOwnedWeaponDLC());

	for (WeaponIndex = Link.PlayerVariantList.Length - 1; WeaponIndex >= 0; --WeaponIndex)
	{
		for (VariantIndex = Link.PlayerVariantList[WeaponIndex].VariantList.Length - 1; VariantIndex >= 0; --VariantIndex)
		{
			WeaponClass = class<KFWeapon>(Link.PlayerVariantList[WeaponIndex].VariantList[VariantIndex].VariantClass.default.InventoryType);

			//Test DLC status.
			WeaponLockID = WeaponClass.default.AppID;
			if (WeaponLockID != 0)
			{
				if (PlayerOwnsWeaponDLC(WeaponLockID))
				{
					Link.PlayerVariantList[WeaponIndex].VariantList[VariantIndex].ItemStatus = 0;
				}
				else if (WeaponClass.default.UnlockedByAchievement != -1)
				{
					Link.PlayerVariantList[WeaponIndex].VariantList[VariantIndex].ItemStatus = 2;
				}
				else
				{
					Link.PlayerVariantList[WeaponIndex].VariantList[VariantIndex].ItemStatus = 1;
				}

				continue;
			}
			
			//Test achievement status.
			WeaponLockID = WeaponClass.default.UnlockedByAchievement;
			if (WeaponLockID != -1)
			{
				if (Achievements[WeaponLockID].bCompleted == 1)
				{
					Link.PlayerVariantList[WeaponIndex].VariantList[VariantIndex].ItemStatus = 0;
				}
				else
				{
					Link.PlayerVariantList[WeaponIndex].VariantList[VariantIndex].ItemStatus = 2;
				}

				continue;
			}

			Link.PlayerVariantList[WeaponIndex].VariantList[VariantIndex].ItemStatus = 0;
		}
	}

	//Link.DebugVariantInfo(false);

	UpdatePerkStats();

	LifeSpan = 1.f;
}

//Since we don't push these anymore, we need to do so now.
simulated function UpdatePerkStats()
{
	GetStatInt(DamageHealedStat, SteamNameStat[0]);
	SavedDamageHealedStat = DamageHealedStat.Value;
	PCOwner.ServerInitializeSteamStatInt(0, DamageHealedStat.Value);

	GetStatInt(WeldingPointsStat, SteamNameStat[1]);
	SavedWeldingPointsStat = WeldingPointsStat.Value;
	PCOwner.ServerInitializeSteamStatInt(1, WeldingPointsStat.Value);

	GetStatInt(ShotgunDamageStat, SteamNameStat[2]);
	SavedShotgunDamageStat = ShotgunDamageStat.Value;
	PCOwner.ServerInitializeSteamStatInt(2, ShotgunDamageStat.Value);

	GetStatInt(HeadshotKillsStat, SteamNameStat[3]);
	SavedHeadshotKillsStat = HeadshotKillsStat.Value;
	PCOwner.ServerInitializeSteamStatInt(3, HeadshotKillsStat.Value);

	GetStatInt(StalkerKillsStat, SteamNameStat[4]);
	SavedStalkerKillsStat = StalkerKillsStat.Value;
	PCOwner.ServerInitializeSteamStatInt(4, StalkerKillsStat.Value);

	GetStatInt(BullpupDamageStat, SteamNameStat[5]);
	SavedBullpupDamageStat = BullpupDamageStat.Value;
	PCOwner.ServerInitializeSteamStatInt(5, BullpupDamageStat.Value);

	GetStatInt(MeleeDamageStat, SteamNameStat[6]);
	SavedMeleeDamageStat = MeleeDamageStat.Value;
	PCOwner.ServerInitializeSteamStatInt(6, MeleeDamageStat.Value);

	GetStatInt(FlameThrowerDamageStat, SteamNameStat[7]);
	SavedFlameThrowerDamageStat = FlameThrowerDamageStat.Value;
	PCOwner.ServerInitializeSteamStatInt(7, FlameThrowerDamageStat.Value);

	GetStatInt(ExplosivesDamageStat, SteamNameStat[21]);
	SavedExplosivesDamageStat = ExplosivesDamageStat.Value;
	PCOwner.ServerInitializeSteamStatInt(21, ExplosivesDamageStat.Value);
}

defaultproperties
{
	RemoteRole=ROLE_None
	LifeSpan=10.000000
}

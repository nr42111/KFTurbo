class KFPHumanPawn extends SRHumanPawn;

function bool CanBuyPickup(class<Weapon> WClass)
{
	// Validate if allowed to buy that weapon.
	if (PerkLink == None)
		PerkLink = FindStats();
	if (PerkLink != None && !PerkLink.CanBuyPickup(GetCorrectedWeaponPickup(WClass.Default.PickupClass)))
		return false;

	return true;
}

static final function class<KFWeaponPickup> GetCorrectedWeaponPickup(class<Pickup> PickupClass)
{
	local class<KFWeaponPickup> WeaponPickup;

	WeaponPickup = Class<KFWeaponPickup>(PickupClass);

	if (WeaponPickup.default.VariantClasses.Length > 0 && WeaponPickup.default.VariantClasses[0] != None)
	{
		return class<KFWeaponPickup>(WeaponPickup.default.VariantClasses[0]);
	}

	return WeaponPickup;
}

function ServerBuyWeapon( Class<Weapon> WClass, float Weight )
{
	local float Price;
	local int OtherPrice;
	local int Index;
	local Inventory I,OI;
	local class<KFWeapon> SecType;
	local class<KFWeaponPickup> WeaponPickup;

	if( !CanBuyNow() || Class<KFWeapon>(WClass)==None || Class<KFWeaponPickup>(WClass.Default.PickupClass)==None || HasWeaponClass(WClass) )
		Return;

	if (!CanBuyPickup(WClass))
	{
		return;
	}

	WeaponPickup = class<KFWeaponPickup>(WClass.Default.PickupClass);

	Price = WeaponPickup.Default.Cost;

	if ( KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill != none )
		Price *= KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.GetCostScaling(KFPlayerReplicationInfo(PlayerReplicationInfo), GetCorrectedWeaponPickup(WClass.Default.PickupClass));

	Weight = Class<KFWeapon>(WClass).Default.Weight;

	if( class'DualWeaponsManager'.Static.IsDualWeapon(WClass,SecType) )
	{
		if( WClass!=class'Dualies' && HasWeaponClass(SecType,OI) )
		{
			Weight-=SecType.Default.Weight;
			Price*=0.5f;
			OtherPrice = KFWeapon(OI).SellValue;
			if( OtherPrice==-1 )
			{
				OtherPrice = class<KFWeaponPickup>(SecType.Default.PickupClass).Default.Cost * 0.75;
				if ( KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill != none )
					OtherPrice *= KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.GetCostScaling(KFPlayerReplicationInfo(PlayerReplicationInfo), SecType.Default.PickupClass);
			}
		}
		else if (WeaponPickup.default.VariantClasses.Length > 0)
		{
			for (Index = 0; Index < WeaponPickup.default.VariantClasses.Length; Index++)
			{
				if (class'DualWeaponsManager'.Static.IsDualWeapon(class<Weapon>(WeaponPickup.default.VariantClasses[Index].default.InventoryType), SecType))
				{
					if (class<Weapon>(WeaponPickup.default.VariantClasses[Index].default.InventoryType) != class'Dualies' && HasWeaponClass(SecType, OI))
					{
						Weight -= SecType.Default.Weight;
						Price *= 0.5f;
						OtherPrice = KFWeapon(OI).SellValue;
						if (OtherPrice == -1)
						{
							OtherPrice = class<KFWeaponPickup>(SecType.Default.PickupClass).Default.Cost * 0.75;
							if (KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill != none)
								OtherPrice *= KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.GetCostScaling(KFPlayerReplicationInfo(PlayerReplicationInfo), SecType.Default.PickupClass);
						}

						break;
					}
				}
				else if (class'DualWeaponsManager'.Static.HasDualies(class<Weapon>(WeaponPickup.default.VariantClasses[Index].default.InventoryType), Inventory))
					return;
			}
		}
	}
	else if( class'DualWeaponsManager'.Static.HasDualies(WClass,Inventory) )
		return;

	Price = int(Price); // Truncuate price.

	if( Weight>0 && !CanCarry(Weight) )
	{
		ClientMessage("Error: "$WClass.Name$" is too heavy ("$CurrentWeight$"+"$Weight$">"$MaxCarryWeight$")");
		return;
	}
	if ( PlayerReplicationInfo.Score<Price )
	{
		ClientMessage("Error: "$WClass.Name$" is too expensive ("$int(Price)$">"$int(PlayerReplicationInfo.Score)$")");
		Return;
	}

	I = Spawn(WClass);
	if ( I != none )
	{
		if ( KFGameType(Level.Game) != none )
			KFGameType(Level.Game).WeaponSpawned(I);

		KFWeapon(I).UpdateMagCapacity(PlayerReplicationInfo);
		KFWeapon(I).FillToInitialAmmo();
		KFWeapon(I).SellValue = Price * 0.75;
		if( OtherPrice>0 )
			KFWeapon(I).SellValue+=OtherPrice;
		I.GiveTo(self);
		PlayerReplicationInfo.Score -= Price;
        ClientForceChangeWeapon(I);
    }
	else ClientMessage("Error: "$WClass.Name$" failed to spawn.");

	SetTraderUpdate();
}


function bool ServerBuyAmmo(Class<Ammunition> AClass, bool bOnlyClip)
{
	local Inventory I;
	local float Price;
	local Ammunition AM;
	local KFWeapon KW;
	local int c;
	local float UsedMagCapacity;
	local Boomstick DBShotty;

	if (!CanBuyNow() || AClass == None)
	{
		SetTraderUpdate();
		return false;
	}

	for (I = Inventory; I != none; I = I.Inventory)
	{
		if (I.Class == AClass)
		{
			AM = Ammunition(I);
		}
		else if (KW == None && KFWeapon(I) != None && (Weapon(I).AmmoClass[0] == AClass || Weapon(I).AmmoClass[1] == AClass))
		{
			KW = KFWeapon(I);
		}
	}

	if (KW == none || AM == none)
	{
		SetTraderUpdate();
		return false;
	}

	DBShotty = Boomstick(KW);

	AM.MaxAmmo = AM.default.MaxAmmo;

	if (KFPlayerReplicationInfo(PlayerReplicationInfo) != none && KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill != none)
	{
		AM.MaxAmmo = int(float(AM.MaxAmmo) * KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.AddExtraAmmoFor(KFPlayerReplicationInfo(PlayerReplicationInfo), AClass));
	}

	if (AM.AmmoAmount >= AM.MaxAmmo)
	{
		SetTraderUpdate();
		return false;
	}

	Price = class<KFWeaponPickup>(KW.PickupClass).default.AmmoCost * KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.GetAmmoCostScaling(KFPlayerReplicationInfo(PlayerReplicationInfo), GetCorrectedWeaponPickup(KW.PickupClass)); // Clip price.

	if (KW.bHasSecondaryAmmo && AClass == KW.FireModeClass[1].default.AmmoClass)
	{
		UsedMagCapacity = 1; // Secondary Mags always have a Mag Capacity of 1? KW.default.SecondaryMagCapacity;
	}
	else
	{
		UsedMagCapacity = KW.default.MagCapacity;
	}

	if (KW.PickupClass == class'HuskGunPickup')
	{
		UsedMagCapacity = class<HuskGunPickup>(KW.PickupClass).default.BuyClipSize;
	}

	if (bOnlyClip)
	{
		if (KFPlayerReplicationInfo(PlayerReplicationInfo) != none && KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill != none)
		{
			if (KW.PickupClass == class'HuskGunPickup')
			{
				c = UsedMagCapacity * KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.AddExtraAmmoFor(KFPlayerReplicationInfo(PlayerReplicationInfo), AM.Class);
			}
			else
			{
				c = UsedMagCapacity * KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.GetMagCapacityMod(KFPlayerReplicationInfo(PlayerReplicationInfo), KW);
			}
		}
		else
		{
			c = UsedMagCapacity;
		}
	}
	else
	{
		c = (AM.MaxAmmo - AM.AmmoAmount);
	}

	Price = int(float(c) / UsedMagCapacity * Price);

	if (PlayerReplicationInfo.Score < Price) // Not enough CASH (so buy the amount you CAN buy).
	{
		c *= (PlayerReplicationInfo.Score / Price);

		if (c == 0)
		{
			SetTraderUpdate();
			return false; // Couldn't even afford 1 bullet.
		}

		AM.AddAmmo(c);
		if (DBShotty != none)
		{
			DBShotty.AmmoPickedUp();
		}

		PlayerReplicationInfo.Score = Max(PlayerReplicationInfo.Score - (float(c) / UsedMagCapacity * Price), 0);

		SetTraderUpdate();

		return false;
	}

	PlayerReplicationInfo.Score = int(PlayerReplicationInfo.Score - Price);
	AM.AddAmmo(c);
	if (DBShotty != none)
	{
		DBShotty.AmmoPickedUp();
	}

	SetTraderUpdate();

	return true;
}

simulated event SetAnimAction(name NewAction)
{
	Super.SetAnimAction(NewAction);
}

defaultproperties
{
}

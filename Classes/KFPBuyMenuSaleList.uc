//A rewrite to change how buying custom skins works.
class KFPBuyMenuSaleList extends SRBuyMenuSaleList
	config(KFProTrader); //uses config to persist user selection (due to inherent volatility of GUI items)

var	Texture	ButtonTexture;
var	Texture	ButtonHoverTexture;
var	Texture	ButtonDisabledTexture;

var	Texture	NoSkinTexture;
var	Texture	GoldSkinTexture;
var	Texture	StickerSkinTexture;
var	Texture CamoSkinTexture;
var Texture LockedDLCTexture;

enum EVariantType
{
	Default,
	
	//Vanilla KF Skins
	Gold,
	Camo,
	Neon,
	
	//Built-in Skins
	Sticker,
	Paint,
	
	//Custom
	Custom1,
	Custom2,
	Custom3,
	Custom4
};

struct HoverCacheInfo
{
	var int LastKnownMouseOverIndex;
	var int LastKnownMouseOverSubIndex;
};
var HoverCacheInfo HoverCache;

var int MouseOverSubIndex;

//Used soley to be compliant with how DrawInvItem is implemented.
struct VariantListContainer
{
	var array< class<Pickup> > Variants;
	var array< byte> VariantStatus;
	var int Selection;
};
var array<VariantListContainer> VariantClasses;

struct StoredVariantSelection
{
	var class<KFWeapon> WeaponClass;
	var int Selection;
};
var config array<StoredVariantSelection> VariantSelection;

struct ButtonExtent
{
	var bool bLocked;
	var float ButtonLocation[2];
	var float ButtonSize[2];
};

var array<ButtonExtent> ItemButtonList;

event Closed(GUIComponent Sender, bool bCancelled)
{
	Super.Closed(Sender, bCancelled);
}

function StoreVariantSelection(class<KFWeapon> WeaponClass, int Selection)
{
	local int i;

	for (i = 0; i < VariantSelection.Length; i++)
	{
		if (VariantSelection[i].WeaponClass == WeaponClass)
		{
			VariantSelection[i].Selection = Selection;
			SaveConfig();
			return;
		}
	}

	VariantSelection.Length = VariantSelection.Length + 1;
	VariantSelection[VariantSelection.Length - 1].WeaponClass = WeaponClass;
	VariantSelection[VariantSelection.Length - 1].Selection = Selection;
	SaveConfig();
}

function int GetVariantSelection(class<KFWeapon> WeaponClass)
{
	local int i;

	for (i = 0; i < VariantSelection.Length; i++)
	{
		if (VariantSelection[i].WeaponClass == WeaponClass)
		{
			return VariantSelection[i].Selection;
		}
	}

	return -1;
}

function bool InternalOnClick(GUIComponent Sender)
{
	if (!Super.InternalOnClick(Sender))
	{
		return false;
	}
	
	UpdateSelectedAlternateSkin(Sender);

	return false;
}

function UpdateSelectedAlternateSkin(GUIComponent Sender)
{
	local KFPGUIBuyable Buyable;
	local int ButtonIndex;

	Buyable = KFPGUIBuyable(GetSelectedBuyable());

	if (MouseOverIndex != Index)
	{
		return;
	}

	if (MouseOverIndex == -1 || MouseOverIndex >= CanBuys.Length)
	{
		return;
	}

	log(CanBuys[MouseOverIndex]);

	if (CanBuys[MouseOverIndex] < 1)
	{
		return;
	}

	if (!HasAlternateSkin(Buyable))
	{
		if (Buyable != None)
		{
			Buyable.VariantSelection = -1;
		}
		return;
	}

	ButtonIndex = GetButtonIndex(Buyable);

	if (ButtonIndex != -1)
	{
		Buyable.VariantSelection = ButtonIndex;
	}

	StoreVariantSelection(Buyable.ItemWeaponClass, Buyable.VariantSelection);
	UpdateList();

	if (bNotify)
	{
		OnChange(Sender);
	}
}

function int GetButtonIndex(optional KFPGUIBuyable Buyable)
{
	local int i;
	local float X, Y;

	for (i = 0; i < ItemButtonList.Length; i++)
	{
		X = ItemButtonList[i].ButtonLocation[0];
		Y = ItemButtonList[i].ButtonLocation[1];

		if (Controller.MouseX < X || Controller.MouseX > X + ItemButtonList[i].ButtonSize[0])
		{
			continue;
		}

		if (Controller.MouseY < Y || Controller.MouseY > Y + ItemButtonList[i].ButtonSize[1])
		{
			continue;
		}

		if (ItemButtonList[i].bLocked)
		{
			PlayerOwner().SteamStatsAndAchievements.PurchaseWeaponDLC(class<KFWeapon>(Buyable.VariantClasses[i].default.InventoryType).default.AppID);
			return -1;
		}

		return i;
	}

	return -1;
}

static function bool HasAlternateSkin(KFPGUIBuyable Buyable)
{
	if (Buyable == None || Buyable.VariantClasses.Length == 0)
	{
		return false;
	}

	return true;
}

static function VariantListContainer GetAlternateSkins(KFPGUIBuyable Buyable)
{
	local VariantListContainer VariantContainer;

	if (Buyable == None)
	{
		VariantContainer.Variants.Length = 0;
		VariantContainer.VariantStatus.Length = 0;
		VariantContainer.Selection = -1;
		return VariantContainer;
	}

	VariantContainer.Variants = Buyable.VariantClasses;
	VariantContainer.VariantStatus = Buyable.VariantStatus;
	VariantContainer.Selection = Buyable.VariantSelection;

	return VariantContainer;
}

function bool PreDraw(Canvas Canvas)
{
	local bool bReturn;
	local bool bUpdateHint;
	bReturn = Super.PreDraw(Canvas);

	bUpdateHint = HoverCache.LastKnownMouseOverIndex != MouseOverIndex || HoverCache.LastKnownMouseOverSubIndex != MouseOverSubIndex;

	if (bUpdateHint)
	{
		if (MouseOverIndex == -1 || MouseOverSubIndex == -1 || MouseOverIndex >= CanBuys.Length || CanBuys[MouseOverIndex] < 1)
		{
			SetHint("");
		}
		else
		{
			if (VariantClasses[MouseOverIndex].Variants.Length > MouseOverSubIndex)
			{
				SetHint(GetButtonHint(VariantClasses[MouseOverIndex].Variants[MouseOverSubIndex]));
			}
			else
			{
				SetHint("");
			}
		}

		HoverCache.LastKnownMouseOverIndex = MouseOverIndex;
		HoverCache.LastKnownMouseOverSubIndex = MouseOverSubIndex;
	}

	return bReturn;
}

function DrawInvItem(Canvas Canvas, int CurIndex, float X, float Y, float Width, float Height, bool bSelected, bool bPending)
{
	Super.DrawInvItem(Canvas, CurIndex, X, Y, Width, Height, bSelected, bPending);

	if (CanBuys[CurIndex] < 2 && VariantClasses[CurIndex].Variants.Length != 0)
	{
		DrawAlternateSkinButtons(Canvas, CurIndex, X, Y, Width, Height, bSelected, bPending);
	}

	Canvas.SetDrawColor(255, 255, 255, 255);
}

function DrawAlternateSkinButtons(Canvas Canvas, int CurIndex, float X, float Y, float Width, float Height, bool bSelected, bool bPending)
{
	local float TextX, TextY;
	local float ButtonSize;
	local int i;
	local float TempX, TempY;
	local bool bHovered, bSubButtonHovered;
	local ButtonExtent ItemButton;
	local ClientPerkRepLink CPRL;

	CPRL = Class'ClientPerkRepLink'.Static.FindStats(PlayerOwner());

	//Update bounds data to what's relevant to use.
	//Handle perk icon space
	X += ((Height - ItemSpacing) - 1);
	Width -= ((Height - ItemSpacing) - 1);

	//Handle text spacer
	X += (0.2 * Height);
	Width -= (0.2 * Height);

	Canvas.TextSize(PrimaryStrings[CurIndex], TextX, TextY);

	//Handle item name text
	X += TextX;
	Width -= TextX;

	Canvas.TextSize(SecondaryStrings[CurIndex], TextX, TextY);

	//Handle item price text
	Width -= (0.2 * Height);
	Width -= TextX;

	//Allow for further spacing
	X += (0.2 * Height);
	Width -= (0.4 * Height);

	Height -= 12.f;
	Y += 6.f;

	ButtonSize = FMin(Width / VariantClasses[CurIndex].Variants.Length, Height * 0.7) - 0.05f;

	TempX = X + Width;
	TempY = Y + (Height * 0.5f) - (ButtonSize * 0.5f);

	Canvas.SetDrawColor(255, 255, 255, 255);

	//Prepare for extent tests on sub buttons
	if (CurIndex == MouseOverIndex)
	{
		bHovered = true;
		ItemButton.ButtonSize[0] = ButtonSize;
		ItemButton.ButtonSize[1] = ButtonSize;
		ItemButtonList.Length = 0;
		MouseOverSubIndex = -1;
	}

	for (i = 0; i < VariantClasses[CurIndex].Variants.Length; i++)
	{
		TempX -= ButtonSize;
		Canvas.SetPos(TempX, TempY);
		bSubButtonHovered = false;

		if (bHovered)
		{
			ItemButton.bLocked = VariantClasses[CurIndex].VariantStatus[i] != 0;
			ItemButton.ButtonLocation[0] = TempX;
			ItemButton.ButtonLocation[1] = TempY;

			ItemButtonList[ItemButtonList.Length] = ItemButton;

			if (IsSkinButtonHovered(ItemButton, Controller.MouseX, Controller.MouseY))
			{
				bSubButtonHovered = true;
				MouseOverSubIndex = i;
			}
		}
		
		if (CanBuys[CurIndex] != 1)
		{
			Canvas.SetDrawColor(50, 50, 50, 150);
			Canvas.DrawTileStretched(ButtonDisabledTexture, ButtonSize, ButtonSize);
			Canvas.SetDrawColor(200, 200, 200, 100);
		}
		else if (VariantClasses[CurIndex].VariantStatus[i] != 0)
		{
			Canvas.DrawTileStretched(ButtonDisabledTexture, ButtonSize, ButtonSize);
			Canvas.SetDrawColor(200, 200, 200, 100);
		}
		else if ((i == 0 && VariantClasses[CurIndex].Selection == -1) || i == VariantClasses[CurIndex].Selection) //If we don't have a selection, highlight the default.
		{
			Canvas.DrawTileStretched(ButtonTexture, ButtonSize, ButtonSize);
		}
		else if (bHovered && bSubButtonHovered)
		{
			Canvas.DrawTileStretched(ButtonHoverTexture, ButtonSize, ButtonSize);
		}
		else
		{
			Canvas.DrawTileStretched(ButtonDisabledTexture, ButtonSize, ButtonSize);
		}

		if (CanBuys[CurIndex] == 1)
		{
			Canvas.SetDrawColor(255, 255, 255, 255);
		}

		if (GetButtonTexture(VariantClasses[CurIndex].Variants[i]) != None)
		{
			Canvas.DrawRect(GetButtonTexture(VariantClasses[CurIndex].Variants[i]), ButtonSize, ButtonSize);
		}

		if (VariantClasses[CurIndex].VariantStatus[i] != 0)
		{
			Canvas.SetPos(TempX, TempY);
			Canvas.DrawRect(LockedDLCTexture, ButtonSize, ButtonSize);
		}

		TempX -= 2.f;
	}
}

static final function bool IsSkinButtonHovered(out ButtonExtent Button, float MouseX, float MouseY)
{
	if (Button.ButtonLocation[0] > MouseX || Button.ButtonLocation[0] + Button.ButtonSize[0] < MouseX)
	{
		return false;
	}

	if (Button.ButtonLocation[1] > MouseY || Button.ButtonLocation[1] + Button.ButtonSize[1] < MouseY)
	{
		return false;
	}

	return true;
}

//MODIFICATION TO GUIBUYABLE
//We have to completely copy paste the following functions to make minute changes...
final function KFPGUIBuyable AllocateKFPEntry(ClientPerkRepLink L)
{
	local KFPGUIBuyable NewBuyable;
	local int i;

	//Since potentially not all of these are the type we're looking for...
	for (i = 0; i < L.AllocatedObjects.Length; i++)
	{
		NewBuyable = KFPGUIBuyable(L.AllocatedObjects[i]);

		if (NewBuyable != None)
		{
			L.AllocatedObjects.Remove(i, 1);
			break;
		}
	}

	if (NewBuyable == None)
	{
		return new Class'KFPGUIBuyable';
	}

	L.ResetItem(NewBuyable);

	NewBuyable.VariantClasses.Length = 0;
	NewBuyable.VariantSelection = -1;
	
	return NewBuyable;
}

function UpdateForSaleBuyables()
{
	local class<KFVeterancyTypes> PlayerVeterancy;
	local KFPlayerReplicationInfo KFPRI;
	local ClientPerkRepLink CPRL;
	local KFPRepLink KFPL;
	local KFPGUIBuyable ForSaleBuyable;
	local class<KFWeaponPickup> ForSalePickup;
	local int j, DualDivider, i, Num, z, PerkSaleOffset;
	local class<KFWeapon> ForSaleWeapon, SecType;
	local class<SRVeterancyTypes> Blocker;
	local KFShopVolume_Story CurrentShop;
	local byte DLCLocked;

	// Clear the ForSaleBuyables array
	CopyAllBuyables();
	ForSaleBuyables.Length = 0;

	// Grab the items for sale
	CPRL = Class'ClientPerkRepLink'.Static.FindStats(PlayerOwner());
	if (CPRL == None)
		return; // Hmmmm?

	KFPL = class'KFPRepLink'.static.GetKFPRepLink(PlayerOwner().PlayerReplicationInfo);

	KFPRI = KFPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo);

	// Grab Players Veterancy for quick reference
	if (KFPRI != none)
	{
		PlayerVeterancy = KFPRI.ClientVeteranSkill;
	}

	if (PlayerVeterancy == None)
	{
		PlayerVeterancy = class'KFVeterancyTypes';
	}

	CurrentShop = GetCurrentShop();

	// Grab the weapons!
	if (ActiveCategory >= -1)
	{
		if (CurrentShop != None)
			Num = CurrentShop.SaleItems.Length;
		else Num = CPRL.ShopInventory.Length;
		for (z = 0; z < Num; z++)
		{
			if (CurrentShop != None)
			{
				// Allow story mode volume limit weapon availability.
				ForSalePickup = class<KFWeaponPickup>(CurrentShop.SaleItems[z]);
				if (ForSalePickup == None)
					continue;
				for (j = (CPRL.ShopInventory.Length - 1); j >= CPRL.ShopInventory.Length; --j)
					if (CPRL.ShopInventory[j].PC == ForSalePickup)
						break;
				if (j < 0)
					continue;
			}
			else
			{
				ForSalePickup = class<KFWeaponPickup>(CPRL.ShopInventory[z].PC);
				j = z;
			}

			if (ForSalePickup == None || class<KFWeapon>(ForSalePickup.default.InventoryType) == None || class<KFWeapon>(ForSalePickup.default.InventoryType).default.bKFNeverThrow
				|| IsInInventory(ForSalePickup))
				continue;
			if (ActiveCategory == -1)
			{
				if (!Class'SRClientSettings'.Static.IsFavorite(ForSalePickup))
					continue;
			}
			else if (ActiveCategory != CPRL.ShopInventory[j].CatNum)
				continue;

			// Remove single weld.
			ForSaleWeapon = class<KFWeapon>(ForSalePickup.default.InventoryType);

			if (class'DualWeaponsManager'.Static.HasDualies(ForSaleWeapon, PlayerOwner().Pawn.Inventory) || (ForSalePickup.Default.VariantClasses.Length > 0 && CheckGoldGunAvailable(ForSalePickup)))
			{
				continue;
			}
			else if (ForSalePickup.default.VariantClasses.Length > 0) //We need to check if ANY of the variants of this weapon in their dual forms is being held
			{
				Blocker = None;
				for (i = 0; i < ForSalePickup.default.VariantClasses.Length; i++)
				{
					ForSaleWeapon = class<KFWeapon>(ForSalePickup.default.VariantClasses[i].default.InventoryType);

					if (class'DualWeaponsManager'.Static.HasDualies(ForSaleWeapon, PlayerOwner().Pawn.Inventory) || (ForSalePickup.Default.VariantClasses.Length > 0 && CheckGoldGunAvailable(ForSalePickup)))
					{
						Blocker = class'SRVeterancyTypes'; //set it to not null for tracking purposes
						break;
					}
				}

				if (Blocker != None)
				{
					continue;
				}

				ForSaleWeapon = class<KFWeapon>(ForSalePickup.default.InventoryType);
			}

			DualDivider = 1;

			// Make cheaper.
			if (ForSaleWeapon != class'Dualies' && class'DualWeaponsManager'.Static.IsDualWeapon(ForSaleWeapon, SecType) && IsInInventoryWep(SecType))
			{
				DualDivider = 2;
			}
			else if (ForSalePickup.default.VariantClasses.Length > 0) //We need to check if ANY of the variants of this weapon in their single form is being held
			{
				for (i = 0; i < ForSalePickup.default.VariantClasses.Length; i++)
				{
					ForSaleWeapon = class<KFWeapon>(ForSalePickup.default.VariantClasses[i].default.InventoryType);

					if (ForSaleWeapon != class'Dualies' && class'DualWeaponsManager'.Static.IsDualWeapon(ForSaleWeapon, SecType) && IsInInventoryWep(SecType))
					{
						DualDivider = 2;
						break;
					}
				}

				ForSaleWeapon = class<KFWeapon>(ForSalePickup.default.InventoryType);
			}

			Blocker = None;
			for (i = 0; i < CPRL.CachePerks.Length; ++i)
				if (!CPRL.CachePerks[i].PerkClass.Static.AllowWeaponInTrader(ForSalePickup, KFPRI, CPRL.CachePerks[i].CurrentLevel))
				{
					Blocker = CPRL.CachePerks[i].PerkClass;
					break;
				}
			if (Blocker != None && Blocker.Default.DisableTag == "")
				continue;

			ForSaleBuyable = AllocateKFPEntry(CPRL);

			ForSaleBuyable.ItemName = ForSalePickup.default.ItemName;
			ForSaleBuyable.ItemDescription = ForSalePickup.default.Description;
			ForSaleBuyable.ItemImage = ForSaleWeapon.default.TraderInfoTexture;
			ForSaleBuyable.ItemWeaponClass = ForSaleWeapon;
			ForSaleBuyable.ItemAmmoClass = ForSaleWeapon.default.FireModeClass[0].default.AmmoClass;
			ForSaleBuyable.ItemPickupClass = ForSalePickup;
			ForSaleBuyable.ItemCost = int((float(ForSalePickup.default.Cost)
				* PlayerVeterancy.static.GetCostScaling(KFPRI, ForSalePickup)) / DualDivider);
			ForSaleBuyable.ItemAmmoCost = 0;
			ForSaleBuyable.ItemFillAmmoCost = 0;

			if (KFPL != None)
			{
				KFPL.GetVariantsForWeapon(ForSalePickup, ForSaleBuyable.VariantClasses, ForSaleBuyable.VariantStatus);
			}
			else
			{
				ForSaleBuyable.VariantClasses = ForSalePickup.default.VariantClasses;
			}

			ForSaleBuyable.VariantSelection = Clamp(GetVariantSelection(ForSaleWeapon), 0, ForSaleBuyable.VariantClasses.Length - 1);

			ForSaleBuyable.ItemWeight = ForSaleWeapon.default.Weight;
			if (DualDivider == 2)
				ForSaleBuyable.ItemWeight -= SecType.Default.Weight;

			ForSaleBuyable.ItemPower = ForSalePickup.default.PowerValue;
			ForSaleBuyable.ItemRange = ForSalePickup.default.RangeValue;
			ForSaleBuyable.ItemSpeed = ForSalePickup.default.SpeedValue;
			ForSaleBuyable.ItemAmmoMax = 0;
			ForSaleBuyable.ItemPerkIndex = ForSalePickup.default.CorrespondingPerkIndex;

			// Make sure we mark the list as a sale list
			ForSaleBuyable.bSaleList = true;

			// Sort same perk weapons in front.
			if (ForSalePickup.default.CorrespondingPerkIndex == PlayerVeterancy.default.PerkIndex)
			{
				ForSaleBuyables.Insert(PerkSaleOffset, 1);
				i = PerkSaleOffset++;
			}
			else
			{
				i = ForSaleBuyables.Length;
				ForSaleBuyables.Length = i + 1;
			}
			ForSaleBuyables[i] = ForSaleBuyable;
			DLCLocked = CPRL.ShopInventory[j].bDLCLocked;
			if (DLCLocked == 0 && Blocker != None)
			{
				ForSaleBuyable.ItemCategorie = Blocker.Default.DisableTag$":"$Blocker.Default.DisableDescription;
				DLCLocked = 3;
			}
			ForSaleBuyable.ItemAmmoCurrent = DLCLocked; // DLC info.
		}
	}

	// Now Update the list
	UpdateList();
}

function UpdateList()
{
	local int i, j;
	local ClientPerkRepLink CPRL;

	CPRL = Class'ClientPerkRepLink'.Static.FindStats(PlayerOwner());

	// Update the ItemCount and select the first item
	ItemCount = CPRL.ShopCategories.Length + ForSaleBuyables.Length + 1;

	// Clear the arrays
	if (ForSaleBuyables.Length < PrimaryStrings.Length)
	{
		PrimaryStrings.Length = ItemCount;
		SecondaryStrings.Length = ItemCount;
		CanBuys.Length = ItemCount;
		ListPerkIcons.Length = ItemCount;
		VariantClasses.Length = ItemCount;
	}

	// Update categories
	if (ActiveCategory >= -1)
	{
		for (i = -1; i < (ActiveCategory + 1); ++i)
		{
			if (i == -1)
			{
				PrimaryStrings[j] = FavoriteGroupName;
				ListPerkIcons[j] = None;
			}
			else
			{
				PrimaryStrings[j] = CPRL.ShopCategories[i].Name;
				if (CPRL.ShopCategories[i].PerkIndex < CPRL.ShopPerkIcons.Length)
					ListPerkIcons[j] = CPRL.ShopPerkIcons[CPRL.ShopCategories[i].PerkIndex];
				else ListPerkIcons[j] = None;
			}
			CanBuys[j] = 3 + i;
			++j;
		}
	}
	else
	{
		PrimaryStrings[j] = FavoriteGroupName;
		CanBuys[j] = 2;
		++j;
		for (i = 0; i < CPRL.ShopCategories.Length; ++i)
		{
			PrimaryStrings[j] = CPRL.ShopCategories[i].Name;
			if (CPRL.ShopCategories[i].PerkIndex < CPRL.ShopPerkIcons.Length)
				ListPerkIcons[j] = CPRL.ShopPerkIcons[CPRL.ShopCategories[i].PerkIndex];
			else ListPerkIcons[j] = None;
			CanBuys[j] = 3 + i;
			++j;
		}
	}

	// Update the players inventory list
	for (i = 0; i < ForSaleBuyables.Length; i++)
	{
		PrimaryStrings[j] = ForSaleBuyables[i].ItemName;
		SecondaryStrings[j] = "£" @ int(ForSaleBuyables[i].ItemCost);

		VariantClasses[j] = GetAlternateSkins(KFPGUIBuyable(ForSaleBuyables[i]));

		if (ForSaleBuyables[i].ItemPerkIndex < CPRL.ShopPerkIcons.Length)
			ListPerkIcons[j] = CPRL.ShopPerkIcons[ForSaleBuyables[i].ItemPerkIndex];
		else ListPerkIcons[j] = None;

		if (ForSaleBuyables[i].ItemAmmoCurrent != 0)
		{
			CanBuys[j] = 0;
			if (ForSaleBuyables[i].ItemAmmoCurrent == 1)
				SecondaryStrings[j] = "DLC";
			else if (ForSaleBuyables[i].ItemAmmoCurrent == 2)
				SecondaryStrings[j] = "LOCKED";
			else SecondaryStrings[j] = Left(ForSaleBuyables[i].ItemCategorie, InStr(ForSaleBuyables[i].ItemCategorie, ":"));
		}
		else if (ForSaleBuyables[i].ItemCost > PlayerOwner().PlayerReplicationInfo.Score ||
			ForSaleBuyables[i].ItemWeight + KFHumanPawn(PlayerOwner().Pawn).CurrentWeight > KFHumanPawn(PlayerOwner().Pawn).MaxCarryWeight)
		{
			CanBuys[j] = 0;
		}
		else
		{
			CanBuys[j] = 1;
		}
		++j;
	}

	if (ActiveCategory >= -1)
	{
		for (i = (ActiveCategory + 1); i < CPRL.ShopCategories.Length; ++i)
		{
			PrimaryStrings[j] = CPRL.ShopCategories[i].Name;
			if (CPRL.ShopCategories[i].PerkIndex < CPRL.ShopPerkIcons.Length)
				ListPerkIcons[j] = CPRL.ShopPerkIcons[CPRL.ShopCategories[i].PerkIndex];
			else ListPerkIcons[j] = None;
			CanBuys[j] = 3 + i;
			++j;
		}
	}

	if (bNotify)
	{
		CheckLinkedObjects(Self);
	}

	if (MyScrollBar != none)
	{
		MyScrollBar.AlignThumb();
	}

	bNeedsUpdate = false;
}

static final function EVariantType GetVariantType(class<Pickup> PickupClass)
{
	switch (PickupClass)
	{
	case class 'W_Flamethrower_Pick_G' :
	case class 'W_Deagle_Pickup_G' :
	case class 'W_DualDeagle_Pickup_G' :
		return Gold; //TODO: maybe just rename these so they're compliant with our default naming scheme?
	}

	//Migrating to a generic naming scheme so that we don't need to maintain multiple lists of skins whenever we add new ones.
	//TODO: Leverage the KFPRepLink so we can specify all of this from within there (would allow for server configuration of icons)
	if (IsGenericGoldSkin(PickupClass))
	{
		return Gold;
	}

	if (IsGenericCamoSkin(PickupClass))
	{
		return Camo;
	}

	if (IsGenericVariantSkin(PickupClass))
	{
		return Sticker;
	}

	return Default;
}

static final function bool IsGenericGoldSkin(class<Pickup> PickupClass)
{
	return InStr(Caps(PickupClass), "_GOLD_") != -1;
}

static final function bool IsGenericCamoSkin(class<Pickup> PickupClass)
{
	return InStr(Caps(PickupClass), "_CAMO_") != -1;
}

static final function bool IsGenericVariantSkin(class<Pickup> PickupClass)
{
	return InStr(Caps(PickupClass), "W_V_") != -1; //If we contain the variant naming scheme in our class name, assume we are some sort of variant skin.
}

static final function Texture GetButtonTexture(class<Pickup> PickupClass)
{
	return class'KFPRepLink'.static.GetIconForPickup(PickupClass);
}

static final function string GetButtonHint(class<Pickup> PickupClass)
{
	return class'KFPRepLink'.static.GetHintForPickup(PickupClass);
}

defaultproperties
{
     ButtonTexture=Texture'KF_InterfaceArt_tex.Menu.Button'
     ButtonHoverTexture=Texture'KF_InterfaceArt_tex.Menu.button_Highlight'
     ButtonDisabledTexture=Texture'KF_InterfaceArt_tex.Menu.button_Disabled'
     NoSkinTexture=Texture'KFTurbo.HUD.NoSkinIcon_D'
     GoldSkinTexture=Texture'KFTurbo.HUD.GoldIcon_D'
     StickerSkinTexture=Texture'KFTurbo.HUD.StickerIcon_D'
     CamoSkinTexture=Texture'KFTurbo.HUD.CamoIcon_D'
     LockedDLCTexture=Texture'KFTurbo.HUD.DLCLocked_D'
     HoverCache=(LastKnownMouseOverIndex=-1,LastKnownMouseOverSubIndex=-1)
     MouseOverSubIndex=-1
     Begin Object Class=GUIToolTip Name=GUIListVariantToolTip
         bTrackMouse=True
         bTrackInput=False
         InitialDelay=0.000000
         ExpirationSeconds=0.000000
     End Object
     ToolTip=GUIToolTip'KFTurbo.KFPBuyMenuSaleList.GUIListVariantToolTip'

}

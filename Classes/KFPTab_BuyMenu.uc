class KFPTab_BuyMenu extends SRKFTab_BuyMenu;

function DoBuy()
{
	if (KFPawn(PlayerOwner().Pawn) != none)
	{
		if (KFPGUIBuyable(TheBuyable) != None)
		{
			KFPawn(PlayerOwner().Pawn).ServerBuyWeapon(KFPGUIBuyable(TheBuyable).GetWeapon(), TheBuyable.ItemWeight);
		}
		else
		{
			KFPawn(PlayerOwner().Pawn).ServerBuyWeapon(TheBuyable.ItemWeaponClass, TheBuyable.ItemWeight);
		}

		MakeSomeBuyNoise();

		SaleSelect.List.SetIndex(-1);
		SaleSelect.List.BuyableToDisplay = none;
		TheBuyable = none;
		LastBuyable = none;

		UpdateBuySellButtons();
	}
}

function OnAnychange()
{
	LastBuyable = TheBuyable;

	ItemInfo.Display(TheBuyable);
	SetInfoText();
	UpdatePanel();
	UpdateBuySellButtons();
}

function UpdatePanel()
{
	local float Price;

	Price = 0.0;

	if (TheBuyable != none && !TheBuyable.bSaleList && TheBuyable.bSellable)
	{
		SaleValueLabel.Caption = SaleValueCaption $ TheBuyable.ItemSellValue;

		SaleValueLabel.bVisible = true;
		SaleValueLabelBG.bVisible = true;
	}
	else
	{
		SaleValueLabel.bVisible = false;
		SaleValueLabelBG.bVisible = false;
	}

	if (TheBuyable == none || !TheBuyable.bSaleList)
	{
		GUIBuyMenu(OwnerPage()).WeightBar.NewBoxes = 0;
	}

	ItemInfo.Display(TheBuyable);
	UpdateAutoFillAmmo();
	SetInfoText();

	// Money update
	if (PlayerOwner() != none)
	{
		MoneyLabel.Caption = MoneyCaption $ int(PlayerOwner().PlayerReplicationInfo.Score);
	}
}

function SetInfoText()
{
	local string TempString;

	if (TheBuyable == None && !bDidBuyableUpdate)
	{
		InfoScrollText.SetContent(InfoText[0]);
		bDidBuyableUpdate = true;
		return;
	}

	if (TheBuyable != None && OldPickupClass != TheBuyable.ItemPickupClass)
	{
		// Unowned Weapon DLC
		if (TheBuyable.ItemWeaponClass.Default.AppID > 0 && !PlayerOwner().SteamStatsAndAchievements.PlayerOwnsWeaponDLC(TheBuyable.ItemWeaponClass.Default.AppID))
		{
			InfoScrollText.SetContent(Repl(InfoText[4], "%1", PlayerOwner().SteamStatsAndAchievements.GetWeaponDLCPackName(TheBuyable.ItemWeaponClass.Default.AppID)));
		}
		// Too expensive
		else if (TheBuyable.ItemCost > PlayerOwner().PlayerReplicationInfo.Score && TheBuyable.bSaleList)
		{
			InfoScrollText.SetContent(InfoText[2]);
		}
		// Too heavy
		else if (TheBuyable.ItemWeight + KFHumanPawn(PlayerOwner().Pawn).CurrentWeight > KFHumanPawn(PlayerOwner().Pawn).MaxCarryWeight && TheBuyable.bSaleList)
		{
			TempString = Repl(Infotext[1], "%1", int(TheBuyable.ItemWeight));
			TempString = Repl(TempString, "%2", int(KFHumanPawn(PlayerOwner().Pawn).MaxCarryWeight - KFHumanPawn(PlayerOwner().Pawn).CurrentWeight));
			InfoScrollText.SetContent(TempString);
		}
		// default
		else
		{
			if (KFPGUIBuyable(TheBuyable) != None)
			{
				InfoScrollText.SetContent(class<KFWeapon>(KFPGUIBuyable(TheBuyable).GetPickup().default.InventoryType).default.Description);
			}
			else
			{
				InfoScrollText.SetContent(TheBuyable.ItemDescription);
			}
		}

		bDidBuyableUpdate = false;
		OldPickupClass = TheBuyable.ItemPickupClass;
	}
}

defaultproperties
{
     Begin Object Class=SRKFBuyMenuInvListBox Name=InventoryBox
         OnCreateComponent=InventoryBox.InternalOnCreateComponent
         WinTop=0.070841
         WinLeft=0.000108
         WinWidth=0.328204
         WinHeight=0.521856
     End Object
     InvSelect=SRKFBuyMenuInvListBox'KFTurbo.KFPTab_BuyMenu.InventoryBox'

     Begin Object Class=KFPGUIBuyWeaponInfoPanel Name=KFPItemInfoPanel
         WinTop=0.193730
         WinLeft=0.332571
         WinWidth=0.333947
         WinHeight=0.489407
     End Object
     ItemInfo=KFPGUIBuyWeaponInfoPanel'KFTurbo.KFPTab_BuyMenu.KFPItemInfoPanel'

     Begin Object Class=KFPBuyMenuSaleListBox Name=SaleBox
         OnCreateComponent=SaleBox.InternalOnCreateComponent
         WinTop=0.064312
         WinLeft=0.672632
         WinWidth=0.325857
         WinHeight=0.674039
     End Object
     SaleSelect=KFPBuyMenuSaleListBox'KFTurbo.KFPTab_BuyMenu.SaleBox'

}

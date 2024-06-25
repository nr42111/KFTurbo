class KFTurboBuyMenuSettings extends Object;

function Texture GetIconForPickup(class<Pickup> PickupClass)
{
    switch (PickupClass)
    {
    //Default weapon
    case class'W_FlameThrower_Pick' :
    case class'W_M4203_Pickup' :
    case class'W_M14_Pickup' :
    case class'W_Shotgun_Pickup' :
    case class'W_AK47_Pickup' :
    case class'W_Deagle_Pickup' :
    case class'W_DualDeagle_Pickup' :
    case class'W_Katana_Pickup' :
    case class'W_Benelli_Pickup' :
    case class'W_MP5M_Pickup' :
    case class'W_M32_Pickup' :
    case class'W_BlowerThrower_Pickup' :
    case class'W_FNFAL_Pickup' :
    case class'W_LAR_Pickup' :
    case class'W_LAW_Pick' :
    case class'W_M99_Pickup' :
    case class'W_MK23_Pickup' :
    case class'W_SCARMK17_Pickup' :
        return Texture'KFTurbo.HUD.NoSkinIcon_D';

    //Gold weapon
    case class'W_V_FlameThrower_Gold_Pickup' :
    case class'W_V_AK47_Gold_Pickup' :
    case class'W_V_Deagle_Gold_Pickup' :
    case class'W_V_DualDeagle_Gold_Pickup' :
    case class'W_V_Katana_Gold_Pickup' :
    case class'W_V_Benelli_Gold_Pickup' :
        return Texture'KFTurbo.HUD.GoldIcon_D';

    //Camo weapon
    case class'W_V_M4203_Camo_Pickup' :
    case class'W_V_Shotgun_Camo_Pickup' :
    case class'W_V_MP5M_Camo_Pickup' :
    case class'W_V_M32_Camo_Pickup' :
        return Texture'KFTurbo.HUD.CamoIcon_D';

    //KFTurbo Stickers
    case class'W_V_AK47_Turbo_Pickup' :
    case class'W_V_FNFAL_Turbo_Pickup' :
    case class'W_V_LAR_Turbo_Pickup' :
    case class'W_V_LAW_Turbo_Pickup' :
    case class'W_V_M14_Turbo_Pickup' :
    case class'W_V_M32_Turbo_Pickup' :
    case class'W_V_M4203_Turbo_Pickup' :
    case class'W_V_M99_Turbo_Pickup' :
    case class'W_V_MK23_Turbo_Pickup' :
    case class'W_V_SCARMK17_Turbo_Pickup' :
        return Texture'KFTurbo.HUD.TurboIcon_D';

    //Invidual Stickers
    case class'W_V_M4203_Retart_Pickup' :
        return Texture'KFTurbo.HUD.LevelIcon_D';
    case class'W_V_M4203_Scuddles_Pickup' :
        return Texture'KFTurbo.HUD.ScrubblesIcon_D';
    case class'W_V_M14_Cubic_Pickup' :
        return Texture'KFTurbo.HUD.SkellIcon_D';
    case class'W_V_M14_SMP_Pickup' :
        return Texture'KFTurbo.HUD.ShowMeProIcon_D';
    case class'W_V_BlowerThrower_VM_Pickup' :
    case class'W_V_Katana_VM_Pickup' :
        return Texture'KFTurbo.HUD.VMIcon_D';
    case class'W_V_Shotgun_WL_Pickup' :
        return Texture'KFTurbo.HUD.WestLondonIcon_D';
    }

    return Texture'KFTurbo.HUD.StickerIcon_D';
}

function String GetHintForPickup(class<Pickup> PickupClass)
{
    switch (PickupClass)
    {
    //Default weapon
    case class'W_FlameThrower_Pick' :
    case class'W_M4203_Pickup' :
    case class'W_M14_Pickup' :
    case class'W_Shotgun_Pickup' :
    case class'W_AK47_Pickup' :
    case class'W_Deagle_Pickup' :
    case class'W_DualDeagle_Pickup' :
    case class'W_Katana_Pickup' :
    case class'W_Benelli_Pickup' :
    case class'W_MP5M_Pickup' :
    case class'W_M32_Pickup' :
    case class'W_BlowerThrower_Pickup' :
    case class'W_FNFAL_Pickup' :
    case class'W_LAR_Pickup' :
    case class'W_LAW_Pick' :
    case class'W_M99_Pickup' :
    case class'W_MK23_Pickup' :
    case class'W_SCARMK17_Pickup' :
        return "Default";

    //Gold weapon
    case class'W_V_FlameThrower_Gold_Pickup' :
    case class'W_V_AK47_Gold_Pickup' :
    case class'W_V_Deagle_Gold_Pickup' :
    case class'W_V_DualDeagle_Gold_Pickup' :
    case class'W_V_Katana_Gold_Pickup' :
    case class'W_V_Benelli_Gold_Pickup' :
        return "Gold";

    //Camo weapon
    case class'W_V_M4203_Camo_Pickup' :
    case class'W_V_Shotgun_Camo_Pickup' :
    case class'W_V_MP5M_Camo_Pickup' :
    case class'W_V_M32_Camo_Pickup' :
        return "Camo";
    }

    return "Sticker";
}
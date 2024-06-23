class W_MK23_Pickup extends MK23Pickup;

function inventory SpawnCopy( pawn Other )
{
	local Inventory I;

	For( I=Other.Inventory; I!=None; I=I.Inventory )
	{
		if( MK23Pistol(I)!=None )
		{
			if( Inventory!=None )
				Inventory.Destroy();
			InventoryType = class'W_DualMK23_Weap';
			AmmoAmount[0] += MK23Pistol(I).AmmoAmount(0);
			MagAmmoRemaining += MK23Pistol(I).MagAmmoRemaining;
			I.Destroyed();
			I.Destroy();
			Return Super(KFWeaponPickup).SpawnCopy(Other);
		}
	}
	InventoryType = Default.InventoryType;
	Return Super(KFWeaponPickup).SpawnCopy(Other);
}

defaultproperties
{
     VariantClasses(0)=Class'KFTurbo.W_MK23_Pickup'
     VariantClasses(1)=Class'KFTurbo.W_V_MK23_Turbo_Pickup'
     InventoryType=Class'KFTurbo.W_MK23_Weap'
}

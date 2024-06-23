class W_Magnum44_Pickup extends Magnum44Pickup;

function inventory SpawnCopy( pawn Other )
{
	local Inventory I;

	for ( I = Other.Inventory; I != none; I = I.Inventory )
	{
		if ( Magnum44Pistol(I) != none )
		{
			if( Inventory != none )
				Inventory.Destroy();
			InventoryType = Class'W_Dual44_Weap';
            AmmoAmount[0] += Magnum44Pistol(I).AmmoAmount(0);
            MagAmmoRemaining += Magnum44Pistol(I).MagAmmoRemaining;
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
     Weight=3.000000
     InventoryType=Class'KFTurbo.W_Magnum44_Weap'
}

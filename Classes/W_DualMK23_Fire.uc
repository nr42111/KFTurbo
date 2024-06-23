class W_DualMK23_Fire extends DualMK23Fire;

function DoTrace(Vector Start, Rotator Dir)
{
	class'WeaponHelper'.static.PenetratingWeaponTrace(Start, KFWeapon(Weapon), self, 0, 0.0);
}

defaultproperties
{
     Spread=0.011000
}

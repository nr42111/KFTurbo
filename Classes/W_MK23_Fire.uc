class W_MK23_Fire extends MK23Fire;

function DoTrace(Vector Start, Rotator Dir)
{
	class'WeaponHelper'.static.PenetratingWeaponTrace(Start, KFWeapon(Weapon), self, 0, 0.0);
}

defaultproperties
{
     Spread=0.011000
}

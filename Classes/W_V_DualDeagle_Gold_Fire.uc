class W_V_DualDeagle_Gold_Fire extends GoldenDualDeagleFire;

function DoTrace(Vector Start, Rotator Dir)
{
	class'WeaponHelper'.static.PenetratingWeaponTrace(Start, KFWeapon(Weapon), self, 1, 0.8);
}

defaultproperties
{
     maxVerticalRecoilAngle=850
     maxHorizontalRecoilAngle=150
}

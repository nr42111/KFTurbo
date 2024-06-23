class W_Dual44_Fire extends Dual44MagnumFire;

function DoTrace(Vector Start, Rotator Dir)
{
	class'WeaponHelper'.static.PenetratingWeaponTrace(Start, KFWeapon(Weapon), self, 2, 0.9);
}

defaultproperties
{
     RecoilRate=0.090000
     maxVerticalRecoilAngle=1250
     maxHorizontalRecoilAngle=250
     DamageType=Class'KFTurbo.W_Dual44_DT'
     DamageMin=100
     DamageMax=120
     FireRate=0.125000
     Spread=0.008000
}

class W_NailGun_Proj extends NailGunProjectile;

var array<Pawn> HitPawnList;

event PreBeginPlay()
{
	Super.PreBeginPlay();

	class'WeaponHelper'.static.NotifyPostProjectileSpawned(self);
}

simulated function ProcessTouch(Actor Other, vector HitLocation)
{
	if (class'WeaponHelper'.static.AlreadyHitPawn(Other, HitPawnList))
	{
		return;
	}

	Super.ProcessTouch(Other, HitLocation);
}

simulated function HitWall(vector HitNormal, actor Wall)
{
	HitPawnList.Length = 0;

	Super.HitWall(HitNormal, Wall);
}

defaultproperties
{
     Bounces=1
     MaxPenetrations=4
     PenDamageReduction=0.900000
     HeadShotDamageMult=1.550000
     Speed=4000.000000
     MaxSpeed=4500.000000
     Damage=250.000000
     MyDamageType=Class'KFTurbo.W_NailGun_DT'
     ExplosionDecal=Class'KFTurbo.W_NailGun_Decal'
     StaticMesh=StaticMesh'EffectsSM.Weapons.Vlad_9000_Nail'
     CullDistance=4000.000000
     DrawScale=3.000000
}

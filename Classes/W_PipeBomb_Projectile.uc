class W_PipeBomb_Projectile extends PipeBombProjectile;

simulated function Explode(vector HitLocation, vector HitNormal)
{
	if (bHasExploded)
	{
		return;
	}

	Super.Explode(HitLocation, HitNormal);
}

defaultproperties
{
     ShrapnelClass=Class'KFTurbo.W_PipeBomb_Shrapnel'
}

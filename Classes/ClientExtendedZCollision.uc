//Unsure if we'll ever need to make any more changes than just TakeDamage().
class ClientExtendedZCollision extends ExtendedZCollision;

//We definitely don't want simulated proxies calling take damage on zeds.
function TakeDamage( int Damage, Pawn EventInstigator, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{
	return;
}

defaultproperties
{
}

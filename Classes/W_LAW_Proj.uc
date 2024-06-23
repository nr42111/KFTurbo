class W_LAW_Proj extends LAWProj;

simulated function HurtRadius(float DamageAmount, float Radius, class<DamageType> DamageType, float Momentum, vector HitLocation)
{
	local actor HitActor;
	local class<actor> PipebombClass;

	Super.HurtRadius(DamageAmount, Radius, DamageType, Momentum, HitLocation);

	Radius *= 0.5f;

	PipebombClass = class'PipeBombProjectile';
	foreach CollidingActors (PipebombClass, HitActor, Radius, HitLocation)
	{
		DetonatePipebomb(HitActor, Instigator);
	}
}

static final function DetonatePipebomb(Actor Actor, Pawn DetonationInstigator)
{
	local PipeBombProjectile Pipebomb;
	Pipebomb = PipeBombProjectile(Actor);

	if(Pipebomb == None)
	{
		return;
	}

	Pipebomb.TakeDamage(default.Damage, DetonationInstigator, Actor.Location, vect(0,0,0), default.ImpactDamageType);
}

defaultproperties
{
     ArmDistSquared=202500.000000
     ImpactDamage=475
     Damage=1000.000000
}

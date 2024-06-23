class AI_SC extends SawZombieController;

var bool bEnableForceRage;
var float TimeUntilForcedRage;
var bool bForcedRage;

function Tick(float dt)
{
	Super.Tick(dt);

	if(!bForcedRage && (bEnableForceRage && Level.TimeSeconds > TimeUntilForcedRage))
	{
		ForceRage(Pawn);
	}
}

function ForceRage(Pawn Pawn)
{
	local ZombieScrake ZSC;
	local float RageHealth;
	ZSC = ZombieScrake(Pawn);

	bForcedRage = true;

	if (ZSC == none)
	{
		return;
	}

	//Don't do any complex state management to force the Scrake to charge - just set its health to rage threshold.
	RageHealth = ZSC.HealthMax * 0.73;
	if (ZSC.Health > RageHealth)
	{
		ZSC.Health = RageHealth;
	}
	
	//Attempt a ranged attack to try the normal rage flow.
	RangedAttack(none);
}


state ZombieCharge
{
	function BeginState()
	{
		if(!bEnableForceRage && Level.Game.GameDifficulty >= 5.0)
		{
			bEnableForceRage = true;
			TimeUntilForcedRage = Level.TimeSeconds + 180.f; //Forced raged in 3 minutes.			
		}

        Super.BeginState();
	}
}

defaultproperties
{
}

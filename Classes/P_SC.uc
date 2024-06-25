class P_SC extends ZombieScrake
    abstract
    DependsOn(PawnHelper);

var PawnHelper.AfflictionData AfflictionData;

var bool bUnstunTimeReady;
var float UnstunTime;

var AI_SC ProAI;

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    //In unrealscript it's probably more expensive to check role/if controller exists rather than just cast a null.
    ProAI = AI_SC(Controller);

    class'PawnHelper'.static.SpawnClientExtendedZCollision(self);
}

function TakeDamage(int Damage, Pawn InstigatedBy, Vector HitLocation, Vector Momentum, class<DamageType> DamageType, optional int HitIndex)
{
	if (Role == ROLE_Authority)
	{
		class'PawnHelper'.static.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, HitIndex, AfflictionData);

        if ( Level.Game.GameDifficulty >= 5.0  && (class<DamTypeFlareProjectileImpact>(damageType) != none) )
        {
            Damage *= 0.75; // flare impact damage reduction
        }
        if ( Level.Game.GameDifficulty >= 5.0  && (class<DamTypeFlareRevolver>(damageType) != none) )
        {
            Damage *= 0.75; // flare explosion damage reduction
        }
	}

	Super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, HitIndex);
}

simulated function Tick(float DeltaTime)
{
    Super.Tick(DeltaTime);

    class'PawnHelper'.static.TickAfflictionData(DeltaTime, self, AfflictionData);

    if(bSTUNNED && bUnstunTimeReady && UnstunTime < Level.TimeSeconds)
    {
        bSTUNNED = false;
        bUnstunTimeReady = false;
    }
}

simulated function PostNetReceive()
{
    if (bCharging)
        MovementAnims[0]='ChargeF';
    else
        MovementAnims[0]=default.MovementAnims[0];
}

function float NumPlayersHealthModifer()
{
    return class'PawnHelper'.static.GetBodyHealthModifier(self, Level);
}

function float NumPlayersHeadHealthModifer()
{
    return class'PawnHelper'.static.GetHeadHealthModifier(self, Level);
}

simulated function float GetOriginalGroundSpeed()
{
    return Super.GetOriginalGroundSpeed() * class'PawnHelper'.static.GetSpeedModifier(self, AfflictionData);
}

function PlayDirectionalHit(Vector HitLoc)
{
    local int LastStunCount;
    LastStunCount = StunsRemaining;

    if(!bUnstunTimeReady && class'PawnHelper'.static.ShouldPlayDirectionalHit(self))
        Super.PlayDirectionalHit(HitLoc);

	bUnstunTimeReady = class'PawnHelper'.static.UpdateStunProperties(self, LastStunCount, UnstunTime, bUnstunTimeReady);
}

simulated function SetBurningBehavior()
{
    if(ProAI != None && ProAI.bForcedRage)
        return;

    class'PawnHelper'.static.SetBurningBehavior(self, AfflictionData);
    //BurnRatio = 0.f;

    if( Role == Role_Authority && IsInState('RunningState') )
        GotoState('');

    if( Level.NetMode != NM_DedicatedServer )
        PostNetReceive();
}

simulated function UnSetBurningBehavior()
{
    class'PawnHelper'.static.UnSetBurningBehavior(self, AfflictionData);
    //BurnRatio = 0.f;

    if( Level.NetMode != NM_DedicatedServer )
        PostNetReceive();
}

simulated function ZombieCrispUp()
{
    class'PawnHelper'.static.ZombieCrispUp(self);
}

simulated function Timer()
{
    if (BurnDown > 0)
    {
        TakeFireDamage(LastBurnDamage + rand(2) + 3 , LastDamagedBy);
        SetTimer(1.0,false);
    }
    else
    {
        UnSetBurningBehavior();

        RemoveFlamingEffects();
        StopBurnFX();
        SetTimer(0, false);
    }
}

State SawingLoop
{
    function AnimEnd( int Channel )
    {
        Super(KFMonster).AnimEnd(Channel);

        if( Controller!=None && Controller.Enemy!=None && CanAttack(Controller.Enemy))
            RangedAttack(Controller.Enemy);
    }
}

simulated function SetZappedBehavior()
{
    if(ProAI != None && ProAI.bForcedRage)
        return;

    Super.SetZappedBehavior();
}

function RangedAttack(Actor A)
{
	if ( bShotAnim || Physics == PHYS_Swimming)
		return;
	else if ( CanAttack(A) )
	{
		bShotAnim = true;
		SetAnimAction(MeleeAnims[Rand(2)]);
		CurrentDamType = ZombieDamType[0];
		GoToState('SawingLoop');
	}
}

function bool ShouldCharge()
{
	if (ProAI != None && ProAI.bForcedRage)
	{
		return true;
	}
	else if (Level.Game.GameDifficulty < 5.0 && float(Health) / HealthMax < 0.5)
	{
		return true;
	}
	else if (Level.Game.GameDifficulty >= 5.0 && float(Health) / HealthMax < 0.75)
	{
		return true;
	}

	return false;
}

state RunningState
{
	// Set the zed to the zapped behavior
    simulated function SetZappedBehavior()
    {
        if(ProAI != None && ProAI.bForcedRage)
            return;

        Global.SetZappedBehavior();
        GoToState('');
	}

    simulated function UnSetZappedBehavior()
    {
        Super.UnSetZappedBehavior();
		
		if (ProAI == None || !ProAI.bForcedRage)
		{
			return;
		}

		BeginState();
    }

    simulated function UnSetBurningBehavior()
    {
		Super.UnSetBurningBehavior();

		if (ProAI == None || !ProAI.bForcedRage)
		{
			return;
		}

		BeginState();
    }

	function BeginState()
	{
		if(bZapped && (ProAI == None || !ProAI.bForcedRage))
        {
            GoToState('');
        }
        else
        {
    		SetGroundSpeed(OriginalGroundSpeed * 3.5);
    		bCharging = true;
    		if( Level.NetMode!=NM_DedicatedServer )
    			PostNetReceive();

    		NetUpdateTime = Level.TimeSeconds - 1;
		}
	}
}

defaultproperties
{
     AfflictionData=(Burn=(BurnPrimaryModifier=1.000000,BurnSecondaryModifier=1.000000,BurnDuration=4.000000,Priority=6),HarpoonModifier=0.500000)
     EventClasses(0)="KFTurbo.P_SC_DEF"
     ControllerClass=Class'KFTurbo.AI_SC'
}

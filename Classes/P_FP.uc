class P_FP extends ZombieFleshpound
    abstract
    DependsOn(PawnHelper);

var PawnHelper.AfflictionData AfflictionData;

var bool bUnstunTimeReady;
var float UnstunTime;

var AI_FP ProAI;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	ProAI = AI_FP(Controller);

    class'PawnHelper'.static.SpawnClientExtendedZCollision(self);
}

function TakeDamage(int Damage, Pawn InstigatedBy, Vector HitLocation, Vector Momentum, class<DamageType> DamageType, optional int HitIndex)
{
	if (Role == ROLE_Authority)
	{
		class'PawnHelper'.static.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, HitIndex, AfflictionData);
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
    local float BaseSpeed;

    BaseSpeed = class'PawnHelper'.static.GetOriginalGroundSpeed(self, AfflictionData);

    if(bChargingPlayer)
        return BaseSpeed * 2.3;

    return BaseSpeed;
}

function PlayDirectionalHit(Vector HitLoc)
{
    local int LastStunCount;

    LastStunCount = StunsRemaining;

    if(class'PawnHelper'.static.ShouldPlayDirectionalHit(self))
        Super.PlayDirectionalHit(HitLoc);

    if(LastStunCount != StunsRemaining)
    {
        UnstunTime = Level.TimeSeconds + StunTime;
        bUnstunTimeReady = true;
    }
}

simulated function SetBurningBehavior()
{
    if(ProAI != None && ProAI.bForcedRage)
        return;

    class'PawnHelper'.static.SetBurningBehavior(self, AfflictionData);
    //BurnRatio = 0.f;
}

simulated function UnSetBurningBehavior()
{
    class'PawnHelper'.static.UnSetBurningBehavior(self, AfflictionData);
    //BurnRatio = 0.f;
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

simulated function SetZappedBehavior()
{
    if(ProAI != None && ProAI.bForcedRage)
        return;

    Super.SetZappedBehavior();
}

state RageCharging
{
Ignores StartCharging;

	function BeginState()
	{
        local float DifficultyModifier;

		if(bZapped && (ProAI == None || !ProAI.bForcedRage))
        {
            GoToState('');
        }
        else
        {
            bChargingPlayer = true;

    		if( Level.NetMode!=NM_DedicatedServer )
    			ClientChargingAnims();

            if(Level.Game.GameDifficulty < 2.0)
                DifficultyModifier = 0.85;
            else if(Level.Game.GameDifficulty < 4.0)
                DifficultyModifier = 1.0;
            else if(Level.Game.GameDifficulty < 5.0)
                DifficultyModifier = 1.25;
            else
                DifficultyModifier = 3.0;

        	if(ProAI != None && ProAI.bForcedRage)
        		DifficultyModifier *= 1000.f;

    		RageEndTime = (Level.TimeSeconds + 5 * DifficultyModifier) + (FRand() * 6 * DifficultyModifier);
    		NetUpdateTime = Level.TimeSeconds - 1;
		}
	}

	function bool MeleeDamageTarget(int hitdamage, vector pushdir)
	{
		local bool RetVal,bWasEnemy;

		bWasEnemy = (Controller.Target==Controller.Enemy);
		RetVal = Super(ZombieFleshpoundBase).MeleeDamageTarget(hitdamage*1.75, pushdir*3);

		if(RetVal && bWasEnemy && ProAI != None && !ProAI.bForcedRage)
			GoToState('');
            
		return RetVal;
	}
}

defaultproperties
{
     AfflictionData=(Burn=(BurnPrimaryModifier=1.000000,BurnSecondaryModifier=1.000000,BurnDuration=4.000000,Priority=6),HarpoonModifier=0.500000)
     EventClasses(0)="P_FP_DEF"
     ControllerClass=Class'KFTurbo.AI_FP'
}

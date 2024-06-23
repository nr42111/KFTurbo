class P_Husk extends ZombieHusk DependsOn(PawnHelper);

var PawnHelper.AfflictionData AfflictionData;

var bool bUnstunTimeReady;
var float UnstunTime;

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    class'PawnHelper'.static.SpawnClientExtendedZCollision(self);
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
    return class'PawnHelper'.static.GetOriginalGroundSpeed(self, AfflictionData);
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

//Husks cannot be burned so this is never a thing.
simulated function SetBurningBehavior()
{
    if(!bHarpoonStunned)
    {
        return;
    }

    class'PawnHelper'.static.SetHarpoonedBehaviour(self, AfflictionData);
    //BurnRatio = 0.f;        
}

//Husks cannot be burned so this is never a thing.
simulated function UnSetBurningBehavior()
{
    if(bHarpoonStunned)
    {
        return;
    }

    class'PawnHelper'.static.UnSetHarpoonedBehaviour(self, AfflictionData);
    //BurnRatio = 0.f;
}

simulated function ZombieCrispUp()
{
}

simulated function Timer()
{
}

State ZombieDying
{
ignores AnimEnd, Trigger, Bump, HitWall, HeadVolumeChange, PhysicsVolumeChange, Falling, BreathTimer, Died, RangedAttack, SpawnTwoShots;
}

defaultproperties
{
     AfflictionData=(Burn=(BurnPrimaryModifier=1.000000,BurnSecondaryModifier=1.000000,BurnDuration=4.000000),HarpoonModifier=0.500000)
}

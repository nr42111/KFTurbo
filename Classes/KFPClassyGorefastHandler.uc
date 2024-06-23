class KFPClassyGorefastHandler extends Actor;

function PostBeginPlay()
{
    local KFGameType KFGT;

    KFGT = KFGameType(Level.Game);

    Super.PostBeginPlay();
    
    SetTimer(10.f, false);
}

event Timer()
{
    local KFGameType KFGT;
    local int Index;

    KFGT = KFGameType(Level.Game);

    //Only replace a zed 50% of the time.
    if(FRand() < 0.5f)
    {
        for(Index = 0; Index < KFGT.NextSpawnSquad.Length; Index++)
        {
            //We already replaced a class in this squad!
            if(KFGT.NextSpawnSquad[Index] == class'P_Gorefast_Classy')
            {
                break;
            }

            if(ClassIsChildOf(KFGT.NextSpawnSquad[Index], class'P_Gorefast'))
            {
                KFGT.NextSpawnSquad[Index] = class'P_Gorefast_Classy';

                //We shouldn't just automatically replace all of them, roll dice each time we try.
                if(FRand() < 0.25f)
                {
                    break;
                }
            }
        }
    }

    SetTimer(8.f + (FRand() * 4.f), false);
}

defaultproperties
{
    
}
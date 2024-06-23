class ChatIcon extends Actor;

simulated function Tick(float DeltaTime)
{
	Super.Tick(DeltaTime);

	if (bDeleteMe)
	{
		return;
	}

	if (Owner == None)
	{
		Destroy();
	}
}

defaultproperties
{
     Texture=Texture'KFTurbo.Generic.ChatIcon_D'
     DrawScale=0.175000
     Style=STY_Masked
}

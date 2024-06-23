class ChatWatcher extends Inventory;

var ChatIcon PlayerChatIcon;

simulated function Tick(float DeltaTime)
{
	Super.Tick(DeltaTime);

	if (Role != ROLE_Authority)
	{
		return;
	}

	if (Owner == None || PlayerController(Owner.Owner) == None)
	{
		return;
	}

	UpdatePlayerIcon(PlayerController(Owner.Owner));
}

function UpdatePlayerIcon(PlayerController Player)
{
	if ((PlayerChatIcon != None) == Player.bIsTyping)
	{
		return;
	}

	if (Player.bIsTyping)
	{
		PlayerChatIcon = Spawn(class'ChatIcon', Owner);

		if (PlayerChatIcon != None)
		{
			Owner.AttachToBone(PlayerChatIcon, 'head');
			PlayerChatIcon.SetRelativeLocation(vect(15, 0, 0));
		}
	}
	else
	{
		if (!PlayerChatIcon.bDeleteMe)
		{
			PlayerChatIcon.Destroy();
		}
	}
}

simulated function Destroyed()
{
	Super.Destroyed();

	if (PlayerChatIcon != None)
	{
		PlayerChatIcon.Destroy();
		PlayerChatIcon = None;
	}
}

defaultproperties
{
}

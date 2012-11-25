class MutRoundStats extends Mutator;

enum EObjectiveState
{
	OBJ_Axis,
	OBJ_Allies,
	OBJ_Neutral,
};

// Global variables
var FileLog file;

function Mutate(string MutateString, PlayerController Sender)
{
	local PlayerController PC;
	local ROObjective Obj;

	// always call super class implementation!
	Super.Mutate(MutateString, Sender);

	if ( MutateString ~= "RoundStats" )
	{
		foreach AllActors(class'PlayerController', PC)
			GetPlayerStats( PC );
		foreach AllActors(class'ROObjective', Obj)
			GetObjStats( Obj );
		GetTimeLeft();
	}
}

// Catch when the round ends and turn off live, allies/axis ready, and ff
auto state StartUp
{
	function BeginState()
	{
		SetTimer( 5, true );
	}
	function timer()
	{
		local PlayerController PC;
		local ROObjective Obj;

		if( Level.Game.IsInState('RoundOver') )
		{
			foreach AllActors(class'PlayerController', PC)
				GetPlayerStats( PC );
			foreach AllActors(class'ROObjective', Obj)
				GetObjStats( Obj );
			GetTimeLeft();
		}
	}
}

function GetTimeLeft()
{
	local GameReplicationInfo GRI;
	local int CurrentTime;
	local string TimeLeft, statstring;

	// Get Main Actor
	foreach AllActors(class'GameReplicationInfo', GRI)
		break;
	
	// Get Time Left
	CurrentTime = ROGameReplicationInfo(GRI).RoundStartTime + ROGameReplicationInfo(GRI).RoundDuration - GRI.ElapsedTime;
	TimeLeft = GetTimeString(CurrentTime); // Converts to min:sec string format

	// Build string
	statstring = "[RS] %H:%I TimeLeft:"$TimeLeft;
	statstring = ParseString( statstring );

	// Broadcast & Log string
	Level.Game.Broadcast( self, statstring );
	LogToFile( "test", statstring );
}

function GetPlayerStats( PlayerController Sender )
{
	// Declare Variables
	local string MyPlayerName;
	local PlayerReplicationInfo PRI;
	local Pawn P;
	local string MyPlayerID, MyTeam, statstring;
	local int MyKills, MyDeaths, MyHealth;
	local float MyTKs;

	// Assign Actors to Variables
	PRI = Sender.PlayerReplicationInfo;
	P = Sender.Pawn;

	// Get Actor Properties
	MyPlayerName = PRI.PlayerName;
	MyPlayerID = PlayerController(PRI.Owner).GetPlayerIDHash();
	MyKills = PRI.Kills;
	MyDeaths = PRI.Deaths;
	MyTKs = PRI.FFKills;
	MyHealth = P.Health;
	MyTeam = PRI.Team.GetHumanReadableName();

	// Build string & don't include webadmin
	if(MyPlayerName != "WebAdmin")
	{
		statstring = "[RS] %H:%I PlayerID:"$MyPlayerID$"         PlayerName:"$MyPlayerName$"         Team:"$MyTeam$"         Kills:"$MyKills$"         Deaths:"$MyDeaths$"         TKs:"$MyTKs;
		statstring = ParseString( statstring );
	}

	// Broadcast & Log string
	Level.Game.Broadcast( self, statstring );
	LogToFile( "test", statstring );
}

function GetObjStats( ROObjective Obj )
{
	local name MyObjState;
	local string MyObjName;
	local int MyObjNum;
	local string statstring;

	MyObjState = GetEnum(Enum'EObjectiveState', Obj.ObjState);
	MyObjName = Obj.ObjName;
	MyObjNum = Obj.ObjNum;

	statstring = "[RS] %H:%I ["$MyObjNum$"] "$MyObjName$" is "$MyObjState;
	statstring = ParseString( statstring );

	// Broadcast & Log string
	Level.Game.Broadcast( self, statstring );
	LogToFile( "test", statstring );
}

function LogToFile( string filename, string content )
{
		if( file == None )
		{
			log( "'file' did not exist, creating" );
			file = spawn(class'FileLog');
			if( file != None )
			{
				file.OpenLog( filename );
				file.logf( content );
			}
		}
		else
		{
			log( "'file' already exists, opening" );
			file.OpenLog( filename );
			file.logf( content );
		}

		file.CloseLog(); // Without this line game will crash
}

function string ParseString( string text )
{
  //ReplaceText(text, "%P", GetServerPort());
  //ReplaceText(text, "%N", Level.Game.GameReplicationInfo.ServerName);
  ReplaceText(text, "%Y", Right("0000"$string(Level.Year), 4));
  ReplaceText(text, "%M", Right("00"$string(Level.Month), 2));
  ReplaceText(text, "%D", Right("00"$string(Level.Day), 2));
  ReplaceText(text, "%H", Right("00"$string(Level.Hour), 2));
  ReplaceText(text, "%I", Right("00"$string(Level.Minute), 2));
  ReplaceText(text, "%W", Right("0"$string(Level.DayOfWeek), 1));
  ReplaceText(text, "%S", Right("00"$string(Level.Second), 2));
  return text;
}

// Copied from ROEngine->ROHud
static function string GetTimeString(float Time)
{
	local string S;

	Time = FMax(0.0, Time);

	S = int(Time / 60) $ ":";

	Time = Time % 60;

	if (Time < 10)
		S = S $ "0" $ int(Time);
	else
		S = S $ int(Time);

	return S;
}

defaultproperties
{
	GroupName=			"RoundStats"
	FriendlyName=			"Round Stats"
	Description=			"Logs end-of-round statistics"
}
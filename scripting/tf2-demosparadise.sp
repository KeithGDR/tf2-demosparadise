/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Demos Paradise"
#define PLUGIN_DESCRIPTION "DemoMan's wet dream in a gamemode."
#define PLUGIN_VERSION "1.0.3"

/*****************************/
//Includes
#include <sourcemod>

#include <misc-sm>
#include <misc-tf>
#include <misc-colors>

/*****************************/
//ConVars

/*****************************/
//Globals

enum
{
	Mutation_None = 0,
	Mutation_Crits,
	Mutation_Gravity,
	Mutation_BabyScouts,
	Mutation_CatchTheScout,
	Mutation_LifeFuel,
	Mutation_Total
}

int g_Mutation = Mutation_None;
TFClassType g_Class[MAXPLAYERS + 1];
bool g_SkipMutation;

Handle g_MayhemHud;

enum struct Mayhem
{
	int client;
	int points;

	void Init(int client)
	{
		this.client = client;
		this.points = 0;
	}

	void Reset()
	{
		this.points = 0;
		this.UpdateHud();
	}

	void Clear()
	{
		this.client = -1;
		this.points = 0;
	}

	void AddPoints(int value)
	{
		this.points += value;
		char sSound[PLATFORM_MAX_PATH];
		FormatEx(sSound, sizeof(sSound), "vo/demoman_laughevil0%i.mp3", GetRandomInt(1, 5));
		EmitSoundToClient(this.client, sSound);
		this.UpdateHud();
	}

	void UpdateHud()
	{
		SetHudTextParams(0.1, 0.1, 9999999.0, 255, 0, 0, 255);
		ShowSyncHudText(this.client, g_MayhemHud, "Mayhem Points: %i", this.points);
	}

	void RemoveHud()
	{
		ClearSyncHud(this.client, g_MayhemHud);
	}
}

Mayhem g_Mayhem[MAXPLAYERS + 1];

Handle g_MutationTimer;

/*****************************/
//Plugin Info
public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = "Drixevel", 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_mayhem", Command_Mayhem, ADMFLAG_ROOT);
	RegAdminCmd("sm_explode", Command_Explode, ADMFLAG_ROOT);
	RegAdminCmd("sm_mutation", Command_Mutation, ADMFLAG_ROOT);

	g_MayhemHud = CreateHudSynchronizer();

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
			OnClientConnected(i);

		if (IsClientInGame(i) && IsPlayerAlive(i))
			g_Mayhem[i].UpdateHud();
	}

	g_MutationTimer = CreateTimer(60.0, Timer_Mutation, _, TIMER_REPEAT);
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			g_Mayhem[i].RemoveHud();
}

public void OnMapStart()
{
	char sSound[PLATFORM_MAX_PATH];
	
	for (int i = 1; i <= 5; i++)
	{
		FormatEx(sSound, sizeof(sSound), "vo/demoman_laughevil0%i.mp3", i);
		PrecacheSound(sSound);
	}
	
	for (int i = 1; i <= 2; i++)
	{
		FormatEx(sSound, sizeof(sSound), "vo/demoman_laughlong0%i.mp3", i);
		PrecacheSound(sSound);
	}

	for (int i = 1; i <= 13; i++)
	{
		FormatEx(sSound, sizeof(sSound), "vo/demoman_gibberish%.1i.mp3", i);
		PrecacheSound(sSound);
	}

	for (int i = 1; i <= 9; i++)
	{
		FormatEx(sSound, sizeof(sSound), "ambient/explosions/explode_%i.wav", i);
		PrecacheSound(sSound);
	}
}

public void OnMapEnd()
{
	StopTimer(g_MutationTimer);
}

public void OnClientConnected(int client)
{
	g_Mayhem[client].Init(client);
	SDKHook(client, SDKHook_GetMaxHealth, GetMaxHealth);
}

public void OnClientDisconnect_Post(int client)
{
	g_Mayhem[client].Clear();
}

public void TF2_OnRoundStart(bool full_reset)
{
	char sSound[PLATFORM_MAX_PATH];
	FormatEx(sSound, sizeof(sSound), "vo/demoman_gibberish%.1i.mp3", GetRandomInt(1, 13));
	EmitSoundToAll(sSound);

	for (int i = 1; i <= MaxClients; i++)
		g_Mayhem[i].Reset();
	
	StopTimer(g_MutationTimer);
	g_MutationTimer = CreateTimer(60.0, Timer_Mutation, _, TIMER_REPEAT);
}

public Action Command_Mutation(int client, int args)
{
	g_Mutation = GetCmdArgInt(1);
	ExecuteMutation();
	return Plugin_Handled;
}

public Action Timer_Mutation(Handle timer)
{
	if (g_SkipMutation)
	{
		g_SkipMutation = false;
		return Plugin_Continue;
	}

	g_SkipMutation = view_as<bool>(GetRandomFloat(0.0, 100.0) > 75.0);

	g_Mutation = GetRandomInt(0, Mutation_Total);
	ExecuteMutation();

	return Plugin_Continue;
}

void ExecuteMutation()
{
	char sSound[PLATFORM_MAX_PATH];
	FormatEx(sSound, sizeof(sSound), "vo/demoman_laughlong0%i.mp3", GetRandomInt(1, 2));
	EmitSoundToAll(sSound);

	switch (g_Mutation)
	{
		case Mutation_Crits:
		{
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && IsPlayerAlive(i))
					TF2_AddCondition(i, TFCond_HalloweenCritCandy, 60.0);
		}
		case Mutation_Gravity:
		{
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && IsPlayerAlive(i))
					TF2_AddCondition(i, TFCond_BalloonHead, 60.0);
		}
		case Mutation_BabyScouts:
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					g_Class[i] = TF2_GetPlayerClass(i);
					TF2_SetPlayerClass(i, TFClass_Scout, true, false);
					TF2_RegeneratePlayer(i);

					TF2_AddCondition(i, TFCond_HalloweenTiny, 60.0);
				}
			}

			CreateTimer(60.0, Timer_RevertClasses, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		case Mutation_CatchTheScout:
		{
			int total = GetClientAliveCount();
			int random1;
			int random2;
			int random3;

			if (total >= 1)
			{
				random1 = GetRandomClient();
				g_Class[random1] = TF2_GetPlayerClass(random1);
				TF2_SetPlayerClass(random1, TFClass_Scout, true, false);
				TF2_RegeneratePlayer(random1);
				TF2_AddCondition(random1, TFCond_Ubercharged, 60.0);
			}

			if (total >= 2)
			{
				random2 = GetRandomClient();
				g_Class[random2] = TF2_GetPlayerClass(random2);
				TF2_SetPlayerClass(random2, TFClass_Scout, true, false);
				TF2_RegeneratePlayer(random2);
				TF2_AddCondition(random2, TFCond_Ubercharged, 60.0);
			}

			if (total >= 3)
			{
				random3 = GetRandomClient();
				g_Class[random3] = TF2_GetPlayerClass(random3);
				TF2_SetPlayerClass(random3, TFClass_Scout, true, false);
				TF2_RegeneratePlayer(random3);
				TF2_AddCondition(random3, TFCond_Ubercharged, 60.0);
			}

			DataPack pack;
			CreateDataTimer(60.0, Timer_RevertRandoms, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(random1 > 0 ? GetClientUserId(random1) : 0);
			pack.WriteCell(random2 > 0 ? GetClientUserId(random2) : 0);
			pack.WriteCell(random3 > 0 ? GetClientUserId(random3) : 0);
		}
		case Mutation_LifeFuel:
		{
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && IsPlayerAlive(i))
					TF2_AddCondition(i, TFCond_MegaHeal, 60.0);
		}
	}
}

public Action Timer_RevertRandoms(Handle timer, DataPack pack)
{
	pack.Reset();

	int random1 = GetClientOfUserId(pack.ReadCell());
	
	if (random1 > 0 && IsClientInGame(random1) && IsPlayerAlive(random1))
		TF2_SetPlayerClass(random1, g_Class[random1], true, true);

	int random2 = GetClientOfUserId(pack.ReadCell());
	
	if (random2 > 0 && IsClientInGame(random2) && IsPlayerAlive(random2))
		TF2_SetPlayerClass(random2, g_Class[random2], true, true);

	int random3 = GetClientOfUserId(pack.ReadCell());

	if (random3 > 0 && IsClientInGame(random3) && IsPlayerAlive(random3))
		TF2_SetPlayerClass(random3, g_Class[random3], true, true);
}

public Action Timer_RevertClasses(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && IsPlayerAlive(i))
			TF2_SetPlayerClass(i, g_Class[i], true, true);
}

public void TF2_OnRoundEnd(int team, int winreason, int flagcaplimit, bool full_round, float round_time, int losing_team_num_caps, bool was_sudden_death)
{
	StopTimer(g_MutationTimer);

	int[] clients = new int[MaxClients];
	int numClients;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		clients[numClients++] = i;
	}

	Panel panel = new Panel();
	panel.SetTitle("Mayhem Points:");

	char sPlayer[128];

	for (int i = 0; i < numClients; i++)
	{
		if (clients[i] == 0)
			continue;
		
		FormatEx(sPlayer, sizeof(sPlayer), "%.2i Points :: %N", g_Mayhem[i].points, clients[i]);
		panel.DrawText(sPlayer);
	}

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			panel.Send(i, MenuAction_Void, MENU_TIME_FOREVER);
	
	delete panel;
}

public int MenuAction_Void(Menu menu, MenuAction action, int param1, int param2)
{

}

public void TF2_OnPlayerSpawn(int client, int team, int class)
{
	TF2Attrib_ApplyMoveSpeedBonus(client, 0.5);
	TF2Attrib_SetByName_Weapons(client, -1, "fire rate bonus", 0.5);

	SetClassAttributes(client, view_as<TFClassType>(class));

	if (!IsFakeClient(client))
		CreateTimer(0.1, Timer_SpawnDelay, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_SpawnDelay(Handle timer, any data)
{
	int client;
	if ((client = GetClientOfUserId(data)) > 0 && IsClientInGame(client) && IsPlayerAlive(client))
		g_Mayhem[client].UpdateHud();
}

public void TF2_OnClassChangePost(int client, TFClassType class)
{
	SetClassAttributes(client, class);
}

void SetClassAttributes(int client, TFClassType class)
{
	switch (class)
	{
		case TFClass_Scout:
		{
			TF2Attrib_SetByName(client, "air dash count", 1.0);
		}
		case TFClass_Soldier:
		{
			TF2Attrib_SetByName(client, "rocket jump damage reduction", 0.25);
		}
		case TFClass_Pyro:
		{
			TF2Attrib_SetByName(client, "airblast cost decreased", 0.25);
			TF2Attrib_SetByName(client, "airblast pushback scale", 1.50);
		}
		case TFClass_DemoMan:
		{
			TF2Attrib_SetByName(client, "Projectile speed increased", 1.25);
		}
		case TFClass_Heavy:
		{
			TF2Attrib_SetByName(client, "minigun spinup time decreased", 0.25);
		}
		case TFClass_Engineer:
		{
			TF2Attrib_SetByName(client, "build rate bonus", 0.25);
		}
		case TFClass_Medic:
		{
			TF2Attrib_SetByName(client, "ubercharge rate bonus", 8.0);
			TF2Attrib_SetByName(client, "uber duration bonus", 5.0);
		}
		case TFClass_Sniper:
		{
			TF2Attrib_SetByName(client, "sniper charge per sec", 2.0);
			TF2Attrib_SetByName(client, "SRifle Charge rate increased", 2.0);
			TF2Attrib_SetByName(client, "mult sniper charge after headshot", 2.0);
		}
		case TFClass_Spy:
		{
			TF2Attrib_SetByName(client, "cloak consume rate decreased", 0.01);
		}
	}
}

public Action GetMaxHealth(int entity, int& maxhealth)
{
	maxhealth *= 3;
	return Plugin_Changed;
}

public Action Command_Mayhem(int client, int args)
{
	g_Mayhem[client].AddPoints(GetCmdArgInt(1));
	return Plugin_Handled;
}

public void TF2_OnPlayerDeath(int client, int attacker, int assister, int inflictor, int damagebits, int stun_flags, int death_flags, int customkill)
{
	if (client != attacker)
		g_Mayhem[attacker].AddPoints(GetRandomInt(4, 6));
}

public void TF2_OnControlPointCaptured(int index, char[] name, int cappingteam, char[] cappers)
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == cappingteam)
			ExplodePlayer(i, 2);
}

public void TF2_OnPlayerTaunting(int client, int index, int defindex)
{
	ExplodePlayer(client, 1);
}

public Action Command_Explode(int client, int args)
{
	ExplodePlayer(client, GetCmdArgInt(1));
	return Plugin_Handled;
}

void ExplodePlayer(int client, int level)
{
	float origin[3];
	GetClientAbsOrigin(client, origin);

	CreateParticle("Explosion_ShockWave_01", origin);
	CreateParticle("rd_robot_explosion", origin);

	float distance = 475.0;
	float damage = 100.0;

	if (level > 1)
	{
		CreateParticle("rd_robot_explosion_bits", origin);
		distance = 485.0;
		damage = 125.0;
	}
		
	if (level > 2)
	{
		CreateParticle("rd_robot_exposion_glow", origin);
		distance = 500.0;
		damage = 150.0;
	}

	if (level > 3)
	{
		CreateParticle("rd_robot_explosion_shockwave", origin);
		distance = 515.0;
		damage = 175.0;
	}

	if (level > 4)
	{
		CreateParticle("rd_robot_explosion_shockwave2", origin);
		distance = 525.0;
		damage = 200.0;
	}

	DamageRadius(origin, distance, damage, client, 0, DMG_BLAST);
	PushAllPlayersFromPoint(origin, 50.0, distance, GetClientTeam(client) == 2 ? 3 : 2, client);

	char sSound[PLATFORM_MAX_PATH];
	FormatEx(sSound, sizeof(sSound), "ambient/explosions/explode_%i.wav", GetRandomInt(1, 9));
	EmitSoundToAll(sSound, client);
}
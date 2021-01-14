/*  CS:GO Weapons&Knives SourceMod Plugin
 *
 *  Copyright (C) 2017 Kağan 'kgns' Üstüngel
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

public void OnConfigsExecuted()
{
	GetConVarString(g_Cvar_DBConnection, g_DBConnection, sizeof(g_DBConnection));
	GetConVarString(g_Cvar_TablePrefix, g_TablePrefix, sizeof(g_TablePrefix));
	g_iGraceInactiveDays = g_Cvar_InactiveDays.IntValue;
	
	if(g_DBConnectionOld[0] != EOS && strcmp(g_DBConnectionOld, g_DBConnection) != 0 && db != null)
	{
		delete db;
		db = null;
	}
	
	if(db == null)
	{
		Database.Connect(SQLConnectCallback, g_DBConnection);
	}
	else
	{
		DeleteInactivePlayerData();
	}
	
	strcopy(g_DBConnectionOld, sizeof(g_DBConnectionOld), g_DBConnection);
	
	g_Cvar_ChatPrefix.GetString(g_ChatPrefix, sizeof(g_ChatPrefix));
	g_iKnifeStatTrakMode = g_Cvar_KnifeStatTrakMode.IntValue;
	g_bEnableFloat = g_Cvar_EnableFloat.BoolValue;
	g_bEnableNameTag = g_Cvar_EnableNameTag.BoolValue;
	g_bEnableStatTrak = g_Cvar_EnableStatTrak.BoolValue;
	g_fFloatIncrementSize = g_Cvar_FloatIncrementSize.FloatValue;
	g_iFloatIncrementPercentage = RoundFloat(g_fFloatIncrementSize * 100.0);
	g_bOverwriteEnabled = g_Cvar_EnableWeaponOverwrite.BoolValue;
	g_iGracePeriod = g_Cvar_GracePeriod.IntValue;
	g_Cvar_VIPGroups.GetString(g_VIPGroups, sizeof(g_VIPGroups));
	if(g_iGracePeriod > 0)
	{
		HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	}
	ReadConfig();
}

public void OnClientPutInServer(int client)
{
	if(IsFakeClient(client))
	{
		if(g_bEnableStatTrak)
			SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	}
	else if(IsValidClient(client))
	{
		g_iIndex[client] = 0;
		g_FloatTimer[client] = INVALID_HANDLE;
		g_bWaitingForNametag[client] = false;
		HookPlayer(client);
	}
}
public void OnClientPostAdminCheck(int client)
{
	if(IsValidClient(client))
	{
		char steam32[20];
		char temp[20];
		GetClientAuthId(client, AuthId_Steam3, steam32, sizeof(steam32));
		strcopy(temp, sizeof(temp), steam32[5]);
		int index;
		if((index = StrContains(temp, "]")) > -1)
		{
			temp[index] = '\0';
		}
		g_iSteam32[client] = StringToInt(temp);
		GetPlayerData(client);
	}
}


public void OnClientDisconnect(int iClient)
{
	g_bPreview[iClient] = false;
	strcopy(g_sPreviewItem[iClient], sizeof g_sPreviewItem[], "");

	if(IsFakeClient(iClient))
	{
		if(g_bEnableStatTrak)
			SDKUnhook(iClient, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	}
	else if(IsValidClient(iClient))
	{
		UnhookPlayer(iClient);	
		g_iSteam32[iClient] = 0;
	}
}

public void OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientDisconnect(i);
		}
	}
	Shop_UnregisterMe();	
}

public bool Open_ws(int iClient, const char[] sFeatureName)
{
	int menuTime;
	if((menuTime = GetRemainingGracePeriodSeconds(iClient)) >= 0)
		CreateMainMenu(iClient).Display(iClient, menuTime);
	return false;
}

/*  CS:GO Gloves SourceMod Plugin
 *
 *  Copyright (C) 2017 Kağan 'kgns' Üstüngel
 * 
 * This program is free software: you can redistribute it and/or modify it
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

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <shop>
#include <vip_core>

#pragma semicolon 1
#pragma newdecls required

#include "gloves/globals.sp"
#include "gloves/hooks.sp"
#include "gloves/helpers.sp"
#include "gloves/database.sp"
#include "gloves/config.sp"
#include "gloves/menus.sp"
#include "gloves/natives.sp"

public Plugin myinfo = 
{
	name = "[Shop] Gloves",
	author = "kgns & TheBO$$#2967",
	description = "CS:GO Gloves Management",
	version = "1.0.0",
	url = "https://discord.gg/9uYJ5J7"
};

public void OnPluginStart()
{
	LoadTranslations("gloves.phrases");
	
	g_Cvar_DBConnection = CreateConVar("sm_gloves_db_connection", "gloves", "Database connection name in databases.cfg to use");
	g_Cvar_TablePrefix = CreateConVar("sm_gloves_table_prefix", "shop_", "Prefix for database table (example: 'xyz_')");
	g_Cvar_ChatPrefix = CreateConVar("sm_gloves_chat_prefix", "[GLOVES]", "Prefix for chat messages");
	g_Cvar_EnableFloat = CreateConVar("sm_gloves_enable_float", "1", "Enable/Disable gloves float options");
	g_Cvar_FloatIncrementSize = CreateConVar("sm_gloves_float_increment_size", "0.1", "Increase/Decrease by value for gloves float");
	g_Cvar_EnableWorldModel = CreateConVar("sm_gloves_enable_world_model", "1", "Enable/Disable gloves to be seen by other living players");
	g_Cvar_VIPGroups = CreateConVar("sm_gloves_vip_groups", "", "VIP Groups that get skins for free");
	
	AutoExecConfig(true, "shop_gloves", "shop");

	RegConsoleCmd("sm_gloves", CommandGlove);
	RegConsoleCmd("sm_glove", CommandGlove);
	RegConsoleCmd("sm_glov", CommandGlove);
	RegConsoleCmd("sm_gl", CommandGlove);
	RegConsoleCmd("sm_eldiven", CommandGlove);
	RegConsoleCmd("sm_arms", CommandGlove);
	RegConsoleCmd("sm_arm", CommandGlove);

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);

	if(Shop_IsStarted()) Shop_Started();
}

public void OnConfigsExecuted()
{
	GetConVarString(g_Cvar_DBConnection, g_DBConnection, sizeof(g_DBConnection));
	GetConVarString(g_Cvar_TablePrefix, g_TablePrefix, sizeof(g_TablePrefix));
	
	if(g_DBConnectionOld[0] != EOS && strcmp(g_DBConnectionOld, g_DBConnection) != 0 && db != null)
	{
		delete db;
		db = null;
	}
	
	if(db == null)
	{
		Database.Connect(SQLConnectCallback, g_DBConnection);
	}

	strcopy(g_DBConnectionOld, sizeof(g_DBConnectionOld), g_DBConnection);
	
	g_Cvar_ChatPrefix.GetString(g_ChatPrefix, sizeof(g_ChatPrefix));
	g_iEnableFloat = g_Cvar_EnableFloat.IntValue;
	g_fFloatIncrementSize = g_Cvar_FloatIncrementSize.FloatValue;
	g_iFloatIncrementPercentage = RoundFloat(g_fFloatIncrementSize * 100.0);
	g_iEnableWorldModel = g_Cvar_EnableWorldModel.IntValue;
	g_Cvar_VIPGroups.GetString(g_VIPGroups, sizeof(g_VIPGroups));
	ReadConfig();
}

public void OnPluginEnd()
{
	Shop_UnregisterMe();	
}

public bool Open_gloves(int iClient, const char[] sFeatureName)
{

	CreateMainMenu(iClient).Display(iClient, MENU_TIME_FOREVER);
	return false;
}
public Action CommandGlove(int client, int args)
{
	if(!Shop_IsAuthorized(client))
	{
		PrintToChat(client, "You don't have access to change gloves before shop load, just wait a few seconds and retry");
		return Plugin_Handled;
	}
	
	if (IsValidClient(client))
	{
		CreateMainMenu(client).Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public void OnClientDisconnect(int iClient)
{
	g_bPreview[iClient] = false;
	strcopy(g_sPreviewItem[iClient], sizeof g_sPreviewItem[], "");
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

public void GivePlayerGloves(int client)
{
	if(g_iGloves[client] != 0)
	{
		int ent = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
		if(ent != -1)
		{
			AcceptEntityInput(ent, "KillHierarchy");
		}
		FixCustomArms(client);
		ent = CreateEntityByName("wearable_item");
		if(ent != -1)
		{
			SetEntProp(ent, Prop_Send, "m_iItemIDLow", -1);
			SetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex", g_iGroup[client]);
			SetEntProp(ent, Prop_Send,  "m_nFallbackPaintKit", g_iGloves[client]);
			SetEntPropFloat(ent, Prop_Send, "m_flFallbackWear", g_fFloatValue[client]);
			SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
			SetEntPropEnt(ent, Prop_Data, "m_hParent", client);
			if(g_iEnableWorldModel) SetEntPropEnt(ent, Prop_Data, "m_hMoveParent", client);
			SetEntProp(ent, Prop_Send, "m_bInitialized", 1);
			
			DispatchSpawn(ent);
			
			SetEntPropEnt(client, Prop_Send, "m_hMyWearables", ent);
			if(g_iEnableWorldModel) SetEntProp(client, Prop_Send, "m_nBody", 1);
		}
	}
}

bool CheckToGiveGloves(int iClient, const char[] sInfo, bool bOff = false, bool bFromShop = false)
{
	char buffer[2][10];
	ExplodeString(sInfo, ";", buffer, 2, 10);
	int groupId = StringToInt(buffer[0]);
	int gloveId = bOff ? 0 : StringToInt(buffer[1]);

	ItemId item = Shop_GetItemId(g_cCategory, sInfo);
	if(item > INVALID_ITEM && !g_bPreview[iClient] && !bFromShop)
	{
		if(!Shop_IsClientHasItem(iClient, item))
		{
			Shop_ShowItemPanel(iClient,item);
			return false;
		}
	}
	
	g_iGroup[iClient] = groupId;
	g_iGloves[iClient] = gloveId;
	char updateFields[128];

	if (!g_bPreview[iClient])
	{
		Format(updateFields, sizeof(updateFields), "groupid = %d, gloveid = %d", groupId, gloveId);
		UpdatePlayerData(iClient, updateFields);
	}
	
	int activeWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");

	if(activeWeapon != -1)
	{
		SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", -1);
	}

	if(gloveId == 0)
	{
		int ent = GetEntPropEnt(iClient, Prop_Send, "m_hMyWearables");

		if(ent != -1)
		{
			AcceptEntityInput(ent, "KillHierarchy");
		}

		SetEntPropString(iClient, Prop_Send, "m_szArmsModel", g_CustomArms[iClient]);
	}

	GivePlayerGloves(iClient);

	if(activeWeapon != -1)
	{
		DataPack dpack;
		CreateDataTimer(0.1, ResetGlovesTimer, dpack);
		dpack.WriteCell(iClient);
		dpack.WriteCell(activeWeapon);
	}

	return true;
}
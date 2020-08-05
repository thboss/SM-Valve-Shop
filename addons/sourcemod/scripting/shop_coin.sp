#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools_functions>
#include <shop>

// Force 1.7 syntax
#pragma newdecls required

#define PLUGIN_VERSION "2.3"
#define CATEGORY "Coins"

CategoryId g_CategoryId;

KeyValues kv;

int m_nActiveCoinRank;

int g_iClientCoin[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "[SHOP] Coins",
	description = "Adds coins to shop",
	author = "White Wolf (HLModders LLC)",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	CreateConVar("sm_shop_coins_version", PLUGIN_VERSION, _, FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	m_nActiveCoinRank = FindSendPropInfo("CCSPlayerResource", "m_nActiveCoinRank");
	if (m_nActiveCoinRank == -1)
		SetFailState("Fatal Error: Unable to find offset: \"CCSPlayerResource::m_nActiveCoinRank\"");
	
	if (Shop_IsStarted()) Shop_Started();
}

public void OnPluginEnd()
{
	Shop_UnregisterMe();
	
}

public void Shop_Started()
{
	if (kv != null) kv.Close();
	kv = new KeyValues("Coins");
	
	char buffer[PLATFORM_MAX_PATH];
	Shop_GetCfgFile(buffer, sizeof(buffer), "coins.txt");
	
	if (!kv.ImportFromFile(buffer)) SetFailState("Couldn't parse file %s", buffer);
	
	if (kv.GotoFirstSubKey(true))
	{
		char item[64];
		int	coin;
		int iLuckChance;
		// Register category `coins`
		g_CategoryId = Shop_RegisterCategory(CATEGORY, "Medals", "");
		do
		{
			if (kv.GetSectionName(item, sizeof(item)))
			{
				coin = StringToInt(item);
				if (coin > 0)
				{
					FormatEx(buffer, sizeof(buffer), "coin_%s", item);
					if (Shop_StartItem(g_CategoryId, buffer))
					{
						kv.GetString("name", buffer, sizeof(buffer), item);
						kv.GetString("desc", item, sizeof(item), "");
						Shop_SetInfo(buffer, item, kv.GetNum("price", 1000), kv.GetNum("sell_price", kv.GetNum("price")/2), Item_Togglable, kv.GetNum("duration", 0), kv.GetNum("gold_price", -1), kv.GetNum("gold_sell_price", -1));
						Shop_SetCallbacks(_, OnEquipItem);
						Shop_SetCustomInfo("coin_id", coin);

						if(kv.GetNum("price") > 0 && kv.GetNum("price") <= 50)
							iLuckChance = 30;	
						else if(kv.GetNum("price") > 50 && kv.GetNum("price") <= 500)
							iLuckChance = 20;
						else if(kv.GetNum("price") > 500 && kv.GetNum("price") <= 1000)
							iLuckChance = 10;	
						else if(kv.GetNum("price") > 1000 && kv.GetNum("price") <= 2000)
							iLuckChance = 8;
						else if(kv.GetNum("price") > 2000 && kv.GetNum("price") <= 3000)
							iLuckChance = 7;
						else if(kv.GetNum("price") > 3000 && kv.GetNum("price") <= 5000)
							iLuckChance = 6;
						else if(kv.GetNum("price") > 5000 && kv.GetNum("price") <= 10000)
							iLuckChance = 5;
						else if(kv.GetNum("price") > 10000 && kv.GetNum("price") <= 15000)
							iLuckChance = 4;
						else if(kv.GetNum("price") > 15000 && kv.GetNum("price") <= 25000)
							iLuckChance = 3;
						else if(kv.GetNum("price") > 25000 && kv.GetNum("price") <= 40000)
							iLuckChance = 2;
						else
							iLuckChance = 1;						
						
						Shop_SetLuckChance(kv.GetNum("luckchance", iLuckChance));
						Shop_SetHide(view_as<bool>(kv.GetNum("hidden", 0)));
						Shop_EndItem();
					}
				}
			}
		} while (kv.GotoNextKey(true));
	}
	kv.Rewind();
}

public void OnMapStart()
{
	SDKHook(FindEntityByClassname(MaxClients+1, "cs_player_manager"), SDKHook_ThinkPost, Hook_OnThinkPost);
}

public ShopAction OnEquipItem(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, bool isOn, bool elapsed)
{
	if (isOn || elapsed)
	{
		g_iClientCoin[client] = 0;
		return Shop_UseOff;
	}
	Shop_ToggleClientCategoryOff(client, category_id);
	g_iClientCoin[client] = Shop_GetItemCustomInfo(item_id, "coin_id");
	return Shop_UseOn;
}

public void Hook_OnThinkPost(int entity)
{
	for (int i = 1; i <= MaxClients; ++i)
		if (g_iClientCoin[i])
			SetEntData(entity, m_nActiveCoinRank + i*4, g_iClientCoin[i], 4, true);
}
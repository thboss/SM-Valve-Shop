#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <clientprefs>
#include <shop>

#pragma newdecls required

#define CATEGORY "Mkit"

CategoryId g_CategoryId;

KeyValues kv;

Handle MKitCookie;

int g_iClientMkit[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "[SHOP] Music Kit",
	author = "TheBO$$#2967",
	description = "",
	version = "1.0.0",
	url = "https://discord.gg/9uYJ5J7"
};

public void OnPluginStart()
{	

	MKitCookie = RegClientCookie("MusicKit", "MusicKit", CookieAccess_Protected);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			if(!AreClientCookiesCached(i))
			{
				continue;
			}
			OnClientCookiesCached(i);
		}	
	}
	
	if (Shop_IsStarted()) Shop_Started();
}

public void OnPluginEnd()
{		
	Shop_UnregisterMe();	
}

public void OnClientCookiesCached(int client)
{
	if(IsFakeClient(client))
	{
		return;
	}

	GetIntCookie(client, MKitCookie);
}

public void Shop_Started()
{
	if (kv != null) kv.Close();
	kv = new KeyValues("Mkit");
	
	char buffer[PLATFORM_MAX_PATH];
	Shop_GetCfgFile(buffer, sizeof(buffer), "mkits.txt");
	
	if (!kv.ImportFromFile(buffer)) SetFailState("Couldn't parse file %s", buffer);
	
	if (kv.GotoFirstSubKey(true))
	{
		char item[64];
		int	mkit;
		int iLuckChance;
		g_CategoryId = Shop_RegisterCategory(CATEGORY, "MusicKit", "");
		do
		{
			if (kv.GetSectionName(item, sizeof(item)))
			{
				mkit = StringToInt(item);
				if (mkit > 0)
				{
					FormatEx(buffer, sizeof(buffer), "mkit_%s", item);
					if (Shop_StartItem(g_CategoryId, buffer))
					{
						kv.GetString("name", buffer, sizeof(buffer), item);
						kv.GetString("desc", item, sizeof(item), "");
						Shop_SetInfo(buffer, item, kv.GetNum("price", 1000), kv.GetNum("sell_price", kv.GetNum("price")/2), Item_Togglable, kv.GetNum("duration", 0), kv.GetNum("gold_price", -1), kv.GetNum("gold_sell_price", -1));
						Shop_SetCallbacks(_, OnEquipItem);
						Shop_SetCustomInfo("mkit_id", mkit);

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
						Shop_EndItem();
					}
				}
			}
		} while (kv.GotoNextKey(true));
	}
	kv.Rewind();
}


public ShopAction OnEquipItem(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, bool isOn, bool elapsed)
{
	if (isOn || elapsed)
	{
		g_iClientMkit[client] = 0;
		//SetEntProp(client, Prop_Send, "m_unMusicID", g_iClientMkit[client]);
		SDKHook(client, SDKHook_PostThink, Hook_OnThinkPost);
		save_mkit(client, g_iClientMkit[client]);
		return Shop_UseOff;
	}
	Shop_ToggleClientCategoryOff(client, category_id);
	g_iClientMkit[client] = Shop_GetItemCustomInfo(item_id, "mkit_id");
	//SetEntProp(client, Prop_Send, "m_unMusicID", g_iClientMkit[client]);
	SDKHook(client, SDKHook_PostThink, Hook_OnThinkPost);
	save_mkit(client, g_iClientMkit[client]);
	return Shop_UseOn;
}

public bool SellCallback(int iClient, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ItemType type, int sell_price, int gold_sell_price)
{
	save_mkit(iClient, g_iClientMkit[iClient]);
	return true;				
}
public bool Shop_OnItemTransfer(int iClient, int iTarget, ItemId item_id)
{
	if(g_CategoryId != Shop_GetItemCategoryId(item_id)) return true;

	g_iClientMkit[iClient] = 0;
	save_mkit(iClient, g_iClientMkit[iClient]);

	return true;
}

public void OnClientPutInServer(int iClient)
{
	char sCookieValue[10];
	SDKHook(iClient, SDKHook_PostThink, Hook_OnThinkPost);
	GetClientCookie(iClient, MKitCookie, sCookieValue, sizeof(sCookieValue));
	g_iClientMkit[iClient] = StringToInt(sCookieValue);
}

public void save_mkit(int iClient, int mkit)
{
	char sCookieValue[10]; // больше бл*** чаров
	IntToString(mkit, sCookieValue, sizeof(sCookieValue));
	SetClientCookie(iClient, MKitCookie, sCookieValue);
}

int GetIntCookie(int client, Handle handle)
{
	char sCookieValue[11];
	GetClientCookie(client, handle, sCookieValue, sizeof(sCookieValue));
	return StringToInt(sCookieValue);
}

bool IsClientValid(int client)
{
	if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
		return true;
	return false;
}

public void Hook_OnThinkPost(int iClient)
{
	SetEntProp(iClient, Prop_Send, "m_unMusicID", g_iClientMkit[iClient]);
} 

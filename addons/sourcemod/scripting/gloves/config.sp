/*  CS:GO Gloves SourceMod Plugin
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

public void ReadConfig()
{
	if(g_smGlovesGroupIndex != null) delete g_smGlovesGroupIndex;
	g_smGlovesGroupIndex = new StringMap();

		
	BuildPath(Path_SM, configPath, sizeof(configPath), "configs/gloves/gloves.cfg");
		
	KeyValues kv = CreateKeyValues("Gloves");
	FileToKeyValues(kv, configPath);
		
	if (!KvGotoFirstSubKey(kv))
	{
		SetFailState("CFG File not found: %s", configPath);
		CloseHandle(kv);
	}	
		
	for (int k = CS_TEAM_T; k <= CS_TEAM_CT; k++)
	{
		if(menuGlovesGroup[k] != null)
		{
			delete menuGlovesGroup[k];
		}
		menuGlovesGroup[k] = new Menu(GloveMainMenuHandler, MENU_ACTIONS_DEFAULT|MenuAction_DisplayItem);
		menuGlovesGroup[k].SetTitle("%T", "GloveMenuTitle", LANG_SERVER);
		menuGlovesGroup[k].AddItem("0", "Default");
		menuGlovesGroup[k].ExitBackButton = true;
	}
		
	int counter = 1;
	do {
		char name[64];
		char index[10];
		char group[10];
		char team[32];
		char temp[1];
		char buffer[20];
			
		KvGetSectionName(kv, name, sizeof(name));
		KvGetString(kv, "index", group, sizeof(group));
		g_smGlovesGroupIndex.SetValue(group, counter);
		KvGotoFirstSubKey(kv);
		for (int k = CS_TEAM_T; k <= CS_TEAM_CT; k++)
		{
			IntToString(counter, index, sizeof(index));
			menuGlovesGroup[k].AddItem(index, name);
			
			if(menuGloves[k][counter] != null)
			{
				delete menuGloves[k][counter];
			}
			menuGloves[k][counter] = new Menu(GloveMenuHandler, MENU_ACTIONS_DEFAULT|MenuAction_DisplayItem);
			menuGloves[k][counter].SetTitle(name);
			Format(buffer, sizeof(buffer), "%s;-1", group);
				
			menuGloves[k][counter].ExitBackButton = true;
		}
		do {
			KvGetSectionName(kv, name, sizeof(name));
			KvGetString(kv, "index", index, sizeof(index));
			KvGetString(kv, "team", team, sizeof(team));
			for (int k = CS_TEAM_T; k <= CS_TEAM_CT; k++)
			{
				IntToString(k, temp, sizeof(temp));
				
				if(StrContains(team, temp) > -1)
				{
					Format(buffer, sizeof(buffer), "%s;%s", group, index);
					menuGloves[k][counter].AddItem(buffer, name);
				}
			}
		} while (KvGotoNextKey(kv));
		KvGoBack(kv);
		counter++;
	} while (KvGotoNextKey(kv));
		
	CloseHandle(kv);
}

/*
"gloves"
{
	"skin_name"
	{
		"groupid" "5035"
		"id" "10057"
		"discription" "gg"
		"price" "10000"
		"duraction" "65000"
		"luckchance" "20"
	}
}
*/
public void Shop_Started()
{
	char szPath[PLATFORM_MAX_PATH];
	Shop_GetCfgFile(szPath, sizeof szPath, "gloves.ini");

	KeyValues hKv = new KeyValues("gloves");
	if(!hKv.ImportFromFile(szPath))	 SetFailState("Could read config file [%s]", szPath);

	int iLuckChance;
	char szKey[32];
	char szName[64];
	char szDiscription[128];

	g_fPreviewDuration = hKv.GetFloat("preview_duration", 4.0);

	hKv.GetString("name", szName, sizeof szName, "Gloves");
	g_cCategory = Shop_RegisterCategory("gloves_", szName, NULL_STRING);

	if (!hKv.GotoFirstSubKey()) SetFailState("Could read config file [%s]", szPath);

	do
	{
		if(!hKv.GetSectionName(szName, sizeof szName)) continue;

		hKv.GetString("discription", szDiscription, sizeof szDiscription);
		FormatEx(szKey, sizeof szKey, "%d;%d", hKv.GetNum("groupid"), hKv.GetNum("id"));

		if(!Shop_StartItem(g_cCategory,szKey)) continue;

		Shop_SetCallbacks(_, OnEquipItem, _, _, _, OnPreviewItem, _, SellCallback);
		Shop_SetInfo(szName, szDiscription, hKv.GetNum("price",7000),  hKv.GetNum("sellprice",hKv.GetNum("price")/2), Item_Togglable, hKv.GetNum("duration",0) );

		if(hKv.GetNum("price") > 0 && hKv.GetNum("price") <= 50)
			iLuckChance = 30;	
		else if(hKv.GetNum("price") > 50 && hKv.GetNum("price") <= 500)
			iLuckChance = 20;
		else if(hKv.GetNum("price") > 500 && hKv.GetNum("price") <= 1000)
			iLuckChance = 10;	
		else if(hKv.GetNum("price") > 1000 && hKv.GetNum("price") <= 2000)
			iLuckChance = 8;
		else if(hKv.GetNum("price") > 2000 && hKv.GetNum("price") <= 3000)
			iLuckChance = 7;
		else if(hKv.GetNum("price") > 3000 && hKv.GetNum("price") <= 5000)
			iLuckChance = 6;
		else if(hKv.GetNum("price") > 5000 && hKv.GetNum("price") <= 10000)
			iLuckChance = 5;
		else if(hKv.GetNum("price") > 10000 && hKv.GetNum("price") <= 15000)
			iLuckChance = 4;
		else if(hKv.GetNum("price") > 15000 && hKv.GetNum("price") <= 25000)
			iLuckChance = 3;
		else if(hKv.GetNum("price") > 25000 && hKv.GetNum("price") <= 40000)
			iLuckChance = 2;
		else
			iLuckChance = 1;

		Shop_SetLuckChance(hKv.GetNum("luckchance", iLuckChance));		
		Shop_EndItem();
	}
	while(hKv.GotoNextKey());
	delete hKv;
}

public Action Shop_OnItemDraw(int iClient, ShopMenu menu_action, CategoryId category_id, ItemId item_id, bool &disable)
{
	int playerTeam = GetClientTeam(iClient);
	
	if( menu_action == Menu_Buy && g_cCategory == category_id)
	{
		if(CS_TEAM_T <= playerTeam <= CS_TEAM_CT)
		{
			g_iTeam[iClient] = playerTeam;
			//RequestFrame(MainMenuOpen,iClient); 
			return Plugin_Continue;
		}
		else
		{
			g_iTeam[iClient] = CS_TEAM_CT;
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}
/*
public void MainMenuOpen(int iClient)
{
	menuGlovesGroup[g_iTeam[iClient]].Display(iClient, MENU_TIME_FOREVER);
}
*/
public bool SellCallback(int iClient, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ItemType type, int sell_price, int gold_sell_price)
{
	int playerTeam = GetClientTeam(iClient);
	if(CS_TEAM_T <= playerTeam <= CS_TEAM_CT)
		g_iTeam[iClient] = playerTeam;
		
	char sCategory[16];
	for(int x = 0; x < strlen(item); x++)
	{
		if(x && item[x -1] == ';') 
		{
			sCategory[x] = '0';
			break;
		}
		sCategory[x] = item[x];
	}
	CheckToGiveGloves(iClient, sCategory);
	return true;				
}
public bool Shop_OnItemTransfer(int iClient, int iTarget, ItemId item_id)
{
	if(g_cCategory != Shop_GetItemCategoryId(item_id)) return true;
	
	int playerTeam = GetClientTeam(iClient);
	if(CS_TEAM_T <= playerTeam <= CS_TEAM_CT)
		g_iTeam[iClient] = playerTeam;
		
	char sItem[16];
	Shop_GetItemById(item_id, sItem, sizeof sItem);
	char sCategory[16];
	GetGloveCategoryFromItem(sItem, strlen(sItem), sCategory);
	CheckToGiveGloves(iClient, sCategory);

	return true;
}
public ShopAction OnEquipItem(int iClient, CategoryId category_id, const char[] sCategory,ItemId item_id, const char[] sItem, bool IsOn, bool elapsed)
{
	int playerTeam = GetClientTeam(iClient);
		
	if(IsOn || elapsed)
	{
		if(CS_TEAM_T <= playerTeam <= CS_TEAM_CT)
			g_iTeam[iClient] = playerTeam;	
		CheckToGiveGloves(iClient, sItem, true, true);
		return Shop_UseOff;
	}

	if(CS_TEAM_T <= playerTeam <= CS_TEAM_CT)
		g_iTeam[iClient] = playerTeam;	

	Shop_ToggleClientCategoryOff(iClient, category_id);
	CheckToGiveGloves(iClient, sItem, _, true);
	return Shop_UseOn;

}

public void OnPreviewItem(int iClient, CategoryId category_id, const char[] sCategory, ItemId item_id, const char[] sItem)
{
	if (!g_bPreview[iClient] && IsPlayerAlive(iClient))
	{
		g_bPreview[iClient] = true;

		int playerTeam = GetClientTeam(iClient);

		if(CS_TEAM_T <= playerTeam <= CS_TEAM_CT)
			g_iPrevieTeam[iClient] = playerTeam;	

		CheckToGiveGloves(iClient, sItem, _, true);

		CreateTimer(g_fPreviewDuration, RemovePreview, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
		strcopy(g_sPreviewItem[iClient], sizeof g_sPreviewItem[], sItem);
	}
}

public Action RemovePreview(Handle hTimer, int iClient)
{
	if ((iClient = GetClientOfUserId(iClient)))
	{
		CheckToGiveGloves(iClient, g_sPreviewItem[iClient], true, true);
		g_iPrevieTeam[iClient] = 0;
		g_bPreview[iClient] = false;

		GetPlayerData(iClient);
		CreateTimer(0.1, ResetGlove, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action ResetGlove(Handle hTimer, int iClient)
{
	if ((iClient = GetClientOfUserId(iClient)) && g_iGloves[iClient][GetClientTeam(iClient)] != 0)
	{
		int ent = GetEntPropEnt(iClient, Prop_Send, "m_hMyWearables");
		if(ent != -1)
		{
			AcceptEntityInput(ent, "KillHierarchy");
		}

		int activeWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
		if(activeWeapon != -1)
		{
			SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", -1);
		}

		GivePlayerGloves(iClient);
		if(activeWeapon != -1)
		{
			DataPack dpack;
			CreateDataTimer(0.1, ResetGlovesTimer, dpack);
			dpack.WriteCell(iClient); 
			dpack.WriteCell(activeWeapon);
		}
	}
}

void GetGloveCategoryFromItem(const char[] sItem, int iLen, char[] sCategory)
{
	LogError("sItem = %s", sItem);
	for(int x = 0; x < iLen; x++)
	{
		if(sItem[x] == ';') 
		{
			//sCategory[x] = '0';
			break;
		}
		sCategory[x] = sItem[x];
	}
}
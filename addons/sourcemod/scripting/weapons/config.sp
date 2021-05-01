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

public void ReadConfig()
{
	if(g_smWeaponIndex != null) delete g_smWeaponIndex;
	g_smWeaponIndex = new StringMap();
	if(g_smWeaponDefIndex != null) delete g_smWeaponDefIndex;
	g_smWeaponDefIndex = new StringMap();
	
	for (int i = 0; i < sizeof(g_WeaponClasses); i++)
	{
		g_smWeaponIndex.SetValue(g_WeaponClasses[i], i);
		g_smWeaponDefIndex.SetValue(g_WeaponClasses[i], g_iWeaponDefIndex[i]);
	}
	
	BuildPath(Path_SM, configPath, sizeof(configPath), "configs/shop/weapon_skins.ini");
		
	KeyValues kv = CreateKeyValues("ws");
	FileToKeyValues(kv, configPath);
		
	if (!KvGotoFirstSubKey(kv))
	{
		SetFailState("CFG File not found: %s", configPath);
		CloseHandle(kv);
	}
	
	for (int k = 0; k < sizeof(g_WeaponClasses); k++)
	{
		if(menuWeapons[k] != null)
		{
			delete menuWeapons[k];
		}
		menuWeapons[k] = new Menu(WeaponsMenuHandler, MENU_ACTIONS_DEFAULT|MenuAction_DisplayItem);
		menuWeapons[k].SetTitle("%T", g_WeaponClasses[k], LANG_SERVER);
		menuWeapons[k].AddItem("0", "Default");
		menuWeapons[k].ExitBackButton = true;
	}

	do {
		char name[64];
		char id[4];
		char weapon[32];
		char szKey[64];
		int price;
			
		KvGetSectionName(kv, name, sizeof(name));
		KvGetString(kv, "weapon", weapon, sizeof(weapon));
		KvGetString(kv, "id", id, sizeof(id));
		price = KvGetNum(kv, "price");
			
		for (int k = 0; k < sizeof(g_WeaponClasses); k++)
		{
			if (StrEqual(weapon, g_WeaponClasses[k]))
			{
				FormatEx(szKey, sizeof(szKey), "[%d$] %s", price, name);
				menuWeapons[k].AddItem(id, szKey);
			}
		}

	} while (KvGotoNextKey(kv));
		
	CloseHandle(kv);
}
/*
"ws"
{
	"skin_name"
	{
		"id" 			"594"
		"discription" 	"gg"
		"weapon" 		"weapon_glock"
		"price" 		"10000"
		"duraction" 	"65000"
		"sellprice" 	"7000"
		"luckchance" 	"0"
	}
}
*/
public Action Timer_Delay(Handle hTimer)
{
	Shop_Started();
}
public void Shop_Started()
{
	if(g_smWeaponIndex == null)
	{
		CreateTimer(5.0, Timer_Delay, _, TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
	char szPath[PLATFORM_MAX_PATH];
	Shop_GetCfgFile(szPath, sizeof szPath, "weapon_skins.ini");

	KeyValues hKv = new KeyValues("ws");
	if(!hKv.ImportFromFile(szPath))	 SetFailState("Could read config file [%s]", szPath);

	int iWeaponIndex;

	char szWeapon[32];
	char szKey[32];
	char szName[64];
	char szDiscription[128];

	g_fPreviewDuration = hKv.GetFloat("preview_duration", 4.0);
	hKv.GetString("name", szName, sizeof szName, "Weapon Skins");
	g_cCategory = Shop_RegisterCategory("weapon_skins", szName, NULL_STRING);

	if(!hKv.GotoFirstSubKey())	 SetFailState("Could read config file [%s]", szPath);
 
	do
	{
		if(!hKv.GetSectionName(szName, sizeof szName)) continue;

		hKv.GetString("weapon", szWeapon, sizeof szWeapon);
		hKv.GetString("discription", szDiscription, sizeof szDiscription);
		g_smWeaponIndex.GetValue(szWeapon, iWeaponIndex);
		FormatEx(szKey, sizeof szKey, "%d_%d", hKv.GetNum("id"), iWeaponIndex);

		if(!Shop_StartItem(g_cCategory,szKey)) continue;

		Shop_SetCallbacks(_, OnEquipItem, _, _, _, OnPreviewItem, _, SellCallback);
		Shop_SetInfo(szName, szDiscription, hKv.GetNum("price",7000),  hKv.GetNum("sellprice",hKv.GetNum("price")/2), Item_Togglable, hKv.GetNum("duration", 0) );

		Shop_SetLuckChance(hKv.GetNum("luckchance", 0));
		Shop_EndItem();
	}
	while(hKv.GotoNextKey());
	delete hKv;
}
/*
public Action Shop_OnItemDraw(int iClient, ShopMenu menu_action, CategoryId category_id, ItemId item_id, bool &disable)
{
	if( g_cCategory == category_id)
	{
		if(menu_action == Menu_Buy)
		{
			//RequestFrame(MainMenuOpen,iClient); 
			return Plugin_Continue;
			//return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void MainMenuOpen(int iClient)
{
	CreateAllWeaponsMenu(iClient).Display(iClient, MENU_TIME_FOREVER);
}
*/
public bool SellCallback(int iClient, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ItemType type, int sell_price, int gold_sell_price)
{
	RemoveClientSkins(iClient, item);
	return true;				
}
public bool Shop_OnItemTransfer(int iClient, int iTarget, ItemId item_id)
{
	if(g_cCategory != Shop_GetItemCategoryId(item_id)) return true;

	char sItem[16];
	Shop_GetItemById(item_id, sItem, sizeof sItem);
	RemoveClientSkins(iClient, sItem);

	return true;
}
public ShopAction OnEquipItem(int iClient, CategoryId category_id, const char[] sCategory,ItemId item_id, const char[] sItem, bool IsOn, bool elapsed)
{	
	if (IsOn || elapsed)
	{
		RemoveClientSkins(iClient, sItem);
		return Shop_UseOff;
	}

	int iLen = strlen(sItem);
	char sIndex[8];
	char sWeaponId[16];
	for(int x = iLen - 1; x > 0; x--) if(sItem[x] == '_')
	{
		strcopy(sIndex, sizeof sIndex, sItem[x + 1]);
		strcopy(sWeaponId, x + 1, sItem);
		break;
	}
	int index = StringToInt(sIndex);
	int iWeaponId = StringToInt(sWeaponId);
	if(IsKnifeIndex(index))
	{
		g_iKnife[iClient] = index;
		char updateFields[50];
		Format(updateFields, sizeof(updateFields), "knife = %d", index);
		UpdatePlayerData(iClient, updateFields);
	}

	Shop_ToggleClientCategoryOff(iClient, category_id);
	CheckToSetWeapon(iClient, index, iWeaponId, true);
	return Shop_UseOn;
}

public void OnPreviewItem(int iClient, CategoryId category_id, const char[] sCategory, ItemId item_id, const char[] sItem)
{
	if (!g_bPreview[iClient] && IsPlayerAlive(iClient))
	{
		g_bPreview[iClient] = true;

		int iLen = strlen(sItem);
		char sIndex[8];
		char sWeaponId[16];
		for(int x = iLen - 1; x > 0; x--) if(sItem[x] == '_')
		{
			strcopy(sIndex, sizeof sIndex, sItem[x + 1]);
			strcopy(sWeaponId, x + 1, sItem);
			break;
		}
		int index = StringToInt(sIndex);
		int iWeaponId = StringToInt(sWeaponId);
		if(IsKnifeIndex(index))
		{
			g_iKnife[iClient] = index;
		}

		CheckToSetWeapon(iClient, index, iWeaponId, true);
		if(IsKnifeIndex(index))
		{
			CreateTimer(g_fPreviewDuration, RemoveKnifePreview, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
		}
		else CreateTimer(g_fPreviewDuration, RemoveWeaponPreview, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);

		strcopy(g_sPreviewItem[iClient], sizeof g_sPreviewItem[], sItem);
	}
}

public Action RemoveKnifePreview(Handle hTimer, int iClient)
{
	if ((iClient = GetClientOfUserId(iClient)))
	{
		RemoveClientSkins(iClient, g_sPreviewItem[iClient]);
		g_bPreview[iClient] = false;
		
		GetOldPlayerData(iClient);
		
		CreateTimer(0.1, ResetKnifeSkin, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action ResetKnifeSkin(Handle hTimer, int iClient)
{
	if ((iClient = GetClientOfUserId(iClient)))
	{
		if(g_iKnife[iClient] == 0)
			RefreshWeapon(iClient, g_iKnife[iClient], true);
		else RefreshWeapon(iClient, g_iKnife[iClient]);
	}
}

public Action RemoveWeaponPreview(Handle hTimer, int iClient)
{
	if ((iClient = GetClientOfUserId(iClient)))
	{
		RemoveClientSkins(iClient, g_sPreviewItem[iClient]);
		g_bPreview[iClient] = false;
		
		GetOldPlayerData(iClient);
		CreateTimer(0.1, ResetWeaponSkin, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action ResetWeaponSkin(Handle hTimer, int iClient)
{
	if ((iClient = GetClientOfUserId(iClient)))
	{
		RefreshWeapon(iClient, g_iIndex[iClient]);
	}
}

void RemoveClientSkins(int iClient, const char[] sItem)
{
	int iLen = strlen(sItem);
	char sIndex[8];
	char sWeaponId[16];
	for(int x = iLen - 1; x > 0; x--) if(sItem[x] == '_')
	{
		strcopy(sIndex, sizeof sIndex, sItem[x + 1]);
		strcopy(sWeaponId, x + 1, sItem);
		break;
	}
	int index = StringToInt(sIndex);
	int iWeaponId = StringToInt(sWeaponId);
	if(g_iSkins[iClient][index] != iWeaponId) return;
	g_iSkins[iClient][index] = 0;
	
	char updateFields[256];
	char weaponName[32];
	RemoveWeaponPrefix(g_WeaponClasses[index], weaponName, sizeof(weaponName));
	if (!g_bPreview[iClient])
	{
		Format(updateFields, sizeof(updateFields), "%s = %d", weaponName, 0);
		UpdatePlayerData(iClient, updateFields);
		RefreshWeapon(iClient, index);
	}
}
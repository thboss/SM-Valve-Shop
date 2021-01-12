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

public int GloveMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{				
				char gloveIdStr[20];
				menu.GetItem(selection, gloveIdStr, sizeof(gloveIdStr));
				if(!CheckToGiveGloves(client, gloveIdStr)) return 0;

				char buffer[2][10];
				ExplodeString(gloveIdStr, ";", buffer, 2, 10);
				int groupId = StringToInt(buffer[0]);
				int gloveId = StringToInt(buffer[1]);
				
				g_iGroup[client] = groupId;
				g_iGloves[client] = gloveId;
				char updateFields[128];
				
				Format(updateFields, sizeof(updateFields), "groupid = %d, gloveid = %d", groupId, gloveId);
				UpdatePlayerData(client, updateFields);
				
				int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(activeWeapon != -1)
				{
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1);
				}
				GivePlayerGloves(client);
				if(activeWeapon != -1)
				{
					DataPack dpack;
					CreateDataTimer(0.1, ResetGlovesTimer, dpack);
					dpack.WriteCell(client);
					dpack.WriteCell(activeWeapon);
				}

				DataPack pack;
				CreateDataTimer(0.5, GlovesMenuTimer, pack);
				pack.WriteCell(menu);
				pack.WriteCell(client);
				pack.WriteCell(GetMenuSelectionPosition());
				
			}
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				menuGlovesGroup.Display(client, MENU_TIME_FOREVER);
			}
		}
	}
	return 0;
}

public Action ResetGlovesTimer(Handle timer, DataPack pack)
{
	ResetPack(pack);
	int clientIndex = pack.ReadCell();
	int activeWeapon = pack.ReadCell();
	
	if(clientIndex <= MaxClients+1 && IsClientInGame(clientIndex) && IsValidEdict(activeWeapon))
	{
		SetEntPropEnt(clientIndex, Prop_Send, "m_hActiveWeapon", activeWeapon);
	}
}

public int GloveMainMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char info[4];
				menu.GetItem(selection, info, sizeof(info));
				int index = StringToInt(info);
				
				if(index == 0 || index == -1)
				{
					char updateFields[128];
					g_iGroup[client] = index;
					g_iGloves[client] = index;

					Format(updateFields, sizeof(updateFields), "groupid = %d, gloveid = %d", index, index);
					UpdatePlayerData(client, updateFields);
					
					int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
					if(activeWeapon != -1)
					{
						SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1);
					}

					if(index == 0)
					{
						int ent = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
						if(ent != -1)
						{
							AcceptEntityInput(ent, "KillHierarchy");
						}
						SetEntPropString(client, Prop_Send, "m_szArmsModel", g_CustomArms[client]);
					}
					else
					{
						GivePlayerGloves(client);
					}

					if(activeWeapon != -1)
					{
						DataPack dpack;
						CreateDataTimer(0.1, ResetGlovesTimer, dpack);
						dpack.WriteCell(client);
						dpack.WriteCell(activeWeapon);
					}
					
					DataPack pack;
					CreateDataTimer(0.5, GlovesMenuTimer, pack);
					pack.WriteCell(menu);
					pack.WriteCell(client);
					pack.WriteCell(GetMenuSelectionPosition());
				}
				else
				{
					menuGloves[index].Display(client, MENU_TIME_FOREVER);
				}
			}
		}
		case MenuAction_DisplayItem:
		{
			if(IsClientInGame(client))
			{
				char info[32];
				char display[64];
				menu.GetItem(selection, info, sizeof(info));
				
				if (StrEqual(info, "0"))
				{
					Format(display, sizeof(display), "%T", "DefaultGloves", client);
					return RedrawMenuItem(display);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				RequestFrame(ShowCategory, client);
			}	
		}
	}
	return 0;
}

public Action GlovesMenuTimer(Handle timer, DataPack pack)
{
	ResetPack(pack);
	Menu menu = pack.ReadCell();
	int clientIndex = pack.ReadCell();
	int menuSelectionPosition = pack.ReadCell();
	
	if(IsClientInGame(clientIndex))
	{
		menu.DisplayAt(clientIndex, menuSelectionPosition, MENU_TIME_FOREVER);
	}
}

Menu CreateFloatMenu(int client)
{
	char buffer[60];
	Menu menu = new Menu(FloatMenuHandler);
	
	float fValue = g_fFloatValue[client];
	fValue = fValue * 100.0;
	int wear = 100 - RoundFloat(fValue);
	
	menu.SetTitle("%T%d%%", "SetFloat", client, wear);
	
	Format(buffer, sizeof(buffer), "%T", "Increase", client, g_iFloatIncrementPercentage);
	menu.AddItem("increase", buffer, wear == 100 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	Format(buffer, sizeof(buffer), "%T", "Decrease", client, g_iFloatIncrementPercentage);
	menu.AddItem("decrease", buffer, wear == 0 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	menu.ExitBackButton = true;
	
	return menu;
}

public int FloatMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char buffer[30];
				menu.GetItem(selection, buffer, sizeof(buffer));
				if(StrEqual(buffer, "increase"))
				{
					g_fFloatValue[client] = g_fFloatValue[client] - g_fFloatIncrementSize;
					if(g_fFloatValue[client] < 0.0)
					{
						g_fFloatValue[client] = 0.0;
					}
					if(g_FloatTimer[client] != INVALID_HANDLE)
					{
						KillTimer(g_FloatTimer[client]);
						g_FloatTimer[client] = INVALID_HANDLE;
					}
					DataPack pack;
					g_FloatTimer[client] = CreateDataTimer(2.0, FloatTimer, pack);
					pack.WriteCell(client);
					CreateFloatMenu(client).Display(client, MENU_TIME_FOREVER);
				}
				else if(StrEqual(buffer, "decrease"))
				{
					g_fFloatValue[client] = g_fFloatValue[client] + g_fFloatIncrementSize;
					if(g_fFloatValue[client] > 1.0)
					{
						g_fFloatValue[client] = 1.0;
					}
					if(g_FloatTimer[client] != INVALID_HANDLE)
					{
						KillTimer(g_FloatTimer[client]);
						g_FloatTimer[client] = INVALID_HANDLE;
					}
					DataPack pack;
					g_FloatTimer[client] = CreateDataTimer(1.0, FloatTimer, pack);
					pack.WriteCell(client);
					CreateFloatMenu(client).Display(client, MENU_TIME_FOREVER);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				CreateMainMenu(client).Display(client, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action FloatTimer(Handle timer, DataPack pack)
{

	ResetPack(pack);
	int clientIndex = pack.ReadCell();
	
	if(IsClientInGame(clientIndex))
	{
		char updateFields[30];

		Format(updateFields, sizeof(updateFields), "%sfloat_value = %.2f", g_fFloatValue[clientIndex]);
		UpdatePlayerData(clientIndex, updateFields);
		
		GivePlayerGloves(clientIndex);
		
		g_FloatTimer[clientIndex] = INVALID_HANDLE;
	}
}

public int MainMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char info[10];
				menu.GetItem(selection, info, sizeof(info));
				
				if(StrEqual(info, "float"))
				{
					CreateFloatMenu(client).Display(client, MENU_TIME_FOREVER);
				}
				else
				{
					menuGlovesGroup.Display(client, MENU_TIME_FOREVER);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				Shop_ShowCategory(client);
			}		
		}		
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public void ShowCategory(int iClient)
{
	Shop_ShowCategory(iClient);
}

Menu CreateMainMenu(int client)
{
	char buffer[60];
	Menu menu = new Menu(MainMenuHandler, MENU_ACTIONS_DEFAULT);
	
	menu.SetTitle("%T", "GloveMenuTitle", client);
	
	Format(buffer, sizeof(buffer), "%T", "CT", client);
	menu.AddItem("ct", buffer);
	//Format(buffer, sizeof(buffer), "%T", "T", client);
	//menu.AddItem("t", buffer);
	
	if (g_iEnableFloat == 1 && IsPlayerAlive(client))
	{
		if(g_iGloves[client] != 0)
		{
			float fValue = g_fFloatValue[client];
			fValue = fValue * 100.0;
			int wear = 100 - RoundFloat(fValue);
			Format(buffer, sizeof(buffer), "%T%d%%", "SetFloat", client, wear);
			menu.AddItem("float", buffer);
		}
	}
	
	menu.ExitBackButton = true;
	return menu;
}
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

char g_GlovesGroupIds[][] = {
/* 0*/ "5035", /* 1*/ "5027", /* 2*/ "5030", /* 3*/ "5032",
/* 4*/ "5031", /* 5*/ "5034", /* 6*/ "5033", /* 7*/ "4725"
};

char g_GlovesGroupNames[][] = {
/* 0*/ "Hydra", /* 1*/ "Bloodhound", /* 2*/ "Sport", /* 3*/ "Hand Wraps",
/* 4*/ "Driver Gloves", /* 5*/ "Specialist", /* 6*/ "Moto", /* 7*/ "Broken Fang"
};

Database db = null;

char configPath[PLATFORM_MAX_PATH];

ConVar g_Cvar_DBConnection;
char g_DBConnection[32];
char g_DBConnectionOld[32];

ConVar g_Cvar_TablePrefix;
char g_TablePrefix[10];
char g_sPreviewItem[MAXPLAYERS+1][96];

ConVar g_Cvar_ChatPrefix;
char g_ChatPrefix[32];

ConVar g_Cvar_FloatIncrementSize;
float g_fFloatIncrementSize;
float g_fPreviewDuration;
int g_iFloatIncrementPercentage;

bool g_bPreview[MAXPLAYERS+1];

ConVar g_Cvar_EnableFloat;
int g_iEnableFloat;

ConVar g_Cvar_EnableWorldModel;
int g_iEnableWorldModel;

int g_iGroup[MAXPLAYERS+1];
int g_iGloves[MAXPLAYERS+1];
float g_fFloatValue[MAXPLAYERS+1];
char g_CustomArms[MAXPLAYERS+1][256];
Handle g_FloatTimer[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
int g_iSteam32[MAXPLAYERS+1] = { 0, ... };

Menu menuGlovesGroup;

CategoryId g_cCategory;
Menu menuGloves[9];
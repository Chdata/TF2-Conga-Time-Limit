/*
    Conga Time limiter.
    By: Chdata

    Thanks to rswallen.

    TODO: Time limit other held taunts.
*/

#pragma semicolon 1

#include <sourcemod>
#include <morecolors>
#include <tf2_stocks>
#include <sdkhooks>

#define NOCONVARS                              //  Why? Because it's glitching out for me and my convars aren't getting created so I don't feel like bothering right now.

//#include <chdata>
#if !defined __chdata_0_included
//#define NOCONVARS

#define TF_MAX_PLAYERS          34             //  Sourcemod supports up to 64 players? Too bad TF2 doesn't. 33 player server +1 for 0 (console/world)

stock bool:IsValidClient(iClient)
{
    return (0 < iClient && iClient <= MaxClients && IsClientInGame(iClient));
}

// True if the condition was removed.
stock bool:RemoveCond(iClient, TFCond:iCond)
{
    if (TF2_IsPlayerInCondition(iClient, iCond))
    {
        TF2_RemoveCondition(iClient, iCond);
        return true;
    }
    return false;
}
#endif

#define PLUGIN_VERSION "0x01"

public Plugin:myinfo = 
{
    name = "Conga Timer Limiter",
    author = "Chdata",
    description = "Adds time limit to Conga",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/groups/tf2data"
};

new g_iCongaEnt[TF_MAX_PLAYERS] = {-1,...};
//new g_iDosido[TF_MAX_PLAYERS] = {-1,...};

#if !defined NOCONVARS
static Handle:g_cvCongaMaxTime;

public OnPluginStart()
{
    CreateConVar(
        "cv_conga_version", PLUGIN_VERSION,
        "Conga Time Limit Version",
        FCVAR_REPLICATED|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY
    );

    g_cvCongaMaxTime = CreateConVar(
        "cv_conga_limit", "5.0",
        "After this many seconds, conga will be stopped.",
        FCVAR_PLUGIN|FCVAR_NOTIFY,
        true, 0.0
    );

    AutoExecConfig(true, "ch.conga");
}
#endif

public OnEntityCreated(iEnt, const String:szClassname[])
{
    if (StrEqual(szClassname, "instanced_scripted_scene", false))
    {
        SDKHook(iEnt, SDKHook_SpawnPost, OnSceneSpawnedPost);
    }
}

public OnSceneSpawnedPost(iTaunt)
{
    new iClient = GetEntPropEnt(iTaunt, Prop_Data, "m_hOwner");
    if (IsValidClient(iClient))
    {
        g_iCongaEnt[iClient] = -1;
        //g_iDosido[iClient] = -1;
        
        decl String:szSceneFile[PLATFORM_MAX_PATH];
        GetEntPropString(iTaunt, Prop_Data, "m_iszSceneFile", szSceneFile, sizeof(szSceneFile));
        
        if (StrContains(szSceneFile, "conga.vcd") != -1)
        {
            //"scenes/player/[class]/low/conga.vcd"
            g_iCongaEnt[iClient] = EntIndexToEntRef(iTaunt);
#if defined __chdata_0_included
            CPrintToChdata("Conga started %N(E:%i U:%i) ent: %i", iClient, iClient, iClient, iTaunt);
#endif
#if !defined NOCONVARS
            CreateTimer(GetConVarFloat(g_cvCongaMaxTime), Timer_EndConga, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
#else
            CreateTimer(5.0, Timer_EndConga, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
#endif
        }
        /*else if (StrContains(szSceneFile, "taunt_dosido") != -1)
        {
            //"scenes/player/[class]/low/taunt_dosido_intro##.vcd"
            //"scenes/player/[class]/low/taunt_dosido_dance##.vcd"
            g_iDosido[iClient] = EntIndexToEntRef(iTaunt);
        }*/
    }
}

/*
    I happen to prefer forcing people to do validation checks outside of stocks
    As opposed to have multiple different stocks that validate on their own
    Just have one global validation for various stocks in a row
*/
bool:IsClientInConga(iClient)
{
    return IsValidEntity(EntRefToEntIndex(g_iCongaEnt[iClient]));
}

/*bool:IsClientInDosido(iClient)
{
    return IsValidEntity(g_iDosido[iClient]);
}*/

public Action:Timer_EndConga(Handle:hTimer, any:UserId)
{
    new iClient = GetClientOfUserId(UserId);
    if (IsValidClient(iClient) && IsClientInConga(iClient))
    {
#if defined __chdata_0_included
        CPrintToChdata("Conga closed %N(E:%i U:%i) ent: %i", iClient, iClient, iClient, EntRefToEntIndex(g_iCongaEnt[iClient]));
#endif
        RemoveCond(iClient, TFCond_Taunting);
        //ForcePlayerSuicide(iClient);
        //g_iCongaEnt[iClient] = -1;
    }
}
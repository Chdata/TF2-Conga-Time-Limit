/*
    Conga Time limiter.
    By: Chdata

    Thanks to rswallen & friagram.
*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION "0x02"

#define TF_MAX_PLAYERS          34             //  Sourcemod supports up to 64 players? Too bad TF2 doesn't. 33 player server +1 for 0 (console/world)

stock bool:IsValidClient(iClient)
{
    return (0 < iClient && iClient <= MaxClients && IsClientInGame(iClient));
}

static Float:s_flLastCongaTime[TF_MAX_PLAYERS] = {-16.0,...}; // Should be set to a value less than -CONGA_DELAY

public Plugin:myinfo = 
{
    name = "Conga Timer Limiter",
    author = "Chdata",
    description = "Adds time limit to Conga",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/groups/tf2data"
};

public TF2_OnConditionAdded(iClient, TFCond:iCond)
{
    if (iCond == TFCond_Taunting && GetEntProp(iClient, Prop_Send, "m_iTauntItemDefIndex") == 1118)
    {
        if (GetGameTime() - s_flLastCongaTime[iClient] > 15.0) // ... > 15.0 or >= 15.0 ???
        {
            CreateTimer(5.0, Timer_EndConga, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
            s_flLastCongaTime[iClient] = GetGameTime();
        }
        else
        {
            PrintToChat(iClient, "Please wait %0.1f seconds before you conga again.", 15.0 - (GetGameTime() - s_flLastCongaTime[iClient]));
            TF2_RemoveCondition(iClient, TFCond_Taunting);
        }
    }
}

public Action:Timer_EndConga(Handle:hTimer, any:UserId)
{
    new iClient = GetClientOfUserId(UserId);
    if (IsValidClient(iClient) && GetEntProp(iClient, Prop_Send, "m_iTauntItemDefIndex") == 1118)
    {
        TF2_RemoveCondition(iClient, TFCond_Taunting);
    }
}

/*
    You don't need to check the taunt condition, it's set to -1 if you're not taunting anyway.
*/
/*stock bool:IsClientInConga(iClient)
{
    return GetEntProp(iClient, Prop_Send, "m_iTauntItemDefIndex") == 1118; // TF2_IsPlayerInCondition(iClient, TFCond_Taunting) && 
}*/

#endinput

//  Whenever I'm not lazy and this isn't bugging out for me I'll go throw this stuff in

static Handle:g_cvCongaMaxTime;
static Handle:g_cvCongaReTime;

public OnPluginStart()
{
    CreateConVar(
        "cv_conga_version", PLUGIN_VERSION,
        "Conga Time Limit Version",
        FCVAR_REPLICATED|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY
    );

    g_cvCongaMaxTime = CreateConVar(
        "cv_conga_limit", "5.0",
        "After this many seconds, conga will be forcibly stopped.",
        FCVAR_PLUGIN|FCVAR_NOTIFY,
        true, 0.0
    );

    g_cvCongaReTime = CreateConVar(
        "cv_conga_reallow", "15.0",
        "After initiating conga, cannot conga again for this many seconds.",
        FCVAR_PLUGIN|FCVAR_NOTIFY,
        true, 0.0
    );

    AutoExecConfig(true, "ch.conga");
}
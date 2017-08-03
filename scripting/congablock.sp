/*
    Conga Time limiter.
    By: Chdata

    Thanks to rswallen & friagram.
*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>


#define TF_MAX_PLAYERS          34             //  Sourcemod supports up to 64 players? Too bad TF2 doesn't. 33 player server +1 for 0 (console/world)
#define FCVAR_VERSION           FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_CHEAT

enum e_flNext2
{
    e_flCongaUnblockTime = 0,
}

public Plugin:myinfo = 
{
    name = "Conga Timer Limiter",
    author = "Chdata",
    description = "Adds time limit to Conga",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/groups/tf2data"
};

static Handle:s_cvCongaMaxTime;
static Handle:s_cvCongaUnblockTime;

public OnPluginStart()
{
    CreateConVar(
        "cv_conga_version", PLUGIN_VERSION,
        "Conga Time Limit Version",
        FCVAR_VERSION
    );

    s_cvCongaMaxTime = CreateConVar(
        "cv_conga_limit", "5.0",
        "After this many seconds, conga will be forcibly stopped.",
        FCVAR_NOTIFY,
        true, 0.0
    );

    s_cvCongaUnblockTime = CreateConVar(
        "cv_conga_unblock", "15.0",
        "After initiating conga, cannot conga again for this many seconds.",
        FCVAR_NOTIFY,
        true, 0.0
    );

    AutoExecConfig(true, "ch.conga");
}

public TF2_OnConditionAdded(iClient, TFCond:iCond)
{
    switch (iCond)
    {
        case TFCond_Taunting:
        {
            switch (GetEntProp(iClient, Prop_Send, "m_iTauntItemDefIndex"))
            {
                case 1118, 1157, 1162: // Conga, Kazotsky Kick, Mannrobics
                {
                    if (DoNextTime2(iClient, e_flCongaUnblockTime, GetConVarFloat(s_cvCongaUnblockTime)))
                    {
                        CreateTimer(GetConVarFloat(s_cvCongaMaxTime), Timer_EndConga, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
                    }
                    else
                    {
                        PrintToChat(iClient, "Please wait %0.1f seconds before you taunt again.", GetTimeTilNextTime2(iClient, e_flCongaUnblockTime));
                        TF2_RemoveCondition(iClient, TFCond_Taunting);
                    }
                }
            }
        }
    }
}

public Action:Timer_EndConga(Handle:hTimer, any:UserId)
{
    new iClient = GetClientOfUserId(UserId);
    if (iClient && IsClientInGame(iClient) && IsPlayerAlive(iClient))
    {
        switch (GetEntProp(iClient, Prop_Send, "m_iTauntItemDefIndex"))
        {
            case 1118, 1157, 1162: // Conga, Kazotsky Kick, Mannrobics
            {
                TF2_RemoveCondition(iClient, TFCond_Taunting);
            }
        }
    }
}

/*
    You don't need to check the taunt condition, it's set to -1 if you're not taunting anyway.
*/
/*stock bool:IsClientInConga(iClient)
{
    return GetEntProp(iClient, Prop_Send, "m_iTauntItemDefIndex") == 1118; // TF2_IsPlayerInCondition(iClient, TFCond_Taunting) && 
}*/

stock Float:fmax(Float:a,Float:b) { return (a > b) ? a : b; }

// Start of plural NextTime versions

static Float:g_flNext2[e_flNext2][TF_MAX_PLAYERS];

stock bool:IsNextTime2(iClient, iIndex, Float:flAdditional = 0.0)
{
    return (GetEngineTime() >= g_flNext2[iIndex][iClient]+flAdditional);
}

stock SetNextTime2(iClient, iIndex, Float:flTime, bool:bAbsolute = false)
{
    g_flNext2[iIndex][iClient] = bAbsolute ? flTime : GetEngineTime() + flTime;
}

stock Float:GetNextTime2(iClient, iIndex)
{
    return g_flNext2[iIndex][iClient];
}

stock ModNextTime2(iClient, iIndex, Float:flDisplacement)
{
    g_flNext2[iIndex][iClient] += flDisplacement;
}

stock Float:GetTimeTilNextTime2(iClient, iIndex, bool:bNonNegative = true)
{
    return bNonNegative ? fmax(g_flNext2[iIndex][iClient] - GetEngineTime(), 0.0) : (g_flNext2[iIndex][iClient] - GetEngineTime());
}

stock GetSecsTilNextTime2(iClient, iIndex, bool:bNonNegative = true)
{
    return RoundToFloor(GetTimeTilNextTime2(iClient, iIndex, bNonNegative));
}

/*
    If next time occurs, we also add time on for when it is next allowed.
*/
stock bool:DoNextTime2(iClient, iIndex, Float:flThenAdd)
{
    if (IsNextTime2(iClient, iIndex))
    {
        SetNextTime2(iClient, iIndex, flThenAdd);
        return true;
    }
    return false;
}
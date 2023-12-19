Scriptname RobcoAutoSort:VersionUpdateManager extends Quest

import RobcoAutoSort:FormLoader

; =============================================================================
; === Properties  =============================================================
; =============================================================================

Group Globals
    GlobalVariable Property BuildNumberGlobal Auto Const Mandatory
EndGroup

DebugLog Property Log Auto Hidden

; =============================================================================
; === Constants  ==============================================================
; =============================================================================

int currentBuildNumber = 1 const

; =============================================================================
; === Structs  ================================================================
; =============================================================================

Struct UpdateResult
    bool isSuccess = true
    int lastIncrementalUpdate
EndStruct

; =============================================================================
; === Local event callbacks  ==================================================
; =============================================================================

Event OnInit()
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
EndEvent


Event Actor.OnPlayerLoadGame(Actor akSender)
    _BindVariables()

    Matcher matcher = LoadMatcher()

    int lastBuildNumber = BuildNumberGlobal.GetValueInt()
    if (lastBuildNumber < currentBuildNumber)
        Log.Info("Build version increased from "+lastBuildNumber+" to "+currentBuildNumber+", running incremental updates")

        UpdateResult result = new UpdateResult
        result.lastIncrementalUpdate = lastBuildNumber

        _RunAllUpdatesFrom(lastBuildNumber, result)
        if (result.isSuccess)
            Log.Info("Update successful! All incremental updates ran from build version "+lastBuildNumber+" to "+currentBuildNumber)
        else
            int lastUpdate = result.lastIncrementalUpdate
            int failingUpdate = lastUpdate+1
            Log.Error("Update failed! Updates ran from build version "+lastBuildNumber+" to "+lastUpdate+", failing at "+failingUpdate)
        endif
        BuildNumberGlobal.SetValueInt(result.lastIncrementalUpdate)
    else
        Log.Info("Build version is up-to-date: "+currentBuildNumber)
    endif
EndEvent

; =============================================================================
; === Private functions =======================================================
; =============================================================================

Function _BindVariables()
    Log = LoadDebugLog()
EndFunction

Function _RunAllUpdatesFrom(int lastBuildNumber, UpdateResult result)
    while (lastBuildNumber < currentBuildNumber)
        lastBuildNumber += 1
        _RunIncrementalUpdate(currentBuildNumber, result)
        if (result.isSuccess)
            result.lastIncrementalUpdate = currentBuildNumber
        else
            return
        endif
    endwhile
EndFunction

Function _RunIncrementalUpdate(int buildNumber, UpdateResult result)
    Log.Info("Running incremental update to build #" + buildNumber)
EndFunction

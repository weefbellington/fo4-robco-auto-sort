Scriptname RobcoAutoSort:VersionManager extends Quest

; =============================================================================
; === Properties  =============================================================
; =============================================================================

Group Versioning
    int property LatestScriptVersion = 1 auto const mandatory
EndGroup

Group CacheKeywords
    Keyword property ScriptVersionCacheKey auto const mandatory
EndGroup

Group ExternalScripts
    RobcoAutoSort:VersionUpdateScript[] property UpdateScripts auto const mandatory
    RobcoAutoSort:TraceLogger property Logger auto const mandatory
EndGroup

; =============================================================================
; === Events  =================================================================
; =============================================================================

Event OnInit()
    Logger.RegisterPrefix(self, "VersionManager")
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
EndEvent

; =============================================================================
; === Public functions ========================================================
; =============================================================================

Function Update(ScriptObject scriptObj)
    int currentScriptVersion = _GetCurrentScriptVersion(scriptObj)
    if (scriptObj != None && currentScriptVersion < LatestScriptVersion)
        Logger.Info(self, "Script '"+scriptObj+"' version increased from #"+currentScriptVersion+" to #"+LatestScriptVersion+", running incremental updates")
        int newScriptVersion = _RunIncrementalUpdates(scriptObj, currentScriptVersion, LatestScriptVersion)
        _SetCurrentScriptVersion(scriptObj, newScriptVersion)
    endif
EndFunction

; =============================================================================
; === Private functions =======================================================
; =============================================================================

int Function _GetCurrentScriptVersion(ScriptObject scriptObj)
    if (scriptObj == None)
        return 1
    endif

    DS:StringDictInt.Create(ScriptVersionCacheKey)
    DS:StringDictInt:Result result = DS:StringDictInt.Get(ScriptVersionCacheKey, scriptObj)
    if (result.Found)
        return result.Value
    else
        return 1
    endif
EndFunction

Function _SetCurrentScriptVersion(ScriptObject scriptObj, int value)
    DS:StringDictInt.Create(ScriptVersionCacheKey)
    DS:StringDictInt.Add(ScriptVersionCacheKey, scriptObj, value)
EndFunction

int Function _RunIncrementalUpdates(ScriptObject scriptObj, int currentVersion, int latestVersion)
    while (currentVersion < latestVersion)
        bool updateFailed = !_RunIncrementalUpdate(scriptObj, currentVersion+1)
        if (updateFailed)
            Logger.Error(self, "Update failed at incremental update #"+(currentVersion+1)+"!")
            return currentVersion
        else
            currentVersion += 1
        endif
    endwhile
    return currentVersion
EndFunction

bool Function _RunIncrementalUpdate(ScriptObject scriptObj, int version)
    Logger.Info(self, "Running incremental update #"+version+" for script '"+scriptObj+"'")
    int i = 0
    while (i < UpdateScripts.Length)
        VersionUpdateScript updateScript = UpdateScripts[i] as RobcoAutoSort:VersionUpdateScript
        if (updateScript.ShouldUpdate(scriptObj, version))
            Logger.Info(self, "Running update script with description: '"+updateScript.GetUpdateDescription(scriptObj, version)+"'")
            bool updateFailed = !updateScript.Update(scriptObj, version)
            if (updateFailed)
                return false
            endif
        endif
        i += 1
    endwhile
    return true
EndFunction
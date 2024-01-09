Scriptname RobcoAutoSort:UpdateScript extends Quest Hidden

TraceLogger property Logger auto const mandatory

; =============================================================================
; === Overriddable functions  =================================================
; =============================================================================

Struct UpdateResult
    int BeforeVersionNumber
    int AfterVersionNumber
    int TargetVersionNumber
    bool Failed
EndStruct

UpdateResult Function Update(ScriptObject target, int oldVersionNumber, int targetVersionNumber)
    UpdateResult result = new UpdateResult
    result.TargetVersionNumber = targetVersionNumber
    result.BeforeVersionNumber = oldVersionNumber
    result.AfterVersionNumber = oldVersionNumber
    result.Failed = false
    int nextVersionNumber = oldVersionNumber

    _DebugOnlyLogVersionInfo(target, oldVersionNumber, targetVersionNumber)

    while (result.Failed == false && nextVersionNumber < targetVersionNumber)
        nextVersionNumber += 1
        _CallUpdateFn(target, nextVersionNumber, result)
    endwhile

    return result
EndFunction

Struct IncrementalUpdateResult
    string Description
    bool Completed = false
    int VersionNumber
EndStruct

Function _CallUpdateFn(ScriptObject target, int versionNumber, UpdateResult result)
    string updateFn = "UpdateV"+versionNumber

    IncrementalUpdateResult incrementalUpdate = new IncrementalUpdateResult
    incrementalUpdate.versionNumber = versionNumber

    Var[] vars = new Var[2]
    vars[0] = target
    vars[1] = incrementalUpdate
    
    Logger.Info(self, "Calling update function...")
    CallFunction(updateFn, vars)
    Logger.Info(self, "Function call completed.")

    if (incrementalUpdate.Completed)
        result.AfterVersionNumber = versionNumber
    else
        result.Failed = true
    endif
    _DebugOnlyLogIncrementalUpdateResult(incrementalUpdate)
EndFunction

Function _DebugOnlyLogVersionInfo(ScriptObject target, int oldVersionNumber, int targetVersionNumber) DebugOnly
    if (oldVersionNumber == targetVersionNumber)
        Logger.Info(self, "Script "+target+" is up-to-date (version: "+oldVersionNumber+").")
    else
        Logger.Info(self, "Script is out-of-date: current version is ("+oldVersionNumber+"), latest version is ("+targetVersionNumber+")")
    endif
EndFunction

Function _DebugOnlyLogIncrementalUpdateResult(IncrementalUpdateResult result) DebugOnly
    if (result.Completed)
        Logger.Info(self, "Update #"+result.versionNumber+": "+result.Description+" - COMPLETE")
    else
        Logger.Error(self, "Update #"+result.versionNumber+": "+result.Description+" - INCOMPLETE")
    endif
EndFunction
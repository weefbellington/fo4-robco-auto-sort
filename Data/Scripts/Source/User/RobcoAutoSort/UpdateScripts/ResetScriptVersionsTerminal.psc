Scriptname RobcoAutoSort:UpdateScripts:ResetScriptVersionsTerminal extends RobcoAutoSort:UpdateScript

Function UpdateV2(ScriptObject target, RobcoAutoSort:UpdateScript:IncrementalUpdateResult result)
    Logger.RegisterPrefix(self, "Update:ResetScriptVersionsTerminal")

    result.Description = "Registering short name in TraceLogger"
    Logger.RegisterPrefix(target, "ResetScriptVersionsTerminal")
    result.Completed = true
EndFunction
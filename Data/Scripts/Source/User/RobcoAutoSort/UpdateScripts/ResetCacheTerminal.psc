Scriptname RobcoAutoSort:UpdateScripts:ResetCacheTerminal extends RobcoAutoSort:UpdateScript

Function UpdateV2(ScriptObject target, RobcoAutoSort:UpdateScript:IncrementalUpdateResult result)
    Logger.RegisterPrefix(self, "Update:ResetCacheTerminal")

    result.Description = "Registering short name in TraceLogger"
    Logger.RegisterPrefix(target, "ResetCacheTerminal")
    result.Completed = true
EndFunction
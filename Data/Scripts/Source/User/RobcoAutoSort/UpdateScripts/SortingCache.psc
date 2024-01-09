Scriptname RobcoAutoSort:UpdateScripts:SortingCache extends RobcoAutoSort:UpdateScript

Function UpdateV2(ScriptObject target, RobcoAutoSort:UpdateScript:IncrementalUpdateResult result)
    Logger.RegisterPrefix(self, "Update:SortingCache")

    result.Description = "Registering short name in TraceLogger"
    Logger.RegisterPrefix(target, "SortingCache")
    result.Completed = true
EndFunction
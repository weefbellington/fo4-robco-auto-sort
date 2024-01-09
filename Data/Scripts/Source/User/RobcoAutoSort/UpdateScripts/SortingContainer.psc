Scriptname RobcoAutoSort:UpdateScripts:SortingContainer extends RobcoAutoSort:UpdateScript

Function UpdateV2(ScriptObject target, RobcoAutoSort:UpdateScript:IncrementalUpdateResult result)
    Logger.RegisterPrefix(self, "Update:SortingContainer")

    result.Description = "Registering short name in TraceLogger"
    Logger.RegisterPrefix(target, "SortingContainer")
    result.Completed = true
EndFunction
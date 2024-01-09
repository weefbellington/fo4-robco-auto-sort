Scriptname RobcoAutoSort:UpdateScripts:FilterRegistry extends RobcoAutoSort:UpdateScript

Function UpdateV2(ScriptObject target, RobcoAutoSort:UpdateScript:IncrementalUpdateResult result)
    Logger.RegisterPrefix(self, "Update:FilterRegistry")

    result.Description = "Registering short name in TraceLogger"
    Logger.RegisterPrefix(target, "FilterRegistry")
    result.Completed = true
EndFunction
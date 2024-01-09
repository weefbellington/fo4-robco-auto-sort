Scriptname RobcoAutoSort:UpdateScripts:Matcher extends RobcoAutoSort:UpdateScript

Function UpdateV2(ScriptObject target, RobcoAutoSort:UpdateScript:IncrementalUpdateResult result)
    Logger.RegisterPrefix(self, "Update:Matcher")

    result.Description = "Registering short name in TraceLogger"
    Logger.RegisterPrefix(target, "Matcher")
    result.Completed = true
EndFunction
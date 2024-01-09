Scriptname RobcoAutoSort:UpdateScripts:FilterCardReader extends RobcoAutoSort:UpdateScript

Function UpdateV2(ScriptObject target, RobcoAutoSort:UpdateScript:IncrementalUpdateResult result)
    Logger.RegisterPrefix(self, "Update:FilterCardReader")

    result.Description = "Registering short name in TraceLogger"
    Logger.RegisterPrefix(target, "FilterCardReader")
    result.Completed = true
EndFunction
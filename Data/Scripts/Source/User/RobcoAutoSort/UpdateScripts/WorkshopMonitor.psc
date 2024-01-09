Scriptname RobcoAutoSort:UpdateScripts:WorkshopMonitor extends RobcoAutoSort:UpdateScript

Function UpdateV2(ScriptObject target, RobcoAutoSort:UpdateScript:IncrementalUpdateResult result)
    Logger.RegisterPrefix(self, "Update:WorkshopMonitor")

    result.Description = "Registering short name in TraceLogger"
    Logger.RegisterPrefix(target, "WorkshopMonitor")
    result.Completed = true
EndFunction
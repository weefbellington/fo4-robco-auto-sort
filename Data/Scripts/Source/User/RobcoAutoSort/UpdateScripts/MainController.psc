Scriptname RobcoAutoSort:UpdateScripts:MainController extends RobcoAutoSort:UpdateScript

Function UpdateV2(ScriptObject target, RobcoAutoSort:UpdateScript:IncrementalUpdateResult result)
    Logger.RegisterPrefix(self, "Update:MainController")

    result.Description = "Registering short name in TraceLogger"
    Logger.RegisterPrefix(target, "MainController")
    result.Completed = true
EndFunction
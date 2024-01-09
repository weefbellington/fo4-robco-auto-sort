Scriptname RobcoAutoSort:UpdateScripts:AutoSortActivator extends RobcoAutoSort:UpdateScript

Function UpdateV2(ScriptObject target, RobcoAutoSort:UpdateScript:IncrementalUpdateResult result)
    Logger.RegisterPrefix(self, "Update:AutoSortActivator")

    result.Description = "Registering short name in TraceLogger"
    Logger.RegisterPrefix(target, "AutoSortActivator")
    result.Completed = true
EndFunction
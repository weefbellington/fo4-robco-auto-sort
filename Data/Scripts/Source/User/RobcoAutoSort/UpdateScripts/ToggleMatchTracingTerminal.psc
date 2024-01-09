Scriptname RobcoAutoSort:UpdateScripts:ToggleMatchTracingTerminal extends RobcoAutoSort:UpdateScript

Function UpdateV2(ScriptObject target, RobcoAutoSort:UpdateScript:IncrementalUpdateResult result)
    Logger.RegisterPrefix(self, "Update:TraceLogger")

    result.Description = "Registering short name in TraceLogger"
    Logger.RegisterPrefix(target, "ToggleMatchTracingTerminal")
    result.Completed = true
EndFunction
Scriptname RobcoAutoSort:UpdateScripts:AlternateActivationPerk extends RobcoAutoSort:UpdateScript

Function UpdateV2(ScriptObject target, RobcoAutoSort:UpdateScript:IncrementalUpdateResult result)
    Logger.RegisterPrefix(self, "Update:AlternateActivationPerk")

    result.Description = "Registering short name in TraceLogger"
    Logger.RegisterPrefix(target, "AlternateActivationPerk")
    result.Completed = true
EndFunction
Scriptname RobcoAutoSort:UpdateScripts:DumpCacheInfoTerminal extends RobcoAutoSort:UpdateScript

Function UpdateV2(ScriptObject target, RobcoAutoSort:UpdateScript:IncrementalUpdateResult result)
    Logger.RegisterPrefix(self, "Update:DumpCacheInfoTerminal")

    result.Description = "Registering short name in TraceLogger"
    Logger.RegisterPrefix(target, "DumpCacheInfoTerminal")
    result.Completed = true
EndFunction
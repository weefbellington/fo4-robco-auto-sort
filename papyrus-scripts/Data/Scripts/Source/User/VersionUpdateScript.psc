Scriptname RobcoAutoSort:VersionUpdateScript extends Quest

; =============================================================================
; === Overriddable functions  =================================================
; =============================================================================

bool Function ShouldUpdate(ScriptObject scriptObject, int version)
    return false
EndFunction

bool Function Update(ScriptObject scriptObject, int version)
EndFunction

string Function GetUpdateDescription(ScriptObject target, int version)
    return ""
EndFunction
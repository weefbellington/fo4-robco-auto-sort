Scriptname RobcoAutoSort:UpdateAutoSortActivatorV2 extends RobcoAutoSort:VersionUpdateScript

; =============================================================================
; === EXAMPLE SCRIPT  =========================================================
; =============================================================================

bool Function ShouldUpdate(ScriptObject target, int version)
    return (target is AutoSortActivator) && (version == 2)
EndFunction

string Function GetUpdateDescription(ScriptObject target, int version)
    if (version == 2)
        return "Example update"
    else
        return ""
    endif
EndFunction

bool Function Update(ScriptObject target, int version)
    AutoSortActivator autoSortActivator = target as AutoSortActivator
    UpdateActivator(autoSortActivator)
    return true
EndFunction

Function UpdateActivator(AutoSortActivator target)

EndFunction


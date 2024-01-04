Scriptname RobcoAutoSort:UpdateMainControllerV2 extends RobcoAutoSort:VersionUpdateScript

; =============================================================================
; === EXAMPLE SCRIPT  =========================================================
; =============================================================================

bool Function ShouldUpdate(ScriptObject target, int version)
    return (target is MainController) && (version == 2)
EndFunction

string Function GetUpdateDescription(ScriptObject target, int version)
    if (version == 2)
        return "Set Player property on MainController."
    else
        return ""
    endif
EndFunction

bool Function Update(ScriptObject target, int version)
    MainController controller = target as MainController
    controller.Player = Game.GetPlayer()
    return true
EndFunction
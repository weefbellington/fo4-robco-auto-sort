Scriptname RobcoAutoSort:ToggleMatchTracingTerminal extends Terminal

; =============================================================================
; === Const propeties  ========================================================
; =============================================================================

Group GlobalVariables
    GlobalVariable property MatchTracingEnabled auto const mandatory
EndGroup

Group ExternalScripts
    VersionManager property VersionManager auto const mandatory
    TraceLogger property Logger auto const mandatory
    Matcher property Matcher auto const mandatory
EndGroup

; =============================================================================
; === Initialization  =========================================================
; =============================================================================

Event OnInit()
    Logger.RegisterPrefix(self, "ToggleMatchTracingTerminal")
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
EndEvent

; =============================================================================
; === Events  =================================================================
; =============================================================================

Event OnMenuItemRun(int auiMenuItemID, ObjectReference akTarget)
    Logger.Info(self, "Menu item selected: "+auiMenuItemID)
    if (auiMenuItemID == 1)
        MatchTracingEnabled.SetValueInt(1)
        Matcher.IsMatchTracingEnabled = true
    elseif (auiMenuItemID == 2)
        MatchTracingEnabled.SetValueInt(0)
        Matcher.IsMatchTracingEnabled = false
    endif
EndEvent
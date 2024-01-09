Scriptname RobcoAutoSort:ResetScriptVersionsTerminal extends Terminal

; =============================================================================
; === Properties  =============================================================
; =============================================================================

Group ExternalScripts
    VersionManager property VersionManager auto const mandatory
    TraceLogger property Logger auto const mandatory
EndGroup

; =============================================================================
; === Initialization  =========================================================
; =============================================================================

Event OnInit()
    Logger.RegisterPrefix(self, "ResetScriptVersionsTerminal")
EndEvent

; =============================================================================
; === Events  =================================================================
; =============================================================================

Event OnMenuItemRun(int auiMenuItemID, ObjectReference akTarget)
    Logger.Info(self, "Menu item selected: "+auiMenuItemID)
    VersionManager.ResetVersionsToDefault()
EndEvent
Scriptname RobcoAutoSort:VersionRegistry extends Quest

; =============================================================================
; === Properties  =============================================================
; =============================================================================

import RobcoAutoSort:Types

Group Dependencies
    RobcoAutoSort:TraceLogger property Logger auto const mandatory
EndGroup

Group FormVersions
    FormVersionInfo property AlternateActivationPerk Auto Const Mandatory
    FormVersionInfo property DumpCacheInfoTerminal Auto Const Mandatory
    FormVersionInfo property FilterRegistry Auto Const Mandatory
    FormVersionInfo property MainController Auto Const Mandatory
    FormVersionInfo property Matcher Auto Const Mandatory
    FormVersionInfo property ResetCacheInfoTerminal Auto Const Mandatory
    FormVersionInfo property ResetScriptVersionsTerminal Auto Const Mandatory
    FormVersionInfo property SortingCache Auto Const Mandatory
    FormVersionInfo property MatchTracingDisabledTerminal Auto Const Mandatory
    FormVersionInfo property MatchTracingEnabledTerminal Auto Const Mandatory
    FormVersionInfo property WorkshopMonitor Auto Const Mandatory
EndGroup

Group ObjectVersions
    ObjectVersionInfo property AutoSortActivator Auto Const Mandatory
    ObjectVersionInfo property FilterCardReader Auto Const Mandatory
    ObjectVersionInfo property SortingContainer Auto Const Mandatory
EndGroup

; =============================================================================
; === Initialization  =========================================================
; =============================================================================

Event OnInit()
    Logger.RegisterPrefix(self, "VersionRegistry")
EndEvent

; =============================================================================
; === Public functions ========================================================
; =============================================================================

FormVersionInfo[] Function GetFormVersions()
    FormVersionInfo[] out = new FormVersionInfo[0]
    out.Add(AlternateActivationPerk)
    out.Add(DumpCacheInfoTerminal)
    out.Add(FilterRegistry)
    out.Add(MainController)
    out.Add(Matcher)
    out.Add(ResetCacheInfoTerminal)
    out.Add(ResetScriptVersionsTerminal)
    out.Add(SortingCache)
    out.Add(MatchTracingDisabledTerminal)
    out.Add(MatchTracingEnabledTerminal)
    out.Add(WorkshopMonitor)
    return out
EndFunction

ObjectVersionInfo[] Function GetObjectVersions()
    ObjectVersionInfo[] out = new ObjectVersionInfo[0]
    out.Add(AutoSortActivator)
    out.Add(FilterCardReader)
    out.Add(SortingContainer)
    return out
EndFunction

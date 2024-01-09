Scriptname RobcoAutoSort:DumpCacheInfoTerminal extends Terminal

; =============================================================================
; === Properties  =============================================================
; =============================================================================

Group FormLists
    FormList property CacheKeys auto const mandatory
EndGroup

Group ExternalScripts
    VersionManager property VersionManager auto const mandatory
    TraceLogger property Logger auto const mandatory
    SortingCache property Cache auto const mandatory
EndGroup

; =============================================================================
; === Initialization  =========================================================
; =============================================================================

Event OnInit()
    Logger.RegisterPrefix(self, "DumpCacheInfoTerminal")
EndEvent

; =============================================================================
; === Events  =================================================================
; =============================================================================

Event OnMenuItemRun(int auiMenuItemID, ObjectReference akTarget)
    Logger.Info(self, "Menu item selected: "+auiMenuItemID)
    int offset = auiMenuItemID-1

    Keyword cacheKey = CacheKeys.GetAt(offset) as Keyword
    Cache.DumpInfo(cacheKey)
EndEvent
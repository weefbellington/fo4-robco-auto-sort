Scriptname RobcoAutoSort:ResetCacheTerminal extends Terminal

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
    Logger.RegisterPrefix(self, "ResetCacheTerminal")
EndEvent

; =============================================================================
; === Events  =================================================================
; =============================================================================

Event OnMenuItemRun(int auiMenuItemID, ObjectReference akTarget)
    Logger.Info(self, "Terminal menu item selected: "+auiMenuItemID)
    if (auiMenuItemID == 0)
        Cache.ResetAllCaches()
    else
        int offset = auiMenuItemID-1
        Keyword cacheKey = CacheKeys.GetAt(offset) as Keyword
        Cache.ResetCache(cacheKey)
    endif
EndEvent
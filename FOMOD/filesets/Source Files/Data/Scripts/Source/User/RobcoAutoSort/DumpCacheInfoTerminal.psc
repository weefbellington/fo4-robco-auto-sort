Scriptname RobcoAutoSort:DumpCacheInfoTerminal extends Terminal

import RobcoAutoSort:FormLoader

; =============================================================================
; === Properties  =============================================================
; =============================================================================

SortingCache Property Cache Auto Hidden
DebugLog Property Log Auto Hidden
FormList Property CacheKeys Auto Hidden

; =============================================================================
; === Local event callbacks  ==================================================
; =============================================================================

Event OnInit()
    Cache = LoadSortingCache()
    Log = LoadDebugLog()
    CacheKeys = LoadAllCacheKeys()
EndEvent

Event OnMenuItemRun(int auiMenuItemID, ObjectReference akTarget)
    Log.Trace("Menu item selected: "+auiMenuItemID)
    int offset = auiMenuItemID-1

    Keyword cacheKey = CacheKeys.GetAt(offset) as Keyword
    Cache.DumpInfo(cacheKey)
EndEvent
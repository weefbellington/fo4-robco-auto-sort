Scriptname RobcoAutoSort:DumpCacheInfoTerminal extends Terminal

; =============================================================================
; === Properties  =============================================================
; =============================================================================

Group FormLists
    FormList property CacheKeys auto const mandatory
EndGroup

Group ExternalScripts
    VersionManager property VersionManager = None auto const
    TraceLogger property Logger auto const mandatory
    SortingCache property Cache auto const mandatory
EndGroup

; =============================================================================
; === Constants  ==============================================================
; =============================================================================

string LogFilename = "Robco Auto Sort" const
string LogPrefix = "[DumpCacheInfoTerminal] " const

; =============================================================================
; === Initialization  =========================================================
; =============================================================================

Event OnInit()
    Logger.RegisterPrefix(self, "DumpCacheInfoTerminal")
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
EndEvent

Event Actor.OnPlayerLoadGame(Actor akPlayer)
    _CheckForUpdates()
EndEvent

Function _CheckForUpdates()
    if VersionManager
        VersionManager.Update(self)
    endif
EndFunction

; =============================================================================
; === Events  =================================================================
; =============================================================================

Event OnMenuItemRun(int auiMenuItemID, ObjectReference akTarget)
    Logger.Info(self, "Menu item selected: "+auiMenuItemID)
    int offset = auiMenuItemID-1

    Keyword cacheKey = CacheKeys.GetAt(offset) as Keyword
    Cache.DumpInfo(cacheKey)
EndEvent
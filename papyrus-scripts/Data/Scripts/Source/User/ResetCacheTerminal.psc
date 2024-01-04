Scriptname RobcoAutoSort:ResetCacheTerminal extends Terminal

; =============================================================================
; === Properties  =============================================================
; =============================================================================

int property CurrentScriptVersion = 1 auto hidden

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
string LogPrefix = "[ResetCacheTerminal] " const

; =============================================================================
; === Initialization  =========================================================
; =============================================================================

Event OnInit()
    Logger.RegisterPrefix(self, "ResetCacheTerminal")
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
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
    Logger.Info(self, "Terminal menu item selected: "+auiMenuItemID)
    if (auiMenuItemID == 0)
        Cache.ResetAllCaches()
    else
        int offset = auiMenuItemID-1
        Keyword cacheKey = CacheKeys.GetAt(offset) as Keyword
        Cache.ResetCache(cacheKey)
    endif
EndEvent
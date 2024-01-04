Scriptname RobcoAutoSort:AlternateActivationPerk extends Perk

; =============================================================================
; === Properties  =============================================================
; =============================================================================

Group ExternalScripts
    VersionManager property VersionManager = None auto const
    TraceLogger property Logger auto const mandatory
EndGroup

bool property Locked = false auto hidden

; =============================================================================
; === Initialization  =========================================================
; =============================================================================

Event OnInit()
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
    Logger.RegisterPrefix(self, "AlternateActivationPerk")
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

Event OnEntryRun(int auiEntryID, ObjectReference akTarget, Actor akPlayer)
    if (!Locked)
        ; simple lock to ignore rapid player inputs
        ; prevent queueing up function calls to external script
        Locked = true
        ProcessEntry(auiEntryID, akTarget, akPlayer)
    endif
EndEvent

; =============================================================================
; === Private functions  ======================================================
; =============================================================================

Function ProcessEntry(int auiEntryID, ObjectReference akTarget, Actor akPlayer)
    ; Note: the default activation seems to bypass onEntryRun
    AutoSortActivator autoSortActivator = akTarget as RobcoAutoSort:AutoSortActivator

    Logger.Info(self, "Selected alternate activation choice: "+auiEntryID)
    if (auiEntryID == 0)
        autoSortActivator.BlockActivation(true, abHideActivateText=true)
        autoSortActivator.Activate(akPlayer)
    elseif (auiEntryID == 1)
        autoSortActivator.BlockActivation(true, abHideActivateText=true)
        autoSortActivator.StashItems()
    elseIf (auiEntryID == 2)
        autoSortActivator.BlockActivation(true, abHideActivateText=true)
        autoSortActivator.OpenCardReader()
    elseIf (auiEntryID == 3)
        autoSortActivator.OpenHelpTerminal()
    endif
    Locked = false
EndFunction
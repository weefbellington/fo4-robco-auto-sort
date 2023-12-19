Scriptname RobcoAutoSort:AlternateActivationPerk extends Perk

import RobcoAutoSort:FormLoader

; =============================================================================
; === Properties  =============================================================
; =============================================================================

DebugLog Property Log Auto Hidden

; =============================================================================
; === Local event callbacks  ==================================================
; =============================================================================

Event OnInit()
    Log = LoadDebugLog()
EndEvent

Event OnEntryRun(int auiEntryID, ObjectReference akTarget, Actor akPlayer)

    ; Note: the default activation seems to bypass onEntryRun
    ItemSorter itemSorter = akTarget as ItemSorter

    Log.Trace("Selected alternate activation choice: "+auiEntryID)

    if (auiEntryID == 0)
        itemSorter.Activate(akPlayer)
    elseif (auiEntryID == 1)
        itemSorter.StashItems()
    elseIf (auiEntryID == 2)
        itemSorter.OpenCardReader()
    elseIf (auiEntryID == 3)
        itemSorter.OpenHelpTerminal()
    endif
EndEvent
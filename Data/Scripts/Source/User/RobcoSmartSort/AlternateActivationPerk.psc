Scriptname RobcoSmartSort:AlternateActivationPerk extends Perk

Event OnEntryRun(int auiEntryID, ObjectReference akTarget, Actor akPlayer)
    SortingChest chest = akTarget as SortingChest
    if (auiEntryID == 0)
        chest.StashItems(akPlayer)
    elseIf (auiEntryID == 1)
    elseIf (auiEntryID == 2)
        chest.LoadHolotapes(akPlayer)
    endif
EndEvent
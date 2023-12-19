Scriptname RobcoAutoSort:SoundBoard extends Quest

; =============================================================================
; === Properties  =============================================================
; =============================================================================

Group Sounds
    ; robco_smart_sort_SoundSetKeyword
    Keyword Property SoundSetID Auto Const Mandatory
    ; OBJSwitchGenericFail
    Sound Property SortingContainerInvalidItemSound Auto Const Mandatory
    ; UITerminalHolotapeIn
    Sound Property CardReaderInstallCardSound Auto Const Mandatory 
    ; UITerminalHolotapeOut
    Sound Property CardReaderUninstallCardSound Auto Const Mandatory
    ; OBJTeleporterJammerLP
    Sound Property MoveToStashLoopSound Auto Const Mandatory
    ; DRSMetalMissileHatchOpen
    Sound Property MoveToStashEndSound Auto Const Mandatory
    ; OBJLoadElevatorUtilityButtonPanel
    Sound Property SortingContainerDisabledSound Auto Const Mandatory
    ; DRSCTrashCanSmallOpen
    Sound Property SortingContainerOpenSound Auto Const Mandatory
    ; DRSCTrashCanSmallClose
    Sound Property SortingContainerCloseSound Auto Const Mandatory
    ; UiTerminalPasswordGood
    Sound Property CardReaderLoadingEndSound Auto Const Mandatory
    ; UiTerminalCharScrollLP
    Sound Property CardReaderLoadingLoopSound Auto Const Mandatory
    ; UITerminalHolotapeProgramLoad
    Sound Property CardReaderOpenSound Auto Const Mandatory
    ; UITerminalHolotapeProgramQuit
    Sound Property CardReaderCloseSound Auto Const Mandatory
    ; UiTerminalPasswordBad
    Sound Property CardReaderInvalidCardSound Auto Const Mandatory
EndGroup

; =============================================================================
; === Public functions  =======================================================
; =============================================================================

Function PlayCardInstallSound(ObjectReference akTarget)
    PlaySoundWithoutOverlapping(SoundSetID, CardReaderInstallCardSound, akTarget)
EndFunction

Function PlayCardUninstallSound(ObjectReference akTarget)
    PlaySoundWithoutOverlapping(SoundSetID, CardReaderUninstallCardSound, akTarget)
EndFunction

int Function PlayDisabledButtonSound(ObjectReference akTarget, float volume=1.0)
    return PlaySoundAtVolume(SortingContainerDisabledSound, akTarget, volume)
EndFunction

int Function PlayMoveToStashLoopSound(ObjectReference akTarget, float volume=1.0)
    return PlaySoundAtVolume(MoveToStashLoopSound, akTarget, volume)
EndFunction

int Function PlaySortingContainerOpenSound(ObjectReference akTarget, float volume=1.0)
    return PlaySoundAtVolume(SortingContainerOpenSound, akTarget, volume)
EndFunction

int Function PlaySortingContainerCloseSound(ObjectReference akTarget, float volume=1.0)
    return PlaySoundAtVolume(SortingContainerCloseSound, akTarget, volume)
EndFunction

int Function PlayMoveToStashEndSound(ObjectReference akTarget, float volume=1.0)
    return PlaySoundAtVolume(MoveToStashEndSound, akTarget, volume)
EndFunction

int Function PlaySortingContainerInvalidItemSound(ObjectReference akTarget, float volume=0.5)
    return PlaySoundAtVolume(SortingContainerInvalidItemSound, akTarget, volume)
EndFunction

int Function PlayCardReaderLoadingEndSound(ObjectReference akTarget, float volume=1.0)
    return PlaySoundAtVolume(CardReaderLoadingEndSound, akTarget, volume)
EndFunction

int Function PlayCardReaderLoadingLoopSound(ObjectReference akTarget, float volume=1.0)
    return PlaySoundAtVolume(CardReaderLoadingLoopSound, akTarget, volume)
EndFunction

int Function PlayCardReaderOpenSound(ObjectReference akTarget, float volume=1.0)
    return PlaySoundAtVolume(CardReaderOpenSound, akTarget, volume)
EndFunction

int Function PlayCardReaderCloseSound(ObjectReference akTarget, float volume=1.0)
    return PlaySoundAtVolume(CardReaderCloseSound, akTarget, volume)
EndFunction

int Function PlayCardReaderInvalidCardSound(ObjectReference akTarget, float volume=1.0)
    return PlaySoundAtVolume(CardReaderInvalidCardSound, akTarget, volume)
EndFunction

int Function PlaySoundAtVolume(Sound akSound, ObjectReference akTarget, float volume=1.0)
    int soundID = akSound.Play(akTarget)
    Sound.SetInstanceVolume(soundID, 0.5)
    return soundID
EndFunction

Function PlaySoundWithoutOverlapping(Keyword soundSetID, Sound target, ObjectReference source) global
    DS:IntSet.Create(soundSetID)
    bool isSoundPlaying = DS:IntSet.Contains(soundSetID, target.GetFormID())
    if !isSoundPlaying
        int formID = target.GetFormID()
        DS:IntSet.Add(soundSetID, formID)
        target.PlayAndWait(source)
        DS:IntSet.Remove(soundSetID, formID)
    endif
EndFunction
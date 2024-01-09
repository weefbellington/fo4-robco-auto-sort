Scriptname RobcoAutoSort:AutoSortActivator extends ObjectReference

import RobcoAutoSort:Types

; =============================================================================
; === Const Properties  =======================================================
; =============================================================================

Group Sounds
    Sound property DisabledSound auto const mandatory
    Sound property LoadingLoopSound auto const mandatory
    Sound property ContainerOpenSound auto const mandatory
    Sound property ContainerCloseSound auto const mandatory
    Sound property CardReaderOpenSound auto const mandatory
    Sound property CardReaderCloseSound auto const mandatory
    Sound property ItemFlushSound auto const mandatory
    Sound property PositiveBeepSound auto const mandatory
EndGroup

Group Keywords 
    Keyword property MultiFilterKeyword auto const mandatory
    Keyword property MissingFilterKeyword auto const mandatory
EndGroup

Group Forms
    Form property CardReaderForm auto const mandatory
    Form property SortingContainerForm auto const mandatory
EndGroup

Group Terminals
    Terminal property HelpTerminal auto const mandatory
EndGroup

Group ExternalScripts
    VersionManager property VersionManager auto const mandatory
    TraceLogger property Logger auto const mandatory
    FilterRegistry property FilterRegistry auto const mandatory
EndGroup

string property ContainerDisplayName = "" auto hidden

Actor property Player auto hidden
ObjectReference property Workshop auto hidden
SortingContainer property SortingContainer auto hidden
FilterCardReader property CardReader auto hidden

; =============================================================================
; === States  =================================================================
; =============================================================================

state Processing
    Event OnActivate(ObjectReference akActionRef)
        DisabledSound.Play(self)
    EndEvent

    Function StashItems()
        DisabledSound.Play(self)
    EndFunction

    Function OpenSortingContainer()
        DisabledSound.Play(self)
    EndFunction

    Function OpenCardReader()
        DisabledSound.Play(self)
    EndFunction
endState

; =============================================================================
; === Initialization ==========================================================
; =============================================================================

Event OnInit()
    Logger.RegisterPrefix(self, "AutoSortActivator")
    Player = Game.GetPlayer()
    AddKeyword(MissingFilterKeyword)
    AddInventoryEventFilter(None)
EndEvent

; =============================================================================
; === Events ==================================================================
; =============================================================================

Event OnActivate(ObjectReference akActionRef)
    if (CardReader.GetInstalledFilters().Length == 0)
        OpenCardReader()
    else
        OpenSortingContainer()
    endif
EndEvent

Event OnWorkshopObjectPlaced(ObjectReference akWorkshop)
    _Setup(akWorkshop)
EndEvent

Event OnWorkshopObjectDestroyed(ObjectReference akWorkshop)
    _Cleanup()
EndEvent

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    if (asMenuName == "ContainerMenu")
        if (SortingContainer.IsActive)
            if (abOpening == false)
                _HandleContainerMenuClosed()
            else
                _HandleContainerMenuOpened()
            endif
        elseif (CardReader.IsActive)
            if (abOpening == false)
                _HandleCardReaderMenuClosed()
            else
                _HandleCardReaderMenuOpened()
            endif
        endif
    endif
EndEvent

; -----------------------------------------------------------------------------
; Move items from the sorting container to the workshop.
; Close the sorting container and wait for the close animation to play.
;
; While this function is running, the script is moved into the 'Processing'
; state and ignores player inputs.
; -----------------------------------------------------------------------------
Function _HandleContainerMenuClosed()
    _GoToProcessingState()

    bool playFlushSound = SortingContainer.GetItemCount() > 0

    SetOpen(false)

    ContainerCloseSound.Play(self)
    int loopSoundID = LoadingLoopSound.Play(self)

    SortingContainer.MoveItemsToWorkshop()    
    _WaitForClosed(fTimeout=3.0)

    Sound.StopInstance(loopSoundID)
    
    if (playFlushSound)
        ItemFlushSound.Play(self)
    endif

    SortingContainer.IsActive = false
    _EndProcessingState()
EndFunction

Function _HandleContainerMenuOpened()
EndFunction

; -----------------------------------------------------------------------------
; Close the card reader and wait for the close animation to play.
;
; While this function is running, the script is moved into the 'Processing'
; state and ignores player inputs.
; -----------------------------------------------------------------------------
Function _HandleCardReaderMenuClosed()
    _GoToProcessingState()

    CardReaderCloseSound.Play(self)
    SetOpen(false)

    _WaitForClosed(fTimeout=3.0)

    CardReader.IsActive = false
    _EndProcessingState()
EndFunction

Function _HandleCardReaderMenuOpened()
EndFunction

; -----------------------------------------------------------------------------
; When the sorting filters change, the sorted item list is invalidated.
; Scan the workshop inventory and reconstruct the list.
; -----------------------------------------------------------------------------
Event RobcoAutoSort:FilterCardReader.OnFiltersChanged(FilterCardReader akSender, Var[] akArgs)
    _GoToProcessingState()

    int soundID = LoadingLoopSound.Play(self)
    SortingContainer.RebuildTrackedItemArrays()

    Sound.StopInstance(soundID)
    PositiveBeepSound.Play(Player)

    _UpdateKeywords()
    _UpdateSortingContainerDisplayName()

    _EndProcessingState()
EndEvent

; -----------------------------------------------------------------------------
; Sets keywords based on which sorting filters are enabled.

; These keyword determine which activation options to display when the player
; hovers over the container with their mouse.
; -----------------------------------------------------------------------------
Function _UpdateKeywords()
    _RemoveAllFilterKeywords()

    Filter[] installedFilters = CardReader.GetInstalledFilters()
    if (installedFilters.Length == 0)
        AddKeyword(MissingFilterKeyword)
    elseif (installedFilters.Length == 1)
        Filter installedFilter = installedFilters[0]
        Keyword filterKywd = installedFilter.CacheID
        AddKeyword(filterKywd)
    else
        AddKeyword(MultiFilterKeyword)
    endif
EndFunction

; -----------------------------------------------------------------------------
; Sets keywords based on which sorting filters are enabled.

; These keyword determine which activation options to display when the player
; hovers over the container with their mouse.
; -----------------------------------------------------------------------------
Function _RemoveAllFilterKeywords()
    RemoveKeyword(MissingFilterKeyword)
    RemoveKeyword(MultiFilterKeyword)
    Filter[] filters = FilterRegistry.GetAllFilters()
    int i = 0
    while (i < filters.Length)
        Keyword kywd = filters[i].CacheID
        RemoveKeyword(kywd)
        i += 1
    endwhile
EndFunction


Function _UpdateSortingContainerDisplayName()
    Filter[] installedFilters = CardReader.GetInstalledFilters()
    int installCount = installedFilters.Length
    if (installCount == 1)
        Types:Filter filter = installedFilters[0]
        Logger.Info(self, "1 card installed, setting container name to '"+filter.DisplayTitle+"'")
        ContainerDisplayName = filter.DisplayTitle
    else
        Logger.Info(self, "0 or 1+ cards installed, setting container name to default.")
        ContainerDisplayName = ""
    endif
EndFunction


; =============================================================================
; === Public functions ========================================================
; =============================================================================

Function Delete()
    Logger.Info(self, "Delete() called")
    _Cleanup()
    parent.Delete()
EndFunction

Function DeleteWhenAble()
    Logger.Info(self, "DeleteWhenAble() called")
    _Cleanup()
    parent.DeleteWhenAble()
EndFunction

Function _TryDelete(ObjectReference ref)
    if (ref)
        ref.Delete()
    endif
EndFunction

; -----------------------------------------------------------------------------
; 1. Move sorted items from the workshop
; 2. Play the activator's open animation and wait for it to complete
; 3. Open the sorting container
;
; While this function is running, the script is moved into the 'Processing'
; state and ignores player inputs.
; -----------------------------------------------------------------------------
Function OpenSortingContainer()
    _GoToProcessingState()
    SortingContainer.IsActive = true

    Logger.Info(self, "Opening sorting container")
    
    SetOpen(true)
    ContainerOpenSound.Play(self)
    SortingContainer.SetOpen(true)
    int loopSoundID = LoadingLoopSound.Play(self)

    SortingContainer.MoveItemsFromWorkshop()
    _WaitForOpen(3.0)

    SortingContainer.SetDisplayName(ContainerDisplayName)
    Sound.StopInstance(loopSoundID)
    
    SortingContainer.Activate(Player)
    
    _EndProcessingState()
EndFunction

; -----------------------------------------------------------------------------
; Open the card reader container for the player to load cards
; -----------------------------------------------------------------------------
Function OpenCardReader()
    _GoToProcessingState()
    
    CardReader.IsActive = true

    Logger.Info(self, "Opening card reader")

    SetOpen(true)
    _WaitForOpen(fTimeout=3.0)

    CardReaderOpenSound.Play(self)
    CardReader.Activate(Player)

    _EndProcessingState()
EndFunction

; -----------------------------------------------------------------------------
; Scans the player inventory for items matching the installed filters and
; moves these items to workshop storage.
;
; While this function is running, the script is moved into the 'Processing'
; state and ignores player inputs.
; -----------------------------------------------------------------------------
Function StashItems()
    _GoToProcessingState()
    Logger.Info(self, "Stashing items")

    int loopSoundID = LoadingLoopSound.Play(self)
    int numItemsMoved = SortingContainer.MovePlayerItemsToWorkshop()
    Sound.StopInstance(loopSoundID)

    _EndProcessingState()

    ; TODO: check if correct sound plays when rejecting quest item
    if (numItemsMoved > 0)
        ItemFlushSound.Play(self)
    else
        DisabledSound.Play(self)
    endIf
EndFunction

; -----------------------------------------------------------------------------
; Opens the help terminal in the pip-boy.
; -----------------------------------------------------------------------------
Function OpenHelpTerminal()
    Logger.Info(self, "Opening help terminal")
    HelpTerminal.ShowOnPipboy()
EndFunction


; =============================================================================
; === Private functions =======================================================
; =============================================================================

Function _Setup(ObjectReference akWorkshop)
    Workshop = akWorkshop
    _CreateContainers()
    _RegisterForEvents()
    VersionManager.Register(self)
EndFunction

Function _Cleanup()
    VersionManager.Unregister(self)
    UnregisterForAllEvents()
    _DestroyContainers()
    Player = None
    Workshop = None
EndFunction

Function _CreateContainers()
    SortingContainer = PlaceAtMe(SortingContainerForm, abForcePersist = true) as SortingContainer
    CardReader = PlaceAtMe(CardReaderForm, abForcePersist = true) as FilterCardReader

    SortingContainer.BindTo(self)
    CardReader.BindTo(self)
EndFunction

Function _DestroyContainers()
    _TryDelete(CardReader)
    _TryDelete(SortingContainer)

    CardReader = None
    SortingContainer = None
EndFunction

Function _RegisterForEvents()
    RegisterForMenuOpenCloseEvent("ContainerMenu")
    RegisterForCustomEvent(CardReader, "OnFiltersChanged")
EndFunction

; -----------------------------------------------------------------------------
; Wait until OpenState matches "Open" (1)
; -----------------------------------------------------------------------------
; PARAMS:
; - fTimeout: max time to wait before returning, in seconds
; -----------------------------------------------------------------------------
Function _WaitForOpen(float fTimeout)
    _WaitForOpenState(1, fTimeout)
EndFunction

; -----------------------------------------------------------------------------
; Wait until OpenState matches "Closed" (3)
; -----------------------------------------------------------------------------
; PARAMS:
; - fTimeout: max time to wait before returning, in seconds
; RETURNS:
; The total wait time, in seconds
; -----------------------------------------------------------------------------
Function _WaitForClosed(float fTimeout)
    _WaitForOpenState(3, fTimeout)
EndFunction

; -----------------------------------------------------------------------------
; Wait until OpenState matches a value
; -----------------------------------------------------------------------------
; PARAMS:
; - iTargetState: value to match
; - fTimeout: max time to wait before returning, in seconds
; -----------------------------------------------------------------------------
Function _WaitForOpenState(int iTargetState, float fTimeout)

    ; avoid external function call to Utility if possible
    if (GetOpenState() == iTargetState)
        return
    endif

    float startTime = Utility.GetCurrentRealTime()
    while (true)
        float currentTime = Utility.GetCurrentRealTime()
        float elapsedTime = currentTime - startTime

        bool complete = GetOpenState() == iTargetState || elapsedTime > fTimeout
        if (complete)
            return
        endif

        Utility.Wait(0.1)
    endwhile
EndFunction

bool Function _IsInProcessingState()
    return GetState() == "Processing"
EndFunction

Function _ReregisterAllEvents()
    _RegisterForEvents()
    CardReader.RegisterForMenuOpenCloseEvent("ContainerMenu")
    CardReader.BindTo(self)
    SortingContainer.BindTo(self)
EndFunction

Function _GoToProcessingState()
    _ReregisterAllEvents()

    GotoState("Processing")
    BlockActivation(true, abHideActivateText=true)
EndFunction

Function _EndProcessingState()
    GoToState("")
    BlockActivation(false)
EndFunction
Scriptname RobcoAutoSort:ItemSorter extends ObjectReference

import RobcoAutoSort:Types
import RobcoAutoSort:FormLoader

; =============================================================================
; === Properties  =============================================================
; =============================================================================

Message Property InvalidItemMsg Auto Hidden

Keyword Property MultiFilterKeyword Auto Hidden
Keyword Property MissingFilterKeyword Auto Hidden

DebugLog Property Log Auto Hidden
SoundBoard Property SoundBoard Auto Hidden
Matcher Property Matcher Auto Hidden
FilterRegistry Property FilterRegistry Auto Hidden

Form Property CardReaderForm Auto Hidden
Form Property EmptyContainerForm Auto Hidden
Terminal Property HelpTerminalForm Auto Hidden

; =============================================================================
; === Variables  ==============================================================
; =============================================================================

Actor Player

ObjectReference kWorkshop = None
ObjectReference kSortingContainer = None

FilterCardReader kCardReader = None

bool bIsSortingContainerOpen = false
bool bIsCardReaderOpen = false

Form[] kSortedItems

; =============================================================================
; === States  =================================================================
; =============================================================================

state Processing

    Event OnActivate(ObjectReference akActionRef)
        SoundBoard.PlayDisabledButtonSound(self)
    EndEvent

    Function StashItems()
        SoundBoard.PlayDisabledButtonSound(self)
    EndFunction

    Function OpenCardReader()
        SoundBoard.PlayDisabledButtonSound(self)
    EndFunction
endState

; =============================================================================
; === Local event callbacks ===================================================
; =============================================================================

Event OnInit()
    Player = Game.GetPlayer()

    MultiFilterKeyword = LoadPluginForm(0x00015EB3) as Keyword
    MissingFilterKeyword = LoadPluginForm(0x00015EB4) as Keyword

    Log = LoadDebugLog()
    SoundBoard = LoadSoundBoard()
    Matcher = LoadMatcher()
    FilterRegistry = LoadFilterRegistry()
    HelpTerminalForm = LoadHelpTerminal()
    InvalidItemMsg = LoadMessage(0x00007AB7)

    CardReaderForm = LoadCardReader()
    EmptyContainerForm = LoadSortingContainer()

    AddKeyword(MissingFilterKeyword)

    AddInventoryEventFilter(None)
EndEvent


Event OnActivate(ObjectReference akActionRef)
    if (kCardReader.GetInstalledFilters().Length == 0)
        OpenCardReader()
    else
        OpenSortingContainer()
    endif
EndEvent

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    if (asMenuName == "ContainerMenu")
        if (_IsSortingContainerOpen())
            if (abOpening == false)
                _HandleContainerMenuClosed()
            else
                _HandleContainerMenuOpened()
            endif
        elseif (_IsCardReaderOpen())
            if (abOpening == false)
                _HandleCardReaderMenuClosed()
            else
                _HandleCardReaderMenuOpened()
            endif
        endif
    endif

EndEvent

Event OnWorkshopObjectPlaced(ObjectReference akWorkshop)
    ; save reference to workshop that created this object
    kWorkshop = akWorkshop
    kSortedItems = new Form[0]

    _CreateContainers()
    _RegisterForEvents()
EndEvent

Event OnWorkshopObjectDestroyed(ObjectReference akWorkshop)
    _UnregisterForEvents()

    _MoveSortingCardsToWorkshop()
    _MoveItemsToWorkshop()

    _DestroyContainers()

    kSortedItems.Clear()
    kWorkshop = None
EndEvent

; =============================================================================
; === Remote event callbacks ==================================================
; =============================================================================

Event ObjectReference.OnItemAdded(ObjectReference akSender, Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    HandleItemAdded(akSender, akBaseItem, akItemReference, akSourceContainer)
EndEvent


Event ObjectReference.OnItemRemoved(ObjectReference akSender, Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
    HandleItemRemoved(akSender, akBaseItem, akItemReference, akDestContainer)
EndEvent

; -----------------------------------------------------------------------------
; When the sorting filters change, the tracked item list is invalidated.
; Scan the workshop inventory and reconstruct the list.
; -----------------------------------------------------------------------------
Event RobcoAutoSort:FilterCardReader.OnFiltersChanged(FilterCardReader akSender, Var[] akArgs)
    _GoToProcessingState()

    int soundID = SoundBoard.PlayCardReaderLoadingLoopSound(self)
    _RebuildTrackedItemArrays()

    Sound.StopInstance(soundID)
    SoundBoard.PlayCardReaderLoadingEndSound(self)

    _UpdateKeywords()

    _EndProcessingState()
EndEvent

; =============================================================================
; === Public functions ========================================================
; =============================================================================

; -----------------------------------------------------------------------------
; 1. Move sorted items from the workshop
; 2. Play the activator's open animation and wait for it to complete
; 3. Open the sorting container
;
; While this function is running, the script is moved into the 'Processing'
; state and ignores player inputs.
; -----------------------------------------------------------------------------
Function OpenSortingContainer()
    Log.Trace("Opening sorting container")

    _GoToProcessingState()
    _SetSortingContainerOpen(true)
    SetOpen(true)
    SoundBoard.PlaySortingContainerOpenSound(Player)

    _MoveItemsFromWorkshop()
    _WaitForOpen(fTimeout=3.0)

    ;/ The container gets the display from the base object.
       Since all ObjectReferences share the same base object,
       reset the name each time the container is opened. /;
    kSortingContainer.GetBaseObject().SetName(kCardReader.GetTitleForDisplay())
    kSortingContainer.Activate(Player)
    
    _EndProcessingState()
EndFunction

; -----------------------------------------------------------------------------
; Open the card reader container for the player to load cards
; -----------------------------------------------------------------------------
Function OpenCardReader()
    Log.Trace("Opening card reader")

    _GoToProcessingState()
    _SetCardReaderOpen(true)
    SetOpen(true)
    ; TODO change sound
    SoundBoard.PlayCardReaderOpenSound(Player)

    _WaitForOpen(fTimeout=3.0)

    kCardReader.Activate(Player)

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
    Log.Trace("Stashing items")

    int soundID = SoundBoard.PlayMoveToStashLoopSound(self)
    _GoToProcessingState()

    SetOpen(false)
    int numItemsMoved = _MovePlayerItemsToWorkshop()

    _EndProcessingState()
    Sound.StopInstance(soundID)

    ; TODO: check if correct sound plays when rejecting quest item
    if (numItemsMoved > 0)
        SoundBoard.PlayMoveToStashEndSound(self)
    else
        SoundBoard.PlayDisabledButtonSound(self)
    endIf
EndFunction

; -----------------------------------------------------------------------------
; Opens the help terminal in the pip-boy.
; -----------------------------------------------------------------------------
Function OpenHelpTerminal()
    Log.Trace("Opening help terminal")

    HelpTerminalForm.ShowOnPipboy()
EndFunction


; =============================================================================
; === Private functions ========================================================
; =============================================================================

; -----------------------------------------------------------------------------
; Sets keywords based on which sorting filters are enabled.

; These keyword determine which activation options to display when the player
; hovers over the container with their mouse.
; -----------------------------------------------------------------------------
Function _UpdateKeywords()
    _RemoveAllFilterKeywords()

    Filter[] installedFilters = kCardReader.GetInstalledFilters()
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

; =============================================================================
; The following handler functions are called when items matching the sorting
; filters are added or removed from:
;   1. the workshop container
;   2. the sorting container
; It adds matching items to a sorted item array to allow quick movement
; between containers.
; =============================================================================

; -----------------------------------------------------------------------------
; When an item is added to the workshop or the sorting container:
;   1. check if it matches the sorting filters
;   2. on match, add to sorted item array
; -----------------------------------------------------------------------------
; PARAMS:
; - akSender: sender of the remote event
; - akBaseItem: base item added to container
; - akItemReference: ObjectReference, or None if non-persistent
; - akSourceContainer: where item was moved from
; -----------------------------------------------------------------------------
Function HandleItemAdded(ObjectReference akSender, Form akBaseItem, ObjectReference akItemReference, ObjectReference akSourceContainer)
    ; this function is a tight loop -- avoid logging where possible.

    ; ignore cases where items are moving between workshop and sorting container
    bool isSortingContainerSource = akSourceContainer == kSortingContainer
    bool isWorkshopSource = akSourceContainer == kWorkshop
    bool isSortingContainerDestination = akSender == kSortingContainer
    bool isWorkshopDestination = akSender == kWorkshop
    if (isSortingContainerSource && isWorkshopDestination) || (isWorkshopSource && isSortingContainerDestination)
        return
    endif

    if (akSourceContainer == Player)
        bool isQuestItem = _ReturnQuestItemsToPlayer(akItemReference)
        if (isQuestItem)
            return
        endif
    endif

    _LogItemAdded(akBaseItem, akItemReference)
    bool isMatch = _CheckForMatch(akBaseItem)
    if (isMatch)
        _AddToSortedItemArray(akBaseItem)
    elseif (isSortingContainerDestination)
        ; Handle case where a non-matching item is added to the sorting container
        RobcoAutoSort:Util.MoveAllItems(akBaseItem, from=akSender, to=akSourceContainer)
        SoundBoard.PlaySortingContainerInvalidItemSound(Player)
        InvalidItemMsg.Show()
        Ui.CloseMenu("ContainerMenu")
    endif
EndFunction

; -----------------------------------------------------------------------------
; When an item is removed by from the workshop or sorting container, remove it
; from the sorted item array, based on the following conditions:
;
; PERSISTENT OBJECTS
; Persistant objects are assumed to be unique. When a persistent object is
; removed from the container, always remove it from the array.

; NON-PERSISTENT OBJECTS
; Count the number of items of the same type that remain in the container.
; If the count is 0 (all items removed), remove the item from the array.
; -----------------------------------------------------------------------------
; PARAMS:
; - akSender: sender of the remote event
; - akBaseItem: base item removed from container
; - akItemReference: ObjectReference, or None if non-persistent
; - akDestContainer: where item was moved to
; -----------------------------------------------------------------------------
Function HandleItemRemoved(ObjectReference akSender, Form akBaseItem, ObjectReference akItemReference, ObjectReference akDestContainer)

    ; ignore cases where items are moving between workshop and sorting container
    bool isSortingContainerSource = akSender == kSortingContainer
    bool isWorkshopSource = akSender == kWorkshop
    bool isSortingContainerDestination = akDestContainer == kSortingContainer
    bool isWorkshopDestination = akDestContainer == kWorkshop
    if (isSortingContainerSource && isWorkshopDestination) || (isWorkshopSource && isSortingContainerDestination)
        return
    endif

    int remainingCount = akSender.GetItemCount(akBaseItem)
    if (remainingCount == 0)
        _RemoveFromSortedItemArray(akBaseItem)
    endif
EndFunction

Function _LogItemAdded(Form akBaseItem, ObjectReference akItemReference)
    if (Log.IsDebugEnabled())
        string itemName = RobcoAutoSort:Util.GetItemName(akBaseItem, akItemReference)
        Log.Trace("Item "+itemName+" added to workshop or sorting container.")
        if (akBaseItem == None && akItemReference == None)
            Log.Error("Warning: akBaseItem == None and akItemReference == None. This should never happen!")
        elseif (akBaseItem==None && akItemReference != None)
            Log.Warning("Warning: akBaseItem == None. Code will need to be modified to handle None.")
        endif
    
    endif
EndFunction

; -----------------------------------------------------------------------------
; Checks whether an item matches the filters installed in the card reader.
; -----------------------------------------------------------------------------
; PARAMS:
; - akBaseItem: an item to check
; RETURNS:
; 'true' on match
; -----------------------------------------------------------------------------
bool Function _CheckForMatch(Form akBaseItem)
    Filter[] installedModules = kCardReader.GetInstalledFilters()
    return Matcher.MatchesAnyFilter(akBaseItem, installedModules)
EndFunction

; -----------------------------------------------------------------------------
; Checks if an object is a quest item. If true, return it to the player's
; inventory.
; -----------------------------------------------------------------------------
; PARAMS:
; - akItemReference: the object to check
; RETURNS:
; 'true' if the item was rerturned
; -----------------------------------------------------------------------------
bool Function _ReturnQuestItemsToPlayer(ObjectReference akItemReference)
    bool isQuestItem = akItemReference != None && akItemReference.IsQuestItem()
    bool isItemReturned = _MoveItemToPlayerInventory(akItemReference, bCondition=isQuestItem)
    if (isItemReturned)
        string itemName = akItemReference.GetBaseObject().GetName()
        Log.Info("Quest item returned to player: "+itemName, notification=true)
    endif
    return isItemReturned
EndFunction

; -----------------------------------------------------------------------------
; Moves an item to the player's inventory, based on some condition
; -----------------------------------------------------------------------------
; PARAMS:
; - akItemReference: the object to move
; - bCondition: the condition to check
; RETURNS:
; 'true' if the item was moved
; -----------------------------------------------------------------------------
bool Function _MoveItemToPlayerInventory(ObjectReference akItemReference, bool bCondition)
    if (bCondition)
        ObjectReference sourceContainer = akItemReference.GetContainer()
        RobcoAutoSort:Util.MoveItem(akItemReference, from=sourceContainer, to=Player)
    endif
    return bCondition
EndFunction

Function _HandleContainerMenuOpened()
EndFunction

; -----------------------------------------------------------------------------
; Move items from the sorting container to the workshop.
; Close the sorting container and wait for the close animation to play.
;
; While this function is running, the script is moved into the 'Processing'
; state and ignores player inputs.
; -----------------------------------------------------------------------------
Function _HandleContainerMenuClosed()
    _GoToProcessingState()
    _MoveItemsToWorkshop()

    ; TODO: play correct close sound
    SoundBoard.PlaySortingContainerCloseSound(Player)
    _SetSortingContainerOpen(false)
    SetOpen(false)
    _WaitForClosed(fTimeout=3.0)
    _EndProcessingState()
EndFunction

Function _HandleCardReaderMenuOpened()
EndFunction

; -----------------------------------------------------------------------------
; Close the card reader and wait for the close animation to play.
;
; While this function is running, the script is moved into the 'Processing'
; state and ignores player inputs.
; -----------------------------------------------------------------------------
Function _HandleCardReaderMenuClosed()
    _GoToProcessingState()

    ; TODO: change sound
    SoundBoard.PlayCardReaderCloseSound(Player)
    _SetCardReaderOpen(false)
    SetOpen(false)
    _WaitForClosed(fTimeout=3.0)
    _EndProcessingState()
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
; Wait until OpenState matches "Open" (3)
; -----------------------------------------------------------------------------
; PARAMS:
; - fTimeout: max time to wait before returning, in seconds
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
    float startTime = Utility.GetCurrentRealTime()
    while (true)
        float currentTime = Utility.GetCurrentRealTime()
        float elapsedTime = currentTime - startTime

        if (elapsedTime > fTimeout)
            return
        endif

        bool isOpen = GetOpenState() == iTargetState
        if (isOpen)
            return
        endif

        Utility.Wait(0.1)
    endwhile
EndFunction

; -----------------------------------------------------------------------------
; Scan for items in workshop storage that match the installed filters.
; Add matching items to the sorted item array.
; -----------------------------------------------------------------------------
; PARAMS:
; - timeout: max time to wait before returning, in seconds
; -----------------------------------------------------------------------------
Function _RebuildTrackedItemArrays()
    Filter[] filters = kCardReader.GetInstalledFilters()
    Form[] matchingItems = Matcher.CheckContainerForMatches(kWorkshop, filters)
    kSortedItems = matchingItems
EndFunction

; -----------------------------------------------------------------------------
; Remove all items from the sorting container and place them in workshop
; storage.
; -----------------------------------------------------------------------------
Function _MoveItemsToWorkshop()
    Log.Info("Moving " + kSortingContainer.GetItemCount() + " items from temp container to workshop")
    kSortingContainer.RemoveAllItems(kWorkshop)
EndFunction

; -----------------------------------------------------------------------------
; Iterate over the sorted item array and move all matching items from the
; workshop storage to the sorted item container.
; -----------------------------------------------------------------------------
int Function _MoveItemsFromWorkshop()
    int itemsRemoved = 0
    int itemIndex = 0
    while (itemIndex < kSortedItems.Length)
        Form itemToRemove = kSortedItems[itemIndex]
        int removeCount = kWorkshop.GetItemCount(itemToRemove)
        kWorkshop.RemoveItem(itemToRemove, removeCount, true, kSortingContainer)
        itemsRemoved += removeCount
        itemIndex += 1
    endwhile
    return itemsRemoved
EndFunction

; -----------------------------------------------------------------------------
; Scan the player inventory for items matching the sorting filters.
; Remove matching items from player inventory and place in workshop.
; -----------------------------------------------------------------------------
int Function _MovePlayerItemsToWorkshop()
    Filter[] installedFilters = kCardReader.GetInstalledFilters()
    Log.Trace("Moving player items to workshop - check for matches")
    Form[] matchingForms = Matcher.CheckContainerForMatches(Player, installedFilters)
    int i = 0
    while (i < matchingForms.Length)
        Form match = matchingForms[i]
        int itemCount = Player.GetItemCount(match)
        Player.RemoveItem(match, aiCount = itemCount, abSilent = true, akOtherContainer = kWorkshop)
        i += 1
    endwhile
    return matchingForms.Length
EndFunction

; -----------------------------------------------------------------------------
; Add an item to the sorted item array, if it has not already been added.
; -----------------------------------------------------------------------------
Function _AddToSortedItemArray(Form akBaseItem)
    int trackedFormIndex = kSortedItems.Find(akBaseItem)
    if (trackedFormIndex < 0)
        string itemName = akBaseItem.GetName()
        Log.Trace("Adding to sorted item array:" + itemName)
        kSortedItems.Add(akBaseItem)
    endif
EndFunction

; -----------------------------------------------------------------------------
; Remove an item from the sorted item array, if it exists in the array.
; -----------------------------------------------------------------------------
Function _RemoveFromSortedItemArray(Form akBaseItem)
    int trackedFormIndex = kSortedItems.Find(akBaseItem)
    if (trackedFormIndex > -1)
        string itemName = akBaseItem.GetName()
        Log.Trace("Removing from sorted item array:" + itemName)
        kSortedItems.Remove(trackedFormIndex)
    endif
EndFunction

; -----------------------------------------------------------------------------
; Remove all sorting cards from the card reader and place in the workshop.
; Called when the activator object is destroyed (deleted in workshop mode).
; -----------------------------------------------------------------------------
Function _MoveSortingCardsToWorkshop()
    kCardReader.RemoveAllItems(kWorkshop)
EndFunction

Function _RegisterForEvents()
    RegisterForMenuOpenCloseEvent("ContainerMenu")

    _RegisterForItemAddedEvent(kWorkshop)
    _RegisterForItemRemovedEvent(kWorkshop)
    _RegisterForItemAddedEvent(kSortingContainer)
    _RegisterForItemRemovedEvent(kSortingContainer)

    RegisterForCustomEvent(kCardReader, "OnFiltersChanged")
EndFunction

Function _UnregisterForEvents()
    UnregisterForAllMenuOpenCloseEvents()

    _UnegisterForItemAddedEvent(kWorkshop)
    _UnregisterForItemRemovedEvent(kWorkshop)
    _UnegisterForItemAddedEvent(kSortingContainer)
    _UnregisterForItemRemovedEvent(kSortingContainer)

    UnregisterForCustomEvent(kCardReader, "OnFiltersChanged")
EndFunction

Function _CreateContainers()
    ; place invisible containers
    kSortingContainer = PlaceAtMe(EmptyContainerForm, abForcePersist = true)
    kCardReader = PlaceAtMe(CardReaderForm, abForcePersist = true) as FilterCardReader
    ; attach invisible containers so they move with the activator
    kSortingContainer.AttachTo(self)
    kCardReader.AttachTo(self)
EndFunction

Function _DestroyContainers()

    kCardReader.AttachTo(None)
    ; Destroy() performs cleanup and then calls Delete()
    kCardReader.Destroy()
    kCardReader = None

    kSortingContainer.AttachTo(None)
    kSortingContainer.Delete()
    kSortingContainer = None
EndFunction

Function _RegisterForItemAddedEvent(ObjectReference akContainer)
    RegisterForRemoteEvent(akContainer, "OnItemAdded")
EndFunction

Function _UnegisterForItemAddedEvent(ObjectReference akContainer)
    UnregisterForRemoteEvent(akContainer, "OnItemAdded")
EndFunction

Function _RegisterForItemRemovedEvent(ObjectReference akContainer)
    RegisterForRemoteEvent(akContainer, "OnItemRemoved")
EndFunction

Function _UnregisterForItemRemovedEvent(ObjectReference akContainer)
    UnregisterForRemoteEvent(akContainer, "OnItemRemoved")
EndFunction

Function _GoToProcessingState()
    GotoState("Processing")
EndFunction

Function _EndProcessingState()
    GoToState("")
EndFunction

Function _SetSortingContainerOpen(bool isOpen)
    bIsSortingContainerOpen = isOpen
EndFunction

bool Function _IsSortingContainerOpen()
    return bIsSortingContainerOpen
EndFunction

Function _SetCardReaderOpen(bool isOpen)
    bIsCardReaderOpen = isOpen
EndFunction

bool Function _IsCardReaderOpen()
    return bIsCardReaderOpen
EndFunction
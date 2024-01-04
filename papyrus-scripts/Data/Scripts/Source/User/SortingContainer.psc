Scriptname RobcoAutoSort:SortingContainer extends ObjectReference

import RobcoAutoSort:Types

; =============================================================================
; === Properties  =============================================================
; =============================================================================

int property CurrentScriptVersion = 1 auto hidden

Group CacheKeywords
    Keyword property SortedItemsCacheKey auto const mandatory
EndGroup

Group Sounds
    Sound property NegativeBeepSound auto const mandatory
EndGroup

Group Messages 
    Message property InvalidItemMsg auto const mandatory
EndGroup

Group ExternalScripts
    VersionManager property VersionManager = None auto const
    TraceLogger property Logger auto const mandatory
    Matcher property Matcher auto const mandatory
    WorkshopMonitor property WorkshopMonitor auto const mandatory
EndGroup

ObjectReference property Workshop auto hidden
FilterCardReader property CardReader auto hidden

Actor property Player auto hidden

bool property IsActive = false auto hidden

; =============================================================================
; === Constants  ==============================================================
; =============================================================================

string DEFAULT_DISPLAY_NAME = "Sorted Items" Const

; =============================================================================
; === Initialization  =========================================================
; =============================================================================

Event OnInit()
    Logger.RegisterPrefix(self, "SortingContainer")
    Player = Game.GetPlayer()
    AddInventoryEventFilter(None)
    _CreateSortedItemArray()
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
; === Override functions ======================================================
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

Function _Cleanup()
    UnregisterForAllEvents()
    WorkshopMonitor.UnregisterForWorkshopUpdates(self, Workshop)
    Player = None
    Workshop = None
    CardReader = None
    AttachTo(None)
    _ClearSortedItemArray()
EndFunction

; =============================================================================
; === Public functions ========================================================
; =============================================================================


Function BindTo(AutoSortActivator binder)
    AttachTo(binder)
    Workshop = binder.Workshop
    CardReader = binder.CardReader
    WorkshopMonitor.RegisterForWorkshopUpdates(self, Workshop)
EndFunction

Function SetDisplayName(string displayName)
    if (displayName == "")
        displayName = DEFAULT_DISPLAY_NAME
    endif
    GetBaseObject().SetName(displayName)
EndFunction

; =============================================================================
; === Events ==================================================================
; =============================================================================

; -----------------------------------------------------------------------------
; When an item is added to the sorting container, append to the workshop
; remove buffer.
; 
; This event is ignored if the source container is the workshop.
; -----------------------------------------------------------------------------
Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    if (akSourceContainer == Workshop)
        return
    endif
    WorkshopMonitor.AppendToAddBuffer(Workshop, akBaseItem, akItemReference, aiItemCount)

    ; Handle case where a non-matching item is added to the sorting container
    if (_CheckForMatch(akBaseItem) == false)
        RemoveItem(akBaseItem, aiItemCount, true, Player)
        NegativeBeepSound.Play(Player)
        InvalidItemMsg.Show()
        Ui.CloseMenu("ContainerMenu")
    endif
EndEvent

; -----------------------------------------------------------------------------
; When an item is removed from the sorting container, append to the workshop
; remove buffer.
;
; This event is ignored if the destination container is the workshop.
; -----------------------------------------------------------------------------
Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
    if (akDestContainer == Workshop)
        return
    endif
    WorkshopMonitor.AppendToRemoveBuffer(Workshop, akBaseItem, akItemReference, aiItemCount)
EndEvent

; -----------------------------------------------------------------------------
; When items are added to the workshop, check if they match the current
; filters. On match, add to the cache.
;
; The cache makes it more efficient to move matching items back and forth
; between the sorting container and the workshop.
; -----------------------------------------------------------------------------
Event RobcoAutoSort:WorkshopMonitor.OnWorkshopItemsAdded(WorkshopMonitor akSender, Var[] args)
    Form[] matches = Matcher.CheckForMatches(args as Form[], CardReader.GetInstalledFilters(), enableTrace=CardReader.IsTraceEnabled)
    if (matches.Length > 0)
        int addCount = _AddAllToSortedItemArray(matches)
        Logger.Info(self, addCount + " items added to sorted items array")
    endif
EndEvent

; -----------------------------------------------------------------------------
; When items are removed from the workshop, check if they match the current
; filters. On match, remove from the cache.
; -----------------------------------------------------------------------------
Event RobcoAutoSort:WorkshopMonitor.OnWorkshopItemsRemoved(WorkshopMonitor akSender, Var[] args)
    Form[] matches = Matcher.CheckForMatches(args as Form[], CardReader.GetInstalledFilters(), enableTrace=CardReader.IsTraceEnabled)
    if (matches.Length > 0)
        int removeCount = _RemoveAllFromSortedItemArray(matches)
        Logger.Info(self, removeCount + " items removed from sorted items array")
    endif
EndEvent

; -----------------------------------------------------------------------------
; Scan for items in workshop storage that match the installed filters.
; Add matching items to the cache.
; -----------------------------------------------------------------------------
Function RebuildTrackedItemArrays()
    Filter[] filters = CardReader.GetInstalledFilters()
    Form[] workshopItems = Workshop.GetInventoryItems()
    Form[] matchingItems = Matcher.CheckForMatches(workshopItems, filters, enableTrace=CardReader.IsTraceEnabled)
    _ClearSortedItemArray()
    _AddAllToSortedItemArray(matchingItems)
EndFunction

; -----------------------------------------------------------------------------
; Remove all items from the container and place them in workshop storage.
; -----------------------------------------------------------------------------
Function MoveItemsToWorkshop()
    Form[] items = GetInventoryItems()
    if items.Length == 1
        Form item = items[0]
        Logger.Warning(self, "Found item with name '"+item.GetName()+"' and ID: "+item.GetFormID())
    endif
    Logger.Info(self, "Moving " + GetItemCount() + " items from sorting container to workshop")
    RemoveAllItems(Workshop)
EndFunction

; -----------------------------------------------------------------------------
; Move all cached items from the workshop to the sorting container.
; -----------------------------------------------------------------------------
; RETURNS:
; A count of items moved
; -----------------------------------------------------------------------------
ItemCount Function MoveItemsFromWorkshop()
    ItemCount moveCount = _MoveAllSortedItemsFrom(Workshop)
    Logger.Info(self, "Moving " + moveCount.total + " items ("+moveCount.unique+" unique types) from workshop to sorting container")
    return moveCount
EndFunction

; -----------------------------------------------------------------------------
; Scan the player inventory for items matching the sorting filters.
; Remove matching items from player inventory and place them in the workshop.
;
; This function ignores favorite and equipped items.
; -----------------------------------------------------------------------------
int Function MovePlayerItemsToWorkshop()
    Filter[] installedFilters = CardReader.GetInstalledFilters()
    Logger.Info(self, "Moving player items to workshop - check for matches")
    Form[] inventory = Player.GetInventoryItems()
    Form[] matchingForms = Matcher.CheckForMatches(inventory, installedFilters, excludeFavorites=true, excludeEquipped=true, enableTrace=CardReader.IsTraceEnabled)
    int i = 0
    while (i < matchingForms.Length)
        Form match = matchingForms[i]
        int itemCount = Player.GetItemCount(match)
        Player.RemoveItem(match, aiCount = itemCount, abSilent = true, akOtherContainer = Workshop)
        i += 1
    endwhile
    return matchingForms.Length
EndFunction

; =============================================================================
; === Private functions =======================================================
; =============================================================================

; -----------------------------------------------------------------------------
; Check whether an item matches the filters installed in the card reader.
; -----------------------------------------------------------------------------
; PARAMS:
; - akBaseItem: an item to check
; RETURNS:
; 'true' on match
; -----------------------------------------------------------------------------
bool Function _CheckForMatch(Form akBaseItem)
    Filter[] installedModules = CardReader.GetInstalledFilters()
    return Matcher.MatchesAnyFilter(akBaseItem, installedModules, enableTrace=CardReader.IsTraceEnabled)
EndFunction

Function _CreateSortedItemArray()
    Logger.Info(self, "Creating sorted item arrays...")
    DS:StringDictFormArray.Create(SortedItemsCacheKey)
EndFunction

Function _ClearSortedItemArray()
    DS:StringDictFormArray.Remove(SortedItemsCacheKey, self)
EndFunction

int Function _GetSortedItemCount()
    int arrayLength = DS:StringDictFormArray.ArrayLength(SortedItemsCacheKey, self)
    if (arrayLength == -1)
        return 0
    else
        return arrayLength
    endif
EndFunction

int Function _GetSortedItemIndex(Form item)
    return DS:StringDictFormArray.IndexOf(SortedItemsCacheKey, self, item, 0)
EndFunction

Form Function _GetSortedItemForIndex(int index)
    DS:StringDictFormArray:Result result = DS:StringDictFormArray.GetElement(SortedItemsCacheKey, self, index)
    if (result.Found)
        return Result.Value
    else
        return None
    endif
EndFunction

Struct ItemCount
    int unique = 0
    int total = 0
EndStruct

; -----------------------------------------------------------------------------
; Iterate over the sorted item array, and move all matching items from the
; target container to this container.
; -----------------------------------------------------------------------------
; PARAMS:
; - target: source container to remove items from
; RETURNS:
; A count of items moved
; -----------------------------------------------------------------------------
ItemCount Function _MoveAllSortedItemsFrom(ObjectReference source)
    ItemCount itemCount = new ItemCount
    int itemsToMove = _GetSortedItemCount()
    int i = 0
    while (i < itemsToMove)
        Form itemToRemove = _GetSortedItemForIndex(i)
        int removeCount = source.GetItemCount(itemToRemove)
        if (removeCount > 0)
            itemCount.unique += 1
            itemCount.total += removeCount
            source.RemoveItem(itemToRemove, removeCount, true, self)
        endif
        i += 1
    endwhile
    return itemCount
EndFunction

; -----------------------------------------------------------------------------
; Add an item to the sorted item array, if it has not already been added.
; -----------------------------------------------------------------------------
; PARAMS:
; - item: form to append
; -----------------------------------------------------------------------------
bool Function _AddToSortedItemArray(Form item)
    string itemName = item.GetName()
    int itemIndex = _GetSortedItemIndex(item)
    if (itemIndex == -1)
        Logger.Info(self, "Appending '"+itemName+"' to sorted item array")
        return DS:StringDictFormArray.AddElement(SortedItemsCacheKey, self, item)
    else
        Logger.Info(self, "Failed to append'"+itemName+"' to sorted item array: item already exists at index "+itemIndex)
        return false
    endif
EndFunction

; -----------------------------------------------------------------------------
; Remove an item from the sorted item array, if it exists in the array.
; -----------------------------------------------------------------------------
; PARAMS:
; - item: form to append
; -----------------------------------------------------------------------------
bool Function _RemoveFromSortedItemArray(Form item)
    string itemName = item.GetName()
    int itemIndex = _GetSortedItemIndex(item)
    if (itemIndex > -1)
        Logger.Info(self, "Removing '"+itemName+"' from sorted item array at index "+itemIndex)
        return DS:StringDictFormArray.RemoveAtIndex(SortedItemsCacheKey, self, itemIndex)
    else
        Logger.Info(self, "Failed to remove'"+itemName+"' from sorted item array: item not found")
        return false
    endif
EndFunction

int Function _AddAllToSortedItemArray(Form[] items)
    int i = 0
    int addCount = 0
    while (i < items.Length)
        if _AddToSortedItemArray(items[i])
            addCount +=1
        endif
        i += 1
    endwhile
    return addCount
EndFunction

int Function _RemoveAllFromSortedItemArray(Form[] items)
    int i = 0
    int removeCount = 0
    while (i < items.Length)
        if _RemoveFromSortedItemArray(items[i])
            removeCount += 1
        endif
        i += 1
    endwhile
    return removeCount
EndFunction
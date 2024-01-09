Scriptname RobcoAutoSort:FilterCardReader extends ObjectReference

import RobcoAutoSort:Types

; =============================================================================
; === Properties  =============================================================
; =============================================================================

Group Sounds
    Sound property CardInvalidSound auto const mandatory
    Sound property CardInstallSound auto const mandatory
    Sound property CardUninstallSound auto const mandatory
EndGroup

Group Messages
    Message property InvalidCardMsg auto const mandatory
EndGroup

Group ExternalScripts
    VersionManager property VersionManager auto const mandatory
    TraceLogger property Logger auto const mandatory
    FilterRegistry property FilterRegistry auto const mandatory
EndGroup

Actor property Player auto hidden
Form[] property InstalledCards auto hidden

bool property IsActive = false auto hidden
bool property IsTraceEnabled = false auto hidden

; =============================================================================
; === Constants  ==============================================================
; =============================================================================

string DEFAULT_DISPLAY_NAME = "Sorted Items" const

; =============================================================================
; === Custom events  ==========================================================
; =============================================================================

CustomEvent OnFiltersChanged

; =============================================================================
; === Initialization  =========================================================
; =============================================================================

Event OnInit()
    Logger.RegisterPrefix(self, "FilterCardReader")
    _InitVariables()
    AddInventoryEventFilter(None)
EndEvent

; =============================================================================
; === Events  =================================================================
; =============================================================================


Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    _TraceItemAdded(akBaseItem, akItemReference)

    bool isTraceEnableCard = FilterRegistry.IsEnableTraceCard(akBaseItem)
    bool isValidFilterCard = FilterRegistry.IsValidFilterCard(akBaseItem)
    if (isValidFilterCard == false && isTraceEnableCard == false)
        Logger.Info(self, "Item is not a valid sorting card - returning to player")
        CardInvalidSound.Play(Player)
        InvalidCardMsg.Show()
        RemoveItem(akBaseItem, aiItemCount, true, akSourceContainer)
        UI.CloseMenu("ContainerMenu")
    else
        Logger.Info(self, "Card is valid - waiting for container menu to close to complete installation.")
        CardInstallSound.Play(Player)
    endif
EndEvent


Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    bool isValidFilterCard = FilterRegistry.IsValidFilterCard(akBaseItem)
    if (isValidFilterCard)
        CardUninstallSound.Play(Player)
    endif
EndEvent

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    if (IsActive && abOpening == false && asMenuName == "ContainerMenu")
        Logger.Info(self, "Container menu closed")
        _ReinstallCards()
    endif
EndEvent

; =============================================================================
; === Public functions  =======================================================
; =============================================================================


Function BindTo(AutoSortActivator binder)
    AttachTo(binder)
    VersionManager.Register(self)
EndFunction

Function DeleteWhenAble()
    Logger.Info(self, "DeleteWhenAble() called")
    _Cleanup()
    parent.DeleteWhenAble()
EndFunction

Function Delete()
    Logger.Info(self, "Delete() called")    
    _Cleanup()
    parent.Delete()
EndFunction

Function _Cleanup()
    VersionManager.Unregister(self)
    RemoveAllItems(akTransferTo=Player)
    Player = None
    UnregisterForAllEvents()
    AttachTo(None)
EndFunction

Filter[] Function GetInstalledFilters()
    Filter[] filters = new Filter[0]
    int i = 0
    while (i < InstalledCards.Length)
        form card = InstalledCards[i]
        Filter installedFilter = FilterRegistry.FilterForCard(card)
        filters.Add(installedFilter)
        i += 1
    endwhile
    return filters
EndFunction


; =============================================================================
; === Private functions  ======================================================
; =============================================================================

Function _InitVariables()
    Player = Game.GetPlayer()
    InstalledCards = new Form[0]
EndFunction

Function _ReinstallCards()
    Logger.Info(self, "Reinstalling cards...")
    string[] oldCardNames = _GetInstalledCardNames()

    InstalledCards.Clear()
    IsTraceEnabled = false

    Form[] items = GetInventoryItems()
    int i = 0
    while i < items.Length
        Form item = items[i]
        if FilterRegistry.IsEnableTraceCard(item)
            IsTraceEnabled = true
        elseif (FilterRegistry.IsValidFilterCard(item))
            int itemCount = GetItemCount(item)
            if (itemCount > 1)
                ; Remove duplicates and add back to player inventory
                int numToRemove = itemCount-1
                Logger.Info(self, "Returning "+numToRemove+" duplicate cards to player inventory")
                RemoveItem(item, aiCount=numToRemove, abSilent=true, akOtherContainer=Player)
            endif
        ; Add the de-duped item to array
        InstalledCards.Add(item)
        Logger.Info(self, "Installed card: "+item.GetName())
        endif
        i += 1
    endwhile

    string[] newCardNames = _GetInstalledCardNames()
    bool filtersChanged = !RobcoAutoSort:Util.ArraysMatch(oldCardNames, newCardNames)
    if (filtersChanged)
        Logger.Info(self, "Filter change detected, sending custom event...")
        SendCustomEvent("OnFiltersChanged")
    endif

EndFunction

string[] Function _GetInstalledCardNames()
    int i = 0
    string[] out = new string[InstalledCards.Length]
    while (i < InstalledCards.Length)
        Form card = InstalledCards[i]
        out.Add(card.GetName())
        i += 1
    endwhile
    return out
EndFunction

Function _TraceItemAdded(Form akBaseItem, ObjectReference akItemReference) DebugOnly
    string itemName
    if (akItemReference == None)
        itemName = akBaseItem.GetName()
    Else
        itemName = RobcoAutoSort:Util.GetItemName(akItemReference)
    endif
    Logger.Info(self, "Item added to sorting card reader: "+itemName)
EndFunction
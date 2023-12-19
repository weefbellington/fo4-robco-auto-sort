Scriptname RobcoAutoSort:FilterCardReader extends ObjectReference

import RobcoAutoSort:FormLoader
import RobcoAutoSort:Types

; =============================================================================
; === Custom events  ==========================================================
; =============================================================================

CustomEvent OnFiltersChanged

; =============================================================================
; === Properties  =============================================================
; =============================================================================

Message Property InvalidCardMsg Auto Hidden

DebugLog Property Log Auto Hidden
SoundBoard Property  SoundBoard Auto Hidden
FilterRegistry Property FilterRegistry Auto Hidden

string DEFAULT_DISPLAY_NAME = "Sorted Items" const

; =============================================================================
; === Variables  ==============================================================
; =============================================================================

Actor Player

Form[] kInstalledFilterCards

string titleForDisplay

bool isActivated = false

; =============================================================================
; === Local event callbacks  ==================================================
; =============================================================================

Event OnInit()
    _InitVariables()
    _InitProperties()
    AddInventoryEventFilter(None)
    _UpdateDisplayName(DEFAULT_DISPLAY_NAME)
    RegisterForMenuOpenCloseEvent("ContainerMenu")
EndEvent

Event OnActivate(ObjectReference akActionRef)
    isActivated = true
EndEvent

Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    string itemName = RobcoAutoSort:Util.GetItemName(akBaseItem, akItemReference)
    Log.Trace("Item added to sorting card reader: "+itemName)

    bool isValidFilterCard = FilterRegistry.IsValidFilterCard(akBaseItem)
    if (isValidFilterCard == false)
        Log.Trace("Item is not a valid sorting card - returning to player")
        SoundBoard.PlayCardReaderInvalidCardSound(Player)
        InvalidCardMsg.Show()
        RemoveItem(akBaseItem, aiItemCount, false, akSourceContainer)
        UI.CloseMenu("ContainerMenu")
    else
        Log.Trace("Card is valid - waiting for container menu to close to complete installation.")
        SoundBoard.PlayCardInstallSound(Player)
    endif
EndEvent

Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    bool isValidFilterCard = FilterRegistry.IsValidFilterCard(akBaseItem)
    if (isValidFilterCard)
        SoundBoard.PlayCardUninstallSound(Player)
    endif
EndEvent

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    if (isActivated && abOpening == false && asMenuName == "ContainerMenu")
        isActivated = false
        Log.Trace("Container menu closed")

        string[] oldCardNames = _GetInstalledCardNames()
        _ReinstallCards()
        string[] newCardNames = _GetInstalledCardNames()

        int installCount = kInstalledFilterCards.Length
        if (installCount == 1)
            Types:Filter filter = FilterRegistry.FilterForCard(kInstalledFilterCards[0])
            Log.Trace("1 card installed, setting container name to '"+filter.DisplayTitle+"'")
            _UpdateDisplayName(filter.DisplayTitle)
        else
            Log.Trace("0 or 1+ cards installed, setting container name to '"+DEFAULT_DISPLAY_NAME+"'")
            _UpdateDisplayName(DEFAULT_DISPLAY_NAME)
        endif

        bool filtersChanged = !RobcoAutoSort:Util.ArraysMatch(oldCardNames, newCardNames)
        if (filtersChanged)
            Log.Trace("Filter change detected, sending custom event...")
            SendCustomEvent("OnFiltersChanged")
        endif
    endif
EndEvent

; =============================================================================
; === Public functions  =======================================================
; =============================================================================

Filter[] Function GetInstalledFilters()
    Filter[] filters = new Filter[0]
    int i = 0
    while (i < kInstalledFilterCards.Length)
        form card = kInstalledFilterCards[i]
        Filter installedFilter = FilterRegistry.FilterForCard(card)
        filters.Add(installedFilter)
        i += 1
    endwhile
    return filters
EndFunction


string Function GetTitleForDisplay()
    return titleForDisplay
EndFunction

Function Destroy()
    UnregisterForAllEvents()
    Delete()
    Log.Trace("OnDestroy() called")
EndFunction

; =============================================================================
; === Private functions  ======================================================
; =============================================================================

Function _InitProperties()  
    Log = LoadDebugLog()
    FilterRegistry = LoadFilterRegistry()
    SoundBoard = LoadSoundBoard()
    InvalidCardMsg = LoadMessage(0x00020DE6)
EndFunction

Function _InitVariables()
    Player = Game.GetPlayer()
    kInstalledFilterCards = new Form[0]
EndFunction

Function _UpdateDisplayName(String title)
    titleForDisplay = title
EndFunction

Function _ReinstallCards()
    Log.Trace("Reinstalling filters...")
    kInstalledFilterCards.Clear()
    Form[] cards = GetInventoryItems()
    int i = 0
    while i < cards.Length
        Form card = cards[i]
        int itemCount = GetItemCount(card)
        if (itemCount > 1)
            ; Remove duplicates and add back to player inventory
            int numToRemove = itemCount-1
            Log.Trace("Returning "+numToRemove+" dupliocates to player inventory")
            RemoveItem(card, aiCount=numToRemove, abSilent=true, akOtherContainer=Player)
        endif
        ; Add the de-duped item to array
        kInstalledFilterCards.Add(card)
        Log.Trace("Installed filter: "+card.GetName())
        i += 1
    endwhile
EndFunction

string[] Function _GetInstalledCardNames()
    int i = 0
    string[] out = new string[kInstalledFilterCards.Length]
    while (i < kInstalledFilterCards.Length)
        Form card = kInstalledFilterCards[i]
        out.Add(card.GetName())
        i += 1
    endwhile
    return out
EndFunction
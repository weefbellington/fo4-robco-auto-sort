Scriptname RobcoMagicStash:SortingChest extends ObjectReference

Group Forms
    Form Property kTempContainer Auto Const Mandatory
    Form Property kModuleContainer Auto Const Mandatory
EndGroup

Group Sound
    Sound Property kProcessingSound Auto Const Mandatory
    Sound Property kStashSound Auto Const Mandatory
    Sound Property kButtonSound Auto Const Mandatory
    Sound Property kOpenSound Auto Const Mandatory
    Sound Property kCloseSound Auto Const Mandatory
EndGroup

Group Quests
    Quest Property DebugQuest Auto Const Mandatory
EndGroup

ObjectReference kWorkshop = None
ObjectReference kWindowContainer = None
SortingModuleContainer kHolotapeContainer = None

bool bIsActivated = false
Actor kPlayer

RobcoSmartStash:DebugLog Log

Event OnInit()
    kPlayer = Game.GetPlayer()
    Log = RobcoSmartStash:DebugLog.Open(DebugQuest)
EndEvent

state Processing
    Event OnActivate(ObjectReference akPlayer)
        kButtonSound.Play(self)
    EndEvent

    Function StashItems(ObjectReference akPlayer)
        kButtonSound.Play(self)
    EndFunction

    Function LoadHolotapes(ObjectReference akPlayer)
        kButtonSound.Play(self)
    EndFunction
endState

Event OnActivate(ObjectReference akPlayer)
    kWindowContainer.GetBaseObject().SetName(kHolotapeContainer.GetTitleForDisplay())
    MoveWorkshopItemsToWindow()
    bIsActivated = true
    kWindowContainer.Activate(akPlayer)
EndEvent

int processingSoundID = -1
Function StartProcessing()
    processingSoundID = kProcessingSound.Play(self)
    GotoState("Processing")
EndFunction

Function EndProcessing()
    Sound.StopInstance(processingSoundID)
    GoToState("")
EndFunction

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    if (bIsActivated && asMenuName == "ContainerMenu")
        if (abOpening == false)
            kCloseSound.Play(kPlayer)
            bIsActivated = false
            MoveWindowItemsToWorkshop()
        else
            kOpenSound.Play(kPlayer)
        endif
    endif
EndEvent

Function StashItems(ObjectReference akPlayer)
    StartProcessing()
    int numItems = MovePlayerItemsToWorkshop(akPlayer)
    EndProcessing()
    if (numItems > 0)
        kStashSound.Play(self)
    else
        kButtonSound.Play(self)
    endIf
EndFunction

Event OnWorkshopObjectPlaced(ObjectReference akWorkshop)
    RegisterForMenuOpenCloseEvent("ContainerMenu")
    kWorkshop = akWorkshop
    kWindowContainer = PlaceAtMe(kTempContainer, abForcePersist = true)
    kHolotapeContainer = PlaceAtMe(kModuleContainer, abForcePersist = true) as SortingModuleContainer
    kWindowContainer.AttachTo(self)
    kHolotapeContainer.AttachTo(self)
EndEvent

Event OnWorkshopObjectDestroyed(ObjectReference akWorkshop)
    MoveHolotapesToWorkshop()
    MoveWindowItemsToWorkshop()
    kWorkshop = None
    kWindowContainer.Delete()
    kHolotapeContainer.Delete()
    kWindowContainer = None
    kHolotapeContainer = None
    Log = None
    UnregisterForAllMenuOpenCloseEvents()
EndEvent

Event ObjectReference.OnItemAdded(ObjectReference akSender, Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    ; reject quest items and send them back to the player
    if (akSourceContainer == kPlayer && akItemReference.IsQuestItem())
        Log.Info("Quest item rejected: " + akItemReference.GetName())
        akSender.RemoveItem(akItemReference, abSilent=true, akOtherContainer=akSourceContainer)
    endif
EndEvent

Function RegisterForWorkshopEvents()
    RegisterForRemoteEvent(kWorkshop, "OnItemAdded")
EndFunction

Function UnregisterForWorkshopEvents()
    UnregisterForRemoteEvent(kWorkshop, "OnItemAdded")
EndFunction

Function MoveHolotapesToWorkshop()
    kHolotapeContainer.RemoveAllItems(kWorkshop)
EndFunction

Function MoveWindowItemsToWorkshop()
    Log.Info("Moving " + kWindowContainer.GetItemCount() + " items from temp container to workshop")
    kWindowContainer.RemoveAllItems(kWorkshop)
EndFunction

int Function MovePlayerItemsToWorkshop(ObjectReference akPlayer)
    RegisterForWorkshopEvents()
    int numItems = MoveMatchingItems(akPlayer, kWorkshop)
    UnregisterForWorkshopEvents()
    return numItems
EndFunction

int Function MoveWorkshopItemsToWindow()
    return MoveMatchingItems(kWorkshop, kWindowContainer)
EndFunction

Function LoadHolotapes(ObjectReference akPlayer)
    kHolotapeContainer.Activate(akPlayer)
EndFunction

int Function MoveMatchingItems(ObjectReference source, ObjectReference target)
    ;Debug.StartScriptProfiling("RobcoMagicStash:SortingModuleContainer")
    Form[] matchingForms = kHolotapeContainer.CheckForMatches(source)
    ;Debug.StopScriptProfiling("RobcoMagicStash:SortingModuleContainer")
    int i = 0
    while (i < matchingForms.Length)
        Form match = matchingForms[i]
        int itemCount = source.GetItemCount(match)
        source.RemoveItem(match, aiCount = itemCount, abSilent = true, akOtherContainer = target)
        i += 1
    endwhile
    return matchingForms.Length
EndFunction
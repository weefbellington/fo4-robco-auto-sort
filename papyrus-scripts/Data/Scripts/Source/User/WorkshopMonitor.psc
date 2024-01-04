Scriptname RobcoAutoSort:WorkshopMonitor extends Quest

; =============================================================================
; === Properties  =============================================================
; =============================================================================

Group CacheKeywords
    Keyword property SubscriptionsCacheKey auto const mandatory
    Keyword property AddBufferCacheKey auto const mandatory
    Keyword property RemoveBufferCacheKey auto const mandatory
EndGroup

Group ExternalScripts
    VersionManager property VersionManager = None auto const
    TraceLogger property Logger auto const mandatory
EndGroup

ObjectReference[] property FlushBuffer auto hidden

; =============================================================================
; === Event definitions  ======================================================
; =============================================================================

CustomEvent OnWorkshopItemsAdded
CustomEvent OnWorkshopItemsRemoved

; =============================================================================
; === Initialization  =========================================================
; =============================================================================

Event OnInit()
    Logger.RegisterPrefix(self, "WorkshopMonitor")
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
    AddInventoryEventFilter(None)
    _InitBuffers()
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
    _CheckForUpdates()
    _InitBuffers()
EndEvent

Function _CheckForUpdates()
    if VersionManager
        VersionManager.Update(self)
    endif
EndFunction

Function _InitBuffers()
    if (FlushBuffer == None)
        FlushBuffer = new ObjectReference[128]
    endif
    Logger.Info(self, "Initializing subscriber array...")
    _InitializeSubscriberArray(SubscriptionsCacheKey)
    Logger.Info(self, "Initializing add buffer...")
    _InitializeBuffer(AddBufferCacheKey)
    Logger.Info(self, "Initializing remove buffer...")
    _InitializeBuffer(RemoveBufferCacheKey)
EndFunction

Function _InitializeSubscriberArray(Keyword cacheKey)
    if (cacheKey == None)
        Logger.Error(self, "Subscriber array: creation error - keyword is None!")
    else
        bool created = DS:StringDictStringArray.Create(CacheKey)
        if (created)
            Logger.Info(self, "Subscriber array: intialized (created)")
        else
            int cacheSize = DS:StringDictStringArray.Size(CacheKey)
            if (cacheSize > -1)
                Logger.Info(self, "Subscriber array: initialized (already created)")
            else
                Logger.Error(self, "Subscriber array: creation error - check DS.log for possible issues.")
            endif
        endif
    endif
EndFunction

Function _InitializeBuffer(Keyword cacheKey)
    if (cacheKey == None)
        Logger.Error(self, "Buffer: creation error - keyword is None!")
    else
        bool created = DS:StringDictFormArray.Create(CacheKey)
        if (created)
            Logger.Info(self, "Buffer: initialized (created)")
        else
            int cacheSize = DS:StringDictFormArray.Size(CacheKey)
            if (cacheSize > -1)
                Logger.Info(self, "Buffer: initialized (already created)")
            else
                Logger.Error(self, "Buffer: creation error - check DS.log for possible issues.")
            endif
        endif
    endif
EndFunction

; =============================================================================
; === Public Functions  =======================================================
; =============================================================================

; -----------------------------------------------------------------------------
; Register a subscriber for OnWorkshopItemsAdded and OnWorkshopItemsRemoved
; events.
; -----------------------------------------------------------------------------
; PARAMS:
; - subscriber: event receiver
; - workshop: workshop to receive events from
; -----------------------------------------------------------------------------
Function RegisterForWorkshopUpdates(ObjectReference subscriber, ObjectReference workshop)
    int oldSubscriberCount = _GetSubscriberCount(workshop)
    if (oldSubscriberCount == 0)
        _RegisterForEvents(workshop)
    endif
    
    subscriber.RegisterForCustomEvent(self, "OnWorkshopItemsAdded")
    subscriber.RegisterForCustomEvent(self, "OnWorkshopItemsRemoved")

    _AddSubscriber(subscriber, workshop)
EndFunction

; -----------------------------------------------------------------------------
; Unregister a subscriber for OnWorkshopItemsAdded and OnWorkshopItemsRemoved
; events.
; -----------------------------------------------------------------------------
; PARAMS:
; - subscriber: event receiver
; - workshop: workshop to receive events from
; -----------------------------------------------------------------------------
Function UnregisterForWorkshopUpdates(ObjectReference subscriber, ObjectReference workshop)
    _RemoveSubscriber(subscriber, workshop)

    subscriber.UnregisterForCustomEvent(self, "OnWorkshopItemsAdded")
    subscriber.UnregisterForCustomEvent(self, "OnWorkshopItemsRemoved")

    int newSubscriberCount = _GetSubscriberCount(workshop)    
    if (newSubscriberCount == 0)
        _UnregisterForEvents(workshop)
    endif
EndFunction

; -----------------------------------------------------------------------------
; Append an item to the 'add' buffer. Also remove it from the 'remove'
; buffer, if it exists.
;
; Buffers are flushed after a short amount of time has passed. Appending to
; the buffer again will restart the timer.
; -----------------------------------------------------------------------------
; PARAMS:
; - workshop: the workshop for this buffer
; - baseObject: base form for added item
; - itemReference: object reference for added item
; - int count: number of items added
; -----------------------------------------------------------------------------
Function AppendToAddBuffer(ObjectReference workshop, Form baseObject, ObjectReference itemReference, int count)
    _WaitForBufferWriteLock(acquire=false)

    _TraceItemAdded(baseObject, itemReference, count)
    _AddToBuffer(AddBufferCacheKey, workshop, baseObject)
    _RemoveFromBuffer(RemoveBufferCacheKey, workshop, baseObject)
    _StartBufferFlushTimer(workshop)
EndFunction

; -----------------------------------------------------------------------------
; Append an item to the 'remove' buffer. Also remove it from the 'add'
; buffer, if it exists.
;
; Buffers are flushed after a short amount of time has passed. Appending to
; the buffer again will restart the timer.
; -----------------------------------------------------------------------------
; PARAMS:
; - workshop: the workshop for this buffer
; - baseObject: base form for added item
; - itemReference: object reference for added item
; - int count: number of items added
; -----------------------------------------------------------------------------
Function AppendToRemoveBuffer(ObjectReference workshop, Form baseObject, ObjectReference itemReference, int count)
    int remainingCount = workshop.GetItemCount(baseObject)
    if (remainingCount > 0)
        return
    endif

    _WaitForBufferWriteLock(acquire=false)

    _TraceItemRemoved(baseObject, itemReference, count)
    _AddToBuffer(RemoveBufferCacheKey, workshop, baseObject)
    _RemoveFromBuffer(AddBufferCacheKey, workshop, baseObject)
    _StartBufferFlushTimer(workshop)
EndFunction

int Function _GetSubscriberCount(ObjectReference workshop)
    int arrayLength = DS:StringDictStringArray.ArrayLength(SubscriptionsCacheKey, workshop)
    if (arrayLength > 0)
        return arrayLength
    else
        return 0
    endif
EndFunction

bool Function _AddSubscriber(ObjectReference subscriber, ObjectReference workshop)
    int firstIndex = DS:StringDictStringArray.IndexOf(SubscriptionsCacheKey, workshop, subscriber, 0)
    if (firstIndex > -1)
        Logger.Warning(self, "Subscriber already added: " + subscriber)
        return false
    else
        return DS:StringDictStringArray.AddElement(SubscriptionsCacheKey, workshop, subscriber)
    endif
EndFunction

bool Function _RemoveSubscriber(ObjectReference subscriber, ObjectReference workshop)
    int firstIndex = DS:StringDictStringArray.IndexOf(SubscriptionsCacheKey, workshop, subscriber, 0)
    if (firstIndex > -1)
        Logger.Warning(self, "Subscriber not found: " + subscriber)
        return false
    else
        return DS:StringDictStringArray.RemoveAtIndex(SubscriptionsCacheKey, workshop, firstIndex)
    endif
EndFunction

Function _RegisterForEvents(ObjectReference workshop)
    RegisterForRemoteEvent(workshop, "OnItemAdded")
    RegisterForRemoteEvent(workshop, "OnItemRemoved")
EndFunction

Function _UnregisterForEvents(ObjectReference workshop)
    UnregisterForRemoteEvent(workshop, "OnItemAdded")
    UnregisterForRemoteEvent(workshop, "OnItemRemoved")
EndFunction

; =============================================================================
; === Events ==================================================================
; =============================================================================

Event ObjectReference.OnItemAdded(ObjectReference akSender, Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    if _IsSortingContainer(akSourceContainer) == false
        AppendToAddBuffer(akSender, akBaseItem, akItemReference, aiItemCount)
    endif
EndEvent

Event ObjectReference.OnItemRemoved(ObjectReference akSender, Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
    if _IsSortingContainer(akDestContainer) == false
        AppendToRemoveBuffer(akSender, akBaseItem, akItemReference, aiItemCount)
    endif
EndEvent

bool Function _IsSortingContainer(ObjectReference target)
    return target is RobcoAutoSort:SortingContainer
EndFunction

; =============================================================================
; === Private functions =======================================================
; =============================================================================

bool Function _AddToBuffer(Keyword bufferID, ObjectReference workshop, Form akBaseItem)
    int itemIndex = DS:StringDictFormArray.IndexOf(bufferID, workshop, akBaseItem, 0)
    if (itemIndex < 0)
        return DS:StringDictFormArray.AddElement(bufferID, workshop, akBaseItem)
    else
        return false
    endIf
EndFunction

bool Function _RemoveFromBuffer(Keyword bufferID, ObjectReference workshop, Form akBaseItem)
    int itemIndex = DS:StringDictFormArray.IndexOf(bufferID, workshop, akBaseItem, 0)
    if (itemIndex > -1)
        return DS:StringDictFormArray.RemoveAtIndex(bufferID, workshop, itemIndex)
    else
        return false
    endif
EndFunction

; -----------------------------------------------------------------------------
; Starts a timer for the given workshop reference.
; When the timer fires, buffers are for this workshop are flushed.
; Calling the function again restarts the timer.
; -----------------------------------------------------------------------------
; PARAMS:
; - workshop: the workshop whose buffers should be flushed
; -----------------------------------------------------------------------------
Function _StartBufferFlushTimer(ObjectReference workshop)
    int index = FlushBuffer.Find(workshop)
    if (index == -1)
        index = FlushBuffer.Find(None)
    endif
    FlushBuffer[index] = workshop
    StartTimer(0.5, index)
EndFunction

bool property BufferWriteLock = false auto hidden

Function _WaitForBufferWriteLock(bool acquire=false)
    while BufferWriteLock
        Utility.Wait(0.05)
    endwhile
    BufferWriteLock = acquire
EndFunction

Function _ReleaseBufferWriteLock()
    BufferWriteLock = false
EndFunction

Event OnTimer(int index)
    ObjectReference workshop = FlushBuffer[index]
    FlushBuffer[index] = None

    _WaitForBufferWriteLock(acquire=true)

    Logger.Info(self, "Draining buffers for workshop: "+workshop)
    _DrainAddBuffer(workshop)
    _DrainRemoveBuffer(workshop)

    _ReleaseBufferWriteLock()
EndEvent

; -----------------------------------------------------------------------------
; Drain the 'add' buffer and send the 'OnWorkshopItemsAdded' event to
; subscribers. The event will fire more than once if the buffer size exceeds
; 128 items.
; -----------------------------------------------------------------------------
; PARAMS:
; - workshop: the workshop associated with this buffer
; -----------------------------------------------------------------------------
Function _DrainAddBuffer(ObjectReference workshop)
    int bufferSize = _GetBufferSize(AddBufferCacheKey, workshop)
    Logger.Info(self, "Draining "+bufferSize+" items from add buffer")
    Form[] output = new Form[0]
    int i = 0
    while (i < bufferSize)
        int remainingCount = bufferSize-i-1
        Form item = DS:StringDictFormArray.GetElement(AddBufferCacheKey, workshop, i).Value
        output.Add(item)
        if (output.Length == 128 || remainingCount == 0)
            SendCustomEvent("OnWorkshopItemsAdded", output as Var[])
            output.Clear()
        endif
        i += 1
    endwhile
    DS:StringDictFormArray.Remove(AddBufferCacheKey, workshop)
EndFunction

; -----------------------------------------------------------------------------
; Drain the 'remove' buffer and send the 'OnWorkshopItemsRemoved' event to
; subscribers. The event will fire more than once if the buffer size exceeds
; 128 items.
; -----------------------------------------------------------------------------
; PARAMS:
; - workshop: the workshop associated with this buffer
; -----------------------------------------------------------------------------
Function _DrainRemoveBuffer(ObjectReference workshop)
    int bufferSize = _GetBufferSize(RemoveBufferCacheKey, workshop)
    Logger.Info(self, "Draining "+bufferSize+" items from remove buffer")
    Form[] output = new Form[0]
    int i = 0
    while (i < bufferSize)
        int remainingCount = bufferSize-i-1
        Form item = DS:StringDictFormArray.GetElement(RemoveBufferCacheKey, workshop, i).Value
        output.Add(item)
        if (output.Length == 128 || remainingCount == 0)
            SendCustomEvent("OnWorkshopItemsRemoved", output as Var[])
            output.Clear()
        endif
        i += 1
    endwhile
    DS:StringDictFormArray.Remove(RemoveBufferCacheKey, workshop)
EndFunction

int Function _GetBufferSize(Keyword bufferID, ObjectReference workshop)
    int arrayLength = DS:StringDictFormArray.ArrayLength(bufferID, workshop)
    if (arrayLength == -1)
        return 0
    else
        return arrayLength
    endif
EndFunction

Function _TraceItemAdded(Form akBaseItem, ObjectReference akItemReference, int aiCount) DebugOnly
    if (akBaseItem == None && akItemReference == None)
        Logger.Error(self, "akBaseItem == None and akItemReference == None. This should never happen!")
    elseif (akBaseItem==None && akItemReference != None)
        Logger.Warning(self, "akBaseItem == None. Code will need to be modified to handle None.")
        Logger.Info(self, "Item "+RobcoAutoSort:Util.GetItemName(akItemReference)+" added to workshop. Count: " + aiCount)
    else
        Logger.Info(self, "Item "+akBaseItem.GetName()+" added to workshop. Count: " + aiCount)
    endif
EndFunction

Function _TraceItemRemoved(Form akBaseItem, ObjectReference akItemReference, int aiCount) DebugOnly
    if (akBaseItem == None && akItemReference == None)
        Logger.Error(self, "akBaseItem == None and akItemReference == None. This should never happen!")
    elseif (akBaseItem==None && akItemReference != None)
        Logger.Warning(self, "akBaseItem == None. Code will need to be modified to handle None.")
        Logger.Info(self, "Item "+RobcoAutoSort:Util.GetItemName(akItemReference)+" removed from workshop. Count: " + aiCount)
    else
        Logger.Info(self, "Item "+akBaseItem.GetName()+" removed from workshop. Count: " + aiCount)
    endif
EndFunction
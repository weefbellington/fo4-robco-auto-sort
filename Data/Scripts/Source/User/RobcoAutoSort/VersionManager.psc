Scriptname RobcoAutoSort:VersionManager extends Quest

import RobcoAutoSort:Types

; =============================================================================
; === Properties  =============================================================
; =============================================================================

Group CacheKeywords
    Keyword property CacheKeyVersionedForms auto const mandatory
    Keyword property CacheKeyVersionedObjects auto const mandatory
    Keyword property CacheKeyFormUpdateBuffer auto const mandatory
    Keyword property CacheKeyObjectUpdateBuffer auto const mandatory
EndGroup

Group Dependencies
    TraceLogger property Logger auto const mandatory
    VersionRegistry property VersionRegistry auto const mandatory
EndGroup

; =============================================================================
; === Events  =================================================================
; =============================================================================

Event OnInit()
    Logger.RegisterPrefix(self, "VersionManager")
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
    _InitCaches()
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
    Logger.RegisterPrefix(self, "VersionManager")
    _InitCaches()
    _CheckForUpdates()
EndEvent

Function _InitCaches()
    DS:FormDictInt.Create(CacheKeyVersionedForms)
    DS:FormDictInt.Create(CacheKeyVersionedObjects)
    DS:FormDictInt.Create(CacheKeyFormUpdateBuffer)
    DS:FormDictInt.Create(CacheKeyObjectUpdateBuffer)
EndFunction

; =============================================================================
; === Public functions ========================================================
; =============================================================================

Function Register(ObjectReference reference)
    ObjectVersionInfo versionInfo = _GetObjectVersionInfo(reference)
    if versionInfo == None
        Logger.Warning(self, "No version registered for ObjectReference: "+reference)
    else
        _AddObjectVersionIfMissing(reference, versionInfo.LatestVersion)
    endif
EndFunction

Function Unregister(ObjectReference reference)
    _RemoveObjectVersion(reference)
EndFunction

int Function CountVersionedForms()
    return _GetCacheSize(CacheKeyVersionedForms)
EndFunction

int Function CountVersionedObjects()
    return _GetCacheSize(CacheKeyVersionedObjects)
EndFunction

int Function _GetCacheSize(Keyword cacheKey)
    int size = DS:FormDictInt.Size(cacheKey)
    if (size < 0)
        return 0
    else
        return size
    endif
EndFunction

Function ForEachKey(Keyword cacheKey, string callbackFn)
    DS:FormDictInt:KeyIterator iterator = DS:FormDictInt.CreateKeyIterator(cacheKey)
    DS:FormDictInt:KeyPointer pointer = DS:FormDictInt.NextKey(iterator)
    bool finished = true
    int count = 1
    while (pointer.Valid)
        Logger.Info(self, "Count: "+count)
        Logger.Info(self, "Value exists: "+(pointer.Value!=None))
        Logger.Info(self, "Finished: "+pointer.Finished)
        Var[] vars = new Var[1]
        vars[0] = pointer.Value
        CallFunction(callbackFn, vars)
        finished = pointer.Finished
        count += 1
        pointer = DS:FormDictInt.NextKey(iterator)
    endwhile

    Logger.Info(self, "Iteration completed, printing last pointer info...")
    Logger.Info(self, "Value exists: "+(pointer.Value!=None))
    Logger.Info(self, "Finished: "+pointer.Finished)
    Logger.Info(self, "Valid: "+pointer.Valid)

    if !finished
        Logger.Warning(self, "Key iterator invalidated before iteration could complete!")
    endif
EndFunction

Function ResetVersionsToDefault()
    _ResetFormVersionsToDefault()
    _ResetObjectVersionsToDefault()
EndFunction

Function _ResetFormVersionsToDefault()
    ForEachKey(CacheKeyVersionedForms, "_ForceFormVersionToDefault")
EndFunction

Function _ResetObjectVersionsToDefault()
    ForEachKey(CacheKeyVersionedObjects, "_ForceObjectVersionToDefault")
EndFunction

Function _ForceFormVersionToDefault(Form target)
    FormVersionInfo versionInfo = _GetFormVersionInfo(target)
    if (versionInfo == None)
        Logger.Warning(self, "No version registered for Form: "+target)
        _SetFormVersion(target, 1, overwrite=true)
    else
        _SetFormVersion(target, versionInfo.LatestVersion, overwrite=true)
    endif
EndFunction

Function _ForceObjectVersionToDefault(Form target)
    ObjectVersionInfo versionInfo = _GetObjectVersionInfo(target)
    if (versionInfo == None)
        Logger.Warning(self, "No version registered for ObjectReference: "+target)
        _SetObjectVersion(target, 1, overwrite=true)
    else
        _SetObjectVersion(target, versionInfo.LatestVersion, overwrite=true)
    endif
EndFunction

; =============================================================================
; === Private functions =======================================================
; =============================================================================

Function _CheckForUpdates()
    _UpdateFormScripts()
    _UpdateObjectReferenceScripts()
    _DrainBuffers()
EndFunction

Function _UpdateFormScripts()
    FormVersionInfo[] formVersions = VersionRegistry.GetFormVersions()
    Logger.Info(self, "Checking for out-of-date Form scripts ("+formVersions.Length+" scripts registered)")
    int i = 0
    while (i < formVersions.Length)
        FormVersionInfo versionInfo = formVersions[i]
        _UpdateFormScript(versionInfo)
        i += 1
    endwhile
    Logger.Info(self, "Finished updating Form scripts")
EndFunction

Function _AddObjectVersionIfMissing(Form target, int latestVersion)
    _SetObjectVersion(target, latestVersion, overwrite=false)
EndFunction

Function _UpdateObjectReferenceScripts()
    int numScripts = CountVersionedObjects()
    Logger.Info(self, "Checking for out-of-date ObjectReference scripts ("+numScripts+" scripts registered)")
    ForEachKey(CacheKeyVersionedObjects, "_UpdateObjectReferenceScript")
    Logger.Info(self, "Finished updating ObjectReference scripts")
EndFunction

FormVersionInfo Function _GetFormVersionInfo(Form target)
    FormVersionInfo[] formVersions = VersionRegistry.GetFormVersions()
    int position = formVersions.FindStruct("Target", target)
    if (position > -1)
        return formVersions[position]
    else
        return None
    endif
EndFunction

ObjectVersionInfo Function _GetObjectVersionInfo(Form target)
    ObjectVersionInfo[] objectVersions = VersionRegistry.GetObjectVersions()
    int i = 0
    while (i < ObjectVersions.Length)
        ObjectVersionInfo versionInfo = objectVersions[i]
        if target.CastAs(versionInfo.TypeSelector)
            return versionInfo
        endif
        i += 1
    endwhile
    return None
EndFunction

Function _UpdateFormScript(FormVersionInfo versionInfo)
    Logger.Info(self, "Running updates for Form script: "+versionInfo.target)
    int currentVersion = _GetFormVersion(versionInfo.target)
    int latestVersion = versionInfo.LatestVersion

    UpdateScript:UpdateResult result = versionInfo.UpdateScript.Update(versionInfo.target, currentVersion, latestVersion)
    
    if (result.AfterVersionNumber > result.BeforeVersionNumber)
            ; To avoid invalidating key iterators, don't update the version number in-place
            ; Instead, buffer the change and perform a batch update later
        _AddToFormBuffer(versionInfo.Target, result.AfterVersionNumber)
    endif

    _DebugOnlyLogUpdateResult(versionInfo.target, result)
EndFunction

Function _UpdateObjectReferenceScript(Form target)
    Logger.Info(self, "Running updates for ObjectReference script: "+target)
    ObjectVersionInfo versionInfo = _GetObjectVersionInfo(target)
    if (versionInfo == None)
        Logger.Warning(self, "No version registered for ObjectReference: "+target)
    else
        int currentVersion = _GetObjectVersion(target)
        int latestVersion = versionInfo.LatestVersion

        UpdateScript:UpdateResult result = versionInfo.UpdateScript.Update(target, currentVersion, latestVersion)

        if (result.AfterVersionNumber > result.BeforeVersionNumber)
            ; To avoid invalidating key iterators, don't update the version number in-place
            ; Instead, buffer the change and perform a batch update later
            _AddToObjectBuffer(target, result.AfterVersionNumber)
        endif

        _DebugOnlyLogUpdateResult(target, result)
    endif
EndFunction

int Function _AddToFormBuffer(Form target, int version)
    DS:FormDictInt.Set(CacheKeyFormUpdateBuffer, target, version)
EndFunction

int Function _AddToObjectBuffer(Form target, int version)
    DS:FormDictInt.Set(CacheKeyObjectUpdateBuffer, target, version)
EndFunction

Function _DrainBuffers()
    ForEachKey(CacheKeyFormUpdateBuffer, "_DrainFormBuffer")
    ForEachKey(CacheKeyObjectUpdateBuffer, "_DrainObjectBuffer")

    DS:FormDictInt.Delete(CacheKeyFormUpdateBuffer)
    DS:FormDictInt.Delete(CacheKeyObjectUpdateBuffer)
    DS:FormDictInt.Create(CacheKeyFormUpdateBuffer)
    DS:FormDictInt.Create(CacheKeyObjectUpdateBuffer)
EndFunction

Function _DrainFormBuffer(Form target)
    Logger.Info(self, "Batch updating form versions...")
    _CopyEntry(CacheKeyFormUpdateBuffer, CacheKeyVersionedForms, target)
EndFunction

Function _DrainObjectBuffer(Form target)
    Logger.Info(self, "Batch updating object versions...")
    _CopyEntry(CacheKeyObjectUpdateBuffer, CacheKeyVersionedObjects, target)
EndFunction

Function _CopyEntry(Keyword source, Keyword destination, Form target)
    DS:FormDictInt:Result result = DS:FormDictInt.Get(source, target)
    if (result.Found)
        DS:FormDictInt.Set(destination, target, result.Value)
    else
        Logger.Warning(self, "Missing key in source dictionary")
    endif
EndFunction

int Function _GetFormVersion(Form target)
    return _GetCurrentVersion(CacheKeyVersionedForms, target)
EndFunction

int Function _GetObjectVersion(Form target)
    return _GetCurrentVersion(CacheKeyVersionedObjects, target)
EndFunction

int Function _GetCurrentVersion(Keyword cacheKey, Form target)
    if (target == None)
        return 1
    endif
    DS:FormDictInt:Result result = DS:FormDictInt.Get(cacheKey, target)
    if (result.Found)
        return result.Value
    else
        return 1
    endif
EndFunction

bool Function _RemoveFormVersion(Form scriptObj)
    return DS:FormDictInt.Remove(CacheKeyVersionedForms, scriptObj)
EndFunction

bool Function _RemoveObjectVersion(Form scriptObj)
    return DS:FormDictInt.Remove(CacheKeyVersionedObjects, scriptObj)
EndFunction

bool Function _RemoveCurrentVersion(Keyword cacheKey, Form scriptObj)
    return DS:FormDictInt.Remove(cacheKey, scriptObj)
EndFunction

Function _SetFormVersion(Form target, int value, bool overwrite)
    _SetCurrentVersion(CacheKeyVersionedForms, target, value, overwrite)
EndFunction

Function _SetObjectVersion(Form target, int value, bool overwrite)
    _SetCurrentVersion(CacheKeyVersionedObjects, target, value, overwrite)
EndFunction

Function _SetCurrentVersion(Keyword cacheKey, Form scriptObj, int value, bool overwrite)
    if (overwrite)
        DS:FormDictInt.Set(cacheKey, scriptObj, value)
    Else
        DS:FormDictInt.Add(cacheKey, scriptObj, value)
    endif
EndFunction

Function _DebugOnlyLogUpdateResult(Form target, UpdateScript:UpdateResult result) DebugOnly
    int updateSuccessCount = result.AfterVersionNumber-result.BeforeVersionNumber
    int updateTotalCount = result.TargetVersionNumber-result.BeforeVersionNumber
    if (result.Failed)
        Logger.Info(self, "Script "+target+": "+updateSuccessCount+"/"+updateTotalCount+" updates completed.")
        Logger.Error(self, "Script "+target+" update failed at (version: "+result.AfterVersionNumber+")")
    elseif (updateTotalCount > 0)
        Logger.Info(self, "Script "+target+": "+updateSuccessCount+"/"+updateTotalCount+" updates completed.")
        Logger.Info(self, "Script "+target+" was updated from (version: "+result.BeforeVersionNumber+") to (version:"+result.AfterVersionNumber+")")
    endif
EndFunction


Scriptname RobcoAutoSort:SortingCache extends Quest

import RobcoAutoSort:FormLoader

; =============================================================================
; === Properties  =============================================================
; =============================================================================

int Property CACHE_HIT_NO_MATCH = -1 AutoReadOnly Hidden
int Property CACHE_MISS = 0 AutoReadOnly Hidden
int Property CACHE_HIT_IS_MATCH = 1 AutoReadOnly Hidden

DebugLog Property Log Auto Hidden
FilterRegistry Property FilterRegistry Auto Hidden

; =============================================================================
; === Local event callbacks  ==================================================
; =============================================================================

Event OnInit()
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
    Log = LoadDebugLog()
    FilterRegistry = LoadFilterRegistry()
    ResetAllCaches()

EndEvent

bool Function Add(Keyword CacheID, int formID, bool isMatch)
    
    return DS:IntDictInt.Add(CacheID, formID, _BoolToCacheInt(isMatch))
EndFunction

int Function Check(Keyword cacheID, int formID)
    return _ResultToCacheInt(DS:IntDictInt.Get(cacheID, formID))
EndFunction

Function DumpInfo(Keyword cacheID)
    DS:IntDictInt:KeyIterator iterator = DS:IntDictInt.CreateKeyIterator(cacheID)

    int matchingKeywordCount = 0
    int nonMatchingKeywordCount = 0
    int matchingFormIDCount = 0
    int nonMatchingFormIDCount = 0

    bool finished = false
    int cacheSize = DS:IntDictInt.Size(cacheID)

    while (cacheSize > 0 && finished == false)
        DS:IntDictInt:Keypointer keyPointer = DS:IntDictInt.NextKey(iterator)

        int formID = keyPointer.Value
        Form formForID = Game.GetForm(formID)
        
        bool isKeyword = formForID as Keyword != None
        bool isMatch = Check(cacheID, formID) == CACHE_HIT_IS_MATCH

        string name
        if (isKeyword)
            name = "KEYWORD " + formID
        else
            name = formForID.GetName()
        endif

        string matchStr
        if isMatch
            matchStr = "MATCH"
        else
            matchStr = "NO MATCH"
        endif

        Log.Trace(name+": " + matchStr)

        if (isKeyword)
            if (isMatch)
                matchingKeywordCount += 1
            else
                nonMatchingKeywordCount += 1
            endif
        else
            if (isMatch)
                matchingFormIDCount += 1
            else
                nonMatchingFormIDCount += 1
            endif
        endif
        finished = keyPointer.Finished
    endwhile

    Log.Info("Keywords: "+matchingKeywordCount+" matches, "+nonMatchingKeywordCount+" non-matches", notification=true)
    Log.Info("Items: "+matchingFormIDCount+" matches, "+nonMatchingFormIDCount+" non-matches", notification=true)
EndFunction

Function DeleteCache(Keyword cacheID)
    Types:Filter filter = FilterRegistry.FilterForCacheID(cacheID)
    Log.Info("Deleting cache: " + filter.DisplayTitle)

    bool deleted = DS:IntDictInt.Create(cacheID)
    DS:IntDictInt.Delete(cacheID)
    if (deleted)
        Log.Info("Delete cache succeeded:" + filter.DisplayTitle)
    else
        Log.Info("Delete cache failed: " + filter.DisplayTitle)
        Log.Error("Check DS.log for possible issues.")
    endif
EndFunction

Function ResetCache(Keyword cacheID)
    Types:Filter filter = FilterRegistry.FilterForCacheID(cacheID)
    Log.Info("ResetCache invoked for cache: "+ filter.DisplayTitle)

    bool cacheExists = DS:IntDictInt.Size(cacheID) > -1
    if (cacheExists)
        DeleteCache(cacheID)
    endif
    CreateCache(cacheID)
    _PrepopulateCache(cacheID)
EndFunction


; -----------------------------------------------------------------------------
; Dict<FormID, Int>
; Values:
;   0: CACHE_MISS
;  -1: CACHE_HIT_NO_MATCH
;   1: CACHE_HIT_IS_MATCH
; -----------------------------------------------------------------------------
Function CreateCache(Keyword cacheID)
    Types:Filter filter = FilterRegistry.FilterForCacheID(cacheID)
    Log.Info("Creating cache: " + filter.DisplayTitle)

    bool created = DS:IntDictInt.Create(cacheID)
    if (created)
        Log.Info("Create cache succeeded:" + filter.DisplayTitle)
    else
        Log.Info("Create cache failed: " + filter.DisplayTitle)
        Log.Error("Check DS.log for possible issues.")
    endif
EndFunction

Function ResetAllCaches()
    Types:Filter[] allFilters = FilterRegistry.GetAllFilters()
    int numCaches = allFilters.Length
    int i = 0
    while (i < numCaches)
        Types:Filter filter = allFilters[i]
        ResetCache(filter.CacheID)
        i += 1
    endwhile
EndFunction


Function _PrepopulateCache(Keyword cacheID)
    Types:Filter filter = FilterRegistry.FilterForCacheID(cacheID)
    Log.Info("Prepopulating cache: "+ filter.DisplayTitle)

    _AddFormListItemsToCache(filter.CacheID, filter.Excludes, isMatch = false)
    _AddFormListItemsToCache(filter.CacheID, filter.Includes, isMatch = true)
EndFunction

Function _AddFormListItemsToCache(Keyword cacheID, FormList flist, bool isMatch)
    if (flist != None)
        _AddFormListID(cacheID, flist, isMatch)
    endif
EndFunction

Function _AddFormListID(Keyword cacheID, FormList flist, bool isMatch)
    _AddFormIDRange(cacheID, RobcoAutoSort:Util.ExtractFormIDs(flist), isMatch)
EndFunction


Function _AddFormIDRange(Keyword cacheID, int[] formIDs, bool isMatch)
    int i = 0
    while (i < formIDs.Length)
        Add(cacheID, formIDs[i], isMatch)
        i += 1
    endwhile
EndFunction

int Function _BoolToCacheInt(bool isMatch)
    if (isMatch)
        return CACHE_HIT_IS_MATCH
    else
        return CACHE_HIT_NO_MATCH
    endif
EndFunction

int Function _ResultToCacheInt(DS:IntDictInt:Result result)
    if (result.Found == true)
        return result.Value
    else
        return CACHE_MISS
    endif
EndFunction
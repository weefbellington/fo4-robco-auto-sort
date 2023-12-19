Scriptname RobcoAutoSort:Matcher extends Quest

import RobcoAutoSort:FormLoader
import RobcoAutoSort:Types

; =============================================================================
; === Properties  =============================================================
; =============================================================================

Form[] Property TrackedObjects Auto Const Mandatory
Keyword Property TrackedObjectsCacheID Auto Const Mandatory
Keyword Property FavoriteSetID Auto Const Mandatory

GlobalVariable Property MatchTracingEnabled Auto Hidden
DebugLog Property Log Auto Hidden
SortingCache Property Cache Auto Hidden

; =============================================================================
; === Local event callbacks  ==================================================
; =============================================================================

Event OnInit()
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
    Log = LoadDebugLog()
    Cache = LoadSortingCache()
    MatchTracingEnabled = LoadGlobalVariable(0x00020DE5)
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
    _InitCaches()
    DS:Debug.LogToConsole(true)
EndEvent

; =============================================================================
; === Structs  ================================================================
; =============================================================================

Struct MatchResult
    bool isMatch = false
    bool isCacheHit = false
    string matchType = "None"
EndStruct

; =============================================================================
; === Public functions  =======================================================
; =============================================================================

Form[] Function CheckContainerForMatches(ObjectReference sourceContainer, Filter[] filters)
    _StartCountingMatches()

    Actor player = Game.GetPlayer()
    bool isPlayerSource = sourceContainer == player
    Form[] inventory = sourceContainer.GetInventoryItems()
    Form[] allMatches = new Form[0]
    int itemIndex = 0

    if (isPlayerSource)
        _PopulateFavoriteItemsCache()
    endif

    while (itemIndex < inventory.Length)
        Form item = inventory[itemIndex]
        Log.Warning("Warning: 'None' item in container inventory at index "+itemIndex, condition = item == None)
        if isPlayerSource && (_IsFavorite(item) || _IsEquipped(player, item))
            ignoredCount += 1
        elseif MatchesAnyFilter(item, filters)
            allMatches.Add(item)
        endif
        itemIndex += 1
    endwhile

    _ClearFavoriteItemsCache()
    _StopCountingMatches()

    return allMatches
EndFunction

bool Function MatchesAnyFilter(Form item, Filter[] filters)
    int filterIndex = 0
    while (filterIndex < filters.Length)
        Filter filter = filters[filterIndex]
        MatchResult result = _MatchesFilter(item, filter)
        _CountMatches(result)
        if (result.isMatch)
            return true
        endif
        filterIndex += 1
    endwhile
    return false
EndFunction

; =============================================================================
; === Private functions  ======================================================
; =============================================================================

bool Function _IsMatchTracingEnabled()
    return MatchTracingEnabled.GetValueInt() == 1
EndFunction

Function _InitCaches()
    _CreateFavoritesCache()
    _PrepopulateTrackedObjectsCache()
EndFunction

Function _CreateFavoritesCache()
    if (DS:IntSet.Create(FavoriteSetID))
        Log.Info("Favorites cache created")
    else
        Log.Info("Favorites cache already created")
    endIf
EndFunction

Function _PrepopulateTrackedObjectsCache()
    if DS:FormSet.Create(TrackedObjectsCacheID)
        Log.Info("Tracked object cache created")
    else
        DS:FormSet.Delete(TrackedObjectsCacheID)
        DS:FormSet.Create(TrackedObjectsCacheID)
        Log.Info("Tracked object cache reset")
    endif
    DS:FormSet.AddRange(TrackedObjectsCacheID, TrackedObjects)
EndFunction


int scanCount = 0
int ignoredCount = 0
int cacheHits = 0
int cacheMisses = 0
int totalMatches = 0
int newMatches = 0

Function _StartCountingMatches()
    scanCount = 0
    ignoredCount = 0
    cacheHits = 0
    cacheMisses = 0
    totalMatches = 0
    newMatches = 0
EndFunction

Function _StopCountingMatches()
    string itemsScannedMsg = scanCount + " total items scanned"
    string ignoredMsg = ignoredCount + " items skipped (favorite or equipped)"
    string cacheHitsMsg = cacheHits + " cache hits, " + cacheMisses + " cache misses"
    string newMatchesMsg = totalMatches + " total matches, " + newMatches + " new matches"

    Log.Info(itemsScannedMsg, notification=true)
    Log.Info(ignoredMsg, notification=true)
    Log.Info(cacheHitsMsg, notification=true)
    Log.Info(newMatchesMsg, notification=true)
EndFunction

Function _CountMatches(MatchResult result)

    scanCount += 1

    if (result.isCacheHit && result.matchType == "formID")
        cacheHits += 1
        if (result.isMatch)
            totalMatches += 1
        endif
    else
        cacheMisses += 1
        if (result.isMatch)
            totalMatches += 1
            newMatches += 1
        endif
    endif

EndFunction


MatchResult Function _MatchesFilter(Form target, Filter filter)

    MatchResult matchResult = new MatchResult

    bool checkCacheForKeywords = false

    Log.Warning("WARNING: CheckCache called with FormList argument!", condition = target is FormList)

    _CheckForFormIDMatch(target, filter.CacheID, matchResult)

    if (matchResult.isCacheHit == false)
        if (_IsTrackedObject(target) || _IsMatchTracingEnabled())
            Log.Trace("Cache miss for form ID on item: " + target.GetName())
            Log.Trace("Checking for keyword matches.")
        endif
        _CheckForKeywordMatch(target, filter.CacheID, matchResult)
    endif

    if (matchResult.isCacheHit == false)
        if (_IsTrackedObject(target) || _IsMatchTracingEnabled())
            Log.Trace("Cache miss for keywords on item: " + target.GetName())
            Log.Trace("Checking for form type matches.")
        endif
        _CheckForTypeMatch(target, filter.FormType, matchResult)
    endif

    ; On cache miss, always add the formID to the cache.
    ; If the cache hit is a 'kywd' type, then add the formID to the cache as well.
    ; This short-circuits the kywd check on the next iteration.
    if (matchResult.IsCacheHit == false || matchResult.matchType == "kywd")
        Log.Trace("Adding formID to cache for item: " + target.GetName(), condition=_IsMatchTracingEnabled())
        bool success = Cache.Add(filter.CacheID, target.GetFormID(), isMatch=matchResult.IsMatch)
        if (!success)
            Log.Error("Add to cache failed! Check DS:Debug for problems.")
        endif
    endif

    _LogResult(target, matchResult)
    
    return matchResult
EndFunction

Function _PopulateFavoriteItemsCache()
    Form[] favorites = FavoritesManager.GetFavorites()
    int i = 0
    while (i < favorites.Length)
        Form item = favorites[i]
        if (item != None)
            DS:IntSet.Add(FavoriteSetID, item.GetFormID())
        endif
        i += 1
    endwhile
EndFunction

Function _ClearFavoriteItemsCache()
    DS:IntSet.Clear(FavoriteSetID)
EndFunction

bool Function _IsFavorite(Form item)
    return DS:IntSet.Contains(FavoriteSetID, item.GetFormID())
EndFunction

bool Function _IsEquipped(Actor target, Form item)
    return target.IsEquipped(item)
EndFunction

bool Function _IsTrackedObject(Form target)
    return DS:FormSet.Contains(TrackedObjectsCacheID, target)
EndFunction

Function _LogResult(Form target, MatchResult result)
    bool shouldLog = _IsTrackedObject(target) || _IsMatchTracingEnabled()
    if (shouldLog)
        Log.Trace("Matching completed for item :" + target.GetName())
        Log.Trace("IS MATCH: " + result.isMatch)
        Log.Trace("IS CACHE HIT: " + result.isCacheHit)
    endif
EndFunction

;------------------------------------------------------------------------------
; Check formID on target against the cache.
;------------------------------------------------------------------------------
Function _CheckForFormIDMatch(Form target, Keyword cacheID, MatchResult matchResult)
    int cacheValue = Cache.Check(cacheID, target.GetFormID())
    if (cacheValue != Cache.CACHE_MISS)
        matchResult.IsCacheHit = true
        matchResult.IsMatch = cacheValue == Cache.CACHE_HIT_IS_MATCH
        matchResult.matchType = "formID"
    endif
EndFunction

;------------------------------------------------------------------------------
; Get all keywords on target and checks them against the cache.
; When there are multiple cache hits:                                         
; - if *any* hits are CACHE_HIT_NO_MATCH, return CACHE_HIT_NO_MATCH
; - if *all* hits are CACHE_HIT_IS_MATCH, return CACHE_HIT_IS_MATCH
;------------------------------------------------------------------------------
; EXAMPLE
; >>> Item is Bourbon. Does it match the 'drink' filter?                      
;
; Filter includes kywd ObjectTypeDrink
; Filter excludes kywd ObjectTypeAlcohol   
;                      
; ObjectTypeDrink -> CACHE_HIT_IS_MATCH
; objectTypeAlcohol -> CACHE_HIT_NO_MATCH
;
; >>> Result: CACHE_HIT_NO_MATCH                                                        
;------------------------------------------------------------------------------
Function _CheckForKeywordMatch(Form target, Keyword cacheID, MatchResult matchResult)
    Keyword[] keywords = target.GetKeywords()
    int i = 0
    int out = Cache.CACHE_MISS
    while (i < keywords.Length)
        Keyword kywd = keywords[i]
        int cacheValue = Cache.Check(cacheID, kywd.GetFormID())
        if cacheValue != Cache.CACHE_MISS
            matchResult.matchType = "kywd"
            if cacheValue == Cache.CACHE_HIT_IS_MATCH
                Log.Trace("MATCH on keyword: " + kywd, condition=_IsMatchTracingEnabled())
                matchResult.isCacheHit = true
                matchResult.isMatch = true
            else
                ; negative match on any keyword short circuits
                Log.Trace("ANTI-MATCH on keyword: " + kywd, condition=_IsMatchTracingEnabled())
                matchResult.isCacheHit = true
                matchResult.isMatch = false
                return
            endif
        endif
    i += 1
    endwhile
EndFunction

;------------------------------------------------------------------------------
; Check whether the item type matches a target value.
;------------------------------------------------------------------------------
Function _CheckForTypeMatch(Form formToMatch, string itemType, MatchResult matchResult)
    bool isMatch = false
    if (itemType == "")
        isMatch = false
    elseif (itemType == "ALCH" && formToMatch is Potion)
        isMatch = true
    elseif (itemType == "ARMO" && formToMatch is Armor)
        isMatch = true
    elseif (itemType == "BOOK" && formToMatch is Book)
        isMatch = true
    elseif (itemType == "CMPO" && formToMatch is Component)
        isMatch = true
    elseif (itemType == "KEYM" && formToMatch is Key)
        isMatch = true
    elseif (itemType == "MISC" && formToMatch is MiscObject)
        isMatch = true
    elseif (itemType == "NOTE" && formToMatch is Holotape)
        isMatch = true
    elseif (itemType == "WEAP" && formToMatch is ObjectMod)
        isMatch = true
    endif
    if (_IsMatchTracingEnabled())
        if (isMatch)
            Log.Trace("MATCH on type " + itemType + " for item:" + formToMatch.GetName())
        else
            Log.Trace("NO MATCH on type " + itemType + " for item:" + formToMatch.GetName())
        endif
    endif
    matchResult.isCacheHit = false
    matchResult.isMatch = isMatch
    matchResult.matchType = "itemType"
EndFunction

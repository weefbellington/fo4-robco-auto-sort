Scriptname RobcoAutoSort:Matcher extends Quest

import RobcoAutoSort:Types

; =============================================================================
; === Properties  =============================================================
; =============================================================================

Group CacheKeywords
    Keyword property FavoriteSetID auto const mandatory
EndGroup

Group GlobalVariables
    GlobalVariable property MatchTracingEnabled auto const mandatory
EndGroup

Group ExternalScripts
    VersionManager property VersionManager = None auto const
    TraceLogger property Logger auto const mandatory
    SortingCache property Cache auto const mandatory
EndGroup

bool property IsMatchTracingEnabled auto hidden

; =============================================================================
; === Constants  ==============================================================
; =============================================================================

string LogFilename = "Robco Auto Sort" Const
string LogPrefix = "[Matcher] " Const

; =============================================================================
; === Structs  ================================================================
; =============================================================================

Struct MatchResult
    bool isMatch = false
    bool isCacheHit = false
    string matchType = "None"
EndStruct

; =============================================================================
; === Initialization  =========================================================
; =============================================================================

Event OnInit()
    Logger.RegisterPrefix(self, "Matcher")
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
    _InitCaches()
    IsMatchTracingEnabled = MatchTracingEnabled.GetValueInt() == 1
    _CheckForUpdates()
EndEvent

Function _CheckForUpdates()
    if VersionManager
        VersionManager.Update(self)
    endif
EndFunction

; =============================================================================
; === Public functions  =======================================================
; =============================================================================

Form[] Function CheckForMatches(Form[] sourceItems, Filter[] filters, bool excludeFavorites=false, bool excludeEquipped=false, bool enableTrace=false)
    Counter counter = new Counter
    Actor player 

    if (excludeEquipped)
        player = Game.GetPlayer()
    endif
    if (excludeFavorites)
        Form[] excludedItems = FavoritesManager.GetFavorites()
        _CacheSkippedItems(excludedItems)
    endif

    Form[] allMatches = new Form[0]
    int itemIndex = 0

    while (itemIndex < sourceItems.Length)
        Form item = sourceItems[itemIndex]
        _TraceInvalidItems(item, itemIndex, enableTrace)
        if _IsSkipped(item)
            counter.ignoredCount += 1
        elseif excludeEquipped && player.IsEquipped(item)
            counter.ignoredCount += 1
        elseif _MatchesAnyFilter(item, filters, enableTrace, counter)
            allMatches.Add(item)
        endif
        itemIndex += 1
    endwhile

    _ClearFavoriteItemsCache()
    _TraceMatchCount(counter, filters, enableTrace)

    return allMatches
EndFunction

bool Function MatchesAnyFilter(Form item, Filter[] filters, bool enableTrace=false)
    bool result = _MatchesAnyFilter(item, filters, enableTrace, counter=None)
    return result
EndFunction

Function _TraceInvalidItems(Form item, int index, bool traceEnabled) DebugOnly
    if (traceEnabled == false)
        return
    endif

    if (item == None)
        Logger.Warning(self, "Warning: 'None' item in container inventory at index "+index, condition = item == None)
    endif
EndFunction

; =============================================================================
; === Private functions  ======================================================
; =============================================================================

Function _InitCaches()
    _CreateFavoritesCache()
EndFunction

Function _CreateFavoritesCache()
    if (DS:IntSet.Create(FavoriteSetID))
        Logger.Info(self, "Favorites cache created")
    else
        Logger.Info(self, "Favorites cache already created")
    endIf
EndFunction


Struct Counter
    int scanCount = 0
    int ignoredCount = 0
    int cacheHits = 0
    int cacheMisses = 0
    int totalMatches = 0
    int newMatches = 0
EndStruct

Function _TraceMatchCount(Counter counter, Filter[] filters, bool traceEnabled) DebugOnly
    if (traceEnabled == false)
        return
    endif

    Logger.Info(self, "Match results for filters:")
    int i = 0
    while (i < filters.Length)
        Filter filter = filters[i]
        Logger.Info(self, "+ " + filter.DisplayTitle)
        i += 1
    endwhile

    string itemsScannedMsg = counter.scanCount + " total items scanned"
    string ignoredMsg = counter.ignoredCount + " items skipped (favorite or equipped)"
    string cacheHitsMsg = counter.cacheHits + " cache hits, " + counter.cacheMisses + " cache misses"
    string newMatchesMsg = counter.totalMatches + " total matches, " + counter.newMatches + " new matches"

    Logger.Info(self, itemsScannedMsg)
    Logger.Info(self, ignoredMsg)
    Logger.Info(self, cacheHitsMsg)
    Logger.Info(self, newMatchesMsg)
EndFunction

Function _UpdateCounter(MatchResult result, Counter counter) DebugOnly
    if (counter == None || result == None)
        return
    endif
    counter.scanCount += 1
    if (result.isCacheHit && result.matchType == "formID")
        counter.cacheHits += 1
        if (result.isMatch)
            counter.totalMatches += 1
        endif
    else
        counter.cacheMisses += 1
        if (result.isMatch)
            counter.totalMatches += 1
            counter.newMatches += 1
        endif
    endif
EndFunction

bool Function _MatchesAnyFilter(Form item, Filter[] filters, bool enableTrace, Counter counter)
    int filterIndex = 0
    MatchResult result = None
    
    while (filterIndex < filters.Length)
        Filter filter = filters[filterIndex]
        result = _MatchesFilter(item, filter, enableTrace)
        if (result.isMatch)
            _UpdateCounter(result, counter)
            return true
        endif
        filterIndex += 1
    endwhile
    
    _UpdateCounter(result, counter)
    return false
EndFunction

MatchResult Function _MatchesFilter(Form target, Filter filter, bool enableTrace)

    MatchResult matchResult = new MatchResult

    if (target is FormList)
        _TraceInvalidFormListArgument(enableTrace)
        return matchResult
    endif

    _TraceMatchAttempt(target, filter, enableTrace)

    _CheckForFormIDMatch(target, filter.CacheID, matchResult)

    if (matchResult.isCacheHit == false)
        _TraceFormIDCacheMiss(target, enableTrace)
        _CheckForKeywordMatch(target, filter.CacheID, matchResult, enableTrace)
    endif

    if (matchResult.isCacheHit == false)
        _TraceKeywordCacheMiss(target, enableTrace)
        _CheckForTypeMatch(target, filter.FormType, matchResult, enableTrace)
    endif

    ; On cache miss, always add the formID to the cache.
    ; If the cache hit is a 'kywd' type, then add the formID to the cache as well.
    ; This short-circuits the kywd check on the next iteration.
    if (matchResult.IsCacheHit == false || matchResult.matchType == "kywd")
        _TraceAddToCache(target, enableTrace)
        bool success = Cache.Add(filter.CacheID, target.GetFormID(), isMatch=matchResult.IsMatch)
        if (!success)
            _TraceAddToCacheFailed(target, enableTrace)
        endif
    endif

    _TraceMatchResult(matchResult, enableTrace)

    return matchResult
EndFunction

Function _TraceMatchAttempt(Form target, Filter filter, bool enableTrace) DebugOnly
    Logger.Info(self, "Checking if item '"+target.GetName()+"' matches filter '"+filter.DisplayTitle+"'", condition=enableTrace && IsMatchTracingEnabled)
EndFunction

Function _TraceInvalidFormListArgument(bool traceEnabled) DebugOnly
    if (traceEnabled == false)
        return
    endif
    Logger.Error(self, "Invalid Argument - _MatchesFilter cannot handle FormList arguments!")
EndFunction

Function _TraceFormIDCacheMiss(Form target, bool traceEnabled) DebugOnly
    if (traceEnabled == false)
        return
    endif
    if (IsMatchTracingEnabled)
        Logger.Info(self, "Cache miss for form ID on item: " + target.GetName())
        Logger.Info(self, "Checking for keyword matches.")
    endif
EndFunction

Function _TraceKeywordCacheMiss(Form target, bool traceEnabled) DebugOnly
    if (traceEnabled == false)
        return
    endif
    if (IsMatchTracingEnabled)
        Logger.Info(self, "Cache miss for keywords on item: " + target.GetName())
        Logger.Info(self, "Checking for form type matches.")
    endif
EndFunction

Function _TraceAddToCache(Form target, bool traceEnabled) DebugOnly
    if (traceEnabled == false)
        return
    endif
    Logger.Info(self, "Adding formID to cache for item: " + target.GetName(), condition=IsMatchTracingEnabled)
EndFunction

Function _TraceAddToCacheFailed(Form target, bool traceEnabled) DebugOnly
    if (traceEnabled == false)
        return
    endif
    Logger.Error(self, "Add to cache failed for item: "+ target.GetName() +"! Check DS:Debug for problems.")
EndFunction


Function _CacheSkippedItems(Form[] itemsToSkip)
    if (itemsToSkip == None)
        return
    endif
    int i = 0
    while (i < itemsToSkip.Length)
        Form item = itemsToSkip[i]
        if (item != None)
            DS:IntSet.Add(FavoriteSetID, item.GetFormID())
        endif
        i += 1
    endwhile
EndFunction

Function _ClearFavoriteItemsCache()
    DS:IntSet.Clear(FavoriteSetID)
EndFunction

bool Function _IsSkipped(Form item)
    return DS:IntSet.Contains(FavoriteSetID, item.GetFormID())
EndFunction

Function _TraceMatchResult(MatchResult result, bool traceEnabled) DebugOnly
    if (traceEnabled == false)
        return
    endif
    if (IsMatchTracingEnabled)
        Logger.Info(self, "IS MATCH: " + result.isMatch)
        Logger.Info(self, "IS CACHE HIT: " + result.isCacheHit)
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
Function _CheckForKeywordMatch(Form target, Keyword cacheID, MatchResult matchResult, bool enableTrace)
    Keyword[] keywords = target.GetKeywords()
    int i = 0
    int out = Cache.CACHE_MISS
    while (i < keywords.Length)
        Keyword kywd = keywords[i]
        int cacheValue = Cache.Check(cacheID, kywd.GetFormID())
        if cacheValue != Cache.CACHE_MISS
            matchResult.matchType = "kywd"
            if cacheValue == Cache.CACHE_HIT_IS_MATCH
                _TraceKeywordMatch(kywd, enableTrace)
                matchResult.isCacheHit = true
                matchResult.isMatch = true
            else
                ; negative match on any keyword short circuits
                _TraceKeywordAntiMatch(kywd, enableTrace)
                matchResult.isCacheHit = true
                matchResult.isMatch = false
                return
            endif
        endif
    i += 1
    endwhile
EndFunction

Function _TraceKeywordMatch(Keyword kywd, bool traceEnabled) DebugOnly
    if (traceEnabled == false)
        return
    endif
    Logger.Info(self, "MATCH on Keyword ID: " + kywd, condition=IsMatchTracingEnabled)
EndFunction

Function _TraceKeywordAntiMatch(Keyword kywd, bool traceEnabled) DebugOnly
    if (traceEnabled == false)
        return
    endif
    Logger.Info(self, "ANTI-MATCH on Keyword ID: " + kywd, condition=IsMatchTracingEnabled)
EndFunction

;------------------------------------------------------------------------------
; Check whether the item type matches a target value.
;------------------------------------------------------------------------------
Function _CheckForTypeMatch(Form target, string itemType, MatchResult matchResult, bool enableTrace)
    bool isMatch = false
    if (itemType == "")
        isMatch = false
    elseif (itemType == "ALCH" && target is Potion)
        isMatch = true
    elseif (itemType == "ARMO" && target is Armor)
        isMatch = true
    elseif (itemType == "BOOK" && target is Book)
        isMatch = true
    elseif (itemType == "CMPO" && target is Component)
        isMatch = true
    elseif (itemType == "KEYM" && target is Key)
        isMatch = true
    elseif (itemType == "MISC" && target is MiscObject)
        isMatch = true
    elseif (itemType == "NOTE" && target is Holotape)
        isMatch = true
    elseif (itemType == "WEAP" && target is ObjectMod)
        isMatch = true
    endif
    _TraceTypeMatchResult(isMatch, itemType, target, enableTrace)
    matchResult.isCacheHit = false
    matchResult.isMatch = isMatch
    matchResult.matchType = "itemType"
EndFunction

Function _TraceTypeMatchResult(bool isMatch, string itemType, Form target, bool traceEnabled) DebugOnly
    if (traceEnabled == false)
        return
    endif
    if (IsMatchTracingEnabled)
        string matchStr
        if (isMatch)
            matchStr = "MATCH"
        else
            matchStr = "NO MATCH"
        endif
        Logger.Info(self, matchStr + " on type " + itemType + " for item:" + target.GetName())
    endif
EndFunction
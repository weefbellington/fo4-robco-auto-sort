Scriptname RobcoMagicStash:SortingModuleContainer extends ObjectReference

Group Sounds
    Sound Property kErrorSound Auto Const Mandatory
    Sound Property kInstallSound Auto Const Mandatory
    Sound Property kUninstallSound Auto Const Mandatory
EndGroup

Group Quests
    Quest Property DebugQuest Auto Const Mandatory
    Quest Property StorageQuest Auto Const Mandatory
EndGroup

Group Other
    Message Property InvalidItemMsg Auto Const Mandatory
    Filter[] Property Filters Auto Const Mandatory
    Keyword Property FavoritesCache Auto Const Mandatory
EndGroup

Actor Player
RobcoSmartStash:Storage Storage
RobcoSmartStash:DebugLog Log

Struct Filter
    Form Module
    FormList Excludes
    FormList Includes
    string FormType
    int NormalizedValueExceeds = -1
    string DisplayTitle
    bool IsEnabled
EndStruct

Struct Range
    int start
    int end
EndStruct

string DISPLAY_NAME_PREFIX
string DEFAULT_TITLE
string titleForDisplay

Event OnInit()
    InitVariables()
    AddInventoryEventFilter(None)
    UpdateDisplayName(DEFAULT_TITLE)
    RegisterForMenuOpenCloseEvent("ContainerMenu")
EndEvent

Function InitVariables()
    Log = RobcoSmartStash:DebugLog.Open(DebugQuest)
    player = Game.GetPlayer()
    DISPLAY_NAME_PREFIX = "Robco Smart Sort - "
    DEFAULT_TITLE = "Filtered Items"
    InitStorage()
    InitCaches()
EndFunction


Function InitStorage()
    DS:IntSet.Create(FavoritesCache)
    Storage = RobcoSmartStash:Storage.Open(StorageQuest)
    if (Storage == None)
        Log.Info("Storage intialization failed (already initialized?)")
    else
        Log.Info("Storage successfully initialized!")
    endif
EndFunction

Function InitCaches()
    int i = 0
    while (i < Filters.Length)
        CreateCaches(Filters[i])
        i += 1
    endwhile
EndFunction

Function CreateCaches(Filter filter)
    Storage.AddAllToExcludesCache(filter.module, FlattenFormList(filter.Excludes))
    Storage.AddAllToIncludesCache(filter.module, FlattenFormList(filter.Includes))
EndFunction


Form[] Function FlattenFormList(FormList flist)
    Form[] out = new Form[0]
    int i = 0
    while (i < flist.GetSize())
        Form lineItem = flist.GetAt(i)
        if (lineItem is FormList)
            AddAll(out, FlattenFormList(lineItem as FormList))
        else
            out.Add(lineItem)
        endif
        i += 1
    endwhile
    return out
EndFunction

Function AddAll(Form[] source, Form[] append)
    int i = 0
    while (i < append.Length)
        source.Add(append[i])
        i += 1
    endwhile
EndFunction

Function DisableAllFilters()
    int i = 0
    while (i < Filters.Length)
        Filter filter = Filters[i]
        filter.IsEnabled = false
        i += 1
    endwhile
EndFunction

int Function GetFilterIndex(Form module)
    return Filters.FindStruct("Module", module)
EndFunction

Filter Function GetFilter(Form module)
    return Filters[GetFilterIndex(module)]
EndFunction

bool Function IsFilterEnabled(Form module)
    return GetFilter(module).IsEnabled
EndFunction

Filter Function GetFirstEnabledFilter()
    int i = 0
    while (i < Filters.Length)
        Filter filter = Filters[i]
        if filter.IsEnabled
            return filter
        endif
        i += 1
    endwhile
    return None
EndFunction

int Function CountEnabledFilters()
    int i = 0
    int count = 0
    while (i < Filters.Length)
        Filter filter = Filters[i]
        if filter.IsEnabled
            count += 1
        endif
        i += 1
    endwhile
    return count
EndFunction

Filter[] Function GetEnabledFilters()
    int i = 0
    Filter[] out = new Filter[0]
    while (i < Filters.Length)
        Filter filter = Filters[i]
        if filter.IsEnabled
            out.Add(filter)
        endif
        i += 1
    endwhile
    return out
EndFunction

Function PopulateFavoriteItemsCache()
    Form[] favorites = FavoritesManager.GetFavorites()
    int i = 0
    while (i < favorites.Length)
        Form item = favorites[i]
        if (item != None)
            DS:IntSet.Add(FavoritesCache, item.GetFormID())
        endif
        i += 1
    endwhile
EndFunction

Function ClearFavoriteItemsCache()
    DS:IntSet.Clear(FavoritesCache)
EndFunction

bool Function IsFavorite(Form item)
    return DS:IntSet.Contains(FavoritesCache, item.GetFormID())
EndFunction

bool Function IsEquipped(Form item)
    return player.IsEquipped(item)
EndFunction


int includeCacheHits = 0
int excludeCacheHits = 0
Function StartCountingCacheHits()
    includeCacheHits = 0
    excludeCacheHits = 0
EndFunction

Form[] Function CheckForMatches(ObjectReference source)
    StartCountingCacheHits()

    bool isPlayerSource = source == player
    Form[] inventory = source.GetInventoryItems()
    Form[] allMatches = new Form[0]
    int itemIndex = 0

    if (isPlayerSource)
        PopulateFavoriteItemsCache()
    endif

    while (itemIndex < inventory.Length)
        Form item = inventory[itemIndex]
        if isPlayerSource && (IsFavorite(item) || IsEquipped(item))
        ; skip if equipped or favorite
        elseif MatchesAnyFilter(item)
            allMatches.Add(item)
        endif
        itemIndex += 1
    endwhile

    ClearFavoriteItemsCache()

    Log.Info("Include cache hits:" + includeCacheHits)
    Log.Info("Exclude cache hits:" + excludeCacheHits)

    return allMatches
EndFunction

bool Function MatchesAnyFilter(Form item)
    Filter[] EnabledFilters = GetEnabledFilters()
    int filterIndex = 0
    while (filterIndex < EnabledFilters.Length)
        Filter selectedFilter = EnabledFilters[filterIndex]
        bool isMatch = MatchesFilter(item, selectedFilter)
        if (isMatch)
            Storage.AddToIncludesCache(selectedFilter.Module, item)
            return true
        else
            Storage.AddToExcludesCache(selectedFilter.Module, item)
            filterIndex += 1
        endif
    endwhile
    return false
EndFunction

bool Function CheckExcludes(Form target, Filter filter)
    bool matchesTarget = Storage.CheckExcludesCache(filter.Module, target)
    if (matchesTarget)
        excludeCacheHits += 1
        return true
    else
        Keyword[] keywords = target.GetKeywords()
        int i = 0
        while (i < keywords.Length)
            Keyword kywd = keywords[i]
            if Storage.CheckExcludesCache(filter.Module, kywd)
                excludeCacheHits += 1
                return true
            endif
        i += 1
        endwhile
    endif
EndFunction

bool Function CheckIncludes(Form target, Filter filter)
    if (Storage.CheckIncludesCache(filter.Module, target))
        includeCacheHits += 1
        return true
    else
        Keyword[] keywords = target.GetKeywords()
        int i = 0
        while (i < keywords.Length)
            Keyword kywd = keywords[i]
            if Storage.CheckIncludesCache(filter.Module, kywd)
                includeCacheHits += 1
                return true
            endif
            i += 1
        endwhile
    endif
EndFunction


bool Function MatchesFilter(Form target, Filter filter)
    if CheckNormalizedValueExceeds(target, filter.NormalizedValueExceeds)
        Log.Info("Matched on value exceeds: " + target.GetName())
        return true
    elseif CheckExcludes(target, filter)
        return false
    elseif CheckIncludes(target, filter) || MatchesType(target, filter.FormType)
        return true
    else
        return false
    endif
EndFunction

bool Function CheckNormalizedValueExceeds(Form item, int limit)
    float limitF = limit
    if (limitF < 0)
        ; Limit unset. Never match on this.
        return false
    endif
    float weight = item.GetWeight()
    float value = item.GetGoldValue()
    if (limitF == 0.0)
        ; Limit 0, weight N/A. Any value above 0 matches.
        Log.Info("Item value is 0: " + item.GetName(), notification = true)
        return value > 0.0
    elseif (weight > 0.0)
        ; Limit > 0, weight > 0. Match if limit > (normalized value)
        Log.Info("Item: " + item.GetName() + ", Weight: " + weight + ", Value: " + value, notification = true)
        return (value / weight) >= limit
    else
        Log.Info("Item weight is 0: " + item.GetName(), notification = true)
        ; Limit > 0, weight == 0. Any value above 0 matches.
        return value > 0.0
    endif
EndFunction

bool Function MatchesType(Form formToMatch, string itemType)
    bool match = false
    if (itemType == "")
        match = false
    elseif (itemType == "ALCH" && formToMatch is Potion)
        match = true
    elseif (itemType == "ARMO" && formToMatch is Armor)
        match = true
    elseif (itemType == "BOOK" && formToMatch is Book)
        match = true
    elseif (itemType == "CMPO" && formToMatch is Component)
        match = true
    elseif (itemType == "KEYM" && formToMatch is Key)
        match = true
    elseif (itemType == "MISC" && formToMatch is MiscObject)
        match = true
    elseif (itemType == "NOTE" && formToMatch is Holotape)
        match = true
    elseif (itemType == "WEAP" && formToMatch is ObjectMod)
        match = true
    endif
    Log.Info("Matched on type: " + formToMatch.GetName(), condition=match)
    return match
EndFunction

Function UpdateDisplayName(String title)
    titleForDisplay = DISPLAY_NAME_PREFIX + title
EndFunction

string Function GetTitleForDisplay()
    return titleForDisplay
EndFunction

Function ShowErrorMessage(string msg)
    Debug.Notification(msg)
    kErrorSound.Play(player)
EndFunction

bool Function IsSortingModule(Form target)
    return Filters.FindStruct("Module", target) > -1
EndFunction

Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    bool isSortingModule = IsSortingModule(akBaseItem)
    if (!isSortingModule)
        InvalidItemMsg.Show()
        RemoveItem(akBaseItem, aiItemCount, false, akSourceContainer)
        UI.CloseMenu("ContainerMenu")
    else
        PlayModuleInstallSound()
    endif
EndEvent

bool installSoundPlaying = false
Function PlayModuleInstallSound()
    installSoundPlaying = false
    kInstallSound.PlayAndWait(player)
    installSoundPlaying = false
EndFunction

Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    bool isSortingModule = IsSortingModule(akBaseItem)
    if (isSortingModule)
        PlayModuleUninstallSound()
    endif
EndEvent

bool uninstallSoundPlaying = false
Function PlayModuleUninstallSound()
    uninstallSoundPlaying = false
    kUninstallSound.PlayAndWait(player)
    uninstallSoundPlaying = false
EndFunction

bool isActivated = false
Event OnActivate(ObjectReference akPlayer)
    isActivated = true
EndEvent

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    if (isActivated && abOpening == false && asMenuName == "ContainerMenu")
        isActivated = false
        DisableAllFilters()
        int i = 0
        while i < Filters.Length
            Form module = Filters[i].Module
            int itemCount = GetItemCount(module)
            if (itemCount > 0)
                RemoveItem(module, aiCount=itemCount-1, abSilent=true, akOtherContainer=player)
                InstallModule(module)
            endif
            i += 1
        endwhile
        int enabledFilters = CountEnabledFilters()
        if (enabledFilters == 1)
            Filter filter = GetFirstEnabledFilter()
            UpdateDisplayName(filter.DisplayTitle)
        else
            UpdateDisplayName(DEFAULT_TITLE)
        endif
    endif
EndEvent

bool Function InstallModule(Form module)
    Filter filter = GetFilter(module)
    if filter.IsEnabled
        return false
    else
        Log.Info("Installing module: " + module.GetName() + ", ID: " + module.GetFormID())
        filter.IsEnabled = true
        return true
    endif
EndFunction
Scriptname RobcoSmartSort:Storage extends Quest

FormList Property FormListCacheIDs Auto Const Mandatory
FormList Property SortingModules Auto Const Mandatory

Struct Cache
    Form module
	Keyword Excludes
	Keyword Includes
EndStruct

Cache[] Caches

int iStage_Started = 1 Const
int iStage_StartupComplete = 2 Const
int iTimerID_QuestStartupComplete = 100 Const

Event OnStageSet(Int auiStageID, Int auiItemID)
	if(auiStageID == iStage_Started)
		if(IsRunning())
			TriggerInitialStartup()
		else
			StartTimer(2.0, iTimerID_QuestStartupComplete)
		endif
	endif
EndEvent

Event OnTimer(Int aiTimerID)
	if(aiTimerID == iTimerID_QuestStartupComplete)
		if(IsRunning())
			TriggerInitialStartup()
		else
			StartTimer(2.0, iTimerID_QuestStartupComplete)
		endif
	endif
EndEvent


Function TriggerInitialStartup()
    InitCaches()
	SetStage(iStage_StartupComplete)
EndFunction

Function InitCaches()
	Keyword[] cacheIDs = ExtractCacheIDs(FormListCacheIDs)
    Debug.Notification("Got " + cacheIDs.Length + "Cache IDs")
    Caches = CreateCaches(cacheIDs)
EndFunction

Storage Function Open(Quest storageQuest) global
    bool started = storageQuest.IsRunning() || storageQuest.IsStarting() || storageQuest.Start()
    if (started)
        return storageQuest as Storage
    else
        return None
    endif
EndFunction


Cache[] Function CreateCaches(Keyword[] cacheIDs)
    int numCaches = SortingModules.GetSize()
    Cache[] out = new Cache[numCaches]
    int i = 0
    int j = 0
    while (i < numCaches)
        Form module = SortingModules.GetAt(i)
        out[i] = CreateCache(module, cacheIDs, j, j+1)
        i += 1
        j += 2
    endwhile
    return out
EndFunction

Keyword[] Function ExtractCacheIDs(FormList idList)
	int size = idList.GetSize()
	Keyword[] out = new Keyword[size]
	int i = 0
	while (i < size)
		Keyword cacheID = idList.GetAt(i) as Keyword
		out[i] = cacheID
		i += 1
	endwhile
	return out
EndFunction

Cache Function CreateCache(Form module, Keyword[] cacheIDs, int excludesIndex, int includesIndex)
	Cache cache = new Cache
    cache.module = module
	cache.Excludes = cacheIDs[excludesIndex]
	Cache.Includes = cacheIDs[includesIndex]

    bool createdExcludes = DS:IntSet.Create(cache.Excludes)
    bool createdIncludes = DS:IntSet.Create(cache.Includes)

    if (createdIncludes && createdExcludes)
        Debug.Notification("Excludes cache creation success. Size: " + DS:IntSet.Size(cache.Excludes))
        Debug.Notification("Includes cache creation success. Size: " + DS:IntSet.Size(cache.Includes))
    else
        Debug.Notification("Cache creation failure")
    endif

	return cache
EndFunction

Cache Function CacheForModule(Form module)
    int index = Caches.FindStruct("module", module)
    if (index < 0)
        Debug.Notification("WARNING: cache not found for module: " + module.GetName())
    endif
    return Caches[index]
EndFunction

bool Function CheckExcludesCache(Form module, Form item)
    Cache cache = CacheForModule(module)
    return DS:IntSet.Contains(cache.Excludes, item.GetFormID())
EndFunction

bool Function CheckIncludesCache(Form module, Form item)
    Cache cache = CacheForModule(module)
    return DS:IntSet.Contains(cache.Includes, item.GetFormID())
EndFunction

bool Function AddToExcludesCache(Form module, Form item)
    Cache cache = CacheForModule(module)
    return DS:IntSet.Add(cache.Excludes, item.GetFormID())
EndFunction

bool Function AddToIncludesCache(Form module, Form item)
    Cache cache = CacheForModule(module)
    return DS:IntSet.Add(cache.Includes, item.GetFormID())
EndFunction

Function AddAllToExcludesCache(Form module, Form[] items)
    Cache cache = CacheForModule(module)
    AddAllFormIDs(cache.Excludes, items)
EndFunction


Function AddAllToIncludesCache(Form module, Form[] items)
    Cache cache = CacheForModule(module)
    AddAllFormIDs(cache.Includes, items)
EndFunction

Function AddAllFormIDs(Keyword cacheKey, Form[] items)
    int i = 0
    while (i < items.Length)
        Form item = items[i]
        DS:IntSet.Add(cacheKey, item.GetFormID())
        i += 1
    endwhile
EndFunction
Scriptname RobcoAutoSort:FilterRegistry extends Quest

import RobcoAutoSort:FormLoader

; =============================================================================
; === Properties  =============================================================
; =============================================================================

Types:Filter[] Property Filters Auto Const Mandatory

DebugLog Property Log Auto Hidden

; =============================================================================
; === Local event callbacks  ==================================================
; =============================================================================

Event OnInit()
    Log = LoadDebugLog()
EndEvent

; =============================================================================
; === Public functions  =======================================================
; =============================================================================

int Function GetFilterIndexForCard(Form target)
    return Filters.FindStruct("FilterCard", target)
EndFunction

int Function _GetFilterIndexForCacheID(Keyword cacheID)
    return Filters.FindStruct("CacheID", cacheID)
EndFunction

bool Function IsValidFilterCard(Form target)
    return GetFilterIndexForCard(target) > -1
EndFunction

Types:Filter Function FilterForCacheID(Keyword cacheID)
    int index = _GetFilterIndexForCacheID(cacheID)
    if (index < 0)
        Log.Warning("WARNING: no filter found for cacheID: " + cacheID, notification = true)
        return None
    else
        return Filters[index]
    endif
EndFunction

Types:Filter Function FilterForCard(Form target)
    int index = GetFilterIndexForCard(target)
    if (index < 0)
        Log.Warning("WARNING: no filter found for card: " + target.GetName(), notification = true)
        return None
    else
        return Filters[index]
    endif
EndFunction

Types:Filter[] Function GetAllFilters()
    return Filters
EndFunction

; =============================================================================
; === List of current filters
; =============================================================================
; AlcoholModule
; -- Includes: AlcoholKeywords
; -- DisplayTitle: Alcohol
; -----------------------------------------------------------------------------
; AmmoModule
; -- Includes: AmmoIncludes
; -- DisplayTitle: Ammo
; -----------------------------------------------------------------------------
; ArmorModule
; -- Includes: ArmorKeywords
; -- DisplayTitle: Armor
; -----------------------------------------------------------------------------
; BooksModule
; -- FormType: BOOK
; -- DisplayTitle: Books
; -----------------------------------------------------------------------------
; ChemsModule
; -- Includes: ChemsKeywords
; -- DisplayTitle: Addictive Chems
; -----------------------------------------------------------------------------
; ClothingModule
; -- Excludes: ClothingExcludes
; -- FormType: ARMO
; -- DisplayTitle: Clothing
; -----------------------------------------------------------------------------
; DrinksModule
; -- Excludes: AlcoholKeywords
; -- Includes: DrinkKeywords
; -- DisplayTitle: Drinks (Non-Alcoholic)
; -----------------------------------------------------------------------------
; FoodModule
; -- Includes: FoodKeywords
; -- DisplayTitle: Food
; -----------------------------------------------------------------------------
; HolotapesModule
; -- FormType: NOTE
; -- DisplayTitle: Books
; -----------------------------------------------------------------------------
; KeysModule
; -- FormType: KEYM
; -- DisplayTitle: Keys
; -----------------------------------------------------------------------------
; LooseModsModule
; -- Includes: LooseModsKeywords
; -- DisplayTitle: Loose Mods
; -----------------------------------------------------------------------------
; MedicineModule
; -- Includes: MedicineList
; -- DisplayTitle: Medicine
; -----------------------------------------------------------------------------
; MiscModule
; -- Excludes: MiscExcludeList
; -- FormType: MISC
; -- DisplayTitle: Miscellaneous Objects
; -----------------------------------------------------------------------------
; PowerArmorModule
; -- Excludes: PowerArmorExcludes
; -- Includes: PowerArmorIncludes
; -- DisplayTitle: Power Armor
; -----------------------------------------------------------------------------
; ScrapModule
; -- Includes: ScrapList
; -- DisplayTitle: Scrap
; -----------------------------------------------------------------------------
; WeaponsModule
; -- Includes: WeaponsKeywords
; -- DisplayTitle: Weapons


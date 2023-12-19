Scriptname RobcoAutoSort:FormLoader

; =============================================================================
; === Global functions  =======================================================
; =============================================================================

String Function PluginFile() global
    return "Robco Auto Sort.esp"
EndFunction

Form Function LoadPluginForm(int aiFormID) global
    string filename = PluginFile()
    Form value = Game.GetFormFromFile(aiFormID, PluginFile())
    if (value == None)
        DebugLog Log = LoadDebugLog()
        Log.Error("ERROR: form ID +"+aiFormID+" could not be loaded from file: "+filename)
    endif
    return value
EndFunction

GlobalVariable Function LoadGlobalVariable(int aiFormId) global
    return LoadPluginForm(aiFormId) as GlobalVariable
EndFunction

Message Function LoadMessage(int aiFormID) global
    return LoadPluginForm(aiFormId) as Message
EndFunction

FormList Function LoadAllCacheKeys() global
    return LoadPluginForm(0x0001E03F) as FormList
EndFunction

Form Function LoadCardReader() global
    return LoadPluginForm(0x000044DE)
EndFunction

DebugLog Function LoadDebugLog() global
    return LoadPluginForm(0x00006B71) as DebugLog
EndFunction

FilterRegistry Function LoadFilterRegistry() global
    return LoadPluginForm(0x000138A3) as FilterRegistry
EndFunction

Terminal Function LoadHelpTerminal() global
    return LoadPluginForm(0x0001EF73) as Terminal
EndFunction

Matcher Function LoadMatcher() global
    return LoadPluginForm(0x00003D88) as Matcher
EndFunction

SortingCache Function LoadSortingCache() global
    return LoadPluginForm(0x0001A31A) as SortingCache
EndFunction

Form Function LoadSortingContainer() global
    return LoadPluginForm(0x00002E06)
EndFunction

SoundBoard Function LoadSoundBoard() global
    return LoadPluginForm(0x000138B4) as SoundBoard
EndFunction
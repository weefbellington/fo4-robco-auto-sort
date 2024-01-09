Scriptname RobcoAutoSort:TraceLogger extends Quest

; =============================================================================
; === Properties  =============================================================
; =============================================================================

Group Filenames
    string property LogFilename = "Robco Auto Sort" auto const
EndGroup

Group CacheKeywords
    Keyword property LogPrefixCacheKey auto const mandatory
EndGroup

; =============================================================================
; === Initialization  =========================================================
; =============================================================================

Event OnInit()
    DS:StringDictString.Create(LogPrefixCacheKey)
EndEvent

; =============================================================================
; === Public Functions  =======================================================
; =============================================================================

Function RegisterPrefix(ScriptObject caller, String prefix)
    DS:StringDictString.Create(LogPrefixCacheKey)
    DS:StringDictString.Set(LogPrefixCacheKey, caller, prefix)
EndFunction

Function Info(ScriptObject caller, string msg, bool condition=true, bool notification=false) DebugOnly
    _Trace(caller, msg, condition, notification, 0)
EndFunction

Function Warning(ScriptObject caller, string msg, bool condition=true, bool notification=false) DebugOnly
    _Trace(caller, msg, condition, notification, 1)
EndFunction

Function Error(ScriptObject caller, string msg, bool condition=true, bool notification=false) DebugOnly
    _Trace(caller, msg, condition, notification, 2)
EndFunction

; =============================================================================
; === Private Functions  ======================================================
; =============================================================================

string Function _GetPrefix(ScriptObject caller, int severity)
    return _GetCallerPrefix(caller)+_GetSeverityPrefix(severity)
EndFunction

string Function _GetCallerPrefix(ScriptObject caller)
    if (caller == None)
        return ""
    endif
    DS:StringDictString:Result result = DS:StringDictString.Get(LogPrefixCacheKey, caller)
    if result.Found
        return "["+result.Value+"] "
    else
        return caller+" "
    endif
EndFunction

string Function _GetSeverityPrefix(int severity)
    if (severity == 0)
        return ""
    elseif (severity == 1)
        return "[WARNING] "
    elseif (severity == 2)
        return "[ERROR] "
    else
        return ""
    endif
EndFunction

Function _Trace(ScriptObject caller, string msg, bool condition, bool notification, int severity) DebugOnly
    Debug.OpenUserLog(LogFilename)
    if notification && condition
        Debug.Notification(msg)
        Debug.TraceUser(LogFilename, _GetPrefix(caller, severity)+msg, severity)
    elseif condition
        Debug.TraceUser(LogFilename, _GetPrefix(caller, severity)+msg, severity)
    endif
EndFunction
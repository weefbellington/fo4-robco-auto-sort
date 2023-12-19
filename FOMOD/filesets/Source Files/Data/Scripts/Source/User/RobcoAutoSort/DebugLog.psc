Scriptname RobcoAutoSort:DebugLog extends Quest

; =============================================================================
; === Properties  =============================================================
; =============================================================================

GlobalVariable Property DebugFlag Auto Const

; =============================================================================
; === Constants  ==============================================================
; =============================================================================

string UserFilename = "RobcoSmartSort"

; =============================================================================
; === Local event callbacks
; =============================================================================

Event OnInit()
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
    _InitLogging()
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
    _InitLogging()
EndEvent

; =============================================================================
; === Public functions  =======================================================
; =============================================================================

bool Function IsDebugEnabled()
    return DebugFlag.GetValueInt() == 1
EndFunction

Function CloseUserLog()
    Debug.CloseUserLog(UserFilename)
EndFunction

Function Info(string msg, bool condition=true, bool notification=false)
    Trace(msg, condition, notification, 0)
EndFunction

Function Warning(string msg, bool condition=true, bool notification=false)
    Trace(msg, condition, notification, 1)
EndFunction

Function Error(string msg, bool condition=true, bool notification=false)
    Trace(msg, condition, notification, 2)
EndFunction

bool Function Trace(string msg, bool condition=true, bool notification=false, int severity=0)
    if !IsDebugEnabled()
        return false
    elseif notification && condition
        Debug.Notification(msg)

        return Debug.TraceUser(UserFilename, msg, severity)
    elseif condition
        return Debug.TraceUser(UserFilename, msg, severity)
    endif
EndFunction

; =============================================================================
; === Private functions  ======================================================
; =============================================================================

Function _InitLogging() DebugOnly
    if (IsDebugEnabled())
        Debug.OpenUserLog(UserFilename)
        DS:Debug.LogToConsole(true)
        DS:Debug.SetLogLevel(4)
    Else
        DS:Debug.LogToConsole(false)
    endif
EndFunction
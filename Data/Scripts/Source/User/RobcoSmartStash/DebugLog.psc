Scriptname RobcoSmartStash:DebugLog extends Quest

GlobalVariable Property DebugFlag Auto Const

String UserFilename = "RobcoSmartSort"

RobcoSmartStash:DebugLog Function Open(Quest debugQuest) global
    return debugQuest as DebugLog
EndFunction

bool Function IsDebugEnabled()
    return DebugFlag.GetValueInt() == 1
EndFunction

Function StopLogging()
    Debug.CloseUserLog(UserFilename)
EndFunction

Function Info(string msg, bool condition=true, bool notification=false)
    Trace(msg, notification, condition, 0)
EndFunction

Function Warning(string msg, bool condition=true, bool notification=false)
    Trace(msg, notification, condition, 1)
EndFunction

Function Error(string msg, bool condition=true, bool notification=false)
    Trace(msg, notification, condition, 2)
EndFunction

bool Function Trace(string msg, bool condition=true, bool notification=false, int severity=0)
    bool isSuccess = Debug.OpenUserLog(UserFilename)
    Debug.Notification("Open user log: " + isSuccess)
    if !IsDebugEnabled()
        return false
    elseif notification && condition
        Debug.Notification(msg)
        return Debug.TraceUser(UserFilename, msg, severity)
    elseif condition
        return Debug.TraceUser(UserFilename, msg, severity)
    endif
EndFunction
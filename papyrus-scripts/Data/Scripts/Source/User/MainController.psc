Scriptname RobcoAutoSort:MainController extends Quest

; =============================================================================
; === Properties  =============================================================
; =============================================================================

int property CurrentScriptVersion = 1 auto hidden

Group Perks
    Perk[] property AddPerks auto const mandatory
EndGroup

Group GlobalVariables
    GlobalVariable property DebugEnabled auto const mandatory
EndGroup

Group ExternalScripts
    VersionManager property VersionManager = None auto const
    TraceLogger property Logger auto const mandatory
EndGroup

Actor property Player auto hidden

; =============================================================================
; === Initialization  =========================================================
; =============================================================================

Event OnInit()
    Logger.RegisterPrefix(self, "MainController")
    Player = Game.GetPlayer()
	_AddPerks()
    RegisterForRemoteEvent(Player, "OnPlayerLoadGame")
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
    _InitLogging()
    _CheckForUpdates()
EndEvent

Function _CheckForUpdates()
    if VersionManager
        VersionManager.Update(self)
    endif
EndFunction

; =============================================================================
; === Private functions  ======================================================
; =============================================================================

Function _UpdateDebugFlag()
    DebugEnabled.SetValueInt(0)
    _TryEnableDebugFlag()
EndFunction

Function _TryEnableDebugFlag() DebugOnly
    DebugEnabled.SetValueInt(1)
EndFunction

Function _InitLogging()
    DS:Debug.LogToConsole(false)
    DS:Debug.SetLogLevel(0)
    _UpdateLogLevelForDebug()
EndFunction

Function _UpdateLogLevelForDebug() DebugOnly
    DS:Debug.LogToConsole(true)
    DS:Debug.SetLogLevel(2)
EndFunction

Function _AddPerks()
    int i = 0
    while (i < AddPerks.Length)
        Perk perkToAdd = AddPerks[i]
        if Player.HasPerk(perkToAdd)
            Player.RemovePerk(perkToAdd)
        endif
        Logger.Info(self, "Adding perk to player:" + perkToAdd.GetName())
        Player.AddPerk(perkToAdd)
        i += 1
    endwhile
EndFunction
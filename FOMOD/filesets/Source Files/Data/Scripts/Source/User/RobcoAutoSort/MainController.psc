Scriptname RobcoAutoSort:MainController extends Quest

import RobcoAutoSort:FormLoader

; =============================================================================
; === Properties  =============================================================
; =============================================================================

FormList[] Property AddItems Auto Const Mandatory
Perk[] Property AddPerks Auto Const Mandatory

DebugLog Property Log Auto Hidden

; =============================================================================
; === Variables  ==============================================================
; =============================================================================

Actor Player

; =============================================================================
; === Local event callbacks  ==================================================
; =============================================================================

Event OnInit()
	Log = LoadDebugLog()

    Player = Game.GetPlayer()

	_AddItemsFromLists(AddItems)
	_AddPerks()
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
    _AddPerks()
EndEvent

; =============================================================================
; === Private functions  ======================================================
; =============================================================================

Function _AddItemsFromLists(FormList[] lists)
	int i = 0
	while (i < lists.Length)
		FormList items = lists[i]
		_AddItems(items)
		i += 1
	endwhile
EndFunction

Function _AddItems(FormList items)
    int i = 0
    while (i < items.GetSize())
        Form item = items.GetAt(i)
        Log.Info("RobcoSmartStash:MainController quest started")
        Player.AddItem(item, 100, abSilent=true)
        i += 1
    endwhile
EndFunction


Function _AddPerks()
    int i = 0
    while (i < AddPerks.Length)
        Perk perkToAdd = AddPerks[i]
        if Player.HasPerk(perkToAdd)
            Player.RemovePerk(perkToAdd)
        endif
        Log.Info("Adding perk:" + perkToAdd.GetName())
        Player.AddPerk(perkToAdd)
        i += 1
    endwhile
EndFunction


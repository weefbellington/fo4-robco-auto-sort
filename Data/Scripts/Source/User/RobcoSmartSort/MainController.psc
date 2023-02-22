Scriptname RobcoSmartSort:MainController extends Quest

FormList[] Property AddItems Auto Const Mandatory
Perk[] Property AddPerks Auto Const Mandatory 
Actor Property Player Auto Const Mandatory
Quest Property DebugQuest Auto Const Mandatory

int iStage_Started = 1 Const
int iStage_StartupComplete = 2 Const
int iTimerID_QuestStartupComplete = 100 Const

DebugLog Log

Event OnInit()
	Log = RobcoSmartSort:DebugLog.Open(DebugQuest)
EndEvent

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
    AddInitialItemsFromLists(AddItems)
	AddInitialPerks(AddPerks)
	SetStage(iStage_StartupComplete)
EndFunction

Function AddInitialItemsFromLists(FormList[] lists)
	int i = 0
	while (i < lists.Length)
		FormList items = lists[i]
		AddInitialItems(items)
		i += 1
	endwhile
EndFunction

Function AddInitialItems(FormList items)
    int i = 0
    while (i < items.GetSize())
        Form item = items.GetAt(i)
        Log.Info("RobcoSmartStash:MainController quest started")
        Player.AddItem(item, 100, abSilent=true)
        i += 1
    endwhile
EndFunction


Function AddInitialPerks(Perk[] perks)
    int i = 0
    while (i < perks.Length)
        Perk perkItem = perks[i]
        Log.Info("Adding perk:" + perkItem.GetName())
        Player.AddPerk(perkItem)
        i += 1
    endwhile
EndFunction


unit RobcoSmartSort_ConvertContainersToActivators;

interface
uses  xEditAPI, xEditExtensions, Classes, SysUtils, StrUtils, Windows, ScriptUtilities;

implementation

var FalloutESM, PluginESP, TargetESP: IInterface;
var ActivatorGRUP, ConstructableGRUP: IInterface;
var ActivatorKYWD, WorkshopScrapFilterKYWD: IInterface;
var ButtonSNDR, SortSNDR, ProcessingSNDR: string;
var TempCONT, ModuleCONT: string;
var DebugQUST: string;

const
  FALLOUT_4_ESM_NAME = 'Fallout4.esm';
  PLUGIN_ESP_NAME = 'Robco Smart Stash.esp';
  TARGET_ESP_NAME = 'Robco Smart Sort - Base Game Containers.esp';
const
  PLUGIN_EDID_PREFIX = 'robco_smart_sort_';
  ACTI_EDID_FORMAT = PLUGIN_EDID_PREFIX + 'Activator_%s';
  COBJ_EDID_FORMAT = PLUGIN_EDID_PREFIX+ 'co_%s';
  FLST_EDID_FORMAT = PLUGIN_EDID_PREFIX + '%s';
const
  KYWD_WORKSHOP_SCRAP_FILTER = 'WorkshopRecipeFilterScrap';
  KYWD_PLUGIN_ACTI = PLUGIN_EDID_PREFIX + 'ActivatorKeyword';
const
  SNDR_BUTTON = 'OBJLoadElevatorUtilityButtonPanel';
  SNDR_SORT = 'DRSMetalMissileHatchOpen';
  SNDR_PROCESSING = 'OBJTeleporterJammerLP';
const
  CONT_TEMP = PLUGIN_EDID_PREFIX + 'Container';
  CONT_MODULE = PLUGIN_EDID_PREFIX + 'ModuleContainer';
const
  QUST_DEBUG = PLUGIN_EDID_PREFIX + 'DebugQuest';
const
  SCRIPT_SORTING_CHEST = 'RobcoMagicStash:SortingChest';
const
  ACTI_NAME_SUFFIX = ' (Smart Sort)';
  ACTI_ATTX_OVERRIDE = 'Open';

Function FindMainRecord(baseFile: IInterface; grup: string; recordID: string): IInterface;
begin
  Result := WinningOverride(MainRecordByEditorID(GroupBySignature(baseFile, grup), recordID));
end; 

Procedure ScanForFiles();
var
  i: integer;
  currentFile: IInterface;
begin
  for i := 0 to FileCount - 1 do begin
    currentFile := FileByIndex(i);
    if GetFileName(currentFile) = FALLOUT_4_ESM_NAME then begin
      FalloutESM := currentFile;
      AddMessage('Found Fallout4.esm');
    end
    else if GetFileName(currentFile) = TARGET_ESP_NAME then begin
      TargetESP := currentFile;
      AddMessage('Found target file');
    end
    else if GetFileName(currentFile) = PLUGIN_ESP_NAME then begin
      PluginESP := currentFile;
      AddMessage('Found plugin source file');
    end;
  end;
end;

Procedure ResolveIDs();
var
  buttonSound, sortSound, processingSound: IInterface;
begin

  buttonSound := FindMainRecord(FalloutESM, 'SNDR', SNDR_BUTTON);
  sortSound := FindMainRecord(FalloutESM, 'SNDR', SNDR_SORT);
  processingSound := FindMainRecord(FalloutESM, 'SNDR', SNDR_PROCESSING);

  TempCONT := BaseName(FindMainRecord(PluginESP, 'CONT', CONT_TEMP));
  ModuleCONT := BaseName(FindMainRecord(PluginESP, 'CONT', CONT_MODULE));

  DebugQUST := BaseName(FindMainRecord(PluginESP, 'QUST', QUST_DEBUG));

  ButtonSNDR := BaseName(buttonSound);
  SortSNDR := BaseName(sortSound);
  ProcessingSNDR := BaseName(processingSound);
end;

Procedure ResolveGroups();
begin
  ActivatorGRUP := Add(TargetESP, 'ACTI', false);
  ConstructableGRUP := Add(TargetESP, 'COBJ', false);
end;

Procedure ResolveKeywords();
var
  kywd: IInterface;
begin
  kywd := GroupBySignature(PluginESP, 'KYWD');
  ActivatorKYWD := MainRecordByEditorID(kywd, KYWD_PLUGIN_ACTI);
  kywd := GroupBySignature(FalloutESM, 'KYWD');
  WorkshopScrapFilterKYWD := MainRecordByEditorID(kywd, KYWD_WORKSHOP_SCRAP_FILTER);
end;

Procedure CopyPreviewTransform(container: IInterface; activator: IInterface);
var
  sourceTransform: IInterface;
  targetTransform: IInterface;
begin
  sourceTransform := ElementBySignature(container, 'PTRN');
  targetTransform := Add(activator, 'PTRN', true);
  SetEditValue(targetTransform, GetEditValue(sourceTransform));
end;

type ContainerSounds = record
  button, close, open, stash: string;
end;


Procedure AddScripts(sourceContainer: IInterface; targetActivator: IInterface);
var
  properties: IInterface;
  openSoundID, closeSoundID: String;
begin

  openSoundID := GetEditValue(ElementBySignature(sourceContainer, 'SNAM'));
  closeSoundID := GetEditValue(ElementBySignature(sourceContainer, 'QNAM'));

  properties := AddScript(targetActivator, SCRIPT_SORTING_CHEST);

  AddScriptObjectProperty(properties, 'kOpenSound', openSoundID);
  AddScriptObjectProperty(properties, 'kCloseSound', closeSoundID);
  AddScriptObjectProperty(properties, 'kButtonSound', ButtonSNDR);
  AddScriptObjectProperty(properties, 'kStashSound', SortSNDR);
  AddScriptObjectProperty(properties, 'kProcessingSound', ProcessingSNDR);
  AddScriptObjectProperty(properties, 'kTempContainer', TempCONT);
  AddScriptObjectProperty(properties, 'kModuleContainer', ModuleCONT);
  AddScriptObjectProperty(properties, 'DebugLog', DebugQUST);
end;

Procedure SetEDID(e: IInterface; id: string);
begin
  SetElementEditValues(e, 'EDID', id);
end;

Function CopyElement(element: IInterface; editorID: string): IInterface;
var
  copy: IInterface;
begin
  copy := wbCopyElementToFile(WinningOverride(element), TargetESP, true, true);
  SetEDID(copy, editorID);
  Result := copy;
end;

Procedure LinkConstructableObjectTo(cobj: IInterface; cnam: IInterface);
begin
  SetElementEditValues(cobj, 'CNAM', BaseName(cnam));
end;

Function CreateActivatorFromContainer(container: IInterface): IInterface;
var
  activator: IInterface;
begin
  //AddMessage('Creating new activator: ' + activatorID);
  activator := Add(ActivatorGRUP, 'ACTI', true);
  //AddMessage('Activator assigned: ' + IfThen(Assigned(activator), 'True','False'));
  ApplyEditorID(activator, Format(ACTI_EDID_FORMAT, [EditorID(container)]));
  ApplyName(activator, GetContainerDisplayName(container) + ACTI_NAME_SUFFIX);
  ApplyActivateTextOverride(activator, ACTI_ATTX_OVERRIDE);
  ApplyDefaultMarkerColor(activator);
  AddKeywordData(activator, ActivatorKYWD);
  CopyModelData(container, activator);
  CopyPreviewTransform(container, activator);

  AddScripts(container, activator);;

  Result := activator;
end;

Function Initialize() : integer;
begin
  ScanForFiles();
  ResolveIDs();
  ResolveGroups();
  ResolveKeywords();
end;

Procedure ProcessConstructableFormList(cobj: IInterface; flst: IInterface);
var
  lnam: IInterface;
  linkedForm, acti, cont: IInterface;
  lnamEntry: IInterface;
  hasLinkedContainer: boolean;
  i: integer;
begin
  lnam := ElementByPath(flst, 'LNAM');
  hasLinkedContainer := false;
  for i := 0 to ElementCount(lnam) - 1 do begin
    linkedForm := GetLinkedMainRecord(ElementByIndex(lnam, i));
    if Signature(linkedForm) = 'CONT' then hasLinkedContainer := true;
  end;
  if hasLinkedContainer then begin
    cobj := CopyElement(cobj, Format(COBJ_EDID_FORMAT, [EditorID(cobj)]));
    flst := CopyElement(flst, Format(FLST_EDID_FORMAT, [EditorID(flst)]));
    seev(flst, 'FULL', geev(flst, 'FULL') + ACTI_NAME_SUFFIX);
    LinkConstructableObjectTo(cobj, flst);
    lnam := ElementByPath(flst, 'LNAM');
    for i := 0 to ElementCount(lnam) - 1 do begin
      lnamEntry := ElementByIndex(lnam, i);
      linkedForm := GetLinkedMainRecord(lnamEntry);
      if Signature(linkedForm) = 'CONT' then begin
        cont := linkedForm;
        acti := CreateActivatorFromContainer(cont);
        SetEditValue(lnamEntry, BaseName(acti));
      end;
    end;
  end;
end;

function Process(e: IInterface): integer;
var
  cnam, flist, cont, cobj, acti: IInterface;
begin

  if Signature(e) <> 'COBJ' then Exit;
  cobj := e;
  if HasKeyword(cobj, 'FNAM', WorkshopScrapFilterKYWD) then Exit;

  cnam := GetLinkedMainRecord(ElementBySignature(cobj, 'CNAM'));

  if Signature(cnam) = 'FLST' then begin
    flist := cnam;
    ProcessConstructableFormList(cobj, flist);
  end;
  
  if Signature(cnam) = 'CONT' then begin
    cont := cnam;
    acti := CreateActivatorFromContainer(cont);
    cobj := CopyElement(cobj, Format(COBJ_EDID_FORMAT, ['Activator_' + EditorID(cont)]));
    LinkConstructableObjectTo(cobj, acti);
  end;
end;

end.


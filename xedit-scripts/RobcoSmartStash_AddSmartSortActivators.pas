unit RobcoSmartStash_AddSmartSortActivators;

interface
//uses xEditAPI, xEditExtensions, Classes, SysUtils, StrUtils, Windows;
uses xEditAPI, xEditExtensions, Classes, SysUtils, StrUtils, Windows, Vcl.CheckLst, Vcl.Forms;

implementation

const
  FALLOUT_ESM_NAME = 'Fallout4.esm';
  FALLOUT_EXE_NAME = 'Fallout4.exe';
  PLUGIN_ESP_NAME = 'Robco Auto Sort.esp';
const
  PLUGIN_EDID_PREFIX = 'robco_auto_sort_';
  ACTI_EDID_FORMAT = PLUGIN_EDID_PREFIX + 'acti_%s';
  COBJ_EDID_FORMAT = PLUGIN_EDID_PREFIX+ 'cobj_%s';
  FLST_EDID_FORMAT = PLUGIN_EDID_PREFIX + 'flst_%s';
  KYWD_EDID_FORMAT = PLUGIN_EDID_PREFIX + 'kywd_%s';
const
  SCRIPT_ITEM_SORTER = 'RobcoAutoSort:ItemSorter';
const
  ACTI_NAME_SUFFIX = ' (Auto Sort)';
  ACTI_ATTX_OVERRIDE = 'Open';
const
  KYWD_WORKSHOP_SCRAP_FILTER = 'WorkshopRecipeFilterScrap';

var KYWD_PLUGIN_ACTI: string;
var FalloutESM, PluginESP, TargetESP: IInterface;
var ActivatorGRUP, ConstructableGRUP: IInterface;
var ActivatorKYWD, WorkshopScrapFilterKYWD: IInterface;

Function FindMainRecord(baseFile: IInterface; grup: string; recordID: string): IInterface;
begin
  Result := WinningOverride(MainRecordByEditorID(GroupBySignature(baseFile, grup), recordID));
end;

Function IsFalloutExe(fileName: string): boolean;
begin
    Result := fileName = FALLOUT_EXE_NAME;
end;

Function IsFalloutESM(fileName: string): boolean;
begin
    Result := fileName = FALLOUT_ESM_NAME;
end;

Function IsPluginESP(fileName: string): boolean;
begin
  Result := fileName = PLUGIN_ESP_NAME;
end;

Function SelectTargetFile(): IInterface;
var
  frm: TForm;
  clb: TCheckListBox;
  iFile: IInterface;
  iFileName: string;
  i: integer;
begin
  frm := frmFileSelect;
  try
    frm.Caption := 'Select a plugin to add files into';
    clb := TCheckListBox(frm.FindComponent('CheckListBox1'));

    for i := 0 to FileCount()-1 do begin
      iFile := FileByIndex(i);
      iFileName := GetFileName(iFile);
      if not isFalloutExe(iFileName) and not isFalloutESM(iFileName) and not isPluginEsp(iFileName) then begin
        clb.Items.InsertObject(0, iFileName, iFile);
      end;
    end;
    if frm.ShowModal <> mrOk then begin
      Result := nil;
      Exit;
    end;
    for i := 0 to clb.Items.Count do begin
      if clb.Checked[i] then begin
        Result := ObjectToElement(clb.Items.Objects[i]);
        Break;
      end;
    end;
  finally
    frm.Free;
  end;
end;


Procedure ScanForFiles();
var
  i: integer;
  currentFile: IInterface;
begin
  for i := 0 to FileCount - 1 do begin
    currentFile := FileByIndex(i);
    if GetFileName(currentFile) = FALLOUT_ESM_NAME then begin
      FalloutESM := currentFile;
      AddMessage('Found Fallout4.esm');
    end
    else if GetFileName(currentFile) = PLUGIN_ESP_NAME then begin
      PluginESP := currentFile;
      AddMessage('Found plugin source file');
    end;
  end;
  TargetESP := SelectTargetFile();
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
begin
  properties := AddScript(targetActivator, SCRIPT_ITEM_SORTER);
end;

Procedure SetEDID(e: IInterface; id: string);
begin
  SetElementEditValues(e, 'EDID', id);
end;


Function CopyRecordToTarget(element: IInterface; newEditorID: string): IInterface;
var
  copy: IInterface;
begin
  copy := wbCopyElementToFile(WinningOverride(element), TargetESP, true, true);
  SetEDID(copy, newEditorID);
  Result := copy;
end;

Function CopyMainRecordIfMissing(element: IInterface; newEditorID: string): IInterface;
var
  oldRecord: IInterface;
begin
  AddMessage('CopyMainRecordIfMissing');
  AddMessage('signature: ' + Signature(element));
  AddMessage('newEditorID: ' + newEditorID);
  oldRecord := FindMainRecord(TargetESP, Signature(element), newEditorID);
  AddMessage('old record editor ID: ' + EditorID(oldRecord));
  if not Assigned(oldRecord) then begin
    Result := CopyRecordToTarget(element, newEditorID);
  end
  else begin
    Result := oldRecord;
  end;
end;


Function AddMainRecordIfMissing(groupRecord: IInterface; signature: string; editorID: string): IInterface;
var
  oldRecord: IInterface;
begin
  oldRecord := FindMainRecord(TargetESP, signature, editorID);
  if not Assigned(oldRecord) then begin
    Result := Add(groupRecord, signature, true);
  end
  else begin
    Result := oldRecord;
  end;
end;

Procedure LinkConstructableObjectTo(cobj: IInterface; cnam: IInterface);
begin
  SetElementEditValues(cobj, 'CNAM', BaseName(cnam));
end;

Procedure CopyProperties(source: IInterface; target: IInterface);
  var
    sourceProperties, targetProperties, sourceProperty: IInterface;
    i: integer;
begin
  sourceProperties := Properties(source);
  if not Assigned(sourceProperties) then Exit;
  RemoveIfAssigned(target, 'PRPS');
  targetProperties := Add(target, 'PRPS', true);
  for i := 0 to ElementCount(sourceProperties)-1 do begin
    sourceProperty := ElementByIndex(sourceProperties, i);
    ElementAssign(targetProperties, HighInteger, sourceProperty, false); // append
  end;
end;

Function CreateActivatorFromContainer(container: IInterface): IInterface;
var
  edid: string;
  activator: IInterface;
begin
  //AddMessage('Creating new activator: ' + activatorID);
  edid := Format(ACTI_EDID_FORMAT, [EditorID(container)]);
  activator := AddMainRecordIfMissing(ActivatorGRUP, 'ACTI', edid);
  //AddMessage('Activator assigned: ' + IfThen(Assigned(activator), 'True','False'));
  CopyRecordHeaderFlags(container, activator);
  ApplyEditorID(activator, edid);
  ApplyName(activator, GetContainerDisplayName(container) + ACTI_NAME_SUFFIX);
  ApplyActivateTextOverride(activator, ACTI_ATTX_OVERRIDE);
  ApplyDefaultMarkerColor(activator);
  AddKeywordData(activator, ActivatorKYWD);
  CopyModelData(container, activator);
  CopyPreviewTransform(container, activator);
  CopyProperties(container, activator);

  AddScripts(container, activator);

  Result := activator;
end;

Function Initialize() : integer;
begin
  KYWD_PLUGIN_ACTI := Format(KYWD_EDID_FORMAT, ['SortingActivator']);
  AddMessage('KYWD_PLUGIN_ACTI: ' + KYWD_PLUGIN_ACTI);

  ScanForFiles();
  ResolveGroups();
  ResolveKeywords();
end;

Procedure ProcessConstructableFormList(sourceCobj: IInterface; sourceFlist: IInterface);
var
  lnam: IInterface;
  linkedForm, cobj, flst, acti, cont: IInterface;
  lnamEntry: IInterface;
  hasLinkedContainer: boolean;
  i: integer;
begin
  lnam := ElementByPath(sourceFlist, 'LNAM');
  hasLinkedContainer := false;
  AddMessage('Processing constructable form list');
  for i := 0 to ElementCount(lnam) - 1 do begin
    linkedForm := GetLinkedMainRecord(ElementByIndex(lnam, i));
    if Signature(linkedForm) = 'CONT' then hasLinkedContainer := true;
  end;
  if hasLinkedContainer then begin
    cobj := CopyMainRecordIfMissing(sourceCobj, Format(FLST_EDID_FORMAT, [EditorID(sourceCobj)]));
    flst := CopyMainRecordIfMissing(sourceFlist, Format(FLST_EDID_FORMAT, [EditorID(sourceFlist)]));
    seev(flst, 'FULL', geev(sourceFlist, 'FULL') + ACTI_NAME_SUFFIX);
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

  AddMessage('Processing constructable form list');
  cnam := GetLinkedMainRecord(ElementBySignature(cobj, 'CNAM'));

  if Signature(cnam) = 'FLST' then begin
    flist := cnam;
    ProcessConstructableFormList(cobj, flist);
  end;

  if Signature(cnam) = 'CONT' then begin
    cont := cnam;
    acti := CreateActivatorFromContainer(cont);
    cobj := CopyMainRecordIfMissing(cobj, Format(COBJ_EDID_FORMAT, ['Activator' + EditorID(cont)]));
    LinkConstructableObjectTo(cobj, acti);
  end;
end;

end.


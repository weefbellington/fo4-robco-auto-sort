unit RobcoSmartSort_CreateConstructableObject;

interface
uses xEditAPI, xEditExtensions, Classes, SysUtils, StrUtils, Windows, ScriptUtilities;

implementation

var FalloutESM, PluginESP: IInterface;
var ConstructableGRUP: IInterface;
var BottlecapMISC, WorkbenchKYWD, RecipeFilterKYWD: string;

const
  FALLOUT_4_ESM_NAME = 'Fallout4.esm';
  PLUGIN_ESP_NAME = 'Robco Smart Stash.esp';
const
  PLUGIN_EDID_PREFIX = 'robco_smart_sort_';
  COBJ_EDID_FORMAT = PLUGIN_EDID_PREFIX + 'co_%s';
const
  ACTI_NAME_SUFFIX = ' (Smart Sort)';
  ACTI_ATTX_OVERRIDE = 'Open';
const
  MISC_BOTTLECAP = 'Caps001';
  KYWD_WORKBENCH = PLUGIN_EDID_PREFIX + 'VendingMachineCraftKey';
  KYWD_RECIPE_FILTER = PLUGIN_EDID_PREFIX + 'SortingModuleRecipeFilter';

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
    else if GetFileName(currentFile) = PLUGIN_ESP_NAME then begin
      PluginESP := currentFile;
      AddMessage('Found plugin source file');
    end;
  end;
end;

Procedure ResolveGroups();
begin
  ConstructableGRUP := Add(PluginESP, 'COBJ', false);
end;

Procedure ResolveIDs();
begin
  AddMessage('Workbench keyword string: ' + KYWD_WORKBENCH);
  BottlecapMISC := BaseName(FindMainRecord(FalloutESM, 'MISC', MISC_BOTTLECAP));
  WorkbenchKYWD := BaseName(FindMainRecord(PluginESP, 'KYWD', KYWD_WORKBENCH));
  RecipeFilterKYWD := BaseName(FindMainRecord(PluginESP, 'KYWD', KYWD_RECIPE_FILTER));
end;


Procedure SetEDID(e: IInterface; id: string);
begin
  SetElementEditValues(e, 'EDID', id);
end;


Procedure LinkConstructableObjectTo(cobj: IInterface; cnam: IInterface);
begin
  SetElementEditValues(cobj, 'CNAM', BaseName(cnam));
end;


Function RemoveCharacters(str: string; len: integer): string;
begin
  Result := Copy(str, len+1, Length(str));
end;

Function Initialize() : integer;
begin
  ScanForFiles();
  ResolveGroups();
  ResolveIDs();
end;

Function Process(e: IInterface): integer;
var
  edid, co_edid: string;
  cobj, intv: IInterface;
begin
  edid := GetElementEditValues(e, 'EDID');
  cobj := Add(ConstructableGRUP, 'COBJ', true);
  co_edid := RemoveCharacters(edid, Length(PLUGIN_EDID_PREFIX));
  co_edid := Format(COBJ_EDID_FORMAT, [co_edid]);
  ApplyEditorID(cobj, co_edid);

  AddComponent(cobj, BottlecapMISC, '10');

  AddMessage('Workbench Keyword: ' + WorkbenchKYWD);
  Add(cobj, 'BNAM', true);
  SetElementEditValues(cobj, 'BNAM', WorkbenchKYWD);
  
  intv := Add(cobj, 'INTV', true);
  seev(intv, 'Created Object Count', '1');
  seev(intv, 'Priority', '0');

  Add(cobj, 'FNAM', true);
  seev(cobj, 'FNAM\[0]', RecipeFilterKYWD);

  Add(cobj, 'CNAM', true);
  SetElementEditValues(cobj, 'CNAM', BaseName(e));

  Add(cobj, 'DESC', true);
  SetElementEditValues(cobj, 'DESC', GetElementEditValues(e, 'FULL'));

end;

end.


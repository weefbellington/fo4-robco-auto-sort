unit xEditExtensions;

interface

uses xEditAPI, Classes, SysUtils, StrUtils, Windows;

Function geev(e: IInterface; ip: string): string;
Procedure seev(e: IInterface; ip: string; val: string);

Function RemoveIfAssigned(parent: IInterface; path: string): boolean;

Procedure ApplyEditorID(e: IInterface; id: string);
Procedure ApplyName(e: IInterface; name: string);

Function HasKeyword(e: IInterface; elementSignature: string; keyword: IInterface): boolean;
Procedure AddKeywordData(e: IInterface; keyword: IInterface);

procedure AddMasterFiles(target: IInterface; fileNames: TStringList);
Procedure ApplyActivateTextOverride(e: IInterface; text: string);
Procedure ApplyDefaultMarkerColor(e: IInterface);

Function GetFileHeader(fileObj: IInterface): IInterface;
Function HeaderNextObjectID(fileObj: IInterface): string;
Procedure SetHeaderNextObjectID(fileObj: IInterface; id: string);

Procedure CopyRecordHeaderFlags(source: IInterface; target: IInterface);

Function StringValue(b: boolean): string;
Function GetContainerDisplayName(source: IInterface): string;
Function IsEmpty(s: string): boolean;
Function IsNotEmpty(s: string): boolean;

Function ObjectBounds(source: IInterface): IInterface;
Function Properties(source: IInterface): IInterface;

Procedure CopyModelData(source: IInterface; target: IInterface);

Function GetLinkedMainRecord(e: IInterface): IInterface;
Function AddScript(mainRecord: IInterface; scriptName: string): IInterface;
Procedure AddScriptObjectProperty(e: IInterface; pName: string; pForm: string);
Procedure AddComponent(mainRecord: IInterface; componentName: string; count: string);

implementation

{
  geev:
  GetElementEditValues, enhanced with ElementByPath.

  Example usage:
  s1 := geev(e, 'Conditions\[3]\CTDA - \Function');
  s2 := geev(e, 'KWDA\[2]');
}
function geev(e: IInterface; ip: string): string;
begin
  Result := GetEditValue(ElementByPath(e, ip));
end;

{
  seev:
  SetElementEditValues, enhanced with ElementByPath.

  Example usage:
  seev(e, 'Conditions\[2]\CTDA - \Type', '10000000');
  seev(e, 'KWDA\[0]'),
}
procedure seev(e: IInterface; ip: string; val: string);
begin
  SetEditValue(ElementByPath(e, ip), val);
end;

Function RemoveIfAssigned(parent: IInterface; path: string): boolean;
var
  element: IInterface;
begin
  Result := false;
  element := ElementByPath(parent, path);
  if Assigned(element) then begin
    Remove(element);
    Result := true;
  end;
end;

Procedure ApplyActivateTextOverride(e: IInterface; text: string);
begin
  Add(e, 'ATTX', true);
  SetElementEditValues(e, 'ATTX', text);
end;

Procedure ApplyDefaultMarkerColor(e: IInterface);
begin
  Add(e, 'PNAM', true);
  seev(e, 'PNAM\Red', '204');
  seev(e, 'PNAM\Green', '76');
  seev(e, 'PNAM\Blue', '51');
end;

Procedure ApplyEditorID(e: IInterface; id: string);
begin
  Add(e, 'EDID', true);
  SetElementEditValues(e, 'EDID', id);
end;

Procedure ApplyName(e: IInterface; name: string);
begin
  Add(e, 'FULL', true);
  SetElementEditValues(e, 'FULL', name)
end;

Function GetContainerDisplayName(source: IInterface): string;
begin
  Result := GetElementEditValues(source, 'FULL');
end;

Function HasKeyword(e: IInterface; elementSignature: string; keyword: IInterface): boolean;
var
  keywordContainer, kywd: IInterface;
  i: integer;
begin
  Result := false;
  keywordContainer := ElementBySignature(e, elementSignature);
  for i := 0 to ElementCount(keywordContainer) do begin
    kywd := ElementByIndex(keywordContainer, i);
    if GetEditValue(kywd) = BaseName(keyword) then begin
      Result := true;
      exit;
    end;
  end;
end;

Procedure AddKeywordData(e: IInterface; keyword: IInterface);
begin
  RemoveIfAssigned(e, 'KWDA');
  Add(e, 'KWDA', true);
  seev(e, 'KWDA\[0]', BaseName(keyword));
end;

Procedure AddScriptObjectProperty(e: IInterface; pName: string; pForm: string);
var
  p: IInterface;
begin
  p := ElementAssign(e, HighInteger, nil, false);
  seev(p, 'propertyName', pName);
  seev(p, 'Type', 'Object');
  seev(p, 'Flags', 'Edited');
  seev(p, 'Value\Object Union\Object v2\FormID', pForm);
end;

Function GetFileHeader(fileObj: IInterface): IInterface;
begin
  Result := IInterface(ElementByIndex(fileObj, 0));
end;

Function HeaderNextObjectID(fileObj: IInterface): string;
var
  header: IInterface;
begin
  header := GetFileHeader(fileObj);
  AddMessage('Next Object ID is not empty: ' + StringValue(IsNotEmpty(geev(header, 'HEDR\Next Object ID'))));
  Result := geev(header, 'HEDR\Next Object ID');
end;

Procedure SetHeaderNextObjectID(fileObj: IInterface; id: string);
var
  header: IInterface;
begin
  header := GetFileHeader(fileObj);
  seev(header, 'HEDR\Next Object ID', id);
end;

Procedure CopyRecordHeaderFlags(source: IInterface; target: IInterface);
var
  sourceFlags: IInterface;
  targetFlags: IInterface;
begin
  sourceFlags := ElementByPath(source, 'Record Header\Record Flags');
  targetFlags := ElementByPath(target, 'Record Header\Record Flags');
  SetNativeValue(targetFlags, GetNativeValue(sourceFlags));
end;

Function GetMasterFilesContainer(fileObj: IInterface): IInterface;
var
  header: IInterface;
begin
  header := GetFileHeader(fileObj);
  Result := IInterface(Add(header, 'Master Files', true));
end;

Procedure AddMasterFileEntry(masterContainer: IInterface; index: integer; fileName: String);
var
  entry: IInterface;
begin
  entry := ElementByIndex(masterContainer, index);
  if not Assigned(entry) then begin
    entry := ElementAssign(masterContainer, HighInteger, nil, False);
  end;
  SetElementEditValues(entry, 'MAST', fileName);
end;

Procedure AddMasterFiles(target: IInterface; fileNames: TStringList);
var
  masterContainer: IInterface;
  i: integer;
begin
  masterContainer := GetMasterFilesContainer(target);
  for i := 0 to fileNames.Count - 1 do begin
    AddMasterFileEntry(masterContainer, i, fileNames[i]);
  end;
end;

Function IsEmpty(s: string): boolean;
begin
  Result := s = ''
end;

Function IsNotEmpty(s: string): boolean;
begin
  Result := s <> ''
end;

Function StringValue(b: boolean): string;
begin
  Result := IfThen(b, 'True', 'False');
end;

Function ObjectBounds(source: IInterface): IInterface;
begin
  Result := ElementByName(source, 'OBND');
end;

Function Properties(source: IInterface): IInterface;
begin
  Result := ElementByPath(source, 'PRPS');
end;

Procedure CopyModelData(source: IInterface; target: IInterface);
var
  model: IInterface;
  obnd_cont, obnd_acti: IInterface;
begin
  // Add model
  RemoveIfAssigned(target, 'Model');
  model := Add(target, 'Model', true);
  if Assigned(ElementByPath(source, 'Model\MODL')) then Add(model, 'MODL', true);
  if Assigned(ElementByPath(source, 'Model\MODC')) then Add(model, 'MODC', true);
  if Assigned(ElementByPath(source, 'Model\MODS')) then Add(model, 'MODS', true);
  if Assigned(ElementByPath(source, 'Model\MODF')) then Add(model, 'MODF', true);

  seev(target, 'Model\MODL', geev(source, 'Model\MODL'));
  seev(target, 'Model\MODC', geev(source, 'Model\MODC'));
  seev(target, 'Model\MODS', geev(source, 'Model\MODS'));
  seev(target, 'Model\MODF', geev(source, 'Model\MODF'));

  // Add model object bounds
  obnd_acti := ObjectBounds(target);
  obnd_cont := ObjectBounds(source);

  seev(obnd_acti, 'X1', geev(obnd_cont, 'X1'));
  seev(obnd_acti, 'Y1', geev(obnd_cont, 'Y1'));
  seev(obnd_acti, 'Z1', geev(obnd_cont, 'Z1'));
  seev(obnd_acti, 'X2', geev(obnd_cont, 'X2'));
  seev(obnd_acti, 'Y2', geev(obnd_cont, 'Y2'));
  seev(obnd_acti, 'Z2', geev(obnd_cont, 'Z2'));

end;

Function AddScript(mainRecord: IInterface; scriptName: string): IInterface;
var
  vmad, scripts, script, properties: IInterface;
begin

  RemoveIfAssigned(mainRecord, 'VMAD');
  vmad := Add(mainRecord, 'VMAD', true);
  seev(vmad, 'Version', '6');
  seev(vmad, 'Object Format', '2');

  scripts := ElementByName(vmad, 'Scripts');
  script := ElementAssign(scripts, HighInteger, nil, false);
  seev(script, 'scriptName', scriptName);
  seev(script, 'Flags', 'Local');
  properties := ElementByName(script, 'Properties');
  Result := properties;
end;

Procedure AddComponent(mainRecord: IInterface; componentName: string; count: string);
var
  fvpa, component: IInterface;
begin
  fvpa := Add(mainRecord, 'FVPA', true);
  component := ElementAssign(fvpa, HighInteger, nil, false);
  seev(component, 'Component', componentName);
  seev(component, 'Count', count);
end;


Function GetLinkedMainRecord(e: IInterface): IInterface;
begin
  Result := WinningOverride(LinksTo(e));
end;

end.

unit xEditExtensions;

interface

Function ObjectBounds(source: IInterface): IInterface;
Procedure CopyModelData(source: IInterface; target: IInterface);
Function GetLinkedMainRecord(e: IInterface): IInterface;
Function AddScript(mainRecord: IInterface; scriptName: string): IInterface;
Procedure AddComponent(mainRecord: IInterface; componentName: string; count: string);

implementation
uses xEditAPI, ScriptUtilities;

Function ObjectBounds(source: IInterface): IInterface;
begin
  Result := ElementByName(source, 'OBND');
end;

Procedure CopyModelData(source: IInterface; target: IInterface);
var
  model: IInterface;
  obnd_cont, obnd_acti: IInterface;
begin
  // Add model

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

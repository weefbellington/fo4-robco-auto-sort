Scriptname RobcoAutoSort:Util

; =============================================================================
; === Public global functions  ================================================
; =============================================================================

Struct Scale
    float scalarX
    float scalarY
    float scalarZ
EndStruct

string Function ToString(Scale s)
    return "("+s.scalarX+","+s.scalarY+","+s.scalarZ+")"
EndFunction

Scale Function GetObjectScale(ObjectReference akObj) global
    Scale s = new Scale
    s.scalarX = akObj.GetWidth()
    s.scalarY = akObj.GetLength()
    s.scalarZ = akObj.GetHeight()
    return s
EndFunction

bool Function ArraysMatch(string[] leftArr, string[] rightArr) global
    if (leftArr.Length == rightArr.Length)
        int i = 0
        while (i < leftArr.Length)
            if (leftArr[i] != rightArr[i])
                return false
            endif
            i += 1
        endwhile
        return true
    else
        return false
    endif
EndFunction

Form[] Function FlattenFormListToArray(FormList flist) global
    var[] result = _MapFormList(flist, "_FormIdentity")
    return result as Form[]
EndFunction

Int[] Function ExtractFormIDs(FormList flist) global
    return _MapFormList(flist, "_FormID") as Int[]
EndFunction

string Function GetItemName(ObjectReference akItemReference) global
    string itemName = akItemReference.GetDisplayName()
    if (itemName == "")
        itemName = akItemReference.GetName()
        if (itemName == "")
            return akItemReference.GetBaseObject().GetName()
        else
            return itemName
        endif
    else
        return itemName
    endif
EndFunction

; =============================================================================
; === Private global functions  ===============================================
; =============================================================================

Var[] Function _MapFormList(FormList flist, String fMap) global
    Var[] out = new Var[0]
    int i = 0
    while (i < flist.GetSize())
        Form lineItem = flist.GetAt(i)
        if (lineItem is FormList)
            Var[] append = _MapFormList(lineItem as FormList, fMap)
            _AddAll(out, append)
        else
            Var[] params = new var[1]
            params[0] = lineItem
            Var result = Utility.CallGlobalFunction("RobcoAutoSort:Util", fMap, params)
            out.Add(result)
        endif
        i += 1
    endwhile
    return out
EndFunction

Function _AddAll(Var[] source, Var[] append)  global
    int i = 0
    while (i < append.Length)
        source.Add(append[i])
        i += 1
    endwhile
EndFunction

Form Function _FormIdentity(Form f) global
    return f
EndFunction

Int Function _FormID(Form f) global
    return f.GetFormID()
EndFunction
Scriptname RobcoAutoSort:Util

; =============================================================================
; === Public global functions  ================================================
; =============================================================================

Function MoveItem(ObjectReference item, ObjectReference from, ObjectReference to) global
    from.RemoveItem(item, abSilent=true, akOtherContainer=to)
EndFunction

Function MoveAllItems(Form item, ObjectReference from, ObjectReference to) global
    from.RemoveItem(item, akOtherContainer=to, aiCount=-1, abSilent=true)
EndFunction

Function LogObjectScale(DebugLog log, ObjectReference akObj) global
    float scalarX = akObj.GetWidth()
    float scalarY = akObj.GetLength()
    float scalarZ = akObj.GetHeight()

    string scale = "("+scalarX+","+scalarY+","+scalarZ+")"

    log.Info("Container scale (x,y,z):" + scale, notification = true)
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

string Function GetItemName(Form akBaseItem=None, ObjectReference akItemReference=None) global
    if (akItemReference != None)
        string refName = akItemReference.GetName()
        if (refName == "")
            if (akBaseItem != None)
                return GetItemName(akBaseItem)
            else
                return GetItemName(akItemReference.GetBaseObject())
            endif
        else
            return refName
        endif
    elseif (akBaseItem != None)
        return akBaseItem.GetName()
    else
        return "None"
    endif
Endfunction
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
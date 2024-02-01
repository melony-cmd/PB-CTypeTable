; Author: T.J.Roughton
; File: C2CodeBlocks.pbi
; Description: Inserts PureBasic Code into .h based on line number / locatable string on a line.
;              It's purpose is to obviously replace #defines that cannot be directly replaced with a single
;              line definition.
; Version: 0
; Licence: Dilligaf

Structure CodeBlockList
  List codeln.s()
EndStructure

Global NewMap cblist.CodeBlockList()

; -
; C2Tasks_WritePreference - Write Preference Data
; -> See: Save_TaskList(eventType)
; -
Macro C2CodeBlocks_WritePreference
  mapkeys.s = ""
  ForEach cblist()
    mapkeys = mapkeys + MapKey(cblist())+","
  Next    
  WritePreferenceString("CodeBlockKeys",mapkeys)  
  ForEach cblist()
    i=0
    PreferenceGroup("CodeBlocks."+MapKey(cblist()))
    ForEach cblist()\codeln()
      WritePreferenceString("L"+Str(i),cblist()\codeln())
      i=i+1
    Next    
  Next  
EndMacro

; -
; C2CodeBlocks_ReadPreference - Read Preference Data
; -> See: Save_TaskList(eventType)
; -
Macro C2CodeBlocks_ReadPreference
  ClearMap(cblist())
  mapkeys.s = ReadPreferenceString("CodeBlockKeys","")
  If mapkeys<>""
    numkeys = CountString(mapkeys,",") - 1 ; because there is always a last comma and we don't need it as there isn't anything after trailing comma
    For keyidx=0 To numkeys
      key.s = StringField(mapkeys,1+keyidx,",")
      PreferenceGroup("CodeBlocks."+key)
      C2CodeBlock_Add(key)
      ExaminePreferenceKeys()
      While NextPreferenceKey()
        value.s = PreferenceKeyValue()
        If value="" : value=" " : EndIf
        C2CodeBlock_Update(key,value)
      Wend      
    Next
    Update_TagCodeBlocks()
  EndIf
EndMacro


; -
; ()
; 
; -


; -
; C2CodeBlockAdd()
; 
; -
Procedure C2CodeBlock_Add(codeblockname.s)
  AddMapElement(cblist(),codeblockname)
EndProcedure

; -
; C2CodeBlockDelete()
; 
; -
Procedure C2CodeBlock_Delete(codeblockname.s)
  Debug(":::"+codeblockname)
  If FindMapElement(cblist(),codeblockname)
    DeleteElement(cblist()\codeln())
    DeleteMapElement(cblist(),codeblockname)
  EndIf  
EndProcedure

; -
; C2CodeBlockUpdate()
; 
; -
Procedure C2CodeBlock_Update(codeblockname.s,string.s = "")
  DebugOut("C2CodeBlock_Update() -> "+codeblockname+" "+string,#False,"CodeBlock")
  If FindMapElement(cblist(),codeblockname)
    If string<>""
      AddElement(cblist()\codeln())
      cblist()\codeln() = string
    Else
      ClearList(cblist()\codeln())
      maxlines = ScintillaSendMessage(#SCI_CodeBlocksText,#SCI_GETLINECOUNT)  
      For i_ln=0 To maxlines
        linein.s = GOSCI_GetLineText(#SCI_CodeBlocksText, i_ln)
        AddElement(cblist()\codeln())
        cblist()\codeln() = linein
      Next      
    EndIf
  EndIf  
EndProcedure

; -
; C2CodeBlock_View()
; 
; -
Procedure C2CodeBlock_View(id,codeblockname.s)
  DebugOut("C2CodeBlock_View() -> "+Str(id)+" "+codeblockname,#False,"CodeBlock")
  bufstr.s = ""
  If FindMapElement(cblist(),codeblockname)
    ForEach cblist()\codeln()
      Debug cblist()\codeln()
      bufstr = bufstr + cblist()\codeln() + Chr(10)   
    Next
    GOSCI_SetText(id,bufstr,#True)
  EndIf  
EndProcedure

; -
; C2CodeBlock_Paste()
; 
; -
Procedure C2CodeBlock_ReplacePaste(codeblockname.s,strreplace.s="",currentln.s="",atline=-1)
  If FindString(currentln,strreplace)=0 : ProcedureReturn : EndIf
  If FindMapElement(cblist(),codeblockname)
    GOSCI_SetLineText(#SCI_CText,atline,"")
    ForEach cblist()\codeln()
      GOSCI_InsertLineOfText(#SCI_CText,atline+iins,cblist()\codeln())
      iins=iins+1
    Next
  EndIf    
EndProcedure


;
; Test Fill because we don't actually have anything to use this feature with yet
;
;  C2CodeBlock_Add("TESTA")
;  C2CodeBlock_Update("TESTA","1")
;  C2CodeBlock_Update("TESTA","2")
;  C2CodeBlock_Update("TESTA","3")
;  C2CodeBlock_Update("TESTA","4")
;  
;  
;  C2CodeBlock_Add("TESTB")
;  C2CodeBlock_Update("TESTB","x1")
;  C2CodeBlock_Update("TESTB","x2")
;  C2CodeBlock_Update("TESTB","x3")
;  C2CodeBlock_Update("TESTB","x4")
 
; CodeBlock_View("TESTA")
; CodeBlock_View("TESTB")
; 
; CodeBlock_Delete("TESTA")
; Debug("---")
; CodeBlock_View("TESTA")


; IDE Options = PureBasic 6.03 LTS (Windows - x86)
; CursorPosition = 118
; FirstLine = 91
; Folding = --
; EnableXP
; DPIAware
; CompileSourceDirectory
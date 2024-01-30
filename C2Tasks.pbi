﻿; Author: T.J.Roughton
; File: C2Tasks.pbi
; Description: Designed to perform certain tasks before & after the main chunk of translating a .h file to .pbi takes place             
; Version: 0
; Licence: Dilligaf

; -
; C2Tasks_WritePreferenceTasks - Write Preference Data
; -> See: Save_TaskList(eventType)
; -
Macro C2Tasks_WritePreferenceTasks
  For row = 0 To CountGadgetItems(#LI_TASKS)    
    PreferenceGroup("Task_"+Str(row))
      For column = 0 To 4
        WritePreferenceString("Pram_"+Str(column),GetGadgetItemText(#LI_TASKS, row, column))          
      Next    
  Next  
EndMacro

; -
; C2Tasks_WritePreferenceMarkers - Write Preference Data
; -> See: Save_TaskList(eventType)
; -
Macro C2Tasks_WritePreferenceMarkers
  markers.s=""
  lnmax = GOSCI_GetNumberOfLines(#SCI_CText)
  For iln = 0 To lnmax
    cmarker = ScintillaSendMessage(#SCI_CText,#SCI_MARKERGET,iln)
    If cmarker<0 : cmarker=0 : EndIf
    markers + Str(cmarker) + ","
  Next     
  WritePreferenceString("ProcMakers",markers)  
EndMacro

; -
; C2Tasks_ReadPreferenceTasks - Read Preference Data
; -> See: Open_TaskList(eventType)
; -
Macro C2Tasks_ReadPreferenceTasks
  While PreferenceGroup("Task_"+Str(row)) <> 0
    Task.s = ReadPreferenceString("Pram_0","")
    ValueA.s = ReadPreferenceString("Pram_1","")
    ValueB.s = ReadPreferenceString("Pram_2","")
    Parm.s = ReadPreferenceString("Pram_3","")
    Order.s = ReadPreferenceString("Pram_4","")
    Add_TaskList(Task,ValueA,ValueB,Parm,Order)
    row=row+1
  Wend
EndMacro

; -
; C2Tasks_ReadPreferenceMarkers - Read Preference Data
; -> See: Open_TaskList(eventType)
; -
Macro C2Tasks_ReadPreferenceMarkers
  markers.s = ReadPreferenceString("ProcMakers","")
  GOSCI_DeleteBookmarksAll(#SCI_CText)
      
  For iln=0 To CountString(markers,",")
    mark = Val(StringField(markers,1+iln,","))
    If mark = 0 : mark=-1 : EndIf
    If mark = 2 : mark=#MARK_CIRCLEPLUS : EndIf
    If mark = 4 : mark=#MARK_VLINE : EndIf
    If mark = 16 : mark=#MARK_CURVELINE : EndIf
    GOSCI_SetLineBookmark(#SCI_CText,iln,#True,mark)
  Next 
EndMacro

;
;
;
Procedure.s C2Tasks_GetPramDetails(task.s)
  Select task
    Case "Replace A->B" ; (#StartPosition,#NbOcurrences)
      ProcedureReturn "CaseSensitive|NoCase|Inplace #StartPosition,#NbOcurrences,#ForceColumnPosition"
    Case "RegReplace"
      ProcedureReturn "DotAll|Extended|MultiLine|AnyNewLine|Nocase"
    Case "Delete A"
      ProcedureReturn "CaseSensitive|NoCase #StartPosition,#NbOcurrences,#ForceColumnPosition"      
    Case "Delete Line #"
      ProcedureReturn "ValueA=#Line"
    Default
      ProcedureReturn "No Task Set."
  EndSelect
EndProcedure
;
;
;
Procedure.s C2Tasks_Replace(inline.s,va.s,vb.s,parms.s)
  ;#PB_String_CaseSensitive :: CaseSensitive,#,#
  ;#PB_String_NoCase        :: NoCase,#,#
  ;#PB_String_InPlace       :: InPlace,#,#  
  
  DebugOut("-------------------------------------- C2Tasks_Replace() = "+parms,#False,"Tasks")
  DebugOut("IN:"+inline,#False,"Tasks")
  
  p_sensitivity.s = StringField(parms,1," ")
  p_nb.s = StringField(parms,2," ")
   
  p_startpos = Val(StringField(p_nb,1,","))
  p_nboccurrences = Val(StringField(p_nb,2,","))
  p_forcecolumnposition = Val(StringField(p_nb,3,","))
  
  DebugOut("sensitivity:"+p_sensitivity,#False,"Tasks")
  DebugOut("startpos:"+Str(p_startpos),#False,"Tasks")
  DebugOut("nboccurrences:"+Str(p_nboccurrences),#False,"Tasks")
  DebugOut("forcecolumnposition:"+Str(p_forcecolumnposition),#False,"Tasks")
  
  If p_forcecolumnposition<>0    
    findpos = FindString(inline,va)
    If findpos <> p_forcecolumnposition
      ProcedureReturn inline
    EndIf    
  EndIf
  
  Select p_sensitivity
    Case "CaseSensitive"
      DebugOut("CaseSensitive",#False,"Tasks")
      outline.s = ReplaceString(inline,va,vb,#PB_String_CaseSensitive,p_startpos,p_nboccurrences)
    Case "NoCase"
      DebugOut("NoCase",#False,"Tasks")
      outline.s = ReplaceString(inline,va,vb,#PB_String_NoCase,p_startpos,p_nboccurrences)
    Case "InPlace"
      DebugOut("InPlace",#False,"Tasks")
      outline.s = ReplaceString(inline,va,vb,#PB_String_InPlace,p_startpos,p_nboccurrences)
    Default
      DebugOut("Defaulting",#False,"Tasks")
      outline.s = ReplaceString(inline,va,vb)
  EndSelect
  
  ProcedureReturn outline
EndProcedure

;
;
;
Procedure.s C2Tasks_RegReplace(inline.s, va.s, vb.s, parms.s)
   ;#PB_RegularExpression_DotAll    :: DotAll           ;'.' matches anything including newlines.
   ;#PB_RegularExpression_Extended  :: Extended         ;whitespace And '#' comments will be ignored.
   ;#PB_RegularExpression_MultiLine :: MultiLine        ;'^' And '$' match newlines within Data.
   ;#PB_RegularExpression_AnyNewLine:: AnyNewLine       ;recognize 'CR', 'LF', And 'CRLF' As newline sequences.
   ;#PB_RegularExpression_NoCase    :: NoCase           ;comparison And matching will be Case-insensitive
   If CreateRegularExpression(0, va)
    ProcedureReturn ReplaceRegularExpression(0, inline , vb)
  Else
    ProcedureReturn inline  
  EndIf
EndProcedure

;
;
;
Procedure.s C2Tasks_RemoveString(inline.s,va.s,parms.s)
  ;
  ; Character Index Nb
  ;01                    -                        46
  ; abcjdefghijklmnop235124511234511qabcdefjjuvwxyz
  ;    ^      ^    ^- StartPos ->          ^^
  ;    |______|____________________________||-> NbOccurrences
  ;
  ;0 = Nothing!
  
  ; so if forcecolumnposition is zero it's ignored, if greater than 0 eg. 1 then remove of the string and must therefore
  
  ;#PB_String_CaseSensitive: Case sensitive remove (a=a) (Default)
  ;#PB_String_NoCase       : Case insensitive remove (A=a)
  
  DebugOut("-------------------------------------- C2Tasks_Delete() = "+parms,#False,"Tasks")
  DebugOut("IN:"+inline,#False,"Tasks")
  
  p_sensitivity.s = StringField(parms,1," ")
  p_nb.s = StringField(parms,2," ")
   
  p_startpos = Val(StringField(p_nb,1,","))
  p_nboccurrences = Val(StringField(p_nb,2,","))
  p_forcecolumnposition = Val(StringField(p_nb,3,","))
  
  DebugOut("sensitivity:"+p_sensitivity,#False,"Tasks")
  DebugOut("startpos:"+Str(p_startpos),#False,"Tasks")
  DebugOut("nboccurrences:"+Str(p_nboccurrences),#False,"Tasks")
  DebugOut("forcecolumnposition:"+Str(p_forcecolumnposition),#False,"Tasks")
  
  If p_forcecolumnposition<>0    
    findpos = FindString(inline,va)
    If findpos <> p_forcecolumnposition
      ProcedureReturn inline
    EndIf    
  EndIf
         
  Select p_sensitivity
    Case "CaseSensitive"
      DebugOut("CaseSensitive",#False,"Tasks")
      outline.s = RemoveString(inline,va,#PB_String_CaseSensitive,p_startpos,p_nboccurrences)
    Case "NoCase"
      DebugOut("NoCase",#False,"Tasks")
      outline.s = RemoveString(inline,va,#PB_String_NoCase,p_startpos,p_nboccurrences)
    Default
      DebugOut("Defaulting",#False,"Tasks")
      outline.s = RemoveString(inline,va)
  EndSelect
  
  DebugOut("OUT:"+outline,#False,"Tasks")

  ProcedureReturn outline  
EndProcedure

;
;
;
Procedure C2Tasks_DeleteLine()
EndProcedure

; IDE Options = PureBasic 6.03 LTS (Windows - x86)
; CursorPosition = 68
; FirstLine = 38
; Folding = --
; EnableXP
; DPIAware
; CompileSourceDirectory
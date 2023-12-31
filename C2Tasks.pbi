﻿;
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
  
  Debug "-------------------------------------- C2Tasks_Replace() = "+parms
  Debug "IN:"+inline
  
  p_sensitivity.s = StringField(parms,1," ")
  p_nb.s = StringField(parms,2," ")
   
  p_startpos = Val(StringField(p_nb,1,","))
  p_nboccurrences = Val(StringField(p_nb,2,","))
  p_forcecolumnposition = Val(StringField(p_nb,3,","))
  
  Debug "sensitivity:"+p_sensitivity
  Debug "startpos:"+Str(p_startpos)
  Debug "nboccurrences:"+Str(p_nboccurrences)
  Debug "forcecolumnposition:"+Str(p_forcecolumnposition)  
  
  If p_forcecolumnposition<>0    
    findpos = FindString(inline,va)
    If findpos <> p_forcecolumnposition
      ProcedureReturn inline
    EndIf    
  EndIf
  
  Select p_sensitivity
    Case "CaseSensitive"
      Debug "CaseSensitive"
      outline.s = ReplaceString(inline,va,vb,#PB_String_CaseSensitive,p_startpos,p_nboccurrences)
    Case "NoCase"
      Debug "NoCase"
      outline.s = ReplaceString(inline,va,vb,#PB_String_NoCase,p_startpos,p_nboccurrences)
    Case "InPlace"
      Debug "InPlace"
      outline.s = ReplaceString(inline,va,vb,#PB_String_InPlace,p_startpos,p_nboccurrences)
    Default
      Debug "Defaulting"
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
  
  Debug "-------------------------------------- C2Tasks_Delete() = "+parms
  Debug "IN:"+inline
  
  p_sensitivity.s = StringField(parms,1," ")
  p_nb.s = StringField(parms,2," ")
   
  p_startpos = Val(StringField(p_nb,1,","))
  p_nboccurrences = Val(StringField(p_nb,2,","))
  p_forcecolumnposition = Val(StringField(p_nb,3,","))
  
  Debug "sensitivity:"+p_sensitivity
  Debug "startpos:"+Str(p_startpos)
  Debug "nboccurrences:"+Str(p_nboccurrences)
  Debug "forcecolumnposition:"+Str(p_forcecolumnposition)  
  
  If p_forcecolumnposition<>0    
    findpos = FindString(inline,va)
    If findpos <> p_forcecolumnposition
      ProcedureReturn inline
    EndIf    
  EndIf
         
  Select p_sensitivity
    Case "CaseSensitive"
      Debug "CaseSensitive"
      outline.s = RemoveString(inline,va,#PB_String_CaseSensitive,p_startpos,p_nboccurrences)
    Case "NoCase"
      Debug "NoCase"
      outline.s = RemoveString(inline,va,#PB_String_NoCase,p_startpos,p_nboccurrences)
    Default
      Debug "Defaulting"
      outline.s = RemoveString(inline,va)
  EndSelect
  
  Debug "OUT:"+outline

  ProcedureReturn outline  
EndProcedure

;
;
;
Procedure C2Tasks_DeleteLine()
EndProcedure

; IDE Options = PureBasic 6.03 LTS (Windows - x86)
; CursorPosition = 62
; FirstLine = 29
; Folding = -
; EnableXP
; DPIAware
;
; String Tools
;

;
; Get Last Word By Terminator
;
Procedure.s LastWordByTerminator(string.s,terminator.s)
  findln = - 1
  For i = Len(string) To 0 Step -1
    ch.s = Mid(string,i,1)
    For iterm=1 To Len(terminator)     
      If Mid(terminator,iterm,1) = ch : findln = i : EndIf
    Next
    If findln<>-1 : Break : EndIf
  Next  
  string = Right(string,Len(string)-findln)  
  ProcedureReturn string
EndProcedure

;
; Finds 'strip' within a string and removes from strip including 'strip' to the end of the string.
;
Procedure.s StripStringRight(string.s,strip.s)
  fpos = FindString(string,strip)
  If fpos
    string = RemoveString(Trim(Mid(string,1,fpos-1)),Chr(9))
  EndIf
  ProcedureReturn string
EndProcedure

;
; Get String between First SeporatorA and Last SeporatorB
;
Procedure.s GetStringBetween(string.s,SeparatorA.s,SeparatorB.s,index.l=1)
  If index=0 : index=1 : EndIf
  fposbracket_o = FindString(string,SeparatorA)
  
  For i = 0 To Len(string)
    If Mid(string,i,1) = SeparatorA : cnt=cnt+1 : EndIf
    If cnt=index : Break : EndIf
  Next
  fposbracket_o = i
  
  
  For i = Len(string) To 0 Step -1
    If Mid(string,i,1) = SeparatorB : Break : EndIf    
  Next
  fposbracket_c = i    
  ProcedureReturn Mid(string,fposbracket_o,fposbracket_c-fposbracket_o+1)
EndProcedure

;
;
;
Procedure.s GetStringHeadBetween(String.s,SeparatorA.s,SeparatorB.s,SeparatorStrip.b=#False)
  fpos_s = FindString(string,SeparatorA)
  fpos_e = FindString(string,SeparatorB,fpos_s)
  If SeparatorStrip=#False    
    ProcedureReturn Mid(string,fpos_s,fpos_e-fpos_s+1)
  Else
    r.s = Mid(string,fpos_s,fpos_e-fpos_s+1)
    r = RemoveString(r,SeparatorA)
    r = RemoveString(r,SeparatorB)
    ProcedureReturn r
  EndIf  
EndProcedure

;
; Remove string list from string
;
Procedure.s RemoveStringList(String.s,RemoveStringList.s,Mode=#PB_String_CaseSensitive,StartPosition=-1,NbOccurrences=-1)  
  For i=0 To Len(RemoveStringList)
    If StartPosition=-1 And NbOccurrences=-1 : string = RemoveString(string,Mid(RemoveStringList,i,1),mode) : EndIf
    If StartPosition<>-1 And NbOccurrences=-1 : string = RemoveString(string,Mid(RemoveStringList,i,1),mode,StartPosition) : EndIf
    If StartPosition<>-1 And NbOccurrences<>-1 : string = RemoveString(string,Mid(RemoveStringList,i,1),mode,StartPosition,NbOccurrences) : EndIf
  Next  
  ProcedureReturn String
EndProcedure

;
; Insert Numb Tabs into String
;
Procedure.s InsertTabs(numtabs)
  string.s = ""  
  For i=0 To numtabs : string=string+Chr(9) : Next  
  ProcedureReturn string
EndProcedure

;
;
;
Procedure.s GetTypeFromString(string.s)
  fposbracket_o = FindString(string,"(")
  If fposbracket_o
    fposbracket_c = FindString(string,")")
    string = RemoveString(Mid(string,fposbracket_o+1,fposbracket_c-fposbracket_o-1),"*")
    ProcedureReturn "_"+string+".Prototype"+string
  Else
    ProcedureReturn Trim(RemoveString(string,LastWordByTerminator(string,"* ")))
  EndIf   
  ProcedureReturn string
EndProcedure

;
; Strip Comments
;
Procedure.s GetComment(instring.s)
  outstring.s = instring
  fpos = FindString(instring,";/*")
  If fpos
    outstring = Mid(outstring,fpos)
  Else
    outstring = ""
  EndIf
  ProcedureReturn outstring
EndProcedure

;
; Strip Comments
;
Procedure.s StripComment(instring.s)
  outstring.s = instring
  fpos = FindString(instring,";/*")
  If fpos
    outstring = RemoveString(Trim(Mid(outstring,1,fpos-1)),Chr(9))
  EndIf
  ProcedureReturn outstring
EndProcedure


;Debug "["+GetStringBetween("  zz_err_t (*seek)(zz_vfs_t,zz_u32_t,zz_u8_t);	/**< offset,whence. */","(",")",2)+"]"
;Debug "["+RemoveStringList("  zz_err_t (*seek)(zz_vfs_t,zz_u32_t,zz_u8_t);	/**< offset,whence. */","()")+"]"

;Debug "["+GetStringHeadBetween("  zz_err_t (*seek)(zz_vfs_t,zz_u32_t,zz_u8_t);	/**< offset,whence. */","(",")",#True)+"]"


; IDE Options = PureBasic 6.03 LTS (Windows - x86)
; CursorPosition = 113
; FirstLine = 84
; Folding = --
; EnableXP
; DPIAware
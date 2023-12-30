;
; Remove ridculus C over elite typing! congratulations you gave yourself RSI for no reason, and I'm not talking about the mega demo.
;
Procedure C2PB_GarbadgeCollection(gadgetid)  
  ; remove all worthless ";"
  maxlns = ScintillaSendMessage(#SCI_CText,#SCI_GETLINECOUNT)  
  For i = 0 To maxlns
    linein.s = GOSCI_GetLineText(#SCI_CText, i)  
    linein = ReplaceString(linein,";","")    
    GOSCI_SetLineText(gadgetid,i,linein)
  Next
  
  ; remove all lines that contain # where define is not stated
  maxlns = ScintillaSendMessage(#SCI_CText,#SCI_GETLINECOUNT)  
  For i = 0 To maxlns
    linein.s = GOSCI_GetLineText(#SCI_CText, i)  
    If FindString(linein,"#") And FindString(linein,"define")=0
      GOSCI_DeleteLine(gadgetid,i) : i=i-1
      maxlns = ScintillaSendMessage(#SCI_CText,#SCI_GETLINECOUNT)
    EndIf    
    If FindString(linein,"#") And FindString(linein,"if")<>0
      GOSCI_DeleteLine(gadgetid,i) : i=i-1
      maxlns = ScintillaSendMessage(#SCI_CText,#SCI_GETLINECOUNT)
    EndIf
  Next
    
EndProcedure

;
; Convert Comments
;
Procedure C2PB_Comments(gadgetid,linein.s,nline,maxlines)
  If FindString(linein,"*/")
    linein = ReplaceString(linein,"/*",";/*")
    GOSCI_SetLineText(gadgetid, nline,linein)
  Else
    linein = ReplaceString(linein,"/*",";/*")    
    GOSCI_SetLineText(gadgetid,nline,linein)
    For nl = nline+1 To maxlines      
      linein = GOSCI_GetLineText(gadgetid, nl)
      GOSCI_SetLineText(gadgetid,nl,";"+linein)      
      If FindString(linein,"*/")
        Break
      EndIf      
    Next
  EndIf    
EndProcedure

;
; Convert Comments
;
Procedure C2PB_Enumations(gadgetid,linein.s,nline,maxlines)
  i=1+nline 
  GOSCI_SetLineText(gadgetid, nline,"Enumeration")
  While FindString(linein,"}") = 0
    linein = GOSCI_GetLineText(#SCI_CText,i) 
    linein = RemoveString(linein,",")
    Debug linein
    GOSCI_SetLineText(gadgetid, i,Chr(9)+"#"+LTrim(linein))
    i=i+1
  Wend
  GOSCI_SetLineText(gadgetid, i-1,"EndEnumeration")  
EndProcedure

;
; Convert Define
;
Procedure C2PB_Defines(gadgetid,linein.s,nline,maxlines)
  GOSCI_SetLineText(gadgetid, nline,">>"+linein)
  For i = 1 To CountString(linein," ")+1
    Debug StringField(linein,i," ")
  Next
  
EndProcedure

;
; Convert Structure
;
Procedure C2PB_Structures(gadgetid,linein.s,nline,maxlines)
EndProcedure


;
; Converts C variables into PB types
;
Procedure C2PB_ProcessLine(gadgetid,nline,maxlines,linein.s)
  
  skip=#False     ; skip all following phases if #True
  
    
  ; language restructure mainly looking for comment/enums/struct/#defines
  
  ;
  ; Comments
  ;
  If FindString(linein,"/*")
    C2PB_Comments(gadgetid,linein,nline,maxlines)
  EndIf
  If FindString(linein,"//")
    linein = ReplaceString(linein,"//",";//")
    GOSCI_SetLineText(gadgetid, nline,linein)
  EndIf
   
  ;
  ;
  ;  
  If FindString(linein,"enum") And FindString(linein,"{")
    Debug("---> ENUM")
    C2PB_Enumations(gadgetid,linein,nline,maxlines)
  EndIf
    
  If FindString(linein,"#define")    
    Debug("---> #define")
    C2PB_Defines(gadgetid,linein.s,nline,maxlines)
  EndIf
  
  If FindString(linein,"struct")
    Debug("---> Struct")
    C2PB_Structures(gadgetid,linein.s,nline,maxlines)    
  EndIf
  
  ; Phase 1 (Generic C Types)
  ForEach CTypeList()
    If FindString(linein,StringField(CTypeList(),2,","))
      skip=#True
    EndIf    
  Next
  
  ; Phase 2 ()
  If skip=#False
    ForEach DefTypeList()
      If FindString(linein,StringField(CTypeList(),2,","))
        skip=#True
      EndIf    
    Next
  EndIf
  
  ;GOSCI_SetLineText(gadgetid, nline,linein)
  ;Debug linein
EndProcedure  

;
;
;
Procedure C2PB_ProcessTasks(order)
  
  Debug "---------------------------------------------"        
  Debug "Process Tasks Order = "+Str(Order)
  Debug "CountGadgetItems = "+Str(CountGadgetItems(#LI_TASKS))
 
  maxlines = ScintillaSendMessage(#SCI_CText,#SCI_GETLINECOUNT)
  
  For i_ln=0 To maxlines
    linein.s = GOSCI_GetLineText(#SCI_CText, i_ln)
    For i=0 To CountGadgetItems(#LI_TASKS)-1
      If Get_TasksDetails(i,#TASK_ORDER)=Str(order)
        Debug("Str(order) = "+Str(order))
        task.s = Get_TasksDetails(i,#TASK_TYPE)
        Debug("task = "+task)        
        Select task
            
          Case "Replace A->B"
            Debug "***** Case Replace A->B"
            StrValueA.s = Get_TasksDetails(i,#TASK_VALUEA)
            StrValueB.s = Get_TasksDetails(i,#TASK_VALUEB)
            Param.s = Get_TasksDetails(i,#TASK_PARM)
            outline.s = C2Tasks_Replace(linein,StrValueA,StrValueB,Param)
            If outline<>linein
              GOSCI_SetLineText(#SCI_CText,i_ln,outline)
            EndIf
            
          Case "RegReplace"
            
          Case "Delete A"
            Debug "***** Case Delete A"            
            StrValueA.s = Get_TasksDetails(i,#TASK_VALUEA)
            Param.s = Get_TasksDetails(i,#TASK_PARM)
            outline.s = C2Tasks_RemoveString(linein,StrValueA,Param)
            If outline<>linein
              GOSCI_SetLineText(#SCI_CText,i_ln,outline)
            EndIf
            
          Case "Delete Line #"
            ValueA = Val(Get_TasksDetails(i,#TASK_VALUEA))
            
         EndSelect
      EndIf    
    Next    
  Next  
  Debug "Lines Dones = "+Str(i_ln)

EndProcedure

; IDE Options = PureBasic 6.03 LTS (Windows - x86)
; CursorPosition = 166
; FirstLine = 141
; Folding = --
; EnableXP
; DPIAware
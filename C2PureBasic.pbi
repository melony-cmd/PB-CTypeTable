;
;
;
Structure Function
  ; C
  c_name.s
  c_rtstype.s
  c_cargname.s[127]
  c_cargtype.s[127]
  c_isptr.b[127]
  c_cnbargs.b
  ; PureBasic
  pb_prototype.s
  pb_argtype.s[127]
  pb_getfunction.s
EndStructure

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

;
;
;
Procedure.s C2PB_FunctionToProtoType(inputstring.s,*cFunc.Function, prefix.s = "")   
  result.s = ""  
  ; reduce the complexity by making a multi line string into a 1 line string
  result = RemoveString(inputstring,Chr(10))
  result = RemoveString(result,Chr(13))  
  ; remove the tabs
  result = RemoveString(result,Chr(9))  
  ; remove the idiotic ; from the C standard.
  result = RemoveString(result,";")   
  ; reduce all multi-spaces to 1 space.
  For i=31 To 2 Step -1 : result = RemoveString(result,Space(i)) : Next
  
  DebugOut("C2PB_FunctionToProtoType() inputstring = ["+inputstring+"]")
  DebugOut("C2PB_FunctionToProtoType() result = ["+result+"]")
  
  ; now we should have a pretty cleaning c function  
  ; find the function name.
  fopnbrance = FindString(result,"(")
  For i=fopnbrance To 0 Step -1 : If Mid(result,i,1)=" " : Break : EndIf : Next  
  procname.s = Trim(Mid(result,i+1,fopnbrance-i-1))  
  ; get the arguments chunk from ( <- to -> ) and remove the ()
  args.s = Trim(Mid(result,fopnbrance))
  args.s = RemoveString(args,"(")
  args.s = RemoveString(args,")")  
  ;get number of arguments
  nbargs = CountString(args,",")  
  
  DebugOut("C2PB_FunctionToProtoType() args = ["+args+"]")
  ;get argument names
  For i=1 To nbargs+1
    pramname.s = Trim(StringField(args,i,","))
    argstype.s = pramname
    ;Debug Right(pramname,Len(pramname))
    For fsr=Len(pramname) To 1 Step -1
      ch.s = Mid(pramname,fsr,1)
      If (ch=" ") Or (ch="*")
        Break
      EndIf      
    Next
    pramname = Trim(Mid(pramname,fsr,Len(pramname)-fsr+1))
    argstype = RemoveString(argstype,pramname,#PB_String_CaseSensitive,fsr)
    
    DebugOut("C2PB_FunctionToProtoType() pramname = ["+pramname+"]")
    DebugOut("C2PB_FunctionToProtoType() argstype = ["+argstype+"]")
    
    ;
    *cFunc\c_cargname[i-1] = pramname
    *cFunc\c_cargtype[i-1] = argstype
    If FindString(argstype,"*")
      *cFunc\c_isptr[i-1] = #True
    Else
      *cFunc\c_isptr[i-1] = #False
    EndIf    
  Next  
  ;Build Structure
  *cFunc\c_name = procname
  *cFunc\c_cnbargs = nbargs
  
  ;Build ProtoType
  ;PrototypeC SidConfig_SetDefaultC64Model(c_defaultC64Model.l) : Global SidConfig_SetDefaultC64Model.SidConfig_SetDefaultC64Model  
  pbarguments.s = ""
  ptr.s = ""
  For i=0 To *cFunc\c_cnbargs
    ; Set pointer or not
    If *cFunc\c_isptr[i] = #True : ptr = "*" : Else : ptr = "" : EndIf 
    
    ; Convert the arguments to PB veriable types
    std.SearchTypeDefArgs : ClearStructure(std,SearchTypeDefArgs)
    std\c_name = Trim(*cFunc\c_cargname[i])
    std\c_type = Trim(*cFunc\c_cargtype[i])
      
    DebugOut("C2PB_FunctionToProtoType() (A) std\c_name = ["+std\c_name+"]")
    DebugOut("C2PB_FunctionToProtoType() (A) std\c_type = ["+std\c_type+"]")      
    DebugOut("C2PB_FunctionToProtoType() (A) std\pb_type = ["+std\pb_type+"]")      
      
    SearchTypeDef(std)
      
    DebugOut("C2PB_FunctionToProtoType() (B) std\c_name = ["+std\c_name+"]")
    DebugOut("C2PB_FunctionToProtoType() (B) std\c_type = ["+std\c_type+"]")            
    DebugOut("C2PB_FunctionToProtoType() (B) std\pb_type = ["+std\pb_type+"]")      
    
    ; Add the arguments to the 'pbarguments' stack string
    If *cFunc\c_cnbargs=i
      pbarguments+ptr+std\c_name+std\pb_type
    Else      
      pbarguments+ptr+std\c_name+std\pb_type+","
    EndIf
  Next
  
  ;Build ReturnType
  std.SearchTypeDefArgs
  std\c_name = ""
  std\c_type = Trim(Mid(result,1,FindString(result,*cFunc\c_name)-1))
  SearchTypeDef(std)
  *cFunc\c_rtstype = std\pb_type
    
  *cFunc\pb_prototype = "PrototypeC"+*cFunc\c_rtstype+" "+prefix+*cFunc\c_name+"("+pbarguments+") : Global "+prefix+*cFunc\c_name+"."+prefix+*cFunc\c_name  
  *cFunc\pb_getfunction = prefix+*cFunc\c_name+" = GetFunction(dll,"+Chr(34)+*cFunc\c_name+Chr(34)+")"
  
  ClearStructure(std,SearchTypeDefArgs)
  ProcedureReturn *cFunc\pb_prototype  
EndProcedure
; IDE Options = PureBasic 6.03 LTS (Windows - x86)
; CursorPosition = 250
; FirstLine = 228
; Folding = --
; EnableXP
; DPIAware
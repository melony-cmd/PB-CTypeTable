﻿;
; Function -> Procedure Structure
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
; Remove C PreProcessore Statements which are often not required in PB
;
Procedure C2PB_RemoveCPreProcessor(gadgetid) ; GarbageCollector
  DebugOut("C2PB_RemoveCPreProcessor()",#False,"GarbageCollector") 
  ; remove all lines that contain # where define is not stated
  DebugOut("Remove C Compiler Preprocessor Statements",#False,"GarbageCollector")
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
; Remove C ;
;
Procedure C2PB_RemoveSemiColon(gadgetid)
  DebugOut("C2PB_RemoveSemiColon()",#False,"GarbageCollector") 
  ; remove all worthless ";"   
  DebugOut("Remove all worthless ;",#False,"GarbageCollector")
  maxlns = ScintillaSendMessage(#SCI_CText,#SCI_GETLINECOUNT)  
  For i = 0 To maxlns
    linein.s = GOSCI_GetLineText(#SCI_CText, i)  
    linein = ReplaceString(linein,";","")    
    GOSCI_SetLineText(gadgetid,i,linein)
  Next
EndProcedure

;
; Convert Comments
;
Procedure C2PB_Comments(gadgetid,linein.s,nline,maxlines) ; ProcessLines
  DebugOut("C2PB_Comments()",#False,"Comments")
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
; Strip Comments
;
Procedure.s C2PB_StripComment(instring.s)
  outstring.s = instring
  fpos = FindString(instring,";/*")
  If fpos
    outstring = RemoveString(Trim(Mid(outstring,1,fpos-1)),Chr(9))
  EndIf
  ProcedureReturn outstring
EndProcedure

;
; Strip Comments
;
Procedure.s C2PB_GetComment(instring.s)
  outstring.s = instring
  fpos = FindString(instring,";/*")
  If fpos
    outstring = Str(fpos)+":"+Mid(outstring,fpos)
  EndIf
  ProcedureReturn outstring
EndProcedure

;
; Convert Enumation
;
Procedure C2PB_Enumations(gadgetid,linein.s,nline,maxlines)
  DebugOut("C2PB_Enumations()",#False,"Enumeration")
  i=1+nline 
  GOSCI_SetLineText(gadgetid, nline,"Enumeration")
  While FindString(linein,"}") = 0
    linein = GOSCI_GetLineText(#SCI_CText,i) 
    linein = RemoveString(linein,",")
    DebugOut(linein)
    GOSCI_SetLineText(gadgetid, i,Chr(9)+"#"+LTrim(linein))
    i=i+1
  Wend
  GOSCI_SetLineText(gadgetid, i-1,"EndEnumeration")  
EndProcedure

;
; Convert Define
;
Procedure C2PB_Defines(gadgetid,linein.s,nline,maxlines)
  ;-Incomplete
  DebugOut("C2PB_Defines()",#False,"Define")
  GOSCI_SetLineText(gadgetid, nline,">>"+linein)
  For i = 1 To CountString(linein," ")+1
    DebugOut(StringField(linein,i," "),#False,"Define")
  Next  
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
    DebugOut("---> ENUM",#False,"ProcessLines")
    C2PB_Enumations(gadgetid,linein,nline,maxlines)
  EndIf
    
  If FindString(linein,"#define")
    DebugOut("---> #define")
    C2PB_Defines(gadgetid,linein.s,nline,maxlines)
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
; C2PB_ProcessTasks()
;
Procedure C2PB_ProcessTasks(order)  
  DebugOut("---------------------------------------------",#False,"C2PB_ProcessTasksLevel"+Str(Order))
  DebugOut("Process Tasks Order = "+Str(Order),#False,"C2PB_ProcessTasksLevel"+Str(Order))
  DebugOut("CountGadgetItems = "+Str(CountGadgetItems(#LI_TASKS)),#False,"C2PB_ProcessTasksLevel"+Str(Order))
 
  maxlines = ScintillaSendMessage(#SCI_CText,#SCI_GETLINECOUNT)
  
  For i_ln=0 To maxlines
    linein.s = GOSCI_GetLineText(#SCI_CText, i_ln)
    For i=0 To CountGadgetItems(#LI_TASKS)-1
      If Get_TasksDetails(i,#TASK_ORDER)=Str(order)
        DebugOut("Str(order) = "+Str(order),#False,"C2PB_ProcessTasksLevel"+Str(Order))
        task.s = Get_TasksDetails(i,#TASK_TYPE)
        DebugOut("task = "+task,#False,"C2PB_ProcessTasksLevel"+Str(Order))     
        Select task
            
          Case "Replace A->B"
            DebugOut("***** Case Replace A->B",#False,"C2PB_ProcessTasksLevel"+Str(Order))
            StrValueA.s = Get_TasksDetails(i,#TASK_VALUEA)
            StrValueB.s = Get_TasksDetails(i,#TASK_VALUEB)
            Param.s = Get_TasksDetails(i,#TASK_PARM)
            outline.s = C2Tasks_Replace(linein,StrValueA,StrValueB,Param)
            If outline<>linein
              GOSCI_SetLineText(#SCI_CText,i_ln,outline)
            EndIf
            
          Case "RegReplace"
            DebugOut("***** RegReplace",#False,"C2PB_ProcessTasksLevel"+Str(Order))
            
          Case "Delete A"
            DebugOut("***** Case Delete A",#False,"C2PB_ProcessTasksLevel"+Str(Order))
            StrValueA.s = Get_TasksDetails(i,#TASK_VALUEA)
            Param.s = Get_TasksDetails(i,#TASK_PARM)
            outline.s = C2Tasks_RemoveString(linein,StrValueA,Param)
            If outline<>linein
              GOSCI_SetLineText(#SCI_CText,i_ln,outline)
            EndIf            
          Case "Delete Line #"
            DebugOut("***** Delete Line #",#False,"C2PB_ProcessTasksLevel"+Str(Order))
            ValueA = Val(Get_TasksDetails(i,#TASK_VALUEA))            
         EndSelect
      EndIf    
    Next    
  Next  
  DebugOut("Lines Dones = "+Str(i_ln),#False,"C2PB_ProcessTasksLevel"+Str(Order))
EndProcedure

;
; C2PB_FunctionToProtoType()
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
  
  DebugOut("C2PB_FunctionToProtoType() inputstring = ["+inputstring+"]",#False,"Functions")
  DebugOut("C2PB_FunctionToProtoType() result = ["+result+"]",#False,"Functions")
  
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
  
  DebugOut("C2PB_FunctionToProtoType() args = ["+args+"]",#False,"Functions")
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
    
    DebugOut("C2PB_FunctionToProtoType() pramname = ["+pramname+"]",#False,"Functions")
    DebugOut("C2PB_FunctionToProtoType() argstype = ["+argstype+"]",#False,"Functions")
    
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
      
    DebugOut("C2PB_FunctionToProtoType() (A) std\c_name = ["+std\c_name+"]",#False,"Functions")
    DebugOut("C2PB_FunctionToProtoType() (A) std\c_type = ["+std\c_type+"]",#False,"Functions")      
    DebugOut("C2PB_FunctionToProtoType() (A) std\pb_type = ["+std\pb_type+"]",#False,"Functions")     
      
    SearchTypeDef(std)
      
    DebugOut("C2PB_FunctionToProtoType() (B) std\c_name = ["+std\c_name+"]",#False,"Functions")
    DebugOut("C2PB_FunctionToProtoType() (B) std\c_type = ["+std\c_type+"]",#False,"Functions")            
    DebugOut("C2PB_FunctionToProtoType() (B) std\pb_type = ["+std\pb_type+"]",#False,"Functions")      
    
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

;
; Attempts to Clean up empty lines in structures.
;
Procedure C2PB_CleanStructures()
  Debug "C2PB_CleanStructures()"
  numLines = ScintillaSendMessage(#SCI_CText,#SCI_GETLINECOUNT)
  enable=#False
  For li = 0 To numLines
    cline.s = GOSCI_GetLineText(#SCI_CText, li)
    If FindString(cline,"Structure")
      If StringField(cline,1," ")<>"" And StringField(cline,2," ")<>""
        enable=#True
      EndIf
    EndIf
    
    If enable=#True
      If cline="" 
        ScintillaSendMessage(#SCI_CText,#SCI_GOTOLINE,li,0)
        ScintillaSendMessage(#SCI_CText,#SCI_LINEDELETE,0,0)
        li=li-1 : numLines = numLines - 1
      EndIf      
    EndIf
    
    If FindString(cline,"EndStructure")
      enable=#False
    EndIf  
  Next
  
EndProcedure

;
; Convert Structres Phase 2
;

; Only deals with the first acurrance of a nested struct struct..

Procedure C2PB_ConvertSubStructures(startln = 0)
  numLines = ScintillaSendMessage(#SCI_CText,#SCI_GETLINECOUNT)
  
  NewList substructbuf.s()
  NewList rootstructptr.s()
  
  ; Convert struct -> Structure
  For i = startln To numLines
    cline.s = GOSCI_GetLineText(#SCI_CText, i)
    If StringField(cline,1," ") = "Structure"
      If nstruct = 0 : structheadln = i : EndIf
      nstruct=nstruct+1
    EndIf
    
    If nstruct>1 
      AddElement(substructbuf())
      If StringField(cline,1," ") = "Structure"
        AddElement(rootstructptr())
        bufptr.s = RemoveString(Trim(RemoveString(C2PB_StripComment(cline),"Structure")),";")
        If FindString(bufptr,",")=0
          ptr.s = "*"+bufptr+"."+bufptr
          rootstructptr() = ptr
        Else
          For imptr=0 To CountString(bufptr,",")
            ptr.s = "*"+StringField(bufptr,1+imptr,",")+"."+StringField(bufptr,1+imptr,",")
            Debug "///" + ptr
            rootstructptr() = ptr
            AddElement(rootstructptr())
          Next          
        EndIf
      EndIf      
      substructbuf() = cline
      GOSCI_SetLineText(#SCI_CText,i,"")
    EndIf
    
    If FindString(cline,"EndStructure")
      nstruct=nstruct-1 : structfootln = i
      If nstruct = 0 : structfootln = i : Break : EndIf
    EndIf    
  Next
  
  Debug "%%% HEAD %%%"+Str(structheadln)
  Debug "%%% FOOT %%%"+Str(structfootln)
  
  ForEach rootstructptr()
    Debug "\\\ [" + rootstructptr() + "]"
    GOSCI_InsertLineOfText(#SCI_CText,structheadln+ListIndex(rootstructptr())+1,rootstructptr())
  Next
  
  ForEach substructbuf()        
    GOSCI_InsertLineOfText(#SCI_CText,structheadln+ListIndex(substructbuf()),substructbuf())
  Next   
      
  ClearList(rootstructptr())
  ClearList(substructbuf())
  
  ; the state of the file is now what I call in flux, e.g I don't know where anything is now.
  
EndProcedure

;
; Struct to PB Structure Phase 1 -> Phase 2
;
Procedure C2PB_StructToPB()
  numLines = ScintillaSendMessage(#SCI_CText,#SCI_GETLINECOUNT)
  
  ; Convert struct -> Structure
  For i = 0 To numLines
    cline.s = GOSCI_GetLineText(#SCI_CText, i)    
    ; Root Stucture
    If FindString(cline,"struct")<>0 And FindString(cline,"{")<>0
      structhead.s = ReplaceString(cline,"struct","Structure")
      structhead = Trim(RemoveString(structhead,"{"))
      GOSCI_SetLineText(#SCI_CText,i,structhead)
      structheadln = i
    EndIf
    
    If FindString(cline,"};")<>0
      GOSCI_SetLineText(#SCI_CText,i,Trim(ReplaceString(cline,"};","EndStructure")))
    EndIf
    
    If FindString(cline,"}")<>0
      GOSCI_SetLineText(#SCI_CText,i,Trim(ReplaceString(cline,"}","EndStructure")))
      semipos = FindString(cline,";")
      cbracepos = FindString(cline,"}")
      substructname.s = RemoveString(Trim(Mid(cline,cbracepos+1,semipos)),";")
      If substructname<>""
        subcline.s = GOSCI_GetLineText(#SCI_CText, i)
        DebugOut("["+substructname+"]",#False,"Struct")
        substructname = RemoveString(subcline,"EndStructure")
        GOSCI_SetLineText(#SCI_CText,structheadln,"Structure "+substructname)
        GOSCI_SetLineText(#SCI_CText,i,"EndStructure")
      Else
        ; no name! maybe it's beyond the struct as many names? 
        ; nb: I can already see a bug here if the struct has been improperly closed without a terminating ;
        ; that would also break a c compiler too however, in this situation offset is bound to a limit of (1-7)           
        ; as 0 is already is already handled above. - I highly doubt anyone would be a thick headed to put that
        ; many an alias on a struct and if you DO you should be shot in the head.
        ; It will also break if cline is equal to nothing, but that's more of what I call natural loop exit,
        ; as it falls out the bottom of the repeat/until loop, unnatural would be 'break'
        If cline<>"};"
          offseti = 1
          obuf.s = ""
          Repeat            
            cline.s = C2PB_StripComment(GOSCI_GetLineText(#SCI_CText, i + offseti))
            cline = Mid(cline,1,Len(cline)-1)
            If cline<>""
              ; Problem here of cause is PB only has 1 name thus the structure must be copied twice with each name
              ; however in this chunck of code we're not ready to do that yet as we're still processing the basics
              ; not moving structs out.              
              DebugOut("[NO SINGLE NAME]! = [" + cline + "]",#False,"Struct")
              obuf = obuf + cline + ","
            EndIf
            GOSCI_SetLineText(#SCI_CText,i + offseti,"") ; the sad consequence of the sitation is any comments are oblitorated.
            offseti=offseti+1 : If offseti>=7 : Break : EndIf
          Until FindString(cline,";")<>0 Or cline=""
          ; Solution therefore is;
          obuf = Mid(obuf,1,Len(obuf)-1)
          DebugOut("[SOLUTION]! = [" + obuf + "]",#False,"Struct")
          GOSCI_SetLineText(#SCI_CText,structheadln,"Structure "+obuf)          
        EndIf        
      EndIf      
    EndIf    
  Next
  C2PB_ConvertSubStructures()
  C2PB_CleanStructures()
EndProcedure

; IDE Options = PureBasic 6.03 LTS (Windows - x86)
; CursorPosition = 353
; FirstLine = 328
; Folding = ---
; EnableXP
; DPIAware
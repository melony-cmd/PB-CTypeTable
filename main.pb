; Author: T.J.Roughton
; File: main.pb
; Description:
;
;   On a simple level it's designed to be purely a window that displays what PB variable types translate to C variable types with
;   the user editable additional types that I might not have thought of or don't know about, including typedef translation tables.
;   
;   The more complicated level is the Header Assistant which attempts to translate .h to .pbi, it will likely never be a one catch all
;   one button click affair to do this task due to the complexities and the individuals style that orginally wrote the .h file, but
;   we can simplify it down by taking out hopefully a huge chunk of the more time consuming tedious details that are common jobs
;   when moving a .lib/.dll to the language of PureBasic which is far superior, even though we are still missing unsigned variable types
;   which would make these types of tasks by far a simpler job to undertake as you'd have 1:1 like for like variable in from one arcane 
;   language to PureBasic anyway... >> {sigh}.
;   
; Version: 0.0.1a (yeah we're still in alpha)
; Licence: Dilligaf

; Known Bugs: 
;   (likely location: C2PureBasic.pbi)
;   Multi line C functions prototypes don't get commented out
;   -- its actually part of another issue of the translated function in PB format not being placed below it but instead in a list which
;   is designed to work that way, but I needs a redesign, because sometimes developers are nice enough to actually comment/document their
;   code, which is why the translated PB procedure should be below it's counter part C function prototype, where by we don't actually know
;   it has documentation we can predictively presume it would be close to it's definition. -- wow that was a mouthful.
;
;   (likely location: C2PureBasic.pbi)
;   *varible.l is not proper PureBasic syntax *variable is however, but that's not what it being written it's been written as *v.l 
;
;   (*)
;   It's not a bug but it is cousing some anxiety, this code has never been tested on 'other' .h files other than zingzong.h while it has made
;   a lot of progress over the weeks of designing this application, it's never really been tested on anything else, mainly because requires
;   building a whole new project for something else, this has me nervious and I am expecting it to break and break pretty bad!
;
; ToDo:
;   [ ] - Clean up the debug output file, sure I can read it but I'm pretty sure no one else is going to be able to, which makes it
;         really hard for someone to report a bug when they can't even ready the debuglog.
;   [ ] - Complete Code Blocks.
;         + the design is taking awhile because I'm still not entirely sure I should put a whole editor in, or open a pre-existing editor
;         + or go a completely different direction.


;
; Setup USE
;
UseSQLiteDatabase()

;
; Declare
;
Declare Callback_Scintilla_Translation(Gadget, *scinotify.SCNotification)
Declare DebugOut(string.s,clearlog.b=#False,loglevel.s="")
Declare Header_Import(file.s="")
Declare.s Get_TasksDetails(idx.l,value.l=0)
Declare Update_TagCodeBlocks()

;
; Includes
;
IncludeFile "debuglog.pbi"
IncludeFile "GoScintilla.pbi"

;
; Forms
;
IncludeFile "form.pbf"
IncludeFile "convert_form.pbf"

;
; Enums
;
Enumeration 
  #PANELTAB_PBTYPE
  #PANELTAB_CTYPE
  #PANELTAB_DEFTYPE
  #PANELTAB_CONVERT
EndEnumeration

Enumeration
  #TASK_TYPE
  #TASK_VALUEA
  #TASK_VALUEB
  #TASK_PARM
  #TASK_ORDER
EndEnumeration

Enumeration
  #STD_PROCEDURE
  #STD_STRUCTURE
EndEnumeration

#MARK_CIRCLEPLUS = %000000001
#MARK_VLINE      = %000000010
#MARK_CURVELINE  = %000000100

;
; Types & Lists
;
Structure Type
  BasicTypeID.b
  CType.s
EndStructure

Global NewList TypeList.Type()
Global NewList SearchResults.s()

Structure SearchTypeDefArgs
  c_name.s
  c_type.s
  pb_type.s
EndStructure
Declare SearchTypeDef(*args.SearchTypeDefArgs,srctype.l)

Structure ReservedWords
  pbword.s
  reword.s
EndStructure

;
;
;
Structure PrototypeList
  proc.s
  getproc.s
EndStructure

;
Global NewList PTList.PrototypeList()
Global NewList PBTypeList.s()
Global NewList CTypeList.s()
Global NewList DefTypeList.s()
Global NewList ResWords.ReservedWords()
Global lnselected.s
Global convdonce.b = #True

;
; My System Includes
;
IncludeFile "String.pbi"
IncludeFile "ListIconGadgetInclude.pbi"
IncludeFile "DataBase.pbi"
IncludeFile "C2Tasks.pbi"
IncludeFile "C2PureBasic.pbi"
IncludeFile "C2CodeBlocks.pbi"

Global default_database.s = "default.sqlite"
Global current_hsourcefile.s = ""

;
; LineStart,ColumnStart,LineEnd,ColumnEnd
; LSxCSxLExCE
;
Procedure.s ReadSelection(arg_input.s)
  filename.s = StringField(arg_input,1,",")
  location.s = StringField(arg_input,2,",")
    
  ls = Val(StringField(location,1,"x"))
  cs = Val(StringField(location,2,"x"))
  le = Val(StringField(location,3,"x"))
  ce = Val(StringField(location,4,"x"))
  
  ; usage errors
  If cs=ce
    MessageRequester("Error","Nothing Selected!")
    End
  EndIf
  
  If ls>le Or ls<le
    MessageRequester("Error","Only one line should be selected at a time!")
    End
  EndIf

  ; pull the selected text
  If ReadFile(0,filename)
    Repeat
      inline.s = ReadString(0)
      If i=ls-1
        Break
      EndIf      
      i=i+1
    Until Eof(0) <> 0
    CloseFile(0)
  EndIf
  ProcedureReturn Mid(inline,cs,ce-cs)  
EndProcedure

;
;
;
Procedure StatusUpdate(string.s)
  StatusBarText(0,2,string)
EndProcedure

;
;
;
Procedure Add_Table(gadgetid.l,addln.s = "") ; #LI_CTypeTable
  uniqueid = Val(StringField(addln,1,","))    
  addln = RemoveString(addln,Str(uniqueid)+",",#PB_String_NoCase,1,1)     
  addln_formated.s = ReplaceString(addln,",",Chr(10))    
  
  nitems = CountGadgetItems(gadgetid)    
  AddGadgetItem(gadgetid,nitems,addln_formated)    
  SetGadgetItemData(gadgetid,nitems,uniqueid) 
EndProcedure

;
;
;
Procedure Update_PBTypeList()
  ClearGadgetItems(#LI_PBTypeTable)
  GetDatabaseList(0,"PureBasicTypes",PBTypeList())
  ForEach PBTypeList()
    Add_Table(#LI_PBTypeTable,PBTypeList())
    pbtype.s = "("+StringField(PBTypeList(),3,",")+") "+StringField(PBTypeList(),2,",")
    AddGadgetItem(#CB_PureTypes,-1,pbtype)
  Next
EndProcedure

;
;
;
Procedure Update_CTypeList()
  ClearGadgetItems(#LI_CTypeTable)
  GetDatabaseList(0,"CTypes",CTypeList())
  ForEach CTypeList()
    Add_Table(#LI_CTypeTable,CTypeList())
    AddGadgetItem(#CB_CTypes,-1,StringField(CTypeList(),2,","))
  Next
EndProcedure

;
;
;
Procedure Update_DefTypeList()
  ClearGadgetItems(#LI_DefTypeTable)
  GetDatabaseList(0,"UserTypesDef",DefTypeList())
  ForEach DefTypeList()
    Add_Table(#LI_DefTypeTable,DefTypeList())
  Next
EndProcedure

;-----------------------------------------------------------------------------
;- User Interface Procedure Calls
;-----------------------------------------------------------------------------

;
;
;
Procedure About(eventType)  
  aboutmsg.s        = "Programming: T.J.Roughton"+Chr(10)
  aboutmsg=aboutmsg + "GNU General Public License v3 (GPL-3)"+Chr(10)  
  aboutmsg=aboutmsg + "Version: 0.0.1a"  
  MessageRequester("About",aboutmsg)
EndProcedure

;
;
;
Procedure MainPanel(eventType)
  Select GetGadgetState(#MainPanel)
    Case #PANELTAB_PBTYPE
      HideGadget(#BT_Convert,#True)
    Case #PANELTAB_CTYPE
      HideGadget(#BT_Convert,#True)
    Case #PANELTAB_DEFTYPE
      HideGadget(#BT_Convert,#True)
    Case #PANELTAB_CONVERT
      HideGadget(#BT_Convert,#False)
  EndSelect  
EndProcedure

;
;
;
Procedure Save(filename.s="")
  ;
  If filename=""
    pattern.s = "Include File (*.pbi)|*.pbi;|All files (*.*)|*.*"  
    filename.s = SaveFileRequester("Import Header","",pattern,0)
  EndIf  
  ;
  If CreateFile(0,filename)
    lnmax = GOSCI_GetNumberOfLines(#SCI_CText)
    For i=0 To lnmax
      WriteStringN(0,GOSCI_GetLineText(#SCI_CText,i))
    Next
    CloseFile(0)
  EndIf  
EndProcedure

;
;
;
Procedure Open(filename.s="")
  Header_Import(filename)
EndProcedure

;
;
;
Procedure Delete(eventType)
  Select GetGadgetState(#MainPanel)
    Case #PANELTAB_PBTYPE
    Case #PANELTAB_CTYPE
    Case #PANELTAB_DEFTYPE
      For i=0 To CountGadgetItems(#LI_DefTypeTable)
        If GetGadgetItemState(#LI_DefTypeTable,i) = #PB_ListIcon_Selected 
          DeleteDatabaseRow(0,"UserTypesDef",GetGadgetItemData(#LI_DefTypeTable,i))
        EndIf        
      Next      
      Update_DefTypeList()
    Case #PANELTAB_CONVERT
  EndSelect  
EndProcedure

;
;
;
Procedure Insert(eventType) 
  Select GetGadgetState(#MainPanel)
    Case #PANELTAB_PBTYPE
    Case #PANELTAB_CTYPE
    Case #PANELTAB_DEFTYPE
      InsertDatabase_UserTypesDef(0,GetGadgetText(#ST_TypeDef),GetGadgetText(#CB_CTypes),GetGadgetText(#CB_PureTypes))
      Update_DefTypeList()
  EndSelect  
EndProcedure

;
;
;
Procedure Update(eventType) 
  Select GetGadgetState(#MainPanel)
    Case #PANELTAB_PBTYPE
    Case #PANELTAB_CTYPE
    Case #PANELTAB_DEFTYPE
  EndSelect  
EndProcedure

;
;
;
Procedure BlockUser(enable.b)
  For id=0 To 500
    If IsGadget(id)<>0
      DisableGadget(id,enable)
    EndIf    
  Next
EndProcedure

;
;
;
Procedure SaveConfig()
  If CreatePreferences("CTypeTable.cfg")
    PreferenceGroup("HeaderAssistant")
    For li=0 To CountGadgetItems(#LI_HASETTINGS)-1
      chk.s = "0"
      If GetGadgetItemState(#LI_HASETTINGS, li) & #PB_ListIcon_Checked
        chk.s = "1"
      EndIf        
      hasettings.s + chk
    Next    
    WritePreferenceString("Settings",hasettings)
    
    PreferenceGroup("ReservedWord")
    ForEach ResWords()
      WritePreferenceString("rword_"+Str(i),ResWords()\pbword+","+ResWords()\reword)
      i=i+1
    Next    
    ClosePreferences()
  EndIf  
EndProcedure

;
;
;
Procedure LoadConfig()
  If OpenPreferences("CTypeTable.cfg")
    PreferenceGroup("HeaderAssistant")
    hasettings.s = ReadPreferenceString("Settings","")
    For li=0 To Len(hasettings)-1
      ; well well. well, cannot just save value of GetGadgetItemState() must save as 1 or 0 and then SetGadgetItemState(#LI_HASETTINGS .... #PB_ListIcon_Checked) with the flag.
      ; based on 0 or 1.. weird quirk.
      chkstate = Val(Mid(hasettings,1+li,1))
      If chkstate=1 : SetGadgetItemState(#LI_HASETTINGS,li,#PB_ListIcon_Checked) : EndIf      
      If DebugGetID_LogLevel(Str(li))
        If chkstate=0 : DebugSetIDState_LogLevel(Str(li),#False) : EndIf          
        If chkstate=1 : DebugSetIDState_LogLevel(Str(li),#True) : EndIf          
      EndIf
    Next        
    PreferenceGroup("ReservedWord")    
    Repeat      
      wrd.s = ReadPreferenceString("rword_"+Str(i),"-1")
      i=i+1
      If wrd<>"-1"
        AddElement(ResWords())
        ResWords()\pbword=StringField(wrd,1,",")
        ResWords()\reword=StringField(wrd,2,",")
      EndIf      
    Until wrd="-1"        
    ClosePreferences()
  EndIf  
EndProcedure

;-----------------------------------------------------------------------------
;- Insert Code Blocks
;-----------------------------------------------------------------------------

;
;
;
Procedure Insert_AutoDllProcedureHeader(insline)
  ;<%PRJ>
  Restore autodll_procedure_header:
  rdline.s = ""
  Repeat
    Read.s rdline
    If rdline<>"--" : GOSCI_InsertLineOfText(#SCI_CText,insline+i,rdline) : EndIf
    i=i+1
  Until rdline = "--"
EndProcedure

;
;
;
Procedure Insert_AutoDllProcedureFooter(insline)
  Restore autodll_procedure_footer
  rdline.s = ""
  Repeat
    Read.s rdline
    If rdline<>"--" : GOSCI_InsertLineOfText(#SCI_CText,insline+i,rdline) : EndIf
    i=i+1
  Until rdline = "--"
EndProcedure

;-----------------------------------------------------------------------------
;- Task Operations
;-----------------------------------------------------------------------------

;
;
;
Procedure Callback_Scintilla_Translation(Gadget, *scinotify.SCNotification)
EndProcedure

;
; Attempt to convert the lines given into something usable by PB
;
Procedure Convert(eventType)
  StatusUpdate("Converting..")
  BlockUser(#True)
  convdonce.b = #True
  numLines = ScintillaSendMessage(#SCI_CText,#SCI_GETLINECOUNT)
  cFunc.Function
  ClearList(PTList())
    
  ;-Remove C PreProcessor
  StatusUpdate("C2PB_RemoveCPreProcessor")
  C2PB_RemoveCPreProcessor(#SCI_CText)
    
  ;-Enter Process Tasks Level 0 
  StatusUpdate("C2PB_ProcessTasks Level 0")
  C2PB_ProcessTasks(0)
    
  ;-General Processing
  StatusUpdate("C2PB_ProcessLines")
  For i = 0 To numLines
    C2PB_ProcessLine(#SCI_CText,i,numLines,GOSCI_GetLineText(#SCI_CText, i))
  Next
  
  ;-Function Processing
  StatusUpdate("Function Processing")
  For icurrent = 0 To numLines
    mark = ScintillaSendMessage(#SCI_CText,#SCI_MARKERGET,icurrent)
    If mark>0
      func.s = ""
      ClearStructure(cFunc,Function)
      nextmark = ScintillaSendMessage(#SCI_CText,#SCI_MARKERGET,icurrent+1)
      AddElement(PTList())
      If nextmark>2
        func = GOSCI_GetLineText(#SCI_CText,icurrent)
        Repeat
          icurrent=icurrent+1
          func = func + GOSCI_GetLineText(#SCI_CText,icurrent)
        Until ScintillaSendMessage(#SCI_CText,#SCI_MARKERGET,icurrent)=16
        ; multi line    
        DebugOut("Multi Line Source:"+func,#False,"Functions")
        proc.s = C2PB_FunctionToProtoType(func,cFunc)
        DebugOut("=="+proc,#False,"Functions")
        PTList()\proc = proc
      Else
        ; single line    
        func = GOSCI_GetLineText(#SCI_CText,icurrent)
        DebugOut("Single Line Source:"+func,#False,"Functions")
        proc.s = C2PB_FunctionToProtoType(func,cFunc)
        DebugOut("=="+proc,#False,"Functions") 
        PTList()\proc = proc
      EndIf
      getproc.s = cFunc\pb_getfunction
      PTList()\getproc = getproc
      DebugOut("=="+getproc,#False,"Functions")
      DebugOut("",#False,"Functions")
      GOSCI_SetLineText(#SCI_CText,icurrent,";"+func)
    EndIf
  Next
  
  ;nb: altough we've processed the functions at this point we've still not added the back to the document yet.
  ;    The problem is the marks will move if we add/remove lines and thus paste them back in the above for..next
  ;    loop real time will just make a mess, we can't detele the line either because of the previous forementioned
  ;    problem. 
  
  ;solution ?: 
  ;    keep the alterations as list of sources line numbers to be replaced and loop the lines again.
  DebugOut("--- PTList()",#False,"Functions")
  numLines = ScintillaSendMessage(#SCI_CText,#SCI_GETLINECOUNT)
  ForEach PTList()
    DebugOut(PTList()\proc,#False,"Functions")
    GOSCI_InsertLineOfText(#SCI_CText,numLines+ListIndex(PTList()),PTList()\proc)
  Next
  
  numLines = ScintillaSendMessage(#SCI_CText,#SCI_GETLINECOUNT)
  GOSCI_InsertLineOfText(#SCI_CText,numLines,"")
  
  Insert_AutoDllProcedureHeader(ScintillaSendMessage(#SCI_CText,#SCI_GETLINECOUNT))
  
  numLines = ScintillaSendMessage(#SCI_CText,#SCI_GETLINECOUNT)
  ForEach PTList()
    DebugOut(PTList()\getproc,#False,"Functions")
    GOSCI_InsertLineOfText(#SCI_CText,numLines+ListIndex(PTList()),Chr(9)+PTList()\getproc)
  Next  
  ClearList(PTList())
  
  Insert_AutoDllProcedureFooter(ScintillaSendMessage(#SCI_CText,#SCI_GETLINECOUNT))

  ;-Structure Processing
  ; StatusUpdate("Structure Processing")
  C2PB_StructToPB()
  
  ;-Exit Process Tasks Level 1
  StatusUpdate("C2PB_ProcessTasks Level 1")
  C2PB_ProcessTasks(1)
  
  
  ;-Complete
  Save("Tasks/"+current_hsourcefile+".pbi")
  StatusUpdate("Complete!")
  BlockUser(#False)
EndProcedure

;
;
;
Procedure Search(eventType)
;   
;   ClearList(SearchResults())
;   
;   If GetGadgetText(#ST_Search)=""
;     ClearGadgetItems(#LI_CTypeTable)
;     Load()
;     ProcedureReturn 
;   EndIf
;     
;   For r = 0 To CountGadgetItems(#LI_CTypeTable)-1
;     lnout.s = ""
;     For c = 0 To GetGadgetAttribute(#LI_CTypeTable,#PB_ListIcon_ColumnCount)-1
;       lnout + GetGadgetItemText(#LI_CTypeTable,r,c) + ","
;     Next
;     
;     fpos = FindString(lnout,GetGadgetText(#ST_Search))    
;     If fpos
;       AddElement(SearchResults())
;       SearchResults() = lnout
;     EndIf      
;   Next
;   
;   ClearGadgetItems(#LI_CTypeTable)  
;   ForEach SearchResults()
;     Add_CTypeTable(SearchResults())
;   Next
  
EndProcedure

;
; Search TypeDef
;
Procedure SearchTypeDef(*args.SearchTypeDefArgs,srctype.l)
   
  If srctype = #STD_PROCEDURE
    DebugOut("#STD_PROCEDURE / SearchTypeDef() name=["+*args\c_name+"] type=["+*args\c_type+"]")
    For i=0 To CountGadgetItems(#LI_DefTypeTable)-1
      deftype.s = GetGadgetItemText(#LI_DefTypeTable,i,0)    
      If deftype=*args\c_type
        pbtype.s = GetGadgetItemText(#LI_DefTypeTable,i,2)
        pbtype = Mid(pbtype,2,FindString(pbtype,")")-2)
        *args\pb_type = pbtype
      EndIf    
      If deftype=*args\c_name
        *args\c_name = Mid(pbtype,2,FindString(pbtype,")")-2) 
      EndIf    
    Next
  EndIf
  
  If srctype = #STD_STRUCTURE
    ;DebugOut("#STD_STRUCTURE / SearchTypeDef() name=["+*args\c_name+"] type=["+*args\c_type+"]",#False,"Struct")
    For i=0 To CountGadgetItems(#LI_DefTypeTable)-1
      deftype.s = GetGadgetItemText(#LI_DefTypeTable,i,0)    
      ;DebugOut("#STD_STRUCTURE / SearchTypeDef() Compare=["+deftype+"] with ["+*args\c_type+"]",#False,"Struct")
      If deftype=*args\c_type
        pbtype.s = GetGadgetItemText(#LI_DefTypeTable,i,2)
        pbtype = Mid(pbtype,2,FindString(pbtype,")")-2)
        *args\pb_type = pbtype
        Break
      EndIf    
    Next
    ;DebugOut("#STD_STRUCTURE / SearchTypeDef() name=["+*args\c_name+"] type=["+*args\c_type+"] pbtype="+*args\pb_type,#False,"Struct")
  EndIf  
EndProcedure

;
;
;
Procedure CustomLI_TaskEditCallback_ComboItem(Gadget.i, Line.i, Column.i, ComboBox.i)
	AddGadgetItem(ComboBox, -1, "Replace A->B")               ; -> C2Tasks.pbi
	AddGadgetItem(ComboBox, -1, "RegReplace")                 ; -> C2Tasks.pbi
	AddGadgetItem(ComboBox, -1, "Delete A")                   ; -> C2Tasks.pbi
	AddGadgetItem(ComboBox, -1, "Delete Line #")              ; -> C2Tasks.pbi
	AddGadgetItem(ComboBox, -1, "Replace A->Code Block")      ; -> C2CodeBlocks.pbi
	AddGadgetItem(ComboBox, -1, "Insert Code Block")          ; -> C2CodeBlocks.pbi
EndProcedure

;
;
;
Procedure CustomLI_TaskEditCallback_SelectMode(Gadget.i, Line.i, Column.i)	
	Select Gadget
		Case #LI_TASKS
			Select Column
				Case 0 : ProcedureReturn #LIG_EditGadget_ComboBox
				;Case 2 : ProcedureReturn #LIG_EditGadget_ComboBox_Editable
				;Case 5 : ProcedureReturn #LIG_EditGadget_Date
				;Case 6 : ProcedureReturn #LIG_EditGadget_DateTime
				Default : ProcedureReturn #LIG_EditGadget_EditBox
			EndSelect
	EndSelect	
EndProcedure

;
;
;
Procedure CustomLI_TaskEditCallback_YesNo(Gadget.i, Line.i, Column.i)
	;Debug "EditYesNoCallback >"+Str(Gadget)+"< Line >"+Str(Line)+"< Column >"+Str(Column)+"<"
EndProcedure

;
;
;
Procedure Clear_Tasks(eventType)
  ClearGadgetItems(#LI_TASKS)  
EndProcedure

;
;
;
Procedure Add_TaskList(Task.s="(Select)",ValueA.s="<value a>",ValueB.s="<value b>",Parms.s="Null",Order.s = "0")
  AddGadgetItem(#LI_TASKS, -1,Task+Chr(10)+ValueA+Chr(10)+ValueB+Chr(10)+Parms+Chr(10)+Order)
EndProcedure

;
;
;
Procedure Add_Task(eventType)
  Add_TaskList()
EndProcedure

;
;
;
Procedure Delete_Task(eventType)  
  RemoveGadgetItem(#LI_TASKS,LIG_GetGadgetState(#LI_TASKS))  
EndProcedure

; -
; Save Tasks to perform on .h file
; Notes: the way i've written this code may appear a little strange, a guide to the philosophy is to push all code that has
; a function to perform also houses the macros to write/read preference data, making Open/Save_TaskList() in this case
; smaller and easier to read the follow and order.
; -
Procedure Save_TaskList(eventType)   
  pattern.s = "INI File (*.ini)|*.ini;|All files (*.*)|*.*"  
  file.s = SaveFileRequester("Save TaskList","",pattern,0)
  If file<>""
    If CreatePreferences(file)
      C2Tasks_WritePreferenceTasks            ; -> C2Tasks.pbi as a Macro
      
      PreferenceGroup("MarkedProcedures")
      C2Tasks_WritePreferenceMarkers          ; -> C2Tasks.pbi as a Macro
      
      PreferenceGroup("CodeBlocks")
      C2CodeBlocks_WritePreference            ; -> C2CodeBlocks.pbi as a Macro
      
      ClosePreferences()
    EndIf    
  EndIf  
EndProcedure

;
;
;
Procedure Open_TaskList(file.s="")
  If file=""
    pattern.s = "INI File (*.ini)|*.ini;|All files (*.*)|*.*"  
    file = OpenFileRequester("Open TaskList","",pattern,0)
  EndIf
  If file<>""
    ClearGadgetItems(#LI_TASKS)
    If OpenPreferences(file)
      C2Tasks_ReadPreferenceTasks
      
      PreferenceGroup("MarkedProcedures")
      C2Tasks_ReadPreferenceMarkers
      
      PreferenceGroup("CodeBlocks")
      C2CodeBlocks_ReadPreference
      
      ClosePreferences()
    EndIf
  EndIf  
EndProcedure

;
;
;
Procedure.s Get_TasksDetails(idx.l,value.l=0)
  For row = 0 To CountGadgetItems(#LI_TASKS)    
    If row = idx 
      ProcedureReturn GetGadgetItemText(#LI_TASKS, row, value)
    EndIf      
  Next  
EndProcedure

;
;
;
Procedure Help_Task(eventType)
  MessageRequester("Information","pre-Replace A->B : "+Chr(10)+
                                 "pre-Delete A : "+Chr(10)+
                                 
                                 "peri-Replace A->B : "+Chr(10)+
                                 "peri-Delete A : "+Chr(10)+
       
                                 "post-Replace A->B : "+Chr(10)+
                                 "post-Delete A : ")
EndProcedure

;- Import

;
;
;
Procedure Header_Import(file.s="")
  If file=""
    pattern.s = "Header File (*.h)|*.h;|All files (*.*)|*.*"  
    file.s = OpenFileRequester("Import Header","",pattern,0)
  EndIf  
  If file<>""
    current_hsourcefile = GetFilePart(file)
    GOSCI_Clear(#SCI_CText)
    GOSCI_LoadText(#SCI_CText,file)
    taskfile.s = "Tasks/"+GetFilePart(file)+".ini"
    If FileSize(taskfile)
      Open_TaskList(taskfile)  
    EndIf    
  EndIf  
EndProcedure

;
;
;
Procedure UnMarkProc(eventType)
  currentln = GOSCI_GetState(#SCI_CText,#GOSCI_CURRENTLINE)  
  lnmax = GOSCI_GetNumberOfLines(#SCI_CText)  
  If ScintillaSendMessage(#SCI_CText, #SCI_MARKERGET, currentln ) = 2
    irmln = currentln
    While ScintillaSendMessage(#SCI_CText,#SCI_MARKERGET,irmln)>0
      If ScintillaSendMessage(#SCI_CText,#SCI_MARKERGET,irmln) = 2
        cpls=cpls+1
        If cpls = 2 : Break : EndIf
      EndIf      
      GOSCI_SetLineBookmark(#SCI_CText,irmln,#False,#MARK_CIRCLEPLUS)    
      GOSCI_SetLineBookmark(#SCI_CText,irmln,#False,#MARK_VLINE)    
      GOSCI_SetLineBookmark(#SCI_CText,irmln,#False,#MARK_CURVELINE)      
      irmln=irmln+1      
    Wend
  EndIf  
EndProcedure

;
;
;
Procedure MarkProcStart(eventType)
  currentln = GOSCI_GetState(#SCI_CText,#GOSCI_CURRENTLINE)
  GOSCI_SetLineBookmark(#SCI_CText,currentln,#True,#MARK_CIRCLEPLUS)
EndProcedure

;
;
;
Procedure MarkProcEnd(eventType) 
  currentln = GOSCI_GetState(#SCI_CText,#GOSCI_CURRENTLINE)
  prevmarker = ScintillaSendMessage(#SCI_CText, #SCI_MARKERPREVIOUS, currentln, %000000001)
  
  If ScintillaSendMessage(#SCI_CText, #SCI_MARKERGET, currentln ) = 0 
    prevmarker = ScintillaSendMessage(#SCI_CText, #SCI_MARKERPREVIOUS, currentln, 2 )
    If prevmarker<>-1
      For ln=1+prevmarker To currentln-1
        GOSCI_SetLineBookmark(#SCI_CText,ln,#True,#MARK_VLINE)
      Next
      GOSCI_SetLineBookmark(#SCI_CText,currentln,#True,#MARK_CURVELINE)
    EndIf
  EndIf
EndProcedure

;-----------------------------------------------------------------------------
;-Code Blocks
;-----------------------------------------------------------------------------

;
;
;
Procedure Update_TagCodeBlocks()
  ForEach cblist()    
    AddGadgetItem(#CBE_TagCodeBlocks,-1,MapKey(cblist()))
  Next
EndProcedure
  
;-----------------------------------------------------------------------------
;-Setup Main Window Events
;-----------------------------------------------------------------------------

;
;
;
Procedure HasSettings_Update()
  selectionidx = GetGadgetState(#LI_HASETTINGS)
  If GetGadgetItemState(#LI_HASETTINGS,selectionidx) & #PB_ListIcon_Checked
    DebugSetIDState_LogLevel(Str(selectionidx),#True)
  Else
    DebugSetIDState_LogLevel(Str(selectionidx),#False)
  EndIf
EndProcedure

;
;
;
Procedure SetupMainWindow()   
  Update_PBTypeList()
  Update_CTypeList()
  Update_DefTypeList()
  
  SetGadgetState(#CB_PureTypes,0)
  SetGadgetState(#CB_CTypes,0)
  SetGadgetText(#ST_Search,lnselected)    
  StatusBarText(0,1,default_database)
  
  ; Scintilla Setup
  ; ScintillaSendMessage(#SCI_CText,#SCI_SETMARGINS,0)
  GOSCI_SetColor(#SCI_CText,#GOSCI_LINENUMBERBACKCOLOR,RGB(0,0,0))  
  ScintillaSendMessage(#SCI_CText,#SCI_MARKERDEFINE,#MARK_CIRCLEPLUS,#SC_MARK_CIRCLEPLUS)  
  ScintillaSendMessage(#SCI_CText,#SCI_MARKERDEFINE,#MARK_VLINE,#SC_MARK_VLINE) 
  ScintillaSendMessage(#SCI_CText,#SCI_MARKERDEFINE,#MARK_CURVELINE,#SC_MARK_LCORNERCURVE) 
  
  ; Editable ListIconGadet Setup
  LIG_EnableAddon(#LI_TASKS, #LIG_MouseEdit|#LIG_CursorEdit)
  LIG_Edit_SetCallback(#LI_TASKS, #LIG_Callback_GadgetType, @CustomLI_TaskEditCallback_SelectMode())
  LIG_Edit_SetCallback(#LI_TASKS, #LIG_Callback_ComboItem, @CustomLI_TaskEditCallback_ComboItem())  
  ;LIG_Edit_SetCallback(#LI_TASKS, #LIG_Callback_EditYesNo, @CustomLI_TaskEditCallback_YesNo())
  LIG_EnableEditSetting(#LI_TASKS, #LIG_EditSetting_ApplyOnExit|#LIG_EditSetting_AllowCtrlC|#LIG_EditSetting_AllowCtrlV)
  
  ;- needs configuring
  DebugAdd_LogLevel("6","All","All Debug Log"                                    ,"Enable/Disable all log file output (overrides)",#True)
  DebugAdd_LogLevel("7","GarbageCollector","Log Garbage Collector"               ,"Enable/Disable Garbage Collector log file output",#True)
  DebugAdd_LogLevel("8","C2PB_ProcessTasksLevel0","Log C2PB_ProcessTasks Level 0","Enable/Disable C2PB_ProcessTasks Level 0 log file output",#True)
  DebugAdd_LogLevel("9","C2PB_ProcessTasksLevel1","Log C2PB_ProcessTasks Level 1","Enable/Disable C2PB_ProcessTasks Level 1 log file output",#True)
  DebugAdd_LogLevel("10","ProcessLines","Log Process Lines"                      ,"Enable/Disable Process Lines log file output",#True)
  DebugAdd_LogLevel("11","Functions","Log Functions"                             ,"Enable/Disable Functions log file output",#True)
  DebugAdd_LogLevel("12","Struct","Log Struct"                                   ,"Enable/Disable Struct log file output",#True)
  DebugAdd_LogLevel("13","Define","Log Define"                                   ,"Enable/Disable Define log file output",#True)
  DebugAdd_LogLevel("14","Enumeration","Log Enumeration"                         ,"Enable/Disable Enumeration log file output",#True)
  DebugAdd_LogLevel("15","Comments","Log Comments"                               ,"Enable/Disable Comments log file output",#True)
  DebugAdd_LogLevel("16","Tasks","Log Task"                                      ,"Enable/Disable Task log file output",#True)  
  DebugAdd_LogLevel("17","DataBase","Log Database"                               ,"Enable/Disable Database log file output",#True)  
  
  DebugClear()
  
  Restore headerass_settings
  id.s="" : tagname.s="" : name.s="" : desc.s=""
  Read.s id : Read.s tagname : Read.s name : Read.s desc
  While name<>"--"
    If id<>"{{DEBUGGER}}"
      AddGadgetItem(#LI_HASETTINGS,-1,name+Chr(10)+desc)
    Else
      ForEach stddebugloglevel()
        AddGadgetItem(#LI_HASETTINGS,-1,stddebugloglevel()\shortdescription+Chr(10)+stddebugloglevel()\longdescription)
      Next
    EndIf
    Read.s id : Read.s tagname : Read.s name : Read.s desc
  Wend
  
  Update_TagCodeBlocks()
  
  MainPanel(eventType)
EndProcedure

;
;-[design in progress]
;
Procedure ProgArgs()  
  For i = 0 To CountProgramParameters()
    Select ProgramParameter(i)
      Case "-ui"
      Case "-s"
        search.s = ProgramParameter(i+1)
        lnselected.s = ReadSelection(search)
      Case "-c"
        convert.s = ProgramParameter(i+1)
        PrintN(convert)
    EndSelect
  Next  
EndProcedure

;
;
;
Procedure MainWindow_Events(event)
  Select event
    Case #PB_Event_CloseWindow
      ProcedureReturn event

    Case #PB_Event_Menu
      Select EventMenu()
        Case #MenuItem_2
          CreateFile_Database(EventMenu())
        Case #MenuItem_3
          Open()          
        Case #MenuItem_4
          Save()
        Case #MenuItem_5
        Case #MenuItem_6
          Header_Import()
        Case #MenuItem_7
          About(EventMenu())
        Case #MenuItem_9
      EndSelect

    Case #PB_Event_Gadget
      Select EventGadget()
        Case #LI_TASKS
          SetGadgetText(#ST_PRAMDETAILS,C2Tasks_GetPramDetails(Get_TasksDetails(LIG_GetGadgetState(#LI_TASKS),#TASK_TYPE)))
        Case #BT_Delete
          Delete(EventType())          
        Case #BT_Insert
          Insert(EventType())          
        Case #BT_Search
          Search(EventType())          
        Case #MainPanel
          MainPanel(EventType())          
        Case #BT_Convert
          Convert(EventType())          
        Case #BTI_AddTask
          Add_Task(EventType())          
        Case #BTI_DeleteTask
          Delete_Task(EventType())          
        Case #BTI_SAVETASK
          Save_TaskList(EventType())          
        Case #BTI_LOADTASK
          Open_TaskList()          
        Case #BTI_TaskHelp
          Help_Task(EventType())          
        Case #BTI_ClearTasks
          Clear_Tasks(EventType())
        Case #BT_MARKPROCSTART
          MarkProcStart(EventType())
        Case #BT_MARKPROCEND
          MarkProcEnd(EventType())
        Case #BT_UNMARKPROC
          UnMarkProc(EventType())        
        Case #BT_Update
          Update(EventType())
        Case #LI_HASETTINGS
          HasSettings_Update()
        Case #BTI_AddTask_CodeBlock_Update
          C2CodeBlock_Update(GetGadgetText(#CBE_TagCodeBlocks))
        Case #BTI_AddTask_CodeBlock_View
          GOSCI_Clear(#SCI_CodeBlocksText)
          C2CodeBlock_View(#SCI_CodeBlocksText,GetGadgetText(#CBE_TagCodeBlocks))          
        Case #CBE_TagCodeBlocks
          ;it's not a good idea updating the SCI text box here --> use a button.
        Case #BTI_AddTask_CodeBlock
          C2CodeBlock_Add(GetGadgetText(#CBE_TagCodeBlocks))
          ClearGadgetItems(#CBE_TagCodeBlocks)
          Update_TagCodeBlocks()
        Case #BTI_DeleteTask_CodeBlock
          C2CodeBlock_Delete(GetGadgetText(#CBE_TagCodeBlocks))
          ClearGadgetItems(#CBE_TagCodeBlocks)
          Update_TagCodeBlocks()
      EndSelect
  EndSelect
  ProcedureReturn event
EndProcedure

;
; Begin
;
DebugInit()

ProgArgs()

If OpenDatabase(0,default_database,"","")
EndIf

OpenMainWindow()
SetupMainWindow()
LoadConfig()

;Header_Import("D:\Work\Code\SDK\ZingZong\src\zz_private.h")
Open("D:\Work\Code\SDK\ZingZong\src\zingzong.h")

Repeat 
  event = MainWindow_Events(WaitWindowEvent())
Until event = #PB_Event_CloseWindow

;
; Exit
;
If IsDatabase(0)
  CloseDatabase(0)
EndIf

SaveConfig()

End

DataSection
  headerass_settings:
  Data.s "","","Garbage Collector"                                    ,"Removes C pre-processor statements & deletes ;"
  Data.s "","","C2PB_ProcessTasks Level 0"                            ,"Enable/Disable Tasks Level 0"
  Data.s "","","C2PB_ProcessTasks Level 1"                            ,"Enable/Disable Tasks Level 1"
  Data.s "","","Process Lines"                                        ,"?"
  Data.s "","","C Functions to PB"                                    ,"?"
  Data.s "","","C Struct to PB"                                       ,"?"
  Data.s "{{DEBUGGER}}","","",""
  Data.s "","","AutoDoc Header"                                       ,"Enable/Disable Basic Documenation"  
  Data.s "","","AutoDoc Procedure"                                    ,"Enable/Disable Basic Documenation"  
  Data.s "--","--","--"
  autodoc_header:
  Data.s "--"
  autodoc_procedure:
  Data.s ";/****** <name>.dll/<procedurename> *******************************"
  Data.s ";*" 
  Data.s ";*   NAME"
  Data.s ";* 	 <procedurename> -- <Description>"
  Data.s ";*"
  Data.s ";*   SYNOPSIS"
  Data.s ";*	 int8 error = <procedurename>(<arguments>)"
  Data.s ";*"
  Data.s ";*   FUNCTION"
  Data.s ";*"
  Data.s ";*   INPUTS"
  Data.s ";* 	 name -"
  Data.s ";*"	
  Data.s ";*   RESULT"
  Data.s ";* 	 result -" 
  Data.s ";*" 
  Data.s ";*/"
  Data.s "--"
  autodll_procedure_header:
  Data.s "Procedure.l <%PRJ>_OpenLibrary(library.s)"
  Data.s "  dll = OpenLibrary(#PB_Any,library)"
  Data.s "  If dll_plugin"
  Data.s "--"
  autodll_procedure_footer:
  Data.s "  Else"
  Data.s "    ProcedureReturn #False"
  Data.s "  EndIf"
  Data.s "  ProcedureReturn dll_plugin"
  Data.s "EndProcedure"
  Data.s "--"

EndDataSection

; IDE Options = PureBasic 6.03 LTS (Windows - x86)
; CursorPosition = 54
; FirstLine = 36
; Folding = AIAQgJu-
; Markers = 504
; EnableXP
; DPIAware
; Executable = CTypeTable.exe
; CompileSourceDirectory
;
;
;
UseSQLiteDatabase()

;
; Declare
;
Declare Callback_Scintilla_Translation(Gadget, *scinotify.SCNotification)
Declare DebugOut(string.s,clearlog.b=#False,loglevel.s="")

Declare.s Get_TasksDetails(idx.l,value.l=0)

;
; Includes
;
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
Declare SearchTypeDef(*args.SearchTypeDefArgs)

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

Global lnselected.s
Global convdonce.b = #True

;
; My System Includes
;
IncludeFile "ListIconGadgetInclude.pbi"
IncludeFile "DataBase.pbi"
IncludeFile "C2Tasks.pbi"
IncludeFile "C2PureBasic.pbi"

Global default_database.s = "default.sqlite"

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

;  6 Data.s "All Debug Log"                ,"Enable/Disable all log file output (overrides)"
;  7 Data.s "Log Garbage Collector"        ,"Enable/Disable Garbage Collector log file output"
;  8 Data.s "Log C2PB_ProcessTasks Level 0","Enable/Disable C2PB_ProcessTasks Level 0 log file output"
;  9 Data.s "Log C2PB_ProcessTasks Level 1","Enable/Disable C2PB_ProcessTasks Level 1 log file output"
; 10 Data.s "Log Process Lines"            ,"Enable/Disable Process Lines log file output"
; 11 Data.s "Log Functions"                ,"Enable/Disable Functions log file output"
; 12 Data.s "Log Struct"                   ,"Enable/Disable Struct log file output"
; 13 Data.s "Log Define"                   ,"Enable/Disable Define log file output"
;
Procedure DebugOut(string.s,clearlog.b = #False,loglevel.s="")
  debugenable = #False
  
  If clearlog = #True
    DeleteFile("pb-ctypetable.log")
    ProcedureReturn 
  EndIf
  
  Select loglevel
    Case "GarbageCollector" : If GetGadgetItemState(#LI_HASETTINGS,7) = #PB_ListIcon_Checked : debugenable = #True : EndIf      
    Case "C2PB_ProcessTasksLevel0" : If GetGadgetItemState(#LI_HASETTINGS,8) = #PB_ListIcon_Checked : debugenable = #True : EndIf      
    Case "C2PB_ProcessTasksLevel1" : If GetGadgetItemState(#LI_HASETTINGS,9) = #PB_ListIcon_Checked : debugenable = #True :  EndIf      
    Case "ProcessLines" : If GetGadgetItemState(#LI_HASETTINGS,10) = #PB_ListIcon_Checked : debugenable = #True : EndIf      
    Case "Functions" : If GetGadgetItemState(#LI_HASETTINGS,11) = #PB_ListIcon_Checked : debugenable = #True : EndIf      
    Case "Struct" : If GetGadgetItemState(#LI_HASETTINGS,12) = #PB_ListIcon_Checked : debugenable = #True : EndIf      
    Case "Define" : If GetGadgetItemState(#LI_HASETTINGS,13) = #PB_ListIcon_Checked : debugenable = #True : EndIf      
  EndSelect
    
  If GetGadgetItemState(#LI_HASETTINGS,6) = #PB_ListIcon_Checked                ;"All Debug Log"
    debugenable = #True
  EndIf
  
  If debugenable = #True
    ofh = OpenFile(#PB_Any,"pb-ctypetable.log")
    If ofh
      WindowEvent()
      outstring.s = "["+FormatDate("%hh:%ii:%ss", Date())+"] [Debug] "+string    
      FileSeek(ofh,Lof(ofh))
      WriteStringN(ofh,outstring)
      CloseFile(ofh)
    EndIf  
  EndIf  
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
Procedure Save(eventType)   
EndProcedure

;
;
;
Procedure Open(eventType)   
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
  DisableGadget(#BT_Convert,#True)
  convdonce.b = #True
  numLines = ScintillaSendMessage(#SCI_CText,#SCI_GETLINECOUNT)
  cFunc.Function
  ClearList(PTList())
  
  ;-Garbadge Collection
  StatusUpdate("Garbadge Collection..")
  C2PB_GarbadgeCollection(#SCI_CText)
  
  ;-Process Tasks Level 0 
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
        DebugOut("Multi Line Source:"+func)
        proc.s = C2PB_FunctionToProtoType(func,cFunc)
        DebugOut("=="+proc)
        PTList()\proc = proc
      Else
        ; single line    
        func = GOSCI_GetLineText(#SCI_CText,icurrent)
        DebugOut("Single Line Source:"+func)
        proc.s = C2PB_FunctionToProtoType(func,cFunc)
        DebugOut("=="+proc) 
        PTList()\proc = proc
      EndIf
      getproc.s = cFunc\pb_getfunction
      PTList()\getproc = getproc
      DebugOut("=="+getproc)
      DebugOut("")        
    EndIf
  Next
  
  ;nb: altough we've processed the functions at this point we've still not added the back to the document yet.
  ;    The problem is the marks will move if we add/remove lines and thus paste them back in the above for..next
  ;    loop real time will just make a mess, we can't detele the line either because of the previous forementioned
  ;    problem. 
  
  ;solution ?: 
  ;    keep the alterations as list of sources line numbers to be replaced and loop the lines again.
  ForEach PTList()
    Debug PTList()\proc
    Debug PTList()\getproc
  Next
  ClearList(PTList())
  
  ;-Structure Processing
  StatusUpdate("Structure Processing")
  
  
  
  
  ;-Process Tasks Level 1
  StatusUpdate("C2PB_ProcessTasks Level 1")
  C2PB_ProcessTasks(1)
  
  
  ;-Complete
  StatusUpdate("Complete!")
  DisableGadget(#BT_Convert,#False)
  
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
Procedure SearchTypeDef(*args.SearchTypeDefArgs)
  r.s = "!"
  
  DebugOut("SearchTypeDef() name=["+*args\c_name+"] type=["+*args\c_type+"]")
  
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
  
EndProcedure

;
;
;
Procedure CustomLI_TaskEditCallback_ComboItem(Gadget.i, Line.i, Column.i, ComboBox.i)
	AddGadgetItem(ComboBox, -1, "Replace A->B") 
	AddGadgetItem(ComboBox, -1, "RegReplace") 
	AddGadgetItem(ComboBox, -1, "Delete A") 
	AddGadgetItem(ComboBox, -1, "Delete Line #") 
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
	Debug "EditYesNoCallback >"+Str(Gadget)+"< Line >"+Str(Line)+"< Column >"+Str(Column)+"<"
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

Procedure Add_Task(eventType)
  Add_TaskList()
EndProcedure

;
;
;
Procedure Delete_Task(eventType)  
  RemoveGadgetItem(#LI_TASKS,LIG_GetGadgetState(#LI_TASKS))  
EndProcedure

;
;
;
Procedure Save_TaskList(eventType)   
  pattern.s = "INI File (*.ini)|*.ini;|All files (*.*)|*.*"  
  file.s = SaveFileRequester("Save TaskList","",pattern,0)
  If file<>""
    If CreatePreferences(file)  
      For row = 0 To CountGadgetItems(#LI_TASKS)    
        PreferenceGroup("Task_"+Str(row))
        For column = 0 To 4
          WritePreferenceString("Pram_"+Str(column),GetGadgetItemText(#LI_TASKS, row, column))          
        Next    
      Next
      PreferenceGroup("MarkedProcedures")
      markers.s=""
      lnmax = GOSCI_GetNumberOfLines(#SCI_CText)
      For iln = 0 To lnmax
        cmarker = ScintillaSendMessage(#SCI_CText,#SCI_MARKERGET,iln)
        If cmarker<0 : cmarker=0 : EndIf
        markers + Str(cmarker) + ","
      Next     
      WritePreferenceString("ProcMakers",markers)
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
      While PreferenceGroup("Task_"+Str(row)) <> 0
        Task.s = ReadPreferenceString("Pram_0","")
        ValueA.s = ReadPreferenceString("Pram_1","")
        ValueB.s = ReadPreferenceString("Pram_2","")
        Parm.s = ReadPreferenceString("Pram_3","")
        Order.s = ReadPreferenceString("Pram_4","")
        Add_TaskList(Task,ValueA,ValueB,Parm,Order)
        row=row+1
      Wend
      PreferenceGroup("MarkedProcedures")
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
;- 
;-----------------------------------------------------------------------------


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
  
  Restore headerass_settings
  Read.s name.s
  Read.s desc.s
  While name<>"--"
    AddGadgetItem(#LI_HASETTINGS,-1,name+Chr(10)+desc)
    Read.s name.s
    Read.s desc.s
  Wend
  
  
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
          Open(EventMenu())          
        Case #MenuItem_4
          Save(EventMenu())
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
      EndSelect
  EndSelect
  ProcedureReturn event
EndProcedure

;
; Begin
;
ProgArgs()

DebugOut("",#True)

If OpenDatabase(0,default_database,"","")
EndIf

OpenMainWindow()
SetupMainWindow()

;Header_Import("D:\Work\Code\SDK\ZingZong\src\zz_private.h")
Header_Import("D:\Work\Code\SDK\ZingZong\src\zingzong.h")

;Debug PeekS(*textbuffer,-1,#PB_Ascii)

Repeat 
  event = MainWindow_Events(WaitWindowEvent())
Until event = #PB_Event_CloseWindow

;
; Exit
;
If IsDatabase(0)
  CloseDatabase(0)
EndIf

End

DataSection
  headerass_settings:
  Data.s "Garbage Collector"            ,"Removes C pre-processor statements & deletes ;"
  Data.s "C2PB_ProcessTasks Level 0"    ,"Enable/Disable Tasks Level 0"
  Data.s "C2PB_ProcessTasks Level 1"    ,"Enable/Disable Tasks Level 1"
  Data.s "Process Lines"                ,"?"
  Data.s "C Functions to PB"            ,"?"
  Data.s "C Struct to PB"               ,"?"
  Data.s "All Debug Log"                ,"Enable/Disable all log file output (overrides)"
  Data.s "Log Garbage Collector"        ,"Enable/Disable Garbage Collector log file output"
  Data.s "Log C2PB_ProcessTasks Level 0","Enable/Disable C2PB_ProcessTasks Level 0 log file output"
  Data.s "Log C2PB_ProcessTasks Level 1","Enable/Disable C2PB_ProcessTasks Level 1 log file output"
  Data.s "Log Process Lines"            ,"Enable/Disable Process Lines log file output"
  Data.s "Log Functions"                ,"Enable/Disable Functions log file output"
  Data.s "Log Struct"                   ,"Enable/Disable Struct log file output"
  Data.s "Log Define"                   ,"Enable/Disable Define log file output"
  Data.s "AutoDoc Header"               ,"Enable/Disable Basic Documenation"  
  Data.s "AutoDoc Procedure"            ,"Enable/Disable Basic Documenation"  
  Data.s "--","--"
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
     
EndDataSection

; IDE Options = PureBasic 6.03 LTS (Windows - x86)
; CursorPosition = 153
; FirstLine = 104
; Folding = +------
; EnableXP
; DPIAware
; Executable = CTypeTable.exe
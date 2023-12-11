;
;
;
UseSQLiteDatabase()
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
EndEnumeration

;
; Types & Lists
;
Structure Type
  BasicTypeID.b
  CType.s
EndStructure

Global NewList TypeList.Type()
Global NewList SearchResults.s()

;

Global NewList PBTypeList.s()
Global NewList CTypeList.s()
Global NewList DefTypeList.s()

Global lnselected.s

;
; DataBase
;
IncludeFile "DataBase.pbi"
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

;
;
;
Procedure Add_Table(gadgetid.l,addln.s = "") ; #LI_CTypeTable
  uniqueid = Val(StringField(addln,1,","))  
  addln = RemoveString(addln,StringField(addln,1,",")+",")
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
    AddGadgetItem(#CB_PureTypes,-1,StringField(PBTypeList(),2,","))
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

;
;
;
Procedure Save(eventType)   
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
        ;Debug "GetGadgetItemData = "+Str(GetGadgetItemData(#LI_DefTypeTable,i))          
        If GetGadgetItemState(#LI_DefTypeTable,i) = #PB_ListIcon_Selected 
          DeleteDatabaseRow(0,"UserTypesDef",GetGadgetItemData(#LI_DefTypeTable,i))
        EndIf        
      Next      
      DEBUG_Show_UserTypesDef()
      Update_DefTypeList()
  EndSelect  
  ;
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
; Begin
;
ProgArgs()

If OpenDatabase(0,default_database,"","")
EndIf

OpenMainWindow()
SetupMainWindow()

Repeat 
  event = MainWindow_Events(WaitWindowEvent())
Until event = #False

;
; Exit
;
If IsDatabase(0)
  CloseDatabase(0)
EndIf

End

; IDE Options = PureBasic 6.03 LTS (Windows - x86)
; CursorPosition = 202
; FirstLine = 149
; Folding = +-
; EnableXP
; DPIAware
; Executable = CTypeTable.exe
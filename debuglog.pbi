; Author: T.J.Roughton
; File: debuglog.pbi
; Description: For Debugging by File Output 
; Version: 1.0
; Licence: Dilligaf

#DEBUG_DEBUGGEROUT = #False

Structure STD_DEBUG_SETTINGS
  outfolder.s                       ; Output Folder
  outfilename.s                     ; Output File
  enabledate.b                      ; Enable Date/Time
  initclear.b                       ; Delete Log File at start.
  splitfileloglevel.b               ; Splits logfiles out by loglevel.
EndStructure

Global stddebug.STD_DEBUG_SETTINGS
stddebug\outfolder = "Logs/"
stddebug\outfilename = "pb-debugtest"
stddebug\enabledate = #True
stddebug\initclear = #True
stddebug\splitfileloglevel = #True

Structure STD_DEBUG_LOGLEVEL
  id.s                              ; id useful for lists and such.
  tagname.s                         ; tagname short quick name, must be stated as it defines the loglevel.
  shortdescription.s                ; Short description of log level
  longdescription.s                 ; Long description of log level
  enabled.b                         ; Log level enabled or not.
EndStructure
Global NewList stddebugloglevel.STD_DEBUG_LOGLEVEL()

; -
; DebugInit() 
; Sets up the debug, eg. does the folder exists etc.
; -
Procedure DebugInit()
  If stddebug\outfolder="" : ProcedureReturn : EndIf ; We're writting to root folder.
  If ExamineDirectory(0,stddebug\outfolder,"*.*")
    FinishDirectory(0)
  Else
    CreateDirectory(stddebug\outfolder)
    DebugInit()
  EndIf  
EndProcedure

; -
; DebugClear() 
; Use to output debug information to a file, based on settings.
; -
Procedure DebugClear()
  DeleteFile(stddebug\outfolder+stddebug\outfilename+".log")
  Debug "Deleting Log:"+stddebug\outfolder+stddebug\outfilename+".log"
  ForEach stddebugloglevel()
    DeleteFile(stddebug\outfolder+stddebug\outfilename+"."+stddebugloglevel()\tagname+".log")
    Debug "Deleting Log:"+stddebug\outfolder+stddebug\outfilename+"."+stddebugloglevel()\tagname+".log"
  Next  
EndProcedure

;-
; DebugFind_TagNameState()
; Finds the state of a given tagname
;-
Procedure.b DebugFind_TagNameState(tag.s)
  ForEach stddebugloglevel()
    If stddebugloglevel()\tagname = tag
      ProcedureReturn stddebugloglevel()\enabled
    EndIf    
  Next
  ProcedureReturn #False
EndProcedure
  
; -
; DebugWrite() 
; Does the actual writting
; -
Procedure DebugWrite(string.s,splittag.s)
  date.s = ""
  
  ofh = OpenFile(#PB_Any,stddebug\outfolder+stddebug\outfilename+splittag+".log")
  If ofh
    If stddebug\enabledate=#True
      date = "["+FormatDate("%hh:%ii:%ss", Date())+"]"
    EndIf        
    outstring.s = date + "["+loglevel+"] "+string    
    FileSeek(ofh,Lof(ofh))
    WriteStringN(ofh,outstring)
    CloseFile(ofh)
  Else
    Debug("Failed to Create: "+stddebug\outfolder+stddebug\outfilename+splittag+".log")
  EndIf  
EndProcedure

; -
; DebugOut() 
; Use to output debug information to a file, based on settings.
; -
Procedure DebugOut(string.s,clearlog.b = #False,loglevel.s="")
  If clearlog = #True : DebugClear() : ProcedureReturn : EndIf  

  splittag.s = ""
  debugallstate.b = DebugFind_TagNameState("All")
  
  If debugallstate = #False
    ForEach stddebugloglevel()
      ; Are we debuging all or loglevel?
      ; if loglevel is defined we do the following
      If stddebugloglevel()\enabled=#True And loglevel=stddebugloglevel()\tagname
        If stddebug\splitfileloglevel=#True
          splittag = "."+loglevel
        EndIf      
        DebugWrite(string,splittag)
      EndIf
    Next
  EndIf
  
  ; if we are just spewing everything then ignore loglevel except for the if split is enabled.
  If debugallstate = #True
    If stddebug\splitfileloglevel=#True
      splittag = "."+loglevel
    EndIf      
    DebugWrite(string,splittag)
  EndIf        

EndProcedure

; -
;   Output Debug Log Level Details
; - 
Procedure DebugDump_LogLevel()
  Debug("--DebugDump_LogLevel()")
  ForEach stddebugloglevel()
    Debug("---------------------------------------------------------------------------------")
    Debug("\id = "+stddebugloglevel()\id)
    Debug("\tagname = "+stddebugloglevel()\tagname)
    Debug("\shortdescription = "+stddebugloglevel()\shortdescription)
    Debug("\longdescription = "+stddebugloglevel()\longdescription)
    If stddebugloglevel()\enabled = #False
      Debug("\enabled = #False")
    Else
      Debug("\enabled = #True")
    EndIf    
  Next  
EndProcedure

; -
;   Add LogLevel
; -
Procedure DebugAdd_LogLevel(id.s,tagname.s,shortdescription.s,longdescription.s,enabled.b)
  AddElement(stddebugloglevel())  
  stddebugloglevel()\id = id
  stddebugloglevel()\tagname = tagname
  stddebugloglevel()\shortdescription = shortdescription
  stddebugloglevel()\longdescription = longdescription
  stddebugloglevel()\enabled = enabled
EndProcedure

; -
;   DebugGetID sets the list position to the given id
; -
Procedure.b DebugGetID_LogLevel(id.s)
  ForEach stddebugloglevel()
    If stddebugloglevel()\id = id
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
EndProcedure

; -
;   DebugSetIDState sets the list position to the given id
; -
Procedure DebugSetIDState_LogLevel(id.s,state.b)
  ForEach stddebugloglevel()
    If stddebugloglevel()\id = id
      stddebugloglevel()\enabled = state
      Break
    EndIf
  Next    
EndProcedure

; -
;   DebugGetIDState gets the list position to the given id
; -
Procedure.b DebugGetIDState_LogLevel(id.s)
  ForEach stddebugloglevel()
    If stddebugloglevel()\id = id
      ProcedureReturn stddebugloglevel()\enabled
    EndIf
  Next    
EndProcedure


CompilerIf #DEBUG_DEBUGGEROUT = #True
 DebugInit()
  
 DebugAdd_LogLevel("7","All","All Debug Log"                                    ,"Enable/Disable all log file output (overrides)",#True)
 DebugAdd_LogLevel("8","GarbageCollector","Log Garbage Collector"               ,"Enable/Disable Garbage Collector log file output",#True)
 DebugAdd_LogLevel("9","C2PB_ProcessTasksLevel0","Log C2PB_ProcessTasks Level 0","Enable/Disable C2PB_ProcessTasks Level 0 log file output",#True)
 DebugAdd_LogLevel("10","C2PB_ProcessTasksLevel1","Log C2PB_ProcessTasks Level 1","Enable/Disable C2PB_ProcessTasks Level 1 log file output",#True)
 DebugAdd_LogLevel("11","ProcessLines","Log Process Lines"                      ,"Enable/Disable Process Lines log file output",#True)
 DebugAdd_LogLevel("12","Functions","Log Functions"                             ,"Enable/Disable Functions log file output",#True)
 DebugAdd_LogLevel("13","Struct","Log Struct"                                   ,"Enable/Disable Struct log file output",#True)
 DebugAdd_LogLevel("14","Define","Log Define"                                   ,"Enable/Disable Define log file output",#True)
 DebugAdd_LogLevel("15","Enumeration","Log Enumeration"                         ,"Enable/Disable Enumeration log file output",#True)
 DebugAdd_LogLevel("16","Comments","Log Comments"                               ,"Enable/Disable Comments log file output",#True)
 DebugAdd_LogLevel("17","Tasks","Log Task"                                      ,"Enable/Disable Task log file output",#True) 
 
 DebugClear()
 
 DebugOut("This is is a test output",#False,"GarbageCollector")
 DebugOut("This is is a test output",#False,"C2PB_ProcessTasksLevel0")
 DebugOut("This is is a test output",#False,"C2PB_ProcessTasksLevel1")
 DebugOut("This is is a test output",#False,"ProcessLines")
 DebugOut("This is is a test output",#False,"Functions")
 DebugOut("This is is a test output",#False,"Struct")
 DebugOut("This is is a test output",#False,"Define")
 DebugOut("This is is a test output",#False,"Enumeration")
 DebugOut("This is is a test output",#False,"Comments")
 DebugOut("This is is a test output",#False,"Tasks")
  
 
 DebugGetID_LogLevel("16")
 Debug stddebugloglevel()\tagname
 
 DebugSetIDState_LogLevel("7",#False)
 DebugDump_LogLevel()
 
CompilerEndIf 

; IDE Options = PureBasic 6.03 LTS (Windows - x86)
; CursorPosition = 115
; FirstLine = 77
; Folding = cg
; EnableXP
; DPIAware
; CompileSourceDirectory
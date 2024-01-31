;
; Declarations
;

;
;- Main.pb
;
Declare Callback_Scintilla_Translation(Gadget, *scinotify.SCNotification)
Declare DebugOut(string.s,clearlog.b=#False,loglevel.s="")
Declare Header_Import(file.s="")
Declare.s Get_TasksDetails(idx.l,value.l=0)
Declare Update_TagCodeBlocks()

;
;- C2CodeBlocks.pbi
;
Declare C2CodeBlock_ReplacePaste(codeblockname.s,strreplace.s="",currentln.s="",atline=-1)
; IDE Options = PureBasic 6.03 LTS (Windows - x86)
; CursorPosition = 16
; EnableXP
; DPIAware
; CompileSourceDirectory
IncludeFile "form.pbf"

;
;
;
Structure Type
  BasicTypeID.b
  CType.s
EndStructure

Global NewList TypeList.Type()
;
;
;
#PB_MAXBASICTYPES = 12
Global Dim PB_BasicType.s(#PB_MAXBASICTYPES)
Global Dim ColumnNames.s(4)
ColumnNames.s(0) = "C"
ColumnNames.s(1) = "Name"
ColumnNames.s(2) = "E"
ColumnNames.s(3) = "Size"
ColumnNames.s(4) = "Range"
  
PB_BasicType.s(0) = "Byte,.b,1 byte,-128 To +127"
PB_BasicType.s(1) = "Ascii,.a,1 byte,0 To +255"
PB_BasicType.s(2) = "Character,.c,2 bytes,0 To +65535"
PB_BasicType.s(3) = "Word,.w,2 bytes,-32768 To +32767"
PB_BasicType.s(4) = "Unicode,.u,2 bytes,0 To +65535" 
PB_BasicType.s(5) = "Long,.l,4 bytes,-2147483648 To +2147483647"
PB_BasicType.s(6) = "Integer32,.i,4 bytes (using 32-bit compiler),-2147483648 To +2147483647"
PB_BasicType.s(7) = "Integer64,.i,8 bytes (using 64-bit compiler),-9223372036854775808 To +9223372036854775807"
PB_BasicType.s(8) = "Float,.f,4 bytes,unlimited"
PB_BasicType.s(9) = "Quad,.q,8 bytes,-9223372036854775808 To +9223372036854775807"
PB_BasicType.s(10) = "Double,.d,8 bytes,unlimited" 
PB_BasicType.s(11) = "String,.s,string length + 1,unlimited"
PB_BasicType.s(12) = "Fixed String,.s{Length},string length,unlimited"


;
;
;
Procedure Add_CTypeTable(addln.s = "")
  type.s = ""
  If addln=""
    type.s = GetGadgetText(#ST_Arguments)+Chr(10)
    pbtype.s = ReplaceString(PB_BasicType(GetGadgetState(#CB_PureTypes)),",",Chr(10))
  Else
    pbtype.s = ReplaceString(addln,",",Chr(10))
  EndIf
  AddGadgetItem(#LI_CTypeTable,-1,type+pbtype)  
EndProcedure
;
;
;
Procedure Load()
  If OpenFile(0,"default.types")
    While Eof(0) = 0
      Add_CTypeTable(ReadString(0))
    Wend    
    CloseFile(0)
  Else
    MessageRequester("Error","Cannot make/load default.types")
  EndIf  
EndProcedure

;
;
;
Procedure Save(eventType)   
  If OpenFile(0,"default.types")    
    For r = 0 To CountGadgetItems(#LI_CTypeTable)-1
      lnout.s = ""
      For c = 0 To GetGadgetAttribute(#LI_CTypeTable,#PB_ListIcon_ColumnCount)-1
        lnout + GetGadgetItemText(#LI_CTypeTable,r,c) + ","
      Next
      WriteStringN(0,Mid(lnout,1,Len(lnout)-1))
    Next     
    CloseFile(0)
  Else
    MessageRequester("Error","Cannot make/load default.types")
  EndIf    
EndProcedure

;
;
;
Procedure Delete(eventType)
  RemoveGadgetItem(#LI_CTypeTable,GetGadgetState(#LI_CTypeTable))
EndProcedure

;
;
;
Procedure Add(eventType)
  Add_CTypeTable()
EndProcedure

;
;
;
Procedure SetupMainWindow()
  For i = 0 To #PB_MAXBASICTYPES    
    AddGadgetItem(#CB_PureTypes,-1,PB_BasicType.s(i))
  Next
  SetGadgetState(#CB_PureTypes,0)
  Load()
EndProcedure

;
;
;
OpenMainWindow()
SetupMainWindow()

Repeat 
  event = MainWindow_Events(WaitWindowEvent())
Until event = #False

; IDE Options = PureBasic 6.03 LTS (Windows - x86)
; CursorPosition = 42
; FirstLine = 24
; Folding = --
; EnableXP
; DPIAware
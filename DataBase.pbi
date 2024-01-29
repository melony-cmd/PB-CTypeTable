; Author: T.J.Roughton
; File: DataBase.pbi
; Description: Editable Database of C and PureBasic variable types.
; Version: 0
; Licence: Dilligaf


UseSQLiteDatabase()

;
;
;
Enumeration
  #PB_VariableType
  #PB_VariableExtension
  #PB_VariableByteSize
  #PB_VariableMinRange
  #PB_VariableMaxRange
EndEnumeration

Enumeration
  #C_VariableType = 1
  #C_VariableExtension
  #C_VariableByteSize
  #C_VariableMinRange
  #C_VariableMaxRange
  #C_VariablePBIsEqual
EndEnumeration

;
; Create 'new' Database
;
Procedure CreateDefaultDatabase(filename.s)
  If CreateFile(0,filename)
    Debug "Database file created"
    CloseFile(0)
  EndIf  
  If OpenDatabase(0,filename, "", "")
    If DatabaseUpdate(0, "CREATE TABLE PureBasicTypes(unqueid INTEGER PRIMARY KEY ASC,type VARCHAR(255),extension VARCHAR(255),bytesize VARCHAR(255),minrange VARCHAR(255),maxrange VARCHAR(255));")
      DatabaseUpdate(0, "INSERT INTO PureBasicTypes (type, extension, bytesize, minrange, maxrange) VALUES ('Byte','.b','1 Byte','-128','+127')")
      DatabaseUpdate(0, "INSERT INTO PureBasicTypes (type, extension, bytesize, minrange, maxrange) VALUES ('Ascii','.a','1 Byte','0','+255')")
      DatabaseUpdate(0, "INSERT INTO PureBasicTypes (type, extension, bytesize, minrange, maxrange) VALUES ('Character','.c','2 Byte','0','+65535')")
      DatabaseUpdate(0, "INSERT INTO PureBasicTypes (type, extension, bytesize, minrange, maxrange) VALUES ('Word','.w','2 Byte','-32768','+32767')")
      DatabaseUpdate(0, "INSERT INTO PureBasicTypes (type, extension, bytesize, minrange, maxrange) VALUES ('Unicode','.u','4 Byte','0','+65535')")
      DatabaseUpdate(0, "INSERT INTO PureBasicTypes (type, extension, bytesize, minrange, maxrange) VALUES ('Long','.l','4 Byte','-2147483648','+2147483647')")
      DatabaseUpdate(0, "INSERT INTO PureBasicTypes (type, extension, bytesize, minrange, maxrange) VALUES ('Integer32','.i','4 Byte','-2147483648','+2147483647')")
      DatabaseUpdate(0, "INSERT INTO PureBasicTypes (type, extension, bytesize, minrange, maxrange) VALUES ('Integer64','.i','8 Byte','-9223372036854775808','+9223372036854775807')")
      DatabaseUpdate(0, "INSERT INTO PureBasicTypes (type, extension, bytesize, minrange, maxrange) VALUES ('Float','.f','4 Byte','unlimited','unlimited')")
      DatabaseUpdate(0, "INSERT INTO PureBasicTypes (type, extension, bytesize, minrange, maxrange) VALUES ('Quad','.q','8 Byte','-9223372036854775808','+9223372036854775807')")
      DatabaseUpdate(0, "INSERT INTO PureBasicTypes (type, extension, bytesize, minrange, maxrange) VALUES ('Double','.d','8 Byte','unlimited','unlimited')")
      DatabaseUpdate(0, "INSERT INTO PureBasicTypes (type, extension, bytesize, minrange, maxrange) VALUES ('String','.s','String Length','unlimited','unlimited')")
      DatabaseUpdate(0, "INSERT INTO PureBasicTypes (type, extension, bytesize, minrange, maxrange) VALUES ('Fixed String','.s{length}','1 Byte','unlimited','unlimited')")
      DatabaseUpdate(0, "INSERT INTO PureBasicTypes (type, extension, bytesize, minrange, maxrange) VALUES ('Null','','','','')")
      DatabaseUpdate(0, "INSERT INTO PureBasicTypes (type, extension, bytesize, minrange, maxrange) VALUES ('*','*','','pointer','pointer')")
    EndIf
  
    If DatabaseUpdate(0, "CREATE TABLE CTypes(unqueid INTEGER PRIMARY KEY ASC,type VARCHAR(255),bytesize VARCHAR(255),minrange VARCHAR(255),maxrange VARCHAR(255),pbisequal VARCHAR(255));")
      DatabaseUpdate(0, "INSERT INTO CTypes (type, bytesize,minrange, maxrange, pbisequal) VALUES ('char',              '1 Byte', '-128','+127',              'Byte')")
      DatabaseUpdate(0, "INSERT INTO CTypes (type, bytesize,minrange, maxrange, pbisequal) VALUES ('unsigned char',     '1 Byte', '0',   '255',               'Ascii')")    
      DatabaseUpdate(0, "INSERT INTO CTypes (type, bytesize,minrange, maxrange, pbisequal) VALUES ('int',               '4 Byte', '-2147483648','+2147483647','Long')")
      DatabaseUpdate(0, "INSERT INTO CTypes (type, bytesize,minrange, maxrange, pbisequal) VALUES ('unsigned int',      '4 Byte', '0','+4294967295',          'Long')")    
      DatabaseUpdate(0, "INSERT INTO CTypes (type, bytesize,minrange, maxrange, pbisequal) VALUES ('short int',         '2 Byte', '-32768','+32767',          'Word')")
      DatabaseUpdate(0, "INSERT INTO CTypes (type, bytesize,minrange, maxrange, pbisequal) VALUES ('unsigned short int','2 Byte', '0','+65535',               'Unicode')")    
      DatabaseUpdate(0, "INSERT INTO CTypes (type, bytesize,minrange, maxrange, pbisequal) VALUES ('long',              '8 Byte', '','',                      'Quad')")
      DatabaseUpdate(0, "INSERT INTO CTypes (type, bytesize,minrange, maxrange, pbisequal) VALUES ('unsigned long',     '8 Byte', '','',                      'Quad')")    
      DatabaseUpdate(0, "INSERT INTO CTypes (type, bytesize,minrange, maxrange, pbisequal) VALUES ('long int',          '8 Byte', '','',                      'Quad')")
      DatabaseUpdate(0, "INSERT INTO CTypes (type, bytesize,minrange, maxrange, pbisequal) VALUES ('unsigned long int', '8 Byte', '','',                      'Quad')")    
      DatabaseUpdate(0, "INSERT INTO CTypes (type, bytesize,minrange, maxrange, pbisequal) VALUES ('float',             '4 Byte', '','',                      'Float')")
      DatabaseUpdate(0, "INSERT INTO CTypes (type, bytesize,minrange, maxrange, pbisequal) VALUES ('double',            '8 Byte', '','',                      'Double')")
      DatabaseUpdate(0, "INSERT INTO CTypes (type, bytesize,minrange, maxrange, pbisequal) VALUES ('long double',       '16 Byte','','',                      '')")
      DatabaseUpdate(0, "INSERT INTO CTypes (type, bytesize,minrange, maxrange, pbisequal) VALUES ('void',              '0 Byte' ,'','',                      '')")
    EndIf
  
    If DatabaseUpdate(0, "CREATE TABLE UserTypesDef(unqueid INTEGER PRIMARY KEY ASC,typedef VARCHAR(255),ctype VARCHAR(255),pbtype VARCHAR(255));")    
    EndIf
    CloseDatabase(0)
  EndIf
EndProcedure

;
; Get List From Database
;
Procedure GetDatabaseList(dbidx.l,table.s,List thislist.s())
  
  ClearList(thislist())
    
  If IsDatabase(dxidx)
    If DatabaseQuery(dbidx, "SELECT * FROM "+table)
      ncolumns = DatabaseColumns(dbidx)
      While NextDatabaseRow(dbidx)      
        output.s = ""
        For i = 0 To ncolumns-1
          output=output+GetDatabaseString(dbidx,i)+","
        Next
        AddElement(thislist())
        thislist() = Mid(output,1,Len(output)-1)
      Wend    
      FinishDatabaseQuery(dbidx)
    EndIf
  EndIf  
EndProcedure

;
; Get Row From Database
;
Procedure.s GetDatabaseRow(dbidx.l,table.s,row.l=-1)
  If IsDatabase(dxidx)
    If DatabaseQuery(dbidx, "SELECT * FROM "+table)
      ncolumns = DatabaseColumns(dbidx)
      While NextDatabaseRow(dbidx)      
        output.s = ""
        For i = 0 To ncolumns-1
          output=output+GetDatabaseString(dbidx,i)+","
        Next
        output=output+GetDatabaseString(dbidx,ncolumns)
        If r=row
          ProcedureReturn output
        EndIf
        r=r+1
      Wend    
      FinishDatabaseQuery(dbidx)
    EndIf
  EndIf  
EndProcedure

;
; Delete Row
;
Procedure DeleteDatabaseRow(dbidx.l,table.s,row.l)  
  del.s = "DELETE FROM "+table+" WHERE unqueid = "+Str(row)+";"
  Debug del
    
  Debug DatabaseUpdate(dbidx, del)
  Debug DatabaseError()
  Debug AffectedDatabaseRows(dbidx)  
EndProcedure

;
; 
;
Procedure InsertDatabase_UserTypesDef(dxidx.l, typedef.s, ctype.s, pbtype.s)
  If IsDatabase(dxidx)
    typedef = "'"+typedef+"',"
    ctype = "'"+ctype+"',"
    pbtype = "'"+pbtype+"'"
    DatabaseUpdate(dxidx, "INSERT INTO UserTypesDef (typedef, ctype, pbtype) VALUES ("+typedef+ctype+pbtype+")")
  EndIf  
EndProcedure

;
;
;
Procedure SearchDatabase(flags.l)
      
EndProcedure

;
; IO Create Database
;
Procedure CreateFile_Database(Event)
  savefile.s = SaveFileRequester("Create DataBase","","SQLite File|*.sqlite|All Files|*.*",0)
  If savefile<>""
    CreateDefaultDatabase(savefile)
  EndIf  
EndProcedure

;
; IO Open Database
;
Procedure OpenFile_Database(Event)  
  If IsDatabase(0) : CloseDatabase(0) : EndIf   
  loadfile.s = OpenFileRequester("Open DataBase","","SQLite File|*.sqlite|All Files|*.*",0)
  If loadfile<>""
    If OpenDatabase(0,loadfile, "", "")
      
    EndIf    
  EndIf  
EndProcedure

;
; DEBUG
;
Procedure DEBUG_Show_UserTypesDef()
  NewList utd.s()
  GetDatabaseList(0,"UserTypesDef",utd())
  ForEach utd()
    Debug utd()
  Next  
EndProcedure

;
;
;
; NewList PureBasicTypes.s()
; NewList CTypes.s()
; NewList UserTypesDef.s()
; 
; ;CreateDefaultDatabase("default.sqlite")
; 
; If OpenDatabase(0,"default.sqlite", "", "")
;   GetDatabaseList(0,"PureBasicTypes",PureBasicTypes())
;   GetDatabaseList(0,"CTypes",CTypes())
;   GetDatabaseList(0,"UserTypesDef",UserTypesDef())  
;   
;   ; Show Begin
;   DEBUG_Show_UserTypesDef()
;   
;   ; Show Deleted
;   GetDatabaseList(0,"UserTypesDef",UserTypesDef())  
;   DeleteDatabaseRow(0,"UserTypesDef",1)
;   
;   DEBUG_Show_UserTypesDef() ; creates new list within itself.
;   
;   CloseDatabase(0)
; Else
;   Debug "UmmERROR"
; EndIf


; IDE Options = PureBasic 6.03 LTS (Windows - x86)
; CursorPosition = 2
; Folding = 8-
; EnableXP
; DPIAware
; CompileSourceDirectory
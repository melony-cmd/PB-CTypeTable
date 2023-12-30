;
; We don't need the entire functionality of scintilla so these come from a project called GoScintilla
; with slight personal modifications.
;

;/////////////////////////////////////////////////////////////////////////////////
;-CONSTANTS.  
#GOSCI_DEFAULTCODECOMPLETIONCHARS = 3
#GOSCI_BOOKMARKMARKERNUM          = 0
#GOSCI_ERRORMARKERNUM             = 1

;/////////////////////////////////////////////////////////////////////////////////
;-STRUCTURES.

;The following structure holds information (such as syntax highlighting info) on individual Scintilla controls.
Structure _GoScintilla
  ;Creation fields.
  id.i
  callback.GOSCI_proto_Callback
  flags.i
  state.i
  ;Custom line styling function.
  stylingFunction.GOSCI_proto_StyleLine
  ;Additional user-supplied data.
  userData.i
  lineNumberAutoSizePadding.i
  lexerSeparators$
  lexerNumbersStyleIndex.i
  ;Lists/maps.
  List keywords.GoScintillaKeyword()
  Map keywordPtr.i()
  ;Code folding.
  blnLineCodeFoldOption.i     ;0 = no code folding, 1 = open fold, 2 = close fold.
  foldLevel.i
  ;Styling.
  previouslyRecordedStyle.i   ;Used for left delimiters (separators).
  *bytePointer                ;Used for left delimiters (separators).
                              ;Code completion.
  codeCompletionChars.i       ;Number of characters required to instigate code completion.
                              ;Call-tips.
  lastStartPos.i
  callTipLine.i
  lastCallTipIndex.i
  ;Miscellaneous.
  blnSpaceAdded.i
EndStructure

;The following structure is used to deal with call-tips.
Structure _GoScintillaCallTips
  *keyword.GoScintillaKeyword
  charPos.i
  previousCloseCalltipSeparator.a
EndStructure
;/////////////////////////////////////////////////////////////////////////////////

;/////////////////////////////////////////////////////////////////////////////////
;The following function retrieves the text (minus any EOL characters) for a given line.
Procedure.s GOSCI_GetLineText(id, lineIndex)
  Protected text$, numLines, lineLength, utf8Buffer, *ptrAscii.ASCII
  If IsGadget(id) And GadgetType(id) = #PB_GadgetType_Scintilla
    numLines = ScintillaSendMessage(id, #SCI_GETLINECOUNT)
    If lineIndex >=0 And lineIndex < numLines
      lineLength = ScintillaSendMessage(id, #SCI_LINELENGTH, lineIndex)
      If lineLength
        utf8Buffer = AllocateMemory(lineLength+1,#PB_Memory_NoClear)
        If utf8Buffer
          ScintillaSendMessage(id, #SCI_GETLINE, lineIndex, utf8Buffer)
          ;Remove any terminating EOL characters.
            *ptrAscii = utf8Buffer + lineLength - 1
            While (*ptrAscii\a = 10 Or *ptrAscii\a = 13) And lineLength
              lineLength - 1
              *ptrAscii - 1
            Wend
          text$ = PeekS(utf8Buffer, lineLength, #PB_UTF8)
          FreeMemory(utf8Buffer)
        EndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn text$
EndProcedure

;/////////////////////////////////////////////////////////////////////////////////
;The following function sets the text for the entire control.
;Set the optional clearUndoStack parameter to non-zero to have the undo stack cleared so that this operation cannot be undone.
;No return value.
Procedure GOSCI_SetText(id, text$, clearUndoStack=#False)
  Protected utf8Buffer
  If IsGadget(id) And GadgetType(id) = #PB_GadgetType_Scintilla
    ;Need To convert To utf-8 first.
    utf8Buffer = AllocateMemory(StringByteLength(text$, #PB_UTF8)+1)
    If utf8Buffer 
      PokeS(utf8Buffer, text$, -1, #PB_UTF8)
      ScintillaSendMessage(id, #SCI_SETTEXT, 0, utf8Buffer)
      FreeMemory(utf8Buffer)
      If clearUndoStack
        ScintillaSendMessage(id, #SCI_EMPTYUNDOBUFFER)
      EndIf
    EndIf
  EndIf
EndProcedure

;/////////////////////////////////////////////////////////////////////////////////
;The following function changes the text for a given line.
;No return value.
Procedure GOSCI_SetLineText(id, lineIndex, text$)
  Protected numLines, lineLength, startPos, endPos, char.a, utf8Buffer
  If IsGadget(id) And GadgetType(id) = #PB_GadgetType_Scintilla
    numLines = ScintillaSendMessage(id, #SCI_GETLINECOUNT)
    If lineIndex >=0 And lineIndex < numLines
      ;Remove all EOL characters.
      text$ = RemoveString(text$, #LF$)
      text$ = RemoveString(text$, #CR$)
      ;Find the beginning And the End of the text To replace.
      lineLength = ScintillaSendMessage(id, #SCI_LINELENGTH, lineIndex)
      startPos = ScintillaSendMessage(id, #SCI_POSITIONFROMLINE, lineIndex)
      endPos = startPos + lineLength
      ;We ignore any EOL characters.
      endPos - 1
      char = ScintillaSendMessage(id, #SCI_GETCHARAT, endPos)
      While (char = 10 Or char = 13) And endPos >= startPos
        endPos-1
        char = ScintillaSendMessage(id, #SCI_GETCHARAT, endPos)
      Wend
      endPos + 1
      ;Need to convert text to utf-8 first.
      utf8Buffer = AllocateMemory(StringByteLength(text$, #PB_UTF8)+1)
      If utf8Buffer 
        PokeS(utf8Buffer, text$, -1, #PB_UTF8)
        ScintillaSendMessage(id, #SCI_SETTARGETSTART, startPos)
        ScintillaSendMessage(id, #SCI_SETTARGETEND, endPos)
        ScintillaSendMessage(id, #SCI_REPLACETARGET, -1, utf8Buffer)
        FreeMemory(utf8Buffer)
      EndIf
    EndIf
  EndIf
EndProcedure

;/////////////////////////////////////////////////////////////////////////////////
;The following function removes the specified line of text.
;No return value.
Procedure GOSCI_DeleteLine(id, lineIndex)
  ScintillaSendMessage(id,#SCI_GOTOLINE,lineIndex)
  ScintillaSendMessage(id,#SCI_LINEDELETE)  
EndProcedure

;/////////////////////////////////////////////////////////////////////////////////
;The following function clears all text (unless the control is read-only).
;No return.
Procedure GOSCI_Clear(id)
  If IsGadget(id) And GadgetType(id) = #PB_GadgetType_Scintilla
    If ScintillaSendMessage(id, #SCI_GETREADONLY) = 0
      ScintillaSendMessage(id, #SCI_CLEARALL)
    EndIf
  EndIf
EndProcedure

;/////////////////////////////////////////////////////////////////////////////////
;The following function sets or clears a bookmark from the given line depending on the flag parameter.
Procedure GOSCI_SetLineBookmark(id, lineIndex, flag=#True)
  If IsGadget(id) And GadgetType(id) = #PB_GadgetType_Scintilla
    If flag
      ScintillaSendMessage(id, #SCI_MARKERADD, lineIndex, #GOSCI_BOOKMARKMARKERNUM)    
    Else
      ScintillaSendMessage(id, #SCI_MARKERDELETE, lineIndex, #GOSCI_BOOKMARKMARKERNUM) 
    EndIf
  EndIf
EndProcedure

 ;/////////////////////////////////////////////////////////////////////////////////
 ;The following function retrieves state information. See header file for more details of which states can be retrieved.
 Procedure.i GOSCI_GetState(id, stateType)
   Protected result, *this._GoScintilla, nPos
   If IsGadget(id) And GadgetType(id) = #PB_GadgetType_Scintilla
     Select stateType
       Case #GOSCI_CURRENTLINE
         nPos = ScintillaSendMessage(id, #SCI_GETCURRENTPOS)
         result = ScintillaSendMessage(id, #SCI_LINEFROMPOSITION, nPos)
       Case #GOSCI_ISMODIFIED
         result = ScintillaSendMessage(id, #SCI_GETMODIFY)
       Case #GOSCI_ISREADYTOREDO
         result = ScintillaSendMessage(id, #SCI_CANREDO)
       Case #GOSCI_ISREADYTOUNDO
         result = ScintillaSendMessage(id, #SCI_CANUNDO)
       Case #GOSCI_ISEMPTY
         If ScintillaSendMessage(id, #SCI_GETLENGTH) = 0
           result = #True
         EndIf
     EndSelect
   EndIf
   ProcedureReturn result
 EndProcedure

;
;
;


; IDE Options = PureBasic 6.03 LTS (Windows - x86)
; CursorPosition = 196
; FirstLine = 155
; Folding = --
; EnableXP
; DPIAware
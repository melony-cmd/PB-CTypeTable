
;- +++++++++ Common Procedures Start ++++++++++++

Structure FindProp
	PropName.s
	PropFound.b
EndStructure

Procedure.i _HasPropCallback(hwnd.i, lpszString.i, hData.i, *Info.FindProp)
	If lpszString>>16
		If PeekS(lpszString)=*Info\PropName
			*Info\PropFound=#True
			ProcedureReturn 0
		EndIf
	EndIf
	ProcedureReturn 1	
EndProcedure

Procedure HasProp(hwnd.i, PropName.s)
	Protected Info.FindProp
	
	Info\PropName=PropName
	Info\PropFound=#False
	EnumPropsEx_(hwnd, @_HasPropCallback(), @Info)
	ProcedureReturn Info\PropFound
EndProcedure


Procedure IsPBWindow(hwnd.i)
	If HasProp(hwnd, "PB_WindowID")
		ProcedureReturn #True
	Else
		ProcedureReturn #False	
	EndIf
EndProcedure

Procedure IsPBGadget(hwnd.i)
	If HasProp(hwnd, "PB_ID")
		ProcedureReturn #True
	Else
		ProcedureReturn #False	
	EndIf
EndProcedure

Procedure GetPBID(hwnd.i)
	Protected ID.i
	If IsPBWindow(hwnd) Or IsPBGadget(hwnd)
		ProcedureReturn GetDlgCtrlID_(hwnd)
	Else
		ProcedureReturn -1
	EndIf	
EndProcedure

Procedure.i GetGadgetList(Gadget.i)
	
	Protected hwnd.i=GadgetID(Gadget)
	Protected GadID.i
	
	Repeat
; 		Debug "Hwnd >"+Str(Hwnd)+"<"
		hwnd=GetParent_(hwnd)
		If IsPBGadget(hwnd)
			GadID=GetPBID(hwnd)
; 			Debug "GadID >"+Str(GadID)+"<"
			If GadId>-1
				Select GadgetType(GadID)
					Case #PB_GadgetType_Container, #PB_GadgetType_Panel, #PB_GadgetType_ScrollArea
; 						Debug "Container, Panel, ScrollArea Gadget found"
						ProcedureReturn hwnd
				EndSelect
			EndIf
		EndIf
	Until IsPBWindow(hwnd)
	
	ProcedureReturn hwnd
	
EndProcedure

;- ########## Common Procedures End ############


Structure LIG_SelectSettings
	Color_Back.i
	Color_Back_Inactive.i
	Color_Front.i
	
	Last_Color_Back.i
	Last_Color_Front.i
	Last_Line.i
	Last_Column.i
	Last_Valid.b
EndStructure

Structure LIG_EditSettings
	EditGadgetMem.i
	Edit_ApplyOnExit.b
	Edit_AllowCtrlC.b
	Edit_AllowCtrlV.b
EndStructure

Structure LIG_SubClassInfo
	Enable_MouseEdit.b ; stores if 'MouseEdit' is enabled (allows to start edit with DoubleClick)
	Enable_CursorEdit.b ; stores if 'CursorEdit' is enabled (allows to select the desired Cell with Cursor Keys and start edit with ENTER key)
	Enable_ColumnSort.b ; stores if 'ColumnSort' is allowed (allows to sort columns by click on header)
	
	ListIconGadget.i ; the PB-ID of the ListIconGadget
	GadgetList.i ; the GadgetList responsible for the ListIconGadget ('Edit' Gadgets will be assigned to this GadgetList)
	OrgProc.i ; the original Address of the MessageHandler (before subclassing)
	
	CursorSettings.LIG_SelectSettings ; stores the settings for 'CursorEdit'
	EditSettings.LIG_EditSettings ; stores general 'Edit' settings
EndStructure

Structure LIG_CellInfo
	Line.i
	Column.i
EndStructure

Structure HDHITTESTINFO
	pt.POINT
	flags.i
	iItem.i
EndStructure

;- ++++++ ListIconGadget Tools Start ++++++

Enumeration ; Type of Column Sort
	#LIG_SortString
	#LIG_SortNumeric
	#LIG_SortFloat
	#LIG_SortDate
	#LIG_SortAutoDetect
EndEnumeration

Enumeration ; Column Sort States
	#LIG_NoSort   ; keine Sortierung
	#LIG_AscSort  ; Aufsteigende Sortierung
	#LIG_DescSort ; Absteigende Sortierung
	#LIG_ChngSort   ; change the current direction
EndEnumeration

Enumeration
	#LIG_MoveUpTop
	#LIG_MoveUp
	#LIG_MoveDown
	#LIG_MoveDownBottom
EndEnumeration

Procedure LIG_AlignColumn(gadget, index, format)
	; by Danilo, 15.12.2003 - english chat (for 'Karbon')
	; 20130615..nalor..modified
	
	; change text alignment for columns
	; #LVCFMT_LEFT / #LVCFMT_CENTER / #LVCFMT_RIGHT
	
	Protected lvc.LV_COLUMN
	lvc\mask = #LVCF_FMT
	lvc\fmt = format
	
	SendMessage_(GadgetID(gadget), #LVM_SETCOLUMN, index, @lvc)
EndProcedure

Procedure LIG_SetColumnWidth(gadget,index,new_width)
	; by Danilo, 15.12.2003 - english chat (for 'Karbon')
	;
	; change column header width
	
; Debug #LVSCW_AUTOSIZE_USEHEADER
; Debug #LVSCW_AUTOSIZE	
	
	SendMessage_(GadgetID(gadget),#LVM_SETCOLUMNWIDTH,index,new_width)
EndProcedure

Procedure.i LIG_GetColumnCount(Gadget.i)
	
	ProcedureReturn SendMessage_(SendMessage_(GadgetID(Gadget),#LVM_GETHEADER,0,0), #HDM_GETITEMCOUNT,0,0)
	
EndProcedure

Procedure LIG_AutoColumnWidth(Gadget.i, WithoutHeader.b=#False)
	
	Protected ColumnCount.i
	Protected Cnt.i

	ColumnCount=LIG_GetColumnCount(Gadget)
	
	SendMessage_(GadgetID(Gadget), #WM_SETREDRAW, #False, #Null)
	For Cnt=0 To ColumnCount-1
		If Not WithoutHeader
			SendMessage_(GadgetID(Gadget), #LVM_SETCOLUMNWIDTH, Cnt, #LVSCW_AUTOSIZE_USEHEADER)
		Else
			SendMessage_(GadgetID(Gadget), #LVM_SETCOLUMNWIDTH, Cnt, #LVSCW_AUTOSIZE)			
		EndIf
	Next	
	SendMessage_(GadgetID(Gadget), #WM_SETREDRAW, #True, #Null)

EndProcedure

Procedure LIG_SetSortArrow(ListGadget.i, Column.i, SortOrder.i)
; http://stackoverflow.com/questions/254129/how-To-i-display-a-sort-arrow-in-the-header-of-a-List-view-column-using-c	

	Protected ColumnHeader.i
	Protected ColumnCount.i
	Protected hditem.HD_ITEM
	Protected Cnt.i
	
	ColumnHeader=SendMessage_(GadgetID(ListGadget), #LVM_GETHEADER, 0, 0)
		
	ColumnCount=SendMessage_(ColumnHeader, #HDM_GETITEMCOUNT, 0, 0)
	
	For Cnt=0 To ColumnCount-1
		hditem\mask=#HDI_FORMAT
		
		If SendMessage_(ColumnHeader, #HDM_GETITEM, Cnt, @hditem)=0
			Debug "ERROR! LIG_SetSortIcon 1"
		EndIf
		
		hditem\mask=#HDI_FORMAT
		If (Cnt=Column And SortOrder<>#LIG_NoSort)
			Select SortOrder
				Case #LIG_AscSort ; wenn aufsteigend sortiert werden soll
					hditem\fmt& ~#HDF_SORTDOWN
					hditem\fmt|#HDF_SORTUP
; 					Debug "sortup"
				Case #LIG_DescSort
					hditem\fmt& ~#HDF_SORTUP
					hditem\fmt|#HDF_SORTDOWN					
; 					Debug "sortdown"
			EndSelect
		Else
			hditem\fmt& ~#HDF_SORTUP
			hditem\fmt& ~#HDF_SORTDOWN
		EndIf

		If (SendMessage_(ColumnHeader, #HDM_SETITEM, Cnt, @hditem)=0)
			Debug "ERROR! LIG_SetSortIcon 2"
		EndIf
		
	Next
EndProcedure
	
Procedure.b LIG_GetSortOrder(ListGadget.i, Column.i)
	Protected ColumnHeader.i
	Protected hditem.HD_ITEM
	Protected RetVal.b
	
	If GetGadgetAttribute(ListGadget, #PB_ListIcon_DisplayMode)=#PB_ListIcon_Report

		ColumnHeader=SendMessage_(GadgetID(ListGadget), #LVM_GETHEADER, 0, 0)
			
		hditem\mask=#HDI_FORMAT
		
		If SendMessage_(ColumnHeader, #HDM_GETITEM, Column, @hditem)
			If (hditem\fmt&#HDF_SORTUP)=#HDF_SORTUP
; 				Debug "sortup"
				RetVal=#LIG_AscSort
			ElseIf (hditem\fmt&#HDF_SORTDOWN)=#HDF_SORTDOWN
; 				Debug "sortdown"
				RetVal=#LIG_DescSort
			Else
; 				Debug "keine sortierung"
				RetVal=#LIG_NoSort
			EndIf
			
		Else
			Debug "ERROR! LIG_GetSortOrder"
			RetVal=-1
			
		EndIf
	Else
		RetVal=#LIG_NoSort
	EndIf
	
	ProcedureReturn RetVal

EndProcedure

Procedure LIG_SwapItems(id, item1, item2)
	
	Protected col.i
	Protected Text.s
	Protected Temp.i
	Protected ColCnt.i=LIG_GetColumnCount(id)
	
	For col = 0 To ColCnt - 1
		;swap item text
		Text = GetGadgetItemText(id, item1, col)
		SetGadgetItemText(id, item1, GetGadgetItemText(id, item2, col), col)
		SetGadgetItemText(id, item2, Text, col)

		;swap item data
		Temp = GetGadgetItemData(id, item1)
		SetGadgetItemData(id, item1, GetGadgetItemData(id, item2))
		SetGadgetItemData(id, item2, Temp)
		
		;swap item fg colors
		Temp = GetGadgetItemColor(id, item1, #PB_Gadget_FrontColor, col)
		SetGadgetItemColor(id, item1, #PB_Gadget_FrontColor, GetGadgetItemColor(id, item2, #PB_Gadget_FrontColor, col), col)
		SetGadgetItemColor(id, item2, #PB_Gadget_FrontColor, Temp, col)
		
		;swap item bg colors
		Temp = GetGadgetItemColor(id, item1, #PB_Gadget_BackColor, col)
		SetGadgetItemColor(id, item1, #PB_Gadget_BackColor, GetGadgetItemColor(id, item2, #PB_Gadget_BackColor, col), col) 
		SetGadgetItemColor(id, item2, #PB_Gadget_BackColor, Temp, col)
	Next col
	;swap checkbox/selected item states
	Temp = GetGadgetItemState(id, item1)
	SetGadgetItemState(id, item1, GetGadgetItemState(id, item2))
	SetGadgetItemState(id, item2, Temp)
EndProcedure

Procedure.b LIG_MoveItems(Gadget.i, Direction.i)
	
	Protected iListCnt.i
	Protected iCnt.i
	Protected iBorder.i
	Protected iSelCnt.i
	Protected LIG_Change.b=#False
	
	iListCnt=CountGadgetItems(Gadget)
	
	Select(Direction)
			
		Case #LIG_MoveUp ; 1 nach oben
			iBorder=0
			For iCnt=0 To iListCnt-1
; 				Debug Str(iCnt)+"-"+GetGadgetItemText(Gadget, iCnt, 0)
				
				If (GetGadgetItemState(Gadget, iCnt)&#PB_ListIcon_Selected ) ;#PB_ListIcon_Checked)
; 					Debug "checked"
					
					If (iCnt>iBorder)
						LIG_SwapItems(Gadget, iCnt, iCnt-1)
						LIG_Change=#True
					Else
						iBorder+1
; 						Debug "Eintrag ist schon der oberste erlaubte - darf nicht weiter nach oben!"
					EndIf
								
				EndIf
			Next
			
		Case #LIG_MoveDown ; 1 nach unten
			iBorder=iListCnt-1
			For iCnt=iListCnt-1 To 0 Step -1
; 				Debug Str(iCnt)+"-"+GetGadgetItemText(Gadget, iCnt, 0)
				
				If (GetGadgetItemState(Gadget, iCnt)&#PB_ListIcon_Selected ) ;#PB_ListIcon_Checked)
; 					Debug "checked"
					
					If (iCnt<iBorder)
						LIG_SwapItems(Gadget, iCnt+1, iCnt)
						LIG_Change=#True
					Else
						iBorder-1
; 						Debug "Eintrag ist schon der letzte erlaubte - darf nicht weiter nach unten!"
					EndIf
								
				EndIf
			Next
		
		Case #LIG_MoveUpTop ; ganz nach oben
			
			iSelCnt=0
			For iCnt=0 To iListCnt-1
				If (GetGadgetItemState(Gadget, iCnt)&#PB_ListIcon_Selected )
					iSelCnt+1
				EndIf
			Next
			
			iBorder=0
			While(iBorder<iSelCnt)
				iBorder=0
				For iCnt=0 To iListCnt-1
					
					If (GetGadgetItemState(Gadget, iCnt)&#PB_ListIcon_Selected ) ;#PB_ListIcon_Checked)
; 						Debug Str(iCnt)+"-"+GetGadgetItemText(#Liste, iCnt, 0)+"SELEKTIERT"
						
						If (iCnt>iBorder)
; 							Debug "Vertausche >"+Str(iCnt)+"< mit >"+Str(iCnt-1)+"< - Border >"+Str(iBorder)+"<"
							LIG_SwapItems(Gadget, iCnt, iCnt-1)
							LIG_Change=#True
						Else
							iBorder+1
; 							Debug "Eintrag >"+Str(iCnt)+"< ist schon der oberste erlaubte - darf nicht weiter nach oben! - Border >"+Str(iBorder)+"<"

						EndIf
									
					EndIf
				Next
			Wend	
			
		Case #LIG_MoveDownBottom ; ganz nach unten
			
			iSelCnt=0
			For iCnt=0 To iListCnt-1
				If (GetGadgetItemState(Gadget, iCnt)&#PB_ListIcon_Selected )
					iSelCnt+1
				EndIf
			Next
			
			iBorder=iListCnt-1
			While(iBorder>(iListCnt-1-iSelCnt))
			
				iBorder=iListCnt-1
				For iCnt=iListCnt-1 To 0 Step -1
;					Debug Str(iCnt)+"-"+GetGadgetItemText(#Liste, iCnt, 0)
					
					If (GetGadgetItemState(Gadget, iCnt)&#PB_ListIcon_Selected ) ;#PB_ListIcon_Checked)
; 						Debug Str(iCnt)+"-"+GetGadgetItemText(Gadget, iCnt, 0)+"SELEKTIERT"
						
						If (iCnt<iBorder)
; 							Debug "Vertausche >"+Str(iCnt+1)+"< mit >"+Str(iCnt)+"< - Border >"+Str(iBorder)+"<"
							LIG_SwapItems(Gadget, iCnt+1, iCnt)
							LIG_Change=#True	
						Else
							iBorder-1
; 							Debug "Eintrag >"+Str(iCnt)+"< ist schon der unterste erlaubte - darf nicht weiter nach unten! - Border >"+Str(iBorder)+"<"
						EndIf
									
					EndIf
				Next
			Wend
			
	EndSelect
			
	ProcedureReturn LIG_Change
EndProcedure

Procedure LIG_RemoveAll(id)
	
	Protected col.i
	Protected ColCnt.i=LIG_GetColumnCount(id)
	
	ClearGadgetItems(id)
	For col = 0 To ColCnt - 1
		RemoveGadgetColumn(id, 0)
	Next

EndProcedure

Procedure LIG_GetItemRect(Gadget.i, Line.i, Column.i, *Data.RECT)
	
	;Get bounding rectangle.
	*Data\top=Column
	*Data\left=#LVIR_BOUNDS
	
	SendMessage_(GadgetID(Gadget), #LVM_GETSUBITEMRECT, Line, *Data)	
	
	If Column=0 And GetGadgetAttribute(Gadget, #PB_ListIcon_DisplayMode)=#PB_ListIcon_Report ; only in Report Mode!
		*Data\right=*Data\left+GetGadgetItemAttribute(Gadget, #Null, #PB_ListIcon_ColumnWidth, Column)
	EndIf
	
EndProcedure

Procedure LIG_EnsureLineVisible(Gadget.i, Line.i)
	; makes sure the line is visible
	
	SendMessage_(GadgetID(Gadget), #LVM_ENSUREVISIBLE, Line, #True)
	
EndProcedure

Procedure LIG_EnsureCellVisible(Gadget.i, Line.i, Column.i)
	;Scroll the listicon if the clicked cell is not entirely visible
	
	Protected CellSize.RECT
	Protected ClientSize.RECT
	Protected ChangePos.b=#False
	Protected ScrollX.i
	Protected ScrollY.i
	
	LIG_GetItemRect(Gadget, Line, Column, @CellSize)
	
	LIG_EnsureLineVisible(Gadget, Line)	
	
	GetClientRect_(GadgetID(Gadget), ClientSize)
	If CellSize\left<0 Or (CellSize\right-CellSize\left)>=ClientSize\right
		ScrollX=CellSize\left
		ChangePos=#True
	ElseIf CellSize\right>ClientSize\right
		ScrollX=CellSize\right-ClientSize\right
		ChangePos=#True
	EndIf
	
	If ChangePos
		SendMessage_(GadgetID(Gadget), #LVM_SCROLL, ScrollX, 0)		
	EndIf
	
EndProcedure



Procedure LIG_GetCellFromMousePosition(Gadget.i, *Data.LIG_CellInfo)
	
	Protected PInfo.LVHITTESTINFO
	Protected CltRct.RECT
	Protected Border.b
	Protected ScrollBar.b	
	
	; Check for Scrollbars
	ScrollBar=0
	If GetWindowLong_(GadgetID(Gadget), #GWL_STYLE) & #WS_HSCROLL
		ScrollBar=GetSystemMetrics_(#SM_CXHSCROLL)
	EndIf
	
	; Calculate Gadget Border
	GetClientRect_(GadgetID(Gadget), @CltRct)
	Border=(GadgetHeight(Gadget)-CltRct\bottom-ScrollBar)/2

	;Identify the clicked item
	PInfo\pt\x = DesktopMouseX()-GadgetX(Gadget, #PB_Gadget_ScreenCoordinate)-Border
	PInfo\pt\y = DesktopMouseY()-GadgetY(Gadget, #PB_Gadget_ScreenCoordinate)-Border		
		
; 	Debug "MousePos >"+Str(PInfo\pt\x)+"< / >"+Str(PInfo\pt\y)+"<"
	If SendMessage_(GadgetID(Gadget), #LVM_SUBITEMHITTEST, 0, @PInfo) <> -1 ;A valid cell was clicked.	
		*Data\Line=PInfo\iItem
		*Data\Column=PInfo\iSubItem
		ProcedureReturn #True
	Else
		ProcedureReturn #False
	EndIf
		
EndProcedure

#HHT_ONFILTER = $10
#HHT_ONFILTERBUTTON=$20
#HHT_ONITEMSTATEICON=$1000
#HHT_ONDROPDOWN=$2000
#HHT_ONOVERFLOW=$4000
Procedure LIG_GetHeaderFromMousePosition(Gadget.i)
	
	Protected PInfo.HDHITTESTINFO
	Protected CltRct.RECT
	Protected Border.b
	Protected ScrollBar.b	
	Protected Column.i
	Protected ColumnHeader.i
	Protected ActiveWin.i
	
	; Check for Scrollbars
	ScrollBar=0
	If GetWindowLong_(GadgetID(Gadget), #GWL_STYLE) & #WS_HSCROLL
		ScrollBar=GetSystemMetrics_(#SM_CXHSCROLL)
	EndIf
	
	; Calculate Gadget Border
	GetClientRect_(GadgetID(Gadget), @CltRct)
	Border=(GadgetHeight(Gadget)-CltRct\bottom-ScrollBar)/2
	
	ColumnHeader=SendMessage_(GadgetID(Gadget), #LVM_GETHEADER, 0, 0)
	
	;Identify the clicked item
	PInfo\pt\x = DesktopMouseX()-GadgetX(Gadget, #PB_Gadget_ScreenCoordinate)-Border
	PInfo\pt\y = DesktopMouseY()-GadgetY(Gadget, #PB_Gadget_ScreenCoordinate)-Border		
	
; 	Debug "MousePos >"+Str(PInfo\pt\x)+"< / >"+Str(PInfo\pt\y)+"<"
	If SendMessage_(ColumnHeader, #HDM_HITTEST, 0, @PInfo)<>-1
; 		Debug "Header >"+Str(PInfo\iItem)+"<"
		
; 		If PInfo\flags&#HHT_ABOVE : Debug "HHT_ABOVE" : EndIf
; 		If PInfo\flags&#HHT_BELOW : Debug "HHT_BELOW" : EndIf
; 		If PInfo\flags&#HHT_NOWHERE : Debug "HHT_NOWHERE" : EndIf
; 		If PInfo\flags&#HHT_ONDIVIDER : Debug "HHT_ONDIVIDER" : EndIf
; 		If PInfo\flags&#HHT_ONDIVOPEN : Debug "HHT_ONDIVOPEN" : EndIf
; 		If PInfo\flags&#HHT_ONHEADER : Debug "HHT_ONHEADER" : EndIf
; 		If PInfo\flags&#HHT_ONFILTER : Debug "HHT_ONFILTER" : EndIf
; 		If PInfo\flags&#HHT_ONFILTERBUTTON : Debug "HHT_ONFILTERBUTTON" : EndIf
; 		If PInfo\flags&#HHT_TOLEFT : Debug "HHT_TOLEFT" : EndIf
; 		If PInfo\flags&#HHT_TORIGHT : Debug "HHT_TORIGHT" : EndIf
; 		If PInfo\flags&#HHT_ONITEMSTATEICON : Debug "HHT_ONITEMSTATEICON" : EndIf
; 		If PInfo\flags&#HHT_ONDROPDOWN : Debug "HHT_ONDROPDOWN" : EndIf
; 		If PInfo\flags&#HHT_ONOVERFLOW : Debug "HHT_ONOVERFLOW" : EndIf
		
		
		If PInfo\flags&#HHT_ONHEADER
			Column=PInfo\iItem
		EndIf
	Else
		Column=-1
	EndIf

	ProcedureReturn Column
		
EndProcedure

;- ##### ListIconGadget Tools End #####


;- ++++++ ListIconGadget Sort Start ++++++

; http://msdn.microsoft.com/de-de/library/bb979183.aspx	

; Die Struktur LVWSORT enthält Informationen über das zu sortierende ListView-Steuerelement, die Spalte,
; nach der sortiert werden soll, sowie die gewünschte Sortierrichtung.
Structure LVWSORT
  hWndListView.l ; Fensterhandle des ListView-Controls
  SortKey.l ; Spalte, die sortiert werden soll
  SortType.b ; Typ der zu sortierenden Daten
  SortOrder.b ; Sortierrichtung
  DateFormat.s ; Mask for 'ParseDate'
EndStructure

Procedure.b IsNumChar(*Text, Position.i=1)
	Select Asc(PeekS(*Text+(Position-1)*SizeOf(Character), 1))
		Case 48 To 57
			ProcedureReturn #True
		Default
			ProcedureReturn #False
	EndSelect
	
EndProcedure

Procedure.l CompareStrings(*sEntry1, *sEntry2, SortOrder.b)
	; ' -----------------------------------------------------
	; ' Gibt zurück, ob das erste der beiden unterschiedlichen
	; ' Elemente nach Maßgabe des Parameters SortOrder größer
	; ' (1 bei aufsteigender Sortierung) oder kleiner (-1 bei
	; ' aufsteigender Sortierung) als das zweite Element ist.
	; ' Gleiche Elemente wurden bereits in CompareFunc ausge-
	; ' schlossen; für sie wäre sonst 0 zurückzugeben.
	; ' -----------------------------------------------------
	; ' Rückgabewert je nach erwünschter Sortierung:
	
	If SortOrder=#LIG_AscSort
		; Aufsteigende Sortierung zweier unterschiedlicher Strings
		If CompareMemoryString(*sEntry1, *sEntry2, #PB_String_NoCase)=#PB_String_Lower
			ProcedureReturn -1
		Else
			ProcedureReturn 1
		EndIf
	Else ; Absteigende Sortierung
		If CompareMemoryString(*sEntry1, *sEntry2, #PB_String_NoCase)=#PB_String_Greater
			ProcedureReturn -1
		Else
			ProcedureReturn 1
		EndIf
	EndIf
	
EndProcedure

Procedure.l CompareNumbers(sEntry1.s, sEntry2.s, SortOrder.b)
	; ' -----------------------------------------------------
	; ' Gibt zurück, ob das erste der beiden unterschiedlichen
	; ' Elemente nach Maßgabe des Parameters SortOrder größer
	; ' (1 bei aufsteigender Sortierung) oder kleiner (-1 bei
	; ' aufsteigender Sortierung) als das zweite Element ist.
	; ' Gleiche Elemente wurden bereits in CompareFunc ausge-
	; ' schlossen; für sie wäre sonst 0 zurückzugeben.
	; ' -----------------------------------------------------
	; ' Rückgabewert je nach erwünschter Sortierung:
	
	If SortOrder=#LIG_AscSort
		; Aufsteigende Sortierung zweier unterschiedlicher Zahlen
		If Val(sEntry1)<Val(sEntry2)
			ProcedureReturn -1
		Else
			ProcedureReturn 1
		EndIf
	Else ; Absteigende Sortierung
		If Val(sEntry1)>Val(sEntry2)
			ProcedureReturn -1
		Else
			ProcedureReturn 1
		EndIf
	EndIf
	
EndProcedure

Procedure.l CompareFloat(sEntry1.s, sEntry2.s, SortOrder.b)
	; ' -----------------------------------------------------
	; ' Gibt zurück, ob das erste der beiden unterschiedlichen
	; ' Elemente nach Maßgabe des Parameters SortOrder größer
	; ' (1 bei aufsteigender Sortierung) oder kleiner (-1 bei
	; ' aufsteigender Sortierung) als das zweite Element ist.
	; ' Gleiche Elemente wurden bereits in CompareFunc ausge-
	; ' schlossen; für sie wäre sonst 0 zurückzugeben.
	; ' -----------------------------------------------------
	; ' Rückgabewert je nach erwünschter Sortierung:
	
	ReplaceString(sEntry1, ",", ".", #PB_String_InPlace, 1, 1) ; ersetze Dezimalkomma durch Punkt, damit ValF korrekt arbeitet
	ReplaceString(sEntry2, ",", ".", #PB_String_InPlace, 1, 1)
		
	If SortOrder=#LIG_AscSort
		; Aufsteigende Sortierung zweier unterschiedlicher Zahlen
		If ValF(sEntry1)<ValF(sEntry2)
			ProcedureReturn -1
		Else
			ProcedureReturn 1
		EndIf
	Else ; Absteigende Sortierung
		If ValF(sEntry1)>ValF(sEntry2)
			ProcedureReturn -1
		Else
			ProcedureReturn 1
		EndIf
	EndIf			
	
EndProcedure

Procedure.l CompareDate(sEntry1.s, sEntry2.s, SortOrder.b, sDateMask.s)
	; ' -----------------------------------------------------
	; ' Gibt zurück, ob das erste der beiden unterschiedlichen
	; ' Elemente nach Maßgabe des Parameters SortOrder größer
	; ' (1 bei aufsteigender Sortierung) oder kleiner (-1 bei
	; ' aufsteigender Sortierung) als das zweite Element ist.
	; ' Gleiche Elemente wurden bereits in CompareFunc ausge-
	; ' schlossen; für sie wäre sonst 0 zurückzugeben.
	; ' -----------------------------------------------------
	; ' Rückgabewert je nach erwünschter Sortierung:
	
	If SortOrder=#LIG_AscSort
		; Aufsteigende Sortierung zweier unterschiedlicher Zahlen
		If ParseDate(sDateMask, sEntry1)<ParseDate(sDateMask, sEntry2)
			ProcedureReturn -1
		Else
			ProcedureReturn 1
		EndIf
	Else ; Absteigende Sortierung
		If ParseDate(sDateMask, sEntry1)>ParseDate(sDateMask, sEntry2)
			ProcedureReturn -1
		Else
			ProcedureReturn 1
		EndIf
	EndIf			
	
EndProcedure

Procedure.s LvwGetText(*ListViewSort.LVWSORT, lParam.l)
	; ' -----------------------------------------------------
	; ' Ermittelt aus dem Fensterhandle des ListView-
	; ' Steuerelements, der in ListViewSort.SortKey
	; ' angegebenen (nullbasierten) Spalte im ListView
	; ' und der an CompareFunc übergebenen Werte lParam1/2
	; ' die davon repräsentierten Zelleninhalte.
	; ' -----------------------------------------------------
	
	; 20130623..nalor..Check if AllocateMemory succeeds
	;                  freememory at the end (kudos to 'Little John')
	
	Protected udtFindInfo.LV_FINDINFO
	Protected udtLVItem.LV_ITEM
	Protected lngIndex.l
	Protected *baBuffer
	Protected lngLength.l
	Protected RetVal.s=""

	*baBuffer=AllocateMemory(512)
	
	If (*baBuffer)
		; Auf Basis des Index den Text der Zelle auslesen:
		udtLVItem\mask=#LVIF_TEXT
		udtLVItem\iSubItem=*ListViewSort\SortKey
		udtLVItem\pszText=*baBuffer
		udtLVItem\cchTextMax=(512/SizeOf(Character))-1
		
		lngLength = SendMessage_(*ListViewSort\hWndListView, #LVM_GETITEMTEXT, lParam, @udtLVItem)
		
		; Byte-Array in passender Länge als String-Rückgabewert kopieren:
		If lngLength > 0
			RetVal = PeekS(*baBuffer, lngLength)
		EndIf
		FreeMemory(*baBuffer)
	Else
		Debug "ERROR!! Allocating memory (LvwGetText)"
	EndIf
	
	ProcedureReturn RetVal
EndProcedure

Procedure.l CompareFunc(lParam1.l, lParam2.l, lParamSort.l)
	; ' -----------------------------------------------------
	; ' Vergleichsfunktion CompareFunc
	; ' -----------------------------------------------------
	; ' Verglichen werden jeweils zwei Elemente der zu
	; ' sortierenden Spalte des ListView-Steuerelements,
	; ' die über lParam1 und lParam2 angegeben werden.
	; ' Hierbei wird über den Rückgabewert der Funktion
	; ' bestimmt, welches der beiden Elemente als größer
	; ' gelten soll (hier für Aufwärtssortierung):
	; ' * Element 1 < Element 2: Rückgabewert < 0
	; ' * Element 1 = Element 2: Rückgabewert = 0
	; ' * Element 1 > Element 2: Rückgabewert > 0
	; ' -----------------------------------------------------
	Protected *ListViewSort.LVWSORT
	Protected sEntry1.s
	Protected sEntry2.s
	Protected vCompare1.s ; As Variant
	Protected vCompare2.s ; As Variant
	
	; In lParamSort von SortListView als Long-Pointer übergebene LVWSORT-Struktur abholen, um auf deren
	; Werte zugreifen zu können:
	
	*ListViewSort=lParamSort
	
	; Die Werte der zu vergleichenden Elemente werden mithilfe der privaten Funktion LvwGetText aus
	; den Angaben lParam1 und lParam2 ermittelt:
	sEntry1 = LvwGetText(*ListViewSort, lParam1)
	sEntry2 = LvwGetText(*ListViewSort, lParam2)

	; Sind die Elemente gleich, kann die Funktion sofort mit dem aktuellen Rückgabewert 0
	; verlassen werden:
	If sEntry1 = sEntry2
		ProcedureReturn 0
	EndIf
	
	; Für die Sortierung wird unterschieden zwischen Zahlen, Fließkommazahlen und allgemeinen Strings. Hierfür
	; steht jeweils eine separate, private Vergleichsfunktion zur Verfügung.
	
	Select *ListViewSort\SortType
		Case #LIG_SortNumeric ; ' Spalteninhalte sind Zahlen
			ProcedureReturn CompareNumbers(sEntry1, sEntry2, *ListViewSort\SortOrder)
		Case #LIG_SortFloat ; ' Spalteninhalte sind Zahlen mit Nachkommastellen
			ProcedureReturn CompareFloat(sEntry1, sEntry2, *ListViewSort\SortOrder)
		Case #LIG_SortString;  ' Spalteninhalte sind Strings
			ProcedureReturn CompareStrings(@sEntry1, @sEntry2, *ListViewSort\SortOrder)
		Case #LIG_SortDate
			ProcedureReturn CompareDate(sEntry1, sEntry2, *ListViewSort\SortOrder, *ListViewSort\DateFormat)
	EndSelect
EndProcedure

Procedure.s GetDateFormat(Date.s)
	; 20130902..FIR..bugfix: changed %mm to %ii for minute...
	
; 	Debug "GetDateFormat >"+Date+"<"
	
	Protected Diff.i
	
	Diff=Len(Date)-CountString(Date, "0")-CountString(Date, "1")-CountString(Date, "2")-CountString(Date, "3")-CountString(Date, "4")-CountString(Date, "5")-CountString(Date, "6")-CountString(Date, "7")-CountString(Date, "8")-CountString(Date, "9")	
	
	Select Diff
		Case 2
			If Len(Date)=10 ; Date 'dd.mm.yyyy', 'mm.dd.yyyy' or 'yyyy.mm.dd'

				If (Not IsNumChar(@Date, 5) And Not IsNumChar(@Date, 8)) ; yyyy.mm.dd
					ProcedureReturn "" ; faster to sort as string
					
				ElseIf (Not IsNumChar(@Date, 3) And Not IsNumChar(@Date, 6)) ; dd.mm.yyyy or mm.dd.yyyy
					If Val(Mid(Date, 4, 2))>12 ; is it mm.dd.yyyy?
						ProcedureReturn "%mm"+Mid(Date, 3, 1)+"%dd"+Mid(Date, 6, 1)+"%yyyy"
					Else ; default is dd.mm.yyyy
						ProcedureReturn "%dd"+Mid(Date, 3, 1)+"%mm"+Mid(Date, 6, 1)+"%yyyy"
					EndIf
					
				Else
					ProcedureReturn "" ; not a date - sort as string
				EndIf
			Else
				ProcedureReturn "" ; not a date - sort as string
			EndIf
			
		Case 4
			If Len(Date)=16 ;yyyy-mm-dd hh:mm, dd-mm-yyyy hh:mm or mm-dd-yyyy hh:mm
				
				If (Not IsNumChar(@Date, 5) And Not IsNumChar(@Date, 8)) ; yyyy.mm.dd xxxxx
					ProcedureReturn "" ; faster to sort as string
					
				ElseIf (Not IsNumChar(@Date, 3) And Not IsNumChar(@Date, 6)) ; dd.mm.yyyy hh:mm or mm.dd.yyyy hh:mm
					If Val(Mid(Date, 4, 2))>12 ; is it mm.dd.yyyy?
						ProcedureReturn "%mm"+Mid(Date, 3, 1)+"%dd"+Mid(Date, 6, 1)+"%yyyy"+Mid(Date, 11, 1)+"%hh"+Mid(Date, 14, 1)+"%ii"
					Else ; default is dd.mm.yyyy
						ProcedureReturn "%dd"+Mid(Date, 3, 1)+"%mm"+Mid(Date, 6, 1)+"%yyyy"+Mid(Date, 11, 1)+"%hh"+Mid(Date, 14, 1)+"%ii"
					EndIf
					
				Else
					ProcedureReturn "" ; not a date - sort as string
				EndIf
			Else
				ProcedureReturn "" ; not a date - sort as string
			EndIf				
					
		Case 5 ; 5 other chars, possibly DateTime?
			
			If Len(Date)=19 ;yyyy-mm-dd hh:mm, dd-mm-yyyy hh:mm or mm-dd-yyyy hh:mm
				
				If (Not IsNumChar(@Date, 5) And Not IsNumChar(@Date, 8)) ; yyyy.mm.dd xxxxx
					ProcedureReturn "" ; faster to sort as string
					
				ElseIf (Not IsNumChar(@Date, 3) And Not IsNumChar(@Date, 6)) ; dd.mm.yyyy hh:mm or mm.dd.yyyy hh:mm
					If Val(Mid(Date, 4, 2))>12 ; is it mm.dd.yyyy?
						ProcedureReturn "%mm"+Mid(Date, 3, 1)+"%dd"+Mid(Date, 6, 1)+"%yyyy"+Mid(Date, 11, 1)+"%hh"+Mid(Date, 14, 1)+"%ii"+Mid(Date, 17, 1)+"%ss"
					Else ; default is dd.mm.yyyy
						ProcedureReturn "%dd"+Mid(Date, 3, 1)+"%mm"+Mid(Date, 6, 1)+"%yyyy"+Mid(Date, 11, 1)+"%hh"+Mid(Date, 14, 1)+"%ii"+Mid(Date, 17, 1)+"%ss"
					EndIf
					
				Else
					ProcedureReturn "" ; not a date - sort as string
				EndIf
			Else
				ProcedureReturn "" ; not a date - sort as string
			EndIf
			
		Default
			ProcedureReturn ""
	EndSelect
			
EndProcedure

Procedure SortListView(hWndListView.l, SortKey.l, SortType.b, SortOrder.b)
; ' -----------------------------------------------------
; ' Öffentlich aufzurufende Prozedur SortListView, die
; ' für die individuelle Sortierung einer ListView-Spalte
; ' sorgt.
; ' -----------------------------------------------------
; ' hWndListView: Fensterhandle des ListView-Steuerelements
; ' SortKey:      Spalte (nullbasiert), die sortiert werden
; '               soll (= Spaltennummer - 1).
; ' SortType:     stString, um Strings zu sortieren (Standardwert)
; '               stDate, um Datumsangaben zu sortieren
; '               stNumeric, um Zahlen zu sortieren
; ' SortOrder:    lvwAscending für aufsteigende Sortierung (Std.)
; '               lvwDescending für absteigende Sortierung
; ' -----------------------------------------------------
	
	Protected udtLVWSORT.LVWSORT
	Protected sDateFormat.s, sTemp.s, GadId.i
	
	If SortType=#LIG_SortDate
		GadId=GetDlgCtrlID_(hWndListView)
		sDateFormat=GetDateFormat(GetGadgetItemText(GadId, 0, SortKey))
		
		If sDateFormat=""
			SortType=#LIG_SortString
		Else
			sTemp=GetDateFormat(GetGadgetItemText(GadId, CountGadgetItems(GadId)-1, SortKey))
			If sTemp=""
				SortType=#LIG_SortString
			Else
				If sTemp<>sDateFormat
					If Left(sTemp, 3)="%mm" ; new format starts with %mm (.dd.yyyy) - if this US format is detected it has higher prio
						sDateFormat=sTemp
					EndIf
				EndIf
				sTemp=GetDateFormat(GetGadgetItemText(GadId, CountGadgetItems(GadId)/2, SortKey))
				If sTemp=""
					SortType=#LIG_SortString
				Else
					If sTemp<>sDateFormat
						If Left(sTemp, 3)="%mm" ; new format starts with %mm (.dd.yyyy) - if this US format is detected it has higher prio
							sDateFormat=sTemp
						EndIf
					EndIf
				EndIf	
			EndIf			
		EndIf
		udtLVWSORT\DateFormat=sDateFormat
; 		Debug "Final DateFormat >"+sDateFormat+"<"
	EndIf
	
	; Übergebene Informationen in einer LVWSORT-Struktur zusammenfassen:
	udtLVWSORT\hWndListView=hWndListView
	udtLVWSORT\SortKey=SortKey
	udtLVWSORT\SortOrder=SortOrder
	udtLVWSORT\SortType=SortType	
	
	; Eigene Sortierfunktionalität in der Funktion CompareFunc verwenden: Die Informationen der
	; LVWSORT-Struktur wird mithilfe eines Zeigers auf die Variable udtLVWSORT beigegeben:
	SendMessage_(hWndListView, #LVM_SORTITEMSEX, @udtLVWSORT, @CompareFunc())
EndProcedure	

Procedure.b DetectOrderType(sText.s)
	
	Protected Diff.i
	
	Diff=Len(sText)-CountString(sText, "0")-CountString(sText, "1")-CountString(sText, "2")-CountString(sText, "3")-CountString(sText, "4")-CountString(sText, "5")-CountString(sText, "6")-CountString(sText, "7")-CountString(sText, "8")-CountString(sText, "9")	
	
	Select Diff
		Case 0 ; es sind nur Ziffern
			ProcedureReturn #LIG_SortNumeric
			
		Case 1 ; nur 1 anderes Zeichen
			If (CountString(sText, ",")>0 Or CountString(sText, ".")>0)
				ProcedureReturn #LIG_SortFloat
			ElseIf (Left(sText, 1)="$" Or Left(sText, 1)="%") ; es ist eine HEX oder Binär Zahl
				ProcedureReturn #LIG_SortNumeric
			Else
				ProcedureReturn #LIG_SortString
			EndIf
			
		Case 2 ; 2 andere Zeichen - evtl. Datum?
			
			If (Len(sText)=10 And
			    Not IsNumChar(@sText, 3) And Not IsNumChar(@sText, 6))
				; dd-mm-yyyy or mm-dd-yyyy
				ProcedureReturn #LIG_SortDate
			Else
				; yyyy-mm-dd
				ProcedureReturn #LIG_SortString
			EndIf
			
		Case 4 ; 4 other chars, possibly DateTime?
			
			If (Len(sText)=16 And
			    Not IsNumChar(@sText, 3) And Not IsNumChar(@sText, 6) And
			    Not IsNumChar(@sText, 11) And Not IsNumChar(@sText, 14))
				;dd-mm-yyyy hh:mm or mm-dd-yyyy hh:mm
				ProcedureReturn #LIG_SortDate
			Else
				ProcedureReturn #LIG_SortString
			EndIf
			
		Case 5 ; 5 other chars, possibly DateTime?
			
			If (Len(sText)=19 And
			    Not IsNumChar(@sText, 3) And Not IsNumChar(@sText, 6) And
			    Not IsNumChar(@sText, 11) And Not IsNumChar(@sText, 14) And Not IsNumChar(@sText, 17))
				;dd-mm-yyyy hh:mm:ss or mm-dd-yyyy hh:mm:ss
				ProcedureReturn #LIG_SortDate
			Else
				ProcedureReturn #LIG_SortString
			EndIf			
	
		Default
			ProcedureReturn #LIG_SortString
			
	EndSelect

EndProcedure

Procedure LIG_SortColumn(GadId.l, Column.l, Order.b=#LIG_ChngSort, OrderType.b=#LIG_SortAutoDetect)
	
	Protected ColCnt.i
	Protected iStartT.i
	Protected iEndT.i
	Protected Temp.b
	
; 	Debug "LIG_SortColumn >"+Str(GadId)+"< Spalte >"+Str(Column)+"<"
	
	; Special Handling for CursorEdit - Part 1
	Protected *Data.LIG_SubClassInfo
	Protected CursorEdit.b=#False
	*Data=GetProp_(GadgetID(GadId), "_LIG_SubClassInfo")
	If *Data
		With *Data
			If \Enable_CursorEdit
				CursorEdit=#True
				SetGadgetState(GadId, \CursorSettings\Last_Line) ; set the current 'internal' selected line really as selected line
			EndIf
		EndWith
	EndIf
	; Special Handling for CursorEdit - Part 1 - END
	
	If Order=#LIG_ChngSort
		Select LIG_GetSortOrder(GadId, Column)
			Case #LIG_NoSort, #LIG_DescSort
				Order=#LIG_AscSort
			Case #LIG_AscSort
				Order=#LIG_DescSort
		EndSelect
	EndIf
	
	iStartT=ElapsedMilliseconds()
	
	If OrderType=#LIG_SortAutoDetect ; detect automatically - check first, last and middle item of list
		OrderType=DetectOrderType(GetGadgetItemText(GadId, 0, Column))
		If (OrderType=DetectOrderType(GetGadgetItemText(GadId, CountGadgetItems(GadId)-1, Column)))
			If (OrderType<>DetectOrderType(GetGadgetItemText(GadId, CountGadgetItems(GadId)/2, Column)))
; 				Debug "Different OrderType - use SortString 2"
				OrderType=#LIG_SortString
			EndIf
		Else
; 			Debug "Different OrderType - use SortString"
			OrderType=#LIG_SortString
		EndIf
	EndIf	
	
	SortListView(GadgetID(GadId), Column, OrderType, Order)
	
	iEndT=ElapsedMilliseconds()
	
; 	Debug "Duration >"+StrF( (iEndT-iStartT)/1000, 2)+"<"
	
	LIG_SetSortArrow(GadId, Column, Order)
	
	If (GetGadgetState(GadId)>-1)
		LIG_EnsureLineVisible(GadId, GetGadgetState(GadId))
; 		Debug "sort visible"
	EndIf
	
	; Special Handling for CursorEdit - Part 2
	If CursorEdit
		With *Data
			\CursorSettings\Last_Line=GetGadgetState(GadId)
			SetGadgetState(GadId, -1)
		EndWith
	EndIf
	; Special Handling for CursorEdit - Part 2 END
EndProcedure

Procedure LIG_RefreshSort(Gadget.i)
	
	Protected Cnt.i
	Protected Order.b
	Protected Column.i=-1
	
	; check which column is responsible for the current order
	
	For Cnt=1 To LIG_GetColumnCount(Gadget)
		Order=LIG_GetSortOrder(Gadget, Cnt)
		If Order<>#LIG_NoSort
			Column=Cnt
			Break
		EndIf
	Next
	
	If Column>=0
		LIG_SortColumn(Gadget, Column, Order)
	EndIf
	
EndProcedure

; http://msdn.microsoft.com/en-us/library/windows/desktop/bb761075%28v=vs.85%29.aspx

;- ##### ListIconGadget Sort End ######


;- ++++++ ListIconGadget Edit Start ++++++

Structure LIG_EditInfo
	GadgetType.i
	Line.i
	Column.i
	ListIconGadget.i
	EditGadget.i
	EditGadgetHwnd.i
	OrgProc.i
	OrigValue.s
	ApplyOnExit.b
EndStructure

Structure COMBOBOXINFO
	cbSize.i ; DWORD
	rcItem.RECT
	rcButton.RECT
	stateButton.i ; DWORD
	hwndCombo.i ; HWND
	hwndItem.i ; HWND
	hwndList.i ; HWND
EndStructure

Enumeration
	#LIG_EditGadget_EditBox
	#LIG_EditGadget_ComboBox
	#LIG_EditGadget_ComboBox_Editable
	#LIG_EditGadget_Date
	#LIG_EditGadget_DateTime
	#LIG_EditGadget_NoEdit
EndEnumeration

Enumeration
	#LIG_Callback_GadgetType
	#LIG_Callback_ComboItem
	#LIG_Callback_EditYesNo
	#LIG_Callback_ValueChanged
EndEnumeration

Enumeration
	#LIG_EditSetting_ApplyOnExit=1
	#LIG_EditSetting_AllowCtrlC=2
	#LIG_EditSetting_AllowCtrlV=4
EndEnumeration

;- EditCallback Prototypes
Prototype.b _LIG_Callback_GadgetType(Gadget.i, Line.i, Column.i)
Prototype.b _LIG_Callback_ComboItem(Gadget.i, Line.i, Column.i, ComboBox.i)
Prototype.b _LIG_Callback_EditYesNo(Gadget.i, Line.i, Column.i)
Prototype.b _LIG_Callback_ValueChanged(Gadget.i, Line.i, Column.i, NewValue.s)

Procedure GetMinHeight_ComboBox(Gadget)
	
	Protected DC.i
	Protected Font.i
	Protected Size.SIZE
	Protected Height.i
	
	DC = GetDC_(GadgetID(Gadget))
	Font = SelectObject_(DC, GetGadgetFont(Gadget))
	
	GetTextExtentPoint32_(DC, @"Hg", 2, @Size)
	Height=Size\cy + 8
	If Height<21
		Height=21
	EndIf
	SelectObject_(DC, Font)
	ReleaseDC_(GadgetID(Gadget), DC)
	
	ProcedureReturn Height

EndProcedure

Procedure CalcAndSetMinDroppedWidth_ComboBox(Gadget)
	
	Protected DC.i
	Protected Font.i
	Protected Size.SIZE
	Protected Cnt.i
	Protected sTmp.s
	Protected NewWidth.i
	
	DC = GetDC_(GadgetID(Gadget))
	Font = SelectObject_(DC, GetGadgetFont(Gadget))
	NewWidth=GadgetWidth(Gadget)
	For Cnt=0 To CountGadgetItems(Gadget)-1
		sTmp=GetGadgetItemText(Gadget, Cnt)
		GetTextExtentPoint32_(DC, @sTmp, Len(sTmp), @Size)
		If (Size\cx+8)>NewWidth
			NewWidth=Size\cx+8
		EndIf
	Next
	SelectObject_(DC, Font)
	ReleaseDC_(GadgetID(Gadget), DC)
	SendMessage_(GadgetID(Gadget), #CB_SETDROPPEDWIDTH, NewWidth, 0)

EndProcedure

Procedure _LIG_ResizeComboCox(Gadget)
	
	Protected OldGadY.i
	Protected OldHeight.i
	Protected NewHeight.i
	Protected NewDroppedWidth.i
	
	OldHeight=GadgetHeight(Gadget)
	NewHeight=GetMinHeight_ComboBox(Gadget)
	If OldHeight<NewHeight
		OldGadY=GadgetY(Gadget)
		
		ResizeGadget(Gadget, #PB_Ignore, OldGadY-((NewHeight-OldHeight)/2), #PB_Ignore, NewHeight)
	EndIf

EndProcedure


Macro _LIG_EditEndCancel
	SetWindowLongPtr_(*Data\EditGadgetHwnd, #GWL_WNDPROC, *Data\OrgProc)
	
	; Remove the Data in the CommonStructure
	*CommonData=GetProp_(GadgetID(*Data\ListIconGadget), "_LIG_SubClassInfo")
	If *CommonData
		*CommonData\EditSettings\EditGadgetMem=0
	EndIf	
	
	FreeGadget(*Data\EditGadget)
	SetActiveGadget(*Data\ListIconGadget)
	FreeMemory(*Data)
EndMacro

Macro _LIG_EditEndApply
	SetGadgetItemText(*Data\ListIconGadget, *Data\Line, GetGadgetText(*Data\EditGadget), *Data\Column)
	
	_LIG_EditEndCancel
EndMacro

Procedure.i _LIG_EditCallback(hwnd, msg, wParam, lParam)
	Protected *Data.LIG_EditInfo
	Protected NotHandled.b=#True
	Protected NewValue.s
	Protected ApplyValue.b=#True
	Protected ValueChangedCB._LIG_Callback_ValueChanged
	Protected *CommonData.LIG_SubClassInfo ; this is necessary for the '_LIG_EditEndCancel' macro!
	
	*Data=GetWindowLongPtr_(hwnd, #GWL_USERDATA)
	Select msg
		Case #WM_CHAR
			
			Select wparam
				Case #VK_RETURN
; 					Debug "RETURN"
					NewValue=GetGadgetText(*Data\EditGadget)
					
					If NewValue<>*Data\OrigValue ; in case the new value is different from the previous value
						ValueChangedCB=GetProp_(GadgetID(*Data\ListIconGadget), "_LIG_Edit_ValueChangedCB")
						If ValueChangedCB<> #Null
							ApplyValue=ValueChangedCB(*Data\ListIconGadget, *Data\Line, *Data\Column, NewValue)
						EndIf					
					
						If ApplyValue
							_LIG_EditEndApply   		
						Else
							_LIG_EditEndCancel
						EndIf
					Else ; nothing changed
						_LIG_EditEndCancel
					EndIf
					NotHandled=#False
					
				Case #VK_ESCAPE
; 					Debug "ESCAPE"
					_LIG_EditEndCancel
					NotHandled=#False	
			EndSelect
			
		Case #WM_KILLFOCUS
; 			Debug "KILLFOCUS"
			If *Data\ApplyOnExit
				
				NewValue=GetGadgetText(*Data\EditGadget)
				
				If NewValue<>*Data\OrigValue ; in case the new value is different from the previous value
					ValueChangedCB=GetProp_(GadgetID(*Data\ListIconGadget), "_LIG_Edit_ValueChangedCB")
					If ValueChangedCB<> #Null
						ApplyValue=ValueChangedCB(*Data\ListIconGadget, *Data\Line, *Data\Column, NewValue)
					EndIf					
				
					If ApplyValue
						_LIG_EditEndApply   		
					Else
						_LIG_EditEndCancel
					EndIf
				Else ; nothing changed
					_LIG_EditEndCancel
				EndIf				

			Else
				_LIG_EditEndCancel
			EndIf
			NotHandled=#False
	EndSelect
   
   If NotHandled
   	ProcedureReturn CallWindowProc_(*Data\OrgProc, hwnd, msg, wParam, lParam)
   EndIf
EndProcedure

Procedure.i LIG_StartEdit(Gadget.i, GadgetType.i=#LIG_EditGadget_EditBox, *CellInfo.LIG_CellInfo=0)
	
	Protected PInfo.LVHITTESTINFO
	Protected ItemSize.RECT
	Protected WinPos.WINDOWPOS
	Protected EditGadget.i
	Protected ComboGadget.i
	Protected CltRct.RECT
	Protected Border.b
	Protected ScrollBar.b
	Protected CmbBoxInfo.COMBOBOXINFO
	Protected EditBoxHwnd.i
	Protected CellInfo.LIG_CellInfo
	Protected *Data.LIG_EditInfo
	Protected ValidCell.b=#False
	Protected Callback_GadgetType._LIG_Callback_GadgetType
	Protected Callback_ComboItem._LIG_Callback_ComboItem
	Protected *CommonData.LIG_SubClassInfo
	Protected OldGadgetList.i
	
	Protected Cnt.i
	Protected sTmp.s
	Protected bTmp.b
	Protected iTmp.i
		
	If *CellInfo
		CellInfo\Line=*CellInfo\Line
		CellInfo\Column=*CellInfo\Column
		ValidCell=#True
	ElseIf LIG_GetCellFromMousePosition(Gadget, @CellInfo)
		ValidCell=#True
	EndIf
	
	If ValidCell  ;A valid cell was clicked.
		
		*CommonData=GetProp_(GadgetID(Gadget), "_LIG_SubClassInfo")
		
		*Data=AllocateMemory(SizeOf(LIG_EditInfo))
		
 		If *Data
			Callback_GadgetType=GetProp_(GadgetID(Gadget), "_LIG_Edit_GadgetTypeCB")
			If Callback_GadgetType
				GadgetType=Callback_GadgetType(Gadget, CellInfo\Line, CellInfo\Column)
			EndIf
			
			Select GadgetType
				Case #LIG_EditGadget_NoEdit
					MessageBeep_(#MB_ICONERROR)
					EditGadget=0
					
				Case #LIG_EditGadget_EditBox, #LIG_EditGadget_ComboBox, #LIG_EditGadget_ComboBox_Editable, #LIG_EditGadget_Date, #LIG_EditGadget_DateTime
					LIG_EnsureCellVisible(Gadget, CellInfo\Line, CellInfo\Column)
					LIG_GetItemRect(Gadget, CellInfo\Line, CellInfo\Column, @ItemSize)
					
					If *CommonData
						OldGadgetList=UseGadgetList(*CommonData\GadgetList)
					Else
						OldGadgetList=-1
					EndIf
					
					*Data\OrigValue=GetGadgetItemText(Gadget, CellInfo\Line, CellInfo\Column)
					Select GadgetType
						Case #LIG_EditGadget_EditBox
							EditGadget=StringGadget(#PB_Any, ItemSize\left, ItemSize\top, ItemSize\right-ItemSize\left, ItemSize\bottom-ItemSize\top, *Data\OrigValue)
							EditBoxHwnd=GadgetID(EditGadget)
							
						Case #LIG_EditGadget_ComboBox
; 							Debug "Combo Height >"+Str(ItemSize\bottom-ItemSize\top)+"<"
							EditGadget=ComboBoxGadget(#PB_Any, ItemSize\left, ItemSize\top, ItemSize\right-ItemSize\left, ItemSize\bottom-ItemSize\top)
							EditBoxHwnd=GadgetID(EditGadget)				
							
						Case #LIG_EditGadget_ComboBox_Editable
							EditGadget=ComboBoxGadget(#PB_Any, ItemSize\left, ItemSize\top, ItemSize\right-ItemSize\left, ItemSize\bottom-ItemSize\top, #PB_ComboBox_Editable)
							SetGadgetText(EditGadget, *Data\OrigValue)
							
							CmbBoxInfo\cbSize=SizeOf(COMBOBOXINFO)
							If GetComboBoxInfo_(GadgetID(EditGadget), @CmbBoxInfo)
								EditBoxHwnd=CmbBoxInfo\hwndItem
							Else
								EditBoxHwnd=0
								Debug "ERROR!!"
							EndIf
							
						Case #LIG_EditGadget_Date, #LIG_EditGadget_DateTime
; 							Debug "Combo Height >"+Str(ItemSize\bottom-ItemSize\top)+"<"
							sTmp=GetDateFormat(*Data\OrigValue)
							If sTmp=""
								If GadgetType=#LIG_EditGadget_DateTime
									sTmp="%yyyy.%mm.%dd %hh:%ii"
								Else
									sTmp="%yyyy.%mm.%dd"
								EndIf
								iTmp=0
							Else
								iTmp=ParseDate(sTmp, *Data\OrigValue)
								sTmp=ReplaceString(sTmp, "%ss", FormatDate("%ss", iTmp)) ; seconds cannot be changed with the dategadget - so make it static											
							EndIf
							EditGadget=DateGadget(#PB_Any, ItemSize\left, ItemSize\top, ItemSize\right-ItemSize\left, ItemSize\bottom-ItemSize\top, sTmp, iTmp)
							EditBoxHwnd=GadgetID(EditGadget)							
							
						Default
; 							Debug "GadgetType not supported"
							EditBoxHwnd=0
					EndSelect
					
					If OldGadgetList<>-1
						UseGadgetList(OldGadgetList) ; reset it to previous value - we don't want to disturb something else..
					EndIf
					
					If GadgetType=#LIG_EditGadget_ComboBox Or GadgetType=#LIG_EditGadget_ComboBox_Editable
						
						_LIG_ResizeComboCox(EditGadget) 					
						
						Callback_ComboItem=GetProp_(GadgetID(Gadget), "_LIG_Edit_ComboItemCB")
						If Callback_ComboItem
							Callback_ComboItem(Gadget, CellInfo\Line, CellInfo\Column, EditGadget)
						EndIf				
						
						If GadgetType=#LIG_EditGadget_ComboBox
							bTmp=#False
							For Cnt=0 To CountGadgetItems(EditGadget)-1
								If GetGadgetItemText(EditGadget, Cnt)=*Data\OrigValue ; we've found the entry!
									SetGadgetState(EditGadget, Cnt)		
									bTmp=#True
									Break
								EndIf
							Next
							
							If Not bTmp ; in case the current text is not in the dropdown list
								AddGadgetItem(EditGadget, 0, *Data\OrigValue) ; add it at the first position
								SetGadgetState(EditGadget, 0)		
							EndIf	
						EndIf	
							
						CalcAndSetMinDroppedWidth_ComboBox(EditGadget) ; now we should have a complete list of gadgetitems for the dropbox - now we can calc and set the dropped width
					EndIf
					
					If EditBoxHwnd
						SetGadgetFont(EditGadget, GetGadgetFont(Gadget))
						
						SetParent_(GadgetID(EditGadget), GadgetID(Gadget)) ; wichtig !!!
						SetActiveGadget(EditGadget)
						
						*Data\GadgetType=GadgetType
						*Data\EditGadget=EditGadget
						*Data\ListIconGadget=Gadget
						*Data\Line=CellInfo\Line
						*Data\Column=CellInfo\Column
						If *CommonData
							*Data\ApplyOnExit=*CommonData\EditSettings\Edit_ApplyOnExit
						EndIf
						
						If EditBoxHwnd
							*Data\EditGadgetHwnd=EditBoxHwnd
							*Data\OrgProc=GetWindowLongPtr_(EditBoxHwnd, #GWL_WNDPROC)
							SetWindowLongPtr_(EditBoxHwnd, #GWL_USERDATA, *Data)
							SetWindowLongPtr_(EditBoxHwnd, #GWL_WNDPROC, @_LIG_EditCallback())
						EndIf
					Else
						EditGadget=0
					EndIf
					
					; Special Handling to offer CancelEdit from outside
					If EditGadget
						If *CommonData
							*CommonData\EditSettings\EditGadgetMem=*Data
						EndIf
					Else ; in case no EditGadget has been created free the memory as it's not used anyway
						FreeMemory(*Data)
					EndIf							
				Default
					Debug "invalid GadgetType selected!"
					
			EndSelect
 		EndIf
	Else
		Debug "Not a valid cell!"
		EditGadget=0
	EndIf
	
	ProcedureReturn EditGadget

EndProcedure

Procedure.i LIG_CancelEdit(Gadget.i)
	Protected *Data.LIG_EditInfo
	Protected ValidCell.b=#False
	Protected *EditCallback
	Protected *CommonData.LIG_SubClassInfo
	
	*CommonData=GetProp_(GadgetID(Gadget), "_LIG_SubClassInfo")
	If *CommonData
		*Data=*CommonData\EditSettings\EditGadgetMem
		If *Data
			_LIG_EditEndCancel
		EndIf
	EndIf
	
EndProcedure

Procedure.b LIG_Edit_SetCallback(Gadget.i, CallbackType.i, *Callback)
	Protected PropertyName.s
	
	Select CallbackType
		Case #LIG_Callback_GadgetType
			PropertyName="_LIG_Edit_GadgetTypeCB"
		Case #LIG_Callback_ComboItem
			PropertyName="_LIG_Edit_ComboItemCB"
		Case #LIG_Callback_EditYesNo
			PropertyName="_LIG_Edit_EditYesNoCB"
		Case #LIG_Callback_ValueChanged
			PropertyName="_LIG_Edit_ValueChangedCB"
		Default
			ProcedureReturn #False
	EndSelect
			
	If *Callback
		SetProp_(GadgetID(Gadget), PropertyName, *Callback)
	Else
		RemoveProp_(GadgetID(Gadget), PropertyName)
	EndIf		
	ProcedureReturn #True
EndProcedure

;- Callback Examples

; #LIG_Callback_GadgetType
; expects the address of a procedure that accepts 3 parameters (Gadget, Line, Column) and returns one of the possible Type-Values
; or '0' to remove the Callback	
; EXAMPLE:
; Procedure PossibleEditGadgetTypeCallback(Gadget.i, Line.i, Column.i)
; 	Select Random(4, 1)
; 		Case 1 : ProcedureReturn #LIG_EditBox
; 		Case 2 : ProcedureReturn #LIG_ComboBox
; 		Case 3 : ProcedureReturn #LIG_ComboBox_Editable
; 		Case 4 : ProcedureReturn #LIG_NoEdit
; 	EndSelect
; EndProcedure

; #LIG_Callback_ComboItem
; expects the address of a procedure that accepts 4 parameters (Gadget, Line, Column, ComboBox)
; or '0' to remove the Callback
; EXAMPLE:
; Procedure PossibleComboGadgetCallback(Gadget.i, Line.i, Column.i, ComboBox.i)
; 	AddGadgetItem(ComboBox, -1, "Item Number 0") 
; 	AddGadgetItem(ComboBox, -1, "Item Number 1") 
; 	AddGadgetItem(ComboBox, -1, "Item Number 2") 
; 	AddGadgetItem(ComboBox, -1, "Item Number 3") 
; EndProcedure

; #LIG_Callback_EditYesNo
; expects the address of a procedure that accepts 3 parameters (Gadget, Line, Column)
; or '0' to remove the Callback	
; EXAMPLE:
; Procedure PossibleEditYesNoCallback(Gadget.i, Line.i, Column.i)
; 	If Line=3
; 		ProcedureReturn #False
; 	Else
; 		ProcedureReturn #True
; 	EndIf
; EndProcedure	

; #LIG_Callback_ValueChanged
; expects the address of a procedure that accepts 3 parameters (Gadget, Line, Column)
; or '0' to remove the Callback	
; EXAMPLE:
; Procedure PossibleEditValueChangedCallback(Gadget.i, Line.i, Column.i)
; 	If Line=3
; 		ProcedureReturn #False
; 	Else
; 		ProcedureReturn #True
; 	EndIf
; EndProcedure	

;- ###### ListIconGadget Edit End ########
;- ++++++ ListIconGadget CursorSelect Start ++++++

Procedure _LIG_DeselectCell(*Data.LIG_SubClassInfo)
	; Reset Last Selected Cell
; 	Debug "_LIG_DeselectCell"
	If *Data\CursorSettings\Last_Valid ; only if there has been a last cell!
		SetGadgetItemColor(*Data\ListIconGadget, *Data\CursorSettings\Last_Line, #PB_Gadget_FrontColor, *Data\CursorSettings\Last_Color_Front, *Data\CursorSettings\Last_Column)
		SetGadgetItemColor(*Data\ListIconGadget, *Data\CursorSettings\Last_Line, #PB_Gadget_BackColor, *Data\CursorSettings\Last_Color_Back, *Data\CursorSettings\Last_Column)
		*Data\CursorSettings\Last_Valid=#False
	EndIf	
	
EndProcedure

Procedure _LIG_SelectCell(Line.i, Column.i, *Data.LIG_SubClassInfo)
; 	Debug "_LIG_SelectCell"
	If CountGadgetItems(*Data\ListIconGadget)>0
		; Remove official 'Selected' Item
		SetGadgetState(*Data\ListIconGadget, -1)
		
		_LIG_DeselectCell(*Data) 
		
		; now save the new values as 'last' values
		*Data\CursorSettings\Last_Color_Front=GetGadgetItemColor(*Data\ListIconGadget, Line, #PB_Gadget_FrontColor, Column)
		*Data\CursorSettings\Last_Color_Back=GetGadgetItemColor(*Data\ListIconGadget, Line, #PB_Gadget_BackColor, Column)
		*Data\CursorSettings\Last_Line=Line
		*Data\CursorSettings\Last_Column=Column
		*Data\CursorSettings\Last_Valid=#True
		; and apply the 'select' color
		SetGadgetItemColor(*Data\ListIconGadget, *Data\CursorSettings\Last_Line, #PB_Gadget_FrontColor, *Data\CursorSettings\Color_Front, *Data\CursorSettings\Last_Column)
		
		If GetActiveGadget()=*Data\ListIconGadget
			SetGadgetItemColor(*Data\ListIconGadget, *Data\CursorSettings\Last_Line, #PB_Gadget_BackColor, *Data\CursorSettings\Color_Back, *Data\CursorSettings\Last_Column)
		Else
			SetGadgetItemColor(*Data\ListIconGadget, *Data\CursorSettings\Last_Line, #PB_Gadget_BackColor, *Data\CursorSettings\Color_Back_Inactive, *Data\CursorSettings\Last_Column)			
		EndIf
		
		LIG_EnsureCellVisible(*Data\ListIconGadget, *Data\CursorSettings\Last_Line, *Data\CursorSettings\Last_Column)
	EndIf
EndProcedure

Procedure _LIG_ActInactCell(*Data.LIG_SubClassInfo, ActiveCell.b)
; 	Debug "_LIG_ActInactCell"
	If *Data\CursorSettings\Last_Valid
		If ActiveCell
; 			Debug "ACTIVE CELL"
			; set selected cell active
			SetGadgetItemColor(*Data\ListIconGadget, *Data\CursorSettings\Last_Line, #PB_Gadget_BackColor, *Data\CursorSettings\Color_Back, *Data\CursorSettings\Last_Column)
			
		Else
; 			Debug "INACTIVE CELL"
			; set selected cell inactive
			SetGadgetItemColor(*Data\ListIconGadget, *Data\CursorSettings\Last_Line, #PB_Gadget_BackColor, *Data\CursorSettings\Color_Back_Inactive, *Data\CursorSettings\Last_Column)
			
		EndIf
	EndIf
	
EndProcedure

Procedure _LIG_MouseSelect(*Data.LIG_SubClassInfo)
	
	Protected CellInfo.LIG_CellInfo
	
	If LIG_GetCellFromMousePosition(*Data\ListIconGadget, @CellInfo)
; 		Debug "CellPosition >"+Str(CellInfo\Line)+"< >"+Str(CellInfo\Column)+"<"
		_LIG_SelectCell(CellInfo\Line, CellInfo\Column, *Data)
	EndIf
			
EndProcedure

Procedure _LIG_EditSelected(*Data.LIG_SubClassInfo)
	
	Protected CellInfo.LIG_CellInfo
	
; 	Debug "_LIG_EditSelected"
	
	If *Data\CursorSettings\Last_Valid
; 		Debug "Last Valid >"+Str(*Data\CursorSettings\Last_Line)+"<  >"+Str(*Data\CursorSettings\Last_Column)+"<"
		CellInfo\Line=*Data\CursorSettings\Last_Line
		CellInfo\Column=*Data\CursorSettings\Last_Column
	Else
; 		Debug "Current"
		CellInfo\Line=GetGadgetState(*Data\ListIconGadget)
		If CellInfo\Line=-1
			CellInfo\Line=0
		EndIf
		CellInfo\Column=0
	EndIf
	
	LIG_StartEdit(*Data\ListIconGadget, #LIG_EditGadget_EditBox, @CellInfo)
	
EndProcedure

Procedure _LIG_ChangeSelectedCell(*Data.LIG_SubClassInfo, Keypress.i)
	
	Protected NewCellInfo.LIG_CellInfo
	Protected CellChange.b=#False
	
	If *Data\CursorSettings\Last_Valid
		Select Keypress
			Case #VK_LEFT
				If *Data\CursorSettings\Last_Column>0
					NewCellInfo\Column=*Data\CursorSettings\Last_Column-1
					NewCellInfo\Line=*Data\CursorSettings\Last_Line
					CellChange=#True
				EndIf
							
			Case #VK_RIGHT
				If *Data\CursorSettings\Last_Column<(LIG_GetColumnCount(*Data\ListIconGadget)-1)
					NewCellInfo\Column=*Data\CursorSettings\Last_Column+1
					NewCellInfo\Line=*Data\CursorSettings\Last_Line
					CellChange=#True
				EndIf
				
			Case #VK_UP	
				If *Data\CursorSettings\Last_Line>0
					NewCellInfo\Column=*Data\CursorSettings\Last_Column
					NewCellInfo\Line=*Data\CursorSettings\Last_Line-1
					CellChange=#True
				EndIf
							
			Case #VK_DOWN
				If *Data\CursorSettings\Last_Line<(CountGadgetItems(*Data\ListIconGadget)-1)
					NewCellInfo\Column=*Data\CursorSettings\Last_Column
					NewCellInfo\Line=*Data\CursorSettings\Last_Line+1
					CellChange=#True
				EndIf			
				
		EndSelect
		
	Else ; there has been no selected cell before
		If GetGadgetState(*Data\ListIconGadget)>0
			NewCellInfo\Line=GetGadgetState(*Data\ListIconGadget)
			NewCellInfo\Column=0
			
			Select Keypress
				Case #VK_RIGHT
					If NewCellInfo\Line<(LIG_GetColumnCount(*Data\ListIconGadget)-1)
						NewCellInfo\Column+1
					EndIf
					
				Case #VK_UP	
					If NewCellInfo\Line>0
						NewCellInfo\Line-1
					EndIf
								
				Case #VK_DOWN
					If NewCellInfo\Line<(CountGadgetItems(*Data\ListIconGadget)-1)
						NewCellInfo\Line+1
					EndIf
			EndSelect			
			
		Else
			NewCellInfo\Line=0	
			NewCellInfo\Column=0
		EndIf
		
		CellChange=#True
	EndIf
		
	If CellChange
		_LIG_SelectCell(NewCellInfo\Line, NewCellInfo\Column, *Data)
	EndIf
	
EndProcedure

Procedure _LIG_Edit_ApplyClipboardText(*Data.LIG_SubClassInfo)
	Protected Line.i
	Protected Column.i
	Protected ClipTxt.s
	Protected Callback_GadgetType._LIG_Callback_GadgetType
	Protected Callback_ComboItem._LIG_Callback_ComboItem
	Protected GadgetType.i
	Protected sTmp.s
	Protected OldGadgetList.i
	Protected EditGadget.i
	Protected ApplyClipTxt.b=#False
	Protected ValueChangedCB._LIG_Callback_ValueChanged
	Protected CurItemTxt.s
	
	ClipTxt=GetClipboardText()

	If Trim(ClipTxt)<>""
		If *Data\CursorSettings\Last_Valid ; if a valid cell has been clicked
			Line=*Data\CursorSettings\Last_Line
			Column=*Data\CursorSettings\Last_Column
		ElseIf GetGadgetAttribute(*Data\ListIconGadget, #PB_ListIcon_DisplayMode)<>#PB_ListIcon_Report And GetGadgetState(*Data\ListIconGadget)>=0
			Line=GetGadgetState(*Data\ListIconGadget)
			Column=0
		EndIf
		
		CurItemTxt=GetGadgetItemText(*Data\ListIconGadget, Line, Column)
		
		If CurItemTxt<>ClipTxt
			
			Callback_GadgetType=GetProp_(GadgetID(*Data\ListIconGadget), "_LIG_Edit_GadgetTypeCB")
			If Callback_GadgetType
				GadgetType=Callback_GadgetType(*Data\ListIconGadget, Line, Column)
			Else
				GadgetType=#LIG_EditGadget_EditBox
			EndIf
			Select GadgetType
				Case #LIG_EditGadget_NoEdit
					
				Case #LIG_EditGadget_EditBox, #LIG_EditGadget_ComboBox_Editable
					ApplyClipTxt=#True
					
				Case #LIG_EditGadget_Date, #LIG_EditGadget_DateTime
					sTmp=GetDateFormat(ClipTxt)
					If sTmp<>""
						If FindString(sTmp, "%hh") And GadgetType=#LIG_EditGadget_Date
							Debug "not allowed to insert datetime text into date field!"
						Else
							ApplyClipTxt=#True
						EndIf
					EndIf
					
				Case #LIG_EditGadget_ComboBox
					
					Callback_ComboItem=GetProp_(GadgetID(*Data\ListIconGadget), "_LIG_Edit_ComboItemCB")
					If Callback_ComboItem				
						
						OldGadgetList=UseGadgetList(*Data\GadgetList)
						EditGadget=ComboBoxGadget(#PB_Any, 0, 0, 0, 0)
						UseGadgetList(OldGadgetList) ; reset it to previous value - we don't want to disturb something else..
						Callback_ComboItem(*Data\ListIconGadget, Line, Column, EditGadget)
						
						SetGadgetText(EditGadget, ClipTxt)
						If GetGadgetText(EditGadget)=ClipTxt ; text is in the itemlist of the combobox
							ApplyClipTxt=#True
						EndIf
						
						FreeGadget(EditGadget)
					EndIf						
					
				Default
					Debug "unknown gadgettype!"
			EndSelect
			
			If ApplyClipTxt ; in case the clipboard text fits into the item
				ValueChangedCB=GetProp_(GadgetID(*Data\ListIconGadget), "_LIG_Edit_ValueChangedCB")
				If ValueChangedCB<>#Null
					ApplyClipTxt=ValueChangedCB(*Data\ListIconGadget, Line, Column, ClipTxt)
				EndIf					
				If ApplyClipTxt
					SetGadgetItemText(*Data\ListIconGadget, Line, ClipTxt, Column)
				EndIf				
			Else ; in case it doesnt fit into the item
				MessageBeep_(#MB_ICONERROR) ; combination not allowed
			EndIf
		EndIf
	EndIf
		
EndProcedure

Procedure.i LIG_GetGadgetState(Gadget.i, GetColumn.b=#False)
	; returns the currently selected row (or column)
	Protected *Data.LIG_SubClassInfo
	
	*Data=GetProp_(GadgetID(Gadget), "_LIG_SubClassInfo")	
	
	If *Data
		If (*Data\Enable_CursorEdit Or *Data\Enable_MouseEdit) And *Data\CursorSettings\Last_Valid
			If Not GetColumn
				ProcedureReturn *Data\CursorSettings\Last_Line
			Else
				ProcedureReturn *Data\CursorSettings\Last_Column
			EndIf
		EndIf
	EndIf
			
	ProcedureReturn GetGadgetState(Gadget)
	
EndProcedure

Procedure LIG_SetGadgetState(Gadget.i, Line.i, Column.i=0)
	; sets the currently selected row
	Protected *Data.LIG_SubClassInfo
	
	*Data=GetProp_(GadgetID(Gadget), "_LIG_SubClassInfo")	
	
	If *Data
		If *Data\Enable_CursorEdit Or *Data\Enable_MouseEdit
			_LIG_SelectCell(Line, Column, *Data)
			ProcedureReturn
		EndIf
	EndIf
			
	SetGadgetState(Gadget, Line.i)
	
EndProcedure

Procedure LIG_GetGadgetItemColor(Gadget.i, Line.i, ColorType.i, Column.i=0)
	; returns the requested color
	Protected *Data.LIG_SubClassInfo
	
	*Data=GetProp_(GadgetID(Gadget), "_LIG_SubClassInfo")	
	
	If *Data
		If *Data\Enable_CursorEdit
			If Line=*Data\CursorSettings\Last_Line And Column=*Data\CursorSettings\Last_Column
				Select ColorType
					Case #PB_Gadget_FrontColor
						ProcedureReturn *Data\CursorSettings\Last_Color_Front
					Case #PB_Gadget_BackColor
						ProcedureReturn *Data\CursorSettings\Last_Color_Back
				EndSelect
			EndIf
		EndIf
	EndIf
	
	ProcedureReturn GetGadgetItemColor(Gadget, Line, ColorType, Column)
	
EndProcedure

Procedure LIG_SetGadgetItemColor(Gadget.i, Line.i, ColorType.i, Color.i, Column.i=0)
	; sets the requested color
	Protected *Data.LIG_SubClassInfo
	
	*Data=GetProp_(GadgetID(Gadget), "_LIG_SubClassInfo")	
	
	SetGadgetItemColor(Gadget, Line, ColorType, Color, Column)
	
	If *Data
		If *Data\Enable_CursorEdit
			If Line=*Data\CursorSettings\Last_Line And
			   (Column=*Data\CursorSettings\Last_Column Or Column=-1)
				Select ColorType
					Case #PB_Gadget_FrontColor
						*Data\CursorSettings\Last_Color_Front=Color
					Case #PB_Gadget_BackColor
						*Data\CursorSettings\Last_Color_Back=Color
				EndSelect
				SetGadgetItemColor(Gadget, Line, ColorType, Color, *Data\CursorSettings\Last_Column)
			EndIf
		EndIf
	EndIf
	
EndProcedure

;- ###### ListIconGadget CursorSelect End ########

Procedure.i _LIG_RemoveAllProps(*Data.LIG_SubClassInfo)
	If *Data
		With *Data
			RemoveProp_(GadgetID(*Data\ListIconGadget), "_LIG_Edit_GadgetTypeCB")
			RemoveProp_(GadgetID(*Data\ListIconGadget), "_LIG_Edit_ComboItemCB")
			RemoveProp_(GadgetID(*Data\ListIconGadget), "_LIG_Edit_EditYesNoCB")
			RemoveProp_(GadgetID(*Data\ListIconGadget), "_LIG_Edit_ValueChangedCB")			
			RemoveProp_(GadgetID(*Data\ListIconGadget), "_LIG_SubClassInfo") ; remove the custom property
			
			SetWindowLongPtr_(GadgetID(*Data\ListIconGadget), #GWL_WNDPROC, \OrgProc) ; remove the subclassing
			FreeMemory(*Data) ; and free the memory
		EndWith		
	EndIf	
EndProcedure

Procedure.i _LIG_CommonCallback(hwnd, msg, wParam, lParam)
	Protected *Data.LIG_SubClassInfo
	Protected *WmNotify.NMHDR
	Protected *msg.NM_LISTVIEW
	Protected *Notify.NMHEADER
	Protected *CustDraw.NMLVCUSTOMDRAW
	Protected *ListViewItem.LVITEM
	Protected *ListViewColumn.LVCOLUMN
	Protected NotHandled.b=#True
	Protected iTmp.i
	Protected Callback_EditYesNo._LIG_Callback_EditYesNo
	Protected CellInfo.LIG_CellInfo
	
	*Data=GetProp_(hwnd, "_LIG_SubClassInfo")
	Select msg

		Case #WM_KEYDOWN
; 			Debug "WM_KEYDOWN"
			If *Data\Enable_CursorEdit
				Select wparam
					Case #VK_LEFT, #VK_RIGHT, #VK_UP, #VK_DOWN
; 						Debug "VK_LEFT/VK_RIGHT/VK_UP/VK_DOWN"
						If GetGadgetAttribute(*Data\ListIconGadget, #PB_ListIcon_DisplayMode)=#PB_ListIcon_Report
							_LIG_ChangeSelectedCell(*Data, wparam)
							NotHandled=#False
						Else ; if not in report mode let windows handle the cursor movement
							_LIG_DeselectCell(*Data)
						EndIf
						
					Case #VK_RETURN
; 						Debug "VK_RETURN"
						Callback_EditYesNo=GetProp_(GadgetID(*Data\ListIconGadget), "_LIG_Edit_EditYesNoCB")
						If Callback_EditYesNo ; a callback is specified
							If *Data\CursorSettings\Last_Valid ; if a valid cell has been clicked
								iTmp=Callback_EditYesNo(*Data\ListIconGadget, *Data\CursorSettings\Last_Line, *Data\CursorSettings\Last_Column)
							ElseIf GetGadgetAttribute(*Data\ListIconGadget, #PB_ListIcon_DisplayMode)<>#PB_ListIcon_Report And GetGadgetState(*Data\ListIconGadget)>=0
								iTmp=Callback_EditYesNo(*Data\ListIconGadget, GetGadgetState(*Data\ListIconGadget), 0)
							Else
								iTmp=#False
							EndIf
						Else
							iTmp=#True
						EndIf
; 						Debug "VK Return Tmp >"+Str(iTmp)+"<"
						If iTmp
							_LIG_EditSelected(*Data)
							NotHandled=#False
						EndIf						
						
					Case Asc("C")
						If (GetKeyState_(#VK_CONTROL)&128)
; 							Debug "CTRL-C"
							If *Data\EditSettings\Edit_AllowCtrlC And *Data\Enable_CursorEdit
								If *Data\CursorSettings\Last_Valid
									SetClipboardText(GetGadgetItemText(*Data\ListIconGadget, *Data\CursorSettings\Last_Line, *Data\CursorSettings\Last_Column))
								ElseIf GetGadgetAttribute(*Data\ListIconGadget, #PB_ListIcon_DisplayMode)<>#PB_ListIcon_Report And GetGadgetState(*Data\ListIconGadget)>=0
									SetClipboardText(GetGadgetItemText(*Data\ListIconGadget, GetGadgetState(*Data\ListIconGadget), 0))						
								EndIf
							EndIf
						EndIf
						
					Case Asc("V")
						If (GetKeyState_(#VK_CONTROL)&128)
; 							Debug "CTRL-V"
							If *Data\EditSettings\Edit_AllowCtrlV And *Data\Enable_CursorEdit
								
								Callback_EditYesNo=GetProp_(GadgetID(*Data\ListIconGadget), "_LIG_Edit_EditYesNoCB")
								If Callback_EditYesNo ; a callback is specified
									If *Data\CursorSettings\Last_Valid ; if a valid cell has been clicked
										iTmp=Callback_EditYesNo(*Data\ListIconGadget, *Data\CursorSettings\Last_Line, *Data\CursorSettings\Last_Column)
									ElseIf GetGadgetAttribute(*Data\ListIconGadget, #PB_ListIcon_DisplayMode)<>#PB_ListIcon_Report And GetGadgetState(*Data\ListIconGadget)>=0
										iTmp=Callback_EditYesNo(*Data\ListIconGadget, GetGadgetState(*Data\ListIconGadget), 0)
									Else
										iTmp=#False
									EndIf
								Else
									iTmp=#True
								EndIf
		; 						Debug "VK Return Tmp >"+Str(iTmp)+"<"
								If iTmp
									_LIG_Edit_ApplyClipboardText(*Data)
									NotHandled=#False
								EndIf									
							EndIf
						EndIf
						
				EndSelect			
			EndIf
			
		Case #WM_CHAR
			; 			Debug "WM_CHAR"
			If *Data\Enable_CursorEdit
				NotHandled=#False ; this is necessary to prevent 'select on keypress' in the listview
			EndIf
			
		Case #WM_LBUTTONDOWN
; 			Debug "WM_LBUTTONDOWN"
			SetActiveGadget(*Data\ListIconGadget)
			If *Data\Enable_CursorEdit
				If GetGadgetAttribute(*Data\ListIconGadget, #PB_ListIcon_DisplayMode)=#PB_ListIcon_Report ; only in Report Mode!
					_LIG_MouseSelect(*Data)
					NotHandled=#False
				EndIf
			EndIf
			
		Case #WM_LBUTTONDBLCLK
; 			Debug "WM_LBUTTONDBLCLK"	
			SetActiveGadget(*Data\ListIconGadget)
			If *Data\Enable_MouseEdit
				Callback_EditYesNo=GetProp_(GadgetID(*Data\ListIconGadget), "_LIG_Edit_EditYesNoCB")
				If Callback_EditYesNo ; a callback is specified
					If LIG_GetCellFromMousePosition(*Data\ListIconGadget, @CellInfo) ; if a valid cell has been clicked
						iTmp=Callback_EditYesNo(*Data\ListIconGadget, CellInfo\Line, CellInfo\Column)
					Else
						iTmp=#False
					EndIf
				Else
					iTmp=#True
				EndIf
				
				If iTmp
					LIG_StartEdit(*Data\ListIconGadget)
					NotHandled=#False
				EndIf
			EndIf
			
			
		Case #WM_NOTIFY
; 			Debug "#WM_NOTIFY-"
			*WmNotify=lParam
			Select *WmNotify\code
				Case #HDN_ITEMCLICK, #HDN_ITEMCLICKW ; in ascii mode ListView still sends HDN_ITEMCLICKW under win7x64
; 					Debug "#HDN_ITEMCLICK"
					If *Data\Enable_ColumnSort
						*Notify=lParam
						
						If *Notify\iButton=0 ; Left Button
; 							Debug "CurSelected >"+Str(*Data\CursorSettings\Last_Column)+"< >"+Str(*Data\CursorSettings\Last_Line)+"<"
							LIG_SortColumn(*Data\ListIconGadget, *Notify\iItem)
							SetActiveGadget(*Data\ListIconGadget)
							NotHandled=#False
						EndIf						
					EndIf				
			
			EndSelect
			
			
		Case #WM_SETFOCUS
; 			Debug "WM_SETFOCUS"
			If *Data\Enable_CursorEdit
				_LIG_ActInactCell(*Data, #True)
			EndIf
			
		Case #WM_KILLFOCUS
; 			Debug "WM_KILLFOCUS"
			If *Data\Enable_CursorEdit
				_LIG_ActInactCell(*Data, #False)
			EndIf	
			
		Case #WM_DESTROY
; 			Debug "WM_DESTROY"
			_LIG_RemoveAllProps(*Data)
			
		Case #LVM_INSERTITEM
; 			Debug "#LVM_INSERTITEM"			
			*ListViewItem=lParam
			
			If *ListViewItem\iItem<=*Data\CursorSettings\Last_Line ; in case the new Item should be inserted BEFORE or AT the selected item
				*Data\CursorSettings\Last_Line+1
			EndIf
			
		Case #LVM_DELETEITEM
; 			Debug "#LVM_DELETEITEM"			
			
			If wParam<*Data\CursorSettings\Last_Line ; in case the Item should be deleted BEFORE the selected item
				*Data\CursorSettings\Last_Line-1
			ElseIf wParam=*Data\CursorSettings\Last_Line ; if the current selected line is deleted
				If CountGadgetItems(*Data\ListIconGadget)=(*Data\CursorSettings\Last_Line+1) ; if the bottom line is deleted
					*Data\CursorSettings\Last_Line-1
					_LIG_SelectCell(*Data\CursorSettings\Last_Line, *Data\CursorSettings\Last_Column, *Data)
				Else
					_LIG_SelectCell(*Data\CursorSettings\Last_Line+1, *Data\CursorSettings\Last_Column, *Data) ; display the selection at the next line (next line will move to current selected line after the deletion has been processed)
					*Data\CursorSettings\Last_Line-1 ; and correct the selected line again
				EndIf
			EndIf
			
		Case #LVM_INSERTCOLUMN
; 			Debug "#LVM_INSERTCOLUMN"			
			*ListViewColumn=lParam
			
			If *ListViewColumn\iSubItem<=*Data\CursorSettings\Last_Column ; in case the new Column should be inserted BEFORE or AT the selected column
				*Data\CursorSettings\Last_Column+1
			EndIf	
			
		Case #LVM_DELETECOLUMN
; 			Debug "#LVM_DELETECOLUMN"			
			
			If wParam<*Data\CursorSettings\Last_Column ; in case the Column should be deleted BEFORE the selected column
				*Data\CursorSettings\Last_Column-1
			ElseIf wParam=*Data\CursorSettings\Last_Column ; if the current selected column is deleted
				If LIG_GetColumnCount(*Data\ListIconGadget)=(*Data\CursorSettings\Last_Column+1) ; if it is the rightmost column
					*Data\CursorSettings\Last_Column-1					
					_LIG_SelectCell(*Data\CursorSettings\Last_Line, *Data\CursorSettings\Last_Column, *Data)
				Else		
					_LIG_SelectCell(*Data\CursorSettings\Last_Line, *Data\CursorSettings\Last_Column+1, *Data)
					*Data\CursorSettings\Last_Column-1
				EndIf
			EndIf			
			
		Case #LVM_DELETEALLITEMS
; 			Debug "#LVM_DELETEALLITEMS"			
			*Data\CursorSettings\Last_Column=0
			*Data\CursorSettings\Last_Line=0
			*Data\CursorSettings\Last_Valid=#False
			
		Case #WM_STYLECHANGED
; 			Debug "#WM_STYLECHANGED"
			If *Data\Enable_CursorEdit
				If GetGadgetAttribute(*Data\ListIconGadget, #PB_ListIcon_DisplayMode)=#PB_ListIcon_Report ; when the Style has changed to Report Mode
					If Not *Data\CursorSettings\Last_Valid ; only when the stored selection is not valid
						iTmp=GetGadgetState(*Data\ListIconGadget)
						If iTmp=-1
							iTmp=0
						EndIf
						_LIG_SelectCell(iTmp, 0, *Data)
					EndIf
				Else ; a view different from report mode
					If *Data\CursorSettings\Last_Valid ; only when the stored selection IS valid
						_LIG_DeselectCell(*Data)
						SetGadgetState(*Data\ListIconGadget, *Data\CursorSettings\Last_Line)
					EndIf
					
				EndIf
			EndIf
	EndSelect
   
   If NotHandled
   	ProcedureReturn CallWindowProc_(*Data\OrgProc, hwnd, msg, wParam, lParam)
   EndIf
EndProcedure

Enumeration
	#LIG_ColumnSort=1
	#LIG_MouseEdit=2
	#LIG_CursorEdit=4
EndEnumeration

Procedure LIG_EnableAddon(Gadget.i, Addon.i)
	
	Protected *Data.LIG_SubClassInfo
	Protected NewValue.b=#False
	Protected iTmp.i
	Protected RetVal.b=#True
	
	*Data=GetProp_(GadgetID(Gadget), "_LIG_SubClassInfo")
	
	If Not *Data
		*Data=AllocateMemory(SizeOf(LIG_SubClassInfo))
		If *Data
			*Data\ListIconGadget=Gadget
			*Data\Enable_ColumnSort=#False
			*Data\Enable_CursorEdit=#False
			*Data\Enable_MouseEdit=#False
			*Data\GadgetList=GetGadgetList(Gadget)
			*Data\EditSettings\EditGadgetMem=0
			*Data\EditSettings\Edit_ApplyOnExit=#False
			*Data\EditSettings\Edit_AllowCtrlC=#False
			*Data\EditSettings\Edit_AllowCtrlV=#False			
			*Data\CursorSettings\Last_Valid=#False
			*Data\CursorSettings\Color_Back_Inactive=GetSysColor_(#COLOR_MENU)
			*Data\CursorSettings\Color_Back=GetSysColor_(#COLOR_HIGHLIGHT)
			*Data\CursorSettings\Color_Front=GetSysColor_(#COLOR_HIGHLIGHTTEXT)		
			NewValue=#True
		Else
			Debug "ERROR!! Allocating Memory"
			RetVal=#False
		EndIf
	EndIf
	
	If RetVal
		If Addon&#LIG_ColumnSort
			*Data\Enable_ColumnSort=#True
		EndIf
		If Addon&#LIG_MouseEdit
			*Data\Enable_MouseEdit=#True
		EndIf
		If Addon&#LIG_CursorEdit
			If Not *Data\Enable_CursorEdit ; in case it's fresh enabled
				iTmp=GetGadgetState(*Data\ListIconGadget)
				If iTmp=-1
					iTmp=0
				EndIf
				_LIG_SelectCell(iTmp, 0, *Data)
				SetActiveGadget(*Data\ListIconGadget)
			EndIf
			*Data\Enable_CursorEdit=#True
		EndIf
		
		If NewValue
; 			Debug "CallBack gesetzt"
			*Data\OrgProc=GetWindowLongPtr_(GadgetID(Gadget), #GWL_WNDPROC)
			SetProp_(GadgetID(Gadget), "_LIG_SubClassInfo", *Data)
			SetWindowLongPtr_(GadgetID(Gadget), #GWL_WNDPROC, @_LIG_CommonCallback())	
		EndIf
	EndIf
	
	ProcedureReturn RetVal
	
EndProcedure

Procedure LIG_DisableAddon(Gadget.i, Addon.i)
	
	Protected *Data.LIG_SubClassInfo
	Protected NewValue.b=#False
	
	*Data=GetProp_(GadgetID(Gadget), "_LIG_SubClassInfo")
	
	If *Data
		With *Data
			If Addon&#LIG_ColumnSort
				\Enable_ColumnSort=#False
			EndIf
			If Addon&#LIG_MouseEdit
				\Enable_MouseEdit=#False
			EndIf
			If Addon&#LIG_CursorEdit
				\Enable_CursorEdit=#False
			EndIf
		
			If Not \Enable_ColumnSort And Not \Enable_CursorEdit And Not \Enable_MouseEdit ; in case everything is disabled
				_LIG_RemoveAllProps(*Data)
			EndIf
		EndWith
	EndIf
		
EndProcedure

Procedure LIG_EnableEditSetting(Gadget.i, EditSettings.i)
	
	Protected *Data.LIG_SubClassInfo
	Protected RetVal.b=#True
	
	*Data=GetProp_(GadgetID(Gadget), "_LIG_SubClassInfo")
	
	If Not *Data
		RetVal=#False
	EndIf
	
	If RetVal
		If EditSettings&#LIG_EditSetting_ApplyOnExit
			*Data\EditSettings\Edit_ApplyOnExit=#True
		EndIf
		If EditSettings&#LIG_EditSetting_AllowCtrlC
			*Data\EditSettings\Edit_AllowCtrlC=#True
		EndIf
		If EditSettings&#LIG_EditSetting_AllowCtrlV
			*Data\EditSettings\Edit_AllowCtrlV=#True
		EndIf
	EndIf
	
	ProcedureReturn RetVal
	
EndProcedure

Procedure LIG_DisableEditSetting(Gadget.i, EditSettings.i)
	Protected *Data.LIG_SubClassInfo
	Protected RetVal.b=#True
	
	*Data=GetProp_(GadgetID(Gadget), "_LIG_SubClassInfo")
	
	If Not *Data
		RetVal=#False
	EndIf
	
	If RetVal
		If EditSettings&#LIG_EditSetting_ApplyOnExit
			*Data\EditSettings\Edit_ApplyOnExit=#False
		EndIf
		If EditSettings&#LIG_EditSetting_AllowCtrlC
			*Data\EditSettings\Edit_AllowCtrlC=#False
		EndIf
		If EditSettings&#LIG_EditSetting_AllowCtrlV
			*Data\EditSettings\Edit_AllowCtrlV=#False
		EndIf
	EndIf
	
	ProcedureReturn RetVal
		
EndProcedure



; IDE Options = PureBasic 6.03 LTS (Windows - x86)
; CursorPosition = 2344
; FirstLine = 1484
; Folding = ----------
; EnableXP
; DPIAware
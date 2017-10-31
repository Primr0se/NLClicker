#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent
#SingleInstance

SetBatchLines, 50ms
SetControlDelay, -1
DetectHiddenWindows, On
;~ Process, Priority,, High

#Include GDIP.ahk
#Include Gdip_ImageSearch.ahk

Menu, Tray, Icon, IconDeactive.ico
Menu, Tray, Add , Restart , l_Restart
Menu, Tray, Add , Quit , l_Quit
Menu, Tray, Click , 1
Menu, Tray, NoStandard

active:=0, gdipToken := Gdip_Startup(), clicker := new Clicker()

;~ super global var
global Bitmaps:={}, Images:={}, Maps:={}
global GameHWND, HostHWND, OffsetX:=6, OffsetY:=-53, MouseOffset:=54, EnableSH
global timer:=Object, Mouses, CurMouse
global GoPrev:=false, CurMap:=0, CurMapPnts:={}
global TBExchange:=0
;~ init var & const
Mouses:=[]
LoadBitmaps()
SetUpMap()
SetUpImage()
SetUpGameHWND()

Suspend, On
Hotkey, IfWinActive, S2
Hotkey, F1, l_ToggleKeys
Hotkey, Esc, l_StopExec
Hotkey, ^LButton, l_SetWinOrPos
loop 4
	Hotkey % A_Index, Label_%A_Index%
return

LoadBitmaps()
{
	texture:=Gdip_CreateBitmapFromFile("Textures.png")
	Loop, Read, Textures.data
	{
		OutputDebug % "" A_LoopReadLine
		StringSplit, S, A_LoopReadLine, =
		name:=Trim(S1)
		StringSplit, C, % Trim(S2), % A_Space
		Bitmaps[name] := Gdip_CloneBitmapArea(texture, C1, C2, C3, C4)
	}
	Gdip_DisposeImage(texture)
}
SetUpGameHWND() {
	HostHWND:=-1, GameHWND:=[]
	WinGet, all, List, S2
	OutputDebug % "found " all " window!!"
	loop % all
	{
		GameHWND.Push(all%A_Index%)
		WinMove, % "ahk_id " all%A_Index%,, -5, 309, 1010, 690
	}
	if( all = 1) {
		HostHWND:=GameHWND.Pop()
		OutputDebug % "Host: " HostHWND
	}
	return
}
SetUpMap() {
	Loop, Read, Maps.data
	{
		StringSplit, S, A_LoopReadLine, =
		name:=Trim(S1), Maps[name]:=[]
		Loop, parse, S2, % A_Space
		{
			StringSplit, C, A_LoopField, `,
			Maps[name].Push({x:C1, y:C2})
		}
	}
	return
}
SetUpImage() {
	Loop, Read, Areas.data
	{
		StringSplit, S, A_LoopReadLine, =
		name:=Trim(S1)
		StringSplit, A, S2, % A_Space
		StringSplit, C, A2, `,
		Images[name]:={area:A1, pnt:{x:C1, y:C2}}
	}
	return
}

ToggleSH(turnOn){
	if !ce:=WinExist("Cheat Engine 6.7")
		return
	OutputDebug % "" ce
	ControlClick, Button4, ahk_id %ce%, Enable Speedhack
	if turnOn
	{
		ControlSetText, Edit1, 10, ahk_id %ce%
		Sleep 50
		ControlClick, Button3, ahk_id %ce%, Apply
	}
	return
}
l_ToggleKeys:
	suspend
	active:=!active
	if(active) {
		Hotkey, Esc, On
		Hotkey, ^LButton, On
		;~ Hotkey, Space, On
		loop 4
			Hotkey % A_Index , On
		Menu, Tray, Icon, IconReady.ico
	} else {
		Hotkey, Esc, Off
		Hotkey, ^LButton, Off
		;~ Hotkey, Space, Off
		loop 4
			Hotkey % A_Index , Off
		clicker.Stop()
		Menu, Tray, Icon, IconDeactive.ico
	}
	return
Label_1:
	if !EnableSH
		ToggleSH(EnableSH:=!EnableSH)
	clicker.Start("FarmQDExec")
	return
Label_2:
	clicker.Start("FnExec", 250, 0, Mouses)
	return
Label_3:
	clicker.Start("FnExec", 350, Images)
	return
Label_4:
	clicker.Start("QTExec", 550)
	return
l_StopExec:
	if EnableSH
		ToggleSH(EnableSH:=!EnableSH)
	clicker.Stop()
	return
l_SimClick:
	clicker.DoClick(Mouses[1])
	return
l_SetWinOrPos:
	if(GetKeyState("LButton", "P")) {
		MouseGetPos x, y, win
		y-=MouseOffset
		Mouses.Push({x: x, y: y})
		FileAppend % "{x:" x ", y:" y "}`n", point.txt
		if (HostHWND = -1) {
			loop % GameHWND.length()
			{
				if (GameHWND[A_Index] = win)
				{
					HostHWND:=GameHWND.RemoveAt(A_Index)
					break
				}
			}
		}
		OutputDebug % "" HostHWND
	}
	return
l_Restart:
	Reload
	return
l_Quit:
	For k, v in Bitmaps
		Gdip_DisposeImage(v)
	Bitmaps:={}, Images:={}, Maps:={}
	clicker:=Object, Mouses:=""
	Gdip_Shutdown(gdipToken)
	ExitApp
	return

class Clicker {
	__New() {
		
	}
	
	FnExec(ImgSeq, MouseSeq) {
		if(!ImgSeq && MouseSeq) {
			loop % MouseSeq.length()
				this.DoClick(MouseSeq[A_Index])
			return
		}
		if(this.FindImage("exchange"))
		{
			OutputDebug % "" TBExchange
			x:=332+TBExchange*80, y:=450
			this.DoClick({x:x, y:y}) ;~ select
			this.DoClick({x:685, y:542}) ;~ exchange
			
			if c1:=this.FindImage("confirm1",,true)
			or c2:=this.FindImage("confirm2",,true)
			{
				TBExchange++
				if (TBExchange = 4)
				{
					if this.FindImage("thoatTB",,true)
					{
						TBExchange:=0
					}
				}
			}
			return
		}
		
		while(this.FindImage("xbtn")) 
		{
			if this.FindImage("tancong") 
			or this.FindImage("tiencong")
				break
			Sleep 50 ;bad connection
		}
		
		clicked := false
		
		For img, val in ImgSeq
		{
			if clicked:=this.FindImage(img,,true)
			{
				if img=hetluot or img=tiencong
				{
					CurMouse++
				}
				break
			}
		}
			
		if( MouseSeq && CurMouse > MouseSeq.length()) {
			GoPrev:=true
			return
		}

		if(!clicked && MouseSeq) {
			this.DoClick(MouseSeq[CurMouse])
		}
	}
	
	;~ call function
	Stop() {
		if(timer)
			SetTimer % timer, Delete
		Mouses:=[]
		VKTState:=-1, CurMap:=0
		Menu, Tray, Icon, IconReady.ico
	}
	Start(fnname, period:=175, ImgSeq:=0, MouseSeq:=0) {
		if(timer)
			SetTimer % timer, Delete
		timer := ObjBindMethod(this, fnname, ImgSeq, MouseSeq) 
		SetTimer % timer, % period
		CurMouse:=1, VKTState:=0
		Menu, Tray, Icon, IconExecuting.ico
	}
	
	FarmQDExec(prm*) {
		if(GoPrev) {
			GoPrev:=false
			if( CurMap = 1) ;~ pvevent
				this.DoClick({x:907, y:584})
			else	
				this.DoClick({x:420, y:621}) 
			CurMap:=0, CurMouse:=1
			return
		}
		
		if(!CurMap) {
			if(!this.GetMapPosClick()) {
				this.Stop()
				return
			}
		}
		
		this.FnExec(Images, CurMapPnts)
	}
	
	;~ internal function
	IsEmpty(Arr) {
		return !Arr._NewEnum()[k, v]
	}
	
	DoClick(point, win:=0) {
		x:=point.x, y:=point.y+MouseOffset
		if !win 
			win:=HostHWND
		OutputDebug % "Click at " x "," y
		ControlClick x%x% y%y%, ahk_id %win%,,,, NA
	}
	
	MemberClick(point) {
		loop % GameHWND.length() 
		{
			this.DoClick(point, GameHWND[A_Index])
		}
	}
	
	FindImage(name, win:=0, click:=false) {
		if !win
			win:=HostHWND
		area:=Images[name].area
		StringSplit, s, area, |
		x:=s1+OffsetX, y:=s2+OffsetY, w:=s3, h:=s4
		bmpArea := GDIP_BitmapFromScreen("hwnd:" win "|" x "|" y "|" w "|" h) 
		res := Gdip_ImageSearch(bmpArea, Bitmaps[name])
		if res > 0 and click
		{
			this.DoClick(Images[name].pnt)
		}
		Gdip_DisposeImage(bmpArea)
		return (res > 0)
	}
	
	GetMapPosClick(win:=0)
	{
		if !win
			win:=HostHWND
		bmpArea := GDIP_BitmapFromScreen("hwnd:" win "|446|652|120|22") 
		CurMapPnts:={}, found:=false
		For name, ResVal in Maps
		{
			if Gdip_ImageSearch(bmpArea, Bitmaps[name])
			{
				if (name=gcd2 or name=hhuy) {
					GoPrev:=true
					goto endofsub
				}
				CurMap:=A_Index, CurMapPnts:=ResVal
				;~ OutputDebug % "name:" name ", Pnts: " CurMapPnts.length()
				found:=true
				goto endofsub
			}
		}
		endofsub:
		Gdip_DisposeImage(bmpArea)
		return found
	}
}
!macro CheckDotNet DotNetReqVer
	!define DOTNET_URL "http://download.microsoft.com/download/6/0/f/60fc5854-3cb8-4892-b6db-bd4f42510f28/dotnetfx35.exe"
	
	;Save the variables in case something else is using them
 
	Push $0		; Registry key enumerator index
	Push $1		; Registry value
	Push $2		; Temp var
	Push $R0	; Max version number
	Push $R1	; Looping version number
 
	StrCpy $R0 "0.0.0"
	StrCpy $0 0
 
	loop:
 
		; Get each sub key under "SOFTWARE\Microsoft\NET Framework Setup\NDP"
		EnumRegKey $1 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP" $0
 
		StrCmp $1 "" done 	; jump to end if no more registry keys
 
		IntOp $0 $0 + 1 	; Increase registry key index
		StrCpy $R1 $1 "" 1 	; Looping version number, cut of leading 'v'
 
		${VersionCompare} $R1 $R0 $2
		; $2=0  Versions are equal, ignore
		; $2=1  Looping version $R1 is newer
        ; $2=2  Looping version $R1 is older, ignore
 
		IntCmp $2 1 newer_version loop loop
 
		newer_version:
		StrCpy $R0 $R1
		goto loop
 
	done:
 
	; If the latest version is 0.0.0, there is no .NET installed ?!
	${VersionCompare} $R0 "0.0.0" $2
	IntCmp $2 0 NoDotNET
	
	${VersionCompare} $R0 ${DotNetreqVer} $2
	${select} $2
		${case} 0	; equal
			goto clean
		${case} 1	; newer than required
			goto clean
		${case} 2	; older than required
			goto OldDotNET
	${endselect}
	


	NoDotNET:
	MessageBox MB_YESNOCANCEL|MB_ICONEXCLAMATION \
	".NET Framework not installed.$\nRequired Version: ${DotNetreqVer} or greater.$\nDownload .NET Framework version from www.microsoft.com?" \
	/SD IDNO IDYES DownloadDotNET IDNO GiveUpDotNET
	goto GiveUpDotNET ;IDCANCEL
	

	OldDotNET:
	MessageBox MB_YESNOCANCEL|MB_ICONEXCLAMATION \
	"Your .NET Framework version: $R0.$\nRequired Version: ${DotNetreqVer} or greater.$\nDownload .NET Framework version from www.microsoft.com?" \
	/SD IDNO IDYES DownloadDotNET IDNO GiveUpDotNET
	goto GiveUpDotNET ;IDCANCEL


	DownloadDotNET:
	DetailPrint "Beginning download of latest .NET Framework version."
	NSISDL::download ${DOTNET_URL} "$TEMP\dotnetfx.exe"
	DetailPrint "Completed download."
	Pop $0
	${If} $0 == "cancel"
	MessageBox MB_YESNO|MB_ICONEXCLAMATION \
	"Download cancelled.  Continue Installation?" \
	IDYES clean IDNO GiveUpDotNET
	${ElseIf} $0 != "success"
	MessageBox MB_YESNO|MB_ICONEXCLAMATION \
	"Download failed:$\n$0$\n$\nContinue Installation?" \
	IDYES clean IDNO GiveUpDotNET
	${EndIf}
	DetailPrint "Pausing installation while downloaded .NET Framework installer runs."
	ExecWait '$TEMP\dotnetfx35.exe /q /c:"install /q"'
	DetailPrint "Completed .NET Framework install/update. Removing .NET Framework installer."
	Delete "$TEMP\dotnetfx.exe"
	DetailPrint ".NET Framework installer removed."
	goto clean


	GiveUpDotNET:
	LogEx::Write "Installation cancelled by user due to incompatible DotNET Framework Version."
	Abort "Installation cancelled by user due to incompatible DotNET Framework Version."


	clean:
	; Pop the variables we pushed earlier
	Pop $0
	Pop $1
	Pop $2
	Pop $R1
!macroend
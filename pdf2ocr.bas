' pdf2ocr
' Version 1.1
' November 12, 2015
' Copyright 2012 - 2015 by Jamal Mazrui
' GNU Lesser General Public License (LGPL)

#INCLUDE "C:\pdf2ocr\Private.inc"
#INCLUDE "Win32API.inc"

Global bDebugMode, bStandAlone As Long
GLOBAL sExe,sExePath, sSayLineExe AS STRING

FUNCTION GetCommandArgCount() AS LONG
    LOCAL i AS LONG
    FOR i = 1 TO 100
IF COMMAND$(i) = "" THEN EXIT FOR
NEXT
i = i - 1
FUNCTION = i
END FUNCTION

        FUNCTION GetImageFormatFromString(BYVAL sFormat AS STRING, BYREF sExt AS STRING) AS LONG
LOCAL iReturn AS LONG

iReturn = -1
sFormat = LCase$(sFormat)
sFormat = LTrim$(sFormat, Any ".")
IF sFormat = "bmp" THEN iReturn = 0
IF sFormat = "jpg" THEN iReturn = 1
IF sFormat = "wmf" THEN iReturn = 2
IF sFormat = "emf" THEN iReturn = 3
IF sFormat = "eps" THEN iReturn = 4
IF sFormat = "png" THEN iReturn = 5
IF sFormat = "gif" THEN iReturn = 6
IF sFormat = "tif" Or sFormat = "tiff" THEN iReturn = 7
IF sFormat = "emf+" THEN
iReturn = 8
sExt = ".emf"
ELSEIf sFormat = "tiff" Then
sExt = ".tif"
Else
sExt = "." & sFormat
END IF
FUNCTION = iReturn
END FUNCTION

FUNCTION LogError(sText AS STRING) AS LONG
LOCAL s AS STRING

IF ISFALSE bDebugMode THEN EXIT FUNCTION
CLIPBOARD GET TEXT TO s
s = s & $CRLF & sText
CLIPBOARD SET TEXT s
END FUNCTION

FUNCTION FileToString(BYVAL s_file AS ASCIIZ * 256) AS STRING
LOCAL i_size AS LONG, h_file AS LONG, s_return AS STRING

IF IsFalse IsFile(s_file) THEN
s_return =""
ELSE
h_file =FREEFILE
OPEN s_file FOR BINARY AS h_file
i_size =LOF(h_file)
GET$ h_file, i_size, s_return
CLOSE h_file
END IF
FUNCTION =s_return
END FUNCTION

FUNCTION StringToFile(BYVAL s_text AS STRING, BYVAL s_file AS ASCIIZ * 256) AS LONG
LOCAL i_size AS LONG, h_file AS LONG, i_return AS LONG

IF ISTRUE ISFILE(s_file) THEN KILL s_File
'msgbox format$(len(s_text))
IF LEN(s_text) =0 THEN
'If IsFalse Then
i_return =0
ELSE
h_file =FREEFILE
OPEN s_file FOR BINARY AS h_file
i_size =LEN(s_text)
PUT$ h_file, s_text
CLOSE h_file
i_return =1
END IF
FUNCTION =i_return
END FUNCTION

FUNCTION PrintLine(Z AS STRING) AS LONG
If IsFalse bStandAlone Then
Say(z)
Exit Function
End if

' returns TRUE (non-zero) on success
   LOCAL hStdOut AS LONG, nCharsWritten AS LONG
   LOCAL w AS STRING
   STATIC CSInitialized AS LONG, CS AS CRITICAL_SECTION
   IF ISFALSE CSInitialized THEN
       InitializeCriticalSection CS
       CSInitialized  =  1
   END IF
   EntercriticalSection Cs
   hStdOut      = GetStdHandle (%STD_OUTPUT_HANDLE)
   IF hSTdOut   = -1& OR hStdOut = 0&   THEN     ' invalid handle value, coded in line to avoid
                                                 ' casting differences in Win32API.INC
                                                 ' test for %NULL added 8.26.04 for Win/XP
     AllocConsole
     hStdOut  = GetStdHandle (%STD_OUTPUT_HANDLE)
   END IF
   LeaveCriticalSection CS
   w = Z & $CRLF
   FUNCTION = WriteFile(hStdOut, BYVAL STRPTR(W), LEN(W),  nCharsWritten, BYVAL %NULL)
 END FUNCTION

FUNCTION StringPlural(sText AS STRING, iCount AS LONG) AS STRING
LOCAL sReturn AS STRING

sReturn = sText
IF iCount <> 1 THEN sReturn = sReturn & "s"
FUNCTION = sReturn
END FUNCTION

FUNCTION GetWidth(iNum AS LONG) AS LONG
LOCAL iResult, iLoop, iPower AS LONG

iLoop = 1
WHILE iLoop > 0
iResult = iNum \ (10^iPower)
IF (iResult = 0) OR (iLoop = 100) THEN
iLoop = -1 * iLoop
ELSE
iPower = iPower + 1
END IF
WEND

IF iLoop = -100 THEN
DialogShow("reached 100 for width", "")
GetWidth = 5
ELSE
GetWidth = iPower
END IF
END FUNCTION

FUNCTION DialogInput(sTitle AS STRING, sMessage AS STRING, sValue AS STRING) AS STRING
FUNCTION = INPUTBOX$(sMessage, sTitle, sValue)
END FUNCTION

FUNCTION DialogShow(sTitle AS STRING, sMessage AS STRING) AS LONG
' show a standard message box

DIM iFlags AS LONG

DialogShow = %True
iFlags = %MB_ICONINFORMATION OR %MB_SYSTEMMODAL
IF sTitle = "" THEN sTitle = "Show"
MSGBOX sMessage, iFlags, sTitle
END FUNCTION

FUNCTION StringQuote(BYVAL s$) AS STRING
FUNCTION = CHR$(34) & s$ & CHR$(34)
END FUNCTION

FUNCTION DialogConfirm(sTitle AS STRING, sMessage AS STRING, sDefault AS STRING) AS STRING
' Get choice from a standard Yes, No, or Cancel message box

DIM iFlags AS LONG, iChoice AS LONG

DialogConfirm = ""
iFlags = %MB_YESNOCANCEL
iFlags = iFlags OR %MB_ICONQUESTION     ' 32 query icon
iFlags = iFlags OR %MB_SYSTEMMODAL ' 4096   System modal
IF sTitle = "" THEN sTitle = "Confirm"
IF sDefault = "N" THEN iFlags = iFlags OR %MB_DEFBUTTON2
iChoice = MSGBOX(sMessage, iFlags, sTitle)
IF iChoice = %IDCANCEL THEN EXIT FUNCTION

IF iChoice = %IDYES THEN
DialogConfirm = "Y"
ELSE
DialogConfirm = "N"
END IF
END FUNCTION

FUNCTION Say(sText AS STRING) AS LONG
DIM sExe AS STRING

If Len(Trim$(sText)) = 0 Then Exit Function
sExe = Exe.Path$ + "SayLine.exe"
SHELL(StringQuote(sExe) & sText, 0)
END FUNCTION


FUNCTION PBMAIN() AS LONG
LOCAL hLib, hDoc, hPdf, hPage, hGraphics, hGraphic AS LONG
LOCAL iCount, iFormat, iOptions, iDPI, iResult, iPage, iPageCount, iPageWidth, iType, iProperty, iGraphic, iImageCount, iImageWidth AS LONG
Local oLib As IDispatch
LOCAL sSpec, sIntro, sPsm, sLang, sRange, sLib, sProgId, sClsId, sUnlockKey, sPage, sDPI, sFormat, sText, sPdf, sPassword, sImage, sGraphic, sBody, sTxt, sSuffix, sPath, sBase, sRoot, sExt AS STRING
Local vRange, vPassword, vGraphic, vPdf, vPage, vTxt, vImage, vUnlockKey As Variant

' bDebugMode = %True
bDebugMode = %False

sSayLineExe = Exe.Path$ + "SayLine.exe"
If IsFalse IsFile(sSayLineExe) Then bStandAlone = %true

sExe = EXE.FULL$
sExePath = EXE.PATH$
sLib = sExePath & "pdf2ocr.dll"
If IsFalse IsFile(sLib) Then sLib = sExePath & "pdf2parts.dll"

iDPI = 300
sFormat = "tiff"
sExt = ".tif"
iFormat = 7
sPsm = "3"
sLang = "eng"

iCount = GetCommandArgCount()
IF iCount = 0 THEN
PrintLine("Syntax:")
PrintLine("pdf2ocr.exe FileName DPI Mode Language")
PrintLine("FileName is the PDF, DPI is the Dots Per Inch, Mode is the page segmentation mode, and Language is the language code")
EXIT FUNCTION
END IF

IF iCount > 0 THEN
sSpec = COMMAND$(1)
sPdf = Dir$(sSpec)
' IF ISFALSE ISFILE(sPdf) THEN
If Len(sPdf) = 0 Then
PrintLine("Cannot find file matching " & sSpec)
EXIT FUNCTION
END IF
END IF

vPassword = sPassword
sIntro = "Converting to text via OCR"

IF iCount > 1 THEN
sDPI = COMMAND$(2)
iDPI = VAL(sDPI)
sIntro += " at " +sDpi + " DPI"
END IF

IF iCount > 2 THEN
sPsm = COMMAND$(3)
sIntro += " using mode " + sPsm
END IF

IF iCount > 3 THEN
sLang = COMMAND$(4)
sIntro += " and language " +sLang
END IF

If bStandAlone Then PrintLine(sIntro)

sClsId = GUID$("{2E75DB15-9312-4902-8DA0-EAC34A6DD40C}")
oLib = NewCom ClsId sClsId Lib sLib
sUnlockKey = $QuickPDF_UnlockKey
vUnlockKey = sUnlockKey
Object Call oLib.UnlockKey(vUnlockKey) To iResult

While Len(sPdf) > 0
sPdf = PathName$(PATH, sSpec) + sPdf
vPdf = sPdf
sPath = PATHNAME$(PATH, sPdf)
sRoot = PATHNAME$(NAME, sPdf)
sBase = PATHNAME$(NAMEX, sPdf)

Object Call oLib.DAOpenFileReadOnly(vPdf, vPassword) To hPdf
Object Call oLib.DAGetPageCount(hPdf) To iPageCount
iPageWidth = GetWidth(iPageCount)
PrintLine("")
If bStandAlone Then PrintLine(sBase & " = " & FORMAT$(iPageCount) & " " & StringPlural("page", iPageCount))

FOR iPage = 1 TO iPageCount
PrintLine("page " & Format$(iPage))
Object Call oLib.DAFindPage(hPdf, iPage) To hPage
sSuffix = "_" & RSET$(FORMAT$(iPage), iPageWidth USING "0")

iFormat = GetImageFormatFromString(sFormat, sExt)
sImage = SPath & sRoot & sSuffix & sExt
vImage = sImage
Object Call oLib.DARenderPageToFile(hPdf, hPage, iFormat, iDpi, vImage) To iResult

' Adds .txt automatically
' sExt = ".txt"
sExt = ""
sTxt = SPath & sRoot & sSuffix & sExt
Local sTesseract, sCommand As String
' Silence tesseract logo output via standard error
' sTesseract = sPath & "tesseract.exe"
sTesseract = sExePath & "RunTesseract.bat"
sCommand = StringQuote(sTesseract) & " " & StringQuote(sImage) & " " & StringQuote(sTxt)
sCommand += " -psm " + sPsm
sCommand += " -l " + sLang
sCommand += " --tessdata-dir " + StringQuote(sExePath + "tessdata")
' sCommand = "cmd.exe /c " + sCommand
' sCommand += " 2>nul"
Shell sCommand, 0

sExt = ".txt"
sTxt = SPath & sRoot & sSuffix & sExt
sText = FileToString(sTxt)
Kill sTxt
Kill sImage
IF sBody <> "" THEN sBody = sBody & CHR$(12) & CHR$(13) & CHR$(10)
sBody = sBody & sText
NEXT

sExt = ".txt"
sTxt = sPath & sRoot & sExt
StringToFile(sBody, sTxt)
Object Call oLib.DACloseFile(hPdf) To iResult

sPdf = Dir$()
sBody = ""
WEnd
PrintLine("")
PrintLine("Done")

AbortFunction:
Object Call oLib.DACloseFile(hPdf) To iResult
Object Call oLib.ReleaseLibrary() To iResult
EXIT FUNCTION

ErrorTrap:
SELECT CASE ERRCLEAR
CASE %ERR_NOERROR: LogError "ERR_NOERROR= 0"
CASE %ERR_ILLEGALFUNCTIONCALL: LogError "ERR_ILLEGALFUNCTIONCALL= 5"
CASE %ERR_OVERFLOW: LogError "ERR_OVERFLOW = 6 (reserved)"
CASE %ERR_OUTOFMEMORY: LogError "ERR_OUTOFMEMORY= 7"
CASE %ERR_SUBSCRIPTPOINTEROUTOFRANGE: LogError "ERR_SUBSCRIPTPOINTEROUTOFRANGE= 9"
CASE %ERR_DIVISIONBYZERO: LogError "ERR_DIVISIONBYZERO = 11 (reserved)"
CASE %ERR_DEVICETIMEOUT: LogError "ERR_DEVICETIMEOUT= 24"
CASE %ERR_INTERNALERROR: LogError "ERR_INTERNALERROR= 51"
CASE %ERR_BADFILENAMEORNUMBER: LogError "ERR_BADFILENAMEORNUMBER= 52"
CASE %ERR_FILENOTFOUND: LogError "ERR_FILENOTFOUND= 53"
CASE %ERR_BADFILEMODE: LogError "ERR_BADFILEMODE= 54"
CASE %ERR_FILEISOPEN: LogError "ERR_FILEISOPEN= 55"
CASE %ERR_DEVICEIOERROR: LogError "ERR_DEVICEIOERROR= 57"
CASE %ERR_FILEALREADYEXISTS: LogError "ERR_FILEALREADYEXISTS= 58"
CASE %ERR_DISKFULL: LogError "ERR_DISKFULL= 61"
CASE %ERR_INPUTPASTEND: LogError "ERR_INPUTPASTEND= 62"
CASE %ERR_BADRECORDNUMBER: LogError "ERR_BADRECORDNUMBER= 63"
CASE %ERR_BADFILENAME: LogError "ERR_BADFILENAME= 64"
CASE %ERR_TOOMANYFILES: LogError "ERR_TOOMANYFILES= 67"
CASE %ERR_DEVICEUNAVAILABLE: LogError "ERR_DEVICEUNAVAILABLE= 68"
CASE %ERR_COMMERROR: LogError "ERR_COMMERROR= 69"
CASE %ERR_PERMISSIONDENIED: LogError "ERR_PERMISSIONDENIED= 70"
CASE %ERR_DISKNOTREADY: LogError "ERR_DISKNOTREADY= 71"
CASE %ERR_DISKMEDIAERROR: LogError "ERR_DISKMEDIAERROR= 72"
CASE %ERR_RENAMEACROSSDISKS: LogError "ERR_RENAMEACROSSDISKS= 74"
CASE %ERR_PATHFILEACCESSERROR: LogError "ERR_PATHFILEACCESSERROR= 75"
CASE %ERR_PATHNOTFOUND: LogError "ERR_PATHNOTFOUND= 76"
CASE %ERR_OBJECTERROR: LogError "ERR_OBJECTERROR= 99"
CASE %ERR_GLOBALMEMORYCORRUPT: LogError "ERR_GLOBALMEMORYCORRUPT= 241 (Previously %ERR_FARHEAPCORRUPT)"
CASE %ERR_STRINGSPACECORRUPT: LogError "ERR_STRINGSPACECORRUPT= 242"
CASE ELSE : LogError "Unknown error!"
END SELECT
RESUME AbortFunction
END FUNCTION

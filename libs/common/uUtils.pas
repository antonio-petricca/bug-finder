unit uUtils;

interface

uses
  Classes,
  Controls,
  Dialogs,
  hUtils,
  SysUtils,
  Windows;

function  AreYouSure: Boolean;
function  DateToWeek(ADate: TDateTime): Integer;
function  FileCreationAge(const AFileName: string): Integer;
function  GetAppVersionInfo(var AFileVErsionInfo: TFileVersionInfo; AAppNamePath: String = ''): Boolean;
function  GetQuickAppVersionInfo(AAppNamePath: String = ''): String;
function  IsOsWin32: Boolean;

implementation

function GetAppVersionInfo(var AFileVErsionInfo: TFileVersionInfo; AAppNamePath: String): Boolean;
var
  VerBuf      : PChar;
  VerBufLen   : Cardinal;
  VerBufValue : Pointer;
  VerHandle   : Cardinal;
  VerKey      : String;
  VerSize     : Integer;

  function GetInfo(const AKey: String): String;
  begin
    Result := '';

    VerKey :=
      '\StringFileInfo\' + IntToHex(loword(integer(VerBufValue^)), 4) +
      IntToHex(hiword(integer(VerBufValue^)), 4) + '\' + AKey
    ;

    if VerQueryValue(VerBuf, PChar(VerKey), VerBufValue, VerBufLen) then
      Result := StrPas(VerBufValue);
  end;

  function QueryValue(const AValue: String): String;
  begin
    Result := '';

    if GetFileVersionInfo(PChar(AAppNamePath), VerHandle, VerSize, VerBuf) and
      VerQueryValue(VerBuf, '\VarFileInfo\Translation', VerBufValue, VerBufLen)
    then
      Result := GetInfo(AValue);
  end;

begin
  if (AAppNamePath = '') then
    AAppNamePath := ParamStr(0);

  VerSize := GetFileVersionInfoSize(PChar(AAppNamePath), VerHandle);
  Result  := (VerSize > 0);
  if Result then begin
    VerBuf  := AllocMem(VerSize);

    try
      AFileVersionInfo.Comments         := QueryValue('Comments');
      AFileVersionInfo.CompanyName      := QueryValue('CompanyName');
      AFileVersionInfo.FileDescription  := QueryValue('FileDescription');
      AFileVersionInfo.FileVersion      := QueryValue('FileVersion');
      AFileVersionInfo.InternalName     := QueryValue('InternalName');
      AFileVersionInfo.LegalCopyRight   := QueryValue('LegalCopyRight');
      AFileVersionInfo.LegalTradeMark   := QueryValue('LegalTradeMark');
      AFileVersionInfo.OriginalFileName := QueryValue('OriginalFileName');
      AFileVersionInfo.ProductName      := QueryValue('ProductName');
      AFileVersionInfo.ProductVersion   := QueryValue('ProductVersion');
    finally
      FreeMem(VerBuf, VerSize);
    end;
  end;
end;

function GetQuickAppVersionInfo(AAppNamePath: String): String;
var
  VerInfos : TFileVersionInfo;
begin
  GetAppVersionInfo(VerInfos, AAppNamePath);             

  Result := Format('Product name : %s'#13#10, [VerInfos.ProductName]);
  Result := Result + Format('File description : %s'#13#10, [VerInfos.FileDescription]);
  Result := Result + Format('File version : %s'#13#10, [VerInfos.FileVersion]);
  Result := Result + Format('Company name : %s'#13#10, [VerInfos.CompanyName]);
end;

function AreYouSure: Boolean;
begin
  Result := (mrYes = MessageDlg('Are you sure?', mtConfirmation, [mbYes, mbNo], 0));
end;

function GetMachineName: String;
var
  Buf : array[0 .. MAX_PATH] of Char;
  Sz  : DWORD;
begin
  Sz := SizeOf(Buf);
  GetComputerName(Buf, Sz);

  Result := StrPas(Buf);
end;

function IsOsWin32: Boolean;
var
  VerInfos : TOSVersionInfo;
begin
  VerInfos.dwOSVersionInfoSize := SizeOf(VerInfos);
  GetVersionEx(VerInfos);
  Result := (VerInfos.dwPlatformId = VER_PLATFORM_WIN32_NT);
end;

function FileCreationAge(const AFileName: string): Integer;
var
  Handle        : THandle;
  FindData      : TWin32FindData;
  LocalFileTime : TFileTime;
begin
  Handle := FindFirstFile(PChar(AFileName), FindData);
  if (Handle <> INVALID_HANDLE_VALUE) then begin
    Windows.FindClose(Handle);

    if (FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) = 0 then begin
      FileTimeToLocalFileTime(FindData.ftLastWriteTime, LocalFileTime);
      if FileTimeToDosDateTime(
        LocalFileTime,
        LongRec(Result).Hi,
        LongRec(Result).Lo
      ) then
        Exit;
    end;
  end;

  Result := -1;
end;

function FileDateCompare(AList: TStringList; AIndex1, AIndex2: Integer): Integer;
var
  Age1, Age2 : Integer;
begin
  Age1 := FileCreationAge(AList[AIndex1]);
  Age2 := FileCreationAge(AList[AIndex2]);

  if (Age1 = Age2) then
    Result := 0
  else if (Age1 < Age2) then
    Result := -1
  else
    Result := 1;
end;

function DateToWeek(ADate: TDateTime): Integer;
begin
  Result := (DateTimeToTimeStamp(ADate).Date div 7);
end;

end.

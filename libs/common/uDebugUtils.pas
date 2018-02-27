unit uDebugUtils;

interface

uses
  hDebugUtils,
  PsApi,
  SysUtils,
  TlHelp32,
  Windows;

function GetModuleCodeBase(AProcess: THandle; AModuleAsPtr: Pointer; out ACodeBase: DWORD): Boolean;
function GetModuleHeader(AProcess: THandle; AModuleAsPtr: Pointer; AImageNTHeaders: PImageNtHeaders): Boolean;
function GetModuleInfos(AProcess: THandle; AProcessId: DWORD; AModuleAddress: DWORD; out AModuleInfos: TModuleInfo): Boolean;
function GetPreferredLoadAddress(AProcess: THandle; AModuleAsPtr: Pointer): Pointer;
function GetProcessModuleFileName(AProcess: THandle; AFile: THandle): String;
function GetProcessModuleFileNameEx(APID: DWORD; const AModuleName: String): String;
function GetProcessModuleName(AProcess: THandle; AModuleAsPtr: Pointer): String;
function GetThreadHandleByID(AThreadId: DWORD): THandle;
function ReadProcMem(AProcess: THandle; AProcMem, ALocalMem: Pointer; ASize: DWORD): Boolean;
function SearchModulePath(const AModuleName: String): String;
function WriteProcMem(AProcess: THandle; AProcMem, ALocalMem: Pointer; ASize: DWORD): Boolean;

implementation

function ReadProcMem(AProcess: THandle; AProcMem, ALocalMem: Pointer; ASize: DWORD): Boolean;
var
  dwRead : DWORD;
begin
  Result := ReadProcessMemory(
    AProcess,
    AProcMem,
    ALocalMem,
    ASize,
    dwRead
  );
end;

function GetModuleHeader(AProcess: THandle; AModuleAsPtr: Pointer; AImageNTHeaders: PImageNtHeaders): boolean;
var
  DH : TImageDosHeader;
begin
  if ReadProcMem(AProcess, AModuleAsPtr, @DH, SizeOf(TImageDosHeader)) then
    Result := ReadProcMem(
      AProcess,
      Pointer(DWORD(AModuleAsPtr) + DWORD(DH._lfanew)),
      AImageNTHeaders,
      SizeOf(TImageNTHeaders)
    )
  else
    Result := False;
end;

function GetProcessModuleName(AProcess: THandle; AModuleAsPtr: Pointer): String;
var
  IH         : TImageNtHeaders;
  IED        : TImageExportDirectory;
  ExportsRVA : DWORD;
  Str        : String;
begin
  Result := '<Unknown>';

  if GetModuleHeader(AProcess, AModuleAsPtr, @IH) then begin
    ExportsRVA := IH.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress;
    if (ExportsRVA <> 0) and
       ReadProcMem(AProcess, Pointer(DWORD(AModuleAsPtr) + ExportsRVA), @IED, SizeOf(TImageExportDirectory))
    then begin
      SetLength(Str, 64);
      if ReadProcMem(AProcess, Pointer(DWORD(AModuleAsPtr) + IED.Name), @Str[1], 64) then
        Result := StrPas(PChar(Str));
    end;
  end;
end;

function GetPreferredLoadAddress(AProcess: THandle; AModuleAsPtr: Pointer): Pointer;
var
  IH : TImageNtHeaders;
begin
  if GetModuleHeader(AProcess, AModuleAsPtr, @IH) then
    Result := Pointer(IH.OptionalHeader.ImageBase)
  else
    Result := nil;
end;

function GetProcessModuleFileName(AProcess: THandle; AFile: THandle): String;

{

    "Obtaining a File Name From a File Handle"
    http://msdn2.microsoft.com/en-us/library/aa366789.aspx

}  

const
  BUF_SIZE = 512;

var
  bFound       : Boolean;
  dwFileSizeHi : DWORD;
  dwFileSizeLo : DWORD;
  hFileMap     : THandle;
  lpTemp       : PByte;
  nDriveCount  : Integer;
  pMem         : Pointer;
  szDrive      : array[0 .. 2] of Char;
  szFileName   : array[0 .. MAX_PATH] of Char;
  szName       : array[0 .. MAX_PATH] of Char;
  szTemp       : array[0 .. BUF_SIZE] of Char;
  TempFileName : String;
  uNameLen     : UINT;
begin
  Result   := '';

  { Get the file size }

  dwFileSizeLo := GetFileSize(AFile, @dwFileSizeHi);
  if (dwFileSizeLo = 0) and (dwFileSizeHi = 0) then
    Exit;

  { Create a file mapping object }

  hFileMap := CreateFileMapping(
    AFile,
    nil,
    PAGE_READONLY,
    0,
    MAX_PATH,
    nil
  );

  if (hFileMap <= 0) then
    Exit;

  { Create a file mapping to get the file name }

  pMem := MapViewOfFile(hFileMap, FILE_MAP_READ, 0, 0, 1);

  if not Assigned(pMem) then begin
    CloseHandle(hFileMap);
    Exit;
  end;

  if (GetMappedFileName(
    GetCurrentProcess(),
    pMem,
    szFileName,
    MAX_PATH
  ) <= 0) then begin
    UnmapViewOfFile(pMem);
    CloseHandle(hFileMap);
    Exit;
  end;

  { Translate path with device name to drive letters }

  szTemp[0]   := #0;
  nDriveCount := GetLogicalDriveStrings((BUF_SIZE - 1), szTemp);

  if (nDriveCount <= 0) then begin
    UnmapViewOfFile(pMem);
    CloseHandle(hFileMap);
    Exit;
  end;

  bFound      := False;
  szDrive     := ' :';
  nDriveCount := nDriveCount div (SizeOf(szDrive) + 1 { Null });
  lpTemp      := @szTemp;

  repeat
    { Copy the drive letter to the template string }

    Byte(szDrive[0]) := lpTemp^;

    { Look up each device name }

    if (QueryDosDevice(szDrive, szName, BUF_SIZE) > 0) then begin
      uNameLen := StrLen(szName);

      if (uNameLen < MAX_PATH) then begin
        bFound := (StrLComp(szFileName, szName, uNameLen) = 0);
        
        if bFound then begin
          TempFileName := StrPas(szFileName);
          TempFileName := Copy(TempFileName, (uNameLen + 1), MaxInt);
          Result       := Format('%s%s', [szDrive, TempFileName]);
        end;
      end;
    end;

    { Go to the next NULL character }

    lpTemp      := Pointer(DWORD(lpTemp) + (SizeOf(szDrive) + 1 { Null }));
    nDriveCount := nDriveCount - 1;
  until (bFound or (nDriveCount <= 0));

  UnmapViewOfFile(pMem);
  CloseHandle(hFileMap);
end;

function SearchModulePath(const AModuleName: String): String;
var
  Path : array[0 .. MAX_PATH] of Char;
  Part : PChar;
begin
  if (SearchPath(
    nil,
    PChar(AModuleName),
    nil,
    MAX_PATH,
    Path,
    Part
  ) <= 0) then
    Result := ''
  else
    Result := StrPas(Path);
end;

function GetProcessModuleFileNameEx(APID: DWORD; const AModuleName: String): String;

{var
  hModule  : array[0 .. (MAX_PROCESS_MODULES - 1)] of DWORD;
  nCount   : DWORD;
  szMod    : array[0 .. MAX_PATH] of Char;
begin
  Result := '';

  if not EnumProcessModules(
    AProcess,
    @hModule,
    SizeOf(hModule),
    nCount)
  then
    Exit;

  nCount := nCount div SizeOf(DWORD);

  while (nCount > 0) do begin
    GetModuleFileNameExA(AProcess, hModule[nCount - 1], szMod, MAX_PATH);

    //**

    Dec(nCount);
  end;
end;}

var
  hSnap    : THandle;
  ModEntry : TModuleEntry32;

begin
  Result := '';

  hSnap := CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, APID);

  if (hSnap <= 0) then
    Exit;

  if Module32First(hSnap, ModEntry) then
    repeat

      if SameText(AModuleName, ModEntry.szModule) then begin
        Result := ModEntry.szExePath;
        Break;
      end;

    until not Module32Next(hSnap, ModEntry);

  CloseHandle(hSnap);
end;

function WriteProcMem(AProcess: THandle; AProcMem, ALocalMem: Pointer; ASize: DWORD): Boolean;
var
  dwWrote : DWORD;
begin
  Result := WriteProcessMemory(
    AProcess,
    AProcMem,
    ALocalMem,
    ASize,
    dwWrote
  );
end;

function GetThreadHandleByID(AThreadId: DWORD): THandle;

{
    From JclDebug.pas -> JclCreateThreadStackTraceFromID
}

type
  TOpenThreadFunc = function(DesiredAccess: DWORD; InheritHandle: BOOL; ThreadID: DWORD): THandle; stdcall;

var
  Kernel32Lib    : THandle;
  OpenThreadFunc : TOpenThreadFunc;

begin
  Result      := 0;
  Kernel32Lib := GetModuleHandle(kernel32);

  if (Kernel32Lib <> 0) then begin
    OpenThreadFunc := GetProcAddress(Kernel32Lib, 'OpenThread');
    if Assigned(OpenThreadFunc) then
      Result := OpenThreadFunc(THREAD_GET_CONTEXT or THREAD_QUERY_INFORMATION, False, AThreadID);
  end;
end;

function GetModuleInfos(AProcess: THandle; AProcessId: DWORD; AModuleAddress: DWORD; out AModuleInfos: TModuleInfo): Boolean;
var
  hSnap       : THandle;
  ModuleEntry : TModuleEntry32;
  ModuleInfo  : TModuleInfo;
begin
  Result := GetModuleInformation(AProcess, HINST(AModuleAddress), @ModuleInfo, SizeOf(TModuleInfo));
  if Result then
    AModuleInfos := ModuleInfo
  else begin
    hSnap := CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, AProcessId);

    if (hSnap > 0) then begin
      ModuleEntry.dwSize := SizeOf(TModuleEntry32);

      if Module32First(hSnap, ModuleEntry) then
        repeat

          Result := (ModuleEntry.modBaseAddr = Pointer(AModuleAddress));
          if Result then begin
            AModuleInfos.lpBaseOfDll := ModuleEntry.modBaseAddr;
            AModuleInfos.SizeOfImage := ModuleEntry.modBaseSize;
            AModuleInfos.EntryPoint  := nil;

            Break;
          end;

        until not Module32Next(hSnap, ModuleEntry);

      CloseHandle(hSnap);
    end;
  end;
end;

function GetModuleCodeBase(AProcess: THandle; AModuleAsPtr: Pointer; out ACodeBase: DWORD): Boolean;
var
  IH : TImageNtHeaders;
begin
  Result := GetModuleHeader(AProcess, AModuleAsPtr, @IH);
  if Result then
    ACodeBase := IH.OptionalHeader.BaseOfCode
  else
    ACodeBase := 0;
end;

end.

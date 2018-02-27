unit uCore;

interface

uses    
  Classes,
  hCore,
  hCoreServices,
  hExcProvider,
  hStackWalk,
  hSymProvider,
  IniFiles,
  Messages,
  Sysutils,
  TypInfo,
  uBreakpoints,
  uDebugUtils,
  uExcProviders,
  uLog,
  uLogRotator,
  uModulesList,
  uSymProviders,
  uThreadsList,
  Windows;

type
  TBugFinderCore = class(TObject, IUnknown, ICoreServices)
  private
    FAppProvider  : ISymbolProvider;
    FAppCodeBase  : DWORD;
    FBreakpoints  : TBreakPoints;
    FConfig       : TCoreConfiguration;
    FExcProviders : TExceptionProviders;
    FIniFileName  : String;
    FLastErr      : String;
    FLog          : TLogFile;
    FLogEvent     : TLogEvent;
    FLogRotator   : TTimeLogRotator;
    FModules      : TModulesList;
    FProcData     : TCreateProcessDebugInfo;
    FProcInfo     : TProcessInformation;
    FSymProviders : TSymbolProviders;
    FStopped      : Boolean;
    FThreads      : TThreadsList;

    FIsStartBP   : Boolean;
    FLastBP      : TBreakpoint;

    function    LoadBreakpoints(const AModuleName: String; ASymProvider: ISymbolProvider; AModuleCodeBase: DWORD): Boolean;
    function    LoadExceptionProviders: Boolean;
    function    LoadSymbolProviders: Boolean;

    function    AcquireDebugPrivilege: Boolean;
    procedure   Debug;

    procedure   HandleEvent_BreakPoint(ARawAddress, ARelativeAddress: DWORD; AException: PExceptionRecord; AThreadID: DWORD);
    procedure   HandleEvent_BreakPoint_SingleStep(ADbgAddr: DWORD);
    procedure   HandleEvent_CreatedProcess(AInfos: PCreateProcessDebugInfo; AThreadId: DWORD);
    procedure   HandleEvent_CreatedThread(AInfos: PCreateThreadDebugInfo; AThreadId: DWORD);
    function    HandleEvent_Exception(AException: PExceptionRecord; AThreadId: DWORD): Boolean;
    procedure   HandleEvent_ExitProcess(AInfos: PExitProcessDebugInfo; AThreadId: DWORD);
    procedure   HandleEvent_ExitThread(AInfos: PExitThreadDebugInfo; AThreadId: DWORD);
    procedure   HandleEvent_GenericException(AException: PExceptionRecord; AThreadId: DWORD);
    procedure   HandleEvent_LoadedDLL(ADLL: PLoadDLLDebugInfo);
    procedure   HandleEvent_OutputDebugString(AODS: POutputDebugStringInfo);
    procedure   HandleEvent_UnloadedDLL(ADLL: PUnloadDLLDebugInfo);

    procedure   LogDebugInfos(AException: PExceptionRecord; ARawAddress, ARelativeAddress: DWORD; const AMessage: String; AIsError: Boolean; const AExceptionProvider: IExceptionProvider; AThreadId: DWORD);

    procedure   DisplayErrorMsg(const AMsg: String); overload;
    procedure   DisplayErrorMsg(const AFormat: String; AArgs: array of const); overload;

    procedure   LogMsg(const AMsg: String; AIsError: Boolean); overload;
    procedure   LogMsg(const AFormat: String; AArgs: array of const; AIsError: Boolean); overload;

    { IUnknown }

    function    QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function    _AddRef: Integer; stdcall;
    function    _Release: Integer; stdcall;

    { ICoreServices }

    function    GetProcess: THandle;
    function    GetProcessDebugInfo: PCreateProcessDebugInfo;
    function    GetProcessInfo: PProcessInformation;
    procedure   LogMessage(AMsg: PChar; AIsError: BOOL);

  public
    constructor Create(const AIniFileName: String); reintroduce;
    destructor  Destroy; override;

    function    LoadConfiguration(out AErrorMessage: String): Boolean;
    function    Run: Boolean;
    procedure   Terminate;

    property    Config      : TCoreConfiguration read FConfig;
    property    IniFileName : String             read FIniFileName;

    property    LogEvent    : TLogEvent          read FLogEvent write FLogEvent;
    property    Stopped     : Boolean            read FStopped;
  end;

implementation

uses
  Dialogs;

{ TBugFinderCore }

function TBugFinderCore.AcquireDebugPrivilege: Boolean;
var
  NewState     : TTokenPrivileges;
  NewLuid      : TLargeInteger;
  hToken       : THandle;
  ReturnLength : DWORD;
begin
  FLastErr := '';
  Result   := False;

  if not OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES, hToken) then begin
    FLastErr := SysErrorMessage(GetLastError);
    Exit;
  end;

  if not LookupPrivilegeValue(nil, 'SeDebugPrivilege', NewLuid) then begin
    FLastErr := SysErrorMessage(GetLastError);
    CloseHandle(hToken);
    Exit;
  end;

  with NewState do begin
    PrivilegeCount     := 1;

    with Privileges[0] do begin
      Luid       := NewLuid;
      Attributes := SE_PRIVILEGE_ENABLED
    end;
  end;

  if not AdjustTokenPrivileges(
    hToken,
    False,
    NewState,
    SizeOf(NewState),
    nil,
    ReturnLength
  ) then begin
    FLastErr := SysErrorMessage(GetLastError);
    CloseHandle(hToken);
    Exit;
  end;

  CloseHandle(hToken);
  Result := True;
end;

constructor TBugFinderCore.Create(const AIniFileName: String);
begin
  inherited Create;

  FIniFileName  := AIniFileName;
  FLog          := nil;
  FLogEvent     := nil;
  FLogRotator   := TTimeLogRotator.Create;
  FSymProviders := TSymbolProviders.Create;
  FModules      := TModulesList.Create(FSymProviders);
  FThreads      := TThreadsList.Create;
  FBreakpoints  := TBreakPoints.Create(FThreads);
  FExcProviders := TExceptionProviders.Create;
  FAppProvider  := nil;
  FStopped      := True;
end;

procedure TBugFinderCore.Debug;
var
  Event  : TDebugEvent;
  LError : Integer;
  Path   : String;
  lpPrms : PChar; 
  lpPath : PChar;
  SI     : TStartupInfo;
begin
  FStopped := True;

  FillChar(SI, SizeOf(TStartupInfo), 0);

  with SI do begin
    cb          := SizeOf(TStartupInfo);
    dwFlags     := STARTF_USESHOWWINDOW;
    wShowWindow := SW_SHOWNORMAL;
  end;

  if (FConfig.AppParameters <> '') then
    lpPrms := PChar(FConfig.AppParameters)
  else
    lpPrms := nil;

  Path := ExtractFileDir(FConfig.AppFileName);
  if (Path = '') then
    lpPath := nil
  else
    lpPath := PChar(Path);

  if not CreateProcess(
    PChar(FConfig.AppFileName),
    PChar(lpPrms),
    nil,
    nil,
    False,
    DEBUG_ONLY_THIS_PROCESS,
    nil,
    lpPath,
    SI,
    FProcInfo
  ) then begin
    LogMsg('Unable to create process: "%s".', [SysErrorMessage(GetLastError)], True);
    Exit;
  end;

  FAppCodeBase := 0;
  FStopped     := False;
  FIsStartBP   := True;
  FLastBP      := nil;

  while not FStopped do begin

    SetLastError(ERROR_SUCCESS);
    
    while WaitForDebugEvent(Event, 100) do begin

      case Event.dwDebugEventCode of

        EXCEPTION_DEBUG_EVENT      : begin
          if HandleEvent_Exception(@Event.Exception, Event.dwThreadId) then
            with Event.Exception.ExceptionRecord do
              if
                (ExceptionCode  <> EXCEPTION_BREAKPOINT)  and
                (ExceptionCode  <> EXCEPTION_SINGLE_STEP)
              then
                with Event do
                  ContinueDebugEvent(dwProcessId, dwThreadId, DBG_EXCEPTION_NOT_HANDLED);
        end;

        OUTPUT_DEBUG_STRING_EVENT  : HandleEvent_OutputDebugString(@Event.DebugString);

        CREATE_THREAD_DEBUG_EVENT  : HandleEvent_CreatedThread(@Event.CreateThread, Event.dwThreadId);
        EXIT_THREAD_DEBUG_EVENT    : HandleEvent_ExitThread(@Event.CreateThread, Event.dwThreadId);

        LOAD_DLL_DEBUG_EVENT       : HandleEvent_LoadedDLL(@Event.LoadDll);
        UNLOAD_DLL_DEBUG_EVENT     : HandleEvent_UnloadedDLL(@Event.UnloadDll);

        CREATE_PROCESS_DEBUG_EVENT : HandleEvent_CreatedProcess(@Event.CreateProcessInfo, Event.dwThreadId);

        EXIT_PROCESS_DEBUG_EVENT   : begin
          HandleEvent_ExitProcess(@Event.ExitProcess, Event.dwThreadId);
          FStopped := True;
          Break;
        end;

      end;

      with Event do
        ContinueDebugEvent(dwProcessId, dwThreadId, DBG_CONTINUE);
    end;

    LError := GetLastError;
    if
      (LError <> ERROR_SUCCESS) and
      (LError <> ERROR_SEM_TIMEOUT)
    then
      LogMsg('Debug loop error: "[%d] %s".', [GetLastError, SysErrorMessage(GetLastError)], True);

    if FStopped then
      Break;
  end;
end;

destructor TBugFinderCore.Destroy;
begin
  FAppProvider := nil;

  FreeAndNil(FExcProviders);
  FreeAndNil(FBreakpoints);
  FreeAndNil(FThreads);
  FreeAndNil(FModules);
  FreeAndNil(FSymProviders);
  FreeAndNil(FLogRotator);

  inherited Destroy;
end;

procedure TBugFinderCore.LogDebugInfos(AException: PExceptionRecord; ARawAddress, ARelativeAddress: DWORD; const AMessage: String; AIsError: Boolean; const AExceptionProvider: IExceptionProvider; AThreadId: DWORD);
var
  Depth    : Integer;
  DbgInfos : ISymbol;
  Frame    : TStackFrame;
  Offset   : DWORD;
  Handle   : THandle;
  ModName  : String;
  Module   : TModuleItem;
begin
  { Init }

  if not FThreads.GetFrame(AThreadId, Frame, Handle) then begin
    LogMsg('Error getting context frame for thread 0x%.08x: "%s".', [AThreadId, SysErrorMessage(GetLastError)], True);
    Exit;
  end;

  Depth := FConfig.StackDepth;

  { Custom exception provider }

  LogMsg(AMessage, [ARelativeAddress], AIsError);

  if Assigned(AExceptionProvider) then
    AExceptionProvider.HandleException(AException);

  while (Depth > 0) do begin

    { Get Stack Infos }

    if not StackWalk(
      IMAGE_FILE_MACHINE_I386,
      FProcData.hProcess,
      Handle,
      @Frame,
      nil,
      nil,
      @SymFunctionTableAccess,
      @SymGetModuleBase,
      nil
    ) then begin
      { No more stack entries... }

      Exit;
    end;

    ARawAddress      := Frame.AddrPC.Offset;
    ARelativeAddress := ARawAddress;

    { Extract debug infos }

    if not FModules.GetDebugInfos(@FProcInfo, ARawAddress, ARelativeAddress, Module, DbgInfos, ModName) then begin

      Offset := DWORD(FProcData.lpBaseOfImage) + FAppCodeBase;

      if (Offset < ARelativeAddress) then
        ARelativeAddress := ARelativeAddress - Offset
      else
        ARelativeAddress := 0;

      if
        Assigned(FAppProvider) and
        (ARelativeAddress > 0)
      then
        DbgInfos := FAppProvider.QuerySymbol(ARawAddress, ARelativeAddress)
      else
        DbgInfos := nil;

      ModName  := ExtractFileName(FConfig.AppFileName);
    end;

    { Header }

    LogMsg('', AIsError);
    LogMsg('  Stack call #%d:', [FConfig.StackDepth - Depth + 1], AIsError);
    LogMsg('    Binary name : %s', [ModName], AIsError);

    { Symbols details }

    if Assigned(DbgInfos) then
      try
        LogMsg('    Source file : %s', [DbgInfos.SourceName], AIsError);
        LogMsg('    Module name : %s', [DbgInfos.ModuleName], AIsError);
        LogMsg('    Procedure   : %s', [DbgInfos.ProcName],   AIsError);
        LogMsg('    Line number : %d', [DbgInfos.LineNumber], AIsError);
      finally
        DbgInfos := nil;
      end;  

    { Dec stack depth }  

    Dec(Depth);
  end;    
end;

procedure TBugFinderCore.HandleEvent_LoadedDLL(ADLL: PLoadDLLDebugInfo);
var
  Module : TModuleItem;
begin
  Module := FModules.Add(@FProcInfo, @FProcData, ADll, Self);

  LoadBreakpoints(Module.Path, Module.SymProvider, Module.CodeBase);

  if not FConfig.SuppressDllEvents then
    with Module do begin
      LogMsg('Loaded DLL: "%s".', [Name], False);
      if Relocated then
        LogMsg('  Wanted addr.: 0x%.08x', [WantedAddr], False);

      LogMsg('  Base address: 0x%.08x', [Address], False);
      LogMsg('  Full path   : "%s"', [Path], False);
      LogMsg('  Symbols     : %s', [BooleanIdents[Assigned(Module.SymProvider)]], False);
    end;
end;

procedure TBugFinderCore.HandleEvent_UnloadedDLL(ADLL: PUnloadDLLDebugInfo);
var
  Module : TModuleItem;
begin
  Module := FModules.Find(ADLL^.lpBaseOfDll);

  if not Assigned(Module) then
    LogMsg('Module to unload at address 0x%.08x not found!', [DWORD(ADLL^.lpBaseOfDll)], True)
  else begin
    if not FConfig.SuppressDllEvents then
      LogMsg('Unloaded module "%s".', [Module.Path], False);

    FModules.Remove(Module);
  end;
end;

procedure TBugFinderCore.HandleEvent_CreatedProcess(AInfos: PCreateProcessDebugInfo; AThreadId: DWORD);
begin
  FProcData := AInfos^;
  GetModuleCodeBase(FProcInfo.hProcess, FProcData.lpBaseOfImage, FAppCodeBase);
  FThreads.Add(AThreadId, FProcData.hThread);

  FAppProvider := FSymProviders.QueryProvider(Self, FConfig.AppFileName, nil);

  if not FConfig.SuppressProcessEvents then begin
    LogMsg('Created process with handle 0x%.08x.', [FProcData.hProcess], False);
    LogMsg('  Symbols : %s', [BooleanIdents[Assigned(FAppProvider)]], False);
  end;

  LoadBreakpoints(FConfig.AppFileName, FAppProvider, FAppCodeBase);
end;

procedure TBugFinderCore.HandleEvent_CreatedThread(AInfos: PCreateThreadDebugInfo; AThreadId: DWORD);
begin
  FThreads.Add(AThreadId, AInfos^.hThread);

  if not FConfig.SuppressThreadEvents then
    LogMsg('Created thread 0x%.08x with handle 0x%.08x.', [AThreadId, AInfos^.hThread], False);
end;

procedure TBugFinderCore.HandleEvent_BreakPoint(ARawAddress, ARelativeAddress: DWORD; AException: PExceptionRecord; AThreadID: DWORD);
var
  BP : TBreakpoint;
begin
  if FIsStartBP then begin
    FIsStartBP := False;
    LogDebugInfos(AException, ARawAddress, ARelativeAddress, 'Application entry breakpoint at 0x%.08x.', False, nil, AThreadID);
  end else begin

    { Resume from breakpoint }

    BP := FBreakpoints.Find(ARelativeAddress);
    if not Assigned(BP) then begin                              
      LogMsg('Breakpoint data not found for address 0x%.08x.', [ARelativeAddress], True);
      Exit;
    end;

    if not FConfig.SuppressBreakpointSourceDetails then
      LogDebugInfos(AException, ARawAddress, ARelativeAddress, 'Breakpoint at 0x%.08x ' + Format('[%s]', [BP.Name]), False, nil, AThreadID);

    if not BP.Resume(AThreadID) then
      LogMsg('Errore resuming breapoint "%s".', [BP.Name], True)
    else begin
      FLastBP := BP;
      LogMsg('BP "%s" on "[%s] %s::%s".', [BP.Name, BP.Module, BP.UnitName, BP.Method], False);
    end;
  end;
end;

procedure TBugFinderCore.HandleEvent_BreakPoint_SingleStep(ADbgAddr: DWORD);
var
  BP : TBreakpoint;
begin
  BP := FLastBP;

  if not Assigned(BP) then begin
    BP := FBreakpoints.Find(ADbgAddr - 1);
    
    if not Assigned(BP) then begin
      LogMsg('Breakpoint data not found for address 0x%.08x.', [ADbgAddr], True);
      Exit;
    end;
  end;

  if not BP.Activate(FProcData.hProcess) then
    LogMsg('Error re/activating breapoint "%s".', [BP.Name], True);

  FLastBP := nil;
end;

function TBugFinderCore.HandleEvent_Exception(AException: PExceptionRecord; AThreadId: DWORD): Boolean;
var
  ErrMsg     : String;
  TmpAddress : DWORD;
begin
  Result      := True;
  TmpAddress  := DWORD(AException^.ExceptionAddress);

  case AException^.ExceptionCode of

    EXCEPTION_DATATYPE_MISALIGNMENT    : LogDebugInfos(AException, TmpAddress, TmpAddress, 'Data type misalignment at 0x%.08x.', True, nil, AThreadID);
    EXCEPTION_ARRAY_BOUNDS_EXCEEDED    : LogDebugInfos(AException, TmpAddress, TmpAddress, 'Array bounds exceeded at 0x%.08x.', True, nil, AThreadID);
    EXCEPTION_FLT_DENORMAL_OPERAND     : LogDebugInfos(AException, TmpAddress, TmpAddress, 'Floating point denormal operator at 0x%.08x.', True, nil, AThreadID);
    EXCEPTION_FLT_INEXACT_RESULT       : LogDebugInfos(AException, TmpAddress, TmpAddress, 'Floating point inexact result at 0x%.08x.', True, nil, AThreadID);
    EXCEPTION_FLT_INVALID_OPERATION    : LogDebugInfos(AException, TmpAddress, TmpAddress, 'Floating point invalid operation at 0x%.08x.', True, nil, AThreadID);
    EXCEPTION_FLT_OVERFLOW             : LogDebugInfos(AException, TmpAddress, TmpAddress, 'Floating point overflow at 0x%.08x.', True, nil, AThreadID);
    EXCEPTION_FLT_STACK_CHECK          : LogDebugInfos(AException, TmpAddress, TmpAddress, 'Floating stack check at 0x%.08x.', True, nil, AThreadID);
    EXCEPTION_FLT_UNDERFLOW            : LogDebugInfos(AException, TmpAddress, TmpAddress, 'Floating underflow at 0x%.08x.', True, nil, AThreadID);
    EXCEPTION_INT_OVERFLOW             : LogDebugInfos(AException, TmpAddress, TmpAddress, 'Integer overflow at 0x%.08x.', True, nil, AThreadID);
    EXCEPTION_IN_PAGE_ERROR            : LogDebugInfos(AException, TmpAddress, TmpAddress, 'Page error at 0x%.08x.', True, nil, AThreadID);
    EXCEPTION_GUARD_PAGE               : LogDebugInfos(AException, TmpAddress, TmpAddress, 'Guard page at 0x%.08x.', True, nil, AThreadID);
    EXCEPTION_INVALID_HANDLE           : LogDebugInfos(AException, TmpAddress, TmpAddress, 'Invalid handle at 0x%.08x.', True, nil, AThreadID);
    CONTROL_C_EXIT                     : LogDebugInfos(AException, TmpAddress, TmpAddress, 'Ctrl+C exit at 0x%.08x.', True, nil, AThreadID);

    EXCEPTION_ACCESS_VIOLATION : begin
      ErrMsg := Format('(Write: %s; Address: 0x%.08x).', [
        BooleanIdents[AException^.ExceptionInformation[0] = 1],
        AException^.ExceptionInformation[1]
      ]);

      ErrMsg := 'Access violation at 0x%.08x ' + ErrMsg;

      LogDebugInfos(AException, TmpAddress, TmpAddress, ErrMsg, True, nil, AThreadID);
    end;

    EXCEPTION_FLT_DIVIDE_BY_ZERO       : begin
      LogDebugInfos(AException, TmpAddress, TmpAddress, 'Floating point divide by zero at 0x%.08x.', True, nil, AThreadID);
      Result := False;
    end;

    EXCEPTION_INT_DIVIDE_BY_ZERO       : begin
      LogDebugInfos(AException, TmpAddress, TmpAddress, 'Integer divide by zero at 0x%.08x.', True, nil, AThreadID);
      Result := False;
    end;

    EXCEPTION_PRIV_INSTRUCTION         : begin
      LogDebugInfos(AException, TmpAddress, TmpAddress, 'Privileged instruction at 0x%.08x.', True, nil, AThreadID);
      Result := False;
    end;

    EXCEPTION_ILLEGAL_INSTRUCTION      : begin
      LogDebugInfos(AException, TmpAddress, TmpAddress, 'Illegal instruction at 0x%.08x.', True, nil, AThreadID);
      Result := False;
    end;

    EXCEPTION_NONCONTINUABLE_EXCEPTION : begin
      LogDebugInfos(AException, TmpAddress, TmpAddress, 'Non continuable exception at 0x%.08x.', True, nil, AThreadID);
      Result := False;
    end;

    EXCEPTION_STACK_OVERFLOW           : begin
      LogDebugInfos(AException, TmpAddress, TmpAddress, 'Stack overflow at 0x%.08x.', True, nil, AThreadID);
      Result := False;
    end;

    EXCEPTION_INVALID_DISPOSITION      : begin
      LogDebugInfos(AException, TmpAddress, TmpAddress, 'Invalid disposition at 0x%.08x.', True, nil, AThreadID);
      Result := False;
    end;

    EXCEPTION_BREAKPOINT               : HandleEvent_BreakPoint(TmpAddress, TmpAddress, AException, AThreadId);
    EXCEPTION_SINGLE_STEP              : HandleEvent_BreakPoint_SingleStep(TmpAddress);

    else begin
      HandleEvent_GenericException(AException, TmpAddress);
    end;    
  end;
end;

procedure TBugFinderCore.HandleEvent_ExitProcess(AInfos: PExitProcessDebugInfo; AThreadId: DWORD);
begin
  FThreads.Remove(AThreadId);

  if not FConfig.SuppressProcessEvents then
    LogMsg('Terminated process with code %d.', [AInfos^.dwExitCode], False);
end;

procedure TBugFinderCore.HandleEvent_ExitThread(AInfos: PExitThreadDebugInfo; AThreadId: DWORD);
begin
  FThreads.Remove(AThreadId);

  if not FConfig.SuppressThreadEvents then
    LogMsg('Exited thread %.08x with code %d.', [AThreadId, AInfos^.dwExitCode], False);
end;

procedure TBugFinderCore.HandleEvent_GenericException(AException: PExceptionRecord; AThreadId: DWORD);
var
  ErrMsg      : String;
  ExcProvider : IExceptionProvider;
  RelAddress  : DWORD;
  TmpAddress : DWORD;
begin
  { Get custom exception provider }

  ExcProvider := FExcProviders.QueryProvider(Self, AException);
  TmpAddress  := DWORD(AException^.ExceptionAddress);

  if Assigned(ExcProvider) then begin
    { Custom exception provider }

    ErrMsg     := ExcProvider.GetDescription + ' at address 0x%.08x.';
    RelAddress := ExcProvider.TranslateExceptionAddress(AException);

    LogDebugInfos(AException, TmpAddress, RelAddress, ErrMsg, True, ExcProvider, AThreadID);
  end else begin
    { Unknown exception }

    ErrMsg := Format('Unknown exception: code = 0x%.08x, ', [AException^.ExceptionCode]);
    ErrMsg := ErrMsg + 'address 0x%.08x, ';

    try
      ErrMsg := ErrMsg + Format('sys. msg. = "%s".', [SysErrorMessage(AException^.ExceptionCode)]);
    except
      ErrMsg := ErrMsg + 'sys. msg. = "Unknown!".';
    end;

    LogDebugInfos(AException, TmpAddress, TmpAddress, ErrMsg, (AException^.ExceptionCode <> ERROR_SUCCESS), nil, AThreadID);
  end;

  ExcProvider := nil;
end;

procedure TBugFinderCore.HandleEvent_OutputDebugString(AODS: POutputDebugStringInfo);
var
  Len : Integer;
  Buf : Pointer;
  Str : String;
begin
  if not FConfig.SuppressOutputDebugStringEvents then begin

    Len := AODS^.nDebugStringLength;
    if (AODS^.fUnicode <> 0) then
      Len := Len * 2;

    GetMem(Buf, Len);

    if not ReadProcMem(FProcInfo.hProcess, AODS^.lpDebugStringData, Buf, Len) then
      LogMsg('Invalid ODS string data!', True)
    else begin
      if (AODS^.fUnicode = 0) then
        SetString(Str, PAnsiChar(Buf), (Len - 1))
      else
        WideCharLenToStrVar(PWideChar(Buf), (Len div 2), Str);

      LogMsg('ODS: "%s".', [Str], False);
    end;

  end;
end;

function TBugFinderCore.Run: Boolean;
begin
  Result  := False;

  { Set log }

  FLogRotator.Mode := FConfig.LogFileRotation;
  FLog             := TLogFile.Create(FLogRotator, False, FConfig.LogFileName);
  FLog.Details     := [ldDateTime];

  { Load providers }

  if
    not LoadExceptionProviders or
    not LoadSymbolProviders
  then
    Exit;

  { Check file name }

  if not FileExists(FConfig.AppFileName) then begin
    DisplayErrorMsg('File "%s" not found".', [FConfig.AppFileName]);
    Exit;
  end;

  { Acquiring debug priviledge }

  if (Win32Platform = VER_PLATFORM_WIN32_NT) then
    if not AcquireDebugPrivilege then begin
      LogMsg('Failed acquiring debug privilege: "%s".', [SysErrorMessage(GetLastError)], True);
      Exit;
    end;

  { Starting debugger }

  Debug;

  { Free resources }

  FreeAndNil(FLog);
  Result := True;
end;

procedure TBugFinderCore.LogMsg(const AMsg: String; AIsError: Boolean);
var
  Kind : TLogKind;
  Msg  : String;
begin
  if
    FConfig.SpoolToFile and
    Assigned(FLog)
  then begin
    if AIsError then
      Kind := lkError
    else
      Kind := lkInformation;

    FLog.AppendLine(AMsg, Kind);
    Msg := FLog.LastMessage;
  end;

  if Assigned(FLogEvent) then
    FLogEvent(Self, Msg, AIsError);
end;

procedure TBugFinderCore.LogMsg(const AFormat: String; AArgs: array of const; AIsError: Boolean);
begin
  LogMsg(Format(AFormat, AArgs), AIsError);
end;

procedure TBugFinderCore.Terminate;
var
  dwExitCode : DWORD;
begin
  if (FProcInfo.hProcess > 0) and not FStopped then begin
    LogMsg('Process termination requested by user!', False);

    PostThreadMessage(FProcInfo.dwThreadId, WM_CLOSE, 0, 0);
    WaitForSingleObject(FProcInfo.hProcess, 1000);

    GetExitCodeProcess(FProcInfo.hProcess, dwExitCode);
    if (dwExitCode = STILL_ACTIVE) then begin
      TerminateProcess(FProcInfo.hProcess, 0);
      {WaitForSingleObject(FProcInfo.hProcess, INFINITE);}
    end;

    CloseHandle(FProcInfo.hProcess);
  end;

  FillChar(FProcInfo, SizeOf(TProcessInformation), 0);
end;

function TBugFinderCore.LoadConfiguration(out AErrorMessage: String): Boolean;
begin
  AErrorMessage := '';
  Result        := False;

  if not FileExists(FIniFileName) then begin
    AErrorMessage := Format('Configuration file "%s" not found (Current directory: "%s").', [FIniFileName, GetCurrentDir]);
    Exit;
  end;

  with TIniFile.Create(FIniFileName) do
    try
      with FConfig do begin
        { Main }

        AppFileName                     := Trim(ReadString(SEC_CONFIG, CFG_VAL_APPFILENAME, ''));
        AppParameters                   := Trim(ReadString(SEC_CONFIG, CFG_VAL_APPPARAMETERS, ''));

        { Log }

        LogFileName                     := Trim(ReadString(SEC_LOG, CFG_VAL_LOGFILENAME, ''));
        LogFileRotation                 := TTimeLogRotation(ReadInteger(SEC_LOG, CFG_VAL_LOGFILEROTATION, DEF_VAL_LOGFILEROTATION));
        LogViewLinesLimit               := ReadInteger(SEC_LOG, CFG_VAL_LOGVIEWLINESLIMIT, DEF_VAL_LOGVIEWLINESLIMIT);

        PopUpOnErrors                   := ReadBool(SEC_LOG, CFG_VAL_POPUPONERRORS, True);

        SpoolToFile                     := ReadBool(SEC_LOG, CFG_VAL_SPOOLTOFILE, True);
        StackDepth                      := ReadInteger(SEC_LOG, CFG_VAL_STACKDEPTH, DEF_VAL_STACKDEPTH);

        SuppressBreakpointSourceDetails := ReadBool(SEC_LOG, CFG_VAL_SUPPRESSBREAKPOINTSOURCEDETAILS, False);
        SuppressDllEvents               := ReadBool(SEC_LOG, CFG_VAL_SUPPRESSDLLEVENTS, False);
        SuppressOutputDebugStringEvents := ReadBool(SEC_LOG, CFG_VAL_SUPPRESSOUTPUTDEBUGSTRINGEVENTS, False);
        SuppressProcessEvents           := ReadBool(SEC_LOG, CFG_VAL_SUPPRESSPROCESSEVENTS, False);
        SuppressThreadEvents            := ReadBool(SEC_LOG, CFG_VAL_SUPPRESSTHREADEVENTS, False);

        if (AppFileName = '') then begin
          AErrorMessage := 'Invalid application file name.';
          Exit;
        end;

        if not (LogFileRotation in [tlrDaily, tlrWeekly, tlrMonthly]) then begin
          AErrorMessage := Format('Invalid log file rotation policy (Value: %d).', [Integer(LogFileRotation)]);
          Exit;
        end;

        if (LogViewLinesLimit < 0) then begin
          AErrorMessage := Format('Invalid log view lines limit (Value: %d).', [LogViewLinesLimit]);
          Exit;
        end;

        if (StackDepth <= 0) then begin
          AErrorMessage := Format('Invalid stack depth (Value: %d).', [StackDepth]);
          Exit;
        end;

        Result := True;
      end;
    finally
      Free;
    end;
end;

function TBugFinderCore.LoadBreakpoints(const AModuleName: String; ASymProvider: ISymbolProvider; AModuleCodeBase: DWORD): Boolean;
var
  BP      : TBreakpoint;
  I       : Integer;
  List    : TStringList;
  ModName : String;
  Name    : String;
  Tkns    : TStringList;
begin
  Result  := True;

  ModName := ExtractFileName(AModuleName);
  List    := TStringList.Create;
  Tkns    := TStringList.Create;

  { Parse ini file }

  with TIniFile.Create(FIniFileName) do
    try
      ReadSection(SEC_BRKPTS, List);

      for I := 0 to (List.Count - 1) do begin

        { Parse BP entry }

        Name           := List[I];
        Tkns.CommaText := ReadString(SEC_BRKPTS, Name, '');

        if (Tkns.Count <> 3) then begin
          LogMsg('Invalid breakpoint entry specification for "%s".', [Name], True);
          Result := False;
          Break;
        end;

        Tkns[0] := Trim(Tkns[0]);
        Tkns[1] := Trim(Tkns[1]);
        Tkns[2] := Trim(Tkns[2]);

        if SameText(ModName, Tkns[0]) then begin

          { Validate BP }

          BP := FBreakpoints.ValidateBP(ASymProvider, Name, Tkns[0], Tkns[1], Tkns[2], AModuleCodeBase);

          if not Assigned(BP) then begin
            LogMsg('Invalid breakpoint entry for "%s": module or method not found for "%s".', [Name, ModName], True);
            Continue;
          end;

          { Set BP }

          if not FBreakpoints.Activate(BP, FProcData.hProcess) then begin
            LogMsg('Unable to activate breakpoint "%s".', [Name], True);
            Result := False;
            FreeAndNil(BP);
            Break;
          end;

          LogMsg('Added breakpoint "%s" for "[%s] %s.%s" at address 0x%.08x.', [Name, BP.Module, BP.UnitName, BP.Method, BP.Address], False);

        end;
      end;

    finally
      Free;
    end;

  FreeAndNil(Tkns);
  FreeAndNil(List);
end;

function TBugFinderCore.LoadExceptionProviders: Boolean;
var
  FName : String;
  I     : Integer;
  List  : TStringList;
begin
  Result := True;
  List   := TStringList.Create;

  with TIniFile.Create(FIniFileName) do
    try
      ReadSection(SEC_EXCPRV, List);

      for I := 0 to (List.Count - 1) do begin
        FName  := List[I];
        Result := FExcProviders.Add(FName, Trim(ReadString(SEC_EXCPRV, FName, '')));
        if not Result then begin
          LogMsg('Unable to load exception provider "%s".', [FName], True);
          Break;
        end;

        LogMsg('Loaded exception provider "%s".', [FName], False);
      end;
    finally
      Free;
    end;

  FreeAndNil(List);
end;

function TBugFinderCore.LoadSymbolProviders: Boolean;
var
  FName : String;
  I     : Integer;
  List  : TStringList;
begin
  Result := True;
  List   := TStringList.Create;

  with TIniFile.Create(FIniFileName) do
    try
      ReadSection(SEC_SYMPRV, List);

      for I := 0 to (List.Count - 1) do begin
        FName  := List[I];
        Result := FSymProviders.Add(FName, Trim(ReadString(SEC_SYMPRV, FName, '')));
        if not Result then begin
          LogMsg('Unable to load symbol provider "%s".', [FName], True);
          Break;
        end;

        LogMsg('Loaded symbol provider "%s".', [FName], False);
      end;
    finally
      Free;
    end;

  FreeAndNil(List);
end;

procedure TBugFinderCore.DisplayErrorMsg(const AMsg: String);
begin
  MessageDlg(AMsg, mtError, [mbAbort], 0);
end;

procedure TBugFinderCore.DisplayErrorMsg(const AFormat: String; AArgs: array of const);
begin
  DisplayErrorMsg(Format(AFormat, AArgs));
end;

function TBugFinderCore._AddRef: Integer;
begin
  Result := 2;
end;

function TBugFinderCore._Release: Integer;
begin
  Result := 1;
end;

function TBugFinderCore.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

procedure TBugFinderCore.LogMessage(AMsg: PChar; AIsError: BOOL);
begin
  LogMsg(AMsg, AIsError);
end;

function TBugFinderCore.GetProcessDebugInfo: PCreateProcessDebugInfo;
begin
  Result := @FProcData;
end;

function TBugFinderCore.GetProcess: THandle;
begin
  Result := FProcData.hProcess;
end;

function TBugFinderCore.GetProcessInfo: PProcessInformation;
begin
  Result := @FProcInfo;
end;

end.

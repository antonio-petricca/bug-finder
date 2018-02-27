unit uLog;

interface

uses
  Classes,
  SysUtils,
  Windows;

type
  TLogKind = (lkInformation, lkWarning, lkError, lkDebug);

const
  LOG_LABELS      : array[TLogKind] of String = ('Info', 'Warn', 'Errr', 'Dbug');
  LOG_LABELS_FULL : array[TLogKind] of String = ('Information', 'Warning', 'Error', 'Debug');
  LOG_DEF_MAXSIZE                             = 2000; { 2Mb }
  LOG_DEF_MAXSIZE_W9X                         = 60;
  LOG_DEF_MUTEX_TIMEOUT                       = 5000; { Ms  }

type
  TLogDetail  = (
    ldProcessId,
    ldThreadId,
    ldModuleHandle,
    ldDateTime
  );

  TLogDetails = set of TLogDetail;
  TLogFile    = class;

  TLogRotator = class(TObject)
  private
    FOwner : TLogFile;
  protected
    procedure   SetLogFileName(const AFileName: String); virtual;
  public
    constructor Create; reintroduce; virtual;

    procedure   Initialize; virtual; abstract;
    function    Validate: Boolean; virtual; abstract;

    property    Owner : TLogFile read FOwner;
  end;

  TLogFile = class(TObject)
  private
    procedure      SetRotator(const AValue: TLogRotator);
  protected
    FDetails      : TLogDetails;
    FFileName     : String;
    FFreeRotator  : Boolean;
    FLastError    : String;
    FLastMessage  : String;
    FLogDebug     : Boolean;
    FMaxSize      : Integer;
    FMutex        : THandle;
    FMutexTimeOut : Integer;
    FPrefix       : String;
    FRotator      : TLogRotator;

    function       CreateMutex: Boolean;
    procedure      DestroyMutex;
  public
    constructor    Create(const AFileName: String = ''); overload;
    constructor    Create(ARotator: TLogRotator; AFreeRotator: Boolean; const AFileName: String = ''); overload;
    destructor     Destroy; override;

    class function GetLogDateTime: String;
    class function GetModuleFileName: String;
    function       ValidateFile: Boolean; virtual;

    procedure      AppendLine(const ALine: String); overload; virtual;
    procedure      AppendLine(const ALine: String; AKind: TLogKind); overload; virtual;
    procedure      AppendLine(const AFormat: String; AArgs: array of const; AKind: TLogKind); overload; virtual;

    procedure      ResetLastError;

    function       WaitForReady: Boolean;
    procedure      ExitWaited;

    property       Details      : TLogDetails  read FDetails       write FDetails;
    property       FileName     : String       read FFileName;
    property       LastError    : String       read FLastError;
    property       LogDebug     : Boolean      read FLogDebug      write FLogDebug;
    property       MaxSize      : Integer      read FMaxSize       write FMaxSize;
    property       MutexTimeOut : Integer      read FMutexTimeOut  write FMutexTimeOut;
    property       Prefix       : String       read FPrefix        write FPrefix;

    property       FreeRotator  : Boolean      read FFreeRotator   write FFreeRotator;
    property       Rotator      : TLogRotator  read FRotator       write SetRotator;

    property       LastMessage  : String       read FLastMessage;
  end;

implementation

uses
  uUtils;

{ TLogRotator }

constructor TLogRotator.Create;
begin
  inherited Create;
end;

procedure TLogRotator.SetLogFileName(const AFileName: String);
begin
  FOwner.FFileName := AFileName;
end;

{ TLogFile }

procedure TLogFile.AppendLine(const ALine: String);
var
  F  : Integer;
  Ln : String;
begin
  F := -1;

  try
    { Enter mutex }

    if not WaitForReady then
      Exit;

    { Validate file size }

    ValidateFile;

    try
      { Append text line }

      if FileExists(FFileName) then
        F := FileOpen(FFileName, fmOpenWrite or fmShareDenyWrite)
      else
        F := FileCreate(FFileName);

      if (F <> INVALID_HANDLE_VALUE) then begin
        FileSeek(F, 0, soFromEnd);

        Ln := '';

        if (ldDateTime in FDetails) then
          Ln := Ln + Format('[%s] ', [GetLogDateTime]);

        if (ldProcessId in FDetails) then
          Ln := Ln + Format('[P: %.04x] ', [GetCurrentProcessId]);

        if (ldModuleHandle in FDetails) then
          Ln := Ln + Format('[M: %.04x] ', [HInstance]);

        if (ldThreadId in FDetails) then
          Ln := Ln + Format('[T: %.04x] ', [GetCurrentThreadId]);

        Ln := Format('%s%s%s', [
          Ln,
          FPrefix,
          ALine
        ]);

        FLastMessage := Ln;
        Ln           := Ln + #13#10;

        FileWrite(F, PChar(Ln)^, Length(Ln));
      end;
    finally
      if (F <> -1) then
        FileClose(F);
    end;

  finally
    { Release mutex }

    ExitWaited;
  end;
end;

procedure TLogFile.AppendLine(const ALine: String; AKind: TLogKind);
begin
  if not (not FLogDebug and (AKind = lkDebug)) then begin
    if (AKind = lkError) then
      FLastError := ALine;

    if (AKind >= Low(TLogKind)) and (AKind <= High(TLogKind)) then
      AppendLine(Format('[%s] %s', [LOG_LABELS[AKind], ALine]));
  end;
end;

procedure TLogFile.AppendLine(const AFormat: String; AArgs: array of const; AKind: TLogKind);
begin
  AppendLine(Format(AFormat, AArgs), AKind);
end;

constructor TLogFile.Create(const AFileName: String);

begin
  inherited Create;

  FDetails      := [ldThreadId, ldDateTime];
  FFileName     := Trim(AFileName);
  FFreeRotator  := False;
  FLogDebug     := False;
  FMaxSize      := LOG_DEF_MAXSIZE;
  FMutexTimeOut := LOG_DEF_MUTEX_TIMEOUT;
  FPrefix       := '';
  FRotator      := nil;

  if not IsOsWin32 then
    FMaxSize := LOG_DEF_MAXSIZE_W9X;

  if (FFileName = '') then
    FFileName := ChangeFileExt(GetModuleFileName, '.log');

  CreateMutex;
end;

function TLogFile.CreateMutex: Boolean;
var
  MutexName : String;
begin
  MutexName := FFileName;
  MutexName := StringReplace(MutexName, ':', '_', [rfReplaceAll]);
  MutexName := StringReplace(MutexName, '\', '_', [rfReplaceAll]);
  MutexName := StringReplace(MutexName, '.', '_', [rfReplaceAll]);
  FMutex    := Windows.CreateMutex(nil, FALSE, PChar(MutexName));
  Result    := (FMutex <> INVALID_HANDLE_VALUE);
end;

destructor TLogFile.Destroy;
begin
  DestroyMutex;

  if
    Assigned(FRotator) and
    FFreeRotator
  then
    FreeAndNil(FRotator);

  inherited Destroy;
end;

procedure TLogFile.DestroyMutex;
begin
  if (FMutex <> INVALID_HANDLE_VALUE) then begin
    CloseHandle(FMutex);
    FMutex := INVALID_HANDLE_VALUE;
  end;
end;

class function TLogFile.GetLogDateTime: String;
begin
  Result := FormatDateTime('DD/MM/YYYY HH:NN:SS', Now);
end;

class function TLogFile.GetModuleFileName: String;
var
  ModName : array[0 .. MAX_PATH] of Char;
begin
  Windows.GetModuleFileName(HInstance, ModName, SizeOf(ModName));
  Result := StrPas(ModName);
end;

function TLogFile.ValidateFile: Boolean;
var
  F   : THandle;
  Sz  : DWORD;
  FNm : String;
begin
  if Assigned(FRotator) then
    try
      Result := FRotator.Validate
    except
      Result := False;
    end
  else
    try
      if not FileExists(FFileName) then
        Sz := 0
      else begin
        F := FileOpen(FFileName, fmOpenRead or fmShareDenyNone);
        if (F <> INVALID_HANDLE_VALUE) then begin
          Sz := GetFileSize(F, nil);
          FileClose(F);
        end else
          Sz := 0;
      end;

      Result := (Sz < (FMaxSize * 1024));
      if not Result then begin
        FNm := FormatDateTime('YYYYMMDDHHNNSSZZZ', Now);
        FNm := FFileName + '.' + FNm;

        RenameFile(FFileName, FNm);
      end;
    except
      Result := False;
    end;
end;

procedure TLogFile.ResetLastError;
begin
  FLastError := '';
end;

function TLogFile.WaitForReady: Boolean;
begin
  Result := (WaitForSingleObject(FMutex, FMutexTimeOut) <> WAIT_TIMEOUT);
end;

procedure TLogFile.ExitWaited;
begin
  ReleaseMutex(FMutex);
end;

constructor TLogFile.Create(ARotator: TLogRotator; AFreeRotator: Boolean; const AFileName: String);
begin
  Create(AFileName);

  FFreeRotator := AFreeRotator;
  SetRotator(ARotator);
end;

procedure TLogFile.SetRotator(const AValue: TLogRotator);
begin
  FRotator := AValue;
  if Assigned(FRotator) then begin
    FRotator.FOwner := Self;
    FRotator.Initialize;
  end;
end;

end.

unit uDebugThread;

interface

uses
  Classes,
  SysUtils,
  hCore,
  uCore;

type
  TDebugThread = class(TThread)
  private
    FCore        : TBugFinderCore;
    FErrorStatus : Boolean;
    FIsError     : Boolean;
    FLogEvent    : TLogEvent;
    FMessage     : String;

    procedure   DoInternalLog;
    procedure   DoSyncLog(ASender: TObject; const AMsg: String; AIsError: Boolean);
    function    GetIsRunning: Boolean;
  protected
    procedure   Execute; override;
  public
    constructor Create(ALogEvent: TLogEvent; AOnTerminate: TNotifyEvent); reintroduce;
    destructor  Destroy; override;

    procedure   Start;
    procedure   Stop;

    property    Core        : TBugFinderCore read FCore;

    property    ErrorStatus : Boolean        read FErrorStatus;
    property    IsRunning   : Boolean        read GetIsRunning;
  end;

implementation

uses
  Forms;

{ TDebugThread }

constructor TDebugThread.Create(ALogEvent: TLogEvent; AOnTerminate: TNotifyEvent);
var
  IniFileName : String;
  IniFilePath : String;
begin
  inherited Create(True);

  IniFileName := Trim(ParamStr(1));
  IniFilePath := ExtractFilePath(IniFileName);

  if (IniFilePath = '') then
    IniFileName := Format('.\%s', [IniFileName]);

  FCore          := TBugFinderCore.Create(IniFileName);
  FCore.LogEvent := DoSyncLog;

  FErrorStatus   := False;
  FLogEvent      := ALogEvent;

  OnTerminate    := AOnTerminate;
end;

destructor TDebugThread.Destroy;
begin
  FreeAndNil(FCore);

  inherited Destroy;
end;

procedure TDebugThread.DoInternalLog;
begin
  FLogEvent(Self, FMessage, FIsError);
end;

procedure TDebugThread.DoSyncLog(ASender: TObject; const AMsg: String; AIsError: Boolean);
begin
  FIsError := AIsError;
  FMessage := AMsg;

  Synchronize(DoInternalLog);
end;

procedure TDebugThread.Execute;
begin
  FErrorStatus := not FCore.Run;
end;

function TDebugThread.GetIsRunning: Boolean;
begin
  Result := not FCore.Stopped;
end;

procedure TDebugThread.Start;
begin
  Resume;
end;

procedure TDebugThread.Stop;
begin
  with FCore do begin
    Terminate;

    while not Stopped do
      Application.ProcessMessages;
  end;

  WaitFor;
end;


end.

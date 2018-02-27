unit uThreadsList;

interface

uses
  Classes,
  Contnrs,
  hStackWalk,
  SysUtils,
  Windows;

type
  TThreadItem = class(TObject)
  private
    FHandle : THandle;
    FId     : DWORD;
  public
    constructor Create(AId: DWORD; AHandle: THandle); reintroduce;
    destructor  Destroy; override;

    procedure   GetFrame(out AFrame: TStackFrame);

    property    Handle : THandle read FHandle;
    property    Id     : DWORD   read FId;
  end;

  TThreadsList = class(TObject)
  private
    FList : TObjectList;
  public
    constructor Create; reintroduce;
    destructor  Destroy; override;

    function    Add(AId: DWORD; AHandle: THandle): TThreadItem;
    function    Find(AID: DWORD): TThreadItem;
    function    GetFrame(AID: DWORD; out AFrame: TStackFrame; out AHandle: THandle): Boolean;
    function    Remove(AID: DWORD): Boolean;
  end;

implementation

{ TThreadItem }

constructor TThreadItem.Create(AId: DWORD; AHandle: THandle);
begin
  inherited Create;

  FHandle := AHandle;
  FId     := AId;
end;

destructor TThreadItem.Destroy;
begin
  {if (FHandle <> 0) then
    CloseHandle(FHandle);}

  inherited Destroy;
end;

procedure TThreadItem.GetFrame(out AFrame: TStackFrame);
var
  Context : TContext;
begin
  FillChar(AFrame,  SizeOf(TStackFrame), 0);
  FillChar(Context, SizeOf(TContext),    0);

  Context.ContextFlags := CONTEXT_FULL;
  GetThreadContext(FHandle, Context);

  with AFrame do begin
    AddrPC.Offset    := Context.Eip;
    AddrPC.Mode      := AddrModeFlat;
    AddrStack.Offset := Context.Esp;
    AddrStack.Mode   := AddrModeFlat;
    AddrFrame.Offset := Context.Ebp;
    AddrFrame.Mode   := AddrModeFlat;
  end;
end;

{ TThreadsList }

function TThreadsList.Add(AId: DWORD; AHandle: THandle): TThreadItem;
begin
  Result := Find(AID);
  if not Assigned(Result) then begin
    Result := TThreadItem.Create(AId, AHandle);
    FList.Add(Result);
  end;
end;

constructor TThreadsList.Create;
begin
  inherited Create;

  FList := TObjectList.Create(True);
end;

destructor TThreadsList.Destroy;
begin
  FreeAndNil(FList);

  inherited Destroy;
end;

function TThreadsList.Find(AID: DWORD): TThreadItem;
var
  I   : Integer;
  Thd : TThreadItem;
begin
  Result := nil;

  for I := 0 to (FList.Count - 1) do begin
    Thd := TThreadItem(FList[I]);
    if (Thd.Id = AID) then begin
      Result := Thd;
      Break;
    end;
  end;
end;

function TThreadsList.GetFrame(AID: DWORD; out AFrame: TStackFrame; out AHandle: THandle): Boolean;
var
  Thd : TThreadItem;
begin
  Thd    := Find(AID);
  Result := Assigned(Thd);

  if Result then begin
    AHandle := Thd.Handle;
    Thd.GetFrame(AFrame);
  end;
end;

function TThreadsList.Remove(AID: DWORD): Boolean;
var
  Thd : TThreadItem;
begin
  Thd    := Find(AID);
  Result := Assigned(Thd);

  if Result then
    FList.Remove(Thd);
end;

end.

unit uBreakpoints;

interface

uses
  Classes,
  Contnrs,
  Dialogs,
  hCore,
  hDebugUtils,
  hSymProvider,
  SysUtils,
  uDebugUtils,
  uModulesList,
  uSymProviders,
  uThreadsList,
  Windows;

type
  TBreakpoint = class(TObject)
  private
    FAddress  : DWORD;
    FByteData : Byte;
    FMethod   : String;
    FModule   : String;
    FName     : String;
    FProcess  : THandle;
    FUnitName : String;
    FThreads  : TThreadsList;
  public
    constructor Create(AThreadsList: TThreadsList; const AName, AModule, AUnit, AMethod: String; AAddress: DWORD); reintroduce;

    function    Activate(AProcess: THandle): Boolean;
    function    Resume(AThreadId: THandle): Boolean;

    property    Address  : DWORD  read FAddress;
    property    Method   : String read FMethod;
    property    Module   : String read FModule;
    property    Name     : String read FName;
    property    UnitName : String read FUnitName;

    property    ByteData : Byte   read FByteData;
  end;

  TBreakPoints = class(TObject)
  private
    FList    : TObjectList;
    FThreads : TThreadsList;
  public
    constructor Create(AThreadsList: TThreadsList); reintroduce;
    destructor  Destroy; override;

    function    Activate(ABP: TBreakpoint; AProcess: THandle): Boolean;
    function    Find(AAddress: DWORD): TBreakpoint;
    function    ValidateBP(const ASymProvider: ISymbolProvider; const AName, AModule, AUnit, AMethod: String; AModuleCodeBase: DWORD): TBreakpoint;
  end;

implementation

{ TBreakpoint }

function TBreakpoint.Activate(AProcess: THandle): Boolean;
begin
  FProcess := AProcess;
  Result   := ReadProcMem(FProcess, Pointer(FAddress), @FByteData, 1);
  Result   := Result and WriteProcMem(FProcess, Pointer(FAddress), @INT_3C, 1);
  Result   := Result and FlushInstructionCache(FProcess, Pointer(FAddress), 1);
end;

constructor TBreakpoint.Create(AThreadsList: TThreadsList; const AName, AModule, AUnit, AMethod: String; AAddress: DWORD);
begin
  inherited Create;

  FThreads  := AThreadsList;
  FName     := AName;
  FMethod   := AMethod;
  FModule   := AModule;
  FAddress  := AAddress;
  FUnitName := AUnit;
end;

function TBreakpoint.Resume(AThreadId: THandle): Boolean;
var
  Ctx    : TContext;
  Thread : TThreadItem;
begin
  { Locate thread }
  
  Thread := FThreads.Find(AThreadId);
  Result := Assigned(Thread);

  if Result then begin
    { Get thread context }

    FillChar(Ctx, SizeOf(TContext), 0);
    Ctx.ContextFlags := CONTEXT_FULL;
    Result           := GetThreadContext(Thread.Handle, Ctx);
    
    if Result then begin

      { Check BP address }

      Result := (Ctx.Eip = (FAddress + 1));
      if Result then begin

        { Rewrite original byte data }

        Result := WriteProcMem(FProcess, Pointer(FAddress), @FByteData, 1);
        Result := Result and FlushInstructionCache(FProcess, Pointer(FAddress), 1);

        if Result then begin

          { Set single step excecution thread context }

          Ctx.Eip    := FAddress;
          Ctx.EFlags := Ctx.EFlags or CTX_FLAGS_SINGLE_STEP;
          Result     := Result and SetThreadContext(Thread.Handle, Ctx);
        end;
      end;
    end;
  end;
end;

{ TBreakPoints }

function TBreakPoints.Activate(ABP: TBreakpoint; AProcess: THandle): Boolean;
begin
  Result := ABP.Activate(AProcess);
  if Result then
    FList.Add(ABP);
end;

constructor TBreakPoints.Create(AThreadsList: TThreadsList);
begin
  inherited Create;

  FList    := TObjectList.Create(True);
  FThreads := AThreadsList;
end;

destructor TBreakPoints.Destroy;
begin
  FreeAndNil(FList);

  inherited Destroy;
end;

function TBreakPoints.Find(AAddress: DWORD): TBreakpoint;
var
  BP : TBreakpoint;
  I  : Integer;
begin
  Result := nil;

  for I := 0 to (FList.Count - 1) do begin
    BP := TBreakpoint(FList[I]);
    if (BP.Address = AAddress) then begin
      Result := BP;
      Break;
    end;
  end;
end;

function TBreakPoints.ValidateBP(const ASymProvider: ISymbolProvider; const AName, AModule, AUnit, AMethod: String; AModuleCodeBase: DWORD): TBreakpoint;
var
  Address : DWORD;
begin
  if not Assigned(ASymProvider) then
    Address := 0
  else
    ASymProvider.QueryAddress(PChar(AUnit), PChar(AMethod), AModuleCodeBase, Address);

  if (Address <= 0) then
    Result := nil
  else
    Result  := TBreakpoint.Create(FThreads, AName, AModule, AUnit, AMethod, Address);
end;


end.

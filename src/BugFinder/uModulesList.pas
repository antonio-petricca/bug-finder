unit uModulesList;

interface

uses
  Contnrs,
  Classes,
  hCore,
  hCoreServices,
  hSymProvider,
  PsAPI,
  SysUtils,
  uDebugUtils,
  uSymProviders,
  Windows;

type
  TModuleItem = class(TObject)
  private
    FAddress     : DWORD;
    FCodeBase    : DWORD;
    FDebugAddr   : DWORD;
    FInfos       : TLoadDLLDebugInfo;
    FName        : String;
    FPath        : String;
    FProcessInfo : TProcessInformation;
    FRelocated   : Boolean;
    FSymProvider : ISymbolProvider;
    FWantedAddr  : DWORD;
  public
    constructor Create(
      const AServices : ICoreServices;
      ASymProviders   : TSymbolProviders;
      AProcessInfo    : PProcessInformation;
      AModule         : PLoadDLLDebugInfo
    ); reintroduce;

    destructor  Destroy; override;

    function    GetDebugInfos(ARawAddress, ARelativeAddress: DWORD): ISymbol;
    function    GetInfos(out AInfos: TModuleInfo): Boolean;

    property    Infos       : TLoadDLLDebugInfo read FInfos;
    property    SymProvider : ISymbolProvider   read FSymProvider;

    property    Name        : String            read FName;
    property    Path        : String            read FPath;

    property    Address     : DWORD             read FAddress;
    property    CodeBase    : DWORD             read FCodeBase;
    property    WantedAddr  : DWORD             read FWantedAddr;
    property    Relocated   : Boolean           read FRelocated;

    property    DebugAddr   : DWORD             read FDebugAddr;
  end;

  TModulesList = class(TObject)
  private
    FList         : TObjectList;
    FSymProviders : TSymbolProviders;
  public
    constructor Create(ASymProviders: TSymbolProviders); reintroduce;
    destructor  Destroy; override;

    function    Add(
      AProcessInfo    : PProcessInformation;
      AProcessData    : PCreateProcessDebugInfo;
      AModule         : PLoadDLLDebugInfo;
      const AServices : ICoreServices
    ): TModuleItem;

    function    Find(AModuleBaseAddress: Pointer): TModuleItem;
    procedure   Remove(AModule: PUnloadDLLDebugInfo); overload;
    procedure   Remove(AModule: TModuleItem); overload;

    function    GetDebugInfos(
      AProcessInfo    : PProcessInformation;
      ARawAddress     : DWORD;
      var ARelAddress : DWORD;
      out AModule     : TModuleItem;
      out ADebugInfos : ISymbol;
      out AModuleName : String
    ): Boolean;
  end;

implementation

{ TModuleItem }

constructor TModuleItem.Create(
  const AServices : ICoreServices;
  ASymProviders   : TSymbolProviders;
  AProcessInfo    : PProcessInformation;
  AModule         : PLoadDLLDebugInfo
);
begin
  inherited Create;

  FInfos       := AModule^;
  FProcessInfo := AProcessInfo^;
  FAddress     := DWORD(AModule^.lpBaseOfDll);
  FWantedAddr  := DWORD(GetPreferredLoadAddress(AProcessInfo^.hProcess, AModule^.lpBaseOfDll));
  FRelocated   := (FWantedAddr <> 0) and (FAddress <> FWantedAddr);

  GetModuleCodeBase(AProcessInfo^.hProcess, AModule^.lpBaseOfDll, FCodeBase);
  FDebugAddr   := FAddress + FCodeBase;

  FName        := GetProcessModuleName(AProcessInfo^.hProcess, AModule^.lpBaseOfDll);
  FPath        := GetProcessModuleFileName(AProcessInfo^.hProcess, AModule^.hFile);

  if (FPath = '') then begin
    FPath := GetProcessModuleFileNameEx(AProcessInfo^.dwProcessId, FName);
    if (FPath = '') then
      FPath := SearchModulePath(FName);
  end;

  FSymProvider := ASymProviders.QueryProvider(AServices, FPath, AModule);

  {

    Identifies a handle of the DLL. If this member is NULL, the handle is
    not valid. Otherwise, the member is opened for reading and read-sharing
    in the context of the debugger.

  }

  with AModule^ do
    if (hFile <> 0) then
      CloseHandle(hFile);
end;

destructor TModuleItem.Destroy;
begin
  FSymProvider := nil;

  inherited Destroy;
end;

function TModuleItem.GetDebugInfos(ARawAddress, ARelativeAddress: DWORD): ISymbol;
begin
  if Assigned(FSymProvider) then
    Result := FSymProvider.QuerySymbol(ARawAddress, ARelativeAddress)
  else
    Result := nil;
end;

function TModuleItem.GetInfos(out AInfos: TModuleInfo): Boolean;
begin
  Result := GetModuleInfos(FProcessInfo.hProcess, FProcessInfo.dwProcessId, FAddress, AInfos);
end;

{ TModulesList }

function TModulesList.Add(
  AProcessInfo    : PProcessInformation;
  AProcessData    : PCreateProcessDebugInfo;
  AModule         : PLoadDLLDebugInfo;
  const AServices : ICoreServices
): TModuleItem;
begin
  Assert(AModule <> nil);

  Result := TModuleItem.Create(AServices, FSymProviders, AProcessInfo, AModule);
  FList.Add(Result);
end;

constructor TModulesList.Create(ASymProviders: TSymbolProviders);
begin
  inherited Create;

  FList         := TObjectList.Create(True);
  FSymProviders := ASymProviders;
end;

destructor TModulesList.Destroy;
begin
  FreeAndNil(FList);

  inherited Destroy;
end;

function TModulesList.Find(AModuleBaseAddress: Pointer): TModuleItem;
var
  I      : Integer;
  Module : TModuleItem;
begin
  Result := nil;

  for I := 0 to (FList.Count - 1) do begin
    Module := TModuleItem(FList[I]);
    if (Module.Infos.lpBaseOfDll = AModuleBaseAddress) then begin
      Result := Module;
      Break;
    end;
  end;
end;

function TModulesList.GetDebugInfos(
  AProcessInfo    : PProcessInformation;
  ARawAddress     : DWORD;
  var ARelAddress : DWORD;
  out AModule     : TModuleItem;
  out ADebugInfos : ISymbol;
  out AModuleName : String
): Boolean;
var
  I          : Integer;
  ModInfos   : TModuleInfo;
  TmpAddress : DWORD;
  TmpModule  : TModuleItem;
begin
  Result      := False;
  AModule     := nil;
  ADebugInfos := nil;
  AModuleName := '';

  for I := 0 to (FList.Count - 1) do begin
    TmpModule := TModuleItem(FList[I]);

    if not TmpModule.GetInfos(ModInfos) then
      Continue;

    if (ARelAddress >= TmpModule.Address) and (ARelAddress <= (TmpModule.Address + ModInfos.SizeOfImage)) then begin
      TmpAddress  := ARelAddress - TmpModule.DebugAddr;
      AModule     := TmpModule;
      ADebugInfos := TmpModule.GetDebugInfos(ARawAddress, TmpAddress);
      ARelAddress := TmpAddress;
      AModuleName := TmpModule.Name;
      Result      := True;

      Break;
    end;
    
  end;
end;

procedure TModulesList.Remove(AModule: PUnloadDLLDebugInfo);
var
  Module : TModuleItem;
begin
  Assert(AModule <> nil);

  Module := Find(AModule^.lpBaseOfDll);
  if Assigned(Module) then
    FList.Remove(Module);
end;

procedure TModulesList.Remove(AModule: TModuleItem);
begin
  FList.Remove(AModule);
end;

end.

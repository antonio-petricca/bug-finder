unit uMapSP;

interface

uses
  hCoreServices,
  hSymProvider,
  SysUtils,
  uJclDebug,
  uSymProvider,
  Windows;

type
  TMapSPFactory = class(TSymProviderFactory)
  public
    
    function AcceptModule(
      const AServices   : ICoreServices;
      const AModuleName : String;
      AModuleData       : PLoadDLLDebugInfo;
      out AProvider     : ISymbolProvider
    ): Boolean; override;

  end;

  TMapSP = class(TSymProvider)
  private
    FMapFileName : String;
    FScanner     : TJclMapScannerEx;
  protected
    function    QuerySymbol(ARawAddress, ARelativeAddress: DWORD): ISymbol; override;
    function    QueryAddress(AUnitName, AProcName: PChar; ACodeBase: DWORD; out AAddress: DWORD): BOOL; override;
  public
    constructor Create(
      const AServices    : ICoreServices;
      const AModuleName  : String;
      const AMapFileName : String;
      AModuleData        : PLoadDLLDebugInfo
    ); reintroduce;

    destructor  Destroy; override;
  end;  

implementation

{ TMapSPFactory }

function TMapSPFactory.AcceptModule(
  const AServices   : ICoreServices;
  const AModuleName : String;
  AModuleData       : PLoadDLLDebugInfo;
  out AProvider     : ISymbolProvider
): Boolean;
var
  MapFileName : String;
begin
  MapFileName := ChangeFileExt(AModuleName, '.map');
  Result      := FileExists(MapFileName);

  if not Result then
    AProvider := nil
  else
    AProvider := TMapSP.Create(AServices, AModuleName, MapFileName, AModuleData);
end;

{ TMapSP }

constructor TMapSP.Create(
  const AServices    : ICoreServices;
  const AModuleName  : String;
  const AMapFileName : String;
  AModuleData        : PLoadDLLDebugInfo
);
begin
  inherited Create(AServices, AModuleName, AModuleData);

  FMapFileName := AMapFileName;
  FScanner     := TJclMapScannerEx.Create(FMapFileName);
end;

destructor TMapSP.Destroy;
begin
  FreeAndNil(FScanner);

  inherited Destroy;
end;

function TMapSP.QueryAddress(AUnitName, AProcName: PChar; ACodeBase: DWORD; out AAddress: DWORD): BOOL;
begin
  AAddress := FScanner.AddressFromProcName(AUnitName, AProcName);
  Result   := (AAddress > 0);
  if Result then
    AAddress := AAddress + GetModuleBase + ACodeBase;
end;

function TMapSP.QuerySymbol(ARawAddress, ARelativeAddress: DWORD): ISymbol;
var
  LnNo : DWORD;
begin
  LnNo := FScanner.LineNumberFromAddr(ARelativeAddress);

  if (LnNo <= 0) then
    Result := nil
  else
    Result := TSymbol.Create(
      FScanner.SourceNameFromAddr(ARelativeAddress),
      FScanner.ModuleNameFromAddr(ARelativeAddress),
      FScanner.ProcNameFromAddr(ARelativeAddress),
      ARelativeAddress,
      LnNo
    );
end;

begin
  RegisterFactory(TMapSPFactory);
end.

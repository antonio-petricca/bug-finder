unit uTD32SP;

interface

uses
  hCoreServices,
  hSymProvider,
  JclTD32,
  SysUtils,
  uJclTD32,
  uSymProvider,
  uTD32Utils,
  Windows;

type
  TTD32SPFactory = class(TSymProviderFactory)
  public
    
    function AcceptModule(
      const AServices   : ICoreServices;
      const AModuleName : String;
      AModuleData       : PLoadDLLDebugInfo;
      out AProvider     : ISymbolProvider
    ): Boolean; override;

  end;

  TTD32SP = class(TSymProvider)
  private
    FHandle    : THandle;
    FTd32Infos : TJclPeBorTD32ImageEx;
  protected
    function    QuerySymbol(ARawAddress, ARelativeAddress: DWORD): ISymbol; override;
    function    QueryAddress(AUnitName, AProcName: PChar; ACodeBase: DWORD; out AAddress: DWORD): BOOL; override;
  public
    constructor Create(
      const AServices   : ICoreServices;
      const AModuleName : String;
      AModuleData       : PLoadDLLDebugInfo;
      ATd32Infos        : TJclPeBorTD32ImageEx;
      AHandle           : THandle
    ); reintroduce;

    destructor  Destroy; override;
  end;  

implementation

{ TTD32SPFactory }

function TTD32SPFactory.AcceptModule(
  const AServices   : ICoreServices;
  const AModuleName : String;
  AModuleData       : PLoadDLLDebugInfo;
  out AProvider     : ISymbolProvider
): Boolean;
var
  Handle    : THandle;
  Td32Infos : TJclPeBorTD32ImageEx;
begin
  Td32Infos := GetTd32Infos(AModuleName, Handle);
  Result    := Assigned(Td32Infos);

  if not Result then
    AProvider := nil
  else
    AProvider := TTD32SP.Create(AServices, AModuleName, AModuleData, Td32Infos, Handle);
end;

{ TTD32SP }

constructor TTD32SP.Create(
  const AServices   : ICoreServices;
  const AModuleName : String;
  AModuleData       : PLoadDLLDebugInfo;
  ATd32Infos        : TJclPeBorTD32ImageEx;
  AHandle           : THandle
);
begin
  inherited Create(AServices, AModuleName, AModuleData);

  FHandle    := AHandle;
  FTd32Infos := ATd32Infos;
end;

destructor TTD32SP.Destroy;
begin
  FreeAndNil(FTd32Infos);
  FreeLibrary(FHandle);

  inherited Destroy;
end;

function TTD32SP.QueryAddress(AUnitName, AProcName: PChar; ACodeBase: DWORD; out AAddress: DWORD): BOOL;
begin
  AAddress := FTd32Infos.AddressFromProcName(AUnitName, AProcName);
  Result   := (AAddress > 0);
  if Result then
    AAddress := AAddress + GetModuleBase + ACodeBase;
end;

function TTD32SP.QuerySymbol(ARawAddress, ARelativeAddress: DWORD): ISymbol;
var
  nfoLnNo : DWORD;
  nfoMod  : String;
  nfoProc : String;
  nfoSrc  : String;
begin
  with FTd32Infos.TD32Scanner do begin
  
    nfoLnNo := LineNumberFromAddr(ARelativeAddress);
    nfoMod  := ModuleNameFromAddr(ARelativeAddress);
    nfoProc := ProcNameFromAddr(ARelativeAddress);
    nfoSrc  := SourceNameFromAddr(ARelativeAddress);

    if
      (nfoLnNo <= 0)  and
      (nfoMod  =  '') and
      (nfoProc =  '') and
      (nfoSrc  =  '') 
    then
      Result := nil
    else
      Result := TSymbol.Create(
        nfoSrc,
        nfoMod,
        nfoProc,
        ARelativeAddress,
        nfoLnNo
      );
    end;
end;

begin
  RegisterFactory(TTD32SPFactory);
end.

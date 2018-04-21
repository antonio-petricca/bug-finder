unit uSymProvider;

interface

uses
  hCoreServices,
  hSymProvider,
  SysUtils,
  Windows;

type
  TSymbol = class(TInterfacedObject, IUnknown, ISymbol)
  private
    FAddress    : DWORD;
    FLineNumber : DWORD;
    FModuleName : String;
    FProcName   : String;
    FSourceName : String;

    function    GetAddress: DWORD;
    function    GetModuleName: PChar;
    function    GetLineNumber: DWORD;
    function    GetProcName: PChar;
    function    GetSourceName: PChar;
  public
    constructor Create(const ASourceName, AModuleName, AProcName: String; AAddress, ALineNumber: DWORD); reintroduce; virtual;
  end;

  TSymProvider = class(TInterfacedObject, IUnknown, ISymbolProvider)
  protected
    FModuleData  : PLoadDLLDebugInfo;
    FModuleName  : String;
    FServices    : ICoreServices;

    function    GetModuleBase: DWORD;

    { ISymbolProvider}

    function    QuerySymbol(ARawAddress, ARelativeAddress: DWORD): ISymbol; virtual; abstract;
    function    QueryAddress(AUnitName, AProcName: PChar; ACodeBase: DWORD; out AAddress: DWORD): BOOL; virtual; abstract;
    function    QuerySymbolProps(AUnitName, AProcName: PChar; ACodeBase: DWORD; out AAddress, ASize, ADebugStart, ADebugEnd: DWORD): BOOL; virtual; abstract;

  public
    constructor Create(
      const AServices   : ICoreServices;
      const AModuleName : String;
      AModuleData       : PLoadDLLDebugInfo
    ); reintroduce; virtual;

    destructor Destroy; override;
  end;

  TSymProviderFactory = class(TObject)
  public
    constructor Create; reintroduce; virtual;

    function    AcceptModule(
      const AServices   : ICoreServices;
      const AModuleName : String;
      AModuleData       : PLoadDLLDebugInfo;
      out AProvider     : ISymbolProvider
    ): Boolean; virtual; abstract;
  end;

  TSymProviderFactoryClass = class of TSymProviderFactory;

procedure RegisterFactory(AFactory: TSymProviderFactoryClass);

implementation

var
  Factory : TSymProviderFactory = nil;

procedure RegisterFactory(AFactory: TSymProviderFactoryClass);
begin
  Factory := AFactory.Create;
end;

{ Main }

function GetSymbolProvider(
  const AServices : ICoreServices;
  AModuleName     : PChar;
  AModuleData     : PLoadDLLDebugInfo;
  out AProvider   : ISymbolProvider
): BOOL; stdcall;
begin
  Result := Assigned(Factory);

  Result := Result and Factory.AcceptModule(
    AServices,
    StrPas(AModuleName),
    AModuleData,
    AProvider
  );
end;

exports
  GetSymbolProvider;

{ TSymProvider }

constructor TSymProvider.Create(
  const AServices   : ICoreServices;
  const AModuleName : String;
  AModuleData       : PLoadDLLDebugInfo
);
begin
  inherited Create;

  FModuleData  := AModuleData;
  FModuleName  := AModuleName;
  FServices    := AServices;
end;

destructor TSymProvider.Destroy;
begin
  FServices := nil;

  inherited Destroy;
end;

function TSymProvider.GetModuleBase: DWORD;
begin
  if not Assigned(FModuleData) then
    Result := DWORD(FServices.ProcessDebugInfo^.lpBaseOfImage)
  else
    Result := DWORD(FModuleData^.lpBaseOfDll);
end;

{ TSymProviderFactory }

constructor TSymProviderFactory.Create;
begin
  inherited Create;
end;

{ TSymbol }

constructor TSymbol.Create(const ASourceName, AModuleName, AProcName: String; AAddress, ALineNumber: DWORD);
begin
  inherited Create;

  FAddress    := AAddress;
  FLineNumber := ALineNumber;
  FLineNumber := ALineNumber;
  FModuleName := AModuleName;
  FProcName   := AProcName;
  FSourceName := ASourceName;
end;

function TSymbol.GetAddress: DWORD;
begin
  Result := FAddress;
end;

function TSymbol.GetLineNumber: DWORD;
begin
  Result := FLineNumber;
end;

function TSymbol.GetModuleName: PChar;
begin
  Result := PChar(FModuleName);
end;

function TSymbol.GetProcName: PChar;
begin
  Result := PChar(FProcName);
end;

function TSymbol.GetSourceName: PChar;
begin
  Result := PChar(FSourceName);
end;

initialization
finalization

  if Assigned(Factory) then
    FreeAndNil(Factory);

end.

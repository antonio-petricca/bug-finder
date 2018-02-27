unit uSymProviders;

interface

uses
  Contnrs,
  hCoreServices,
  hSymProvider,
  Sysutils,
  Windows;

type
  TSymbolProviderItem = class(TObject)
  private
    FFactory  : TGetSymbolProviderFunc;
    FFileName : String;
    FHandle   : THandle;
    FName     : String;
  public
    constructor Create(AHandle: THandle; const AName, AFileName: String; AFactory: TGetSymbolProviderFunc); reintroduce;
    destructor  Destroy; override;

    property    Factory  : TGetSymbolProviderFunc read FFactory;
    property    FileName : String                 read FFileName;
    property    Handle   : THandle                read FHandle;
    property    Name     : String                 read FName;
  end;

  TSymbolProviders = class(TObject)
  private
    FList : TObjectList;

    function    GetFactory(const ADllName: String; out AHandle: THandle; out AFactory: TGetSymbolProviderFunc): Boolean;
  public
    constructor Create; reintroduce;
    destructor  Destroy; override;

    function    Add(const AName, ADllName: String): Boolean;
    
    function    QueryProvider(
      const AServices : ICoreServices;
      const ADllName  : String;
      AModuleData     : PLoadDLLDebugInfo
    ): ISymbolProvider;
  end;

implementation

{ TSymbolProviderItem }

constructor TSymbolProviderItem.Create(AHandle: THandle; const AName, AFileName: String; AFactory: TGetSymbolProviderFunc);
begin
  inherited Create;

  FFactory  := AFactory;
  FFileName := AFileName;
  FHandle   := AHandle;
  FName     := AName;
end;

destructor TSymbolProviderItem.Destroy;
begin
  FreeLibrary(FHandle);

  inherited Destroy;
end;

{ TSymbolProviders }

function TSymbolProviders.Add(const AName, ADllName: String): Boolean;
var
  Factory : TGetSymbolProviderFunc;
  Handle  : THandle;
begin
  Result := GetFactory(ADllName, Handle, Factory);
  if Result then
    FList.Add(TSymbolProviderItem.Create(Handle, AName, ADllName, Factory));
end;

constructor TSymbolProviders.Create;
begin
  inherited Create;

  FList := TObjectList.Create(True);
end;

destructor TSymbolProviders.Destroy;
begin
  FreeAndNil(FList);

  inherited Destroy;
end;

function TSymbolProviders.GetFactory(const ADllName: String; out AHandle: THandle; out AFactory: TGetSymbolProviderFunc): Boolean;
begin
  AFactory := nil;
  AHandle  := LoadLibrary(PChar(ADllName));
  Result   := (AHandle > 0);

  if Result then begin
    AFactory := TGetSymbolProviderFunc(GetProcAddress(AHandle, PChar('GetSymbolProvider')));
    Result   := Assigned(AFactory);

    if not Result then begin
      FreeLibrary(AHandle);
      AHandle := 0;
    end;
  end;
end;

function TSymbolProviders.QueryProvider(
  const AServices : ICoreServices;
  const ADllName  : String;
  AModuleData     : PLoadDLLDebugInfo
): ISymbolProvider;
var
  I        : Integer;
  Provider : TSymbolProviderItem;
  TmpProv  : ISymbolProvider;
begin
  Result := nil;

  for I := 0 to (FList.Count - 1) do begin
    Provider := TSymbolProviderItem(FList[I]);

    if Provider.Factory(AServices, PChar(ADllName), AModuleData, TmpProv) then begin
      Result := TmpProv;
      Break;
    end;
  end;
end;

end.

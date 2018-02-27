unit uExcProviders;

interface

uses
  Contnrs,
  hCoreServices,
  hExcProvider,
  Sysutils,
  Windows;


type
  TExceptionProviderItem = class(TObject)
  private
    FFactory  : TGetExceptionProviderFunc;
    FFileName : String;
    FHandle   : THandle;
    FName     : String;
  public
    constructor Create(AHandle: THandle; const AName, AFileName: String; AFactory: TGetExceptionProviderFunc); reintroduce;
    destructor  Destroy; override;

    property    Factory  : TGetExceptionProviderFunc read FFactory;
    property    FileName : String                    read FFileName;
    property    Handle   : THandle                   read FHandle;
    property    Name     : String                    read FName;
  end;
  
  TExceptionProviders = class(TObject)
  private
    FList : TObjectList;

    function    GetFactory(const ADllName: String; out AHandle: THandle; out AFactory: TGetExceptionProviderFunc): Boolean;
  public
    constructor Create; reintroduce;
    destructor  Destroy; override;

    function    Add(const AName, ADllName: String): Boolean;
    function    QueryProvider(const AServices: ICoreServices; AException: PExceptionRecord): IExceptionProvider;
  end;

implementation

{ TExceptionProviderItem }

constructor TExceptionProviderItem.Create(AHandle: THandle; const AName, AFileName: String; AFactory: TGetExceptionProviderFunc);
begin
  inherited Create;

  FFactory  := AFactory;
  FFileName := AFileName;
  FHandle   := AHandle;
  FName     := AName;
end;

destructor TExceptionProviderItem.Destroy;
begin
  FreeLibrary(FHandle);

  inherited Destroy;
end;

{ TExceptionProviders }

function TExceptionProviders.Add(const AName, ADllName: String): Boolean;
var
  Factory : TGetExceptionProviderFunc;
  Handle  : THandle;
begin
  Result := GetFactory(ADllName, Handle, Factory);
  if Result then
    FList.Add(TExceptionProviderItem.Create(Handle, AName, ADllName, Factory));
end;

constructor TExceptionProviders.Create;
begin
  inherited Create;

  FList := TObjectList.Create(True);
end;

destructor TExceptionProviders.Destroy;
begin
  FreeAndNil(FList);

  inherited Destroy;
end;

function TExceptionProviders.GetFactory(const ADllName: String; out AHandle: THandle; out AFactory: TGetExceptionProviderFunc): Boolean;
begin
  AFactory := nil;
  AHandle  := LoadLibrary(PChar(ADllName));
  Result   := (AHandle > 0);

  if Result then begin
    AFactory := TGetExceptionProviderFunc(GetProcAddress(AHandle, 'GetExceptionProvider'));
    Result   := Assigned(AFactory);

    if not Result then begin
      FreeLibrary(AHandle);
      AHandle := 0;
    end;
  end;
end;

function TExceptionProviders.QueryProvider(const AServices: ICoreServices; AException: PExceptionRecord): IExceptionProvider;
var
  I        : Integer;
  Provider : TExceptionProviderItem;
  TmpProv  : IExceptionProvider;
begin
  Result := nil;

  for I := 0 to (FList.Count - 1) do begin
    Provider := TExceptionProviderItem(FList[I]);

    if Provider.Factory(AServices, AException, TmpProv) then begin
      Result := TmpProv;
      Break;
    end;
  end;
end;

end.

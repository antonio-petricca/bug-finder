unit uExcProvider;

interface

uses
  hCoreServices,
  hExcProvider,
  SysUtils,
  Windows;

type
  TExcProvider = class(TInterfacedObject, IUnknown, IExceptionProvider)
  protected
    FServices : ICoreServices;

    { IExceptionProvider}

    function    GetDescription: PChar; virtual; abstract;
    function    HandleException(AException: PExceptionRecord): BOOL; virtual; abstract;
    function    TranslateExceptionAddress(AException: PExceptionRecord): DWORD; virtual; abstract;

  public
    constructor Create(const AServices: ICoreServices); reintroduce; virtual;
    destructor  Destroy; override;
  end;

  TExcProviderFactory = class(TObject)
  public
    constructor Create; reintroduce; virtual;

    function    AcceptException(const AServices: ICoreServices; AException: PExceptionRecord; out AProvider: IExceptionProvider): Boolean; virtual; abstract;
  end;

  TExcProviderFactoryClass = class of TExcProviderFactory;

procedure RegisterFactory(AFactory: TExcProviderFactoryClass);  

implementation

var
  Factory : TExcProviderFactory = nil;

procedure RegisterFactory(AFactory: TExcProviderFactoryClass);
begin
  Factory := AFactory.Create;
end;

{ Main }

function GetExceptionProvider(const AServices: ICoreServices; AException: PExceptionRecord; out AProvider: IExceptionProvider): BOOL; stdcall;
begin
  Result := Assigned(Factory);
  Result := Result and Factory.AcceptException(AServices, AException, AProvider);
end;

exports
  GetExceptionProvider;

{ TExcProvider }

constructor TExcProvider.Create(const AServices: ICoreServices);
begin
  inherited Create;

  FServices := AServices;
end;

destructor TExcProvider.Destroy;
begin
  FServices := nil;

  inherited Destroy;
end;

{ TExcProviderFactory }

constructor TExcProviderFactory.Create;
begin
  inherited Create;
end;

initialization
finalization

  if Assigned(Factory) then
    FreeAndNil(Factory);
    
end.

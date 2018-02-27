unit uClrEP;

interface

uses
  hCoreServices,
  hClrEP,
  hExcProvider,
  SysUtils,
  uExcProvider,
  uDebugUtils,
  Windows;

type
  TClrEPFactory = class(TExcProviderFactory)
  public
    function AcceptException(const AServices: ICoreServices; AException: PExceptionRecord; out AProvider: IExceptionProvider): Boolean; override; 
  end;

  TClrEP = class(TExcProvider)
  protected
    function GetDescription: PChar; override;
    function HandleException(AException: PExceptionRecord): BOOL; override;
    function TranslateExceptionAddress(AException: PExceptionRecord): DWORD; override;
  end;

implementation

{ TClrEPFactory }

function TClrEPFactory.AcceptException(const AServices: ICoreServices; AException: PExceptionRecord; out AProvider: IExceptionProvider): Boolean;
begin
  Result := Assigned(AException) and (AException^.ExceptionCode = EXCEPTION_CLR);

  if Result then
    AProvider := TClrEP.Create(AServices)
  else
    AProvider := nil;
end;

{ TClrEP }

function TClrEP.GetDescription: PChar;
begin
  Result := EXCEPTION_DESCRIPTION;
end;

function TClrEP.HandleException(AException: PExceptionRecord): BOOL;
begin
  Result := False;
end;

function TClrEP.TranslateExceptionAddress(AException: PExceptionRecord): DWORD;
begin
  Result := 0;
end;

begin
  RegisterFactory(TClrEPFactory);
end.

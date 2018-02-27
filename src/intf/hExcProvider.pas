unit hExcProvider;

interface

uses
  hCoreServices,
  Windows;

type
  IExceptionProvider = interface(IUnknown)

    function GetDescription: PChar;
    function HandleException(AException: PExceptionRecord): BOOL;
    function TranslateExceptionAddress(AException: PExceptionRecord): DWORD;

  end;

  TGetExceptionProviderFunc = function(const AServices: ICoreServices; AException: PExceptionRecord; out AProvider: IExceptionProvider): BOOL; stdcall;  

implementation

end.

unit hSymProvider;

interface

uses
  hCoreServices,
  Windows;

type
  ISymbol = interface(IUnknown)
    function GetAddress: DWORD;
    function GetModuleName: PChar;
    function GetLineNumber: DWORD;
    function GetProcName: PChar;
    function GetSourceName: PChar;

    property Address    : DWORD read GetAddress;
    property LineNumber : DWORD read GetLineNumber;
    property ModuleName : PChar read GetModuleName;
    property ProcName   : PChar read GetProcName;
    property SourceName : PChar read GetSourceName;
  end;

  ISymbolProvider = interface(IUnknown)
    function QueryAddress(AUnitName, AProcName: PChar; ACodeBase: DWORD; out AAddress: DWORD): BOOL;
    function QuerySymbol(ARawAddress, ARelativeAddress: DWORD): ISymbol; 
    function QuerySymbolProps(AUnitName, AProcName: PChar; ACodeBase: DWORD; out AAddress, ASize, ADebugStart, ADebugEnd: DWORD): BOOL;
  end;

  TGetSymbolProviderFunc = function(
    const AServices : ICoreServices;
    AModuleName     : PChar;
    AModuleData     : PLoadDLLDebugInfo;
    out AProvider   : ISymbolProvider
  ): BOOL; stdcall;

implementation

end.


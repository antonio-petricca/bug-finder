unit uCoffHelpers;

interface

uses
  hCoffHelpers,
  Windows;

function  hlpInitialize(AProcess, AFile: THandle; const AModuleName: String; ABaseAddress: DWORD): Boolean;
procedure hlpFinalize(AProcess: THandle; ABaseAddress: DWORD);

function  SymGetSymFromAddr(hProcess: THandle; dwAddr: DWORD; pdwDisplacement: PDWORD; Symbol: PIMAGEHLP_SYMBOL): BOOL; stdcall;
function  SymGetSymFromName(hProcess: THandle; Name: LPSTR; Symbol: PIMAGEHLP_SYMBOL): BOOL; stdcall;
function  SymGetLineFromAddr(hProcess: THandle; dwAddr: DWORD; pdwDisplacement: PDWORD; Line: PIMAGEHLP_LINE): BOOL; stdcall;

implementation

const
  DLL_NAME = 'DbgHelp.dll';

function SymInitialize(hProcess: THandle; UserSearchPath: LPSTR; fInvadeProcess: BOOL): BOOL; stdcall;                               external DLL_NAME;
function SymSetOptions(SymOptions: DWORD): DWORD; stdcall;                                                                           external DLL_NAME;
function SymLoadModule(hProcess: THandle; hFile: THandle; ImageName, ModuleName: LPSTR; BaseOfDll, SizeOfDll: DWORD): BOOL; stdcall; external DLL_NAME;
function SymUnloadModule(hProcess: THandle; BaseOfDll: DWORD): BOOL; stdcall;                                                        external DLL_NAME;
function SymCleanup(hProcess: THandle): BOOL; stdcall;                                                                               external DLL_NAME;
function SymGetSymFromAddr(hProcess: THandle; dwAddr: DWORD; pdwDisplacement: PDWORD; Symbol: PIMAGEHLP_SYMBOL): BOOL; stdcall;      external DLL_NAME;
function SymGetSymFromName(hProcess: THandle; Name: LPSTR; Symbol: PIMAGEHLP_SYMBOL): BOOL; stdcall;                                 external DLL_NAME;
function SymGetLineFromAddr(hProcess: THandle; dwAddr: DWORD; pdwDisplacement: PDWORD; Line: PIMAGEHLP_LINE): BOOL; stdcall;         external DLL_NAME;

function hlpInitialize(AProcess, AFile: THandle; const AModuleName: String; ABaseAddress: DWORD): Boolean;
begin                     
  SymSetOptions(SYMOPT_UNDNAME or SYMOPT_DEFERRED_LOADS or SYMOPT_LOAD_LINES);
  Result := SymInitialize(AProcess, nil, False);
  Result := Result and SymLoadModule(AProcess, 0, PAnsiChar(AModuleName), nil, ABaseAddress, 0);
end;

procedure hlpFinalize(AProcess: THandle; ABaseAddress: DWORD);
begin
  SymUnloadModule(AProcess, ABaseAddress);
  SymCleanup(AProcess);
end;

end.

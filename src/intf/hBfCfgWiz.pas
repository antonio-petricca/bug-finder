unit hBfCfgWiz;

interface

uses
  Windows;

{ RunDll invocation standard interface! }   

procedure Configure(hWnd: HWND; hInst: HINST; lpszCmdLine: LPSTR; nCmdShow: Integer); stdcall;

implementation

procedure Configure(hWnd: HWND; hInst: HINST; lpszCmdLine: LPSTR; nCmdShow: Integer); stdcall; external 'BfCfgWiz.dll';

end.

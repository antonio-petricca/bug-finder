// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
// JCL_DEBUG_EXPERT_INSERTJDBG OFF

library BfCfgWiz;

uses
  Forms,
  SysUtils,
  Windows,
  ufmBfCfgWiz in 'ufmBfCfgWiz.pas' {fmBfCfgWiz},
  hCore in '..\BugFinder\hCore.pas',
  uLogRotator in '..\..\libs\common\uLogRotator.pas',
  uLog in '..\..\libs\common\uLog.pas',
  uUtils in '..\..\libs\common\uUtils.pas',
  hUtils in '..\..\libs\common\hUtils.pas';

{$R *.RES}

procedure Configure(hWnd: HWND; hInst: HINST; lpszCmdLine: LPSTR; nCmdShow: Integer); stdcall;
begin
  with TfmBfCfgWiz.Create(nil) do begin
    SetFileName(StrPas(lpszCmdLine));
    ShowModal;
    Free;
  end;
end;

exports
  Configure;

begin
end.

// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
// JCL_DEBUG_EXPERT_INSERTJDBG OFF

program BugFinder;

{$R *.RES}

uses
  Forms,
  SysUtils,
  uCore in 'uCore.pas',
  uModulesList in 'uModulesList.pas',
  hCore in 'hCore.pas',
  ufmBugFinder in 'ufmBugFinder.pas' {fmBugFinder},
  uBreakpoints in 'uBreakpoints.pas',
  uThreadsList in 'uThreadsList.pas',
  hSymProvider in '..\intf\hSymProvider.pas',
  uSymProviders in 'uSymProviders.pas',
  hCoreServices in '..\intf\hCoreServices.pas',
  hExcProvider in '..\intf\hExcProvider.pas',
  uExcProviders in 'uExcProviders.pas',
  uUtils in '..\..\libs\common\uUtils.pas',
  hUtils in '..\..\libs\common\hUtils.pas',
  uLog in '..\..\libs\common\uLog.pas',
  uLogRotator in '..\..\libs\common\uLogRotator.pas',
  hBfCfgWiz in '..\intf\hBfCfgWiz.pas',
  hStackWalk in 'hStackWalk.pas',
  hDebugUtils in '..\..\libs\common\hDebugUtils.pas',
  uDebugUtils in '..\..\libs\common\uDebugUtils.pas';

begin
  Application.Initialize;
  Application.CreateForm(TfmBugFinder, fmBugFinder);
  if fmBugFinder.WellStarted then
    Application.Run
  else
    FreeAndNil(fmBugFinder);
end.


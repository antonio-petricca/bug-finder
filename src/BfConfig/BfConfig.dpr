// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
// JCL_DEBUG_EXPERT_INSERTJDBG OFF

program BfConfig;

uses
  Forms,
  Windows,
  hBfCfgWiz in '..\intf\hBfCfgWiz.pas';

{$R *.RES}

begin
  Application.Initialize;
  Configure(0, 0, PChar(ParamStr(1)), 0);
end.

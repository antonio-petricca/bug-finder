// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
// JCL_DEBUG_EXPERT_INSERTJDBG OFF

program FaultingApp;

uses
  Forms,
  ufmFault in 'ufmFault.pas' {fmFault};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TfmFault, fmFault);
  Application.Run;
end.

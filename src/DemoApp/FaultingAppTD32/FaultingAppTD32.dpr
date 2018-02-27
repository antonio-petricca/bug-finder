// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
// JCL_DEBUG_EXPERT_INSERTJDBG OFF

library FaultingAppTD32;

uses
  Windows;

{$R *.RES}

procedure RaiseExceptionFromTD32Dll; stdcall;
begin
  PInteger(nil)^ := 0;
end;

exports
  RaiseExceptionFromTD32Dll;

begin
end.

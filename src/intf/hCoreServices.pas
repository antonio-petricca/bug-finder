unit hCoreServices;

interface

uses
  Windows;

type
  ICoreServices = interface(IUnknown)

     function  GetProcess: THandle;
     function  GetProcessDebugInfo: PCreateProcessDebugInfo;
     function  GetProcessInfo: PProcessInformation;
     
     procedure LogMessage(AMsg: PChar; AIsError: BOOL);

     property  Process          : THandle                 read GetProcess;
     property  ProcessDebugInfo : PCreateProcessDebugInfo read GetProcessDebugInfo;
     property  ProcessInfo      : PProcessInformation     read GetProcessInfo;
  end;  

implementation

end.

unit hCore;

interface

uses
  uLogRotator;

const
  { Configuration sections }

  SEC_BRKPTS = 'Breakpoints';
  SEC_EXCPRV = 'ExceptionProviders';
  SEC_CONFIG = 'Configuration';
  SEC_LOG    = 'Logging';
  SEC_SYMPRV = 'SymbolProviders';

  { Configuration values }

  CFG_VAL_APPFILENAME                     = 'AppFileName';
  CFG_VAL_APPPARAMETERS                   = 'AppParameters';

  CFG_VAL_LOGFILENAME                     = 'LogFileName';
  CFG_VAL_LOGFILEROTATION                 = 'LogFileRotation';
  CFG_VAL_LOGVIEWLINESLIMIT               = 'LogViewLinesLimit';
  CFG_VAL_POPUPONERRORS                   = 'PopUpOnErrors';
  CFG_VAL_SPOOLTOFILE                     = 'SpoolToFile';
  CFG_VAL_STACKDEPTH                      = 'StackDepth';

  CFG_VAL_SUPPRESSBREAKPOINTSOURCEDETAILS = 'SuppressBreakpointSourceDetails';
  CFG_VAL_SUPPRESSDLLEVENTS               = 'SuppressDllEvents';
  CFG_VAL_SUPPRESSOUTPUTDEBUGSTRINGEVENTS = 'SuppressOutputDebugStringEvents';
  CFG_VAL_SUPPRESSPROCESSEVENTS           = 'SuppressProcessEvents';
  CFG_VAL_SUPPRESSTHREADEVENTS            = 'SuppressThreadEvents';

  { Default logging configuration values }

  DEF_VAL_LOGFILEROTATION                 = Integer(tlrDaily);
  DEF_VAL_LOGVIEWLINESLIMIT               = 1000;
  DEF_VAL_STACKDEPTH                      = 3;

type
  { Misc types }

  TCoreConfiguration = record
    { Configuration }

    AppFileName                     : String;
    AppParameters                   : String;

    { Logging }

    LogFileName                     : String;
    LogFileRotation                 : TTimeLogRotation; { Daily = 0, Weekly = 1, Monthly = 2 }
    LogViewLinesLimit               : Integer;
    PopUpOnErrors                   : Boolean;
    SpoolToFile                     : Boolean;
    StackDepth                      : Integer;

    SuppressBreakpointSourceDetails : Boolean;
    SuppressDllEvents               : Boolean;
    SuppressOutputDebugStringEvents : Boolean;
    SuppressProcessEvents           : Boolean;
    SuppressThreadEvents            : Boolean;
  end;

  TLogEvent = procedure(ASender: TObject; const AMsg: String; AIsError: Boolean) of object;

implementation

end.

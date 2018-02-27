unit hDelphiEP;

interface

const
  cDelphiException      = $0EEDFADE;
  EXCEPTION_DESCRIPTION = 'Delphi Exception';

  { VMT offsets }

  VMT_CLASSNAME_D3  = -32;
  VMT_CLASSNAME_Dx  = vmtClassName;  { -44 }

type
  { ExceptionRecord as defined into System.pas }

  PSysExceptionRecord = ^TSysExceptionRecord;
  TSysExceptionRecord = record
    ExceptionCode    : LongWord;
    ExceptionFlags   : LongWord;
    OuterException   : PSysExceptionRecord;
    ExceptionAddress : Pointer;
    NumberParameters : Longint;

    case {IsOsException:} Boolean of
      True : (ExceptionInformation : array [0..14] of Longint);
      False: (ExceptAddr           : Pointer; ExceptObject: Pointer);
  end;  

implementation

end.

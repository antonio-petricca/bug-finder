unit hStackWalk;

interface

uses
  Windows;

{$Z4} // minimum storage size of enumerated types  

type
  ADDRESS_MODE = (
    AddrMode1616,
    AddrMode1632,
    AddrModeReal,
    AddrModeFlat
  );
  
  TAddressMode = ADDRESS_MODE;
  
  PAddress    = ^TAddress;
  _tagADDRESS = record { Not packed to fit 12 bytes size!!! } 
    Offset   : DWORD;
    Segment  : Word;
    Mode     : TAddressMode;
  end;

  ADDRESS  = _tagADDRESS;
  TAddress = _tagADDRESS;

  PKdHelp  = ^TKdHelp;
  _KDHELP  = packed record
    Thread                    : DWORD;
    ThCallbackStack           : DWORD;
    NextCallback              : DWORD;
    FramePointer              : DWORD;
    KiCallUserMode            : DWORD;
    KeUserCallbackDispatcher  : DWORD;
    SystemRangeStart          : DWORD;
    ThCallbackBStore          : DWORD;
    KiUserExceptionDispatcher : DWORD;
    StackBase                 : DWORD;
    StackLimit                : DWORD;
    Reserved                  : array[0 .. 4] of DWORD;
  end;

  KDHELP = _KDHELP;
  TKdHelp = _KDHELP;
  
  PStackFrame    = ^TStackFrame;
  _tagSTACKFRAME = packed record
    AddrPC         : TAddress;                      { program counter }
    AddrReturn     : TAddress;                      { return address }
    AddrFrame      : TAddress;                      { frame pointer }
    AddrStack      : TAddress;                      { stack pointer }
    FuncTableEntry : Pointer;                       { pointer to pdata/fpo or NULL }
    Params         : packed array[0 .. 3] of DWORD; { possible arguments to the function }
    _Far           : Bool;                          { WOW far call }
    _Virtual       : Bool;                          { is this a virtual frame? }
    Reserved       : packed array[0 .. 2] of DWORD; { used internally by StackWalk api }
    KdHelp         : TKdHelp;
    AddrBStore     : TAddress;                      { backing store pointer }
  end;

  STACKFRAME  = _tagSTACKFRAME;
  TStackFrame = _tagSTACKFRAME;  

function StackWalk(
  MachineType                : DWORD;
  hProcess, hThread          : THandle;
  StackFrame                 : PStackFrame;
  ContextRecord              : Pointer;
  ReadMemoryRoutine          : Pointer;
  FunctionTableAccessRoutine : Pointer;
  GetModuleBaseRoutine       : Pointer;
  TranslateAddress           : Pointer
): Bool; stdcall;

function SymFunctionTableAccess(hProcess: THandle; AddrBase: DWORD): Pointer; stdcall;
function SymGetModuleBase(hProcess: THandle; dwAddr: DWORD): DWORD; stdcall;

implementation

const
  DLL_NAME = 'DbgHelp.dll';

function StackWalk(
  MachineType                : DWORD;
  hProcess, hThread          : THandle;
  StackFrame                 : PStackFrame;
  ContextRecord              : Pointer;
  ReadMemoryRoutine          : Pointer;
  FunctionTableAccessRoutine : Pointer;
  GetModuleBaseRoutine       : Pointer;
  TranslateAddress           : Pointer
): Bool; stdcall; external DLL_NAME;

function SymFunctionTableAccess(hProcess: THandle; AddrBase: DWORD): Pointer; stdcall; external DLL_NAME;
function SymGetModuleBase(hProcess: THandle; dwAddr: DWORD): DWORD; stdcall;           external DLL_NAME;

end.

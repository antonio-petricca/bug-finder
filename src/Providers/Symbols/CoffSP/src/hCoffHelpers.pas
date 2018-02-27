unit hCoffHelpers;

interface

uses
  Windows;

const
  MAX_SYM_NAME                  =     $1000;

  SYMOPT_CASE_INSENSITIVE       = $00000001;
  SYMOPT_UNDNAME                = $00000002;
  SYMOPT_DEFERRED_LOADS         = $00000004;
  SYMOPT_NO_CPP                 = $00000008;
  SYMOPT_LOAD_LINES             = $00000010;
  SYMOPT_OMAP_FIND_NEAREST      = $00000020;
  SYMOPT_LOAD_ANYTHING          = $00000040;
  SYMOPT_IGNORE_CVREC           = $00000080;
  SYMOPT_NO_UNQUALIFIED_LOADS   = $00000100;
  SYMOPT_FAIL_CRITICAL_ERRORS   = $00000200;
  SYMOPT_EXACT_SYMBOLS          = $00000400;
  SYMOPT_ALLOW_ABSOLUTE_SYMBOLS = $00000800;
  SYMOPT_IGNORE_NT_SYMPATH      = $00001000;
  SYMOPT_INCLUDE_32BIT_MODULES  = $00002000;
  SYMOPT_PUBLICS_ONLY           = $00004000;
  SYMOPT_NO_PUBLICS             = $00008000;
  SYMOPT_AUTO_PUBLICS           = $00010000;
  SYMOPT_NO_IMAGE_SEARCH        = $00020000;
  SYMOPT_SECURE                 = $00040000;

type
  _IMAGEHLP_SYMBOL = packed record
    SizeOfStruct  : DWORD;                                { set to sizeof(IMAGEHLP_SYMBOL) }
    Address       : DWORD;                                { virtual address including dll base address }
    Size          : DWORD;                                { estimated size of symbol, can be zero }
    Flags         : DWORD;                                { info about the symbols, see the SYMF defines }
    MaxNameLength : DWORD;                                { maximum size of symbol name in 'Name' }
    Name          : packed array[0 .. 0] of Char;           { symbol name (null terminated string) }
  end;

  IMAGEHLP_SYMBOL  = _IMAGEHLP_SYMBOL;
  PIMAGEHLP_SYMBOL = ^IMAGEHLP_SYMBOL;

  _IMAGEHLP_LINE = packed record
    SizeOfStruct : DWORD;                                 { set to sizeof(IMAGEHLP_LINE) }
    Key          : Pointer;                               { internal }
    LineNumber   : DWORD;                                 { line number in file }
    FileName     : PChar;                                 { full filename }
    Address      : DWORD;                                 { first instruction of line }
  end;

  IMAGEHLP_LINE  = _IMAGEHLP_LINE;
  PIMAGEHLP_LINE = ^IMAGEHLP_LINE;

implementation

end.

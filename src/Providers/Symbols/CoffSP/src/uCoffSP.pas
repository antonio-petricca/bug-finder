unit uCoffSP;

interface

uses
  hCoffHelpers,
  hCoreServices,
  hSymProvider,
  SysUtils,
  uCoffHelpers,
  uSymProvider,
  Windows;

type
  TCoffSPFactory = class(TSymProviderFactory)
  public
    
    function AcceptModule(
      const AServices   : ICoreServices;
      const AModuleName : String;
      AModuleData       : PLoadDLLDebugInfo;
      out AProvider     : ISymbolProvider
    ): Boolean; override;

  end;

  TCoffSP = class(TSymProvider)
  private
    function    ExtractModuleName(const ASourceFileName: String): String;
  protected
    function    QuerySymbol(ARawAddress, ARelativeAddress: DWORD): ISymbol; override;
    function    QueryAddress(AUnitName, AProcName: PChar; ACodeBase: DWORD; out AAddress: DWORD): BOOL; override;
  end;

implementation

{ TCoffSPFactory }

function TCoffSPFactory.AcceptModule(
  const AServices   : ICoreServices;
  const AModuleName : String;
  AModuleData       : PLoadDLLDebugInfo;
  out AProvider     : ISymbolProvider
): Boolean;

var
  BaseAddr : DWORD;
  hFile    : THandle;

begin
  if not Assigned(AModuleData) then begin
    BaseAddr := DWORD(AServices.ProcessDebugInfo^.lpBaseOfImage);
    hFile    := 0;
  end else begin
    BaseAddr := DWORD(AModuleData^.lpBaseOfDll);
    hFile    := AModuleData^.hFile;
  end;

  Result := hlpInitialize(AServices.ProcessDebugInfo^.hProcess, hFile, AModuleName, BaseAddr);

  if Result then
    AProvider := TCoffSP.Create(AServices, AModuleName, AModuleData)
  else
    AProvider := nil;

  hlpFinalize(AServices.ProcessDebugInfo^.hProcess, BaseAddr);
end;

{ TCoffSP }

function TCoffSP.QueryAddress(AUnitName, AProcName: PChar; ACodeBase: DWORD; out AAddress: DWORD): BOOL;
var
  Symbol   : PIMAGEHLP_SYMBOL;
  SymSize  : DWORD;
begin
  Result   := False;
  AAddress := DWORD(-1);
  Symbol   := nil;

  { Init }

  if hlpInitialize(FServices.Process, 0, FModuleName, GetModuleBase) then

    try
      { Symbol: Unit name ignored!!! }

      SymSize := SizeOf(IMAGEHLP_SYMBOL) + MAX_SYM_NAME;
      GetMem(Symbol, SymSize);
      FillChar(Symbol^, SymSize, 0);

      with Symbol^ do begin
        SizeOfStruct  := SymSize;
        MaxNameLength := MAX_SYM_NAME;
      end;

      Result := SymGetSymFromName(FServices.Process, PAnsiChar(AProcName), Symbol);
      if Result then
        AAddress := Symbol^.Address;
    finally
      FreeMem(Symbol);
    end;

  { Finalize }

  hlpFinalize(FServices.Process, GetModuleBase);
end;

function TCoffSP.QuerySymbol(ARawAddress, ARelativeAddress: DWORD): ISymbol;
var
  dwDispl  : DWORD;
  Symbol   : PIMAGEHLP_SYMBOL;
  SymbolLn : IMAGEHLP_LINE;
  symFName : String;
  symLine  : DWORD;
  symName  : String;
  SymSize  : Integer;
begin
  Result := nil;
  Symbol := nil;

  { Init }

  if hlpInitialize(FServices.Process, 0, FModuleName, GetModuleBase) then
    try
      { Symbol }

      SymSize := SizeOf(IMAGEHLP_SYMBOL) + MAX_SYM_NAME;
      GetMem(Symbol, SymSize);
      FillChar(Symbol^, SymSize, 0);

      with Symbol^ do begin
        SizeOfStruct  := SymSize;
        MaxNameLength := MAX_SYM_NAME;
      end;

      dwDispl := 0; { Optional for SymGetSymFromAddr }

      if SymGetSymFromAddr(FServices.Process, ARawAddress, @dwDispl, Symbol) then begin
        symName := Trim(StrPas(PAnsiChar(@Symbol^.Name)));

        { Line }

        FillChar(SymbolLn, SizeOf(IMAGEHLP_LINE), 0);
        SymbolLn.SizeOfStruct := SizeOf(IMAGEHLP_LINE);

        dwDispl               := 0; { Not optional for SymGetLineFromAddr!!! }

        if SymGetLineFromAddr(FServices.Process, ARawAddress, @dwDispl, @SymbolLn) then begin
          symFName := StrPas(SymbolLn.FileName);
          symLine  := SymbolLn.LineNumber;
        end else begin
          symFName := 'N/A';
          symLine  := 0;
        end;

        Result := TSymbol.Create(
          ExtractFileName(symFName),
          ExtractModuleName(symFName),
          symName,
          ARawAddress,
          symLine
        );
      end;
    finally
      FreeMem(Symbol);
    end;

  { Finalize }

  hlpFinalize(FServices.Process, GetModuleBase);
end;

function TCoffSP.ExtractModuleName(const ASourceFileName: String): String;
var
  Ext : String;
begin
  Result := ExtractFileName(ASourceFileName);
  Ext    := ExtractFileExt(Result);

  if (Ext <> '') then
    Result := Copy(Result, 1, (Length(Result) - Length(Ext)));
end;

begin
  RegisterFactory(TCoffSPFactory);
end.

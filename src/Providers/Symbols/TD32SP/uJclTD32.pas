unit uJclTD32;

interface

uses
  JclTd32,
  SysUtils,
  Windows;

type
  TJclPeBorTD32ImageEx = class(TJclPeBorTD32Image)
  protected
    function FormatProcName(const AProcName: String): String;
  public
    function AddressFromProcName(const AUnitName, AProcName: String): DWORD; 
    function ModuleStartFromName(const AModuleName: String): DWORD;
  end;

implementation

{ TJclPeBorTD32ImageEx }

function TJclPeBorTD32ImageEx.AddressFromProcName(const AUnitName, AProcName: String): DWORD;
var
  I        : Integer;
  ModAddr  : DWORD;
  Proc     : TJclProcSymbolInfo;
  ProcName : String;
begin
  Result  := 0;

  ModAddr := ModuleStartFromName(AUnitName);
  if (ModAddr <> DWORD(-1)) then
    with TD32Scanner do
      for I := 0 to (ProcSymbolCount - 1) do begin
        Proc := ProcSymbols[I];

        if (Proc.Offset >= ModAddr) then begin
          ProcName := FormatProcName(Names[Proc.NameIndex]);

          if SameText(AProcName, ProcName) then begin
            Result := Proc.Offset;
            Break;
          end;
        end;
      end;

end;

function TJclPeBorTD32ImageEx.FormatProcName(const AProcName: String): String;
var
  pchSecondAt, P: PChar;
begin
  Result := AProcName;
  
  if (Length(AProcName) > 0) and (AProcName[1] = '@') then
  begin
    pchSecondAt := StrScan(PChar(Copy(AProcName, 2, Length(AProcName) - 1)), '@');
    if pchSecondAt <> nil then
    begin
      Inc(pchSecondAt);
      Result := pchSecondAt;
      P := PChar(Result);
      while P^ <> #0 do
      begin
        if (pchSecondAt^ = '@') and ((pchSecondAt - 1)^ <> '@') then
          P^ := '.';
        Inc(P);
        Inc(pchSecondAt);
      end;
    end;
  end;
end;

function TJclPeBorTD32ImageEx.ModuleStartFromName(const AModuleName: String): DWORD;
var
  I       : Integer;
  ModName : String;
  Module  : TJclSourceModuleInfo;
begin
  Result := DWORD(-1);

  with TD32Scanner do
    for I := 0 to (SourceModuleCount - 1) do begin
      Module  := SourceModules[I];
      ModName := ExtractFileName(Names[Module.NameIndex]);

      if SameText(ModName, AModuleName) then begin
        Result := Module.Segment[0].StartOffset;
        Break;
      end;
    end;
end;

end.

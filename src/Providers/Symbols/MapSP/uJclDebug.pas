unit uJclDebug;

interface

uses
  JclDebug,
  JclSysUtils,
  SysUtils,
  Windows;

type
  TJclMapScannerEx = class(TJclMapScanner)
  public
    function AddressFromProcName(const AUnitName, AProcName: String): DWORD;
    function ModuleStartFromName(const AModuleName: String): DWORD;
  end;

implementation

{ TJclMapScannerEx }

function TJclMapScannerEx.AddressFromProcName(const AUnitName, AProcName: String): DWORD;
var
  I, Len  : Integer;
  ModAddr : DWORD;
  Proc    : String;
begin
  Result  := 0;
  Len     := Length(FProcNames);

  ModAddr := ModuleStartFromName(AUnitName);
  if (ModAddr <> DWORD(-1)) then
    for I := 0 to (Len - 1) do
      if (FProcNames[I].VA >= ModAddr) then begin
        Proc := MapStringCacheToStr(FProcNames[I].ProcName);

        if SameText(AProcName, Proc) then begin
          Result := FProcNames[I].VA;
          Break;
        end;
      end;

end;

function TJclMapScannerEx.ModuleStartFromName(const AModuleName: String): DWORD;
var
  I : Integer;
begin
  Result := DWORD(-1);

  for I := (Length(FSegments) - 1) downto 0 do
    if SameText(AModuleName, MapStringCacheToStr(FSegments[I].UnitName)) then begin
      Result := FSegments[I].StartVA;
      Break;
    end;
end;

end.

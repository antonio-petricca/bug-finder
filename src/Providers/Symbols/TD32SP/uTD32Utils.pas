unit uTD32Utils;

interface

uses
  SysUtils,
  uJclTD32,
  Windows;

function GetTd32Infos(const AModuleName: String; out AHandle: THandle): TJclPeBorTD32ImageEx;

implementation

function GetTd32Infos(const AModuleName: String; out AHandle: THandle): TJclPeBorTD32ImageEx;
begin
  Result  := nil;

  AHandle := LoadLibrary(PChar(AModuleName));
  if (AHandle <= 0) then
    Exit;

  Result := TJclPeBorTD32ImageEx.Create();
  Result.AttachLoadedModule(AHandle);

  if not Result.IsTD32DebugPresent then begin
    FreeAndNil(Result);
    FreeLibrary(AHandle);
    AHandle := 0;
  end;
end;

end.

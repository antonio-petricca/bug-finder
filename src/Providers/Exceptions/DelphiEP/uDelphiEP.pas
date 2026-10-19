unit uDelphiEP;

interface

uses
  hCoreServices,
  hDelphiEP,
  hExcProvider,
  SysUtils,
  uExcProvider,
  uDebugUtils,
  Windows;

type
  TDelphiEPFactory = class(TExcProviderFactory)
  public
    function AcceptException(const AServices: ICoreServices; AException: PExceptionRecord; out AProvider: IExceptionProvider): Boolean; override; 
  end;

  TDelphiEP = class(TExcProvider)
  private
    function GetExceptionDescription(AProcess: THandle; AExceptionObject: Pointer): String;
    function GetExceptionName(AProcess: THandle; AExceptionObject: Pointer): String;
    function GetExceptionVMT(AProcess: THandle; AExceptionObject: Pointer): DWORD;
  protected
    function GetDescription: PChar; override;
    function HandleException(AException: PExceptionRecord): BOOL; override;
    function TranslateExceptionAddress(AException: PExceptionRecord): DWORD; override;
  end;

implementation

const
  CP_UTF16           = 1200;
  MAX_MESSAGE_LENGTH = 65536;

type
  TStrRecHeader = packed record
    CodePage : Word;
    ElemSize : Word;
    RefCount : Longint;
    Length   : Longint;
  end;

{ TDelphiEPFactory }

function TDelphiEPFactory.AcceptException(const AServices: ICoreServices; AException: PExceptionRecord; out AProvider: IExceptionProvider): Boolean;
begin
  Result := Assigned(AException) and (AException^.ExceptionCode = cDelphiException);

  if Result then
    AProvider := TDelphiEP.Create(AServices)
  else
    AProvider := nil;
end;

{ TDelphiEP }

function TDelphiEP.GetExceptionVMT(AProcess: THandle; AExceptionObject: Pointer): DWORD;
var
  lpVMT : DWORD;
begin
  if not ReadProcMem(AProcess, AExceptionObject, @lpVMT, SizeOf(DWORD)) then
    Result := DWORD(nil)
  else
    Result := lpVMT;
end;

function TDelphiEP.GetExceptionName(AProcess: THandle; AExceptionObject: Pointer): String;

var
  tmpResult : String;

  function InternalGetExceptionName(AVmtOfs: Integer): String;
  var
    lpClassName   : Pointer;
    lplpClassName : Pointer;
    lpVMT         : Pointer;
    szClassName   : ShortString;
  begin
    Result := '';
    lpVMT  := Pointer(GetExceptionVMT(AProcess, AExceptionObject));
    
    if Assigned(lpVMT) then begin                                                                                { TClass(VMT) }
      lplpClassName := Pointer(DWORD(lpVMT) + AVmtOfs);

      if ReadProcMem(AProcess, lplpClassName, @lpClassName, SizeOf(DWORD)) then                                  { *ClassName }
        if ReadProcMem(AProcess, lpClassName, @szClassName[0], 1) then                                           { ClassName length }
          if ReadProcMem(AProcess, Pointer(DWORD(lpClassName) + 1), @szClassName[1], Byte(szClassName[0])) then  { ClassName data }
            Result := szClassName;
    end;
  end;

begin
  Result := 'Unknown!';

  {

    TClass(VMT) = ExceptionObject^
    *ClassName  = VMT + vmtClassName

  }

  tmpResult := InternalGetExceptionName(VMT_CLASSNAME_Dx);
  if IsValidIdent(tmpResult) then begin
    Result := tmpResult;
    Exit;
  end;

  tmpResult := InternalGetExceptionName(VMT_CLASSNAME_D3);
  if IsValidIdent(tmpResult) then
    Result := tmpResult;
end;

function TDelphiEP.GetExceptionDescription(AProcess: THandle; AExceptionObject: Pointer): String;
var
  AnsiMsg : AnsiString;
  dwLen   : Longint;
  Header  : TStrRecHeader;
  lpMsg   : Pointer;
  lpVars  : Pointer;
  WideMsg : WideString;
begin
  Result := 'Unknown!';
  lpVars := Pointer(DWORD(AExceptionObject) + SizeOf(Pointer) { VMT ptr } );

  {

    TObjectInstanceData = record
      VMT          : Pointer;
      InstanceData : ...

      ...
    end;

    Exception.FMessage is the first field after the VMT pointer.

    String header, located immediately before the characters data:

      Delphi 2009+ (12 bytes):   CodePage (Word, -12), ElemSize (Word, -10), RefCount (Longint, -8), Length (Longint, -4)
      Delphi pre-2009 (8 bytes): RefCount (Longint, -8), Length (Longint, -4)

    Length is expressed in characters in both cases.

  }

  if not ReadProcMem(AProcess, lpVars, @lpMsg, SizeOf(Pointer)) then
    Exit;

  if not Assigned(lpMsg) then begin
    Result := '';
    Exit;
  end;

  { Message length }

  if not ReadProcMem(AProcess, Pointer(DWORD(lpMsg) - 4), @dwLen, SizeOf(Longint)) then
    Exit;

  if (dwLen = 0) then begin
    Result := '';
    Exit;
  end;

  if (dwLen < 0) or (dwLen > MAX_MESSAGE_LENGTH) then
    Exit;

  { Message data }

  if ReadProcMem(AProcess, Pointer(DWORD(lpMsg) - SizeOf(TStrRecHeader)), @Header, SizeOf(TStrRecHeader)) and
     (Header.CodePage = CP_UTF16) and
     (Header.ElemSize = SizeOf(WideChar))
  then begin
    { UnicodeString }

    SetLength(WideMsg, dwLen);

    if ReadProcMem(AProcess, lpMsg, PWideChar(WideMsg), dwLen * SizeOf(WideChar)) then
      Result := WideMsg;
  end else begin
    { AnsiString }

    SetLength(AnsiMsg, dwLen);

    if ReadProcMem(AProcess, lpMsg, PAnsiChar(AnsiMsg), dwLen) then
      Result := String(AnsiMsg);
  end;
end;

function TDelphiEP.GetDescription: PChar;
begin
  Result := EXCEPTION_DESCRIPTION;
end;

function TDelphiEP.HandleException(AException: PExceptionRecord): BOOL;
var
  ExceptObj : Pointer;
begin
  ExceptObj := PSysExceptionRecord(AException)^.ExceptObject;

  FServices.LogMessage(PChar(Format('  Class name  : %s', [GetExceptionName(FServices.ProcessInfo^.hProcess, ExceptObj)])), True);
  FServices.LogMessage(PChar(Format('  Error mesg. : "%s"', [GetExceptionDescription(FServices.ProcessInfo^.hProcess, ExceptObj)])), True);

  Result := True;
end;

function TDelphiEP.TranslateExceptionAddress(AException: PExceptionRecord): DWORD;
begin
  Result := DWORD(PSysExceptionRecord(AException).ExceptAddr);
end;

begin
  RegisterFactory(TDelphiEPFactory);
end.

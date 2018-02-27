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
  dwSize : DWORD;
  lpMsg  : Pointer;
  lpSize : PDWORD;
  lpVars : Pointer;
  szMsg  : PChar;
begin
  Result := 'Unknown!';
  lpVars := Pointer(DWORD(AExceptionObject) + SizeOf(Pointer) { VMT ptr } );


  {

    TObjectInstanceData = record
      VMT          : Pointer;
      InstanceData : ...

      ...
    end;

  }

  if ReadProcMem(AProcess, lpVars, @lpMsg, SizeOf(Pointer)) then begin
    lpSize := PDWORD(DWORD(lpMsg) - 4 { AnsiString length offset } );
    szMsg  := nil;

    if ReadProcMem(AProcess, lpSize, @dwSize, SizeOf(DWORD)) then
      if (dwSize > 0) then
        try
          szMsg := StrAlloc(dwSize + 1);

          if ReadProcMem(AProcess, lpMsg, szMsg, dwSize) then begin
            PByte(DWORD(szMsg) + dwSize)^ := 0;
            Result                        := StrPas(szMsg);
          end;

        finally

          try
            if Assigned(szMsg) then
              StrDispose(szMsg);
          except
          end;

        end;

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

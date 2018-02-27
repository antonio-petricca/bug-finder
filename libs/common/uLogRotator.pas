unit uLogRotator;

interface

uses
  SysUtils,
  uLog,
  uUtils,
  Windows;

type
  TTimeLogRotation = (tlrDaily, tlrWeekly, tlrMonthly);

  TTimeLogRotator = class(TLogRotator)
  private
    FMode : TTimeLogRotation;
  protected
    fdtDate                   : TDateTime;
    fdtDay, fdtMonth, fdtYear : Word;
    fdtWeek                   : Integer;

    function    CheckRotation(AReferenceDate: TDateTime): Boolean;
    function    GetOldFileName: String;
    procedure   UpdateLastFileInfos(const AFileName: String);
  public
    constructor Create; override;

    procedure   Initialize; override;
    function    Validate: Boolean; override;

    property    Mode : TTimeLogRotation read FMode write FMode;
  end;

implementation

{ TTimeLogRotator }

function TTimeLogRotator.CheckRotation(AReferenceDate: TDateTime): Boolean;
var
  rdtDate                   : TDateTime;
  rdtDay, rdtMonth, rdtYear : Word;
  rdtWeek                   : Integer;

  procedure DoDecode;
  begin
    DecodeDate(rdtDate, rdtYear, rdtMonth, rdtDay);
  end;

begin
  rdtDate := Trunc(AReferenceDate);

  case FMode of
    tlrDaily :
      Result := (rdtDate > fdtDate);

    tlrMonthly : begin
      DoDecode;

      Result :=
        (rdtMonth > fdtMonth) or
        (rdtYear  > fdtYear)
      ;
    end;

    tlrWeekly : begin
      DoDecode;

      rdtWeek := DateToWeek(rdtDate);
      Result  := (rdtWeek > fdtWeek);
    end;
  else
    Result := False;
  end;
end;

constructor TTimeLogRotator.Create;
begin
  inherited Create;

  FMode := tlrDaily;
end;

function TTimeLogRotator.GetOldFileName: String;
begin
  Result := Format('%s.%s', [
    Owner.FileName,
    FormatDateTime('YYYY-MM-DD', fdtDate)
  ]);
end;

procedure TTimeLogRotator.Initialize;
begin
  if Assigned(Owner) then
    UpdateLastFileInfos(Owner.FileName);
end;

procedure TTimeLogRotator.UpdateLastFileInfos(const AFileName: String);
var
  FileAge : Integer;
begin
  FileAge := FileCreationAge(AFileName);
  if (FileAge <= 0) then
    fdtDate := Now
  else
    fdtDate := FileDateToDateTime(FileAge);

  DecodeDate(fdtDate, fdtYear, fdtMonth, fdtDay);

  fdtWeek := DateToWeek(fdtDate);
  fdtDate := Trunc(fdtDate);
end;

function TTimeLogRotator.Validate: Boolean;
var
  OldFileName : String;
begin
  Result := not CheckRotation(Now);
  if not Result then
    if FileExists(Owner.FileName) then
      try
        OldFileName := GetOldFileName;
        if FileExists(OldFileName) then
          DeleteFile(PChar(OldFileName));

        RenameFile(Owner.FileName, OldFileName);
      finally
        UpdateLastFileInfos(Owner.FileName);
      end;
end;

end.

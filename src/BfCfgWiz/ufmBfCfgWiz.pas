unit ufmBfCfgWiz;

interface

uses
  ActnList,
  Classes,
  ComCtrls,
  Controls,
  Dialogs,
  ExtCtrls,
  Forms,
  Graphics,
  hCore,
  IniFiles,
  JvCheckBox,
  JvCombobox,
  JvDialogs,
  JvEdit,
  JvExComCtrls,
  JvExControls,
  JvExExtCtrls,
  JvExMask,
  JvExStdCtrls,
  JvListView,
  JvRadioButton,
  JvRadioGroup,
  JvSpin,
  JvWizard,
  JvWizardRouteMapNodes,
  Mask,
  Messages,
  StdCtrls,
  SysUtils,
  uLog,
  uLogRotator,
  Windows;

type
  TfmBfCfgWiz = class(TForm)
    acAddBP                   : TAction;
    acAddExcProvider          : TAction;
    acAddSymProvider          : TAction;
    acDeleteBP                : TAction;
    acDelExcProvider          : TAction;
    acDelSymProvider          : TAction;
    ActionList                : TActionList;
    btAddBP                   : TButton;
    btAddExcProvider          : TButton;
    btAddSymProvider          : TButton;
    btDeleteBP                : TButton;
    btDelExcProvider          : TButton;
    btDelSymProvider          : TButton;
    btSelectFile              : TButton;
    cbBreakpointSourceDetails : TJvCheckBox;
    cbDllEvents               : TJvCheckBox;
    cbModuleName              : TJvComboBox;
    cbOutputDebugStringEvents : TJvCheckBox;
    cbPopUpOnErrors           : TJvCheckBox;
    cbProcessEvents           : TJvCheckBox;
    cbSource                  : TJvComboBox;
    cbSpoolToFile             : TJvCheckBox;
    cbSymbol                  : TJvComboBox;
    cbThreadEvents            : TJvCheckBox;
    edAppCmdLine              : TJvEdit;
    edAppName                 : TJvEdit;
    edBPName                  : TJvEdit;
    edFileName                : TJvEdit;
    edLogFileName             : TJvEdit;
    edSelectApp               : TButton;
    lbAppCmdLine              : TLabel;
    lbAppName                 : TLabel;
    lbBPName                  : TLabel;
    lbEvents                  : TLabel;
    lbLogFile                 : TLabel;
    lbLogViewLimit            : TLabel;
    lbModuleName              : TLabel;
    lbSave                    : TLabel;
    lbSource                  : TLabel;
    lbStackDepth              : TLabel;
    lbSymbol                  : TLabel;
    lvBreakpoints             : TJvListView;
    lvExcProviders            : TJvListView;
    lvSymProviders            : TJvListView;
    MapNodes                  : TJvWizardRouteMapNodes;
    odDll                     : TJvOpenDialog;
    odSelectApp               : TJvOpenDialog;
    odSelectFile              : TJvOpenDialog;
    pgAppSelection            : TJvWizardInteriorPage;
    pgConfigFileSelection     : TJvWizardInteriorPage;
    pgEvents                  : TJvWizardInteriorPage;
    pgExcProviders            : TJvWizardInteriorPage;
    pgLogging                 : TJvWizardInteriorPage;
    pgSave                    : TJvWizardInteriorPage;
    pgSymProviders            : TJvWizardInteriorPage;
    pgTracing                 : TJvWizardInteriorPage;
    rbCreateNewFile           : TJvRadioButton;
    rbSelectExistentFile      : TJvRadioButton;
    rgLogRotation             : TJvRadioGroup;
    sdConfig                  : TJvSaveDialog;
    seLogViewLimit            : TJvSpinEdit;
    seStackDepth              : TJvSpinEdit;
    Wizard                    : TJvWizard;

    procedure acAddBPExecute(Sender: TObject);
    procedure acAddBPUpdate(Sender: TObject);
    procedure acAddExcProviderExecute(Sender: TObject);
    procedure acDeleteBPExecute(Sender: TObject);
    procedure acDeleteBPUpdate(Sender: TObject);
    procedure acDelExcProviderExecute(Sender: TObject);
    procedure acDelExcProviderUpdate(Sender: TObject);
    procedure btSelectFileClick(Sender: TObject);
    procedure edSelectAppClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OnConfigFileClick(Sender: TObject);
    procedure WizardActivePageChanging(Sender: TObject; var ToPage: TJvWizardCustomPage);
    procedure acDelSymProviderUpdate(Sender: TObject);
    procedure acDelSymProviderExecute(Sender: TObject);
    procedure acAddSymProviderExecute(Sender: TObject);
    procedure WizardFinishButtonClick(Sender: TObject);
  private
    procedure AddBP(const AName, AModName, ASource, ASymbol: String);
    procedure AddExceptionProvider(const AName, AModule: String);
    procedure AddSymbolProvider(const AName, AModule: String);
    procedure ChangeToAppSelection;
    procedure ChangeToFileSelection;
    procedure DoUpdateFileNameBox;
    function  GetFileName: String;
    function  ValidateProvider(const AModule, AType: String): Boolean;

    procedure LoadConfiguration;
    procedure SaveConfiguration(const AFileName: String);
    
    procedure ResetGUI;
    procedure ResetGUI_Breakpoints;
    procedure ResetGUI_ExceptionProviders;
    procedure ResetGUI_SymbolProviders;
  public
    procedure SetFileName(const AFileName: String);
  end;

var
  fmBfCfgWiz: TfmBfCfgWiz;

implementation

{$R *.DFM}

{ TfmBfCfgWiz }

procedure TfmBfCfgWiz.DoUpdateFileNameBox;
var
  Status : Boolean;
begin
  Status               := rbSelectExistentFile.Checked;
  edFileName.Enabled   := Status;
  btSelectFile.Enabled := Status;

  if Status then
    edFileName.Color := clWindow
  else
    edFileName.Color := clBtnFace;
end;

procedure TfmBfCfgWiz.OnConfigFileClick(Sender: TObject);
begin
  DoUpdateFileNameBox;
end;

procedure TfmBfCfgWiz.btSelectFileClick(Sender: TObject);
begin
  with odSelectFile do
    if Execute then
      edFileName.Text := Trim(FileName);
end;

procedure TfmBfCfgWiz.LoadConfiguration;
var
  I          : Integer;
  List, Tkns : TStringList;
  Name       : String;
begin
  List := TStringList.Create;
  Tkns := TStringList.Create;
  
  with TIniFile.Create(GetFileName) do
    try
      { Main }

      edAppName.Text                    := Trim(ReadString(SEC_CONFIG, CFG_VAL_APPFILENAME, ''));
      edAppCmdLine.Text                 := Trim(ReadString(SEC_CONFIG, CFG_VAL_APPPARAMETERS, ''));

      { Log }

      edLogFileName.Text                := Trim(ReadString(SEC_LOG, CFG_VAL_LOGFILENAME, ''));
      cbSpoolToFile.Checked             := ReadBool(SEC_LOG, CFG_VAL_SPOOLTOFILE, True);

      rgLogRotation.ItemIndex           := ReadInteger(SEC_LOG, CFG_VAL_LOGFILEROTATION, DEF_VAL_LOGFILEROTATION);
      seLogViewLimit.Value              := ReadInteger(SEC_LOG, CFG_VAL_LOGVIEWLINESLIMIT, DEF_VAL_LOGVIEWLINESLIMIT);

      cbBreakpointSourceDetails.Checked := not ReadBool(SEC_LOG, CFG_VAL_SUPPRESSBREAKPOINTSOURCEDETAILS, False);
      cbDllEvents.Checked               := not ReadBool(SEC_LOG, CFG_VAL_SUPPRESSDLLEVENTS, False);
      cbOutputDebugStringEvents.Checked := not ReadBool(SEC_LOG, CFG_VAL_SUPPRESSOUTPUTDEBUGSTRINGEVENTS, False);
      cbProcessEvents.Checked           := not ReadBool(SEC_LOG, CFG_VAL_SUPPRESSPROCESSEVENTS, False);
      cbThreadEvents.Checked            := not ReadBool(SEC_LOG, CFG_VAL_SUPPRESSTHREADEVENTS, False);

      seStackDepth.Value                := ReadInteger(SEC_LOG, CFG_VAL_STACKDEPTH, DEF_VAL_STACKDEPTH);
      cbPopUpOnErrors.Checked           := ReadBool(SEC_LOG, CFG_VAL_POPUPONERRORS, True);

      { Breakpoints }

      ResetGUI_Breakpoints;
      ReadSection(SEC_BRKPTS, List);

      for I := 0 to (List.Count - 1) do begin
        Name           := List[I];
        Tkns.CommaText := ReadString(SEC_BRKPTS, Name, '');

        if (Tkns.Count = 3) then begin

          Tkns[0] := Trim(Tkns[0]);
          Tkns[1] := Trim(Tkns[1]);
          Tkns[2] := Trim(Tkns[2]);

          AddBP(Name, Tkns[0], Tkns[1], Tkns[2]);

        end;
      end;

      { Exception providers }

      ResetGUI_ExceptionProviders;
      ReadSection(SEC_EXCPRV, List);

      for I := 0 to (List.Count - 1) do begin
        Name := List[I];
        AddExceptionProvider(Name, ReadString(SEC_EXCPRV, Name, ''));
      end;

      { Symbol providers }

      ResetGUI_SymbolProviders;
      ReadSection(SEC_SYMPRV, List);

      for I := 0 to (List.Count - 1) do begin
        Name := List[I];
        AddSymbolProvider(Name, ReadString(SEC_SYMPRV, Name, ''));
      end;
    finally
      Free;
    end;

  FreeAndNil(Tkns);
  FreeAndNil(List);  
end;

function TfmBfCfgWiz.GetFileName: String;
begin
  Result := Trim(edFileName.Text);
end;

procedure TfmBfCfgWiz.WizardActivePageChanging(Sender: TObject; var ToPage: TJvWizardCustomPage);
begin
  if (ToPage = pgConfigFileSelection) then
    ChangeToFileSelection
  else if (ToPage = pgAppSelection) then
    ChangeToAppSelection;
end;

procedure TfmBfCfgWiz.ResetGUI;
begin
  edAppName.Text          := '';
  edAppCmdLine.Text       := '';

  cbSpoolToFile.Checked   := True;
  edLogFileName.Text      := '';
  rgLogRotation.ItemIndex := DEF_VAL_LOGFILEROTATION;
  seLogViewLimit.Value    := DEF_VAL_LOGVIEWLINESLIMIT;

  with rgLogRotation do begin
    ItemIndex                      := DEF_VAL_LOGFILEROTATION;
    Items[DEF_VAL_LOGFILEROTATION] := Items[DEF_VAL_LOGFILEROTATION] + ' (Default)';
  end;

  ResetGUI_Breakpoints;
  ResetGUI_ExceptionProviders;
  ResetGUI_SymbolProviders;
end;

procedure TfmBfCfgWiz.ChangeToAppSelection;
begin
  if rbCreateNewFile.Checked then
    ResetGUI
  else begin
    if not FileExists(GetFileName) then begin
      MessageDlg('Specified file is not valid.', mtError, [mbRetry], 0);
      Abort;
    end;

    LoadConfiguration;
  end;
end;

procedure TfmBfCfgWiz.edSelectAppClick(Sender: TObject);
begin
  with odSelectApp do
    if Execute then
      edAppName.Text := Trim(FileName);
end;

procedure TfmBfCfgWiz.FormCreate(Sender: TObject);
begin
  with lbLogViewLimit do
    Caption := Format(Caption, [DEF_VAL_LOGVIEWLINESLIMIT]);

  with lbStackDepth do
    Caption := Format(Caption, [DEF_VAL_STACKDEPTH]);

  with seStackDepth do begin
    MaxValue := MaxInt;
    MinValue := DEF_VAL_STACKDEPTH;
    Value    := DEF_VAL_STACKDEPTH;
  end;

  ResetGUI;
  OnConfigFileClick(Self);
end;

procedure TfmBfCfgWiz.acDeleteBPUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := (lvBreakpoints.ItemIndex >= 0);
end;

procedure TfmBfCfgWiz.acDeleteBPExecute(Sender: TObject);
begin
  if (MessageDlg('Are you sure to remove the selected breakpoint?', mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
    with lvBreakpoints do
      Items.Delete(ItemIndex);
end;

procedure TfmBfCfgWiz.acAddBPUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled :=
    (Trim(edBPName.Text)     <> '') and
    (Trim(cbModuleName.Text) <> '') and
    (Trim(cbSource.Text)     <> '') and
    (Trim(cbSymbol.Text)     <> '')
  ;
end;

procedure TfmBfCfgWiz.acAddBPExecute(Sender: TObject);
begin
  AddBP(edBPName.Text, cbModuleName.Text, cbSource.Text, cbSymbol.Text);
end;

procedure TfmBfCfgWiz.AddBP(const AName, AModName, ASource, ASymbol: String);
var
  ModName, Source, Symbol : String;
begin
  ModName := Trim(AModName);
  Source  := Trim(ASource);
  Symbol  := Trim(ASymbol);

  with cbModuleName.Items do
    if (IndexOf(ModName) < 0) then
      Add(ModName);

  with cbSource.Items do
    if (IndexOf(Source) < 0) then
      Add(Source);

  with cbSymbol.Items do
    if (IndexOf(Symbol) < 0) then
      Add(Symbol);

  with lvBreakpoints.Items.Add do begin
    Caption := Trim(AName);
    SubItems.Add(ModName);
    SubItems.Add(Source);
    SubItems.Add(Symbol);
  end;
end;

procedure TfmBfCfgWiz.ResetGUI_Breakpoints;
begin
  lvBreakpoints.Items.Clear;
  cbModuleName.Clear;
  cbSource.Clear;
  cbSymbol.Clear;
end;

procedure TfmBfCfgWiz.ChangeToFileSelection;
begin
  ResetGUI;
end;

procedure TfmBfCfgWiz.SetFileName(const AFileName: String);
begin
  if FileExists(AFileName) then begin
    ResetGUI;

    rbSelectExistentFile.Checked := True;
    edFileName.Text              := AFileName;
    Wizard.ActivePageIndex       := 1; { pgAppSelection }
  end;
end;

procedure TfmBfCfgWiz.ResetGUI_ExceptionProviders;
begin
  lvExcProviders.Items.Clear;
end;

procedure TfmBfCfgWiz.AddExceptionProvider(const AName, AModule: String);
begin
  with lvExcProviders.Items.Add do begin
    Caption := AName;
    SubItems.Add(AModule);
  end;
end;

procedure TfmBfCfgWiz.acDelExcProviderUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := (lvExcProviders.ItemIndex >= 0);
end;

procedure TfmBfCfgWiz.acDelExcProviderExecute(Sender: TObject);
begin
  if (MessageDlg('Are you sure to remove the exception provider?', mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
    with lvExcProviders do
      Items.Delete(ItemIndex);
end;

procedure TfmBfCfgWiz.acAddExcProviderExecute(Sender: TObject);
var
  ModName : String;
begin
  with odDll do
    if Execute then
      if not ValidateProvider(FileName, 'Exception') then
        MessageDlg('The select module is not a valid exception provider.', mtError, [mbAbort], 0)
      else begin
        ModName := ExtractFileName(FileName);
        if InputQuery('Exception Provider', 'Enter a mnemonic name:', ModName) then
          AddExceptionProvider(ModName, FileName);
      end;
end;

function TfmBfCfgWiz.ValidateProvider(const AModule, AType: String): Boolean;
var
  hModule : THandle;
begin
  hModule := LoadLibrary(PChar(AModule));
  Result  := (hModule > 0);
  if Result then begin
    Result := (nil <> GetProcAddress(hModule, PChar(Format('Get%sProvider', [AType]))));
    FreeLibrary(hModule);
  end;
end;

procedure TfmBfCfgWiz.acDelSymProviderUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := (lvSymProviders.ItemIndex >= 0);
end;

procedure TfmBfCfgWiz.acDelSymProviderExecute(Sender: TObject);
begin
  if (MessageDlg('Are you sure to remove the symbol provider?', mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
    with lvSymProviders do
      Items.Delete(ItemIndex);
end;

procedure TfmBfCfgWiz.acAddSymProviderExecute(Sender: TObject);
var
  ModName : String;
begin
  with odDll do
    if Execute then
      if not ValidateProvider(FileName, 'Symbol') then
        MessageDlg('The select module is not a valid symbol provider.', mtError, [mbAbort], 0)
      else begin
        ModName := ExtractFileName(FileName);
        if InputQuery('Exception Provider', 'Enter a mnemonic name:', ModName) then
          AddSymbolProvider(ModName, FileName);
      end;
end;

procedure TfmBfCfgWiz.AddSymbolProvider(const AName, AModule: String);
begin
  with lvSymProviders.Items.Add do begin
    Caption := AName;
    SubItems.Add(AModule);
  end;
end;

procedure TfmBfCfgWiz.ResetGUI_SymbolProviders;
begin
  lvSymProviders.Items.Clear;
end;

procedure TfmBfCfgWiz.WizardFinishButtonClick(Sender: TObject);
var
  CfgFileName : String;
begin
  if not rbCreateNewFile.Checked then
    CfgFileName := GetFileName
  else
    with sdConfig do
      if not Execute then
        Exit
      else
        CfgFileName := Trim(FileName);

  SaveConfiguration(CfgFileName);
  Close;
end;

procedure TfmBfCfgWiz.SaveConfiguration(const AFileName: String);
var
  I : Integer;
begin
  with TIniFile.Create(AFileName) do
    try
      { Main }

      WriteString(SEC_CONFIG, CFG_VAL_APPFILENAME, Trim(edAppName.Text));
      WriteString(SEC_CONFIG, CFG_VAL_APPPARAMETERS, Trim(edAppCmdLine.Text));

      { Log }

      WriteString(SEC_LOG, CFG_VAL_LOGFILENAME, Trim(edLogFileName.Text));
      WriteBool(SEC_LOG, CFG_VAL_SPOOLTOFILE, cbSpoolToFile.Checked);

      WriteInteger(SEC_LOG, CFG_VAL_LOGFILEROTATION, rgLogRotation.ItemIndex);
      WriteInteger(SEC_LOG, CFG_VAL_LOGVIEWLINESLIMIT, Trunc(seLogViewLimit.Value));

      WriteBool(SEC_LOG, CFG_VAL_SUPPRESSBREAKPOINTSOURCEDETAILS, not cbBreakpointSourceDetails.Checked);
      WriteBool(SEC_LOG, CFG_VAL_SUPPRESSDLLEVENTS, not cbDllEvents.Checked);
      WriteBool(SEC_LOG, CFG_VAL_SUPPRESSOUTPUTDEBUGSTRINGEVENTS, not cbOutputDebugStringEvents.Checked);
      WriteBool(SEC_LOG, CFG_VAL_SUPPRESSPROCESSEVENTS, not cbProcessEvents.Checked);
      WriteBool(SEC_LOG, CFG_VAL_SUPPRESSTHREADEVENTS, not cbThreadEvents.Checked);

      WriteInteger(SEC_LOG, CFG_VAL_STACKDEPTH, Trunc(seStackDepth.Value));
      WriteBool(SEC_LOG, CFG_VAL_POPUPONERRORS, cbPopUpOnErrors.Checked);

      { Breakpoints }

      EraseSection(SEC_BRKPTS);

      for I := 0 to (lvBreakpoints.Items.Count - 1) do
        with lvBreakpoints.Items[I] do
          WriteString(SEC_BRKPTS, Caption, Format('%s,%s,%s', [
            SubItems[0],
            SubItems[1],
            SubItems[2]
          ]));

      { Exception providers }

      EraseSection(SEC_EXCPRV);

      for I := 0 to (lvExcProviders.Items.Count - 1) do
        with lvExcProviders.Items[I] do
          WriteString(SEC_EXCPRV, Caption, SubItems[0]);

      { Symbol providers }

      EraseSection(SEC_SYMPRV);

      for I := 0 to (lvSymProviders.Items.Count - 1) do
        with lvSymProviders.Items[I] do
          WriteString(SEC_SYMPRV, Caption, SubItems[0]);
      
    finally
      Free;
    end;
end;

end.

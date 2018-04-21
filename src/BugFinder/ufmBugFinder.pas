unit ufmBugFinder;

interface

uses
  Classes,
  Clipbrd,
  Controls,
  Dialogs,
  ExtCtrls,
  Forms,
  Graphics,
  hBfCfgWiz,
  hCore,
  hUtils,
  ImgList,
  JvBaseDlg,
  JvWinDialogs,
  LMDBaseDialog,
  LMDContainerComponent,
  LMDCustomComponent,
  LMDTrayIcon,
  LMDWndProcComponent,
  Menus,
  Messages,
  StdCtrls,
  SysUtils,
  uCore,
  uUtils,
  Windows, System.ImageList,
  uDebugThread;

type
  TfmBugFinder = class(TForm)
    AboutDlg   : TJvShellAboutDialog;
    btCopy     : TButton;
    btHide     : TButton;
    LargeIcons : TImageList;
    miAbout    : TMenuItem;
    miClose    : TMenuItem;
    miEditCfg  : TMenuItem;
    miView     : TMenuItem;
    mmLog      : TMemo;
    N1         : TMenuItem;
    N2         : TMenuItem;
    Panel      : TPanel;
    PopupMenu  : TPopupMenu;
    SmallIcons : TImageList;
    TrayIcon   : TLMDTrayIcon;    

    procedure miViewClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure miCloseClick(Sender: TObject);
    procedure miAboutClick(Sender: TObject);
    procedure btCopyClick(Sender: TObject);
    procedure btHideClick(Sender: TObject);
    procedure miEditCfgClick(Sender: TObject);
  private
    FDebugger    : TDebugThread;
    FForceClose  : Boolean;
    FWellStarted : Boolean;

    procedure   DoClose; reintroduce;
    procedure   DoLog(ASender: TObject; const AMsg: String; AIsError: Boolean);
    procedure   DoShow; reintroduce;
    procedure   DoTerminate(ASender: TObject);
    procedure   SetTrayIcon(AIsError: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    property    WellStarted : Boolean read FWellStarted;
  end;

var
  fmBugFinder: TfmBugFinder;

implementation

{$R *.DFM}

{ TfmBugFinder }

constructor TfmBugFinder.Create(AOwner: TComponent);
var
  ErrorMessage : String;
  Infos        : TFileVersionInfo;
begin
  inherited Create(AOwner);

  FWellStarted := False;
  GetAppVersionInfo(Infos);

  Caption           := Format(Caption, [Infos.FileVersion]);
  Application.Title := Caption;
  TrayIcon.Hint     := Caption;

  SetTrayIcon(False);

  FDebugger         := TDebugThread.Create(DoLog, DoTerminate);
  FForceClose       := False;

  with FDebugger do begin

    { Load configuration }

    if not Core.LoadConfiguration(ErrorMessage) then begin
      MessageDlg(ErrorMessage, mtError, [mbOk], 0);
      miEditCfgClick(Self);
      Close;
      Exit;
    end;

    { Start debugging }

    Start;

    while
      not IsRunning and
      not ErrorStatus
    do
      Application.ProcessMessages;

    if ErrorStatus then
      Self.DoTerminate(Self);
  end;

  FWellStarted := True;
end;

destructor TfmBugFinder.Destroy;
begin
  if
    FWellStarted and
    FDebugger.IsRunning
  then
    FDebugger.Stop;

  FreeAndNil(FDebugger);

  inherited Destroy;
end;

procedure TfmBugFinder.DoLog(ASender: TObject; const AMsg: String; AIsError: Boolean);
begin
  if not (csDestroying in ComponentState) then begin

    with mmLog do
      try
        Lines.BeginUpdate;

        with FDebugger.Core.Config do
          if
            (LogViewLinesLimit > 0) and
            (Lines.Count >= LogViewLinesLimit)
          then
            Lines.Clear;

        Lines.Add(AMsg);
        Perform(EM_LineScroll, 0, Lines.Count);
      finally
        Lines.EndUpdate;
      end;

    if AIsError then begin
      SetTrayIcon(True);

      if 
        FDebugger.Core.Config.PopUpOnErrors and
        not Visible
      then
        DoShow;
    end;
  end;    
end;

procedure TfmBugFinder.miViewClick(Sender: TObject);
begin
  SetTrayIcon(False);
  DoShow;
end;

procedure TfmBugFinder.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if
    not FForceClose and
    FDebugger.IsRunning
  then begin
    SetTrayIcon(False);
    Action := caNone;
    Hide;
  end else
    Action := caFree;
end;

procedure TfmBugFinder.miCloseClick(Sender: TObject);
begin
  if AreYouSure then begin
    FForceClose := True;
    Close;
  end;
end;

procedure TfmBugFinder.DoTerminate(ASender: TObject);
begin
  if Assigned(FDebugger) then
    if not FDebugger.Core.Config.PopUpOnErrors then begin
      MessageDlg('The process has been terminated.'#13#10#13#10'Please see the log file for further details.', mtInformation, [mbOK], 0);
      DoClose;
    end else
      DoShow;
end;

procedure TfmBugFinder.miAboutClick(Sender: TObject);
begin
  with AboutDlg do begin
    Caption := Self.Caption;
    Execute;
  end;
end;

procedure TfmBugFinder.SetTrayIcon(AIsError: Boolean);
begin
  if not AIsError then
    TrayIcon.Icon := Application.Icon
  else
    SmallIcons.GetIcon(0, TrayIcon.Icon); 
end;

procedure TfmBugFinder.btCopyClick(Sender: TObject);
begin
  Clipboard.AsText := mmLog.Lines.Text;
  MessageDlg('Current log text successfully copied to cliepboard.', mtInformation, [mbOK], 0);
end;

procedure TfmBugFinder.btHideClick(Sender: TObject);
begin
  Close;
end;

procedure TfmBugFinder.miEditCfgClick(Sender: TObject);
begin
  Configure(0, 0, PAnsiChar(FDebugger.Core.IniFileName), 0);
  MessageDlg('Please restart Bug Finder to apply changes.', mtInformation, [mbOK], 0);
end;

procedure TfmBugFinder.DoShow;
begin
  Show;
  Update;
  BringToFront;
end;

procedure TfmBugFinder.DoClose;
begin
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

end.

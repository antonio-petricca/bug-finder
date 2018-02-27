unit ufmFault;

interface

uses
  Classes,
  Controls,
  Dialogs,
  ExtCtrls,
  Forms,
  Graphics,
  Messages,
  ShellApi,
  StdCtrls,
  SysUtils,
  Windows, jpeg;

type
  TfmFaultingThread = class(TThread)
  protected
    procedure Execute; override;
  end;

  TfmFault = class(TForm)
    btCustDelphiExc            : TButton;
    btDelphiAccessViolationExc : TButton;
    btDelphiIntOverflowExc     : TButton;
    btOds                      : TButton;
    btTD32Exc                  : TButton;
    btThdExc                   : TButton;
    btVCppExc                  : TButton;
    btVCppExcByClass           : TButton;
    GroupBox1                  : TGroupBox;
    GroupBox2                  : TGroupBox;
    imgLogo                    : TImage;

    procedure btCustDelphiExcClick(Sender: TObject);
    procedure btDelphiAccessViolationExcClick(Sender: TObject);
    procedure btDelphiIntOverflowExcClick(Sender: TObject);
    procedure btOdsClick(Sender: TObject);
    procedure btTD32ExcClick(Sender: TObject);
    procedure btThdExcClick(Sender: TObject);
    procedure btVCppExcByClassClick(Sender: TObject);
    procedure btVCppExcClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure imgLogoClick(Sender: TObject);
  protected
    procedure WMPostCreate(var AMessage: TMessage); message WM_USER;
  end;

var
  fmFault: TfmFault;

implementation

{$R *.DFM}

procedure RaiseExceptionFromCoffDll(); stdcall;        external 'FaultingAppCOFF.dll';
procedure RaiseExceptionFromCoffDllByClass(); stdcall; external 'FaultingAppCOFF.dll';
procedure RaiseExceptionFromTD32Dll; stdcall;          external 'FaultingAppTD32.dll';

{ TfmFaultingThread }

procedure TfmFaultingThread.Execute;
begin
  FreeOnTerminate := True;
  raise Exception.Create('Exception from a faulting Thread!');
end;

{ TfmFault }

procedure TfmFault.btCustDelphiExcClick(Sender: TObject);
begin
  raise Exception.Create('Custom Delphi Exception!');
end;

procedure TfmFault.btOdsClick(Sender: TObject);
begin
  OutputDebugString('The Bug Finder');
end;

procedure TfmFault.btDelphiIntOverflowExcClick(Sender: TObject);
var
  B : Byte;
begin
  B := 255;
  Inc(B);
  ShowMessageFmt('%d', [B]);
end;

procedure TfmFault.btDelphiAccessViolationExcClick(Sender: TObject);
begin
  PInteger(nil)^ := 0;
end;

procedure TfmFault.btVCppExcClick(Sender: TObject);
begin
  RaiseExceptionFromCoffDll;
end;

procedure TfmFault.btVCppExcByClassClick(Sender: TObject);
begin
  RaiseExceptionFromCoffDllByClass;
end;

procedure TfmFault.imgLogoClick(Sender: TObject);
begin
  ShellExecute(0, 'open', 'http://exccatch.sourceforge.net', nil, nil, SW_NORMAL);
end;

procedure TfmFault.WMPostCreate(var AMessage: TMessage);
begin
 MessageDlg('By this application you can explore some of the basic Bug Finder features.'+#13+#10+''+#13+#10+'Please edit the "BugFinder.ini" file to customize the configuration parameters.', mtInformation, [mbOK], 0);
end;

procedure TfmFault.FormCreate(Sender: TObject);
begin
  PostMessage(Handle, WM_USER, 0, 0);
end;

procedure TfmFault.btTD32ExcClick(Sender: TObject);
begin
  RaiseExceptionFromTD32Dll;
end;

procedure TfmFault.btThdExcClick(Sender: TObject);
begin
  TfmFaultingThread.Create(False);
  MessageDlg('Please see the Bug Finder log', mtWarning, [mbOK], 0);
end;

end.

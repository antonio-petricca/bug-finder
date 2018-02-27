object fmBfCfgWiz: TfmBfCfgWiz
  Left = 284
  Top = 137
  ActiveControl = edBPName
  BorderStyle = bsDialog
  Caption = 'Bug Finder configuration wizard'
  ClientHeight = 443
  ClientWidth = 650
  Color = clWindow
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Verdana'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Wizard: TJvWizard
    Left = 0
    Top = 0
    Width = 650
    Height = 443
    ActivePage = pgTracing
    ButtonBarHeight = 42
    ButtonStart.Caption = 'To &Start Page'
    ButtonStart.NumGlyphs = 1
    ButtonStart.Width = 85
    ButtonLast.Caption = 'To &Last Page'
    ButtonLast.NumGlyphs = 1
    ButtonLast.Width = 85
    ButtonBack.Caption = '< &Back'
    ButtonBack.NumGlyphs = 1
    ButtonBack.Width = 75
    ButtonNext.Caption = '&Next >'
    ButtonNext.NumGlyphs = 1
    ButtonNext.Width = 75
    ButtonFinish.Caption = '&Finish'
    ButtonFinish.NumGlyphs = 1
    ButtonFinish.Width = 75
    ButtonCancel.Caption = 'Cancel'
    ButtonCancel.NumGlyphs = 1
    ButtonCancel.ModalResult = 2
    ButtonCancel.Width = 75
    ButtonHelp.Caption = '&Help'
    ButtonHelp.NumGlyphs = 1
    ButtonHelp.Width = 75
    ShowRouteMap = True
    OnFinishButtonClick = WizardFinishButtonClick
    OnActivePageChanging = WizardActivePageChanging
    DesignSize = (
      650
      443)
    object pgConfigFileSelection: TJvWizardInteriorPage
      Header.ParentFont = False
      Header.Title.Color = clNone
      Header.Title.Text = 'Configuration file'
      Header.Title.Anchors = [akLeft, akTop, akRight]
      Header.Title.Font.Charset = DEFAULT_CHARSET
      Header.Title.Font.Color = clWindowText
      Header.Title.Font.Height = -16
      Header.Title.Font.Name = 'Verdana'
      Header.Title.Font.Style = [fsBold]
      Header.Subtitle.Color = clNone
      Header.Subtitle.Text = 
        #13#10'Select Bug Finder existent configuration file or create new on' +
        'e.'
      Header.Subtitle.Anchors = [akLeft, akTop, akRight, akBottom]
      Header.Subtitle.Font.Charset = DEFAULT_CHARSET
      Header.Subtitle.Font.Color = clWindowText
      Header.Subtitle.Font.Height = -11
      Header.Subtitle.Font.Name = 'Verdana'
      Header.Subtitle.Font.Style = []
      Panel.Color = clWindow
      Color = clWindow
      object rbCreateNewFile: TJvRadioButton
        Left = 16
        Top = 88
        Width = 124
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Create new one...'
        Checked = True
        TabOrder = 0
        TabStop = True
        OnClick = OnConfigFileClick
        HotTrackFont.Charset = DEFAULT_CHARSET
        HotTrackFont.Color = clWindowText
        HotTrackFont.Height = -11
        HotTrackFont.Name = 'Verdana'
        HotTrackFont.Style = []
        LinkedControls = <>
      end
      object rbSelectExistentFile: TJvRadioButton
        Left = 16
        Top = 120
        Width = 131
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Select existent file:'
        TabOrder = 1
        OnClick = OnConfigFileClick
        HotTrackFont.Charset = DEFAULT_CHARSET
        HotTrackFont.Color = clWindowText
        HotTrackFont.Height = -11
        HotTrackFont.Name = 'Verdana'
        HotTrackFont.Style = []
        LinkedControls = <>
      end
      object edFileName: TJvEdit
        Left = 32
        Top = 144
        Width = 417
        Height = 21
        TabOrder = 2
      end
      object btSelectFile: TButton
        Left = 456
        Top = 144
        Width = 21
        Height = 21
        Caption = '...'
        TabOrder = 3
        OnClick = btSelectFileClick
      end
    end
    object pgAppSelection: TJvWizardInteriorPage
      Header.ParentFont = False
      Header.Title.Color = clNone
      Header.Title.Text = 'Target application'
      Header.Title.Anchors = [akLeft, akTop, akRight]
      Header.Title.Font.Charset = DEFAULT_CHARSET
      Header.Title.Font.Color = clWindowText
      Header.Title.Font.Height = -16
      Header.Title.Font.Name = 'Verdana'
      Header.Title.Font.Style = [fsBold]
      Header.Subtitle.Color = clNone
      Header.Subtitle.Text = #13#10'Choose a target application to be debugged by Bug Finder.'
      Header.Subtitle.Anchors = [akLeft, akTop, akRight, akBottom]
      Header.Subtitle.Font.Charset = DEFAULT_CHARSET
      Header.Subtitle.Font.Color = clWindowText
      Header.Subtitle.Font.Height = -11
      Header.Subtitle.Font.Name = 'Verdana'
      Header.Subtitle.Font.Style = []
      Panel.Color = clWindow
      Color = clWindow
      object lbAppName: TLabel
        Left = 16
        Top = 88
        Width = 157
        Height = 13
        Caption = 'Target application full path:'
      end
      object lbAppCmdLine: TLabel
        Left = 16
        Top = 144
        Width = 320
        Height = 13
        Caption = 'Target application command line parameters (optional):'
      end
      object edAppName: TJvEdit
        Left = 16
        Top = 104
        Width = 433
        Height = 21
        TabOrder = 0
      end
      object edSelectApp: TButton
        Left = 456
        Top = 104
        Width = 21
        Height = 21
        Caption = '...'
        TabOrder = 1
        OnClick = edSelectAppClick
      end
      object edAppCmdLine: TJvEdit
        Left = 16
        Top = 160
        Width = 457
        Height = 21
        TabOrder = 2
      end
    end
    object pgLogging: TJvWizardInteriorPage
      Header.ParentFont = False
      Header.Title.Color = clNone
      Header.Title.Text = 'Logging options'
      Header.Title.Anchors = [akLeft, akTop, akRight]
      Header.Title.Font.Charset = DEFAULT_CHARSET
      Header.Title.Font.Color = clWindowText
      Header.Title.Font.Height = -16
      Header.Title.Font.Name = 'Verdana'
      Header.Title.Font.Style = [fsBold]
      Header.Subtitle.Color = clNone
      Header.Subtitle.Text = #13#10'Choose file and screen logging options and policies.'
      Header.Subtitle.Anchors = [akLeft, akTop, akRight, akBottom]
      Header.Subtitle.Font.Charset = DEFAULT_CHARSET
      Header.Subtitle.Font.Color = clWindowText
      Header.Subtitle.Font.Height = -11
      Header.Subtitle.Font.Name = 'Verdana'
      Header.Subtitle.Font.Style = []
      Panel.Color = clWindow
      Color = clWindow
      object lbLogFile: TLabel
        Left = 16
        Top = 120
        Width = 224
        Height = 13
        Caption = 'Log file name (Default: BugFinder.log):'
      end
      object lbLogViewLimit: TLabel
        Left = 16
        Top = 296
        Width = 232
        Height = 13
        Caption = 'Log view (GUI) lines limit (Default: %d):'
      end
      object lbStackDepth: TLabel
        Left = 16
        Top = 320
        Width = 257
        Height = 13
        Caption = 'Exceptions Stack Trace depth (Default: %d):'
      end
      object edLogFileName: TJvEdit
        Left = 16
        Top = 136
        Width = 457
        Height = 21
        TabOrder = 1
      end
      object cbSpoolToFile: TJvCheckBox
        Left = 16
        Top = 88
        Width = 198
        Height = 17
        Caption = 'Write log to file (Default: True)'
        TabOrder = 0
        LinkedControls = <>
        HotTrackFont.Charset = DEFAULT_CHARSET
        HotTrackFont.Color = clWindowText
        HotTrackFont.Height = -11
        HotTrackFont.Name = 'Verdana'
        HotTrackFont.Style = []
      end
      object seLogViewLimit: TJvSpinEdit
        Left = 352
        Top = 292
        Width = 121
        Height = 21
        TabOrder = 2
      end
      object rgLogRotation: TJvRadioGroup
        Left = 16
        Top = 176
        Width = 457
        Height = 105
        Caption = 'Log rotation policy'
        ItemIndex = 0
        Items.Strings = (
          'Daily'
          'Weekly'
          'Monthly')
        TabOrder = 3
        CaptionVisible = True
      end
      object seStackDepth: TJvSpinEdit
        Left = 352
        Top = 316
        Width = 121
        Height = 21
        TabOrder = 4
      end
      object cbPopUpOnErrors: TJvCheckBox
        Left = 16
        Top = 352
        Width = 246
        Height = 17
        Caption = 'Pop up log window on exception events'
        TabOrder = 5
        LinkedControls = <>
        HotTrackFont.Charset = DEFAULT_CHARSET
        HotTrackFont.Color = clWindowText
        HotTrackFont.Height = -11
        HotTrackFont.Name = 'Verdana'
        HotTrackFont.Style = []
      end
    end
    object pgEvents: TJvWizardInteriorPage
      Header.ParentFont = False
      Header.Title.Color = clNone
      Header.Title.Text = 'Events'
      Header.Title.Anchors = [akLeft, akTop, akRight]
      Header.Title.Font.Charset = DEFAULT_CHARSET
      Header.Title.Font.Color = clWindowText
      Header.Title.Font.Height = -16
      Header.Title.Font.Name = 'Verdana'
      Header.Title.Font.Style = [fsBold]
      Header.Subtitle.Color = clNone
      Header.Subtitle.Text = #13#10'Choose which kind of events you need to be logged.'
      Header.Subtitle.Anchors = [akLeft, akTop, akRight, akBottom]
      Header.Subtitle.Font.Charset = DEFAULT_CHARSET
      Header.Subtitle.Font.Color = clWindowText
      Header.Subtitle.Font.Height = -11
      Header.Subtitle.Font.Name = 'Verdana'
      Header.Subtitle.Font.Style = []
      Panel.Color = clWindow
      Color = clWindow
      object lbEvents: TLabel
        Left = 16
        Top = 88
        Width = 99
        Height = 13
        Caption = 'Available events:'
      end
      object cbBreakpointSourceDetails: TJvCheckBox
        Left = 32
        Top = 208
        Width = 166
        Height = 17
        Caption = 'Breakpoint source details'
        TabOrder = 0
        LinkedControls = <>
        HotTrackFont.Charset = DEFAULT_CHARSET
        HotTrackFont.Color = clWindowText
        HotTrackFont.Height = -11
        HotTrackFont.Name = 'Verdana'
        HotTrackFont.Style = []
      end
      object cbDllEvents: TJvCheckBox
        Left = 32
        Top = 160
        Width = 147
        Height = 17
        Caption = 'DLL loading/unloading'
        TabOrder = 1
        LinkedControls = <>
        HotTrackFont.Charset = DEFAULT_CHARSET
        HotTrackFont.Color = clWindowText
        HotTrackFont.Height = -11
        HotTrackFont.Name = 'Verdana'
        HotTrackFont.Style = []
      end
      object cbOutputDebugStringEvents: TJvCheckBox
        Left = 32
        Top = 184
        Width = 193
        Height = 17
        Caption = 'Win32 OutputDebugString API'
        TabOrder = 2
        LinkedControls = <>
        HotTrackFont.Charset = DEFAULT_CHARSET
        HotTrackFont.Color = clWindowText
        HotTrackFont.Height = -11
        HotTrackFont.Name = 'Verdana'
        HotTrackFont.Style = []
      end
      object cbProcessEvents: TJvCheckBox
        Left = 32
        Top = 112
        Width = 185
        Height = 17
        Caption = 'Process creation/termination'
        TabOrder = 3
        LinkedControls = <>
        HotTrackFont.Charset = DEFAULT_CHARSET
        HotTrackFont.Color = clWindowText
        HotTrackFont.Height = -11
        HotTrackFont.Name = 'Verdana'
        HotTrackFont.Style = []
      end
      object cbThreadEvents: TJvCheckBox
        Left = 32
        Top = 136
        Width = 187
        Height = 17
        Caption = 'Threads creation/termination'
        TabOrder = 4
        LinkedControls = <>
        HotTrackFont.Charset = DEFAULT_CHARSET
        HotTrackFont.Color = clWindowText
        HotTrackFont.Height = -11
        HotTrackFont.Name = 'Verdana'
        HotTrackFont.Style = []
      end
    end
    object pgTracing: TJvWizardInteriorPage
      Header.ParentFont = False
      Header.Title.Color = clNone
      Header.Title.Text = 'Tracing'
      Header.Title.Anchors = [akLeft, akTop, akRight]
      Header.Title.Font.Charset = DEFAULT_CHARSET
      Header.Title.Font.Color = clWindowText
      Header.Title.Font.Height = -16
      Header.Title.Font.Name = 'Verdana'
      Header.Title.Font.Style = [fsBold]
      Header.Subtitle.Color = clNone
      Header.Subtitle.Text = 
        #13#10'Define how many breakpoints you need to trace your application' +
        ' execution flow.'
      Header.Subtitle.Anchors = [akLeft, akTop, akRight, akBottom]
      Header.Subtitle.Font.Charset = DEFAULT_CHARSET
      Header.Subtitle.Font.Color = clWindowText
      Header.Subtitle.Font.Height = -11
      Header.Subtitle.Font.Name = 'Verdana'
      Header.Subtitle.Font.Style = []
      Panel.Color = clWindow
      Color = clWindow
      object lbModuleName: TLabel
        Left = 16
        Top = 116
        Width = 136
        Height = 13
        Caption = 'Module name (Exe/Dll):'
      end
      object lbSource: TLabel
        Left = 16
        Top = 140
        Width = 105
        Height = 13
        Caption = 'Source (Unit/File):'
      end
      object lbSymbol: TLabel
        Left = 16
        Top = 164
        Width = 124
        Height = 13
        Caption = 'Symbol (func./proc.):'
      end
      object lbBPName: TLabel
        Left = 16
        Top = 92
        Width = 98
        Height = 13
        Caption = 'Mnemonic name:'
      end
      object lvBreakpoints: TJvListView
        Left = 16
        Top = 232
        Width = 457
        Height = 137
        Columns = <
          item
            Caption = 'Mnemonic'
            Width = 100
          end
          item
            Caption = 'Module (Exe/Dll)'
            Width = 150
          end
          item
            Caption = 'Source (Unit/File)'
            Width = 150
          end
          item
            Caption = 'Symbol (func./proc.)'
            Width = 150
          end>
        ColumnClick = False
        GridLines = True
        HideSelection = False
        HotTrack = True
        ReadOnly = True
        RowSelect = True
        TabOrder = 4
        ViewStyle = vsReport
        ColumnsOrder = '0=100,1=150,2=150,3=150'
        Groups = <>
        ExtendedColumns = <
          item
          end
          item
          end
          item
          end
          item
          end>
      end
      object cbModuleName: TJvComboBox
        Left = 160
        Top = 112
        Width = 313
        Height = 21
        ItemHeight = 13
        Sorted = True
        TabOrder = 1
      end
      object cbSource: TJvComboBox
        Left = 160
        Top = 136
        Width = 313
        Height = 21
        ItemHeight = 13
        Sorted = True
        TabOrder = 2
      end
      object cbSymbol: TJvComboBox
        Left = 160
        Top = 160
        Width = 313
        Height = 21
        ItemHeight = 13
        Sorted = True
        TabOrder = 3
      end
      object btDeleteBP: TButton
        Left = 16
        Top = 192
        Width = 75
        Height = 25
        Action = acDeleteBP
        TabOrder = 5
      end
      object btAddBP: TButton
        Left = 398
        Top = 192
        Width = 75
        Height = 25
        Action = acAddBP
        TabOrder = 6
      end
      object edBPName: TJvEdit
        Left = 160
        Top = 88
        Width = 313
        Height = 21
        TabOrder = 0
      end
    end
    object pgExcProviders: TJvWizardInteriorPage
      Header.ParentFont = False
      Header.Title.Color = clNone
      Header.Title.Text = 'Exception providers'
      Header.Title.Anchors = [akLeft, akTop, akRight]
      Header.Title.Font.Charset = DEFAULT_CHARSET
      Header.Title.Font.Color = clWindowText
      Header.Title.Font.Height = -16
      Header.Title.Font.Name = 'Verdana'
      Header.Title.Font.Style = [fsBold]
      Header.Subtitle.Color = clNone
      Header.Subtitle.Text = 
        #13#10'Declare all the needed exception providers to better explain a' +
        'pplication exceptions.'
      Header.Subtitle.Anchors = [akLeft, akTop, akRight, akBottom]
      Header.Subtitle.Font.Charset = DEFAULT_CHARSET
      Header.Subtitle.Font.Color = clWindowText
      Header.Subtitle.Font.Height = -11
      Header.Subtitle.Font.Name = 'Verdana'
      Header.Subtitle.Font.Style = []
      Panel.Color = clWindow
      Color = clWindow
      object lvExcProviders: TJvListView
        Left = 16
        Top = 88
        Width = 457
        Height = 265
        Columns = <
          item
            Caption = 'Mnemonic description'
            Width = 200
          end
          item
            AutoSize = True
            Caption = 'Module (Dll)'
          end>
        ColumnClick = False
        GridLines = True
        HideSelection = False
        HotTrack = True
        ReadOnly = True
        RowSelect = True
        TabOrder = 0
        ViewStyle = vsReport
        ColumnsOrder = '0=200,1=253'
        Groups = <>
        ExtendedColumns = <
          item
          end
          item
          end>
      end
      object btAddExcProvider: TButton
        Left = 16
        Top = 364
        Width = 226
        Height = 25
        Action = acAddExcProvider
        TabOrder = 1
      end
      object btDelExcProvider: TButton
        Left = 247
        Top = 364
        Width = 226
        Height = 25
        Action = acDelExcProvider
        TabOrder = 2
      end
    end
    object pgSymProviders: TJvWizardInteriorPage
      Header.ParentFont = False
      Header.Title.Color = clNone
      Header.Title.Text = 'Symbol providers'
      Header.Title.Anchors = [akLeft, akTop, akRight]
      Header.Title.Font.Charset = DEFAULT_CHARSET
      Header.Title.Font.Color = clWindowText
      Header.Title.Font.Height = -16
      Header.Title.Font.Name = 'Verdana'
      Header.Title.Font.Style = [fsBold]
      Header.Subtitle.Color = clNone
      Header.Subtitle.Text = 
        #13#10'Declare all the needed symbol providers to get source code inf' +
        'ormations about exception and to correctly place tracing breakpo' +
        'ints.'
      Header.Subtitle.Anchors = [akLeft, akTop, akRight, akBottom]
      Header.Subtitle.Font.Charset = DEFAULT_CHARSET
      Header.Subtitle.Font.Color = clWindowText
      Header.Subtitle.Font.Height = -11
      Header.Subtitle.Font.Name = 'Verdana'
      Header.Subtitle.Font.Style = []
      Panel.Color = clWindow
      Color = clWindow
      object lvSymProviders: TJvListView
        Left = 16
        Top = 88
        Width = 457
        Height = 265
        Columns = <
          item
            Caption = 'Mnemonic description'
            Width = 200
          end
          item
            AutoSize = True
            Caption = 'Module (Dll)'
          end>
        ColumnClick = False
        GridLines = True
        HideSelection = False
        HotTrack = True
        ReadOnly = True
        RowSelect = True
        TabOrder = 0
        ViewStyle = vsReport
        ColumnsOrder = '0=200,1=253'
        Groups = <>
        ExtendedColumns = <
          item
          end
          item
          end>
      end
      object btAddSymProvider: TButton
        Left = 16
        Top = 364
        Width = 226
        Height = 25
        Action = acAddSymProvider
        TabOrder = 1
      end
      object btDelSymProvider: TButton
        Left = 247
        Top = 364
        Width = 226
        Height = 25
        Action = acDelSymProvider
        TabOrder = 2
      end
    end
    object pgSave: TJvWizardInteriorPage
      Header.ParentFont = False
      Header.Title.Color = clNone
      Header.Title.Text = 'Save configuration'
      Header.Title.Anchors = [akLeft, akTop, akRight]
      Header.Title.Font.Charset = DEFAULT_CHARSET
      Header.Title.Font.Color = clWindowText
      Header.Title.Font.Height = -16
      Header.Title.Font.Name = 'Verdana'
      Header.Title.Font.Style = [fsBold]
      Header.Subtitle.Color = clNone
      Header.Subtitle.Text = #13#10'Confirm saving of all the selected options.'
      Header.Subtitle.Anchors = [akLeft, akTop, akRight, akBottom]
      Header.Subtitle.Font.Charset = DEFAULT_CHARSET
      Header.Subtitle.Font.Color = clWindowText
      Header.Subtitle.Font.Height = -11
      Header.Subtitle.Font.Name = 'Verdana'
      Header.Subtitle.Font.Style = []
      Panel.Color = clWindow
      VisibleButtons = [bkBack, bkFinish, bkCancel]
      Color = clWindow
      object lbSave: TLabel
        Left = 16
        Top = 158
        Width = 457
        Height = 86
        Alignment = taCenter
        AutoSize = False
        Caption = 
          'The configuration process has been completed!'#13#10#13#10'Now hit on FINI' +
          'SH button to save your settings or'#13#10'hit on CANCEL to rollback an' +
          'y change.'#13#10#13#10'Good luck with Bug Finder!!!'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Verdana'
        Font.Style = [fsBold]
        ParentFont = False
        WordWrap = True
      end
    end
    object MapNodes: TJvWizardRouteMapNodes
      Left = 0
      Top = 0
      Width = 161
      Height = 401
      AllowClickableNodes = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
    end
  end
  object odSelectFile: TJvOpenDialog
    Filter = 'Configuration files (*.ini)|*.ini|All Files (*.*)|*.*'
    Options = [ofHideReadOnly, ofNoChangeDir, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Height = 0
    Width = 0
    Left = 72
    Top = 408
  end
  object odSelectApp: TJvOpenDialog
    Filter = 'Executable files (*.exe)|*.exe|All Files (*.*)|*.*'
    Options = [ofHideReadOnly, ofNoChangeDir, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Height = 0
    Width = 0
    Left = 40
    Top = 408
  end
  object ActionList: TActionList
    Left = 8
    Top = 408
    object acAddBP: TAction
      Category = 'Breakpoints'
      Caption = 'Add BP'
      OnExecute = acAddBPExecute
      OnUpdate = acAddBPUpdate
    end
    object acDeleteBP: TAction
      Category = 'Breakpoints'
      Caption = 'Delete BP'
      OnExecute = acDeleteBPExecute
      OnUpdate = acDeleteBPUpdate
    end
    object acAddExcProvider: TAction
      Category = 'ExceptionProviders'
      Caption = 'Add new exception provider'
      OnExecute = acAddExcProviderExecute
    end
    object acDelExcProvider: TAction
      Category = 'ExceptionProviders'
      Caption = 'Remove exception provider'
      OnExecute = acDelExcProviderExecute
      OnUpdate = acDelExcProviderUpdate
    end
    object acAddSymProvider: TAction
      Category = 'SymbolProviders'
      Caption = 'Add new symbol provider'
      OnExecute = acAddSymProviderExecute
    end
    object acDelSymProvider: TAction
      Category = 'SymbolProviders'
      Caption = 'Remove symbol provider'
      OnExecute = acDelSymProviderExecute
      OnUpdate = acDelSymProviderUpdate
    end
  end
  object odDll: TJvOpenDialog
    Filter = 'Extention library (*.dll)|*.dll|All Files (*.*)|*.*'
    Options = [ofHideReadOnly, ofNoChangeDir, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Height = 454
    Width = 563
    Left = 104
    Top = 408
  end
  object sdConfig: TJvSaveDialog
    Filter = 'Configuration files (*.ini)|*.ini|All Files (*.*)|*.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofNoChangeDir, ofPathMustExist, ofEnableSizing]
    Height = 419
    Width = 563
    Left = 136
    Top = 408
  end
end

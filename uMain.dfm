object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'BasePlayer'
  ClientHeight = 460
  ClientWidth = 721
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object lbl_Subtitle: TLabel
    Left = 0
    Top = 385
    Width = 721
    Height = 34
    Align = alBottom
    Alignment = taCenter
    AutoSize = False
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = #47569#51008' '#44256#46357
    Font.Style = [fsBold]
    ParentFont = False
    Layout = tlCenter
    WordWrap = True
    ExplicitLeft = 1
    ExplicitTop = 384
    ExplicitWidth = 719
  end
  object paControl: TPanel
    Left = 0
    Top = 419
    Width = 721
    Height = 41
    Align = alBottom
    TabOrder = 1
    DesignSize = (
      721
      41)
    object btnOpen: TButton
      Left = 6
      Top = 3
      Width = 57
      Height = 33
      Caption = #50676#44592
      TabOrder = 0
      OnClick = btnOpenClick
    end
    object btnPlay: TButton
      Left = 63
      Top = 3
      Width = 57
      Height = 33
      Caption = #51116#49373
      TabOrder = 1
      OnClick = btnPlayClick
    end
    object btnStop: TButton
      Left = 120
      Top = 3
      Width = 57
      Height = 33
      Caption = #51221#51648
      TabOrder = 2
      OnClick = btnStopClick
    end
    object TrackBar1: TTrackBar
      Left = 288
      Top = 6
      Width = 425
      Height = 41
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 3
      OnChange = TrackBar1Change
    end
    object btnUp: TButton
      Left = 177
      Top = 3
      Width = 57
      Height = 33
      Caption = 'Up'
      TabOrder = 4
      OnClick = btnUpClick
    end
    object btnDown: TButton
      Left = 235
      Top = 3
      Width = 57
      Height = 33
      Caption = 'Down'
      TabOrder = 5
      OnClick = btnDownClick
    end
  end
  object paScreen: TPanel
    Left = 0
    Top = 0
    Width = 721
    Height = 385
    Align = alClient
    Color = clBlack
    ParentBackground = False
    PopupMenu = PopupMenu1
    TabOrder = 0
  end
  object Timer1: TTimer
    OnTimer = Timer1Timer
    Left = 352
    Top = 232
  end
  object Timer_Subtitle: TTimer
    Enabled = False
    Interval = 100
    OnTimer = Timer_SubtitleTimer
    Left = 392
    Top = 232
  end
  object PopupMenu1: TPopupMenu
    AutoHotkeys = maManual
    Left = 432
    Top = 304
    object N1: TMenuItem
      Caption = #51204#52404#54868#47732
      OnClick = N1Click
    end
  end
end

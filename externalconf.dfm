object Form7: TForm7
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'External configuration'
  ClientHeight = 207
  ClientWidth = 428
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 160
    Top = 19
    Width = 31
    Height = 13
    Caption = 'Name:'
  end
  object Label2: TLabel
    Left = 160
    Top = 48
    Width = 73
    Height = 13
    Caption = 'Command Line:'
  end
  object Label3: TLabel
    Left = 159
    Top = 104
    Width = 257
    Height = 64
    Caption = 
      'External tools  can be called by the //! external preprocessor. ' +
      ' An //! external preprocessos found by jasshelper in the map scr' +
      'ipt  will make jasshelper run the properly configured tool after' +
      ' the usual compile process.'
    WordWrap = True
  end
  object ListBox1: TListBox
    Left = 8
    Top = 16
    Width = 145
    Height = 150
    ItemHeight = 13
    TabOrder = 0
    OnClick = ListBox1Click
  end
  object Button1: TButton
    Left = 8
    Top = 172
    Width = 73
    Height = 25
    Caption = 'Add'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 88
    Top = 172
    Width = 65
    Height = 25
    Caption = 'Remove'
    TabOrder = 2
    OnClick = Button2Click
  end
  object Edit1: TEdit
    Left = 197
    Top = 16
    Width = 221
    Height = 21
    TabOrder = 3
    OnChange = Edit1Change
  end
  object Edit2: TEdit
    Left = 159
    Top = 67
    Width = 234
    Height = 21
    TabOrder = 4
    OnChange = Edit2Change
  end
  object Button3: TButton
    Left = 297
    Top = 174
    Width = 57
    Height = 25
    Caption = 'OK'
    TabOrder = 5
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 360
    Top = 174
    Width = 57
    Height = 25
    Caption = 'Cancel'
    TabOrder = 6
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 392
    Top = 67
    Width = 25
    Height = 22
    Caption = '...'
    TabOrder = 7
    OnClick = Button5Click
  end
  object OpenDialog1: TOpenDialog
    Filter = 'Executable files|*.exe;*.bat;*.py;*.pl|All files|*.*'
    InitialDir = '.'
    Options = [ofEnableSizing]
    Title = 'Browse for external tool '
    Left = 368
    Top = 40
  end
end

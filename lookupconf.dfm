object Form6: TForm6
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Lookup folders'
  ClientHeight = 283
  ClientWidth = 380
  Color = clBtnFace
  Constraints.MaxHeight = 315
  Constraints.MaxWidth = 386
  Constraints.MinHeight = 315
  Constraints.MinWidth = 386
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 220
    Height = 13
    Caption = 'Separate each lookup folder with a line break.'
  end
  object Label2: TLabel
    Left = 8
    Top = 235
    Width = 305
    Height = 26
    Caption = 
      'Lookup folders are used by import, loaddata and external tools w' +
      'hen called with a relative path.'
    WordWrap = True
  end
  object Button1: TButton
    Left = 321
    Top = 214
    Width = 49
    Height = 25
    Caption = 'OK'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 321
    Top = 245
    Width = 49
    Height = 25
    Caption = 'Cancel'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 321
    Top = 32
    Width = 49
    Height = 25
    Caption = 'Add...'
    TabOrder = 2
    OnClick = Button3Click
  end
  object Memo1: TMemo
    Left = 8
    Top = 32
    Width = 307
    Height = 197
    ScrollBars = ssBoth
    TabOrder = 3
    WordWrap = False
  end
end

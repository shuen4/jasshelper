object Form4: TForm4
  Left = 0
  Top = 0
  Caption = 'Syntax Errors'
  ClientHeight = 420
  ClientWidth = 489
  Color = clBtnFace
  Constraints.MinHeight = 400
  Constraints.MinWidth = 400
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Icon.Data = {
    0000010001001010000001002000680400001600000028000000100000002000
    0000010020000000000040040000000000000000000000000000000000000000
    000000000015000000470000005E000000610000006600000069000000690000
    006900000069000000690000006900000062000000370000001B000000170000
    0000432510FF3F230FFF3C210EFF3C210EFF3C210EFF3C210EFF3C210EFF3C21
    0EFF3C210EFF3C210EFF3C210EFF3C210EFF3C210EFF3C210EFF000000190000
    000042240FFF06A152FF069E50FF069F51FF069F51FF069F51FF069F51FF069F
    51FF069F51FF069F51FF069F51FF069F51FF069F51FF3D210EFF000000180000
    000041240FFF06AF58FF05964CFF05964CFF05974CFF05974CFF05974CFF0597
    4CFF05974CFF05974CFF05964CFF05964CFF06A956FF40230FFF000000120000
    000042240FFF07B75DFF069A4EFF069A4EFFECEEEEFF069A4EFF069A4EFFECEE
    EEFFECEEEEFFECEEEEFFECEEEEFF05994DFF07AD58FF432510FF000000010000
    0000432510FF07B75DFF069A4EFF069A4EFFECEEEEFFECEEEEFF069A4EFF069A
    4EFFECEEEEFFECEEEEFF069A4EFF069A4EFF07AD58FF432510FF000000000000
    0000432510FF07B75DFF069A4EFF069A4EFFECEEEEFFECEEEEFFECEEEEFF069A
    4EFFECEEEEFFECEEEEFFECEEEEFF069A4EFF07AD58FF432510FF000000000000
    0000432510FF07B75DFF069A4EFF069A4EFFECEEEEFF069A4EFFECEEEEFFECEE
    EEFFECEEEEFF069A4EFFECEEEEFF069A4EFF07AD58FF432510FF000000000000
    0000432510FF07B75DFF069A4EFF069A4EFFECEEEEFF069A4EFF069A4EFFECEE
    EEFFECEEEEFF069A4EFF069A4EFF069A4EFF07AD58FF432510FF000000000000
    0000432510FF07B75DFF069A4EFFECEEEEFFECEEEEFF069A4EFF069A4EFFECEE
    EEFFECEEEEFF069A4EFF069A4EFF069A4EFF07AD58FF432510FF000000000000
    0000432510FF07B75DFF069A4EFFECEEEEFF069A4EFF069A4EFF069A4EFFECEE
    EEFFECEEEEFF069A4EFF069A4EFF069A4EFF07AD58FF432510FF000000000000
    0000432510FF07B75DFF069A4EFF069A4EFF069A4EFF069A4EFF069A4EFFECEE
    EEFFECEEEEFF069A4EFF069A4EFF069A4EFF07AD58FF432510FF000000000000
    0000432510FF07B75DFF069A4EFF069A4EFF069A4EFF069A4EFF069A4EFF069A
    4EFF069A4EFF069A4EFF069A4EFF069A4EFF07AD58FF432510FF000000000000
    0000432510FF07B75DFF07B75DFF07B75DFF07B75DFF07B75DFF07B75DFF07B7
    5DFF07B75DFF07B75DFF07B75DFF07B75DFF07B75DFF432510FF000000000000
    0000432510FF432510FF432510FF432510FF432510FF432510FF432510FF4325
    10FF432510FF432510FF432510FF432510FF432510FF432510FF000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000008000
    0000800000008000000080000000800100008001000080010000800100008001
    0000800100008001000080010000800100008001000080010000FFFF0000}
  OldCreateOrder = False
  OnKeyPress = Memo1KeyPress
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 31
    Height = 13
    Caption = 'Label1'
  end
  object Label2: TLabel
    Left = 8
    Top = 27
    Width = 31
    Height = 13
    Caption = 'Label2'
  end
  object Label3: TLabel
    Left = 8
    Top = 388
    Width = 26
    Height = 13
    Caption = 'Line: '
  end
  object Memo1: TMemo
    Left = 8
    Top = 139
    Width = 473
    Height = 241
    Color = clBtnFace
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier'
    Font.Style = []
    Lines.Strings = (
      'Memo1')
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 0
    WordWrap = False
    OnClick = Memo1Click
    OnKeyDown = Memo1KeyDown
    OnKeyPress = Memo1KeyPress
    OnKeyUp = Memo1KeyUp
  end
  object ListBox1: TListBox
    Left = 8
    Top = 48
    Width = 473
    Height = 85
    ItemHeight = 13
    TabOrder = 1
    OnClick = ListBox1Click
  end
  object Button1: TButton
    Left = 424
    Top = 386
    Width = 57
    Height = 26
    Caption = 'Ok'
    TabOrder = 2
    OnClick = Button1Click
  end
  object Edit1: TEdit
    Left = 40
    Top = 386
    Width = 57
    Height = 21
    BiDiMode = bdRightToLeft
    Color = clBtnFace
    ParentBiDiMode = False
    ReadOnly = True
    TabOrder = 3
    Text = 'Edit1'
  end
  object Button2: TButton
    Left = 345
    Top = 387
    Width = 73
    Height = 25
    Caption = 'About ...'
    TabOrder = 4
    OnClick = Button2Click
  end
  object SwitchEncodingButton: TButton
    Left = 250
    Top = 387
    Width = 90
    Height = 25
    Caption = 'Switch encoding'
    TabOrder = 5
    OnClick = SwitchEncoding
  end
end

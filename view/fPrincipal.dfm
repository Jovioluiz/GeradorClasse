object frmPrincipal: TfrmPrincipal
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Gerar Classe'
  ClientHeight = 225
  ClientWidth = 649
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 48
    Width = 37
    Height = 13
    Caption = 'Tabelas'
  end
  object Label2: TLabel
    Left = 16
    Top = 99
    Width = 41
    Height = 13
    Caption = 'Diret'#243'rio'
  end
  object SpeedButton1: TSpeedButton
    Left = 383
    Top = 96
    Width = 34
    Height = 21
    Caption = '...'
    OnClick = SpeedButton1Click
  end
  object btnConectarBanco: TButton
    Left = 496
    Top = 43
    Width = 105
    Height = 25
    Caption = 'Conectar Banco'
    TabOrder = 0
    OnClick = btnConectarBancoClick
  end
  object cbTabelas: TComboBox
    Left = 72
    Top = 45
    Width = 305
    Height = 21
    TabOrder = 1
  end
  object btnGerarClasse: TButton
    Left = 496
    Top = 94
    Width = 105
    Height = 25
    Caption = 'Gerar Classe'
    TabOrder = 2
    OnClick = btnGerarClasseClick
  end
  object edtDiretorio: TEdit
    Left = 72
    Top = 96
    Width = 305
    Height = 21
    TabOrder = 3
    Text = 'C:\Users\jovio\Desktop\Delphi'
  end
  object dialog: TOpenDialog
    Left = 416
    Top = 8
  end
end

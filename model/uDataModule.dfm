object dm: Tdm
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 89
  Width = 298
  object conexaoBanco: TFDConnection
    Params.Strings = (
      'Server='
      'Port='
      'DriverID=PG')
    Left = 32
    Top = 16
  end
  object driver: TFDPhysPgDriverLink
    VendorLib = 
      'C:\Users\jovio\Desktop\Delphi\GeradorClasse\Win32\Debug\lib\libp' +
      'q.dll'
    Left = 104
    Top = 16
  end
  object FDGUIxWaitCursor1: TFDGUIxWaitCursor
    Provider = 'Forms'
    ScreenCursor = gcrHourGlass
    Left = 208
    Top = 16
  end
end

program GeradorClasse;

uses
  Vcl.Forms,
  fPrincipal in 'view\fPrincipal.pas' {frmPrincipal},
  fConexao in 'model\fConexao.pas' {frmConexao},
  uDataModule in 'model\uDataModule.pas' {dm: TDataModule},
  uCarregaInformacoesBanco in 'model\uCarregaInformacoesBanco.pas',
  uManipuladorClasse in 'controller\uManipuladorClasse.pas';

{$R *.res}

begin
  Application.Initialize;
  ReportMemoryLeaksOnShutdown := True;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.CreateForm(TfrmConexao, frmConexao);
  Application.CreateForm(Tdm, dm);
  Application.Run;
end.

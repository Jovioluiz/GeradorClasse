unit fPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, uCarregaInformacoesBanco,
  uManipuladorClasse, Vcl.Buttons, FileCtrl;

type
  TfrmPrincipal = class(TForm)
    Label1: TLabel;
    btnConectarBanco: TButton;
    cbTabelas: TComboBox;
    btnGerarClasse: TButton;
    dialog: TOpenDialog;
    edtDiretorio: TEdit;
    Label2: TLabel;
    SpeedButton1: TSpeedButton;
    procedure btnConectarBancoClick(Sender: TObject);
    procedure btnGerarClasseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
  private
    FDadosBanco: TCarregaInformacoesBanco;
    { Private declarations }
    procedure ConectarBanco;
    procedure CarregaTabelas;
    procedure SetDadosBanco(const Value: TCarregaInformacoesBanco);
    procedure GerarClasse;
  public
    { Public declarations }
    property DadosBanco: TCarregaInformacoesBanco read FDadosBanco write SetDadosBanco;
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

uses
  fConexao, System.Generics.Collections;

{$R *.dfm}

procedure TfrmPrincipal.btnConectarBancoClick(Sender: TObject);
begin
  ConectarBanco;
  CarregaTabelas;
end;

procedure TfrmPrincipal.btnGerarClasseClick(Sender: TObject);
begin
  if cbTabelas.Items.Count <= 0 then
    raise Exception.Create('Conecte ao banco e selecione uma tabela!');
  GerarClasse;
end;

procedure TfrmPrincipal.CarregaTabelas;
var
  listaTabelas: TList<String>;
begin
  listaTabelas := TList<String>.Create;

  try
    listaTabelas := FDadosBanco.CarregaTabelas;

    for var tab in listaTabelas do
      cbTabelas.Items.Add(tab);

    cbTabelas.ItemIndex := 0;
  finally
    listaTabelas.Free;
  end;
end;

procedure TfrmPrincipal.ConectarBanco;
var
  conexao: TfrmConexao;
begin
  conexao := TfrmConexao.Create(Self);

  try
    conexao.ShowModal;
  finally
    conexao.Free;
  end;
end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  FDadosBanco := TCarregaInformacoesBanco.Create;
end;

procedure TfrmPrincipal.FormDestroy(Sender: TObject);
begin
  FDadosBanco.Free;
end;

procedure TfrmPrincipal.GerarClasse;
var
  geraClasse: TManipuladorClasse;
begin
  geraClasse := TManipuladorClasse.Create(edtDiretorio.Text);

  try
    geraClasse.GerarClasse(cbTabelas.Text);
  finally
    geraClasse.Free;
  end;
end;

procedure TfrmPrincipal.SetDadosBanco(const Value: TCarregaInformacoesBanco);
begin
  FDadosBanco := Value;
end;

procedure TfrmPrincipal.SpeedButton1Click(Sender: TObject);
var
  dir: string;
begin
  if SelectDirectory(ExtractFilePath(dialog.FileName), 'C:\', dir) then
    edtDiretorio.Text := dir;

//  if dialog.Execute then
//    edtDiretorio.Text := dialog.FileName;
end;

end.

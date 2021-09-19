unit fPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, uCarregaInformacoesBanco,
  uManipuladorClasse, Vcl.Buttons;

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
var
  geraClasse: TManipuladorClasse;
  dadosTabela: TDictionary<string, string>;
begin
  geraClasse := TManipuladorClasse.Create(edtDiretorio.Text);
  dadosTabela := TDictionary<string, string>.Create;

  try
    dadosTabela := FDadosBanco.CarregaDadosTabela(cbTabelas.Text);
    geraClasse.CriaClasse(cbTabelas.Text, dadosTabela);
  finally
    geraClasse.Free;
    dadosTabela.Free;
  end;
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

procedure TfrmPrincipal.SetDadosBanco(const Value: TCarregaInformacoesBanco);
begin
  FDadosBanco := Value;
end;

procedure TfrmPrincipal.SpeedButton1Click(Sender: TObject);
begin
  if dialog.Execute then
    edtDiretorio.Text := dialog.FileName;
end;

end.

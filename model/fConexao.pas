unit fConexao;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.IniFiles, Vcl.Mask;

type
  TfrmConexao = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    edtServidor: TEdit;
    edtBanco: TEdit;
    edtPorta: TEdit;
    edtUsuario: TEdit;
    btnTestar: TButton;
    btnSalvar: TButton;
    edtSenha: TMaskEdit;
    memo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure btnTestarClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
  private
    { Private declarations }
    FArquivoIni: TIniFile;
    procedure Salvar;
  public
    { Public declarations }
  end;

var
  frmConexao: TfrmConexao;

implementation

uses
  uDataModule;

{$R *.dfm}

procedure TfrmConexao.btnSalvarClick(Sender: TObject);
begin
  Salvar;
end;

procedure TfrmConexao.btnTestarClick(Sender: TObject);
var
  msg: string;
begin
  memo.Clear;
  try
    dm.conexaoBanco.Params.Values['Server'] := edtServidor.Text;
    dm.conexaoBanco.Params.Database := edtBanco.Text;
    dm.conexaoBanco.Params.UserName := edtUsuario.Text;
    dm.conexaoBanco.Params.Password := EdtSenha.Text;
    dm.conexaoBanco.Params.Values['Port'] := edtPorta.Text;

    dm.conexaoBanco.Connected := True;
    if dm.conexaoBanco.Connected then
    begin
      memo.Lines.Add('Conexão OK');
      btnSalvar.Enabled := True;
    end;
  except
    on e:Exception do
    begin
      msg := 'Erro ao conectar no banco de dados ' + edtBanco.Text + e.Message;
      memo.Lines.Add(msg);
    end;
  end;
end;

procedure TfrmConexao.FormCreate(Sender: TObject);
begin
  FArquivoIni := TIniFile.Create(GetCurrentDir + '\conexao\conexao.ini');

  edtServidor.Text := FArquivoIni.ReadString('configuracoes', 'servidor', '');
  edtBanco.Text := FArquivoIni.ReadString('configuracoes', 'banco', '');
  edtPorta.Text := FArquivoIni.ReadString('configuracoes', 'porta', '');
  edtUsuario.Text := FArquivoIni.ReadString('configuracoes', 'usuario', '');
  EdtSenha.Text := FArquivoIni.ReadString('configuracoes', 'senha', '');
end;

procedure TfrmConexao.FormDestroy(Sender: TObject);
begin
  FArquivoIni.Free;
end;

procedure TfrmConexao.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    Perform(WM_NEXTDLGCTL, 0, 0)
  end;
end;

procedure TfrmConexao.Salvar;
begin
  FArquivoIni.WriteString('configuracoes', 'servidor', edtServidor.Text);
  FArquivoIni.WriteString('configuracoes', 'banco', edtBanco.Text);
  FArquivoIni.WriteString('configuracoes', 'porta', edtPorta.Text);
  FArquivoIni.WriteString('configuracoes', 'usuario', edtUsuario.Text);
  FArquivoIni.WriteString('configuracoes', 'senha', edtSenha.Text);
  memo.Clear;
  memo.Lines.Add('Salvo!');
  btnSalvar.Enabled := False;
end;

end.

unit uManipuladorClasse;

interface

uses
  System.Generics.Collections, uCarregaInformacoesBanco;

type TManipuladorClasse = class(TCarregaInformacoesBanco)
  private
    FCaminho: String;
    FNomeClasse: String;
    function RetornaMaiuscula(vStr: String): string;
    function RetornaTipoCampo(NomeTipoCampo: string): String;
    function RetornaTipoCampoParametros(NomeTipoCampo: string): String;
    function FormataStringUpdate(NomeTabela, Pk: string): string;
    function FormataParametros(NomeTabela: string): string;

  public
    procedure CriaClasse(NomeTabela: string; DadosTabela: TDictionary<string, string>);
    function FormataStringInsert(NomeTabela: string): string;
    constructor Create(Caminho: string);
    destructor Destroy; override;
end;

implementation

uses
  Vcl.Dialogs, System.Classes, System.SysUtils, System.StrUtils;

{ TManipuladorClasse }

constructor TManipuladorClasse.Create(Caminho: string);
begin
  FCaminho := Caminho;
end;

procedure TManipuladorClasse.CriaClasse(NomeTabela: string; DadosTabela: TDictionary<string, string>);
var
  arquivo: TextFile;
  nomeArquivo,
  nome,
  insert,
  update: string;
  pkTabela: TDadosPkTabela;
  dados: TCarregaInformacoesBanco;
  FNomeMetodosPublicos: TList<string>;
begin
  dados := TCarregaInformacoesBanco.Create;
  FNomeMetodosPublicos := TList<string>.Create;

  try

    nome := RetornaMaiuscula(NomeTabela);
    nomeArquivo := FCaminho + '\' + 'u' + nome + '.pas';
    FNomeClasse := 'T' + nome;

    AssignFile(arquivo, nomeArquivo);
    Rewrite(arquivo);

    Write(arquivo, 'unit ' + 'u' + nome + ';');
    Writeln(arquivo);
    Writeln(arquivo);
    Write(arquivo, 'interface');
    Writeln(arquivo);
    Writeln(arquivo);
    Write(arquivo, 'uses');
    Writeln(arquivo);
    Writeln(arquivo);
    Write(arquivo, 'type ' + FNomeClasse + ' = class ');
    Writeln(arquivo);
    Writeln(arquivo);

    Write(arquivo, '  private ');
    Writeln(arquivo);

    //monta os fields
    for var colunas in DadosTabela do
    begin
      Write(arquivo, '    ');
      Write(arquivo, 'F' + colunas.Key + ': ' + RetornaTipoCampo(colunas.Value) + ';');

      Writeln(arquivo);
    end;

    //métodos Sets
    for var colunas in DadosTabela do
    begin
      Write(arquivo, '    ');
      Write(arquivo, 'Set' + colunas.Key + '(' + 'const Value: ' + RetornaTipoCampo(colunas.Value) + ');');
      Writeln(arquivo);
    end;

    pkTabela := dados.GetPKTabela(NomeTabela);

    Write(arquivo, '  public ');
    Writeln(arquivo);

    //método pesquisar pela pk
    if pkTabela.NomeColunaPk <> '' then
    begin
      Write(arquivo, '    ');
      Write(arquivo, 'function Pesquisar(' + pkTabela.NomeColunaPk + ': ' + RetornaTipoCampo(pkTabela.TipoPk) + ');');
      FNomeMetodosPublicos.Add('Pesquisar');
    end;

    Writeln(arquivo);
    Write(arquivo, '    ');
    Write(arquivo, 'procedure Inserir;');
    FNomeMetodosPublicos.Add('Inserir');
    Writeln(arquivo);
    Write(arquivo, '    ');
    Write(arquivo, 'procedure Atualizar;');
    FNomeMetodosPublicos.Add('Atualizar');
    Writeln(arquivo);
    Write(arquivo, '    ');
    Write(arquivo, 'procedure Excluir;');
    FNomeMetodosPublicos.Add('Excluir');
    Writeln(arquivo);
    Writeln(arquivo);

    //monta as property
    for var colunas in DadosTabela do
    begin
      Write(arquivo, '    ');
      Write(arquivo, 'property ' + colunas.Key + ': ' + RetornaTipoCampo(colunas.Value) + ' read ' + 'F' + colunas.Key + ' write ' + 'Set' + colunas.Key + ';');
      Writeln(arquivo);
    end;

    Writeln(arquivo);
    Write(arquivo, 'end;');
    Writeln(arquivo);
    Writeln(arquivo);
    Write(arquivo, 'implementation');
    Writeln(arquivo);
    Writeln(arquivo);
    Write(arquivo, 'uses');
    Writeln(arquivo);
    Write(arquivo, '    ');
    Write(arquivo, 'System.SysUtils, Vcl.Dialogs;');
    Writeln(arquivo);
    Writeln(arquivo);
    Write(arquivo, '{ ' + FNomeClasse + ' }');
    Writeln(arquivo);
    Writeln(arquivo);

    insert := FormataStringInsert(NomeTabela);
    Write(arquivo, insert);
    Writeln(arquivo);
    update := FormataStringUpdate(NomeTabela, pkTabela.NomeColunaPk);
    Write(arquivo, update);
    CloseFile(arquivo);

  finally
    dados.Free;
    FNomeMetodosPublicos.Free;
  end;
end;

function TManipuladorClasse.FormataStringInsert(NomeTabela: string): string;
var
  colunasTabela: TArray<TColunasTabela>;
begin
  Result := 'procedure ' + FNomeClasse + '.' + 'Inserir' + ';' + #13
            + 'const'  + #13
            + '   '
            + 'SQL = '  + #13
            + '   '
            + '''' + 'insert into ' + '''' + ' +'  + #13
            + '   '
            + '''' + NomeTabela + '(' + '''' + ' +' + #13;

  colunasTabela := GetColunasTabela(NomeTabela);

  for var I := 0 to Length(colunasTabela) - 1 do
  begin
    Result := Result + '' + '' + '' + '   ';
    Result := Result + '''' + ifthen(I = High(colunasTabela), colunasTabela[I].NomeColuna + ')', colunasTabela[I].NomeColuna + ', ')  + '''' + ' +' + #13
  end;

  Result := Result + '   ' + '''' + 'values ' + '(' + '''' + ' +';
  for var I := 0 to Length(colunasTabela) - 1 do
  begin
    Result := Result + '' + '' + '' + #13;
    Result := Result + '   ' + '''' + ifthen(I = High(colunasTabela), ':' + colunasTabela[I].NomeColuna + ')' + '''' + ';',
                                                                      ':' + colunasTabela[I].NomeColuna + ', ' + '''' + ' +');
  end;

  Result := Result + FormataParametros(NomeTabela);
end;

function TManipuladorClasse.FormataParametros(NomeTabela: string): string;
var
  colunasTabela: TArray<TColunasTabela>;
begin

  colunasTabela := GetColunasTabela(NomeTabela);
  Result := Result + #13;
  Result := Result + 'var' + #13;
  Result := Result + '  query: TFDquery;' + #13;
  Result := Result + 'begin' + #13;
  Result := Result + '  query := TFDquery.Create(nil);' + #13;
  Result := Result + '  query.Connection := dm.conexaoBanco;' + #13;
  Result := Result + '  dm.conexaoBanco.StartTransaction;' + #13;
  Result := Result + '  query.SQL.Add(SQL);' + #13;
  Result := Result + '  try' + #13;
  Result := Result + '    try' + #13;

  for var I := 0 to Length(colunasTabela) - 1 do
  begin
    Result := Result + '      query.ParamByName(''' + colunasTabela[I].NomeColuna + ''').'
              + RetornaTipoCampoParametros(colunasTabela[I].typeColuna) + ' := ' + 'F' + colunasTabela[I].NomeColuna + ';' + #13;
  end;

  Result := Result + '      query.ExecSQL;' + #13;
  Result := Result + '      dm.conexaoBanco.Commit;' + #13;
  Result := Result + '    except' + #13;
  Result := Result + '    on E:exception do' + #13;
  Result := Result + '      begin' + #13;
  Result := Result + '        dm.conexaoBanco.Rollback;' + #13;
  Result := Result + '        raise Exception.Create(''Erro ao gravar os dados na tabela ' + NomeTabela + '''' + ' + ' + ' E.Message' + ');' + #13;
  Result := Result + '      end;' + #13;
  Result := Result + '    end;' + #13;
  Result := Result + '  finally' + #13;
  Result := Result + '    dm.conexaoBanco.Rollback;' + #13;
  Result := Result + '    qry.Free;' + #13;
  Result := Result + '  end;' + #13;
  Result := Result + 'end;' + #13;

end;

function TManipuladorClasse.FormataStringUpdate(NomeTabela, Pk: string): string;
var
  colunasTabela: TArray<TColunasTabela>;
begin
  Result := 'procedure ' + FNomeClasse + '.' + 'Atualizar' + ';' + #13
            + 'const'  + #13
            + '   '
            + 'SQL = '  + #13
            + '   '
            + '''' + 'update ' + '''' + ' +'  + #13
            + '   '
            + '''' + NomeTabela + '''' + ' +' + #13
            + '''' + 'set ' + '''' + ' +' + #13;

  colunasTabela := GetColunasTabela(NomeTabela);

  for var I := 0 to Length(colunasTabela) - 1 do
  begin
    Result := Result + '' + '' + '' + '   ';
    Result := Result + '''' + colunasTabela[I].NomeColuna + ' = ' + ':' + colunasTabela[I].NomeColuna + '''' + ' +' + #13;
  end;

  Result := Result + '''' + 'where ' + '''' + ' +' + #13;
  Result := Result + '''' + Pk + ' = :' + Pk + '''' + ';' + #13;

  Result := Result + FormataParametros(NomeTabela);
end;

destructor TManipuladorClasse.Destroy;
begin
  FCaminho := '';
  inherited;
end;

function TManipuladorClasse.RetornaMaiuscula(vStr: String): string;
begin
  vStr := LowerCase(vStr);
  Result := UpperCase(Copy(vStr, 1, 1)) + Copy(vStr, 2, length(vStr) -1);
end;

function TManipuladorClasse.RetornaTipoCampo(NomeTipoCampo: string): String;
var
  tipoCampo: string;
begin
  if AnsiContainsStr(NomeTipoCampo, 'bigint') then
    tipoCampo := 'Int64'
  else if AnsiContainsStr(NomeTipoCampo, 'numeric') then
    tipoCampo := 'Currency'
  else if AnsiContainsStr(NomeTipoCampo, 'double') then
    tipoCampo := 'Double'
  else if AnsiContainsStr(NomeTipoCampo, 'timestamp') then
    tipoCampo := 'TDateTime'
  else if AnsiContainsStr(NomeTipoCampo, 'date') then
    tipoCampo := 'TDate'
  else if (AnsiContainsStr(NomeTipoCampo, 'character')) or (AnsiContainsStr(NomeTipoCampo, 'text')) then
    tipoCampo := 'String'
  else if (AnsiContainsStr(NomeTipoCampo, 'smallint')) or (AnsiContainsStr(NomeTipoCampo, 'integer')) then
    tipoCampo := 'Integer'
  else if AnsiContainsStr(NomeTipoCampo, 'bytea') then
    tipoCampo := 'TBytes'
  else if AnsiContainsStr(NomeTipoCampo, 'boolean') then
    tipoCampo := 'Boolean';

  Result := tipoCampo;
end;

function TManipuladorClasse.RetornaTipoCampoParametros(NomeTipoCampo: string): String;
var
  tipoCampo: string;
begin
  if AnsiContainsStr(NomeTipoCampo, 'bigint') then
    tipoCampo := 'AsLargeInt'
  else if AnsiContainsStr(NomeTipoCampo, 'numeric') then
    tipoCampo := 'AsCurrency'
  else if AnsiContainsStr(NomeTipoCampo, 'double') then
    tipoCampo := 'AsFloat'
  else if AnsiContainsStr(NomeTipoCampo, 'timestamp') then
    tipoCampo := 'AsDateTime'
  else if AnsiContainsStr(NomeTipoCampo, 'date') then
    tipoCampo := 'AsDate'
  else if (AnsiContainsStr(NomeTipoCampo, 'character')) or (AnsiContainsStr(NomeTipoCampo, 'text')) then
    tipoCampo := 'AsString'
  else if (AnsiContainsStr(NomeTipoCampo, 'smallint')) or (AnsiContainsStr(NomeTipoCampo, 'integer')) then
    tipoCampo := 'AsInteger'
  else if AnsiContainsStr(NomeTipoCampo, 'bytea') then
    tipoCampo := 'AsBytes'
  else if AnsiContainsStr(NomeTipoCampo, 'boolean') then
    tipoCampo := 'AsBoolean';

  Result := tipoCampo;
end;

end.

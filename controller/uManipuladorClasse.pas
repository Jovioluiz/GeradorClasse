unit uManipuladorClasse;

interface

uses
  System.Generics.Collections, uCarregaInformacoesBanco;

type TManipuladorClasse = class(TCarregaInformacoesBanco)
  private
    FCaminho: String;
    FNomeClasse: String;
    function RetornaMaiuscula(Str: String): string;
    function RetornaTipoCampo(NomeTipoCampo: string): String;
    function RetornaTipoCampoParametros(NomeTipoCampo: string): String;
    function FormataStringUpdate(NomeTabela, Pk: string): string;
    function FormataParametros(NomeTabela: string): string;
    function FormataStringPesquisar(NomeTabela, NomePk, TipoPk: string): string;
    function FormataParametrosPesquisar(NomeTabela, NomePk: string): string;

  public
    procedure CriaClasse(NomeTabela: string);
    function FormataStringInsert(NomeTabela: string): string;
    procedure GerarClasse(NomeTabela: string);
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

procedure TManipuladorClasse.CriaClasse(NomeTabela: string);
var
  arquivo: TextFile;
  nomeArquivo,
  nome,
  insert,
  update: string;
  pkTabela: TDadosPkTabela;
  dados: TCarregaInformacoesBanco;
  FNomeMetodosPublicos: TList<string>;
  DadosTabela: TArray<TColunasTabela>;
begin
  dados := TCarregaInformacoesBanco.Create;
  FNomeMetodosPublicos := TList<string>.Create;

  try
    DadosTabela := dados.GetColunasTabela(NomeTabela);
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
    Write(arquivo, ' FireDAC.Stan.Intf, FireDAC.Stan.Option, ' + #13 +
                   ' FireDAC.Stan.Error, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.Phys.Intf,   ' + #13 +
                   ' FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.Comp.Client, FireDAC.DApt,  ' + #13 +
                   ' FireDAC.Comp.DataSet, Data.DB;');
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
      Write(arquivo, 'F' + colunas.NomeColuna + ': ' + RetornaTipoCampo(colunas.typeColuna) + ';');
      Writeln(arquivo);
    end;

    //métodos Sets
    for var colunas in DadosTabela do
    begin
      Write(arquivo, '    ');
      Write(arquivo, 'procedure Set' + colunas.NomeColuna + '(' + 'const Value: ' + RetornaTipoCampo(colunas.typeColuna) + ');');
      Writeln(arquivo);
    end;

    pkTabela := dados.GetPKTabela(NomeTabela);

    Write(arquivo, '  public ');
    Writeln(arquivo);

    //método pesquisar pela pk
    if pkTabela.NomeColunaPk <> '' then
    begin
      Write(arquivo, '   //Metodo Pesquisar pela chave primaria');
      Writeln(arquivo);
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
      Write(arquivo, 'property ' + colunas.NomeColuna + ': ' + RetornaTipoCampo(colunas.typeColuna) + ' read ' + 'F' + colunas.NomeColuna + ' write ' + 'Set' + colunas.typeColuna + ';');
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
    Write(arquivo, 'uDataModule, System.SysUtils, Vcl.Dialogs;');
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

    if pkTabela.NomeColunaPk <> '' then
    begin
      Writeln(arquivo);
      Write(arquivo, FormataStringPesquisar(NomeTabela, pkTabela.NomeColunaPk, pkTabela.TipoPk));
      Writeln(arquivo);
    end;

    Write(arquivo, 'end.');
    CloseFile(arquivo);

  finally
    dados.Free;
    FNomeMetodosPublicos.Free;
  end;
end;

function TManipuladorClasse.FormataStringPesquisar(NomeTabela, NomePk, TipoPk: string): string;
begin
  Result := 'function ' + FNomeClasse +'.Pesquisar(' + NomePk + ': ' + RetornaTipoCampo(TipoPk) + ');' + #13
            + 'const'  + #13
            + '   '
            + ' SQL = ' + #13
            + '   ' + '''' + 'SELECT * ' + '''' + ' +' + #13
            + '   ' + '''' + ' FROM ' + '''' + ' +' + #13
            + '   ' + '''' + NomeTabela + '''' + ' +' + #13
            + '   ' + '''' + ' WHERE ' + '''' + ' +' + #13
            + '   ' + '''' + NomePk + ' = ' + ':' + NomePk + '''' + ';';

  Result := Result + FormataParametrosPesquisar(NomeTabela, NomePk);
end;

function TManipuladorClasse.FormataParametrosPesquisar(NomeTabela, NomePk: string): string;
begin
  Result := #13;
  Result := Result + 'var' + #13;
  Result := Result + '  query: TFDquery;' + #13;
  Result := Result + 'begin' + #13;
  Result := Result + '  query := TFDquery.Create(nil);' + #13;
  Result := Result + '  query.Connection := dm.conexaoBanco;' + #13 + #13;
  Result := Result + '  try' + #13;
  Result := Result + '    query.Open(SQL, [' + NomePk + ']);' + #13;
  Result := Result + '    Result := not query.IsEmpty;' + #13;
  Result := Result + '  finally' + #13;
  Result := Result + '    qry.Free;' + #13;
  Result := Result + '  end;' + #13;
  Result := Result + 'end;';
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
            + '''' + 'INSERT INTO ' + '''' + ' +'  + #13
            + '   '
            + '''' + NomeTabela + '(' + '''' + ' +' + #13;

  colunasTabela := GetColunasTabela(NomeTabela);

  for var I := 0 to Length(colunasTabela) - 1 do
  begin
    Result := Result + '' + '' + '' + '   ';
    Result := Result + '''' + ifthen(I = High(colunasTabela), colunasTabela[I].NomeColuna + ')', colunasTabela[I].NomeColuna + ', ')  + '''' + ' +' + #13
  end;

  Result := Result + '   ' + '''' + 'VALUES ' + '(' + '''' + ' +';
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
            + '''' + 'UPDATE ' + '''' + ' +'  + #13
            + '   '
            + '''' + NomeTabela + '''' + ' +' + #13
            + '''' + 'SET ' + '''' + ' +' + #13;

  colunasTabela := GetColunasTabela(NomeTabela);

  for var I := 0 to Length(colunasTabela) - 1 do
  begin
    Result := Result + '' + '' + '' + '   ';
    Result := Result + '''' + colunasTabela[I].NomeColuna + ' = ' + ':' + colunasTabela[I].NomeColuna + '''' + ' +' + #13;
  end;

  Result := Result + '''' + 'WHERE ' + '''' + ' +' + #13;
  Result := Result + '''' + Pk + ' = :' + Pk + '''' + ';' + #13;

  Result := Result + FormataParametros(NomeTabela);
end;

procedure TManipuladorClasse.GerarClasse(NomeTabela: string);
begin
  CriaClasse(NomeTabela);
end;

destructor TManipuladorClasse.Destroy;
begin
  FCaminho := '';
  inherited;
end;

function TManipuladorClasse.RetornaMaiuscula(Str: String): string;
begin
  Str := LowerCase(Str);
  Result := UpperCase(Copy(Str, 1, 1)) + Copy(Str, 2, length(Str) -1);
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

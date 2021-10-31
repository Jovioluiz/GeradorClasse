unit uManipuladorClasse;

interface

uses
  System.Generics.Collections, uCarregaInformacoesBanco;

type TManipuladorClasse = class(TCarregaInformacoesBanco)

  type TDadosUnique = record
    nome,
    tipo: string;
  end;

  private
    FCaminho: String;
    FNomeClasse: String;
    FManipuladorInfo: TCarregaInformacoesBanco;
    function RetornaMaiuscula(Str: String): string;
    function RetornaTipoCampo(NomeTipoCampo: string): String;
    function RetornaTipoCampoParametros(NomeTipoCampo: string): String;
    function FormataStringUpdate(NomeTabela, Pk: string): string;
    function FormataParametros(NomeTabela: string): string;
    function FormataStringPesquisar(NomeTabela, NomePk, TipoPk: string): string; overload;
    function FormataStringPesquisar(NomeTabela: string; DadosUnk: TArray<TDadosUnique>): string; overload;
    function FormataParametrosPesquisar(NomeTabela, NomePk: string; EhPK: Boolean): string;
    function FormataStringDelete(NomeTabela, Pk, TipoPk: string): string;
    function FormataMetodosSets(NomeTabela: string): string;
    procedure SetManipuladorInfo(const Value: TCarregaInformacoesBanco);
  public
    procedure CriaClasse(NomeTabela: string);
    function FormataStringInsert(NomeTabela: string): string;
    procedure GerarClasse(NomeTabela: string);
    constructor Create(Caminho: string);
    destructor Destroy; override;

    property ManipuladorInfo: TCarregaInformacoesBanco read FManipuladorInfo write SetManipuladorInfo;
end;

implementation

uses
  Vcl.Dialogs, System.Classes, System.SysUtils, System.StrUtils;

{ TManipuladorClasse }

constructor TManipuladorClasse.Create(Caminho: string);
begin
  FCaminho := Caminho;
  FManipuladorInfo := TCarregaInformacoesBanco.Create;
end;

procedure TManipuladorClasse.CriaClasse(NomeTabela: string);
var
  arquivo: TextFile;
  nomeArquivo,
  nome,
  s: string;
  pkTabela: TDadosPkTabela;
  uniqueTabela: TArray<TDadosPkUniqueTabela>;
  FNomeMetodosPublicos: TList<string>;
  dadosTabela: TArray<TColunasTabela>;
begin
  FNomeMetodosPublicos := TList<string>.Create;

  try
    try

      dadosTabela := FManipuladorInfo.GetColunasTabela(NomeTabela);
      nome := RetornaMaiuscula(NomeTabela);
      nomeArquivo := FCaminho + '\ucl' + nome + '.pas';
      FNomeClasse := 'T' + nome;

      AssignFile(arquivo, nomeArquivo);
      Rewrite(arquivo);

      Write(arquivo, 'unit ' + 'ucl' + nome + ';');
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
      for var colunas in dadosTabela do
      begin
        Write(arquivo, '    ');
        Write(arquivo, 'F' + colunas.NomeColuna + ': ' + RetornaTipoCampo(colunas.typeColuna) + ';');
        Writeln(arquivo);
      end;

      //métodos Sets
      for var colunas in dadosTabela do
      begin
        Write(arquivo, '    ');
        Write(arquivo, 'procedure Set' + colunas.NomeColuna + '(' + 'const Value: ' + RetornaTipoCampo(colunas.typeColuna) + ');');
        Writeln(arquivo);
      end;

      pkTabela := FManipuladorInfo.GetPKTabela(NomeTabela);
      uniqueTabela := FManipuladorInfo.GetUniqueTabelas(NomeTabela);
      Write(arquivo, '  public ');
      Writeln(arquivo);

      //método pesquisar pela pk
      if (pkTabela.NomeColunaPk = '') and (not Assigned(uniqueTabela)) then
        raise Exception.Create('A tabela ' + NomeTabela + ' não possui PK. Verifique.');
      
      if pkTabela.NomeColunaPk <> '' then
      begin
        Write(arquivo, '   //Metodo Pesquisar pela chave primaria');
        Writeln(arquivo);
        Write(arquivo, '    ');
        Write(arquivo, 'function Pesquisar(' + pkTabela.NomeColunaPk + ': ' + RetornaTipoCampo(pkTabela.TipoPk) + '): Boolean; ' + ifthen(Assigned(uniqueTabela), ' overload;', ''));
        FNomeMetodosPublicos.Add('Pesquisar');
      end;
    
      if Assigned(uniqueTabela) then
      begin
        Writeln(arquivo);
        Write(arquivo, '   //Metodo Pesquisar pelas unique');
        Writeln(arquivo);
        Write(arquivo, '    ');
        var str := 'function Pesquisar(' ;
        var primeiro := uniqueTabela[0].TipoUnique;
        for var I := 0 to Length(uniqueTabela) - 1 do
        begin
          s := s + uniqueTabela[I].NomeColunaUnique + ': ' + ifthen(I = High(uniqueTabela), RetornaTipoCampo(uniqueTabela[I].TipoUnique) + '): Boolean; ',
                                                                                            RetornaTipoCampo(uniqueTabela[I].TipoUnique) + '; ');
          primeiro := uniqueTabela[I].TipoUnique;
        end;
        if pkTabela.NomeColunaPk <> '' then
          s := s + ' overload;';
        
        Write(arquivo, str + s);
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
      for var colunas in dadosTabela do
      begin
        Write(arquivo, '    ');
        Write(arquivo, 'property ' + colunas.NomeColuna + ': ' + RetornaTipoCampo(colunas.typeColuna) + ' read '
                       + 'F' + colunas.NomeColuna + ' write ' + 'Set' + colunas.NomeColuna + ';');
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

      //metodo insert
      Write(arquivo, FormataStringInsert(NomeTabela));
      Writeln(arquivo);
      //metodo update
      Write(arquivo, FormataStringUpdate(NomeTabela, pkTabela.NomeColunaPk));

      //metodo pesquisar pela pk
      if pkTabela.NomeColunaPk <> '' then
      begin
        Writeln(arquivo);
        Write(arquivo, FormataStringPesquisar(NomeTabela, pkTabela.NomeColunaPk, pkTabela.TipoPk));
        Writeln(arquivo);
      end;

      if Assigned(uniqueTabela) then
      begin
        var dadosUnique: TArray<TDadosUnique>;
        Writeln(arquivo);

        SetLength(dadosUnique, Length(uniqueTabela));
        for var I := 0 to Length(uniqueTabela) - 1 do
        begin
          dadosUnique[I].nome := uniqueTabela[I].NomeColunaUnique;
          dadosUnique[I].tipo := uniqueTabela[I].TipoUnique;
        end;

        Writeln(arquivo, FormataStringPesquisar(NomeTabela, dadosUnique));
      end;

      Writeln(arquivo);
      Write(arquivo, FormataStringDelete(NomeTabela, pkTabela.NomeColunaPk, pkTabela.TipoPk));
      Writeln(arquivo);

      Write(arquivo, FormataMetodosSets(NomeTabela));
      Write(arquivo, 'end.');
      CloseFile(arquivo);
    except
      on e: exception do
      begin
        CloseFile(arquivo);
        raise Exception.Create(e.message);
      end;
    end;
  finally
    FNomeMetodosPublicos.Free;
  end;
end;

function TManipuladorClasse.FormataStringPesquisar(NomeTabela, NomePk, TipoPk: string): string;
begin
  Result := 'function ' + FNomeClasse +'.Pesquisar(' + NomePk + ': ' + RetornaTipoCampo(TipoPk) + '): Boolean;' + #13
            + 'const'  + #13
            + '   '
            + ' SQL = ' + #13
            + '   ' + '''' + 'SELECT * ' + '''' + ' +' + #13
            + '   ' + '''' + ' FROM ' + '''' + ' +' + #13
            + '   ' + '''' + NomeTabela + '''' + ' +' + #13
            + '   ' + '''' + ' WHERE ' + '''' + ' +' + #13
            + '   ' + '''' + NomePk + ' = ' + ':' + NomePk + '''' + ';';

  Result := Result + FormataParametrosPesquisar(NomeTabela, NomePk, True);
end;

function TManipuladorClasse.FormataParametrosPesquisar(NomeTabela, NomePk: string; EhPK: Boolean): string;
var
  dadosUnk: TArray<TDadosPkUniqueTabela>;
  str: string;
begin
  str := '';
  Result := #13;
  Result := Result + 'var' + #13;
  Result := Result + '  query: TFDquery;' + #13;
  Result := Result + 'begin' + #13;
  Result := Result + '  query := TFDquery.Create(nil);' + #13;
  Result := Result + '  query.Connection := dm.conexaoBanco;' + #13 + #13;
  Result := Result + '  try' + #13;

  if EhPK then
    Result := Result + '    query.Open(SQL, [' + NomePk + ']);' + #13
  else
  begin
    dadosUnk := FManipuladorInfo.GetUniqueTabelas(NomeTabela);
    Result := Result + '    query.Open(SQL, [' ;
    for var I := 0 to Length(dadosUnk) - 1 do
      str := str + dadosUnk[I].NomeColunaUnique + ifthen(I = High(dadosUnk), ']', ', ');
  end;

  Result := Result + str + #13;
  Result := Result + '    Result := not query.IsEmpty;' + #13;
  Result := Result + '  finally' + #13;
  Result := Result + '    query.Free;' + #13;
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

function TManipuladorClasse.FormataStringPesquisar(NomeTabela: string; DadosUnk: TArray<TDadosUnique>): string;
var
  I: integer;
  str: string;
begin
  str := '';
  Result := 'function ' + FNomeClasse +'.Pesquisar(';

  for I := 0 to Length(DadosUnk) - 1 do
    str := str + DadosUnk[I].nome + ': ' + RetornaTipoCampo(DadosUnk[I].tipo) + ifthen(I = High(DadosUnk), '', '; ');

  str := str + '): Boolean;' + #13;

  Result := Result + str
            + 'const'  + #13
            + '   '
            + ' SQL = ' + #13
            + '   ' + '''' + 'SELECT * ' + '''' + ' +' + #13
            + '   ' + '''' + ' FROM ' + '''' + ' +' + #13
            + '   ' + '''' + NomeTabela + '''' + ' +' + #13
            + '   ' + '''' + ' WHERE ' + '''' + ' +' + #13
            + '   ' + '''';

  str := '';

  for I := 0 to Length(DadosUnk) - 1 do
    str := str + ' ' + DadosUnk[I].nome + ' = ' + ':' + DadosUnk[I].nome + ifthen(I = High(DadosUnk), '''', ' AND ');

  Result := Result + str + ';';
  Result := Result + FormataParametrosPesquisar(NomeTabela, '', False);
end;

function TManipuladorClasse.FormataStringDelete(NomeTabela, Pk, TipoPk: string): string;
begin
  Result := 'procedure ' + FNomeClasse + '.' + 'Excluir' + ';' + #13
            + 'const'  + #13
            + '   '
            + 'SQL = '  + #13
            + '   '
            + '''' + 'DELETE ' + '''' + ' +' + #13
            + '   '
            + '''' + ' FROM ' + '''' + ' +' + #13
            + '   '
            + '''' + NomeTabela + '''' + ' +' + #13
            + '   '
            + '''' + ' WHERE ' + '''' + ' +' + #13
            + '   '
            + '''' + Pk + ' = :' + Pk + '''' + ';'; //ajustar quando possui unique key

  Result := Result + #13;
  Result := Result + 'var' + #13;
  Result := Result + '  query: TFDquery;' + #13;
  Result := Result + 'begin' + #13;
  Result := Result + '  query := TFDquery.Create(nil);' + #13;
  Result := Result + '  query.Connection := dm.conexaoBanco;' + #13;
  Result := Result + '  query.Connection.StartTransaction;' + #13;
  Result := Result + '  query.SQL.Add(SQL);' + #13;
  Result := Result + '  try' + #13;
  Result := Result + '    try' + #13;
  Result := Result + '      query.ParamByName(''' + Pk + ''').' + RetornaTipoCampoParametros(TipoPk) + ' := ' + 'F' + Pk + ';' + #13;
  Result := Result + '      query.ExecSQL;' + #13;
  Result := Result + '      query.Connection.Commit;' + #13;
  Result := Result + '    except' + #13;
  Result := Result + '    on E:exception do' + #13;
  Result := Result + '      begin' + #13;
  Result := Result + '        query.Connection.Rollback;' + #13;
  Result := Result + '        raise Exception.Create(''Erro ao excluir os dados na tabela ' + NomeTabela + '''' + ' + ' + ' E.Message' + ');' + #13;
  Result := Result + '      end;' + #13;
  Result := Result + '    end;' + #13;
  Result := Result + '  finally' + #13;
  Result := Result + '    query.Connection.Rollback;' + #13;
  Result := Result + '    query.Free;' + #13;
  Result := Result + '  end;' + #13;
  Result := Result + 'end;' + #13;
end;

function TManipuladorClasse.FormataMetodosSets(NomeTabela: string): string;
var
  colunasTabela: TArray<TColunasTabela>;
  dados: TCarregaInformacoesBanco;
begin
  dados := TCarregaInformacoesBanco.Create;

  try
    colunasTabela := dados.GetColunasTabela(NomeTabela);

    for var colunas in colunasTabela do
    begin
      Result := Result + 'procedure ' + FNomeClasse + '.Set' + colunas.NomeColuna + '(' + 'const Value: ' + RetornaTipoCampo(colunas.typeColuna) + ');' + #13;
      Result := Result + 'begin' + #13;
      Result := Result + '  F' + colunas.NomeColuna + ' := Value;' +  #13;
      Result := Result + 'end;' + #13;
      Result := Result + #13;
    end;
  finally
    dados.Free;
  end;
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
  Result := Result + '  query.Connection.StartTransaction;' + #13;
  Result := Result + '  query.SQL.Add(SQL);' + #13;
  Result := Result + '  try' + #13;
  Result := Result + '    try' + #13;

  for var I := 0 to Length(colunasTabela) - 1 do
  begin
    Result := Result + '      query.ParamByName(''' + colunasTabela[I].NomeColuna + ''').'
              + RetornaTipoCampoParametros(colunasTabela[I].typeColuna) + ' := ' + 'F' + colunasTabela[I].NomeColuna + ';' + #13;
  end;

  Result := Result + '      query.ExecSQL;' + #13;
  Result := Result + '      query.Connection.Commit;' + #13;
  Result := Result + '    except' + #13;
  Result := Result + '    on E:exception do' + #13;
  Result := Result + '      begin' + #13;
  Result := Result + '        query.Connection.Rollback;' + #13;
  Result := Result + '        raise Exception.Create(''Erro ao gravar os dados na tabela ' + NomeTabela + '''' + ' + ' + ' E.Message' + ');' + #13;
  Result := Result + '      end;' + #13;
  Result := Result + '    end;' + #13;
  Result := Result + '  finally' + #13;
  Result := Result + '    query.Connection.Rollback;' + #13;
  Result := Result + '    query.Free;' + #13;
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

  Result := Result + '''' + 'WHERE ' + '''' + ' +' + #13;  //ajustar quando possui unique key
  Result := Result + '''' + Pk + ' = :' + Pk + '''' + ';' + #13;

  Result := Result + FormataParametros(NomeTabela);
end;

procedure TManipuladorClasse.GerarClasse(NomeTabela: string);
begin
  try
    CriaClasse(NomeTabela);
  except
    on e: exception do
      raise Exception.Create(e.message);
  end;
end;

destructor TManipuladorClasse.Destroy;
begin
  FCaminho := '';
  FManipuladorInfo.Free;
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

procedure TManipuladorClasse.SetManipuladorInfo(const Value: TCarregaInformacoesBanco);
begin
  FManipuladorInfo := Value;
end;

end.

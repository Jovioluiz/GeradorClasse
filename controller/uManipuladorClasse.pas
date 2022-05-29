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
    function RetornaTipoCampo(NomeTipoCampo: string): String;
    function RetornaTipoCampoParametros(NomeTipoCampo: string): String;
    function FormataStringUpdate(NomeTabela, Pk: string): string;
    function FormataParametros(NomeTabela: string): string;
    function FormataStringPesquisar(NomeTabela, NomePk, TipoPk: string): string; overload;
    function FormataStringPesquisar(NomeTabela: string; DadosUnk: TArray<TDadosUnique>): string; overload;
    function FormataParametrosPesquisar(NomeTabela, NomePk: string; EhPK: Boolean): string;
    function FormataStringDelete(NomeTabela, Pk, TipoPk: string): string;
    function FormataMetodosSets(NomeTabela: string): string;
    function FormataStringPersistir(NomeTabela: string): string;
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
  parametrosPesquisarUk: string;
  pkTabela: TDadosPkTabela;
  uniqueTabela: TArray<TDadosPkUniqueTabela>;
  FNomeMetodosPublicos: TList<string>;
  dadosTabela: TArray<TColunasTabela>;
begin
  FNomeMetodosPublicos := TList<string>.Create;

  try
    try
      dadosTabela := FManipuladorInfo.GetColunasTabela(NomeTabela);
      nomeArquivo := FCaminho + '\ucl' + NomeTabela.ToUpper + '.pas';
      FNomeClasse := 'T' + NomeTabela.ToUpper;

      AssignFile(arquivo, nomeArquivo);
      Rewrite(arquivo);

      Write(arquivo, 'unit ' + 'ucl' + NomeTabela.ToUpper + ';');
      Writeln(arquivo);
      Writeln(arquivo);
      Write(arquivo, 'interface');
      Writeln(arquivo);
      Writeln(arquivo);
      Write(arquivo, 'uses');
      Writeln(arquivo);
      Write(arquivo, ' FireDac.Stan.Param, Data.DB, uPersistencia, uConsultaSQL;');
      Writeln(arquivo);
      Writeln(arquivo);
      Write(arquivo, 'type ' + FNomeClasse.ToUpper + ' = class(TPersistencia) ');
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

      Write(arquivo, '  public ');
      Writeln(arquivo);

      pkTabela := FManipuladorInfo.GetPKTabela(NomeTabela);
      uniqueTabela := FManipuladorInfo.GetUniqueTabelas(NomeTabela);
      //método pesquisar pela pk
      if (pkTabela.NomeColunaPk = '') and (not Assigned(uniqueTabela)) then
        raise Exception.Create('A tabela ' + NomeTabela + ' não possui PK. Verifique.');
      
      if pkTabela.NomeColunaPk <> '' then
      begin
        Write(arquivo, '   //Metodo Pesquisar pela chave primaria');
        Writeln(arquivo);
        Write(arquivo, '    ');
        Write(arquivo, 'function Pesquisar(' + pkTabela.NomeColunaPk + ': '
                                             + RetornaTipoCampo(pkTabela.TipoPk) + '): Boolean; '
                                             + ifthen(Assigned(uniqueTabela), ' overload;', ''));
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
          parametrosPesquisarUk := parametrosPesquisarUk + uniqueTabela[I].NomeColunaUnique
                                   + ': ' + ifthen(I = High(uniqueTabela),
                                   RetornaTipoCampo(uniqueTabela[I].TipoUnique) + '): Boolean; ',
                                   RetornaTipoCampo(uniqueTabela[I].TipoUnique) + '; ');
          primeiro := uniqueTabela[I].TipoUnique;
        end;
        if pkTabela.NomeColunaPk <> '' then
          parametrosPesquisarUk := parametrosPesquisarUk + ' overload;';
        
        Write(arquivo, str + parametrosPesquisarUk);
      end;

      Writeln(arquivo);
      Write(arquivo, '    ');
      Write(arquivo, 'procedure Inserir; override;');
      FNomeMetodosPublicos.Add('Inserir');
      Writeln(arquivo);
      Write(arquivo, '    ');
      Write(arquivo, 'procedure Atualizar; override;');
      FNomeMetodosPublicos.Add('Atualizar');
      Writeln(arquivo);
      Write(arquivo, '    ');
      Write(arquivo, 'procedure Excluir; override;');
      FNomeMetodosPublicos.Add('Excluir');
      Writeln(arquivo);
      Write(arquivo, '    ');
      Write(arquivo, 'procedure Persistir(Novo: Boolean); override;');
      FNomeMetodosPublicos.Add('Persistir');
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
      Write(arquivo, 'System.SysUtils, Vcl.Dialogs;');
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
      Writeln(arquivo, FormataStringPersistir(NomeTabela));

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
  Result := 'function ' + FNomeClasse.ToUpper +'.Pesquisar(' + NomePk + ': ' + RetornaTipoCampo(TipoPk) + '): Boolean;' + #13
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
  colunasTabela: TArray<TColunasTabela>;
begin
  str := '';
  Result := #13;
  Result := Result + 'var' + #13;
  Result := Result + '  consulta: TConsultaSQL;' + #13;
  Result := Result + 'begin' + #13;
  Result := Result + '  consulta := TConsultaSQL.Create(nil);' + #13;
  Result := Result + '  consulta.Connection := Conexao;' + #13 + #13;
  Result := Result + '  try' + #13;

  if EhPK then
    Result := Result + '    consulta.Open(SQL, [' + NomePk + ']);' + #13
  else
  begin
    dadosUnk := FManipuladorInfo.GetUniqueTabelas(NomeTabela);
    Result := Result + '    consulta.Open(SQL, [' ;
    for var I := 0 to Length(dadosUnk) - 1 do
      str := str + dadosUnk[I].NomeColunaUnique + ifthen(I = High(dadosUnk), ']', ', ');
  end;

  Result := Result + str + #13;
  Result := Result + '    Result := not consulta.IsEmpty;' + #13;

  colunasTabela := GetColunasTabela(NomeTabela);
  for var I := 0 to Length(colunasTabela) - 1 do
  begin
    Result := Result + '    F' + colunasTabela[I].NomeColuna + ' := consulta.FieldByName(''' + colunasTabela[I].NomeColuna + ''').'
              + RetornaTipoCampoParametros(colunasTabela[I].typeColuna) +  ';' + #13;
  end;

  Result := Result + '  finally' + #13;
  Result := Result + '    consulta.Free;' + #13;
  Result := Result + '  end;' + #13;
  Result := Result + 'end;';
end;

function TManipuladorClasse.FormataStringInsert(NomeTabela: string): string;
var
  colunasTabela: TArray<TColunasTabela>;
begin
  Result := 'procedure ' + FNomeClasse.ToUpper + '.' + 'Inserir' + ';' + #13
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

function TManipuladorClasse.FormataStringPersistir(NomeTabela: string): string;
begin
  var idGeral := '    ' + 'if ' + 'id_geral = 0' + ' then' + #13
                 + '      ' + 'id_geral := GetIdGeral;' + #13;

  Result := 'procedure ' + FNomeClasse.ToUpper + '.Persistir(Novo: Boolean);' + #13
            + 'begin' + #13
            + '  ' + 'if Novo then' + #13
            + '  ' + 'begin '    + #13;
  if FManipuladorInfo.PossuiIdGeral(NomeTabela) then
    Result := Result + idGeral;

  Result := Result + '    ' + 'Inserir;' + #13
                   + '  ' + 'end'    + #13
                   + '  ' + 'else ' + #13
                   + '    ' + 'Atualizar;' + #13
                   + 'end;';
end;

function TManipuladorClasse.FormataStringPesquisar(NomeTabela: string; DadosUnk: TArray<TDadosUnique>): string;
var
  I: integer;
  str: string;
begin
  str := '';
  Result := 'function ' + FNomeClasse.ToUpper +'.Pesquisar(';

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
    str := str + ' ' + DadosUnk[I].nome + ' = ' + ':' + DadosUnk[I].nome + ifthen(I = High(DadosUnk), '''', ' AND');

  Result := Result + str + ';';
  Result := Result + FormataParametrosPesquisar(NomeTabela, '', False);
end;

function TManipuladorClasse.FormataStringDelete(NomeTabela, Pk, TipoPk: string): string;
begin
  Result := 'procedure ' + FNomeClasse.ToUpper + '.' + 'Excluir' + ';' + #13
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
  Result := Result + '  consulta: TConsultaSQL;' + #13;
  Result := Result + 'begin' + #13;
  Result := Result + '  consulta := TConsultaSQL.Create(nil);' + #13;
  Result := Result + '  consulta.Connection := Conexao;' + #13;
  Result := Result + '  consulta.SQL.Add(SQL);' + #13;
  Result := Result + '  try' + #13;
  Result := Result + '    try' + #13;
  Result := Result + '      consulta.ParamByName(''' + Pk + ''').' + RetornaTipoCampoParametros(TipoPk) + ' := ' + 'F' + Pk + ';' + #13;
  Result := Result + '      consulta.ExecSQL;' + #13;
  Result := Result + '    except' + #13;
  Result := Result + '    on E:exception do' + #13;
  Result := Result + '      begin' + #13;
  Result := Result + '        raise Exception.Create(''Erro ao excluir os dados na tabela ' + NomeTabela + '''' + ' + ' + ' E.Message' + ');' + #13;
  Result := Result + '      end;' + #13;
  Result := Result + '    end;' + #13;
  Result := Result + '  finally' + #13;
  Result := Result + '    consulta.Free;' + #13;
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
      Result := Result + 'procedure ' + FNomeClasse.ToUpper + '.Set'
                + colunas.NomeColuna + '(' + 'const Value: ' + RetornaTipoCampo(colunas.typeColuna) + ');' + #13;
      Result := Result + 'begin' + #13;
      Result := Result + '  F' + colunas.NomeColuna + ' := Value;' + #13;
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
  Result := Result + '  consulta: TConsultaSQL;' + #13;
  Result := Result + 'begin' + #13;
  Result := Result + '  consulta := TConsultaSQL.Create(nil);' + #13;
  Result := Result + '  consulta.Connection := Conexao;' + #13;
  Result := Result + '  consulta.SQL.Add(SQL);' + #13;
  Result := Result + '  try' + #13;
  Result := Result + '    try' + #13;

  for var I := 0 to Length(colunasTabela) - 1 do
  begin
    Result := Result + '      consulta.ParamByName(''' + colunasTabela[I].NomeColuna + ''').'
              + RetornaTipoCampoParametros(colunasTabela[I].typeColuna) + ' := ' + 'F' + colunasTabela[I].NomeColuna + ';' + #13;
  end;

  Result := Result + '      consulta.ExecSQL;' + #13;
  Result := Result + '    except' + #13;
  Result := Result + '    on E:exception do' + #13;
  Result := Result + '      begin' + #13;
  Result := Result + '        raise Exception.Create(''Erro ao gravar os dados na tabela '
                              + NomeTabela + '''' + ' + ' + ' E.Message' + ');' + #13;
  Result := Result + '      end;' + #13;
  Result := Result + '    end;' + #13;
  Result := Result + '  finally' + #13;
  Result := Result + '    consulta.Free;' + #13;
  Result := Result + '  end;' + #13;
  Result := Result + 'end;' + #13;

end;

function TManipuladorClasse.FormataStringUpdate(NomeTabela, Pk: string): string;
var
  colunasTabela: TArray<TColunasTabela>;
begin
  Result := 'procedure ' + FNomeClasse.ToUpper + '.' + 'Atualizar' + ';' + #13
            + 'const'  + #13
            + '   '
            + 'SQL = '  + #13
            + '   '
            + '''' + 'UPDATE ' + '''' + ' +'  + #13
            + '   '
            + '''' + NomeTabela + ' ' + '''' + ' +' + #13
            + '''' + 'SET ' + '''' + ' +' + #13;

  colunasTabela := GetColunasTabela(NomeTabela);

  for var I := 0 to Length(colunasTabela) - 1 do
  begin
    Result := Result + '' + '' + '' + '   ';
    Result := Result + '''' + colunasTabela[I].NomeColuna
                     + ' = '
                     + ':'
                     + colunasTabela[I].NomeColuna
                     + ifthen(I = High(colunasTabela), ' ', ', ') + '''' + ' +' + #13;
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

function TManipuladorClasse.RetornaTipoCampo(NomeTipoCampo: string): String;
begin
  if AnsiContainsStr(NomeTipoCampo, 'bigint') then
    Exit('Int64')
  else if AnsiContainsStr(NomeTipoCampo, 'numeric') then
    Exit('Currency')
  else if AnsiContainsStr(NomeTipoCampo, 'double') then
    Exit('Double')
  else if AnsiContainsStr(NomeTipoCampo, 'timestamp') then
    Exit('TDateTime')
  else if AnsiContainsStr(NomeTipoCampo, 'date') then
    Exit('TDate')
  else if (AnsiContainsStr(NomeTipoCampo, 'character')) or (AnsiContainsStr(NomeTipoCampo, 'text')) then
    Exit('String')
  else if (AnsiContainsStr(NomeTipoCampo, 'smallint')) or (AnsiContainsStr(NomeTipoCampo, 'integer')) then
    Exit('Integer')
  else if AnsiContainsStr(NomeTipoCampo, 'bytea') then
    Exit('TBytes')
  else if AnsiContainsStr(NomeTipoCampo, 'boolean') then
    Exit('Boolean');
end;

function TManipuladorClasse.RetornaTipoCampoParametros(NomeTipoCampo: string): String;
begin
  if AnsiContainsStr(NomeTipoCampo, 'bigint') then
    Exit('AsLargeInt')
  else if AnsiContainsStr(NomeTipoCampo, 'numeric') then
   Exit('AsCurrency')
  else if AnsiContainsStr(NomeTipoCampo, 'double') then
    Exit('AsFloat')
  else if AnsiContainsStr(NomeTipoCampo, 'timestamp') then
    Exit('AsDateTime')
  else if AnsiContainsStr(NomeTipoCampo, 'date') then
    Exit('AsDate')
  else if (AnsiContainsStr(NomeTipoCampo, 'character')) or (AnsiContainsStr(NomeTipoCampo, 'text')) then
    Exit('AsString')
  else if (AnsiContainsStr(NomeTipoCampo, 'smallint')) or (AnsiContainsStr(NomeTipoCampo, 'integer')) then
    Exit('AsInteger')
  else if AnsiContainsStr(NomeTipoCampo, 'bytea') then
    Exit('AsBytes')
  else if AnsiContainsStr(NomeTipoCampo, 'boolean') then
    Exit('AsBoolean');
end;

procedure TManipuladorClasse.SetManipuladorInfo(const Value: TCarregaInformacoesBanco);
begin
  FManipuladorInfo := Value;
end;

end.

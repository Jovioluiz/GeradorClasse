unit uCarregaInformacoesBanco;

interface

uses
  System.Generics.Collections;

type TCarregaInformacoesBanco = class

  type TDadosPkTabela = record
    NomeColunaPk,
    TipoPk: string;
  end;

  type TColunasTabela = record
    NomeColuna,
    typeColuna: string;
  end;

    private
      FListaTabelas: TList<string>;
      FDadosTabelas: TDictionary<string, string>;
      procedure SetListaTabelas(const Value: TList<string>);
      procedure SetDadosTabelas(const Value: TDictionary<string, string>);

    public
      function CarregaTabelas: TList<String>;
      function CarregaDadosTabela(Tabela: string): TDictionary<string, string>;
      function GetPKTabela(NomeTabela: string): TDadosPkTabela;
      function GetColunasTabela(NomeTabela: string): TArray<TColunasTabela>;

      constructor Create;
      destructor Destroy; override;

      property ListaTabelas: TList<string> read FListaTabelas write SetListaTabelas;
      property DadosTabelas: TDictionary<string, string> read FDadosTabelas write SetDadosTabelas;
  end;

implementation

uses
  FireDAC.Comp.Client, uDataModule, System.SysUtils;

{ TCarregaInformacoesBanco }

function TCarregaInformacoesBanco.CarregaDadosTabela(Tabela: string): TDictionary<string, string>;
const
  SQL = '  SELECT ' +
        '  	attname AS coluna, ' +
        '  	format_type(atttypid, atttypmod) AS tipo ' +
        '  FROM ' +
        '  	pg_class c ' +
        '  JOIN pg_attribute a ' +
        '      ON c.oid = a.attrelid ' +
        '  WHERE ' +
        '  	attnum > 0 ' +
        '  	AND relname = :tabela ' +
        '   ORDER BY coluna ';
var
  query: TFDQuery;
begin
  query := TFDQuery.Create(nil);
  query.Connection := dm.conexaoBanco;

  try
    query.Open(SQL, [Tabela]);

    query.First;
    while not query.Eof do
    begin
      if not FDadosTabelas.ContainsKey(query.FieldByName('coluna').AsString) then
        FDadosTabelas.Add(query.FieldByName('coluna').AsString, query.FieldByName('tipo').AsString);
      query.Next;
    end;

    Result := FDadosTabelas;

  finally
    query.Free;
  end;
end;

function TCarregaInformacoesBanco.CarregaTabelas: TList<String>;
const
  SQL = ' SELECT ' +
        '   table_name ' +
        ' FROM ' +
        '   information_schema.tables ' +
        ' WHERE ' +
        '   table_schema = ''public'' ' +
        '   AND table_type = ''BASE TABLE'' ' +
        ' ORDER BY table_name';
var
  query: TFDquery;
begin
  query := TFDQuery.Create(nil);
  query.Connection := dm.conexaoBanco;

  try
    query.SQL.Add(SQL);
    query.Open();

    query.First;
    while not query.Eof do
    begin
      FListaTabelas.Add(query.FieldByName('table_name').AsString);
      query.Next;
    end;

    Result := FListaTabelas;

  finally
    query.Free;
  end;
end;

constructor TCarregaInformacoesBanco.Create;
begin
  FListaTabelas := TList<string>.Create;
  FDadosTabelas := TDictionary<string, string>.Create;
end;

destructor TCarregaInformacoesBanco.Destroy;
begin
//  if FListaTabelas <> nil then
//    FListaTabelas.Free;
//  FDadosTabelas.Free;
  inherited;
end;

function TCarregaInformacoesBanco.GetColunasTabela(NomeTabela: string): TArray<TColunasTabela>;
const
  SQL = ' SELECT ' +
        ' 	column_name, ' +
        '   data_type ' +
        ' FROM ' +
        ' 	INFORMATION_SCHEMA.COLUMNS ' +
        ' WHERE ' +
        ' 	table_name = :tabela ' +
        ' ORDER BY ' +
        ' 	column_name';
var
  query: TFDQuery;
begin
  query := TFDQuery.Create(nil);
  query.Connection := dm.conexaoBanco;

  try
    query.Open(SQL, [NomeTabela]);

    SetLength(Result, query.RecordCount);

    query.First;
    for var I := 0 to Length(Result) - 1 do
    begin
      Result[I].NomeColuna := query.FieldByName('column_name').AsString;
      Result[I].typeColuna := query.FieldByName('data_type').AsString;
      query.Next;
    end;

  finally
    query.Free;
  end;
end;

function TCarregaInformacoesBanco.GetPKTabela(NomeTabela: string): TDadosPkTabela;
const
  SQL = ' SELECT ' +
        ' 	kcu.column_name, ' +
        ' 	( ' +
        ' 	SELECT ' +
        ' 		format_type(atttypid, atttypmod) ' +
        ' 	FROM ' +
        ' 		pg_attribute a ' +
        ' 	JOIN pg_class c ON ' +
        ' 			c.oid = a.attrelid ' +
        ' 		AND c.relname = :nome_tabela ' +
        ' 		AND attnum > 0 ' +
        ' 	LIMIT 1) AS tipo_pk ' +
        ' FROM ' +
        ' 	information_schema.table_constraints AS tc ' +
        ' JOIN information_schema.key_column_usage AS kcu ' +
        '       ON ' +
        ' 	tc.constraint_name = kcu.constraint_name ' +
        ' WHERE ' +
        ' 	constraint_type = ''PRIMARY KEY'' ' +
        ' 	AND tc.table_name = :nome_tabela; ';
var
  query: TFDQuery;
begin
  query := TFDQuery.Create(nil);
  query.Connection := dm.conexaoBanco;

  try
    query.Open(SQL, [NomeTabela]);

    Result.NomeColunaPk := query.FieldByName('column_name').AsString;
    Result.TipoPk := query.FieldByName('tipo_pk').AsString;

  finally
    query.Free;
  end;
end;

procedure TCarregaInformacoesBanco.SetDadosTabelas(const Value: TDictionary<string, string>);
begin
  FDadosTabelas := Value;
end;

procedure TCarregaInformacoesBanco.SetListaTabelas(const Value: TList<string>);
begin
  FListaTabelas := Value;
end;

end.

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

  type TTabelasBanco = record
    NomeTabela: string;
  end;

  type TDadosPkUniqueTabela = record
    NomeColunaUnique,
    TipoUnique: string;
  end;

    private
      FListaTabelas: TList<string>;
      procedure SetListaTabelas(const Value: TList<string>);

    public
      function CarregaTabelas: TList<String>;
      function GetPKTabela(NomeTabela: string): TDadosPkTabela;
      function GetColunasTabela(NomeTabela: string): TArray<TColunasTabela>;
      function GetUniqueTabelas(NomeTabela: string): TArray<TDadosPkUniqueTabela>;
      function PossuiIdGeral(NomeTabela: string): Boolean;
      constructor Create;
      destructor Destroy; override;

      property ListaTabelas: TList<string> read FListaTabelas write SetListaTabelas;
  end;

implementation

uses
  FireDAC.Comp.Client, uDataModule, System.SysUtils;

{ TCarregaInformacoesBanco }

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
end;

destructor TCarregaInformacoesBanco.Destroy;
begin
//  FListaTabelas.Free;
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

function TCarregaInformacoesBanco.GetUniqueTabelas(NomeTabela: string): TArray<TDadosPkUniqueTabela>;
const
  SQL = ' SELECT   ' +
        ' 	kcu.column_name, ' +
        ' 	a.tipo ' +
        ' FROM ' +
        ' 	information_schema.table_constraints AS tc ' +
        ' JOIN information_schema.key_column_usage AS kcu ' +
        '      ON tc.constraint_name = kcu.constraint_name ' +
        ' JOIN ( ' +
        '     	SELECT  ' +
        '     		column_name, ' +
        '     		data_type AS tipo, ' +
        '     		table_name ' +
        '     	FROM ' +
        '     		INFORMATION_SCHEMA.COLUMNS ' +
        '     	WHERE ' +
        '     		table_name = :nome_tabela) a ON	a.table_name = tc.table_name ' +
        ' 		    AND kcu.column_name = a.column_name ' +
        ' WHERE ' +
        ' 	constraint_type = ''UNIQUE'' ' +
        ' 	AND tc.table_name = :nome_tabela ORDER BY a.tipo';
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
      Result[I].NomeColunaUnique := query.FieldByName('column_name').AsString;
      Result[I].TipoUnique := query.FieldByName('tipo').AsString;
      query.Next;
    end;

  finally
    query.Free;
  end;
end;

function TCarregaInformacoesBanco.PossuiIdGeral(NomeTabela: string): Boolean;
var
  dadosTabela: TArray<TColunasTabela>;
begin
  dadosTabela := GetColunasTabela(NomeTabela);
  Result := False;

  for var campos in dadosTabela do
  begin
    if campos.NomeColuna = 'id_geral' then
      Exit(True);
  end;
end;

procedure TCarregaInformacoesBanco.SetListaTabelas(const Value: TList<string>);
begin
  FListaTabelas := Value;
end;

end.

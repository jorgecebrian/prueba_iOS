unit uDM;
interface
uses
  System.SysUtils, System.Classes, Data.DB,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def,  FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.FMXUI.Wait, FireDAC.Comp.Client;

type
  TDMod = class(TDataModule)
    FDConnection1: TFDConnection;
    procedure DataModuleCreate(Sender: TObject);
  private       { Private declarations }
  public        { Public declarations }
    function  errorSql(): String;
    function  executeSql(cSQL: String): Boolean;
    function  selectSql(cSQL: String): String;
    procedure Table_FieldBlob_Save(const cTable, cField: string; cRowId: Integer; const cValue: string);
  end;

var
  DMod: TDMod;
  vUltimoError: String;

implementation
{%CLASSGROUP 'FMX.Controls.TControl'}
{$R *.dfm}
uses
  System.JSON,
  FireDAC.Stan.Param;

procedure TDMod.DataModuleCreate(Sender: TObject);
begin     vUltimoError := '';                                         end;

function  TDMod.errorSql(): String;
begin     Result := vUltimoError;                                     end;

function TDMod.executeSql(cSQL: String): Boolean;
var      vFDQuery: TFDQuery;
begin
  Result   := False;
  vFDQuery := TFDQuery.Create(nil);
  try
    vFDQuery.Connection := FDConnection1;
    vFDQuery.SQL.Text := cSQL;
    try
      vFDQuery.ExecSQL;
      Result := True;
    except
      on E: Exception do
        vUltimoError := 'Error al ejecutar comando SQL: ' + E.Message;
    end;
  finally
    vFDQuery.Free;
  end;
end;

function TDMod.selectSql(cSQL: String): String;
var
  i: Integer;               vJSONArray: TJSONArray;
  vFDQuery: TFDQuery;       vJSONObject: TJSONObject;
begin
  Result     := '';
  vJSONArray := TJSONArray.Create;
  vFDQuery   := TFDQuery.Create(nil);
  try
    vFDQuery.Connection := FDConnection1;
    vFDQuery.SQL.Text := cSQL;  // Asignar el comando SQL
    try
      vFDQuery.Open; // Ejecutar el SELECT
      while not vFDQuery.Eof do begin
        vJSONObject := TJSONObject.Create;
        for i := 0 to vFDQuery.FieldCount - 1 do
          case vFDQuery.Fields[i].DataType of
            ftInteger: vJSONObject.AddPair(vFDQuery.Fields[i].FieldName, vFDQuery.Fields[i].AsInteger.ToString);
            ftFloat: vJSONObject.AddPair(vFDQuery.Fields[i].FieldName, vFDQuery.Fields[i].AsFloat.ToString);
            ftDate: vJSONObject.AddPair(vFDQuery.Fields[i].FieldName, DateToStr(vFDQuery.Fields[i].AsDateTime));
            else
              vJSONObject.AddPair(vFDQuery.Fields[i].FieldName, vFDQuery.Fields[i].AsString);
          end;
        vJSONArray.AddElement(vJSONObject);
        vFDQuery.Next;
      end;
      Result := vJSONArray.ToString;
    except
      on E: Exception do
        vUltimoError := E.Message;
    end;
  finally
    vFDQuery.Free;
    vJSONArray.Free;
  end;
end;

procedure TDMod.Table_FieldBlob_Save(const cTable, cField: string; cRowId: Integer; const cValue: string);
var
  vQry: TFDQuery;         vMs: TMemoryStream;           vBytes: TBytes;
begin    // Crear el query
  vQry := TFDQuery.Create(nil);
  try
    vQry.Connection := DMod.FDConnection1; // Asigna aquí tu conexión FireDAC
    vQry.SQL.Text := Format('UPDATE %s SET %s = :BlobData WHERE RowId = :RowId', [cTable, cField]);
    vBytes := TEncoding.UTF8.GetBytes(cValue);     // Convertir el string cValue a bytes (UTF-8)
    vMs := TMemoryStream.Create;
    try        // Crear un MemoryStream para cargar el contenido
      if Length(vBytes) > 0 then begin
        vMs.WriteBuffer(vBytes[0], Length(vBytes));
        vMs.Position := 0;  // Asignar el contenido del stream al parámetro de tipo blob
        vQry.Params.ParamByName('BlobData').LoadFromStream(vMs, ftBlob);
      end else
        vQry.Params.ParamByName('BlobData').Clear;
    finally
      vMs.Free;
    end;
    vQry.Params.ParamByName('RowId').AsInteger := cRowId;
    vQry.ExecSQL;
  finally
    vQry.Free;
  end;
end;

end.

unit uIphone;
interface
uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.WebBrowser, FMX.Controls.Presentation, FMX.StdCtrls;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    WebBrowser1: TWebBrowser;
  private       { Private declarations }
  public        { Public declarations }
    function  MND_Info_Device: string;
    procedure MND_LoadURLFilePath(const cNombreArchivo,cPathInterno: String);
    function  FileLoadTxtPath(const cFileName, cPath: String): String;
    function  FileExists(const cFileName, cPath: String): Boolean;
    function  FileDeletePath(const cFileName, cPath: String): Boolean;
    function  DirFilesDelete(const cPath, cFiltro: String): Integer;
    function  FileCopy(const cPathFitOrigen, cPathFitDestino: String): Boolean;
    function  FileSaveFromURLFilePath(const cNombreArchivoURL, cPathInterno: String): Boolean;
    function  FileSavePath(const cNombreArchivo, cPath, cCadenaString: String): Boolean;
end;

var
  Form1: TForm1;

implementation
{$R *.fmx}
{$R *.iPhone47in.fmx IOS}
uses
  System.JSON, System.IOUtils, System.Net.HttpClient,
  iOSapi.UIKit, Macapi.Helpers, uDM;

procedure TForm1.MND_LoadURLFilePath(const cNombreArchivo,cPathInterno: String);
var       vFilePath: String;
begin
  vFilePath := TPath.Combine(TPath.GetDocumentsPath, TPath.Combine(cPathInterno, cNombreArchivo));
  if TFile.Exists(vFilePath)
    then WebBrowser1.Navigate('file://' + vFilePath)
    else ShowMessage('Error: El archivo no existe en el path especificado.');
end;

function TForm1.MND_Info_Device: string;
var      vUD: UIDevice;     vDeviceInfo: TJSONObject;
begin   // Obtener la instancia del dispositivo iOS actual:
  vUD := TUIDevice.Wrap(TUIDevice.OCClass.currentDevice);
  vDeviceInfo := TJSONObject.Create;
  try         // Convertir de NSString a string usando NSStrToStr (de Macapi.Helpers)
    vDeviceInfo.AddPair('name', TJSONString.Create(NSStrToStr(vUD.name)));
    vDeviceInfo.AddPair('systemName', TJSONString.Create(NSStrToStr(vUD.systemName)));
    vDeviceInfo.AddPair('systemVersion', TJSONString.Create(NSStrToStr(vUD.systemVersion)));
    vDeviceInfo.AddPair('model', TJSONString.Create(NSStrToStr(vUD.model)));
    vDeviceInfo.AddPair('identifierForVendor', TJSONString.Create(NSStrToStr(vUD.identifierForVendor.UUIDString)));
    Result := vDeviceInfo.ToString;
  finally
    vDeviceInfo.Free;
  end;
end;

function TForm1.FileLoadTxtPath(const cFileName, cPath: String): String;
var      vFile: String;
begin
  Result := '';
  try
    vFile := TPath.Combine(TPath.GetDocumentsPath, TPath.Combine(cPath, cFileName));
    if TFile.Exists(vFile)
      then Result := TFile.ReadAllText(vFile) // Leer todo el contenido del archivo como cadena
      else raise Exception.CreateFmt('El archivo "%s" no existe en el path: "%s"', [cFileName, cPath]);
  except
    on E: Exception do
      ShowMessage('Error al leer el archivo: ' + E.Message);
  end;
end;

function TForm1.FileExists(const cFileName, cPath: String): Boolean;
var      vFile: String;
begin
  vFile  := TPath.Combine(TPath.GetDocumentsPath, TPath.Combine(cPath, cFileName));
  Result := TFile.Exists(vFile);
end;

function TForm1.FileDeletePath(const cFileName, cPath: String): Boolean;
var      vFile: String;
begin
  Result := False;
  try
    vFile := TPath.Combine(TPath.GetDocumentsPath, TPath.Combine(cPath, cFileName));
    if TFile.Exists(vFile) then begin
      TFile.Delete(vFile);
      Result := True;
    end
    else
      raise Exception.CreateFmt('El archivo "%s" no existe en el path: "%s"', [cFileName, cPath]);
  except
    on E: Exception do
      ShowMessage('Error al eliminar el archivo: ' + E.Message);
  end;
end;

function  TForm1.DirFilesDelete(const cPath, cFiltro: String): Integer;
var
  vDirectorio, vFile : String;
  Files: TArray<String>;
begin
  Result := 0; // Contador de archivos eliminados
  try
    vDirectorio := TPath.Combine(TPath.GetDocumentsPath, cPath);
    if TDirectory.Exists(vDirectorio) then begin
      Files := TDirectory.GetFiles(vDirectorio, cFiltro);
      for vFile in Files do begin
        TFile.Delete(vFile);
        Inc(Result);
      end;
    end else
      raise Exception.CreateFmt('El directorio "%s" no existe.', [vDirectorio]);
  except
    on E: Exception do
      ShowMessage('Error al eliminar archivos: ' + E.Message);
  end;
end;

function TForm1.FileCopy(const cPathFitOrigen, cPathFitDestino: String): Boolean;
var      vFilePathOrigen, vFilePathDestino, vPathDestino: String;
begin
  Result := False;
  try
    vFilePathOrigen := TPath.Combine(TPath.GetDocumentsPath, cPathFitOrigen);
    vFilePathDestino := TPath.Combine(TPath.GetDocumentsPath, cPathFitDestino);
    vPathDestino := TPath.GetDirectoryName(vFilePathDestino);
    if TFile.Exists(vFilePathOrigen) then begin
      if not TDirectory.Exists(vPathDestino)
        then TDirectory.CreateDirectory(vPathDestino);
      TFile.Copy(vFilePathOrigen, vFilePathDestino, True);
      Result := True;
    end
    else
      raise Exception.CreateFmt('El archivo de origen "%s" no existe.', [vFilePathOrigen]);
  except
    on E: Exception do
      ShowMessage('Error al copiar el archivo: ' + E.Message);
  end;
end;

function TForm1.FileSaveFromURLFilePath(const cNombreArchivoURL, cPathInterno: String): Boolean;
var
  vHttpClient: THTTPClient;
  vResponse: IHTTPResponse;
  vFile, vDirectorio: String;
begin
  Result := False;
  vHttpClient := THTTPClient.Create;
  try
    vDirectorio := TPath.Combine(TPath.GetDocumentsPath, cPathInterno);
    vFile := TPath.Combine(vDirectorio, ExtractFileName(cNombreArchivoURL));
    if not TDirectory.Exists(vDirectorio)
      then TDirectory.CreateDirectory(vDirectorio);
    vResponse := vHttpClient.Get(cNombreArchivoURL);
    TFile.WriteAllText(vFile, vResponse.ContentAsString);
    Result := True;
  except
    on E: Exception do
      ShowMessage('Error al descargar archivo: ' + E.Message);
  end;
  vHttpClient.Free;
end;

function TForm1.FileSavePath(const cNombreArchivo, cPath, cCadenaString: String): Boolean;
var      vFile, vDirectorio: String;
begin
  Result := False;
  try
    vDirectorio := TPath.Combine(TPath.GetDocumentsPath, cPath);
    vFile := TPath.Combine(vDirectorio, cNombreArchivo);
    if not TDirectory.Exists(vDirectorio)
      then TDirectory.CreateDirectory(vDirectorio);
    TFile.WriteAllText(vFile, cCadenaString);
    Result := True;
  except
    on E: Exception do
      ShowMessage('Error al guardar archivo: ' + E.Message);
  end;
end;

end.

program prIPhone;

uses
  System.StartUpCopy,
  FMX.Forms,
  uIphone in 'uIphone.pas' {Form1},
  uDM in 'uDM.pas' {DMod: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TDMod, DMod);
  Application.Run;
end.

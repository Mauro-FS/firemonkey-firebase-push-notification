program Push;

uses
  System.StartUpCopy,
  FMX.Forms,
  unMain in 'unMain.pas' {frmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.

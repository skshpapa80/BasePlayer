program BasePlayer;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {frmMain},
  uSAMI in 'uSAMI.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.

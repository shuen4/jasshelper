program jasshelperinstaller;

uses
  Forms,
  installer in 'installer.pas' {Form3},
  about in 'about.pas' {Aboutdialog};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm3, Form3);
  Application.CreateForm(TAboutdialog, Aboutdialog);
  Application.Run;
end.

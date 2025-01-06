unit installer;

interface

uses
  Windows, {Messages, }SysUtils, {Variants, }Classes, Graphics, Controls, Forms,
  Dialogs, Registry, StdCtrls;

type
  TForm3 = class(TForm)
    Label1: TLabel;
    Edit1: TEdit;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    OpenDialog1: TOpenDialog;
    Button4: TButton;
    procedure Button4Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure RequestMode;
    procedure SetTarget;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form3: TForm3;
  jasshelperdll: AnsiString;
  jasshelpercgt: AnsiString;
  jasshelpertargetdll:AnsiString;
  jasshelpertargetcgt:AnsiString;

implementation

uses about;

{$R *.dfm}
procedure TForm3.SetTarget;
var
   f:AnsiString;
begin
    if (Edit1.Text[Length(Edit1.Text)]='\') then begin
        f:=Edit1.Text+'plugins\';
        jasshelpertargetdll:=Edit1.Text+'plugins\jasshelper.dll';
        jasshelpertargetcgt:=Edit1.Text+'plugins\jasshelper.cgt'
    end else begin
        f:=Edit1.Text+'\plugins\';
        jasshelpertargetdll:=Edit1.Text+'\plugins\jasshelper.dll';
        jasshelpertargetcgt:=Edit1.Text+'\plugins\jasshelper.cgt';
    end;
    if (not DirectoryExists(f)) and (not CreateDirectory(pchar(f),nil)) then begin
        Application.MessageBox('Unable to find/create plugins folder','Error',MB_ICONERROR);
        Halt;
    end;


    if (FileExists(jasshelpertargetdll)) then begin
        Button1.Caption:='Update JASSHelper'
    end
    else
        Button1.Caption:='Install JASSHelper';

end;

procedure TForm3.RequestMode;
begin
    Label1.Caption:='Unable to find WEHelper path in registry';
    Edit1.Text:='Please browse for the path [...] button, you can also try (re)installing WEHelper.';
    Button1.Enabled:=false;
    Button2.Enabled:=true;
//    Edit1.ReadOnly:=false;
end;

procedure TForm3.Button1Click(Sender: TObject);
begin
    Application.MessageBox('Make sure to have the latest WEHelper version in order to ensure compatibility with this version of jasshelper and the latest warcraft patch.','Warning',MB_ICONWARNING);
    Application.MessageBox('Make sure to close WEHelper then click ok','JASSHelper',MB_ICONWARNING);
    try
        if (not FileExists(jasshelperdll)) then begin
            raise Exception.Create('Cannot find '+jasshelperdll);
        end;

        DeleteFile(jasshelpertargetdll);
        if (fileExists(jasshelpertargetdll)) then raise Exception.Create('Cannot update JASSHelper. Is WEHelper open?');
        CopyFile(pchar(jasshelperdll),pchar(jasshelpertargetdll),true);
        if (not fileExists(jasshelpertargetdll)) then raise Exception.Create('Copy failed');

        if (not FileExists(jasshelpercgt)) then begin
            raise Exception.Create('Cannot find '+jasshelpercgt);
        end;

        DeleteFile(jasshelpertargetcgt);
        if (fileExists(jasshelpertargetcgt)) then raise Exception.Create('Cannot update JASSHelper. Is WEHelper open?');
        CopyFile(pchar(jasshelpercgt),pchar(jasshelpertargetcgt),true);
        if (not fileExists(jasshelpertargetcgt)) then raise Exception.Create('Copy failed');


    except
       on e:Exception do begin
           Application.MessageBox(pchar(e.message),'Error',MB_ICONERROR);
           Halt;
       end;

    end;


    Application.MessageBox('JASSHelper was installed succesfully','JASSHelper', MB_ICONINFORMATION);
    Button1.Enabled:=false;
    Label1.Caption:='You can now use JASSHelper';

end;

procedure TForm3.Button2Click(Sender: TObject);
var
   s:AnsiString;
begin
   OpenDialog1.Filter:='WEHelper.exe|WEHelper.exe';
   if OpenDialog1.Execute then begin
       s:=ExtractFileDir(OpenDialog1.FileName);
       if(s[Length(s)]<>'\') then s:=s+'\';
       Edit1.Text:=s;
       SetTarget;
       button2.Enabled:=false;
       Button1.Enabled:=true;
   end;

end;

procedure TForm3.Button3Click(Sender: TObject);
begin
    Close;
end;

procedure TForm3.Button4Click(Sender: TObject);
var
 a:TAboutDialog;
begin
   a:=TaboutDialog.Create(self);
   a.ShowWEWarlock(false);
   a.ShowModal;
   a.Destroy;
end;

procedure TForm3.FormCreate(Sender: TObject);
var
   R:TRegistry;
begin

    JASSHELPERDLL:=ExtractFileDir(ParamStr(0))+'\jasshelper.dll';
    JASSHELPERCGT:=ExtractFileDir(ParamStr(0))+'\jasshelper.cgt';
    if (not FileExists(JASSHELPERDLL)) then begin
        Application.MessageBox(pchar('Unable to find jasshelper.dll at: '+JASSHELPERDLL),'Error',MB_ICONSTOP);
        Halt;
    end;
    if (not FileExists(JASSHELPERCGT)) then begin
        Application.MessageBox(pchar('Unable to find jasshelper.cgt at: '+JASSHELPERCGT),'Error',MB_ICONSTOP);
        Halt;
    end;





    Top:= (Screen.Height - Height) div 2;
    Left:= (Screen.Width - Width) div 2;

    R:=TRegistry.Create;
    if (R.OpenKey('\Software\WEHelper\',false)) then begin
        Edit1.Text:=R.ReadString('InstallPath');

        if (Edit1.Text='') or (not DirectoryExists(Edit1.Text)) then RequestMode
        else begin
            SetTarget;
        end;

    end else begin
        RequestMode;
    end;

end;

end.

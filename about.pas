unit about;
// The simple About form, why are you looking at this?

interface

uses
  Windows, {Messages, }SysUtils, {Variants,} Classes, Graphics, Forms,
  Dialogs, ExtActns, Controls, StdCtrls, ExtCtrls ;

type
  TAboutdialog = class(TForm)
    Button1: TButton;
    Label1: TLabel;
    Image1: TImage;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Label3Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
//    procedure Label4Click(Sender: TObject);
  private
    { Private declarations }
  public
     procedure ShowWEWarlock(b:boolean);

    { Public declarations }
  end;

var
  Aboutdialog: TAboutdialog;

//function MpqGetVersionString: LPCSTR; stdcall; external 'SFmpq.dll';

implementation
uses jasshelper;

{$R *.dfm}

procedure TAboutdialog.ShowWEWarlock(b:boolean);
begin
end;

procedure TAboutdialog.Button1Click(Sender: TObject);
begin
     close;
end;

procedure TAboutdialog.Label3Click(Sender: TObject);
var url:TBrowseUrl;
begin
     url:=TBrowseUrl.Create(label3);
     url.URL:='http://www.wc3campaigns.net';
     url.executetarget(nil);
end;


procedure TAboutdialog.FormShow(Sender: TObject);
begin
     Self.Label4.Caption:='Version : '+JassHelper.VERSION;
     Self.Left:=(Screen.Width-width) div 2;
     Self.Top:=(Screen.Height-height) div 2;

end;

end.

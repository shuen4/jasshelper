unit lookupconf;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm6 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Memo1: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    procedure Button3Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    b_ac:boolean;
  public
     property accepted:boolean read b_ac;

    { Public declarations }
  end;

var
  Form6: TForm6;


procedure doDialog(parent: Tform; var inout:TstringList);

implementation

uses folderbrowse;

{$R *.dfm}

procedure doDialog(parent: Tform; var inout:TstringList);
var i:integer;
begin
    Form6:=TForm6.Create(parent);
    for i := 0 to inout.Count - 1 do begin
        Form6.Memo1.Lines.Add(inout[i]);
    end;
    Form6.ShowModal;
    if(Form6.accepted) then begin
        inout.Clear;
        for i := 0 to Form6.Memo1.Lines.Count - 1 do
        if (Form6.Memo1.Lines[i]<>'') then
        begin
            inout.Add(Form6.Memo1.Lines[i]);
        end;
    end;

    Form6.Release;

end;

procedure TForm6.Button1Click(Sender: TObject);
begin
    b_ac:=true;
    Close;
end;

procedure TForm6.Button2Click(Sender: TObject);
begin
    Close;
end;

procedure TForm6.Button3Click(Sender: TObject);
var
   dir: String;
begin
dir:='.';
    if folderbrowse.GetFolderDialog(0,'Select a lookup folder.',dir) then begin
        Memo1.Lines.Add(dir)
    end;
end;

procedure TForm6.FormCreate(Sender: TObject);
begin
    b_ac:=false;
    Left:= (Screen.Width - width) div 2;
    Top:= (Screen.Height - height) div 2;
end;

end.

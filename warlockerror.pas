unit warlockerror;

interface

uses
  Windows, Messages, SysUtils, {Variants,} Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm2 = class(TForm)
    Memo1: TMemo;
    Memo2: TMemo;
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;
procedure ShowError(stdout,stderr:string; modal:boolean=false);
//var
//  Form1: TForm1;



implementation

{$R *.dfm}

procedure ShowError(stdout,stderr:string;modal:boolean=false);
var
   err:TForm2;
begin
     err:=TForm2.Create(nil);
     err.Width:=Screen.Width div 2;
     err.Height:=(Screen.Height*2) div 3;
     err.Memo1.Lines.LoadFromFile(Stdout);
     err.Memo2.Lines.LoadFromFile(Stderr);
    if(modal) then err.ShowModal
    else err.Show;

end;

procedure TForm2.FormClose(Sender: TObject; var Action: TCloseAction);
begin
     //Free;
end;

procedure TForm2.FormResize(Sender: TObject);
var
   x,y:integer;
begin
    x:=width-24;
    Memo1.Width:=x;
    Memo2.Width:=x;


    x:=height;
    y:=(x*6) div 10 - 24;
    Memo1.Height:=y;
    Memo2.Top:=y+17;
    Memo2.Height:= (x-y-59);


 SendMessage(Memo1.Handle,{ HWND of the Memo Control }

WM_VSCROLL,{ Windows Message }

SB_BOTTOM, { Scroll Command }

0);

SendMessage(Memo2.Handle,{ HWND of the Memo Control }

WM_VSCROLL,{ Windows Message }

SB_BOTTOM, { Scroll Command }

0);


end;

procedure TForm2.FormShow(Sender: TObject);
begin
MessageBeep(0);
end;

end.

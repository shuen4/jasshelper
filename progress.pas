unit progress;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls;

type
  TForm5 = class(TForm)
    ProgressBar1: TProgressBar;
    Label1: TLabel;
    Label2: TLabel;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form5: TForm5;

{type
  TJASSHelperInterface = class(TObject)
  public
      ProPosition:TJHIProPosition;
      ProMax:TJHIProMax;
      GetProMax:TJHIGetProMax;
      GetProPosition:TJHIGetProMax;
      ProStatus:TJHIStatus;
  end;
}

{TJHIProPosition = procedure(p:integer); stdcall;
TJHIProMax = procedure(max:integer); stdcall;
TJHIGetProMax = function:integer ; stdcall;
TJHIGetProPosition = function:integer ; stdcall;
TJHIStatus = procedure(const msg:string); stdcall;}

procedure show;
procedure stop;
procedure SetPosition(p:integer); stdcall;
function GetPosition:integer; stdcall;
function GetMax:integer;stdcall;
procedure SetMax(max:integer);stdcall;
procedure StatusMsg(const msg:string);stdcall;

implementation


procedure show;
begin
    Form5:=TForm5.Create(nil);
    Form5.Show;
end;

procedure stop;
begin

    Form5.Destroy;
end;

procedure SetPosition(p:integer); stdcall;
begin

    Form5.ProgressBar1.Position:=p;
    Form5.Update;

end;

function GetMax:integer;stdcall;
begin
    Result:=Form5.ProgressBar1.Max;
end;

function GetPosition:integer;stdcall;
begin
    Result:=Form5.ProgressBar1.Position;
    Form5.Update;
end;

procedure SetMax(max:integer);stdcall;
begin
    Form5.ProgressBar1.Max:=max;
    Form5.Update;
end;

procedure StatusMsg(const msg:string);stdcall;
begin
    Form5.Label1.Caption:=msg;
    Form5.Update;
end;




{$R *.dfm}

procedure TForm5.FormCreate(Sender: TObject);
begin
    Top:=(Screen.Height - Height) dIV 2-14;
    Left:=(Screen.Width - Width) dIV 2;

end;

end.

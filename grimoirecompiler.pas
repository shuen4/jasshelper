unit grimoirecompiler;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm4 = class(TForm)
    Memo1: TMemo;
    ListBox1: TListBox;
    Button1: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Edit1: TEdit;
    Button2: TButton;
    procedure Button2Click(Sender: TObject);
    procedure Memo1KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Memo1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Memo1KeyPress(Sender: TObject; var Key: Char);
    procedure Memo1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    function binarySearchusrijiyus(ini:integer; endi:integer; val:integer):integer;
    procedure updateLineLabel;
    { Private declarations }
  public
    { Public declarations }
  end;



var
  Form4: TForm4;
  filevar: textfile;
  errorn:integer=0;


procedure start(const f:string; const title:string);
procedure add(const line:integer; const msg:string; error:boolean);
procedure show;

procedure load;
procedure clear;

implementation

uses jasshelper,ShellApi,about,progress;
procedure start(const f:string; const title:string);
//var x:string;

begin

    AssignFile(filevar,'logs\compileerrors.txt');
    filemode:=fmOpenWrite;
    Rewrite(filevar);

    WriteLn(filevar,f);
    WriteLn(filevar,title);


    {Form4:=TForm4.Create(nil);
    Form4.Label1.Caption:=title;
    }
    errorn:=0;

end;

procedure add(const line:integer; const msg:string; error:boolean);
begin
    WriteLn(filevar,'Line '+IntToStr(line)+': '+msg);
    if(error) then errorn:=errorn+1;


 //   Form4.ListBox1.AddItem(,nil);


end;

procedure clear;
begin
    DeleteFile('logs\compileerrors.txt');
end;

// TMemo has a limit of 1024 characters per line
// Longer characters will be truncated to new lines
// Leading to incorrect line calculations
// This limitation may related to hardcoded values in Windows Multiline Edit Control
function fix_long_line(input:string): string;
var
    i,L,k,ln:integer;
    lines: array of string;
begin

    i:=1;
    L:=Length(input);
    k:=1;
    ln:=0;
    
    while (i<=L) do begin
        if (input[i]=#10) then begin
            ln:=ln+1;
            SetLength(lines,ln);
            if ((i>1) and (input[i-1]=#13)) then begin
                lines[ln-1]:=Copy(input,k,i-1-k);
                k:=i+1;
            end else begin
                lines[ln-1]:=Copy(input,k,i-k);
                k:=i+1;
            end;
            if (Length(lines[ln-1]) > 1024) then
                SetLength(lines[ln-1], 1024);
        end;
        i:=i+1;
    end;
    
    i:=0;
    Result := '';
    while(i<ln) do begin
        SWriteLn(Result,lines[i]);
        i:=i+1;
    end;
end;

procedure load;
var
   title:string;
   f,x:string;
begin

    if(not FileExists('logs\compileerrors.txt')) then begin
        MessageBox(0,'Jasshelper did not find any syntax error last time it was called','Jasshelper',MB_ICONINFORMATION);
        halt;
    end;

    progress.show;
    progress.StatusMsg('Errors found, please wait...');

    //try
    AssignFile(filevar,'logs\compileerrors.txt');
    filemode:=fmOpenRead;
    Reset(filevar);
    {except
       on e:exception do begin
            MessageBox(0,'Error ','!!',0);
       end;

    end;}
    ReadLn(filevar,f);
    ReadLn(filevar,title);


    Form4:=TForm4.Create(nil);

    JASShelper.LoadFile(f,x);
    Form4.Memo1.Text:=fix_long_line(x);
    Form4.Label1.Caption:=title;

    while(not EoF(filevar)) do begin
        ReadLn(filevar,x);
        if(tryStrToInt(x,errorn)) then
        else Form4.ListBox1.AddItem(x,nil)
    end;
    Close(filevar);

    
    if(errorn=1) then begin
        Form4.Label2.Caption:='Compile error.';
    end else begin
        Form4.Label2.Caption:=IntToStr(errorn)+' compile errors.';
    end;

    MessageBeep(0);
    progress.stop;
    Form4.ShowModal;
    Form4.Release;


end;



procedure show;
begin
    WriteLn(filevar,IntToStr(errorn));
    Close(filevar);
    //GetCurrentDir : much more portable than '.' , '.\' , '', nil , (towards WINE)
    ShellExecute(0, 'open', pchar(ParamStr(0)),'--showerrors', pchar(GetCurrentDir), SW_SHOWNORMAL) ;




end;

{$R *.dfm}

procedure TForm4.Button1Click(Sender: TObject);
begin
    Close;
end;

procedure TForm4.Button2Click(Sender: TObject);
var
 a:TAboutDialog;
begin
   a:=TaboutDialog.Create(self);
   a.ShowWEWarlock(false);
   a.ShowModal;
   a.Destroy;
end;

procedure TForm4.FormResize(Sender: TObject);
begin
    if(errorn>0) then begin
        ListBox1.ItemIndex:=0;
        ListBox1Click(Sender);
        errorn:=0;
    end;

    Memo1.Width:=ClientWidth-20;
    ListBox1.Width:=ClientWidth-20;
    Button1.Left:=ClientWidth-Button1.Width-10;

    Button1.Top := ClientHeight - Button1.Height - 6;
    Button2.Top := Button1.Top;
    Button2.Left := Button1.Left - Button2.Width - 5;
    Label3.Top:=Button1.Top+2;
    Edit1.Top:=Button1.Top;

    Memo1.Height := ClientHeight - Memo1.Top - Button1.Height - 12;
end;

procedure TForm4.FormShow(Sender: TObject);
begin
    Width:=(Screen.Width * 2) div 3;
    Height:=(Screen.Height * 2) div 3;
    Top:=(Screen.Height-Height) div 2;
    Left:=(Screen.Width - Width) div 2;
    errorn:=1;
end;

procedure TForm4.ListBox1Click(Sender: TObject);
var s:string;
    i:integer;

begin
    s:=ListBox1.Items[ListBox1.ItemIndex ];
    i:=6;//'Line
    while( (i<=Length(s)) and   (s[i]<>':')) do i:=i+1;

    if(i>Length(s)) then exit;
    i:=StrToInt(Copy(s,6,i-6));
    Memo1.SetFocus;
    Memo1.SelStart := Memo1.Perform(EM_LINEINDEX, i-3, 0);
    Memo1.SelLength:=1;
    update;
    Memo1.SelStart := Memo1.Perform(EM_LINEINDEX, i-2, 0);
    Memo1.SelLength:=1;
    update;
    Memo1.SelStart := Memo1.Perform(EM_LINEINDEX, i, 0);
    Memo1.SelLength:=1;
    update;
    Memo1.SelStart := Memo1.Perform(EM_LINEINDEX, i+1, 0);
    Memo1.SelLength:=1;
    update;

    Memo1.SelStart := Memo1.Perform(EM_LINEINDEX, i-1, 0);
    Memo1.SelLength := Memo1.Perform(EM_LINEINDEX, i, 0)-Memo1.SelStart-1;
    Edit1.Text:=IntToStr(i);

//    Memo1.SelStart := 12;
//    Memo1.SelLength := 100;
end;

function TForm4.binarySearchusrijiyus(ini:integer; endi:integer; val:integer):integer;
var q,r:integer;
begin

    if(ini>=endi) then begin
        Result:=endi;
        exit;
    end;
    q:=ini+(endi-ini)div 2;
    r:=Memo1.Perform(EM_LINEINDEX,q,0);
    if(r<val) then begin
        Result:=(binarySearchusrijiyus(q+1,endi,val));
    end else begin
        Result:=(binarySearchusrijiyus(ini,q,val));
    end;



{    while(r<endi) do begin
        if(Memo1.Perform(EM_LINEINDEX,r,0)>val) then begin
            r:=r-1;
            break;
        end;
        r:=r+1
    end;
    Result:=r;

{    if (Memo1.Perform(EM_LINEINDEX,endi,0)<val) then Result := endi

    else if(ini>=endi) then begin
        Result:=endi;
    end else begin

        q:=(endi-ini) div 2 + ini;
        r:=Memo1.Perform(EM_LINEINDEX,q,0);
        if(r=val) then Result:=q
        else if(r>val) then begin
            Result:=binarySearchusrijiyus(ini,q,val)
        end else begin
            Result:=binarySearchusrijiyus(q+1,endi,val);
        end;
    end;}


end;

procedure TForm4.updateLineLabel;
var

   i:integer;
begin
     i:=binarySearchusrijiyus(1,Memo1.Lines.Count,Memo1.SelStart+1);

{

     while(i<Memo1.Lines.Count) do begin
         if (Memo1.Perform(EM_LINEINDEX, i, 0)>Memo1.SelStart) then break;
         i:=i+1
     end;}


{     g.y:=1;
     Memo1.Perform(EM_POSFROMCHAR,Integer(Addr(g)),Memo1.SelStart );}
     Edit1.Text:=IntToStr(i);
end;

procedure TForm4.Memo1Click(Sender: TObject);
begin
    updateLineLabel;
end;

procedure TForm4.Memo1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
    updateLineLabel;
end;

procedure TForm4.Memo1KeyPress(Sender: TObject; var Key: Char);
begin
    updateLineLabel;
end;

procedure TForm4.Memo1KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
    updateLineLabel;
end;

end.

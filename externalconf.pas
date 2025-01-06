unit externalconf;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm7 = class(TForm)
    ListBox1: TListBox;
    Button1: TButton;
    Button2: TButton;
    Label1: TLabel;
    Edit1: TEdit;
    Label2: TLabel;
    Edit2: TEdit;
    Label3: TLabel;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    OpenDialog1: TOpenDialog;
    procedure Button5Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Edit2Change(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);

    procedure FormCreate(Sender: TObject);
  private
     b_ac:boolean;
     procedure enableItemEditor(b:boolean);
    { Private declarations }
  public
    { Public declarations }
    property accepted:boolean read b_ac;
  end;

var
  Form7: TForm7;

procedure doDialog(var names:TStringList; var paths:TstringList);


type
    Tstringhold = Class(TObject)
        s:AnsiString;
        constructor create(const ss:AnsiString);
    end;
implementation

{$R *.dfm}

procedure TForm7.Button1Click(Sender: TObject);
begin
   ListBox1.AddItem('newexternal',Tstringhold.create('z:\path\path.exe'));
   ListBox1.ItemIndex:=ListBox1.Count-1;
   ListBox1Click(self);
end;

procedure TForm7.Button2Click(Sender: TObject);
var
   i:integer;
begin
    i:=ListBox1.ItemIndex;
    ListBox1.Items.Delete(i);
    if (ListBox1.ItemIndex=-1) then enableItemEditor(false);
    

end;

procedure TForm7.Button3Click(Sender: TObject);
begin
   b_ac:=true;
   Close;
end;

procedure TForm7.Button4Click(Sender: TObject);
begin
    Close;
end;

procedure TForm7.Button5Click(Sender: TObject);
begin
    OpenDialog1.FileName:=Edit2.Text;

    if OpenDialog1.Execute(self.Handle) then begin
        Edit2.Text:=OpenDialog1.FileName;
    end;
end;

procedure TForm7.Edit1Change(Sender: TObject);
var i:integer;
begin
    i:=ListBox1.ItemIndex;
    ListBox1.Items[i]:=Edit1.Text;
end;

procedure TForm7.Edit2Change(Sender: TObject);
var i:integer;
begin
    i:=ListBox1.ItemIndex;
    Tstringhold(ListBox1.Items.Objects[i]).s:=Edit2.Text;
end;

procedure TForm7.enableItemEditor;
begin
    label1.Enabled:=b;
    label2.Enabled:=b;
    Edit1.Enabled:=b;
    Edit2.Enabled:=b;
    Button5.Enabled:=b;

end;

procedure TForm7.FormCreate(Sender: TObject);
begin
    enableItemEditor(false);
    Left:= (Screen.Width - width) div 2;
    Top:= (Screen.Height - height) div 2;
end;


procedure TForm7.FormDestroy(Sender: TObject);
//var i:integer;
begin
{   for i := 0 to ListBox1.Count - 1 do begin
        ListBox1.Items.Objects[i].Destroy;
   end;
}
end;

procedure TForm7.ListBox1Click(Sender: TObject);
var i:integer;
begin
    i:=ListBox1.ItemIndex;
    if(i<0) then begin
        enableItemEditor(false);
        exit;
    end else enableItemEditor(true);
    edit1.Text:=ListBox1.Items[i];
    edit2.Text:=Tstringhold(ListBox1.Items.Objects[i]).s;


end;

procedure doDialog(var names:TStringList; var paths:TstringList);
var
   i:integer;
begin
    form7:=Tform7.Create(nil);
    if (names.Count<>paths.Count) then raise Exception.Create('Internal error');
    for i := 0 to names.Count  - 1 do begin
         form7.ListBox1.AddItem(names[i],Tstringhold.create(paths[i]));
    end;
    Form7.ShowModal;
    if(Form7.accepted) then begin
        names.Clear;
        paths.Clear;
        for i := 0 to Form7.ListBox1.Count - 1 do begin
           names.Add(Form7.ListBox1.Items[i]);
           paths.Add( Tstringhold(Form7.ListBox1.Items.Objects[i]).s );
        end;
    end;
    Form7.Release;


end;


constructor Tstringhold.create(const ss: AnsiString);
begin
    s:=ss;
end;

end.

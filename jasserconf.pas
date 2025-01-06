unit jasserconf;

interface

uses
  Windows, {Messages, }SysUtils, {Variants,} Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;




type
  Tjasserconfig = class(TForm)
    CheckBox1: TCheckBox;
    Button1: TButton;
    Button3: TButton;
    OpenDialog1: TOpenDialog;
    Image1: TImage;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    procedure Button6Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);

    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
    var
     temLookupFolders:TstringList;
     temExternalNames:TstringList;
     temExternalPaths:TstringList;
     procedure UpdateConfig;

  public
    { Public declarations }
  end;


var
   ConfigFile:AnsiString;

   //PUPDATE:Tupdateconf;

   DebugMode: boolean;

   Lookupfolders:TStringList;
   Externalnames:TStringList;
   Externalpaths:TstringList;



procedure Load;
procedure Save;
procedure Dialog;

implementation
uses about, lookupconf, externalconf;

{$R *.dfm}

procedure Dialog;
var f:Tjasserconfig;
begin
    f:=Tjasserconfig.Create(nil);
    f.ShowModal;
    f.Release;
end;

procedure Save;
var
   f:textfile;
   open:boolean;
   i:integer;
begin
    {ConfigFile holds a valid file location}
    open:=false;
    try
    try
       AssignFile(f,ConfigFile);
       filemode:=fmOpenWrite;
       Rewrite(f); open:=true;


       //Write Lookup folders:
       if (Lookupfolders.Count>0) then begin
           WriteLn(f,'[lookupfolders]');
           i:=0; while(i<lookupfolders.Count) do begin
               Write(f,'"');Write(f,lookupfolders[i]);WriteLn(f,'"');
               i:=i+1;
           end;
       end;

       //Write Lookup folders:
       if (ExternalNames.Count>0) then begin
           if (Externalnames.Count<>ExternalPaths.Count) then raise Exception.Create('Oddity, counts don''t match');

           WriteLn(f,'[externaltools]');
           i:=0; while(i<ExternalNames.Count) do begin
               Write(f,'"');Write(f,ExternalNames[i]);Write(f,'","');Write(f,ExternalPaths[i]);WriteLn(f,'"');
               i:=i+1;
           end;
       end;
    finally
        if(open) then Close(f);
    end;
    except
       on e:exception do begin
           MessageBox(0,Pchar(e.Message),'Config Save Error',MB_ICONERROR);
       end;
    end;


end;

procedure Load;
var
   i,L,j:integer;
   line,a,b:AnsiString;
   f:textfile;
   s_path,s_ext,s_war:boolean;
begin
    {ConfigFile holds a valid file location}
     LookupFolders:=TstringList.Create;
     ExternalNames:=TStringList.Create;
     ExternalPaths:=TStringList.Create;

     DebugMode:=false;
     s_path:=false;s_ext:=false;s_war:=false;
     L:=0;
    if(fileexists(ConfigFile)) then begin
       Try
          Try
           Assign(f,ConfigFile);
           filemode:=fmOpenRead;
           Reset(f);
           while not EoF(f) do begin
               repeat
                   if(EoF(f)) then break;
                   ReadLn(f,line);L:=Length(line);
               until (L>1) and (line[1]<>'/');
               if(Eof(f) and ((L<=1) or (line[1]='/'))) then break;

               if (line[1]='[') then begin
                    //section
                    s_path:=false;
                    s_ext:=false;
                    s_war:=false;
                    if (line='[lookupfolders]') then s_path:=true
                    else if (line='[externaltools]') then s_ext:=true
                    else if (line='[wewarlock]') then s_war:=true;


                end else if (line[1]='"') then begin
                    if(s_ext) then begin
                        i:=2;
                        while( i<=L) and (line[i]<>'"') do i:=i+1;
                        if(i>L) then i:=L
                        else i:=i-1;
                        a:=Copy(line,2,i-1);
                        while (i<=L) and (line[i]<>',') do i:=i+1;
                        i:=i+1;
                        while (i<=L) and (line[i]<>'"') do i:=i+1;

                        if(i>L) then raise Exception.create('.conf file error:'#13#10'Missing program path entry for: '+a);
                        j:=i+1;
                        i:=j;
                        while( i<=L) and (line[i]<>'"') do i:=i+1;
                        if(i>L) then i:=L
                        else i:=i-1;
                        b:=Copy(line,j,i-j+1);

                        ExternalNames.Add(a);
                        ExternalPaths.Add(b);

                    end else if (s_path)  then begin
                        i:=2;
                        while( i<=L) and (line[i]<>'"') do i:=i+1;
                        if(i>L) then i:=L
                        else i:=i-1;
                        a:=Copy(line,2,i-1);
                        LookupFolders.Add(a);

                    end else if(s_war) then begin
                        i:=2;
                        while( i<=L) and (line[i]<>'"') do i:=i+1;
                        if(i>L) then i:=L
                        else i:=i-1;
                        a:=Copy(line,2,i-1);



                    end;
                end;
            end;
         finally
             Close(f);
         end;

       except
           on e:exception do begin
                MessageBox(0,Pchar(e.Message),'Config Load Error',MB_ICONERROR);
           end;
       end;
    end else begin
        //Default stuff: aka do nothing
    end;

end;



procedure Tjasserconfig.Button1Click(Sender: TObject);
begin
    UpdateConfig;
    Save;
    Close;
end;


procedure Tjasserconfig.Button3Click(Sender: TObject);
begin
    Close;
end;

procedure Tjasserconfig.Button4Click(Sender: TObject);
var
  ab:TAboutDialog;
begin
   ab:=TAboutDialog.Create(nil);
   ab.ShowWEWarlock(false) ;
   ab.ShowModal;
   ab.Free;

end;

procedure Tjasserconfig.Button5Click(Sender: TObject);
begin
    lookupconf.doDialog(self,TemLookupfolders);
end;

procedure Tjasserconfig.Button6Click(Sender: TObject);
begin
    externalconf.doDialog(TemExternalnames,TemExternalpaths);
end;

procedure Tjasserconfig.FormClose(Sender: TObject; var Action: TCloseAction);
begin
    //Free;
end;


procedure Tjasserconfig.FormCreate(Sender: TObject);
begin
    Temlookupfolders:=TStringList.Create;
    TemLookupFolders.AddStrings(LookupFolders);
    Temexternalnames:=TStringList.Create;
    TemExternalNames.AddStrings(ExternalNames);
    Temexternalpaths:=TStringList.Create;
    TemExternalPaths.AddStrings(ExternalPaths);
    CheckBox1.Checked:=DebugMode;



    Left:= (Screen.Width - width) div 2;
    Top:= (Screen.Height - height) div 2;
end;

procedure Tjasserconfig.UpdateConfig;
begin
    ExternalNames.Clear;
    ExternalNames.AddStrings(TemExternalNames);
    ExternalPaths.Clear;
    ExternalPaths.AddStrings(TemExternalPaths);
    LookupFolders.Clear;
    LookupFolders.AddStrings(TemLookupFolders);

    DebugMode:=CheckBox1.Checked;

end;
procedure Tjasserconfig.FormDestroy(Sender: TObject);
begin
    Temlookupfolders.Destroy;
    Temexternalnames.Destroy;
    Temexternalpaths.Destroy;
end;

end.

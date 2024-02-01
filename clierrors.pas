unit clierrors;

interface


procedure start(const f:string; const title:string);
procedure add(const line:integer; const msg:string; error:boolean);
procedure show;

procedure load;
procedure clear;


implementation

uses windows,shellapi,jasshelper,sysutils,classes;
var
  filevar: textfile;
  errorn:integer=0;

procedure start(const f:string; const title:string);
begin

    AssignFile(filevar,'logs\compileerrors.txt');
    filemode:=fmOpenWrite;
    Rewrite(filevar);

    WriteLn(filevar,f);
    WriteLn(filevar,title);

    errorn:=0;

end;

procedure add(const line:integer; const msg:string; error:boolean);
begin
    WriteLn(filevar,'Line '+IntToStr(line)+': '+msg);
    if(error) then errorn:=errorn+1;

end;
procedure show;
begin
    WriteLn(filevar,IntToStr(errorn));
    Close(filevar);
    //GetCurrentDir : much more portable than '.' , '.\' , '', nil , (towards WINE)
    load;

end;

function ParseLineNumber(const s:string):integer;
var
   i:integer;
begin
    Result:=0;
    for i := 1 to Length(s) do
       if(s[i]=':') then
           break
       else if(s[i] in ['0'..'9']) then
           Result:=Result*10 + Integer(s[i])-Integer('0');


end;
function compareByValue(Item1 : Pointer; Item2 : Pointer) : integer;
begin
     if(Integer(Item1) < Integer(Item2) ) then
         Result:=-1
     else if(Integer(Item1) > Integer(Item2) ) then
         Result:=1
     else
         Result:=0;
end;

procedure load;
var
   title:string;
   f,x:string;
    errored:textfile;

   line:string;
   linecount,y, lastprint, printedlines:integer;

   errorlines: Tlist;
begin
    errorlines := TList.create;

    if(not FileExists('logs\compileerrors.txt')) then begin
        WriteLn('Jasshelper did not find any syntax error last time it was called.');
        halt;
    end;

    //try
    AssignFile(filevar,'logs\compileerrors.txt');
    filemode:=fmOpenRead;
    Reset(filevar);

    ReadLn(filevar,f);
    ReadLn(filevar,title);

    WriteLn('');
    WriteLn('');
    Write(f+': ');
    if(errorn=1) then begin
        WriteLn('Compile error.');
    end else begin
        WriteLn(IntToStr(errorn)+' compile errors.');
    end;

    while(not EoF(filevar)) do begin
        ReadLn(filevar,x);
        if(tryStrToInt(x,errorn)) then
        else begin
            WriteLn(x);
            errorLines.add(Pointer(ParseLineNumber(x)) );
        end;
    end;
    errorLines.Sort(compareByValue);
    Close(filevar);
    filemode:=fmOpenRead;
    AssignFile(errored, f);
    Reset(errored);
    linecount:=1;
    lastprint:=-1;
    y:=0;
    printedlines := 0;
    while not Eof(errored) do begin
        ReadLn(errored, line);
        if(y < errorlines.count ) then begin
            if( abs(linecount-Integer(errorlines[y]))  <= 3 ) then begin
                printedlines := printedlines + 1;
                if(printedlines >= 100) then       begin
                    WriteLn('(and many more...)');
                    break;
                end;
                if(lastprint<>linecount-1) then
                    WriteLn('');
                lastprint:=linecount;
                WriteLn( IntToStr(linecount):6,' | ',line);
            end;
            if(linecount>Integer(errorlines[y])+2 ) then begin
                 y:=y+1;
            end;

        end;
        linecount:=linecount+1;

    end;




end;

procedure clear;begin
    DeleteFile('logs\compileerrors.txt');
end;


end.

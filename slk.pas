unit slk;

interface

uses
  Windows, Forms,Dialogs, Messages,StrUtils, SysUtils, Classes, Controls, StdCtrls,
  ComCtrls, IniFiles, ExtCtrls, Graphics, Math;

type TDynamicStringArray = array of string;
type TDynamicStringMat = array of array of string;

type
  TSLK = class(TObject)
  private
      data:TDynamicStringMat;
      id:string;
      garbage:string;
      tx:integer;
      ty:integer;
      pro:Tprogressbar;
      usepro:boolean;
  public
      function LoadFromFile(s:string):boolean;
      function LoadFromStream(var st:Tstream):boolean;
      property contents: TDynamicStringMat read data;
      property LengthX: integer read tx;
      property LengthY: integer read ty;

      constructor Create;
  end;





implementation

uses Jasshelper;

constructor TSLK.Create;
begin
   inherited Create;
   SetLength(data,1,1);
   tx:=1;
   ty:=1;
   data[0][0]:='';
   usepro:=false;
   pro:=nil;
end;

var
   readlnbuff:array of char;

function StreamReadLn(var st:Tstream):string;
var
 ch:char;
 lf,str:boolean;
 n:integer;

    procedure add(const cc:char);
    begin
        if(Length(readlnbuff)<=n) then begin
            SetLength(readlnbuff,n*2+1);
        end;
        readlnbuff[n]:=cc;
        n:=n+1;
    end;

begin
    Result:='';
    n:=0;

    lf:=false;
    str:=false;
    if (st.position<st.Size) then repeat
         st.Read(ch,1);
         if not(str) and (ch=#13) then begin
             st.Read(ch,1);
             if (ch=#10) then lf:=true
             else begin
                 add(#13);add(ch);
             end;
         end else if not(str) and (ch=#10) then begin
             lf:=true
         end else begin
             if (ch='"') then str:=not(str);
             add(ch);
         end;
    until (st.position>=st.Size) or lf;

    SetLength(Result,n);
    while n>0 do begin
        Result[n]:=readlnbuff[n-1];
        n:=n-1;
    end;


end;


function TSLK.LoadFromStream(var st:Tstream):boolean;
var
 i,L,x,y,anchor:integer;
 line,wor:string;

  function Token:string;
  var k:integer;
  begin
      Result:='';
      i:=i+1;
      k:=i;
      while (i<=L) and (line[i]<>';') do begin
          //Result:=Result+line[i];
          i:=i+1;
      end;
      Result:=Copy(line,k,i-k);
//      form1.DebugMemo.Lines.add(Result);
  end;

  function QuickInt(const s:string; a:integer; b:integer):integer;
  var k:integer;
  begin
      result:=0;
      for k := a to b do begin
          result:=result*10+ (integer(s[k])-48);
      end;
  end;

  function ParseB: boolean;
  begin
      i:=0;
      L:=Length(line);

      wor:=Token;  //B
      Result:= (wor='B');

      if (result) then begin
          wor:=Token;
          if (wor[1]='X') then x:=QuickInt(wor,2,Length(wor))
          else y:=QuickInt(wor,2,Length(wor));
          wor:=Token;
          if (wor[1]='X') then x:=QuickInt(wor,2,Length(wor))
          else y:=QuickInt(wor,2,Length(wor));

          {if (wor[1]='X') then x:=StrToInt(Copy(wor,2,Length(wor)-1))
          else y:=StrToInt(Copy(wor,2,Length(wor)-1));
          wor:=Token;
          if (wor[1]='X') then x:=StrToInt(Copy(wor,2,Length(wor)-1))
          else y:=StrToInt(Copy(wor,2,Length(wor)-1));}
          garbage:=Token;
      end;
  end;

  function ParseK:String;
  var j:integer;
  var wor2:string;
  begin

      i:=0;
      L:=Length(line);

      if (line<>'') and (line[1]='C') then begin
       Token;     //C
       Result:='';
       while (i<L) do begin
         wor2:=Token;
         if (wor2<>'') then begin
                  if (wor2[1]='X') then x:=QuickInt(wor2,2,Length(wor2))
             else if (wor2[1]='Y') then y:=QuickInt(wor2,2,Length(wor2))
             else if (wor2[1]='K') then begin
                 if(Length(wor2)>1) and (wor2[2]='"') then begin
                     Result:=Copy(wor2,3,Length(wor2)-3)
                 end else begin
                     Result:=Copy(wor2,2,Length(wor2)-1)
                 end;

                 //This is openoffice.org compatibility, it adds special quotes instead of normal ones.
                 j:=1;
                 while(j<=Length(Result)) do begin

//Special quote excel: $1B $29 $33/$34

                     if(Result[j]=#147) or (Result[j]=#148) then begin
                         Result[j]:='"';
                     end else
                     if ((Length(Result)>=j+2) and (Result[j]=#27) and (Result[j+1]=#41) and ((Result[j+2]=#51) or (Result[j+2]=#52) ) ) then begin
                         Result[j]:='"';
                         Result:=Copy(Result,1,j)+Copy(Result,j+3,Length(Result));
                     end;
                     //some new freaking openoffice quote:
                     if ((Length(Result)>=j+2) and (Result[j]=#226) and (Result[j+1]=#128) and ((Result[j+2]=#156) or (Result[j+2]=#157) ) ) then begin
                         Result[j]:='"';
                         Result:=Copy(Result,1,j)+Copy(Result,j+3,Length(Result));
                     end;

                     j:=j+1;
                 end;

             end;
             //end else begin Result:=''; Exit end;
         end;
       end;
      end else Result:='';
  end;

begin
    st.Position:=0;
    if (st.position>=st.size) then begin  Result:=false; Exit; end;
    line:=StreamReadLn(st);
    if (Copy(line,1,2)<>'ID') then begin  Result:=false; Exit; end;
    id:=line;
    if (st.position>=st.size) then begin  Result:=false; Exit; end;
    //ResetPro(st.size);
    anchor:=st.Position;
    repeat
        line:=StreamReadLn(st);
        //MovePro(st.Position);
    until (st.position>=st.Size) or ParseB;
    if st.position>=st.Size then begin
       // raise exception.create('@'); Result:=false; Exit;
       line:='';
       st.position:=anchor;
    end else begin
        SetLength(data,x,y);
        tx:=0;
        ty:=0;
    end;
    x:=1;
    y:=1;
//    SetLength(data,100,1000);
    while (st.position<st.size) and (line<>'E') do begin
        //MovePro(st.Position);
        line:=StreamReadLn(st);
        if (line<>'E') then begin
            wor:=ParseK;
            if (wor<>'') then begin
                if(x > tx) then begin
                    if(y>ty) then begin
                        tx:=x;
                        ty:=y;
                        SetLength(data,x,y);
                    end else begin
                        tx:=x;
                        SetLength(data,x,ty);
                    end;
                end else if(y>ty) then begin
                    ty:=y;
                    SetLength(data,tx,y);
                end;
                data[x-1][y-1]:=wor;
            end;
        end;
    end;
    //RestorePro;
    Result:=true;
end;


function TSLK.LoadFromFile(s:string):boolean;
var st:Tfilestream;
begin
    st:=TFileStream.Create(s,fmOpenRead);

//    st.LoadFromFile(s);
    Result:=LoadFromStream(Tstream(st));
    st.Destroy;
end;









end.

unit jasslib;
//unit that parses Jass library files (common.j / blizzard.j maybe)?
interface
 uses
    Classes, SysUtils, StringHash ;

 type

   JassLibException = class(Exception)
       public
          msg : string;
          line: integer;
   end;

   TJassType = class(TObject)
   public
       name   : string;
       extends: string;
   end;

   TJassVar = class(TObject)
   public
       name : string;
       typename : string;
       isconstant : boolean;
       isarray : boolean;
       initialvalue : string;
   end;

   TJassFunc = class(TObject)
   public
       isnative : boolean;
       name : string;
       arguments: Array of String;
       argumentn : integer;
       returntype : string;
       isconstant : boolean;
   end;


procedure Init;
function VerifyJassFunc( const name:string; out tpoint:TJassFunc ): boolean;
function VerifyJassVar( const name:string; out tpoint:TJassVar ): boolean;
function VerifyJassType( const name:string; out tpoint:TJassType ): boolean;
procedure parseFile( const filename: TFileName);

// Adds a native line, returns false if the native was already known...
function AddNativeLine( const s:string): boolean;

implementation
uses Jasshelper;
// As common.j may have functions and blizzard.j may have natives, there is actually no difference
// between them, it seems, so this single thing parses both.

var
   VarHash : TStringHash;
   TypeHash: TStringHash;
   FuncHash: TStringHash;
   VarArray : Array of TJassVar;
   FuncArray : Array of TJassFunc;
   TypeArray : Array of TJassType;


   VarCount : integer;
   TypeCount : integer;
   FuncCount : integer;
   interf : TJasshelperInterface;

   input: TDynamicStringArray;
   ln : integer;



procedure Init;
begin
    VarHash := TStringHash.Create;
    TypeHash := TStringHash.Create;
    FuncHash := TStringHash.Create;
    VarCount := 0;
    TypeCount :=0;
    FuncCount :=0;
    interf := Jasshelper.Interf;
end;

procedure LoadLines( const filename: TFileName);
 var
    buf, line:string;
    i,k,L: integer;
begin
    if(interf<>nil) then begin
        interf.ProStatus('Opening: '+filename);
    end;
    JassHelper.LoadFile(filename, buf);
    L:= Length(buf);
    if(interf<>nil) then begin
        interf.ProStatus('Loading: '+filename);
        interf.ProMax(L);
        interf.ProPosition(0);
    end;
    ln:=0 ;
    i:=1;
    k:=0;

    while ( i<=L+1) do begin
        if(interf<>nil) and (i mod 1000 = 0) then
            interf.ProPosition(i);
        if (i=L+1) or ( buf[i] = #13 ) or (buf[i]=#10) then begin
            line := Copy(buf,k+1, i-k - 1);
            if( i+1<=L ) and (buf[i] =#13) and (buf[i+1]=#10) then
                i:= i +1;
            k:=i;
            if(Length(input) <= ln) then
                SetLength(input, ln+5 + i*(L-i) div (ln+1) );
            input[ln] := line;
            ln:=ln+1;

        end;

        i:=i+1;
    end;
    if(interf<>nil) then
        interf.ProPosition(L);






end;

procedure ParseVariableLine( const line:string);
var
    nextStartPos:integer;
    s:string;
begin
    // try to find out JASS_MAX_ARRAY_SIZE (it should be safe if we only check the first occurrence since more than one is a syntax error)
    // although the script may have JASS_ARRAY_SIZE with value 0 but who cares
    if (JassHelper.JASS_ARRAY_SIZE <> 0) then
        exit;
    nextStartPos:=1;
    // constant integer JASS_MAX_ARRAY_SIZE = value
    GetLineToken(line,s,nextStartPos,nextStartPos);
    if (s = 'constant') then
        GetLineToken(line,s,nextStartPos,nextStartPos);
    if (s <> 'integer') then
        exit;
    GetLineToken(line,s,nextStartPos,nextStartPos);
    if (s <> 'JASS_MAX_ARRAY_SIZE') then
        exit;
    {
    '=' is in SEPARATORS and will ignore by GetLineToken
    we dont use GetLineWord because it fails if there are no spaces before/after "="
    GetLineToken(line,s,nextStartPos,nextStartPos);
    if (s <> '=') then
        exit;
    }
    GetLineToken(line,s,nextStartPos,nextStartPos);
    if (not TryStrToIntX(s, nextStartPos{this variable is no longer used, so just use it for other usage})) then
        exit;
    JassHelper.JASS_ARRAY_SIZE := nextStartPos - 1;
end;
procedure ParseTypeLine( const s:string);
begin
   //we really don't need this yet, do we?
end;

var
argumentsbuf:array of string;

function ParseFuncLine( const constant:boolean ; const native:boolean; const s:string; var x:integer):boolean;
var
    y:integer;
    name, word:string;
    func: TJassFunc;
begin

    GetLineWord(s, name, x,x);
    Result:=false;
    if(FuncHash.ValueOf(name)<>-1 ) then exit;
    if (not CompareLineWord('takes',s,x,x) ) then
        exit;
    Result:=true;

    if(Length(FuncArray) = FuncCount) then
        SetLength( FuncArray, 5+FuncCount + FuncCount div 5);
    func := TJassFunc.Create;
    func.isconstant := constant;
    func.isnative:=native;
    FuncArray[FuncCount ] := func;
    FuncHash.add(name, FuncCount);
    FuncCount := FuncCount + 1;
    func.name:=name;
    func.argumentn:=0;

    if not CompareLineWord('nothing',s,y,x) then begin
        //we got arguments!!111
        while(true) do begin
            GetLineToken(s,word,y,x);
            if(word='returns') then break;
            if(word='') then begin
                 break;
            end;
            x:=y;
            if(Length(argumentsbuf) <= func.argumentn) then
                SetLength(argumentsbuf, func.argumentn+5);
            argumentsbuf[func.argumentn] := word;
            GetLineToken(s,word,x,x);
            func.argumentn:=func.argumentn+1;
        end;
        SetLength(func.arguments,func.argumentn);
        for y := 0 to func.argumentn - 1 do
            func.arguments[y]:=argumentsbuf[y];

    end else x:=y;
    CompareLineWord('returns',s,x,x);
    GetLineWord(s,func.returntype,x,x);

end;


function AddNativeLine( const s:string): boolean;
var x:integer;
    word:string;
    constant:boolean;
begin
    GetLineWord(s, word, x);
    constant := (word='constant');
    if constant then
        GetLineWord(s, word,x,x);
    Result:=ParseFuncLine(constant, true, s,x);
end;


procedure parseStuff;
var
 i,x:integer;
 glob, constant:boolean;
 word:string;


begin
    if(interf<>nil) then begin
        interf.ProStatus('Parsing...');
        interf.ProMax(ln);
        interf.ProPosition(0);
    end;
    glob := false;
    i:=0;
    while(i<ln) do begin
        if(interf<>nil) and (i mod 1000 = 0) then
            interf.ProPosition(i);
        GetLineWord(input[i],word,x);
        if ( (word <> '') and (word[1]<>'/') and (word[2]<>'/') ) then begin
            // i don't think we need to check syntax since no one except testing will pass an invalid script
            if (word = 'globals') then
                glob := true
            else if(glob) then begin
                if( word = 'endglobals') then glob:=false
                else ParseVariableLine(input[i]);
            end else if (word ='type') then begin
                ParseTypeLine(input[i]);
            end else begin
                constant := (word = 'constant');
                if(constant) then GetLineWord(input[i],word,x,x);
                if(word='native') or (word='function') then
                    ParseFuncLine(constant, (word='native'), input[i], x);
            end;

        end;

        i:=i+1;
    end;
    if(interf<>nil) then
        interf.ProPosition(ln);

end;


procedure parseFile( const filename:TfileName);
begin

    LoadLines(filename);
    ParseStuff;

end;


function VerifyJassType( const name:string; out tpoint:TJassType ): boolean;
begin
    Result := false;
end;


function VerifyJassFunc( const name:string; out tpoint:TJassFunc ): boolean;
var k:integer;
begin
    k:=FuncHash.ValueOf(name);
    Result := (k<>-1);
    if(Result) then begin
        tpoint:= FuncArray[k];  
    end;

end;

function VerifyJassVar( const name:string; out tpoint:TJassVar ): boolean;
begin
    Result := false;
end;





end.

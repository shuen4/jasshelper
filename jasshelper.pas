unit jasshelper;

interface

uses
  Windows, SysUtils, Classes, StringHash, slk,
  GrammarReader, GOLDParser, Symbol, Token, jasshelpersymbols, jasslib;

//{$define ZINC_DEBUG}
const VERSION:String = '0.A.5.1';
type TDynamicStringArray = array of string;
type TDynamicIntegerArray = array of integer;


   JASSerException = class(Exception)
   private

   public
      linen:integer;
      msg:string;
      two:boolean;
      linen2:integer;
      msg2:string;
      macro1:integer;
      macro2:integer;
   end;

   //Not really an stack, it was going to be an stack but I found out I needed more
   //options than push and pop.
   Tscopestack = class(TObject)
   private
      ascope: array of string;
      adecl: array of integer;
      aprivpref:array of string;
      apblicpref:array of string;
      adescope: array of string;
      n:integer;
   public
       constructor create;
       procedure push(const scope:string; const descope:string; const decl:integer; const privpref:string; const pblicpref:string);
       procedure top(var scope:string; var descope:string; var decl:integer; var privpref:string; var pblicpref:string);
       procedure pop;
       function empty:boolean;
       procedure makeprivate(d:integer;var s:string; id:integer);
       procedure makepublic(d:integer;var s:string; id:integer);
       function bottomline:integer;
       function GetScopeDecl(d:integer): string;
       function list(ignoretop:boolean=false ) :string;
       function GetScopeId(d:integer): integer;
       function MakePrefix(pri:boolean):string;
   end;

   Ttextmacro = class(TObject)
   private
       contents:array of string;
       contentssize:integer;
       args:array of string;
       argsn:integer;
   public
       decl:integer;
       constructor create;
       procedure run(var replaceto:TDynamicStringArray);
       procedure addArgument(const s:string);
       procedure add(const s:string);
       procedure reserveSpace(s:integer);

   end;

   const JASS_ARRAYS_BEFORE_SPLIT=1;
   const EXTERNAL_SIZE_LIMIT=1000;

   const SLK_LOADSTRUCTS_BATCHSIZE = 100;

   const ACCESS_PUBLIC=0;
   const ACCESS_PRIVATE=1;
   const ACCESS_READONLY=2;
   type Tmember = class(TObject)

   private
       abuseexecv:boolean;
   public
       isstatic:boolean;
       isstaticarray:boolean;
       access:integer;
       ignore:boolean;
       ismethod:boolean;
       construct:boolean;
       destruct:boolean;
       decl:integer;
       abuse:boolean;
       fromparent:boolean;
       stub:boolean;

       oninit_value:string;
       oninit_struct:string;
       name:string;
       returntype:string;
       argnumber:integer;
       argtypes:array of string;
       argnames:array of string;

       arraydummy:integer;
       interdefault: string;

       //1:attribute, 2:private attribute, 3:method, 4:private method, 5:constructor, 6:private constructor, 7:destructor, 8:private destructor.
       //11: static attribute
       //12: static private attribute-
       constructor create(d:integer; const s:string; accs:integer; sta:boolean; method:boolean);
       procedure addarg(const t:string; const n:string);
       procedure abuseexecset(const b:boolean);

       property abuseexec:boolean read abuseexecv write abuseexecset;
   end;


   type Tfunction = class(TObject)
       PrototypeId: integer;
       decl:integer;
       abuse:boolean;
       name:string;


   end;

   type Tfunctionprototype = class(TObject)
   public


       args:Array of string;
       res: string;
       argn:Integer;

       addedtoscript : boolean;

       childfunctions: Tstringhash;

       funccount:integer;
       abuse:boolean;

       function GetId(const s:string):integer;
       constructor Create( iargs:TDynamicStringArray; iargsn:integer; ires:string);
       destructor Destroy; override;
   end;

   Tstruct = class(TObject)
   private
       oninitv:string;
       function getOnInit:string;
   public


       decl:integer;
       endline:integer;
       typeid:integer;
       name:string;

       modulesOnInit:string;


       membershash:TStringHash;
       members:array of Tmember;
       membern:integer;

       delegates:array of Tmember;
       delegateN:integer;


       ondestroy:Tmember;
       ondestroydone:boolean;
       zincstruct:boolean;
       parent:integer;
       parentstruct : integer;
       parentname:string;
       isarraystruct:boolean;
       isinterface:boolean;
       gotstructchildren:boolean;
       gotStubMethods:boolean;
       children:array of integer;
       nchildren:integer;

       customarray:integer;
       customarraytype:string;

       requiredspace: integer;

       maximum:integer;

       lessthan: string;

       forInternalUse:boolean;

       addedArrayControl:boolean;
       containsarraymembers:boolean;
       FunctionInterfacePrototype:integer;

       bigArrayId:integer;

       dofactory:boolean;
       noargumentcreate:boolean;
       customcreate:boolean;

       constructor create(d:integer;int:boolean);
       procedure addchild(i:integer);
       function addmember(d:integer; const s:string;accs:integer; sta:boolean; method:boolean):tmember;
       procedure addDelegate(memb:tmember);
       function getmember(const s:string; var res:Tmember):boolean;

       procedure makeArrayStruct();

       procedure dropmember(const s:string);
       procedure addModuleOnInit(const s:string);
       procedure BeforeDestruction; override;

       function GetSuperParentName:string;
       function GetSuperParentNameForMethod(const methodname:string):string;
       property oninit:string read GetOnInit write oninitv;
       property superparentname:  string read GetSuperParentName;
   end;

   Tarray = class(Tobject)
   public
       decl:integer;
       name:string;
       oftype:string;
   end;

   TexternalUsage=class(TObject)
   public
        n:integer;
        name:array of string;
        args:array of string;
        stdin:array of string;
        ext:array of string;
        pos:array of integer;
        constructor create;
        procedure add(const na:string; const a:string; const i:integer; const ex:string = ''; const si:string = '' );
        procedure reset;
   end;


   Tdynamicstructarray = array of Tstruct;
{   Toutputstring =class(Tobject)
   private
       c:array of char;
       n:integer;
       function strread:string;
   public
       constructor Create(inisz:integer);
       procedure add(c:char);overload;
       procedure add(s:string);overload;
       property str:string read strread;
   end;}

TJHIProPosition = procedure(p:integer); stdcall;
TJHIProMax = procedure(max:integer); stdcall;
TJHIGetProMax = function:integer ; stdcall;
TJHIGetProPosition = function:integer ; stdcall;
TJHIStatus = procedure(const msg:string); stdcall;

type
  TJASSHelperInterface = class(TObject)
  public
      ProPosition:TJHIProPosition;
      ProMax:TJHIProMax;
      GetProMax:TJHIGetProMax;
      GetProPosition:TJHIGetProMax;
      ProStatus:TJHIStatus;
  end;

var
  Interf:TJASSHelperInterface=nil;
  REQUIREFOUND:integer=0;
  FORGETIMPORT:boolean=false;
  AUTOMETHODEVALUATE:boolean = false;
  AFTERIMPORT:string;
  GRAMMARPATH:string='jasshelper.cgt';

  IMPORTUSED:boolean;
  Parser:TGoldParser=nil;

  COMMONJ: Tfilename = '';
  BLIZZARDJ: Tfilename = '';
  WARCITY:boolean=false;
  ZINC_MODE:boolean=false;
  MACROMODE:boolean=false;
  DEBUG_MODE:boolean=false;
  JASS_ARRAY_SIZE:integer=0;
  VJASS_MAX_ARRAY_INDEXES:integer=0;
  all_handle, reference_counted_obj:array of string;

const UPDATEVALUE=100;

type
    Tvtype = class(Tobject)
    public
        id:integer;
        name:string;
        tag:string;
    end;

function MakeType(const id:integer):Tvtype; overload; forward;
function MakeType(const id:integer; const name:string):Tvtype; overload; forward;
function MakeType(const id:integer; const name:string; const tag:string):Tvtype; overload; forward;


procedure DoJASSerMagic(f1:string; f2:string; debug:boolean);overload;


function DoJASSerMagic(sinput:string; debug:boolean):string; overload;
procedure DoJasserBlocksMagic;

procedure DoStructModuleMagic();

function getExternalUsage(var r:Texternalusage):boolean;


procedure processTextMacros;
procedure ProcessZinc(const debug:boolean);
function CompareSubString(const s:string; st:integer; en:integer; const val:string):boolean;

procedure DoJASSerStructMagic(sinput:string;const debug:boolean; var Result:string);overload;
procedure DoJASSerStructMagic(f1:string;f2:string;const debug:boolean);overload;

procedure DoJASSerInlineMagicS(sinput:string; var Result:string);
procedure DoJASSerInlineMagicF(const f1:string; const f2:string);

procedure DoJASSerReturnFixMagicS(sinput:string; var Result:string);
procedure DoJASSerReturnFixMagicF(const f1:string; const f2:string);

procedure DoJASSerShadowHelperMagicS(sinput:string; var Result:string);
procedure DoJASSerShadowHelperMagicF(const f1:string; const f2:string);

function ArrayStringContains(const arr: array of string; const value: string): Boolean;
procedure DoJASSerNullLocalMagicS(sinput:string; var Result:string);
procedure DoJASSerNullLocalMagicF(const f1:string; const f2:string);


procedure LoadFile(const FileName: TFileName; var result:string);
procedure SaveFile(const FileName: TFileName; const result:string);
procedure doJassHelperExternals(const maplocation:string);

procedure importPathsClear;
procedure addImportPath(const s:string);

function fetchPath(var path:string; const current:string=''):boolean;

procedure InitFunctionPrototypes;
procedure CleanFunctionPrototypes;
function GetFunctionPrototype( args:TDynamicStringArray; argn:integer; returntype:string):integer;
procedure parseFunction(const s:string; decl:integer);
function translateMethodOfFunction(const f:string; const fid:integer; const memb:string; const args:string; var res:string; var typ:Tvtype):boolean;
function translateMemberOfFunction(const f:string; const fid:integer; const memb:string; var res:string; var typ:Tvtype):boolean;
function translateMethodOfFunctionPointer(const f:string; const st:tstruct; const memb:string; const args:string; var res:string; var typ:Tvtype):boolean;
function translateMemberOfFunctionInterface(const f:string; const st:tstruct; const memb:string; var res:string; var typ:Tvtype):boolean;

procedure MakeFunctionCallers(var output:string);
procedure NormalizeFunctionArguments;
procedure buildFunctionActions(var output:string);
procedure buildIniFunctionActions(var output:string);


function translateDotMethod(const obj:string; const memb:string; const args:string; styp:Tvtype; var res:string; var typ:Tvtype;   fromstruct:integer; const pos:integer; const execute:boolean=false; const fromsuper:boolean=false; const evaluate:boolean=false ):boolean;
function TryStrToIntX(const s:string;var x:integer):boolean;
procedure generateMultiArrayPickerBatch(const n:integer; namepref:TDynamicStringArray; namesuf:TDynamicStringArray; const indexspace:integer; const index:string; const indent:integer; commandprefix:TDynamicStringArray; commandsufix:TDynamicStringArray; var outs:string; const inioff:integer=0; const iniindex:integer = 1; const continueif:boolean = false);
    procedure generateMultiArrayPicker(const namepref:string; const namesuf:string; const indexspace:integer; const index:string; const indent:integer; const commandprefix:string; const commandsufix:string; var outs:string);


procedure Concatenate3(var res:string; const s1,s2,s3:string);
procedure Concatenate4(var res:string; const s1,s2,s3,s4:string);
procedure Concatenate5(var res:string; const s1,s2,s3,s4,s5:string);
procedure Concatenate6(var res:string; const s1,s2,s3,s4,s5,s6:string);
procedure Concatenate7(var res:string; const s1,s2,s3,s4,s5,s6,s7:string);
procedure Concatenate8(var res:string; const s1,s2,s3,s4,s5,s6,s7,s8:string);
procedure Concatenate9(var res:string; const s1,s2,s3,s4,s5,s6,s7,s8,s9:string);
procedure Concatenate10(var res:string; const s1,s2,s3,s4,s5,s6,s7,s8,s9,s10:string);
procedure Concatenate13(var res:string; const s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13:string);
function RConcatenate3(const s1,s2,s3:string):string;
function RConcatenate6(const s1,s2,s3,s4,s5,s6:string):string;

procedure GetLineWord(const  line:string; var st:string ; var sti:integer; ival:integer=1);
function CompareLineWord(const match:string; const  line:string; var sti:integer; ival:integer=1):boolean;
procedure GetLineToken(const line: string; var st:string ; out sti:integer; ival:integer=1);

procedure SWriteLn(var s:string; const l:string);

const   SEPARATORS: set of char=[ '.', '(',' ',#9,')' , ',', '+', '-', '*', '/' ,'"', '''', '=','!', '<', '>','[',']',':' ];

implementation
uses ZincParser, JassHelperConfigFile;


const  VERYBIG= 2147483647;

type
   THook = class(Tobject)
       isMethod: boolean;
       funcid: integer;
       memb: Tmember;
       struct:Tstruct;
   end;
   THookedNative = class(Tobject)
       nativename:string;
       hooks: Tlist;
   end;
var
   HookedNatives : Tlist;
   HookedNativeHash: TStringHash;


type
   TLibrary = class(TObject)
   public
       name: string;
       req: array of string;
       req_opt: array of boolean;
       reqn: integer;
       contents: string;
       globals: string;
       validatedinit:boolean;
       declaration: integer;
       Init: string;

   end;
var
   importpaths:array of string;
   importpathn:integer=0;

   input: array of string;
   offset:array of integer;
   textmacrotrace:array of integer;
   globaltextmacrotrace:integer;
   globaloffset:integer;

   globals: string='';

   premainarea: string;
   postmainarea: string;
   libraries: array of TLibrary;
   library_usedinit:boolean=false;
   libraryn:integer;

   ScopeInit:array of string;
   ScopeInitN:integer;



   ln:integer;
   writefactor:integer=1;
   WHITESPACE_SEPARATORS : set of char=[' ',#9];

   NUMBERS: set of char=['0','1','2','3','4','5','6','7','8','9'];
   NONNUMBERSIDENTIFCHAR: set of char=[ 'a'..'z', 'A'..'Z', '_'];
   IDENTIFCHARS: set of char=[ '0'..'9' , '_' , 'a'..'z', 'A'..'Z'];

   Exter: Texternalusage=nil;

   datafunctions: array of string;
   datafunctions_N:integer;
   datafunctions_Current:integer;

   //globals for struct processing
   HashtableKeys: integer;
   StructHash:Tstringhash;
   RequiredSizeHash:Tstringhash;
   IntegerConstants:Tstringhash;
   IdentifierTypes:Tstringhash;
   LocalIdentifierTypes: Tstringhash;

   StructList: TDynamicStructArray;
   TopSortedStructList: array of integer;
   StructN: integer;


   //globals for global big arrays:
   BigArrayN:integer;
   BigArrayHash:Tstringhash;
   BigArrayTypes: array of string;
   BigArrayNames: array of string;
   BigArraySizes: array of integer;
   BigArrayWidths: array of integer;
   BigArrayStructs: array of integer;
   BigArrayDeclLines: array of integer;

   //---
   badHandleHash:TstringHash;

   Prototype: Array of Tfunctionprototype;
   ProtoHash: Tstringhash;
   PrototypeN: integer=0;

   FunctionData: Array of Tfunction;
   FunctionDataN: integer=0;
   FunctionHash: Tstringhash;

   FunctionDataUsed: boolean = false;

   RecCurrentLine : integer =0;


//external usage!
constructor Texternalusage.create;
begin

    N:=0;
end;

procedure Texternalusage.reset;
begin
    N:=0;
end;
procedure Texternalusage.add(const na:string; const a:string; const i:integer; const ex:string; const si:string);
begin
    if(Length(name)<=N) then begin
        SetLength(name,N+1);
    end;
    if(Length(args)<=N) then begin
        SetLength(args,N+1);
    end;
    if(Length(pos)<=N) then begin
        SetLength(pos,N+1);
    end;
    if(Length(stdin)<=N) then begin
        SetLength(stdin,N+1);
    end;
    if(Length(ext)<=N) then begin
        SetLength(ext,N+1);
    end;

    name[N]:=na;
    args[N]:=a;
    stdin[N]:=si;
    pos[N]:=i;
    ext[N]:=ex;
    N:=N+1;


end;

//<TSCOPESTACK>
constructor TScopeStack.Create;
begin
    n:=0;
end;
procedure TScopeStack.push (const scope:string; const descope:string; const decl:integer; const privpref:string; const pblicpref:string);
begin
    n:=n+1;
    SetLength(ascope,n);
    SetLength(adescope,n);
    SetLength(adecl,n);
    SetLength(aprivpref,n);
    SetLength(apblicpref,n);
    ascope[n-1]:=scope;
    adescope[n-1]:=descope;
    adecl[n-1]:=decl;
    aprivpref[n-1]:=privpref;
    apblicpref[n-1]:=pblicpref;
end;
procedure TScopeStack.top(var scope:string;var descope:string; var decl:integer; var privpref:string; var pblicpref:string);
begin
   scope:=ascope[n-1];
   descope:=adescope[n-1];
   privpref:=aprivpref[n-1];
   pblicpref:=apblicpref[n-1];
   decl:=adecl[n-1];
end;
procedure TScopeStack.pop;
begin
   n:=n-1;
end;
function TScopeStack.empty:boolean;
begin
    Result:=(n<=0);
end;
procedure TScopeStack.MakePrivate(d:integer;var s:string; id:integer);
begin
    if(d>=n) or (adecl[d]<>id) then Exit;
    s:=aprivpref[d]+s;
end;

function TScopeStack.MakePrefix(pri:boolean):string;
begin
   if(pri) then result:='"'+aprivpref[n-1]+'"'
   else result:='"'+apblicpref[n-1]+'"';
end;


function TScopeStack.GetScopeDecl(d:integer): string;
begin
     if(d>=n) then begin
         Result:='';
     end else
         Result:=adescope[d];
end;
function TScopeStack.GetScopeId(d:integer): integer;
begin
     if(d>=n) then begin
         Result:=0;
     end else
         Result:=adecl[d];
end;
procedure TScopeStack.MakePublic(d:integer;var s:string; id:integer);
begin
    if(d>=n) or (adecl[d]<>id) then Exit;
    if (s='InitTrig') then s:=s+'_'+Copy(apblicpref[d],1,Length(apblicpref[d])-1)
    else s:=apblicpref[d]+s;
end;
function TScopeStack.bottomline:integer;
begin
    Result:=adecl[0];
end;
function TScopeStack.list(ignoretop:boolean=false ):string;
var
   i:integer;
begin
    Result:=ascope[0];
    if(ignoretop) then
    for i := 1 to n - 2 do begin
        Result:=Result+', '+ascope[i];
    end
    else
    for i := 1 to n - 1 do begin
        Result:=Result+', '+ascope[i];
    end;

end;
//</TSCOPESTACK>

//<TTextMacro>

//</TTextMacro>

procedure SWriteLn(var s:string; const l:string);
begin
    Insert(l, s, VERYBIG);
    Insert(#13#10, s, VERYBIG);
end;

procedure SWriteLnSmart(var s:string; const l:string);
var len:integer;
begin
    Insert(l, s, VERYBIG);
    len:=Length(s);
    if( (len>=2) and (s[len]=#10) and (s[len-1]=#13)) then exit; 
    Insert(#13#10, s, VERYBIG);
end;


procedure SWrite(var s:string; const l:string);
begin
    Insert(l, s, VERYBIG);
end;



{
line : '     call    BJDebugMsg() '
st   : 'call'
sti  : 10
}
procedure GetLineWord(const  line:string; var st:string ; var sti:integer; ival:integer=1);
var
 i,L:integer;
 commprotect:boolean;
begin


   L:=Length(line);
   if (L=0) then begin
       sti:=0;
       st:='';
       exit;
   end;
   i:=ival;
   //st:='';
   // because // is accepted after keywords it also handles //
   while (i<=L) do begin
      if (line[i] in [' ',#9]) then i:=i+1 //#9 is tab
      else break;
   end;
   commprotect := ((i>L) or (line[i]<>'/'));
   sti:=i+1;
   while (sti<=L) do begin
        if ( commprotect and (line[sti]='/') and (sti<L) and (line[sti+1]='/')) then begin
            //st:=Copy(line,i,sti-1);
            break;
        end;

        if (line[sti] in [' ',#9]) then break;
        sti:=sti+1;
   end;
   st:=Copy(line,i,sti-i);
end;

function CompareLineWord(const match:string; const  line:string; var sti:integer; ival:integer=1):boolean;
var
 i,L:integer;
begin

   L:=Length(line);
   if (L=0) then begin
       Result:=(match='');
       exit;
   end;
   i:=ival;
   //st:='';
   // because // is accepted after keywords it also handles //
   while (i<=L) do begin
      if (line[i] in [' ',#9]) then i:=i+1 //#9 is tab
      else break;
   end;
   sti:=i+1;
   while (sti<=L) do begin
        if ((line[sti]='/') and (sti<L) and (line[sti+1]='/')) then begin
            //st:=Copy(line,i,sti-1);
            break;
        end;

        if (line[sti] in [' ',#9]) then break;
        sti:=sti+1;
   end;
   Result:=CompareSubString(line,i,sti-1,match);
end;

function CompareLineToken(const match:string; const  line:string; var sti:integer; ival:integer=1):boolean;
var
 i,L:integer;
begin

   L:=Length(line);
   if (L=0) then begin
       sti:=1;
       Result:=(match='');
       exit;
   end;
   i:=ival;
   //st:='';
   // because // is accepted after keywords it also handles //
   while (i<=L) do begin
      if (line[i] in SEPARATORS) then i:=i+1 //#9 is tab
      else break;
   end;
   sti:=i+1;
   while (sti<=L) do begin
        if (line[sti] in SEPARATORS) then break;
        sti:=sti+1;
   end;
   Result:=CompareSubString(line,i,sti-1,match);
end;




function nonNumeralPrefix(const s:string; p:integer):boolean;

begin
    result:=false;
    while (p>0) and (s[p] in NUMBERS) do begin
        p:=p-1;
    end;
    if(p<=0) then exit;
    if(s[p] in SEPARATORS) then exit;

    if (s[p] in NONNUMBERSIDENTIFCHAR ) then result:=true;

end;

procedure GetLineToken(const line: string; var st:string ; out sti:integer; ival:integer=1);
var
 i,L:integer;

begin

   L:=Length(line);
   if (L=0) then begin
       sti:=0;
       st:='';
       exit;
   end;
   i:=ival;
   //st:='';

   // because // is accepted after keywords it also handles //
   while (i<=L) do begin
      if( line[i] = '"') then begin
          i:=i+1;
          while(i<=L) do begin
              if(line[i]='"') then break;
              if(line[i]='\') then i:=i+1;
              i:=i+1;
          end;
          i:=i+1;
      end else if( line[i] = '''') then begin
          i:=i+1;
          while(i<=L) and (line[i]<>'''') do
              i:=i+1;
          i:=i+1;

      end else if line[i] in SEPARATORS then i:=i+1
      else if
      (line[i]='.')
      and
      ((i=1)
          or nonNumeralPrefix(line,i-1))
       and ( (i=L)
          or not(line[i+1] in NUMBERS) ) then
          i:=i+1
       //support for struct syntax.
      else break;
   end;
   sti:=i+1;
   while (sti<=L) do begin
        if line[sti] in SEPARATORS then break;
        sti:=sti+1;
   end;
   st:=Copy(line,i,sti-i);
end;


function TestGetLineWord(line:string;i:integer):string;
var j:integer;
begin
    GetLineWord(line,Result,j,i);
end;

procedure GetLineWordAlsoComma(line:string; var st:string ; var sti:integer; ival:integer=1);
var
 i,L:integer;
begin

   L:=Length(line);
   if (L=0) then begin
       sti:=0;
       st:='';
       exit;
   end;
   i:=ival;
   //st:='';
   while (i<=L) do begin
      if (line[i] in [' ',#9,',']) then i:=i+1 //#9 is tab
      else break;
   end;
   sti:=i+1;
   while (sti<=L) do begin
        if (line[sti] in [' ',#9,',']) then break;
        sti:=sti+1;
   end;
   st:=Copy(line,i,sti-i);
end;

function IsWhitespace(const s:string; const st:integer=1):boolean;
var i,L:integer;
begin
    i:=st;
    L:=Length(s);
    Result:=false;
    while (i<=L) do
    if (s[i]=' ') or (s[i]=#9) then i:=i+1
    else begin
        if (s[i]='/') and (i<L) and (s[i+1]='/')  then result:=true;
        break;
    end;
    result:=result or (i>L);

end;

function GetEndOfUsefulLine(const s:string):integer;
var i,L,j:integer;
ctr:boolean;
begin
    L:=Length(s);
    if(IsWhiteSpace(s) or (L=0) ) then begin
         result:=1;
         exit;
    end;
    i:=1;

    while (i<=L) do begin
        if (s[i]=' ') or (s[i]=#9) then begin
            j:=i+1;
            while(j<=L) and ((s[j]=' ')or(s[j]=#9)) do j:=j+1;
            if (j>L) or ((j+1<=L) and (s[j]='/') and (s[j+1]='/')) then begin
                result:=i;
                exit;
            end;
            i:=j;
        end else if(i<=L+1) and (s[i]='/') and (s[i+1]='/') then begin
            result:=i;
            exit;
        end else if(s[i]='''') then begin
            if(i+2<=l) and (s[i+2]='''') then i:=i+3
            else i:=i+6;
        end else if (s[i]='"') then begin
            ctr:=false;
            i:=i+1;
            while(i<=L)do begin
                if(ctr) then ctr:=false
                else if(s[i]='\') then ctr:=true
                else if(s[i]='"') then break;
                i:=i+1;

            end;
            i:=i+1;
        end else i:=i+1;
    end;
    result:=L+1;

end;

// s[a] is the beginning of a string, moves a to the end of such string or b,
// whatever comes first.
procedure SkipString(const s:string; var a:integer; const b:integer);
var ctr:boolean;
begin
    if(s[a]='''') then begin
        if(a+2<=b) and (s[a+2]='''') then a:=a+2
        else if(a+5<=b) then a:=a+5
        else a:=b;
        exit;
    end;

    if(s[a]='"') then begin
        ctr:=false;        
        a:=a+1;
        while(a<b) do begin
            if(ctr) then ctr:=false
            else if(s[a]='\') then ctr:=true
            else if(s[a]='"') then break;
            a:=a+1;
        end;


    end;
end;

procedure SkipUselessBrackets(const s:string; var a:integer; var b:integer);
var i,par,ra,rb:integer;


begin
    ra:=a;
    rb:=b;
    while(true) do begin
        while( (ra<rb) and ((s[ra]=' ')or (s[ra]=#9) ) ) do ra:=ra+1;
        if(ra=rb) then break; //why give this function a bunch of whitespace?
        while( (rb>ra) and ((s[rb]=' ')or (s[rb]=#9) ) ) do rb:=rb-1;
        if(s[rb]<>')') or(s[ra]<>'(') then break;
        //are these useful?
        i:=ra+1;
        par:=0;
        while(i<=rb-1) and (par>=0) do begin
            if(s[i]='(') or (s[i]='[') then  par:=par+1
            else if(s[i]=')') or (s[i]=']') then par:=par-1
            else if(s[i]='''') or (s[i]='"') then SkipString(s,i,rb-1);

            i:=i+1;

        end;
        if(par<>0) then break; //not useless / error
        ra:=ra+1;
        rb:=rb-1;

    end;
    a:=ra;
    b:=rb;
end;

function JASSerLineException(i:integer;msg:string):JASSerException;
begin
   Result:=JASSerException.Create(msg  );
   Result.msg:=msg;
   Result.linen:=i+offset[i];
   Result.two:= false;
   Result.macro1:=textmacrotrace[i]-1;
   Result.macro2:=-1;


end;

procedure VerifyEndOfLine(const s:string; const st:integer; LineNumber:integer);
var i,L:integer;
begin
   if(not IsWhitespace(s,st)) then begin
       i:=st;
       L:=Length(s);
       while (i<=L) do begin
           if(s[i]='/') and (i<L) and (s[i+1]='/') then begin
                break;
           end;
           i:=i+1;
       end;

       raise JasserLineException(LineNumber,'Unexpected: "'+Copy(s,st,i-st)+'"');

   end;
end;


function JASSerLineExceptionNoTextMacro(i:integer;msg:string):JASSerException;
begin
   Result:=JASSerException.Create(msg);
   Result.msg:=msg;
   Result.linen:=i;
   Result.two:= false;
   Result.macro1:=-1;
   Result.macro2:=-1;

end;


function JASSerLineDoubleException(i:integer;msg:string; j:integer; msg2:string):JASSerException;
begin
   Result:=JASSerException.Create(msg);
   Result.msg:=msg;
   Result.linen:=i+offset[i];
   Result.two:= true;
   Result.msg2:=msg2;
   Result.linen2:=j+offset[j];

   Result.macro1:=textmacrotrace[i]-1;
   Result.macro2:=textmacrotrace[j]-1;

end;

function JASSerLineDoubleExceptionNoTextMacro(i:integer;msg:string; j:integer; msg2:string):JASSerException;
begin
   Result:=JASSerException.Create(msg);
   Result.msg:=msg;
   Result.linen:=i;
   Result.two:= true;
   Result.msg2:=msg2;
   Result.linen2:=j;

   Result.macro1:=-1;
   Result.macro2:=-1;

end;




procedure GetRealLine(var i:integer; var line:string );
var
 j,L,anchor, strcount:integer;
 ctl,str,raw:boolean;

 c:char;


begin
    //line:='';
    ctl:=false;
    str:=false;
    raw:=false;

    { lots of threats, for example "aaa
     aa f f"  is a valid string, also "aaa\"aaa" and "aaadf\\"

      There is also the infamous '"' which does not open an string
     }
    anchor:=i;

    strcount:=0;
    while (i<=ln) do begin

        j:=1;
        L:=Length(input[i]);
        while j<=L do begin
            c:=input[i][j];

            if (str) then begin
                strcount:=strcount+1;
                if (ctl) then ctl:=false
                else if (c='"') then begin
                    str:=false;
                    strcount:=0;
                end
                else if (c='\') then ctl:=true;
                if (strcount>1100) then begin
                    raise JASSerLineException(anchor,'String literal size limit exceeded /unclosed string');
                end;

            end else if (raw) then begin
                if (c='''') then raw:=false;

            end else if ( (c='/') and (j<L)   and (input[i][j+1]='/')) then begin
                //found a comment, end.
                j:=L;

            end else if (c='"') then begin
                 str:=true;
                 strcount:=0;
            end
            else if (c='''') then raw:=true;

            j:=j+1;
        end;

        if (i<>anchor) then Insert(input[i],line, VERYBIG );

        if (str) then begin
            //doh, string didn't end the line yet;
            i:=i+1;
            Insert('\n',line, VERYBIG ); //It is handy and prevents pjass from returning the wrong line number


        end
        else break;
    end;
    if (str) then raise JASSerLineException(anchor,'Unclosed string');




end;


function validScopeName(const s:string):boolean;
var
   i,L:integer;
begin
    i:=1;
    L:=Length(s);
    Result:=true;
    while(i<=L) do begin
        if ((s[i]>='a') and (s[i]<='z')) or ((s[i]>='A') and (s[i]<='Z') or ((s[i] in ['0'..'9'])and(i>1)) ) then
            i:=i+1
        else begin
            Result:=false;
            break;
        end;
    end;

end;


function validIdentifierName(const s:string):boolean;
var
   i,L:integer;
begin
    i:=1;
    L:=Length(s);
    Result:=true;
    while(i<=L) do begin
        if ((s[i]>='a') and (s[i]<='z')) or ((s[i]>='A') and (s[i]<='Z')) or ( (((s[i]>='0') and (s[i]<='9')) or (s[i]='_')) and(i>1)) then
            i:=i+1
        else begin
            Result:=false;
            break;
        end;
    end;

end;


// requires a,b,c,d,
procedure parseLibrary(var line:string; var lib:TLibrary; beginp:integer; linenumber:integer; const libraryname:string);
var
   j,k:integer;
   word:string;
   optional:boolean;
begin
    lib.reqn:=0;
    lib.declaration:=linenumber;



    lib.name:=libraryname;
    GetLineWord(line,word,j,beginp);
    lib.validatedinit:=true;
    if (word='initializer') then begin
        GetLineToken(line,word,j,j);
        lib.Init:=word;
        library_usedinit:=true;
        if(not IsWhiteSpace(line,j)) then
            GetLineWord(line,word,j,j) //So requires works later
        else
            word:='';
        lib.validatedinit:=false;
    end else lib.Init:='';

    if ((word='needs')or(word='requires')or(word='uses')) then begin

        //parse requirements
        word:='';
        k:=Length(line);
        while (j<=k) do begin
            if(isWhiteSpace(line,j)) then break;

             GetLineToken(line,word,j,j);
             if(word='') then break;
             if(word='initializer') then begin
                  raise JASSerLineException(linenumber,'Please place initializer before the requirements.');
             end;
             optional := (word='optional');
             if(optional) then begin
                 GetLineToken(line, word, j, j);
             end;

             if ( Length(word)>=2) and (word[1]='/') and (word[2]='/') then break;
             lib.reqn:= lib.reqn +1;
             SetLength(lib.req,lib.reqn);
             SetLength(lib.req_opt,lib.reqn);
             lib.req[lib.reqn-1]:=word;
             lib.req_opt[lib.reqn-1] := optional;
        end;
        if (lib.reqn=0) then raise JASSerLineException(linenumber,'Missing requirements but requires keyword used : '+lib.name);

    end else if ( Length(word)>=2) and (word[1]='/') and (word[2]='/') then begin
       //comment
    end else if (word<>'') then raise JASSerLineException(linenumber,'Not a valid library declaration: ['+word+']?');









end;



procedure ReplaceTokens(var hash:TStringHash; var currenthash:TStringHash; var stack:TScopeStack; var s:string; deleteprivate:boolean);
var
  o,token:string;
  i,L,k,x,d:integer;
  str,ctr,now:boolean;

    procedure replacetoken;
    begin
        x:=hash.ValueOf(token);
        if (x>0) then begin
            d:=(x-1) div 2;
            if (x mod 2=0) then //it is public
                stack.makepublic(d,token,currenthash.valueof(token) )
            else
                stack.makeprivate(d,token,currenthash.valueof(token));
        end else if (token='SCOPE_PREFIX') then token:=stack.makeprefix(false)
        else if( token='DEBUG_MODE') then begin
            if(DEBUG_MODE) then
                token:='true'
            else
                token:='false';
        end else if (token='SCOPE_PRIVATE') then token:=stack.makeprefix(true);


    end;
begin
    o:=s;
    s:='';
    i:=1;
    str:=false;
    ctr:=false;
    now:=false;
    k:=1;
    L:=Length(o);
    while (i<=L) do begin
        if (str) then begin
            if (ctr) then ctr:=false
            else begin
                if (o[i]='"') then begin
                     str:=false;
                     k:=i+1;
                end else if (o[i]='\') then ctr:=true;
            end;

            Insert(o[i],s,VERYBIG);

        end else if (o[i]='"') then begin
            if (k<>i) then begin
                token:=Copy(o,k,i-k);
                replacetoken;
                 if (deleteprivate) then begin
                    if (token='private')or(token='public') then {now:=true}
                    else Insert(token,s,VERYBIG);
                end else Insert(token,s,VERYBIG);

            end;
            str:=true;
            Insert(o[i],s,VERYBIG);
        end else if ((o[i]='/') and (i<L) and (o[i+1]='/')) then begin
            break;

        end else if (o[i] in SEPARATORS) or ( (o[i]='.') and ((i=L) or not(o[i+1] in NUMBERS) ) and ((i=1) or nonNumeralPrefix(o,i-1) )  ) then begin
            if (k<>i) then begin
                token:=Copy(o,k,i-k);
                replacetoken;
                if (deleteprivate) then begin
                    if (token='private')or(token='public') then now:=true
                    else Insert(token,s,VERYBIG);
                end else Insert(token,s,VERYBIG);
            end;

            k:=i+1;
            if(now) then begin
                i:=i+1;
                now:=false;
            end else Insert(o[i],s,VERYBIG);

        end;
        i:=i+1;
    end;
    if ((k<>i) and not(str)) then begin
        token:=Copy(o,k,i-k);
        replacetoken;
        Insert(token,s,VERYBIG);
    end;
    while (i<=L) do begin //for comments/preprocessors
        Insert(o[i],s,VERYBIG);
        i:=i+1;
    end;

end;

function ReplaceIdentifier(const s:string; const orig:string; const newt:string):string;
var
    i,L,k:integer;
    inraw,instring,ctr, incom,add:boolean;
//    IDENTIFCHARS

begin
    instring:=false; ctr:=false;
    inraw:=false;
    incom:=false;
    Result:='';
    L:=Length(s);
    i:=1;
    while(i<=L) do begin
        add:=true;
        if(incom) then
        else if( inraw) then begin
            if( s[i]='''') then inraw:=false;
        end else if (instring) then begin
            if(ctr) then ctr:=false
            else if(s[i] = '\') then ctr:=true
            else if( s[i]='"') then instring:=false;
        end else if(s[i]='/') and (i<L) and (s[i+1]='/')  then
            incom:=true
        else if (s[i] in IDENTIFCHARS) then begin
            k:=i+1;
            while( (k<=L) and (s[k] in IDENTIFCHARS) ) do k:=k+1;
            if(CompareSubString(s,i,k-1, orig) ) then
                Insert(newt,result,VERYBIG)
            else
                Insert(Copy(s,i,k-i),result,VERYBIG);
            add:=false;
            i:=k-1;
        end;
        if(add) then
            Insert(s[i],result,VERYBIG);
        i:=i+1;
    end;


end;

function ReplaceIdentifiersByHash(const s:string; var hash:TStringHash; const prefix:string):string;
var
    i,L,k:integer;
    inraw,instring,ctr, incom,add:boolean;
    tem:string;
//    IDENTIFCHARS

begin
    instring:=false; ctr:=false;
    inraw:=false;
    incom:=false;
    Result:='';
    L:=Length(s);
    i:=1;
    while(i<=L) do begin
        add:=true;
        if(incom) then
        else if( inraw) then begin
            if( s[i]='''') then inraw:=false;
        end else if (instring) then begin
            if(ctr) then ctr:=false
            else if(s[i] = '\') then ctr:=true
            else if( s[i]='"') then instring:=false;
        end else if(s[i]='/') and (i<L) and (s[i+1]='/')  then
            incom:=true
        else if (s[i] in IDENTIFCHARS) then begin
            k:=i+1;
            while( (k<=L) and (s[k] in IDENTIFCHARS) ) do k:=k+1;
            tem:=Copy(s,i,k-i);
            if( hash.ValueOf(tem)<>-1 ) then
                Insert(prefix+tem,result,VERYBIG)
            else
                Insert(tem,result,VERYBIG);
            add:=false;
            i:=k-1;
        end;
        if(add) then
            Insert(s[i],result,VERYBIG);
        i:=i+1;
    end;


end;


function CompareSubString(const s:string; st:integer; en:integer; const val:string):boolean;
var
  L1,L2,j:integer;
begin
    L1:=Length(s);
    L2:=Length(val);

    if (en-st+1<>L2) then begin
        Result:=false;
        Exit;
    end;
    if ((en>L1) or (st<1)) then begin
         Result:=false;
         exit;
    end;
    j:=1;
    while (st<=en) do begin
        if (s[st]<>val[j]) then begin
            Result:=false;
            Exit;
        end;
        j:=j+1;
        st:=st+1;
    end;
 Result:=true;

end;


procedure VerifyValidForDebug(const s:string; decl:integer);
var x:integer;
    word:string;
begin
{s's first 'word' is debug}

    exit;

    if ( CompareLineWord('debug',s,x) ) then begin
     GetLineToken(s,word,x,x);
     if (word='local') or (word='set') or (word='exitwhen')
            or (word='loop') or (word='endloop') or (word='if') or (word='elseif')
            or(word='else') or (word='endif') or (word='call')
            or (word='hook') or(word='implement')
            then
     else
         raise JasserLineException(decl, 'Incompatible statement for debug: "'+word+'"');
    end;


end;

procedure parseInput(debug:boolean);
var
 i,j,k,r,wordend,updatetime,updateinterval,scopelevelid,scopeid:integer;

 globalsdecl,anchor,structdecl:integer;
 period,nextperiod,injectpos:integer;
 word{,line},libpreffix_private,libpreffix_public,tmp,scope,declscopename,injectmain,postinjectmain,injectconfig:string;
 once,skip,ininjectmain,ininjectpostmain,usedmaininject,usedconfiginject,inconfiginject,skipfunction,validatedscopeinit:boolean;
 hash:TStringHash;
 scopehash:TStringHash;
 linehash:TStringHash;

 currenthash:TStringHash;

 noreplacetokens,tolibrary,toglobals,add,post,inmain,privateused,onscope,ispublic{, commusedwas //! used?}:boolean;

 scopeinitializer:string;


 stack:TScopeStack;

 ExternalBlockStdin, ExternalBlockName, ExternalBlockArgs, ExternalBlockExtension:string;
 ExternalBlockLn: integer;


     procedure newscope(const b:boolean);
     begin
          scopeid:=i;
          if (not validScopeName(scope)) then raise JASSerLineException(i,'Invalid scope name : '+scope);
          declscopename:=scope;
          if (onscope) then begin
               stack.top(word,tmp,j,tmp,tmp);
               scope:=word+'_'+scope;
          end;
          j:=scopehash.ValueOf(scope);
          if(j>0) then begin
              raise JASSerLineDoubleException(i,'Scope redeclared : '#39+scope+#39,j,'`---- previously declared here');
          end else begin
              scopehash.Add(scope,i);
          end;


          scopelevelid:=scopelevelid+2;
          if(GetTickCount mod 2 = 0) then libpreffix_private:=scope+'__'
          else libpreffix_private:=scope+'___';
          libpreffix_public:=scope+'_';
          stack.push(scope,declscopename,scopeid,libpreffix_private,libpreffix_public);
          onscope:=true;
          if(b) then input[k]:='// scope '+scope+' begins';
     end;
     procedure outscope;
     begin
         if(stack.empty) then begin
             raise JasserLineException(i,'Unexpected endscope/endlibrary');
         end;
         stack.pop;
         if (stack.empty) then begin
             onscope:=false;
             privateused:=false;
             scopelevelid:=0;
         end else begin
            stack.top(scope,declscopename,scopeid,libpreffix_private,libpreffix_public);
            scopelevelid:=scopelevelid-2;
         end;
     end;

     procedure addScopeInit( const s: string);
     begin
         if (length(ScopeInit)<=ScopeInitN) then begin
             SetLength(ScopeInit,1+ScopeInitN+2*(ScopeInitN div 5));
         end;
         ScopeInit[ScopeInitN]:=s;
         ScopeInitN:=ScopeInitN+1;
     end;

     procedure addpublicforparents;
     var h:integer;
     var xword:string;
     begin
          xword:=word;
          h:=scopelevelid-2;
          while(h>0) do begin
              xword:=stack.GetScopeDecl( h div 2 )+'_'+xword;
              currenthash.Add(xword,stack.GetScopeId( (h-1) div 2));
              linehash.Add(xword,i);
              hash.Add(xword,h);
              h:=h-2;
          end;

     end;

     procedure addscopeword({wordisscope:boolean=false});
     var
        tmpi:integer;
     begin
          if(not validIdentifierName(word) ) then begin
              raise JASSERLineException(i,'Not a valid identifier name: "'+word+'"');
          end;
          tmpi:=hash.valueof(word);
          if (tmpi>0) and (tmpi<=scopelevelid-2) then begin
              tmpi:=linehash.ValueOf(word);
              if(tmpi=-1) then raise JASSERLineException(i,'Internal error');

              raise JASSERLineDoubleException(i,'Scope Identifier: '+word+' already declared in a parent scope: '+stack.list(true) ,tmpi,'\--- (previously declared here)');
          end;
          tmpi:=currenthash.ValueOf(word);
          if (tmpi=scopeid) then begin
              tmpi:=linehash.ValueOf(word);
              if(tmpi=-1) then raise JASSERLineException(i,'Internal error');

              if(input[tmpi]='//!keyword-public') then begin
                  if(not ispublic) then raise JASSERLineDoubleException(i,'Unable to change access flag for: '+word,tmpi,'\--- (previously declared here, as public)');

              end else if(input[tmpi]='//!keyword-private') then begin
                  if(ispublic) then raise JASSERLineDoubleException(i,'Unable to change access flag for: '+word,tmpi,'\--- (previously declared here, as private)');
              end
              else raise JASSERLineDoubleException(i,'Scope symbol redeclared: '+word,tmpi,'\--- (previously declared here)');
          end;

          currenthash.Add(word,scopeid);
          if(ispublic) then begin
              hash.Add(word,scopelevelid);
              addpublicforparents;
              linehash.Add(word,i);
          end else begin
              hash.Add(word,scopelevelid-1);
              linehash.Add(word,i);
          end;
     end;

     procedure beginLibrary;
     begin
                        privateused:=false;
                        add:=false;
                        if (tolibrary) then raise JASSerLineDoubleException(i,'Library nesting is not allowed.',libraries[libraryn-1].declaration,'Previous library declared here.');
                        if (onscope) then raise
                            JASSerLineDoubleException(i,'declaration of libraries inside of scope blocks not allowed',stack.bottomline,'`---- (open scopes: '+stack.list+')');

                        GetLineWord(input[k],word,wordend,wordend);
                        //We got the name?
                        if (word='') then raise JASSerLineException(i,'Found Unnamed library');
                        if (not validScopeName(word)) then raise JASSerLineException(i,'Invalid library name : '+word);
                        skip:=false;
                        // prevent redeclaration.
                        j:=0;
                        while(j<libraryn) do begin
                          if (libraries[j].name=word) then begin
                            if(once) then begin
                               skip:=true;
                               break;
                            end else begin
                                raise JASSerLineException(i,'library redeclared : '+word);
                            end;
                          end;
                          j:=j+1
                        end;

                        if(skip) then begin

                            anchor:=i;
                            input[anchor]:='// redeclaration of library '+word+' skipped';
                            i:=i+1;
                            while(i<=ln) do begin
                                k:=i;
                                GetRealLine(i,input[k]);
                                GetLineWord(input[k],word,wordend);

                                if(word='//!') then GetLineWord(input[k],word,wordend,wordend);
                                if(word='endlibrary') then break
                                else if (word='library') then
                                        raise JASSerLineDoubleException(i,'Library nesting is not allowed.',anchor,'Previous library declared here.');

                                i:=i+1;
                            end;
                            if(i>ln) then raise JASSerLineException(anchor,'Missing endlibrary');
                            input[k]:=input[anchor];
                            add:=true;
                        end else begin
                            tolibrary:=true;
                            j:=libraryn;
                            libraryn:=libraryn+1;
                            SetLength(libraries,libraryn);

                            libraries[j]:=TLibrary.Create;

                            libraries[j].contents:='';

                            //Parse the library and requirements
                            parseLibrary(input[k],libraries[j],wordend,i,word);
                            SWriteLn(libraries[j].globals,'constant boolean LIBRARY_'+libraries[j].name+'=true');
                            scope:=libraries[j].name;
                            newscope(false);
                        end;
     end;

     procedure endLibrary;
     begin
                        add:=false; //It is the end of a library!
                        if (not tolibrary) then raise JASSerLineException(i,'Unexpected endlibrary.');

                        if (not libraries[libraryn-1].validatedInit) then begin
                            if(libraries[libraryn-1].init='onInit') then begin
                                libraries[libraryn-1].init:='';
                                libraries[libraryn-1].validatedInit:=true;
                            end else
                                 raise JASSerLineException(libraries[libraryn-1].declaration,'Unable to find prototype: function '+libraries[libraryn-1].init+' takes nothing returns *** inside the library.');
                        end;
                        tolibrary:=false;
                        outscope;
     end;

begin

    //A line can go to 3 places: globals section, a library or main area.
    //Need to take care of : comments, strings/rawcodes (so we ignore stuff inside them
    // * Library preprocessor
    // * globals keyword
    hash:=TstringHash.Create();
    scopehash:=Tstringhash.Create();
    currenthash:=Tstringhash.Create();
    linehash:=Tstringhash.create();

    ScopeInitN:=0;
    scopeinitializer:='';
    validatedscopeinit:=false;

        injectpos:=-1;
        globals:='';
        toglobals:=false;
        globalsdecl:=-1;
        scope:='';
        declscopename:='';
        onscope:=false;
        injectconfig:='';
        injectmain:='';
        ininjectmain:=false;
        ininjectpostmain:=false;
        postinjectmain:='';
    premainarea:='';
    usedmaininject:=false;
    usedconfiginject:=false;
    inconfiginject:=false;
    skipfunction:=false;
    postmainarea:='';
    libpreffix_private:='';
    libpreffix_public:='';
    libraryn:=0;
    library_usedinit:=false;
    tolibrary:=false;
    updatetime:=0;
    stack:=TScopeStack.create;
    scopelevelid:=0;
    scopeid:=0;


    i:=0;
    post:=false;
    updateinterval:=ln div UPDATEVALUE;
    inmain:=false;
    REQUIREFOUND:=0;
    scope:='';
    privateused:=false;
//    commused:=false;

    structdecl:=-1;

    if(interf<>nil) then begin
        interf.ProStatus('Libraries - parsing...');
    end;

    if(exter<>nil) then exter.reset
    else exter:=TExternalusage.create;

try
 try
    while (i<ln) do begin
        if (Interf<>nil) then begin
            if (updatetime=updateinterval) then begin
               Interf.ProPosition(i);
               updatetime:=0;
            end else updatetime:=updatetime+1;

        end;
        add:=true;
        //line:=input[i];
        k:=i;

        if (input[k]='') then
        else begin

            //Make sure to handle strings correctly and the possible final comment
            GetRealLine(i,input[k]);
            GetLineWord(input[k],word,wordend);
            if ({privateused and} ((word<>'private') and (word<>'public')) or (structdecl<>-1)  ) then begin
                ReplaceTokens(hash,currenthash,stack,input[k],false);
                GetLineWord(input[k],word,wordend);
            end;

            if(skipfunction) then begin
                add:=(word='endfunction');
                if(add) then skipfunction:=false;

            end else if (word<>'//')  then begin //comment
                if (word='//!') then begin //preprocessor
                    j:=wordend;
                    GetLineWord(input[k],word,wordend,j); //get a new word.
                    if (word='external') then begin

                        GetLineWord(input[k],word,wordend,wordend);
                        tmp:=Copy(input[k],wordend,Length(input[k]));

                        if( Length(tmp)>EXTERNAL_SIZE_LIMIT) then raise JasserLineException(i,'The external call is too long');
                        Exter.add(word,tmp,i);
                        input[k]:='//processed : '+input[k];

                    end else if(word='externalblock') then begin

                        GetLineWord(input[k],word,wordend,wordend);
                        ExternalBlockExtension:='tmp';
                        for j := 1 to Length(word) do
                           if(word[j]='=') then begin
                               if( Copy(word,1,j-1) <> 'extension' ) then
                                   raise JasserLineException(i,'Expected: extension (before =) ');
                               ExternalBlockExtension:=Copy(word,j+1, Length(word) );
                               GetLineWord(input[k],word,wordend,wordend);
                               break;
                           end;


                        tmp:=Copy(input[k],wordend,Length(input[k]));

                        if( Length(tmp)>EXTERNAL_SIZE_LIMIT) then raise JasserLineException(i,'The external call is too long');
                        input[k]:='//processed : '+input[k];

                        ExternalBlockStdin := '';



                        ExternalBlockName:=word;

                        ExternalBlockArgs:=tmp;
                        ExternalBlockLn:=i;

                    end else if(word='i') and (ExternalBlockName <> '') then begin
                        SWriteLn(ExternalBlockStdin,Copy(input[k], wordend+1, Length(input[k]) ) );

                    end else if(word='endexternalblock') then begin
                        Exter.add(ExternalBlockName, ExternalBlockArgs, ExternalBlockLn, ExternalBlockExtension, ExternalBlockStdIn);
                        ExternalBLockName:='';
                    end else if (word='require') then begin
                         if (REQUIREFOUND=0)then REQUIREFOUND:=i+1;
                    end else if (word='inject') then begin
                        if(injectpos<>-1) then begin
                            raise JASSerLineDoubleException(i,'Nested inject statement',injectpos,'Previous inject was here');
                        end;
                        injectpos:=i;
                        add:=false;
                        GetLineWord(input[k],word,wordend,wordend);

                        if(word='main') then begin
                            usedmaininject:=true;
                            ininjectmain:=true;
                        end else if(word='config') then begin
                             usedconfiginject:=true;
                             inconfiginject:=true;
                        end else begin
                             raise JASSerLineException(i,'Unrecognized inject option');
                        end;
                    end else if (word='endinject') then begin
                        if( ininjectmain ) then begin
                            raise JASSerLineException(i,'A well placed //! dovjassinit is required');
                        end else if(inconfiginject) then begin
                            inconfiginject:=false;
                            add:=false;
                            injectpos:=-1;
                        end else if not( ininjectpostmain) then begin
                            raise JASSerLineException(i,'Unexpected endinject.');
                        end else begin
                            ininjectpostmain:=false;
                            add:=false;
                            injectpos:=-1;
                        end;
                    end else if (word='initstructs') then begin
                        raise JASSerLineException(i,'Illegal preprocessor (used for internal operations only)');

                    end else if(word='dovjassinit') then begin

                        if(not ininjectmain) then begin
                            raise JASSerLineException(i,'//! dovjassinit must be inside //! inject main block');
                        end;
                        add:=false;
                        ininjectmain:=false;
                        ininjectpostmain:=true;

                    end else if(word='library') or (word='library_once') or (word='scope') or (word='endscope') or (word='endlibrary') then begin
                        raise JasserLineException(i,'//! syntax is deprecated for "'+word+'" please remove the //!');


                    end;  //Else it is an unknown preprocessor better keep it.


                end else if (word='struct') or (word='interface') or (word='module') then begin
                    if(structdecl<>-1) then raise JASSerLineDoubleException(i,'Nested struct',structdecl,'First struct declaration');
                    structdecl:=i;
                end else if (word='endstruct') or (word='endinterface') or (word='endmodule') then begin
                    if(structdecl=-1) then raise JASSerLineException(i,'Unexpected "'+word+'"');
                    structdecl:=-1;
                end else if ((word='library') or(word='library_once')) then begin
                    if(structdecl<>-1) then raise JASSerLineDoubleException(i,'Library inside struct?',structdecl,'struct declaration');
                    //commused:=false;
                    once:=(word='library_once');
                    beginLibrary;

                end else if (word='endlibrary') then     begin
                    endLibrary;

                end else if (word='scope') then begin
                        validatedscopeinit:=false;
                        if(onscope and (scopeinitializer<>'') ) then begin
                            raise JasserLineException(i,'Scopes with initializers cannot allow nested scopes');
                        end;

                        if(structdecl<>-1) then raise JASSerLineDoubleException(i,'Scope inside struct?',structdecl,'struct declaration');
                        //commused:=false;
                        //if (tolibrary) then raise JaSSerLineException(i,'scope declarations inside libraries not allowed');
                        GetLineWord(input[k],scope,j,wordend);
                        if (scope='') then JASSerLineException(i,'missing scope name');
                        if (not validScopeName(scope)) then raise JASSerLineException(i,'Invalid scope name : '+scope);

                        scopeinitializer:='';
                        r:=j;
                        if(CompareLineWord('initializer',input[k],r,r) ) then begin
                            if(onscope) then begin
                                raise JasserLineException(i,'Nested scopes cannot have initializers');
                            end;

                            GetLineWord(input[k],scopeinitializer,r,r);
                            if(not validIdentifierName(scopeinitializer)) then raise JasserLineException(i,'Invalid initializer name : '+scopeinitializer);
                            //addScopeInit(scope+'_'+scopeinitializer);
                            j:=r;
                        end else validatedscopeinit:=true;



                        VerifyEndOfLine(input[k],j,i);
                        newscope(true);

                end else if (word='endscope') then begin

                        if ((tolibrary) and (stack.n=1)) or (not onscope) then raise JASSerLineException(i,'endscope found but no scope block was started');
                        if (not onscope) then raise JASSerLineException(i,'endscope found but no scope block was started');

                        if (not validatedscopeinit) then begin
                            if(scopeinitializer = 'onInit') then begin
                                scopeinitializer:='';
                            end else begin
                                raise JasserLineException(i,'Unable to find initializer: '+scopeinitializer);
                            end;
                        end;

                        //raise JASSerLineException(i,'endscope found but no scope block was started');
                        VerifyEndOfLine(input[k],wordend,i);
                        input[k]:='// scope '+scope+' ends';
                        outscope;
                        scopeinitializer:='';


                end else if (word='globals') then begin //It is a globals section
                    if(structdecl<>-1) then raise JASSerLineDoubleException(i,'Globals inside struct?',structdecl,'struct declaration');
                    if (toglobals) then raise JASSerLineDoubleException(i,'nested globals',globalsdecl,'`---- first globals declaration here.');

                    VerifyEndOfLine(input[k],wordend,i);
                    globalsdecl:=i;
                    add:=false;

                    toglobals:=true;
                end else if  (word='endglobals') then begin //It is the end of a globals section
                    add:=false;
                    if (not toglobals) then raise JASSerLineException(i,'endglobals found but globals were not started');
                    toglobals:=false;
                    globalsdecl:=-1;
                    VerifyEndOfLine(input[k],wordend,i);

                end else if (word='globals') then begin
                    if(globalsdecl<>-1) then raise JASSerLineDoubleException(i,'nested globals',globalsdecl,'`---- first globals declaration here.');
                    VerifyEndOfLine(input[k],wordend,i);
                    globalsdecl:=i
                end else if (word='endglobals') then begin
                    if(globalsdecl=-1) then raise JASSerLineException(i,'Unexpected "endglobals"');
                    globalsdecl:=-1;
                    VerifyEndOfLine(input[k],wordend,i);



                end else if (word='function') then begin //It a function declaration
                    if(structdecl<>-1) then raise JASSerLineDoubleException(i,'Function inside struct?',structdecl,'struct declaration');

                //function main takes nothing returns nothing, returns nothing is probably not forcefully necessary although
                //a main function with a return value would be kind of useless I guess
                    j:=wordend;
                    GetLineWord(input[k],word,j,j);
                    if(word='interface') then GetLineWord(input[k],word,j,j);
                    if tolibrary then begin
                        if (not libraries[libraryn-1].validatedInit) then begin
                            if (word=libraries[libraryn-1].init) then begin
                                 GetLineWord(input[k],word,j,j);
                                 if (word='takes') then begin
                                     GetLineWord(input[k],word,j,j);
                                     if (word='nothing') then libraries[libraryn-1].validatedInit:=true;
                                 end;
                            end;


                        end;
                    end
                    else if (onscope and not(validatedscopeinit) and (word=scopeinitializer) ) then begin
                         if(compareLineWord('takes',input[k],j,j) and compareLineWord('nothing',input[k],j,j)) then begin
                              validatedscopeinit:=true;
                              addScopeInit(scopeinitializer);
                         end;
                    end else if (word='main') then begin
                        GetLineWord(input[k],word,j,j);
                        if (word='takes') then begin
                            GetLineWord(input[k],word,j,j);
                            if (word='nothing') then inmain:=true;
                        end;
                        if(usedmaininject) then begin
                            SWriteLn(premainarea,input[k]);
                            SWriteLn(premainarea,injectmain);
                            add:=false;
                        end;
                    end else if (word='config') then begin
                        GetLineWord(input[k],word,j,j);
                        if (word='takes') then begin
                            GetLineWord(input[k],word,j,j);
                            if (word='nothing') then inmain:=true;
                        end;
                        if(inmain and usedconfiginject) then begin
                            if(post) then begin
                                SWriteLn(postmainarea,input[k]+' // by inject');
                                SWriteLn(postmainarea,injectconfig);
                                //SWriteLn(postmainarea,'endfunction //by inject');
                            end else begin
                                SWriteLn(premainarea,input[k]+' // by inject');
                                SWriteLn(premainarea,injectconfig);
                                //SWriteLn(premainarea,'endfunction //by inject');

                            end;
                            add:=false;
                            skipfunction:=true;

                        end;
                        inmain:=false;
                    end;

                end else if((word='private')or(word='public')) and(structdecl=-1) then begin

                    noreplacetokens:=false;
                    ispublic:=(word='public');

                    if ((not tolibrary) and (not onscope)) then begin
                        if(ispublic) then
                            raise JasserLineException(i,'public outside library/scope definition')
                        else
                            raise JasserLineException(i,'private outside library/scope definition');
                    end;
                    if (not privateused) then begin
                        hash.Clear;
                        privateused:=true;
                    end;
                    j:=wordend;
                    GetLineToken(input[k],word,j,j);

                    if (word='constant') then GetLineWord(input[k],word,j,j);
                    if(word='struct') then structdecl:=i;
                    if(word='interface') then structdecl:=i;
                    if(word='module') then structdecl:=i;

                    if(word='library') then raise JasserLineException(i,'No private/public/ nested libraries are allowed');



                    if (word='function') then begin
                        GetLineWord(input[k],word,j,j);

                        if(word='interface') then GetLineWord(input[k],word,j,j);
                        //now word has the function name!
                        AddScopeWord;

                        //It should be invalid if initializer is not in the exact same library instead of a child scope
                        if (tolibrary and (scopelevelid=2) and (not libraries[libraryn-1].validatedInit) and (word=libraries[libraryn-1].init) ) then begin
                            //clever, the guy used a private initializer!
                            //word;
                            GetLineWord(input[k],tmp,j,j);
                            if (tmp='takes') then begin
                                GetLineWord(input[k],tmp,j,j);
                                if (tmp='nothing') then begin
                                     libraries[libraryn-1].validatedInit:=true;
                                     if (ispublic) then
                                         libraries[libraryn-1].Init:=libpreffix_public+word
                                     else
                                         libraries[libraryn-1].Init:=libpreffix_private+word;
                                end;
                            end;


                        end else if ( not(validatedscopeinit) and (word=scopeinitializer)) then begin
                            GetLineWord(input[k],tmp,j,j);
                            if (tmp='takes') then begin
                                GetLineWord(input[k],tmp,j,j);
                                if (tmp='nothing') then begin
                                     validatedscopeinit:=true;
                                     if (ispublic) then
                                         addScopeInit(libpreffix_public+scopeinitializer)
                                     else
                                         addScopeInit(libpreffix_private+scopeinitializer);
                                end;
                            end;
                        end;


                    end else if (word='scope') then  begin
                        if(structdecl<>-1) then raise JASSerLineDoubleException(i,'Scope inside struct?',structdecl,'struct declaration');
                        GetLineWord(input[k],scope,j,j);
                        if (scope='') then JASSerLineException(i,'missing scope name');
                        if (not validScopeName(scope)) then raise JASSerLineException(i,'Invalid scope name : '+scope);
                        VerifyEndOfLine(input[k],j,i);
                        if(ispublic) then begin
                            //same as a normal scope
                            newscope(true);
                        end else begin
                            //AddScopeWord; also the same...
                            newscope(true);
                        end;

                        noreplacetokens:=true;

                    end else if (word='keyword') then begin
                        GetLineToken(input[k],word,j,j);
                        AddScopeWord;
                        if(ispublic) then
                            input[k]:='//!keyword-public' //leave signal
                        else
                            input[k]:='//!keyword-private'; //leave signal;

                        add:=false;
                    end else if(globalsdecl=-1) and (word<>'struct') and (word<>'type') and (word<>'interface') and (word<>'module') then begin
                         raise JasserLineException(i,'Expected: "type", "struct", "interface", "function", "keyword" or "scope"');

                    end else begin
                        //word should now have forcefully a type name in word

                        //use tokens because there might be name=something
                        GetLineToken(input[k],word,j,j);
                        if (word='array') then GetLineToken(input[k],word,j,j);
                        //now we have a variable name
                        AddScopeWord;

                    end;
                    if(not noreplacetokens) then ReplaceTokens(hash,currenthash,stack,input[k],true);


                end else begin

                    if (inmain) then begin
                        if(usedmaininject) then begin
                            if (word='endfunction') then begin
                                SWriteLn(postmainarea,postinjectmain);
                                SWriteLn(postmainarea,'endfunction //injected main function (! inject command)??');
                                post:=true;
                                inmain:=false;
                                usedmaininject:=false;//11111111111111
                            end;
                            add:=false;
                        end else if (word='call') then begin
                            j:=wordend;
                            GetLineToken(input[k],word,j,j);
                            if (word='InitBlizzard') then begin
                                Insert(input[k],premainarea,VERYBIG); //append to premainarea
                                Insert(#13#10,premainarea,VERYBIG); //append to premainarea
                                post:=true;
                                inmain:=false;
                                add:=false;
                            end;
                        end else if (word='endfunction') then begin
                                post:=true;
                                inmain:=false;
                                add:=true;
                            //    raise JASSerLineException(i,'Missing InitBlizzard in main function');
                        end;
                    end;
                end;

            end;

        end;

        if (word='debug') then begin
            VerifyValidForDebug(input[k],k);

            if (debug) then begin
                word:='';
                for j := 1 to wordend-6 do word:=word+' ';


                input[k]:=word+Copy(input[k],wordend,Length(input[k])-wordend+1);
            end else begin
                add:=false;
            end;
        end;


        if add then begin
            if (inconfiginject) then begin
                SWriteLn(injectconfig,input[k]);

            end else if ininjectpostmain then begin
                SWriteLn(postinjectmain,input[k]);
            end else if ininjectmain then begin
                SWriteLn(injectmain,input[k]);
            end else if toglobals then begin
                if(tolibrary) then begin
                    SWriteLn(libraries[libraryn-1].globals,input[k]);
                end else begin
                    Insert(input[k],globals,VERYBIG); //append to globals section
                    Insert(#13#10,globals,VERYBIG);
                end;
            end else if tolibrary then begin
                Insert(input[k],libraries[libraryn-1].contents,VERYBIG); //append to library
                Insert(#13#10,libraries[libraryn-1].contents,VERYBIG);
            end else if (post) then begin
                Insert(input[k],postmainarea,VERYBIG); //append to premainarea
                Insert(#13#10,postmainarea,VERYBIG);
            end else begin
                Insert(input[k],premainarea,VERYBIG); //append to postmainarea
                Insert(#13#10,premainarea,VERYBIG);
            end;
        end;

        i:=i+1;
    end;
    if(structdecl<>-1) then raise JASSerLineException(structdecl,'Missing endstruct');
    if (toglobals) then raise JASSerLineException(globalsdecl,'Missing endglobals');
    if (globalsdecl<>-1) then raise JASSerLineException(globalsdecl,'Missing endglobals');


    if (injectpos<>-1) then raise JASSerLineException(injectpos,'Missing endinjenct');
    if (tolibrary) then raise JASSerLineException(libraries[libraryn-1].declaration,'Missing endlibrary');
    if (onscope) then begin
         raise JASSerLineException(stack.bottomline,'Missing endscope');
    end;
    if (postmainarea='') then  begin
        if (inmain) then raise JASSerLineException(1,'Could not find call to InitBlizzard in main function!')
        else raise JASSerLineException(1,'Could not find correct main function in file. / unclosed string');
    end;

    for i := 0 to libraryn - 1 do begin
        j:= 0;
        while( j<libraries[i].reqn ) do begin
            {if (scopehash.ValueOf(libraries[i].req[j])<0) then begin
                 raise JASSerLineException(libraries[i].declaration,'Missing requirement: '+libraries[i].req[j]);
            end; This actually increased time}
            k:=0;
            while(k<libraryn) do begin
                if(libraries[k].name=libraries[i].req[j]) then break;
                k:=k+1;
            end;
            if(k=libraryn) then begin
                if (libraries[i].req_opt[j]) then begin
                    libraries[i].reqn := libraries[i].reqn - 1;
                    libraries[i].req[j]:= libraries[i].req[ libraries[i].reqn ];
                    libraries[i].req_opt[j]:= libraries[i].req_opt[ libraries[i].reqn ];
                    j:=j-1;
                end else begin
                    raise JASSerLineException(libraries[i].declaration,'Missing requirement: '+libraries[i].req[j]+' (libraries cannot require scopes)' );
                end;
            end;
            j:=j+1;
        end;
    end;

    if (Interf<>Nil) then Interf.ProPosition(ln);


    except
       on e:EAccessviolation do begin
           raise JasserLineDoubleException(i,'[Internal Error]',i,e.message);
       end;
    end;
finally
    hash.Destroy;
    stack.Destroy;
    scopehash.Destroy;
    currenthash.Destroy;
    linehash.Destroy;

end;


end;

function findNoReqLibrary:integer;
var i:integer;
begin
    Result:=-1;
    for i := 0 to libraryn - 1 do if (libraries[i].reqn=0) then begin

        if(Result=-1) or (CompareStr(Libraries[i].name, Libraries[result].name)<0) then begin
            Result:=i;
        end;
    end;

end;

procedure FindLibraryCycles;
var
   i:integer;
   processed,parent: array of integer;

     function buildCycle(x:integer; par:integer):string;
     var
        i,c,y:integer;
        arr: array of string;
     begin
         c:=2;
         y:=par;
         while( y<>x) do begin
             c:=c+1;
             y:=parent[y];
         end;
         SetLength(arr,c);
         arr[c-1]:=libraries[x].name;
         arr[c-2]:=libraries[par].name;
         y:=par;
         for i := c-3 downto 0 do begin
             y:=parent[y];
             arr[i]:=libraries[y].name;
         end;
         result:=arr[0];
         for i := 1 to c-1 do
             result:=result+' -> '+arr[i];
           

     end;


     procedure dfs(x:integer; par:integer);
     var j,k:integer;
     begin
         if(processed[x]=0) then begin
             processed[x]:=2;
             parent[x]:=par;
             for j := 0 to Libraries[x].reqn-1 do begin
                 k:=0;
                 while(k<libraryn) do begin
                     if(libraries[k].name=libraries[x].req[j]) then break;
                     k:=k+1;
                 end;
                 if(k<libraryn) then
                     dfs(k, x);
             end;

             processed[x]:=1;
         end else if(processed[x]=2) then begin
             //cycle!
             raise JasserLineDoubleException(
             libraries[x].declaration,'Found a library requirements cycle.',
             libraries[par].declaration,'\--- '+buildCycle(x,par)
             );
         end;
     end;
begin
    SetLength(processed, libraryn);
    SetLength(parent, libraryn);
    for i := 0 to libraryn - 1 do
        processed[i]:=0;
    for i := 0 to libraryn - 1 do
        if(processed[i]=0) then
            dfs(i,-1);

end;


var removedLibrariesN:integer;
var removedLibraries: array of string;


procedure removeLibrary(i:integer);
var
   name:string;
   lib:TLibrary;
begin
   lib:=Libraries[i];
   name:=lib.name;
   libraries[i]:=libraries[libraryn-1];
   libraryn:=libraryn-1;
   lib.Destroy;

   if( Length(RemovedLibraries)=removedLibrariesN) then begin
       SetLength(RemovedLibraries,removedLibrariesN*2+1);
   end;
   removedLibraries[removedLibrariesN]:=name;
   removedLibrariesN:=removedLibrariesN+1;


end;

procedure cleanAddedLibraries;
var   j,k,p,i:integer;
begin
   for j := 0 to libraryn - 1 do begin


      k:=0;
      while(k<libraries[j].reqn) do begin
          p:=-1;
          i:=0;
          while (i<removedLibrariesN) do begin
              if(libraries[j].req[k]=removedLibraries[i]) then begin
                  p:=1;
                  break;
              end;
              i:=i+1;
          end;
          if(p<>-1) then begin
              libraries[j].reqn:=libraries[j].reqn-1;
              libraries[j].req[k]:=libraries[j].req[libraries[j].reqn] ;
          end else k:=k+1;
      end;
   end;
   removedLibrariesN:=0;
end;

function getInvolvedLibraries:string;
var
 i,j:integer;
begin

   for i := 0 to libraryn - 1 do begin
       Result:=Result+' '+libraries[i].name+'{';
       for j := 0 to libraries[i].reqn - 1 do Result:=Result+' '+libraries[i].req[j];
       Result:=Result+'}';


   end;


end;



procedure writeOutput(var Result:string);Overload;
var
   i:integer;
   initializers:string;
   librarycode:string;

begin
    Result:='';

    removedLibrariesN:=0;
    SetLength(removedLibraries,5);

  if(interf<>nil) then begin
      interf.ProMax(libraryn*4+6);
      interf.ProPosition(0);
      interf.ProStatus('Libraries - writing...');
  end;

    SWriteLn(Result,'globals');
    if (Interf<>nil) then Interf.ProPosition(Interf.GetProPosition+1);

    initializers:='';
    librarycode:='';
    //if(library_usedinit) then
    //    initializers:='set l__library_init=CreateTrigger()'#13#10;
    FindLibraryCycles;

    while (libraryn>0) do begin
        i:=findNoReqLibrary;
        if (i=-1) then begin
            cleanAddedLibraries;
            i:=findNoReqLibrary;
            if (i=-1) then raise JASSerLineException(libraries[0].declaration,'Library requirements cycle, involved libraries are: '+getInvolvedLibraries);
        end;

        SWriteLn(librarycode,'//library '+libraries[i].name+':');
        SWriteLn(librarycode,libraries[i].contents);
        SWriteLn(librarycode,'//library '+libraries[i].name+' ends');
        if(libraries[i].globals<>'') then begin
            SWriteLn(Result,'//globals from '+libraries[i].name+':');
            Swrite(Result,libraries[i].globals);
            SWriteLn(Result,'//endglobals from '+libraries[i].name);
        end;


        if (libraries[i].Init<>'') then
            //SWriteLn(initializers,'call TriggerAddAction(l__library_init,function '+libraries[i].Init+')');
            SWriteLn(initializers,'call ExecuteFunc("'+libraries[i].Init+'")');

        removeLibrary(i);

        if (Interf<>nil) then Interf.ProPosition(Interf.GetProPosition+4);
    end;

    //if(library_usedinit) then
    //    SWriteLn(initializers,'call TriggerExecute(l__library_init)');

    SWriteLn(Result,globals);
    if (Interf<>nil) then Interf.ProPosition(Interf.GetProPosition+1);
    if(library_usedinit) then
        SWriteLn(Result,'trigger l__library_init');
    SWriteLn(Result,'endglobals');
    if (Interf<>nil) then Interf.ProPosition(Interf.GetProPosition+1);
    Swrite(Result,librarycode);


    for i := 0 to ScopeInitN - 1 do begin
            Insert('call '+ScopeInit[i]+'()'#13#10,initializers,VERYBIG);
    end;

    SWriteLn(Result,premainarea);
    SWriteLn(Result,'//! initstructs');

    if (Interf<>nil) then Interf.ProPosition(Interf.GetProPosition+1);
    SWriteLn(Result,initializers);

    //It is better to have them after the library initializers
    SWriteLn(Result,'//! initdatastructs');


    if (Interf<>nil) then Interf.ProPosition(Interf.GetProPosition+1);
    SWriteLn(Result,postmainarea);


    if (Interf<>nil) then Interf.ProPosition(Interf.GetProMax);


end;

procedure writeOutput(var ff2:textfile); overload;
var x:string;
begin
    writeOutput(x);
    WriteLn(ff2,x);
end;

procedure DoJASSerMagic(f1:string; f2:string; debug:boolean);Overload;
var

ff2:textfile;
inp:string;
{i:integer;}
open2:boolean;


begin
    DEBUG_MODE:=debug;
    try
        SetLength(all_handle, Length(all_handle) + 1);
        all_handle[High(all_handle)] := 'handle';
    
        JassLib.init;
        if( jasshelper.COMMONJ <> '') then begin
            JassLib.parseFile(jasshelper.COMMONJ);
        end;
        if( jasshelper.BLIZZARDJ <> '') then begin
            JassLib.parseFile(jasshelper.BLIZZARDJ);
        end;
        // should we just only parse from common.j ?
        if (JASS_ARRAY_SIZE = 0) then
            // default to 8191
            JASS_ARRAY_SIZE := 8191;
        VJASS_MAX_ARRAY_INDEXES := JASS_ARRAY_SIZE * 50;
    except
        on e:JassLibException do begin
            raise Exception.Create(e.msg );
        end;
    end;



    open2:=false;
    if (Exter=nil) then Exter:=TexternalUsage.create
    else Exter.reset;


try

    if (Interf<>nil) then begin
        Interf.ProPosition(0);
        Interf.ProStatus('Loading...');
    end;
    LoadFile(f1,inp);


    AssignFile(ff2,f2);
    filemode:=fmOpenWrite;
    Rewrite(ff2);
    open2:=true;
    Write(ff2,DoJASSerMagic(inp,debug));
finally
    if (open2) then Close(ff2);

end;

end;

    function fetchPath(var path:string; const current:string=''):boolean;
     var s:string;
     var x:integer;
    begin
         //import path
         Result:=true;
         if(not fileExists(path)) then begin
             if (current<>'') then begin    //should have priority.
                 s:=current+path;
                 if(fileexists(s)) then begin
                     path:=s;
                     exit;
                 end;
             end;

             for x := 0 to importpathn-1 do begin
                 s:=importpaths[x]+path;
                 if(fileexists(s)) then begin
                     path:=s;
                     exit;
                 end;
             end;
             Result:=false;
         end;
    end;

    function CrossExtractFolder(const filepath:string): string;
     var i,L:integer;
    begin
        L:=Length(filepath);
        i:=L;
        while(i>=1) do begin
            if(filepath[i]='/') or (filepath[i]='\') then begin
                break;
            end;
            i:=i-1;
        end;
        if(i=0) then begin
            result:='';
            exit;
        end;
        result:=Copy(filepath,1,i);

    end;
    function CrossExtractFilename(const filepath:string): string;
     var i,L:integer;
    begin
        L:=Length(filepath);
        i:=L;
        while(i>=1) do begin
            if(filepath[i]='/') or (filepath[i]='\') then begin
                break;
            end;
            i:=i-1;
        end;
        if(i=0) then begin
            result:='';
            exit;
        end;
        result:=Copy(filepath,i+1,Length(filepath));

    end;

    function CrossNormalizeFilename(const filepath:string): string;
    begin
        result:= StringReplace(StringReplace(filepath,'\\','\',[rfREPLACEALL]), '\','/', [rfREPLACEALL]);
    end;

function DoJASSerMagic(sinput:string; debug:boolean):string;overload;
var
i,L,eln:integer;
hash:TStringHash;
novjass, comment:integer;
pendingline, zinc:boolean;
localzinc:integer;

    // some signatures:
    procedure addFileLine( const line:string; ignorecom:boolean=false); forward
    procedure importPhase(const sinput: string ); forward;

    procedure doImport( const line: string; start:integer);
     var i, a,b, L:integer;
         filename, shortfilename : string;
         giantString: string;

         usedMode:integer;
         renableZinc:integer;
         llocalzinc:integer;
         label finish;
    begin
        llocalzinc:=localzinc;
        IMPORTUSED:=TRUE;

        L:=length(Line);
        //0:none, 1:vJass, 2:zinc
        if(CompareLineWord('vjass',line,i, start) ) then begin
            usedMode:=1;
        end else if(CompareLineWord('zinc',line,i, start) ) then begin
            usedMode:=2;
        end else if(CompareLineWord('comment', line,i,start) and not WARCITY ) then begin
            AddFileLine('// IGNORE COMMENT IMPORT OF '+filename);
            goto finish; //Dijkstra forgive me!
        end else begin
            if(zinc) then
                usedMode:=2
            else
                usedMode:=1;
            i:=start;
        end;
        localzinc:=-1;


        while ((i<=L) and (line[i]<>'"') ) do i:=i+1;
        a:=i;
        if( a > L) then begin
           addFileLine(line);
           raise JASSerLineExceptionNoTextMacro(ln-1,'import requires filename between quotes. (")');
        end;
        i:=i+1;
        while ((i<=L) and (line[i]<>'"') ) do i:=i+1;
        b:=i;
        if( b > L) then begin
           addFileLine(line);
           raise JASSerLineExceptionNoTextMacro(ln-1,'Expected: "');
        end;
        filename := Copy(line, a+1, b-a-1);
        if(not fetchPath(filename) ) then begin
           addFileLine(line);
           raise JASSerLineExceptionNoTextMacro(ln-1,'Unable to find file: '+filename);
        end;
        addImportPath(CrossExtractFolder(filename));
        shortfilename := CrossNormalizeFilename(filename);
        if( hash.ValueOf(shortfilename) <> -1) then begin
            if(not jasshelper.WARCITY ) then begin
                AddFileLine('// IGNORE DOUBLE IMPORT OF '+filename);
            end;
        end else begin
            hash.Add(shortfilename,1);
            renablezinc:=0;
            if( zinc and (usedmode=1) ) then begin
                zinc:=false;
                renablezinc:=1;
                AddFileLine('//! endzinc');
            end else if( not(zinc) and (usedmode=2) ) then begin
                zinc:=true;
                renablezinc:=-1;
                AddFileLine('//! zinc');
            end;

            if(not jasshelper.WARCITY ) then begin
                AddFileLine('// BEGIN IMPORT OF '+filename);
            end;
            LoadFile(filename, giantString);
            importPhase( giantString);
            if(not jasshelper.WARCITY ) then begin
                AddFileLine('// END IMPORT OF '+filename);
            end;

            if(renablezinc=1) then begin
                zinc:=true;
                AddFileLine('//! zinc');
            end else if(renablezinc=-1) then begin
                zinc:=false;
                AddFileLine('//! endzinc');
            end;

        end;
        finish:
        if(localzinc<>-1) then begin
           raise JASSerLineExceptionNoTextMacro(localzinc,'Unterminated //! zinc in file: '+filename);
        end;
        localzinc:=llocalzinc;
    end;

    procedure dealWithComments(line:string; var output:string);
     var
        i,k,L:integer;
        modify: boolean;
        ctr,str:boolean;
    begin

        modify:=( comment > 0);
        L:=Length(line);
        if(not modify) then
            for i := 1 to L-1 do begin
               if(line[i]='/') and (line[i+1]='/') then
                   break
               else if (line[i]='/') and (line[i+1]='*') then begin
                   IMPORTUSED:=TRUE;
                   modify:=true;
                   break;
               end;
            end;
        if(not modify) then begin
            output:=line;
            exit;
        end;
        k:=0;
        i:=1;
        str:=false;
        ctr:=false;
        while(i<=L) do begin
            if(comment>0) then begin
                if(line[i] = '*') and (i<L) and (line[i+1]='/') then begin
                    i:=i+1;
                    comment := comment - 1;
                end else if (line[i] = '/') and (i<L) and (line[i+1]='*') then begin
                    i:=i+1;
                    comment:= comment +1;
                    IMPORTUSED:=TRUE;
                end;
                k:=i;
            end else if(str) then begin
                if(ctr) then
                    ctr:=false
                else if(line[i]='\') then
                    ctr:=true
                else if(line[i]='"') then
                    str:=false;
            end else begin
                if(line[i] = '/') and (i<L) and (line[i+1]='/') then
                    i:=L
                else if(line[i] = '/') and (i<L) and (line[i+1]='*') then begin
                    IMPORTUSED:=TRUE;
                    comment := comment + 1;
                    output:=output + Copy(line,k+1, i-k-1);
                    i:=i+1;
                end else if(line[i] = '"') then str:=true;
            end;
            i:=i+1;
        end;
        if(comment =0) then output:=output + Copy(line,k+1,L-k);

    end;


    procedure parseFileLine(const cline: string);
     var
       i : integer;
       word, line:string;
       addline: boolean;
    begin
          dealWithComments(cline, line);
          addline:= true;
          if CompareLineWord('//!',line,i) then begin
              GetLineWord(line, word, i,i);
              if (not ZINC_MODE) and (novjass=0) and not(jasshelper.FORGETIMPORT) and (word='import') then begin
                  addline := false;
                  doImport(line, i);
              end else if (word='zinc') then begin
                  if(zinc) then begin
                     addFileLine(line);
                     raise JASSerLineExceptionNoTextMacro(ln-1,'Nested //! zinc');
                  end;
                  localzinc:=ln;
                  zinc := true;
              end else if (word='endzinc') then begin
                  if(localzinc=-1) then begin
                     addFileLine(line);
                     raise JASSerLineExceptionNoTextMacro(ln-1,'Unexpected: //! endzinc');
                  end;
                  zinc := false;
                  localzinc:=-1;

              end else if (word='novjass') then begin
                 IMPORTUSED:=true;
                  novjass:=novjass + 1;
              end else if (word='endnovjass') then begin
                 if(novjass<=0) then begin
                     addFileLine(line);
                     raise JASSerLineExceptionNoTextMacro(ln-1,'//! endnovjass found with no corresponding //! novjass');
                 end;
                 novjass:=novjass-1;
                 addline:=false;
              end;
          end;

          if addline and (novjass = 0) then begin
              if(jasshelper.WARCITY) then
                  addFileLine(cline, true)
              else
                  addFileLine(line, false);
          end;

    end;

    procedure addFileLine ( const line:string; ignorecom:boolean = false); begin
        if(pendingline) then begin
            input[ln - 1] := input[ln-1] + line;
        end else begin
            ln := ln + 1;
            if( ln > Length(input) ) then SetLength(input, ln+ln div 50);
            input[ln -1]:= line;
        end;
        if( not(ignorecom) and (comment>0) ) then begin
            Swrite(AFTERIMPORT, line);
            pendingline:=true;
        end else begin
            SWriteLn(AFTERIMPORT, line);
            pendingline:=false;
        end;

    end;

  procedure importPhase(const sinput: string);
     var
      k,i, L:integer;
      line:string;

    begin
        L:=Length(sinput);
        SetLength(input, Length(input) + 1 + L div 50);
        comment:=0;
        novjass:=0;
        k:=0;
        i:=1;
        pendingline:=false;
        while(i<=L+1) do begin
            if (i>L)
                or (sinput[i]=#10)
                or ( (sinput[i]=#13) and ((i+1>L) or (sinput[i+1]<>#10)) )
            then begin //line break.
                if( (i>1) and (sinput[i-1] = #13) ) then begin
                    line := Copy(sinput,k+1, i-k-2);
                end else begin
                    line := Copy(sinput,k+1, i-k-1);
                end;
                parseFileLine(line);
                k:=i;
            end;
            i:=i+1;

       end;
       if(novjass>0) then
           raise JASSerLineExceptionNoTextMacro(ln,'The file contains unclosed //! novjass statements');

       if (comment>0) then
           raise JASSerLineExceptionNoTextMacro(ln,'The file contains unclosed /* comments!');

   end;


begin
    hash:=TStringHash.Create;
    if (Interf<>nil) then begin
        Interf.ProPosition(0);
        Interf.ProStatus('Loading...');
    end;

    ln:=0;
    IMPORTUSED:=false;
    AFTERIMPORT:='';
    L:=Length(sinput);
    eln:=L div 50; //estimated ln
    SetLength(input,eln+1);
    zinc:=false;
    localzinc:=-1;
    importPhase(sinput);

    hash.Destroy;

    if (ln<2) then raise Exception.Create('Input file seems too small / unclosed string issues');

    if (Interf<>nil) then begin
        writefactor:=ln div 5+1;
        Interf.ProMax(ln+(7 + libraryn)*writefactor);
        Interf.ProStatus('Parsing...');
    end;

    if(WARCITY) then begin
         RESULT:=AFTERIMPORT;
         exit;
    end;
    processTextMacros;
    if(MACROMODE) then begin
         RESULT:='';
         for i := 0 to ln-1 do SWriteLn(RESULT, input[i]);
         exit;
    end;

    ProcessZinc(debug);
    if(ZINC_MODE) then begin
         RESULT:='';
         for i := 0 to ln-1 do SWriteLn(RESULT, input[i]);
         exit;
    end;


    parseInput(debug);

    if (Interf<>nil) then begin
        Interf.ProStatus('Generating...');
    end;

    writeOutput(Result);




    IMPORTUSED:=false;
    AFTERIMPORT:=''; //deallocates memory
end;

//<Ttextmacro>
{
   Ttextmacro = class(TObject)
   private
       contents:array of string;
       contentssize:integer;
       args:array of string;
       argsn:integer;
   public
       decl:integer;
       constructor create;
       procedure run(var replaceto:array of string; var copyto:array of string;var copyton:integer);
       procedure addArgument(const s:string);
       procedure add(const s:string);

   end;
}



constructor Ttextmacro.Create;
begin
    contentssize:=0;
    argsn:=0;
    decl:=0;
    SetLength(contents,1);
    SetLength(args,1);
end;

procedure Ttextmacro.addArgument(const s:string);
var
   i:integer;
begin
    for i:=0 to argsn-1 do if (args[i]=s) then raise JASSerLineException(decl,'The same argument name was used multiple times');
    SetLength(args,argsn+1);
    args[argsn]:=s;
    argsn:=argsn+1;
end;

procedure Ttextmacro.reserveSpace(s:integer);
begin
    if(Length(contents)<s) then SetLength(contents,s);
end;

procedure Ttextmacro.add(const s:string);
begin
    contentssize:=contentssize+1;
    if(Length(contents)<contentssize) then SetLength(contents,contentssize);
    contents[contentssize-1]:=s;
end;

   procedure findchar(const s:string; var pos:integer; const start:integer; const c:char);
   var
      L:integer;
   begin
       L:=Length(s);
       pos:=start;
       while(pos<=L) do begin
           if(s[pos]=c) then break;
           pos:=pos+1;
       end;
   end;


   procedure TextMacro_addline(const s:string);
   begin
       if(  Length(input)<=ln) then begin
            SetLength(input,ln*2+1);
            SetLength(offset,ln*2+1);
            SetLength(textmacrotrace,ln*2+1);
        end;
        offset[ln]:=globaloffset;
        input[ln]:=s;
        textmacrotrace[ln]:=globaltextmacrotrace;
        ln:=ln+1;
   end;


procedure Ttextmacro.run(var replaceto:TDynamicStringArray);
var
 i,k,L,t,j:integer;
 word:string;




begin
    i:=0;
    if(argsn=0) then begin

        //textmacroes without arguments in the list can just do a blind replace
        while(i<contentssize) do begin
            TextMacro_addline(contents[i]);
            i:=i+1;
        end;

    end else begin

        while(i<contentssize) do begin
            L:=Length(contents[i]);
            findchar(contents[i],k,1,'$');
            if(k<=L) then begin
                word:=Copy(contents[i],1,k-1);
                while(true) do begin
                    findchar(contents[i],t,k+1,'$');
                    if(t>L) then begin
                        SWrite(word,Copy(contents[i],k,L-k+1));
                        break;

                    end else begin
                        j:=0;
                        while(j<argsn) do begin
                            if(comparesubstring(contents[i],k+1,t-1,args[j])) then break;
                            j:=j+1;
                        end;
                        if(j>=argsn) then begin
                            SWrite(word,Copy(contents[i],k,t-k+1));
                        end else SWrite(word,replaceto[j]);

                        findchar(contents[i],k,t+1,'$');
                        if(k>L) then begin
                            SWrite(word,Copy(contents[i],t+1, L-t  ));
                            break;
                        end else begin
                            SWrite(word,Copy(contents[i],t+1, k-t-1  ));
                        end;
                    end;
                end;
                //TextMacro_addline(word);

            end else
                //TextMacro_addline(contents[i]);
                word:=contents[i];
            {if(not evaluateTextmacroLine(word)) then}
            TextMacro_addline(word);
            i:=i+1;
        end;


    end;

end;
//</Ttextmacro>



procedure processTextMacros;
var
   incopy : array of string;
   word,tempish:string;
   i,k,h,c,wordend:integer;
   tmp,tmp2:integer;
   hash: TStringHash;
   macro:Ttextmacro;
   macros: array of TTextMacro;
   macron: integer;
   parsedarg:array of string;
   parsedargsn:integer;
   period,nextperiod:integer;
   once,skip,optional:boolean;
   label kkk;


   procedure ParseCrazyCall(st:integer;const s:string);
   var
      L:integer;
      x:integer;
      ctr:boolean;
      owe:integer;


   begin
       L:=Length(s);
       x:=st;
       owe:=0;
       while(x<=L) do begin
           if(s[x]='(') then begin
               break;
           end else if (s[x]=' ') or (s[x]=#9) then
              x:=x+1
           else  raise JASSerLineExceptionNoTextMacro(i,'Unexpected symbol : "'+s[x]+'"');
       end;
       if(x>L) then raise JASSerLineExceptionNoTextMacro(i,'Expected (');
       //great we now get and count the args!!

       parsedargsn:=0;
       x:=x+1;
       while(x<=L) do begin
           if(s[x]=' ') or (s[x]=#9) then x:=x+1
           else if(s[x]='"') then begin
               owe:=0;
               //turns out it is an argument...
               word:='';
               x:=x+1;
               ctr:=false;
               while(x<=L) do begin
                   if(ctr) then begin
                        if(s[x]='"') then word:=word+'"'
                        else word:=word+'\'+s[x];
                        ctr:=false;
                   end
                   else if (s[x]='"') then break
                   else if(s[x]='\') then ctr:=true
                   else word:=word+s[x];
                   x:=x+1;
               end;
               if(x>L) then raise JASSerLineExceptionNoTextMacro(i,'Unclosed argument');
               {s[x]='"'}
               x:=x+1;
               while(x<=L) do begin
                   if(s[x]=',') or (s[x]=')') then break;
                   x:=x+1;
               end;
               if(x>L) then raise JASSerLineExceptionNoTextMacro(i,'Expected , or )');

               SetLength(parsedarg,parsedargsn+1);
               parsedarg[parsedargsn]:=word;
               parsedargsn:=parsedargsn+1;
               if (s[x]=',') then begin
                  x:=x+1;
                  owe:=1;
                end
               else if(s[x]=')') then break;


           end
           else if (s[x]=')') then break
           else raise JASSerLineExceptionNoTextMacro(i,'Unexpected symbol : "'+s[x]+'"  ['+s+']');
           //x:=x+1;
       end;
       if(owe>0) then raise JASSerLineExceptionNoTextMacro(i,'Expected an argument after ,');
       if(x>L) then raise JASSerLineExceptionNoTextMacro(i,'Expected )');




   end;

begin

     period:=0;
     nextperiod:=0;
    {input contains the script}
    {ln contains the number of lines}
    if(interf<>nil) then begin
        period:=ln div UPDATEVALUE+1;
        nextperiod:=period;
        interf.ProStatus('Textmacros - initializing...');
        interf.ProMax(ln-1);
    end;

    if(ln>Length(input)) then raise Exception.Create('wtf');
    SetLength(offset,Length(input));
    SetLength(textmacrotrace,Length(input));
    SetLength(incopy,Length(input));
    for i := 0 to ln - 1 do begin
        if(interf<>nil) and (i>=nextperiod) then begin
            nextperiod:=i+period;
            interf.ProPosition(i);
        end;
        incopy[i]:=input[i];
        offset[i]:=0;
        textmacrotrace[i]:=0;
    end;

    macron:=0;
    macro:=nil;
    hash:=TStringHash.Create;
try

    {copy contains a copy of the input script}

    //parse all of the TextMacros
    i:=0;
    //Why care about strings? the only danger would be an string that has line breaks and in one of its lines
    //begins with //! textmacro or //! endtextmacro, you got to accept that's pretty unlikelly to happen.

    //First step involves fetching the textmacros. We need to do it in 2 steps to avoid issues

    if(interf<>nil) then begin
        period:=ln div UPDATEVALUE+1;
        nextperiod:=period;
        interf.ProStatus('Textmacros - parsing...');
        interf.ProMax(ln-1);
    end;
    while(i<ln) do begin

        if(interf<>nil) and (i>=nextperiod) then begin
            nextperiod:=i+period;
            interf.ProPosition(i);
        end;

        //textmacro or not?
        if CompareLineWord('//!',input[i],wordend) then begin
            //begins with //! , is preprocessor
            GetLineWord(input[i],word,wordend,wordend);
            once:=(word='textmacro_once');
            if once or (word='textmacro') then begin
                //awesome! it is a textmacro declaration!

                GetLineWord(input[i],word,wordend,wordend);

                if(word='') then raise JASSerLineExceptionNoTextMacro(i,'Expected a name');

                {word holds the macro name}
                h:=hash.ValueOf(word);
                skip:=false;
                if(h>=0) then begin
                    if(once) then begin
                        skip:=true;
                        goto kkk;
                    end else
                            raise JASSerLineDoubleExceptionNoTextMacro(i,'Textmacro redeclared',macros[h].Decl,'`--- Previously declared here');
                end;
                hash.Add(word,macron);
                macro:=Ttextmacro.create;
                macro.decl:=i;
                macron:=macron+1;
                SetLength(macros,macron);
                macros[macron-1]:=macro;

                GetLineWord(input[i],word,wordend,wordend);

                if(word='takes') then begin

                    GetLineWordAlsoComma(input[i],word,wordend,wordend);
                    if(word='') then raise JASSerLineExceptionNoTextMacro(i,'Expected argument list');
                    while(word<>'') do begin
                        if (not validIdentifierName(word)) then raise JASSerLineExceptionNoTextMacro(i,'Invalid argument name: '+word);

                        macro.addArgument(word);
                        GetLineWordAlsoComma(input[i],word,wordend,wordend);
                    end;
                end else if (word<>'') then raise JASSerLineExceptionNoTextMacro(i,'Expected "takes"');
                   kkk:
                    k:=i+1;
                    while(k<ln) do begin
                        if CompareLineWord('//!',input[k],wordend) then begin
                            GetLineWord(input[k],word,wordend,wordend);
                            if(word='endtextmacro') then begin
                                break;
                            end else if (word='textmacro') then begin
                                raise JASSerLineDoubleExceptionNoTextMacro(k,'Nested textmacros are not allowed',i,'`--- textmacro began here');
                            end else if (word='runtextmacro') then begin
                                raise JASSerLineDoubleExceptionNoTextMacro(k,'runtextmacro inside a textmacro is not allowed',i,'`--- textmacro began here');
                            end;
                        end;
                        k:=k+1;
                    end;

                    if(k=ln) then begin
                        raise JASSerLineExceptionNoTextMacro(i,'Missing endtextmacro');
                    end;
                    {k holds position of endtextmacro}

                    incopy[i]:='//! jasshelperskip '+IntToStr(k);

                    i:=i+1;
                    if(not skip) then begin
                        macro.reservespace(k-i);
                        while(i<k) do begin
                            macro.add(incopy[i]);
                            i:=i+1;
                        end;
                    end else i:=k;


            end
            else if (word='endtextmacro') then begin
                //For crying out loud syntax errors.
                raise JASSerLineExceptionNoTextMacro(i,'Unexpected endtextmacro');
            end;
        end;

        i:=i+1;
    end;

    if(interf<>nil) then begin
        period:=ln div UPDATEVALUE+1;
        nextperiod:=period;
        interf.ProStatus('Textmacros - writing...');
        interf.ProMax(ln-1);
    end;

    //step 2 involves doing the actual textmacro executing
    i:=0;
    c:=ln;
    ln:=0;
    globaloffset:=0;
    globaltextmacrotrace:=0;

    while(i<c) do begin
        if(interf<>nil) and (i>=nextperiod) then begin
            nextperiod:=i+period;
            interf.ProPosition(i);
        end;


        if CompareLineWord('//!',incopy[i],wordend) then begin
            GetLineWord(incopy[i],word,wordend,wordend);
            if (word='jasshelperskip') then begin
                //skip to line k;
                GetLineWord(incopy[i],word,wordend,wordend);
                h:=StrToInt(word);
                //in theory, no bug should be here, but who knows?.
                if(h<i) then raise JASSerLineExceptionNoTextMacro(i,'[internal error] Wrong JASSHelper Skip');
                globaloffset:=globaloffset+h-i+1;
                i:=h;
            end else if (word='runtextmacro') then begin

                GetLineToken(incopy[i],word,wordend,wordend);
                optional := (word='optional');
                if(optional) then
                    GetLineToken(incopy[i],word,wordend,wordend);

                if(word='') then raise JASSerLineExceptionNoTextMacro(i,'Expected a name');
                h:=hash.ValueOf(word);
                tempish:=word;

                tempish:=word+Copy(incopy[i],wordend,Length(incopy));
                ParseCrazyCall(wordend,incopy[i]);

                if(h<0) then begin
                    if(not optional) then
                        raise JASSerLineExceptionNoTextMacro(i,'Unable to find textmacro: "'+word+'"');
                    TextMacro_addLine('//ignored textmacro command: '+tempish);
                    globaltextmacrotrace:=i+1;

                end else begin
                    macro:=macros[h];


                    if(parsedargsn<>macro.argsn) then raise JASSerLineDoubleExceptionNoTextMacro(i,'Invalid number of arguments (Expected: '+IntToStr(macro.argsn)+', got: '+IntToStr(parsedargsn)+')',macro.decl,'`--- macro declared here');
                    tmp:=globaloffset;
                    globaloffset:=macro.decl-ln;
                    tmp2:=ln;

                    TextMacro_addLine('//textmacro instance: '+tempish);
                    globaltextmacrotrace:=i+1;
                    macro.run(TDynamicStringArray(parsedarg));
                    globaltextmacrotrace:=0;
                    TextMacro_addLine('//end of: '+tempish);

                    globaloffset:=tmp-(ln-tmp2)+1;
                end;
//                macro.destroy;

            end else begin
                TextMacro_addline(incopy[i]);
            end;

        end else begin
            TextMacro_addline(incopy[i]);
        end;
        i:=i+1;
    end;

finally
{    if(macro<>nil) then begin
        macro.Destroy;
    end;}
    hash.destroy;
    for i := 0 to macron - 1 do macros[i].Destroy;
end;




end;



{   Tstruct = class(TObject)
   public
       decl:integer;
       name:string;
       members:TStringHash; //1:attribute, 2:private attribute, 3:method, 4:private method, 5:constructor, 6:private constructor, 7:destructor, 8:private destructor.
       constructor create;
       destructor destroy;
   end;
}

constructor Tmember.create(d:integer;const s:string;accs:integer; sta:boolean; method:boolean);
begin
    oninit_value:='';
    oninit_struct:='';
    decl:=d;
    abuse:=false;
    abuseexecv:=false;
    fromparent:=false;
    stub:=false;
    name:=s;
    access:=accs;
    ignore:=false;
    isstatic:=sta;
    isstaticarray:=False;
    ismethod:=method;
    construct:=false;
    destruct:=false;
    returntype:='nothing';
    argnumber:=0;

    arraydummy:=0;
    interdefault:='';
end;

procedure Tmember.addarg(const t:string; const n:string);
begin
    if(Length(argtypes)<=argnumber) then begin
         SetLength(argtypes,argnumber+5);
         SetLength(argnames,argnumber+5);
    end;
    argtypes[argnumber]:=t;
    argnames[argnumber]:=n;
    argnumber:=argnumber+1;
end;

procedure Tmember.abuseexecset(const b:boolean);
begin
     if(b) then abuse:=true;
     abuseexecv:=b;
end;

function Tstruct.GetOnInit:string;
var
 i,n:integer;

 anamesuf,anamepref,acommandsuf,acommandpref:TDynamicStringArray;



    procedure add(const np:string; const ns:string; const cp:string; const cs:string);
    begin
        if(Length(anamesuf)<=n) then begin
            SetLength(anamesuf,n*2+2);
            SetLength(anamepref,n*2+2);
            SetLength(acommandsuf,n*2+2);
            SetLength(acommandpref,n*2+2);
        end;
        anamesuf[n]:=ns;
        anamepref[n]:=np;
        acommandsuf[n]:=cs;
        acommandpref[n]:=cp;
        n:=n+1;
    end;

begin
   Result:='';

   SWriteLnSmart(Result,oninitv);

   SetLength(anamesuf,1);
   SetLength(anamepref,1);
   SetLength(acommandsuf,1);
   SetLength(acommandpref,1);

   if(self.requiredspace>=JASS_ARRAY_SIZE) then begin
       n:=0;
       for i := 0 to membern - 1 do if(members[i].oninit_value<>'') then  begin
           add(RConcatenate3('s__',members[i].oninit_struct,'_'),members[i].name, 'set ','='+members[i].oninit_value );
       end;
       if(n<>0) then begin
           GenerateMultiArrayPickerBatch(n,anamepref,anamesuf,Self.requiredspace,'this',4,acommandpref,acommandsuf,Result);
       end;
   end else for i := 0 to membern - 1 do begin
       if(members[i].oninit_value<>'') then  begin
           SWriteLnSmart(Result,RConcatenate6('   set s__',members[i].oninit_struct,'_',members[i].name,'[this]=',members[i].oninit_value));
       end;
   end;




end;

procedure Tstruct.addModuleOnInit(const s:string);
begin
    SWriteLn(self.modulesOnInit,'call ExecuteFunc("s__'+Self.name+'_'+s+'")' );
end;



procedure Tstruct.dropmember(const s:string);
var
   h:integer;
begin
   h:=membershash.valueof(s);
   if(h<0) then exit;
   Members[h].oninit_value:='';
   members[h].oninit_struct:='';
   Members[h].ignore:=true;
   membershash.Remove(s); //no convenience totally getting rid of it.


end;

procedure TStruct.makeArrayStruct;
begin
    isArrayStruct:=true;
    dropmember('allocate');
    dropmember('deallocate');
end;

function Tstruct.addmember(d:integer; const s:string;accs:integer; sta:boolean; method:boolean):tmember;
begin
    if(membern=Length(members)) then begin
         SetLength(members,membern+5);
    end;
    members[membern]:=Tmember.create(d,s,accs,sta,method);
    Result:=    members[membern];
    membershash.Add(s,membern);
    membern:=membern+1;

end;

procedure Tstruct.addDelegate(memb: Tmember);
begin
//it would be odd if someone added much more than two delegates, so provisions to optimize this would be lame.
    delegateN:=delegateN+1;
    SetLength(delegates,delegateN);
    delegates[delegateN-1]:=memb;
end;

function Tstruct.getmember(const s:string; var res:Tmember):boolean;
var
   h:integer;
begin
    h:=membershash.valueof(s);
    if(h<0) then begin
        Result:=false;
    end else begin
       res:=members[h];
       Result:=true;
    end;
end;

procedure Tstruct.addchild(i:integer);
begin
    SetLength(children,nchildren+1);
    children[nchildren]:=i;
    nchildren:=nchildren+1;
end;

constructor Tstruct.create(d:integer;int:boolean);
var
   m:tmember;
begin
    zincstruct:=false;
    parentname:='';
    bigArrayId:=-1; 
    isArrayStruct:=false;
    typeid:=1;
    FunctionInterfacePrototype:=-1;

    nchildren:=0;
    decl:=d;
    endline:=0;
    name:='????';
    isinterface:=int;
    gotstructchildren:=false;
    gotStubMethods:=false;
    lessthan:='';
    forInternalUse:=false;

    oninit:='';
    parent:=-1;
    parentstruct:=-1;
    membershash:=TStringHash.Create;
    membern:=0;
    ondestroy:=nil;
    SetLength(members,5);
    ondestroydone:=false;
    m:=addmember(-1,'allocate',0,true,true);
    m.construct:=true;
    m.access:=ACCESS_PRIVATE;
    m:=addmember(-1,'deallocate',0,false,true);
    m.access:=ACCESS_PRIVATE;
    m.destruct:=true;

    dofactory:=false;
    noargumentcreate:=false;
    customcreate:=false;

    addedArrayControl:=false;
    containsarraymembers:=false;

    customarray:=-1;
    customarraytype:='';

    delegateN:=0;

    requiredspace:=JASS_ARRAY_SIZE-1;
    maximum:=JASS_ARRAY_SIZE-1;
end;

function Tstruct.GetSuperParentName:string;
begin
    if(parent<>-1) then result:=StructList[parent].superparentname
    else if(parentstruct<>-1) then result:=StructList[parentstruct].superparentname
    else result:=name;

end;

function Tstruct.GetSuperParentNameForMethod(const methodname:string):string;
var memb:tmember;
begin
    self.getmember(methodname, memb);
    if(memb.fromparent) then begin
        if(parent<>-1) then result:=StructList[parent].superparentname
        else if(parentstruct<>-1) then result:=StructList[parentstruct].superparentname;
    end else begin
        result:=name;
    end;

end;

procedure Tstruct.beforedestruction;
var
   i:integer;
begin
    membershash.destroy;
    for i := 0 to membern - 1 do members[i].free;
end;

//}}}}}}}}}}

//assigns to r an assignment if it can be found from i.
function GetAssigment( const s:string; var r:string; fromi:integer):boolean;
var
   i,L,j:integer;
begin
    Result:=true;
    i:=fromi;
    L:=Length(s);
    r:='';
    while( (i<=L) and (s[i]<>'=') ) do begin
        if (s[i]='/') and (i<L) and (s[i+1]='/') then begin
            i:=L;
        end;
        i:=i+1;
    end;
    j := L - 1;
    while( j>=1 ) do begin
         if(s[j]='/') and (s[j+1]='/') then begin
             L:=j-1;
             break;
         end;
         j := j  -1;
    end;

    if(i>L) then Result:=false
    else r:=Copy(s,i+1, L-i);
end;


procedure ConcatenateManySep(var res:string; var s:Tdynamicstringarray; const total:integer; const sep:char);
var
  n,i,j:integer;
//  debugstr:string;

begin


//   debugstr:='';
   n:=0;
   for i := 0 to total - 1 do begin
//      debugstr:=s[i]+';;';
      n:=n+Length(s[i]);
   end;
   n:=n+total-1;


   SetLength(res,n);

   n:=1;
   if(total>0) then begin
       for j := 1 to Length(s[0]) do begin
           if(Length(res)<n) then raise Exception.Create('wtf1');
           res[n]:=s[0][j];
           n:=n+1;
       end;

       if(total>1) then for i := 1 to total - 1 do begin
           res[n]:=sep;
           n:=n+1;
           for j := 1 to Length(s[i]) do begin
              if(Length(res)<n) then raise Exception.Create('wtf2 '); //+IntToStr(n)+' , '+IntToStr(Length(res))+' ... '+IntToStr(total)+': '+debugstr);
              res[n]:=s[i][j];
              n:=n+1;
           end;
       end;
   end;
 //  debugstr:= res+'//'+debugstr;
  // res:=debugstr;

end;


procedure Concatenate3(var res:string; const s1,s2,s3:string);
var
  n:integer;

   procedure add(const s:string);
   var i:integer;
   begin
       for i := 1 to Length(s) do begin
           res[n]:=s[i];
           n:=n+1;
       end;
   end;


begin
  SetLength(res,Length(s1)+Length(s2)+Length(s3));
  n:=1;
  add(s1);add(s2);add(s3);

end;
function RConcatenate3(const s1,s2,s3:string):string;
begin
    Concatenate3(result,s1,s2,s3);
end;

procedure Concatenate4(var res:string; const s1,s2,s3,s4:string);
var
  n:integer;

   procedure add(const s:string);
   var i:integer;
   begin
       for i := 1 to Length(s) do begin
           res[n]:=s[i];
           n:=n+1;
       end;
   end;


begin
  SetLength(res,Length(s1)+Length(s2)+Length(s3)+Length(s4));
  n:=1;
  add(s1);add(s2);add(s3);add(s4);

end;
procedure Concatenate5(var res:string; const s1,s2,s3,s4,s5:string);
var
  n:integer;

   procedure add(const s:string);
   var i:integer;
   begin
       for i := 1 to Length(s) do begin
           res[n]:=s[i];
           n:=n+1;
       end;
   end;


begin
  SetLength(res,Length(s1)+Length(s2)+Length(s3)+Length(s4)+Length(s5));
  n:=1;
  add(s1);add(s2);add(s3);add(s4);add(s5);

end;
procedure Concatenate6(var res:string; const s1,s2,s3,s4,s5,s6:string);
var
  n:integer;

   procedure add(const s:string);
   var i:integer;
   begin
       for i := 1 to Length(s) do begin
           res[n]:=s[i];
           n:=n+1;
       end;
   end;


begin
  SetLength(res,Length(s1)+Length(s2)+Length(s3)+Length(s4)+Length(s5)+Length(s6));
  n:=1;
  add(s1);add(s2);add(s3);add(s4);add(s5);add(s6);

end;
function RConcatenate6(const s1,s2,s3,s4,s5,s6:string):string;
begin
    Concatenate6(Result,s1,s2,s3,s4,s5,s6);
end;

procedure Concatenate7(var res:string; const s1,s2,s3,s4,s5,s6,s7:string);
var
  n:integer;

   procedure add(const s:string);
   var i:integer;
   begin
       for i := 1 to Length(s) do begin
           res[n]:=s[i];
           n:=n+1;
       end;
   end;


begin
  SetLength(res,Length(s1)+Length(s2)+Length(s3)+Length(s4)+Length(s5)+Length(s6)+Length(s7));
  n:=1;
  add(s1);add(s2);add(s3);add(s4);add(s5);add(s6);add(s7);

end;
procedure Concatenate8(var res:string; const s1,s2,s3,s4,s5,s6,s7,s8:string);
var
  n:integer;

   procedure add(const s:string);
   var i:integer;
   begin
       for i := 1 to Length(s) do begin
           res[n]:=s[i];
           n:=n+1;
       end;
   end;


begin
  SetLength(res,Length(s1)+Length(s2)+Length(s3)+Length(s4)+Length(s5)+Length(s6)+Length(s7)+Length(s8));
  n:=1;
  add(s1);add(s2);add(s3);add(s4);add(s5);add(s6);add(s7);add(s8);

end;

procedure Concatenate9(var res:string; const s1,s2,s3,s4,s5,s6,s7,s8,s9:string);
var
  n:integer;

   procedure add(const s:string);
   var i:integer;
   begin
       for i := 1 to Length(s) do begin
           res[n]:=s[i];
           n:=n+1;
       end;
   end;


begin
  SetLength(res,Length(s1)+Length(s2)+Length(s3)+Length(s4)+Length(s5)+Length(s6)+Length(s7)+Length(s8)+Length(s9));
  n:=1;
  add(s1);add(s2);add(s3);add(s4);add(s5);add(s6);add(s7);add(s8);add(s9);

end;
procedure Concatenate10(var res:string; const s1,s2,s3,s4,s5,s6,s7,s8,s9,s10:string);
var
  n:integer;

   procedure add(const s:string);
   var i:integer;
   begin
       for i := 1 to Length(s) do begin
           res[n]:=s[i];
           n:=n+1;
       end;
   end;


begin
  SetLength(res,Length(s1)+Length(s2)+Length(s3)+Length(s4)+Length(s5)+Length(s6)+Length(s7)+Length(s8)+Length(s9)+Length(s10));
  n:=1;
  add(s1);add(s2);add(s3);add(s4);add(s5);add(s6);add(s7);add(s8);add(s9);add(s10);

end;
procedure Concatenate11(var res:string; const s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11:string);
var
  n:integer;

   procedure add(const s:string);
   var i:integer;
   begin
       for i := 1 to Length(s) do begin
           res[n]:=s[i];
           n:=n+1;
       end;
   end;


begin
  SetLength(res,Length(s1)+Length(s2)+Length(s3)+Length(s4)+Length(s5)+Length(s6)+Length(s7)+Length(s8)+Length(s9)+Length(s10)+Length(s11));
  n:=1;
  add(s1);add(s2);add(s3);add(s4);add(s5);add(s6);add(s7);add(s8);add(s9);add(s10);add(s11);

end;

procedure Concatenate12(var res:string; const s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12:string);
var
  n:integer;

   procedure add(const s:string);
   var i:integer;
   begin
       for i := 1 to Length(s) do begin
           res[n]:=s[i];
           n:=n+1;
       end;
   end;


begin
  SetLength(res,Length(s1)+Length(s2)+Length(s3)+Length(s4)+Length(s5)+Length(s6)+Length(s7)+Length(s8)+Length(s9)+Length(s10)+Length(s11)+Length(s12));
  n:=1;
  add(s1);add(s2);add(s3);add(s4);add(s5);add(s6);add(s7);add(s8);add(s9);add(s10);add(s11);add(s12);

end;

procedure Concatenate13(var res:string; const s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13:string);
var
  n:integer;

   procedure add(const s:string);
   var i:integer;
   begin
       for i := 1 to Length(s) do begin
           res[n]:=s[i];
           n:=n+1;
       end;
   end;


begin
  SetLength(res,Length(s1)+Length(s2)+Length(s3)+Length(s4)+Length(s5)+Length(s6)+Length(s7)+Length(s8)+Length(s9)+Length(s10)+Length(s11)+Length(s12)+Length(s13) );
  n:=1;
  add(s1);add(s2);add(s3);add(s4);add(s5);add(s6);add(s7);add(s8);add(s9);add(s10);add(s11);add(s12);add(s13);

end;


//---
function VerifyRedeclaration(const s:string; const ignoreglobals:boolean=false):Integer;
begin
    Result:=0;
    if(LocalIdentifierTypes.ValueOf(s)<>-1) then Result:=-1
    else if ( not(ignoreglobals) and (IdentifierTypes.ValueOf(s)<>-1)) then Result:=-1
    else if ( {not(ignoreglobals) and} (FunctionHash.ValueOf(s)<>-1)) then begin
        Result:=FunctionData[FunctionHash.ValueOf(s)].decl;
    end else if (StructHash.ValueOf(s)<>-1) then begin
        Result:=StructList[StructHash.ValueOf(s)].decl;
    end;
end;

//--
function GetHashtableKey:string;
begin
    HashtableKeys := HashtableKeys + 1 +integer(GetTickCount mod 2);
    result := IntToStr(HashtableKeys);
end;

//--

procedure VerifyRedeclarationRaise(const ln: integer;const s:string; const ignoreglobals:boolean=false);
var i:integer;
begin
    i:=VerifyRedeclaration(s,ignoreglobals);
    if(i=-1) then Raise JasserLineException(ln,'Identifier redeclared : "'+s+'"');
    if(i>0) then Raise JasserLineDoubleException(ln,'Identifier redeclared : "'+s+'"',i,'---- (previously declared here)');
end;

const ARRAYEDTYPE=1000000;
const METHODTYPE = -5;
const FUNCTION_NAME_TYPE = -6;

function structs_evaluatecode({const} s:string; var res:string;   fromstruct:integer; const pos:integer; const insetstatement:boolean=false):boolean; forward;
//if it is a correct global declaration, returns true and reevaluated version is in res.
//otherwise, returns false and error is in res.
function structs_evaluateglobal(const s:string; var res:string; const fromstruct:integer=-1):boolean;
var
   constant,isarray:boolean;
   word,name,assign, typename:string;
   x,h:integer;
begin
    // [constant] <type (possibly struct type)> [array] name [= assign]
       // constant structs simply don't have any sense.
       // struct types must be replaced with integer
       // and identifiertypes should make it point to the struct type id.
       // if we evaluated assign, it would later add issues cause it is impossible to declare functions before globals in war3map.j
       // so global declarations can't use . syntax.

   GetLineWord(s,word,x);
   constant:=(word='constant');
   if constant then begin
       GetLineWord(s,word,x,x);
   end;
   typename := word;

   //now word holds a possibly struct type.
   h:= StructHash.ValueOf(typename);
   if (h<>-1) and constant then begin
       res:='constant structs are not supported';result:=false;exit;
   end;
   GetLineToken(s,name,x,x);
   isarray:=(name='array');
   if isarray then begin
       GetLineToken(s,name,x,x);
   end;
   if (name='') then begin
       res:='Expected a name';result:=false;exit;
   end;
   if (not ValidIdentifierName(name)) then begin
       res:='Invalid identifier name: '+name;result:=false;exit;
   end;
   if (h<>-1) then begin
       VerifyRedeclarationRaise(RecCurrentLine,name);
       if(isarray) then IdentifierTypes.Add(name,h+ARRAYEDTYPE)
       else IdentifierTypes.Add(name,h);
   end;

   if GetAssigment(s,assign,x) then begin
       if(assign='') then begin
           res:='Missing expression'+name;result:=false;exit;
       end;
   end else assign:='';
   if(assign<>'') then begin
        if not structs_evaluatecode(assign, res, fromstruct, 1) then begin
            Result := false;
            exit;
        end;
        assign := res;

   end;

   if( word = 'key') then begin
       res:='';
       if(assign<>'') then res:='Unable to assign keys.'
       else if(isarray) then res:='key arrays are not allowed.';

       if(res<>'') then begin
          result:=false;
          exit;
       end;
       Concatenate4(res,'constant integer ',name,'=',GetHashtableKey);
       result:=true;
       exit;
   end;

   if ((assign<>'') and isarray) then begin
      res:='Cannot initialize arrays';result:=false;exit;
   end;
   if( h<>-1) then begin
        typename := 'integer';
   end;
   if (isarray) then
       res:=typename+' array '+name
   else if ( constant) then
       Concatenate4(res,'constant '+typename+' ',name,'=',assign)
   else if(assign='') then
       res:=typename+' '+name
   else
       Concatenate4(res,typename+' ',name,'=',assign);
   Result:=true;
end;



//if it is a correct function declaration, returns true and reevaluated version is in res.
//otherwise, returns false and error is in res.
function structs_evaluatefunction(const s:string; var res:string):boolean;
var
    x,L,k,h,indent:integer;
    word,name,argname,argtype:string;
begin


    GetLineWord(s,word,x);
    indent:=x-Length(word)-1;

    res:='';
    while(indent>0) do begin
        SWrite(res,' ');
        indent:=indent-1;
    end;
    if(word='constant') then begin
        SWrite(res,'constant ');
        GetLineWord(s,word,x,x);
    end;
    if(word<>'function') then begin
        res:='';Result:=false;Exit;
    end;
    SWrite(res,'function ');
    GetLineWord(s,name,x,x);
    if( not(validIdentifierName(name))) then begin
        res:='Not a valid function name: '+name;Result:=false;Exit;
    end;
    SWrite(res,name);
    if(not comparelineword('takes',s,x,x)) then begin
        res:='Expected "takes"';Result:=false;Exit;
    end;
    SWrite(res,' takes ');
    GetLineWord(s,word,x,x);
    if(word='nothing') then begin
        SWrite(res,'nothing');
        //no arguments

    end else begin
        L:=Length(s);
        x:=x-Length(word);
      while(true) do begin
        GetLineWord(s,argtype,x,x);
        if(argtype='') then begin
            res:='Expected an argument type';result:=false;exit;
        end;
        while(x<=L) and ((s[x]=' ') or (s[x]=#9)) do begin
            x:=x+1;
        end;
        if(x>L) then begin
            res:='Expected an argument name';result:=false;exit;
        end;
        k:=x;
        while(x<=L) and (s[x]<>' ') and (s[x]<>#9) and (s[x]<>',') do begin
            x:=x+1;
        end;
        argname:=Copy(s,k,x-k);
        while(x<=L) and ((s[x]=#9) or (s[x]=' ')) do begin
            x:=x+1;
        end;
        if(x>L) then begin
            res:='Expected , or returns';result:=false;exit;
        end;

        h:=StructHash.ValueOf(argtype);
        if(h<>-1) then begin
            SWrite(res,'integer ');

            VerifyRedeclarationRaise(RecCurrentLine,argname,true);
            LocalIdentifierTypes.Add(argname,h);

        end else begin
            VerifyRedeclarationRaise(RecCurrentLine,argname,true);
            LocalIdentifierTypes.Add(argname,-2);
            SWrite(res,argtype);
            SWrite(res,' ');
        end;
        SWrite(res,argname);
        if (x<=L) and (s[x]=',') then begin
            x:=x+1; //continue
            SWrite(res,',');
        end else break;


      end;
    end;
    if(not CompareLineWord('returns',s,x,x)) then begin
        res:='Expected returns';result:=false;exit;
    end;
    Swrite(res,' returns ');
    GetLineWord(s,word,x,x);
    h:=StructHash.ValueOf(word);
    if(h<>-1) then begin
        Swrite(res,'integer');
        // we already verified redeclaration before, no need for this: 
        //VerifyRedeclarationRaise(RecCurrentLine,name);
        IdentifierTypes.Add(name,h);

    end else begin
        Swrite(res,word);
    end;
    Result:=true;



end;

function EscapedBackSlash( const str:string; const L:integer; i:integer):boolean;
var
   c:integer;
begin
    c:=1;
    i:=i-1;
    while (i>0) and (str[i]='\') do begin
        c:=c+1;
        i:=i-1;
    end;
    Result:= (c mod 2=0);

end;


procedure parsemethod(const s:string; var obj:string; var sid:integer; var memb:string);
var
   i,k,L:integer;
begin
    //s__obj_methodname
    //structname.getMethod(methodname, obj)
    i:=1;
    L:=Length(s);
    while(i<=L) and (s[i]<>'.') do i:=i+1;
    sid:=StructHash.ValueOf(Copy(s,1,i-1));
    if(sid<0) then raise JasserLineException(RecCurrentLine,'[internal error] Malformed method passing data, report this bug.'#13#10#13#10+s);

    while(i<=L) and (s[i]<>'(') do i:=i+1;
    i:=i+1;
    k:=i+1;
    while(k<=L) and (s[k]<>',') do k:=k+1;

    memb:=Copy(s,i,k-i);

    obj:=Copy(s,k+1,L-k-1);
end;





function translateDotFunctionName(const s:string; var res:string; var typ:Tvtype; fromstruct:integer; const pos:integer):boolean;
var obj,memb:string;
    sid:integer;
begin
    parseMethod(s,obj,sid,memb);
    res:='"s__'+StructList[sid].name+'_'+memb+'"';
    typ:=MakeType(-1);

    result:=true;
end;

function TranslateFunctionName(const f:string; var res:string; var typ:Tvtype):boolean;forward;
function translateDotMethodPointer(const s:string; var res:string; var typ:Tvtype; fromstruct:integer; const pos:integer):boolean;
var obj,memb:string;
    k:integer;
    smemb:Tmember;
    sid:integer;
begin
    parseMethod(s,obj,sid,memb);
    res:='s__'+StructList[sid].name+'_'+memb+'';
    result:=false;
    if not StructList[sid].getmember(memb, smemb) then begin
        res:='Cannot find member: '+memb;
        exit;
    end;
    {if not smemb.isstatic then begin
        res:=StructList[sid].name+'.'+memb+' must be static.';
        exit;
    end;

    }
    if(( StructList[sid].name <> obj ) and (obj<>'this') )then begin
        res:='Correct usage is : structname.methodname, non-static methods DO NOT pass the instance when used as function pointers.';
        result:=false;
        exit;
    end;
    obj:=res;
    if not structList[sid].isinterface and  (FunctionHash.ValueOf(obj)=-1) then begin
        if(smemb.decl = -1) then
            raise JasserLineDoubleException(reccurrentline,smemb.name+' is an internal method that cannot be used for function pointers.',
                                            reccurrentline,'\--- Perhaps you meant: '+smemb.name+'()');
        parseFunction(input[smemb.decl] , smemb.decl);
    end;

    result:=TranslateFunctionName(obj, res, typ);
    typ:=MakeType(METHODTYPE,'method',s);
end;


function translateDotMethodExists(const s:string; var res:string; var typ:Tvtype; fromstruct:integer; const pos:integer):boolean;
var obj,memb:string;
    sid:integer;
    k,r:integer;
    smemb:Tmember;

begin
    parseMethod(s,obj,sid,memb);
    k:=StructList[sid].membershash.ValueOf(memb);
    if(k=-1) then begin
        res:='[Internal error] The method is not a member!? report this bug';
        result:=false;
        exit;
    end;
    if(not StructList[sid].members[k].ismethod) then begin
        res:='[Internal error] The method is not a method!? report this bug';
        result:=false;
        exit;
    end;
    if(StructList[sid].members[k].fromparent or StructList[sid].isinterface) then begin
        r:=StructHash.ValueOf(obj);
        if(-1 <> r ) then begin
            {if( r<>k ) then begin
                res:='false';
            end else begin
                res:='true';
            end;}
            if( StructList[r].getmember(memb,smemb) ) then
                res:='true'
            else
                res:='false';

        end else begin
            res:='si__'+StructList[sid].superparentname+'_type['+obj+']';
            res:='(st__'+StructList[sid].superparentname+'_'+memb+'['+res+']!=null)';
        end;
    end else begin
        res:='true';
    end;
    typ:=MakeType(-1);

    result:=true;
end;



function translateDotVar(const obj:string; const memb:string; sid:integer; styp: Tvtype; var res:string; var typ:Tvtype;   fromstruct:integer; const pos:integer; const insetstatement:boolean; const assign:string; const assigntyp: Tvtype; var converttocall:boolean ):boolean;overload;forward;

function translateDotVar(const obj:string; const memb:string; sid:integer; var res:string; var typ:Tvtype;   fromstruct:integer; const pos:integer; const insetstatement:boolean; const assign:string; const assigntyp: Tvtype; var converttocall:boolean ):boolean;overload;
begin
    resulT:=translateDotVar(obj,memb,sid,MakeType(sid),res,typ,fromstruct,pos,insetstatement,assign,assigntyp,converttocall);
end;

function translateDotVar(const obj:string; const memb:string; sid:integer; styp: Tvtype; var res:string; var typ:Tvtype;   fromstruct:integer; const pos:integer; const insetstatement:boolean; const assign:string; const assigntyp: Tvtype; var converttocall:boolean ):boolean;overload;
var
   tem:string;
   allowinstance:boolean;
   membd:Tmember;
   h:integer;


    function TryDelegate(const dmemb:Tmember):boolean;
     var typ2,typ3:Tvtype;
     var res2,res3:string;
     var converttocall3:boolean;
    begin
        if not translateDotVar(obj,dmemb.name,sid,styp,res2,typ2,{fromstruct}sid,pos,false,'',MakeType(0),converttocall) then begin
            raise Exception.Create('BAd internal error : '+res2);
        end;
        converttocall:=false;
        result:=false;
        if(translateDotVar(res2,memb,typ2.id,typ2,res3,typ3,fromstruct,pos,insetstatement,assign,assigntyp,converttocall3)) then begin
            result:=true;
            res:=res3;
            typ:=typ3;
            converttocall:=converttocall3;
        end;

    end;

begin
     converttocall:=false;

    {maybe later if(sid=FUNCTION_NAME_TYPE) then begin
        result:=translateDotVar(FunctionData[StrToInt(obj)].name,memb,-1,res,typ,fromstruct,pos,insetstatement,assign,assigntyp,converttocall);
        exit;
    end;}

    if (obj='') then begin//default
        if (fromstruct=-1) then begin
            res:='Unable to find default object ''.'' used without a preffix outside struct declaration';
            result:=false;exit;
        end;
        result:=translateDotVar('this',memb,fromstruct,MakeType(fromstruct),res,typ,fromstruct,pos,insetstatement,assign,assigntyp,converttocall);
        exit;
    end;
    h:=FunctionHash.ValueOf(obj);
    if(h<>-1) then begin
        result:=translateMemberOfFunction(obj,h,memb,res, typ);
        exit;

    end;


    allowinstance:=true;

    if(sid>=ARRAYEDTYPE) then begin
        res:=obj+' requires an index '+IntToStr(sid)+' ..';
        result:=false;
        exit;
    end;

    if(sid=METHODTYPE) then begin
        if(memb='name') then begin
           if(insetstatement) then begin
               result:=false;
               res:='.name is read-only';
               exit;
           end;

           translateDotFunctionName(styp.tag,res,typ,fromstruct,pos);
           result:=true;
           exit;
        end;
        if (memb='exists') then begin
           if(insetstatement) then begin
               result:=false;
               res:='.exists is read-only';
               exit;
           end;
           if(styp.name = 'method') then
               translateDotMethodExists(styp.tag,res,typ,fromstruct,pos)
           else
               translateDotMethodExists(obj,res,typ,fromstruct,pos);
           result:=true;
           exit;

        end;

        if(memb='execute') then raise JasserLineException(RecCurrentLine,'Expected (argument list) after execute');
        if(memb='_pointer') then begin
           if(insetstatement) then begin
               result:=false;
               res:='._pointer is read-only';
               exit;
           end;
           result:=translateDotMethodPointer(styp.tag,res,typ,fromstruct,pos);
           exit;

        end;

        raise JasserLineException(RecCurrentLine,'method has two members: .name , .exists');
    end;

    if(sid=-1) then begin
        h:=BigArrayHash.ValueOf(obj);
        if(h<>-1) then begin
            typ:=MakeType(-1);
        
            //It's a big array.
            if(memb='size') then begin

                result:=true;
                res:=IntToStr(BigArraySizes[h]);
            end else if(memb='width') then begin
                if(BigArrayWidths[h]=-1) then begin
                    raise JasserLineException(RecCurrentLine,'.width invalid since the array is one-dimensional.');
                end;
                result:=true;
                res:=IntToStr(BigArraySizes[h] div BigArrayWidths[h]);


            end else if(memb='height') then begin
                if(BigArrayWidths[h]=-1) then begin
                    raise JasserLineException(RecCurrentLine,'.width invalid since the array is one-dimensional.');
                end;
                result:=true;
                res:=IntToStr(BigArrayWidths[h]);

            end else begin
                raise JasserLineException(RecCurrentLine,'vJass Arrays only accept fields: size, width, height');
            end;
            exit;
        end;
    end;

    if (sid=-1) then begin
        //could be an attempt to use a static member
        sid:=structhash.ValueOf(obj);
        if (sid=-1) then begin
            res:=obj+' is not of a type that allows . syntax';
            result:=false;exit;
        end;
        allowinstance:=false;
    end;
    if( StructList[sid].FunctionInterfacePrototype<>-1) then begin
        result:=translateMemberOfFunctionInterface(obj,StructList[sid],memb, res, typ);
        exit;
    end;

    if(memb='typeid') then begin
        typ:=MakeType(-1);

        res:='si__'+StructList[sid].name;
        result:=true;
        exit;
    end;

    h:=StructList[sid].membershash.ValueOf(memb);



    if( h=-1) then begin
       // "properties"
       if (insetstatement) then begin
          h:=StructList[sid].membershash.ValueOf('_set_'+memb);
          if(h<>-1) then begin
              if(StructList[sid].members[h].returntype=StructList[sid].name) then begin

                  if translateDotMethod(obj,'_set_'+memb,assign,styp,res,typ,fromstruct,pos,false) then begin
                      //Concatenate4(res,'set ',obj,'=',tem);
                      //That line up there is faster
                      // but probably causes bugs
                      res:='set '+obj+'='+res;
                      result:=true;
                  end else
                      result:=false;
              end else begin
                  converttocall:=true;
                  result:=translateDotMethod(obj,'_set_'+memb,assign,styp,res,typ,fromstruct,pos,false);
              end;
              exit;
          end;
       end else begin
           h:=StructList[sid].membershash.ValueOf('_get_'+memb);
           if(h<>-1) then begin
               result:=translateDotMethod(obj,'_get_'+memb,'',styp,res,typ,fromstruct,pos,false);
               exit;
           end;
       end;

       if (StructList[sid].parent<>-1) then begin
          result:=translateDotVar(obj,memb,StructList[sid].parent,res,typ,fromstruct,pos,insetstatement,assign,assigntyp,converttocall);
          //exit;
       end else if (StructList[sid].parentstruct<>-1) then begin
          result:=translateDotVar(obj,memb,StructList[sid].parentstruct,res,typ,fromstruct,pos,insetstatement,assign,assigntyp,converttocall);
          //exit;
       end else begin
           res:=memb+' is not a member of '+StructList[sid].name; result:=false;
       end;
       if(not result) then begin
           //Try delegation:
           for h := 0 to StructList[sid].delegateN-1 do begin
               if(TryDelegate(StructList[sid].delegates[h]) ) then begin
                    result:=true;
                    exit;
               end;
           end;
       end;
       exit;
    end;

    membd:=StructList[sid].members[h];
    if (membd.access=ACCESS_PRIVATE) and (fromstruct<>sid) then begin
        res:=StructList[sid].name+'.'+memb+' is private';result:=false;exit;
    end;
    if (insetstatement and (membd.access=ACCESS_READONLY) and (fromstruct<>sid) ) then begin
        res:=StructList[sid].name+'.'+memb+' is read-only';result:=false;exit;
    end;

    if(membd.ismethod) then begin
        Concatenate6(res,StructList[sid].name,'.getMethod(',memb,',',obj,')');
        typ:=MakeType(METHODTYPE, 'method', res); //method
        tem:=res;
        if (TranslateDotMethodPointer(res,tem,typ,fromstruct,pos)) then
            res:=tem;

        result:=true;
        exit;
    end;
    if(membd.isstatic) then begin
        //ooh a static member.

        concatenate4(res,'s__',StructList[sid].name,'_',memb);
        typ:=MakeType(StructHash.ValueOf(membd.returntype));
    
        if(typ.id<>-1) and (membd.isstaticarray) then typ:=MakeType(typ.id+ARRAYEDTYPE);

    end else if (not allowinstance) then begin
        res:=memb+' is not an static member of '+StructList[sid].name;
        result:=false;
        exit;
    end else begin
        //ooh an instance member

        if(StructList[sid].requiredspace>=JASS_ARRAY_SIZE) then begin

            if(insetstatement) then begin
                if(obj='') then
                    concatenate7(res,'sg__',StructList[sid].name,'_set_',memb,'(this,',assign,')')
                else
                    concatenate9(res,'sg__',StructList[sid].name,'_set_',memb,'(',obj,',',assign,')');
                typ:=MakeType(-1);
            
                converttocall:=true;
                result:=true;
                exit;
            end else if(obj='') then
                concatenate5(res,'sg__',StructList[sid].name,'_get_',memb,'(this)')
            else
                concatenate7(res,'sg__',StructList[sid].name,'_get_',memb,'(',obj,')');

        end else begin
            if(obj='') then
                concatenate5(res,'s__',StructList[sid].name,'_',memb,'[this]')
            else
                concatenate7(res,'s__',StructList[sid].name,'_',memb,'[',obj,']');
        end;
        typ:=MakeType(StructHash.ValueOf(membd.returntype));
    
    end;
    Result:=true;
end;

function translateDotExecuteMethod(const s:string; const args:string; var res:string; var typ:Tvtype;   fromstruct:integer; const pos:integer):boolean;
var obj,memb:string;
    sid:integer;
begin
    parseMethod(s,obj,sid,memb);
    result:= translateDotMethod(obj,memb,args,MakeType(sid),res,typ,fromstruct,pos,true);
end;

function translateDotEvaluateMethod(const s:string; const args:string; var res:string; var typ:Tvtype;   fromstruct:integer; const pos:integer):boolean;
var obj,memb:string;
    sid:integer;
begin
    parseMethod(s,obj,sid,memb);
    result:= translateDotMethod(obj,memb,args,MakeType(sid),res,typ,fromstruct,pos,false, false, true );
end;


function translateDotMethod(const obj:string; const memb:string; const args:string; styp:Tvtype; var res:string; var typ:Tvtype;   fromstruct:integer; const pos:integer; const execute:boolean=false; const fromSuper:boolean=false; const evaluate:boolean=false):boolean;
var
   allowinstance,usedestroy:boolean;
   membd, membd2:Tmember;
   h:integer;
   prefix:string;

    function TryDelegate(const dmemb:Tmember):boolean;
     var typ2,typ3:Tvtype;
     var res2,res3:string;
     var dummyvar:boolean;
    begin
        if not translateDotVar(obj,dmemb.name,styp.id, styp,res2,typ2,{fromstruct}styp.id,pos,false,'',MakeType(0),dummyvar) then begin
            raise Exception.Create('Bad internal error #2 : '+res2);
        end;
        result:=false;
        if(translateDotMethod(res2,memb,args,typ2,res3,typ3,fromstruct,pos,execute)) then begin
            result:=true;
            res:=res3;
            typ:=typ3;
        end;

    end;


begin
    if (obj='super') and (fromstruct<>-1) then begin//default

        result:=translateDotMethod('this',memb,args,MakeType(fromstruct),res,typ,fromstruct,pos,execute,true);
        exit;
    end;


    if (obj='') then begin//default

        if (fromstruct=-1) then begin
            res:='Unable to find default object ''.'' used without a preffix outside struct declaration';
            result:=false;exit;
        end;
        result:=translateDotMethod('this',memb,args,makeType(fromstruct),res,typ,fromstruct,pos);
        exit;
    end;

    h:=FunctionHash.ValueOf(obj);
    if(h<>-1) then begin
        result:=translateMethodOfFunction(obj,h,memb,args, res, typ);
        if(result) then exit;

    end;

    allowinstance:=true;

    if(styp.id>=ARRAYEDTYPE) then begin
        res:=obj+' requires an index';
        result:=false;
        exit;
    end;

    if(styp.id=METHODTYPE) then begin
        if(memb='evaluate') then begin
             result:=translateDotEvaluateMethod(styp.tag ,args,res,typ,fromstruct,pos);
             exit;
        end;
        if(memb<>'execute') then raise JasserLineException(RecCurrentLine, 'expected .evaluate, .execute or an struct variable instead of method.');

        result:=translateDotExecuteMethod(styp.tag,args,res,typ,fromstruct,pos);
        exit;
    end;

    if (styp.id=-1) then begin
        //could be an attempt to use a static member
        styp:=MakeType(structhash.ValueOf(obj));
        if (styp.id=-1) then begin
            res:=obj+' is not of a type that allows . syntax';
            result:=false;exit;
        end;
        allowinstance:=false;
    end;

    if( StructList[styp.id].FunctionInterfacePrototype<>-1) then begin
        result:=translateMethodOfFunctionPointer(obj,StructList[styp.id],memb,args, res, typ);
        exit;
    end;

    h:=StructList[styp.id].membershash.ValueOf(memb);
    if( h=-1) then begin

       if (memb='getType') {and StructList[sid].isinterface} then begin
          if(not allowinstance) then begin
              res:='getType is an instance method';
              result:=false;
              exit;
          end;
          if(args<>'') then begin
               res:='Unexpected arguments given to getType';
               result:=false;
               exit;
          end;
          if(StructList[styp.id].isInterface or StructList[styp.id].gotstructchildren) then begin
            if(StructList[styp.id].requiredspace>=JASS_ARRAY_SIZE) then begin
              Concatenate5(res,'si__',StructList[styp.id].superparentname,'_getType(',obj,')');
            end else begin
              Concatenate5(res,'si__',StructList[styp.id].superparentname,'_type[',obj,']');
            end;

          end else begin
             res:=IntToStr(styp.id);
          end;
          typ:=MakeType(-1);
          result:=true;
          exit;
       end;

       if (StructList[styp.id].parent<>-1) then begin
          result:=translateDotMethod(obj,memb,args,MakeType(StructList[styp.id].parent),res,typ,fromstruct,pos);
       end else if (StructList[styp.id].parentstruct<>-1) then begin
          result:=translateDotMethod(obj,memb,args,MakeType(StructList[styp.id].parentstruct),res,typ,fromstruct,pos,execute);
       end else begin
          if (memb='_lessthan') then begin
              res:=StructList[styp.id].name+' does not overload a < operator'; result:=false;
          end else begin
              res:=memb+' is not a member of '+StructList[styp.id].name; result:=false;
          end;
       end;
       if(not result) then begin
           for h := 0 to StructList[styp.id].delegateN-1 do begin
               if(TryDelegate(StructList[styp.id].delegates[h]) ) then begin
                    result:=true;
                    exit;
               end;
           end;
       end;
       exit;
    end;

    if(StructList[styp.id].forInternalUse) then begin
        Result:=false;
        Res:=StructList[styp.id].name+' does not allow methods';
        Exit;
    end;

    membd:=StructList[styp.id].members[h];
    if (membd.access=ACCESS_PRIVATE) and (fromstruct<>styp.id) then begin
        res:=StructList[styp.id].name+'.'+memb+' is private';result:=false;exit;
    end;

    if(not membd.ismethod) then begin res:=memb+' is not a method.'; result:=false; exit; end;

    if(membd.fromparent and StructList[styp.id].gotstructchildren) and not fromSuper then begin
         if(structList[styp.id].parent<>-1) then begin
             result:=TranslateDotMethod(obj,memb,args,MakeType(structlist[styp.id].parent),res,typ,fromstruct,pos,execute);
         end else if (structlist[styp.id].parentstruct<>-1) then begin
             result:=TranslateDotMethod(obj,memb,args,MakeType(structlist[styp.id].parentstruct),res,typ,fromstruct,pos,execute);
         end else begin
             res:='[internal error] member comes from parent but struct has no parent???!!';
             result:=false;
         end;
         exit;
    end;


    if ((membd.argnumber>0) and (args='')) then begin res:=memb+' requires more arguments'; result:=false; exit; end;

    if (execute) then  begin
        membd.abuseexec:=true;
        prefix:='sx__'
    end else if (membd.decl>pos) then begin
        if(     (not evaluate)
             and not AUTOMETHODEVALUATE
             and not( (Length(membd.name)>=1) and (membd.name[1]='_') )
             and not ( membd.construct )
             and not ( membd.destruct )
          )

        then
            raise JasserLineDoubleException(pos,'Since you added [forcemethodevaluate] to jasshelper.conf, calling methods "from above their declaration" requires you to add .evaluate, correct this mistake.', pos, 'You may alternatively edit jasshelper.conf and remove that option.');
        membd.abuse:=true;
        prefix:='sc__';
    end else if(StructList[styp.id].isinterface) or (membd.stub) then prefix:='sc__'
    else prefix:='s__';

    if(fromSuper) then begin
        if(execute) then
             raise JasserLineException(pos,'Sorry, can''t use super and execute right now');
        if StructList[styp.id].parentStruct=-1 then
             raise JasserLineException(pos,'The struct has no parent, cannot use super');
        if not StructList[StructList[styp.id].parentStruct].getmember(membd.name,membd2) then
             raise JasserLineException(pos,'The parent struct has no member called '+membd.name);
        if (membd2.decl>pos) then
             raise JasserLineDoubleException(pos, 'Sorry, but for now super cannot call methods declared bellow the line.',membd.decl,'---- Parent''s method declared here.');

        if( args<>'') then
            Concatenate9(res,'s__',StructList[StructList[styp.id].parentStruct].name,'_',memb,'(',obj,',',args,')')
        else
            Concatenate7(res,'s__',StructList[StructList[styp.id].parentStruct].name,'_',memb,'(',obj,')');
        Result:=true;
        exit;
    end;



    if (membd.destruct) then begin
        usedestroy:=false;
        if( (styp.id<>fromstruct) and (membd.access=ACCESS_PRIVATE) ) then begin
            raise JasserLineException(RecCurrentLine,StructList[styp.id].name+'.'+membd.name+' is private.')
        end;

        if(StructList[styp.id].isarraystruct) then begin
            raise JasserLineException(RecCurrentLine,'Array structs cannot be destroyed.')
        end else if (execute) then
            raise JasserLineException(RecCurrentLine,'No reason to use .execute on destructor...')
        else if(StructList[styp.id].parent<>-1) then begin
            prefix:='sc__';
            styp:=MakeType( StructList[styp.id].parent );
        end else if(StructList[styp.id].parentstruct<>-1) then begin
            prefix:='sc__';
            while (StructList[styp.id].parentstruct<>-1) do begin
                styp:=MakeType( StructList[styp.id].parentstruct );
                if( StructList[styp.id].getmember('destroy',membd2) and not membd2.destruct ) then begin
                    if(membd2.decl > pos) then begin
                         membd2.abuse:=true;
                         prefix:='sc__';
                    end else begin
                         prefix:='s__';
                    end;
                    usedestroy:=true;
                    break;
                end;
            end;
            if (StructList[styp.id].parent<>-1) then styp:=MakeType(StructList[styp.id].parent);
        end else if(StructList[styp.id].gotstructchildren) then begin
            prefix:='sc__';
        end else begin
            {if StructList[sid].getmember('onDestroy',membd2) then begin
                if(membd2.decl > pos) then
                    prefix:='sc__'
                else
                    prefix:='s__';
            end else
                prefix:='s__';}
        end;
        if(usedestroy) then begin
            if( args<>'') then
                Concatenate7(res,prefix,StructList[styp.id].name,'_',{memb}'destroy','(',args,')')
            else
                Concatenate7(res,prefix,StructList[styp.id].name,'_',{memb}'destroy','(',obj,')');

        end else begin
            if( args<>'') then
                Concatenate7(res,prefix,StructList[styp.id].name,'_',{memb}'deallocate','(',args,')')
            else
                Concatenate7(res,prefix,StructList[styp.id].name,'_',{memb}'deallocate','(',obj,')');

        end;
        typ:=MakeType(-1);
    


    end else if(membd.isstatic) then begin

        if(membd.construct) then begin
           if (StructList[styp.id].isArrayStruct) then begin
                res:='Array structs cannot be allocated';
                result:=false;
                exit;
           end else if (StructList[styp.id].isinterface) then begin

               if(args='') then begin
                  res:='Interface constructor requires a type id argument';result:=false;exit;
               end;
               typ:=MakeType(styp.id);
           
               Result:=true;
               concatenate5(res,prefix,StructList[styp.id].name,'__factory(',args,')');
               StructList[styp.id].dofactory:=true;
               exit;
           end
           else if(StructList[styp.id].parentstruct<>-1) then begin
               typ:=MakeType(styp.id);
           
               Result:=true;
               concatenate5(res,prefix,StructList[styp.id].name,'__allocate(',args,')');
           end
           else if(args<>'') then begin
               res:='constructor requires no arguments'; result:=false; exit;
               Result:=false;
           end else begin
               typ:=MakeType(styp.id);
           
               Result:=true;
               concatenate3(res,prefix,StructList[styp.id].name,'__allocate()');

           end;


           exit;
       end;

        //ooh a static member.
        concatenate7(res,prefix,StructList[styp.id].name,'_',memb,'(',args,')');
        typ:=MakeType(StructHash.ValueOf(membd.returntype));
    

    end else if (not allowinstance) then begin
        res:=memb+' is not an static member of '+StructList[styp.id].name;
        result:=false;
        exit;
    end else begin


        //ooh an instance member
        if(args='') then begin
          if(obj='') then
            concatenate5(res,prefix,StructList[styp.id].name,'_',memb,'(this)')
          else
            concatenate7(res,prefix,StructList[styp.id].name,'_',memb,'(',obj,')');
        end else begin
          if(obj='') then
            concatenate7(res,prefix,StructList[styp.id].name,'_',memb,'(this,',args,')')
          else
            concatenate9(res,prefix,StructList[styp.id].name,'_',memb,'(',obj,',',args,')');
        end;
        typ:=MakeType(StructHash.ValueOf(membd.returntype) );

    end;


    Result:=true;
end;


function TryStrToIntX(const s:string;var x:integer):boolean;
var
   min,num,oct:boolean;


   i,r:integer;
begin
    min:=false;
    num:=false;
    oct:=false;
    r:=0;
    for i := 1 to Length(s) do begin
        if (not num) then begin
            if (s[i]=' ') then
            else if (s[i]='-') then begin
                 if(min) then begin result:=false; exit; end;
                 min:=true;
            end else if (s[i] in ['0'..'9']) then begin
                r:=integer(s[i])-integer('0');
                num:=true;
                if(s[i]='0') then oct:=true;
            end else begin
                result:=false;
                exit;
            end;


        end else if (s[i] in ['0'..'9']) then begin
            if(oct) then
                r:=r*8+integer(s[i])-integer('0')
            else
                r:=r*10+integer(s[i])-integer('0');

        end else begin
             result:=false;
             exit;
        end;
    end;
    result:=num;
    if(min) then r:=-r;
    if(result) then x:=r;

end;


function translateIndexSet( const obj:string; const sid:integer; const ind:string; const val:string;
          var res:string; var typ:Tvtype;  fromstruct:integer; const pos:integer):boolean;

var esp,h:integer;

    function TryDelegate(const dmemb:Tmember):boolean;
     var typ2,typ3:Tvtype;
     var res2,res3:string;
     var dummyvar:boolean;
    begin
        if not translateDotVar(obj,dmemb.name,sid,res2,typ2,{fromstruct}sid,pos,false,'',MakeType(0),dummyvar) then begin
            raise Exception.Create('Bad internal error #4: '+res2);
        end;
        result:=false;
        if(translateIndexSet(res2,typ2.id,ind,val,res3,typ3,fromstruct,pos)) then begin
            result:=true;
            res:=res3;
            typ:=typ3;
        
        end;

    end;
begin

    h:=BigArrayHash.ValueOf(obj);
    if(h<>-1) then begin
        if(bigArrayWidths[h]<>-1) then begin
            res:='Illegal assignment of 2D array';
            result:=false;
            exit;
        end;
        result:=true;
        typ:=MakeType(StructHash.ValueOf(BigArrayTypes[h]));
    
        if(BigArraySizes[h]>JASS_ARRAY_SIZE) then begin
            Concatenate7(res,'call sg__',BigArrayNames[h],'_set(',ind,',',val,')');
        end else begin
            Concatenate6(res,'set s__',BigArrayNames[h],'[',ind,']= ',val);
        end;
        exit;
    end;


    esp:=StructHash.ValueOf(obj);

    if(esp<>-1 ) then begin
        if (StructList[esp].membershash.ValueOf('_staticsetindex')<>-1) then begin
            result:=translateDotMethod(obj, '_staticsetindex', ind+', '+val, MakeType(esp), res, typ, fromstruct, pos);

            res:='call '+res;
        end else begin
            result:=false;
        end;
        exit;
    end;


    if ((sid>=ARRAYEDTYPE)or(sid=-1) or (sid=METHODTYPE) ) then begin result:=false; exit; end;

    h:=StructList[sid].bigArrayId;
    if(h<>-1) then begin
        result:=true;
        typ:=MakeType( StructHash.ValueOf(BigArrayTypes[h]) );
    
        if(BigArraySizes[h]>JASS_ARRAY_SIZE) then begin
            Concatenate9(res,'call sg__',BigArrayNames[h],'_set(',obj,'+',ind,',',val,')');
        end else begin
            Concatenate8(res,'set s__',BigArrayNames[h],'[',obj,'+',ind,']= ',val);
        end;
        exit;
    end;

    if(StructList[sid].customarray>0) then begin
        if(TryStrToIntX(ind,h)) then begin
            if ((h>=StructList[sid].customarray) or (h<0)) then begin
                 res:='Array index out of bounds: '+ind; result:=false; exit;
            end;
        end;
        if(StructList[sid].requiredspace>=JASS_ARRAY_SIZE) then begin
            if(h=0) then
                Concatenate7(res,'call sg__',StructList[sid].name,'_set(',obj,',',val,')')
            else
                Concatenate9(res,'call sg__',StructList[sid].name,'_set(',obj,'+',ind,',',val,')');

        end else begin
            if(h=0) then
                Concatenate6(res,'set s__',StructList[sid].name,'[',obj,']=',val)
            else
                Concatenate8(res,'set s__',StructList[sid].name,'[',obj,'+',ind,']=',val);
        end;
        typ:=MakeType(-1);
    
        Result:=true;


    end else begin
      h:=StructList[sid].membershash.ValueOf('_setindex');
      if (h<>-1) then begin
        result:=translateDotMethod(obj, '_setindex', ind+', '+val, MakeType(sid), res, typ, fromstruct, pos);
        if(StructList[sid].members[h].returntype=StructList[sid].name) then
            res:='set '+obj+'='+res
        else
            res:='call '+res;
      end else begin
        result:=false;
      end;
      if(not result) then begin
          for h := 0 to StructList[sid].delegateN-1 do begin
              if TryDelegate(StructList[sid].delegates[h]) then begin
                  result:=true;
                  exit;
              end;

          end;
      end;
    end;




end;

function translateArray(const arr:string; const ind:string; sid:integer; var res:string; var typ:Tvtype;   fromstruct:integer; const pos:integer; const insetstatement:boolean; const allowgetstructindex:boolean=false):boolean;
var
   h:integer;


    function TryDelegate(const dmemb:Tmember):boolean;
     var typ2,typ3:Tvtype;
     var res2,res3:string;
     var dummyvar:boolean;
    begin
        if not translateDotVar(arr,dmemb.name,sid,res2,typ2,{fromstruct}sid,pos,false,'',MakeType(0),dummyvar) then begin
            raise Exception.Create('Bad internal error #3: '+res2);
        end;
        result:=false;
        if(translateArray(res2,ind,typ2.id,res3,typ3,fromstruct,pos,insetstatement,allowgetstructindex)) then begin
            result:=true;
            res:=res3;
            typ:=typ3;
        
        end;

    end;


begin

    h:=BigArrayHash.ValueOf(arr);
    if(h<>-1) then begin
        result:=true;
        if(bigArrayWidths[h]<>-1) then begin
            //2D !
            typ:=MakeType(BigArrayStructs[h] );
        
            Concatenate5(res,'(',ind,')*(',IntToStr(BigArrayWidths[h]),')');
            exit;
        end;

        typ:=MakeType( StructHash.ValueOf(BigArrayTypes[h]) );
    
        if(BigArraySizes[h]>JASS_ARRAY_SIZE) then begin
            Concatenate5(res,'sg__',BigArrayNames[h],'_get(',ind,')');
        end else begin
            Concatenate5(res,'s__',BigArrayNames[h],'[',ind,']');
        end;
        exit;
    end;


    h:=StructHash.ValueOf(arr);
    if (h<>-1) and (StructList[h].customarray<=0) then begin
        if(allowgetstructindex) then h:= StructList[h].membershash.valueOf('_staticgetindex')
        else h:=-1;
        if (h<>-1) then begin
            result:=translateDotMethod(arr,'_staticgetindex',ind,MakeType(sid),res,typ,fromstruct,pos);
            exit;
        end else begin
            h:=StructHash.ValueOf(arr);
            if(StructList[h].isarraystruct) then begin
                if(insetstatement) then begin
                    res:='Cannot assign a struct array''s index';
                    result:=false;
                    exit;
                end;
                typ:=MakeType(h);
            
                Res:='('+ind+')';
                result:=true;
                exit;
            end;
            res:=arr+' is not an array.'; Result:=false; exit;
        end;


    end;




    if ((sid=-1) or (sid>=ARRAYEDTYPE)) then begin
        //just print out
        //res:='['+ind+']';
        //Result:=true;
        concatenate4(res,arr,'[',ind,']');
        result:=true;
    
        if(sid>=ARRAYEDTYPE) then typ:=MakeType(sid-ARRAYEDTYPE)
        else typ:=MakeType(-1);

        exit;
    end;



    if(sid=METHODTYPE) then begin
        res:='Unexpected: [';
        result:=false;
        exit;
    end;


    if(sid<=0) then begin
        res:='[Internal error] wrong "sid" (contact Vexorian about this)';
        result:=false;
        exit;
    end;


    if (StructList[sid].customarray<=0) then begin
        h:=StructList[sid].bigArrayId;
        if(h<>-1) then begin
            result:=true;
            typ:=MakeType(StructHash.ValueOf(BigArrayTypes[h]) );
        
            if(BigArraySizes[h]>JASS_ARRAY_SIZE) then begin
                Concatenate7(res,'sg__',BigArrayNames[h],'_get(',arr,'+',ind,')');
            end else begin
                Concatenate7(res,'s__',BigArrayNames[h],'[',arr,'+',ind,']');
            end;
            exit;
        end;

        if(allowgetstructindex) then begin
            if(translateDotMethod(arr,'_getindex',ind,MakeType(sid),res,typ,fromstruct,pos)) then begin
                result:=true;
                exit;
            end;
            for h := 0 to StructList[sid].delegateN - 1 do begin
                if(TryDelegate(StructList[sid].delegates[h]) ) then begin
                    result:=true;
                    exit;
                end;
            end;

        end;
        res:=arr+' is not an array.'; result:=false; exit;
    end;
    h:=-1;
    if(TryStrToIntX(ind,h)) then begin
        if ((h>=StructList[sid].customarray) or (h<0)) then begin
             res:='Array index out of bounds: '+ind; result:=false; exit;
        end;
    end else h:=-1;


    if(StructList[sid].requiredspace>=JASS_ARRAY_SIZE) then begin
        if(h=0) then
            Concatenate5(res,'sg__',StructList[sid].name,'_get(',arr,')')
        else
            Concatenate7(res,'sg__',StructList[sid].name,'_get(',arr,'+',ind,')');

    end else begin
        if(h=0) then
            Concatenate5(res,'s__',StructList[sid].name,'[',arr,']')
        else
            Concatenate7(res,'s__',StructList[sid].name,'[',arr,'+',ind,']');
    end;
    typ:=MakeType( StructHash.ValueOf(StructList[sid].customarraytype) );

    Result:=true;
end;

function translateMethodCode( const clas:string; const meth:string; var res:string; fromstruct:integer; const pos:integer):boolean;
var
  h,k:integer;
  memb:Tmember;
  prefix:string;
begin
    h:=Structhash.ValueOf(clas);
    if(h=-1) then begin res:=clas+' is not an struct name'; result:=false; exit; end;

    k:= StructList[h].membershash.ValueOf(meth);
    if(k=-1) then begin res:=meth+' is not a member of '+clas; result:=false; exit; end;
    memb:=StructList[h].members[k];
    if (memb.ismethod and memb.isstatic and (memb.argnumber=0)) then begin
        if( (memb.access=ACCESS_PRIVATE) and (fromstruct<>h)) then begin
            result:=false; res:=StructList[h].name+'.'+meth+' is private.'; Exit;
        end;
        if (memb.decl>pos) then begin
            memb.abuse:=true;
            prefix:='sc__';
        end
        else prefix:='s__';

        Concatenate5(res,'function ',prefix,StructList[h].name,'_',meth);
        result:=true;

    end else begin
        result:=false;
        res:=meth+' is not an static method of '+clas+' that takes nothing.';
    end;

end;


function translateLessThan( const m1:string; i1:integer; const m2:string; i2:integer; var res:string; fromstruct:integer; const pos:integer):boolean;
var
  h:Tvtype;

begin

    if ( (i1=-1) or (i2=-1) ) then begin
        res:='Relational comparission between special type and native type.';
        result:=false; exit;
    end;


    if (i1<>i2) then begin
        res:='Relational comparission between different struct types.';
        result:=false; exit;
    end;


    result:=translateDotMethod( m1,'_lessthan',m2, MakeType(i1), res, h,  fromstruct, pos);

end;

function translateEqualTo( const m1:string; i1:integer; const m2:string; i2:integer; var res:string; fromstruct:integer; const pos:integer; const negate:boolean):boolean;
var
  h:Tvtype;
  memb:Tmember;
  label normal;
begin



    if ( (i1=-1) or (i2=-1) ) then begin
        goto normal;
        {res:='== comparission between special type and native type?';
        result:=false; exit;}
    end;

    if (i1<>i2) then begin
        goto normal;
        {res:='== comparission between different struct types.';
        result:=false; exit;}
    end;
    if( (i1<1) or (StructN<i1) ) then goto normal;

    if( StructList[i1].getmember('_equalto', memb) ) then begin







        result:=translateDotMethod( m1,'_equalto',m2, MakeType(i1), res, h,  fromstruct, pos);
        if(negate) then res:='not ('+res+')';
    end else begin
     normal:
        if(negate) then res:=m1+' != '+m2
        else            res:=m1+' == '+m2;
        result:=true;
        //result:=translateDotMethod( m1,'_equal',m2, i1, res, h,  fromstruct, pos);
    end;




end;


function TranslateFunctionName(const f:string; var res:string; var typ:Tvtype):boolean;
var
   h:integer;
begin
    h:=FunctionHash.ValueOf(f);
    Result:=false;
    if(h<>-1) then begin
        Result:=true;
        TranslateMemberOfFunction(f,h,'_pointer',res,typ);
    end else begin
        res:='Cannot find function: '+f;
    end;
end;

function TryGetTypeOf(const s:string):Tvtype;
begin
    Result:=MakeType(LocalIdentifierTypes.ValueOf(s) );
    if(Result.id=-1) then Result:=MakeType(IdentifierTypes.ValueOf(s) );
    if(Result.id=-2) then Result:=MakeType(-1 );
end;

const
    STRUCT_STRING_LIMIT: integer = 62;
var
 StructStrings: array of string;
 StructStringN:integer;


procedure addStructString(const  s:string);
begin
   if(Length(StructStrings)<=StructStringN) then begin
       SetLength(StructStrings,StructStringN+3+(StructStringN div 3) );
   end;
   StructStrings[StructStringN]:=s;
   StructStringN:=StructStringN+1;
end;


function preprocessStructStrings(var s:string):boolean;
var i,k,L:integer;

begin
    StructStringN:=0;
    L:=Length(s);
    i:=1;
    while(i<=L) do begin
        if(s[i]='"') then begin
            k:=i;
            i:=i+1;
            while(i<=L) do begin
                if(s[i]='"') then break
                else if(s[i]='\') then i:=i+1;

                i:=i+1;

            end;
            if(i>L) then break;

            if(StructStringN=STRUCT_STRING_LIMIT) then begin
                result:=false;
                exit;
            end;
            if((k+1)<>i) then begin
                addStructString(Copy(s,k,i-k+1));
                //prevent having one of these with the escape char...
                if Char(Byte('A')+StructStringN-1) = '\' then
                    addStructString(Copy(s,k,i-k+1));
                s[k+1]:=Char(Byte('A')+StructStringN-1);
                k:=k+2;
                while(k<i) do begin
                    s[k]:=' ';
                    k:=k+1;
                end;

            end;

            i:=i+1;
        end else if(s[i]='/') and (i<L) and (s[i+1]='/') then break
        else i:=i+1;
    end;
 result:=true;
end;


function structStringGet(const  s:string):string;
begin
  if(s='""') then result:=s
  else result:=StructStrings[byte(s[2])-byte('A')];

end;

function structs_evaluate_terminal(tok:TToken):string;
begin
    if(tok.Kind<>SymbolTypeNonterminal) then begin
        result:=tok.DataVar;
    end else if(tok.Reduction.TokenCount=0) then begin
        result:='';
    end else if(tok.Reduction.TokenCount>1) then begin
        result:='?';
    end else begin
        result:=structs_evaluate_terminal(tok.Reduction.tokens[0]);
    end;
end;

function MakeType(const id:integer):Tvtype; overload;
begin
   Result:=Tvtype.Create;
   Result.id := id;
   Result.name:='_unknown';
end;
function MakeType(const id:integer; const name:string):Tvtype; overload;
begin
   Result:=Tvtype.Create;
   Result.id := id;
   Result.name:=name;
end;
function MakeType(const id:integer; const name:string; const tag:string):Tvtype; overload;
begin
   Result:=Tvtype.Create;
   Result.id := id;
   Result.name:=name;
   Result.tag := tag;
end;

function evaluate_value_type( const wanted:Tvtype;  var s:string; var typ:Tvtype):boolean;
begin
    if (wanted.name ='_unknown') or (typ.name='_unknown') then begin
        result:=true;
        exit;
    end;
    if(wanted.name ='boolexpr') and (typ.name='code') then begin
        s:='Condition('+s+')';
        typ:=wanted;
        result:=true;
        exit;
    end;
    result:=true;
end;


function structs_evaluate_rec(tok: TToken; var res:string; var typ:Tvtype; fromstruct:integer; const pos:integer):boolean;overload; forward;
function structs_evaluate_JassLibArguments( const funname: string; tok:TToken; var res:string; var typ:Tvtype; fromstruct:integer; pos:integer):boolean;
 var
    ctok:TToken;
    red:Treduction;
    func:TJassFunc;
    i:integer;
    typ1: Tvtype;
    res1: string;
    argtok: Array of TToken;
    an : integer;
begin


   result:=false;
   if not Jasslib.VerifyJassFunc(funname, func) then begin
       res:='[internal error] Expected a function?';
       exit;
   end;
   res:='';
   SetLength(argtok,func.argumentn);
   an:=0;
   while(tok<>nil) do begin
       red:=tok.Reduction;
       ctok:=nil;
       case RuleConstants(Red.ParentRule.TableIndex) of
          RULE_ARGUMENTS: (* <Arguments> ::= <Expression> *)
          begin
              tok := nil;
              ctok:=red.Tokens[0];
          end;
          RULE_ARGUMENTS_COMMA: (* <Arguments> ::= <Expression> , <Arguments> *)
          begin
              ctok:=red.Tokens[0];
              tok:=red.Tokens[2];
          end;
          else begin
              break;
          end;
       end;
       if(an = func.argumentn) then begin
           res:='Too many arguments given to function : '+funname;
           exit;
       end;
       argtok[ an ] :=ctok;
       an:=an+1;

   end;
   if (an < func.argumentn) then begin
       res:='Not enough arguments given to function : '+funname;
       exit;
   end;

   for i := 0 to func.argumentn-1 do begin
       ctok:=argtok[i];
       if( not structs_evaluate_rec(ctok, res1, typ1, fromstruct, pos) ) then begin
           res:=res1;
           exit;
       end;

       if not evaluate_value_type( MakeType(-1,func.arguments[i] ) , res1, typ1) then begin
           res:=res1;
           exit;
       end;
       if(res='') then res:=res1
       else res:=res+', '+res1;


   end;
   result:=true;


end;


function structs_evaluate_rec(tok: TToken; var res:string; var typ:Tvtype; fromstruct:integer; const pos:integer):boolean;overload;
var red:Treduction;
var s1,s2,s3,s4:string;
    i1,i2,i3,i4:Tvtype;
    i:integer;
    tmfunc:TJassFunc;
var
   stevrecd: Tdynamicstringarray;
   unused,tocall:boolean;


   procedure handleArraySet(arrtok: TToken;indtok: TToken;valtok: TToken; var result:boolean);
   begin
       result:=true;
             if not structs_evaluate_rec(arrtok,s1,i1,fromstruct,pos)
             then begin res:=s1; result:=false; exit; end;

             if not structs_evaluate_rec(indtok,s2,i2,fromstruct,pos)
             then begin res:=s2; result:=false; exit; end;

             if not structs_evaluate_rec(valtok,s3,i3,fromstruct,pos)
             then begin res:=s3; result:=false; exit; end;


             if ( ((i1.id<>-1) or (StructHash.ValueOf(s1)<>-1) or (BigArrayHash.ValueOf(s1)<>-1) ) and translateIndexSet(s1,i1.id,s2,s3, res,typ,fromstruct,pos )) then begin
                 result:=true;
                 exit;
             end;

             if (not translateArray(s1,s2,i1.id,s4,i4,fromstruct,pos,true)) then
             begin
                 res:=s4;
                 result:=false; exit;
             end;

             Concatenate4(res,'set ',s4,'=',s3);
   end;

   procedure handleArrayGet(arrtok: TToken;indtok: TToken;var result:boolean);
   begin
        result:=true;
             if not structs_evaluate_rec(arrtok,s1,i1,fromstruct,pos)
             then begin res:=s1; result:=false; exit; end;

             if not structs_evaluate_rec(indtok,s2,i2,fromstruct,pos)
             then begin res:=s2; result:=false; exit; end;

             if (not translateArray(s1,s2,i1.id,res,typ,fromstruct,pos,false,true)) then
             begin
                 result:=false; exit;
             end;
    end;



begin

    if(tok.Kind<>SymbolTypeNonterminal) then begin
        //IT is just a terminal
        if (LocalIDentifierTypes.ValueOf(tok.DataVar)=-1) and  TranslateFunctionName(tok.DataVar,res,typ)  then begin
           result:=true;
           exit;
        end;
        result:=true;
        typ:=TryGetTypeOf(tok.DataVar);
        res:=tok.DataVar;
        exit;
    end;

    red:=tok.Reduction;

    case RuleConstants(Red.ParentRule.TableIndex) of

       RULE_EXPRESSION8_STRINGLITERAL:
       begin
            res:=red.Tokens[0].datavar;
            if(res[1]<>'''') then
                res:=structStringGet(res);
            typ:=MakeType(-1);
            result:=true;
       end;
       RULE_EXPRESSION8_IDENTIFIER:
       begin
           (* <Expression8> ::= Identifier *)
           if(fromstruct<>-1)
             and ( not(jasshelperconfigfile.DISABLE_IMPLICIT_THIS) or StructList[fromstruct].zincstruct )
             and (LocalIDentifierTypes.ValueOf(red.Tokens[0].datavar)=-1)
             and TranslateDotVar('this', red.Tokens[0].DataVar, fromstruct, res,typ,fromstruct,pos,false,'',MakeType(-1),tocall)
           then begin
               result:=true;
               exit;
           end else begin
               result:=structs_evaluate_rec(red.Tokens[0],res,typ,fromstruct,pos);
               exit;
           end;
       end;
       RULE_ASSIGNVAR_SET_IDENTIFIER_EQ:
       begin

           (* <AssignVar> ::= set Identifier = <Expression> *)
           s1 := red.Tokens[1].DataVar;
           if(not structs_evaluate_rec(red.Tokens[3], s2, i2, fromstruct,pos) ) then
           begin;
               res:=s2;
               result:=false;
               exit;
           end;

           if(fromstruct<>-1)
             and ( not(jasshelperconfigfile.DISABLE_IMPLICIT_THIS) or StructList[fromstruct].zincstruct )
             and (LocalIDentifierTypes.ValueOf(s1)=-1)
             and TranslateDotVar('this', s1, fromstruct, res,typ,fromstruct,pos,true,s2,i2,tocall)
           then begin
               if(tocall) then begin
                   res:='call '+res;
               end else begin
                   s3:=res;
                   Concatenate4(res,'set ',s3,'=',s2);
               end;
               typ:=MakeType(-1);
               result:=true;
               exit;
           end else begin
               Concatenate4(res,'set ',s1,'=',s2);
               typ:=MakeType(-1);
               result:=true;
               exit;
           end;


       end;
       RULE_EXPRESSION8_NUMBERLITERAL:
          begin
              s1:=red.Tokens[0].datavar;
              if( (Length(s1)>10) and (s1[1]='0') and (s1[2]='x') ) then begin
                   res:='Hexadecimal literal too big';
                   result:=false;
                   exit;
              end;
              typ:=MakeType(-1);
              res:=s1;
              result:=true;
              exit;
          end;

       RULE_GETMEMBER_DOT_IDENTIFIER:
          begin
             if not structs_evaluate_rec(red.Tokens[0],s1,i1,fromstruct,pos)
             then begin res:=s1; result:=false; exit; end;

             //if not structs_evaluate_rec(red.Tokens[2],s2,i2,fromstruct,pos)
             //then begin res:=s2; result:=false; exit; end;
            s2:=structs_evaluate_terminal(red.Tokens[2]); //Reduction.tokens[0].datavar  ;
             //MessageBox(0,pchar(s2),pchar(s2),0);
             result:=false;
             try
                 if ( translateDotVar(structs_evaluate_terminal(red.Tokens[0]),s2,-1,res,typ,fromstruct,pos,false,'',MakeType(0),unused)) then
                 begin
                      result:=true; exit;
                 end;
             finally
             end;

             if (not translateDotVar(s1,s2,i1.id,i1,res,typ,fromstruct,pos,false,'',MakeType(0),unused)) then
             begin
                  result:=false; exit;
             end;
          end;

       RULE_ASSIGNMEMBER_SET_DOT_IDENTIFIER_EQ:
       //set somethind.var = something
       begin


             if not structs_evaluate_rec(red.Tokens[1],s1,i1,fromstruct,pos)
             then begin res:=s1; result:=false; exit; end;

             //if not structs_evaluate_rec(red.Tokens[3],s2,i2,fromstruct,pos)
             //then begin res:=s2; result:=false; exit; end;
             s2:=structs_evaluate_terminal(red.Tokens[3])  ;

             if not structs_evaluate_rec(red.Tokens[5],s4,i4,fromstruct,pos)
             then begin res:=s4; result:=false; exit; end;

             tocall:=false;
             if (not translateDotVar(s1,s2,i1.id,s3,typ,fromstruct,pos,true,s4,i4,tocall)) then
             begin
                 res:=s3;
                 result:=false; exit;
             end;

             if(typ.id=METHODTYPE) then begin
                 res:='Hmnn, you are not supposed to assign values to methods...';
                 result:=false;
                 exit;
             end;

             if( typ.id >= ARRAYEDTYPE ) then begin
                  res:='You cannot directly assign a static array member...';
                  result:=false; exit;
             end;

             if ((typ.id<>-1) and StructList[typ.id].forInternalUse) then begin
                 res:='Cannot assign to : '+StructList[typ.id].name;
                 result:=false; exit;
             end;


             if(tocall) then begin
                 res:='call '+s3;
             end else if CompareSubString(s3,1,4,'set ') then begin
                 res:=s3;
             end else begin
                 Concatenate4(res,'set ',s3,'=',s4);
             end;



       end;

       RULE_NOTHINGMETHOD_DOT_IDENTIFIER_LPARAN_RPARAN:
       // something.method()
       begin
             if not structs_evaluate_rec(red.Tokens[0],s1,i1,fromstruct,pos)
             then begin res:=s1; result:=false; exit; end;

             s2:=red.Tokens[2].DataVar;


             if {(red.TokenCount>1) or} (not translateDotMethod(structs_evaluate_terminal(red.Tokens[0]),s2,'',MakeType(-1),res,typ,fromstruct,pos)) then
             begin
                  if (not translateDotMethod(s1,s2,'',i1,res,typ,fromstruct,pos)) then
                  begin
                      result:=false; exit;
                  end;
             end;

       end;
       RULE_ARGMETHOD_DOT_IDENTIFIER_LPARAN_RPARAN:
       begin
       //something.method(args)
             if not structs_evaluate_rec(red.Tokens[0],s1,i1,fromstruct,pos)
             then begin res:=s1; result:=false; exit; end;

             s2:=red.Tokens[2].DataVar;

             if not structs_evaluate_rec(red.Tokens[4],s3,i3,fromstruct,pos)
             then begin res:=s3; result:=false; exit; end;

             if {(red.TokenCount>1) or} (not translateDotMethod(structs_evaluate_terminal(red.Tokens[0]) ,s2,s3,MakeType(-1),res,typ,fromstruct,pos)) then
             begin
             //res:='{'+res+'}'+red.Tokens[0].DataVar;
              //             exit;
                 if (not translateDotMethod(s1,s2,s3,i1,res,typ,fromstruct,pos)) then
                 begin
                      result:=false; exit;
                 end;

             end;

       end;


       RULE_NOTHINGFUNCTION_IDENTIFIER_LPARAN_RPARAN: (* <NothingFunction> ::= Identifier ( ) *)
       // functionname ( )
       begin
           s1:=red.Tokens[0].DataVar;
           typ:=MakeType(StructHash.valueOf(s1));
           if(typ.id<>-1) then //typecast attempt, but gave no arguments...
           begin res:='Expected argument for typecast operator'; result:=false; exit; end;


           typ:=MakeType( HookedNativeHash.ValueOf(s1) );
           if(typ.id<>-1) then begin
              //doubtful a native returns a struct type...
              typ:=MakeType(-1);
              res:='h__'+s1+'()';
              result:=true;
              exit;
           end;


           if  (fromstruct<>-1)
             and ( not(jasshelperconfigfile.DISABLE_IMPLICIT_THIS) or StructList[fromstruct].zincstruct )
             and TranslateDotMethod('this',s1,'',MakeType(fromstruct),res,typ,fromstruct,pos)
           then begin
               result:=true;
               exit;
           end;


           typ:=TryGetTypeOf(red.Tokens[0].datavar);
           res:=red.Tokens[0].datavar+'()';




       end;

       RULE_ARGFUNCTION_IDENTIFIER_LPARAN_RPARAN:
       // functionname ( args )
       begin
           if not structs_evaluate_rec(red.Tokens[2],s1,i1,fromstruct,pos)
               then begin res:=s1; result:=false; exit; end;

           if(red.Tokens[0].DataVar='integer') then //to integer typecast operator
           begin
               if (i1.id=-1) then  begin res:='Invalid typecast'; result:=false; exit; end;
               typ:=MakeType(-1);
               Concatenate3(res,'(',s1,')'); Result:=true; exit;
           end;

           typ:=MakeType( StructHash.valueOf(red.Tokens[0].DataVar) );
           if(typ.id<>-1) then //typecast operator!
           begin
               Concatenate3(res,'(',s1,')');
           end else begin
               typ:=MakeType(HookedNativeHash.ValueOf(red.Tokens[0].DataVar) );
               if(typ.id<>-1) then begin
                   if not structs_evaluate_JassLibArguments( THookedNative(HookedNatives[typ.id]).nativename    , red.Tokens[2],s1,i1,fromstruct,pos)
                       then begin res:=s1; result:=false; exit; end;


                   Concatenate4(res,'h__'+red.Tokens[0].datavar,'(',s1,')');
                   //doubtful a native returns a struct type...
                   typ.id:=-1;
               end else begin
                   s3 := red.Tokens[0].DataVar;
                   if  (fromstruct<>-1)
                     and TranslateDotMethod('this',s3,s1,MakeType(fromstruct),res,typ,fromstruct,pos)
                     and ( not(jasshelperconfigfile.DISABLE_IMPLICIT_THIS) or StructList[fromstruct].zincstruct )
                   then begin
                      result:=true;
                   end else begin
                       if(JassLib.VerifyJassFunc(s3, tmfunc) ) then begin
                           if not structs_evaluate_JassLibArguments( s3, red.Tokens[2],s1,i1,fromstruct,pos)
                              then begin res:=s1; result:=false; exit; end;
                       end;
                       Concatenate4(res,red.Tokens[0].datavar,'(',s1,')');
                       typ:=TryGetTypeOf(red.Tokens[0].datavar);
                   end;
               end;
           end;

       end;

       RULE_EQUALTO_EQEQ:
       (* <EqualTo> ::= <Expression3> == <Expression3> *)
       begin
             if not structs_evaluate_rec(red.Tokens[0],s1,i1,fromstruct,pos)
             then begin res:=s1; result:=false; exit; end;

             if not structs_evaluate_rec(red.Tokens[2],s2,i2,fromstruct,pos)
             then begin res:=s2; result:=false; exit; end;


             if (  ((i1.id<>-1) and (i2.id<>-1)) and (  s1<>'0') and (  s2<>'0') ) then begin
                 Result:=TranslateEqualTo(s1,i1.id,s2,i2.id, res,fromstruct,pos , false);
             end else begin
                 Result:=true;
                 res:= s1+' == '+s2;
             end;
             typ:=MakeType(-1); //type is boolean...
             exit;

       end;
       RULE_NOTEQUALTO_EXCLAMEQ:
       (* <NotEqualTo> ::= <Expression3> != <Expression3> *)
       begin
             if not structs_evaluate_rec(red.Tokens[0],s1,i1,fromstruct,pos)
             then begin res:=s1; result:=false; exit; end;

             if not structs_evaluate_rec(red.Tokens[2],s2,i2,fromstruct,pos)
             then begin res:=s2; result:=false; exit; end;

             if (  ((i1.id<>-1) and (i2.id<>-1)) and (  s1<>'0') and (  s2<>'0') ) then begin
                 Result:=TranslateEqualTo(s1,i1.id,s2,i2.id, res,fromstruct,pos , true);
             end else begin
                 Result:=true;
                 res:= s1+' != '+s2;
             end;
             typ:=MakeType(-1); //type is boolean...
             exit;

       end;

       RULE_LESSTHAN_LT:
       (* <LessThan> ::= <Expression4> < <Expression4> *)
       begin
             if not structs_evaluate_rec(red.Tokens[0],s1,i1,fromstruct,pos)
             then begin res:=s1; result:=false; exit; end;

             if not structs_evaluate_rec(red.Tokens[2],s2,i2,fromstruct,pos)
             then begin res:=s2; result:=false; exit; end;


             if (  ((i1.id<>-1) or (i2.id<>-1)) and (  s1<>'0') and (  s2<>'0') ) then begin
                 Result:=TranslateLessThan(s1,i1.id,s2,i2.id, res,fromstruct,pos );
             end else begin
                 Result:=true;
                 res:= s1+' < '+s2;
             end;
             typ:=MakeType(-1); //type is boolean...
             exit;

       end;

       RULE_GREATERTHAN_GT:
       (* <GreaterThan> ::= <Expression4> > <Expression4> *)

       begin
             if not structs_evaluate_rec(red.Tokens[0],s1,i1,fromstruct,pos)
             then begin res:=s1; result:=false; exit; end;

             if not structs_evaluate_rec(red.Tokens[2],s2,i2,fromstruct,pos)
             then begin res:=s2; result:=false; exit; end;


             if (  ((i1.id<>-1) or (i2.id<>-1)) and (  s1<>'0') and (  s2<>'0') ) then begin
                 Result:=TranslateLessThan(s2,i2.id,s1,i1.id, res,fromstruct,pos );
             end else begin
                 Result:=true;
                 res:= s1+' > '+s2;
             end;
             typ:=MakeType(-1); //type is boolean...
             exit;
       end;


       RULE_ASSIGNARRAY_SET_LBRACKET_RBRACKET_EQ:
       //set something[something]=something
       begin
           HandleArraySet(red.Tokens[1],red.Tokens[3],red.Tokens[6], result);
           exit;
       end;

       RULE_GETARRAY_LBRACKET_RBRACKET:
       //something[something]
       begin
            HandleArrayGet(red.Tokens[0], red.Tokens[2], result);
            exit;
       end;

       RULE_ASSIGNARRAYSUF_SET_COLON_IDENTIFIER_EQ:
       // set something:something =something
       begin
           HandleArraySet(red.Tokens[3],red.Tokens[1],red.Tokens[5], result);
           exit;
       end;

       RULE_GETARRAYSUF_COLON_IDENTIFIER:
       // something:something
       begin
            HandleArrayGet(red.Tokens[2], red.Tokens[0], result);
            exit;
       end;

       RULE_CODEVALUE_FUNCTION_IDENTIFIER :
       // function functionname
       begin
           Result:=true;
           res:='function '+red.Tokens[1].DataVar;
           typ:=MakeType(-1,'code');
       end;

       RULE_MEMBERCODEVALUE_FUNCTION_IDENTIFIER_DOT_IDENTIFIER:
       // function class.method
       begin
           Result:= translateMethodCode( red.Tokens[1].datavar, red.Tokens[3].datavar, res,fromstruct,pos);
           typ:=MakeType(-1,'code');
           Exit;
       end;

       RULE_ADDITION_PLUS:
       (* <Addition> ::= <Expression5> + <Expression4> *)
       begin
             if not structs_evaluate_rec(red.Tokens[0],s1,i1,fromstruct,pos)
             then begin res:=s1; result:=false; exit; end;

             if not structs_evaluate_rec(red.Tokens[2],s2,i2,fromstruct,pos)
             then begin res:=s2; result:=false; exit; end;


             if ( (Length(s1)>=2) and (Length(s2)>=2) and (s1[1]='"')and (s2[1]='"')
              and (s1[Length(s1)]='"')and (s2[Length(s2)]='"') ) then begin
                 Result:=true;
                 res:=Copy(s1,1,Length(s1)-1)+Copy(s2,2,Length(s2)-1);
             end else begin
                 Result:=true;
                 res:= s1+' + '+s2;
             end;
             typ:=MakeType(-1); //type is a native one...
             Exit;

       end;

       RULE_CALL_CALL: //call function([args])
       begin
            red:=red.Tokens[1].Reduction;
            if (RuleConstants(red.ParentRule.TableIndex)=RULE_FUNCTION) then begin
{                //weee ( )
                if not structs_evaluate_rec(red.Tokens[0],s1,i1,fromstruct,pos)
                then begin res:=s1; result:=false; exit; end;
}
                s1:=red.Tokens[0].Reduction.Tokens[0].DataVar;


                if CompareSubString(s1,1,9,'InitTrig_') then begin
                    if(FunctionHash.ValueOf(s1)=-1) then begin
                        Concatenate3(res,'//Function not found: call ',s1,'()');
                        Result:=true;
                        exit;
                    end;
                end;


            end;
            red:=tok.Reduction;
            if not structs_evaluate_rec(red.Tokens[1],s1,i1,fromstruct,pos)
            then begin res:=s1; result:=false; exit; end;
            Result:=true;
            res:='call '+s1;
            exit;

       end;

       else //rules that just stay the way they are,
       begin


           res:='';
           if(Length(stevrecd)<red.TokenCount) then SetLength(stevrecd,red.TokenCount+2);
           for i := 0 to red.TokenCount - 1 do begin
               if(i=0) then begin
                   if(not structs_evaluate_rec(red.Tokens[i],res,typ,fromstruct,pos)) then begin
                       result:=false; exit;
                   end;
               end else begin
                   if(not structs_evaluate_rec(red.Tokens[i],res,i2,fromstruct,pos)) then begin
                       result:=false; exit;
                   end;
               end;
               //MessageBox(0,pchar(res),'!',0);
               stevrecd[i]:=res
           end;
           {stevrecd[0]:='a';
           stevrecd[1]:='b';
           stevrecd[2]:='c';}

           ConcatenateManySep(res,stevrecd, red.TokenCount,' ');
           if(red.TokenCount=0) then
               typ:=MakeType(-1);
//           res:='abc';
       end;
    end;

 Result:=true;
end;

//if it is a correct code chunk, returns true and reevaluated version is in res.
//otherwise, returns false and error is in res.
function structs_evaluatecode({const} s:string; var res:string;   fromstruct:integer; const pos:integer; const insetstatement:boolean=false):boolean;
 var done:boolean;
     Response:Integer;
     whitespace,tmres:string;
     tm,i,L:integer;
     tmt:Tvtype;
begin
    RecCurrentLine:=pos;
    //done:=false;
    {i:=1;}L:=Length(s);
    {while( (not done) and (i<=L)) do begin
        done:= done or (s[i]='.') or (s[i]='[') or (s[i]='(') ;
        i:=i+1;
    end;
    if(not done) then begin res:=s; result:=true; exit; end;}



    i:=1;
    while (i<=L) and ((s[i]=' ') or (s[i]=#9)) do i:=i+1;
    whitespace:=Copy(s,1,i-1);

    if not preprocessStructStrings(s) then begin
       raise  JasserLineException(pos,'[Internal error] please have less than '+IntToStR(STRUCT_STRING_LIMIT+1)+' string literals in a line.');
    end;

    if (not Parser.OpenTextString(s)) then raise JasserLineException(pos,'Unknown internal error 1');

    Done := False;
    while not Done do
    begin
            Response := Parser.Parse;
            case Response of
                gpMsgLexicalError:
                begin
                     res:='Unexpected : '+Parser.CurrentToken.DataVar;result:=false;exit;
                end;
                gpMsgSyntaxError: begin
                    if(Parser.CurrentToken.Datavar = '') then
                        res:='Syntax Error, unexpected: end of line?'
                    else
                        res:='Syntax Error, unexpected: "'+Parser.CurrentToken.Datavar+'"?';
                    result:=false;
                    exit;
                end;

                gpMsgAccept:
                    Done := True;
                gpMsgInternalError:  begin res:='Internal Parser Error';result:=false;exit; end;

                gpMsgNotLoadedError: begin res:='Parser Not Loaded Error';result:=false;exit; end;
                gpMsgCommentError: begin res:='Syntax Error, unexpected end of line';result:=false;exit; end;
            end;
    end;


    //Hehem parsed correctly!!! Now we *just* have to translate the reductions
    Result:=structs_evaluate_rec(parser.CurrentReduction.Tokens[0],tmres,tmt,   fromstruct,pos);
    res:=tmres;
    if(not Result) then
        exit;
    if (parser.CurrentReduction.TokenCount>1) then begin
       ConcateNate4(res,whitespace,tmres,' ',parser.CurrentReduction.Tokens[1].DataVar); //comment
    end else begin
       res:=whitespace+tmres;
    end;

end;




//if it is a correct local declaration, returns true and reevaluated version is in res.
//otherwise, returns false and error is in res.
function structs_evaluatelocal(const s:string; var res:string;  fromstruct:integer; const pos:integer):boolean;
var
   x,h,i:integer;
   typen,name,assign,tem,indent:string;
   arr:boolean;
begin

    if(not CompareLineWord('local',s,x)) then begin
        res:='Not a local syntax?';Result:=false;Exit;
    end;
    i:=x-6;
    SetLength(indent,i);
    while(i>0) do begin
         indent[i]:=' ';
         i:=i-1;
    end;

    GetLineWord(s,typen,x,x);
    if (typen='') then begin
        res:='Expected a type';Result:=false;Exit;
    end;
    h:=StructHash.ValueOf(typen);
    GetLineToken(s,name,x,x);

    arr:=(name='array');
    if(arr) then begin
        GetLineToken(s,name,x,x);
    end;
    if (name='') then begin
        res:='Expected a name';Result:=false;Exit;
    end;
    if ( not ValidIdentifierName(name)) then begin
        res:='Invalid name: "'+name+'"';Result:=false;Exit;
    end;

    if(GetAssigment(s,tem,x) and (tem='')) then begin
         res:='Expected an expression.';Result:=false;Exit;
    end;
    if(arr and (tem<>'')) then begin
        res:='Cannot initialize an array';Result:=false;Exit;
    end;

    if(tem<>'') then begin
      if(structs_evaluatecode(tem,assign,fromstruct,pos)) then begin

      end else begin
         res:=assign; result:=false;Exit;
      end;
    end;
    if(tem='') and (not IsWhitespace(s,x)) then begin
         res:='Unexpected: '+Copy(s,x,Length(s)-x+1);
         result:=false;
         exit;
    end;

    VerifyRedeclarationRaise(RecCurrentLine,name);
    if(h<>-1) then begin
        if(arr) then
            LocalIDentifierTypes.Add(name,h+ARRAYEDTYPE)
        else
            LocalIDentifierTypes.Add(name,h);
        if(arr) then
            res :='local integer array '+name
        else if (assign<>'') then
            Concatenate4(res,'local integer ',name,'=',assign)
        else
            res:='local integer '+name;
    end else begin

        LocalIdentifierTypes.Add(name,-2);
        if(arr) then
            Concatenate4(res,'local ',typen,' array ',name)
        else if (assign<>'') then
            Concatenate6(res,'local ',typen,' ',name,'=',assign)
        else
            Concatenate4(res,'local ',typen,' ',name);
    end;
    res:=indent+res;


    Result:=true;



end;

function compareArrays(var A:Tdynamicstringarray; const an:integer; var B:Tdynamicstringarray; const bn:integer):boolean;
var i:integer;
begin
    Result:=true;
    if(an<>bn) then Result:=false
    else begin
        i:=0;
        while(i<an) do begin
            if(A[i]<>B[i]) then begin
                Result:=false;
                exit;
            end;
            i:=i+1;
        end;

    end;

end;

//Actually method globals
procedure generateFuncPassGlobals( var outp:string);
var
   i,j,k,m,c:integer;
   hash:Tstringhash;
   types: array of string;
   dothis:boolean;
   counts: array of integer;

   typ:string;

   memb:Tmember;
   prot:Tfunctionprototype;
   tn:integer;
   checked: array of boolean;


   procedure inichecked(const it:integer);
   var
      x:integer;
   begin
       if(Length(checked)<it) then SetLength(checked,it);
       for x := 0 to it - 1 do checked[x]:=false;

   end;

   procedure addType(const s:string; const sc:integer);
   var
      x:integer;
   begin
       x:=0;
       while(x<tn) do begin
           if(types[x]=s) then break;
           x:=x+1;
       end;
       if(x=tn) then begin
           SetLength(types,x+1);
           SetLength(counts,x+1);
           tn:=tn+1;
           types[x]:=s;
           counts[x]:=0;
       end;
       if(counts[x]<sc) then counts[x]:=sc;
   end;
begin

    hash:=Tstringhash.Create;
    dothis:=false;
    tn:=0;
    for i := 1 to StructN do begin

        //is it an interface with do factory?
        if(StructList[i].isinterface and StructList[i].dofactory) then begin
            //then add a single integer argument
            addtype('integer',1);

            //don't forget the factory trigger:
            Swrite(outp,'trigger st__');
            Swrite(outp,StructList[i].name);
            SWriteLn(outp,'__factory');
        end;

        if(StructList[i].parentname<>'') then dothis:=true;



        for j := 0 to StructList[i].membern-1 do  begin
            memb:=StructList[i].members[j];
            if(memb.name='onDestroy') then dothis:=true;
            if(memb.fromparent) then continue;



            if(memb.abuse) then begin
               if (not StructList[i].isinterface)
                  and (not memb.stub)
                  and ( (StructList[i].parentstruct=-1) or (memb.name<>'onDestroy')   )
                  and ( (StructList[i].gotstructchildren=false) or (memb.name<>'onDestroy') )  then begin

                   Swrite(outp,'trigger st__');
                   Swrite(outp,StructList[i].name);
                   Swrite(outp,'_');
                   SWriteLn(outp,memb.name);

               end;

                dothis:=(dothis or not(memb.isstatic));
                inichecked(memb.argnumber);
                for k := 0 to memb.argnumber- 1 do if(not checked[k]) then begin
                    typ:=memb.argtypes[k];
                    if(structhash.ValueOf(typ)<>-1) then typ:='integer';

                    c:=1;
                    for m := k+1 to memb.argnumber-1 do begin
                        if(memb.argtypes[m]=typ) or( (typ='integer') and (structhash.ValueOf(memb.argtypes[m])<>-1)) then begin
                            c:=c+1;
                            checked[m]:=true;
                        end;
                    end;

                    addType(typ,c);
                end;
            end;

        end;
    end;


    //Do prototypes' globals:
    for i := 1 to PrototypeN do if(Prototype[i].abuse) then begin
        Swrite(outp,'trigger array st___prototype');
        SWriteLn(outp,IntToStr(i));
        prot:=Prototype[i];
        inichecked(prot.argn);
        for k := 0 to prot.argn - 1 do begin
            typ:=prot.args[k];
            if(structhash.ValueOf(typ)<>-1) then typ:='integer';

            c:=1;
            for m := k+1 to prot.argn-1 do begin
                if(prot.args[m]=typ) or ( (typ='integer') and (structhash.ValueOf(prot.args[m])<>-1)) then begin
                    c:=c+1;
                    checked[m]:=true;
                end;
            end;
            addType(typ,c);
        end;

        //prototypes are normalized
        typ:=prot.res;
        if(typ<>'nothing') then begin
            if (hash.ValueOf(typ)=-1) then begin
                 hash.Add(typ,5);
                 Swrite(outp,typ);
                 Swrite(outp,' f__result_');
                 SWriteLn(outp,typ);
            end;
        end;
    end;

    for i := 0 to tn-1 do begin
         for j := 1 to counts[i] do begin
             Swrite(outp,types[i]);
             Swrite(outp,' ');
             Swrite(outp,'f__arg_');
             Swrite(outp,types[i]);
             SWriteLn(outp,IntToStr(j));
         end;

    end;
    if(dothis) then begin
         SWriteLn(outp,'integer f__arg_this');
    end;


    for i := 1 to StructN do begin
       //is it an interface with do factory?
        if(StructList[i].isinterface and StructList[i].dofactory) then begin
            //then add f__result_integer if it wasn't added yet:
            if (hash.ValueOf('integer')=-1) then begin
                 hash.Add('integer',1);
                 SWriteLn(outp,'integer f__result_integer');
            end;


        end;

        j:=0;
        while(j<StructList[i].membern) do begin
            memb:=StructList[i].members[j];
            if(memb.abuse) then begin
             typ:=memb.returntype;
             if( structhash.ValueOf(typ)<>-1) then typ:='integer';
             if(typ<>'nothing') and (hash.ValueOf(typ)=-1) then begin
                 hash.Add(typ,1);
                 Swrite(outp,typ);
                 Swrite(outp,' f__result_');
                 SWriteLn(outp,typ);
             end;
            end;

            j:=j+1;
        end;
    end;
    hash.Destroy;
end;



procedure writechilddefaultinit(var st:tstruct; var parentstruct:tstruct;  var os:string; const debug:boolean; const dodestroy:boolean=false );
var
    s,tem:string;

begin

        s:= st.oninit;

        if((s<>'') or (st.containsarraymembers) ) then begin

            if (st.containsarraymembers) then begin

                Concatenate3(tem,'    if (si__',st.name,'_arrN==0) then');SWriteLn(os,tem);
                Concatenate5(tem,'        set si__',st.name,'_arrI=si__',st.name,'_arrI+1');SWriteLn(os,tem);
                Concatenate3(tem,'        set kthis=si__',st.name,'_arrI');SWriteLn(os,tem);
                Concatenate3(tem,'        if (kthis>',IntToStr(st.maximum),') then');SWriteLn(os,tem);

                if(dodestroy) then begin

                    if(st.requiredspace>=JASS_ARRAY_SIZE) then begin
                        GenerateMultiArrayPicker(RConcatenate3('si__',parentstruct.superparentname,'_'),'type',st.requiredspace, 'this',12,'set ','='+IntToStr(parentstruct.typeid),os);
                    end else begin
                        Concatenate4(tem,'            set si__',parentstruct.superparentname,'_type[this]=',IntToStr(parentstruct.typeid));SWriteLn(os,tem);
                    end;
                    Concatenate3(tem,'            call sc__',parentstruct.superparentname,'_deallocate(this)');SWriteLn(os,tem);
                end else begin
                    if(st.requiredspace>=JASS_ARRAY_SIZE) then begin
                        GenerateMultiArrayPicker(RConcatenate3('si__',parentstruct.name,'_'),'V',st.requiredspace, 'this',12,'set ',RConcatenate3('=si__',parentstruct.name,'_F'),os);
                    end else begin
                        Concatenate5(tem,'            set si__',parentstruct.name,'_V[this]=si__',parentstruct.name,'_F');SWriteLn(os,tem);
                    end;
                    Concatenate3(tem,'            set si__',parentstruct.name,'_F=this');SWriteLn(os,tem);
                end;

                if(debug) then begin
                     SWriteLn(os,'            call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,1000.,"Unable to allocate id for an object of type: '+st.name+'")');
                end;
                SWriteLn(os,     '            return 0');
                SWriteLn(os     ,'        endif');
                SWriteLn(os     ,'    else');
                if(st.requiredspace>=JASS_ARRAY_SIZE) then begin
                    GenerateMultiArrayPicker(RConcatenate3('si__',st.name,'_'),'arrV',st.requiredspace,RConcatenate3('si__',st.name,'_arrN'),8,'set kthis=','',os);
                end else begin
                    Concatenate5(tem,'        set kthis=si__',st.name,'_arrV[si__',st.name,'_arrN]');SWriteLn(os,tem);
                end;
                Concatenate5(tem,'        set si__',st.name,'_arrN=si__',st.name,'_arrN-1');SWriteLn(os,tem);
                SWriteLn(os,     '    endif');

                if(st.requiredspace>=JASS_ARRAY_SIZE) then begin
                    GenerateMultiArrayPicker( RConcatenate3('si__',st.name,'_'),'arr',st.requiredspace,'this',4,'set ','=kthis',os);
                end else begin
                    Concatenate3(tem,'    set si__',st.name,'_arr[this]=kthis');SWriteLn(os,tem);
                end;

            end else SWriteLn(os,'    set kthis=this');

            SWriteLnSmart(os,s);

        end;



end;






function GetLineIndexInt(const s:string;  var ends:integer; sti:integer ):integer;
var
   i,L,o:integer;
   ts:string;
begin
    L:=Length(s);
    i:=sti;
    ends:=sti;
    while (i<=L) and (s[i]<>'[') do begin
        if( s[i]<>' ') and (s[i]<>#9) then begin
            result:=-3; exit;
        end;
        i:=i+1;
    end;
    if(i>L) then begin Result:=-3;exit;end;
    o:=i;
    i:=i+1;

    while (i<=L) and (s[i]<>']') do i:=i+1;
    if(i>L) then begin Result:=-3;exit;end;

    ends:=i+1;

    repeat
       i:=i-1;
    until (s[i]<>' ');

    repeat
       o:=o+1;
    until (s[o]<>' ');

    ts:=Copy(s,o,i-o+1);
    if (not TryStrToInt(ts,Result)) then begin
        Result:=IntegerConstants.ValueOf(ts);
    end
    else if (result<0) then Result:=-2;

end;

procedure GetLineIndexIntCommaInt(const s:string;  sti:integer; var endofindex:integer; var result:integer; var sresult:integer);
var
   i,L,o,j,t, comma:integer;
   ts:string;
begin
    endofindex:=0;
    L:=Length(s);
    i:=sti;
    while (i<=L) and (s[i]<>'[') do i:=i+1;
    if(i>L) then begin Result:=-1;exit;end;
    o:=i;
    i:=i+1;

    while (i<=L) and (s[i]<>']') do i:=i+1;
    if(i>L) then begin Result:=-1;exit;end;
    endofindex:=i+1;

    repeat
       i:=i-1;
    until (s[i]<>' ');

    repeat
       o:=o+1;
    until (s[o]<>' ');

    comma:=-1;
    for j := o to i do begin
        if(s[j]=',') then begin
             if(comma=-1) then comma:=j
             else begin
                 Result:=-1;
                 exit;
             end;
        end;
    end;


    if(comma=-1) then begin
        ts:=Copy(s,o,i-o+1);
        if (not TryStrToInt(ts,Result)) then begin
            Result:=IntegerConstants.ValueOf(ts);
        end
        else if (result<0) then Result:=-2;
        sresult:=-1;
    end else begin
        t:=comma;
        repeat
            t:= t-1;
        until (s[t]<>' ');

        ts:=Copy(s,o,t-o+1);
        if (not TryStrToInt(ts,Result)) then begin
            Result:=IntegerConstants.ValueOf(ts);
        end
        else if (result<0) then Result:=-2;

        if(result>=0) then begin
            t:=comma;
            repeat
                t:=t+1
            until (s[t]<>' ');
            ts:=Copy(s,t,i-t+1);
            if (not TryStrToInt(ts,sResult)) then begin
                sResult:=IntegerConstants.ValueOf(ts);
            end
            else if (sresult<0) then sResult:=-2;
        end;


    end;

end;

//==============================================================================
// Stuff for SLK loading splitting
//
procedure DataFunctions_init; begin
   SetLength(datafunctions,3);
   datafunctions[0]:='';
   datafunctions_N:=0;
   datafunctions_Current:=0;
end;

function DataFunctions_New: boolean; begin
   if(datafunctions_N=0) then begin
       datafunctions_N:=1;
       datafunctions_Current:=1;
       datafunctions[0]:='';
       Result:=true;
       exit;
   end;

   datafunctions_Current:=datafunctions_Current+1;
   Result:=(datafunctions_Current>SLK_LOADSTRUCTS_BATCHSIZE);
   if(Result) then begin
       if(Length(datafunctions)=datafunctions_N) then begin
           SetLength(Datafunctions, datafunctions_N+3+datafunctions_N div 6);
       end;
       datafunctions[datafunctions_N]:='';
       datafunctions_N:=datafunctions_N+1;
       datafunctions_Current:=1;
       Result:=true;
   end;

end;

procedure DataFunctions_Insert(const s:string); begin
   Swrite(Datafunctions[datafunctions_N-1],s);
end;

//==============================================================================
// The structs loader from slk!
//
procedure loadStructs(const s:string;sti:integer; linen:integer);


var a,b,Len,h,k:integer;
var quot,res:boolean;
var path,conc,val:string;
var slk:Tslk;

var structtype:string;
var memb:Tmember;
var struc:Tstruct;
var membtype:array of string;

    procedure readpath;
    begin
            Len:=Length(s);
            a:=sti;
            b:=a;
            while  ((a<=Len) and ((s[a]=' ') or (s[a]=#9))) do a:=a+1;

            if(a>Len) or (a=b) then raise JasserLineException(linen,'Incomplete loaddata command.');
            quot:=(s[a]='"');
            if quot then
                a:=a+1;

            path:='';

            while( (a<=Len) and ((not quot) or (s[a]<>'"') )) do begin
                if (a<Len) and (s[a]='\') and (s[a+1]='\') then begin
                    path:=path+'\';
                    a:=a+1;
                end else path:=path+s[a];
                a:=a+1;
            end;
    end;

    procedure fixInteger(var value:string);
      var isinteger:boolean;
      var i:integer;
    begin
        isinteger:=true;
        for i := 1 to Length(value) do begin
            isinteger:=isinteger and (value[i] in NUMBERS);
        end;
        if(isinteger) then exit;
        if((length(value)=4) or (length(value)=1)) then value:=''''+value+'''';

    end;
    procedure fixBoolean(var value:string);
    begin
        if(value='0') then value:='false'
        else if(value='1') then value:='true';


    end;

    procedure fixString(var value:string);
    begin
        if(Length(value)=0) then value:='""';
        if(value[Length(value)]<>'"') then value:=value+'"';
        if(value[1]<>'"') then value:='"'+value;

    end;

    function isDash(const value:string):boolean;
      var i,L:integer;
    begin
        L:=Length(value);
        i:=1;
        while (L>0) and (value[L]=' ') do L:=L-1;
        while (i<L) and (value[i]=' ') do i:=i+1;
        result := (i=L) and (L>0) and ((value[i]='-') or(value[i]='_')); 
    end;


begin

    slk:=nil;
 try
    readpath;
    if(path='') then raise JasserLineException(linen,'Incomplete loaddata command');
    if(not fetchpath(path)) then begin
        raise JasserLineException(linen,'Unable to find file: '+path);
    end;
    {path holds the file's path}

    //if( isslk(path) ) then begin

       slk:=Tslk.create;
       if(interf<>nil) then begin
           interf.ProStatus('Loading : '+path);
       end;

       try
           res:=slk.LoadFromFile(path);
       except
          on e:exception do begin
              raise JasserLineDoubleException(linen,'Unable to open file: '+path, linen,'---'+e.Message+'');
          end;

       end;

       if not res then begin
           raise JasserLineDoubleException(linen,'Unable to load file: '+path,linen,'---(slk format error/ read error)');
       end;

       //file has been loaded!

       if(slk.LengthX<2) or (slk.LengthY<1) then begin
           raise JasserLineException(linen,'Too few cells in slk: '+path);
       end;

       //Writing the structs data, first of all, 0,0 is the structtype.

       structtype:=slk.contents[0][0];
       h:=Structhash.ValueOf(structtype);
       if(h=-1) then begin
           raise JASSerLineException(linen,'(row 1, column 1) Undeclared struct type: '+structtype);
       end;
       struc:=StructList[h];
       k:=struc.membershash.ValueOf('getFromKey');
       if (k=-1) then begin
           raise JASSerLineDoubleException(linen,'(row 1, column 1) Struct '+structtype+' does not have a getFromKey static method',struc.decl,'---- (struct declaration)' );
       end;

       memb:=struc.members[k];

       if( not(memb.ismethod) or not(memb.isstatic) ) then begin
           raise JASSerLineDoubleException(memb.decl,'getFromKey must be a static method',
                                           linen,    '---- (row 1, column 1) of SLK instanciates '+struc.name+')');
       end;
       if (memb.argnumber<>1) or (memb.returntype='nothing') then begin
           raise JASSerLineDoubleException(memb.decl,'getFromKey must take one argument and a return value',
                                           linen,    '---- (row 1, column 1) of SLK instanciates '+struc.name+')');
       end;


       SetLength(membtype,slk.LengthX);
       membtype[0]:=memb.argtypes[0];
       //verify the fields are ok: , and setup membtype
       for a := 1 to slk.LengthX-1 do begin
           if(slk.contents[a][0]<>'') then begin
               k:=struc.membershash.ValueOf(slk.contents[a][0]);
               if(k=-1) then begin
                   raise JasserLineDoubleException(linen     ,'(row 1, column '+IntToStr(a)+') '+slk.contents[a][0]+' is not a member of',
                                                   struc.decl,'--- '+struc.name+'');
               end;
               memb:=struc.members[k];
               if( memb.ismethod or memb.isstatic) then begin
                   raise JASSerLineDoubleException(memb.decl,slk.contents[a][0]+' is not an instance variable of '+structtype,
                                                  linen,    '---- (row 1, column '+IntToStr(a)+') of SLK uses '+struc.name+'.'+memb.name+')');
               end;
               membtype[a]:=memb.returntype;
           end;
       end;


       for a := 1 to slk.LengthY - 1 do begin
           if(DataFunctions_New() or (a=1)) then begin
              datafunctions_Insert(#13#10'//Loaded from: '+path+#13#10);
           end;


           val:=slk.contents[0][a];
           if(membtype[0]='integer') then fixInteger(val)
           else if(membtype[0]='boolean') then fixBoolean(val)
           else if(membtype[0]='string') then fixString(val);
           Concatenate5(conc,'    set s=s__',structtype,'_getFromKey(',val,')'#13#10);
           datafunctions_Insert(conc);
           for b := 1 to slk.LengthX - 1 do begin

               if(slk.contents[b][a]<>'') and not(isDash(slk.contents[b][a])) and (slk.contents[b][0]<>'') then begin

                    val:=slk.contents[b][a];
                    if(membtype[b]='integer') then fixInteger(val)
                    else if(membtype[b]='boolean') then fixBoolean(val)
                    else if(membtype[b]='string') then fixString(val);
                    Concatenate7(conc,'    set s__',structtype,'_',slk.contents[b][0],'[s]=',val,#13#10);
                    datafunctions_Insert(conc);
               end;
           end;

       end;

    //end;
       if(interf<>nil) then begin
           interf.ProStatus('Structs: Writing...');
       end;

 finally
     if(slk<>nil) then slk.Destroy;
 end;



end;


procedure initParser;
var
  lMemStream : TMemoryStream;
  lResource : Pointer;
  lHandle   : Cardinal;

begin
   if (Parser=nil) then
   begin

         lHandle := FindResource(0, 'VJASSLINEGRAMMAR', RT_RCDATA);
         lResource := LockResource(LoadResource(0, lHandle));
         if lResource = nil then begin

             if (fileexists(GRAMMARPATH)) then begin
                 parser:=TGoldParser.Create;
                 if not Parser.LoadCompiledGrammar(GRAMMARPATH) then raise Exception.Create('Load grammar error');
                 exit;

             end else if (fileExists('jasshelper.cgt')) then begin
                 parser:=TGoldParser.Create;
                 if not Parser.LoadCompiledGrammar('jasshelper.cgt') then raise Exception.Create('Load grammar error');
                 exit;
             end else begin
                 raise Exception.Create('nil Resource and unable to find external cgt file.');;
             end;
         end;
         lMemStream := TMemoryStream.Create;
         try
            lMemStream.WriteBuffer(lResource^, SizeofResource(0, lHandle));
            lMemStream.Position := 0;
            Parser:=TGoldParser.Create;
            if not Parser.LoadCompiledGrammar(lMemStream) then raise Exception.Create('Load grammar error');
         finally
            lMemStream.Free;
         end; // try .. finally
   end
   else
       Parser.Reset;

end;

//==============================================================================
procedure DoStructTopSort;
var n,t,i:integer;
var q:array of integer;
var p:array of integer;
var added:array of boolean;
var reduced:boolean;
var info:string;
begin
    n:=StructN;
    if(n=0) then exit;
    SetLength(TopSortedStructList, n+2);
    SetLength(q, n+2);
    SetLength(p, n+2);
    SetLength(added, n+2);

    for i := 1 to n do begin
        q[i]:=i;
        p[i]:=StructList[i].parentstruct;
        if(p[i]=-1) then p[i]:=StructList[i].parent;
        added[i]:=false;
    end;

    t:=0;
    while (n>0) do begin
        i:=1;
        reduced:=false;

        while (i<=n) do begin
            if ((p[i]=-1) or  added[p[i]]) then begin
                t:=t+1;
                TopSortedStructList[t]:=q[i];
                added[q[i]]:=true;
                q[i]:=q[n];
                p[i]:=p[n];
                n:=n-1;
                reduced:=true;
           end else begin
                i:=i+1;
           end;
        end;
        if(not reduced) then begin
            info:='';
            if(n>5) then  n:=5;
            info:=StructList[q[1]].name;
            for i := 2 to n do info:=info+', '+StructList[q[i]].name;

            raise JasserLineDoubleException(structList[q[1]].decl,'Found an "extends" cycle',structList[q[1]].decl, '\--- Involved structs: '+info);
        end;
    end;
end;

//=====================================================
procedure DoDelegateCycleVerification;
var
    visited:array of boolean;
    finished:array of boolean;
    i:integer;

    procedure dfs(p:integer);
     var j,h:integer;
    begin
        if(visited[p]) then begin
            if(not finished[p]) then
               raise JasserLineException(StructList[p].decl,'Found delegate cycle related with: '+StructList[p].name);
            exit;
        end;
        visited[p]:=true;
        for j := 0 to StructList[p].delegateN-1 do begin
            h:=StructHash.ValueOf(StructList[p].delegates[j].returntype);
            if(h<>-1) then dfs(h);
        end;
        h:=StructList[p].parent;
        if(h<>-1) then dfs(h);
        h:=StructList[p].parentstruct;
        if(h<>-1) then dfs(h);
        finished[p]:=true;

    end;

begin
    SetLength(visited,StructN+1);
    SetLength(finished,StructN+1);
    for i := 1 to StructN do begin
        visited[i]:=false;
        finished[i]:=false;
    end;
    for i := 1 to StructN do if(not visited[i]) then begin
        dfs(i);
    end;



end;

//===========================================================================================================================
procedure CompareStructInterfaceMembers(var st:Tstruct; var stmemb:Tmember; var inter:Tstruct; var itmemb:Tmember);
var tem:string;
begin
    if(stmemb.destruct) or (itmemb.destruct) or (stmemb.construct) or (itmemb.construct)  then exit;

    if(itmemb.ismethod) then begin
       //sure a member with that name 'exists' but is that enough?
       if(not stmemb.ismethod) then begin
           raise JASSerLineDoubleException(st.decl,stmemb.name+' should be a method.',itmemb.decl,'`--- interface declaration here');
       end;

       if(stmemb.returntype<>itmemb.returntype)
           or not(  ((stmemb.name='_lessthan') and ( stmemb.argnumber=1) and (stmemb.argtypes[0]=st.name))
                     or compareArrays(Tdynamicstringarray(stmemb.argtypes),stmemb.argnumber, Tdynamicstringarray(itmemb.argtypes), itmemb.argnumber )
                  )
          or (stmemb.isstatic) then begin
             raise JASSerLineDoubleException(stmemb.decl,stmemb.name+' signatures don''t match.',itmemb.decl,'`--- interface declaration here');
       end;
       stmemb.fromparent:=true;
       stmemb.abuse:=true;

    end else begin
        if(stmemb.ismethod) then raise JASSerLineDoubleException(stmemb.decl,stmemb.name+' already used as member of parent interface.',itmemb.decl,'\--- interface declaration here');
        if(stmemb.returntype <> itmemb.returntype) then  raise JASSerLineDoubleException(stmemb.decl,stmemb.name+' type mismatch with parent interface.',itmemb.decl,'`--- interface declaration here');
        tem:=stmemb.oninit_value;
        st.DropMember(stmemb.name);
        stmemb.oninit_struct:=inter.name;
        stmemb.oninit_value:=tem;
    end;
end;

//==============================================================================
procedure ChildStructMemberCheck(var st:Tstruct);
var
   pids: array of integer;
   pn,pni,k,i:integer;
   memb,mb:Tmember;
   inter:Tstruct;
begin

    SetLength(pids,10);

    if(st.parentstruct=-1) then raise Exception.Create('Error: wrong argument sent to ChildStructMemberCheck');

    k:=st.typeid;
    pn:=0;
    while (StructList[k].parentstruct<>-1) do begin
        if(pn+1>Length(pids)) then SetLength(pids,pn+20);
        k:=StructList[k].parentstruct;

        if(StructList[k].getmember('create',memb) and (memb.access=ACCESS_PRIVATE) ) then begin
            raise JasserLineDoubleException(st.decl,'Unable to extend '+StructList[k].name,memb.decl,'\--- ('+StructList[k].name+' was declared to have a private "create" method)');
        end;

        pids[pn]:=k;
        pn:=pn+1;

    end;
    pni:=pn;
    if(StructList[k].parent<>-1) then begin
        if(pn+1>Length(pids)) then SetLength(pids,pn+20);
        pids[pn]:=StructList[k].parent;
        pni:=pn+1;
    end;

    //check for interface methods...
    if(pni<>pn) then begin
        inter:=StructList[pids[pni-1]];
        for i := 0 to st.membern - 1 do begin
            mb:=st.members[i];

            if (inter.getmember(mb.name,memb)) then begin
                CompareStructInterfaceMembers(st,mb,inter,memb);
            end;

            if (inter.noargumentcreate) and (mb.name='create') and (mb.argnumber<>0) then begin
                raise JasserLineException(mb.decl,'Since '+st.name+' is a child of '+inter.name+' create must be an static method that takes nothing.');
            end;
        end;
    end;

    //check variable redeclaration
    for i := 0 to st.membern - 1 do begin
        mb:=st.members[i];
        if (not mb.ismethod) or ( (not mb.fromparent) and (mb.name<>'onDestroy') and(not mb.construct) and(not mb.destruct) and (mb.name<>'create') and (mb.name<>'destroy')  ) then begin
            for k := 0 to pn - 1 do begin
                if (StructList[pids[k]].getmember(mb.name,memb)) then begin
                    if( memb.stub) then begin
                        mb.fromparent:=true;
                        mb.abuse := true;
                        break;
                    end else if(memb.access=ACCESS_PRIVATE) then break
                    else begin
                        raise JasserLineDoubleException(st.members[i].decl,'Member name already in use by a parent type',memb.decl,'\--- First time used here.');
                    end;
                end;
            end;
        end;
    end;

end;



//===========================================================================
procedure DoCrazyRecursiveTriggerAssign( var iter:Tstruct; var curr: Tstruct; var memb:Tmember; var outs:string);
var
   i,n,k:integer;
   mname:string;
   tem:string;
   tem2:string;
   tememb:Tmember;
begin
    if(not curr.gotstructchildren) and (not curr.isinterface) then Exit;
    if( memb = nil) then mname := 'onDestroy' //default
    else mname := memb.name;
    //if(memb.name='onDestroy') then Exit;

    n:=curr.nchildren;
    for i := 0 to n-1 do begin
        k:=curr.children[i];

        if(StructList[k].getmember(mname,tememb) and ((iter<>curr)           or not iter.isinterface) ) then            continue;
       Concatenate6(tem,'    set st__',iter.name,'_',mname,'[',IntToStr(k));
        Concatenate8(tem2,tem,']=st__',iter.name,'_',mname,'[',IntToStr(curr.typeid),']');
        SWriteLn(outs,tem2);
        DoCrazyRecursiveTriggerAssign(iter,StructList[k],memb,outs);
    end;
end;

//===========================================================================
procedure DoCrazyRecursiveNullTriggerAssign( var iter:Tstruct; var curr: Tstruct; const membname:string; var outs:string);
var
   i,n,k:integer;
   tem:string;
   tememb:Tmember;
begin

    if(not curr.gotstructchildren) and (not curr.isinterface) then Exit;

    //if(memb.name='onDestroy') then Exit;

    n:=curr.nchildren;
    for i := 0 to n-1 do begin
        k:=curr.children[i];
        if(StructList[k].getmember(membname,tememb) or ((membname='onDestroy') and (StructList[k].containsarraymembers) )) then continue;
        Concatenate7(tem,'    set st__',iter.name,'_',membname,'[',IntToStr(k),']=null');
        SWriteLn(outs,tem);
        DoCrazyRecursiveNullTriggerAssign(iter,StructList[k],membname,outs);

    end;


end;


//=========================================================================
procedure WriteFactoryFunction(var st:Tstruct; var outs:string; debug:boolean);
var
 tem:string;
 tmstruct2:Tstruct;
 childs:Array of integer;
 cn,i,c,x,b : integer;
 memb:Tmember;


     //================================
     function gotWeirdAllocate(var ist:Tstruct): boolean;
     var
         par:Tstruct;
         pmemb:Tmember;
     begin
         if(ist.parentstruct=-1) then Result:=false
         else begin
             par:=StructList[ist.parentstruct];
             if(par.customcreate) and par.getmember('create',pmemb)  then begin
                 if (pmemb.argnumber<>0)  then Result:=true
                 else result:=false;
             end else begin
                 result:=gotWeirdAllocate(par);
             end;
         end;

     end;


begin

    cn:=st.nchildren;
    SetLength(childs,cn+10);

    for i := 0 to cn - 1 do childs[i]:=st.children[i];

    i:=0;
    while(i<cn) do begin
        c:=childs[i];
        x:=StructList[c].nchildren;
        if (x>0) then begin
            if(x+cn>Length(childs)) then SetLength(childs,x+cn+20);
            x:=x-1;
            while (x>=0) do begin
                childs[cn]:=StructList[c].children[x];
                cn:=cn+1;
                x:=x-1;
            end;
        end;
        i:=i+1;
    end;

    Concatenate3(tem,#13#10'function sa__',st.name,'__factory takes nothing returns boolean');SWriteLn(outs,tem);

    for c := 0 to cn - 1 do begin
        b:=childs[c];
        tmstruct2:=StructList[b];
        if(c=0) then begin
            Concatenate3(tem,'    if (f__arg_integer1==',IntToStr(b),') then');
        end else begin
            Concatenate3(tem,'    elseif (f__arg_integer1==',IntToStr(b),') then');
        end;
        SWriteLn(outs,tem);

        if(tmstruct2.customcreate) then begin

            tmstruct2.getmember('create',memb);
            if(memb.argnumber=0) then begin //all is fine
                Concatenate3(tem,'        set f__result_integer=s__',tmstruct2.name,'_create()');
                SWriteLn(outs,tem);
            end else if (gotWeirdAllocate(tmstruct2)) then begin
                if(debug) then begin
                    SWriteLn(outs, '        call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,1000.,"Warning: Unable to use allocate()  when trying to create a '+tmstruct2.name+' object using the interface create method.")');
                end;
                SWriteLn(outs,'        set f__result_integer=0');

            end else begin
                //not all is fine...
                if(debug) then begin
                    SWriteLn(outs, '        call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,1000.,"Warning: Forced to use allocate() over .create() when trying to create a '+tmstruct2.name+' object using the interface create method.")');
                end;
                SWriteLn(outs,   '        set f__result_integer=0');
            end;
        end else begin
            if (gotWeirdAllocate(tmstruct2)) then begin
                if(debug) then begin
                    SWriteLn(outs, '        call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,1000.,"Warning: Unable to use allocate()  when trying to create a '+tmstruct2.name+' object using the interface create method.")');
                end;
                SWriteLn(outs,'        set f__result_integer=0');

            end else begin //all is fine
                Concatenate3(tem,'        set f__result_integer=s__',tmstruct2.name,'__allocate()');
                SWriteLn(outs,tem);
            end;

        end;

    end;
    if(debug) then begin
        SWriteLn(outs,'    else');
        SWriteLn(outs, '        call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,1000.,"Unable to allocate id for an object of type: '+st.name+', given a wrong typeid: "+I2S(f__arg_integer1))');
    end;
    SWriteLn(outs,'    endif');
    SWriteLn(outs,'    return true');
    SWriteLn(outs,'endfunction'#13#10);

end;

//===========================================================================
//I was going to make it parse common.j for this but there are issues with that:
//* WEHelper's plugin.pas does not allow me to get a good common.j file.
//* Certain handle types like player are not ref counted.
//
procedure setupBadHandleHash(var badHandleHash:TStringHash);
begin
    badHandleHash:=TStringHash.create();
    badHandleHash.add('event',1);
    badHandleHash.add('widget',1);
    badHandleHash.add('unit',1);
    badHandleHash.add('destructable',1);
    badHandleHash.add('item',1);
    badHandleHash.add('force',1);
    badHandleHash.add('group',1);
    badHandleHash.add('trigger',1);
    badHandleHash.add('triggercondition',1);
    badHandleHash.add('triggeraction',1);
    badHandleHash.add('timer',1);
    badHandleHash.add('location',1);
    badHandleHash.add('region',1);
    badHandleHash.add('rect',1);
    badHandleHash.add('boolexpr',1);
    badHandleHash.add('sound',1);
    badHandleHash.add('conditionfunc',1);
    badHandleHash.add('filterfunc',1);
    badHandleHash.add('unitpool',1);
    badHandleHash.add('itempool',1);
    badHandleHash.add('eventid',1);
    badHandleHash.add('unittype',1);
    badHandleHash.add('camerasetup',1);
    badHandleHash.add('effect',1);
    badHandleHash.add('weathereffect',1);
    badHandleHash.add('terraindeformation',1);
    badHandleHash.add('dialog',1);
    badHandleHash.add('button',1);
    badHandleHash.add('quest',1);
    badHandleHash.add('questitem',1);
    badHandleHash.add('timerdialog',1);
    badHandleHash.add('leaderboard',1);
    badHandleHash.add('multiboard',1);
    badHandleHash.add('multiboarditem',1);
    badHandleHash.add('trackable',1);
    badHandleHash.add('gamecache',1);
    badHandleHash.add('texttag',1);
    badHandleHash.add('lightning',1);
    badHandleHash.add('image',1);
    badHandleHash.add('ubersplat',1);


end;

//=========================================================================
//TODO: make this ignore blizzard.j / common.j function calls.
function DoesLineContainFunctionCalls(const s:string; linenumber:integer):boolean;
var k,L:integer;
tok:string;
func:TJassFunc;
begin
    result:=false;
    if(s='') then begin
        result:=true;
        exit;
    end;
     {if(compareLineToken('call',s,k) ) then
        result:=true
     else begin}
        L:=Length(s);
        k:=1;

        while (k>=1) and (k<=L) do begin
             GetLineToken(s,tok,k,k);
             if( tok = 'function') then result:=true
             else begin
                 //if the next non-whitespace character is (...
                 while (k>=1) and (k<=L) do begin
                      if s[k]='(' then begin
                          if(not jasslib.VerifyJassFunc(tok,func) ) then begin
                              //it is not a native/blizzard.j func, so it is a map func, ban
                              result:=true; exit;
                          end;
                      end;
                      if (s[k] in NONNUMBERSIDENTIFCHAR ) then
                          break;
                      k:=k+1;
                 end;
             end;

        end;


     //end;

end;

//=======================================================================


procedure generateRequiredSizeHash;
var i,h,period,nextperiod,wordend,k,p:integer;
var word,tem:string;

var parents,names:array of string;
var tried: array of boolean;
var sizes: array of integer;

var n:integer;
var hash:TStringHash;

    function dfs(j:integer):integer;
        var par:string;
    begin

        if((sizes[j]=-1) and not tried[j]) then begin
            tried[j]:=true;
            par:=parents[j];
            if(par<>'') then begin
                p:=hash.valueOf(par);
                if (p>=0) and (p<n) then sizes[j]:=dfs(p);
            end;
        end;
        result:=sizes[j];
    end;

begin
  hash:=TStringHash.create;

  try
    nextperiod:=0;
    period:=0;
    if (Interf<>nil) then begin
        Interf.ProStatus('Structs: Parsing');
        Interf.ProMax(ln);
        Interf.ProPosition(0);
        period:=ln div UPDATEVALUE + 1;
        nextperiod:=period;
    end;
    SetLength(names,2);
    SetLength(sizes,2);
    SetLength(parents,2);
    SetLength(tried,2);
    n:=0;

    i:=0;
    try while(i<ln) do begin
        GetLineWord(input[i],word,wordend);
        if(word='struct') or (word='interface') then begin
            if(Length(names)<=n) then begin
                SetLength(names,2*n+2);
                SetLength(parents,2*n+2);
                SetLength(sizes,2*n+2);
                SetLength(tried,2*n+2);
            end;
            GetLineToken(input[i],word,wordend,wordend);
            tried[n]:=false;
            names[n]:=word;
            hash.add(word,n);
            k:=GetLineIndexInt(input[i],wordend,wordend);
            parents[n]:='';
            if(k>=1) then begin
                sizes[n]:=k;
            end else begin
                sizes[n]:=-1;
                if(CompareLineWord('extends',input[i],wordend,wordend)) then begin
                    GetLineWord(input[i],word,wordend,wordend);
                    parents[n]:=word;
                end;
            end;
            n:=n+1;

        end else if(word='globals') then begin
            i:=i+1;
            while(i<ln) and (not CompareLineWord('endglobals',input[i],wordend) )
            do begin
               if(CompareLineWord('constant',input[i],wordend)
                  and CompareLineWord('integer',input[i],wordend,wordend)) then begin
                   GetLineToken(input[i],word,wordend,wordend);
                   h:=-1;
                   if (GetAssigment(input[i], tem, wordend)) then begin
                        GetLineToken(tem,tem,wordend);
                        if TryStrToInt(tem,h) then begin
                            if (h<0) then h:=-2;
                        end else begin
                            h:=IntegerConstants.ValueOf(tem);
                        end;
                        IntegerConstants.Add(word,h);

                    end;

               end;
               i:=i+1;
            end;


        end;
        i:=i+1;
        if(Interf<>nil) then begin
            if(i>=nextperiod) then begin
                nextperiod:=nextperiod+period;
                Interf.ProPosition(i);
            end;
        end;

    end;
    except
       on e:EAccessviolation do begin
           raise JasserLineDoubleException(i,'[Internal Error]',i,e.message);
       end;
    end;

    for i := 0 to n-1 do begin
        sizes[i]:=dfs(i);
        RequiredSizeHash.Add(names[i],sizes[i]);
    end;


  finally
      hash.Destroy;
  end;


end;

//=========================================================================
    procedure generateMultiArrayPickerBatch(const n:integer; namepref:TDynamicStringArray; namesuf:TDynamicStringArray; const indexspace:integer; const index:string; const indent:integer; commandprefix:TDynamicStringArray; commandsufix:TDynamicStringArray; var outs:string; const inioff:integer=0; const iniindex:integer = 1; const continueif:boolean = false);
     var indentstr,tmp,tsuf, tsub:string;
         i,re,k,u:integer;
         newini, newlim:integer;
    begin
//        Writeln('Initial index '+IntToStr(indexspace));
//      if(indent > 40) then raise Exception.Create('OMG');

        SetLength(indentstr,indent); for i:=1 to indent do indentstr[i]:=' ';
        //WriteLn( indentstr + IntTostr(inioff)+' -> '+IntTostr(indexspace));
        re:=(indexSpace-inioff);
        if(re<=0) then raise Exception.Create('Internal error (re<=0) contact vexorian');

        u:=(indexSpace-inioff);
        if(u mod JASS_ARRAY_SIZE <> 0) then u:=u div JASS_ARRAY_SIZE+1
        else u:=u div JASS_ARRAY_SIZE;

        i:=0;
        while((re>=1) and ((i<JASS_ARRAYS_BEFORE_SPLIT) or ( (u-i) <=2 ) {or ((u-i) mod 2 <>0 )} ) ) do begin
            i:=i+1;
            if(indexSpace - iniOff > JASS_ARRAY_SIZE) or(continueif) then begin
                if(re<=JASS_ARRAY_SIZE) then begin
                    SWriteLn(outs,indentstr+'else');
                end else begin
                    if( i=1) and not(continueif) then tsuf := 'if('
                    else tsuf:='elseif(';
                    Concatenate6(tmp,indentstr,tsuf,index,'<',IntToStr(JASS_ARRAY_SIZE*i+inioff),') then');SWriteLn(outs,tmp);
                end;
            end;

            if(JASS_ARRAY_SIZE*(i-1)+inioff > 0) then
                tsub:='-'+IntToStr(JASS_ARRAY_SIZE*(i-1)+inioff)
            else
                tsub:='';

            for k := 0 to n-1 do begin
                if(i+iniindex-1=1) then
                    tsuf:=namesuf[k]
                else
                    tsuf:=IntToStr(i+iniindex-1)+namesuf[k];
                Concatenate10(tmp,indentstr,'    ',commandprefix[k],namepref[k],tsuf,'[',index,tsub,']',commandsufix[k]);SWriteLn(outs,tmp);
            end;
            re:=re-JASS_ARRAY_SIZE;
            if(re<0) then re:=0;
        end;
        //split
        if (re>=1) then begin
            if( i=0) and not (continueif) then tsuf := 'if('
            else          tsuf:='elseif(';

            Concatenate6(tmp,indentstr,tsuf,index,'<',IntToStr(JASS_ARRAY_SIZE*(i+(u-i) div 2)+inioff), ') then');
            SWriteLn(outs,tmp);
            //writeln(indentstr+'#'+IntTostr(i)+' of '+Inttostr(u) );
            newini := inioff + i*JASS_ARRAY_SIZE;
            newlim:= inioff + (i+ (u-i) div 2) * JASS_ARRAY_SIZE;
            generateMultiArrayPickerBatch(n,namepref,namesuf, newlim, index,indent+4,commandprefix,commandsufix,outs, newini, i+iniindex);

            //SWriteLn(outs,indentstr+'else');
            newini := newlim;
            newlim:= indexspace;
            generateMultiArrayPickerBatch(n,namepref,namesuf, newlim, index,indent,commandprefix,commandsufix,outs, newini, i+iniindex+(u-i) div 2 , true);

//            SWriteLn(outs,tmp);

        end;
        if(indexspace - inioff > JASS_ARRAY_SIZE) and not(continueif) then
            SWriteLn(outs,indentstr+'endif');
    end;

//=========================================================================
    var
       array_namepref,array_namesuf,array_commandprefix, array_commandsufix: TDynamicStringArray;
       generateMultiArrayPicker_doinit : boolean = true;

    procedure generateMultiArrayPicker(const namepref:string; const namesuf:string; const indexspace:integer; const index:string; const indent:integer; const commandprefix:string; const commandsufix:string; var outs:string);
    begin

        if(generateMultiArrayPicker_doinit) then begin
            generateMultiArrayPicker_doinit:=false;
            SetLength(array_namepref,1);
            SetLength(array_namesuf,1);
            SetLength(array_commandprefix,1);
            SetLength(array_commandsufix,1);
        end;
        array_namepref[0]:=namepref;
        array_namesuf[0]:=namesuf;
        array_commandprefix[0]:=commandprefix;
        array_commandsufix[0]:=commandsufix;
        generateMultiArrayPickerBatch(1,array_namepref,array_namesuf,indexspace,index,indent,array_commandprefix,array_commandsufix,outs);
    end;

//=========================================================================
    procedure correctArraySize(const lnum:integer; const arsize:integer; const extended:boolean=false);
    begin
        if(arsize=-3) then raise JAsserLineException(lnum,'Expected [size].');
        if(arsize=-1) then raise JAsserLineException(lnum,'Wrong [size] definition.');
        if(arsize<0) then raise JasserLineException(lnum,'Negative array size?');
        if(arsize=0) then raise JasserLineException(lnum,'Zero array size?');
        if(extended) then begin
            if(arsize>VJASS_MAX_ARRAY_INDEXES) then raise JasserLineException(lnum,'Not more than '+IntToStr(VJASS_MAX_ARRAY_INDEXES)+' is supported by vJass.');
        end else begin
            //if(arsize>JASS_ARRAY_SIZE-1) then raise JasserLineException(lnum,'Size breaks internal limits.');
            if(arsize>12000) then raise JasserLineException(lnum,'Size bigger than 12000 considered impractical.');
        end;
    end;

    procedure correctArray2Size(const lnum:integer; const w:integer; const h:integer; const extended:boolean=false);
     var arsize:integer;
    begin
        arsize:=w*h;
        if(extended) then begin
            if(arsize>VJASS_MAX_ARRAY_INDEXES) then raise JasserLineException(lnum,'Not more than '+IntToStr(VJASS_MAX_ARRAY_INDEXES)+' elements are supported by vJass, '+IntToStr(w)+'*'+IntToStr(h)+' is '+IntToStr(arsize));
        end else begin
            if(arsize>JASS_ARRAY_SIZE-1) then raise JasserLineException(lnum,'Size breaks internal limits.');
        end;
    end;


//=========================================================================
procedure addBigArray(const name:string; const typename:string; const size:integer; const line:integer; const width:integer = -1);
var t:integer;
begin
    if(BigArrayHash.ValueOf(name)<>-1) then begin
        raise JasserLineException(line,name+' already declared...' );
    end;
    BigArrayHash.Add(name,BigArrayN);
    if (Length(BigArrayNames)<=BigArrayN) then begin
        t:=BigArrayN+10+(BigArrayN div 5)*2;
        SetLength(BigArrayNames,t);
        SetLength(BigArrayTypes,t);
        SetLength(BigArraySizes,t);
        SetLength(BigArrayWidths,t);
        SetLength(BigArrayStructs,t);
        SetLength(BigArrayDeclLines,t);
    end;
    BigArrayNames[BigArrayN]:=name;
    BigArrayTypes[BigArrayN]:=typename;
    BigArraySizes[BigArrayN]:=size;
    BigArrayWidths[BigArrayN]:=width;
    if(width<>-1) then begin
        t:=StructN+1;
        SetLength(StructList,StructN+2);
        StructList[t]:=Tstruct.create(line,false);
        StructList[t].name:=name+'[]';
        StructList[t].forInternalUse:=true;
        StructList[t].bigArrayId:=BigArrayN;
        BigArrayStructs[BigArrayN]:=t;
        StructN:=t;

    end;
    BigArrayDeclLines[BigArrayN]:=line;
    BigArrayN:=BigArrayN+1;
end;

procedure parseBigArray(var line:string; const p:integer);
var i,x,y,j:integer;
    typename,name:string;
begin
    GetLineWord(line,typename,i);
    if ((typename<>'') and CompareLineWord('array',line,i,i) ) then begin
        GetLineToken(line,name,i,i,);
        if (name='') then raise JasserLineException(p,'Expected a name.');
        if (not ValidIdentifierName(name))  then raise JasserLineException(p,'Invalid variable name: "'+name+'"');

        if(not IsWhiteSpace(line,i)) then begin
            //                     i
            // typename array name ...
            x:=GetLineIndexInt(line,i,i);
            correctArraySize(p,x,true);
            y:=GetLineIndexInt(line,j,i);

            if(y<-2) then begin
                // not there
                VerifyEndOfLine(line,i,p);

                line:='// processed: '+line;
                addBigArray(name,typename,x,p);

            end else begin
                line:='// processed: '+line;
                correctArraySize(p,y,true);
                correctArray2Size(p,x,y,true);
                addBigArray(name,typename,x*y,p,y);
            end;




        end;


    end;
end;

procedure GetStaticMethod(const structname:string; const methodname:string; const decl:integer; out struct:Tstruct; out memb:Tmember);
var
   x:integer;
begin
   x:=StructHash.ValueOf(structname);
   if(x=-1) then
       raise JasserLineException(decl, 'Cannot find struct: '+structname);

   struct:=StructList[x];
   if(not struct.getMember(methodname,memb) ) then
       raise JasserLineDoubleException(decl, 'Cannot find member: '+methodname, struct.decl,'---- In this struct declaration');
   if( not(memb.isstatic) or not(memb.ismethod) ) then
          raise JasserLineDoubleException(decl, 'Expected a static method.', memb.decl,'---- '+memb.name+' is not a static method.');
end;

//////
procedure EvaluateHook(const s:string; const decl:integer);
var
 nativename, structname, funcname:string;
 func:TJassFunc;
 x:integer;
 memb:Tmember;
 struct:Tstruct;
 hook:Thook;

    function dotcheck(const name:string; var first:string; var second:string):boolean;
     var
        i:integer;
    begin
        Result:=false;
        for i := 1 to Length(name) do
            if(name[i]='.') then begin
                Result:=true;
                first := Copy(name,1,i-1);
                second := Copy(name,i+1, Length(name)-i);
            end;


    end;

begin
    CompareLineWord('hook',s,x);
    GetLineWord(s,nativename, x,x);
    if( not ValidIdentifierName(nativename) ) then
        raise JasserLineException(decl,'Syntax error');

    GetLineWord(s,funcname, x,x);
    VerifyEndOfLine(s, x, decl);

    //does the native exist??!
    if( not jasslib.VerifyJassFunc(nativename, func) ) then begin
        raise JasserLineException(decl,'Unable to find native: '+nativename);
    end;

    hook:= Thook.Create;
    if dotCheck(funcname, structname, funcname) then begin
        if( not ValidIdentifierName(funcname) or not(ValidIdentifierName(structname))  ) then
            raise JasserLineException(decl,'Syntax error');
        GetStaticMethod(structname,funcname, decl, struct, memb );
        memb.abuse:=true;
        hook.isMethod:=true;
        hook.memb:=memb;
        hook.struct:=struct;
    end else begin
        structname:='';
        if not ValidIdentifierName(funcname) then
            raise JasserLineException(decl,'Syntax error');
        x := FunctionHash.valueOf(funcname);
        if(x=-1) then
            raise JasserLineException(decl,'Unable to find function : '+funcname);
        FunctionData[x].abuse:=true;
        prototype[FunctionData[x].prototypeid ].abuse:=true;

        hook.isMethod:=false;
        hook.funcid:= x;
        FunctionDataUsed:=true;
    end;
    x:= HookedNativeHash.ValueOf(nativename);
    if(x=-1) then begin
        HookedNatives.Add(THookedNative.create);
        x:= HookedNatives.Count - 1;
        THookedNative(HookedNatives[x]).nativename:=nativename;
        THookedNative(HookedNatives[x]).hooks:= TList.create;
        HookedNativeHash.Add(nativename, x);
    end;
    THookedNative(HookedNatives[x]).hooks.add(hook);







end;

//===============
procedure WriteHooks(var output:string);
var
   i,j,x:integer;
   victim: THookedNative;
   hook:Thook;
   native: TJassFunc;
   tem:string;
   argumentspart : string;
begin
   for i := 0 to HookedNatives.Count - 1 do begin
       victim:=HookedNatives[i];
       Swrite(output,'function h__'+victim.nativename+' takes ');
       jasslib.VerifyJassFunc(victim.nativename,native);
       if ( native.argumentn = 0) then begin
           argumentspart:='';
           Swrite(output,'nothing ');
       end else begin
           argumentspart:='';
           for j := 0 to native.argumentn - 1 do
               if(j+1<native.argumentn) then begin
                   Concatenate4(tem,native.arguments[j],' a',IntToStr(j),', ');
                   Swrite(output, tem);
                   Concatenate3(tem,'a',IntToStr(j),',');
                   Swrite(argumentspart,tem);

               end else begin
                   Concatenate4(tem,native.arguments[j],' a',IntToStr(j),' ');
                   Swrite(output, tem);
                   Swrite(argumentspart,'a'+IntToStr(j));
               end;

       end;
       SWriteLn(output, 'returns '+native.returntype);

       for j := 0 to victim.hooks.Count - 1 do begin
           hook:=Thook(victim.hooks[j]);
           if(hook.isMethod) then begin
               Concatenate4(tem,'    //hook: ',hook.struct.name,'.',hook.memb.name);
               SWriteLn(output,tem);
               Concatenate7(tem,'    call sc__',hook.struct.name,'_',hook.memb.name,'(',argumentspart,')');
           end else begin

               x:=Prototype[functiondata[hook.funcid].prototypeid].GetId(functiondata[hook.funcid].name);
               SWriteLn(output,'    //hook: '+functiondata[hook.funcid].name);

               if(native.argumentn = 0) then
                   Concatenate5(tem,'    call sc___prototype',IntToStr( functiondata[hook.funcid].prototypeid),'_evaluate(',IntToStr(x),')' )
               else
                   Concatenate7(tem,'    call sc___prototype',IntToStr( functiondata[hook.funcid].prototypeid),'_evaluate(',IntToStr(x),',',argumentspart,')');
           end;
           SWriteLn(output,tem);
       end;


       if(native.returntype='nothing') then
           Concatenate5(tem,'call ',native.name,'(',argumentspart,')')
       else
           Concatenate5(tem,'return ',native.name,'(',argumentspart,')');
       SWriteLn(output, tem);
       SWriteLn(output,'endfunction');
   end;
end;

//=========================
function FindOddCharacters(const s:string; const abound:integer=-1):boolean;
var
    bound:integer;
begin
    if(abound=-1) then bound := Length(s)
    else bound:=abound;
    result:=true;
    while(bound>=1) do begin
       if ( s[bound] in SEPARATORS ) and not(s[bound]=' ') and not(s[bound]=#9) then
           exit;
       dec(bound);
    end;
    result:=false;

end;

//=========================================================================
var
   structmagic_time:string;




// Expects a file that has been already processed by JASSHelper
procedure DoJASSerStructMagic(sinput:string;const debug:boolean; var Result:string);overload;
var
i,k,L,eln,siz,wordend,membbigarr,membbigarr2:integer;

h,indent,argnum,priv,currentstruct,reqsize:integer;

word,typen,idn,init,tem,tem2,ind,callstuff,inilines:string;
glob,fun,loc,stat,stub,deleg,arr,consta,ret,useallocforname,propertyoperator:boolean;

newglobals: Array of string;
nativesblock: string;
interfa:boolean;
globalsblock,typ:string;
funcall:string;

newglobalsgl,newglobalsfs: Array of integer;
newglobalsn,j:integer;
tmstruct,tmstruct2,tmstruct3:Tstruct;
period,nextperiod:integer;
//debug:
a,b,c,TS:integer;
memb,memb2:Tmember;

functionLines: Tlist;
nativeLines:Tlist;
hookLines:Tlist;

firstblock:string;
secondblock:string;
execblock:string;
doExec:boolean;

badHandlesUsed, makeMethodCopy:boolean;

//DEBUGFILE:textfile;
{DEBUGSTR:string;
const DEBUGID=2614;}

    procedure addglobal(const s:string;const genline:integer; const fromstruct:integer=-1);
    begin
        if( Length(newglobals)<=newglobalsn) then begin
            SetLength(newglobals,newglobalsn+20);
            SetLength(newglobalsgl,newglobalsn+20);
            SetLength(newglobalsfs,newglobalsn+20);
        end;
        newglobals[newglobalsn]:=s;
        newglobalsgl[newglobalsn]:=genline;
        newglobalsfs[newglobalsn]:=fromstruct;

        newglobalsn:=newglobalsn+1;
    end;

    procedure generateExtraArrays(const typename:string; const pref:string; const suf:string; const indexSpace:integer; const genline:integer);
    var i,re:integer;
        tmp:string;
    begin
        if (JASS_ARRAY_SIZE>indexSpace) then Exit;
        i:=2;
        re:=indexSpace-JASS_ARRAY_SIZE+1;
        while(re>=1) do begin
            Concatenate5(tmp,typename,' array ',pref,IntToStr(i),suf);
            addglobal(tmp,genline);
            i:=i+1;
            re:=re-JASS_ARRAY_SIZE;
        end;

    end;



    //A good model of correct coding would be making parsetype; call this function.
    //But as you may see later, this whole structs function is totally non-correct coding...
    procedure addArrayType(const name:string; const typ:string; const arsize:integer; const arlimit:integer);
     var
        arstruct:Tstruct;
        artem:string;

    begin
        SetLength(StructList,StructN+2);
        arstruct:=Tstruct.create(i,false);
        arstruct.name:=name;
        StructN:=StructN+1;
        if(StructN>JASS_ARRAY_SIZE-1) then begin
            //Give me a break, 8190 classes? I am yet to see a real life serious project with such a quantity and someone would have it in a map? yeah right.
            raise JASSerLineException(i,'Outstanding, the '+IntToStr(JASS_ARRAY_SIZE-1)+' structs limit was reached! Contact vexorian');
        end;
        arstruct.customarray:=arsize;
        arstruct.customarraytype:=typ;
        arstruct.requiredspace:=arlimit;
        arstruct.maximum:=arlimit;

        StructHash.Add(name,StructN);
        StructList[StructN]:=arstruct;
        arstruct.typeid:=StructN;

        //Concatenate3(artem,'integer si__',arstruct.name,'_I=0'); addglobal(artem,i);
        //Concatenate3(artem,'integer si__',arstruct.name,'_N=0'); addglobal(artem,i);
        Concatenate3(artem,typ,' array s__',arstruct.name); addglobal(artem,i, StructN);
        if(arlimit>=JASS_ARRAY_SIZE) then begin
            GenerateExtraArrays(typ,'s__',arstruct.name,arlimit,i);
        end;

        Concatenate4(artem,'constant integer s__',arstruct.name,'_size=',IntToStr(arsize)); addglobal(artem,i, StructN);
        arstruct.addmember(i,'size',ACCESS_PUBLIC,true,false);

        arstruct.forinternaluse:=true;


        //Concatenate3(artem,'integer array si__',arstruct.name,'_V')  ; addglobal(artem,i);
        //Concatenate3(artem,'boolean array si__',arstruct.name,'_active'); addglobal(artem,i);
        //input[i]:='//processed :'+input[i];
    end;

    procedure parsetype;
     var typename:string;
     var arraytype:string;
     var arsize,arlimit:integer;


    begin
        typename:=word;
        GetLineWord(input[i],typename,wordend,wordend);
        if(typename='') then raise JASSerLineException(i,'Expected an struct name');
        if (not validIdentifierName(typename)) then raise JASSerLineException(i,'Invalid name: '+typename);

        VerifyRedeclarationRaise(i,typename);
//        GetLineWord(input[i],word,wordend,wordend);
        if not CompareLineWord('extends',input[i],wordend,wordend)
           then raise JasserLineException(i,'Expected extends');
        GetLineWord(input[i],arraytype,wordend,wordend);
        if(arraytype='') then raise JASSerLineException(i,'Expected a name');
        if (not validIdentifierName(arraytype)) then raise JASSerLineException(i,'Invalid name: '+arraytype);
        if CompareLineToken('array',input[i],wordend,wordend) then begin
            //action!
            SetLength(StructList,StructN+2);
            tmstruct:=Tstruct.create(i,false);
            tmstruct.name:=typename;
            StructN:=StructN+1;
            if(StructN>JASS_ARRAY_SIZE-1) then begin
                //Give me a break, 8190 classes? I am yet to see a real life serious project with such a quantity and someone would have it in a map? yeah right.
                raise JASSerLineException(i,'Outstanding, the '+IntToStr(JASS_ARRAY_SIZE-1)+' structs limit was reached! Contact vexorian');
            end;
            StructHash.Add(typename,StructN);
            StructList[StructN]:=tmstruct;
            tmstruct.typeid:=StructN;
            tmstruct.customarraytype:=arraytype;
            // '    [    ]';

            GetLineIndexIntCommaInt(input[i],wordend,wordend,arsize,arlimit);
            correctArraySize(i,arsize);
            VerifyEndOfLine(input[i],wordend,i);

            if(arlimit>=0) then begin

                if(arlimit>VJASS_MAX_ARRAY_INDEXES) then begin
                    raise JasserLineException(i,'Jass array space used by a single dynamic array is capped to '+IntToStr(VJASS_MAX_ARRAY_INDEXES));
                end;
                tmstruct.requiredspace:=arlimit;
                tmstruct.maximum:=arlimit;

                if (arsize>arlimit div 8) then begin
                  raise JasserLineException(i,'Not enough storage space for more than 8 instances, considered impractical, array size='+IntToStr(arsize)+' , storage limit:'+IntToStr(arlimit));
                end;
            end else if (arsize>JASS_ARRAY_SIZE div 8) then begin
                raise JasserLineException(i,'Not enough storage space for more than 8 instances, considered impractical, array size='+IntToStr(arsize)+' , storage limit:'+IntToStr(JASS_ARRAY_SIZE));
            end;
            tmstruct.customarray:=arsize;
            tmstruct.addmember(-1,'create',ACCESS_PUBLIC,true,true).construct:=true;
            memb:=tmstruct.addmember(-1,'destroy',ACCESS_PUBLIC,false,true);
            memb.destruct:=true;


            //Done parsing Cool, isn't it?
                Concatenate3(tem,'integer si__',tmstruct.name,'_I=0'); addglobal(tem,i, tmstruct.typeid);
                Concatenate3(tem,'integer si__',tmstruct.name,'_F=0'); addglobal(tem,i, tmstruct.typeid);
                Concatenate3(tem,arraytype,' array s__',tmstruct.name); addglobal(tem,i, tmstruct.typeid);
             generateExtraArrays(arraytype,'s__',tmstruct.name,arlimit,i);

            Concatenate4(tem,'constant integer s__',tmstruct.name,'_size=',IntToStr(arsize)); addglobal(tem,i, tmstruct.typeid);
            memb:=tmstruct.addmember(i,'size',ACCESS_PUBLIC,true,false);
            Concatenate3(tem,'integer array si__',tmstruct.name,'_V')  ; addglobal(tem,i, tmstruct.typeid);
            generateExtraArrays('integer',RConcatenate3('si__',tmstruct.name,'_') ,'V',arlimit,i);

            input[i]:='//processed :'+input[i];

        end;

    end;

begin

     initParser;
    structmagic_time:=IntToStr(GetTickCount); //This allows Jasshelper to run twice on a map even if both instances had structs

//Assign(DEBUGFILE,'c:\debug.txt');
//filemode:=fmOpenWrite;
//Rewrite(DEBUGFILE);

    Result:='ERROR';

    period:=0;nextperiod:=0;

    ln:=0;
    k:=1;



    i:=1;L:=Length(sinput);
    eln:=L div 50 + 1; //estimated ln
    SetLength(input,eln);

    if (Interf<>nil) then begin
        Interf.ProMax(L);
        Interf.ProPosition(0);
        Interf.ProStatus('Structs: Loading...');
        period:= L div UPDATEVALUE +1 ;
        nextperiod:=period;
    end;

    datafunctions_Init;


    i:=1;
    while (i<=L) do begin
        if(Interf<>nil) then begin
            if(i>=nextperiod) then begin
                interf.ProPosition(i);
                nextperiod:=i+period;
            end;
        end;
        if (sinput[i]=#10) then begin
            ln:=ln+1;
            if (ln>eln) then begin
                eln:=ln+((L-i) div 25)+1;
                SetLength(input,eln);
            end;
            if ((i>1) and (sinput[i-1]=#13)) then begin
                input[ln-1]:=Copy(sinput,k,i-1-k);
                k:=i+1;
            end else begin
                input[ln-1]:=Copy(sinput,k,i-k);
                k:=i+1;
            end;
        end;

        i:=i+1;

    end;

    if (ln<2) then raise Exception.Create('Input file seems too small / unclosed string issues');

    SetLength(offset,ln);
    SetLength(textmacrotrace,ln);
    for i := 0 to ln - 1 do begin
        offset[i]:=0;
        textmacrotrace[i]:=0;
    end;

    DoStructModuleMagic;
    DoJasserBlocksMagic;




    i:=0;
    StructN:=0;


    HashtableKeys := GetTickCount mod 10 + 1;
    StructHash:=TStringHash.Create;
    RequiredSizeHash:=TStringHash.Create;
    IntegerConstants:=TStringHash.Create;
    IdentifierTypes:=TStringHash.Create;
    LocalIdentifierTypes:=TStringHash.Create;

    setupBadHandleHash(badHandleHash);

    functionLines:=Tlist.create();
    nativeLines:=Tlist.create();
    hookLines := TList.Create();

    hookedNatives := TList.Create();
    hookedNativeHash := TStringHash.create();
    

    BigArrayHash:=Tstringhash.Create();
    BigArrayN:=0;

    InitFunctionPrototypes;
    nativesblock:='';
    SetLength(newglobals,20);
    SetLength(newglobalsgl,20);
    SetLength(newglobalsfs,20);
    newglobalsn:=0;
//    DEBUGSTR:=input[DEBUGID][1];
//    WriteLn(DEBUGFILE,DEBUGSTR);
 try



    //step 1, before anything else parse interfaces and parent structs for [] (max index space operator)
    i:=0;
    generateRequiredSizeHash;

    if (Interf<>nil) then begin
        Interf.ProStatus('Structs: Evaluating');
        Interf.ProMax(ln);
        Interf.ProPosition(0);
        period:=ln div UPDATEVALUE + 1;
        nextperiod:=period;
    end;
    i:=0;


    //step 1.2 Parse the structs themselves and generate globals, replace methods, etc.
    try while(i<ln) do begin

        if (Interf<>nil) then begin
            if(i>=nextperiod) then begin
                Interf.ProPosition(i);
                nextperiod:=i+period;
            end;
        end;


//        WriteLn(DEBUGFILE,input[i]);
        GetLineWord(input[i],word,wordend);
        interfa:=(word='interface');
        if( word='struct') or (interfa) then begin
            GetLineToken(input[i],word,wordend,wordend);
            if(word='') then raise JASSerLineException(i,'Expected an struct name');

            if (not validIdentifierName(word)) then begin
                raise JASSerLineException(i,'Invalid identifier name: '+word);
            end;
            VerifyRedeclarationRaise(i,word);

            SetLength(StructList,StructN+2);
            tmstruct:=Tstruct.create(i,interfa);
            StructN:=StructN+1;
            if(StructN>JASS_ARRAY_SIZE-1) then begin
                //Give me a break, 8190 classes? I am yet to see a real life serious project with such a quantity and someone would have it in a map? yeah right.
                raise JASSerLineException(i,'Outstanding, the '+IntToStr(JASS_ARRAY_SIZE-1)+' structs limit was reached! Contact vexorian');
            end;
            StructHash.Add(word,StructN);
            StructList[StructN]:=tmstruct;
            tmstruct.typeid:=StructN;


            tmstruct.name:=word;

            reqsize:=GetLineIndexInt(input[i],j,wordend);
            if(reqsize<>-3) and (reqsize<0) then raise JasserLineException(i,'Invalid max indexes specifier');
            if(reqsize>=0) then
               wordend:=j;
            GetLineWord(input[i],word, j, wordend);


            if(word='extends') then begin

                if(interfa) then raise JASSerLineException(i,'Interfaces can''t extend');
                if(reqsize>=0) then raise JasserLineException(i,'Cannot use extends on an struct that specifies max indexes');
                GetLineWord(input[i],word,wordend,j);

                if(word='array') then begin
                    tmstruct.makeArrayStruct;
                    if(not IsWhiteSpace(input[i],wordend)) then begin
                        reqsize:=GetLineIndexInt(input[i],wordend,wordend);
                        CorrectArraySize(i,reqsize);
                    end;


                end else begin

                   tmstruct.parentname:=word;
                   tmstruct.parent:=0;
                   reqsize:=RequiredSizeHash.ValueOf(word);

                end;
            end else if(word<>'') then begin
                JasserLineException(i,'Unexpected: '+word);
            end;
            if(reqsize>=0) then begin
                tmstruct.requiredspace:=reqsize;
                tmstruct.maximum:=reqsize;
            end else reqsize:=JASS_ARRAY_SIZE-1;

            VerifyEndOfLine(input[i],wordend,i);

            { integer si_type_I=0
              integer si_type_N=0
              integer array si_type_V=0
            }
            Concatenate4(tem,'constant integer si__',tmstruct.name,'=',IntToStr(tmstruct.typeid)); addglobal(tem,i, tmstruct.typeid);
            if( not tmstruct.isarraystruct) then begin

                if(tmstruct.parent=-1) then begin
                    Concatenate3(tem,'integer si__',tmstruct.name,'_F=0 //MOOOO'); addglobal(tem,i, tmstruct.typeid);
                    Concatenate3(tem,'integer si__',tmstruct.name,'_I=0'); addglobal(tem,i, tmstruct.typeid);
                    Concatenate3(tem,'integer array si__',tmstruct.name,'_V')  ; addglobal(tem,i, tmstruct.typeid);
                    generateExtraArrays('integer',RConcatenate3('si__',tmstruct.name,'_'),'V',reqsize,i);
                end;
            end;

            if(interfa) then begin
                input[i]:='//! ignore';
                Concatenate3(tem,'integer array si__',tmstruct.name,'_type')  ; addglobal(tem,i, tmstruct.typeid);
                generateExtraArrays('integer',RConcatenate3('si__',tmstruct.name,'_'),'type',reqsize,i);
                Concatenate3(tem,'trigger array st__',tmstruct.name,'_onDestroy')  ; addglobal(tem,i, tmstruct.typeid);
            end;



            i:=i+1;
            while(i<ln) do begin
              GetLineWord(input[i],word,wordend);
              indent:=wordend-Length(word)-1;
              if(word='') or ((Length(word)>=2) and (word[1]='/') and (word[2]='/')) then begin
                  if(word='//!') then begin
                      if CompareLineWord('ModuleOnInit',input[i],k,wordend)  then
                      begin
                           GetLineWord(input[i], word, wordend,k);
                           tmstruct.addModuleOnInit(word);
                      end;
                      k:=wordend;
                      if CompareLineWord('pragma',input[i],k,k)
                        and CompareLineWord('implicitthis',input[i],k,k)
                      then
                      begin
                          tmstruct.zincstruct:=true;
                      end;
                  end;

              end else begin
                membbigarr:=-1;
                membbigarr2:=-1;
                if (word='endstruct') then begin
                    if(interfa) then raise JASSerLineException(i,'Unexpected endstruct');
                    break;
                end;
                if (word='endinterface') then begin
                    if(not interfa) then raise JASSerLineException(i,'Unexpected endinterface');
                    input[i]:='//! ignore';
                    break;
                end;

                if(word='struct') or (word='interface') then raise JASSerLineDoubleException(i,'Nested struct declarations are not allowed.',tmstruct.decl,'Inside this block.');
                priv:=ACCESS_PUBLIC;
                if(word='public') then GetLineWord(input[i],word,wordend,wordend)
                else if (word='private') then begin
                    GetLineWord(input[i],word,wordend,wordend);
                    priv:=ACCESS_PRIVATE;
                end else if(word='readonly') then begin
                    priv:=ACCESS_READONLY;
                    GetLineWord(input[i],word,wordend,wordend);
                end;

                stat:=(word='static');
                if stat then begin
                     GetLineWord(input[i],word,wordend,wordend);
                end;
                stub:=(word='stub');
                if stub then begin
                     GetLineWord(input[i],word,wordend,wordend);
                end;

                deleg:=(word='delegate');
                if deleg then begin
                     GetLineWord(input[i],word,wordend,wordend);
                end;


                // public/private static constant
                consta:=(word='constant');
                if consta then begin
                     GetLineWord(input[i],word,wordend,wordend);
                end;

                if(word='constant') or (word='static') or (word='private') or (word='public')  or (word='stub') then
                    raise JASSerLineException(i,'Wrong keyword order (valid is : [public/private] [static/stub] [constant] <type/method> ...)');

                if(word='function') then raise JasserLineException(i,'Unexpected: function');
                if(word='method') then begin

                    if(priv=ACCESS_READONLY) then raise JASSerLineException(i,'Methods cannot be readonly');
                    //A method, omg.
                    if(consta and not stat) then raise JASSerLineException(i,'A constant instance method?');
                    if(deleg) then raise JASSerLineException(i,'Only variable members (not method) can be delegates.');

                    tem:='';



                    GetLineWord(input[i],idn,wordend,wordend);
                    //word holds the name?

                    if(idn='') then raise JASSerLineException(i,'Expected a name');

                    if( interfa and stat ) then begin
                         if (idn<>'create') then
                            raise JASSerLineException(i,'Expected: create');
                         if( not CompareLineWord('takes',input[i],wordend,wordend))  then
                             raise JASSerLineException(i,'Expected: "takes nothing"');
                         if( not CompareLineWord('nothing',input[i],wordend,wordend))  then
                             raise JASSerLineException(i,'Expected: "takes nothing"');

                         VerifyEndOfLine(input[i],wordend,i);

                         tmstruct.noargumentcreate:=true;
                         input[i]:='//! ignore';
                         i:=i+1;
                         continue;
                    end;

                    propertyoperator:=false;
                    if (CompareSubString(idn,1,8,'operator') and ( (Length(idn)=8) or not(idn[9] in IDENTIFCHARS) )  ) then begin
                        GetLineWord(input[i],idn,wordend,wordend-Length(idn)+8);

                        if(ValidIdentifierName(idn)) then begin
                            propertyoperator:=true;
                            h:=tmstruct.membershash.ValueOf(idn);
                            if(h<>-1) then raise JASSerLineException(i,'Member redeclared : '+idn);
                            idn:='_get_'+idn;
                        end else if( Length(idn)>=2) and (idn<>'[]=') and (idn[Length(idn)]='=') and(idn[Length(idn)-1]<>'=') then begin
                            propertyoperator:=true;
                            idn:=Copy(idn,1,Length(idn)-1);
                            if (not ValidIdentifierName(idn)) then raise JasserLineException(i,'Not a valid identifier name for custom assign operator');
                            h:=tmstruct.membershash.ValueOf(idn);
                            if(h<>-1) then raise JASSerLineException(i,'Member redeclared : '+idn);
                            idn:='_set_'+idn;

                        end else if ((idn<>'[]') and (idn<>'[]=') and (idn<>'<') and (idn<>'==') ) then begin
                            raise JasserLineException(i,'Expected "[]","[]=","<","==" or an identifier name');
                        end;

                    end;


                    if not(ValidIdentifierName(idn)) and not propertyoperator then begin

                        if (idn='<') then begin
                            //if (interfa) then raise JASSerLineException(i,'Operator < not supported as interface method yet.');
                            idn:='_lessthan';
                        end
                        else if (idn='[]') then idn:='_getindex'
                        else if (idn='[]=') then idn:='_setindex'
                        else if (idn='==') then idn:='_equalto'
                        else
                            raise JASSerLineException(i,'Not a valid identifier name');
                    end;


                    if ((idn[1]='_') and stat) then begin
                        if(idn='_getindex') then idn:='_staticgetindex'
                        else if(idn='_setindex') then idn:='_staticsetindex'
                        else if( (idn='_lessthan') or (idn='_equalto') ) then raise JasserLineException(i,'< and == are not supported for static operators.');

                    end;

                    h:=tmstruct.membershash.ValueOf(idn);
                    if(h<>-1) then raise JASSerLineException(i,'Member redeclared : '+idn);


                    memb:=tmstruct.addmember(i, idn, priv ,stat,true);

                    if(stub) then begin
                        memb.stub:=true;
                        tmstruct.gotStubMethods:=true;
                        memb.abuse:=true;
                    end;

                    if(idn='onDestroy') then begin
                        if interfa then raise JASSerLineException(i,'Don''t declare onDestroy for an interface');
                        if tmstruct.isarraystruct then raise JASSerLineException(i,'Don''t declare onDestroy for an array struct');

                        tmstruct.ondestroy:=memb;
                        if(tmstruct.parent<>-1) then memb.fromparent:=true;
                        memb.abuse:=true;
                    end;

                    if(idn='onInit') then begin
                        if interfa then raise JASSerLineException(i,'Don''t declare onInit for an interface');
                        if not stat then raise JASSerLineException(i,'onInit must be static');

                        if(tmstruct.parent<>-1) then memb.fromparent:=true;

                    end;


                    if(interfa) then memb.abuse:=true;

                        ind:='';
                        while(indent>0) do begin
                            Swrite(ind,' ');
                            indent:=indent-1;
                        end;
                        if(consta) then
                            Concatenate7(tem,ind,'constant function ','s__',tmstruct.name,'_',idn,' takes ')
                        else
                            Concatenate7(tem,ind,'function ','s__',tmstruct.name,'_',idn,' takes ');

                    //IF it is not static then we have to add 'takes integer this'
                    //method boo takes type name returns something
                    //method boo takes type1 name1, type1 name2 returns something
                    //method boo takes nothing returns something

                    if(not stat) then begin
                        SWrite(tem,tmstruct.name);
                        Swrite(tem,' this');
                        GetLineWord(input[i],word,wordend,wordend);

                      if (interfa and (memb.name='_lessthan')) then begin
                          if (word<>'') then raise JasserLineException(i,'Expected end of line (interface operator < does not need a complete declaration)');
                          memb.returntype:='boolean';
                          memb.addarg(tmstruct.name,'dummy');
                      end else begin
                        if(word<>'takes') then raise JASSerLineException(i,'Expected "takes"');
                        GetLineWordAlsoComma(input[i],typen,wordend,wordend);
                        if(typen='nothing') then begin
                            Swrite(tem,Copy(input[i],wordend,Length(input[i])));
                                GetLineWordAlsoComma(input[i],typen,wordend,wordend);
                                if(typen='returns') then begin
                                    GetLineWord(input[i],memb.returntype,wordend,wordend);
                                end else raise JASSerLineException(i,'Expected returns');

                        end else begin
                            if(tmstruct.ondestroy=memb) then raise JASSerLineException(i,'Wrong onDestroy definition');
                            ind:=tem;
                            Concatenate4(tem,ind,',',typen,Copy(input[i],wordend,Length(input[i])));

                            while(wordend<Length(input[i]))
                            do begin
                                //read name.
                                GetLineWordAlsoComma(input[i],word,wordend,wordend);

                                memb.addarg(typen,word);

                                //read type or returns.
                                GetLineWordAlsoComma(input[i],typen,wordend,wordend);
                                if(typen='returns') then begin
                                    GetLineWord(input[i],memb.returntype,wordend,wordend);
                                    break;
                                end;
                                //repeat

                            end;
                        end;
                      end;


                    end else begin
                        if(tmstruct.ondestroy=memb) then raise JASSerLineException(i,'onDestroy must be an instance method.');
                        if(interfa) then raise JASSerLineException(i,'Interfaces cannot have static methods');
                        if(not comparelineWord('takes',input[i],wordend,wordend)) then raise JASSerLineException(i,'Expected "takes"');
                        Swrite(tem,Copy(input[i],wordend,Length(input[i])));
                        GetLineWord(input[i],typen,wordend,wordend);
                        if(typen<>'nothing') then begin
                            if(memb.name='onInit') then raise JasserLineException(i,'onInit must have no argument list');

                            while(wordend<Length(input[i]))
                            do begin
                                //read name.
                                GetLineWordAlsoComma(input[i],word,wordend,wordend);
                                memb.addarg(typen,word);

                                //read type or returns.
                                GetLineWordAlsoComma(input[i],typen,wordend,wordend);
                                if(typen='returns') then begin
                                    GetLineWord(input[i],memb.returntype,wordend,wordend);
                                    break;
                                end;

                                //repeat
                            end;
                        end else begin
                            GetLineWordAlsoComma(input[i],typen,wordend,wordend);
                            if(typen='returns') then begin
                                GetLineWord(input[i],memb.returntype,wordend,wordend);
                            end else raise JASSerLineException(i,'Expected returns');
                        end;


                    end;

                    if (CompareLineWord('defaults',input[i],wordend,wordend)) then begin
                         if (not interfa) then raise JasserLineException(i,'defaults is only compatible to interface methods');
                         GetLineWord(input[i],word,wordend,wordend);
                         if (word='') then raise JasserLineException(i,'Expected default value or nothing');
                         memb.interdefault:=word;

                         if(( word='nothing') and (memb.returntype<>'nothing')) then raise JasserLineException(i,'Cannot default nothing, method returns '+memb.returntype);
                         if(( word<>'nothing') and (memb.returntype='nothing')) then raise JasserLineException(i,'Only possible default is nothing since method returns nothing');
                    end;


                    //must be strict on operator declarations
                    if (memb.name='_getindex') or (memb.name='_staticgetindex') then begin
                        if (memb.returntype='nothing') then raise JasserLineException(i,'[] operator must have return a value');


                        if (memb.argnumber<>1) then  raise JasserLineException(i,'operator [] requires 1 argument.');

                        if (memb.argnumber<>1) then  raise JasserLineException(i,'operator [] requires 1 argument.');
                    end else if (memb.name='_setindex') or (memb.name='_staticsetindex') then begin
                        if (memb.argnumber<>2) then  raise JasserLineException(i,'operator []= requires 2 arguments.');
                    end else if (memb.name='_lessthan') then begin
                        if ((memb.argnumber<>1) or (memb.argtypes[0]<>tmstruct.name)  )then  raise JasserLineException(i,' operator < requires 1 argument of type: '+tmstruct.name);
                        if (memb.returntype<>'boolean') then  raise JasserLineException(i,'< operator must return a boolean value');
                    end else if (memb.name='_equalto') then begin
                        if ((memb.argnumber<>1) or (memb.argtypes[0]<>tmstruct.name)  )then  raise JasserLineException(i,' operator == requires 1 argument of type: '+tmstruct.name);
                        if (memb.returntype<>'boolean') then  raise JasserLineException(i,'== operator must return a boolean value');
                    end else if( propertyoperator and (Copy(memb.name,1,5) = '_get_') ) then begin
                        if (memb.argnumber<>0) then  raise JasserLineException(i,'Property operator must take nothing.');
                        if( memb.returntype='nothing') then raise JasserLineException(i,'Property operator must have a return type.');
                    end else if( propertyoperator and (Copy(memb.name,1,5) = '_set_') ) then begin
                        if (memb.argnumber<>1) then  raise JasserLineException(i,'Property assignment operator must have exactly one argument.');
                    end else if(memb.name='create') then begin
                        if(not memb.isstatic) then  raise JasserLineException(i,'method create must be static');

                        if( memb.returntype<>tmstruct.name) then raise JasserLineException(i,'method create must return '+tmstruct.name);
                        tmstruct.customcreate:=true;
                    end else if(memb.name='destroy') then begin
                        if( memb.isstatic) then  raise JasserLineException(i,'method destroy must not be static');

                        if( memb.returntype<>'nothing') then raise JasserLineException(i,'method destroy must return nothing');
                        if( memb.argnumber <> 0) then raise JasserLineException(i,'method destroy must have 0 arguments');

                    end;

                    if(tmstruct.ondestroy=memb) and(memb.returntype<>'nothing') then raise JASSerLineException(i,'onDestroy must return nothing');

                    if(interfa) then begin
                        Concatenate4(tem,'trigger array st__',tmstruct.name,'_',memb.name)  ; addglobal(tem,i, tmstruct.typeid);
                        input[i]:='//! ignore'
                    end else begin
                        //skip to endmethod
                        input[i]:=tem;
                        h:=i;
                        //skip to endmethod
                        repeat
                            i:=i+1;
                            if(i=ln) then JASSerLineException(h,'Missing "endmethod"');
                            GetLineWord(input[i],word,wordend);
                            if((word='endfunction') or (word='function') or (word='method')) then raise JASSerLineException(i,'Unexpected "'+word+'"');
                            if(word='endmethod') then break;
                            if(word='endstruct') then raise JASSerLineException(h,'Missing "endmethod"');
                        until false;

                        if(tmstruct.ondestroy=memb) then begin
                            tmstruct.members[tmstruct.membershash.valueOf('deallocate')].decl:=i;
                        end;
                        tem:='';
                        indent:=wordend-10; //'endmethod'
                        while(indent>0) do begin
                            Swrite(tem,' ');
                            indent:=indent-1;
                        end;
                        Swrite(tem,'endfunction');
                        Swrite(tem,Copy(input[i],wordend,Length(input[i])));
                        input[i]:=tem;
                    end;


                end else begin
                    //word holds a type
                    typen:=word;
                    GetLineToken(input[i],idn,wordend,wordend);
                    arr:=(idn='array');
                    if(arr and tmstruct.isarraystruct and not stat) then
                        raise JASSerLineException(i,'Array structs cannot have array members yet, use a dynamic array instead, if necessary.');

                    membbigarr:=-1;
                    membbigarr2:=-1;
                    if(arr) then begin
                        GetLineToken(input[i],idn,wordend,wordend);
                    end;
                    if ( FindOddCharacters(input[i],wordend-1) ) then
                        raise JasserLineException(i, 'Syntax Error');

                    if(idn='') then raise JASSerLineException(i,'Expected a name');

                    if GetAssigment(input[i],init,wordend) then begin
                       if(init='') then raise JASSerLineException(i,'Expected: default value after =');
                    end else init:='';
                    if(init<>'') and not(stat) and tmstruct.isArrayStruct then
                        raise JASSerLineException(i,'Array structs cannot have default values.');

                    h:=tmstruct.membershash.ValueOf(idn);
                    if(h<>-1) then raise JASSerLineException(i,'Member redeclared : '+idn);
                    h:=tmstruct.membershash.ValueOf('_get_'+idn);
                    if(h<>-1) then raise JASSerLineException(i,'Member name already in use by an operator: '+idn);
                    h:=tmstruct.membershash.ValueOf('_set_'+idn);
                    if(h<>-1) then raise JASSerLineException(i,'Member name already in use by an operator: '+idn);




                    siz:=0;
                    if(stat) then begin
                        if(arr) then begin
                            if(consta) then raise JASSerLineException(i,'constant arrays are not supported');
                            if(init<>'') then raise JASSerLineException(i,'Unable to initialize an array.');

                            if(not IsWhiteSpace(input[i],wordend)) then begin
                                membbigarr:=GetLineIndexInt(input[i],wordend,wordend);
                                correctArraySize(i,membbigarr,true);
                                membbigarr2:=GetLineIndexInt(input[i],k,wordend);
                                if(membbigarr2=-3) then membbigarr2:=-1
                                else begin
                                    wordend:=k;
                                    correctArraySize(i,membbigarr2,true);
                                    correctArraySize(i,membbigarr*membbigarr2,true);
                                end;
                                VerifyEndOfLine(input[i],wordend,i);
                            end;


                        end;

                        if (consta and (init='')) then raise JASSerLineException(i,'A constant requires initializing.');

                        if (consta and (typen='integer')) then begin


                           GetLineToken(init,word,k);
                           k:=-1;
                           if TryStrToInt(word,k) then begin
                               if (k<0) then k:=-2;
                           end else begin
                               k:=IntegerConstants.ValueOf(word);
                           end;
                           Concatenate3(tem,tmstruct.name,'.',idn);
                           IntegerConstants.Add(tem,k);
                           IntegerConstants.Add('.'+idn,k);
                        end;

                    end else begin
                        if(consta) then raise JASSerLineException(i,'constant instance members are not supported (Did you want an static variable instead?)');


                        //if(arr) then raise JASSerLineException(i,'array instance variables are not supported');
                        if(arr) then begin
                            tmstruct.containsarraymembers:=true;

                            if(init<>'') then raise JASSerLineException(i,'Unable to initialize an array.');
                            concatenate4(tem,'_',tmstruct.name,'_',idn);
                            siz:=GetLineIndexInt(input[i],wordend,wordend);
                            correctArraySize(i,siz);
                            VerifyEndOfLine(input[i],wordend,i);

                            addArrayType(tem,typen,siz, tmstruct.requiredspace);
                            typen:=tem;

                            if(tmstruct.parent<>-1)then
                                Concatenate7(tem,'    set s__',tmstruct.name,'_',idn,'[this]=(kthis-1)*',IntToStr(siz),#13#10)
                            else begin
                                if(tmstruct.requiredspace>=JASS_ARRAY_SIZE) then begin
                                    tem:='';
                                    GenerateMultiArrayPicker(RConcatenate3('s__',tmstruct.name,'_'),idn,tmstruct.requiredspace,'this',4,'set ','=(this-1)*'+IntToStr(siz),tem);
                                end else
                                    Concatenate7(tem,'    set s__',tmstruct.name,'_',idn,'[this]=(this-1)*',IntToStr(siz),#13#10);
                            end;
                            swrite(tmstruct.oninitv,tem); //let's use oninitv here


                        end;
                    end;
                    if(init='') then  VerifyEndOfLine(input[i], wordend,i);



                    if(stat) then begin
                        if(arr) then
                            concatenate5(tem,typen,' array s__',tmstruct.name,'_',idn)
                        else if(consta) then
                            concatenate8(tem,'constant ',typen,' s__',tmstruct.name,'_',idn,'=',init)
                        else if(init<>'') then
                            concatenate7(tem,typen,' s__',tmstruct.name,'_',idn,'=',init)
                        else
                            concatenate5(tem,typen,' s__',tmstruct.name,'_',idn);
                    end else begin
                        concatenate5(tem,typen,' array s__',tmstruct.name,'_',idn);
                        generateExtraArrays(typen,RConcatenate3('s__',tmstruct.name,'_'),idn,reqsize,i);
                    end;
                    if(membbigarr>-1) then begin
                        concatenate4(tem,'s__',tmstruct.name,'_',idn);
                        if(membbigarr2>-1) then begin
                            addBigArray(tem,typen,membbigarr*membbigarr2,i, membbigarr2);
                        end else begin
                            addBigArray(tem,typen,membbigarr,i);
                        end;
                    end else begin
                        addglobal(tem,i, tmstruct.typeid);
                    end;

                    memb:=tmstruct.addmember(i, idn, priv,stat,false);
                    if(deleg) then tmstruct.addDelegate(memb);
                    memb.arraydummy :=(siz);


                    if(init<>'') and not(stat)  then begin
                        //   set s__structname_membername=inivalue
                        memb.oninit_value:=init;
                        memb.oninit_struct:=tmstruct.name;
                    end;


                    memb.returntype:=typen;

                    if(siz<>0) then begin
                        k:=(tmstruct.requiredspace) div siz-1;
                        if (tmstruct.maximum>k) then tmstruct.maximum:=k;

                        if( (not tmstruct.addedArrayControl) and (tmstruct.parent<>-1)) then begin
                           Concatenate3(tem,'integer si__',tmstruct.name,'_arrI=0'); addglobal(tem,i, tmstruct.typeid);
                           Concatenate3(tem,'integer si__',tmstruct.name,'_arrN=0'); addglobal(tem,i, tmstruct.typeid);
                           Concatenate3(tem,'integer array si__',tmstruct.name,'_arr'); addglobal(tem,i, tmstruct.typeid);
                           if(tmstruct.requiredspace>=JASS_ARRAY_SIZE) then begin
                               GenerateExtraArrays('integer',RConcatenate3('si__',tmstruct.name,'_'),'arr',tmstruct.requiredspace,i);
                           end;
                           Concatenate3(tem,'integer array si__',tmstruct.name,'_arrV')  ; addglobal(tem,i, tmstruct.typeid);
                           if(tmstruct.requiredspace>=JASS_ARRAY_SIZE) then begin
                               GenerateExtraArrays('integer',RConcatenate3('si__',tmstruct.name,'_'),'arrV',tmstruct.requiredspace,i);
                           end;
                           tmstruct.addedArrayControl:=true;
                        end;
                    end;



                    if(arr and stat) then memb.isstaticarray:=true;

                    input[i]:='//! ignore';
                end;

              end;
                i:=i+1;
            end;

            if(tmstruct.membershash.valueof('create')=-1) and not(tmstruct.isArrayStruct) then begin
                memb:=tmstruct.addmember(-1,'create',ACCESS_PUBLIC,true,true);
                memb.construct:=true;
                memb.access:=ACCESS_PUBLIC;
            end;

            if(tmstruct.membershash.valueof('destroy')=-1) and not(tmstruct.isArrayStruct) then begin
                memb:=tmstruct.addmember(-1,'destroy',ACCESS_PUBLIC,false,true);
                memb.destruct:=true;
                memb.access:=ACCESS_PUBLIC;
                tmstruct.getmember('deallocate',memb2);
                if(memb2 <> nil ) then
                     memb.decl:=memb2.decl
                else
                    memb.decl := 0;

            end;


//            if(input[DEBUGID][1]<>DEBUGSTR) then raise JASSerLineException(tmstruct.decl,'Access '+IntToStr(StructN));
            tmstruct.endline:=i;
            if(i=ln) then raise JASSerLineException(tmstruct.decl,'Missing endstruct');


        end
        else if(word='hook') then begin
            hookLines.add(Pointer(i));        
        end else if (word='type') then begin
            parsetype;
        end else if (word='constant') then begin
              GetLineWord(input[i],word,wordend, wordend);
              if( word='function') then
                   functionLines.add(Pointer(i) )
              else if(word='native') then
                   nativeLines.add(Pointer(i));


        end else if(word='function') then begin
              functionLines.add(Pointer(i) );
        end else if (word='native') then begin
              nativeLines.add(Pointer(i));
        end else if (word='globals') then begin
            i:=i+1;

            while (i<ln) do begin
                GetLineWord(input[i],word,wordend);
                if (word='endglobals') then break
                else if ((word='constant') and CompareLineWord('integer',input[i],wordend,wordend)) then begin


                    GetLineToken(input[i],idn,wordend,wordend);
                    h:=-1;
                    if (GetAssigment(input[i], tem, wordend)) then begin
                        GetLineToken(tem,word,wordend);
                        if TryStrToInt(word,h) then begin
                            if (h<0) then h:=-2;
                        end else begin
                            h:=IntegerConstants.ValueOf(word);
                        end;
                        IntegerConstants.Add(idn,h);
                    end;
                end else if(not IsWhitespace(input[i]) ) then parseBigArray(input[i],i);
                i:=i+1;
            end;
            if (i=ln) then raise JasserLineException(i-1,'[Internal error] An step prior structs has generated wrong globals header, report this bug.');





        end;
        i:=i+1;
    end;
    // iterate through the queue and parse the pending function lines
    for i := 0 to functionLines.Count - 1 do
        parseFunction( input[ Integer(functionLines[i]) ],Integer(functionLines[i]) );

    for i := 0 to nativeLines.Count - 1 do begin

        if jasslib.AddNativeLine(input[Integer(nativeLines[i]) ] ) then begin
            SWriteLn(Nativesblock, input[Integer(nativeLines[i]) ]);
        end;
        input[Integer(nativeLines[i]) ]:='';
    end;

    for i := 0 to hookLines.Count - 1 do begin
        EvaluateHook(input[Integer(hookLines[i])], Integer(hookLines[i]));
        input[Integer(hookLines[i]) ]:='//processed hook: '+input[Integer(hookLines[i]) ];
    end;


    except
       on e:EAccessviolation do begin
           raise JasserLineDoubleException(i,'[Internal Error]',i,e.message);
       end;
    end;


    //add arrays corresponding to BigArrays:
    for i := 0 to BigArrayN-1 do begin
        Concatenate3(tem,BigArrayTypes[i],' array s__',BigArrayNames[i]);
        addGlobal(tem,BigArrayDeclLines[i]);

        if(BigArraySizes[i]>JASS_ARRAY_SIZE) then begin
            GenerateExtraArrays(BigArrayTypes[i],'s__',BigArrayNames[i],BigArraySizes[i],BigArrayDeclLines[i] );
        end;

    end;



    //verify extends
    for i := 1 to StructN do begin
        tmstruct:=    StructList[i];
        if (tmstruct.parentname<>'') then begin
            k:=StructHash.ValueOf(tmstruct.parentname);
            if (k=-1) then raise JASSerLineException(tmstruct.decl,'Unable to find the struct/interface '+tmstruct.parentname);

            tmstruct2:=StructList[k];
            if(tmstruct2.isarraystruct) then raise JasserLineException(tmstruct.decl,'Unable to extend an array struct: '+tmstruct2.name);
            if(not tmstruct2.isinterface) then begin
                tmstruct2.addchild(i);
                tmstruct2.gotstructchildren:=true;
                tmstruct.parentstruct:=k;
                tmstruct.parent:=-1;

                if (tmstruct2.getmember('create',memb)) then begin
                     if memb.construct then begin
                         //just allocate...
                     end else begin
                         memb.abuse:=true; //must abuse...
                     end;


                end else raise JASSerLineException(tmstruct.decl,'[internal error] no create method in '+tmstruct.parentname+'?');

            end else begin
                tmstruct2.addchild(i);
                tmstruct.parent:=k;
            end;
        end;
    end;

    //Verify stub methods on final structs
    for i := 1 to StructN do begin
        tmstruct:=    StructList[i];
        if( not(tmstruct.isinterface) and not(tmstruct.gotstructchildren) and (tmstruct.gotStubMethods) ) then begin
            //tmstruct.gotstructchildren:=true;
            tmstruct.gotStubMethods:= false;
            for j := 0 to tmstruct.membern-1 do
                tmstruct.members[j].stub:=false;
        end else if(tmstruct.gotStubMethods) then begin
            for j := 0 to tmstruct.membern-1 do
                if(tmstruct.members[j].stub) then begin
                    Concatenate4(tem,'trigger array st__',tmstruct.name,'_',tmstruct.members[j].name);
                     addglobal(tem,i, tmstruct.typeid);
                end;
        end;

    end;

    //Do a topsort, useful for a later stage and also to detect cycles
    DoStructTopSort;

    //Verify delegate cycles:
    DoDelegateCycleVerification;

    //verify new parents...
    for i := 1 to StructN do begin
        tmstruct:=StructList[i];
        if ( tmstruct.parentname='') and (tmstruct.gotstructchildren) then begin
            Concatenate3(tem,'integer array si__',tmstruct.name,'_type')  ; addglobal(tem,tmstruct.decl, tmstruct.typeid);
            generateExtraArrays('integer',RConcatenate3('si__',tmstruct.name,'_'),'type',tmstruct.requiredspace,tmstruct.decl);
            Concatenate3(tem,'trigger array st__',tmstruct.name,'_onDestroy')  ; addglobal(tem,tmstruct.decl, tmstruct.typeid);
        end;
        if (tmstruct.parentstruct<>-1) then ChildStructMemberCheck(tmstruct);

    end;

    //verify if interfaces are accomplished
    for i := 1 to StructN do begin
        tmstruct:=StructList[i];
        if(tmstruct.isinterface) then begin
            j:=0;
            while(j<tmstruct.nchildren) do begin

                tmstruct2:=StructList[tmstruct.children[j]];
                //is the member present?
                k:=0;
                while(k<tmstruct.membern) do begin

                  if( tmstruct2.getmember(tmstruct.members[k].name,memb) ) then begin
                      compareStructInterfaceMembers(tmstruct2,memb,tmstruct,tmstruct.members[k]);
                  end else if((tmstruct.members[k].ismethod) and (tmstruct.members[k].interdefault='')) then begin
                        raise JASSerLineDoubleException(tmstruct2.decl,'Missing method : '+tmstruct.members[k].name,tmstruct.members[k].decl,'`--- interface declaration here');
                  end;
                  k:=k+1;
                end;

                if (tmstruct.noargumentcreate) and (tmstruct2.getmember('create',memb)) then begin

                    if(memb.argnumber<>0) then raise JasserLineException(memb.decl,'Since '+tmstruct2.name+' is a child of '+tmstruct.name+' create must be an static method that takes nothing.');
                end;


                j:=j+1;
            end;
        end;

    end;


    //this is the most scarry process, involves writing the output
    secondblock:='';
    firstblock:='';
    execblock:='';
    globalsblock:='';
    result:='';

    //Parse members inits:
    for i := 1 to StructN do begin
        tmstruct:=StructList[i];
        k:=0;
        while(k<tmstruct.membern) do begin
            memb:=tmstruct.members[k];
            if (memb.oninit_value<>'') and  (structs_evaluatecode(memb.oninit_value,tem,i,memb.decl)) then begin
                memb.oninit_value:=tem;
            end
            else if (memb.oninit_value<>'') then begin
                raise JasserLineException(memb.decl,tem);
            end;

            k:=k+1;
        end;

    end;


    // * parse and replace struct types in variable and function declarations.
    //     (also consider the globals we added (newglobals[] )
    // * remove struct declarations and leave methods.
    // *

    i:=0;
    glob:=false;
    loc:=false;
    fun:=false;

    if (Interf<>nil) then begin
        Interf.ProStatus('Structs - Writing');
        Interf.ProMax(ln);
        Interf.ProPosition(0);
        period:=ln div UPDATEVALUE + 1;
        nextperiod:=period;
    end;


    h:=-1;
    currentstruct:=-1;
    while(i<ln) do begin
        RecCurrentLine:=i;
        if (Interf<>nil) then begin
            if(i>=nextperiod) then begin
                Interf.ProPosition(i);
                nextperiod:=i+period;
            end;
        end;

        //WriteLn(DEBUGFILE,input[i]);
        GetLineWord(input[i],word,wordend);

         if (glob) then begin

             if (word='') or (CompareSubString(word,1,2,'//')) then begin
                 SWriteLn(globalsblock,input[i]);
             end else if(word='endglobals') then begin
                 SWriteLn(globalsblock, #13#10'//JASSHelper struct globals:');

                 for j := 0 to newglobalsn-1 do begin
                     if (structs_evaluateglobal(newglobals[j],tem, newglobalsfs[j])) then
                         SWriteLn(globalsblock,tem)
                     else
                         raise JASSerLineDoubleException(newglobalsgl[j],tem,newglobalsgl[j],'(At generated code): '+newglobals[j]);
                 end;
                 glob:=false;
                 // SWriteLn(firstblock,input[i]);
             end else if (structs_evaluateglobal(input[i],tem)) then
                     SWriteLn(globalsblock,tem)
                 else
                     raise JASSerLineException(i,tem);

         end else if(word='//!') then begin

             if(input[i]='//! initstructs') then begin
                 if((StructN>0) or FunctionDataUsed) then
                     SWriteLn(secondblock,'call ExecuteFunc("jasshelper__initstructs'+structmagic_time+'")');
   
             end else if(input[i]='//! initdatastructs') then begin
                 if(StructN>0) and (datafunctions_N>0) then begin
                     for j := 0 to datafunctions_N-1 do begin
                         SWriteLn(secondblock,'call ExecuteFunc("jasshelper__'+IntToStr(j)+'initdatastructs'+structmagic_time+'")');
                     end;
                 end;


             end else if (input[i]='//! ignore') then begin
                 //nothing
             end else begin
                 if compareLineWord('loaddata',input[i],wordend,wordend) then begin
                     loadStructs(input[i],wordend,i);
                     input[i]:='//processed command: '+input[i];

                 end;
             end;


         end else if (word='') or (CompareSubString(word,1,2,'//')) then begin

             //comment/empty line, just add.

             SWriteLn(secondblock,input[i]);

         end else if(word='globals') then begin
             if (fun) then raise JASSerLineException(i,'Unexpected globals inside of function');
             if (glob) then raise JASSerLineException(i,'Nested globals');
             glob:=true;
             SWriteLn(globalsblock,input[i]);
         end else if (word='endglobals') then begin
             raise JASSerLineException(i,'Unexpected endglobals');

         end else if (fun) then begin


             if(word='struct') then raise JASSErLineException(i,'Found struct inside function');
             if(word='local') then begin
                 RecCurrentLine:=i;
                 if (structs_evaluatelocal(input[i],tem,currentstruct,i)) then begin
                     input[i]:=tem;
                     SWriteLn(secondblock,tem)
                 end else
                     raise JASSerLineException(i,tem);

                 if(not loc) then raise JASSerLineException(i,'locals are only supported at the top of the function');
             end else begin
                 if(loc) then loc:=false;
                 if(word='endfunction') then begin
                     LocalIdentifierTypes.Clear;
                     fun:=false;
                     SWriteLn(secondblock,input[i]);

                     if(currentstruct<>-1) then begin
                        tmstruct:=StructList[currentstruct];

                         if (tmstruct.parent=-1) and not(tmstruct.gotstructchildren) and (tmstruct.parentstruct=-1) and (tmstruct.ondestroy<>nil) and(not tmstruct.ondestroydone)
                             and (tmstruct.FunctionInterfacePrototype=-1)
                             and (tmstruct.ondestroy.decl<=i)
                             and (not tmstruct.isarraystruct)
                               then begin
                              //write 'normal' destructor
                              swrite(secondblock,#13#10'//Generated destructor of ');
                              SWriteLn(secondblock,tmstruct.name);
                              Concatenate3(tem,'function s__',tmstruct.name,'_deallocate takes integer this returns nothing');
                              SWriteLn(secondblock,tem);
                              SWriteLn(secondblock,'    if this==null then');
                              if(debug) then begin
                                  SWriteLn(secondblock,'        call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,1000.,"Attempt to destroy a null struct of type: '+tmstruct.name+'")');
                              end;
                              SWriteLn(secondblock,'        return');

                              tmstruct2:=nil;
                              Concatenate3(tem,'    elseif (si__',tmstruct.name,'_V[this]!=-1) then');
                              SWriteLn(secondblock,tem);
                              if(debug) then begin
                                  SWriteLn(secondblock,'        call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,1000.,"Double free of type: '+tmstruct.name+'")');
                              end;
                              SWriteLn(secondblock,'        return');
                              SWriteLn(secondblock,'    endif');

                              Concatenate3(tem,'    call s__',tmstruct.name,'_onDestroy(this)');
                              SWriteLn(secondblock,tem);
                              Concatenate5(tem,'    set si__',tmstruct.name,'_V[this]=si__',tmstruct.name,'_F');
                              SWriteLn(secondblock,tem);
                              Concatenate3(tem,'    set si__',tmstruct.name,'_F=this');
                              SWriteLn(secondblock,tem);
                              SWriteLn(secondblock,'endfunction');
                              tmstruct.ondestroydone:=true;
                         end;
                     end;

                 end else if (structs_evaluatecode(input[i],tem,currentstruct,i)) then begin
                     input[i]:=tem;
                     SWriteLn(secondblock,tem)
                 end else
                     raise JASSerLineException(i,tem);


             end;



         end else if (word='constant') or (word='function') then begin
             if (structs_evaluatefunction(input[i],tem)) then begin
                 fun:=true;
                 loc:=true;
                 SWriteLn(secondblock,tem)
             end else if(tem<>'') then begin
                 raise JASSerLineException(i,tem);
             end else raise JASSerLineException(i,'Syntax error in function declaration.');

         end else if (word='struct') then begin
             GetLineToken(input[i],word,wordend,wordend);
             h:=StructHash.ValueOf(word);
             if(h=-1) then begin
                 raise JASSerLineException(i,'Internal Error - unrecognized struct (step 2)');
             end;
             currentstruct:=h;

         end else if(word='endstruct') then begin

             currentstruct:=-1;
             h:=-1;

         end else begin
             //unrecognized, add just in case. could be a preprocessor that is used later
             SWriteLn(secondblock,input[i])
         end;

         i:=i+1;
    end;


    NormalizeFunctionArguments;
    generateFuncPassGlobals(globalsblock);
    inilines:='';



    SWriteLn(secondblock,#13#10'//Struct method generated initializers/callers:');


    // Generate functions for BigArrays that use more than one Jass array.
    if(BigArrayN>0) then begin
        SWriteLn(secondblock,#13#10'//Functions for BigArrays:');
        for i := 0 to BigArrayN-1 do if(BigArraySizes[i]>JASS_ARRAY_SIZE) then begin
            typen:=BigArrayTypes[i];
            if(StructHash.ValueOf(typen)<>-1) then typen:='integer';
            concatenate4(tem,#13#10'function sg__',BigArrayNames[i],'_get takes integer i returns ',typen);
            SWriteLn(firstblock,tem);
            generateMultiArrayPicker('s__',BigArrayNames[i],BigArraySizes[i],'i',4,'return ','',firstblock);
            SWriteLn(firstblock,'endfunction');

            concatenate5(tem,#13#10'function sg__',BigArrayNames[i],'_set takes integer i,',typen,' v returns nothing');
            SWriteLn(firstblock,tem);
            generateMultiArrayPicker('s__',BigArrayNames[i],BigArraySizes[i],'i',4,'set ','=v',firstblock);
            SWriteLn(firstblock,'endfunction');
        end;

    end;


    //Generate functions for structs/dynamic arrays that use more than one Jass arrays.
    for TS := 1 to StructN do begin
        i:=TopSortedStructList[TS];
        tmstruct:=StructList[i];

        if (tmstruct.customarray>0) and (tmstruct.requiredspace>=JASS_ARRAY_SIZE) then begin
            typen:=tmstruct.customarraytype;
            if(StructHash.ValueOf(typen)<>-1) then typen:='integer';
            concatenate4(tem,#13#10'function sg__',tmstruct.name,'_get takes integer i returns ',typen);
            SWriteLn(firstblock,tem);
            generateMultiArrayPicker('s__',tmstruct.name,tmstruct.requiredspace,'i',4,'return ','',firstblock);
            SWriteLn(firstblock,'endfunction');

            concatenate5(tem,#13#10'function sg__',tmstruct.name,'_set takes integer i,',typen,' v returns nothing');
            SWriteLn(firstblock,tem);
            generateMultiArrayPicker('s__',tmstruct.name,tmstruct.requiredspace,'i',4,'set ','=v',firstblock);
            SWriteLn(firstblock,'endfunction');
        end;

        if( (tmstruct.customarray<=0) and (tmstruct.requiredspace>=JASS_ARRAY_SIZE) ) then begin
            for j := 0 to tmstruct.membern-1 do if(not tmstruct.members[j].ignore) and (not tmstruct.members[j].ismethod) and (not tmstruct.members[j].isstatic) then begin
                memb:=tmstruct.members[j];
                typen:=tmstruct.members[j].returntype;
                if(StructHash.ValueOf(typen)<>-1) then typen:='integer';

                concatenate6(tem,#13#10'function sg__',tmstruct.name,'_get_',memb.name,' takes integer i returns ',typen);
                SWriteLn(firstblock,tem);
                generateMultiArrayPicker( RConcatenate3('s__',tmstruct.name,'_'),memb.name ,tmstruct.requiredspace,'i',4,'return ','',firstblock);
                SWriteLn(firstblock,'endfunction');

                concatenate7(tem,#13#10'function sg__',tmstruct.name,'_set_',memb.name,' takes integer i,',typen,' v returns nothing');
                SWriteLn(firstblock,tem);
                generateMultiArrayPicker(RConcatenate3('s__',tmstruct.name,'_'),memb.name,tmstruct.requiredspace,'i',4,'set ','=v',firstblock);
                SWriteLn(firstblock,'endfunction');

            end;
        end;

        if((tmstruct.gotstructchildren and (tmstruct.parent=-1)) or tmstruct.isinterface) and (tmstruct.requiredspace>=JASS_ARRAY_SIZE)  then begin
             Concatenate3(tem,#13#10'function si__',tmstruct.name,'_getType takes integer this returns integer');
             SWriteLn(firstblock,tem);
             generateMultiArrayPicker( RConcatenate3('si__',tmstruct.name,'_'),'type' ,tmstruct.requiredspace,'this',4,'return ','',firstblock);
             SWriteLn(firstblock,'endfunction');
        end;

    end;

    //Generate usual functions.
    for TS := 1 to StructN do begin
        i:=TopSortedStructList[TS];
        tmstruct:=StructList[i];

        if( (tmstruct.parent<>-1) or (tmstruct.parentstruct<>-1)) and (tmstruct.containsarraymembers) then begin
            Concatenate3(tem,'function sa__',tmstruct.name,'__disposeArrays takes nothing returns boolean');
            SWriteLn(secondblock,tem);
            SWriteLn(secondblock,' local integer this=f__arg_this');
            SWriteLn(secondblock,' local integer kthis');

            Concatenate3(tem2,'si__',tmstruct.name,'_arrN');
            Concatenate5(tem,'    set ',tem2,'=',tem2,'+1');
            SWriteLn(secondblock,tem);
            if(tmstruct.requiredspace>=JASS_ARRAY_SIZE) then begin
                GenerateMultiArrayPicker( RConcatenate3('si__',tmstruct.name,'_'),'arr',tmstruct.requiredspace,'this',4,'set kthis=','',secondblock);
                GenerateMultiArrayPicker( RConcatenate3('si__',tmstruct.name,'_'),'arrV',tmstruct.requiredspace,tem2,4,'set ','=kthis',secondblock);

            end else begin
                Concatenate3(tem,'    set kthis=si__',tmstruct.name,'_arr[this]');
                SWriteLn(secondblock,tem);
                Concatenate5(tem,'    set si__',tmstruct.name,'_arrV[',tem2,']=kthis');
                SWriteLn(secondblock,tem);
            end;


            SWriteLn(secondblock,' return true');
            SWriteLn(secondblock,'endfunction');

        end;



        for j := 0 to tmstruct.membern - 1 do if(  (tmstruct.members[j].abuse) and(not tmstruct.members[j].destruct)  ) then begin

            execblock:='';

            memb:=tmstruct.members[j];
            makeMethodCopy := {false}not(tmstruct.isinterface)  and not (memb.stub);
            doExec := ( memb.abuseexec or tmstruct.isinterface);


            //write caller
            Concatenate4(tem,#13#10'//Generated method caller for ',tmstruct.name,'.',memb.name);
            SWriteLn(firstblock,tem);
            Concatenate5(tem,'function sc__',tmstruct.name,'_',memb.name,' takes ');
            swrite(firstblock,tem);

            if(doExec) then begin
                Concatenate4(tem,#13#10'//Generated method executor for ',tmstruct.name,'.',memb.name);
                SWriteLn(execblock,tem);
                Concatenate5(tem,'function sx__',tmstruct.name,'_',memb.name,' takes ');
                swrite(execblock,tem);
            end;



            if(memb.isstatic) then begin
                if(memb.argnumber=0) then begin
                    Swrite(firstblock,'nothing returns ');
                    if(doExec) then SWriteLn(execblock,'nothing returns nothing');
                    typ:=memb.returntype;if(StructHash.ValueOf(typ)<>-1) then typ:='integer';
                    SWriteLn(firstblock,typ);

                end else begin
                    typ:=memb.argtypes[0];if(StructHash.ValueOf(typ)<>-1) then typ:='integer';
                    Swrite(firstblock,typ);
                    Swrite(firstblock,' ');
                    Swrite(firstblock,memb.argnames[0]);
                    if(doExec) then begin
                        Swrite(execblock,typ);
                        Swrite(execblock,' ');
                        Swrite(execblock,memb.argnames[0]);

                    end;
                    for a := 1 to memb.argnumber-1 do begin
                        typ:=memb.argtypes[a];if(StructHash.ValueOf(typ)<>-1) then typ:='integer';

                        Concatenate4(tem,',',typ,' ',memb.argnames[a]);
                        swrite(firstblock,tem);
                        if(doExec) then Swrite(execblock,tem);
                    end;
                    if(doExec) then SWriteLn(execblock,' returns nothing');
                    swrite(firstblock,' returns ');
                    typ:=memb.returntype;if(StructHash.ValueOf(typ)<>-1) then typ:='integer';
                    SWriteLn(firstblock,typ);
                end;

            end else begin
                swrite(firstblock,'integer this');
                if(doExec) then swrite(execblock,'integer this');
                for a := 0 to memb.argnumber-1 do begin
                    typ:=memb.argtypes[a];if(StructHash.ValueOf(typ)<>-1) then typ:='integer';
                    Concatenate4(tem,',',typ,' ',memb.argnames[a]);
                    swrite(firstblock,tem);
                    if(doExec) then swrite(execblock,tem);
                end;
                if(doExec) then SWriteLn(execblock,' returns nothing');
                swrite(firstblock,' returns ');
                typ:=memb.returntype;if(StructHash.ValueOf(typ)<>-1) then typ:='integer';
                SWriteLn(firstblock,typ);
            end;


            callstuff:='';
            funcall:='';
            badHandlesUsed:=false;
            Concatenate5(funcall,'s__',tmstruct.name,'_',memb.name,'(');


            if(makeMethodCopy) then begin
                k:= memb.decl+1;
                while not CompareLineToken('endfunction',input[k],b) do begin
                     if (DoesLineContainFunctionCalls(input[k],k) ) then begin
                          makeMethodCopy:=false;
                          break;
                     end;
                     k:=k+1;
                end;

                k:= memb.decl+1;
                while makeMethodCopy and not CompareLineToken('endfunction',input[k],b) do begin
                     SWriteLn(firstblock, input[k]);
                     k:=k+1;
                end;
            end;


            if(not memb.isstatic) then begin
                 if(not makeMethodCopy) then SWriteLn(firstblock,'    set f__arg_this=this');
                 //callstuff:='f__arg_this';
                 if(doExec) then SWriteLn(execblock,'    set f__arg_this=this');

                 callstuff:='local integer this=f__arg_this';
                 funcall:=funcall+'f__arg_this';

            end;

            for a := 0 to memb.argnumber-1 do begin
                typ:=memb.argtypes[a];
                if(StructHash.ValueOf(typ)<>-1) then typ:='integer';

                if(badHandleHash.ValueOf(typ)=1) then badHandlesUsed:=true;

                c:=1;
                for b := 0 to a - 1 do begin
                    if(memb.argtypes[b]=typ) or((typ='integer') and ( StructHash.ValueOf(memb.argtypes[b])<>-1 )) then c:=c+1;
                end;

                Concatenate3(tem,'f__arg_',typ,IntToStr(c));

                if( (a<>0) or not memb.isstatic) then begin
                    Concatenate3(tem2,funcall,',',tem);
                    funcall:=tem2;

                end else begin
                    funcall:=funcall+tem;
                end;


                Concatenate6(tem2,'local ',typ,' ',memb.argnames[a],'=',tem);
                if(callstuff<>'') then begin
                    swrite(callstuff,#13#10);
                    swrite(callstuff,tem2);

                end else callstuff:=tem2;

                if(not makeMethodCopy) then begin
                    Swrite(firstblock,'    set ');
                    Swrite(firstblock,tem);
                    Swrite(firstblock,'=');
                    SWriteLn(firstblock,memb.argnames[a]);
                end;

                if(doExec) then begin
                    Swrite(execblock,'    set ');
                    Swrite(execblock,tem);
                    Swrite(execblock,'=');
                    SWriteLn(execblock,memb.argnames[a]);
                end;

            end;

            funcall:=funcall+')';

            if( tmstruct.isinterface or memb.stub) then begin
                if ( memb.stub or (tmstruct.nchildren>0) ) then begin

                    if ((memb.interdefault <> '') and (memb.returntype<>'nothing') ) then begin
                        Concatenate7(tem,'    //An error in the next line would mean declaration for ', tmstruct.name,'.',memb.name,' had a wrong default (',memb.interdefault,')');
                        if(not makeMethodCopy) then SWriteLn(firstblock,tem);
                        typ:=memb.returntype;
                        if(StructHash.ValueOf(typ)<>-1) then typ:='integer';
                        Concatenate4(tem,'    set f__result_',typ,'=',memb.interdefault);
                        if(not makeMethodCopy) then SWriteLn(firstblock,tem);
                    end;

                    //it is impossible to have execute() on < or []
                    if (memb.name='_lessthan') then begin
                        Concatenate5(tem,'  if (si__',tmstruct.name,'_type[this]==si__',tmstruct.name,'_type[dummy]) then');
                        if(not makeMethodCopy) then SWriteLn(firstblock,tem);
                    end;

                    if(tmstruct.requiredspace>=JASS_ARRAY_SIZE) then begin
                        Concatenate5(tem,'    call TriggerEvaluate(st__',tmstruct.superparentname,'_',memb.name,'[');
                        if(not makeMethodCopy) then GenerateMultiArrayPicker( RConcatenate3('si__',tmstruct.name,'_'), 'type', tmstruct.requiredspace, 'this',4,tem,'])',firstblock);
                        Concatenate5(tem,'    call TriggerExecute(st__',tmstruct.name,'_',memb.name,'[');
                        GenerateMultiArrayPicker( RConcatenate3('si__',tmstruct.superparentname,'_'), 'type', tmstruct.requiredspace, 'this',4,tem,'])',execblock);
                    end else begin
                        Concatenate7(tem,'    call TriggerEvaluate(st__',tmstruct.name,'_',memb.name,'[si__',tmstruct.superparentname,'_type[this]])');
                        SWriteLn(firstblock,tem);
                        Concatenate7(tem,'    call TriggerExecute(st__',tmstruct.name,'_',memb.name,'[si__',tmstruct.superparentname,'_type[this]])');
                        SWriteLn(execblock,tem);
                    end;

                    if(not makeMethodCopy) and (memb.name='_lessthan') then begin
                           SWriteLn(firstblock,'  else');
                           if(debug) then
                              SWriteLn(firstblock,'    call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,1000.,"Warning: overloaded compare operator used between structs of different types.")');

                              Concatenate5(tem,'    call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,1000.,"Warning: "+I2S(si__',tmstruct.name,'_type[this])+" vs "+I2S(si__',tmstruct.name,'_type[dummy]))');
                              SWriteLn(firstblock,tem);

                           SWriteLn(firstblock,'    return false');
                        SWriteLn(firstblock,'  endif');
                    end;

                end else begin
                    if(not makeMethodCopy) then SWriteLn(firstblock,'    //no struct used this interface. We should probably avoid adding it...');
                end;

            end else if(tmstruct.gotstructchildren and (tmstruct.parentname='') and ((memb.name='onDestroy') or (memb.fromparent))  ) then begin
                Concatenate7(tem,'    call TriggerEvaluate(st__',tmstruct.name,'_',memb.name,'[',IntToStr(i),'])');
                if(not makeMethodCopy) then SWriteLn(firstblock,tem);
                if(doExec) then begin
                    Concatenate7(tem,'    call TriggerExecute(st__',tmstruct.name,'_',memb.name,'[',IntToStr(i),'])');
                    SWriteLn(execblock,tem);
                end;
            end else begin


               if (tmstruct.parentstruct<>-1) and ((memb.name='onDestroy') or (memb.fromparent)) then begin

                   tmstruct2:=tmstruct;
                   repeat
                       if(tmstruct2.parentstruct=-1) then
                           tmstruct2:=StructList[tmstruct2.parent]
                       else
                           tmstruct2:=StructList[tmstruct2.parentstruct];
                       if tmstruct2.getmember(memb.name,memb2)
                          and (memb2.stub) and not memb2.fromparent then
                           break;

                   until (tmstruct2.parentstruct=-1) and (tmstruct2.parent=-1);
                   { i holds the struct type id }
                   Concatenate7(tem,'    call TriggerEvaluate(st__',tmstruct2.name,'_',memb.name,'[',IntToStr(i),'])');
                   if(not makeMethodCopy) then SWriteLn(firstblock,tem);
                   if(doExec) then begin
                       Concatenate7(tem,'    call TriggerExecute(st__',tmstruct2.name,'_',memb.name,'[',IntToStr(i),'])');
                       SWriteLn(execblock,tem);
                   end;

               end else if (tmstruct.parent<>-1) and (memb.fromparent) then begin
                   tmstruct2:=StructList[tmstruct.parent];
                   { i holds the struct type id }
                   Concatenate7(tem,'    call TriggerEvaluate(st__',tmstruct2.name,'_',memb.name,'[',IntToStr(i),'])');
                   if(not makeMethodCopy) then
                       SWriteLn(firstblock,tem);
                   if(doExec) then begin
                       Concatenate7(tem,'    call TriggerExecute(st__',tmstruct2.name,'_',memb.name,'[',IntToStr(i),'])');
                       SWriteLn(execblock,tem);
                   end;

               end else begin
                   Concatenate5(tem,'    call TriggerEvaluate(st__',tmstruct.name,'_',memb.name,')');
                   if(not makeMethodCopy) then SWriteLn(firstblock,tem);
                   if(doExec) then begin
                       Concatenate5(tem,'    call TriggerExecute(st__',tmstruct.name,'_',memb.name,')');
                       SWriteLn(execblock,tem);
                   end;
               end;
            end;

            if(not tmstruct.isinterface) then begin
                //on inilines:
                if (  ((tmstruct.parentname<>'') or memb.stub ) and (memb.fromparent or memb.stub) and (memb.name<>'onDestroy') ) then begin

                    tmstruct2:=tmstruct;
                    while (tmstruct2.parent<>-1) or (tmstruct2.parentstruct<>-1) do begin
                         if tmstruct2.getmember(memb.name,memb2)
                            and (memb2.stub) and not memb2.fromparent then
                                break;

                         if(tmstruct2.parent=-1) then begin
                             if( memb.stub and not StructList[tmstruct2.parentstruct].getmember(memb.name, memb2)) then begin
                                 break;
                             end;
                             tmstruct2:=StructList[tmstruct2.parentstruct];
                         end
                         else begin
                             tmstruct2:=StructList[tmstruct2.parent];
                         end;
                    end;

                    { i holds the struct type id }
                    Concatenate7(tem,'    set st__',tmstruct2.name,'_',memb.name,'[',IntToStr(i),']=CreateTrigger()');
                    SWriteLn(inilines,tem);
                    DoCrazyRecursiveTriggerAssign(tmstruct2,tmstruct,memb,inilines);
                    Concatenate11(tem,'    call TriggerAddCondition(st__',tmstruct2.name,'_',memb.name,'[',IntToStr(i),'],Condition( function sa__',tmstruct.name,'_',memb.name,'))');
                    SWriteLn(inilines,tem);
                    Concatenate11(tem,'    call TriggerAddAction(st__',tmstruct2.name,'_',memb.name,'[',IntToStr(i),'], function sa__',tmstruct.name,'_',memb.name,')');
                    SWriteLn(inilines,tem);
                end else if ((memb.name='onDestroy') and (tmstruct.gotstructchildren) and (tmstruct.parentname='') ) then begin
                    Concatenate7(tem,'    set st__',tmstruct.name,'_',memb.name,'[',IntToStr(i),']=CreateTrigger()');
                    SWriteLn(inilines,tem);
                    DoCrazyRecursiveTriggerAssign(tmstruct,tmstruct,memb,inilines);
                    Concatenate11(tem,'    call TriggerAddCondition(st__',tmstruct.name,'_',memb.name,'[',IntToStr(i),'],Condition( function sa__',tmstruct.name,'_',memb.name,'))');
                    SWriteLn(inilines,tem);

                end else if (memb.name<>'onDestroy') or (tmstruct.parentname='') then begin

                    Concatenate5(tem,'    set st__',tmstruct.name,'_',memb.name,'=CreateTrigger()');
                    SWriteLn(inilines,tem);
                    Concatenate9(tem,'    call TriggerAddCondition(st__',tmstruct.name,'_',memb.name,',Condition( function sa__',tmstruct.name,'_',memb.name,'))');
                    SWriteLn(inilines,tem);

                    if(doExec) then begin
                        Concatenate9(tem,'    call TriggerAddAction(st__',tmstruct.name,'_',memb.name,', function sa__',tmstruct.name,'_',memb.name,')');
                        SWriteLn(inilines,tem);
                    end;
                end;
            end;

            typ:=memb.returntype;
            if(typ<>'nothing') then begin
                if(not makeMethodCopy) then Swrite(firstblock,' return f__result_');
                if( StructHash.ValueOf(typ)<>-1) then typ:='integer';
                if(not makeMethodCopy) then SWriteLn(firstblock,typ);
            end;

            SWriteLn(firstblock,'endfunction');
            if(doExec) then begin
                SWriteLn(execblock,'endfunction');
                swrite(firstblock,execblock);
            end;



            {typ holds return type}
            //write the trigger action:
            if(not tmstruct.isinterface) then begin
                ret:=False;
                Concatenate5(tem,'function sa__',tmstruct.name,'_',memb.name,' takes nothing returns boolean'#13#10);
                swrite(secondblock,tem);

                if (not badHandlesUsed) then begin
                  SWriteLn(secondblock,callstuff);

                  b:=memb.decl+1;


                  while ( not CompareLineToken('endfunction',input[b],wordend)) do begin
                    if(ret) then begin
                        SWriteLn(secondblock,'return true');
                        ret:=false;
                    end;
                    tem:=input[b];


                    if (Iswhitespace(tem)) then //nothing
                    else if(CompareLineToken('return',tem,wordend) ) then begin
                        if (memb.returntype<>'nothing') then begin
                            tem:=Copy(tem,wordend,Length(tem)) ;
                            if(Iswhitespace(tem)) then raise JasserLineException(b,'Expected a return value');
                            SWriteLn(secondblock,'set f__result_'+typ+'='+tem);
                        end else begin
                            tem:=Copy(tem,wordend,Length(tem)) ;
                            if(not Iswhitespace(tem)) then raise JasserLineException(b,'Unexpected return value. (method declared to return nothing)');
                        end;
                        ret:=true;
                        if (memb.name='onDestroy') and ((tmstruct.parent<>-1) or (tmstruct.parentstruct<>-1)) then begin
                            SWriteLn(secondblock,'    set f__arg_this=this');
                        end;

                    end else SWriteLn(secondblock,tem);
                    b:=b+1;
                  end;
                  if (memb.name='onDestroy') and ((tmstruct.parent<>-1) or (tmstruct.parentstruct<>-1)) then begin
                      SWriteLn(secondblock,'    set f__arg_this=this');
                  end;

                end else begin
                    if (memb.name='onDestroy') and ((tmstruct.parent<>-1) or (tmstruct.parentstruct<>-1)) then begin
                         SWriteLn(secondblock,' local integer this=f__arg_this');
                    end;
                    if(memb.returntype<>'nothing') then begin
                        concatenate4(tem,'    set f__result_',typ,'=',funcall);
                    end else tem:='    call '+funcall;
                    SWriteLn(secondblock,tem);
                    if (memb.name='onDestroy') and ((tmstruct.parent<>-1) or (tmstruct.parentstruct<>-1)) then begin
                         SWriteLn(secondblock,'    set f__arg_this=this');
                    end;

                end;



                {if(typ<>'nothing') then begin
                    Concatenate3(tem,'    set f__result_',typ,'=');
                    swrite(secondblock,tem);
                end else swrite(secondblock,'    call ');
                Concatenate7(tem,'s__',tmstruct.name,'_',memb.name,'(',callstuff,')');
                SWriteLn(secondblock,tem);}
                SWriteLn(secondblock,'   return true');
                SWriteLn(secondblock,'endfunction');
            end;


        end;

        //onDestroy for interfaces/structs extending structs
        memb:=nil;
        if (tmstruct.parentname<>'') and (tmstruct.getmember('onDestroy',memb) or tmstruct.containsarraymembers ) then  begin
            tmstruct2:=tmstruct;
            while (tmstruct2.parent<>-1) or (tmstruct2.parentstruct<>-1) do begin
                if(tmstruct2.parent=-1) then tmstruct2:=StructList[tmstruct2.parentstruct]
                else tmstruct2:=StructList[tmstruct2.parent];
            end;

            Concatenate5(tem2,'st__',tmstruct2.name,'_onDestroy[',IntToStr(i),']');

            { i holds the struct type id }
            Concatenate3(tem,'    set ',tem2,'=CreateTrigger()');
            SWriteLn(inilines,tem);
            DoCrazyRecursiveTriggerAssign(tmstruct2,tmstruct,memb,inilines);
            tmstruct2:=tmstruct;

            while true do begin
                if (tmstruct2.getmember('onDestroy',memb2)) then begin
                    Concatenate5(tem,'    call TriggerAddCondition(',tem2,',Condition( function sa__',tmstruct2.name,'_onDestroy))');
                    SWriteLn(inilines,tem);
                end;

                if (tmstruct2.parent=-1) and (tmstruct2.parentstruct=-1) then break;
                if (tmstruct2.containsarraymembers) then begin
                    Concatenate5(tem,'    call TriggerAddCondition(',tem2,',Condition( function sa__',tmstruct2.name,'__disposeArrays))');
                    SWriteLn(inilines,tem);
                end;

                if(tmstruct2.parent=-1) then tmstruct2:=StructList[tmstruct2.parentstruct]
                else tmstruct2:=StructList[tmstruct2.parent];
            end;

        end;

        //factory stuff::
        if(tmstruct.isinterface and tmstruct.dofactory) then begin
             Concatenate3(tem,'    set st__',tmstruct.name,'__factory=CreateTrigger()');SWriteLn(inilines,tem);
             Concatenate5(tem,'    call TriggerAddCondition(st__',tmstruct.name,'__factory,Condition(function sa__',tmstruct.name,'__factory))');SWriteLn(inilines,tem);

             WriteFactoryFunction(tmstruct,secondblock,debug);

        end;

        if(tmstruct.parent<>-1) and (tmstruct.ondestroy=nil) and not( tmstruct.containsarraymembers ) then begin
            tmstruct2:=StructList[tmstruct.parent];
            { i holds the struct type id }
            // Add a CreateTrigger() line but don't add the condition.
            //Concatenate5(tem,'    set st__',tmstruct2.name,'_onDestroy[',IntToStr(i),']=CreateTrigger()');
            Concatenate5(tem,'    set st__',tmstruct2.name,'_onDestroy[',IntToStr(i),']=null');
            SWriteLn(inilines,tem);
            DoCrazyRecursiveNullTriggerAssign( tmstruct2, tmstruct, 'onDestroy' , inilines);
        end
        else if(tmstruct.parentstruct=-1) and (tmstruct.gotstructchildren) and (tmstruct.ondestroy=nil) and not( tmstruct.containsarraymembers ) then begin
            { i holds the struct type id }
            // Add a CreateTrigger() line but don't add the condition.
            //Concatenate5(tem,'    set st__',tmstruct2.name,'_onDestroy[',IntToStr(i),']=CreateTrigger()');
            Concatenate5(tem,'    set st__',tmstruct.name,'_onDestroy[',IntToStr(i),']=null');
            SWriteLn(inilines,tem);
            DoCrazyRecursiveNullTriggerAssign( tmstruct, tmstruct, 'onDestroy' , inilines);
        end;

        if (tmstruct.isinterface) then  begin

            for j := 0 to tmstruct.membern-1 do begin
                memb:=tmstruct.members[j];
                if(memb.ismethod) then begin
                    DoCrazyRecursiveNullTriggerAssign(tmstruct,tmstruct,memb.name,inilines);
                end;

            end;

        end;

        if (not tmstruct.forInternalUse) then begin

            if(not tmstruct.isinterface) and (tmstruct.FunctionInterfacePrototype=-1) and not(tmstruct.isArrayStruct) then begin
                     //write constructor:
                     swrite(firstblock,#13#10'//Generated allocator of ');
                     SWriteLn(firstblock,tmstruct.name);

                     tmstruct2:=tmstruct;
                     memb:=nil;
                     useallocforname:=false;
                     if(tmstruct.parentstruct=-1) then begin
                         Concatenate3(tem,'function s__',tmstruct.name,'__allocate takes nothing returns integer');
                         SWriteLn(firstblock,tem);
                     end else begin
                         tmstruct2:=StructList[tmstruct.parentstruct];
                         Concatenate3(tem,'function s__',tmstruct.name,'__allocate takes ');

                         if(tmstruct2.getmember('create',memb)) then begin
                             k:=tmstruct2.typeid;

                             while ((memb.construct) and (StructList[k].parentstruct<>-1)) do begin
                                 useallocforname:=true;
                                 k:=StructList[k].parentstruct;
                                 if (not StructList[k].getmember('create',memb)) then raise JasserLineException(StructList[k].decl,'[internal error] No create method???');
                             end;

                             if(memb.construct) then begin
                                 Swrite(tem,'nothing ');
                             end else begin
                                 if(memb.argnumber=0) then begin
                                     Swrite(tem,'nothing ');
                                 end else for j := 0 to memb.argnumber - 1 do begin
                                     typ:=memb.argtypes[j];
                                     if(StructHash.ValueOf(typ)<>-1) then typ:='integer';
                                     if(j=0) then begin
                                         Swrite(tem,typ+' '+memb.argnames[j]+' ');
                                     end else begin
                                         Swrite(tem,','+typ+' '+memb.argnames[j]+' ');
                                     end;
                                 end;
                             end;
                             Swrite(tem,'returns integer');
                             SWriteLn(firstblock,tem);
                         end else raise JasserLineException(tmstruct2.decl,'[internal error] No create method???');
                     end;

                     if(tmstruct.parent<>-1) then begin
                        SWriteLn(firstblock,' local integer kthis');
                        tmstruct2:=StructList[tmstruct.parent];
                     end;

                     if(tmstruct.parentstruct<>-1) then begin

                         if(memb<>nil) then begin
                             if(memb.construct or  useallocforname ) then begin
                                 Concatenate3(tem,' local integer this=s__',tmstruct2.name,'__allocate('); //just allocator...
                             end else begin
                                 Concatenate3(tem,' local integer this=sc__',tmstruct2.name,'_create(');
                             end;
                             for j := 0 to memb.argnumber-1 do begin
                                 if((memb.argnames[j]='this')or(memb.argnames[j]='kthis')) then begin
                                      raise JasserLineException(memb.decl,'Illegal argument name for constructor: '+memb.argnames[j]);
                                 end;
                                 if(j=0) then begin
                                     Swrite(tem,memb.argnames[j]);
                                 end else begin
                                     Swrite(tem,','+memb.argnames[j]);
                                 end;
                             end;
                             //if(memb.argnumber=1) then tem:=tem+'##';
                             Swrite(tem,')');
                             SWriteLn(firstblock,tem);

                         end else raise JasserLineException(tmstruct2.decl,'[internal error] No create method!!!');
                         SWriteLn(firstblock,' local integer kthis');
                         SWriteLn(firstblock,'    if(this==0) then');
                         SWriteLn(firstblock,'        return 0');
                         SWriteLn(firstblock,'    endif');


                         if(tmstruct.requiredspace>=JASS_ARRAY_SIZE) then begin
                             GenerateMultiArrayPicker(RConcatenate3('si__',tmstruct.superparentname,'_'),'type',tmstruct.requiredspace,'this',4,'set ','='+IntToStr(tmstruct.typeid),firstblock);
                         end else begin
                             Concatenate4(tem,'    set si__',tmstruct.superparentname,'_type[this]=',IntToStr(tmstruct.typeid));
                             SWriteLn(firstblock,tem);
                         end;

                         if(tmstruct2.parent=-1) then
                              writechilddefaultinit(tmstruct,tmstruct2,firstblock,debug,true)
                         else
                              writechilddefaultinit(tmstruct,StructList[tmstruct2.parent],firstblock,debug,true);

                         //SWriteLnSmart(firstblock,tmstruct.oninit);
                     end else begin
                         Concatenate3(tem,' local integer this=si__',tmstruct2.name,'_F');SWriteLn(firstblock,tem);
                         SWriteLn(firstblock,'    if (this!=0) then');
                         if(tmstruct.requiredspace>=JASS_ARRAY_SIZE) then begin
                             Concatenate3(tem,'set si__',tmstruct2.name,'_F=');
                             generateMultiArrayPicker(RConcatenate3('si__',tmstruct2.name,'_'),'V',tmstruct2.requiredspace,'this',8,tem,'',firstblock);
                         end else begin
                             Concatenate5(tem,   '        set si__',tmstruct2.name,'_F=si__',tmstruct2.name,'_V[this]');SWriteLn(firstblock,tem);
                         end;
                         SWriteLn(firstblock,'    else');

                         if (tmstruct.customarray>0) then begin
                            Concatenate6(tem,'        set si__',tmstruct2.name,'_I=si__',tmstruct2.name,'_I+',IntToStr(tmstruct2.customarray));
                         end else begin
                            Concatenate5(tem,'        set si__',tmstruct2.name,'_I=si__',tmstruct2.name,'_I+1');
                         end;
                         SWriteLn(firstblock,tem);
                         Concatenate3(tem,   '        set this=si__',tmstruct2.name,'_I');SWriteLn(firstblock,tem);
                         SWriteLn(firstblock,'    endif');

                         if (tmstruct.customarray>0) then begin
                             Concatenate3(tem,   '    if (this>',IntToStr(tmstruct2.maximum-(tmstruct2.customarray-1)),') then');
                         end else begin
                             Concatenate3(tem,   '    if (this>',IntToStr(tmstruct2.maximum),') then');
                         end;
                         SWriteLn(firstblock,tem);
                         if(debug) then begin
                             SWriteLn(firstblock,'        call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,1000.,"Unable to allocate id for an object of type: '+tmstruct.name+'")');
                         end;
                         SWriteLn(firstblock,'        return 0');
                         SWriteLn(firstblock,'    endif');

                         SWriteLnSmart(firstblock,tmstruct2.oninit);
                         if(tmstruct.parent<>-1) then begin

                             if(tmstruct.requiredspace>=JASS_ARRAY_SIZE) then begin
                                 GenerateMultiArrayPicker(RConcatenate3('si__',tmstruct2.name,'_'),'type',tmstruct.requiredspace,'this',4,'set ','='+IntToStr(i),firstblock);
                             end else begin
                                 Concatenate4(tem,'    set si__',tmstruct2.name,'_type[this]=',IntToStr(i));
                                 SWriteLn(firstblock,tem);
                             end;

                             writechilddefaultinit(tmstruct,tmstruct2,firstblock,debug)
                         end else if (tmstruct.gotstructchildren) then begin
                             if(tmstruct.requiredspace>=JASS_ARRAY_SIZE) then begin
                                 GenerateMultiArrayPicker(RConcatenate3('si__',tmstruct.name,'_'),'type',tmstruct.requiredspace,'this',4,'set ','='+IntToStr(i),firstblock);
                             end else begin
                                 Concatenate4(tem,'    set si__',tmstruct.name,'_type[this]=',IntToStr(i));
                                 SWriteLn(firstblock,tem);
                             end;
                         end;

                         if(tmstruct.requiredspace>=JASS_ARRAY_SIZE) then begin
                             generateMultiArrayPicker(RConcatenate3('si__',tmstruct2.name,'_'),'V',tmstruct.requiredspace,'this',4,'set ','=-1',firstblock);
                         end else begin
                             Concatenate3(tem,'    set si__',tmstruct2.name,'_V[this]=-1');SWriteLn(firstblock,tem);
                         end;



                     end;

                     SWriteLn(firstblock,' return this');
                     SWriteLn(firstblock,'endfunction'#13#10);
             end;

             if(tmstruct.IsInterface and tmstruct.dofactory) then begin
                 swrite(firstblock,'//generated factory of ');
                 SWriteLn(firstblock,tmstruct.name);

                 Concatenate3(tem,   'function sc__',tmstruct.name,'__factory takes integer typeid returns integer'); SWriteLn(firstblock,tem);
                 SWriteLn(firstblock,'    set f__result_integer=0');
                 SWriteLn(firstblock,'    set f__arg_integer1=typeid');
                 Concatenate3(tem,   '    call TriggerEvaluate(st__',tmstruct.name,'__factory)'); SWriteLn(firstblock,tem);
                 SWriteLn(firstblock,'    return f__result_integer');
                 SWriteLn(firstblock,'endfunction');
             end;

             if   (not tmstruct.isArrayStruct) and (tmstruct.parent=-1) and (tmstruct.parentstruct=-1) and (tmstruct.FunctionInterfacePrototype=-1) then begin
                     //write destructor:
                     swrite(firstblock,'//Generated destructor of ');
                     SWriteLn(firstblock,tmstruct.name);
                 if (tmstruct.ondestroy<>nil) or(tmstruct.isinterface) or (tmstruct.gotstructchildren) then
                     Concatenate3(tem,'function sc__',tmstruct.name,'_deallocate takes integer this returns nothing')
                 else
                     Concatenate3(tem,'function s__',tmstruct.name,'_deallocate takes integer this returns nothing');
                     SWriteLn(firstblock,tem);

                     if(tmstruct.requiredspace>=JASS_ARRAY_SIZE) then begin
                         SWriteLn(firstblock,' local integer used');
                     end;


                     SWriteLn(firstblock,'    if this==null then');
                     if(debug) then begin
                         SWriteLn(firstblock,'            call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,1000.,"Attempt to destroy a null struct of type: '+tmstruct.name+'")');
                     end;
                     SWriteLn(firstblock,'        return');

                   if(tmstruct.requiredspace>=JASS_ARRAY_SIZE) then begin
                     SWriteLn(firstblock,'    else');
                     generateMultiArrayPicker(RConcatenate3('si__',tmstruct.name,'_'),'V',tmstruct.requiredspace,'this',8,'set used=','',firstblock);

                     SWriteLn(firstblock,'        if (used!=-1) then');
                     if(debug) then begin
                         SWriteLn(firstblock,'            call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,1000.,"Double free of type: '+tmstruct.name+'")');
                     end;
                     SWriteLn(firstblock,'            return');
                     SWriteLn(firstblock,'        endif');



                   end else begin
                     Concatenate3(tem,'    elseif (si__',tmstruct.name,'_V[this]!=-1) then');
                     SWriteLn(firstblock,tem);
                     if(debug) then begin
                         SWriteLn(firstblock,'            call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,1000.,"Double free of type: '+tmstruct.name+'")');
                     end;
                     SWriteLn(firstblock,'        return');
                   end;
                     SWriteLn(firstblock,'    endif');


                if(( tmstruct.isinterface) or (tmstruct.gotstructchildren)) then begin
                    if(tmstruct.nchildren>0) then begin
                        SWriteLn(firstblock,'    set f__arg_this=this');

                        if(tmstruct.requiredspace>=JASS_ARRAY_SIZE) then begin
                            GenerateMultiArrayPicker( RConcatenate3('si__',tmstruct.name,'_'), 'type', tmstruct.requiredspace,'this',4, 'call TriggerEvaluate(st__'+tmstruct.name+'_onDestroy[','])',firstblock);
                        end else begin
                            Concatenate5(tem,'    call TriggerEvaluate(st__',tmstruct.name,'_onDestroy[si__',tmstruct.name,'_type[this]])');
                            SWriteLn(firstblock,tem);
                        end;



                    end else begin
                        SWriteLn(firstblock,'    //no struct used this interface. We should probably avoid adding it...');
                    end;
                end else if(tmstruct.ondestroy<>nil) then begin
                         SWriteLn(firstblock,'    set f__arg_this=this');
                         Concatenate3(tem,'    call TriggerEvaluate(st__',tmstruct.name,'_onDestroy)');
                         SWriteLn(firstblock,tem);
                end;

                 if(tmstruct.requiredspace>=JASS_ARRAY_SIZE) then begin
                     Concatenate3(tem,'=si__',tmstruct.name,'_F');
                     generateMultiArrayPicker(RConcatenate3('si__',tmstruct.name,'_'),'V',tmstruct.requiredspace,'this',4,'set ',tem,firstblock);
                 end else begin
                     Concatenate5(tem,'    set si__',tmstruct.name,'_V[this]=si__',tmstruct.name,'_F');SWriteLn(firstblock,tem);
                 end;
                     Concatenate3(tem,'    set si__',tmstruct.name,'_F=this');SWriteLn(firstblock,tem);

                     SWriteLn(firstblock,'endfunction');
             end;
        end;
    end;

    MakeFunctionCallers(firstblock);
    buildFunctionActions(secondblock);
    buildIniFunctionActions(inilines);

    if(StructN>0) or FunctionDataUsed then begin
        SWriteLn(secondblock,#13#10'function jasshelper__initstructs'+structmagic_time+' takes nothing returns nothing');
        SWriteLn(secondblock,inilines);

        for i := 1 to StructN do begin
            SWriteLn(secondblock,StructList[i].modulesOnInit);
        end;
        for i := 1 to StructN do begin
            if StructList[i].getmember('onInit',memb) then begin
                Concatenate3(tem,'    call ExecuteFunc("s__',StructList[i].name,'_onInit")');
                SWriteLn(secondblock,tem);

            end;
        end;


        SWriteLn(secondblock,'endfunction');
    end;
    if(datafunctions_N>0) then begin
        for i := 0 to datafunctions_n-1 do begin

            swrite(secondblock,#13#10'function jasshelper__'+IntToStr(i)+'initdatastructs'+structmagic_time+' takes nothing returns nothing'#13#10);
            swrite(secondblock,' local integer s'#13#10);
            SWriteLn(secondblock,datafunctions[i]);
            SWriteLn(secondblock,'endfunction');
        end;
    end;
    //Write Hooks:
    WriteHooks(firstblock);



    SWriteLn(result,globalsblock);
    SWriteLn(result,'endglobals');
    SWriteLn(result, nativesblock);
    SWriteLn(result,firstblock);
    SWriteLn(result,secondblock);

        Interf.ProStatus('');
        Interf.ProMax(1);
        Interf.ProPosition(1);

    //Now the real process begins.
 finally
     //Close(DEBUGFILE);
     for i := 1 to StructN do StructList[i].Free;
     functionLines.Free;
     hookedNatives.Free;
     hookedNativeHash.Free;

     nativeLines.Free;
     hookLines.Free;
     BigArrayHash.Free;
     StructHash.Free;
     RequiredSizeHash.Free;
     BadHandleHash.Free;
     IntegerConstants.Free;
     IdentifierTypes.Free;
     LocalIdentifierTypes.Free;
     CleanFunctionPrototypes;


 end;


end;

//<modulemagic>
//Module magic, a phase before main struct stuff, does text-manip-related
// struct features
// input: input array,
// output : processed input array.
var modoutput: array of String;
var modline: array of Integer;
var modtrace: array of Integer;
type TModule = class
    name:string;
    decl, declend:integer;
    ImplementedStructId: integer;
    onInit:string;
    privateMembers:Tstringhash;
end;

procedure DoStructModuleMagic;
var
   i,j,x,oln:integer;
   ModuleHash:TStringHash;
   ModuleN:integer;
   Modules: array of TModule;
   cmodule: TModule;
   modname, privateprefix:string;
   structopen,addit,optional:boolean;
   structname:string;
   structid:integer;

      function replaceThisType(const s:string):string;
      begin
          if(not structopen) then
             Result:=s
          else
              Result:=ReplaceIdentifier(s,'thistype',structname);
      end;

      procedure writeOutputLine( const s:string; fromline:integer; trace:integer);
      begin
          if Length(modoutput) <= oln then begin
              SetLength(modoutput, oln+20 + (oln div 5) );
              SetLength(modline, Length(modoutput) );
              SetLength(modtrace, Length(modoutput) );
          end;

          modoutput[oln]:=Replacethistype(s);
          modline[oln]:=fromline;
          modtrace[oln]:=trace;
          oln:=oln+1;
      end;

      procedure implementModule( const cmod: TModule; fromline:integer);
      var i,j,x:integer;
          optional:boolean;
          modname: String;
      begin
          if(cmod.implementedStructId = structid) then exit;
          cmod.implementedStructId := structid;
          for i := cmod.decl+1 to cmod.declend - 1 do begin
              if(CompareLineWord('implement',input[i],x) ) then begin
                  GetLineWord(input[i],modname,x,x);
                  optional:=false;
                  if(modname='optional') then begin
                      optional:=true;
                      GetLineWord(input[i],modname,x,x);
                  end;
                  VerifyEndOfLine(input[i],x,i);
                  j:=ModuleHash.ValueOf(modname);
                  if(j<0) then begin
                      if (not optional) then
                          raise JasserLineException(i,'Could not find module: '+modname);
                  end else begin
                       implementModule(Modules[j],i);
                  end;
              end else writeOutputLine(input[i], i, fromline);
          end;
          if(cmod.onInit<>'') then WriteOutputLine('//! ModuleOnInit '+cmod.onInit,cmod.decl, fromline);
      end;

      procedure parsePrivate( const line:string; x:integer; var cmodule:Tmodule);
       var
           word:string;
      begin
          GetLineWord(line,word,x,x);
          if(word='static') then begin
              GetLineWord(line,word,x,x);
          end;
          if(word='delegate') then begin
              GetLineWord(line,word,x,x);
          end;
          if(word='constant') then begin
              GetLineWord(line,word,x,x);
          end;

          if(word='method') then begin
              GetLineToken(line,word,x,x);
              if(word='operator') then
                  raise JasserLineException(j,'module private operators are not supported');

              if(word='onInit') then
                  cmodule.onInit:=privateprefix+'onInit';
              if(word='onDestroy') or {(word='onInit') or} (word='create') or (word='destroy') then
                  exit;
                  //raise JasserLineException(j,'private '+word+' not supported yet in modules.');

              cmodule.privateMembers.Add(word,1);

          end else begin
               GetLineToken(line,word,x,x);
               if(word='array') then
                   GetLineToken(line,word,x,x);
               cmodule.privateMembers.Add(word,1);
          end;

      end;
      procedure processPrivate( var line:string; var cmodule:Tmodule);
      begin
           line:=ReplaceIdentifiersByHash(line, cmodule.privateMembers, privateprefix);

      end;



begin

    if (Interf<>nil) then begin
        Interf.ProStatus('Structs: Modules');
    end;


    ModuleHash:=TStringHash.Create;
    ModuleN:=0;
    SetLength(modoutput, ((Length(input)*12) div 10) );
    SetLength(modline, Length(modoutput) );
    SetLength(modtrace, Length(modoutput) );



    //hmnnn:
    //* find modules, store them in array?
    //* find "implement" cnp modules.
    //* replace thisstruct with struct name?

    //--------------------------------------------------------------------------
    //parse Modules
    i:=0;
    while(i<ln) do begin

        if( CompareLineWord('module',input[i],x) ) then begin
            GetLineWord(input[i],modname,x,x);
            if( not ValidIdentifierName(modname) ) then
                raise JasserLineException(i,'Invalid identifier name: '+modname);
            VerifyEndOfLine(input[i],x, i);
            if (Length(Modules) <= ModuleN) then
               SetLength(Modules, ModuleN+5+ModuleN div 5);
            cmodule := TModule.Create;
            cmodule.onInit:='';
            cmodule.name := modname;
            cmodule.implementedStructId := -1;
            cmodule.privateMembers:=TStringHash.create;
            Modules[ModuleN]:=cmodule;
            ModuleHash.Add(modname, ModuleN);
            ModuleN:=ModuleN+1;
            j:=i+1;
            cmodule.decl := i;
            cmodule.declend := -1;
            while(j<ln) do begin
                if(CompareLineWord('endmodule',input[j], x) ) then begin
                    cmodule.declend:=j;
                    break;
                end;
                j:=j+1;
            end;

            if(cmodule.declend < 0) then
                 raise JasserLineException(i,'Could not find endmodule.');
            if(GetTickCount mod 2 = 0) then
                privateprefix:=cmodule.name+'__'
            else
                privateprefix:=cmodule.name+'___';

            //detect private things:
            for j := cmodule.decl+1 to cmodule.declend-1 do begin
                if(CompareLineWord('private',input[j], x) ) then
                    parsePrivate(input[j], x, cmodule);
                cmodule.privateMembers.Add('',-1);
            end;
            for j := cmodule.decl+1 to cmodule.declend-1 do begin
                processPrivate(input[j], cmodule);
            end;


            i:=cmodule.declend+1;
        end
        else i:=i+1;
    end;

    //--------------------------------------------------------------------------
    //implement modules:
    i:=0;
    oln:=0;
    structopen:=false;
    structname:='';
    structid:=-9222; //Magic number!
    while(i<ln) do begin
        addit:=true;
        if( CompareLineWord('module',input[i],x) ) then begin
            GetLineWord(input[i],modname,x,x);
            j:=ModuleHash.ValueOf(modname);
            if( j<0) then
                raise JasserLineException(i, '[internal error], report it.');
            i:=Modules[j].declend;
            addit:=false;
        end else if(CompareLineWord('struct',input[i],x) ) then begin
            structid:=i;
            structopen:=true;
            GetLineToken(input[i],structname,x,x);
        end else if(CompareLineWord('endstruct',input[i],x) ) then
            structopen:=false
        else if( CompareLineWord('implement',input[i],x) ) then begin
            if(not structopen) then
                raise JasserLineException(i, 'Cannot call implement outside structs or modules');

            addit:=false;
            GetLineWord(input[i],modname,x,x);
            optional:=false;
            if(modname = 'optional') then begin
                optional:=true;
                GetLineWord(input[i],modname,x,x);
            end;
            VerifyEndOfLine(input[i],x, i);
            j := ModuleHash.ValueOf(modname);
            if ( (not optional) and (j<0) ) then
                raise JasserLineException(i,'Unable to find module: '+modname);
            if(j>=0) then begin
                writeOutputLine('//Implemented from module '+modname+':', i, -1);
                implementModule(Modules[j],i);
            end;
        end;

        if(addit) then
            writeOutputLine(input[i], i, -1);


        i:=i+1;
    end;

    ln:=oln;
    SetLength(input, oln);
    SetLength(textmacrotrace, oln);
    SetLength(offset, oln);
    for i := 0 to ln - 1 do begin
//         WriteLn(ErrOutput, modoutput[i]);
         input[i]:=modoutput[i];
         offset[i]:=modline[i]-i;
         textmacrotrace[i]:=modtrace[i]+1;
    end;





end;

//<modulemagic>

procedure LoadFile(const FileName: TFileName; var result:string);
begin
  with TFileStream.Create(FileName,
      fmOpenRead or fmShareDenyWrite) do begin
    try
      SetLength(Result, Size);
      Read(Pointer(Result)^, Size);
    except
      Result := '';  // Deallocates memory
      Free;
      raise;
    end;
    Free;
  end;
end;

procedure SaveFile(const FileName: TFileName; const result:string);
var F:textfile;
    open:boolean;
begin
    open:=false;
 try

    Assign(F,filename);
    filemode:=fmOpenWrite;
    Rewrite(F);
    open:=true;
    WriteLn(F,result);
    Close(F);
    open:=false;
 except
     on e:exception do begin
         MessageBox(0,pchar(e.Message),'Error',0);
         if(open) then Close(F);
     end;
 end;
end;

procedure DoJASSerStructMagic(f1:string;f2:string;const debug:boolean);overload;
var
   ff2:textfile;
   bff2:boolean;
   i,o:string;
begin

    bff2:=false;
    try
        LoadFile(f1,i);
        DoJASSerStructMagic(i,debug,o);

        AssignFile(ff2,f2);bff2:=true;

        filemode:=fmOpenWrite;
        Rewrite(ff2);
        Write(ff2,o);
    finally

        if(bff2) then Close(ff2);
    end;
end;

procedure doJassHelperExternals(const maplocation:string);
begin

end;


procedure importPathsClear;
begin
    importpathn:=0;
end;
procedure addImportPath(const s:string);
begin
    if(s='') then Exit;
    if (Length(importpaths)<=importpathn) then begin
        SetLength(importpaths,importpathn+1);
    end;
    if(s[Length(s)]<>'\') then
        importpaths[importpathn]:=s+'\'
    else
        importpaths[importpathn]:=s;
    importpathn:=importpathn+1;

end;

{var
   importpaths:array of string;
   importpathn:integer=0;}



function getExternalUsage(var r:Texternalusage):boolean;
begin
    if(exter.n=0) then begin
        Result:=false;
        exit;
    end;
    Result:=true;
    r:=Exter;
end;


//===================================================
// Functions and prototypes

constructor Tfunctionprototype.Create( iargs:TDynamicStringArray; iargsn:integer; ires:string);
var i:integer;
begin
    SetLength(args,iargsn);
    for i := 0 to iargsn-1 do args[i]:=iargs[i];
    argn:=iargsn;
    self.res:=ires;
    funccount:=0;
    abuse:=false;
    childfunctions:=Tstringhash.Create;
end;
destructor Tfunctionprototype.Destroy;
begin
    childfunctions.Free;
end;

function Tfunctionprototype.GetId(const s:string):integer;
begin
    result:=childfunctions.ValueOf(s);
    if(result=-1) then begin
        result:=funccount+1;
        funccount:=result;
        childfunctions.Add(s,result);
    end;
end;

//========================
procedure InitFunctionPrototypes;
begin
    FunctionDataUsed:=false;
    FunctionHash:=TStringHash.Create;
    ProtoHash:=Tstringhash.Create;
    PrototypeN:=0;
    FunctionDataN:=0;
end;
procedure CleanFunctionPrototypes;
var i:integer;
begin

    FunctionDataUsed:=false;
    FunctionHash.Free;
    ProtoHash.Free;

    for i := 1 to prototypeN do Prototype[i].Free;
    for i := 1 to FunctionDataN do FunctionData[i].Free;


end;
function GetFunctionPrototype( args:TDynamicStringArray; argn:integer; returntype:string):integer;
var protk:string;
    k,i:integer;
    nargs: TDynamicStringArray;
begin

    //normalize:
    SetLength(nargs, Length(args) );
    for i := 0 to argn - 1 do
        if (StructHash.ValueOf(args[i])<>-1) then
            nargs[i]:='integer'
        else
            nargs[i]:=args[i];
    if(StructHash.ValueOf(returntype) <> -1) then
        returntype:='integer';

    ConcatenateManySep(protk,nargs,argn,',');
    protk:=protk+'#'+returntype;

    k:=ProtoHash.ValueOf(protk);
    if (k<>-1) then begin result:=k; exit; end;

    PrototypeN:=PrototypeN+1;
    if (Length(Prototype)<=PrototypeN) then
        SetLength(Prototype,PrototypeN+1+ (PrototypeN div 5) );

    k:=PrototypeN;

    Prototype[k]:= Tfunctionprototype.Create(args,argn,returntype);
    ProtoHash.Add(protk,k);

    Result:=k;
end;

function AddFunctionData(const name:string; const protid:integer; const decl:integer):Tfunction;
begin
    FunctionDataN:=FunctionDataN+1;
    if (Length(FunctionData)<=FunctionDataN) then SetLength(FunctionData,FunctionDataN+1+FunctionDataN div 5);
    Result:=Tfunction.Create;
    Result.PrototypeId:=protid;
    Result.decl:=decl;
    Result.name:=name;
    FunctionData[FunctionDataN]:=Result;

    Functionhash.Add(name,FunctionDataN);


end;
//========================

var argsbuff:array of string;
procedure parseFunction(const s:string; decl:integer);
var word:string;
    name:string;
    ret:string;
    k:integer;
    a:integer;
    fun:Tfunction;
    consta:boolean;
    interf:boolean;

    procedure addtype(const ss:string);
    begin
        if (Length(argsbuff)<=a) then SetLength(argsbuff,2*a+1);
        argsbuff[a]:=ss;
        a:=a+1;

    end;

begin

    //constant? function
    //yes I think we should support constant functions here huh?

    GetLineWord(s,word,k);
    consta:=(word='constant');
    if (consta) then GetLineWord(s,word,k,k);



    if(word<>'function') then raise JasserLineException(decl,'internal error (not a function???');

    GetLineWord(s,name,k,k);

    interf:=(name='interface');
    if(interf) then begin
        if(consta) then raise JasserLineException(decl,'Function interfaces do not use the constant prefix');
        GetLineWord(s,name,k,k);
        //set the Structhash so if an argument equals the function interface¡s name , the prototype works correctly 
        if(StructHash.ValueOf(name)<>-1) then raise JasserLineException(decl,'Identifier already in use: '+name);
        StructHash.Add(name,StructN+1);
    end else begin
        if(StructHash.ValueOf(name)<>-1) then raise JasserLineException(decl,'Identifier already in use: '+name);    
    end;
    if(FunctionHash.ValueOf(name)<>-1) then begin

        raise JasserLineDoubleException(decl,'Function redeclared: '+name,
               FunctionData[FunctionHash.ValueOf(name)].decl, '---- Previous declaration.' );
    end;


    if (not compareLineWord('takes',s,k,k)) then raise JasserLineException(decl,'Expected: "takes"');

    GetLineWord(s,word,k,k);
    a:=0;
    if (word<>'nothing') then begin
         //word holds first type

         repeat
            addtype(word);
            GetLineToken(s,word,k,k);
            GetLineToken(s,word,k,k);
            if(word='returns') then break;
            if(word='') then raise JasserLineException(decl,'Expected: "returns"');
         until (word='returns');

    end else if (not compareLineWord('returns',s,k,k)) then raise JasserLineException(decl,'Expected: "returns"');

    ret:='#_~';
    GetLineWord(s,ret,k,k);

    k:=GetFunctionPrototype(TDynamicStringArray(argsbuff),a,ret);

    if(interf) then begin
        StructN:=StructN+1;
        if(Length(StructList)<=StructN) then SetLength(StructList,StructN+1+StructN div 5);
        StructList[StructN]:=Tstruct.create(decl,false);
        StructList[StructN].typeid:=StructN;
        StructList[StructN].FunctionInterfacePrototype:=k;
        StructList[StructN].name:=name;
        input[decl]:='//processed: '+input[decl];
        StructHash.Add(name,StructN);


    end else begin
        fun:=AddFunctionData(name,k,decl);
        fun.abuse:=false;
    end;
end;

function translateMethodOfFunction(const f:string; const fid:integer; const memb:string; const args:string; var res:string; var typ:Tvtype):boolean;
var
   fun:Tfunction;
   h,k:integer;
begin
    if ((memb<>'execute') and (memb<>'evaluate')  and (memb<>'name') ) then begin
         res:=memb+' is not a valid method for function objects. (Expected .execute or .evaluate)';
         Result:=false;
         exit;
    end;
    fun:=FunctionData[fid];
    k:=fun.PrototypeId;
    h:= Prototype[k].GetId(f);

    if(memb='name') then begin
        if(args<>'') then begin
            result:=false;
            res:='name() takes no arguments.';
            exit;
        end;
        result:=true;
        res:='"'+fun.name+'"';
        typ:=MakeType(-1);
        exit;
    end else if(args<>'') then
        res:='sc___prototype'+IntToStr(k)+'_'+memb+'('+IntToStr(h)+','+args+')'
    else
        res:='sc___prototype'+IntToStr(k)+'_'+memb+'('+IntToStr(h)+')';
    typ:=TryGetTypeOf(f);
    fun.abuse:=true;
    prototype[k].abuse:=true;
    result:=true;    FunctionDataUsed:=true;
end;
function translateMemberOfFunction(const f:string; const fid:integer; const memb:string; var res:string; var typ:Tvtype):boolean;
var
   fun:Tfunction;
   k,h:integer;
begin
    if (memb<>'_pointer') and (memb<>'name') then begin
         res:=memb+' is not a valid member for function objects. (Expected: .code or .name)';
         Result:=false;
         exit;
    end;
    fun:=FunctionData[fid];
    if(memb='name') then begin
         result:=true;
         res:='"'+fun.name+'"';
         typ:=MakeType(-1);
         exit;
    end;
    k:=fun.PrototypeId;
    h:= Prototype[k].GetId(f);

    typ:=MakeType(-1);
    fun.abuse:=true;
    prototype[k].abuse:=true;
    res:='('+IntToStr(h)+')';
    result:=true;
    FunctionDataUsed:=true;
end;

function translateMethodOfFunctionPointer(const f:string; const st:Tstruct; const memb:string; const args:string; var res:string; var typ:Tvtype):boolean;
var
   k:integer;
begin
    if ((memb<>'execute') and (memb<>'evaluate')) then begin
         res:=memb+' is not a valid method for function objects. (Expected .execute or .evaluate)';
         Result:=false;
         exit;
    end;
    if (f=st.name) then begin
         res:='Function interface validation of methods is not supported.';
         Result:=false;
         exit;
    end;


    k:=st.FunctionInterfacePrototype;


    if(args<>'') then
        res:='sc___prototype'+IntToStr(k)+'_'+memb+'('+f+','+args+')'
    else
        res:='sc___prototype'+IntToStr(k)+'_'+memb+'('+f+')';
    typ:=TryGetTypeOf(f);

    prototype[k].abuse:=true;
    result:=true;    FunctionDataUsed:=true;
end;

function translateMemberOfFunctionInterface(const f:string; const st:tstruct; const memb:string; var res:string; var typ:Tvtype):boolean;
var
   k,h:integer;
begin
    if (f<>st.name) then begin
         res:='Function interface "'+st.name+'" does not have instance variables.';
         Result:=false;
         exit;
    end;

    k:=FunctionHash.ValueOf(memb);
    if(k=-1) then  begin
         res:='Unable to find function '+memb+' in the map''s script.';
         Result:=false;
         exit;
    end;

    h:=FunctionData[k].PrototypeId;
    if(h<>st.FunctionInterfacePrototype) then begin
         res:='Signature (arguments/return types) of function "'+memb+'" does not match the one defined for: "'+f+'"';
         Result:=false;
         exit;
    end;
    FunctionData[k].abuse:=true;
    Prototype[h].abuse:=true;

    typ:=TryGetTypeOf(f);
    res:='('+IntToStr(Prototype[h].GetId(memb))+')';
    Result:=true;    FunctionDataUsed:=true;




end;


procedure NormalizeFunctionArguments;
var i,j:integer;
begin


    for i := 1 to PrototypeN do if(prototype[i].abuse) then begin

       for j := 0 to prototype[i].argn-1 do begin
           if(Structhash.ValueOf(prototype[i].args[j])<>-1 ) then prototype[i].args[j]:='integer';
       end;

       if(Structhash.ValueOf(prototype[i].res)<>-1) then prototype[i].res:='integer';
    end;
end;

procedure MakeFunctionCallers(var output:string);
var i,j,k,c:integer;
    prot:Tfunctionprototype;
    tem,tem2,tem3:string;
    assigns:string;
    return:string;
begin



    //Make prototype callers...
    for i := 1 to PrototypeN do if(prototype[i].abuse) then begin

        prot:=prototype[i];
        assigns:='';
        for j := 0 to prot.argn-1 do begin
            c:=1;
            for k := 0 to j-1 do begin
                if(prot.args[k]=prot.args[j]) then c:=c+1;
            end;

            Concatenate5(tem,'    set f__arg_',prot.args[j],IntToStr(c),'=a',IntToStr(j+1));
            SWriteLn(assigns,tem);

        end;

        return:='';
        if(prot.res<>'nothing') then begin
            return:=' return f__result_'+prot.res;
        end;

       //execute:
        prot:=prototype[i];
        Concatenate3(tem2,'function sc___prototype',IntToStr(i),'_execute takes ');

        tem3:='integer i';
        for j := 0 to prot.argn-1 do begin
            Concatenate4(tem,',',prot.args[j],' a',IntToStr(j+1));
            Swrite(tem3,tem);
        end;
        Concatenate3(tem,tem2,tem3,' returns nothing');

        SWriteLn(output,tem);
        SWriteLn(output,assigns);

        Concatenate3(tem,'    call TriggerExecute(st___prototype',IntToStr(i),'[i])');
        SWriteLn(output,tem);

        //Execute doesn't have a return value.. SWriteLn(output,return);

        SWriteLn(output,'endfunction');

       //evaluate:
        prot:=prototype[i];
        Concatenate3(tem2,'function sc___prototype',IntToStr(i),'_evaluate takes ');

        tem3:='integer i';
        for j := 0 to prot.argn-1 do begin
            Concatenate4(tem,',',prot.args[j],' a',IntToStr(j+1));
            Swrite(tem3,tem);
        end;
        Concatenate4(tem,tem2,tem3,' returns ',prot.res);

        SWriteLn(output,tem);
        SWriteLn(output,assigns);

        Concatenate3(tem,'    call TriggerEvaluate(st___prototype',IntToStr(i),'[i])');
        SWriteLn(output,tem);

        SWriteLn(output,return);


        SWriteLn(output,'endfunction');


    end;

end;


procedure generateFakeFunctionLocals(const fun:Tfunction; var output:string; var funcall:string; var usecall:boolean);
var word:string;
    name,typ,tem:string;

    k,c,i:integer;
    a:integer;
    s:string;

    prot:Tfunctionprototype;

begin
    usecall:=false;
    funcall:=fun.name+'(';
    s:=input[fun.decl];

    //¿constant? function
    //yes I think we should support constant functions here huh?

    GetLineWord(s,word,k);
    if (word='constant') then GetLineWord(s,word,k,k);

    if(word<>'function') then raise JasserLineException(fun.decl,'internal error (not a function???');

    GetLineWord(s,name,k,k);


    if (not compareLineWord('takes',s,k,k)) then raise JasserLineException(fun.decl,'Expected: "takes"');

    GetLineWord(s,typ,k,k);
    a:=0;
    prot:=Prototype[fun.PrototypeId];

    if (typ<>'nothing') then begin
         //word holds first type

         repeat
            typ:=prot.args[a];
            GetLineToken(s,name,k,k);
            //typ and name.

            c:=1;
            if(a>prot.argn) then raise Exception.Create('Very strange internal error');
            for i := 0 to a-1 do begin
                if(prot.args[i]=typ) then c:=c+1;
            end;
            a:=a+1;
            Concatenate7(tem,' local ',typ,' ',name,'=f__arg_',typ,IntToStr(c));
            SWriteLn(output,tem);

            if(a=1) then begin
                concatenate4(tem,funcall,'f__arg_',typ,IntToStr(c));
                funcall:=tem;
            end else begin
                concatenate4(tem,funcall,',f__arg_',typ,IntToStr(c));
                funcall:=tem;
            end;

            if(badHandleHash.ValueOf(typ)=1) then usecall:=true;

            GetLineToken(s,typ,k,k);
            if(typ='returns') then break;
            if(typ='') then raise JasserLineException(fun.decl,'Expected: "returns"');
         until (typ='returns');

    end else if (not compareLineWord('returns',s,k,k)) then raise JasserLineException(fun.decl,'Expected: "returns"');
    funcall:=funcall+')';
//done!
end;




procedure buildFunctionActions(var output:string);
var i,j,e:integer;
    tem,t2,locals,funcall:string;
    doret,docall:boolean;

    fun:Tfunction;
begin

    for i := 1 to FunctionDataN do if(FunctionData[i].abuse) then begin
        fun:=FunctionData[i];
        j:=fun.decl;
        Concatenate5(tem,'function sa___prototype',IntToStr(fun.PrototypeId),'_',fun.name,' takes nothing returns boolean');
        SWriteLn(output,tem);
        locals:='';
        funcall:='';
        generateFakeFunctionLocals(fun,locals,funcall,docall);
        doret:=false;

      if(docall) then begin
        tem:=prototype[fun.PrototypeId].res;
        if(tem='nothing') then
            SWriteLn(output,'    call '+funcall)
        else
            SWriteLn(output,'    set f__result_'+tem+'='+funcall);

      end else begin
        SWriteLn(output,locals);
        j:=j+1;
        while(j<=ln) do
        begin
            if( CompareLineWord('endfunction',input[j],e)) then break;

            if(doret) then begin
                SWriteLn(output,'    return true');
                doret:=false;
            end;
            if IsWhitespace(input[j]) then //nothing

            else if(CompareLineToken('return',input[j],e)) then begin
                if(Prototype[fun.PrototypeId].res<>'nothing') then begin
                    t2:=Copy(input[j],e,Length(input[j]));
                    if(IsWhitespace(t2)) then raise JasserLineException(j,'Expected: return value');
                    Concatenate4(tem,'    set f__result_',Prototype[fun.PrototypeId].res,'=', t2 );
                    SWriteLn(output,tem);
                    doret:=true;

                end else begin
                    t2:=Copy(input[j],e,Length(input[j]));
                    if(not IsWhitespace(t2)) then raise JasserLineException(j,'Unexpected: return value');
                    doret:=true;

                end;
            end else SWriteLn(output,input[j]);
            j:=j+1;

        end;
      end;
        SWriteLn(output,'    return true');
        SWriteLn(output,'endfunction');
    end;
end;

procedure buildIniFunctionActions(var output:string);
var i:integer;
    tem,ids,xids,trig:string;

    fun:Tfunction;
begin


    for i := 1 to FunctionDataN do if(FunctionData[i].abuse) then begin
        fun:=FunctionData[i];

        ids:=IntToStr(fun.PrototypeId);
        xids:=IntToStr( Prototype[fun.PrototypeId].GetId(fun.name));
        Concatenate5(trig,'st___prototype',ids,'[',xids,']');


        Concatenate3(tem,'    set ',trig,'=CreateTrigger()');SWriteLn(output,tem);
        Concatenate7(tem,'    call TriggerAddAction(',trig,',function sa___prototype',ids,'_',fun.name,')');SWriteLn(output,tem);
        Concatenate7(tem,'    call TriggerAddCondition(',trig,',Condition(function sa___prototype',ids,'_',fun.name,'))');SWriteLn(output,tem);
    end;
end;


//*************************************************************************************
// inliner stuff

var
    InlineFuncHash:TStringHash;

    InlineFuncReplaceText:array of TDynamicStringArray;
    InlineFuncContents:TDynamicStringArray;
    InlineFuncReplaceArgs:array of TDynamicIntegerArray;
    InlineFuncReplaceN:array of integer;
    InlineFuncArgumentType: array of TDynamicStringArray;
    InlineFuncArgumentN: array of integer;
    InlineFuncN:integer;
    NoStateFunctionsHash:TStringHash;

//=======================================================================
// Resize the inline arrays so they can hold at least n elements.
procedure inlineResizeArrays(n:integer);
var ns:integer;
begin
    if(Length(InlineFuncReplaceText)<n) then begin
         ns:=n+(n div 5) + 5;
         SetLength(InlineFuncReplaceText,ns);
         SetLength(InlineFuncReplaceArgs,ns);
         SetLength(InlineFuncArgumentType,ns);
         SetLength(InlineFuncArgumentN,ns);
         SetLength(InlineFuncReplaceN,ns);
         SetLength(InlineFuncContents,ns);
    end;
end;

//===========================================================================
// processes a function that might be a return bug exploiter
function inline_process_returnbugcandidate(const p:integer; const c:integer):boolean;
var j,k:integer;
 argname,funcname, functype,argtype:string;
begin
    Result:=false;
    j:=1;
    if(CompareLineWord('constant',input[p],k)) then j:=k;
    if not CompareLineWord('function',input[p],j,j) then exit;
    GetLineWord(input[p],funcname,j,j);
    if not CompareLineWord('takes',input[p],j,j) then exit;
    GetLineWord(input[p],argtype,j,j);
    if (argtype='nothing') then exit;
    GetLineWord(input[p],argname,j,j);
    if not CompareLineWord('returns',input[p],j,j) then exit;
    GetLineWord(input[p],functype,j,j);
    if ((functype=argtype) or (functype='nothing') ) then exit;

    j:=1;
    if(not CompareLineWord('return',input[c],j,j)) then exit;
    if(not CompareLineWord(argname,input[c],j,j)) then exit;
    if(not IsWhiteSpace(input[c],j) ) then exit;

    //It is a return bug exploiter!, the second line does not matter at all BTW.


    NoStateFunctionsHash.add(funcname,1);
    Result:=true;
end;


//===========================================================================
// processes a function that was marked as inlineable, add to hash, and create
// replace data. p:function declaration line. c: function content line.
procedure inline_process_inleanable(const p:integer; const c:integer);
var start,j,k,r:integer;
    funcname,aname,atype,tok,nonarg:string;
    ArgumentHash:TStringHash;
    F,T,x,L,an:integer;
    ctr:boolean;
begin
    if(c<0) then exit;       //need a way to handle empty functions, *coming soon*

    j:=1;
    if(CompareLineWord('constant',input[p],k)) then j:=k;
    CompareLineWord('function',input[p],j,j);
    GetLineWord(input[p],funcname,j,j);

    if(not CompareLineWord('takes',input[p],j,j)) then begin
        raise JasserLineException(p,'Expected: "takes"');
    end;
    //we'll just blatantly assume the syntax is all right...
    ArgumentHash:=TStringHAsh.Create;
    F:=InlineFuncN;
    InlineFuncHash.Add(funcname,F);
    InlineFuncN:=InlineFuncN+1;
    inlineResizeArrays(InlineFuncN);
    InlineFuncArgumentN[F]:=0;
    an:=0;
    if (CompareLineWord('nothing',input[p],k,j)) then begin
        j:=k;
        CompareLineWord('returns',input[p],j,j);
        //uh, the function takes nothing, be happy?

    end else begin
        while(not CompareLineToken('returns',input[p],k,j)) do begin
            GetLineToken(input[p],atype,j,j);
            GetLineToken(input[p],aname,j,j);

            if(atype='') or (aname='') then break;
            an:=an+1;
            if(Length(InlineFuncArgumentType[F])<an) then SetLength(InlineFuncArgumentType[F],an+3); //all right, how many arguments does this thing need?
            InlineFuncArgumentType[F][an-1]:=atype;
            ArgumentHash.Add(aname,an-1);
        end;
    end;
    InlineFuncArgumentN[F]:=an;
    // a chain of the sort type name
    // arguments are parsed, we don't need return type, at least not yet...
    // let's mess with the contents...
    T:=0;
    SetLength(InlineFuncReplaceText[F],an+1); //often?
    SetLength(InlineFuncReplaceArgs[F],an); //often?

    start:=1;
    if(CompareLineToken('return',input[c],j)) then start:=j;


    L:=GetEndOfUsefulLine(input[c])-1;
    SkipUselessBrackets(input[c],start,L);
    j:=start;
    InlineFuncContents[F]:=Copy(input[c],start,L-start+1);


    nonarg:='';

    while(j<=L) do begin

        k:=j;
        while(k<=L) and (input[c][k] in SEPARATORS) do begin
            if(input[c][k]='"') then begin //handle strings...
                k:=k+1;
                ctr:=false;
                while(k<=L) do begin
                    if(ctr) then ctr:=false
                    else if(input[c][k]='"') then break
                    else if(input[c][k]='\') then ctr:=true;
                    k:=k+1;
                end;
                k:=k+1;
            end else if(input[c][k]='''') then begin //handle "rawcodes"...
                if(k+2<=L) and (input[c][k+2]='''')then k:=k+3
                else k:=k+6;
            end else k:=k+1;
        end;
        if(k>L) then begin
            nonarg:=nonarg+Copy(input[c],j,L-j+1);
            break;
        end;
        GetLineToken(input[c],tok,r,k);

        x:=ArgumentHash.ValueOf(tok);
        if(x<>-1) then begin
            nonarg:=nonarg+Copy(input[c],j,k-j);

            if(Length(InlineFuncReplaceArgs[F])<=T) then begin
                SetLength(InlineFuncReplaceText[F],T+6);
                SetLength(InlineFuncReplaceArgs[F],T+5);
            end;
            InlineFuncReplaceArgs[F][T]:=x;
            InlineFuncReplaceText[F][T]:=nonarg;
            nonarg:='';
            T:=T+1;

        end else begin
            nonarg:=nonarg+Copy(input[c],j,r-j);
        end;
        j:=r;

    end;
    ArgumentHash.Destroy;
    InlineFuncReplaceText[F][T]:=nonarg;
    InlineFuncReplaceN[F]:=T;
    //debug STUFF
    //nonarg:='';
    //for j := 0 to T do begin
    //    nonarg:=nonarg+'{'+InlineFuncReplaceText[F][j]+'}';
    //    if(j<>T) then nonarg:=nonarg+IntToStr(InlineFuncReplaceArgs[F][j]);
    //end;
    //input[c]:=input[c]+' //'+nonarg;//' //This gets inlined!';
end;



//====================================================================================================
//memo-ized bracket-string handling:
//
var
   InlineBracketEnds: array of integer;
   TEMPDEBUG2:boolean=false;

function inline_dobracket(const s:string;const p:integer; i:integer; L:integer; bend:char):integer;
var j:integer;
ctr:boolean;
begin

    if(InlineBracketEnds[i]<>-1) then
    else if(bend='"') then begin
        j:=i+1;
        ctr:=false;
        while(j<=L-1) do begin
            if(ctr) then ctr:=false
            else if(s[j]='"') then break
            else if(s[j]='\') then ctr:=true;
            j:=j+1;
        end;
        InlineBracketEnds[i]:=j;
    end else if(bend='''') then begin
        j:=i;
        if(j+2<=L) and (s[j+2]='''') then j:=j+2
        else if(j+5>L) then j:=L
        else j:=j+5;
        InlineBracketEnds[i]:=j;


    end else begin
        j:=i+1;
        while(j<=L) and (s[j]<>bend) do begin
             if(s[j]='(') then j:=inline_dobracket(s,p,j,L,')')
             else if(s[j]='[') then j:=inline_dobracket(s,p,j,L,']')
             else if(s[j]='"') then j:=inline_dobracket(s,p,j,L,'"')
             else if(s[j]='''') then  j:=inline_dobracket(s,p,j,L,'''');
             j:=j+1;
        end;
        if(j>L) then raise JasserLineException(p,'Expected: '+bend);
        InlineBracketEnds[i]:=j;
    end;
    Result:=InlineBracketEnds[i];
end;

// This calls and prepares the ground for the above function.
procedure inline_dobracketStuff(const s:string;const p:integer; ini:integer; L:integer);
var i:integer;
begin

    if (L+1>Length(InlineBracketEnds)) then SetLength(InlineBracketEnds,L+(L div 2)+1);
    for i := ini to L do InlineBracketEnds[i]:=-1;
    i:=ini;
    while(i<=L) do begin
        
        if(s[i]='(') then i:=inline_dobracket(s,p,i,L,')')
        else if(s[i]='[') then i:=inline_dobracket(s,p,i,L,']')
        else if(s[i]='"') then i:=inline_dobracket(s,p,i,L,'"')
        else if(s[i]='''') then i:=inline_dobracket(s,p,i,L,'''');
        i:=i+1;
    end;

end;


//===========================================================================
// Is the function inlineable?
//
function Inline_IsInlineableFunc(const p:integer; const c:integer):boolean;
var start,j,k:integer;

    funcname,aname,atype,tok:string;
    ArgumentHash:TStringHash;
    L,an:integer;
    usedarguments:integer;

        function rec(a:integer; b:integer):boolean;
        var ri,rj,rk,rx:integer;
            rtok:string;
        begin
            result:=false;
            ri:=a;
            while(ri<=b) do begin
                while (ri<=b) and (input[c][ri] in SEPARATORS) do begin
                    if (input[c][ri]='"') then ri:=inlinebracketends[ri]
                    else if(input[c][ri]='''') then ri:=inlinebracketends[ri];
                    ri:=ri+1;
                end;
                GetLineToken(input[c],rtok,ri,ri);
                if(ri>b) then begin
                    if(ri=b+1) then begin
                        rk:=ArgumentHash.ValueOf(rtok);
                        if(rk<>-1) then begin //an argument
                            if rk<>usedarguments then  exit;
                            usedarguments:=usedarguments+1;
                         end;
                    end;     
                    break;
                end;

                rk:=ArgumentHash.ValueOf(rtok);
                if(rk<>-1) then begin //an argument
                    if rk<>usedarguments then  exit;
                    usedarguments:=usedarguments+1;
                end else begin //probable function!
                    rk:=NoStateFunctionsHash.ValueOf(rtok);
                    if(rk=-1) then begin //probable bad function!
                        rj:=ri;
                        while (rj<b) and (( input[c][rj]=' ') or ( input[c][rj]=#9)) do rj:=rj+1;
                        if(input[c][rj]='(') then begin
                           //bad function, bad!

                           rx:=inlinebracketends[rj];
                           if (not rec(rj+1,rx-1)) then exit;
                           if(an<>usedarguments) then  exit;
                           ri:=rx+1;
                        end else if (input[c][rj]='"') or (input[c][rj]='''') then begin
                            ri:=inlinebracketends[rj]+1;
                            if(ri=0) then begin
                                //messageBox(0,'#','!',0);
                                raise Exception.Create(input[c]+#13#10#13#10'Something broke, report this bug. '+IntToStr(rj));
                            end;
                        end else begin
                            ri:=rj;
                        end;

                    end;
                end;
            end;
            result:=true;
        end;

begin
    result:=false;
    if(c<0) then exit;       //need a way to handle empty functions, *coming soon*

    j:=1;
    if(CompareLineWord('constant',input[p],k)) then j:=k;
    CompareLineWord('function',input[p],j,j);
    GetLineWord(input[p],funcname,j,j);

    if(not CompareLineWord('takes',input[p],j,j)) then begin
        raise JasserLineException(p,'Expected: "takes"');
    end;
    //we'll just blatantly assume the syntax is all right...
    ArgumentHash:=TStringHAsh.Create;
    an:=0;
    if (CompareLineWord('nothing',input[p],k,j)) then begin
        j:=k;
        CompareLineWord('returns',input[p],j,j);
        //uh, the function takes nothing, be happy?

    end else begin
        while(not CompareLineToken('returns',input[p],k,j)) do begin
            GetLineToken(input[p],atype,j,j);
            GetLineToken(input[p],aname,j,j);

            if(atype='') or (aname='') then break;
            an:=an+1;
            ArgumentHash.Add(aname,an-1);
        end;
    end;
    start:=1;
    if(CompareLineToken('return',input[c],j)) then start:=j;


    L:=GetEndOfUsefulLine(input[c])-1;
    SkipUselessBrackets(input[c],start,L);
    j:=start;
    usedarguments:=0;

    if (CompareLineWord('set',input[c],k,j) ) then begin
        GetLineToken(input[c],tok,k,k);
        if(ArgumentHash.ValueOf(tok)<>-1) then begin
            result:=false;
            ArgumentHash.Destroy;
            exit;
        end;
    end;

TEMPDEBUG2:=true;
    inline_dobracketStuff(input[c],c,j,L);
TEMPDEBUG2:=false;
    //nline_dobracketStuff(input[c],c,1,length(input[c]));
    result:=rec(j,L);
    result:=result and (usedarguments=an);

    ArgumentHash.Destroy;


end;

//=======================================================================
// process a line, based on InlineFuncReplace data (does the inlining)

//==============================================================================
// That the function is marked as inlineable is not enough, sometimes
// it also depends on how you call it.
//
function canInlineInstance(const F:integer; argcontents:TDynamicStringArray; incall:boolean):boolean;
var k,i,L,par:integer;
s:string;
begin
    result:=false;
    if(incall) then begin //is it good for a call?
        s:=InlineFuncContents[F];
        if(length(s)=0) then begin result:=true;exit; end;
        //contents ought not to have any initial bracket
        if(s[1]='(') then exit;
        if(compareLineWord('call',s,k) or compareLineWord('set',s,k)) then begin
            result:=true;
            exit;
        end;

        //is it a function call?
        i:=1; L:=Length(s);
        if(s[L]<>')') then exit;
        CompareLineToken('',s,i,i);
        if(i>L) then exit;
        while (i<L) and ((s[i]=' ') or(s[i]=#9)) do i:=i+1;
        if(s[i]<>'(') then exit;
        par:=0;
        k:=i+1;
        while(k<L) and (par>=0) do begin
            if(s[k]='(') or (s[k]='[') then par:=par+1
            else if (s[k]=')') or (s[k]=']') then par:=par-1
            else if(s[k]='"') or (s[k]='''') then SkipString(s,k,L-1);
            k:=k+1;
        end;
        if(par<>0) then exit;

    end;
    result:=true;
end;

//the one function that inlines functions:
// processes the stuff in [a,b]

var TEMP_DEBUG_INLINE:boolean;

function inlineMaximus(const s:string; const p:integer; const funcname:string; const a:integer; const b:integer):string;
var i,j,k,r,t,F,last,cN:integer;
argcontents:TDynamicStringArray;
tem,TEMFNAME:string;
incall:boolean;
whitespc:boolean;
begin
     result:='';
     i:=a;
     k:=a;
     while(i<=b) do begin
         if(s[i]='(') then begin
            r:=i-1;
            while(r>=a) and ((s[r]=' ') or (s[r]=#9)) do r:=r-1;
            if(r<a) or (s[r] in SEPARATORS) then i:=i+1
            else begin
                t:=r-1;
                while(t>=a) and not(s[t] in SEPARATORS) do t:=t-1;
                t:=t+1;
                if(s[t] in NUMBERS) then i:=i+1
                else begin //it is a function
                    TEMFNAME:=Copy(s,t,r-t+1);
                    F:=InlineFuncHash.ValueOf(Copy(s,t,r-t+1));
                    if(F=-1) then i:=i+1
                    else begin
                        //inlineable!
                        //Joy! Happiness...

                        incall:=false;
                        //verify if it is a function call... (begins with call)
                        j:=t-1;
                        while(j>=a) and (s[j] in SEPARATORS) do j:=j-1;

                        //call is always a four letter word, for god's sake...
                        if(j-3>=a) and CompareSubString(s,j-3,j,'call') then begin
                            t:=j-3;
                            incall:=true;
                        end;

                        j:=i+1;
                        last:=j-1;
                        SetLength(argcontents,InlineFuncArgumentN[F]);//duh, it shouldn't go above that
                        cN:=0;
                        whitespc:=true;
                        while(j<=InlineBracketEnds[i]) do begin
                            if(s[j]<>' ') and (s[j]<>#9) and (s[j]<>')') then whitespc:=false;
                            if(s[j]='(') or(s[j]='[') or (s[j]='"') or(s[j]='''') then j:=InlineBracketEnds[j]
                            else if(s[j]=',') or (s[j]=')') then begin
                                if(cN=Length(argcontents)) and ((cN>1) or (not whitespc)) then begin
                                    //argument mismatch error, let a later phase popup it.
                                    result:=Copy(s,a,b-a+1);
                                    exit;
                                end;
                                if(whitespc and (cN=0) and (s[j]=')')) then
                                else begin
                                    argcontents[cN]:=InlineMaximus(s,p,funcname,last+1,j-1); //Copy(s,last+1,j-last-1);
                                    cN:=cN+1;
                                    last:=j;
                                end;
                            end;
                            j:=j+1;
                        end;
                        if(cN<InlineFuncArgumentN[F]) then begin
                            //argument mismatch error, let a later phase popup it.
                            result:=Copy(s,a,b-a+1);
                            exit;
                        end;

                        if(not canInlineInstance(F,argcontents,incall)) then i:=i+1
                        else begin
                            TEMP_DEBUG_INLINE:=true;
                            //do the actual deal!
                            //from k to t-1
                            result:=result+Copy(s,k,t-k);


                            if(not incall) then Result:=Result+'('
                            else begin
                                if(not(comparelinetoken('call',InlineFuncReplaceText[F][0],r)) and not(comparelinetoken('set',InlineFuncReplaceText[F][0],r)) ) then begin
                                    Result:='call ';
                                end;
                            end;
                            for j := 0 to InlineFuncReplaceN[F] do begin
                                result:=Result+InlineFuncReplaceText[F][j];
                                if(j<>InlineFuncReplaceN[F]) then begin
                                    if(InlineFuncArgumentType[F][InlineFuncReplaceArgs[F][j]]='real') then begin
                                        Concatenate3(tem,'((',argcontents[InlineFuncReplaceArgs[F][j]],')*1.0)');
                                    end else begin
                                        Concatenate3(tem,'(',argcontents[InlineFuncReplaceArgs[F][j]],')');
                                    end;
                                    Result:=Result+tem;
                                end;
                            end;
                            if(not incall) then Result:=Result+')';

                            k:=InlineBracketEnds[i]+1;
                            i:=k;
                        end;
                    end;
                end;
            end;

         end else if(s[i]='''') or (s[i]='"') then begin
            SkipString(s, i, i + 2050);
         end else i:=i+1;

     end;
     Result:=Result+Copy(s,k,b-k+1);
end;


procedure inline_handle_line(var s:string; const p:integer; const funcname:string);
var L:integer;
begin
    L:=GetEndOfUsefulLine(s)-1;
    inline_DoBracketStuff(s,p,1,L);
    TEMP_DEBUG_INLINE:=false;
    s:=inlineMaximus(s,p,funcname,1,L)+Copy(s,L+1);
    if(TEMP_DEBUG_INLINE) then s:=s+' // INLINED!!';

    //s:=s+' //inlined!!?';
end;


//===========================================================================
// Process a function (line #p), does inline, and verifies if the function
// Can be inlined later.
procedure inline_handle_function( var p:integer; var output:string);
var
   fend,i,j,k,goodlines,content:integer;
   caninline:boolean;
   funcname:string;


begin
    j:=1;
    if(CompareLineWord('constant',input[p],k)) then j:=k;
    CompareLineWord('function',input[p],j,j);
    GetLineWord(input[p],funcname,j,j);


    //caninline:=true;
    i:=p+1;
    goodlines:=0;
    content:=-1;
    while(i<ln) do begin
        if(CompareLineWord('endfunction',input[i],j)) then break;
        if(CompareLineWord('function',input[i],j) or (CompareLineWord('constant',input[i],j) and CompareLineWord('function',input[i],j,j) ) ) then i:=ln-1
        else if(not IsWhiteSpace(input[i])) then begin
            if(content=-1) then content:=i;
            inline_handle_line(input[i],i,funcname);
            goodlines:=goodlines+1
        end;
        i:=i+1;
    end;
    if(i>ln)        then  raise JasserLineException(p,'Unclosed function.')
    else                  fend:=i;

    if(goodlines<>1) then caninline:=false
    else begin
         caninline:=Inline_IsInlineableFunc(p,content);
    end;

    if(goodlines<=2) then begin
        if ( inline_process_returnbugcandidate(p,content) ) then begin
            caninline := false;
        end;
    end;

    if(caninline) then begin
        inline_process_inleanable(p, content);

    end;


    for i := p to fend do begin
        SWriteLn(output,input[i]);
    end;
    p:=fend;

end;

//========================================================================
procedure InlineInitExceptionsHash;
//Generated, add some natives considered harmless to the nostate hash.
begin
NoStateFunctionsHash.Add('Deg2Rad',1);
NoStateFunctionsHash.Add('Rad2Deg',1);
NoStateFunctionsHash.Add('Sin',1);
NoStateFunctionsHash.Add('Cos',1);
NoStateFunctionsHash.Add('Tan',1);
NoStateFunctionsHash.Add('Asin',1);
NoStateFunctionsHash.Add('Acos',1);
NoStateFunctionsHash.Add('Atan',1);
NoStateFunctionsHash.Add('Atan2',1);
NoStateFunctionsHash.Add('SquareRoot',1);
NoStateFunctionsHash.Add('Pow',1);
NoStateFunctionsHash.Add('I2R',1);
NoStateFunctionsHash.Add('R2I',1);
NoStateFunctionsHash.Add('I2S',1);
NoStateFunctionsHash.Add('R2S',1);
NoStateFunctionsHash.Add('R2SW',1);
NoStateFunctionsHash.Add('S2I',1);
NoStateFunctionsHash.Add('S2R',1);
NoStateFunctionsHash.Add('SubString',1);
NoStateFunctionsHash.Add('StringLength',1);
NoStateFunctionsHash.Add('StringCase',1);
NoStateFunctionsHash.Add('Player',1);
NoStateFunctionsHash.Add('GetPlayerId',1);
NoStateFunctionsHash.Add('GetUnitAbilityLevel',1);
NoStateFunctionsHash.Add('GetUnitUserData',1);
NoStateFunctionsHash.Add('GetHeroLevel',1);
NoStateFunctionsHash.Add('TimerGetElapsed',1);
NoStateFunctionsHash.Add('TimerGetRemaining',1);

NoStateFunctionsHash.Add('GetHandleId',1);
NoStateFunctionsHash.Add('StringHash',1);

NoStateFunctionsHash.Add('HaveStoredInteger', 1);
NoStateFunctionsHash.Add('HaveStoredReal', 1);
NoStateFunctionsHash.Add('HaveStoredBoolean', 1);
NoStateFunctionsHash.Add('HaveStoredUnit', 1);
NoStateFunctionsHash.Add('HaveStoredString', 1);
NoStateFunctionsHash.Add('GetStoredInteger', 1);
NoStateFunctionsHash.Add('GetStoredReal', 1);
NoStateFunctionsHash.Add('GetStoredBoolean', 1);
NoStateFunctionsHash.Add('GetStoredString', 1);
NoStateFunctionsHash.Add('LoadInteger', 1);
NoStateFunctionsHash.Add('LoadReal', 1);
NoStateFunctionsHash.Add('LoadBoolean', 1);
NoStateFunctionsHash.Add('LoadStr', 1);
NoStateFunctionsHash.Add('LoadPlayerHandle', 1);
NoStateFunctionsHash.Add('LoadWidgetHandle', 1);
NoStateFunctionsHash.Add('LoadDestructableHandle', 1);
NoStateFunctionsHash.Add('LoadItemHandle', 1);
NoStateFunctionsHash.Add('LoadUnitHandle', 1);
NoStateFunctionsHash.Add('LoadAbilityHandle', 1);
NoStateFunctionsHash.Add('LoadTimerHandle', 1);
NoStateFunctionsHash.Add('LoadTriggerHandle', 1);
NoStateFunctionsHash.Add('LoadTriggerConditionHandle', 1);
NoStateFunctionsHash.Add('LoadTriggerActionHandle', 1);
NoStateFunctionsHash.Add('LoadTriggerEventHandle', 1);
NoStateFunctionsHash.Add('LoadForceHandle', 1);
NoStateFunctionsHash.Add('LoadGroupHandle', 1);
NoStateFunctionsHash.Add('LoadLocationHandle', 1);
NoStateFunctionsHash.Add('LoadRectHandle', 1);
NoStateFunctionsHash.Add('LoadBooleanExprHandle', 1);
NoStateFunctionsHash.Add('LoadSoundHandle', 1);
NoStateFunctionsHash.Add('LoadEffectHandle', 1);
NoStateFunctionsHash.Add('LoadUnitPoolHandle', 1);
NoStateFunctionsHash.Add('LoadItemPoolHandle', 1);
NoStateFunctionsHash.Add('LoadQuestHandle', 1);
NoStateFunctionsHash.Add('LoadQuestItemHandle', 1);
NoStateFunctionsHash.Add('LoadDefeatConditionHandle', 1);
NoStateFunctionsHash.Add('LoadTimerDialogHandle', 1);
NoStateFunctionsHash.Add('LoadLeaderboardHandle', 1);
NoStateFunctionsHash.Add('LoadMultiboardHandle', 1);
NoStateFunctionsHash.Add('LoadMultiboardItemHandle', 1);
NoStateFunctionsHash.Add('LoadTrackableHandle', 1);
NoStateFunctionsHash.Add('LoadDialogHandle', 1);
NoStateFunctionsHash.Add('LoadButtonHandle', 1);
NoStateFunctionsHash.Add('LoadTextTagHandle', 1);
NoStateFunctionsHash.Add('LoadLightningHandle', 1);
NoStateFunctionsHash.Add('LoadImageHandle', 1);
NoStateFunctionsHash.Add('LoadUbersplatHandle', 1);
NoStateFunctionsHash.Add('LoadRegionHandle', 1);
NoStateFunctionsHash.Add('LoadFogStateHandle', 1);
NoStateFunctionsHash.Add('LoadFogModifierHandle', 1);
NoStateFunctionsHash.Add('LoadHashtableHandle', 1);

NoStateFunctionsHash.Add('HaveSavedInteger', 1);
NoStateFunctionsHash.Add('HaveSavedReal', 1);
NoStateFunctionsHash.Add('HaveSavedBoolean', 1);
NoStateFunctionsHash.Add('HaveSavedString', 1);
NoStateFunctionsHash.Add('HaveSavedHandle', 1);


end;

// More inliner stuff:
procedure InlineDo( var Result:string);
// var inlinefunc
 var i,j,period,nextperiod:integer;
     word:string;
     printit:boolean;
     globals:boolean;

begin
nextperiod:=0;
period:=0;

    InlineFuncHash:=TStringHash.Create;
    NoStateFunctionsHash:=TStringHash.Create;
    InlineInitExceptionsHash;
    InlineResizeArrays(5);
    InlineFuncN:=0;

 try
    if (Interf<>nil) then begin
        Interf.ProMax(ln);
        Interf.ProPosition(0);
        Interf.ProStatus('Inline: Processing...');
        period:= ln div UPDATEVALUE +1 ;
        nextperiod:=period;
    end;

    Result:='';
    // final script rumble, normalized! There are only two things we can expect, the first globals block
    // and a bunch of functions, everything else is probably a syntax error, but it might be a better idea
    // to let PJASS handle it, so we try to ignore it.

    //by this time, unclosed function/globals errors should have been caught by libraries or struct parser
    i:=0;
    globals:=false;
    while(i<ln) do begin
        if(Interf<>nil) and (i>=nextperiod) then begin
            Interf.ProPosition(i);
            nextperiod:=i+period;

        end;

        printit:=true;
        if(not IsWhitespace(input[i])) then begin
            GetLineWord(input[i],word,j);
            if(globals) then begin
                if(word='endglobals') then globals:=false;
            end else if(word='globals') then globals:=true
            else begin
                //[constant] function?
                if((word='constant') and (compareLineWord('function',input[i],j,j))) or (word='function') then begin
                    printit:=false;
                    inline_handle_function(i,Result);
                end;
            end;
        end;

        if(printit) then SWriteLn(Result,input[i]);
        i:=i+1;
    end;
 finally
     InlineFuncHash.Destroy;
     NoStateFunctionsHash.Destroy;
 end;


end;

procedure DoJASSerInlineMagicS(sinput:string; var Result:string);
var i,L,eln,period,nextperiod,k:integer;
begin

    i:=1;L:=Length(sinput);
    eln:=L div 50 + 1; //estimated ln
    SetLength(input,eln);

    Result:='ERROR';

    period:=0;nextperiod:=0;

    ln:=0;
    k:=1;


    if (Interf<>nil) then begin
        Interf.ProMax(L);
        Interf.ProPosition(0);
        Interf.ProStatus('Inline: Loading script...');
        period:= L div UPDATEVALUE +1 ;
        nextperiod:=period;
    end;



    while (i<=L) do begin
        if(Interf<>nil) then begin
            if(i>=nextperiod) then begin
                interf.ProPosition(i);
                nextperiod:=i+period;
            end;
        end;
        if (sinput[i]=#10) then begin
            ln:=ln+1;
            if (ln>eln) then begin
                eln:=ln+((L-i) div 25)+1;
                SetLength(input,eln);
            end;
            if ((i>1) and (sinput[i-1]=#13)) then begin
                input[ln-1]:=Copy(sinput,k,i-1-k);
                k:=i+1;
            end else begin
                input[ln-1]:=Copy(sinput,k,i-k);
                k:=i+1;
            end;
        end;

        i:=i+1;

    end;
    if (ln<2) then raise Exception.Create('Input file seems too small / unclosed string issues');

    SetLength(offset,ln);
    SetLength(textmacrotrace,ln);
    for i := 0 to ln - 1 do begin
        offset[i]:=0;
        textmacrotrace[i]:=0;
    end;


        InlineDo(Result);


end;

procedure DoJASSerInlineMagicF(const f1:string;const f2:string);
var
   ff2:textfile;
   bff2:boolean;
   i,o:string;
begin

    bff2:=false;
    try
        LoadFile(f1,i);
        DoJASSerInlineMagicS(i,o);

        AssignFile(ff2,f2);bff2:=true;

        filemode:=fmOpenWrite;
        Rewrite(ff2);
        Write(ff2,o);
    finally

        if(bff2) then Close(ff2);
    end;
end;

function ArrayStringContains(const arr: array of string; const value: string): Boolean;
var
    i: Integer;
begin
    for i := Low(arr) to High(arr) do begin
        if (arr[i] = value) then begin
            Result := True;
            Exit;
        end;
    end;
    Result := False;
end;

procedure NullLocalDo( var Result:string);
var
    i, j, k, period, nextperiod, endglobals, lastValidLine, lastReturnLine: integer;
    word, tmpWord: string;
    globals: boolean;
    inFunction: boolean;
    returnHandleType, localVariable: array of string;
    generatedNull, currentFuncReturnType: string;

begin
nextperiod:=0;
period:=0;

    InlineFuncHash:=TStringHash.Create;
    NoStateFunctionsHash:=TStringHash.Create;
    InlineInitExceptionsHash;
    InlineResizeArrays(5);
    InlineFuncN:=0;

 try
    if (Interf<>nil) then begin
        Interf.ProMax(ln);
        Interf.ProPosition(0);
        Interf.ProStatus('NullLocal: Processing...');
        period:= ln div UPDATEVALUE +1 ;
        nextperiod:=period;
    end;

    Result:='';
    // final script rumble, normalized! There are only two things we can expect, the first globals block
    // and a bunch of functions, everything else is probably a syntax error, but it might be a better idea
    // to let PJASS handle it, so we try to ignore it.

    //by this time, unclosed function/globals errors should have been caught by libraries or struct parser
    i:=0;
    globals:=false;
    endglobals := 0;
    inFunction := false;
    lastValidLine := 0;
    lastReturnLine := 0;
    while(i<ln) do begin
        if(Interf<>nil) and (i>=nextperiod) then begin
            Interf.ProPosition(i);
            nextperiod:=i+period;

        end;

        if(not IsWhitespace(input[i])) then begin
            GetLineWord(input[i],word,j);
            if(globals) then begin
                if(word='endglobals') then begin
                    globals:=false;
                    endglobals:=i;
                end
            end else if(word='globals') then
                globals:=true
            else if (word = 'endfunction') and (inFunction) then begin
                if (lastValidLine <> lastReturnLine) and (generatedNull <> '') then
                    input[i] := '//JASSHelper null local processed: ' + input[i] + #13#10 + generatedNull + 'endfunction';
                inFunction := false;
                SetLength(localVariable, 0);
            end else if (word = 'return') and (inFunction) then begin
                lastReturnLine := i;
                if (generatedNull <> '') then begin
                    GetLineWord(input[i], word, j, j);
                    tmpWord := input[i];
                    input[i] := '//JASSHelper null local processed: ' + input[i];
                    if (ArrayStringContains(localVariable, word) and ArrayStringContains(reference_counted_obj, currentFuncReturnType)) then
                         input[i] := input[i] + #13#10'set sn__' + currentFuncReturnType + ' = ' + word;
                    input[i] := input[i] + #13#10 + generatedNull;
                    if (ArrayStringContains(localVariable, word) and ArrayStringContains(reference_counted_obj, currentFuncReturnType)) then
                        input[i] := input[i] + 'return sn__' + currentFuncReturnType
                    else
                        input[i] := input[i] + tmpWord;
                end
            end else if (word = 'local') and (inFunction) then begin
                GetLineWord(input[i], word, j, j);
                if (ArrayStringContains(reference_counted_obj, word)) then begin
                    if (not compareLineWord('array',input[i],k,j)) then begin
                        GetLineToken(input[i], word, j, j);
                        generatedNull := 'set '+ word + ' = null'#13#10 + generatedNull;
                        SetLength(localVariable, Length(localVariable) + 1);
                        localVariable[High(localVariable)] := word;
                    end else begin
                        // TODO: handle array
                        // probably handle explicit used array index only
                    end
                end
            end
            else begin
                //[constant] function?
                if((word='constant') and (compareLineWord('function',input[i],j,j))) or (word='function') then begin
                    inFunction := true;
                    generatedNull := '';
                    GetLineWord(input[i], word, j, j);
                    GetLineWord(input[i], word, j, j);
                    if (word = 'takes') then begin
                        GetLineWord(input[i], word, j, j);
                        if (word = 'nothing') then begin
                            GetLineWord(input[i], word, j, j);
                        end else begin
                            while (word <> 'returns') do begin
                                GetLineToken(input[i], word, j, j);
                                GetLineToken(input[i], word, j, j);
                            end;
                        end;
                        GetLineWord(input[i], word, j, j);
                        currentFuncReturnType := word;
                        if (not ArrayStringContains(returnHandleType , word)) and ArrayStringContains(reference_counted_obj, word) then begin
                            SetLength(returnHandleType, Length(returnHandleType) + 1);
                            returnHandleType[High(returnHandleType)] := word;
                        end
                    end
                end;
            end;
            lastValidLine := i;
        end;

        i:=i+1;
    end;
    for i := Low(returnHandleType) to High(returnHandleType) do begin
        input[endglobals] := returnHandleType[i] + ' sn__' + returnHandleType[i] + #13#10 + input[endglobals];
    end;
    input[endglobals] := '//JASSHelper null local generated globals:'#13#10 + input[endglobals];
    
    if (Interf<>nil) then begin
        Interf.ProMax(ln);
        Interf.ProPosition(0);
        Interf.ProStatus('NullLocal: Writing...');
        period:= ln div UPDATEVALUE +1 ;
        nextperiod:=period;
    end;
    
    i:=0;
    while(i<ln) do begin
        if(Interf<>nil) and (i>=nextperiod) then begin
            Interf.ProPosition(i);
            nextperiod:=i+period;
        end;
        
        SWriteLn(Result,input[i]);
        i:=i+1;
    end;
    
 finally
     InlineFuncHash.Destroy;
     NoStateFunctionsHash.Destroy;
 end;


end;

procedure DoJASSerNullLocalMagicS(sinput:string; var Result:string);
var i,L,eln,period,nextperiod,k:integer;
begin

    i:=1;L:=Length(sinput);
    eln:=L div 50 + 1; //estimated ln
    SetLength(input,eln);

    Result:='ERROR';

    period:=0;nextperiod:=0;

    ln:=0;
    k:=1;


    if (Interf<>nil) then begin
        Interf.ProMax(L);
        Interf.ProPosition(0);
        Interf.ProStatus('NullLocal: Loading script...');
        period:= L div UPDATEVALUE +1 ;
        nextperiod:=period;
    end;



    while (i<=L) do begin
        if(Interf<>nil) then begin
            if(i>=nextperiod) then begin
                interf.ProPosition(i);
                nextperiod:=i+period;
            end;
        end;
        if (sinput[i]=#10) then begin
            ln:=ln+1;
            if (ln>eln) then begin
                eln:=ln+((L-i) div 25)+1;
                SetLength(input,eln);
            end;
            if ((i>1) and (sinput[i-1]=#13)) then begin
                input[ln-1]:=Copy(sinput,k,i-1-k);
                k:=i+1;
            end else begin
                input[ln-1]:=Copy(sinput,k,i-k);
                k:=i+1;
            end;
        end;

        i:=i+1;

    end;
    if (ln<2) then raise Exception.Create('Input file seems too small / unclosed string issues');

    SetLength(offset,ln);
    SetLength(textmacrotrace,ln);
    for i := 0 to ln - 1 do begin
        offset[i]:=0;
        textmacrotrace[i]:=0;
    end;


        NullLocalDo(Result);


end;

procedure DoJASSerNullLocalMagicF(const f1:string;const f2:string);
var
   ff2:textfile;
   bff2:boolean;
   i,o:string;
begin

    bff2:=false;
    try
        LoadFile(f1,i);
        DoJASSerNullLocalMagicS(i,o);

        AssignFile(ff2,f2);bff2:=true;

        filemode:=fmOpenWrite;
        Rewrite(ff2);
        Write(ff2,o);
    finally

        if(bff2) then Close(ff2);
    end;
end;

////////////////////////////////////////////////
//  ParseFunctionSignature - used by returnfixer and shadowhelper
//
//
//

var
    ParseFunctionSignature_ArgNamesBuf:TDynamicStringArray;
    ParseFunctionSignature_ArgTypesBuf:TDynamicStringArray;

procedure ParseFunctionSignature( const s:string; out constant: boolean; out name:string; out argn:integer; out returntype:string);
var
    x,y:integer;
    word:string;
begin
    GetLineWord(s, word, x);
    constant:=(word = 'constant');
    if constant then begin
        CompareLineWord('function',s, x,x);
    end;

    GetLineWord(s, name, x,x);
    CompareLineWord('takes',s,x,x);
    argn:=0;
    if not CompareLineWord('nothing',s,y,x) then begin
        //we got arguments!!111
        while(true) do begin
            GetLineToken(s,word,y,x);
            if(word='returns') then break;
            x:=y;
            if(Length(ParseFunctionSignature_ArgNamesBuf) <= argn) then begin
                SetLength(ParseFunctionSignature_ArgNamesBuf, argn+5);
                SetLength(ParseFunctionSignature_ArgTypesBuf, argn+5);
            end;
            ParseFunctionSignature_ArgTypesBuf[argn] := word;
            GetLineToken(s,ParseFunctionSignature_ArgNamesBuf[argn],x,x);
            argn:=argn+1;
        end;

    end else x:=y;
    CompareLineWord('returns',s,x,x);
    GetLineWord(s, returntype,x,x);



end;



////////////////////////////////////////////////
/// ShadowHelper begins here
///
///
var
    ShadowHelper_GlobalsHash: TStringHash;

procedure ShadowHelper_ReadGlobal(const s:string);
var
   x:integer;
   word:string;

begin
    //[constant] <type> [array] <name> [=value]

    GetLineWord(s,word,x);

    if(word='constant') then GetLineWord(s,word,x,x);
    GetLineToken(s,word,x,x);
    if(word='array') then GetLineToken(s,word,x,x);
    ShadowHelper_GlobalsHash.Add(word,1);

end;

function ShadowHelper_HelpIt(const ModHash:TstringHash; const s:string):String;
var
   tem:string;
   tok:string;
   i,j,k,L:integer;
begin
    if( (ModHash=nil) or IsWhiteSpace(s) )  then begin
         Result:=s;
         exit;
    end;
    i:=1;
    k:=0;
    L:=Length(s);

    while(i<=L+1) do begin
        if( i>L)  or (s[i] in SEPARATORS) then begin
            if(i-k > 0) then begin
                tok:=Copy(s, k+1, i-k-1);
                if( ModHash.ValueOf(tok) <> -1 ) then Swrite(tem, 'l__'+tok)
                else Swrite(tem, tok );
            end;
            k:=i;

            if(i>L) then else if( s[i] = '"' ) then begin
                j:=i+1;
                 while(j<=L) do begin
                    if(s[j]='\') then j:=j+1
                    else if(s[j]='"') then break;
                    j:=j+1;
                end;

                Swrite(tem,Copy(s,i,j-i+1) );
                i:=j;
                k:=i;
            end else if(s[i]='''') then begin
                j:=i+1;
                while(s[j]<>'''') do j:=j+1;
                Swrite(tem,Copy(s,i,j-i+1) );
                i:=j;
                k:=i;

            end else if (s[i]='/') and (i<L) and (s[i+1]='/') then begin
                Swrite(tem,Copy(s, i, L-i+1) );
                break;
            end else Swrite(tem, s[i]);

        end;
        i:=i+1;



    end;
    result:=tem;


end;


procedure ShadowHelper_HandleFunction( const fstart:integer; var Result:string);
var
    tem, lname, ltype, name,returntype: string;
    constant:boolean;
    i,argn,x:integer;
    ModHash: TStringHash;

       procedure addLocal(const s:string);
       begin
           if(ModHash = nil) then begin
               ModHash := TStringHash.create;
           end;
           ModHash.Add(s,1);
       end;
begin
   ParseFunctionSignature(input[fstart], constant, name, argn, returntype);
   ModHash:= nil;
   for i := 0 to argn - 1 do begin
       lname:=ParseFunctionSignature_ArgNamesBuf[i];
       if (ShadowHelper_GlobalsHash.ValueOf(lname ) <> -1) then
           addLocal(lname);
   end;
   if(ModHash<>nil) then begin
       if(constant) then tem:='constant function '
       else tem:='function ';
       tem:= tem+name+' takes ';
       if(argn=0) then tem:='nothing '
       else for i := 0 to argn - 1 do begin
               lname:=ParseFunctionSignature_ArgNamesBuf[i];
               ltype:=ParseFunctionSignature_ArgTypesBuf[i];
               if(ShadowHelper_GlobalsHash.ValueOf(lname) <> -1) then lname:='l__'+lname;
               if(i=0) then
                   tem:=tem+ltype+' '+lname
               else
                   tem:=tem+','+ltype+' '+lname
            end;
       tem := tem + ' returns '+returntype;
       SWriteLn(Result, tem);

   end else SWriteLn(Result, input[fstart]);

   i:=fstart + 1;
   while(true) do begin
       if(IsWhiteSpace(input[i]) ) then begin
           SWriteLn(Result, input[i]);
           input[i]:='#';
           i:=i+1;
           continue;
       end
       else if (not CompareLineWord('local', input[i], x)) then break;
       GetLineWord(input[i],ltype,x,x);
       GetLineToken(input[i],lname,x,x);
       if(lname = 'array') then begin
           ltype := ltype+' array';
           GetLineToken(input[i],lname,x,x);
       end;
       if (ShadowHelper_GlobalsHash.ValueOf(lname ) <> -1) then
           addLocal(lname);

       SWriteLn( Result, ShadowHelper_HelpIt(ModHash, input[i]) );
       input[i]:='#';
       i:=i+1;
   end;
   while(not CompareLineWord('endfunction' , input[i], x) ) do begin
        SWriteLn( Result, ShadowHelper_HelpIt(ModHash, input[i]) );
        input[i]:='#';
        i:=i+1;
   end;



   if(ModHash<>nil) then ModHash.destroy;
end;


procedure ShadowHelperDo( var Result:string);
// var inlinefunc
 var i,j,period,nextperiod:integer;
     word:string;
     printit:boolean;
     globals:boolean;

begin
nextperiod:=0;
period:=0;

 try
    if (Interf<>nil) then begin
        Interf.ProMax(ln);
        Interf.ProPosition(0);
        Interf.ProStatus('ShadowHelper: Processing...');
        period:= ln div UPDATEVALUE +1 ;
        nextperiod:=period;
    end;

    Result:='';
    // final script rumble, normalized! There are only two things we can expect, the first globals block
    // and a bunch of functions, everything else is probably a syntax error, but it might be a better idea
    // to let PJASS handle it, so we try to ignore it.

    //by this time, unclosed function/globals errors should have been caught by libraries or struct parser
    i:=0;
    globals:=false;
    ShadowHelper_GlobalsHash:= TStringHash.Create;
    while(i<ln) do begin
        if(Interf<>nil) and (i>=nextperiod) then begin
            Interf.ProPosition(i);
            nextperiod:=i+period;

        end;

        printit:=true;
        if(not IsWhitespace(input[i])) then begin
            GetLineWord(input[i],word,j);
            if(globals) then begin

                if(word='endglobals') then begin
                    globals:=false ;
                end else begin
                    ShadowHelper_ReadGlobal(input[i]);
                end;
            end else if(word='globals') then begin
                globals:=true ;
            end else begin
                //[constant] function?
                if((word='constant') and (compareLineWord('function',input[i],j,j))) or (word='function') then begin

                    ShadowHelper_HandleFunction(i, Result);
                    printit:=false;
                end;
            end;

        end;

        if(printit and (input[i]<>'#') ) then SWriteLn(Result,input[i]);
        i:=i+1;
    end;


 finally
     ShadowHelper_GlobalsHash.Destroy;
 end;


end;



procedure DoJASSerShadowHelperMagicS(sinput:string; var Result:string);
var i,L,eln,period,nextperiod,k:integer;
begin

    i:=1;L:=Length(sinput);
    eln:=L div 50 + 1; //estimated ln
    SetLength(input,eln);

    Result:='ERROR';

    period:=0;nextperiod:=0;

    ln:=0;
    k:=1;


    if (Interf<>nil) then begin
        Interf.ProMax(L);
        Interf.ProPosition(0);
        Interf.ProStatus('ShadowHelper: Loading script...');
        period:= L div UPDATEVALUE +1 ;
        nextperiod:=period;
    end;



    while (i<=L) do begin
        if(Interf<>nil) then begin
            if(i>=nextperiod) then begin
                interf.ProPosition(i);
                nextperiod:=i+period;
            end;
        end;
        if (sinput[i]=#10) then begin
            ln:=ln+1;
            if (ln>eln) then begin
                eln:=ln+((L-i) div 25)+1;
                SetLength(input,eln);
            end;
            if ((i>1) and (sinput[i-1]=#13)) then begin
                input[ln-1]:=Copy(sinput,k,i-1-k);
                k:=i+1;
            end else begin
                input[ln-1]:=Copy(sinput,k,i-k);
                k:=i+1;
            end;
        end;

        i:=i+1;

    end;
    if (ln<2) then raise Exception.Create('Input file seems too small / unclosed string issues');

    SetLength(offset,ln);
    SetLength(textmacrotrace,ln);
    for i := 0 to ln - 1 do begin
        offset[i]:=0;
        textmacrotrace[i]:=0;
    end;


    ShadowHelperDo(Result);


end;

procedure DoJASSerShadowHelperMagicF(const f1:string;const f2:string);
var
   ff2:textfile;
   bff2:boolean;
   i,o:string;
begin

    bff2:=false;
    try
        LoadFile(f1,i);
        DoJasserShadowHelperMagicS(i,o);

        AssignFile(ff2,f2);bff2:=true;

        filemode:=fmOpenWrite;
        Rewrite(ff2);
        Write(ff2,o);
    finally

        if(bff2) then Close(ff2);
    end;
end;

////////////////////////////////////////////////
// Return fixer begins here
var
    ReturnFixer_Globals: string;
    ReturnFixer_GlobalsHash: TStringHash;

//
procedure ReturnFixer_AddGlobal(const typename:string);
var
   tem:string;
begin
    if(ReturnFixer_GlobalsHash.ValueOf(typename) = -1) then begin
        ReturnFixer_GlobalsHash.Add(typename,1);
        Concatenate4(tem,'    ',typename,' rf__return_',typename);
        SWriteLn(ReturnFixer_Globals, tem);
    end;
end;

function ReturnFixer_ParseFunction( const fstart:integer; out fend:integer): boolean;
var
   constant:boolean;
   rec:boolean;
   typename:string;
   funcname,tok,tem:string;
   i,x, returncount:integer;
begin
    ParseFunctionSignature( input[fstart], constant, funcname, x, typename);
    Result := (typename <> 'nothing');
    if(not result) then exit;

    returncount := 0;

    // find end of function, count return statments, also verify it isn't recursive...
    i:=fstart + 1;
    fend:=fstart+1;
    while (i<ln) do begin

        if CompareLineWord('endfunction', input[i],x) then begin
            fend:=i;
            break;
        end;
        rec:=false;
        if    not(IsWhiteSpace(input[i]) ) then begin
          x:=1;
          while(x<=Length(input[i]) ) do begin
            GetLineToken(input[i],tok,x,x);
            if(tok ='return') then returncount:=returncount+1
            else if(tok=funcname) then rec:=true;
          end;
        end;
        if(rec) then begin
            tem:=input[i];
            input[i]:='';
            SWriteLn(input[i],tem);
            SWriteLn(input[i],'//Recursion + many return statements found, if you see a compile error in the next lines');
            SWriteLn(input[i],'//Then you should really, really fix this function as it is probably a return bug false possitive. ');
            SWriteLn(input[i],'//If you are sure it is fine, and want to be able to compile your map, disable the "return bug fix"');


        end;

        i:=i+1;
    end;
    result:= ( (fend<>-1) and (returncount>1) { and not(recursive)} );

end;

function FirstNoWhiteSpace( const s:string; const x:integer=1): integer;
begin
    Result:=x;
    while ( (Result<=Length(s)) and (s[Result] in WHITESPACE_SEPARATORS ) ) do
        Result:=Result+1;
end;

procedure ReturnFixer_FixFunction( const fstart:integer; const fend:integer; var Result:string);
var
    constant:boolean;
    argn, i, x,y,z: integer;
    name, tem, returntype,takes,arguments, word: string;
    recpattern:boolean;
begin
    ParseFunctionSignature(input[fstart], constant, name, argn, returntype);

    //Add the global:
    ReturnFixer_AddGlobal(returntype);

    //Begin by writing the returns nothing function:
    //constant will be ignored (it is useless anyway, it has always been...)
    takes:='';
    arguments:='';
    if(argn=0) then takes := 'nothing'
    else for i := 0 to argn-1 do begin
        if(i=argn-1) then begin
            Concatenate4(tem,takes,ParseFunctionSignature_ArgTypesBuf[i],' ',ParseFunctionSignature_ArgNamesBuf[i]);
            arguments:= arguments+ParseFunctionSignature_ArgNamesBuf[i];
        end else begin
            Concatenate3(tem,arguments, ParseFunctionSignature_ArgNamesBuf[i],',');
            arguments:=tem;
            Concatenate5(tem,takes,ParseFunctionSignature_ArgTypesBuf[i],' ',ParseFunctionSignature_ArgNamesBuf[i],',');
        end;
        takes := tem;
    end;
    Concatenate5(tem,'function rf__',name,' takes ', takes, ' returns nothing');
    SWriteLn(Result,tem);

    //Now write the 'fixed' contents of the function
    for i := fstart+1 to fend - 1 do  begin

        recpattern:=false;
        //recursion pattern A:
        // set foo = funcname(...
        if CompareLineWord('set', input[i], y) then begin
             GetLineToken(input[i], word, y,y);
             y:=FirstNoWhiteSpace(input[i],y);
             if (y<=Length(input[i])) and (input[i][y]='=') and CompareLineToken(name,input[i],z,y) then begin
                 recpattern:= true;
                 SWriteLn(Result, 'call rf__'+Copy(input[i],z-Length(name), Length(input[i]) ) );
                 SWriteLn(Result, 'set '+word+'=rf__return_'+returntype);
             end;
        end;

        //recursion pattern B:
        // call funcname(...
        if CompareLineWord('call', input[i], y) then begin
             if (y<=Length(input[i])) and CompareLineToken(name,input[i],z,y) then begin
                 recpattern:= true;
                 SWriteLn(Result, 'call rf__'+Copy(input[i],z-Length(name), Length(input[i]) ) );
             end;
        end;

        //recursion pattern C:
        // return funcname(...
        if CompareLineWord('return', input[i], y) then begin
             if (y<=Length(input[i])) and CompareLineToken(name,input[i],z,y) then begin
                 recpattern:= true;
                 SWriteLn(Result, 'call rf__'+Copy(input[i],z-Length(name), Length(input[i]) ) );
                 SWriteLn(Result, 'return');
             end;
        end;



        if(recpattern) then
        else if(   not(IsWhiteSpace(input[i]) ) and CompareLineToken('return', input[i], x) ) then begin
            Concatenate4(tem,'set rf__return_',returntype,'=', Copy(input[i],x, Length(input[i])-x+1));
            SWriteLn(Result, tem);
            SWriteLn(Result, 'return');
        end else SWriteLn(Result, input[i]);
    end;

    SWriteLn(Result, 'endfunction');

    // Replace the function's contents with #
    for i := fstart to fend do input[i]:='#';

    // Write a dummy function:
    Concatenate6(tem,'function ',name,' takes ', takes, ' returns ', returntype);
    SWriteLn(Result,tem);
    Concatenate5(tem,'    call rf__',name,'(', arguments, ')');
    SWriteLn(Result,tem);
    SWriteLn(Result,'    return rf__return_'+returntype);
    SWriteLn(Result,'endfunction');

    //


end;

procedure ReturnFixer_HandleFunction( const fstart: integer; var Result:string);
 var
    fend:integer;

begin
    //Parse the function, should we do it?
    if (  ReturnFixer_ParseFunction(fstart, fend) ) then
        ReturnFixer_FixFunction(fstart, fend, Result);



end;

procedure ReturnFixDo( var Result:string);
// var inlinefunc
 var i,j,period,nextperiod:integer;
     tem,word, insideGlobals:string;
     printit:boolean;
     globals:boolean;

begin
nextperiod:=0;
period:=0;

 try
    if (Interf<>nil) then begin
        Interf.ProMax(ln);
        Interf.ProPosition(0);
        Interf.ProStatus('Return fixer: Processing...');
        period:= ln div UPDATEVALUE +1 ;
        nextperiod:=period;
    end;

    Result:='';
    // final script rumble, normalized! There are only two things we can expect, the first globals block
    // and a bunch of functions, everything else is probably a syntax error, but it might be a better idea
    // to let PJASS handle it, so we try to ignore it.

    //by this time, unclosed function/globals errors should have been caught by libraries or struct parser
    i:=0;
    globals:=false;
    insideglobals:='';
    ReturnFixer_GlobalsHash:= TStringHash.Create;
    while(i<ln) do begin
        if(Interf<>nil) and (i>=nextperiod) then begin
            Interf.ProPosition(i);
            nextperiod:=i+period;

        end;

        printit:=true;
        if(not IsWhitespace(input[i])) then begin
            GetLineWord(input[i],word,j);
            if(globals) then begin
                printit:=false;
                if(word='endglobals') then globals:=false
                else SWriteLn(InsideGlobals, input[i]);
            end else if(word='globals') then begin
                globals:=true ;
                printit:=false;
            end
            else begin
                //[constant] function?
                if((word='constant') and (compareLineWord('function',input[i],j,j))) or (word='function') then begin
                    ReturnFixer_HandleFunction(i, Result);
            //        printit:=false;
                    //input[i] := input[i];
                    //inline_handle_function(i,Result);
                end;
            end;

        end;

        if(printit and (input[i]<>'#') ) then SWriteLn(Result,input[i]);
        i:=i+1;
    end;
    tem := '';
    SWriteLn(tem, 'globals');
    SWriteLn(tem, insideglobals);
    SWriteLn(tem, ReturnFixer_Globals);
    SWriteLn(tem, 'endglobals');
    SWriteLn(tem, Result);
    Result:=tem;


 finally
     ReturnFixer_GlobalsHash.Destroy;
 end;


end;



procedure DoJASSerReturnFixMagicS(sinput:string; var Result:string);
var i,L,eln,period,nextperiod,k:integer;
begin

    i:=1;L:=Length(sinput);
    eln:=L div 50 + 1; //estimated ln
    SetLength(input,eln);

    Result:='ERROR';

    period:=0;nextperiod:=0;

    ln:=0;
    k:=1;


    if (Interf<>nil) then begin
        Interf.ProMax(L);
        Interf.ProPosition(0);
        Interf.ProStatus('Return fixer: Loading script...');
        period:= L div UPDATEVALUE +1 ;
        nextperiod:=period;
    end;



    while (i<=L) do begin
        if(Interf<>nil) then begin
            if(i>=nextperiod) then begin
                interf.ProPosition(i);
                nextperiod:=i+period;
            end;
        end;
        if (sinput[i]=#10) then begin
            ln:=ln+1;
            if (ln>eln) then begin
                eln:=ln+((L-i) div 25)+1;
                SetLength(input,eln);
            end;
            if ((i>1) and (sinput[i-1]=#13)) then begin
                input[ln-1]:=Copy(sinput,k,i-1-k);
                k:=i+1;
            end else begin
                input[ln-1]:=Copy(sinput,k,i-k);
                k:=i+1;
            end;
        end;

        i:=i+1;

    end;
    if (ln<2) then raise Exception.Create('Input file seems too small / unclosed string issues');

    SetLength(offset,ln);
    SetLength(textmacrotrace,ln);
    for i := 0 to ln - 1 do begin
        offset[i]:=0;
        textmacrotrace[i]:=0;
    end;


    ReturnFixDo(Result);


end;

procedure DoJASSerReturnFixMagicF(const f1:string;const f2:string);
var
   ff2:textfile;
   bff2:boolean;
   i,o:string;
begin

    bff2:=false;
    try
        LoadFile(f1,i);
        DoJasserReturnFixMagicS(i,o);

        AssignFile(ff2,f2);bff2:=true;

        filemode:=fmOpenWrite;
        Rewrite(ff2);
        Write(ff2,o);
    finally

        if(bff2) then Close(ff2);
    end;
end;

//=============================================================================
// Code blocks magic!!111
const CONDBLOCKS_MAXDEPTH: integer = 50;
var CondBlocks_CurrentStruct: string='';
var
    CondBlocks_ConstantsHash: TStringHash;
    CondBlocks_Stack: array[0 .. 50{CONDBLOCKS_MAXDEPTH}] of integer;

procedure CondBlocks_ReadGlobal(const s:string; linenum:integer );
var
   x:integer;
   word, value:string;

begin
    //[constant] <type> [array] <name> [=value]
    if(CompareLineWord('constant', s, x) and CompareLineWord('boolean', s, x,x) ) then begin
        GetLineToken(s,word,x,x);
        if( not GetAssigment( s, value, x) ) then begin
            raise JasserLineException(linenum,'Expected: Assignment');
        end;
        value:= Trim(value);
        if( (value<>'true') and (value<>'false') and ValidIdentifierName(value) ) then begin
            x:=CondBlocks_ConstantsHash.ValueOf(value);
            if(x=0) then value:='false'
            else if(x=1) then value :='true';
        end;
        if(value='false') then
            CondBlocks_ConstantsHash.add(word,0)
        else if (value='true') then
            CondBlocks_ConstantsHash.add(word,1);
    end;
end;

procedure CondBlocks_ReadMethodExistence( const s:string; const sname:string; linenum:integer; const nstart:integer; const priv:boolean);
var
    name:string;
    i:integer;
begin
    GetLineWord(s,name,i, nstart);
    CondBlocks_ConstantsHash.add(sname+'@'+name+'.exists',1);
    if(not priv) then
        CondBlocks_ConstantsHash.add(sname+'.'+name+'.exists',1);
end;


procedure CondBlocks_ReadStaticMember(const s:string; const sname: string; linenum:integer );
var
   x:integer;
   word, value:string;
   priv:boolean;

begin
    //[constant] <type> [array] <name> [=value]
    x:=1;
    GetLineWord(s,word,x,x);
    priv:=false;
    if ( (word = 'private') or (word='public') ) then begin
        priv := (word = 'private');
        GetLineWord(s,word,x,x);
    end;

    if (word='static') and (CompareLineWord('constant', s, x,x) and CompareLineWord('boolean', s, x,x) ) then begin
        GetLineToken(s,word,x,x);
        if( not GetAssigment( s, value, x) ) then begin
            raise JasserLineException(linenum,'Expected: Assignment');
        end;
        value:= Trim(value);
        if( (value<>'true') and (value<>'false') and ValidIdentifierName(value) ) then begin
            x:=CondBlocks_ConstantsHash.ValueOf(value);
            if(x=0) then value:='false'
            else if(x=1) then value :='true';
        end;
        if(value='false') then
            CondBlocks_ConstantsHash.add(sname+'@'+word,0)
        else if (value='true') then
            CondBlocks_ConstantsHash.add(sname+'@'+word,1);
        if(not priv) then begin
            if(value='false') then
               CondBlocks_ConstantsHash.add(sname+'.'+word,0)
            else if (value='true') then
                CondBlocks_ConstantsHash.add(sname+'.'+word,1);
        end;

    end;
end;


function CondBlocks_AcceptedBlock(const s:string; const linenum:integer; const start:integer):boolean;
var
   x,y, len:integer;
   nt, reqvalue:boolean;
   reqname,word, reqmember, reqmembermember:string;
begin

    //parse the requirement list :( this is hard :(
    len:=Length(s);
    Result:=true;
    x:=start;
    while(true) do begin
        GetLineWord(s,reqname,x,x);
        nt := (reqname='not');
        if(nt) then begin
             GetLineWord(s,reqname,x,x);
        end;
        reqmember:='';
        reqmembermember:='';
        for y := 1 to Length(reqname) do
            if(reqname[y]='.') then begin
                reqmember:=Copy(reqname,y+1, Length(reqname));
                reqname:=Copy(reqname,1, y-1);
                break;
            end;
        if(reqmember<>'') then
          for y := 1 to Length(reqmember) do
            if(reqmember[y]='.') then begin
                reqmembermember:=Copy(reqmember,y+1, Length(reqmember));
                reqmember:=Copy(reqmember,1, y-1);
                break;
            end;
        if( (reqmembermember<>'') and (reqmembermember<>'exists') ) then
             raise JasserLineException(linenum,'Oexists is supported so far.');
        if(reqmember<>'') then begin
            if( (reqname='') or not(ValidIdentifierName(reqname) ) or (not ValidIdentifierName(reqmember) ) )  then
                raise JasserLineException(linenum,'Expected: not, library name or constant boolean name but got "'+reqname+'.'+reqmember+'" instead');
        end else begin
            if (reqname='') or not(ValidIdentifierName(reqname) ) then
                raise JasserLineException(linenum,'Expected: not, library name or constant boolean name but got "'+reqname+'.'+reqmember+'" instead');
        end;

        if(reqmembermember<>'') then
            reqmember:=reqmember+'.'+reqmembermember;

        if(reqmember<>'') then begin
            if(reqname = CondBlocks_CurrentStruct ) then begin
                reqname:=reqname+'@'+reqmember;
            end else begin
                reqname:=reqname+'.'+reqmember;
            end;
        end;

        if( reqname='true') then
            reqvalue:=true
        else if(reqname='false') then
            reqvalue:=false
        else if(reqname='DEBUG_MODE') then begin
            reqvalue:=DEBUG_MODE;
        end else begin
            reqvalue:=(CondBlocks_ConstantsHash.ValueOf(reqname)=1);
        end;
        if(reqvalue <> not nt) then Result:=false;

        GetLineWord(s,word,x,x);
        if(word = '') or (word='then' ) then begin

            if(not IsWhiteSpace(s,x) ) then
                raise JasserLineException(linenum,'Unexpected: '+Copy(s,x,len-x+1) );
            if( word='' ) then
                raise JasserLineException(linenum,'Expected: "then" ');

            break;
        end else if(word<>'and') then begin
            raise JasserLineException(linenum,'Unexpected: '+word );
        end;


    end;

end;

procedure DoJasserBlocksMagic;
// var inlinefunc
 var i,j,k,x,siz,period,nextperiod:integer;
     word,redo:string;
     printit, priv:boolean;
     globals:boolean;
     structname:string;
     label MEH;


     procedure verifySupported(const s:string; const lin:integer);
      var
         i:integer;
     begin
         for i := 0 to  Length(s) do begin
             //beware of comments
             if (s[i] = '/') and (i<Length(s)) and (s[i+1] = '/') then
                 break;
             if(s[i] in SEPARATORS) and not(S[i] in [' ',#9,'.'] ) then
                 raise JasserLineException(lin,'Unexpected: "'+s[i]+'"');
         end;

     end;

begin
nextperiod:=0;
period:=0;

 try
    if (Interf<>nil) then begin
        Interf.ProMax(ln);
        Interf.ProPosition(0);
        Interf.ProStatus('Conditional Blocks: Processing...');
        period:= ln div UPDATEVALUE +1 ;
        nextperiod:=period;
    end;
    i:=0;
    globals:=false;
    structname:='';
    CondBlocks_CurrentStruct:=structname;
    CondBlocks_ConstantsHash:= TStringHash.Create;

    siz:=0;
    while(i<ln) do begin
        if(Interf<>nil) and (i>=nextperiod) then begin
            Interf.ProPosition(i);
            nextperiod:=i+period;

        end;

        if( (siz>0) and (CondBlocks_Stack[siz-1]<0) ) then
            printit:=false
        else
            printit:=true;

        if(not IsWhitespace(input[i])) then begin
            GetLineToken(input[i],word,j);
            if(globals) then begin

                if(word='endglobals') then begin
                    globals:=false ;
                end else begin
                    CondBlocks_ReadGlobal(input[i], i);
                end;
            end else if(word='struct') then begin
                GetLineToken(input[i],structname,j,j);
                CondBlocks_CurrentStruct:=structname;
            end else if(word='endstruct') then begin
                structname:='';
                CondBlocks_CurrentStruct:=structname;
            end else if(word='globals') then begin
                globals:=true ;
            end else if (structname<>'') then begin
                //This code will come back and haunt me.
                redo := word;
                k:=j;
                priv := (word='private');
                if priv or (word='public') then
                    GetLineWord(input[i], word, k,k);

                if (word='static')  then begin
                    GetLineWord(input[i], word, k, k );
                    if (word = 'constant') then begin
                        GetLineWord(input[i], word, k, k );
                        if word='boolean' then
                            CondBlocks_ReadStaticMember(input[i],structname, i)
                        else if word = 'method' then
                            CondBlocks_ReadMethodExistence(input[i],structname, i,k, priv);
                    end else if (word='method') then
                        CondBlocks_ReadMethodExistence(input[i],structname, i,k, priv);

                end else  if (word='method') then begin
                    CondBlocks_ReadMethodExistence(input[i],structname, i,k, priv);

                end else if(word ='constant') then begin
                    GetLineWord(input[i], word, k, k );
                    if( word ='method') then
                         CondBlocks_ReadMethodExistence(input[i],structname, i,k, priv);
                end;
                word:=redo;
                goto MEH;


            end else begin
                MEH:

                //-2 : static, remove
                //-1 : non-static, remove
                // 1 : non-static, keep
                // 2 : static, keep

                //block start/end?
                if(word='static') and CompareLineToken('if',input[i],j,j) then begin
                    input[i]:=StringReplace(input[i],'(',' ',[]);
                    input[i]:=StringReplace(input[i],')',' ',[]);
                    VerifySupported(input[i],i);

                    if(siz= CondBlocks_MAXDEPTH ) then
                        raise JasserLineException(i, 'Too many nested ifs (Max is '+IntToStr(siz) +')' );
                    if CondBlocks_AcceptedBlock(input[i],i,j) and ( (siz=0) or (CondBlocks_Stack[siz-1]>0) ) then
                        CondBlocks_Stack[siz] := 2
                    else
                        CondBlocks_Stack[siz] := -2;
                    siz:=siz+1;
                    printit:=false;
                end else if(word='elseif') then begin
                    if(siz=0) then
                        raise JasserLineException(i,'Unexpected: elseif');
                    if (CondBlocks_Stack[siz-1] =2) or (CondBlocks_Stack[siz-1] =-2) then begin
                        if( CondBlocks_Stack[siz-1] = 2 ) then begin
                            CondBlocks_Stack[siz-1] := -3;
                        end else if( CondBlocks_Stack[siz-1] = -2 ) then begin
                            input[i]:=StringReplace(input[i],'(',' ',[]);
                            input[i]:=StringReplace(input[i],')',' ',[]);
                            VerifySupported(input[i],i);
                            if CondBlocks_AcceptedBlock(input[i],i,j) and ( (siz<=1) or (CondBlocks_Stack[siz-2]>0) ) then begin
                                CondBlocks_Stack[siz-1] := 2
                            end else begin
                                CondBlocks_Stack[siz-1] := -2;
                            end;

                        end;
                        printit:=false;
                    end else begin
                        //do not change the stack's content...
                    end;

                end else if(word='else') then begin
                    if(siz=0) then
                        raise JasserLineException(i,'Unexpected: elseif');
                    if (CondBlocks_Stack[siz-1] =2) or (CondBlocks_Stack[siz-1] =-2) then begin
                        x:=1;
                        if(siz>1) then
                            x:=CondBlocks_Stack[siz-2];
                        if (x>=0) then
                            CondBlocks_Stack[siz-1]:=CondBlocks_Stack[siz-1]*-1;
                        printit:=false;

                    end;



                end else if(word='if') then begin
                    if(siz= CondBlocks_MAXDEPTH ) then
                        raise JasserLineException(i, 'Too many nested ifs (Max is '+IntToStr(siz) +')' );
                    if(not printit) then
                        CondBlocks_Stack[siz]:=-1
                    else
                        CondBlocks_Stack[siz]:=1;
                    siz:=siz+1;
                end else if (word='endif') then begin
                    if(siz=0) then raise JasserLineException(i, 'Unexpected: endif');
                    siz:=siz-1;
                    if(CondBlocks_Stack[siz]=2) or (CondBlocks_Stack[siz]=-2) then
                        printit:=false;
                end;

            end;

        end;

        if(printit and (input[i]<>'#') ) then begin
            if DEBUG_MODE then begin
                k:=0;
                for j := 0 to siz - 1 do
                     if(CondBlocks_Stack[j]=2) or ( CondBLocks_Stack[j]=-2) then
                         k:=k+1;
                if(k>0)then
                    input[i]:='    '+input[i]
            end else
                input[i]:=input[i];

        end else begin
            if(DEBUG_MODE) then
                input[i]:='//# '+input[i]
            else
                input[i]:='';
        end;
        i:=i+1;
    end;
    if(siz<>0) then raise JasserLineException(i, 'Missing: endblock');


 finally
     CondBlocks_ConstantsHash.Destroy;
 end;


end;



//==================================
// Zinc Magic!
procedure ProcessZinc(const debug:boolean);
var
    i,j,k,x:integer;
    word:string;
    output:Array of string;
    source,trace: Array of integer;
    outn: integer;

    procedure writeOutput(const s:string; const from:integer);
    begin
        if( Length(output) <= outn ) then begin
            SetLength(output, outn+1+outn div 5);
            SetLength(source, Length(output) );
        end;
        output[outn]:=s;
        source[outn]:= from;
        outn:=outn+1;
    end;
    {$ifdef ZINC_DEBUG}
    procedure writeDebugOutput;
      var
         f: textfile;
         i:integer;
    begin
        AssignFile(f,'logs/zincoutput.j');
        filemode:=fmOpenWrite;
        Rewrite(f);
        for i := 0 to outn - 1 do
            WriteLn(f, output[i]);
        CloseFile(f);



    end;
    {$endif}


begin
    i:=0;

    outn:=0;
    SetLength(output,ln);
    SetLength(source,ln);
    if(interf<>nil) then begin
        interf.ProStatus('Zinc...');
    end;

    while(i<ln) do begin
        if(CompareLineWord('//!',input[i],x)  ) or (ZINC_MODE and (i=0) ) then begin
            GetLineWord(input[i], word, x,x);
            if(word='zinc')  or (ZINC_MODE and (i=0) ) then begin
                ZincParser.ResetInput;
                ZincParser.Debug_Mode:= debug;
                if(ZINC_MODE) then ZincParser.AddInputLine(input[i]);
                j:=i;
                i:=i+1;
                while(i<ln) do begin

                    if  (ZINC_MODE and (j=0) ) then
                    else if(CompareLineWord('//!',input[i],x) ) then begin
                        GetLineWord(input[i], word, x,x);
                        if(word='zinc') then
                            raise JasserLineDoubleException(i,'Nested //! zinc', j, 'First called here')
                        else if(word='endzinc') then
                            break;
                    end;
                    ZincParser.AddInputLine(input[i]);
                    i:=i+1;
                end;
                if(i=ln) and not ZINC_MODE then
                     raise JasserLineException(i,'Missing //! endzinc');


                try
                    ZincParser.Parse;
                except
                    on e: ZincSyntaxError do begin
                        raise JasserLineException(j+e.linen, e.msg);
                    end;

                end;
                for k := 0 to ZincParser.GetOutputLineCount-1 do
                    WriteOutput(ZincParser.GetOutputLine(k) , ZincParser.GetOutputLineSource(k)+j );

            end else if(word='endzinc') then begin
                raise JasserLineException(i,'Unexpected: //! endzinc');
            end else
                WriteOutput(input[i], i);

        end else WriteOutput(input[i], i);
        i:=i+1;
    end;
    ln:=outn;
    SetLength(trace,ln);
    for i := 0 to ln - 1 do begin
        trace[i]:=textmacrotrace[source[i]];
        source[i]:=source[i]+offset[source[i]];

    end;

    {$ifdef ZINC_DEBUG}
        WriteDebugOutput;
    {$endif}
    SetLength(input, ln);
    SetLength(offset, ln);
    SetLength(textmacrotrace, ln);
    for i := 0 to ln - 1 do begin
        input[i]:=output[i];
        offset[i]:=source[i]-i;
        textmacrotrace[i]:=trace[i];
    end;


end;



end.


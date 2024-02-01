unit zincparser;
interface
uses SysUtils, Classes, Windows,
     Jasshelper, GrammarReader, GOLDParser, Symbol, Token, ZincSymbols;

procedure ResetInput;
procedure Parse;
procedure AddInputLine(const s:string);
function  GetOutputLineCount:integer;
function  GetOutputLine(const i:integer):string;
function  GetOutputLineSource(const i:integer):integer;

type
   ZincSyntaxError = class(Exception)
   private

   public
      linen:integer;
      msg:string;
   end;

var
  GRAMMAR_PATH:string='zinc.cgt';
  DEBUG_MODE:boolean=false;

 

implementation

var
   ln: integer;
   anoncount:integer;
   input: array of string;
   inputcomment: array of string;
   oln: integer;
   output: array of string;
   outputfrom: array of integer;
   Parser:TGoldParser=nil;

type TAccessModifier = ( ACCESS_PRIVATE, ACCESS_PUBLIC, ACCESS_DEFAULT );


//=====================
function TranslateTerminal(tok:Ttoken):string;
begin
    while(tok.kind = SymbolTypeNonTerminal) do begin
        if(tok.Reduction.TokenCount=0) then begin
            result:='';
            exit;
        end;
        tok:=tok.Reduction.Tokens[0];
    end;
    result:=tok.DataVar;
end;

//======
function ZincLineError( const i:integer;  const msg:string):ZincSyntaxError;
begin
    Result:=ZincSyntaxError.create('Syntax error');
    Result.linen:=i;
    Result.msg:=msg;
end;
function TokenLine1(tok:TToken):integer;
begin
    while(tok.kind = SymbolTypeNonTerminal) do begin
        if(tok.Reduction.TokenCount = 0) then break;
        tok:=tok.Reduction.Tokens[0];
    end;
    Result:=Tok.linenumber;
end;
function TokenLine2(tok:TToken):integer;
begin
    while(tok.kind = SymbolTypeNonTerminal) do begin
        if(tok.Reduction.TokenCount = 0) then break;
        tok:=tok.Reduction.Tokens[ tok.Reduction.TokenCount-1];
    end;
    Result:=Tok.linenumber;
end;


//=====================
function TranslateExpressionNot(tok:Ttoken):string; forward;
function TranslateExpression(tok:Ttoken):string;
var
    red:Treduction;
    i:integer;

    function join(const s1:string; const s2: string):string;
    begin
        if(  (Length(s1)=0) or (s1[Length(s1)] in Jasshelper.SEPARATORS)
           or(Length(s2)=0) or (s2[1] in Jasshelper.SEPARATORS) ) then
              Result:=s1+s2
        else
              Result:=s1+' '+s2;

    end;

begin
    if(tok.kind <> SymbolTypeNonTerminal) then begin
        result:=tok.DataVar;
        exit;
    end;
    result:='-possible error-';

    //place holder
    red:=tok.Reduction;
    case RuleConstants(Red.ParentRule.TableIndex) of
        RULE_PARENTHESIS_LPARAN_RPARAN: begin
        (* <Parenthesis> ::= ( <Expression> ) *)
//            Concatenate3(result,'(',TranslateExpression(red.Tokens[1]),')' );
            Concatenate3(result, '(',TranslateExpression(red.Tokens[1]),')');
        end;
        RULE_LOGICALBINARYOPERATOR_AMPAMP: begin
        (* <LogicalBinaryOperator> ::= && *)
            result:=' and ';
        end;
        RULE_LOGICALBINARYOPERATOR_PIPEPIPE: begin
        (* <LogicalBinaryOperator> ::= || *)
            result:=' or ';
        end;
        RULE_NOT_EXCLAM: begin
        (* <Not> ::= ! <Expression8> *)
            result:=TranslateExpressionNot(red.Tokens[1]);
        end;
        RULE_CODEVALUE_STATIC_METHOD_IDENTIFIER_DOT_IDENTIFIER: begin
        (* <CodeValue> ::= static method Identifier . Identifier *)
            Concatenate4(result,'function ',TranslateTerminal(red.Tokens[2]),'.',TranslateTerminal(red.Tokens[4]))
        end;

        RULE_STATICIFREQUIREMENTNOT_EXCLAM: begin
        (* <StaticIfRequirementNot> ::= ! *)
            result:='not';
        end;
        RULE_STATICIFEXPRESSION_AMPAMP: begin
        (* <StaticIfExpression> ::= <StaticIfExpression> && <StaticIfRequirement> *)
            Concatenate3(result,
                               TranslateExpression( red.Tokens[0]),
                               ' and ',
                                TranslateExpression(red.Tokens[2])
                        );
        end;
        RULE_ANONYMOUSFUNCTION_LPARAN_RPARAN: begin
        (* <AnonymousFunction> ::= <AnonymousTag> ( <FunctionArgumentList> ) <ReturnType> <CodeBlock> *)
            Result:=tok.DataVar;
        end
        else begin
            Result:='';
            for i := 0 to red.tokenCount - 1 do begin
                Result:=join(result, TranslateExpression(red.Tokens[i]) );
            end;

        end;

    end;

end;


function TranslateExpressionNot(tok:Ttoken):string;
var
    red:Treduction;
    tem:string;
begin
    if(tok.kind <> SymbolTypeNonTerminal) then begin
        if     (tok.DataVar ='true') then result:='false'
        else if(tok.DataVar ='false') then result:='true'
        else    result:='not '+tok.DataVar;
        exit;
    end;
    result:='-possible error-';

    //place holder
    red:=tok.Reduction;
    case RuleConstants(Red.ParentRule.TableIndex) of
        RULE_PARENTHESIS_LPARAN_RPARAN: begin
        (* <Parenthesis> ::= ( <Expression> ) *)
            //ncatenate3(result,'(',TranslateExpressionNot(red.Tokens[1]),')' );
            Concatenate3(result, '(',TranslateExpressionNot(red.Tokens[1]),')');
        end;
        RULE_RELATION, (* <Relation> ::= <Expression4> <RelationOperator> <Expression4> *)
        RULE_COMPARISSON: (* <Comparisson> ::= <Expression3> <ComparissonOperator> <Expression3> *)
        begin
            tem:=TranslateExpression(red.Tokens[1]);
            if     (tem='>') then tem:='<='
            else if(tem='<') then tem:='>='
            else if(tem='<=') then tem:='>'
            else if(tem='>=') then tem:='<'
            else if(tem='==') then tem:='!='
            else if(tem='!=') then tem:='==';
            Concatenate3(result, TranslateExpression(red.Tokens[0]),
                                 tem,
                                 TranslateExpression(red.Tokens[2]) );

        end;
        RULE_NOT_EXCLAM: begin
        (* <Not> ::= ! <Expression8> *)
            Result:=TranslateExpression(red.Tokens[1]);
        end;
        RULE_EXPRESSION9,  (* <Expression> ::= <Expression2> *)
        RULE_EXPRESSION22, (* <Expression2> ::= <Expression3> *)
        RULE_EXPRESSION32, (* <Expression3> ::= <Expression4> *)
        RULE_EXPRESSION42, (* <Expression4> ::= <Expression5> *)
        RULE_EXPRESSION52, (* <Expression5> ::= <Expression6> *)
        RULE_EXPRESSION62, (* <Expression6> ::= <Expression7> *)
        RULE_EXPRESSION72: (* <Expression7> ::= <Expression8> *)
            result:=TranslateExpressionNot(red.Tokens[0]);
        else begin
            if(red.TokenCount=1) then begin
                result:=TranslateExpressionNot(red.Tokens[0]);
            end else begin
                Concatenate3(result, 'not (',TranslateExpression(tok),')');
            end;
        end;

    end;

end;


function TranslatePublicPrivate(const tok:Ttoken; const def:TAccessModifier= ACCESS_DEFAULT): TAccessModifier;
var s:string;
begin
    s:=TranslateTerminal(tok);
    if(s='private') then Result:=ACCESS_PRIVATE
    else if(s='public') then Result:=ACCESS_PUBLIC
    else Result:=def;
end;

function TranslateReturnType(const tok:Ttoken): string;
var red:Treduction;
begin
   red:=Tok.Reduction;
   result:='**error';
   case RuleConstants(Red.ParentRule.TableIndex) of
       RULE_RETURNTYPE: begin
       (* <ReturnType> ::=  *)
            Result:='nothing';
       end;
       RULE_RETURNTYPE_MINUSGT: begin
       (* <ReturnType> ::= -> <Type> *)
            Result:=TranslateTerminal( red.Tokens[1]);
       end;

   end;
end;



var
   indent_str: array of string;
procedure WriteOutputLine(const s:string; const from:integer = 1; const indent:integer=0);
var x:integer;
begin
    if(Length(indent_str) <= indent+1) then begin
        x:=Length(indent_str);
        SetLength(indent_str, indent+5);
        while(x<Length(indent_str)) do begin
            indent_str[x]:=StringOfChar(' ',x*4);
            x:=x+1;
        end;
    end;
    if(Length(output)<=oln) then begin
        SetLength(output,oln+20+oln div 5);
        SetLength(outputfrom, Length(output) );
    end;
    output[oln]:=indent_str[indent]+s;
    outputfrom[oln]:=from;
    oln:=oln+1;

end;


//--------
function TranslateFunctionArgumentList(const tok:Ttoken):string;
 var
   red:Treduction;
       function TranslateArgDef(const tok:ttoken): string;
        var
            red:Treduction;
       begin
          red:=tok.Reduction;
          case RuleConstants(Red.ParentRule.TableIndex) of
             RULE_ARGUMENTDEFAULT_EQ: begin
            (* <ArgumentDefault> ::= = <Expression> *)
                 Concatenate3(Result,' defaults ', TranslateExpression(red.Tokens[1]), ' ');
             end;
             RULE_ARGUMENTDEFAULT: (* <ArgumentDefault> ::=  *) begin
                 result:='';
             end;
          end;

       end;

       function TranslateArgument(const tok:ttoken): string;
        var
            red:Treduction;
       begin
           (* <FunctionArgument> ::= <Type> Identifier <ArgumentDefault> *)
           red:=tok.Reduction;
           Concatenate4(result, TranslateTerminal(red.Tokens[0]),' ',
                                TranslateTerminal(red.Tokens[1]),
                                TranslateArgDef(red.Tokens[2]) );



       end;

begin
    red:=tok.Reduction;
    case RuleConstants(Red.ParentRule.TableIndex) of
        RULE_FUNCTIONARGUMENTLIST: begin
        (* <FunctionArgumentList> ::= <FunctionArgument> *)
            result:=TranslateArgument(red.Tokens[0]);
        end;
        RULE_FUNCTIONARGUMENTLIST_COMMA: begin
        (* <FunctionArgumentList> ::= <FunctionArgument> , <FunctionArgumentList> *)
            Concatenate3( result, TranslateArgument(red.Tokens[0]), ',', TranslateFunctionArgumentList(red.Tokens[2]) );

        end;
        RULE_FUNCTIONARGUMENTLIST2: begin
        (* <FunctionArgumentList> ::=  *)
            result:='nothing';
        end;
    end;

end;

//--------------------------
// Code block stuff!
//
var AllowLocals:boolean= false;

procedure TranslateStatementOrBlock( const tok:ttoken; const indent:integer=0);forward;
procedure TranslateAssignments( const tok:ttoken; const indent:integer=0);forward;
procedure TranslateCodeBlock( const tok:ttoken; const indent:integer=0);forward;
procedure TranslateStatement(tok:Ttoken; const indent:integer=0);forward;


procedure TranslateDebug( const tok:ttoken; const indent:integer=0);
begin
(* <Debug> ::= debug <StatementOrBlock> *)
    if(DEBUG_MODE) then begin
       WriteOutPutLine('//Debug:', TokenLine1(tok), indent);
       TranslateStatementOrBlock(tok.Reduction.Tokens[1], indent+1);
    end;
end;

procedure TranslateWhile( const tok:ttoken; const indent:integer=0);
var
   red:Treduction;
   cond:string;
begin
(* <While> ::= while <Parenthesis> <StatementOrBlock> *)
    AllowLocals:=false;
    red:=tok.Reduction;
    cond:=TranslateExpressionNot(red.Tokens[1]);

    WriteOutputLine('loop', TokenLine1(tok),indent);
    if(cond<>'(false)') then
        WriteOutputLine('exitwhen '+cond, TokenLine1(tok),indent);
    TranslateStatementOrBlock( red.Tokens[2], indent+1);
    WriteOutputLine('endloop', TokenLine2(tok),indent);
end;

procedure TranslateDoWhile( const tok:ttoken; const indent:integer=0);
var
   red:Treduction;
   cond:string;
begin
(* <DoWhile> ::= do <StatementOrBlock> while <Parenthesis> ; *)
    AllowLocals:=false;
    red:=tok.Reduction;

    WriteOutputLine('loop', TokenLine1(tok),indent);
    TranslateStatementOrBlock( red.Tokens[1], indent+1);
    cond:=TranslateExpressionNot(red.Tokens[3]);
    if(cond<>'(false)') then
        WriteOutputLine('exitwhen '+cond, TokenLine1(tok),indent);

    WriteOutputLine('endloop', TokenLine2(tok),indent);
end;


//** This is it, time to code the whole For feature...
procedure TranslateFor( const tok:ttoken; const indent:integer=0);
var
   red:Treduction;
   x:integer;
   tem, vr, c1, c2, start, inc:string;
      function opos(const s:string): string;
      begin
          if     (s='>') then result:='<='
          else if(s='<') then result:='>='
          else if(s='>=') then result:='<'
          else                result:='>';
      end;

begin
{
    <=
     <
    >=
    >
}
    AllowLocals:=false;

(* <For> ::= for ( <Expression4> <RelationOperator> <Variable> <RelationOperator> <Expression4> ) <StatementOrBlock> *)
    red:=tok.Reduction;
    c1:= TranslateTerminal(red.Tokens[3]);
    c2:= TranslateTerminal(red.Tokens[5]);
    if(c1[1] <> c2[1] ) then
        raise ZincLineError(TokenLine1(red.Tokens[5]), 'for requires the direction of both relational operators to be the same.');
    vr:=TranslateTerminal(red.Tokens[4]);
    if(c1[1]='<') then begin
        //asc
        if(Length(c1)=2) then //inclusive
            start:=TranslateExpression(red.Tokens[2])
        else
            start:='('+TranslateExpression(red.Tokens[2])+')+1';
        inc:='+';

    end else begin
        //dsc
        if(Length(c1)=2) then //inclusive
            start:=TranslateExpression(red.Tokens[2])
        else
            start:='('+TranslateExpression(red.Tokens[2])+')-1';
        inc:='-';
    end;
    x:=TokenLine1(tok);
    Concatenate4(tem, 'set ',vr,'=',start);
    WriteOutputLine(tem, x, indent);
    WriteOutputLine('loop', x, indent);
    Concatenate5(tem,'exitwhen (',vr,opos(c2), TranslateExpression(red.Tokens[6]) ,')');
    WriteOutputLine(tem, x, indent);
    TranslateStatementOrBlock(red.Tokens[8], indent+1);
    Concatenate6(tem,'set ',vr,' = ',vr, inc, '1');
    WriteOutputLine(tem, x, indent);
    WriteOutputLine('endloop', TokenLine2(tok), indent);
end;

//** This is it, time to code the whole For feature...
procedure TranslateForWhile( const tok:ttoken; const indent:integer=0);
var
   red:Treduction;
   x:integer;

begin
    AllowLocals:=false;

    (* <ForWhile> ::= for ( <Assignments> ; <Expression> ; <Assignments> ) <StatementOrBlock> *)
    red:=tok.Reduction;
    TranslateAssignments(red.Tokens[2],indent);
    x:=TokenLine1(tok);
    WriteOutputLine('loop', x, indent);
    WriteOutputLine('exitwhen '+TranslateExpressionNot(red.Tokens[4]), x, indent);
        TranslateStatementOrBlock(red.Tokens[8],indent+1);
    TranslateAssignments(red.Tokens[6],indent);
    WriteOutputLine('endloop', x, indent);
end;


procedure TranslateIf( const tok:ttoken; const indent:integer=0; const iselseif:boolean=false); forward;
//** There are too many different if commands in Zinc, even though they all look the same...
procedure TranslateIfElse( tok:ttoken; const indent:integer=0);
var
   red,red2:Treduction;
   tok2:Ttoken;
   tem,cond:string;
   iselseif:boolean;
   label repeatit;

   function IsIf(tok:Ttoken; var res:Ttoken): boolean;
   var red:Treduction;
      label redo;
   begin
       redo:
       if (tok.kind <> SymbolTypeNonTerminal) then begin
           Result:=false;
           exit;
       end;
       red:=tok.Reduction;
       case RuleConstants(Red.ParentRule.TableIndex) of
           RULE_IF_IF, RULE_IFELSE_IF_ELSE: begin
           (* <If> ::= if <Parenthesis> <StatementNoBreakOrBlock> *)
           (* <IfElse> ::= if <Parenthesis> <StatementNoBreakOrBlock> else <StatementNoBreakOrBlock> *)
               result:=true;
               res:=tok;
           end;
           RULE_CODEBLOCK_LBRACE_RBRACE: begin
           (* <CodeBlock> ::= { <Statements> } *)
               tok:=red.Tokens[1];
               goto redo;
           end;
           RULE_STATEMENTS: (* <Statements> ::= <Statement> <Statements> *)
           begin
               if( RuleConstants(red.Tokens[1].reduction.parentrule.TableIndex) = RULE_STATEMENTS2 ) then begin
               { RULE_STATEMENTS2  (* <Statements> ::=  *) }
                   tok:=red.Tokens[0];
                   goto redo;
               end else begin
                   result:=false;
               end;
           end;
           else begin
               if(red.TokenCount=1) then begin
                   tok:=red.Tokens[0];
                   goto redo;
               end else begin
                   result:=false;
               end;
           end;

       end;
   end;

begin
    iselseif:=false;
    repeatit:
    AllowLocals:=false;
    (* <IfElse> ::= if <Parenthesis> <StatementNoBreakOrBlock> else <StatementNoBreakOrBlock> *)
    red:=tok.Reduction;
    cond:=TranslateExpression(red.Tokens[1]);
    if(iselseif) then
        Concatenate3(tem,'elseif ',cond,'then')
    else
        Concatenate3(tem,'if ',cond,'then');
    WriteOutputLine(tem, TokenLine1(tok), indent);
    TranslateStatementOrBlock(red.Tokens[2], indent+1);

    if IsIf( red.Tokens[4], tok2 ) then begin
        red2:=tok2.Reduction;
        if RuleConstants(Red2.ParentRule.TableIndex)=RULE_IF_IF then begin
           (* <If> ::= if <Parenthesis> <StatementNoBreakOrBlock> *)
           TranslateIf(tok2, indent, true);
       end else begin
          (* <IfElse> ::= if <Parenthesis> <StatementNoBreakOrBlock> else <StatementNoBreakOrBlock> *)
          iselseif:=true;
          tok:=tok2;
          goto repeatit;

       end;

    end else begin
        WriteOutputLine('else', TokenLine1(red.Tokens[3]), indent);
        TranslateStatementOrBlock(red.Tokens[4], indent+1);
        WriteOutputLine('endif', TokenLine2(tok), indent);
    end;

end;

//*** quick ifs are for lazy people!
procedure TranslateIf( const tok:ttoken; const indent:integer=0; const iselseif:boolean=false);
var
   red:Treduction;
   tem,cond:string;

begin
    AllowLocals:=false;
    (* <If> ::= if <Parenthesis> <StatementNoBreakOrBlock> *)
    red:=tok.Reduction;
    cond:=TranslateExpression(red.Tokens[1]);
    if(iselseif) then
        Concatenate3(tem,'elseif ',cond,'then')
    else
        Concatenate3(tem,'if ',cond,'then');
    WriteOutputLine(tem, TokenLine1(tok), indent);
    TranslateStatementOrBlock(red.Tokens[2], indent+1);
    WriteOutputLine('endif', TokenLine2(tok), indent);

end;


//*** exitwhen for speed morons...
procedure TranslateExitwhen( const tok:ttoken; const indent:integer=0);
var
   red:Treduction;
   cond:string;
begin
    AllowLocals:=false;
   (* <Exitwhen> ::= if <Parenthesis> break ; *)
    red:=tok.Reduction;
    cond:=TranslateExpression(red.Tokens[1]);
    WriteOutputLine('exitwhen '+cond, TokenLine1(tok), indent);

end;

//*** our beloved return
procedure TranslateReturn( const tok:ttoken; const indent:integer=0);
var
   red:Treduction;
begin
    AllowLocals:=false;
    red:=tok.Reduction;
    case RuleConstants(Red.ParentRule.TableIndex) of
        RULE_RETURN_RETURN: begin
        (* <Return> ::= return <Expression> *)
            WriteOutputLine('return '+TranslateExpression(Red.Tokens[1]), TokenLine1(tok), indent);
        end;
        RULE_RETURN_RETURN2: begin
        (* <Return> ::= return *)
            WriteOutputLine('return', TokenLine1(tok), indent);
        end;
    end;
end;

//*** assignments
procedure TranslateAssignment( const tok:ttoken; const indent:integer=0);
var
   red:Treduction;
   ex,tem:string;
begin
    AllowLocals:=false;
    red:=tok.Reduction;
    ex := TranslateExpression(red.Tokens[0]);
    case RuleConstants(Red.ParentRule.TableIndex) of
       RULE_ASSIGNMENT_EQ: (* <Assignment> ::= <Assignable> = <Expression> *)
       begin
            Concatenate4(tem, 'set ', ex, '=', TranslateExpression( red.Tokens[2]) );
       end;
       RULE_ASSIGNMENT_PLUSEQ: (* <Assignment> ::= <Assignable> += <Expression> *)
       begin
            Concatenate6(tem, 'set ', ex, '=', ex,'+', TranslateExpression( red.Tokens[2]) );
       end;
       RULE_ASSIGNMENT_MINUSEQ: (* <Assignment> ::= <Assignable> -= <Expression> *)
       begin
            Concatenate6(tem, 'set ', ex, '=', ex,'-', TranslateExpression( red.Tokens[2]) );
       end;
       RULE_ASSIGNMENT_DIVEQ: (* <Assignment> ::= <Assignable> /= <Expression> *)
       begin
            Concatenate6(tem, 'set ', ex, '=', ex,'/', TranslateExpression( red.Tokens[2]) );
       end;
       RULE_ASSIGNMENT_TIMESEQ: (* <Assignment> ::= <Assignable> *= <Expression> *)
       begin
            Concatenate6(tem, 'set ', ex, '=', ex,'*', TranslateExpression( red.Tokens[2]) );
       end;
    end;
    WriteOutputLine(tem, TokenLine1(tok), indent);
end;
//*** assignments
procedure TranslateAssignments( const tok:ttoken; const indent:integer=0);
var
   red:Treduction;
begin
    AllowLocals:=false;
    red:=tok.Reduction;
    case RuleConstants(Red.ParentRule.TableIndex) of
        RULE_ASSIGNMENTS_COMMA: begin
            (* <Assignments> ::= <Assignments> , <Assignment> *)
            TranslateAssignments(red.Tokens[0], indent);
            TranslateAssignment(red.Tokens[2],indent);
        end;
        RULE_ASSIGNMENTS: begin
            (* <Assignments> ::= <Assignment> *)
            TranslateAssignment(red.Tokens[0],indent);
        end;
    end;
end;

//*** function call (statement version)
procedure TranslateFunctionCallStatement( const tok:ttoken; const indent:integer=0);
var
   red:Treduction;
   tem:string;
begin
    AllowLocals:=false;
    red:=tok.Reduction;
   (* <FunctionCallStatement> ::= <FunctionCall> ; *)
    tem:='call '+ TranslateExpression( red.Tokens[0]);
    WriteOutputLine(tem, TokenLine1(tok), indent);
end;

//*** method call (statement version)
procedure TranslateMethodCallStatement( const tok:ttoken; const indent:integer=0);
var
   red:Treduction;
   tem:string;
begin
    AllowLocals:=false;
    red:=tok.Reduction;
    (* <MethodCallStatement> ::= <MethodCall> ; *)
    tem:='call '+ TranslateExpression( red.Tokens[0]);
    WriteOutputLine(tem, TokenLine1(tok), indent);
end;


//*** static ifs are evil, deceptively like ifs...
procedure TranslateStaticIf( const tok:ttoken; const indent:integer=0);
var
   red:Treduction;
   cond,tem:string;
   loc:boolean;
begin
    red:=tok.Reduction;
    loc:=AllowLocals;


    case RuleConstants(Red.ParentRule.TableIndex) of
        RULE_STATICIF_STATIC_IF_LPARAN_RPARAN: begin
        (* <StaticIf> ::= static if ( <StaticIfExpression> ) <StatementOrBlock> *)
            cond:=TranslateExpression(red.Tokens[3]);
            Concatenate3(tem,'static if ',cond,' then');
            WriteOutputLine(tem, TokenLine1(tok), indent);
            TranslateStatementOrBlock(red.Tokens[5], indent+1);
            WriteOutputLine('endif', TokenLine2(tok), indent);
        end;
        RULE_STATICIF_STATIC_IF_LPARAN_RPARAN_ELSE: begin
        (* <StaticIf> ::= static if ( <StaticIfExpression> ) <StatementOrBlock> else <StatementOrBlock> *)
            cond:=TranslateExpression(red.Tokens[3]);
            Concatenate3(tem,'static if ',cond,' then');
            WriteOutputLine(tem, TokenLine1(tok), indent);
            TranslateStatementOrBlock(red.Tokens[5], indent+1);
            WriteOutputLine('else', TokenLine1(red.Tokens[6]), indent);
            AllowLocals:=loc;
            TranslateStatementOrBlock(red.Tokens[7], indent+1);
            WriteOutputLine('endif', TokenLine2(tok), indent);
        end;
    end;

end;


//********* global variables, another hard to parse monstrousity
procedure TranslateLocalVariables(const tok:TToken; const indent:integer=0);
var
    red:Treduction;
    typ, tem: string;

       procedure TranslateSingleVariable(const tok:Ttoken);
        var
            red:Treduction;
            name, v1, right,left:string;
       begin

           red:=tok.Reduction.Tokens[0].Reduction;
           case RuleConstants(Red.ParentRule.TableIndex) of
               RULE_VARIABLENAME_IDENTIFIER: begin
               (* <VariableName> ::= Identifier *)
                   name:=TranslateTerminal(red.Tokens[0]);
                   right :='';
                   left  :='';
               end;
               RULE_VARIABLENAMEASSIGNED_IDENTIFIER_EQ: begin
               (* <VariableNameAssigned> ::= Identifier = <Expression> *)
                   name:=TranslateTerminal(red.Tokens[0]);
                   v1:=TranslateExpression(red.Tokens[2]);
                   right :='='+v1;
                   left  :='';

               end;
               RULE_ARRAYNAME_IDENTIFIER_LBRACKET_RBRACKET: begin
               (* <ArrayName> ::= Identifier [ ] *)
                   name:=TranslateTerminal(red.Tokens[0]);
                   right :='';
                   left  :=' array ';

               end;
               RULE_ARRAYNAMESIZE_IDENTIFIER_LBRACKET_RBRACKET: begin
               (* <ArrayNameSize> ::= Identifier [ <Expression> ] *)
                   raise ZincLineError(TokenLine2(tok), 'local arrays cannot have explicit sizes');
                   {name:=TranslateTerminal(red.Tokens[0]);
                   v1:=TranslateExpression(red.Tokens[2]);
                   Concatenate3(right,'[',v1,']');;
                   left:=' array ';}
               end;
               RULE_ARRAYNAMESIZESIZE_IDENTIFIER_LBRACKET_RBRACKET_LBRACKET_RBRACKET: begin
               (* <ArrayNameSizeSize> ::= Identifier [ <Expression> ] [ <Expression> ] *)
                   raise ZincLineError(TokenLine2(tok), 'local arrays cannot be 2D');
                   {name:=TranslateTerminal(red.Tokens[0]);
                   v1:=TranslateExpression(red.Tokens[2]);
                   v2:=TranslateExpression(red.Tokens[5]);
                   Concatenate5(right,'[',v1,'][',v2,']');
                   left:=' array ';}
               end;

           end;
           Concatenate6(tem, 'local ',typ,' ',left,name,right);
           WriteOutputLine(tem, TokenLine1(tok), indent);

       end;

       procedure TranslateVariableList(const tok:Ttoken);
        var
           red:Treduction;
       begin
           red:=tok.Reduction;
           case RuleConstants(Red.ParentRule.TableIndex) of
               RULE_VARIABLELIST_COMMA: begin
               (* <VariableList> ::= <SingleVariable> , <VariableList> *)
                   TranslateSingleVariable(red.Tokens[0]);
                   TranslateVariableList(red.Tokens[2]);
               end;
               RULE_VARIABLELIST: begin
               (* <VariableList> ::= <SingleVariable> *)
                   TranslateSingleVariable(red.Tokens[0]);
               end;
           end;
       end;

begin
    (* <LocalVariable> ::= <Type> <VariableList> ; *)
    if(not AllowLocals) then raise ZincLineError(TokenLine1(tok),'Unexpected local variable.');
    red:=tok.Reduction;
    typ:=TranslateTerminal(red.Tokens[0]);
    TranslateVariableList(red.Tokens[1]);
end;


// admits: statement, singlestatement and statementnobreak;
procedure TranslateStatement(tok:Ttoken; const indent:integer=0);
var
    red:Treduction;
begin
    red:=tok.Reduction;
    case RuleConstants(Red.ParentRule.TableIndex) of

        RULE_STATEMENTNOBREAK_SEMI: begin
        (* <StatementNoBreak> ::= <SingleStatement> ; *)
            TranslateStatement(red.Tokens[0],indent);
        end;
        RULE_STATEMENT: begin
        (* <Statement> ::= <StatementNoBreak> *)
            TranslateStatement(red.Tokens[0],indent);
        end;

        RULE_STATEMENTNOBREAK: begin
        (* <StatementNoBreak> ::= <Debug> *)
            TranslateDebug( red.Tokens[0], indent);
        end;
        RULE_STATEMENTNOBREAK2: begin
        (* <StatementNoBreak> ::= <While> *)
            TranslateWhile( red.Tokens[0], indent);
        end;
        RULE_STATEMENTNOBREAK12: begin
        (* <StatementNoBreak> ::= <DoWhile> *)
            TranslateDoWhile( red.Tokens[0], indent);
        end;
        RULE_STATEMENTNOBREAK3: begin
        (* <StatementNoBreak> ::= <For> *)
            TranslateFor( red.Tokens[0], indent);
        end;
        RULE_STATEMENTNOBREAK11: begin
       (* <StatementNoBreak> ::= <ForWhile> *)
            TranslateForWhile( red.Tokens[0], indent);
        end;
        RULE_STATEMENTNOBREAK4: begin
        (* <StatementNoBreak> ::= <If> *)
            TranslateIf( red.Tokens[0], indent);
        end;
        RULE_STATEMENTNOBREAK5: begin
        (* <StatementNoBreak> ::= <StaticIf> *)
            TranslateStaticIf( red.Tokens[0], indent);
        end;
        RULE_STATEMENTNOBREAK6: begin
        (* <StatementNoBreak> ::= <IfElse> *)
            TranslateIfElse( red.Tokens[0], indent);
        end;
        RULE_STATEMENTNOBREAK7: begin
        (* <StatementNoBreak> ::= <Exitwhen> *)
            TranslateExitwhen( red.Tokens[0], indent);
        end;
        RULE_SINGLESTATEMENT: begin
        (* <SingleStatement> ::= <Return> *)
            TranslateReturn( red.Tokens[0], indent);
        end;
        RULE_SINGLESTATEMENT2: begin
        (* <SingleStatement> ::= <Assignments> *)
            TranslateAssignments( red.Tokens[0], indent);
        end;
        RULE_STATEMENTNOBREAK8: begin
        (* <StatementNoBreak> ::= <FunctionCallStatement> *)
            TranslateFunctionCallStatement( red.Tokens[0], indent);
        end;
        RULE_STATEMENTNOBREAK9: begin
        (* <StatementNoBreak> ::= <MethodCallStatement> *)
            TranslateMethodCallStatement( red.Tokens[0], indent);
        end;

        RULE_STATEMENTNOBREAK10: begin
        (* <StatementNoBreak> ::= <LocalVariable> *)
            TranslateLocalVariables( red.Tokens[0], indent);
        end;
        RULE_STATEMENT2: begin
         (* <Statement> ::= <BreakStatement> *)
            AllowLocals:=false;
            WriteOutPutLine('exitwhen true', tok.LineNumber, indent);
        end;
    end;
end;

procedure TranslateStatements(tok:TToken; const indent:integer=0);
var red:Treduction;
begin

    while(true) do begin
        red:=tok.Reduction;
        case RuleConstants(Red.ParentRule.TableIndex) of
            RULE_STATEMENTS: begin
            (* <Statements> ::= <Statement> <Statements> *)
                TranslateStatement(red.Tokens[0], indent);
                tok:=red.Tokens[1];
            end;
            RULE_STATEMENTS2: begin
            (* <Statements> ::=  *)
                break;
            end;
        end;
    end;


end;


procedure TranslateCodeBlock(const tok:TToken; const indent:integer=0);
begin
    (* <CodeBlock> ::= { <Statements> } *)
    TranslateStatements( tok.Reduction.Tokens[1] , indent);
end;

// also translate StatementNoBreakOrBlock
procedure TranslateStatementOrBlock( const tok:ttoken; const indent:integer=0);
var
   red:Treduction;
begin
    red:=tok.Reduction;
    case RuleConstants(Red.ParentRule.TableIndex) of
        RULE_STATEMENTORBLOCK: begin
        (* <StatementOrBlock> ::= <Statement> *)
            TranslateStatement(red.tokens[0],indent);
        end;
        RULE_STATEMENTORBLOCK2: begin
        (* <StatementOrBlock> ::= <CodeBlock> *)
            TranslateCodeBlock(red.tokens[0],indent);
        end;
        RULE_STATEMENTNOBREAKORBLOCK: begin
        (* <StatementNoBreakOrBlock> ::= <StatementNoBreak> *)
            TranslateStatement(red.tokens[0],indent);
        end;
        RULE_STATEMENTNOBREAKORBLOCK2: begin
        (* <StatementNoBreakOrBlock> ::= <CodeBlock> *)
            TranslateCodeBlock(red.tokens[0],indent);
        end;

    end;
end;

//----

procedure TranslatePreprocessor(tok:TToken);
var s:string;
    len:integer;
begin
    s:=TranslateTerminal(tok);
    len:=Length(s);
    while( (len > 0) and ( ( s[Len] = #13) or ( s[Len] = #10) ) ) do
        len:=len-1;
    s:=Copy(s,1,len);
    WriteoutPutline(s, TokenLine1(tok) );
end;

//----------------------------------
var
   lib_privates:integer;
   lib_private: array of string;

procedure AddLibraryPrivate(const s:string);
begin
    if(Length(lib_private) <= lib_privates) then begin
         SetLength(lib_private, lib_privates+10+lib_privates div 10);
    end;
    lib_private[lib_privates]:=s;
    lib_privates := lib_privates + 1;
end;

//****************
// anonymous functions:
//
procedure LookOutForAnonymousFunctions(tok:TToken; const indent:integer=0; frommethod:boolean=false); forward;
procedure TranslateAnonymousFunction(const tok:TToken; const indent:integer=0; frommethod:boolean=false);
var
    red:Treduction;
    id:integer;
    tem,priv,name,typ,takes:string;
    AllowLocalsBack, stat:boolean;

    function IsTagStatic(const tok:Ttoken):boolean;
       var red:Treduction;
    begin
       red:=tok.Reduction;
       Result := (RuleConstants(Red.ParentRule.TableIndex)<>RULE_ANONYMOUSTAG_METHOD );
       (* <AnonymousTag> ::= method *)
    end;
begin
    id:=anoncount;
    anoncount := anoncount + 1;
    (* <AnonymousFunction> ::= <AnonymousTag> ( <FunctionArgumentList> ) <ReturnType> <CodeBlock> *)
    AllowLocalsBack := AllowLocals;
    AllowLocals:=true;
    red:=tok.Reduction;

    stat:=IsTagStatic(red.Tokens[0]);
    LookOutForAnonymousFunctions(red.Tokens[5], indent+1, frommethod);
    name:='anon__'+IntToStr(id);
    priv:='private ';

    typ:=TranslateReturnType(red.Tokens[4]);
    takes:=TranslateFunctionArgumentList(red.Tokens[2]);
    if(frommethod) then begin
        if(takes = 'nothing' ) and stat then
            tok.DataVar:='function thistype.'+name
        else
            tok.DataVar:='thistype.'+name;
    end else begin
        if(not stat) then
            raise ZincLineError(TokenLine1(tok),'Anonymous methods not allowed outside structs.');

        if(takes = 'nothing' ) then
            tok.DataVar:='function '+name
        else
            tok.DataVar:=name;
    end;

    if(frommethod) then begin
       if(Stat) then
           Concatenate7(tem, priv,'static method ',name,' takes ',takes,' returns ',typ)
       else
           Concatenate7(tem, priv,'method ',name,' takes ',takes,' returns ',typ);
    end else begin
       Concatenate7(tem, priv,'function ',name,' takes ',takes,' returns ',typ);
    end;
    WriteOutPutLine(tem, TokenLine1(tok), indent);
    TranslateCodeBlock(red.tokens[5], indent+1);

    if(frommethod) then begin
       WriteOutPutLine('endmethod', TokenLine2(tok), indent);
    end else begin
       WriteOutPutLine('endfunction', TokenLine2(tok), indent);
    end;
    AllowLocals:=AllowLocalsBack;



end;



procedure LookOutForAnonymousFunctions(tok:TToken; const indent:integer=0; frommethod:boolean=false);
var
    red:Treduction;
    i:integer;
begin
    if(tok.kind <> SymbolTypeNonTerminal) then
        exit;

    red:=tok.Reduction;

    case RuleConstants(Red.ParentRule.TableIndex) of
        RULE_ANONYMOUSFUNCTION_LPARAN_RPARAN:
        begin
        (* <AnonymousFunction> ::= <AnonymousTag> ( <FunctionArgumentList> ) <ReturnType> <CodeBlock> *)
            TranslateAnonymousFunction(tok, indent, frommethod );
        end;
        else begin
            for i := 0 to Red.TokenCount-1 do
               LookOutForAnonymousFunctions(red.Tokens[i], indent, frommethod);
        end;
    end;

end;

//***************************************************************************
// function
procedure TranslateFunction(const tok:TToken; const defacc:Taccessmodifier; const indent:integer=0);
var
    red:Treduction;
    tem,priv,name,typ,takes:string;
begin
(* <Function> ::= <PrivatePublic> function Identifier ( <FunctionArgumentList> ) <ReturnType> <CodeBlock> *)

    AllowLocals:=true;
    red:=tok.Reduction;
    LookOutForAnonymousFunctions(red.Tokens[7], indent+1);


    name:=TranslateTerminal(red.Tokens[2]);
    priv:='';
    if TranslatePublicPrivate(red.Tokens[0], defacc) = ACCESS_PRIVATE then begin
        priv:='private ';
        AddLibraryPrivate(name);
    end;
    typ:=TranslateReturnType(red.Tokens[6]);
    takes:=TranslateFunctionArgumentList(red.Tokens[4]);
    Concatenate7(tem, priv,'function ',name,' takes ',takes,' returns ',typ);
    WriteOutPutLine(tem, TokenLine1(tok), indent);
    TranslateCodeBlock(red.tokens[7], indent+1);

    WriteOutPutLine('endfunction', TokenLine2(tok), indent);




end;

//***************************************************************************
// struct stuff
//
procedure TranslateStructBody( tok:TToken; const defacc:Taccessmodifier; const indent:integer=0); forward;

procedure TranslateImplement( tok:TToken; const defacc:Taccessmodifier; const indent:integer=0);
var
    red:Treduction;
    tem:string;

begin
    red:=tok.Reduction;
    (* <StructImplement> ::= <OptionalModule> module Identifier ; *)
    Concatenate4(tem, 'implement ',TranslateTerminal(red.Tokens[0]),' ',TranslateTerminal(red.Tokens[2]) );
    WriteOutputLine(tem,TokenLine1(tok), indent);

end;

procedure TranslateStructPP( tok:TToken; const defacc:Taccessmodifier; const indent:integer=0);
var
    red:Treduction;
    tem:string;

begin
    red:=tok.Reduction;
    (* <StructPPBlock> ::= <PrivatePublic> { <StructBody> } *)
    tem:=TranslateTerminal(red.tokens[0]);
    if(tem='') then raise ZincLineError(TokenLine1(red.Tokens[1]), 'Expected: public or private');
    WriteoutputLine('//'+tem+':', TokenLine1(tok), indent);
    if(tem='private') then
        TranslateStructBody(red.Tokens[2], ACCESS_PRIVATE, indent+1)
    else
        TranslateStructBody(red.Tokens[2], ACCESS_PUBLIC, indent+1)

end;


procedure TranslateStructVariables( tok:TToken; const defacc:Taccessmodifier; const indent:integer=0);
var
    red:Treduction;
    acc:Taccessmodifier;
    stat, constant, delegate: string;
    typ, tem, priv: string;

       procedure TranslateSingleVariable(const tok:Ttoken);
        var
            red:Treduction;
            name, v1,v2, right,left:string;
       begin

           red:=tok.Reduction.Tokens[0].Reduction;
           case RuleConstants(Red.ParentRule.TableIndex) of
               RULE_VARIABLENAME_IDENTIFIER: begin
               (* <VariableName> ::= Identifier *)
                   name:=TranslateTerminal(red.Tokens[0]);
                   right :='';
                   left  :='';
               end;
               RULE_VARIABLENAMEASSIGNED_IDENTIFIER_EQ: begin
               (* <VariableNameAssigned> ::= Identifier = <Expression> *)
                   name:=TranslateTerminal(red.Tokens[0]);
                   v1:=TranslateExpression(red.Tokens[2]);
                   right :='='+v1;
                   left  :='';

               end;
               RULE_ARRAYNAME_IDENTIFIER_LBRACKET_RBRACKET: begin
               (* <ArrayName> ::= Identifier [ ] *)
                   name:=TranslateTerminal(red.Tokens[0]);
                   right :='';
                   left  :=' array ';
                   if(stat='') then
                       raise ZincLineError(TokenLine1(tok), 'Non-static arrays require an explicit size.');
               end;
               RULE_ARRAYNAMESIZE_IDENTIFIER_LBRACKET_RBRACKET: begin
               (* <ArrayNameSize> ::= Identifier [ <Expression> ] *)
                   name:=TranslateTerminal(red.Tokens[0]);
                   v1:=TranslateExpression(red.Tokens[2]);
                   Concatenate3(right,'[',v1,']');;
                   left:=' array ';
               end;
               RULE_ARRAYNAMESIZESIZE_IDENTIFIER_LBRACKET_RBRACKET_LBRACKET_RBRACKET: begin
               (* <ArrayNameSizeSize> ::= Identifier [ <Expression> ] [ <Expression> ] *)
                   name:=TranslateTerminal(red.Tokens[0]);
                   v1:=TranslateExpression(red.Tokens[2]);
                   v2:=TranslateExpression(red.Tokens[5]);
                   Concatenate5(right,'[',v1,'][',v2,']');
                   left:=' array ';
                   if(stat='') then
                       raise ZincLineError(TokenLine1(tok), 'Non-static arrays cannot be 2D.');

               end;

           end;
           if(acc=ACCESS_PRIVATE) then begin
               priv:='private ';
           end;
           Concatenate9(tem, priv, stat, delegate, constant, typ,' ',left,name,right);
           WriteOutputLine(tem, TokenLine1(tok), indent);

       end;

       procedure TranslateStructVariableList(const tok:Ttoken);
        var
           red:Treduction;
       begin
           red:=tok.Reduction;
           case RuleConstants(Red.ParentRule.TableIndex) of
               RULE_VARIABLELIST_COMMA: begin
               (* <VariableList> ::= <SingleVariable> , <VariableList> *)
                   TranslateSingleVariable(red.Tokens[0]);
                   TranslateStructVariableList(red.Tokens[2]);
               end;
               RULE_VARIABLELIST: begin
               (* <VariableList> ::= <SingleVariable> *)
                   TranslateSingleVariable(red.Tokens[0]);
               end;
           end;
       end;

begin
(* <StructVariableDeclaration> ::=
   <PrivatePublic> <Static> <Delegate> <Constant> <Type> <VariableList> ; *)
    LookoutForAnonymousFunctions(tok,indent+1,true);
    red:=tok.Reduction;
    acc:=TranslatePublicPrivate(red.tokens[0], defAcc);
    constant:= TranslateTerminal( red.Tokens[3] );
    stat:= TranslateTerminal( red.Tokens[1] );
    delegate:= TranslateTerminal( red.Tokens[2] );
    if(constant<>'') then constant:='constant ';
    if(stat<>'') then stat:='static ';
    if(delegate<>'') then delegate:='delegate ';

    typ:=TranslateTerminal(red.Tokens[4]);
    if(typ='implement') then raise ZincLineError( TokenLine2(red.Tokens[4]), 'Unexpected: "implement" (did you mean "module"?)');
    TranslateStructVariableList(red.Tokens[5]);
end;

//***************************************************************************
// Struct Method
function TranslateMethodName(const tok:Ttoken):string;
begin
    result:=TranslateExpression(tok);
end;

procedure TranslateStructMethod(const tok:TToken; const defacc:Taccessmodifier; const indent:integer=0);
var
    red:Treduction;
    tem,priv,stat, name,typ,takes:string;
begin
    (* <StructMethod> ::=
    <PrivatePublic> <Static> method <MethodName> ( <FunctionArgumentList> ) <ReturnType> <CodeBlock> *)
    AllowLocals:=true;
    red:=tok.Reduction;

    LookOutForAnonymousFunctions(red.Tokens[8], indent+1, true);

    name:=TranslateMethodName(red.Tokens[3]);
    priv:='';
    if TranslatePublicPrivate(red.Tokens[0], defacc) = ACCESS_PRIVATE then begin
        priv:='private ';
    end;
    stat:=TranslateTerminal(red.tokens[1]);
    if(stat<>'') then stat:='static ';
    typ:=TranslateReturnType(red.Tokens[7]);
    takes:=TranslateFunctionArgumentList(red.Tokens[5]);
    Concatenate8(tem, priv,stat, 'method ',name,' takes ',takes,' returns ',typ);
    WriteOutPutLine(tem, TokenLine1(tok), indent);
    TranslateCodeBlock(red.tokens[8], indent+1);

    WriteOutPutLine('endmethod', TokenLine2(tok), indent);
end;

procedure TranslateInterfaceMethod(const tok:TToken; const defacc:Taccessmodifier; const indent:integer=0);
var
    red:Treduction;
    tem,priv,stat, name,typ,takes, defs:string;

    function TranslateInterfaceDefaults(const tok:Ttoken):string;
     var
        red:Treduction;
    begin
        red:=tok.Reduction;
        case RuleConstants(Red.ParentRule.TableIndex) of
            RULE_INTERFACEDEFAULTS_EQ: begin
            (* <InterfaceDefaults> ::= = <Expression> *)
                result:=TranslateExpression(red.Tokens[1]);
            end;
            else {RULE_INTERFACEDEFAULTS} begin
            (* <InterfaceDefaults> ::=  *)
                Result:='';
            end;

        end;

    end;

begin
    (* <InterfaceMethod> ::=
       <PrivatePublic> <Static> method <MethodName> ( <FunctionArgumentList> )
       <ReturnType> <InterfaceDefaults> ; *)
    red:=tok.Reduction;
    name:=TranslateMethodName(red.Tokens[3]);
    priv:='';
    if TranslatePublicPrivate(red.Tokens[0], defacc) = ACCESS_PRIVATE then begin
        priv:='private ';
    end;
    stat:=TranslateTerminal(red.tokens[1]);
    if(stat<>'') then stat:='static ';
    typ:=TranslateReturnType(red.Tokens[7]);
    takes:=TranslateFunctionArgumentList(red.Tokens[5]);
    defs:=TranslateInterfaceDefaults(red.Tokens[8]);
    if(defs<>'') then begin
        if( (defs='null') and (typ='nothing') ) then
            defs:='nothing';
        defs:=' defaults '+defs;
    end;
    if( (name='create') and (stat<>'') ) then
        typ:=''
    else
        typ:=' returns '+typ;
    Concatenate8(tem, priv,stat, 'method ',name,' takes ',takes, typ,defs);
    WriteOutPutLine(tem, TokenLine1(tok), indent);
end;


procedure TranslateStructMember( tok:TToken; const defacc:Taccessmodifier; const indent:integer=0);
var
    red:Treduction;

begin
    red:=tok.Reduction;
    case RuleConstants(Red.ParentRule.TableIndex) of
        RULE_STRUCTMEMBER, RULE_INTERFACEMEMBER: begin
        (* <StructMember> ::= <StructVariableDeclaration> *)
        (* <InterfaceMember> ::= <StructVariableDeclaration> *)
            TranslateStructVariables(red.Tokens[0], defacc, indent);
        end;
        RULE_STRUCTMEMBER2: begin
        (* <StructMember> ::= <StructMethod> *)
            TranslateStructMethod(red.Tokens[0], defacc, indent);
        end;
        RULE_STRUCTMEMBER3: begin
        (* <StructMember> ::= <StructImplement> *)
            TranslateImplement(red.Tokens[0], defacc, indent);
        end;
        RULE_STRUCTMEMBER4: begin
        (* <StructMember> ::= <StructPPBlock> *)
            TranslateStructPP(red.Tokens[0], defacc, indent);
        end;
        RULE_INTERFACEMEMBER2: begin
        (* <InterfaceMember> ::= <InterfaceMethod> *)
            TranslateInterfaceMethod(red.Tokens[0], defacc, indent);
        end;
        RULE_INTERFACEMEMBER3: begin
        (* <InterfaceMember> ::= <InterfacePPBlock> *)
            raise ZincLineError( TokenLine1(tok),'Sorry, but access modifiers inside a interface make no sense...');
        end;

    end;

end;

procedure TranslateStructBody( tok:TToken; const defacc:Taccessmodifier; const indent:integer=0);
var
    red:Treduction;
    label start;
begin
    start:
    red:=tok.Reduction;
    case RuleConstants(Red.ParentRule.TableIndex) of
        RULE_STRUCTBODY: begin
        (* <StructBody> ::= <StructMember> <StructBody> *)
            TranslateStructMember(red.Tokens[0], defacc, indent);
            tok:=red.Tokens[1];
            goto start;
        end;
        RULE_STRUCTBODY2: begin
        (* <StructBody> ::=  *)
            exit;
        end;
        RULE_INTERFACEBODY: begin
        (* <InterfaceBody> ::= <InterfaceMember> <InterfaceBody> *)
            TranslateStructMember(red.Tokens[0], defacc, indent);
            tok:=red.Tokens[1];
            goto start;
        end;
        RULE_INTERFACEBODY2: begin
        (* <InterfaceBody> ::=  *)
            exit;
        end;

    end;


end;

procedure TranslateStruct(const tok:TToken; const defacc:Taccessmodifier; const indent:integer=0);
var
    red:Treduction;
    priv,name,lim, ext,tem,arr:string;

    function TranslateArrayStruct( const tok:Ttoken): string;
     var
        red:Treduction;
    begin
        red:=tok.Reduction;
        case RuleConstants(Red.ParentRule.TableIndex) of
           RULE_STRUCTARRAY_LBRACKET_RBRACKET: begin
           (* <StructArray> ::= [ ] *)
               Result:='extends array';
           end;
           RULE_STRUCTARRAY_LBRACKET_RBRACKET2: begin
           (* <StructArray> ::= [ <Expression> ] *)
               Concatenate3(result,'extends array [ ',TranslateExpression(red.Tokens[1]), ' ]');
           end;
           else begin
           (* <StructArray> ::=  *)
               Result:='';
           end;

        end;
    end;

begin
(* <Struct> ::= <PrivatePublic> struct <StorageLimit> Identifier <StructArray> <Extends> { <StructBody> } *)

    red:=tok.Reduction;
    name:=TranslateTerminal(red.Tokens[3]);
    priv:='';
    if TranslatePublicPrivate(red.Tokens[0], defacc) = ACCESS_PRIVATE then begin
        priv:='private ';
        AddLibraryPrivate(name);
    end;
    lim:={TranslateStorageLimit}TranslateExpression(red.Tokens[2]);
    ext:={TranslateExtends}TranslateExpression(red.Tokens[5]);
    if( (lim<>'') and (ext<>'') ) then begin
        raise ZincLineError( TokenLine1(red.Tokens[5]), 'Children structs must not specify a storage limit');
    end;
    arr:=TranslateArrayStruct(red.Tokens[4]);
    if( (arr<>'') and ( (lim<>'') or (ext<>'') ) ) then begin
        raise ZincLineError( TokenLine1(red.Tokens[5]), 'array structs cannot extend/have storage limit');
    end;

    Concatenate7(tem, priv,'struct ',name,' ',lim,ext,arr);
    WriteOutPutLine(tem, TokenLine1(tok), indent);
    WriteOutPutLine('//! pragma implicitthis', TokenLine1(tok), indent);
    TranslateStructBody(red.tokens[7], ACCESS_PUBLIC, indent+1);
    WriteOutPutLine('endstruct', TokenLine2(tok), indent);




end;

procedure TranslateModule(const tok:TToken; const defacc:Taccessmodifier; const indent:integer=0);
var
    red:Treduction;
    priv,name, tem:string;

begin
(* <Module> ::= <PrivatePublic> module Identifier { <StructBody> } *)

    red:=tok.Reduction;
    name:=TranslateTerminal(red.Tokens[2]);
    priv:='';
    if TranslatePublicPrivate(red.Tokens[0], defacc) = ACCESS_PRIVATE then begin
        priv:='private ';
        AddLibraryPrivate(name);
    end;

    Concatenate3(tem, priv,'module ',name);
    WriteOutPutLine(tem, TokenLine1(tok), indent);
    TranslateStructBody(red.tokens[4], ACCESS_PUBLIC, indent+1);
    WriteOutPutLine('endmodule', TokenLine2(tok), indent);




end;


procedure TranslateInterface(const tok:TToken; const defacc:Taccessmodifier; const indent:integer=0);
var
    red:Treduction;
    priv,name,lim, tem:string;


begin
   (* <Interface> ::= <PrivatePublic> interface <StorageLimit> Identifier { <InterfaceBody> } *)
    red:=tok.Reduction;
    name:=TranslateTerminal(red.Tokens[3]);
    priv:='';
    if TranslatePublicPrivate(red.Tokens[0], defacc) = ACCESS_PRIVATE then begin
        priv:='private ';
        AddLibraryPrivate(name);
    end;
    lim:={TranslateStorageLimit}TranslateExpression(red.Tokens[2]);

    Concatenate5(tem, priv,'interface ',name,' ',lim);
    WriteOutPutLine(tem, TokenLine1(tok), indent);
    TranslateStructBody(red.tokens[5], ACCESS_PUBLIC, indent+1);
    WriteOutPutLine('endinterface', TokenLine2(tok), indent);




end;


//****************************************************************************
//global variables
procedure TranslateGlobalVariables(const tok:TToken; const DefaultAccess:Taccessmodifier; const indent:integer=0);
var
    red:Treduction;
    acc:Taccessmodifier;
    typ, tem, priv, constant: string;

       procedure TranslateSingleVariable(const tok:Ttoken);
        var
            red:Treduction;
            name, v1,v2, right,left:string;
       begin

           red:=tok.Reduction.Tokens[0].Reduction;
           case RuleConstants(Red.ParentRule.TableIndex) of
               RULE_VARIABLENAME_IDENTIFIER: begin
               (* <VariableName> ::= Identifier *)
                   name:=TranslateTerminal(red.Tokens[0]);
                   right :='';
                   left  :='';
               end;
               RULE_VARIABLENAMEASSIGNED_IDENTIFIER_EQ: begin
               (* <VariableNameAssigned> ::= Identifier = <Expression> *)
                   name:=TranslateTerminal(red.Tokens[0]);
                   v1:=TranslateExpression(red.Tokens[2]);
                   right :='='+v1;
                   left  :='';

               end;
               RULE_ARRAYNAME_IDENTIFIER_LBRACKET_RBRACKET: begin
               (* <ArrayName> ::= Identifier [ ] *)
                   name:=TranslateTerminal(red.Tokens[0]);
                   right :='';
                   left  :=' array ';

               end;
               RULE_ARRAYNAMESIZE_IDENTIFIER_LBRACKET_RBRACKET: begin
               (* <ArrayNameSize> ::= Identifier [ <Expression> ] *)
                   name:=TranslateTerminal(red.Tokens[0]);
                   v1:=TranslateExpression(red.Tokens[2]);
                   Concatenate3(right,'[',v1,']');;
                   left:=' array ';
               end;
               RULE_ARRAYNAMESIZESIZE_IDENTIFIER_LBRACKET_RBRACKET_LBRACKET_RBRACKET: begin
               (* <ArrayNameSizeSize> ::= Identifier [ <Expression> ] [ <Expression> ] *)
                   name:=TranslateTerminal(red.Tokens[0]);
                   v1:=TranslateExpression(red.Tokens[2]);
                   v2:=TranslateExpression(red.Tokens[5]);
                   Concatenate5(right,'[',v1,'][',v2,']');
                   left:=' array ';
               end;

           end;
           if(acc=ACCESS_PRIVATE) then begin
               priv:='private ';
               AddLibraryPrivate(name);
           end;
           Concatenate7(tem, priv,constant, typ,' ',left,name,right);
           WriteOutputLine(tem, TokenLine1(tok), indent);

       end;

       procedure TranslateGlobalVariableList(const tok:Ttoken);
        var
           red:Treduction;
       begin
           red:=tok.Reduction;
           case RuleConstants(Red.ParentRule.TableIndex) of
               RULE_VARIABLELIST_COMMA: begin
               (* <VariableList> ::= <SingleVariable> , <VariableList> *)
                   TranslateSingleVariable(red.Tokens[0]);
                   TranslateGlobalVariableList(red.Tokens[2]);
               end;
               RULE_VARIABLELIST: begin
               (* <VariableList> ::= <SingleVariable> *)
                   TranslateSingleVariable(red.Tokens[0]);
               end;
           end;
       end;

begin
(* <GlobalVariableDeclaration> ::= <PrivatePublic> <Constant> <Type> <VariableList> ; *)
    LookoutForAnonymousFunctions(tok,indent+1,false);
    red:=tok.Reduction;
    acc:=TranslatePublicPrivate(red.tokens[0], DefaultAccess);
    constant:=TranslateTerminal( red.Tokens[1] );
    if(constant<>'') then constant:='constant ';
    typ:=TranslateTerminal(red.Tokens[2]);
    WriteOutputLine('globals',TokenLine1(tok), indent);
    TranslateGlobalVariableList(red.Tokens[3]);
    WriteOutputLine('endglobals',TokenLine2(tok), indent);
end;


//******************************************
// type statement:
//
procedure TranslateDynamicArray(const tok:Ttoken; const acc:TAccessModifier; const name:string; const indent:integer);
var
    red:Treduction;
    tem, siz, lim, priv, typ:string;

      function storageLimit(const tok:Ttoken): string;
       var
          red:Treduction;
      begin
          red:=tok.Reduction;
          case RuleConstants(Red.ParentRule.TableIndex) of
              RULE_DYNAMICARRAYSTORAGELIMIT_COMMA: begin
                  (* <DynamicArrayStorageLimit> ::= , <Expression> *)
                  result:=TranslateExpression(red.Tokens[1]);
              end;
              RULE_DYNAMICARRAYSTORAGELIMIT: begin
                  (* <DynamicArrayStorageLimit> ::=  *)
                  result:='';
              end;
          end;
      end;
begin
  // (* <DynamicArray> ::= <Type> [ <Expression> <DynamicArrayStorageLimit> ] *)
  red:=tok.Reduction;
  priv:='';
  if(acc=ACCESS_PRIVATE) then begin
      AddLibraryPrivate(name);
      priv:='private ';
  end;
  typ:=TranslateTerminal( red.Tokens[0] );
  siz := TranslateExpression(red.Tokens[2] );
  lim := storageLimit(red.Tokens[3]);
  if(lim='') then
      Concatenate8(tem,priv,'type ',name,' extends ',typ,' array [', siz,']')
  else
      Concatenate10(tem,priv,'type ',name,' extends ',typ,' array [', siz,', ',lim, ']');
  WriteOutPutLine(tem, tok.LineNumber, indent); 



end;

procedure TranslateFunctionInterface(const tok:Ttoken; const acc:TAccessModifier; const name:string; const indent:integer);
var
    red:Treduction;
    priv, ret, takes, tem:string;

    function TranslateTakes(const tok:Ttoken; const id:integer=0):string;
    var
        red:Treduction;
    begin
        red:=tok.Reduction;
        case RuleConstants(Red.ParentRule.TableIndex) of
           RULE_FUNCTIONINTERFACEARGUMENTLIST: begin
               (* <FunctionInterfaceArgumentList> ::= <FunctionInterfaceArgument> *)
               Concatenate3(result, TranslateTerminal(red.Tokens[0]), ' arg', IntToStr(id));
           end;
           RULE_FUNCTIONINTERFACEARGUMENTLIST_COMMA: begin
               (* <FunctionInterfaceArgumentList> ::= <FunctionInterfaceArgument> , <FunctionInterfaceArgumentList> *)
               Concatenate3(result, TranslateTerminal(red.Tokens[0]), ' arg', IntToStr(id));
               result:=result+', '+TranslateTakes(red.Tokens[2],id+1);
           end;
           RULE_FUNCTIONINTERFACEARGUMENTLIST2: begin
               (* <FunctionInterfaceArgumentList> ::=  *)
               result:='nothing';
           end;
        end;

    end;
begin
  (* <FunctionInterface> ::= function ( <FunctionInterfaceArgumentList> ) <ReturnType> *)
  red:=tok.Reduction;
  priv:='';
  if(acc=ACCESS_PRIVATE) then begin
      AddLibraryPrivate(name);
      priv:='private ';
  end;
  ret:=TranslateReturnType(red.Tokens[4]);
  takes:=translateTakes(red.Tokens[2]);
  Concatenate7(tem, priv, 'function interface ',name,' takes ',takes,' returns ',ret);
  WriteOutPutLine(tem, tok.LineNumber, indent);



end;



procedure TranslateTypeExtends(const tok:Ttoken; const acc:TAccessModifier; const name:string; const indent:integer);
var
    red:Treduction;
begin
    red:=tok.Reduction;
    case RuleConstants(Red.ParentRule.TableIndex) of
        RULE_TYPEEXTENDS: (* <TypeExtends> ::= <DynamicArray> *)
        begin
            TranslateDynamicArray(red.Tokens[0], acc,name, indent);
        end;
        RULE_TYPEEXTENDS2: (* <TypeExtends> ::= <FunctionInterface> *)
        begin
            TranslateFunctionInterface(red.Tokens[0], acc,name, indent);
        end;
    end;
end;

procedure TranslateTypeDef(tok:TToken; const defacc:Taccessmodifier; const indent:integer=0);
var
    red:Treduction;
    acc:TAccessModifier;
    name:string;
begin
    red:=tok.Reduction;
    case RuleConstants(Red.ParentRule.TableIndex) of
         RULE_TYPEDEF_TYPE_IDENTIFIER_EXTENDS_SEMI:
         (* <TypeDef> ::= <PrivatePublic> type Identifier extends <TypeExtends> ; *)
         begin
             acc := TranslatePublicPrivate(red.Tokens[0], defacc);
             name:= TranslateTerminal(red.Tokens[2] );
             TranslateTypeExtends( red.Tokens[4], acc, name, indent);
         end;
    end;

end;

procedure TranslateLibraryMembers(tok:TToken; const defacc: Taccessmodifier; const indent:integer=0); forward;
procedure TranslateLibraryPP(tok:TToken; const indent:integer=0);
var
   red:Treduction;
   acc:TaccessModifier;
   modi:string;

begin
(* <LibraryPPBlock> ::= <PrivatePublic> { <LibraryMembers> } *)
    red:=tok.Reduction;
    modi:=TranslateTerminal(red.Tokens[0]);
    if(modi='') then raise ZincLineError(TokenLine2(red.Tokens[0]), 'Expected: public or private');

    if(modi='private') then acc:=ACCESS_PRIVATE
    else acc:=ACCESS_PUBLIC;
    WriteOutputLine('//'+modi+':', TokenLine1(tok), indent);

    TranslateLibraryMembers(red.Tokens[2], acc, indent+1);

end;


//-----


procedure TranslateLibraryMember(tok:TToken; const defacc:Taccessmodifier; const indent:integer=0);
var
    red:Treduction;
begin
    red:=tok.Reduction;
    case RuleConstants(Red.ParentRule.TableIndex) of
        RULE_LIBRARYMEMBER: (* <LibraryMember> ::= <GlobalVariableDeclaration> *)
        begin
            TranslateGlobalVariables(red.Tokens[0], defacc ,indent);
        end;
        RULE_LIBRARYMEMBER2: (* <LibraryMember> ::= <Function> *)
        begin
            TranslateFunction(red.Tokens[0], defacc, indent);
        end;
        RULE_LIBRARYMEMBER3: (* <LibraryMember> ::= <Struct> *)
        begin
            TranslateStruct(red.Tokens[0], defacc, indent);
        end;
        RULE_LIBRARYMEMBER4: (* <LibraryMember> ::= <Module> *)
        begin
            TranslateModule(red.Tokens[0], defacc, indent);
        end;
        RULE_LIBRARYMEMBER5: (* <LibraryMember> ::= <Interface> *)
        begin
            TranslateInterface(red.Tokens[0], defacc, indent);
        end;
        RULE_LIBRARYMEMBER6: (* <LibraryMember> ::= <TypeDef> *)
        begin
            TranslateTypeDef(red.Tokens[0],  defacc, indent);
        end;
        RULE_LIBRARYMEMBER7: (* <LibraryMember> ::= <Preprocessor> *)
        begin
            TranslatePreprocessor(red.Tokens[0]);
        end;
        RULE_LIBRARYMEMBER8: (* <LibraryMember> ::= <LibraryPPBlock> *)
        begin
            TranslateLibraryPP(red.Tokens[0],  indent);
        end;
    end;

end;

procedure TranslateLibraryMembers(tok:TToken; const defacc: Taccessmodifier; const indent:integer=0);
var
    red:Treduction;
begin
    red:=tok.Reduction;
    case RuleConstants(Red.ParentRule.TableIndex) of
      RULE_LIBRARYMEMBERS  : (* <LibraryMembers> ::= <LibraryMember> <LibraryMembers> *)
      begin
         TranslateLibraryMember(red.Tokens[0], defacc, indent);
         TranslateLibraryMembers(red.Tokens[1], defacc, indent);
      end;
      RULE_LIBRARYMEMBERS2 : (* <LibraryMembers> ::=  *)
      begin
        Exit;
      end;

    end;

end;

//**********************************************************************
function TranslateSingleRequirement(tok:TToken):string;
var
   red:TReduction;
begin

   red:=tok.Reduction;
   if red.TokenCount = 1 then begin
       (* <Requirement> ::= * *)
       Result:= TranslateTerminal(red.Tokens[0]);
   end else begin
       (* <Requirement> ::= <RequirementOptional> Identifier *)
       Result:= TranslateTerminal(red.Tokens[0])+' '+TranslateTerminal(red.Tokens[1]);
   end;

end;

function TranslateLibraryRequirementList(tok:TToken; out reqall:boolean):string;
var
   red:TReduction;
   tem:string;
   label restart;
begin
   reqall:=false;
   Result:='';
   restart:
   red:=tok.Reduction;
   tem:=TranslateSingleRequirement(red.tokens[0]);

   if(tem='*') then begin
       reqall:=true;
   end;

   case RuleConstants(Red.ParentRule.TableIndex) of
       RULE_REQUIREMENTLIST_COMMA: (* <RequirementList> ::= <Requirement> , <RequirementList> *)
       begin
          Result:=Result+tem+', ';
          tok := red.Tokens[2];
          goto restart;
       end;
       RULE_REQUIREMENTLIST: (* <RequirementList> ::= <Requirement> *)
       begin
          Result:=Result+tem;
       end;

   end;
end;

function TranslateLibraryRequirements(tok:TToken; out reqall:boolean):string;
var
   red:TReduction;
begin
   reqall:=false;
   red:=tok.Reduction;
   case RuleConstants(Red.ParentRule.TableIndex) of
       RULE_LIBRARYREQUIREMENTS_REQUIRES: (* <LibraryRequirements> ::= requires <RequirementList> *)
       begin
          Result:=' requires '+TranslateLibraryRequirementList(red.Tokens[1], reqall );
       end;
       RULE_LIBRARYREQUIREMENTS: (* <LibraryRequirements> ::=  *)
       begin
          Result:=''; //nothing here
       end;

   end;
end;

procedure TranslateLibrary(tok:TToken);
var
    red:Treduction;
(* <Library> ::= library Identifier <LibraryRequirements> { <LibraryMembers> } *)
    tem,name,reqs:string;
    x,i:integer;
    reqall:boolean;

begin
    red:=Tok.Reduction;
    //if(RuleConstants(red.ParentRule.TableIndex) <> RULE_LIBRARY_LIBRARY_IDENTIFIER_LBRACE_RBRACE) then
    name:=TranslateTerminal(red.Tokens[1]);
    reqs:=TranslateLibraryRequirements(red.tokens[2], reqall);
    lib_privates:=0;
    if(reqall) then begin
        raise ZincLineError(TokenLine1(red.Tokens[1]),'Unexpected: "*"');
        Concatenate3(tem, 'scope ',name,' initializer onInit');
    end else begin
        Concatenate4(tem, 'library ',name,' initializer onInit ',reqs);
    end;
    WriteOutputLine(tem, TokenLine1(tok));
    x:=oln;

    TranslateLibraryMembers(red.Tokens[4],ACCESS_PRIVATE, 1);
    if(reqall) then
        WriteOutputLine('endscope', TokenLine2(tok))
    else
        WriteOutputLine('endlibrary', TokenLine2(tok));

    if( Length(output) < oln+lib_privates ) then begin
        SetLength(output, oln+lib_privates+50);
        SetLength(outputfrom,Length(output)) ;
    end;

    for i := oln-1 downto x do begin
        output[i+lib_privates]:=output[i];
        outputfrom[i+lib_privates]:=outputfrom[i];
    end;
    for i := 0 to lib_privates-1 do begin
        if(lib_private[i]<>'onInit') then begin
            output[x+i] := '    private keyword '+lib_private[i];
            outputfrom[x+i]:=1;
        end else begin
            output[x+i] := '';
            outputfrom[x+i]:=1;

        end;
    end;
    oln:=oln+lib_privates;


end;


procedure TranslateZinc(red: TReduction);


begin

    case RuleConstants(Red.ParentRule.TableIndex) of

       RULE_ZINC: (* <Zinc> ::= <Library> <Zinc> *)
       begin
            TranslateLibrary(red.Tokens[0]);
            TranslateZinc(red.Tokens[1].Reduction );
       end;
       RULE_ZINC2: (* <Zinc> ::= <Preprocessor> <Zinc> *)
       begin
            TranslatePreprocessor(red.Tokens[0]);
            TranslateZinc(red.Tokens[1].Reduction);
       end;
       RULE_ZINC3: (* <Zinc> ::=  *)
       begin
            exit;
       end;

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

         lHandle := FindResource(0, 'ZINCGRAMMAR', RT_RCDATA);
         lResource := LockResource(LoadResource(0, lHandle));
         if lResource = nil then begin

             if (fileexists(GRAMMAR_PATH)) then begin
                 parser:=TGoldParser.Create;
                 if not Parser.LoadCompiledGrammar(GRAMMAR_PATH) then raise Exception.Create('Load grammar error');
                 exit;

             end else if (fileExists('zinc.cgt')) then begin
                 parser:=TGoldParser.Create;
                 if not Parser.LoadCompiledGrammar('zinc.cgt') then raise Exception.Create('Load grammar error');
                 exit;
             end else begin
                 raise Exception.Create('Zinc: nil Resource and unable to find external cgt file.');;
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

//*---------------
// public:
procedure Parse;
 var done:boolean;
     Response:Integer;
     i:integer;
     inputtext:string;
begin
     initParser;
     oln:=0;
     inputtext:='';
     for i := 0 to ln - 1 do begin
         SWriteLn(inputtext, input[i]);
     end;



    if (not Parser.OpenTextString(inputtext)) then raise ZincLineError(0,'Unknown internal error 1');

    Done := False;
    while not Done do
    begin
            Response := Parser.Parse;

            case Response of
                gpMsgLexicalError:
                begin
                    raise ZincLineError(Parser.CurrentLineNumber, 'Unexpected : '+Parser.CurrentToken.DataVar);
                end;
                gpMsgSyntaxError: begin
                    raise ZincLineError(Parser.CurrentLineNumber, 'Syntax Error (Unexpected: "'+Parser.CurrentToken.Datavar+'"?');
                end;
                gpMsgAccept:
                    Done := True;
                gpMsgInternalError:  begin
                    raise ZincLineError(Parser.CurrentLineNumber, 'Syntax Error');
                end;

                gpMsgNotLoadedError: begin
                     raise Exception.Create('Zinc parser not loaded');
                end;

                gpMsgCommentError: begin
                    raise ZincLineError(Parser.CurrentLineNumber, 'Syntax Error: Unexpected end of line??');
                end;
            end;
    end;


    //Hehem parsed correctly!!! Now we *just* have to translate the reductions
    TranslateZinc(parser.CurrentReduction);


end;

var lastseen:integer;
procedure ResetInput; begin
   lastseen:=0;
   ln:=0;
   anoncount := 0;
end;
function GetComment(const s:string): string;
var
   i,len:integer;
begin
   len:=Length(s);
   for i := 1 to len-1 do begin
       if(i<len) and (s[i]='/') and (s[i+1]='/') and ( (i+2>len) or (s[i+2]<>'!') ) then begin
           result:=' '+Copy(s,i,Length(s)-i+1);
           exit;
       end;
   end;
   result:='';

end;

procedure AddInputLine(const s:string); begin
   if(Length(input) <= ln) then begin
       SetLength(input, ln+20+ln div 5 );
       SetLength(inputcomment, Length(input) );
   end;
   input[ln]:=s;
   inputcomment[ln]:=GetComment(input[ln]);
   ln:=ln+1;
end;
function  GetOutputLineCount:integer;
begin
   Result:=oln;
end;


function GetOutputLine(const i:integer):string;
var x,j:integer;
    comm:string;
begin
   x:=outputfrom[i];
   comm:='';
   if( x >= ln) then begin
       x:=ln-1;
       //       raise exception.Create('what happened?');
   end;

   for j:=lastseen+1 to x do begin
       comm:=comm+inputcomment[j];
       inputcomment[j]:='';
   end;
   lastseen:=x;
   if(comm<>'') then begin
       Result:=output[i]+' '+comm;
   end else
       Result:=output[i];
end;

function GeTOutputLineSource(const i:integer):integer;
begin
   Result:=outputfrom[i];;
end;

end.

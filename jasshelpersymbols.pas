unit jasshelpersymbols;

interface

type SymbolConstants = (
   SYMBOL_EOF              =  0, (* (EOF) *)
   SYMBOL_ERROR            =  1, (* (Error) *)
   SYMBOL_WHITESPACE       =  2, (* Whitespace *)
   SYMBOL_MINUS            =  3, (* '-' *)
   SYMBOL_EXCLAMEQ         =  4, (* '!=' *)
   SYMBOL_PERCENT          =  5, (* '%' *)
   SYMBOL_LPARAN           =  6, (* '(' *)
   SYMBOL_RPARAN           =  7, (* ')' *)
   SYMBOL_TIMES            =  8, (* '*' *)
   SYMBOL_COMMA            =  9, (* ',' *)
   SYMBOL_DOT              = 10, (* '.' *)
   SYMBOL_DIV              = 11, (* '/' *)
   SYMBOL_COLON            = 12, (* ':' *)
   SYMBOL_LBRACKET         = 13, (* '[' *)
   SYMBOL_RBRACKET         = 14, (* ']' *)
   SYMBOL_PLUS             = 15, (* '+' *)
   SYMBOL_LT               = 16, (* '<' *)
   SYMBOL_LTEQ             = 17, (* '<=' *)
   SYMBOL_EQ               = 18, (* '=' *)
   SYMBOL_EQEQ             = 19, (* '==' *)
   SYMBOL_GT               = 20, (* '>' *)
   SYMBOL_GTEQ             = 21, (* '>=' *)
   SYMBOL_AND              = 22, (* and *)
   SYMBOL_CALL             = 23, (* call *)
   SYMBOL_COMMENTX         = 24, (* Commentx *)
   SYMBOL_ELSE             = 25, (* else *)
   SYMBOL_ELSEIF           = 26, (* elseif *)
   SYMBOL_ENDIF            = 27, (* endif *)
   SYMBOL_ENDLOOP          = 28, (* endloop *)
   SYMBOL_EXITWHEN         = 29, (* exitwhen *)
   SYMBOL_FUNCTION         = 30, (* function *)
   SYMBOL_IDENTIFIER       = 31, (* Identifier *)
   SYMBOL_IF               = 32, (* if *)
   SYMBOL_LOCAL            = 33, (* local *)
   SYMBOL_LOOP             = 34, (* loop *)
   SYMBOL_NOT              = 35, (* not *)
   SYMBOL_NUMBERLITERAL    = 36, (* NumberLiteral *)
   SYMBOL_OR               = 37, (* or *)
   SYMBOL_RETURN           = 38, (* return *)
   SYMBOL_SET              = 39, (* set *)
   SYMBOL_STRINGLITERAL    = 40, (* StringLiteral *)
   SYMBOL_THEN             = 41, (* then *)
   SYMBOL_ADDITION         = 42, (* <Addition> *)
   SYMBOL_AND2             = 43, (* <And> *)
   SYMBOL_ARGFUNCTION      = 44, (* <ArgFunction> *)
   SYMBOL_ARGMETHOD        = 45, (* <ArgMethod> *)
   SYMBOL_ARGUMENTS        = 46, (* <Arguments> *)
   SYMBOL_ASSIGNARRAY      = 47, (* <AssignArray> *)
   SYMBOL_ASSIGNARRAYSUF   = 48, (* <AssignArraySuf> *)
   SYMBOL_ASSIGNLOCAL      = 49, (* <AssignLocal> *)
   SYMBOL_ASSIGNMEMBER     = 50, (* <AssignMember> *)
   SYMBOL_ASSIGNVAR        = 51, (* <AssignVar> *)
   SYMBOL_BRACES           = 52, (* <Braces> *)
   SYMBOL_CALL2            = 53, (* <Call> *)
   SYMBOL_CODEVALUE        = 54, (* <CodeValue> *)
   SYMBOL_DIVISION         = 55, (* <Division> *)
   SYMBOL_DOTABLE          = 56, (* <Dotable> *)
   SYMBOL_EQUALTO          = 57, (* <EqualTo> *)
   SYMBOL_EXITWHEN2        = 58, (* <Exitwhen> *)
   SYMBOL_EXPRESSION       = 59, (* <Expression> *)
   SYMBOL_EXPRESSION2      = 60, (* <Expression2> *)
   SYMBOL_EXPRESSION3      = 61, (* <Expression3> *)
   SYMBOL_EXPRESSION4      = 62, (* <Expression4> *)
   SYMBOL_EXPRESSION5      = 63, (* <Expression5> *)
   SYMBOL_EXPRESSION6      = 64, (* <Expression6> *)
   SYMBOL_EXPRESSION7      = 65, (* <Expression7> *)
   SYMBOL_EXPRESSION8      = 66, (* <Expression8> *)
   SYMBOL_FUNCTION2        = 67, (* <Function> *)
   SYMBOL_GETARRAY         = 68, (* <GetArray> *)
   SYMBOL_GETARRAYSUF      = 69, (* <GetArraySuf> *)
   SYMBOL_GETMEMBER        = 70, (* <GetMember> *)
   SYMBOL_GREATERTHAN      = 71, (* <GreaterThan> *)
   SYMBOL_GREATERTHANEQUAL = 72, (* <GreaterThanEqual> *)
   SYMBOL_IFELSEIF         = 73, (* <IfElseIf> *)
   SYMBOL_LESSTHAN         = 74, (* <LessThan> *)
   SYMBOL_LESSTHANEQUAL    = 75, (* <LessThanEqual> *)
   SYMBOL_LINE             = 76, (* <Line> *)
   SYMBOL_LOCAL2           = 77, (* <Local> *)
   SYMBOL_LOGICALBINARY    = 78, (* <LogicalBinary> *)
   SYMBOL_MEMBERCODEVALUE  = 79, (* <MemberCodeValue> *)
   SYMBOL_METHOD           = 80, (* <Method> *)
   SYMBOL_MODULO           = 81, (* <Modulo> *)
   SYMBOL_NEGATIVE         = 82, (* <Negative> *)
   SYMBOL_NOT2             = 83, (* <Not> *)
   SYMBOL_NOTEQUALTO       = 84, (* <NotEqualTo> *)
   SYMBOL_NOTHINGFUNCTION  = 85, (* <NothingFunction> *)
   SYMBOL_NOTHINGMETHOD    = 86, (* <NothingMethod> *)
   SYMBOL_OR2              = 87, (* <Or> *)
   SYMBOL_PRODUCT          = 88, (* <Product> *)
   SYMBOL_RETURN2          = 89, (* <Return> *)
   SYMBOL_SINGLEKEYWORD    = 90, (* <SingleKeyword> *)
   SYMBOL_STATEMENT        = 91, (* <Statement> *)
   SYMBOL_SUBTRACTION      = 92  (* <Subtraction> *)
);

type RuleConstants = (
   RULE_LINE_COMMENTX                                      =  0, (* <Line> ::= <Statement> Commentx *)
   RULE_LINE                                               =  1, (* <Line> ::= <Statement> *)
   RULE_STATEMENT                                          =  2, (* <Statement> ::= <Expression> *)
   RULE_STATEMENT2                                         =  3, (* <Statement> ::= <AssignVar> *)
   RULE_STATEMENT3                                         =  4, (* <Statement> ::= <AssignMember> *)
   RULE_STATEMENT4                                         =  5, (* <Statement> ::= <AssignLocal> *)
   RULE_STATEMENT5                                         =  6, (* <Statement> ::= <Local> *)
   RULE_STATEMENT6                                         =  7, (* <Statement> ::= <AssignArray> *)
   RULE_STATEMENT7                                         =  8, (* <Statement> ::= <AssignArraySuf> *)
   RULE_STATEMENT8                                         =  9, (* <Statement> ::= <Call> *)
   RULE_STATEMENT9                                         = 10, (* <Statement> ::= <SingleKeyword> *)
   RULE_STATEMENT10                                        = 11, (* <Statement> ::= <IfElseIf> *)
   RULE_STATEMENT11                                        = 12, (* <Statement> ::= <Exitwhen> *)
   RULE_STATEMENT12                                        = 13, (* <Statement> ::= <Return> *)
   RULE_IFELSEIF_IF_THEN                                   = 14, (* <IfElseIf> ::= if <Expression> then *)
   RULE_IFELSEIF_ELSEIF_THEN                               = 15, (* <IfElseIf> ::= elseif <Expression> then *)
   RULE_SINGLEKEYWORD_LOOP                                 = 16, (* <SingleKeyword> ::= loop *)
   RULE_SINGLEKEYWORD_ENDLOOP                              = 17, (* <SingleKeyword> ::= endloop *)
   RULE_SINGLEKEYWORD_ENDIF                                = 18, (* <SingleKeyword> ::= endif *)
   RULE_SINGLEKEYWORD_ELSE                                 = 19, (* <SingleKeyword> ::= else *)
   RULE_CALL_CALL                                          = 20, (* <Call> ::= call <Function> *)
   RULE_CALL_CALL2                                         = 21, (* <Call> ::= call <Method> *)
   RULE_ASSIGNVAR_SET_IDENTIFIER_EQ                        = 22, (* <AssignVar> ::= set Identifier '=' <Expression> *)
   RULE_ASSIGNMEMBER_SET_DOT_IDENTIFIER_EQ                 = 23, (* <AssignMember> ::= set <Dotable> '.' Identifier '=' <Expression> *)
   RULE_ASSIGNARRAYSUF_SET_COLON_IDENTIFIER_EQ             = 24, (* <AssignArraySuf> ::= set <Expression8> ':' Identifier '=' <Expression> *)
   RULE_ASSIGNLOCAL_LOCAL_IDENTIFIER_EQ                    = 25, (* <AssignLocal> ::= local Identifier '=' <Expression> *)
   RULE_ASSIGNARRAY_SET_LBRACKET_RBRACKET_EQ               = 26, (* <AssignArray> ::= set <Expression8> '[' <Expression> ']' '=' <Expression> *)
   RULE_LOCAL_LOCAL_IDENTIFIER                             = 27, (* <Local> ::= local Identifier *)
   RULE_EXITWHEN_EXITWHEN                                  = 28, (* <Exitwhen> ::= exitwhen <Expression> *)
   RULE_RETURN_RETURN                                      = 29, (* <Return> ::= return <Expression> *)
   RULE_RETURN_RETURN2                                     = 30, (* <Return> ::= return *)
   RULE_BRACES_LPARAN_RPARAN                               = 31, (* <Braces> ::= '(' <Expression> ')' *)
   RULE_CODEVALUE_FUNCTION_IDENTIFIER                      = 32, (* <CodeValue> ::= function Identifier *)
   RULE_MEMBERCODEVALUE_FUNCTION_IDENTIFIER_DOT_IDENTIFIER = 33, (* <MemberCodeValue> ::= function Identifier '.' Identifier *)
   RULE_FUNCTION                                           = 34, (* <Function> ::= <NothingFunction> *)
   RULE_FUNCTION2                                          = 35, (* <Function> ::= <ArgFunction> *)
   RULE_NOTHINGFUNCTION_IDENTIFIER_LPARAN_RPARAN           = 36, (* <NothingFunction> ::= Identifier '(' ')' *)
   RULE_ARGFUNCTION_IDENTIFIER_LPARAN_RPARAN               = 37, (* <ArgFunction> ::= Identifier '(' <Arguments> ')' *)
   RULE_GETARRAY_LBRACKET_RBRACKET                         = 38, (* <GetArray> ::= <Expression8> '[' <Expression> ']' *)
   RULE_GETARRAYSUF_COLON_IDENTIFIER                       = 39, (* <GetArraySuf> ::= <Expression8> ':' Identifier *)
   RULE_ARGUMENTS                                          = 40, (* <Arguments> ::= <Expression> *)
   RULE_ARGUMENTS_COMMA                                    = 41, (* <Arguments> ::= <Expression> ',' <Arguments> *)
   RULE_DOTABLE                                            = 42, (* <Dotable> ::= <Expression8> *)
   RULE_DOTABLE2                                           = 43, (* <Dotable> ::=  *)
   RULE_GETMEMBER_DOT_IDENTIFIER                           = 44, (* <GetMember> ::= <Dotable> '.' Identifier *)
   RULE_NOTHINGMETHOD_DOT_IDENTIFIER_LPARAN_RPARAN         = 45, (* <NothingMethod> ::= <Dotable> '.' Identifier '(' ')' *)
   RULE_ARGMETHOD_DOT_IDENTIFIER_LPARAN_RPARAN             = 46, (* <ArgMethod> ::= <Dotable> '.' Identifier '(' <Arguments> ')' *)
   RULE_METHOD                                             = 47, (* <Method> ::= <NothingMethod> *)
   RULE_METHOD2                                            = 48, (* <Method> ::= <ArgMethod> *)
   RULE_EXPRESSION8                                        = 49, (* <Expression8> ::= <GetArray> *)
   RULE_EXPRESSION82                                       = 50, (* <Expression8> ::= <GetArraySuf> *)
   RULE_EXPRESSION83                                       = 51, (* <Expression8> ::= <GetMember> *)
   RULE_EXPRESSION84                                       = 52, (* <Expression8> ::= <Function> *)
   RULE_EXPRESSION85                                       = 53, (* <Expression8> ::= <Method> *)
   RULE_EXPRESSION8_IDENTIFIER                             = 54, (* <Expression8> ::= Identifier *)
   RULE_EXPRESSION8_NUMBERLITERAL                          = 55, (* <Expression8> ::= NumberLiteral *)
   RULE_EXPRESSION8_STRINGLITERAL                          = 56, (* <Expression8> ::= StringLiteral *)
   RULE_EXPRESSION86                                       = 57, (* <Expression8> ::= <CodeValue> *)
   RULE_EXPRESSION87                                       = 58, (* <Expression8> ::= <MemberCodeValue> *)
   RULE_EXPRESSION88                                       = 59, (* <Expression8> ::= <Braces> *)
   RULE_NOT_NOT                                            = 60, (* <Not> ::= not <Expression7> *)
   RULE_EXPRESSION7                                        = 61, (* <Expression7> ::= <Not> *)
   RULE_EXPRESSION72                                       = 62, (* <Expression7> ::= <Expression8> *)
   RULE_NEGATIVE_MINUS                                     = 63, (* <Negative> ::= '-' <Expression6> *)
   RULE_EXPRESSION6                                        = 64, (* <Expression6> ::= <Negative> *)
   RULE_EXPRESSION62                                       = 65, (* <Expression6> ::= <Expression7> *)
   RULE_PRODUCT_TIMES                                      = 66, (* <Product> ::= <Expression6> '*' <Expression5> *)
   RULE_DIVISION_DIV                                       = 67, (* <Division> ::= <Expression6> '/' <Expression5> *)
   RULE_EXPRESSION5                                        = 68, (* <Expression5> ::= <Product> *)
   RULE_EXPRESSION52                                       = 69, (* <Expression5> ::= <Division> *)
   RULE_EXPRESSION53                                       = 70, (* <Expression5> ::= <Expression6> *)
   RULE_MODULO_PERCENT                                     = 71, (* <Modulo> ::= <Expression5> '%' <Expression4> *)
   RULE_ADDITION_PLUS                                      = 72, (* <Addition> ::= <Expression5> '+' <Expression4> *)
   RULE_SUBTRACTION_MINUS                                  = 73, (* <Subtraction> ::= <Expression5> '-' <Expression4> *)
   RULE_EXPRESSION4                                        = 74, (* <Expression4> ::= <Addition> *)
   RULE_EXPRESSION42                                       = 75, (* <Expression4> ::= <Subtraction> *)
   RULE_EXPRESSION43                                       = 76, (* <Expression4> ::= <Modulo> *)
   RULE_EXPRESSION44                                       = 77, (* <Expression4> ::= <Expression5> *)
   RULE_GREATERTHAN_GT                                     = 78, (* <GreaterThan> ::= <Expression4> '>' <Expression4> *)
   RULE_GREATERTHANEQUAL_GTEQ                              = 79, (* <GreaterThanEqual> ::= <Expression4> '>=' <Expression4> *)
   RULE_LESSTHAN_LT                                        = 80, (* <LessThan> ::= <Expression4> '<' <Expression4> *)
   RULE_LESSTHANEQUAL_LTEQ                                 = 81, (* <LessThanEqual> ::= <Expression4> '<=' <Expression4> *)
   RULE_EXPRESSION3                                        = 82, (* <Expression3> ::= <GreaterThan> *)
   RULE_EXPRESSION32                                       = 83, (* <Expression3> ::= <GreaterThanEqual> *)
   RULE_EXPRESSION33                                       = 84, (* <Expression3> ::= <LessThan> *)
   RULE_EXPRESSION34                                       = 85, (* <Expression3> ::= <LessThanEqual> *)
   RULE_EXPRESSION35                                       = 86, (* <Expression3> ::= <Expression4> *)
   RULE_EQUALTO_EQEQ                                       = 87, (* <EqualTo> ::= <Expression3> '==' <Expression3> *)
   RULE_NOTEQUALTO_EXCLAMEQ                                = 88, (* <NotEqualTo> ::= <Expression3> '!=' <Expression3> *)
   RULE_EXPRESSION2                                        = 89, (* <Expression2> ::= <EqualTo> *)
   RULE_EXPRESSION22                                       = 90, (* <Expression2> ::= <NotEqualTo> *)
   RULE_EXPRESSION23                                       = 91, (* <Expression2> ::= <Expression3> *)
   RULE_AND_AND                                            = 92, (* <And> ::= <Expression2> and <Expression> *)
   RULE_OR_OR                                              = 93, (* <Or> ::= <Expression2> or <Expression> *)
   RULE_LOGICALBINARY                                      = 94, (* <LogicalBinary> ::= <And> *)
   RULE_LOGICALBINARY2                                     = 95, (* <LogicalBinary> ::= <Or> *)
   RULE_EXPRESSION                                         = 96, (* <Expression> ::= <LogicalBinary> *)
   RULE_EXPRESSION9                                        = 97  (* <Expression> ::= <Expression2> *)
);

implementation

end.

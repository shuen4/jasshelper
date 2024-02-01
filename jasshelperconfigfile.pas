unit JassHelperConfigFile;

interface

type TDynamicStringArray = array of string;
procedure readConfig(const possibleFilePaths: TDynamicStringArray);
var
 CONFIG_PATH:string;
 EXTERNAL_PROGRAMS: array of string;
 EXTERNAL_NAMES: array of string;
 EXTERNAL_N : integer = 0;
 WORK_PATHS: string = '';
 WEWARLOCK_PATH: string = '';
 JASS_COMPILER: string = 'pjass.exe';
 JASS_COMPILER_LINE: string ='$COMMONJ $BLIZZARDJ $WAR3MAPJ';

 ENABLE_RETURN_FIXER :boolean = false;
 ENABLE_SHADOW_HELPER: boolean = true;
 AUTO_METHOD_EVALUATE: boolean = true;
 DISABLE_IMPLICIT_THIS: boolean = false;
function ParserCommandLine(const commonj: string; const blizzardj:string; const war3mapj:string):string;


implementation
uses windows,   SysUtils, jasshelper;


function ParserCommandLine(const commonj: string; const blizzardj:string; const war3mapj:string):string;
begin
    Result:=JASS_COMPILER_LINE;
    Result:=StringReplace(Result, '$COMMONJ', commonj, [rfReplaceAll,rfIgnoreCase]);
    Result:=StringReplace(Result, '$BLIZZARDJ', blizzardj, [rfReplaceAll,rfIgnoreCase]);
    Result:=StringReplace(Result, '$WAR3MAPJ', war3mapj, [rfReplaceAll,rfIgnoreCase]);
end;



// Currently just reads config file to get import paths
procedure readConfig(const possibleFilePaths: TDynamicStringArray);
var f:textfile;
   open:boolean;
   line,a,b:string;
   i,j,L:integer;
   s_path:boolean;
   s_war:boolean;
   s_ext:boolean;
   s_comp, s_comp2:boolean;

begin
open:=false;

   s_path:=false;
   s_ext:=false;
   s_war:=false;
   s_comp:=false;
   s_comp2:=false;

   CONFIG_PATH := possibleFilePaths[0];
   for i := 0 to Length(possibleFilePaths)-1 do
      if(FileExists(possibleFilePaths[i]) ) then begin
           CONFIG_PATH:=                possibleFilePaths[i];
           break;
      end;
    WEWARLOCK_PATH:='';
    JASS_COMPILER:='pjass.exe';
    EXTERNAL_N := 0;
    WORK_PATHS:= '';
 try
    if (FileExists(CONFIG_PATH)) then begin
        AssignFile(f,CONFIG_PATH);
        filemode:=fmOpenRead;
        Reset(f);        open:=true;
        while not EoF(f) do begin
            ReadLn(f,line);
            L:=Length(line);
            if(L>1) then
            begin
                if(line[1]='/') then
                else if (line[1]='[') then begin
                    s_path:=false;
                    s_ext:=false;
                    s_war:=false;
                    s_comp:=false;
                    if (line='[lookupfolders]') then s_path:=true
                    else if (line='[externaltools]') then s_ext:=true
                    else if (line='[wewarlock]') then s_war:=true
                    else if (line='[jasscompiler]') then s_comp:=true
                    else if (line='[doreturnfixer]') then ENABLE_RETURN_FIXER:=True
                    else if (line='[noreturnfixer]') then ENABLE_RETURN_FIXER:=False
                    else if (line='[doshadowfixer]') then ENABLE_SHADOW_HELPER:=True
                    else if (line='[noshadowfixer]') then ENABLE_SHADOW_HELPER:=False
                    else if (line='[automethodevaluate]') then AUTO_METHOD_EVALUATE:=True
                    else if (line='[forcemethodevaluate]') then AUTO_METHOD_EVALUATE:=false
                    else if (line='[noimplicitthis]') then DISABLE_IMPLICIT_THIS := true
                         
                    ;

                         

                    //section
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



                        SetLength(EXTERNAL_PROGRAMS,EXTERNAL_N+1);
                        SetLength(EXTERNAL_Names,EXTERNAL_N+1);

                        EXTERNAL_PROGRAMS[EXTERNAL_N]:=b;
                        EXTERNAL_Names[EXTERNAL_N]:=a;

                        EXTERNAL_N:=EXTERNAL_N+1;


                    end else if (s_path)  then begin
                        i:=2;
                        while( i<=L) and (line[i]<>'"') do i:=i+1;
                        if(i>L) then i:=L
                        else i:=i-1;
                        a:=Copy(line,2,i-1);
                        jasshelper.addImportPath(a);
                        if (WORK_PATHS='') then WORK_PATHS:=a
                        else WORK_PATHS:=WORK_PATHS+';'+a;

                    end else if (s_comp)  then begin
                        i:=2;
                        while( i<=L) and (line[i]<>'"') do i:=i+1;
                        if(i>L) then i:=L
                        else i:=i-1;
                        a:=Copy(line,2,i-1);
                        if(not s_comp2) then begin
                            JASS_COMPILER := a;
                            s_comp2:=true;
                        end else begin
                            JASS_COMPILER_LINE := a;
                        end;



                    end else if(s_war) then begin
                        i:=2;
                        while( i<=L) and (line[i]<>'"') do i:=i+1;
                        if(i>L) then i:=L
                        else i:=i-1;
                        a:=Copy(line,2,i-1);
                        WEWARLOCK_PATH:=a;

                    end;
                end;
            end;
        end;
    end else begin
        AssignFile(f,CONFIG_PATH);

        filemode:=fmOpenWrite;
        Rewrite(f);        open:=true;
        WriteLn(f,'[lookupfolders]');
        WriteLn(f,'// Just type the folders where //! import would look for if relative paths where used, include the final \');
        WriteLn(f,'// embed them in quotes');
        WriteLn(f,'// example: "c:\"');
        WriteLn(f,'// The order determines priority:');
        WriteLn(f,'".\jass\"');
        WriteLn(f,'');
        WriteLn(f,'[jasscompiler]');
        WriteLn(f,'//this is to specify what compiler to use, normally pjass.exe, you may also want to use JassParserCLI.exe ...');
        WriteLn(f,'"pjass.exe"');
        WriteLn(f,'//the following line specifies the way the jass syntax checker''s arguments are used ...');
        WriteLn(f,'"$COMMONJ $BLIZZARDJ $WAR3MAPJ"');
        WriteLn(f,'');
        WriteLn(f,'[externaltools]');
        WriteLn(f,'// this is for //! external NAME args the syntax is "NAME","executable path"');
        WriteLn(f,'// example:');
        WriteLn(f,'//"OBJMERGE","c:\kool.exe"');
        WriteLn(f,'');
        WriteLn(f,'//To enable automatic .evaluate of methods that are called from above their declaration');
        WriteLn(f,'// add a line containing: [automethodevaluate]') ;
        WriteLn(f,'//this is enabled by default, to disable it');
        WriteLn(f,'// add a line containing: [forcemethodevaluate]');
        WriteLn(f,'//To disable the "implicit this" feature that was added in 0.A.0.0');
        WriteLn(f,'// add a line containing: [noimplicitthis]');

        jasshelper.addImportPath('.\jass\');
        if (WORK_paths='') then WORK_paths:='.\jass\'
        else WORK_paths:=WORK_paths+';.\jass\';




    end;

 finally
   if(open) then Close(f);

 end;


end;


end.

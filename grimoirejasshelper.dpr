program grimoirejasshelper;

{$R 'grammar.res' 'grammar.rc'}

uses
  Forms,
  SysUtils,
  Windows,
  Tlhelp32,
  grimoirecompiler in 'grimoirecompiler.pas' {Form4},
  jasshelper in 'jasshelper.pas',
  winexec in 'winexec.pas',
  vxFilesys in 'vxFilesys.pas',
  about in 'about.pas' {Aboutdialog},
  progress in 'progress.pas' {Form5},
  storm in 'storm.pas',
  grimjhconfp in 'grimjhconfp.pas' {grimjhconf},
  warlockerror in 'warlockerror.pas' {Form2},
  slk in 'slk.pas',
  jasshelpersymbols in 'jasshelpersymbols.pas',
  jasshelperconfigfile in 'jasshelperconfigfile.pas';

{$R *.res}

var
   debug:boolean=false;nopre:boolean=false;noopt:boolean=false;
   scriptmode:boolean=false;
   temi:integer=0;
   stage:integer=1;
   war3mapj,f1,f2,f3,map,{output,}compiled,folder,blizzardj,commonj:string;
   mpq:THandle;

   Exter:Texternalusage;
   CONFIG_PATH:string='';
   JASSHELPER_PATH:string='';




function GetSuffixedName(x,suf:string):string;
var
   i,L:integer;
begin
    L:=Length(x);
    i:=L;
    while (i>0) do begin
        if (x[i]='.') then begin
            Result:=Copy(x,1,i-1)+suf+Copy(x,i,L-i+1);
            exit;
        end;
        i:=i-1;
    end;
    Result:=x+suf;
end;


FUNCTION GetProcessID(ExeName:STRING):DWORD;
 VAR pe: TProcessEntry32;
     h: THandle;
     test: boolean;
 BEGIN
  GetProcessID:=0;
  ExeName:=  LowerCase(ExeName);

  h:=CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS,0);
  TRY
   pe.dwSize:=SizeOf(TProcessEntry32);
   test:=Process32First(h,pe);
   WHILE test DO
    BEGIN
//    MessageDlg(ExtractFileName(pe.szExeFile),mtWarning,[mbOK],0   );
     IF (GetCurrentProcessId<>pe.th32ProcessID) and (ExtractFileName(pe.szExeFile)=ExeName) THEN GetProcessID:=pe.th32ProcessID;
     test:=Process32Next(h,pe);
    END;
   FINALLY
    CloseHandle(h);
   END;
 END;

function Terminate(const e:string):boolean  ;
var
c: THandle;
dw:DWORD;
begin
    dw:=getprocessid(e);
    Result:=false;

    while (dw<>0) do begin
        Result:=true;
        c := openprocess(PROCESS_ALL_ACCESS,FALSE, dw);
        TerminateProcess(C,0);
        closehandle(C);
        dw:=getprocessid(e);
    end;

end;

procedure CopyFile(const i:string;const o:string);
begin
    windows.CopyFile(pchar(i),pchar(o),false);
end;

procedure takeBackup(const m:string);
var dat:string;
    procedure save(const i:char);
    var
       s:string;
    begin
        s:='backups\'+i+'.w3x';
        if (FileExists(s)) then DeleteFile(pchar(s));
        Copyfile(m,s);

    end;

begin
    dat:='';
    if (not DirectoryExists('backups')) then CreateDirectory('backups',nil);



    if(FileExists('backups\backupsdata.txt')) then
        jasshelper.LoadFile('backups\backupsdata.txt',dat);
    if (Length(dat)<36) then begin //something wrong in there
        save('0');
        dat:='123456789abcdefghijklmnopqrstuvwxyz0';
        jasshelper.SaveFile('backups\backupsdata.txt',dat);
    end else begin
        save(dat[1]);
        dat:=Copy(dat,2,35)+dat[1];
        jasshelper.SaveFile('backups\backupsdata.txt',dat);
    end;

end;

function FixScriptFileName(const f:string):string;
var
    i,L,st:integer;
begin
    L:=Length(f);
    st:=0;
    for i := L downto 1 do
        if(f[i]='/') or (f[i]='\') then begin
            st:=i;
            break;
        end;
    Result:=Copy(f, st+1, L);
    Result:=LowerCase(Result);
   

end;


procedure dopjasserrors(const war3mapj:string; const errors:string; const tries:integer=0);
var
   f:textfile;
   line,sect:string;
   blizz,comm,maa:boolean;
   L,i,k,n,counter:integer;

    procedure seek(var ii:integer);
    begin
        while(ii<=L) and not((line[ii]=':') and ( (ii=L) or(line[ii+1]<>'\') )) do ii:=ii+1;
    end;

begin

   counter:=0;
   blizz:=false;
   comm:=false;
   maa:=false;

   try
       assignfile(f,errors);
       filemode:=fmOpenRead;
       Reset(f);
   except
       on e:exception do begin
       {workaround for WINE}
           CopyFile(errors,errors+'_WINEforced');
           assignfile(f,errors+'_WINEforced');
           filemode:=fmOpenRead;
           Reset(f);
       end;
   end;
   while(not EoF(f) ) and (counter<100) do begin      //too much errors do more harm than good
       ReadLn(f,line);
               //    MessageBox(0,pchar(line),'!',0);
       L:=Length(line);
       i:=1;
       seek(i);
       if(i<=L) then begin
           sect:=FixScriptFileName( Copy(line,1,i-1) );
           if(sect<>'parse successful') then begin
               k:=i+1;
               seek(k);
               if(k>L) then //it was an unrecognized character one, ignore
               else if( TryStrToInt(Copy(line,i+1,k-i-1),n) ) then begin

                   if(not maa) then begin
                       if(sect='blizzard.j') then begin
                           blizz:=true;
                       end
                       else if(sect='common.j') then begin
                           comm:=true;
                       end;
                   end;


                   if(not maa) then begin
                       if(comm) then grimoirecompiler.start(commonj,JassHelperConfigFile.JASS_COMPILER+' - common.j')
                       else if(blizz) then grimoirecompiler.start(blizzardj,JassHelperConfigFile.JASS_COMPILER+' - blizzard.j')
                       else grimoirecompiler.start(war3mapj,JassHelperConfigFile.JASS_COMPILER);
                       maa:=true;
                   end;
                   counter:=counter+1;
                   grimoirecompiler.add(n,Copy(line,k+1,L),true);
               end;
           end;
       end;
   end;


   Close(f);

   if(not maa) then begin
       raise Exception.Create('Unrecognized PJASS (syntax) error');
   end;
   grimoirecompiler.show;
end;

procedure doTool(const name:string; const prog:string;  args:string; const ext:string; const stdin:string);
var
   s,f,tem, tem2,tem3,tem4,nargs:string;
   ftem:Textfile;
begin

    s:='On external call:'#13#10+'//! external '+name+' '+args+#13#10#13#10;
    tem:=TempFile;
    tem2:=TempFile;
    tem3:=TempFile;
    tem4:=TempFIle;
    Assign(ftem,tem);
    Rewrite(ftem);
    Write(ftem,stdin);
    Close(ftem);
    CopyFile(tem,tem4);


    if (not FileExists(prog)) then begin
       raise Exception.Create(s+'Unable to find file: "'+prog+'"');
    end;
   //GetCurrentDir : much more portable than '.' , '.\' , '', nil , (towards WINE)
    if(ext<>'') then begin
        CopyFile(tem,tem+'.'+ext);
        args:=StringReplace(args,'$FILENAME$','"'+tem+'.'+ext+'"',[]);
    end;
    temi:= WinExec.StartApp(prog,'"'+map+'" "'+JasshelperConfigFile.WORK_PATHS+'" '+args,GetCurrentDir,0, tem4,tem2,tem3);
    if(temi<>0) then begin
       tem4:=TempFile;
       CopyFile(tem2,tem4);
       jasshelper.LoadFile(tem4,f);
       s:=s+f;
       tem4:=TempFile;
       CopyFile(tem3,tem4);

       jasshelper.LoadFile(tem4,f);
       raise Exception.Create(s+f);
    end;


end;

procedure doExternalThings;
var
   i,j:integer;
begin
    {map holds map's path}

    //fixes some issues:
    for i := 1 to Length(WORK_PATHS) do if(WORK_PATHS[i]='\') then WORK_PATHS[i]:='/';

    progress.SetMax(Exter.n);


    progress.StatusMsg('Executing external commands.');

    for i := 0 to Exter.n-1 do begin
        progress.SetPosition(i);
        j:=0;
        while(j<EXTERNAL_N) do begin
            if (EXTERNAL_Names[j]=Exter.name[i]) then begin
                doTool(EXTERNAL_Names[j],EXTERNAL_PROGRAMS[j],Exter.args[i], Exter.ext[i], Exter.stdin[i]);
                break;
            end;
            j:=j+1;
        end;
        if(j=EXTERNAL_N) then begin
            raise Exception.Create('External not found in config file: "'+Exter.name[i]+'"');
        end;


    end;

end;

procedure DoAbout;
var
 a:TAboutDialog;
begin
   a:=TaboutDialog.Create(nil);
   a.ShowWEWarlock(false);
   a.ShowModal;
   a.Destroy;
end;

//=============
function jasshelperConfPlacements:TdynamicStringArray;
begin
    SeTLength(result,2);
    result[0]:='jasshelper.conf';
    result[1]:=JASSHELPER_PATH+'jasshelper.conf';
end;
//=======

// do warlock
function doWEWarlock(const m:string):boolean;
var

  f1:string;
  f2,f3,compiled,backup,dir:string;
  i:integer;

begin
   result:=false;
   if (WEWARLOCK_PATH='') then Exit; //it could be that the user wants to run wewarlock himself?

   if (not FileExists(WEWARLOCK_PATH)) then begin
       MessageBox(0, pchar('File does not exist: '+WEWARLOCK_PATH), 'JASSHelper - Error' , MB_YESNOCANCEL   );
   end;


    try
       progress.StatusMsg('Executing WEWarlock ...');
       progress.SetPosition(0);
       progress.SetMax(100);

       compiled:=GetSuffixedName(m,'_compiled');
       backup:=m+'.beforewewarlock';




      f1:=TempFile;
      f2:=TempFile;
      f3:=TempFile;
      DeleteFile(pchar(GetSuffixedName(m,'_compiled')));
      dir:=ExtractFileDir(WEWARLOCK_PATH);
      i:= WinExec.StartApp(
      WEWARLOCK_PATH,
      '"'+m+'"',dir,0,f3,f1,f2);



      if i > 0 then begin



          if (dir[Length(dir)]<>'\') then dir:=dir+'\';

          warlockerror.ShowError(f1,dir+'WarlockCompiler.exe.stderr.txt',true);
          result:=true;
      end else if i < 0 then begin

         MessageBox(0, pchar('Unable to call : '+WEWARLOCK_PATH), 'Error' , MB_YESNOCANCEL  );


      end else begin
          DeleteFile(pchar(backup ));
          MoveFile(pchar(m),pchar(backup ));
          MoveFile(pchar(compiled),pchar(m));
      end;


    except
    on e:Exception do begin
        MessageBox(0, pchar(e.Message), 'Error' , MB_YESNOCANCEL    );
        result:=true;
    end;

    end;

end;
                           //
label   RESTARTLABEL;
                                         //
begin

  Application.Initialize;
  Application.Run;


  if (not DirectoryExists('logs')) then CreateDirectory('logs',nil);

  JASSHELPER_PATH := ExtractFileDir(paramstr(0));
  if(JASSHELPER_PATH[Length(JASSHELPER_PATH)]<>'\') then JASSHELPER_PATH:=JASSHELPER_PATH+'\';

{  try
      Write('');
  except
      on e:EInOutError  do begin
          AssignFile(output, 'stdout.txt');
          Rewrite(output);
      end;
  end;}
  





  temi:=1;
  while(true) do begin
      if(paramStr(temi)='--configure') then begin
          MessageBox(0,'To configure edit the file jasshelper.conf located at the same path as this executable or on the work folder (priority give to work folder)','JassHelper',MB_ICONINFORMATION);
          CleanTempFiles();
          Halt;
      end else if(paramStr(temi)='--about') then begin
          DoAbout;
          CleanTempFiles();
          Halt;
      end else if(paramStr(temi)='--showerrors') then begin
          grimoirecompiler.load;
          CleanTempFiles();
          Halt;
      end else if(ParamStr(temi)='--debug') then begin
          debug:=true;
          temi:=temi+1;
      end else if(ParamStr(temi)='--nopreprocessor') then begin
          nopre:=true;
          temi:=temi+1;
      end else if(ParamStr(temi)='--nooptimize') then begin
          noopt:=true;
          temi:=temi+1;
      end else if(ParamStr(temi)='--scriptonly') then begin
          scriptmode:=true;
          temi:=temi+1;
      end else if(ParamStr(temi)='--zinconly') then begin
          jasshelper.ZINC_MODE:=true;
          scriptmode:=true;
          temi:=temi+1;
      end else if(ParamStr(temi)='--warcity') then begin
          jasshelper.WARCITY:=true;
          scriptmode:=true;
          temi:=temi+1;
      end else if(ParamStr(temi)='--macromode') then begin
          jasshelper.MACROMODE:=true;
          scriptmode:=true;
          temi:=temi+1;
      end else break;

  end;

  Terminate(ExtractFileName(paramstr(0)));
  grimoirecompiler.clear;
  
     mpq:=0;
try


     commonj:=ParamStr(temi);
     blizzardj:=ParamStr(temi+1);
     map:=ParamStr(temi+2);
     war3mapj:='';

     if(ParamStr(temi+3)<>'') then begin
         map:=ParamStr(temi+3);
         war3mapj:=ParamStr(temi+2);
     end;

     if(scriptmode and (war3mapj='')) then raise Exception.Create('jasshelper.exe --scriptmode <common.j> <blizzard.j> <input.j> <output.j>');


     if (commonj='') then raise Exception.Create('Missing arguments: <commonj> <blizzardj> <mappath>');
     if (blizzardj='') then raise Exception.Create('Missing arguments: <blizzardj> <mappath>');
     if (map='') then raise Exception.Create('Missing argument: <mappath>');

     if (not FileExists(commonj)) then raise Exception.Create('File does not exist : '+commonj);
     if (not FileExists(blizzardj)) then raise Exception.Create('File does not exist : '+blizzardj);
     if (war3mapj<>'') and (not FileExists(war3mapj)) then raise Exception.Create('File does not exist : '+war3mapj);
     if (not scriptmode) and (not FileExists(map)) then raise Exception.Create('File does not exist : '+map);

     jasshelper.COMMONJ:= commonj;
     jasshelper.BLIZZARDJ:= blizzardj;

     f1:=tempfile;
     f2:=tempfile;
     f3:=tempfile;


     takeBackup(map);

     temi:=temi+1;

     {while( ParamStr(Temi)<>'') do begin
         map:=map+' '+ParamStr(Temi);
         Temi:=temi+1;
     end;}




     progress.show;

     if(scriptmode) then begin
         folder:=ExtractFileDir(war3mapj);
     end
     else begin
         folder:=ExtractFileDir(map);
     end;
     if( (Length(folder)>0) and   (folder[Length(folder)]<>'\')) then folder:=folder+'\';


     jasshelper.importPathsClear;
     WORK_PATHS:=folder;
     jasshelper.addImportPath(folder); //ensures map's path as an import search path
     readConfig(jasshelperConfPlacements);
     jasshelper.AUTOMETHODEVALUATE:= jasshelperConfigFile.AUTO_METHOD_EVALUATE;

     jasshelper.Interf:=TJASSHelperInterface.Create;
     jasshelper.Interf.ProPosition:=progress.SetPosition;
     jasshelper.Interf.ProMax:=progress.SetMax;
     jasshelper.Interf.GetProMax:=progress.GetMax;
     jasshelper.Interf.GetProPosition:=progress.GetPosition;
     jasshelper.Interf.ProStatus:=progress.StatusMsg;

     RESTARTLABEL :

     compiled:='logs\outputwar3map.j';

     progress.SetMax(1);
     progress.SetPosition(0);


     progress.StatusMsg('Checking tool existance...');
	 {
	 because sfmpq.dll is linked to the executable at compile time
	 windows executable loader will help us to check sfmpq.dll
     if (not FileExists(JASSHELPER_PATH+'sfmpq.dll')) then raise Exception.CReate('Unable to find '+JASSHELPER_PATH+'sfmpq.dll');
	 }


     if(not scriptmode) then
         mpq:=MpqOpenArchiveForUpdate(pchar(map),MOAU_OPEN_EXISTING + MOAU_MAINTAIN_LISTFILE,0);
     progress.SetPosition(1-progress.GetPosition);

{     temi:= WinExec.StartApp(
      'bin\extract.exe',
      '"'+map+'" war3map.j "'+war3mapj+'"','.',0,f3,f1,f2);}

     if(war3mapj<>'') then begin
         CopyFile(war3mapj,'logs\inputwar3map.j');
         war3mapj:='logs\inputwar3map.j';
     end else begin
         war3mapj:='logs\inputwar3map.j';
         progress.StatusMsg('Extracting war3map.j ...');
         if(not MPQFileExists(mpq,'war3map.j')) then raise Exception.Create('Map does not contain war3map.j');
         DeleteFile(pchar(war3mapj));
         storm.MPQExtractFileTo(mpq,'war3map.j',pchar(war3mapj));
         if(not FileExists(war3mapj)) then raise Exception.Create('war3map.j extract error');
     end;

     stage:=1;
     progress.StatusMsg('copying ...');
     CopyFile(war3mapj,'logs\currentmapscript.j');

     if(not nopre) then begin
         jasshelper.DoJasserMagic('logs\currentmapscript.j',compiled,debug);
         progress.StatusMsg('copying ...');
         CopyFile(compiled,'logs\currentmapscript.j');
         stage:=2;
         if(not jasshelper.WARCITY) and not jasshelper.MACROMODE  and not jasshelper.ZINC_MODE then begin
             jasshelper.DoJasserStructMagic('logs\currentmapscript.j',compiled,debug);
             stage:=3;

             if(jasshelper.REQUIREFOUND<>0) then begin
                 if(scriptmode) then raise Exception.Create('//! require found, but --scriptonly is in use');
                 storm.MpqAddFileToArchiveEx(mpq,pchar(compiled),'war3map.j',MAFA_REPLACE_EXISTING+MAFA_COMPRESS,MAFA_COMPRESS_DEFLATE,Z_BEST_COMPRESSION);
                 storm.MpqCloseUpdatedArchive(mpq,0);
                 if dowewarlock(map) then begin
                     raise Exception.Create('There were errors while running wewarlock');
                 end;
                 mpq:=MpqOpenArchiveForUpdate(pchar(map),MOAU_OPEN_EXISTING + MOAU_MAINTAIN_LISTFILE,0);
                 storm.MPQExtractFileTo(mpq,'war3map.j',pchar('logs\currentmapscript.j'));
             end else begin
                 progress.StatusMsg('copying ...');
                 CopyFile(compiled,'logs\currentmapscript.j');
             end;
         end;
     end else begin
         progress.StatusMsg('Copying ...');
         CopyFile(war3mapj,compiled);
     end;

    if(not jasshelper.WARCITY) and not jasshelper.MACROMODE  and not jasshelper.ZINC_MODE then begin
      if (not FileExists(JASSHELPER_PATH+JasshelperConfigFile.JASS_COMPILER)) then raise Exception.Create('Unable to find: '+JASSHELPER_PATH+JasshelperConfigFile.JASS_COMPILER);

      progress.SetMax(1);
      progress.SetPosition(0);
      progress.StatusMsg('Calling '+JasshelperConfigFile.JASS_COMPILER+' ...');

      //GetCurrentDir : much more portable than '.' , '.\' , '', nil , (towards WINE)
      temi:= WinExec.StartApp(
       JASSHELPER_PATH+JassHelperConfigFile.JASS_COMPILER,
       JassHelperConfigFile.ParserCommandLine('"'+commonj+'"', '"'+blizzardj+'"','logs\currentmapscript.j'),
       GetCurrentDir,0,f3,'logs\pjass.txt',f2);

      if(temi<>0) then begin
          progress.StatusMsg('Found errors, please wait...');
          dopjasserrors('logs\currentmapscript.j','logs\pjass.txt');

//          dopjasserrors(f1,f1);
          CleanTempFiles();
          halt(1);
      end;
        if (jasshelperconfigfile.ENABLE_RETURN_FIXER) then begin
            progress.StatusMsg('copying ...');
            CopyFile(compiled,'logs\currentmapscript.j');
            jasshelper.DoJasserReturnFixMagicF('logs\currentmapscript.j',compiled);
            CopyFile(compiled,'logs\currentmapscript.j');

            progress.StatusMsg('calling Jass syntax checker again ...');
            temi:= WinExec.StartApp(
                JASSHELPER_PATH+JassHelperConfigFile.JASS_COMPILER,
                JassHelperConfigFile.ParserCommandLine('"'+commonj+'"', '"'+blizzardj+'"','logs\currentmapscript.j'),
                GetCurrentDir,0,f3,'logs\pjass.txt',f2);

            if(temi<>0) then begin
               progress.StatusMsg('Found errors, please wait...');
               dopjasserrors('logs\currentmapscript.j','logs\pjass.txt');
               CleanTempFiles();
               halt(1);
            end;


        end;
        if (jasshelperconfigfile.ENABLE_SHADOW_HELPER) then begin
            progress.StatusMsg('copying ...');
            CopyFile(compiled,'logs\currentmapscript.j');
            jasshelper.DoJasserShadowHelperMagicF('logs\currentmapscript.j',compiled);
            CopyFile(compiled,'logs\currentmapscript.j');

            progress.StatusMsg('calling Jass syntax checker again ...');
            temi:= WinExec.StartApp(
                JASSHELPER_PATH+JassHelperConfigFile.JASS_COMPILER,
                JassHelperConfigFile.ParserCommandLine('"'+commonj+'"', '"'+blizzardj+'"','logs\currentmapscript.j'),
                GetCurrentDir,0,f3,'logs\pjass.txt',f2);

            if(temi<>0) then begin
                progress.StatusMsg('Found errors, please wait...');
                dopjasserrors('logs\currentmapscript.j','logs\pjass.txt');
                CleanTempFiles();
                halt(1);
            end;


        end;

        if (not debug) and (not noopt) then begin
            progress.StatusMsg('copying ...');
            CopyFile(compiled,'logs\currentmapscript.j');
            jasshelper.DoJasserInlineMagicF('logs\currentmapscript.j',compiled);
            CopyFile(compiled,'logs\currentmapscript.j');

            progress.StatusMsg('calling Jass syntax checker again ...');
            temi:= WinExec.StartApp(
                JASSHELPER_PATH+JassHelperConfigFile.JASS_COMPILER,
                JassHelperConfigFile.ParserCommandLine('"'+commonj+'"', '"'+blizzardj+'"','logs\currentmapscript.j'),
                GetCurrentDir,0,f3,'logs\pjass.txt',f2);

            if(temi<>0) then begin
                progress.StatusMsg('Found errors, please wait...');
                dopjasserrors('logs\currentmapscript.j','logs\pjass.txt');
                CleanTempFiles();
                halt(1);
            end;
             
            // should this use another command line flag ?
            progress.StatusMsg('copying ...');
            CopyFile(compiled,'logs\currentmapscript.j');
            jasshelper.DoJasserNullLocalMagicF('logs\currentmapscript.j',compiled);
            CopyFile(compiled,'logs\currentmapscript.j');

            progress.StatusMsg('calling Jass syntax checker again ...');
            temi:= WinExec.StartApp(
                JASSHELPER_PATH+JassHelperConfigFile.JASS_COMPILER,
                JassHelperConfigFile.ParserCommandLine('"'+commonj+'"', '"'+blizzardj+'"','logs\currentmapscript.j'),
                GetCurrentDir,0,f3,'logs\pjass.txt',f2);

            if(temi<>0) then begin
                progress.StatusMsg('Found errors, please wait...');
                dopjasserrors('logs\currentmapscript.j','logs\pjass.txt');
                CleanTempFiles();
                halt(1);
            end;
             
        end;

     end;


     if(not scriptmode) and (storm.MPQFileExists(mpq,'(attributes)')) then begin
         progress.SetPosition(1-progress.GetPosition);
         progress.StatusMsg('Removing (attributes) ...');
         if not storm.MpqDeleteFile(mpq,'(attributes)') then begin
             raise Exception.Create('Unable to remove (attributes)');
         end;
     end;

     if(not scriptmode) then begin
         progress.SetPosition(1-progress.GetPosition);
         progress.StatusMsg('Replacing war3map.j ...');

         storm.MpqAddFileToArchiveEx(mpq,pchar(compiled),'war3map.j',MAFA_REPLACE_EXISTING+MAFA_COMPRESS,MAFA_COMPRESS_DEFLATE,Z_BEST_COMPRESSION);
         progress.StatusMsg('Compacting MPQ archive ...');
         storm.MpqCompactArchive(mpq);
         progress.StatusMsg('Closing MPQ archive ...');
         storm.MpqCloseUpdatedArchive(mpq,0);
         mpq:=0;
         progress.StatusMsg('Checking externals ...');
         if (not nopre) and (jasshelper.getExternalUsage(exter)) then begin
             doExternalThings;
             war3mapj:='';
             goto RESTARTLABEL; //Dijkstra would be so dissapointed
         end;
     end else begin
         progress.SetPosition(1-progress.GetPosition);
         progress.StatusMsg('Saving '+map+' ...');
         CopyFile(compiled,map);
         if( not(nopre) and jasshelper.getExternalUsage(exter)) then begin
             MessageBox(0,'The script compilation was succesful, but //! external was found in the map, --scriptmode is incompatible with external tools','Information',mb_iconinformation);
         end;
     end;

     progress.SetMax(1);
     progress.SetPosition(1);

     progress.StatusMsg('Success!');
     Sleep(250);
     progress.stop;
     CleanTempFiles();


except

 on e:JASSerException do begin

     progress.StatusMsg('Found errors, please wait...');

     if(jasshelper.IMPORTUSED) then begin

         jasshelper.SaveFile('logs\currentmapscript.j', jasshelper.AFTERIMPORT);
         grimoirecompiler.start('logs\currentmapscript.j','JASSHelper - Step 1 (textmacros, libraries, scopes) (scripts were imported)')
     end else begin
         if(stage=1) then grimoirecompiler.start('logs\currentmapscript.j','JASSHelper - Step 1 (textmacros, libraries, scopes)')
         else if(stage=2) then grimoirecompiler.start('logs\currentmapscript.j','JASSHelper - Step 2 (structs)');
     end;



     grimoirecompiler.add(e.linen+1,e.msg,true);

     if(e.two) then begin
        grimoirecompiler.add(e.linen2+1,e.msg2,false);
     end;

     if(e.macro1>=0) then grimoirecompiler.add(e.macro1+1,'(From this instance)',false);
     if(e.macro2>=0) and(e.macro2<>e.macro1) then grimoirecompiler.add(e.macro2+1,'(From this instance)',false);


     grimoirecompiler.show;
     CleanTempFiles();
     Halt(1);
 end;

 on e:Exception do begin
     MessageBox(0,pchar(e.message),'JASSHelper Error',MB_TOPMOST+MB_ICONERROR);
     CleanTempFiles();
     Halt(1);

 end;

end;

     if (mpq<>0) then begin
         MpqCloseUpdatedArchive(mpq,0);
     end;






end.

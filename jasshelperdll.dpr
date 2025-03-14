library jasshelperdll;





uses
  Windows,
  SysUtils,
  PluginTypes in 'PluginTypes.pas',
  jasshelper in 'jasshelper.pas' {Form1},
  vxFilesys in 'vxFilesys.pas',
  about in 'about.pas' {Aboutdialog},
  winexec in 'winexec.pas',
  jasserconf in 'jasserconf.pas' {jasserconfig},
  StringHash in 'StringHash.pas',
  slk in 'slk.pas',
  lookupconf in 'lookupconf.pas' {Form6},
  folderbrowse in 'folderbrowse.pas',
  externalconf in 'externalconf.pas' {Form7};

var


lib:PFunctionLibrary;

propos:integer;
promaximum:integer;

PRENAME:string;
PRELONGNAME:string;
PATHS:string;


procedure ProPosition(p:integer); stdcall;
begin
    propos:=p;
    lib.ProgressWndProgress(propos,promaximum);
end;
procedure ProMax(max:integer); stdcall;
begin
    promaximum:=max;
    lib.ProgressWndProgress(propos,promaximum);
end;
function GetProMax:integer ; stdcall;
begin
    Result:=promaximum;
end;
function GetProPosition:integer ; stdcall;
begin
    Result:=propos;
end;
procedure StatusMessage(const msg:string); stdcall;
begin
    lib.ProgressWndTitle(pchar('JASSHelper - '+msg));
end;


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

procedure DreadFulWEHelperBug;
begin
    MessageBox(0,'A WEHelper error is making it remove war3map.j','WEHelper error detected',MB_TOPMOST+MB_ICONERROR)
end;

procedure doTool(const map:string; const name:string; const prog:string; const args:string);
var
   s,f,f1,f2,f3:string;
   temi:integer;
begin
    f1:=TempFile;
    f2:=TempFile;
    f3:=TempFile;

    s:='On external call:'#13#10+'//! external '+name+' '+args+#13#10#13#10;
    if (not FileExists(prog)) then begin
       raise Exception.Create(s+'Unable to find file: "'+prog+'"');
    end;
   temi:= WinExec.StartApp(prog,'"'+map+'" "'+paths+'" '+args,'.',0,f3,f1,f2);
   if(temi<>0) then begin
       jasshelper.LoadFile(f1,f);
       s:=s+f;
       jasshelper.LoadFile(f2,f);
       raise Exception.Create(s+f);
    end;


    CleanTempFiles(); // i guess here are correct place to insert code that cleanup temp files
end;

procedure doExternalThings(const map:string;exter:TExternalusage);
var
   i,j:integer;

begin
    {map holds map's path}


    //fixes some issues:
    for i := 1 to Length(paths) do if(paths[i]='\') then paths[i]:='/';


    ProMax(Exter.n);



    StatusMessage('Executing external commands.');


    for i := 0 to Exter.n-1 do begin
        ProPosition(i);

        j:=0;
        while(j<jasserconf.Externalnames.count) do begin
            if (jasserconf.Externalnames[j]=Exter.name[i]) then begin
                doTool(map, jasserconf.Externalnames[j],jasserconf.ExternalPaths[j],Exter.args[i]);
                break;
            end;
            j:=j+1;
        end;
        if(j=jasserconf.Externalnames.count) then begin
            raise Exception.Create('External not found: "'+Exter.name[i]+'"');
        end;


    end;

end;


procedure Process(Info: PPreprocessorProcessInfo); stdcall;
var
  mpq:THandle;
//  f1:string;
//  f2,f3:string;
  input,output,tm:string;
  pinput:pchar;
  errordialogopened:boolean;
  i:integer;
  exusage:Texternalusage;

begin

    jasshelper.GRAMMARPATH:=ExtractFileDir(info.CommonJ);
    if(jasshelper.GRAMMARPATH[Length(jasshelper.GRAMMARPATH)]<>'\') then jasshelper.GRAMMARPATH:=jasshelper.GRAMMARPATH+'\';
    jasshelper.GRAMMARPATH:=jasshelper.GRAMMARPATH+'plugins\jasshelper.cgt';
    jasshelper.FORGETIMPORT:=false; //not anymore

   propos:=0;
   promaximum:=100;

   lib:=info.FunctionLibrary;

  mpq:=lib.MpqOpen(info.FileName);
  if not lib.MpqFileExists(mpq,'war3map.j') then begin
      lib.MpqClose(mpq);
      DreadFulWEHelperBug;
      Exit;
  end;
  pinput:=lib.MpqLockFile(mpq,'war3map.j');


  input:=string(pinput);


  lib.MpqFreeFile(pinput);
  lib.MpqClose(mpq);




  //f1:=TempFile;
  //f2:=TempFile;
  //f3:=TempFile;


  //lib.mpqExtractFile(mpq,'war3map.j',Pchar(f1));
  //lib.mpqExtractFile(mpq,'war3map.j',Pchar(f3));

  errordialogopened:=false;
  if (jasserconf.DebugMode) then MessageBox(0, 'Debug mode is currently enabled, all lines that begin with the debug keyword will be enabled.', 'JASSHelper - Notice', MB_TOPMOST	);

  lib.ProgressWndStart('JASSHelper',false);
  jasshelper.Interf:= jasshelper.TJASSHelperInterface.Create;
  jasshelper.Interf.ProPosition:=ProPosition;
  jasshelper.Interf.ProMax:=ProMax;
  jasshelper.Interf.GetProPosition:=GetProPosition;
  jasshelper.Interf.GetProMax:=GetProMax;
  jasshelper.Interf.ProStatus:=StatusMessage;

  jasshelper.importPathsClear;
  jasshelper.addImportPath(ExtractFileDir(info.Filename));

  tm:=ExtractFileDir(info.CommonJ);

  if(tm<>'') and (tm[Length(tm)]<>'\') then tm:=tm+'\imports\'
  else tm:=tm+'imports\';

  jasshelper.addImportPath(ExtractFileDir(info.Filename));

  PATHS:=ExtractFileDir(info.Filename)+';'+tm;
    for i := 0 to jasserconf.Lookupfolders.Count-1 do begin
       jasshelper.addImportPath(jasserconf.Lookupfolders[i]);
       PATHS:=PATHS+';'+jasserconf.Lookupfolders[i];
    end;


    try
      output:=jasshelper.DoJasserMagic(input,jasserconf.DebugMode);
      input:=output;
      jasshelper.DoJasserStructMagic(input,jasserconf.DebugMode,output);

    except
     on e:JASSerException do begin
         Info.Failed:=true;
         errordialogopened:=true;
         lib.ErrorDialogClear;
         lib.ErrorDialogScript(Pchar(input),false);
         lib.ErrorDialogAdd(Pchar('Line '+IntToStr(e.linen+1)+': '+e.msg),e.linen+1);
         if(e.two) then begin
             lib.ErrorDialogAdd(Pchar('Line '+IntToStr(e.linen2+1)+': '+e.msg2),e.linen2+1);

         end;
         if(e.macro1>=0) then lib.ErrorDialogAdd(Pchar('Line '+IntToStr(e.macro1+1)+': (From this macro instance)'),e.macro1+1);
         if(e.macro2>=0) and(e.macro2<>e.macro1) then lib.ErrorDialogAdd(Pchar('Line '+IntToStr(e.macro2+1)+': (From this macro instance)'),e.macro2+1);
    //     MessageBox(0, pchar('Raised Exception:'+#13#10+e.Msg), 'JASSHelper - Error', 0);
     end;
     on e:Exception do begin
         Info.Failed:=true;
         errordialogopened:=true;
         lib.ErrorDialogClear;
         lib.ErrorDialogScript(Pchar(input),false);

         lib.ErrorDialogAdd(Pchar('[JASSHelper - Internal Error] '+e.Message ),1);
     end;

    end;


  if (jasshelper.REQUIREFOUND>0) then begin
     if (not Info.Failed) then begin
         Info.Failed:=true;
         lib.ErrorDialogClear;
         lib.ErrorDialogScript(Pchar(input),false);

     end;

     lib.ErrorDialogAdd(Pchar('Line '+IntToStr(jasshelper.REQUIREFOUND)+': Unsupported preprocessor //! require (try grimoire version instead)'),jasshelper.REQUIREFOUND);

  end;

  mpq:=lib.MpqOpen(info.FileName);
  StatusMessage('Closing');
  ProMax(7);
  ProPosition(0);
  if (not info.failed) then begin
      lib.MpqDeleteFile(mpq,'war3map.j');
      ProPosition(1);
     lib.MpqDeleteFile(mpq,'(attributes)'); //too lazy to generate it, sorry
     ProPosition(2);
   //  lib.MpqAddFile(mpq,'war3map.j',Pchar(f2));
     lib.MpqAddBuffer(mpq,'war3map.j',Pchar(output),Length(output));
     ProPosition(3);
     if (not lib.MpqFileExists(mpq,'war3map.j')) then begin
         MessageBox(0, 'Something unexpected disallowed JASSHelper to add war3map.j to file' , 'JASSHelper - Critical Error'	,0);
     end;

     //lib.MpqCompact(mpq);
     lib.MpqClose(mpq);
  end
  else
      lib.MpqClose(mpq);

   if (jasshelper.getExternalUsage(exusage)) then begin
       try
            doExternalThings(info.FileName,exusage);
       except
           on e:exception do begin
               MessageBox(0,pchar(e.Message),'JassHelper - External Tool Error', MB_ICONERROR+MB_TOPMOST)
           end;
       end;
   end;

//  ProPosition(4);
//  DeleteFile(f1);
//  ProPosition(5);
//  DeleteFile(f2);
//  ProPosition(6);
//  DeleteFile(f3);
//  ProPosition(7);

  lib.ProgressWndEnd;
  jasshelper.Interf.Destroy;
  jasshelper.Interf:=nil;
  if (errordialogopened=true) then begin
      lib.ErrorDialogShow;
  end
  else if (not Info.failed) and (jasshelper.REQUIREFOUND>0) then begin

  end;

  if(jasshelper.getExternalUsage(exusage)) then
     Process(Info);




end;









procedure Configure(Owner: LongWord); stdcall;
begin
   jasserconf.Dialog;
end;
procedure About(Owner: LongWord); stdcall;
var
  ab:TAboutDialog;
begin
   ab:=TAboutDialog.Create(nil);
   ab.ShowWeWarlock(false);
   ab.ShowModal;
   ab.Free;
end;

procedure HelperEntry(Info: PRegisterInfo); stdcall;
var
 PluginInfo: PRegisterPlugin;
 PreprocInfo: PRegisterPreprocessor;


begin

    jasserconf.ConfigFile:=GetAppDataDir+'\jasshelper.conf';
    jasserconf.Load;

 New(PluginInfo);

 PluginInfo.Name := 'JASSHelper';

 PluginInfo.CanAbout := True;

 PluginInfo.CanConfigure := True;
 PluginInfo.Configure:= Configure;

 PluginInfo.About := About;

 PluginInfo.Module := HInstance;




 if Info.Enabled then begin
     New(PreprocInfo);
     PRENAME:='JASSHELPER';
     PRELONGNAME:='Jass Helper - Libraries, global merge, debug mode and string fix';
     PreprocInfo.Process:=Process;
     PreprocInfo.CodeName:=PCHAR(PRENAME);
     PreprocInfo.LongName:=PCHAR(PRELONGNAME);
     PreprocInfo.Level := 1; //after import
     Info.MakePreprocessor(PreprocInfo);


 end;

 Info.MakePlugin(PluginInfo);

end;




exports HelperEntry;









begin

end.

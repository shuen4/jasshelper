program grimoirecaller;

uses
  windows,
  sysutils,
  Tlhelp32,
  registry,
  winexec in 'winexec.pas';

{$R *.res}

var
   fold:string;
   args:string;
   i:integer;

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
//    MessageDlg(ExtractFileName(pe.szExeFile),mtWarning,[mbOK],0	);
     IF (GetCurrentProcessId<>pe.th32ProcessID) and (ExtractFileName(pe.szExeFile)=ExeName) THEN GetProcessID:=pe.th32ProcessID;
     test:=Process32Next(h,pe);
    END;
   FINALLY
    CloseHandle(h);
   END;
 END;


procedure DefaultsRegistry;
var reg:Tregistry;
begin
    reg:=Tregistry.Create;
    try
    try
       Reg.RootKey := HKEY_CURRENT_USER;

       if(not reg.OpenKey('\Software\grimoire',true)) then raise Exception.Create('wtf');


       reg.WriteString('Always allow trigger enable','on');
       reg.WriteString('Debug Mode','off');
       reg.WriteString('Disable default description nag','on');
       reg.WriteString('Disable vJass syntax','off');
       reg.WriteString('Disable WE Syntax Checker','on');
       reg.WriteString('Don''t let WE disable triggers','on');
       reg.WriteString('Enable JassHelper','on');
       reg.WriteString('Enable war3err','on');

       reg.WriteString('Start War3 with grimoire','on');
       reg.WriteString('Start War3 with -window','on');
       reg.CloseKey;
    except
       on e:exception do begin
                 MessageBox(0,pchar(e.Message),'!',0);
       end;
    end;
    finally
        reg.Destroy;
    end;
end;

var isinst:boolean;

begin
{Application.Initialize;
Application.Run;}
  fold:=ExtractFileDir(PAramStr(0));
  if(fold[Length(fold)]<>'\') then fold:=fold+'\';
  args:='';
  i:=1;
  if ParamStr(i)<>'' then begin

      args:=ParamStr(i);
            inc(i);
      while ParamStr(i)<>'' do begin
           args:=' '+ParamStr(i);
           inc(i);
      end;

  end;


  try

     if ((args<>'') and (not FileExists(args)) ) then begin
          raise Exception.Create('Unable to find file:'#13#10+args);
      end;

      isinst:=false;
      if( not FileExists(fold+'bin\sfmpq.dll')) then begin
          if (not FileExists(fold+'sfmpq.dll')) then raise Exception.CReate('Unable to find sfmpq.dll');
          CopyFile(pchar(fold+'sfmpq.dll'),pchar(fold+'bin\sfmpq.dll'),false);
          isinst:=true;
      end;
      if( DirectoryExists(fold+'grimext') and not FileExists(fold+'grimext\sfmpq.dll')) then begin
          if (not FileExists(fold+'sfmpq.dll')) then raise Exception.CReate('Unable to find sfmpq.dll');
          CopyFile(pchar(fold+'sfmpq.dll'),pchar(fold+'grimext\sfmpq.dll'),false);
          isinst:=true;
      end;
      if( not FileExists(fold+'jasshelper\sfmpq.dll')) then begin
          if (not FileExists(fold+'sfmpq.dll')) then raise Exception.CReate('Unable to find sfmpq.dll');
          CopyFile(pchar(fold+'sfmpq.dll'),pchar(fold+'jasshelper\sfmpq.dll'),false);
          isinst:=true;
      end;
      if(          isinst) then DefaultsRegistry;
      if (FileExists(fold+'sfmpq.dll')) then DeleteFile(fold+'sfmpq.dll');



       if (not FileExists(fold+'bin\exehack.exe')) then raise Exception.CReate('Unable to find bin\exehack.exe');
       if (not FileExists(fold+'jasshelper\jasshelper.exe')) then raise Exception.CReate('Unable to find jasshelper.exe');
       if (not FileExists(fold+'we.lua')) then raise Exception.CReate('Unable to find we.lua');

      if (WinExec.StartApp(
      fold+'bin\exehack.exe',
      '-s we.lua '+args,fold,0,'','','')
          =0) then begin

                  Sleep(10000);
                 if GetProcessid('worldedit.exe')=0 then raise exception.Create('Grimoire executed correctly but world editor failed to start, please make sure your warcraft III CD is in your drive.'#13#10#13#10'If problem persists report this bug');


      end;

   except
      on e:exception do begin
          MessageBox(0,pchar(e.message),'Error',MB_TOPMOST+MB_ICONERROR)
      end;


   end;

end.

unit winexec;
interface
uses
  Classes, SysUtils, Windows;


type
  FileSpec = array [0..32767] of char;


function StartApp(AppName, ArgStr, workdir :String; Visibility : integer; input,output,error:string):integer;

implementation
{ TWinExec }
function StartApp(AppName, ArgStr, workdir :String; Visibility : integer; input,output,error:string):integer;
var
  zAppName : FileSpec;


  StartupInfo : TStartupInfo;
  ProcessInfo : TProcessInformation;
  MEH: _OFSTRUCT;
  wd: pchar;
  kk:Cardinal;
  SecAtrrs: TSecurityAttributes;
begin


   FillChar(SecAtrrs, SizeOf(SecAtrrs), #0);
    SecAtrrs.nLength        := SizeOf(SecAtrrs);
    SecAtrrs.lpSecurityDescriptor := nil;
    SecAtrrs.bInheritHandle := True;
  //WorkDir:=ExtractFileDir(AppName);

  {
    https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-createprocessa
  
    The lpApplicationName parameter can be NULL.
    In that case, the module name must be the first white space-delimited token in the lpCommandLine string.
    If you are using a long file name that contains a space,
      use quoted strings to indicate where the file name ends and the arguments begin;
    otherwise,
      the file name is ambiguous.
    For example,
      consider the string
        "c:\program files\sub dir\program name".
      This string can be interpreted in a number of ways.
      The system tries to interpret the possibilities in the following order:
        1. c:\program.exe
        2. c:\program files\sub.exe
        3. c:\program files\sub dir\program.exe
        4. c:\program files\sub dir\program name.exe
  }
  AppName := '"' + AppName + '"';
  
  if ArgStr <> '' then
     AppName := AppName + ' ' + ArgStr;
  StrPCopy(zAppName, AppName);

  if(workdir='') then wd:=nil
  else wd:=pchar(workdir);
  FillChar(StartupInfo, Sizeof(StartupInfo), #0);
  StartupInfo.cb := Sizeof(StartupInfo);
  if(input='') then begin
      StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  end else begin
      if( FileExists(input) ) then begin
          StartupInfo.hStdInput := CreateFile(pchar(input),GENERIC_READ or GENERIC_WRITE,FILE_SHARE_READ or	FILE_SHARE_WRITE	,@SecAtrrs,OPEN_ALWAYS,FILE_ATTRIBUTE_NORMAL,0);
      end else begin
          StartupInfo.hStdInput := CreateFile(pchar(input),GENERIC_READ or GENERIC_WRITE,FILE_SHARE_READ or	FILE_SHARE_WRITE	,@SecAtrrs,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0);
      end;

      StartupInfo.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES	;

      StartupInfo.hStdOutput := CreateFile(pchar(output),GENERIC_WRITE or GENERIC_READ,FILE_SHARE_READ or	FILE_SHARE_WRITE	,@SecAtrrs,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0);
      StartupInfo.hStdError := CreateFile(pchar(error),GENERIC_WRITE or GENERIC_READ,FILE_SHARE_READ or	FILE_SHARE_WRITE,@SecAtrrs,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0);


  end;
  StartupInfo.wShowWindow := Visibility;



  if not CreateProcess(
    nil,                           { pointer to executable}
    zAppName,                      { pointer to command line string }
    nil,                           { pointer to process security attributes }
    nil,                           { pointer to thread security attributes }
    true,                          { handle inheritance flag }
    CREATE_NEW_CONSOLE or          { creation flags }
    NORMAL_PRIORITY_CLASS,
    nil,                           { pointer to new environment block }
    wd,                            { pointer to current directory name }
    StartupInfo,                   { pointer to STARTUPINFO }
    ProcessInfo) then Result := -1 { pointer to PROCESS_INF }
  else
  begin

         WaitforSingleObject(ProcessInfo.hProcess,INFINITE);
         GetExitCodeProcess(ProcessInfo.hProcess,kk);
         Result:=integer(kk);

    CloseHandle(ProcessInfo.hProcess );
    CloseHandle(ProcessInfo.hThread );
  end;
  if(input<>'') then begin
    CloseHandle(StartupInfo.hStdInput);
    CloseHandle(StartupInfo.hStdOutput);
    CloseHandle(StartupInfo.hStdError);
  end;

end;
end.

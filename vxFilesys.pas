unit vxFilesys;
// Just generic file stuff
interface

uses
  Windows, SysUtils, Registry, Classes;


function GetWindowsDir: TFileName;
function GetTempDir: TFileName;
function TempFile: TFileName;
function GetAppDataDir: TFileName;
function LoadFile(const FileName: TFileName): string;
procedure SaveFile(const FileName: TFileName; const content: string);
function CleanTempFiles : integer;


implementation

function LoadFile(const FileName: TFileName): string;
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
procedure SaveFile(const FileName: TFileName; const content: string);
begin
  with TFileStream.Create(FileName, fmCreate) do
    try
      Write(Pointer(content)^, Length(content));
    finally
      Free;
    end;
end;

function GetAppDataDir: TFileName;
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create(KEY_READ);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    // False because we do not want to create it if it doesn't exist
    Registry.OpenKey('\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders', False);
    Result := Registry.ReadString('AppData');
  finally
    Registry.Free;
  end;
  if (Result='') then begin
      Result:=ExtractFileDir(ParamStr(0));
  end else if DirecToryExists(Result+'\vexorian') or CreateDirectory(PChar(Result+'\vexorian'),nil) then
          Result:=Result+'\vexorian';
end;



function GetWindowsDir: TFileName;
var
  WinDir: array [0..MAX_PATH-1] of char;
begin
  SetString(Result, WinDir, GetWindowsDirectory(WinDir, MAX_PATH));
  if Result = '' then
    raise Exception.Create('Failed to get Windows folder' + SysErrorMessage(GetLastError));
end;

function addbackslash(const s:string):string;
var L:integer;
begin
    L:=Length(s);
    if(L=0) then Result:='\'
    else if (s[L]='\') then Result:=s
    else Result:=s+'\';

end;


function GetTempDir: TFileName;
var
  TmpDir: array [0..MAX_PATH-1] of char;
begin
  try
    SetString(Result, TmpDir, GetTempPath(MAX_PATH, TmpDir));
    if not DirectoryExists(Result) then
      if not CreateDirectory(PChar(Result), nil) then begin
        // fall back to %WINDOWS%\TEMP
        Result := addbackslash(GetWindowsDir) + 'TEMP'; //Of course it is specific to a platform! It is supposed to!
        if not DirectoryExists(Result) then
          if not CreateDirectory(PChar(Result), nil) then begin
            // fall back to %WINDOWS%'s drive\TEMP
            Result := ExtractFileDrive(Result) + '\TEMP';
            if not DirectoryExists(Result) then
              if not CreateDirectory(PChar(Result), nil) then begin
                // fall back to %WINDOWS%'s drive\TMP
                Result := ExtractFileDrive(Result) + '\TMP';
                if not DirectoryExists(Result) then
                  if not CreateDirectory(PChar(Result), nil) then begin
                    // no more fall back
                    raise Exception.Create('Failed to get Temp folder' + SysErrorMessage(GetLastError));
                  end;
              end;
          end;
      end;
    // create "Jass Helper" directory in Temp folder
    Result := addbackslash(Result) + 'Jass Helper';
    if not DirectoryExists(Result) then begin
        if not CreateDirectory(PChar(Result), nil) then begin
            raise Exception.Create('Failed to create Jass Helper Temp folder' + SysErrorMessage(GetLastError));
        end;
    end;
  except
    Result := '';
    raise;
  end;
end;

var used_temp_files : array of string;

function TempFile: TFileName;
// Crea un directorio temporal y devuelve su nombre y camino
var
    NomArchTemp: array [0..MAX_PATH-1] of char;
    TempDir : string;
    ErrorCode : integer;
begin
    TempDir := GetTempDir();
    if GetTempFileName(PChar(TempDir),'V', 0, NomArchTemp) = 0 then
    begin
        ErrorCode := GetLastError();
        if ErrorCode = ERROR_FILE_EXISTS then
            raise Exception.Create(SysErrorMessage(GetLastError) + #13#10'Delete ' + TempDir + ' and try again')
        else
            raise Exception.Create(SysErrorMessage(GetLastError) + #13#10'Report this')
    end;
    Result := NomArchTemp;
    SetLength(used_temp_files, Length(used_temp_files) + 1);
    used_temp_files[High(used_temp_files)] := Result;
end;

function CleanTempFiles : integer;
var
    i : integer;
begin
    for i := Low(used_temp_files) to High(used_temp_files) do begin
        DeleteFile(used_temp_files[i])
    end;
    SetLength(used_temp_files, 0);
    Result := i;
end;


end.

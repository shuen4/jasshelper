unit vxFilesys;
// Just generic file stuff
interface

uses
  Windows, SysUtils, Registry, Classes;


function GetWindowsDir: TFileName;
function GetTempDir: TFileName;
function TempFile: TFileName;
function GetAppDataDir: TFileName;
function LoadFile(const FileName: TFileName): AnsiString;
procedure SaveFile(const FileName: TFileName; const content: AnsiString);


implementation

function LoadFile(const FileName: TFileName): AnsiString;
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
procedure SaveFile(const FileName: TFileName; const content: AnsiString);
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
  WinDir: array [0..MAX_PATH-1] of WideChar;
begin
  SetString(Result, WinDir, GetWindowsDirectory(WinDir, MAX_PATH));
  if Result = '' then
    raise Exception.Create(SysErrorMessage(GetLastError));
end;

function addbackslash(const s:AnsiString):AnsiString;
var L:integer;
begin
    L:=Length(s);
    if(L=0) then Result:='\'
    else if (s[L]='\') then Result:=s
    else Result:=s+'\';

end;


function GetTempDir: TFileName;
var
  TmpDir: array [0..MAX_PATH-1] of WideChar;
begin
  try
    SetString(Result, TmpDir, GetTempPath(MAX_PATH, TmpDir));
    if not DirectoryExists(Result) then
      if not CreateDirectory(PChar(Result), nil) then begin
        Result := addbackslash(GetWindowsDir) + 'TEMP'; //Of course it is specific to a platform! It is supposed to!
        if not DirectoryExists(Result) then
          if not CreateDirectory(Pointer(Result), nil) then begin
            Result := ExtractFileDrive(Result) + '\TEMP';
            if not DirectoryExists(Result) then
              if not CreateDirectory(Pointer(Result), nil) then begin
                Result := ExtractFileDrive(Result) + '\TMP';
                if not DirectoryExists(Result) then
                  if not CreateDirectory(Pointer(Result), nil) then begin
                    raise Exception.Create(SysErrorMessage(GetLastError));
                  end;
              end;
          end;
      end;
  except
    Result := '';
    raise;
  end;
end;

function TempFile: TFileName;
// Crea un directorio temporal y devuelve su nombre y camino
var
  NomArchTemp: array [0..MAX_PATH-1] of WideChar;
begin
  if GetTempFileName(PChar(GetTempDir),'V', 0, NomArchTemp) = 0 then
    raise Exception.Create(SysErrorMessage(GetLastError));
  Result := NomArchTemp;
end;


end.

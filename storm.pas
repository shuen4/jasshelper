unit storm;

interface

uses Windows, Classes, SysUtils, dialogs;

type
  ESFileOpenArchive = class(Exception);
  ESFileCloseArchive = class(Exception);
  ESFileOpenFileEx = class(Exception);
  ESFileCloseFile = class(Exception);
  ESFileReadFile = class(Exception);

type
{  TMPQ = class;
    private

    protected

    public

    end;}
  nametype=Array[1..260] of char;

  FILELISTENTRY = record
    dwFileExists: dword;
    lcLocale: lcid;
	  dwCompressedSize:dword; // Compressed size of file
    dwFullSize:dword;
    dwFlags:dword;
	  szFileName: nametype;
  end;

  TMPQARCHIVE= ^MPQARCHIVE{MPQARCHIVE};
  TMPQFILE= ^MPQFILE{MPQFILE};
  TMPQHEADER= ^MPQHEADER{MPQHEADER};
  TBLOCKTABLEENTRY=^BLOCKTABLEENTRY{BLOCKTABLEENTRY};
  THASHTABLEENTRY=^HASHTABLEENTRY{HASHTABLEENTRY};
  TFileListEntry=^FileListEntry;

  MPQHEADER = record
	    dwMPQID:DWORD; //"MPQ\x1A" for mpq's, "BN3\x1A" for bncache.dat
	    dwHeaderSize:DWORD; // Size of this header
      dwMPQSize:DWORD; //The size of the mpq archive
	    wUnused0C:WORD; // Seems to always be 0
	    wBlockSize:WORD; // Size of blocks in files equals 512 << wBlockSize
	    dwHashTableOffset:DWORD; // Offset to hash table
	    dwBlockTableOffset:DWORD; // Offset to block table
	    dwHashTableSize:DWORD; // Number of entries in hash table
	    dwBlockTableSize:DWORD; // Number of entries in block table
  end;

//Handles to archive may be typecasted to this struct
//so you can access some of the file's properties directly.
// Needs to be opened with a valid maximum file number value.
  MPQARCHIVE = Record
     // Arranged according to priority with lowest priority first
     lpNextArc: TMpqArchive; // Pointer to the next ARCHIVEREC struct. Pointer to addresses of first and last archives if last archive
     lpPrevArc: TMpqArchive; // Pointer to the previous ARCHIVEREC struct. 0xEAFC5E23 if first archive
     szFileName: nametype; // Filename of the archive
     hFile:THandle; // The archive's file handle
     dwFlags1:dword; // Some flags, bit 1 (0 based) seems to be set when opening an archive from a CD
     dwPriority:dword; // Priority of the archive set when calling SFileOpenArchive
     lpLastReadFile:TMpqFile; // Pointer to the last read file's FILEREC struct. Only used for incomplete reads of blocks
     dwUnk:dword; // Seems to always be 0
     dwBlockSize:dword; // Size of file blocks in bytes
     lpLastReadBlock:^Byte; // Pointer to the read buffer for archive. Only used for incomplete reads of blocks
     dwBufferSize:dword; // Size of the read buffer for archive. Only used for incomplete reads of blocks
     dwMPQStart:dword; // The starting offset of the archive
     lpMPQHeader:TMpqHeader; // Pointer to the archive header
     lpBlockTable:TBlockTableEntry; // Pointer to the start of the block table
     lpHashTable:THashTableEntry; // Pointer to the start of the hash table
     dwFileSize:dword; // The size of the file in which the archive is contained
     dwOpenFiles:dword; // Count of files open in archive + 1
     MpqHeader:MPQHEADER;
     dwFlags:dword; //The only flag that should be changed is MOAU_MAINTAIN_LISTFILE
     lpFileName:LPSTR;
  end;

//Handles to files in the archive may be typecasted to this struct
//so you can access some of the file's properties directly.
  MPQFILE= record
    	lpNextFile:TMPQFILE; // Pointer to the next FILEREC struct. Pointer to addresses of first and last files if last file
	  	lpPrevFile:TMPQFILE; // Pointer to the previous FILEREC struct. 0xEAFC5E13 if first file
  		szFileName: nametype; // Filename of the file
  		hPlaceHolder: THandle; // Always 0xFFFFFFFF
  		lpParentArc:TMPQARCHIVE; // Pointer to the ARCHIVEREC struct of the archive in which the file is contained
  		lpBlockEntry:TBLOCKTABLEENTRY; // Pointer to the file's block table entry
  		dwCryptKey:DWORD; // Decryption key for the file
  		dwFilePointer:DWORD; // Position of file pointer in the file
  		dwUnk1:DWORD; // Seems to always be 0
  		dwBlockCount:DWORD; // Number of blocks in file
  		lpdwBlockOffsets: ^DWORD; // Offsets to blocks in file. There are 1 more of these than the number of blocks
  		dwReadStarted:DWORD; // Set to 1 after first read
  		dwUnk2:DWORD; // Seems to always be 0
  		lpLastReadBlock:^BYTE; // Pointer to the read buffer for file. Only used for incomplete reads of blocks
  		dwBytesRead:DWORD; // Total bytes read from open file
  		dwBufferSize:DWORD; // Size of the read buffer for file. Only used for incomplete reads of blocks
  		dwConstant:DWORD; // Seems to always be 1
  		lpHashEntry:THashTableEntry;
  		lpFileName: LPSTR ;
  end;

  BLOCKTABLEENTRY=record
	    dwFileOffset:DWORD; // Offset to file
	    dwCompressedSize:DWORD; // Compressed size of file
	    dwFullSize:DWORD; // Uncompressed size of file
	    dwFlags:DWORD; // Flags for file
  end;

  HASHTABLEENTRY=record
	    dwNameHashA:DWORD; // First name hash of file
	    dwNameHashB:DWORD; // Second name hash of file
	    lcLocale:LCID; // Locale ID of file
    	dwBlockTableIndex:DWORD; // Index to the block table entry for the file
  end;

const
  SFMPQ_DLL = 'bin\SFmpq.dll';
//  BUFSIZE = 166777216;

  //MpqOpenArchiveForUpdate flags
  MOAU_CREATE_NEW        = $00;
  MOAU_CREATE_ALWAYS     = $08; // Was wrongly named MOAU_CREATE_NEW
  MOAU_OPEN_EXISTING     = $04;
  MOAU_OPEN_ALWAYS       = $20;
  MOAU_READ_ONLY         = $10; // Must be used with MOAU_OPEN_EXISTING
  MOAU_MAINTAIN_LISTFILE = $01;

  // MpqAddFileToArchive flags
  MAFA_EXISTS           =$80000000; //Will be added if not present
  MAFA_UNKNOWN40000000  =$40000000;
  MAFA_MODCRYPTKEY      =$00020000;
  MAFA_ENCRYPT          =$00010000;
  MAFA_COMPRESS         =$00000200;
  MAFA_COMPRESS2        =$00000100;
  MAFA_REPLACE_EXISTING =$00000001;

// MpqAddFileToArchiveEx compression flags
  MAFA_COMPRESS_STANDARD =$08; //Standard PKWare DCL compression
  MAFA_COMPRESS_DEFLATE  =$02; //ZLib's deflate compression
  MAFA_COMPRESS_WAVE     =$81; //Standard wave compression
  MAFA_COMPRESS_WAVE2    =$41; //Unused wave compression

// Flags for individual compression types used for wave compression
  MAFA_COMPRESS_WAVECOMP1 =$80; //Main compressor for standard wave compression
 	MAFA_COMPRESS_WAVECOMP2 =$40; //Main compressor for unused wave compression
  MAFA_COMPRESS_WAVECOMP3 =$01; //Secondary compressor for wave compression

// ZLib deflate compression level constants (used with MpqAddFileToArchiveEx and MpqAddFileFromBufferEx)
  Z_NO_COMPRESSION      =  0;
  Z_BEST_SPEED          =  1;
  Z_BEST_COMPRESSION    =  9;//9;
  Z_DEFAULT_COMPRESSION =(-1);

// MpqAddWaveToArchive quality flags
  MAWA_QUALITY_HIGH   =1;
  MAWA_QUALITY_MEDIUM =0;
  MAWA_QUALITY_LOW    =2;

  // SFileGetFileInfo flags
  SFILE_INFO_BLOCK_SIZE      =$01; //Block size in MPQ
  SFILE_INFO_HASH_TABLE_SIZE =$02; //Hash table size in MPQ
  SFILE_INFO_NUM_FILES       =$03; //Number of files in MPQ
  SFILE_INFO_TYPE            =$04; //Is MPQHANDLE a file or an MPQ?
  SFILE_INFO_SIZE            =$05; //Size of MPQ or uncompressed file
  SFILE_INFO_COMPRESSED_SIZE =$06; //Size of compressed file
  SFILE_INFO_FLAGS           =$07; //File flags (compressed, etc.), file attributes if a file not in an archive
  SFILE_INFO_PARENT          =$08; //Handle of MPQ that file is in
  SFILE_INFO_POSITION        =$09; //Position of file pointer in files
  SFILE_INFO_LOCALEID        =$0A; //Locale ID of file in MPQ
  SFILE_INFO_PRIORITY        =$0B; //Priority of open MPQ
  SFILE_INFO_HASH_INDEX      =$0C; //Hash index of file in MPQ

  SFILE_SEARCH_CURRENT_ONLY  =$00; //Used with SFileOpenFileEx; only the archive with the handle specified will be searched for the file
  SFILE_SEARCH_ALL_OPEN      =$01; //SFileOpenFileEx will look through all open archives for the file

// SFileListFiles flags
  SFILE_LIST_MEMORY_LIST  =$01; // Specifies that lpFilelists is a file list from memory, rather than being a list of file lists
  SFILE_LIST_ONLY_KNOWN   =$02; // Only list files that the function finds a name for
  SFILE_LIST_ONLY_UNKNOWN =$04; // Only list files that the function does not find a name for


  var
 buf: array of byte;
  //  BUFSIZEX: dword = 4096;

//Storm functions in SFMPQAPI:
function SFileOpenArchive(lpFileName: LPCSTR; dwMPQID: DWORD; dwUnknown: DWORD; var lphMPQ: THandle): Boolean; stdcall; external SFMPQ_DLL;
function SFileCloseArchive(hMPQ: THandle): boolean; stdcall; external SFMPQ_DLL;
function SFileOpenFileEx(hMPQ: THandle; lpFileName: LPCSTR; dwSearchScope: DWORD; var lphFile: THandle): Boolean; stdcall; external SFMPQ_DLL;
function SFileCloseFile(hFile: THandle): Boolean; stdcall; external SFMPQ_DLL;
function SFileReadFile(hFile: THandle; var lpBuffer; nNumberOfBytesToRead: DWORD; var lpNumberOfBytesRead: DWORD; lpOverlapped: Pointer): Boolean; stdcall; external SFMPQ_DLL;
function SFileGetFileSize(hFile: THandle; lpFileSizeHigh: LPDWORD): DWORD; stdcall; external SFMPQ_DLL;
function SFileSetLocale(nNewLocale: LCID): LCID; stdcall; external SFMPQ_DLL;
function SFileGetArchiveName(hMPQ: THandle; lpBuffer: LPCSTR; dwBufferLength: DWORD): Boolean; stdcall; external SFMPQ_DLL;


function SFileGetFileArchive(hFile: THandle; hMPQ: THandle): Boolean; stdcall; external SFMPQ_DLL;
function SFileGetFileName(hFile: THandle; lpBuffer: LPCSTR; dwBufferLength: DWORD): Boolean; stdcall; external SFMPQ_DLL;

//Native SFMPQAPI Interface
function MpqOpenArchiveForUpdate(lpFileName: LPCSTR; dwFlags: DWORD; dwMaximumFilesInArchive: DWORD): THANDLE; stdcall; external SFMPQ_DLL;
function MpqAddFileToArchiveEx(hMPQ:THANDLE; lpSourceFileName:LPCSTR; lpDestFileName:LPCSTR; dwFlags:DWORD; dwCompressionType:DWORD; dwCompressLevel:DWORD): Boolean; stdcall; external SFMPQ_DLL;
function MpqCloseUpdatedArchive(hMPQ: THANDLE; dwUnknown2: DWORD): DWORD; stdcall; external SFMPQ_DLL;
function MpqAddFileToArchive(hMPQ: THANDLE; lpSourceFileName: LPCSTR; lpDestFileName: LPCSTR; dwFlags: DWORD): boolean; stdcall; external SFMPQ_DLL;
function MpqAddWaveToArchive(hMPQ: THANDLE; lpSourceFileName: LPCSTR; lpDestFileName: LPCSTR; dwFlags: DWORD; dwQuality: DWORD): boolean; stdcall; external SFMPQ_DLL;
function MpqRenameFile(hMPQ: THANDLE; lpcOldFileName: LPCSTR; lpcNewFileName: LPCSTR): boolean; stdcall; external SFMPQ_DLL;
function MpqDeleteFile(hMPQ: THANDLE; lpFileName: LPCSTR): boolean; stdcall; external SFMPQ_DLL;
function MpqCompactArchive(hMPQ: THANDLE): boolean; stdcall; external SFMPQ_DLL;

function SFileGetFileInfo(hFile:THANDLE;  dwInfoType:DWORD): dword; stdcall; external SFMPQ_DLL;
function SFileListFiles(hMPQ:THandle;  lpFileLists:LPCSTR; lpListBuffer:TFileListEntry; dwFlags:DWORD ): boolean; stdcall; external SFMPQ_DLL;


//Utility functions
//READING
function MPQOpenArchive(sFileName: PChar): THandle;
procedure MPQCloseArchive(hMPQ: THandle);
function MPQOpenFile(hMPQ: THandle; sMPQFileName: PChar): THandle;
procedure MPQCloseFile(hMPQFile: THandle);
function MPQGetFileSize(hMPQFile: THandle): DWORD;
procedure MPQExtractFile(hMPQ: THandle; sMPQFileName: PChar; sPath: String);
procedure MPQExtractFileTo(hMPQ: THandle; sMPQFileName: PChar; targetfile: String; dwbf:dword=0);
function MPQGetInternalList(hMPQ: THandle): TStringList;
function MPQListFiles(hMPQ: THandle): TStringList; overload;
function MPQListFiles(hMPQ: THandle; List: TStringList; bUseInternal: Boolean): TStringList; overload;
function MPQFileExists(hMPQ: THandle; sFileName: PChar): Boolean;
function MPQGetFileInfo(hMPQ: THandle; sFileName: PChar; dwInfoType:dword): dword;

{ Extra archive editing functions}
function MpqAddFileFromBufferEx(hMPQ: THANDLE;  lpBuffer: pointer;  dwLength: DWORD;  lpFileName: LPCSTR;  dwFlags: DWORD;  dwCompressionType: DWORD;  dwCompressLevel: DWORD): BOOL; stdcall; external SFMPQ_DLL;
function MpqAddFileFromBuffer(hMPQ: THANDLE;  lpBuffer: pointer;  dwLength: DWORD;  lpFileName: LPCSTR;  dwFlags: DWORD): BOOL; stdcall; external SFMPQ_DLL;
function MpqAddWaveFromBuffer(hMPQ: THANDLE;  lpBuffer: pointer;  dwLength: DWORD;  lpFileName: LPCSTR;  dwFlags: DWORD;  dwQuality: DWORD): BOOL; stdcall; external SFMPQ_DLL;
function MpqSetFileLocale(hMPQ: THANDLE;  lpFileName: LPCSTR;  nOldLocale: LCID;  nNewLocale: LCID): BOOL; stdcall; external SFMPQ_DLL;

procedure MPQExtractFileToStream(hMPQ: THandle; sMPQFileName: PChar; var target:TMemoryStream; dwbf:dword=0);


//WRITING
implementation

function MPQOpenArchive(sFileName: PChar): THandle;
  begin
    if not SFileOpenArchive(sFileName, 0, 0, Result) then
      raise ESFileOpenArchive.Create('Error opening archive');
  end;

procedure MPQCloseArchive(hMPQ: THandle);
  begin
    if not SFileCloseArchive(hMPQ) then
      raise ESFileCloseArchive.Create('Error closing archive');
  end;

function MPQOpenFile(hMPQ: THandle; sMPQFileName: PChar): THandle;
  begin
    if not SFileOpenFileEx(hMPQ, sMPQFileName, 0, Result) then
      raise ESFileOpenFileEx.Create('Error opening file: '+sMPQFileName);
  end;

procedure MPQCloseFile(hMPQFile: THandle);
  begin
    if not SFileCloseFile(hMPQFile) then
      raise ESFileCloseFile.Create('Error closing file handle');
  end;

function MPQReadFile(hMPQFile: THandle; var buffer; nNumberOfBytesToRead: DWORD): DWORD;
  begin
    if not SFileReadFile(hMPQFile, buffer, nNumberOfBytesToRead, Result, nil) then
      raise ESFileReadFile.Create('Error reading file');
  end;

function MPQGetFileSize(hMPQFile: THandle): DWORD;
  begin
    Result:= SFileGetFileSize(hMPQFile, nil);
  end;

function MPQFileExists(hMPQ: THandle; sFileName: PChar): Boolean;
  var
    hMPQFile: THandle;
  begin
    Result:= SFileOpenFileEx(hMPQ, sFileName, 0, hMPQFile);
    if Result then SFileCloseFile(hMPQFile);
  end;

{Vexorian}
function MPQGetFileInfo(hMPQ: THandle; sFileName: PChar; dwInfoType:dword): dword;
  var
    hMPQFile: THandle;
  begin
    if SFileOpenFileEx(hMPQ, sFileName, 0, hMPQFile) then begin
        Result:=SFileGetFileInfo(hMPQFile,dwInfoType);
        SFileCloseFile(hMPQFile);
    end
    else Result:=0;
  end;


procedure MPQExtractFileToStream(hMPQ: THandle; sMPQFileName: PChar; var target:TMemoryStream; dwbf:dword=0);
var
 hMPQFile: THandle;
// buf: array[0..BUFSIZE] of byte;
 p:pointer;
 dwRead: DWORD;
 dwLen: DWORD;
 i:integer;
 c:dword;
begin                                                                     //
    hMPQFile:= MPQOpenFile(hMPQ, sMPQFileName);

    if dwbf=0 then begin
        dwbf:=TMpqArchive(hmpq).mpqheader.wblocksize;
        c:=1;
        for i:=1 to (dwbf + 9) do c:=c*2;
        dwbf:=c;
       // for i:=1 to (buffz + 9) do c:=c*2;
    end;

    //    raise exception.Create('lame ='+IntToStr(dwbf));
    if dwbf=0 then dwbf:=4096;
    //Nw(p);
    GetMem(p,dwbf);

    dwLen:= MPQGetFileSize(hMPQFile);
    target:=TMemoryStream.Create;     //
    while dwLen > 0 do begin

        if dwLen >= dwbf then begin
            dwRead:= MPQReadFile(hMPQFile, p^, dwbf);
            target.Write(p^, dwRead);
            dwLen:= dwLen - dwRead;
        end
        else begin
            dwRead:= MPQReadFile(hMPQFile, p^, dwLen);
            target.Write(p^, dwRead);
            dwLen:= 0;
        end;
//    raise Exception.Create('oo');
    end;
    MPQCloseFile(hMPQFile);
    FreeMem(p,dwbf);
    //FileStream.Destroy;
end;







//By Vexorian, slight variation of last function:
procedure MPQExtractFileTo(hMPQ: THandle; sMPQFileName: PChar; targetfile: String; dwbf:dword=0);
var
 MemSt:TMemoryStream;
 FileStream:TFileStream;
begin                                                                     //
    FileStream:= TFileStream.Create(FileCreate(targetfile));
    MemSt:=TMemoryStream.Create;
    MPQExtractFileToStream(hMPQ,sMPQFileName,memSt,dwbf);
    FileStream.Write(MemSt.Memory^,MemSt.Size);
    MemSt.Destroy;
    FileStream.destroy;

end;





procedure MPQExtractFile(hMPQ: THandle; sMPQFileName: PChar; sPath: String);
begin
    MPQExtractFileTo(hMPQ, sMPQFileName, sPath+'\'+sMPQFileName);
end;
function MPQGetInternalList(hMPQ: THandle): TStringList;
  begin
    MPQExtractFile(hMPQ, '(listfile)', GetCurrentDir());
    Result:= TStringList.Create;
    Result.LoadFromFile('(listfile)');
    Windows.DeleteFile('(listfile)');
  end;

function MPQListFiles(hMPQ: THandle): TStringList; overload;
  var
    i: Integer;
  begin
    Result:= MPQGetInternalList(hMPQ);
    i:= 0;
    while i <= Result.Count - 1 do
      begin
        if not MPQFileExists(hMPQ, PChar(Result.Strings[i])) then
          begin
            Result.Delete(i);
            i:= i - 1;
          end;
        i:= i + 1;
      end;
  end;

function MPQListFiles(hMPQ: THandle; List: TStringList; bUseInternal: Boolean): TStringList; overload;
  var
    i: Integer;
  begin
    Result:= List;
    if bUseInternal then
      Result.AddStrings(MPQGetInternalList(hMPQ));
    i:= 0;
    while i <= Result.Count - 1 do
      begin
        if not MPQFileExists(hMPQ, PChar(Result.Strings[i])) then
          begin
            Result.Delete(i);
            i:= i - 1;
          end;
        i:= i + 1;
      end;
  end;

{function MergeListFileStrings(l1,l2:Tstrings): Tstrings;
var i:integer;
begin
    Result:=TStrings.Create;
    for i:=0 to (l1.Count-1) do if Result.IndexOf(l1[i])=-1 then Result.Add(l1[i]);
    for i:=0 to (l1.Count-1) do if Result.IndexOf(l2[i])=-1 then Result.Add(l2[i]);
end;

procedure MergeListFiles(l1,l2,target:string);
var
 f1,f2,t:TextFile;
 res:TStrings;
 s: string;
 i:integer;
begin
    res:=TStrings.Create;
    AssignFile(f1,l1);
    AssignFile(f2,l2);
    filemode:=fmOpenRead;
    Reset(f1);
    Reset(f2);
    repeat
        ReadLn(f1,s);
        if res.IndexOf(s)=-1 then res.Add(s);
    until EoF(f1);
    repeat
        ReadLn(f2,s);
        if res.IndexOf(s)=-1 then res.Add(s);
    until EoF(f2);
    CloseFile(f1);
    CloseFile(f2);
    AssignFile(t,target);
    filemode:=fmOpenWrite;
    Rewrite(t);
    for i:=0 to res.Count-1 do WriteLn(t,res[i]);
end;
}
end.



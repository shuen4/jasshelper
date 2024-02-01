	unit PluginTypes;

	interface

	type
	TSyncWinExecute = function(Command:PChar):Boolean; stdcall;
	TWEOpenMap = procedure(Map:PChar); stdcall;
	TWEMapSaved = function:Boolean; stdcall;
	TUniqueId = function:Word; stdcall;


	TMpqOpen = function(Mpq:PChar):THandle; stdcall;
	TMpqExtractFile = procedure(MpqHandle:THandle; ArchiveName, FileName:PChar); stdcall;
	TMpqDeleteFile = procedure(MpqHandle:THandle; ArchiveName:PChar); stdcall;
	TMpqAddFile = procedure(MpqHandle:THandle; ArchiveName, FileName:PChar); stdcall;
	TMpqCompact = procedure(MpqHandle:THandle); stdcall;
	TMpqFileExists = function(MpqHandle:THandle; ArchiveName:PChar):Boolean; stdcall;
	TMpqClose = procedure(MpqHandle:THandle); stdcall;
  TMpqAddBuffer = procedure (MpqHandle:THandle; ArchiveName:PChar; Buffer:Pointer; BufferLength:Cardinal); stdcall;
  TMpqLockFile = function (MpqHandle:THandle; ArchiveName:PChar):PChar; stdcall;
  TMpqFreeFile =	procedure (FileData:PChar); stdcall;


	TLoadMPQ = procedure(FileName:PChar); stdcall;

	TPreprocessorConfigure = procedure(Owner: LongWord); stdcall;
	TPreprocessorAbout = procedure(Owner: LongWord); stdcall;


	TErrorDialogClear = procedure; stdcall;
	TErrorDialogScript = procedure(Script:PChar; FileName:Boolean); stdcall;
	TErrorDialogAdd = procedure(ErrorMsg:PChar; Line: Integer); stdcall;
	TErrorDialogShow = procedure; stdcall;

	TProgressWndStart = procedure (Title:PChar;ProgressBar:Boolean); stdcall;
	TProgressWndTitle = procedure (Title:PChar); stdcall;
	TProgressWndProgress = procedure (Current, Max:Cardinal); stdcall;
	TProgressWndEnd = procedure; stdcall;

	PFunctionLibrary = ^TFunctionLibrary;
	TFunctionLibrary = packed record
	  SyncWinExecute: TSyncWinExecute;
	  LoadMPQ: TLoadMPQ;
	  MpqOpen: TMpqOpen;
	  MpqExtractFile: TMpqExtractFile;
	  MpqDeleteFile: TMpqDeleteFile;
	  MpqAddFile: TMpqAddFile;
	  MpqClose: TMpqClose;
	  WEOpenMap:TWEOpenMap;
	  MpqCompact:TMpqCompact;
	  UniqueId: TUniqueId;
	  ErrorDialogClear: TErrorDialogClear;
	  ErrorDialogScript :TErrorDialogScript;
	  ErrorDialogAdd: TErrorDialogAdd;
	  ErrorDialogShow: TErrorDialogShow;
	  ProgressWndStart: TProgressWndStart;
	  ProgressWndTitle: TProgressWndTitle;
	  ProgressWndProgress: TProgressWndProgress;
	  ProgressWndEnd: TProgressWndEnd;
	  Wc3Path:PChar;
	  WEMapSaved: TWEMapSaved;
	  MpqFileExists: TMpqFileExists;
    MpqAddBuffer: TMpqAddBuffer;
    MpqLockFile: TMpqLockFile;
    MpqFreeFile: TMpqFreeFile;
	end;

	PPreprocessorProcessInfo = ^TPreprocessorProcessInfo;
	TPreprocessorProcessInfo = packed record
	  FileName:PChar;
	  FunctionLibrary: PFunctionLibrary;
	  Failed, Error:Boolean;
	  BlizzardJ, CommonJ, ErrorMsg:PChar;
	end;

	PRegisterPlugin = ^TRegisterPlugin;
	TRegisterPlugin = packed record
	  Name: PChar;
	  CanAbout, CanConfigure: Boolean;
	  About: TPreprocessorAbout;
	  Configure: TPreprocessorConfigure;
	  Module:HMODULE;
	  DllName:PChar;
	end;

	TPreprocessorProcess = procedure(Info: PPreprocessorProcessInfo); stdcall;

	PRegisterPreprocessor = ^TRegisterPreprocessor;
	TRegisterPreprocessor = packed record
	  Process: TPreprocessorProcess;
	  CodeName, LongName:PChar;
	  Level:Cardinal;
	end;

	TMakePreprocessor = procedure(Info: PRegisterPreprocessor); stdcall;
	TMakePlugin = procedure(Info: PRegisterPlugin); stdcall;

	PRegisterInfo = ^TRegisterInfo;
	TRegisterInfo = packed record
	  Version, Application: Integer;
	  MakePlugin: TMakePlugin;
	  MakePreprocessor: TMakePreprocessor;
	  FunctionLibrary: PFunctionLibrary;
	  Enabled, InEditor: Boolean;
	end;

	THelperEntry = procedure (Info: PRegisterInfo); stdcall;


	implementation
	end.	

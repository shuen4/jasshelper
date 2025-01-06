unit SourceFeeder;

interface

uses
   Classes;

type

  TSourceFeeder = class
  private
    FStream : TStringStream;
    procedure SetText(const Value: AnsiString);
    function GetText: AnsiString;
  public
    constructor Create;
    destructor Destroy; override;

    function ReadCharFromBuffer(Pos: integer; var r:AnsiChar ):boolean;
    function ReadFromBuffer(Size: Integer; DiscardReadText: Boolean; ReturnAllText: Boolean): AnsiString;
    function Done: Boolean;
    function ReadLine: AnsiString;
    property Text: AnsiString read GetText write SetText;
    property Stream : TStringStream read FStream;
  end;

implementation

constructor TSourceFeeder.Create;
begin
  inherited;
  FStream := TStringStream.Create('');
end;

destructor TSourceFeeder.Destroy;
begin
  Stream.Free;
  inherited;
end;

function TSourceFeeder.Done: Boolean;
begin
  Result := Stream.Position >= Stream.Size;
end;

function TSourceFeeder.GetText: AnsiString;
begin
  Result := Stream.DataString;
end;


function TSourceFeeder.ReadCharFromBuffer(Pos: Integer; var r: AnsiChar):boolean;
var SavePos : integer;

begin
  SavePos := Stream.Position;


  if (Stream.Position+Pos>Length(Stream.DataString)) then begin
      result:=false;
  end else begin
      result:=true;
      r := AnsiChar(Stream.DataString[Stream.Position+Pos]);
  end;

  Stream.Position := SavePos;
end;


function TSourceFeeder.ReadFromBuffer(Size: Integer; DiscardReadText: Boolean; ReturnAllText: Boolean): AnsiString;
var SavePos : integer;
    Available: Integer;
begin
  SavePos := Stream.Position;

  if (Stream.Position - 1) + Size > Stream.Size
  then Available := Stream.Size - Stream.Position
  else Available := Size;

  if ReturnAllText then Result := Stream.ReadString(Available)
  else Result := Copy(Stream.DataString, Stream.Position + Size, 1);

  if not DiscardReadText then Stream.Position := SavePos;
end;

function TSourceFeeder.ReadLine: AnsiString;
var EndReached: Boolean;
    ch: AnsiString;
begin
  EndReached := False;
  while not (EndReached) and (not Done) do begin
    ch := ReadFromBuffer(1, True, True);
    if (ch = #10) or (ch = #13) then begin
      ch := ReadFromBuffer(1, False, True);
      if (ch = #10) or (ch = #13) then ReadFromBuffer(1, True, True);
      EndReached := True;
    end else Result := Result + ch;
  end;
end;

procedure TSourceFeeder.SetText(const Value: AnsiString);
begin
  FStream.Size := 0;
  FStream.WriteString(Value);
  FStream.Position := 0;
end;

end.

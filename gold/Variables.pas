unit Variables;

{
'================================================================================
' Class Name:
'      VariableList
'
' Instancing:
'      Private; Internal  (VB Setting: 1 - Private)
'
' Purpose:
'      This is a very simple class that stores a list of "variables". The GOLDParser
'      class uses a this class to store the parameter fields.
'
' Author(s):
'      Devin Cook
'      GOLDParser@DevinCook.com
'
' Dependacies:
'      (None)
'
'================================================================================
 Conversion to Delphi:
      Beany
      Beany@cloud.demon.nl

 Conversion status: Done, not tested
================================================================================
}

interface

uses Classes;

type

  TVariableList = class
  private
    MemberList: TStringList;
    function GetCount: Integer;
    function GetValue(Name: RawByteString): RawByteString;
    procedure SetValue(Name: RawByteString; Value: RawByteString);
    function GetName(Index: Integer): RawByteString;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(Name: RawByteString; Value: RawByteString);

    procedure Clear;
    property Count: Integer read GetCount;
    property Value[Name: RawByteString]: RawByteString read GetValue write SetValue;
    property Names[Index : integer] : RawByteString read GetName;
  end;

implementation

constructor TVariableList.Create;
begin
  inherited Create;
  MemberList := TStringList.Create;
end;

destructor TVariableList.Destroy;
begin
   MemberList.Free;
   inherited Destroy;
end;

procedure TVariableList.Add(Name: RawByteString; Value: RawByteString);
begin
  MemberList.Values[Name] := Value;
end;

procedure TVariableList.Clear;
begin
  MemberList.Clear;
end;

function TVariableList.GetCount: Integer;
begin
   Result := MemberList.Count;
end;

function TVariableList.GetName(Index: Integer): RawByteString;
begin
  Result := MemberList.Names[Index];
end;

function TVariableList.GetValue(Name: RawByteString): RawByteString;
begin
  Result := MemberList.Values[Name];
end;

procedure TVariableList.SetValue(Name: RawByteString; Value: RawByteString);
begin
  MemberList.Values[Name] := Value;
end;

end.


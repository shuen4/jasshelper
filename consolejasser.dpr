program consolejasser;

{$APPTYPE CONSOLE}

{$R 'grammar.res' 'grammar.rc'}

uses
  SysUtils,
  jasshelper in 'jasshelper.pas';

var
   f1:string='';
   f2:string='';
   debug:boolean=false;
   struct:boolean=false;
   temi:integer;


begin
  { TODO -oUser -cConsole Main : Insert code here }

  temi:=1;
  while(true) do begin
      if(ParamStr(temi)='--debug') then begin
          debug:=true;
          temi:=temi+1;
      end else if (ParamStr(temi)='--structs')  then begin
          struct:=true;
          temi:=temi+1;
      end else break;

  end;

  if (ParamStr(temi)='') or (ParamStr(temi+1)='') then begin
      WriteLn('jasshelper.exe [--debug] [--structs] input_war3map.j output.j');
      Halt(2);
  end;
      f1:=ParamStr(temi);
      f2:=ParamStr(temi+1);

try
   if(struct) then begin
       jasshelper.DoJasserStructMagic(f1,f2,debug);
   end else begin
       jasshelper.DoJasserMagic(f1,f2,debug);
   end;
except

 on e:JASSerException do begin
     WriteLn('Line '+IntToStr(e.linen+1)+': '+e.msg);
         if(e.two) then begin
             WriteLn('Line '+IntToStr(e.linen2+1)+': '+e.msg2);
         end;
         if(e.macro1>=0) then WriteLn('Line '+IntToStr(e.macro1+1)+': (From this macro instance)');
         if(e.macro2>=0) and(e.macro2<>e.macro1) then WriteLn('Line '+IntToStr(e.macro2+1)+': (From this macro instance)');
     Halt(1);
 end;
 on e:Exception do begin
     WriteLn('Error: '+e.Message);
     Halt(1);

 end;

end;






end.

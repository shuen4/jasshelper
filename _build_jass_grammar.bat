@echo off
cd GOLD-Builder-5.2.0-Cmd
goldbuild ..\jasshelper.grm ..\jasshelper.cgt
goldprog ..\jasshelper.cgt _jasssymbol.pgt ..\jasshelpersymbols.pas
del jasshelper.log
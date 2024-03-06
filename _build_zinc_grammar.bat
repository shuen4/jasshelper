@echo off
cd GOLD-Builder-5.2.0-Cmd
goldbuild ..\zinc.grm ..\zinc.cgt
goldprog ..\zinc.cgt _zinc.pgt ..\ZincSymbols.pas
del zinc.log
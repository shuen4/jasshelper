@echo off
@REM move compiled file to output folder
move /y cons\consolejasser.exe output
move /y grimoire\clijasshelper.exe output
move /y grimoire\grimoirecaller.exe output
move /y grimoire\grimoirejasshelper.exe output
move /y wehelper\jasshelperdll.dll output
move /y wehelper\jasshelperdll.rsm output
move /y wehelper\jasshelperinstaller.exe output
@REM create zip file
cd output
del output.zip
del debug_symbol.zip
7z a -mx9 -x!jasshelperdll.rsm output.zip *
7z a -mx9 debug_symbol.zip jasshelperdll.rsm
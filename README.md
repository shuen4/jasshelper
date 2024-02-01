source from: https://www.hiveworkshop.com/threads/is-there-any-way-to-get-source-code-for-vexs-jasshelper.329359/<br/>
<br/>
this is just a fix for inline `out of memory` error<br/>
ref:<br/>
https://www.hiveworkshop.com/threads/jasshelper-crashes-on-perfectly-compilable-code.264740/<br/>
https://www.hiveworkshop.com/threads/cohadars-jasshelper.268332/<br/>

## old readme
This is the source for the JASShelper. You require a win32 pascal (Delphi) to compile. I use Delphi 10 lite which is free and a really light download.<br/>
<br/>
You can find many projects: <br/>
'consolejasser': is the standalone compiler<br/>
'jasshelperdll" is the WEHelper plugin.<br/>
'jasshelperinstaller' is the installer for WEHelper<br/>
'grimoirejasshelper' is the source for mapcompiler.exe which would be soon used to allow JASShelper on grimoire once wehack.dll is officially released<br/>
<br/>
The WEHelper plugin uses plugintypes.pas from WEHelper source (that's the way to make a WEHelper plugin, it provides access to the registering api and other functions).<br/>
<br/>
In order to compile jasshelper.grm into jasshelper.cgt (if you modiffy) you need the Gold Parser Builder http://www.devincook.com/goldparser/ I am also including the source of the Delphi version of the parsing engine.<br/>
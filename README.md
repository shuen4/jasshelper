source from: https://www.hiveworkshop.com/threads/is-there-any-way-to-get-source-code-for-vexs-jasshelper.329359/<br/>
<br>
this repo contains modification of Vexorian's JassHelper source code for my own use.<br>
i am making this repository public so that anyone interested can download the source code and/or compiled binaries from here<br>
<br>
**i am not sure if i need to rename repo and/or jasshelper according to zlib license section 2**<br>
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
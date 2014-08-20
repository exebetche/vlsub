vlsub
=====

VLC extension to download subtitles from opensubtitles.org


Author: Guillaume Le Maout  
Contact: http://addons.videolan.org/messages/?action=newmessage&username=exebetche  
Bug report: http://addons.videolan.org/content/show.php/?content=148752  

#### INSTALLATION:
Create a directory "extensions" at this location if it doesn't exists, then extract the file "vlsub.lua" from the archive inside:
* Windows (all users): %ProgramFiles%\VideoLAN\VLC\lua\extensions\
* Windows (current user): %APPDATA%\vlc\lua\extensions\
* Linux (all users): /usr/lib/vlc/lua/extensions/
* Linux (current user): ~/.local/share/vlc/lua/extensions/
* Mac OS X (all users): /Applications/VLC.app/Contents/MacOS/share/lua/extensions/
* Mac OS X (current user): /Users/%your_name%/Library/Application Support/org.videolan.vlc/lua/extensions/


#### USAGE:
* Start Vlc
* Start your video
* Click on the menu View > VLSub or VLC > Extension > VLSub if you're on Mac OS X
* Click on "Search by hash" or "Search by name"
* Select a subtitles file on the list
* Click on "Download selection"
* That's it, the subtitles should appear on your video. 
* If you're not happy with your subtitles (wrong sync etc), you can select an other one and click "Download" again, that will erase the previous one and load it automatically.

#### Limitation:

Due to some bugs on Windows, if the path to your video contain non-english characters, the extension will not be able to save subtitles in this directory automatically (it will propose you to save it manually) and the "search by hash" method might be slower.

-> If possible, use a diretcory with english (ASCII) characters only to store your videos (on Windows only).

#### Changelog:

##### 2014-08-19 (version 0.9.12)
- Fix subtitles loading on Vlc 2.2

##### 2014-05-08 (version 0.9.11)
- Fix a bug due to opensubtitles header modifications
- Add a message at startup to warn it's not gonna work if net module not present 

##### 2013-09-05 (version 0.9.10)
- Add possibility to set opensubtitles.org username/password in config menu to avoid download limit to unlogged users

##### 2013-08-31 (version 0.9.9)
- Rewrite configuration process from scratch to avoid blocking problem with Win 8 + windows username with special characters
- Allow user to set VLSub's working directory from config interface 

##### 2013-07-25 (version 0.9.8)
- Add a method to search subtitles for videos file inside an archive 
- Add a method for video with specials characters in its name or path on Windows.

##### 2013-07-13 (version 0.9.6)
- Add an installer for Windows 7  
- Bug fix: display download behaviour display on xp  
- Bug fix: Add error message if github CA certificate is not present when downloading translations  
- Bug fix: closing dialog on config menu on OS X  

##### 2013-07-04 (version 0.9.5)
- Add interface localization option

##### 2013-04-25 (version 0.9)
- Simplified interface  
- Bug fix with subrip format (".sub") subtitles  
- Add a success message when subtitles are loaded  
- Display a download link to subtitles if direct download fail

##### 2012-12-18 (version 0.8)
- [Benoit Vallee] Fixed subtitle downloading when special characters are present on the video path  
- [Benoit Vallee] Fixed zip file deletion after subtitle has been extracted  

##### 2012-10-17 (version 0.7)
- [thePanz] Added subtitle language in listing  
- [thePanz] Added subtitle language in downloaded file (avoid filename collisions during download)  

##### version 0.6
- Use definitive user agent for opensubtitle API  
- Fix a bug when video file path contains accents/special characters on linux (same bug on windows not corrected yet)  

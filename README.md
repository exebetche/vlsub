vlsub
=====

VLC extension to download subtitles from opensubtitles.org


Author: Guillaume Le Maout  
Contact: http://addons.videolan.org/messages/?action=newmessage&username=exebetche  
Bug report: http://addons.videolan.org/content/show.php/?content=148752  

#### INSTALLATION:
Save the file "vlsub.lua" in vlc /lua/extensions directory of your OS:
* Windows (all users): %ProgramFiles%\VideoLAN\VLC\lua\extensions\
* Windows (current user): %APPDATA%\vlc\lua\extensions\
* Linux (all users): /usr/lib/vlc/lua/extensions/
* Linux (current user): ~/.local/share/vlc/lua/extensions/
* Mac OS X (all users): /Applications/VLC.app/Contents/MacOS/share/lua/extensions/
* Mac OS X (current user): /Users/%your_name%/Library/Application Support/org.videolan.vlc/lua/extensions/

#### KNOWN BUG:

LUA doesn't handle UTF8 very well: Subtitle download will fail if the path to your video file contains special/accentuated characters.
Changelog:

##### 2013-07-13 (version 0.9.6)
Add an installer for Windows 7
Bug fix: display download behaviour display on xp
Bug fix: Add error message if github CA certificate is not present when downloading translations
Bug fix: closing dialog on config menu on OS X

##### 2013-07-04 (version 0.9.5)
Add interface localization option

##### 2013-04-25 (version 0.9)
  Simplified interface
  Bug fix with subrip format (".sub") subtitles
  Add a success message when subtitles are loaded
  Display a download link to subtitles if direct download fail
  
##### 2012-12-18 (version 0.8)
  [Benoit Vallee] Fixed subtitle downloading when special characters are present on the video path
  [Benoit Vallee] Fixed zip file deletion after subtitle has been extracted

##### 2012-10-17 (version 0.7)
  [thePanz] Added subtitle language in listing
  [thePanz] Added subtitle language in downloaded file (avoid filename collisions during download)

##### version 0.6
  Use definitive user agent for opensubtitle API
  Fix a bug when video file path contains accents/special characters on linux (same bug on windows not corrected yet)

VLSub Extension for VLC media player 1.1 and 2.0
Copyright 2010 Guillaume Le Maout

Author: Guillaume Le Maout
Contact: http://addons.videolan.org/messages/?action=newmessage&username=exebetche
Bug report: http://addons.videolan.org/content/show.php/?content=148752

Description:
Search and download subtitles from opensubtitles.org using the hash of the video currently playing or its title.
INSTALLATION:
- click on the download button below
- when the file appears click on the menu file > save as... of your browser
- put the file in the vlc subfile /lua/extensions, by default:
* Windows (all users): %ProgramFiles%\VideoLAN\VLC\lua\extensions\
* Windows (current user): %APPDATA%\vlc\lua\extensions\
* Linux (all users): /usr/lib/vlc/lua/extensions/
* Linux (current user): ~/.local/share/vlc/lua/extensions/
* Mac OS X (all users): /Applications/VLC.app/Contents/MacOS/share/lua/extensions/
(create directories if they don't exist)

KNOWN BUG:
- LUA doesn't handle UTF8 very well: Subtitle download will fail if the path to your video file contains special/accentuated characters.
Changelog:


2013-04-25 (version 0.9)
Simplified interface
Bug fix with microDVD (".sub") subtitles
Add a success message when subtitles are loaded
Display a download link to subtitles if direct download fail
Integrated usage instructions
Add a configuration panel to set default language and other options
  
2012-12-18 (version 0.8)
  [Benoit Vallee] Fixed subtitle downloading when special characters are present on the video path
  [Benoit Vallee] Fixed zip file deletion after subtitle has been extracted

2012-10-17 (version 0.7)
  [thePanz] Added subtitle language in listing
  [thePanz] Added subtitle language in downloaded file (avoid filename collisions during download)

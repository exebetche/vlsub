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

version 0.6
  Use definitive user agent for opensubtitle API
  Fix a bug when video file path contains accents/special characters on linux (same bug on windows not corrected yet)

version 0.5
  Alternative imdb id search for series

version 0.4
  Bug fix: add a forgotten "make_uri"

version 0.3
  Translation of parts of the interface still in french (lazy me) 

version 0.2
  Bug fix: add "make_uri" method since it's no more available in vlc object

--[[
 VLSub Extension for VLC media player 1.1 and 2.0
 Copyright 2013 Guillaume Le Maout

 Authors:  Guillaume Le Maout
 Contact: http://addons.videolan.org/messages/?action=newmessage&username=exebetche
 Bug report: http://addons.videolan.org/content/show.php/?content=148752

 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
--]]

-- You can set here your default language by replacing nil with your language code (see below)
-- Example: 
--~ language = "fre", 
--~ language = "ger", 
--~ language = "eng",
--~ ...

local options = {
	language = nil, 
	downloadBehaviour = 'save',
	langExt = false,
	removeTag = false,
	progressBarSize = 60
}

local languages = {
	{'all', 'All'},
	{'alb', 'Albanian'},
	{'ara', 'Arabic'},
	{'arm', 'Armenian'},
	{'may', 'Malay'},
	{'bos', 'Bosnian'},
	{'bul', 'Bulgarian'},
	{'cat', 'Catalan'},
	{'eus', 'Basque'},
	{'chi', 'Chinese (China)'},
	{'hrv', 'Croatian'},
	{'cze', 'Czech'},
	{'dan', 'Danish'},
	{'dut', 'Dutch'},
	{'eng', 'English (US)'},
	{'bre', 'English (UK)'},
	{'epo', 'Esperanto'},
	{'est', 'Estonian'},
	{'fin', 'Finnish'},
	{'fre', 'French'},
	{'glg', 'Galician'},
	{'geo', 'Georgian'},
	{'ger', 'German'},
	{'ell', 'Greek'},
	{'heb', 'Hebrew'},
	{'hun', 'Hungarian'},
	{'ind', 'Indonesian'},
	{'ita', 'Italian'},
	{'jpn', 'Japanese'},
	{'kaz', 'Kazakh'},
	{'kor', 'Korean'},
	{'lav', 'Latvian'},
	{'lit', 'Lithuanian'},
	{'ltz', 'Luxembourgish'},
	{'mac', 'Macedonian'},
	{'nor', 'Norwegian'},
	{'per', 'Persian'},
	{'pol', 'Polish'},
	{'por', 'Portuguese (Portugal)'},
	{'pob', 'Portuguese (Brazil)'},
	{'rum', 'Romanian'},
	{'rus', 'Russian'},
	{'scc', 'Serbian'},
	{'slo', 'Slovak'},
	{'slv', 'Slovenian'},
	{'spa', 'Spanish (Spain)'},
	{'swe', 'Swedish'},
	{'tha', 'Thai'},
	{'tur', 'Turkish'},
	{'ukr', 'Ukrainian'},
	{'vie', 'Vietnamese'}
}
    
function descriptor()
	return { title = "VLsub 0.9" ;
		version = "0.9" ;
		author = "exebetche" ;
		url = 'http://www.opensubtitles.org/';
		shortdesc = "VLsub";
		description = "<center><b>VLsub</b></center>"
				.. "Dowload subtitles from OpenSubtitles.org" ;
		capabilities = {"menu", "input-listener" }
		--~ capabilities = {"menu" }
	}
end

function activate()
	vlc.msg.dbg("[VLsub] Welcome")
	
    check_config()
    set_default_language()
    set_default_behaviour()
	openSub.getFileInfo()
	openSub.getMovieInfo()
    show_main()
	collectgarbage()
end

function menu()
	  return { "Research", "Config", "Help" }
end

--~ Interface data

input_table = {} -- General widget id reference

function interface_main()
	dlg:add_label('Language:', 1, 1, 1, 1)
	input_table['language'] =  dlg:add_dropdown(2, 1, 2, 1)
	for k, l in ipairs(openSub.conf.languages) do
		if type(l) == "table" then
			input_table['language']:add_value(l[2], k)
		end
	end
	
	dlg:add_button('Search by hash', searchHash, 4, 1, 1, 1)
	
	dlg:add_label('Title:', 1, 2, 1, 1)
	input_table['title'] = dlg:add_text_input(openSub.movie.title or "", 2, 2, 2, 1)
	dlg:add_button('Search by name', searchIMBD, 4, 2, 1, 1)
	dlg:add_label('Season (series):', 1, 3, 1, 1)
	input_table['seasonNumber'] = dlg:add_text_input(openSub.movie.seasonNumber or "", 2, 3, 2, 1)
	dlg:add_label('Episode (series):', 1, 4, 1, 1)
	input_table['episodeNumber'] = dlg:add_text_input(openSub.movie.episodeNumber or "", 2, 4, 2, 1)
	input_table['mainlist'] = dlg:add_list(1, 5, 4, 1)
	input_table['message'] = dlg:add_label(' ', 1, 6, 4, 1)
	dlg:add_button('Show help', show_help, 1, 7, 1, 1)
	dlg:add_button('   Show config   ', show_conf, 2, 7, 1, 1)
	dlg:add_button('Download selection', download_subtitles, 3, 7, 1, 1)
	dlg:add_button('Close', deactivate, 4, 7, 1, 1) 
	
	display_subtitles()
end

function set_interface_main()
	-- Update movie title and co. if video input change
	if not type(input_table['title']) == 'userdata' then return false end
	
	openSub.getFileInfo()
	openSub.getMovieInfo()
	
	input_table['title']:set_text(openSub.movie.title or "")
	input_table['episodeNumber']:set_text(openSub.movie.episodeNumber or "")
	input_table['seasonNumber']:set_text(openSub.movie.seasonNumber or "")
end

function interface_config()
	dlg:add_label('Default language:', 1, 1, 1, 1)
	input_table['default_language'] = dlg:add_dropdown(2, 1, 3, 1)
	
	for k, l in ipairs(openSub.conf.languages) do
		input_table['default_language']:add_value(l[2], k)
	end	
	
	dlg:add_label('What to do with subtitles:', 1, 2, 1, 1)
	input_table['downloadBehaviour'] = dlg:add_dropdown(2, 2, 3, 1)
	
	for k, l in ipairs(openSub.conf.downloadBehaviours) do
		input_table['downloadBehaviour']:add_value(l[2], k)
	end	
	
	input_table['langExt'] = dlg:add_check_box('Display language code in file name', 1, 3, 0, 1)
	input_table['langExt']:set_checked(openSub.option.langExt)
	input_table['removeTag'] = dlg:add_check_box('Remove tags', 1, 4, 0, 1)
	input_table['removeTag']:set_checked(openSub.option.removeTag)
	dlg:add_button('Cancel', show_main, 3, 5, 1, 1)
	dlg:add_button('Save', apply_config, 4, 5, 1, 1)
	
end

function interface_help()
	local help_html = " Download subtittles from <a href='http://www.opensubtitles.org/'>opensubtitles.org</a> and display them while watching a video.<br>"..
		" <br>"..
		" <b><u>Usage:</u></b><br>"..
		" <br>"..
		" VLSub is meant to be used while your watching the video, so start it first (if nothing is playing you will get a link to download the subtitles in your browser).<br>"..
		" <br>"..
		" Choose the language for your subtitles and click on the button corresponding to one of the two research method provided by VLSub:<br>"..
		" <br>"..
		" <b>Method 1: Search by hash</b><br>"..
		" It is recommended to try this method first, because it performs a research based on the video file print, so you can find subtitles synchronized with your video.<br>"..
		" <br>"..
		" <b>Method 2: Search by name</b><br>"..
		" If you have no luck with the first method, just check the title is correct before clicking. If you search subtitles for a serie, you can also provide a season and episode number.<br>"..
		" <br>"..
		" <b>Downloading Subtitles</b><br>"..
		" Select one subtitle in the list and click on 'Download'.<br>"..
		" It will be put in the same directory that your video, with the same name (different extension)"..
		" so Vlc will load them automatically the next time you'll start the video.<br>"..
		" <br>"..
		" <b>/!\\ Beware :</b> Existing subtitles are overwrited without asking confirmation, so put them elsewhere if thet're important.<br>"..
		" <br>"..
		" Find more Vlc extensions at <a href='http://addons.videolan.org'>addons.videolan.org</a>."
		
	input_table['help'] = dlg:add_html(help_html, 1, 1, 4, 1)
	dlg:add_label(string.rep ("&nbsp;", 100), 1, 2, 3, 1)
	dlg:add_button('Ok', show_main, 4, 2, 1, 1)
end

function trigger_menu(id)
	if id == 1 then
		close_dlg()
		dlg = vlc.dialog(openSub.conf.useragent)
		interface_main()
	elseif id == 2 then
		close_dlg()
		dlg = vlc.dialog(openSub.conf.useragent..": Configuration")
		interface_config()
	elseif id == 3 then
		close_dlg()
		dlg = vlc.dialog(openSub.conf.useragent..": Help")
		interface_help()
	end
	--~ collectgarbage() -- create a warning?!
end 

function show_main()
	trigger_menu(1)
end

function show_conf()
	trigger_menu(2)
end

function show_help()
	trigger_menu(3)
end

function getenv_lang()
	local lang = os.getenv("LANG")
	
	if not lang then -- Windows
		local sysroot = assert(os.getenv('SystemRoot'))
		local cmd = sysroot..'\\system32\\reg.exe query "HKEY_CURRENT_USER\\Control Panel\\International" /v "LocaleName"'
		local f = assert(io.popen(cmd))
		local s = assert(f:read('*a'))
		f:close()
		lang = string.match(s, "([%w_-]+)%s+$")
	end
	
	lang = string.sub(lang, 0, 2)
	
	for i, v in ipairs(openSub.conf.languages) do
		if string.sub(v[1], 0, 2) == lang then
			openSub.option.language = v[1]
		end
	end
end

function set_default_language()
	if openSub.option.language then
		table.sort(openSub.conf.languages, function(a, b) 
			if a[1] == openSub.option.language then
				return true
			elseif b[1] == openSub.option.language then
				return false
			elseif a[1] == 'all' then
				return true
			elseif b[1] == 'all' then
				return false
			else
				return a[2] < b[2] 
			end
		end)
	end
end

function set_default_behaviour()
	if openSub.option.downloadBehaviour then
		table.sort(openSub.conf.downloadBehaviours, function(a, b) 
			if a[1] == openSub.option.downloadBehaviour then
				return true
			elseif b[1] == openSub.option.downloadBehaviour then
				return false
			else
				return a[1] > b[1] 
			end
		end)
	end
end

function deactivate()
    vlc.msg.dbg("[VLsub] Bye bye!")
	dlg:hide() 
	if openSub.token ~= "" then
		openSub.request("LogOut")
	end
   vlc.deactivate()
end

function close_dlg()
	vlc.msg.dbg("[VLSub] Closing dialog")

	if dlg ~= nil then 
		dlg:delete() 
	end
	
	dlg = nil
	input_table = nil
	input_table = {}
end

function check_config()
	local path = vlc.config.userdatadir()
	local slash = "/"
	if is_window_path(path) then
		slash = "\\"
	end

	openSub.conf.path = path..slash.."vlsub_conf.xml"
	
	if file_exist(openSub.conf.path) then
		vlc.msg.dbg("[VLSub] Loading config file:  " .. openSub.conf.path)
		load_config()
	elseif not openSub.option.language then
		getenv_lang()
	end
end

function load_config()
	local tmpFile = assert(io.open(openSub.conf.path, "rb"))
	local resp = tmpFile:read("*all")
	tmpFile:flush()
	tmpFile:close()
	local option = parse_xml(resp)
	for key, value in pairs(option) do
		if type(value) == "table" then-- Empty tag
			openSub.option[key] = ""
		else
			if value == "true" then
				openSub.option[key] = true
			elseif value == "false" then
				openSub.option[key] = false
			else
				openSub.option[key] = value
			end
		end
	end
end

function save_config()
	vlc.msg.dbg("[VLSub] Saving config file:  " .. openSub.conf.path)
	local tmpFile = assert(io.open(openSub.conf.path, "wb"))
	local resp = dump_xml(openSub.option)
	tmpFile:write(resp)
	tmpFile:flush()
	tmpFile:close()
end

function meta_changed()
	return false
end

function input_changed()
	set_interface_main()
end

openSub = {
	itemStore = nil,
	actionLabel = "",
	conf = {
		url = "http://api.opensubtitles.org/xml-rpc",
		path = nil,
		userAgentHTTP = "VLSub",
		useragent = "VLSub 0.9",
		downloadBehaviours = { 
			{'save', 'Load and save' },
			{'load', 'Load only'},
			{'manual', 'Manual download'}
		},
		languages = languages
	},
	option = options,
	session = {
		loginTime = 0,
		token = ""
	},
	file = {
		uri = nil,
		ext = nil,
		name = nil,
		path = nil,
		dir = nil,
		hash = nil,
		bytesize = nil,
		fps = nil,
		timems = nil,
		frames = nil
	},
	movie = {
		title = "",
		seasonNumber = "",
		episodeNumber = "",
		sublanguageid = ""
	},
	request = function(methodName)
		local params = openSub.methods[methodName].params()
		local reqTable = openSub.getMethodBase(methodName, params)
		local request = "<?xml version='1.0'?>"..dump_xml(reqTable)
		local host, path = parse_url(openSub.conf.url)		
		local header = {
			"POST "..path.." HTTP/1.1", 
			"Host: "..host, 
			"User-Agent: "..openSub.conf.userAgentHTTP, 
			"Content-Type: text/xml", 
			"Content-Length: "..string.len(request),
			"",
			""
		}
		request = table.concat(header, "\r\n")..request
		
		local response
		local status, responseStr = http_req(host, 80, request)
		
		if status == 200 then 
			response = parse_xmlrpc(responseStr)
			if response then
				if response.status == "200 OK" then
					return openSub.methods[methodName].callback(response)
				elseif response.status == "406 No session" then
					openSub.request("LogIn")
				elseif response then
					setError("code '"..response.status.."' ("..status..")")
					return false
				end
			else
				setError("Server not responding")
				return false
			end
		elseif status == 401 then
			setError("Request unauthorized")
			
			response = parse_xmlrpc(responseStr)
			if openSub.session.token ~= response.token then
				setMessage("Session expired, retrying")
				openSub.session.token = response.token
				openSub.request(methodName)
			end
			return false
		elseif status == 503 then 
			setError("Server overloaded, please retry later")
			return false
		end
		
	end,
	getMethodBase = function(methodName, param)
		if openSub.methods[methodName].methodName then
			methodName = openSub.methods[methodName].methodName
		end
		
		local request = {
		  methodCall={
			methodName=methodName,
			params={ param=param }}}
		
		return request
	end,
	methods = {
		LogIn = {
			params = function()
				openSub.actionLabel = "Logging in"
				return {
					{ value={ string=openSub.option.username } },
					{ value={ string=openSub.option.password } },
					{ value={ string=openSub.movie.sublanguageid } },
					{ value={ string=openSub.conf.useragent } } 
				}
			end,
			callback = function(resp)
				openSub.session.token = resp.token
				openSub.session.loginTime = os.time()
				return true
			end
		},
		LogOut = {
			params = function()
				openSub.actionLabel = "Logging out"
				return {
					{ value={ string=openSub.session.token } } 
				}
			end,
			callback = function()
				return true
			end
		},
		NoOperation = {
			params = function()
				openSub.actionLabel = "Checking session"
				return {
					{ value={ string=openSub.session.token } } 
				}
			end,
			callback = function(resp)
				return true
			end
		},
		SearchSubtitlesByHash = {
			methodName = "SearchSubtitles",
			params = function()
				openSub.actionLabel = "Searching subtitles"
				setMessage(openSub.actionLabel..": "..progressBarContent(0))
				
				return {
					{ value={ string=openSub.session.token } },
					{ value={
						array={
						  data={
							value={
							  struct={
								member={
								  { name="sublanguageid", value={ string=openSub.movie.sublanguageid } },
								  { name="moviehash", value={ string=openSub.file.hash } },
								  { name="moviebytesize", value={ double=openSub.file.bytesize } } }}}}}}}
				}
			end,
			callback = function(resp)
				openSub.itemStore = resp.data
			end
		},
		SearchSubtitles = {
			methodName = "SearchSubtitles",
			params = function()
				openSub.actionLabel = "Searching subtitles"
				setMessage(openSub.actionLabel..": "..progressBarContent(0))
								
				local member = {
						  { name="sublanguageid", value={ string=openSub.movie.sublanguageid } },
						  { name="query", value={ string=openSub.movie.title } } }
						  
				
				if openSub.movie.seasonNumber ~= nil then
					table.insert(member, { name="season", value={ string=openSub.movie.seasonNumber } })
				end 
				
				if openSub.movie.episodeNumber ~= nil then
					table.insert(member, { name="episode", value={ string=openSub.movie.episodeNumber } })
				end 
				
				return {
					{ value={ string=openSub.session.token } },
					{ value={
						array={
						  data={
							value={
							  struct={
								member=member
								   }}}}}}
				}
			end,
			callback = function(resp)
				openSub.itemStore = resp.data
			end
		}
	},
	getInputItem = function()
		return vlc.item or vlc.input.item()
	end,
	getFileInfo = function()
	-- Get video file path, name, extension from input uri
		local item = openSub.getInputItem()
		local file = openSub.file
		if not item then
			file.hasInput = false;
			file.cleanName = nil;
			file.protocol = nil;
			file.path = nil;
			file.name = nil;
			file.ext = nil;
		else
			vlc.msg.dbg("[VLSub] Video URI: "..item:uri())
			local parsed_uri = vlc.net.url_parse(item:uri())
			file.uri = item:uri()
			file.protocol = parsed_uri["protocol"]
			file.path = vlc.strings.decode_uri(parsed_uri["path"])
			-- Correction needed for windows
			local windowPath = string.match(file.path, "^/(%a:/.+)$")
			if windowPath then
				file.path = windowPath
				file.windowPath = true
			end
			file.dir, file.completeName = string.match(file.path, "^([^\n]-/?)([^/]+)$")
			file.name, file.ext = string.match(file.path, "([^/]-)%.?([^%.]*)$")
				
			if file.ext == "part" then
				file.name, file.ext = string.match(file.name, "^([^/]+)%.([^%.]+)$")
			end
			file.hasInput = true;
			file.cleanName = string.gsub(file.name, "[%._]", " ")
		end
		collectgarbage()
	end,
	getMovieInfo = function()
	-- Clean video file name and check for season/episode pattern in title
		if not openSub.file.name then
			openSub.movie.title = ""
			openSub.movie.seasonNumber = ""
			openSub.movie.episodeNumber = ""
			return false 
		end
		
		local showName, seasonNumber, episodeNumber = string.match(openSub.file.cleanName, "(.+)[sS](%d%d)[eE](%d%d).*")

		if not showName then
		   showName, seasonNumber, episodeNumber = string.match(openSub.file.cleanName, "(.+)(%d)[xX](%d%d).*")
		end
		
		if showName then
			openSub.movie.title = showName
			openSub.movie.seasonNumber = seasonNumber
			openSub.movie.episodeNumber = episodeNumber
		else
			openSub.movie.title = openSub.file.cleanName
			openSub.movie.seasonNumber = ""
			openSub.movie.episodeNumber = ""
		end
		collectgarbage()
	end,
	getMovieHash = function()
	-- Calculate movie hash
		openSub.actionLabel = "Calculating movie hash"
		setMessage(openSub.actionLabel..": "..progressBarContent(0))
		
		local item = openSub.getInputItem()
		
		if not item then
			setError("Please use this method during playing")
			return false
		end
		
		openSub.getFileInfo()
		if openSub.file.protocol ~= "file" then
			setError("This method works with local file only (for now)")
			return false
		end
			
		local path = openSub.file.path
		if not path then
			setError("File not found")
			return false
		end
		
		local file = io.open(path, "rb")
		if not file then
			setError("File not found (illegal character?)")
			return false
		end
				
        local lo = 0
        local hi = 0
        local a,b,c,d, size
        
        for i=1,8192 do
                a,b,c,d = file:read(4):byte(1,4)
                lo = lo + a + b*256 + c*65536 + d*16777216
                a,b,c,d = file:read(4):byte(1,4)
                hi = hi + a + b*256 + c*65536 + d*16777216
                while lo>=4294967296 do
                        lo = lo-4294967296
                        hi = hi+1
                end
                while hi>=4294967296 do
                        hi = hi-4294967296
                end
        end
        size = file:seek("end", -65536) + 65536
        for i=1,8192 do
                a,b,c,d = file:read(4):byte(1,4)
                lo = lo + a + b*256 + c*65536 + d*16777216
                a,b,c,d = file:read(4):byte(1,4)
                hi = hi + a + b*256 + c*65536 + d*16777216
                while lo>=4294967296 do
                        lo = lo-4294967296
                        hi = hi+1
                end
                while hi>=4294967296 do
                        hi = hi-4294967296
                end
        end
        lo = lo + size
                while lo>=4294967296 do
                        lo = lo-4294967296
                        hi = hi+1
                end
                while hi>=4294967296 do
                        hi = hi-4294967296
                end
		
		openSub.file.bytesize = size
		openSub.file.hash = string.format("%08x%08x", hi,lo)
	end,
	checkSession = function()
		
		if openSub.session.token == "" then
			openSub.request("LogIn")
		else
			openSub.request("NoOperation")
		end
	end
}

function searchHash()
	openSub.movie.sublanguageid = openSub.conf.languages[input_table["language"]:get_value()][1]
	openSub.getMovieHash()
	
	if openSub.file.hash then
		openSub.checkSession()
		openSub.request("SearchSubtitlesByHash")
		display_subtitles()
	end
end

function searchIMBD()
	openSub.movie.title = trim(input_table["title"]:get_text())
	openSub.movie.seasonNumber = tonumber(input_table["seasonNumber"]:get_text())
	openSub.movie.episodeNumber = tonumber(input_table["episodeNumber"]:get_text())
	openSub.movie.sublanguageid  = openSub.conf.languages[input_table["language"]:get_value()][1]
	
	if openSub.movie.title ~= "" then
		openSub.checkSession()
		openSub.request("SearchSubtitles")
		display_subtitles()
	end
end

function display_subtitles()
	local mainlist = input_table["mainlist"]
	mainlist:clear()
	
	if openSub.itemStore == "0" then 
		mainlist:add_value("No result", 1)
		setMessage("<b>Research complete:</b> No result")
	elseif openSub.itemStore then 
		for i, item in ipairs(openSub.itemStore) do
			mainlist:add_value(
			item.SubFileName..
			" ["..item.SubLanguageID.."]"..
			" ("..item.SubSumCD.." CD)", i)
		end
		setMessage("<b>Research complete:</b> "..#(openSub.itemStore).." result(s)")
	end
end

function get_first_sel(list)
	local selection = list:get_selection()
	for index, name in pairs(selection) do 
		return index
	end
	return 0
end

function download_subtitles()
	local index = get_first_sel(input_table["mainlist"])
	
	if index == 0 then
		setMessage("No subtitles selected")
		return false
	end
	
	openSub.actionLabel = "Downloading subtitle"
	
	display_subtitles() -- reset selection
	
	local item = openSub.itemStore[index]
	
	if openSub.option.downloadBehaviour == 'manual' then
			setMessage("<span style='color:#181'><b>Download link:</b></span> &nbsp;<a href='"..item.ZipDownloadLink.."'>"..item.MovieReleaseName.."</a>")
		return false
	elseif openSub.option.downloadBehaviour == 'load' then
		if add_sub("zip://"..item.ZipDownloadLink.."!/"..item.SubFileName) then
			setMessage(success_tag("Subtitles loaded from stream"))
		end
		return false
	end
	
	local message = ""
	local subfileName = openSub.file.name
	
	if openSub.option.langExt then
		subfileName = subfileName.."."..item.SubLanguageID
	end
	
	subfileName = subfileName.."."..item.SubFormat
	
	local tmpFileURI, tmpFileName = dump_zip(item.ZipDownloadLink, item.SubFileName)
	vlc.msg.dbg("[VLsub] tmpFileName: "..tmpFileName)
	
	-- Determine if the path to the video file is accessible for writing
	
	local target = openSub.file.dir..subfileName
    local target_exist = true

	-- if target is not accessible, pick an alternative target (homedir)
	if not file_touch(target) then 
		local slash = "/"
		if openSub.file.windowPath then
			slash = "\\"
		end
		target = vlc.config.homedir()..slash..subfileName
		target_exist = false
	end
	
	vlc.msg.dbg("[VLsub] Subtitles files: "..target)
	
	-- Unzipped data into file target 
		
	local stream = vlc.stream(tmpFileURI)
	local data = ""
	local subfile = assert(io.open(target, "w"))
   
	while data do
		if openSub.conf.removeTag == true then
			subfile:write(remove_tag(data).."\n")
		else
			subfile:write(data.."\n")
		end
		data = stream:readline()
	end
	
	subfile:flush()
	subfile:close()
	
	stream = nil
	collectgarbage()
	
	if not os.remove(tmpFileName) then
		vlc.msg.err("[VLsub] Unable to remove temp: "..tmpFileName)
	end
	
	subfileURI = vlc.strings.make_uri(target)
	
	if not subfileURI then
		subfileURI = make_uri(target, true)
	end
	
	-- load subtitles
	if add_sub(subfileURI) then 
		message = success_tag("Subtitles loaded")
	end
	
	-- display a link, if path is inaccessible
	if not target_exist then 
		message =  message..
		"<br> "..error_tag("Unable to save subtitles &nbsp;"..
		"<a href='"..subfileURI.."'>Click here to open the file</a>")
	end
	
	setMessage(message)
end

function dump_zip(url, subfileName)
	-- Dump zipped data in a temporary file
	setMessage(openSub.actionLabel..": "..progressBarContent(0))
	local resp = get(url)
	
	if not resp then 
		setError("No response from  server.")
		return false 
	end
	
	local slash = "/"
	if openSub.file.windowPath then
		slash = "\\"
	end
	
	local tmpFileName = vlc.config.cachedir()..slash..subfileName..".gz"
	local tmpFile = assert(io.open(tmpFileName, "wb"))
		
	tmpFile:write(resp)
	tmpFile:flush()
	tmpFile:close()
	tmpFile = nil
	collectgarbage()
	return "zip://"..vlc.strings.make_uri(tmpFileName).."!/"..subfileName, tmpFileName
end

function add_sub(subfileURI)
	if vlc.item or vlc.input.item() then
		vlc.msg.dbg("[VLsub] Adding subtitle :" .. subfileURI)
		return vlc.input.add_subtitle(subfileURI)
	end
	return false
end

-- UI stuff

function apply_config()
	local lang_sel = openSub.conf.languages[input_table["default_language"]:get_value()][1]
	
	if openSub.option.language ~= lang_sel then
		openSub.option.language = lang_sel
		set_default_language()
	end
	
	local behaviour_sel = openSub.conf.downloadBehaviours[input_table["downloadBehaviour"]:get_value()][1]
	
	if openSub.option.downloadBehaviour ~= behaviour_sel then
		openSub.option.downloadBehaviour = behaviour_sel
		set_default_behaviour()
	end
	
	openSub.option.langExt = input_table["langExt"]:get_checked()
	openSub.option.removeTag = input_table["removeTag"]:get_checked()
	
	save_config()
	trigger_menu(1)
end

function progressBarContent(pct)
	local accomplished = math.ceil(openSub.option.progressBarSize*pct/100)
	local left = openSub.option.progressBarSize - accomplished
	local content = "<span style='background-color:#181;color:#181;'>"..
		string.rep ("-", accomplished).."</span>"..
		"<span style='background-color:#fff;color:#fff;'>"..
		string.rep ("-", left)..
		"</span>"
	return content
end

function setMessage(str)
	if input_table["message"] then
		input_table["message"]:set_text(str)
		dlg:update()
	end
end

-- General interface utils

function setError(mess)
	setMessage(error_tag(mess))
end

function success_tag(str)
	return "<span style='color:#181'><b>Success:</b></span> "..str..""
end

function error_tag(str)
	return "<span style='color:#B23'><b>Error:</b></span> "..str..""
end

--~ Network utils

function get(url)
	local host, path = parse_url(url)
	local header = {
		"GET "..path.." HTTP/1.1", 
		"Host: "..host, 
		"User-Agent: "..openSub.conf.userAgentHTTP,
		"",
		""
	}
	local request = table.concat(header, "\r\n")
		
	local response
	local status, response = http_req(host, 80, request)
	
	if status == 200 then 
		return response
	else
		return false
	end
end

function http_req(host, port, request)
	local fd = vlc.net.connect_tcp(host, port)
	if not fd then return false end
	local pollfds = {}
	
	pollfds[fd] = vlc.net.POLLIN
	vlc.net.send(fd, request)
	vlc.net.poll(pollfds)
	
	local response = vlc.net.recv(fd, 1024)
	local headerStr, body = string.match(response, "(.-\r?\n)\r?\n(.*)")
	local header = parse_header(headerStr)
	local contentLength = tonumber(header["Content-Length"])
	local TransferEncoding = header["Transfer-Encoding"]
	local status = tonumber(header["statuscode"])
	local bodyLenght = string.len(body)
	local pct = 0
	
	if status ~= 200 then return status end
	
	while contentLength and bodyLenght < contentLength do
		vlc.net.poll(pollfds)
		response = vlc.net.recv(fd, 1024)

		if response then
			body = body..response
		else
			vlc.net.close(fd)
			return false
		end
		bodyLenght = string.len(body)
		pct = bodyLenght / contentLength * 100
		setMessage(openSub.actionLabel..": "..progressBarContent(pct))
	end
	vlc.net.close(fd)
	
	return status, body
end

function parse_header(data)
	local header = {}
	
	for name, s, val in string.gfind(data, "([^%s:]+)(:?)%s([^\n]+)\r?\n") do
		if s == "" then header['statuscode'] =  tonumber(string.sub (val, 1 , 3))
		else header[name] = val end
	end
	return header
end 

function parse_url(url)
	local url_parsed = vlc.net.url_parse(url)
	return  url_parsed["host"], url_parsed["path"], url_parsed["option"]
end

--~ XML utils

function parse_xml(data)
	local tree = {}
	local stack = {}
	local tmp = {}
	local level = 0
	
	table.insert(stack, tree)

	for op, tag, p, empty, val in string.gmatch(data, "<(%/?)([%w:]+)(.-)(%/?)>[%s\r\n\t]*([^<]*)") do
		if op=="/" then
			if level>0 then
				level = level - 1
				table.remove(stack)
			end
		else
			level = level + 1
			if val == "" then
				if type(stack[level][tag]) == "nil" then
					stack[level][tag] = {}
					table.insert(stack, stack[level][tag])
				else
					if type(stack[level][tag][1]) == "nil" then
						tmp = nil
						tmp = stack[level][tag]
						stack[level][tag] = nil
						stack[level][tag] = {}
						table.insert(stack[level][tag], tmp)
					end
					tmp = nil
					tmp = {}
					table.insert(stack[level][tag], tmp)
					table.insert(stack, tmp)
				end
			else
				if type(stack[level][tag]) == "nil" then
					stack[level][tag] = {}
				end
				stack[level][tag] = vlc.strings.resolve_xml_special_chars(val)
				table.insert(stack,  {})
			end
			if empty ~= "" then
				stack[level][tag] = ""
				level = level - 1
				table.remove(stack)
			end
		end
	end
	return tree
end

function parse_xmlrpc(data)
	local tree = {}
	local stack = {}
	local tmp = {}
	local tmpTag = ""
	local level = 0
	table.insert(stack, tree)

	for op, tag, p, empty, val in string.gmatch(data, "<(%/?)([%w:]+)(.-)(%/?)>[%s\r\n\t]*([^<]*)") do
		if op=="/" then
			if tag == "member" or tag == "array" then
				if level>0  then
					level = level - 1
					table.remove(stack)
				end
			end
		elseif tag == "name" then 
			level = level + 1
			if val~=""then tmpTag  = vlc.strings.resolve_xml_special_chars(val) end
			
			if type(stack[level][tmpTag]) == "nil" then
				stack[level][tmpTag] = {}
				table.insert(stack, stack[level][tmpTag])
			else
				tmp = nil
				tmp = {}
				table.insert(stack[level-1], tmp)
				
				stack[level] = nil
				stack[level] = tmp
				table.insert(stack, tmp)
			end
			if empty ~= "" then
				level = level - 1
				stack[level][tmpTag] = ""
				table.remove(stack)
			end
		elseif tag == "array" then
			level = level + 1
			tmp = nil
			tmp = {}
			table.insert(stack[level], tmp)
			table.insert(stack, tmp)
		elseif val ~= "" then 
			stack[level][tmpTag] = vlc.strings.resolve_xml_special_chars(val)
		end
	end
	return tree
end

function dump_xml(data)
	local level = 0
	local stack = {}
	local dump = ""
	
	local function parse(data, stack)
		for k,v in pairs(data) do
			if type(k)=="string" then
				dump = dump.."\r\n"..string.rep (" ", level).."<"..k..">"	
				table.insert(stack, k)
				level = level + 1
			elseif type(k)=="number" and k ~= 1 then
				dump = dump.."\r\n"..string.rep (" ", level-1).."<"..stack[level]..">"
			end
			
			if type(v)=="table" then
				parse(v, stack)
			elseif type(v)=="string" then
				dump = dump..vlc.strings.convert_xml_special_chars(v)
			elseif type(v)=="number" then
				dump = dump..v
			else
				dump = dump..tostring(v)
			end
			
			if type(k)=="string" then
				if type(v)=="table" then
					dump = dump.."\r\n"..string.rep (" ", level-1).."</"..k..">"
				else
					dump = dump.."</"..k..">"
				end
				table.remove(stack)
				level = level - 1
				
			elseif type(k)=="number" and k ~= #data then
				if type(v)=="table" then
					dump = dump.."\r\n"..string.rep (" ", level-1).."</"..stack[level]..">"
				else
					dump = dump.."</"..stack[level]..">"
				end
			end
		end
	end
	parse(data, stack)
	return dump
end

--~ Misc utils

function make_uri(str, encode)
    local windowdrive = string.match(str, "^(%a:\).+$")
	if encode then
		local encodedPath = ""
		for w in string.gmatch(str, "/([^/]+)") do
			encodedPath = encodedPath.."/"..vlc.strings.encode_uri_component(w) 
		end
		str = encodedPath
	end
    if windowdrive then
        return "file:///"..windowdrive..str
    else
        return "file://"..str
    end
end

function is_window_path(path)
	return string.match(path, "^(%a:\).+$")
end

function file_touch(name) -- test writetability
	local f=io.open(name ,"w")
	if f~=nil then 
		io.close(f) 
		return true 
	else 
		return false 
	end
end

function file_exist(name) -- test readability
	local f=io.open(name ,"r")
	if f~=nil then 
		io.close(f) 
		return true 
	else 
		return false 
	end
end

function trim(str)
    if not str then return "" end
    return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

function remove_tag(str)
	return string.gsub(str, "{[^}]+}", "")
end

function sleep(sec)
   local t = vlc.misc.mdate()
   vlc.misc.mwait(t + sec*1000*1000)
end


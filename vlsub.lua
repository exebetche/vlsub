--[[
 VLSub Extension for VLC media player 1.1 and 2.0
 Copyright 2010 Guillaume Le Maout

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

 Changes by Mondane in 0.8.1
 - different style progress bar (thanks to mederi)
 - start searching for subtitles with hash method when opening VLSub
 - added button 'Download and close' for hash method
 - renamed 'Ok' to 'Download' for hash method
 - renamed 'Ok' to 'Search or download' for IMDB method

--]]

-- Extension description
function descriptor()
	return { title = "VLsub 0.8.1" ;
		version = "0.8.1" ;
		author = "exebetche" ;
		url = 'http://www.opensubtitles.org/';
		shortdesc = "VLsub";
		description = "<center><b>VLsub</b></center>"
				.. "Download subtitles from OpenSubtitles.org" ;
		capabilities = { "input-listener", "meta-listener" }
	}
end

-- Global variables
dlg = nil     -- Dialog
conflocation = 'subdownloader.conf'
url = "http://api.opensubtitles.org/xml-rpc"
progressBarSize = 40
interface_state = 0
result_state = {}
default_language = "eng"

function set_default_language()
	if default_language then
		for k,v in ipairs(languages) do
			if v[2] == default_language then
				table.insert(languages, 1, v)
				return true
			end
		end
	end
end

function activate()
    vlc.msg.dbg("[VLsub] Welcome")
    set_default_language()
    create_dialog()
	openSub.getFileInfo()
	openSub.getMovieInfo()
    --~ openSub.request("LogIn")

    -- Automatically start searching for subtitles if there is an item loaded in VLC.
    local item = openSub.getInputItem()
    if item then
        set_interface()
    end
end

function deactivate()
	if openSub.token then
		openSub.LogOut()
	end
    vlc.msg.dbg("[VLsub] Bye bye!")
end

function close()
    vlc.deactivate()
end

function meta_changed()
	openSub.getFileInfo()
	openSub.getMovieInfo()
	if tmp_method_id == "hash" then
		searchHash()
	elseif tmp_method_id == "imdb" then
		widget.get("title").input:set_text(openSub.movie.name)
		widget.get("season").input:set_text(openSub.movie.seasonNumber)
		widget.get("episode").input:set_text(openSub.movie.episodeNumber)
	end
end

function input_changed()
	return false
end

openSub = {
	itemStore = nil,
	actionLabel = "",
	conf = {
		url = "http://api.opensubtitles.org/xml-rpc",
		userAgentHTTP = "VLSub",
		useragent = "VLSub 0.6",
		username = "",
		password = "",
		language = "",
		downloadSub = true,
		removeTag = true,
		justgetlink = false
	},
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
		name = "",
		season = "",
		episode = "",
		imdbid = nil,
		imdbidShow = nil,
		imdbidEpisode = nil,
		imdbRequest = nil,
		year = nil,
		releasename = nil,
		aka = nil
	},
	sub = {
		id = nil,
		authorcomment = nil,
		hash = nil,
		idfile = nil,
		filename = nil,
		content = nil,
		IDSubMovieFile = nil,
		score = nil,
		comment = nil,
		bad = nil,
		languageid = nil
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
			if (response and response.status == "200 OK") then
				vlc.msg.dbg(responseStr)
				return openSub.methods[methodName].callback(response)
			elseif response then
				setError("code "..response.status.."("..status..")")
				return false
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
					{ value={ string=openSub.conf.username } },
					{ value={ string=openSub.conf.password } },
					{ value={ string=openSub.conf.language } },
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
				return {
					{ value={ string=openSub.session.token } } 
				}
			end,
			callback = function()
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
								  { name="sublanguageid", value={ string=openSub.sub.languageid } },
								  { name="moviehash", value={ string=openSub.file.hash } },
								  { name="moviebytesize", value={ double=openSub.file.bytesize } } }}}}}}}
				}
			end,
			callback = function(resp)
				openSub.itemStore = resp.data
				
				if openSub.itemStore ~= "0" then
					return true
				else
					openSub.itemStore = nil
					return false
				end
			end
		},
		SearchMoviesOnIMDB = {
			params = function()
				openSub.actionLabel = "Searching movie on IMDB"
				setMessage(openSub.actionLabel..": "..progressBarContent(0))
				
				return {
					{ value={ string=openSub.session.token } },
					{ value={ string=openSub.movie.imdbRequest } } 
				}
			end,
			callback = function(resp)
				openSub.itemStore = resp.data
					
				if openSub.itemStore ~= "0" then
					return true
				else
					openSub.itemStore = nil
					return false
				end
			end
		},
		SearchSubtitlesByIdIMDB = {
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
								  { name="sublanguageid", value={ string=openSub.sub.languageid } },
								  { name="imdbid", value={ string=openSub.movie.imdbid } } }}}}}}}
				}
			end,
			callback = function(resp)
				openSub.itemStore = resp.data
					
				if openSub.itemStore ~= "0" then
					return true
				else
					openSub.itemStore = nil
					return false
				end
			end
		},
		GetIMDBMovieDetails = {
			params = function()
				return {
					{ value={ string=openSub.session.token } },
					{ value={ string=openSub.movie.imdbid } } 
				}
			end,
			callback = function(resp)
				print(dump_xml(resp))
			end
		},
		IsTVserie = {
			methodName = "GetIMDBMovieDetails",
			params = function()
				return {
					{ value={ string=openSub.session.token } },
					{ value={ string=openSub.movie.imdbid } } 
				}
			end,
			callback = function(resp)
				return (string.lower(resp.data.kind)=="tv series")
			end
		}
	},
	getInputItem = function()
		return vlc.item or vlc.input.item()
	end,
	getFileInfo = function()
		local item = openSub.getInputItem()
		if not item then
			return false
		else
			local file = openSub.file
			local parsed_uri = vlc.net.url_parse(item:uri())
			file.uri = item:uri()
			file.protocol = parsed_uri["protocol"]
			file.path = vlc.strings.decode_uri(parsed_uri["path"])
			--correction needed for windows
			local windowPath = string.match(file.path, "^/(%a:/.+)$")
			if windowPath then
				file.path = windowPath
			end
			file.dir, file.completeName = string.match(file.path, "^([^\n]-/?)([^/]+)$")
			file.name, file.ext = string.match(file.path, "([^/]-)%.?([^%.]*)$")
				
			if file.ext == "part" then
				file.name, file.ext = string.match(file.name, "^([^/]+)%.([^%.]+)$")
			end
			file.cleanName = string.gsub(file.name, "[%._]", " ")
		end
	end,
	getMovieInfo = function()
		if not openSub.file.name then
			return false 
		end
		
		local showName, seasonNumber, episodeNumber = string.match(openSub.file.cleanName, "(.+)[sS](%d%d)[eE](%d%d).*")

		if not showName then
		   showName, seasonNumber, episodeNumber = string.match(openSub.file.cleanName, "(.+)(%d)[xX](%d%d).*")
		end
		
		if showName then
			openSub.movie.name = showName
			openSub.movie.seasonNumber = seasonNumber
			openSub.movie.episodeNumber = episodeNumber
		else
			openSub.movie.name = openSub.file.cleanName
			openSub.movie.seasonNumber = ""
			openSub.movie.episodeNumber = ""
		end
	end,
	getMovieHash = function()
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
		
		local file = assert(io.open(path, "rb"))
		if not file then
			setError("File not found")
			return false
		end
		
		local i = 1
		local a = {0, 0, 0, 0, 0, 0, 0, 0}
		local hash = ""
		
		local size = file:seek("end")
		file:seek("set", 0)
		local bytes = file:read(65536)
		file:seek("set", size-65536)
		bytes = bytes..file:read("*all")
		file:close ()
		
		for b in string.gfind(string.format("%16X ", size), "..") do
			d = tonumber(b, 16)
			if type(d) ~= "nil" then a[9-i] = d end
			i=i+1
		end

		i = 1
		for b in string.gfind(bytes, ".") do
			a[i] = a[i] + string.byte(b)
			d = math.floor(a[i]/255)
			
			if d>=1 then 
				a[i] = a[i] - d * 256
				if i<8 then a[i+1] = a[i+1] + d end	
			end
			
			i=i+1
			if i==9 then i=1 end
		end

		for i=8, 1, -1 do 
			hash = hash..string.format("%02x",a[i])
		end
		
		openSub.file.bytesize = size
		openSub.file.hash = hash
		
		return true
	end,
	getImdbEpisodeId = function(season, episode)
		openSub.actionLabel = "Searching episode id on IMDB"
		setMessage(openSub.actionLabel..": "..progressBarContent(0))
		local IMDBurl = "http://www.imdb.com/title/tt"..openSub.movie.imdbid.."/episodes/_ajax?season="..season
		
		local host, path = parse_url(IMDBurl)
		
		local stream = vlc.stream(IMDBurl)
		local data = ""
		
		while data do
			data = stream:read(65536)
			local id = string.match(data, 'data%-const="tt(%d+)"[^>]+>\r?\n<img[^>]+>\r?\n<div> S'..season..', Ep'..episode)
			return id
		end
		return false
	end,
	getImdbEpisodeIdYQL = function(season, episode)
		openSub.actionLabel = "Searching episode on IMDB"
		setMessage(openSub.actionLabel..": "..progressBarContent(0))
		
		local url = "http://pipes.yahoo.com/pipes/pipe.run?_id=5f525406f2b2b376eeb20b97a216bcb1&_render=json&imdbid="..openSub.movie.imdbid.."&season="..season.."&episode="..episode
		local host, path = parse_url(url)
		local header = {
			"GET "..path.." HTTP/1.1", 
			"Host: "..host, 
			"User-Agent: "..openSub.conf.userAgentHTTP,
			"",
			""
		}
		local request = table.concat(header, "\r\n")
		local fd = vlc.net.connect_tcp(host, 80)
		local data = ""
		if fd >= 0 then
			local pollfds = {}
			
			pollfds[fd] = vlc.net.POLLIN
			vlc.net.send(fd, request)
			vlc.net.poll(pollfds)
			
			data = vlc.net.recv(fd, 2048)
			print(data)
		end
		
		setMessage(openSub.actionLabel..": "..progressBarContent(100))
		
		local id = string.match(data, '"content":"(%d+)"')
		return id
	end,
	getImdbEpisodeIdGoogle = function(season, episode, title)
		openSub.actionLabel = "Searching episode on IMDB"
		setMessage(openSub.actionLabel..": "..progressBarContent(0))
		
		local query = 'site:imdb.com tv episode "'..title..'" (#'..season..'.'..episode..')'
		local url = "https://www.google.com/uds/GwebSearch?hl=fr&source=gsc&gss=.com&gl=www.google.com&context=1&key=notsupplied&v=1.0&&q="..vlc.strings.encode_uri_component(query)
		local host, path = parse_url(url)
		local header = {
			"GET "..path.." HTTP/1.1", 
			"Host: "..host, 
			"User-Agent: "..openSub.conf.userAgentHTTP,
			"",
			""
		}
		local request = table.concat(header, "\r\n")
		local fd = vlc.net.connect_tcp(host, 80)
		local data = ""
		if fd >= 0 then
			local pollfds = {}
			
			pollfds[fd] = vlc.net.POLLIN
			vlc.net.send(fd, request)
			vlc.net.poll(pollfds)
			
			data = vlc.net.recv(fd, 2048)
			--print(data)
		end
		
		setMessage(openSub.actionLabel..": "..progressBarContent(100))
		
		local id = string.match(data, '"url":"http://www.imdb.com/title/tt(%d+)/"')
		return id
	end,
    loadSubtitles = function(url, fileDir, SubFileName, target)
        openSub.actionLabel = "Downloading subtitle"
       
        setMessage(openSub.actionLabel..": "..progressBarContent(0))
        local resp = get(url)
        local subfileURI = ""
        if resp then
            local tmpFileName = fileDir..SubFileName..".zip"
            local tmpFile = assert(io.open(tmpFileName, "wb"))
            tmpFile:write(resp)
            tmpFile:close()
            
            subfileURI = "zip://"..make_uri(tmpFileName, true).."!/"..SubFileName
            if target then
                local stream = vlc.stream(subfileURI)
                local data = ""
                local subfile = assert(io.open(target, "w")) -- FIXME: check for file presence before overwrite (maybe ask what to do)
               
                while data do
                    if openSub.conf.removeTag then
                        subfile:write(remove_tag(data).."\n")
                    else
                        subfile:write(data.."\n")
                    end
                    data = stream:readline()
                end
                subfile:close()

                stream = nil
            end
            subfileURI = make_uri(target, true)
            collectgarbage() -- force gargabe collection in order to close the opened stream
            os.remove(tmpFileName)
        end
       
        local item = vlc.item or vlc.input.item()
        if item then
            vlc.input.add_subtitle(subfileURI)
        else
            setError("No current input, unable to add subtitles "..target)
        end
    end
}

function make_uri(str, encode)
    local iswindowPath = string.match(str, "^%a:/.+$")
       -- vlc.msg.dbg(iswindowPath)
	if encode then
		local encodedPath = ""
		for w in string.gmatch(str, "/([^/]+)") do
			vlc.msg.dbg(w)
			encodedPath = encodedPath.."/"..vlc.strings.encode_uri_component(w) 
		end
		str = encodedPath
	end
    if iswindowPath then
        return "file:///"..str
    else
        return "file://"..str
    end
end

function downloadHashAndClose()
  searchHash()
  close()
end

function searchHash()
	if not hasAssociatedResult() then
		openSub.sub.languageid = languages[widget.getVal("language")][2]
		
		openSub.getMovieHash()
		associatedResult()
		
		if openSub.file.hash then
			openSub.request("SearchSubtitlesByHash")
			display_subtitles()
		end
	else
		local selection = widget.getVal("hashmainlist")
		if #selection > 0 then 
			download_subtitles(selection)
		end
	end
end

function downloadIMDBAndClose()
  searchIMDB()
  close()
end

function searchIMBD()
	local title = trim(widget.getVal("title"))
	local old_title = trim(widget.get("title").value)
	local season = tonumber(widget.getVal("season"))
	local old_season = tonumber(widget.get("season").value)
	local episode = tonumber(widget.getVal("episode"))
	local old_episode = tonumber(widget.get("episode").value)
	local language = languages[widget.getVal("language")][2]
	local selection = widget.getVal("imdbmainlist")
	local sel = (#selection > 0)
	local newTitle = (title ~= old_title)
	local newEpisode = (season ~= old_season or episode ~= old_episode)
	local newLanguage = (language ~= openSub.sub.languageid)
	local movie = openSub.movie
	local imdbResults = {}
	widget.get("title").value = title
	widget.get("season").value = season
	widget.get("episode").value = episode
	openSub.sub.languageid = language
	
	if newTitle then
		movie.imdbRequest = title
		movie.imdbid = nil
		movie.imdbidShow = nil
		if openSub.request("SearchMoviesOnIMDB") then -- search exact match
			local lowerTitle = string.lower(title)
			local itemTitle = ""
			for i, item in ipairs(openSub.itemStore) do
				-- itemTitle = string.match(item.title, "[%s\"]*([^%(\"]*)[%s\"']*%(?")
				item.cleanTitle = string.match(item.title, "[%s\"]*([^%(\"]*)[%s\"']*%(?")
				-- vlc.msg.dbg(itemTitle)
				
				--[[if string.lower(itemTitle) == lowerTitle then
					movie.imdbid = item.id
					break
				end]]				
				table.insert(imdbResults, item.title)
			end
			if not movie.imdbid then
				widget.setVal("imdbmainlist")
				widget.setVal("imdbmainlist", imdbResults)
			end
		end
	end
	
	if not movie.imdbid and sel then
		local index = selection[1][1]
		local item = openSub.itemStore[index]
		movie.imdbid = item.id
		movie.title = item.cleanTitle
		movie.imdbidShow = movie.imdbid
		newEpisode = true
	end
	
	if movie.imdbid then
		if season and episode and (newTitle or newEpisode) then
			if not newTitle then
				movie.imdbid = movie.imdbidShow
			end
			
			movie.imdbidEpisode = openSub.getImdbEpisodeIdGoogle(season, episode, movie.title)
			-- movie.imdbidEpisode = openSub.getImdbEpisodeId(season, episode)
			
			
			if movie.imdbidEpisode then
				vlc.msg.dbg("Episode imdbid: "..movie.imdbidEpisode)
				movie.imdbidShow = movie.imdbid
				movie.imdbid = movie.imdbidEpisode
			elseif openSub.request("IsTVserie") then
				movie.imdbidEpisode = openSub.getImdbEpisodeIdYQL(season, episode)
				if movie.imdbidEpisode then
					movie.imdbidShow = movie.imdbid
					movie.imdbid = movie.imdbidEpisode
				else
					setError("Season/episode don't match for this title")
				end
			else
				setError("Title not referenced as a TV serie on IMDB")
				--~ -- , choose an other one and/or empty episode/season field")
				widget.setVal("imdbmainlist", imdbResults)
			end
		end
		
		if newTitle or newEpisode or newLanguage then
			openSub.request("SearchSubtitlesByIdIMDB")
			display_subtitles()
		elseif sel and openSub.itemStore then
			download_subtitles(selection)
		end
	end
end

function associatedResult()
	local item = openSub.getInputItem()
	if not item then return false end
	result_state[tmp_method_id] = item:uri()
end

function hasAssociatedResult()
	local item = openSub.getInputItem()
	if not item then return false end
	return (result_state[tmp_method_id] == item:uri())
end
	
function display_subtitles()
	local list = tmp_method_id.."mainlist"
	widget.setVal(list)
	if openSub.itemStore then 
		for i, item in ipairs(openSub.itemStore) do
			widget.setVal(list, item.SubFileName.." ["..item.SubLanguageID.."] ("..item.SubSumCD.." CD)")
		end
	else
		widget.setVal(list, "No result")
	end
end

function download_subtitles(selection)
	local list = tmp_method_id.."mainlist"
	widget.resetSel(list) -- reset selection
	local index = selection[1][1]
	local item = openSub.itemStore[index]
	local subfileTarget = ""
	if openSub.file.dir and openSub.file.name then
		subfileTarget = openSub.file.dir..openSub.file.name.."."..item.SubLanguageID.."."..item.SubFormat
	else
		subfileTarget = os.tmpname() --FIXME: ask the user where to put it instaed
	end
	
	if openSub.conf.justgetlink then
		setMessage("Link: <a href='"..item.ZipDownloadLink.."'>"..item.ZipDownloadLink.."</a>")
	else	
		openSub.loadSubtitles(item.ZipDownloadLink, openSub.file.dir, item.SubFileName, subfileTarget)
	end 
end

widget = {
	stack = {},
    meta = {},
	registered_table = {},
	main_table = {},
	set_node = function(node, parent)
		local left = parent.left
		for k, l in pairs(node) do --parse items
			local tmpTop = parent.height
			local tmpLeft = left
			local ltmpLeft = l.left
			local ltmpTop = l.top
			local tmphidden = l.hidden
			
			l.top = parent.height + parent.top
			l.left = left
			l.parent = parent
			
			if l.display == "none" or parent.hidden then
				l.hidden = true
			else
				l.hidden = false
			end
			
			if l.type == "div" then --that's a container
				l.display = (l.display or "block")
				l.height = 1
				for _, newNode in ipairs(l.content) do --parse lines
					widget.set_node(newNode, l)
					l.height = l.height+1
				end
				l.height = l.height - 1
				left = left - 1
			else --that's an item
				l.display = (l.display or "inline")
				
				if not l.input then
					tmphidden = true
				end
				
				if tmphidden and not l.hidden then --~ create
					widget.create(l)
				elseif not tmphidden and l.hidden then --~ destroy
					widget.destroy(l)
				end
				
				if not l.hidden and (ltmpTop ~= l.top or ltmpLeft ~= l.left) then
					if l.input then --~ destroy
						widget.destroy(l)
					end
					--~ recreate
					widget.create(l)
				end
			end
				
			--~  Store reference ID
			if l.id and not widget.registered_table[l.id] then
				widget.registered_table[l.id] = l
			end
			
			if l.display == "block" then
				parent.height = parent.height + (l.height or 1)
				left = parent.left
			elseif l.display == "none" then
				parent.height = (tmpTop or parent.height)
				left = (tmpLeft or left)
			elseif l.display == "inline" then
				left = left + (l.width or 1)
			end
		end
	end,
	set_interface = function(intf_map)
		local root = {left = 1, top = 0, height = 0, hidden = false}
		widget.set_node(intf_map, root)
	end,
	destroy = function(w)
		dlg:del_widget(w.input)
		--~ w.input = nil
		--~ w.value = nil
		if widget.registered_table[w.id] then
			widget.registered_table[w.id] = nil
		end
	end,
	create = function(w)
		local cur_widget
		if w.type == "button" then
			cur_widget = dlg:add_button(w.value or "", w.callback, w.left, w.top, w.width or 1, w.height or 1)
		elseif w.type == "label" then
			cur_widget = dlg:add_label(w.value or "", w.left, w.top, w.width or 1, w.height or 1)
		elseif w.type == "html" then
			cur_widget = dlg:add_html(w.value or "", w.left, w.top, w.width or 1, w.height or 1)
		elseif w.type == "text_input" then
			cur_widget = dlg:add_text_input(w.value or "", w.left, w.top, w.width or 1, w.height or 1)
		elseif w.type == "password" then
			cur_widget = dlg:add_password(w.value or "", w.left, w.top, w.width or 1, w.height or 1)
		elseif w.type == "check_box" then
			cur_widget = dlg:add_check_box(w.value or "", w.left, w.top, w.width or 1, w.height or 1)
		elseif w.type == "dropdown" then
			cur_widget = dlg:add_dropdown(w.left, w.top, w.width or 1, w.height or 1)
		elseif w.type == "list" then
			cur_widget = dlg:add_list(w.left, w.top, w.width or 1, w.height or 1)
		elseif w.type == "image" then
		
		end
		
		if w.type == "dropdown" or w.type == "list" then
			if type(w.value) == "table" then
				for k, l in ipairs(w.value) do
					if type(l) == "table" then
						cur_widget:add_value(l[1], k)
					else
						cur_widget:add_value(l, k)
					end
				end
			end
		end
		
		if w.type and w.type ~= "div" then
			w.input = cur_widget
		end 
	end,
	get = function(h)
		 return widget.registered_table[h]
	end,
	setVal = function(h, val, index)
		widget.set_val(widget.registered_table[h], val, index)
	end,
	set_val = function(w, val, index)
		local input = w.input
		local t = w.type
		if t == "button" or 
		t == "label" or 
		t == "html" or 
		t == "text_input" or 
		t == "password" then
			if type(val) == "string" then
				input:set_text(val)
				w.value = val
			end
		elseif t == "check_box" then
			if type(val) == "bool" then
				input:set_checked(val)
			else
				input:set_text(val)
			end
		elseif t == "dropdown" or t == "list" then
			if val and index then
				input:add_value(val, index)
				w.value[index] = val
			elseif val and not index then
				if type(val) == "table" then
					for k, l in ipairs(val) do
						input:add_value(l, k)
						table.insert(w.value, l)
					end
				else
					input:add_value(val, #w.value+1)
					table.insert(w.value, val)
				end
			elseif not val and not index then
				input:clear()
				w.value = nil
				w.value = {}
			end
		end
	end,
	getVal = function(h, typeval)
		if not widget.registered_table[h] then print(h) return false end
		return widget.get_val(widget.registered_table[h], typeval)
	end,
	get_val = function(w, typeval)
		local input = w.input
		local t = w.type
					
		if t == "button" or 
		   t == "label" or 
		   t == "html" or 
		   t == "text_input" or 
		   t == "password" then
			return input:get_text()
		elseif t == "check_box" then
			if typeval == "checked" then
				return input:get_checked()
			else
				return input:get_text()
			end
		elseif t == "dropdown" then
			return input:get_value()
		elseif t == "list" then
			local selection = input:get_selection()
			local output = {}
			
			for index, name in  pairs(selection)do
				table.insert(output, {index, name})
			end
			return output
		end
	end,
	resetSel = function(h, typeval)
		local w = widget.registered_table[h]
		local val = w.value
		widget.set_val(w)
		widget.set_val(w, val)
	end
}

function create_dialog()
	dlg = vlc.dialog("VLSub")
	widget.set_interface(interface)
end

function set_interface()
	local method_index = widget.getVal("method")
	local method_id = methods[method_index][2]
	if tmp_method_id then
		if tmp_method_id == method_id then
			return false
		end
		widget.get(tmp_method_id).display = "none"
	else
		openSub.request("LogIn")
	end
	tmp_method_id = method_id
	widget.get(method_id).display = "block"
	widget.set_interface(interface)
	setMessage("")
	
	if method_id == "hash" then
		searchHash()
	elseif method_id == "imdb" then
		if openSub.file.name and not hasAssociatedResult() then
			associatedResult()
			widget.get("title").input:set_text(openSub.movie.name)
			widget.get("season").input:set_text(openSub.movie.seasonNumber)
			widget.get("episode").input:set_text(openSub.movie.episodeNumber)
		end
	end
end

--[[
 Display a progress bar of length progressBarSize. The filled part is calculated
 by progressBarSize * pct / 100 . If a percentage of 100 is given, the word 'Done!'
 is printed after the progress bar.

 Change in style and adding of 'Done!' proposed by mederi, see http://addons.videolan.org/content/show.php?content=148752
--]]
function progressBarContent(pct)
	local content = "<span style='background-color:green;color:#181'>"
	local accomplished = math.ceil(progressBarSize*pct/100)

	local left = progressBarSize - accomplished
	content = content .. string.rep ("-", accomplished)
	content = content .. "</span>"
	content = content .. string.rep ("-", left)

	if pct == 100 then
		content = content .. " Done!"
	end

	return content
end

function setError(str)
	setMessage("<span style='color:#B23'>Error: "..str.."</span>")
end

function setMessage(str)
	if widget.get("message") then
		widget.setVal("message", str)
		dlg:update()
	end
end

function get(url)
	local host, path = parse_url(url)
	local header = {
		"GET "..path.." HTTP/1.1", 
		"Host: "..host, 
		"User-Agent: "..openSub.conf.userAgentHTTP,
		--~ "TE: identity", -- useless, and that's a shame
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
	if fd >= 0 then
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
	return ""
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

function parse_xml(data)
	local tree = {}
	local stack = {}
	local tmp = {}
	local level = 0
	
	table.insert(stack, tree)

	for op, tag, p, empty, val in string.gmatch(data, "<(%/?)([%w:]+)(.-)(%/?)>[%s\r\n\t]*([^<]*)") do
		if op=="/" then
			if level>1 then
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
				--~ print(k)
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

function trim(str)
    if not str then return "" end
    return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

function remove_tag(str)
	return string.gsub(str, "{[^}]+}", "")
end

languages = {
	{'All', 'all'},
	{'Albanian', 'alb'},
	{'Arabic', 'ara'},
	{'Armenian', 'arm'},
	{'Malay', 'may'},
	{'Bosnian', 'bos'},
	{'Bulgarian', 'bul'},
	{'Catalan', 'cat'},
	{'Basque', 'eus'},
	{'Chinese (China)', 'chi'},
	{'Croatian', 'hrv'},
	{'Czech', 'cze'},
	{'Danish', 'dan'},
	{'Dutch', 'dut'},
	{'English (US)', 'eng'},
	{'English (UK)', 'bre'},
	{'Esperanto', 'epo'},
	{'Estonian', 'est'},
	{'Finnish', 'fin'},
	{'French', 'fre'},
	{'Galician', 'glg'},
	{'Georgian', 'geo'},
	{'German', 'ger'},
	{'Greek', 'ell'},
	{'Hebrew', 'heb'},
	{'Hungarian', 'hun'},
	{'Indonesian', 'ind'},
	{'Italian', 'ita'},
	{'Japanese', 'jpn'},
	{'Kazakh', 'kaz'},
	{'Korean', 'kor'},
	{'Latvian', 'lav'},
	{'Lithuanian', 'lit'},
	{'Luxembourgish', 'ltz'},
	{'Macedonian', 'mac'},
	{'Norwegian', 'nor'},
	{'Persian', 'per'},
	{'Polish', 'pol'},
	{'Portuguese (Portugal)', 'por'},
	{'Portuguese (Brazil)', 'pob'},
	{'Romanian', 'rum'},
	{'Russian', 'rus'},
	{'Serbian', 'scc'},
	{'Slovak', 'slo'},
	{'Slovenian', 'slv'},
	{'Spanish (Spain)', 'spa'},
	{'Swedish', 'swe'},
	{'Thai', 'tha'},
	{'Turkish', 'tur'},
	{'Ukrainian', 'ukr'},
	{'Vietnamese', 'vie'}
}

methods = {
	{"Video hash", "hash"},
	{"IMDB ID", "imdb"}
}

interface = {
	{
		id = "header",
		type = "div",
		content = {
			{
				{ type = "label", value = "Search method:" },
				{ 	
					type = "dropdown", 
					value = methods,
					id = "method",
					width = 2
				},
				{ type = "button", value = "Go", callback = set_interface }
			},
			{
				{ type = "label", value = "Language:" },
				{ type = "dropdown", value = languages, id = "language" , width = 2 }
			}
		}
	},
	{
		id = "hash",
		type = "div",
		display = "none",
		content = {
			{
				{ type = "list", width = 4, id = "hashmainlist" }
			},{
				{ type = "span", width = 1},
				{ type = "button", value = "Download and close", callback = downloadHashAndClose },
				{ type = "button", value = "Download", callback = searchHash },
				{ type = "button", value = "Close", callback = close }
			}
		}
	},
	{
		id = "imdb",
		type = "div",
		display = "none",
		content = {
			{
				{ type = "label", value = "Title:"},
				{ type = "text_input", value = openSub.movie.name or "", id = "title" }
			},{
				{ type = "label", value = "Season (series):"},
				{ type = "text_input", value = openSub.movie.seasonNumber or "", id = "season" }
			},{
				{ type = "label", value = "Episode (series):"},
				{ type = "text_input", value = openSub.movie.episodeNumber or "", id = "episode" },
				{ type = "button", value = "Search or download", callback = searchIMBD },
				{ type = "button", value = "Close", callback = close }
			},{
				{ type = "list", width = 4, id = "imdbmainlist" }
			}
		}
	},
	{
		id = "progressBar",
		type = "div",
		content = {
			{
				{ type = "label", width = 4, value = "Powered by <a href='http://www.opensubtitles.org/'>opensubtitles.org</a>", id = "message" }
			}
		}
	}
}

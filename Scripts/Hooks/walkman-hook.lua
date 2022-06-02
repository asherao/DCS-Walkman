local function loadWalkman()
    package.path = package.path .. ";.\\Scripts\\?.lua;.\\Scripts\\UI\\?.lua;"

    local lfs = require("lfs")
    local U = require("me_utilities")
    local Skin = require("Skin")
    local DialogLoader = require("DialogLoader")
    local Tools = require("tools")

    -- Walkman resources
    local window = nil
    local windowDefaultSkin = nil
    local windowSkinHidden = Skin.windowSkinChatMin()
    local panel = nil
    local logFile = io.open(lfs.writedir() .. [[Logs\DCS-Walkman.log]], "w")
    local config = nil

    -- State
    local isHidden = true
    local inMission = false

    -- Song Number State
    local dirPath = lfs.writedir() .. [[DCS-Walkman\]]
	local songIndex = 1 -- the init for which song to play. starts at zero bc the add is before the song play
	local indexModifier
	local isRandomized = false
	
	local buttonHeight = 25 -- 20
	local buttonWidth = 35 -- 40, 55
	
	local columnSpacing = buttonWidth + 5
	
	local rowSpacing = buttonHeight * 0.8
	local row1 = 0
	local row2 = rowSpacing + row1
	
	-- DCS-Walkman TODO
	--[[
	- test in VR
	
	- Functions:
	- When Stop is clicked, stop playing music
	- When FF is clicked play the next indexed song
	- When RW is clicked play last indexed song
	- When play is clicked play indexed song
	- When music button is clicked open music folder (possible?)
	- When loaded, have the program read the Walkman folder
	to see if there are any songs. If so, put that number in
	a variable
	- Test to see that the locations of the buttons make sense
	- Recommend FlicFlac for people to convert their songs https://github.com/DannyBen/FlicFlac
	]]

    local function log(str)
        if not str then
            return
        end

        if logFile then
            logFile:write("[" .. os.date("%H:%M:%S") .. "] " .. str .. "\r\n")
            logFile:flush()
        end
    end
	
	local function dump(o) -- for debug
		if type(o) == 'table' then
			local s = '{ '
			for k,v in pairs(o) do
				if type(k) ~= 'number' then k = '"'..k..'"' end
				s = s .. '['..k..'] = ' .. dump(v) .. ','
			end
			return s .. '} '
		else
			return tostring(o)
		end
	end
	
	local function removeFileExtention(v)
		h = {}
		h[1] = v:match("(.+)%..+$")
		return h[1]
	end
	
	local function GetFileExtension(v)
		return v:match("^.+(%..+)$")
	end

    local function loadConfiguration()
        log("Loading config file...")
		lfs.mkdir(lfs.writedir() .. [[Config\DCS-Walkman\]])
        local tbl = Tools.safeDoFile(lfs.writedir() .. "Config/DCS-Walkman/DCS-WalkmanConfig.lua", false)
        if (tbl and tbl.config) then
            log("Configuration exists...")
            config = tbl.config

            -- move content into text file
            if config.content ~= nil then
                config.content = nil
                saveConfiguration()
            end
        else
            log("Configuration not found, creating defaults...")
            config = {
                hotkey = "Ctrl+Shift+8", -- show/hide
                windowPosition = {x = 200, y = 200},
                windowSize = {w = 220, h = 65},
				hideOnLaunch = false,
				hotkeyStop 		= "Ctrl+Shift+1",
				hotkeyRW 		= "Ctrl+Shift+2",
				hotkeyPlay 		= "Ctrl+Shift+3",
				hotkeyFW 		= "Ctrl+Shift+4",
				hotkeyApp 		= "Ctrl+Shift+5",
				hotkeyVolDown 	= "Ctrl+Shift+6",
				hotkeyVolUp 	= "Ctrl+Shift+7",
            }
            saveConfiguration()
        end
    end

    local function saveConfiguration()
        U.saveInFile(config, "config", lfs.writedir() .. "Config/DCS-Walkman/DCS-WalkmanConfig.lua")
    end

    local function setVisible(b)
        window:setVisible(b)
    end

	-- TODO: try to prevent resizes below a certian size
    local function handleResize(self)
        local w, h = self:getSize()

        panel:setBounds(0, 0, w, h - 20)
		
		-- resize for Walkman
		-- (xpos, ypos, width, height)
		VolSlider:setBounds(0, row2, w, 25)
		local numberOfButtons = 5
		local buttonSpacing = w/numberOfButtons * 0.02
		
		WalkmanStopButton:setBounds(w * (0/numberOfButtons) + buttonSpacing/2, 	
											row1, w/numberOfButtons - buttonSpacing, buttonHeight)
		WalkmanPrevButton:setBounds(w * (1/numberOfButtons) + buttonSpacing, 	
											row1, w/numberOfButtons - buttonSpacing, buttonHeight)
		WalkmanPlayButton:setBounds(w * (2/numberOfButtons) + buttonSpacing, 	
											row1, w/numberOfButtons - buttonSpacing, buttonHeight)
		WalkmanNextButton:setBounds(w * (3/numberOfButtons) + buttonSpacing, 	
											row1, w/numberOfButtons - buttonSpacing, buttonHeight)
		WalkmanFolderButton:setBounds(w * (4/numberOfButtons) + buttonSpacing, 	
											row1, w/numberOfButtons - buttonSpacing, buttonHeight)

        config.windowSize = {w = w, h = h}
        saveConfiguration()
    end

    local function handleMove(self)
        local x, y = self:getPosition()
        config.windowPosition = {x = x, y = y}
        saveConfiguration()
    end

    local function show()
        if window == nil then
            local status, err = pcall(createWalkmanWindow)
            if not status then
                net.log("[DCS-Walkman] Error creating window: " .. tostring(err))
            end
        end

        window:setVisible(true)
        window:setSkin(windowDefaultSkin)
        panel:setVisible(true)
        window:setHasCursor(true)
		window:setText(' ' .. 'DCS-Walkman')

        isHidden = false
    end

    local function hide()
        window:setSkin(windowSkinHidden)
        panel:setVisible(false)
        window:setHasCursor(false)
        -- window.setVisible(false) -- if you make the window invisible, its destroyed
        isHidden = true
    end

	local function playListFromDir(dirPath) -- reloads every time a song is requested
		local list = {}
		for file in lfs.dir(dirPath) do
			local fullPath = dirPath .. '\\' .. file
			if 'file' == lfs.attributes(fullPath).mode then
				if GetFileExtension(file) == '.ogg' or GetFileExtension(file) == '.wav' then
					musicTable = 
					{
						fullPath, -- path of the song to be used to play it
						removeFileExtention(file) -- name of the song to be displayed
					}
					table.insert(list, musicTable)
				end
			end
		end
		return list
	end
	
	-- using this becase it plays one sound in "preview" mode, but 
	-- actually plays the entire sound
	-- it also has a way to stop the music unlike the other method
	local function doSong()
		
		sound.stopPreview()
		
		-- designates the folder that the music will be playing from
		local playList = playListFromDir(lfs.writedir() .. "Config\\DCS-Walkman")
		--net.log(dump(playList)) -- debug
		
		if playList == nil then 
			window:setText('No ogg or wav files detected in ' .. dirPath )  -- write the title of the song/file to the user
			return 
		end
		
		songIndex = songIndex + indexModifier -- go to the next "track", or stay, or previous
		if songIndex > #playList then -- if asking for a number that is bigger than the numbe of tracks...
			songIndex = 1 -- go to the first track
		end
		
		if songIndex < 1 then -- asking for the 0th track, which does not exist in lua
			songIndex = #playList -- go to the first track
		end
		
		if isRandomized then
				songIndex = math.random(1,#playList)
			isRandomized = false
		end
		
		sound.playPreview(playList[songIndex][1]) -- play the song
		window:setText(' ' .. playList[songIndex][2])  -- write the title of the song/file to the user
	end
	
	local function stopSong() 
		sound.stopPreview()
	end
	
	-- sets the volume of the music/effects
	local function setEffectsVolume(volume)
		local gain = volume / 100.0
		enableEffects = 0 < gain
		sound.setEffectsGain(gain)
	end
	
    local function createWalkmanWindow()
        if window ~= nil then
            return
        end
		
        window = DialogLoader.spawnDialogFromFile(
            lfs.writedir() .. "Scripts\\DCS-Walkman\\WalkmanWindow.dlg",
            cdata
        )

        windowDefaultSkin = window:getSkin()
        panel = window.Box
		
		VolSlider = panel.VolSlider
		WalkmanPrevButton = panel.WalkmanPrevButton
		WalkmanStopButton = panel.WalkmanStopButton
		WalkmanPlayButton = panel.WalkmanPlayButton
		WalkmanNextButton = panel.WalkmanNextButton
		WalkmanFolderButton = panel.WalkmanFolderButton

        -- setup window
        window:setBounds(
            config.windowPosition.x,
            config.windowPosition.y,
            config.windowSize.w,
            config.windowSize.h
        )
        handleResize(window)

        window:addHotKeyCallback(
            config.hotkey,
            function()
                if isHidden == true then
                    show()
                else
                    hide()
                end
            end
        )
        window:addSizeCallback(handleResize)
        window:addPositionCallback(handleMove)

        window:setVisible(true)
		
		-- setup Walkman
		
		WalkmanStopButton:addMouseDownCallback(
            function(self)
                stopSong()
            end
        )
		WalkmanPrevButton:addMouseDownCallback(
            function(self)
				indexModifier = -1
                doSong()
            end
        )
		WalkmanPlayButton:addMouseDownCallback(
            function(self)
				indexModifier = 0
                doSong()
            end
        )
		WalkmanNextButton:addMouseDownCallback(
            function(self)
				indexModifier = 1
                doSong()
            end
        )
		WalkmanFolderButton:addMouseDownCallback(
            function(self)
				indexModifier = 0
				isRandomized = true
                doSong()
            end
        )
		--[[
		WalkmanFolderButton:addMouseDoubleDownCallback(
            function(self)
                folderActionDouble()
            end
        )
		]]
		VolSlider:addChangeCallback(
            function(self)
                setEffectsVolume(VolSlider:getValue())
            end
        )
		
		window:addHotKeyCallback(
            config.hotkeyVolUp,
            function()
                local newVolume = VolSlider:getValue() + 10
				if newVolume > 100 then newVolume = 100 end
				VolSlider:setValue(newVolume)
                setEffectsVolume(newVolume)
            end
        )
		
		window:addHotKeyCallback(
            config.hotkeyVolDown,
            function()
                local newVolume = VolSlider:getValue() - 10
				if newVolume < 0 then newVolume = 0 end
				VolSlider:setValue(newVolume)
                setEffectsVolume(newVolume)
            end
        )
		
		-- walkman hotkeys
		
		window:addHotKeyCallback(
            config.hotkeyApp,
            function()
                indexModifier = 0
				isRandomized = true
                doSong()
            end
        )
		
		window:addHotKeyCallback(
            config.hotkeyFW,
            function()
                indexModifier = 1
                doSong()
            end
        )
		window:addHotKeyCallback(
            config.hotkeyPlay,
            function()
                indexModifier = 0
                doSong()
            end
        )
		window:addHotKeyCallback(
            config.hotkeyRW,
            function()
                indexModifier = -1
                doSong()
            end
        )
		window:addHotKeyCallback(
            config.hotkeyStop,
            function()
                stopSong()
            end
        )
		
		-- finish config
		if config.hideOnLaunch then 
			hide() 
			isHidden = true 
		end
		
		lfs.mkdir(lfs.writedir() .. [[Config\DCS-Walkman\]])
		
        log("DCS-Walkman window created")
    end

    local handler = {}
    function handler.onSimulationFrame()
        if config == nil then
            loadConfiguration()
        end

        if not window then
            log("Creating DCS-Walkman window...")
            createWalkmanWindow()
			-- Read the number if songs in the folder
			-- If there are 0 songs, then let the player know how to add songs
			-- If there are songs, display how many songs there are
			local playList = playListFromDir(lfs.writedir() .. "Config\\DCS-Walkman")
			if playList ~= nil and #playList ~= 0 then
				window:setText(' ' .. 'DCS-Walkman - ' .. #playList .. ' song(s) detected')
			else
				window:setText(' ' .. 'DCS-Walkman - '.. 'Add ogg/wav songs in Saved Games/DCS/Config/DCS-Walkman')
				window:setBounds(
					config.windowPosition.x,
					config.windowPosition.y,
					488, -- length of the setText
					config.windowSize.h
				)
			end
        end
    end
	
    function handler.onMissionLoadEnd()
        inMission = true
		--reload the title after a mission load
		if playList[songIndex][2] ~= nil then
			window:setText(' ' .. playList[songIndex][2])
		else
			window:setText(' ' .. 'DCS-Walkman')
		end
    end
	
    function handler.onSimulationStop()
        inMission = false
        --hide()
		
		if playList[songIndex][2] ~= nil then
			window:setText(' ' .. playList[songIndex][2])
		else
			window:setText(' ' .. 'DCS-Walkman')
		end
    end
	
    DCS.setUserCallbacks(handler)

    net.log("[DCS-Walkman] Loaded ...")
end

local status, err = pcall(loadWalkman)
if not status then
    net.log("[DCS-Walkman] Load Error: " .. tostring(err))
end

--capy64 init
--TODO: implement all basic CC functions BM-OS
package.path = "./?.lua;./?/init.lua;/lib/?.lua;/lib/?/init.lua"
local function shallowCopyRequire(name)
	local a = {}
	local b = require(name)
	for i,v in pairs(b) do
		a[i] = v
	end
	return a
end
local machine = shallowCopyRequire("machine")
local event = shallowCopyRequire("event")
local machine = shallowCopyRequire("machine")
local timer = shallowCopyRequire("timer")
local http = shallowCopyRequire("http")
local json = shallowCopyRequire("json")
local libFolder = "/lib"

local blank = function(...) return end
local fakeGlobals = {}

--OS
local fakeOs = {}
fakeOs.run = function(env,file)
	local newEnv = {}
	for i,v in pairs(_G) do
		newEnv[i] = v
	end
	for i,v in pairs(env) do
		newEnv[i] = v
	end
	local a = assert(loadfile(file,"bt",newEnv))

	return a()
end
fakeOs.pullEvent = event.pull
fakeOs.pullEventRaw = event.pullRaw
fakeOs.reboot = machine.reboot
fakeOs.shutdown = machine.shutdown
fakeOs.sleep = function(sec)
	if not sec then
		sec = 1/20
	end
	local sleepTimer = timer.start(sec*1000)
	repeat
		local _, id = event.pull("timer")
	until id == sleepTimer
end
fakeGlobals.os = fakeOs

--MATH
local fakeMath = {}
fakeMath.pow = function(a,b)
	return a^b
end
fakeGlobals.math = fakeMath

--COLORS
local defaultColors = {}
defaultColors[fakeMath.pow(2,0)] = 0xF0F0F0
defaultColors[fakeMath.pow(2,1)] = 0xF2B233
defaultColors[fakeMath.pow(2,2)] = 0xE57FD8
defaultColors[fakeMath.pow(2,3)] = 0x99B2F2
defaultColors[fakeMath.pow(2,4)] = 0xDEDE6C
defaultColors[fakeMath.pow(2,5)] = 0x7FCC19
defaultColors[fakeMath.pow(2,6)] = 0xF2B2CC
defaultColors[fakeMath.pow(2,7)] = 0x4C4C4C
defaultColors[fakeMath.pow(2,8)] = 0x999999
defaultColors[fakeMath.pow(2,9)] = 0x4C99B2
defaultColors[fakeMath.pow(2,10)] = 0xB266E5
defaultColors[fakeMath.pow(2,11)] = 0x3366CC
defaultColors[fakeMath.pow(2,12)] = 0x7F664C
defaultColors[fakeMath.pow(2,13)] = 0x57A64E
defaultColors[fakeMath.pow(2,14)] = 0xCC4C4C
defaultColors[fakeMath.pow(2,15)] = 0x111111

local colorNames = {}
colorNames.white = 1
colorNames.orange = 2 
colorNames.magenta = 4 
colorNames.lightBlue = 8
colorNames.yellow = 16
colorNames.lime = 32
colorNames.pink = 64
colorNames.gray = 128
colorNames.lightGray = 256
colorNames.cyan = 512
colorNames.purple = 1024
colorNames.blue = 2048
colorNames.brown = 4096
colorNames.green = 8192
colorNames.red = 16384
colorNames.black = 32768
local blitNames = {}
blitNames["0"] = 1
blitNames["1"] = 2 
blitNames["2"] = 4 
blitNames["3"] = 8
blitNames["4"] = 16
blitNames["5"] = 32
blitNames["6"] = 64
blitNames["7"] = 128
blitNames["8"] = 256
blitNames["9"] = 512
blitNames.a = 1024
blitNames.b = 2048
blitNames.c = 4096
blitNames.d = 8192
blitNames.e = 16384
blitNames.f = 32768
local colorTable = {}
for i,v in pairs(defaultColors) do
	colorTable[i] = v
end
local colorMeta = {}
colorMeta.__index = function(_,color)
	if colorNames[color] then
		return colorTable[colorNames[color]]
	elseif toBlit then
		for i,v in pairs(blitNames) do
			if v == color then
				return i
			end
		end
	elseif fromBlit then
		return blitNames(tostring(color))
	else
		return colorTable[color]
	end
end
local fakeColors = setmetatable({},colorMeta)
fakeGlobals.colors = fakeColors
fakeGlobals.colours = fakeColors
--TERM
local function blitTransform(ccBlit)
	local newBlit = {}
	for i in string.gmatch(ccBlit, "%U") do
		table.insert(newBlit, blitNames[i])
	end
	return newBlit
end
local fakeTerm = shallowCopyRequire("term")
local sizeX,sizeY = fakeTerm.getSize()
local oldBlit = fakeTerm.blit
fakeTerm.native = function()
    return fakeTerm
end -- according to the CC code (and documentation) this is what term.native does when not multitasking, we dont really care about cc multitasking
fakeTerm.redirect = function(new)
	if not new then
		error("New terminal shallowCopyRequired!",0)
	end
	local oldTerm = fakeTerm
	fakeTerm = new
	return oldTerm
end
fakeTerm.setBackgroundColor = fakeTerm.setBackground 
fakeTerm.setBackgroundColour = fakeTerm.setBackground 
fakeTerm.getBackgroundColor = fakeTerm.getBackground
fakeTerm.setTextColor = fakeTerm.setForeground
fakeTerm.setTextColour = fakeTerm.setForeground
fakeTerm.getTextColor = fakeTerm.getForeground
fakeTerm.getTextColour = fakeTerm.getForeground
fakeTerm.setCursorBlink = fakeTerm.setBlink
fakeTerm.getCursorBlink = fakeTerm.getBlink
fakeTerm.setCursorPos = fakeTerm.setPos
fakeTerm.getCursorPos = fakeTerm.getPos
fakeTerm.isColor = function() return true end
fakeTerm.isColour = fakeTerm.isColor
fakeTerm.nativePaletteColor = function(color)
	return defaultColors[color]
end
fakeTerm.setPaletteColor = function(color,color1)
	colorTable[color] = color1
end
fakeTerm.blit = function(txt,fore,back)
	local currentColor = term.getForeground()
	local currentColor1 = term.getBackground()
	oldBlit(txt,blitTransform(fore),blitTransform(back))
	term.setForeground(currentColor)
	term.setBackground(currentColor1)
end
fakeGlobals.term = fakeTerm

--WINDOW
local fakeWindow = {}
fakeWindow.create = function(...) return fakeTerm end
fakeGlobals.window = fakeWindow

--FILESYSTEM
local readModes = {
	["r"] = true,
	["rb"] = true
}
local writeModes = {
	["w"] = true,
	["wb"] = true,
	["a"] = true,
	["ab"] = true
}
local makeReadHandle = function(a)
	return {
		readAll = function(...) return a:read("a") end,
		readLine = function(...) return a:read("l") end,
		read = function(...) return a:read(...) end,
		close = function(...) return a:close(...) end,
	}
end
local makeWriteHandle = function(a)
	return {
		write = function(str) 
			--[[local lines = {}
			local chars = {}
			for i in string.gmatch(str, ".") do
				table.insert(chars, i)
			end
			currentLine = 1
			for i,v in pairs(chars) do
				if v == "\n" then
					currentLine = currentLine + 1
				end
				if v ~= "\n" then
					if not lines[currentLine] then
						lines[currentLine] = ""
					end
					lines[currentLine] = lines[currentLine]..v
				end
			end
			for i,v in pairs(lines) do
				a:writeLine(v)
			end
			return]]
			return a:write(str) 
		end,
		writeLine = function(...) return a:writeLine(...) end,
		flush = function(...) return a:flush(...) end,
		close = function(...) return a:close(...) end,
	}
end
local fakeFs = shallowCopyRequire("fs")
local oldOpen = fakeFs.open
fakeFs.open = function(file,mode)
	if not readModes[mode] and not writeModes[mode] then
		error("invalid mode!",0)
	else
		local success, response = pcall(function()
			local a = oldOpen(file,mode)
			if readModes[mode] then
				return makeReadHandle(a)
			elseif writeModes[mode] then
				return makeWriteHandle(a)
			else
				error("wtf")
			end
		end)
		if not success then
			compat.log(file)
			error(response)
		else
			return response
		end
		
	end
end
fakeFs.find = function(...) return {} end
fakeGlobals.fs = fakeFs

--SETTINGS
local values = {}
local fakeSettings = {}
fakeSettings.get = function(name)
	return values[name]
end
fakeSettings.set = function(name,val)
	values[name] = val
end
fakeSettings.save = function(file)
	local success = pcall(function()
		if not file then
			file = "/.settings"
		end
		local a = fs.open(file,"w")
		a.write(json.encode(values))
		a.close()
	end)

	return success
end
fakeSettings.define = function(value,tab)
	if not values[value] then
		values[value] = tab.default
	end
end
fakeSettings.load = function(file)
	local success = pcall(function()
		if not file then
			file = "/.settings"
		end
		local a = fs.open(file,"r")
		local b = json.decode(a.readAll())
		a.close()
		for i,v in pairs(b) do
			values[i] = v
		end
	end)
	
	return success
end
fakeGlobals.settings = fakeSettings

--HTTP
local fakeHttp = {}
fakeHttp.get = function(url,headers,options)
	if type(url) == "table" then
		local tab = url
		url = tab.url
		if not options then
			options = {}
		end
		if tab.binary then
			options.binary = true
		end
	elseif not url or type(url) ~= "string" then
		error("Invalid URL!",0)
	end
	local c<close> = http.requestAsync(url,nil,headers,options)
	local a,b = c:await()
	for i,v in pairs(a) do
		compat.log(i,v)
	end
	if not a then
		return nil,b
	else
		return makeReadHandle(a.content)
	end
end
fakeHttp.checkURL = http.checkURL
fakeGlobals.http = fakeHttp

--TEXTUTILS
local fakeTextUtils = {}
fakeTextUtils.serializeJSON = json.encode
fakeTextUtils.serialiseJSON = json.encode
fakeTextUtils.unserializeJSON = json.decode
fakeTextUtils.unserialiseJSON = json.decode
fakeGlobals.textutils = fakeTextUtils

--BIT32
local fakeBit32 = shallowCopyRequire("lib.bit").bit32
fakeGlobals.bit32 = fakeBit32
--IO
local fakeIo = shallowCopyRequire("fs")
fakeGlobals.io = fakeIo
--GLOBALS
local oldPrint = print
local writeLine = function(line)
	local x,y = term.getPos()
	term.write(line)
	if y+1 > sizeY then
		term.scroll(1)
		term.setPos(1,sizeY)
	else
		term.setPos(1,y+1)
	end
end
fakeGlobals.print = function(str)
	oldPrint(str)
	local chars = {}
	local lines = {}
	str = tostring(str)
	if str == nil then
		str = "nil"
	end
	for i in string.gmatch(str, ".") do
		table.insert(chars, i)
	end
	local x,y = term.getPos()
	local currentLine = 1
	local currentCharacter = x
	for i,v in pairs(chars) do
		if currentCharacter > sizeX or v == "\n" then
			currentLine = currentLine + 1
			currentCharacter = 1
		end
		if v ~= "\n" then
			if not lines[currentLine] then
				lines[currentLine] = ""
			end
			lines[currentLine] = lines[currentLine]..v
			currentCharacter = currentCharacter + 1
		end
	end
	for i,v in pairs(lines) do
		writeLine(v)
	end	

end
fakeGlobals.sleep = fakeOs.sleep 
fakeGlobals.loadstring = load
fakeGlobals.read = function(hideChar)
	local continue = true
	local str = ""
	local x,y = term.getPos()
	while continue do
		local a,b,c = event.pull("char","key_down")
		if a == "char" then
			term.write(b)
			str = str..b
			x = x + 1
		else
			if c == "enter" then
				continue = false
			elseif c == "back" then
				if str ~= "" then
					str = str:sub(1, -2)
					x = x - 1
					term.setPos(x,y)
					term.write(" ")
					term.setPos(x,y)
				end
			end
		end
	end
	
	if y+1 > sizeY then
		term.scroll(1)
		term.setPos(1,sizeY)
	else
		term.setPos(1,y+1)
	end
	return str
end
fakeGlobals.expect = function(...) return end
fakeGlobals.field = function(...) return end
fakeGlobals.wrap = function(str)
	local chars = {}
	local lines = {}
	for i in string.gmatch(str, ".") do
		table.insert(chars, i)
	end
	local x,y = term.getPos()
	local currentLine = 1
	local currentCharacter = x
	for i,v in pairs(chars) do
		if currentCharacter > sizeX or v == "\n" then
			currentLine = currentLine + 1
			currentCharacter = 1
		end
		if v ~= "\n" then
			if not lines[currentLine] then
				lines[currentLine] = ""
			end
			lines[currentLine] = lines[currentLine]..v
			currentCharacter = currentCharacter + 1
		end
	end
	local returnString = ""
	for i,v in pairs(lines) do
		if i == 1 then
			returnString=v
		else
			returnString=returnString.."\n"..v
		end
	end	
	return returnString
end
local oldDoFile = dofile
local badFiles = {
	["/rom/modules/main/cc/shallowCopyRequire.lua"] = true,
	["/rom/modules/main/cc/shallowCopyRequire.lua"] = true
}
fakeGlobals.dofile = function(file)
	if badFiles[file] then
		local fake = {}
		fake.make = function(...)
			return shallowCopyRequire, package
		end
		fake.expect = function(...) return end
		fake.field = function(...) return end
		return fake
	else
		return oldDoFile(file)
	end
end

fakeGlobals.printError = fakeGlobals.print
--CONFIG
for i,v in pairs(fakeGlobals) do
	if _G[i] and type(v) == "table" then
		for i1,v in pairs(v) do
			_G[i][i1] = v
		end
	else
		_G[i] = v
	end
end

settings.load()
machine.title("BM-OS")
machine.setRPC("BM-OS", "")
os.run({},"/boot/loader.lua")

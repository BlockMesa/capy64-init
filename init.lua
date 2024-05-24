--capy64 BM-BIOS wrapper
--TODO: implement all basic CC functions BM-BIOS uses
local blank = function(...) return end


--OS
_G.os.run = function(env,file)
	local newEnv = {}
	for i,v in pairs(_G) do
		newEnv[i] = v
	end
		for i,v in pairs(env) do
		newEnv[i] = v
	end
	return loadfile(file,"bt",newEnv)()
end
_G.os.pullEvent = blank
_G.os.pullEventRaw = blank

--SETTINGS
_G.settings = {}
_G.settings.get = blank
_G.settings.set = blank


os.run(_ENV,".BIOS")
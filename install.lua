local json = require("json")
local machine = require("machine")
local makeJson = json.encode
local makeTable = json.decode
local http = require("http")
local fs = require("fs")
local term = require("term")

local a = http.get('https://windclan.neocities.org/blockmesa/meta.json')
local json = a.content:read("a"):gsub("%G","")
local c = makeTable(json)
local b = c.packages.base

print("Installing BM-OS")


pcall(fs.delete,"home",true)
pcall(fs.makeDir,"/home")
pcall(fs.makeDir,"/boot")
pcall(fs.makeDir,"/bin")
pcall(fs.makeDir,"/sbin")
pcall(fs.makeDir,"/etc")
pcall(fs.makeDir,"/usr")
pcall(fs.makeDir,"/lib")
pcall(fs.makeDir,"/usr/bin")
pcall(fs.makeDir,"/usr/lib")
pcall(fs.makeDir,"/usr/bin")
pcall(fs.makeDir,"/usr/etc")

local meta = {
    updated = "",
    installed = {
        base = {
            packageId = "base",
            version = b.version,
			requires = b.requires
        },
    },
	conflicts = {},
	provided = {}
}

local function installFile(file,url)
    local result, reason = http.get(url,nil,{binary = true}) --make names better
    if not result then
        print(("Failed to update %s from %s (%s)"):format(file, url, reason)) --include more detail
        return
    end
    a1 = fs.open(file,"wb")
    a1:write(result.content:read("a"))
    a1:close()
end
local function install(v)
	print("Installing package "..v)
	local files = {}
	for i,v1 in pairs(c.packages[v].files) do
		local url = v1
		local file = ""
		if type(i) == "string" then
			file = i
		else
			file = v1
		end
		table.insert(files,file)
		installFile(file,c.packages[v].assetBase..url)
	end
	meta.installed[v] = {
        packageId = v,
        version = c.packages[v].version,
		requires = c.packages[v].requires,
		files = files
    }
	meta.conflicts[v] = c.packages[v].conflicts or {}
	meta.provided[v] = {v}
	if c.packages[v].provides then
		for _,v1 in pairs(c.packages[v].provides) do
			table.insert(provided[v],v1)
		end
	end
end
for i,v in pairs(b.requires) do
	install(v)
end
--install("capy64-init")

pcall(fs.makeDir,"/etc/packages.d")
local file = fs.open("/etc/packages.d/packages.json","w")
file:write(makeJson(meta))
file:close()

local file = fs.open("/etc/hostname", "w")
print("Please enter a hostname")
term.write("hostname: ")
local a = io.read()
if not a or a == "" then
	a = "computer"
end
file:write(a)
file:close()

print("Installation complete!")
fs.delete("sys",true)
machine.reboot()

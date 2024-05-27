local json = require("json")
local machine = require("machine")
local makeJson = json.encode
local makeTable = json.decode
local http = require("http")
local fs = require("fs")
local term = require("term")
local a = http.get('https://notbronwyn.neocities.org/blockmesa/meta.json')
local c = json.decode(a.content:read("a"))
local b = c.packages.base
local b1 = c.packages.kernel
local b2 = c.packages.bootloader
local b3 = c.packages.shell
local b4 = c.packages.package
local baseUrl = b.assetBase
local baseUrl1 = b1.assetBase
local baseUrl2 = b2.assetBase
local baseUrl3 = b3.assetBase
local baseUrl4 = b4.assetBase
print("BM-OS WILL NOW BE INSTALLED.")
fs.makeDir("/bin")
fs.makeDir("/sbin")
fs.makeDir("/etc")
fs.makeDir("/usr")
fs.makeDir("/lib")
fs.makeDir("/usr/bin")
fs.makeDir("/usr/lib")
fs.makeDir("/usr/etc")
fs.makeDir("/etc/packages.d")
local file = fs.open("/etc/packages.d/packages.json","w")
file:write(makeJson({
    updated = "",
    installed = {
        bios = {
            packageId = "bios",
            version = c.packages.bios.version,
        },
        base = {
            packageId = "base",
            version = b.version,
        },
        kernel = {
            packageId = "kernel",
            version = b1.version,
        },
        bootloader = {
            packageId = "bootloader",
            version = b2.version,
        },
        shell = {
            packageId = "shell",
            version = b3.version,
        },
        package = {
            packageId = "package",
            version = b4.version,
        }
		["bios-wrapper"] = {
            packageId = "bios-wrapper",
            version = c.packages["bios-wrapper"].version,
        }
    }
}))
file:close()

local function installFile(url,file)
    local result, reason = http.get(url, nil, {binary = true}) --make names better
    if not result then
        print(("Failed to update %s from %s (%s)"):format(file, url, reason)) --include more detail
        return
    end
    a1 = fs.open(file,"wb")
    a1:write(result.content:read("a"))
    a1:close()
end
print("Installing kernel")
for i,v in pairs(b1.files) do
    installFile(baseUrl1..v,v)
end
print("Installing bootloader")
for i,v in pairs(b2.files) do
    installFile(baseUrl2..v,v)
end
print("Installing shell")
for i,v in pairs(b3.files) do
    installFile(baseUrl3..v,v)
end
print("Installing package manager")
for i,v in pairs(b4.files) do
    installFile(baseUrl4..v,v)
end
print("Installing base commands")
for i,v in pairs(b.files) do
    installFile(baseUrl..v,v)
end
installFile(c.packages.bios.assetBase..".BIOS",".BIOS")
installFile(c.packages["bios-wrapper"].assetBase.."init.lua","init.lua")
fs.delete("sys",true)
print("Installation complete!")
machine.reboot()
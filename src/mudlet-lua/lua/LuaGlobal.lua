-- Mudlet Lua packages loader

if package.loaded["rex_pcre"] then
  rex = require "rex_pcre"
end
if package.loaded["lpeg"] then
  lpeg = require "lpeg"
end
if package.loaded["zip"] then
  zip = require "zip"
end
if package.loaded["lfs"] then
  lfs = require "lfs"
end

print("==== Lua module loader debug ====")
print("Lua version:", _VERSION)
print("package.path = ", package.path)
print("package.cpath = ", package.cpath)
print("----------------------------------")

local modules = {
    "lfs", "rex_pcre", "lpeg", "zip",
    "yajl", "luasql.sqlite3", "lua-utf8", "utf8"
}

local missing = {}
local broken = {}
local loaded_paths = {}

-- Hook pour savoir quel fichier est utilisé
local original_require = require
require = function(mod)
    local result, path
    for _, searcher in ipairs(package.loaders or package.searchers) do
        local loader, found_path = searcher(mod)
        if type(loader) == "function" then
            path = found_path
            break
        end
    end
    local ok, lib = pcall(original_require, mod)
    if ok then
        loaded_paths[mod] = path or "(Lua builtin or C-preloaded)"
        return lib
    else
    -- error(lib)  -- on commente pour ne pas arrêter le script
    print("[WARN] module '" .. mod .. "' could not be loaded: " .. tostring(lib))
    return nil  -- retourne nil pour que le programme continue
    end
end

for _, mod in ipairs(modules) do
    local ok, lib = pcall(require, mod)
    if not ok then
        table.insert(missing, mod)
    else
        local test_ok, test_err = pcall(function()
            if mod == "lfs" then lib.currentdir() end
            if mod == "rex_pcre" then lib.match("abc","a") end
            if mod == "lpeg" then lib.P("a") end
            if mod == "zip" then local _ = lib.open end
            if mod == "yajl" then local _ = lib.encode end
            if mod == "luasql.sqlite3" then local env = lib.sqlite3() end
            if mod == "lua-utf8" or mod == "utf8" then local _ = lib.len or require("utf8") end
        end)
        if not test_ok then
            table.insert(broken, mod .. " (loaded but unusable)")
        end
    end
end

print("\n==== Module summary ====")
for mod, path in pairs(loaded_paths) do
    print(string.format("[OK] %s → %s", mod, path))
end
for _, mod in ipairs(broken) do
    print("[BROKEN] " .. mod)
end
for _, mod in ipairs(missing) do
    print("[MISSING] " .. mod)
end
print("=================================")

print("==== Checking preloaded (embedded) Lua modules ====")

local found = false
for name, loader in pairs(package.preload) do
    print("[PRELOADED] " .. name)
    found = true
end

if not found then
    print("(none found — no modules embedded in package.preload)")
end

print("===================================================")

local module_name = "lpeg"  -- ou "rex_pcre", "zip", etc.

if package.preload[module_name] then
  print(module_name .. " is preloaded in the executable (package.preload)")
else
  print(module_name .. " is NOT preloaded, checking cpath...")

  -- On essaye de le charger sans l'exécuter
  for _, searcher in ipairs(package.loaders or package.searchers) do
    local loader, path = searcher(module_name)
    if type(loader) == "function" then
      print(module_name .. " found at path:", path or "(C built-in)")
      break
    end
  end
end

print("== Test recherche lpeg ==")
print("Lua version:", _VERSION)
print("package.path:", package.path)
print("package.cpath:", package.cpath)
print("----------------------------------")

-- test manuel des chemins .so
local name = "lpeg"
for path in string.gmatch(package.cpath, "[^;]+") do
  local candidate = path:gsub("?", name)
  local f = io.open(candidate, "rb")
  if f then
    print("[FOUND FILE] " .. candidate)
    f:close()
  else
    print("[missing] " .. candidate)
  end
end

print("----------------------------------")
local ok, mod = pcall(require, "lpeg")
print("require('lpeg') =", ok, mod)
print("----------------------------------")



local ok, mod = pcall(require, "utf8")
if ok then
    print("utf8 type:", type(mod))
    for k,v in pairs(mod) do
        print("  ", k, v)
    end
end


























-- TODO this is required by DB.lua, so we might load it all at one place
--if package.loaded["luasql.sqlite3"] then require "luasql.sqlite3" end

json_to_value = yajl.to_value
gmcp = {}
mssp = {}

function __gmcp_merge_gmcp_sub_tables( a, key )
  local _m = a.__needMerge;
  for k, v in pairs(_m) do
    a[key][k] = v;
  end
  a.__needMerge = nil
end


function unzip( what, dest )
  -- cecho("\n<blue>unpacking package:<"..what.."< to <"..dest..">\n")
  local z, err = zip.open( what )

  if not z then
    cecho("\nerror unpacking: " .. err)
    return
  end

  local createdDirs = {}
  for file in z:files() do
    local _f, err = z:open( file.filename )
    local _data = _f:read("*a")
    local _path = dest .. file.filename
    local _dir = string.split( file.filename, '/' )
    local created = dest;
    for k, v in ipairs( _dir ) do
      if k < #_dir then
        created = created .. '/' .. v;
        if not table.contains( createdDirs, created ) then
          table.insert( createdDirs, created );
          lfs.mkdir( created );
          -- cecho("<red>--> creating dir:" .. created .. "\n");
        end
      elseif file.uncompressed_size == 0 then
        if not table.contains( createdDirs, created ) then
          -- cecho("<red>--> creating dir:" .. file.filename .. "\n")
          table.insert( createdDirs, created );
          lfs.mkdir( file.filename )
        end
      end
    end
    local _path = dest .. file.filename
    if file.uncompressed_size > 0 then
      local out = io.open( _path, "wb" )
      if out then
        -- cecho("<green>unpacking file:".._path.."\n")
        out:write( _data )
        out:close()
      else
        cecho("<red>ERROR: can't write file:" .. _path .. "\n")
      end
    end
    _f:close();
  end
  z:close()
end



function onConnect()
end

function handleWindowResizeEvent()
end

local packages = {
  "StringUtils.lua",
  "TableUtils.lua",
  -- "Logging.lua", -- never documented and fails to load now
  "DebugTools.lua",
  "DateTime.lua",
  "DB.lua",
  "geyser/Geyser.lua",
  "geyser/GeyserGeyser.lua",
  "geyser/GeyserUtil.lua",
  "geyser/GeyserColor.lua",
  "geyser/GeyserSetConstraints.lua",
  "geyser/GeyserStyleSheet.lua",
  "geyser/GeyserContainer.lua",
  "geyser/GeyserWindow.lua",
  "geyser/GeyserLabel.lua",
  "geyser/GeyserGauge.lua",
  "geyser/GeyserMiniConsole.lua",
  "geyser/GeyserMapper.lua",
  "geyser/GeyserReposition.lua",
  "geyser/GeyserScrollBox.lua",
  "geyser/GeyserHBox.lua",
  "geyser/GeyserVBox.lua",
  "geyser/GeyserUserWindow.lua",
  "geyser/GeyserAdjustableContainer.lua",
  "geyser/GeyserCommandLine.lua",
  "geyser/GeyserButton.lua",

  -- TODO probably don't need to load this file
  "geyser/GeyserTests.lua",
  "GUIUtils.lua",
  "Other.lua",
  "GMCP.lua",
  "KeyCodes.lua",
  "CursorShapes.lua",
  "TTSValues.lua",
  "IDManager.lua",
}

-- Set to true (possibly via code in the C++ TLuaInterpreter::loadGlobal()
-- method) to report on the determination of what path to use to load the other
-- Mudlet and Geyser provided Lua files...
debugLoading = debugLoading or false
local sep = package.config:sub(1,1)

if debugLoading then
  echo("Path separator is: '" .. sep .. "'\n\n")

  -- Set via code in C++ TLuaInterpreter::loadGlobal() but fall back to current
  -- directory if nil.
  if luaGlobalPath == nil then
    luaGlobalPath = lfs.currentdir()
    echo("luaGlobalPath was nil so has been defaulted to: \"" .. luaGlobalPath .. "\".\n\n")
  else
    echo("luaGlobalPath has been preset to: \"" .. luaGlobalPath .. "\".\n\n")
  end
  nativeLuaGlobalPath = toNativeSeparators(luaGlobalPath)
  echo("Directory separator conversion gives: \"" .. nativeLuaGlobalPath .. "\".\n\n")
  echo("Current directory is: \"" .. lfs.currentdir() .. "\".\n\n")

  local packagePath, status, result = "", false, ""
  for _, packageName in ipairs(packages) do
    packagePath = nativeLuaGlobalPath .. sep .. toNativeSeparators(packageName)
    echo("Trying to load: \"" .. packagePath .. "\"\n")
    status, result = pcall(dofile, packagePath)
    if (status == false) then
        error("Error attempting to load package("..packageName..") file:\n  " .. result .. ".\n\n")
    end
    echo("Loaded: \"" .. packageName .. "\".\n\n")
  end
else
  -- Set via code in C++ TLuaInterpreter::loadGlobal() but fall back to current
  -- directory if nil.
  luaGlobalPath = luaGlobalPath or lfs.currentdir()
  nativeLuaGlobalPath = toNativeSeparators(luaGlobalPath)

  local packagePath = ""
  for _, packageName in ipairs(packages) do
    packagePath = nativeLuaGlobalPath .. sep .. toNativeSeparators(packageName)
    dofile(packagePath)
  end
end

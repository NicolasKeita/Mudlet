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

local modules = {"lfs", "rex_pcre", "lpeg", "zip", "yajl", "luasql.sqlite3", "lua-utf8", "utf8"}
local missing = {}
local broken = {}

for _, mod in ipairs(modules) do
    local ok, lib = pcall(require, mod)
    if not ok then
        table.insert(missing, mod)
    else
        -- Test rapide d'une fonction minimale
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

if #missing > 0 or #broken > 0 then
    print("Lua modules issues:")
    for _, mod in ipairs(missing) do print("  - Missing: " .. mod) end
    for _, mod in ipairs(broken) do print("  - Broken: " .. mod) end
    os.exit(1)
end

print("All modules loaded and usable!")

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

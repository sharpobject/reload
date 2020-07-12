local replace = require"replace"

local reload_modules = {}
local reload_types = {table=true, ["function"]=true}
local reloading = false

local function reload(name)
  --print(name, type(name))
  if name:find("[./\\]") then
    return require(name)
  end
  reload_modules[name] = true
  if reloading then
    return require(name)
  end
  local old = package.loaded[name]
  package.loaded[name] = nil
  reloading = true
  local new = require(name)
  reloading = false
  --print(old, new)
  local ok1, otr = pcall(function()
      return old.to_replace
    end)
  local ok2, ntr = pcall(function()
      return new.to_replace
    end)
  if ok1 and ok2 and type(otr) == "table" and type(ntr) == "table" then
    replace.replace_all(otr, ntr)
  end
  if reload_types[type(old)] and reload_types[type(new)] then
    replace.replace(old, new)
  end
  return new
end

local to_check = {}
local idx = 1
local n = 0
local modmap = {}

local function update()
  if idx > n then
    to_check = {}
    idx = 1
    n = 0
    for k,v in pairs(reload_modules) do
      n = n + 1
      to_check[n] = k
    end
  else
    local name = to_check[idx]
    idx = idx + 1
    --print("checking: " .. name)
    local newmod = love.filesystem.getInfo(name..".lua").modtime
    if modmap[name] and modmap[name] ~= newmod then
      local file = love.filesystem.newFile(name..".lua")
      local func = loadstring(file:read())
      if func then
        reload(name)
      end
    end
    modmap[name] = newmod
  end
end

local function setup()
  love.run = coroutine.wrap(love.run)
end

local ret = {
  reload = reload,
  update = update,
  setup = setup,
}
setmetatable(ret, {
  __call = function(_,name) return reload(name) end,
})
return ret
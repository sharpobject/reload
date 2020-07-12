local debug = debug
local coroutine = coroutine
local type = type
local next = next
local pairs = pairs
local package = package

-- todo: lightuserdata?
local all_types = {
  1,
  true,
  "hello",
  function() return type end,
  coroutine.create(function() end)
}

local function maybe_visit(visited, to_visit, item)
  local typ = type(item)
  if (typ == "table" or typ == "thread" or typ == "function") and not visited[item] then
    to_visit[item] = true
  end
end

local function real_replace(old, new)
  --print("replacing "..old.." "..new)
  --print(debug.getregistry())
  --for k,v in pairs(debug.getregistry()) do print("FUCK "..k.." "..v) end
  local to_visit = {}
  local visited = {}
  visited[coroutine.running()] = true
  to_visit[debug.getregistry()] = true
  for i=0,#all_types do
    maybe_visit(visited, to_visit, debug.getmetatable(all_types[i]))
  end
  while true do
    local item = next(to_visit)
    if item == nil then break end
    if type(item) == "table" then
      local mt = debug.getmetatable(item)
      maybe_visit(visited, to_visit, mt)
      if mt == old then mt = new end
      debug.setmetatable(item, nil)
      for k,v in pairs(item) do
        if v == old then
          item[k] = new
        end
        maybe_visit(visited, to_visit, k)
        maybe_visit(visited, to_visit, v)
      end
      if item[old] then
        local tmp = item[old]
        item[old] = nil
        item[new] = tmp
      end
      debug.setmetatable(item, mt)
    elseif type(item) == "thread" then
      for qq=0,1e99 do
        local info = debug.getinfo(item, qq)
        if not info then break end
        for i=1,1e99 do
          local name,value = debug.getlocal(item, qq, i)
          if name == nil then break end
          maybe_visit(visited, to_visit, value)
          if value == old then
            debug.setlocal(item, qq, i, new)
          end
        end
        for i=-1,-1e99,-1 do
          local name,value = debug.getlocal(item, qq, i)
          if name == nil then break end
          maybe_visit(visited, to_visit, value)
          if value == old then
            debug.setlocal(item, qq, i, new)
          end
        end
      end
    elseif type(item) == "function" then
      for i=1,1e99 do
        local name,value = debug.getupvalue(item, i)
        if name == nil then break end
        maybe_visit(visited, to_visit, value)
        if value == old then
          debug.setupvalue(item, i, new)
        end
      end
    end
    to_visit[item] = nil
    visited[item] = true
  end
end

local function replace(old, new)
  local f = coroutine.wrap(real_replace)
  f(old, new)
end


local function real_replace_all(otr, ntr)
  --print("replacing "..old.." "..new)
  --print(debug.getregistry())
  --for k,v in pairs(debug.getregistry()) do print("FUCK "..k.." "..v) end
  local olds = {}
  for k,v in pairs(otr) do
    olds[v] = k
  end
  local to_visit = {}
  local visited = {}
  visited[coroutine.running()] = true
  to_visit[debug.getregistry()] = true
  for i=0,#all_types do
    maybe_visit(visited, to_visit, debug.getmetatable(all_types[i]))
  end
  while true do
    local item = next(to_visit)
    if item == nil then break end
    if type(item) == "table" then
      local mt = debug.getmetatable(item)
      local oldkeys = {}
      maybe_visit(visited, to_visit, mt)
      if olds[mt] ~= nil then mt = ntr[olds[mt]] end
      debug.setmetatable(item, nil)
      for k,v in pairs(item) do
        if olds[v] ~= nil then
          item[k] = ntr[olds[v]]
        end
        if olds[k] ~= nil then
          oldkeys[k] = true
        end
        maybe_visit(visited, to_visit, k)
        maybe_visit(visited, to_visit, v)
      end
      for k,_ in pairs(oldkeys) do
        local tmp = item[k]
        item[k] = nil
        item[ntr[olds[k]]] = tmp
      end
      debug.setmetatable(item, mt)
    elseif type(item) == "thread" then
      for qq=0,1e99 do
        local info = debug.getinfo(item, qq)
        if not info then break end
        for i=1,1e99 do
          local name,value = debug.getlocal(item, qq, i)
          if name == nil then break end
          maybe_visit(visited, to_visit, value)
          if olds[value] ~= nil then
            debug.setlocal(item, qq, i, ntr[olds[value]])
          end
        end
        for i=-1,-1e99,-1 do
          local name,value = debug.getlocal(item, qq, i)
          if name == nil then break end
          maybe_visit(visited, to_visit, value)
          if olds[value] ~= nil then
            debug.setlocal(item, qq, i, ntr[olds[value]])
          end
        end
      end
    elseif type(item) == "function" then
      for i=1,1e99 do
        local name,value = debug.getupvalue(item, i)
        if name == nil then break end
        maybe_visit(visited, to_visit, value)
        if olds[value] ~= nil then
          debug.setupvalue(item, i, ntr[olds[value]])
        end
      end
    end
    to_visit[item] = nil
    visited[item] = true
  end
end

local function replace_all(otr, ntr)
  local f = coroutine.wrap(real_replace_all)
  f(otr, ntr)
end

return {
  replace = replace,
  replace_all = replace_all,
}

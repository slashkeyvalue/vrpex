local Tools = module("lib/Tools")

local Proxy = {}

local callbacks = setmetatable({}, { __mode = "v" })
local rscname = GetCurrentResourceName()

local function proxy_resolve(itable,key)

	-- print("Resource just tried to call `vRP." .. key .. "`")

	local mtable = getmetatable(itable)
	local iname = mtable.name
	local ids = mtable.ids
	local callbacks = mtable.callbacks
	local identifier = mtable.identifier

	local fname = key
	local no_wait = false
	if string.sub(key,1,1) == "_" then
		fname = string.sub(key,2)
		no_wait = true
	end

	local fcall = function(...)
		local rid, r
		local profile

		if no_wait then
			rid = -1
		else
			r = async()
			rid = ids:gen()
			callbacks[rid] = r
		end

		local args = {...}

		TriggerEvent(iname..":proxy",fname, args, identifier, rid)
    
		if not no_wait then
			return r:wait()
		end
	end

	itable[key] = fcall
	return fcall
end

function proxy_resolve_new_index(itable, key, value)

	if string.sub(key,1,1) ~= "_" then
		local metatable = getmetatable(itable)

		local interface_name =  metatable.name

		-- print("TryToRegisterMember at " .. interface_name .. " key " .. key, value, itable)

		TriggerEvent("proxy:TryToRegisterMember", interface_name, GetCurrentResourceName(), key, value)
	end
end

function Proxy.addInterface(name, itable)
	AddEventHandler(name..":proxy", function(member,args,identifier,rid)

		if itable[member] then

			local f = itable[member]

			local rets = {}

			local membertype = type(f)

			if membertype == "function" or (membertype == "table" and f.__cfx_functionReference)then
				rets = {f(table.unpack(args, 1, table.maxn(args)))}
			end

			if rid >= 0 then
				TriggerEvent(name..":"..identifier..":proxy_res",rid,rets)
			end
		else
			print("Error: `" ..identifier .. "` tentou chamar `".. member .. "`, que nao existe em `" .. name .. "`") 
		end
	end)

	local resource_owned_members = {}

	itable.DestroyResourceOwnedFunction = function(key)
		itable[key] =  nil
	end

	AddEventHandler("proxy:TryToRegisterMember", function(iname, resource_name_sender, key, value)
		if iname == name and not itable[key] then
			if pcall(value) then -- Lua's protected call
				itable[key] = value

				if not resource_owned_members[resource_name_sender] then
					resource_owned_members[resource_name_sender] = {}
				end

				table.insert(resource_owned_members[resource_name_sender], key)

				print("^4[" ..resource_name_sender .. "] Registered an new member (`" .. key .. "`) at " .. name, value.__cfx_functionReference)
			end
		end
	end)

	AddEventHandler("onResourceStop", function(resource_name)

		for owner_resource_name, members in pairs(resource_owned_members) do
			if resource_name == owner_resource_name then

				for i, member in ipairs(members) do
					itable[member] = nil

					-- print("[" .. name .. "] destroyed [" .. GetCurrentResourceName() .. "]'s member: " .. owner_resource_name)
				end
			end
		end
	end)
end

function Proxy.getInterface(name, identifier)
	if not identifier then identifier = GetCurrentResourceName() end

	local ids = Tools.newIDGenerator()
	local callbacks = {}
	local r = setmetatable({},{ __index = proxy_resolve, name = name, ids = ids, callbacks = callbacks, identifier = identifier, __newindex = proxy_resolve_new_index})

	AddEventHandler(name..":"..identifier..":proxy_res", function(rid,rets)
		local callback = callbacks[rid]
		if callback then
			ids:free(rid)
			callbacks[rid] = nil
			callback(table.unpack(rets, 1, table.maxn(rets)))
		end
	end)

	return r
end

return Proxy
local prototype = (...) or _G.prototype

local META = {}

prototype.GetSet(META, "DebugTrace", "")
prototype.GetSet(META, "CreationTime", os.clock())
prototype.GetSet(META, "PropertyIcon", "")
prototype.GetSet(META, "HideFromEditor", false)
prototype.GetSet(META, "GUID", "")

prototype.StartStorable(META)
	prototype.GetSet("Name", "")
prototype.EndStorable()

function META:__tostring()
	local additional_info = self:__tostring2()
	
	if self.ClassName ~= self.Type then
		return ("%s:%s[%p]%s"):format(self.Type, self.ClassName, self, additional_info)
	else
		return ("%s[%p]%s"):format(self.Type, self, additional_info)
	end
end

function META:__tostring2()
	return ""
end

function META:IsValid()
	return true
end

do 
	prototype.remove_these = prototype.remove_these or {}
	local event_added = false

	function META:Remove(...)
		if self.call_on_remove then
			for k, v in pairs(self.call_on_remove) do
				if v() == false then
					return
				end
			end
		end
		
		if self.added_events then
			for event in pairs(self.added_events) do
				self:RemoveEvent(event)
			end
		end
	
		if self.OnRemove then 
			self:OnRemove(...) 
		end
		
		if not event_added and _G.event then 
			event.AddListener("Update", "prototype_remove_objects", function()
				for k in pairs(prototype.remove_these) do
					prototype.remove_these[k] = nil
					prototype.created_objects[k] = nil
					prototype.MakeNULL(k)
				end
			end)
			event_added = true
		end
		
		prototype.remove_these[self] = true
	end
end

do -- serializing
	local callbacks = {}

	function META:SetStorableTable(tbl)
		self:SetGUID(tbl.GUID)
		
		if self.OnDeserialize then
			self:OnDeserialize(tbl.__extra_data)
		end
		
		for _, info in ipairs(prototype.GetStorableVariables(self)) do
			if tbl[info.var_name] then
				self[info.set_name](self, tbl[info.var_name])
			end
		end
		
		if tbl.__property_links then
			for i, v in ipairs(tbl.__property_links) do
				self:WaitForGUID(v[1], function(obj)
					v[1] = obj
					self:WaitForGUID(v[2], function(obj)
						v[2] = obj
						prototype.AddPropertyLink(unpack(v))
					end)
				end)
			end
		end
	end
	
	function META:GetStorableTable()
		local out = {}
		
		for _, info in ipairs(prototype.GetStorableVariables(self)) do
			out[info.var_name] = self[info.get_name](self)
		end
		
		out.GUID = self.GUID
		
		local info = prototype.GetPropertyLinks(self)
		
		if next(info) then
			for i,v in ipairs(info) do
				v[1] = v[1].GUID
				v[2] = v[2].GUID
			end
			out.__property_links = info
		end
		
		if self.OnSerialize then
			out.__extra_data = self:OnSerialize()
		end
		
		return table.copy(out)
	end
	
	function META:SetGUID(guid)
		prototype.created_objects_guid = prototype.created_objects_guid or utility.CreateWeakTable()
				
		if prototype.created_objects_guid[self.GUID] then
			prototype.created_objects_guid[self.GUID] = nil
		end
		
		self.GUID = guid
		
		prototype.created_objects_guid[self.GUID] = self
				
		if callbacks[self.GUID] then
			for i, cb in ipairs(callbacks[self.GUID]) do
				cb(self)
			end
			callbacks[self.GUID] = nil
		end
	end
	
	function META:WaitForGUID(guid, callback)
		local obj = prototype.GetObjectByGUID(guid)
		if obj:IsValid() then
			callback(obj)
		else
			callbacks[guid] = callbacks[guid] or {}
			table.insert(callbacks[guid], callback)
			print("added callback for ", guid)
		end
	end
			
	function prototype.GetObjectByGUID(guid)
		prototype.created_objects_guid = prototype.created_objects_guid or utility.CreateWeakTable()
		
		return prototype.created_objects_guid[guid] or NULL
	end
end

function META:CallOnRemove(callback, id)
	id = id or callback
	
	if type(callback) == "table" and callback.Remove then
		callback = function() prototype.SafeRemove(callback) end
	end
	
	self.call_on_remove = self.call_on_remove or {}
	self.call_on_remove[id] = callback
end

do -- events
	local events = {}
	local ref_count = {}

	function META:AddEvent(event_type)
		self.added_events = self.added_events or {}
		if self.added_events[event_type] then return end
		
		ref_count[event_type] = (ref_count[event_type] or 0) + 1
		
		local func_name = "On" .. event_type
		
		events[event_type] = events[event_type] or utility.CreateWeakTable()		
		table.insert(events[event_type], self)
		
		event.AddListener(event_type, "prototype_events", function(a_, b_, c_) 
			for name, self in ipairs(events[event_type]) do
				if self[func_name] then
					self[func_name](self, a_, b_, c_)
				end
			end
		end, {on_error = function(str)
			logn(str)
			self:RemoveEvent(event_type)
		end})
				
		self.added_events[event_type] = true
	end

	function META:RemoveEvent(event_type)
		self.added_events = self.added_events or {}
		if not self.added_events[event_type] then return end

		ref_count[event_type] = (ref_count[event_type] or 0) - 1

		events[event_type] = events[event_type] or utility.CreateWeakTable()
		
		for i, other in pairs(events[event_type]) do
			if other == self then
				events[event_type][i] = nil
				break
			end
		end
		
		table.fixindices(events[event_type])
		
		self.added_events[event_type] = nil
		
		if ref_count[event_type] <= 0 then
			event.RemoveListener(event_type, "prototype_events")
		end
	end
end

prototype.base_metatable = META

if RELOAD then
	prototype.RebuildMetatables()
end
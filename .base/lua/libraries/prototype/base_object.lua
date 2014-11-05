local prototype = (...) or _G.prototype

local META = {}

prototype.GetSet(META, "DebugTrace", "")
prototype.GetSet(META, "CreationTime", os.clock())
prototype.GetSet(META, "PropertyIcon", "")
prototype.GetSet(META, "Name", "")

function META:__tostring()
	if self.ClassName ~= self.Type then
		return ("%s:%s[%p]"):format(self.Type, self.ClassName, self)
	else
		return ("%s[%p]"):format(self.Type, self)
	end
end

function META:IsValid()
	return true
end

do 
	prototype.remove_these = prototype.remove_these or {}
	local event_added = false

	function META:Remove(...)
		for k, v in pairs(self.call_on_remove) do
			if v() == false then
				return
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

do -- call on remove
	META.call_on_remove = {}

	function META:CallOnRemove(callback, id)
		id = id or callback
		
		self.call_on_remove[id] = callback
	end
end

do -- events
	local events = {}
	local ref_count = {}

	function META:AddEvent(event_type)			
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
		
		self.added_events = self.added_events or {}
		self.added_events[event_type] = true
	end

	function META:RemoveEvent(event_type)
		ref_count[event_type] = (ref_count[event_type] or 0) - 1

		events[event_type] = events[event_type] or utility.CreateWeakTable()
		
		for i, other in pairs(events[event_type]) do
			if other == self then
				events[event_type][i] = nil
				break
			end
		end
		
		table.fixindices(events[event_type])
		
		if ref_count[event_type] <= 0 then
			event.RemoveListener(event_type, "prototype_events")
		end
	end
end

prototype.base_metatable = META
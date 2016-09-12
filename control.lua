aux 'core'

local event_frame = CreateFrame('Frame')

local listeners, threads = t, t

local thread_id
function public.thread_id.get() return thread_id end

function LOAD()
	event_frame:SetScript('OnUpdate', UPDATE)
	event_frame:SetScript('OnEvent', EVENT)
end

function EVENT()
	for id, listener in listeners do
		if listener.killed then
			listeners[id] = nil
		elseif event == listener.event then
			listener.cb(listener.kill)
		end
	end
end

do
	function UPDATE()
		for _, listener in listeners do
			local event, needed = listener.event, false
			for _, listener in listeners do needed = needed or listener.event == event and not listener.killed end
			if not needed then event_frame:UnregisterEvent(event) end
		end

		for id, thread in threads do
			if thread.killed or not thread.k then
				threads[id] = nil
			else
				local k = thread.k
				thread.k = nil
				thread_id = id
				k()
				thread_id = nil
			end
		end
	end
end

do local id = 0
	function private.unique_id.get() id = id + 1; return id end
end

function public.kill_listener(listener_id)
	for listener in present(listeners[listener_id]) do listener.killed = true end
end

function public.kill_thread(thread_id)
	for thread in present(threads[thread_id]) do thread.killed = true end
end

function public.event_listener(event, cb)
	local listener_id = unique_id
	listeners[listener_id] = { event=event, cb=cb, kill=function(...) auto[arg] = true if arg.n == 0 or arg[1] then kill_listener(listener_id) end end }
	event_frame:RegisterEvent(event)
	return listener_id
end

function public.on_next_event(event, callback)
	event_listener(event, function(kill) callback(); kill() end)
end

function public.thread(k, ...) auto[arg] = true
	local thread_id = unique_id
	threads[thread_id] = T('k', partial(k, unpack(arg)))
	return thread_id
end

function public.wait(k, ...) auto[arg] = true
	if type(k) == 'number' then
		when(function() k = k - 1 return k <= 1 end, unpack(arg))
	else
		threads[thread_id].k = partial(k, unpack(arg))
	end
end

function public.when(c, k, ...) auto[arg] = true
	if c() then
		return k(unpack(arg))
	else
		return wait(when, c, k, unpack(arg))
	end
end

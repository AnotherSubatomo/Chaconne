
-- AnotherSubatomo/Chaconne
-- A simple, strictly-typed, reactive state manager.
-- Heavily inspired by fewkz/cells and dphfox/fusion.
-- License: Unlicense

--!native
--!strict

type collection<O> = {[O]: true}
export type subscriber<T> = (T) -> ()
export type unsubscriber = () -> ()
export type janitor = () -> ()
export type cell<T> = {
	internal: {
		value: T,
		subscribers: collection<subscriber<T>>,
		janitors: collection<janitor>
	},
	set:       (cell<T>, T) -> (),
	get:       (cell<T>) -> (T),
	subscribe: (cell<T>, subscriber<T>) -> (unsubscriber),
	janitor:   (cell<T>, janitor) -> (),
	dispose:   (cell<T>) -> ()
}
export type use<T> = (cell<T>) -> (T)
export type equation<T> = (use<any>) -> (T)

local ERR_TYPE_MISMATCH = "New cell value's type mismatched with the previous."

local function SET<T>(self: cell<T>, new: T): ()
	local current = self.internal.value
	if current == new then return end
	assert(typeof(current) == typeof(new), ERR_TYPE_MISMATCH)
	self.internal.value = new
	for subscriber in self.internal.subscribers do subscriber(new) end
end

local function GET<T>(self: cell<T>): (T)
	return self.internal.value
end

local function SUBSCRIBE<T>(self: cell<T>, subscriber: subscriber<T>): (unsubscriber)
	local subscribers = self.internal.subscribers
	subscribers[subscriber] = true
	return function () subscribers[subscriber] = nil end
end

local function JANITOR<T>(self: cell<T>, janitor: janitor): ()
	self.internal.janitors[janitor] = true
end

local function DISPOSE<T>(self: cell<T>): ()
	for janitor in self.internal.janitors do janitor() end
	table.clear(self.internal.subscribers)
	table.clear(self.internal.janitors)
	table.clear(self)
end

local function use<U>(this_cell: cell<U>): (U?)
	return this_cell.get and this_cell:get() or nil
end

local function cell<T>(initial: T): cell<T>
	local self:cell<T> = {
		internal = {
			value = initial;
			subscribers = {};
			janitors = {};
		};
		set = SET;
		get = GET;
		subscribe = SUBSCRIBE;
		janitor = JANITOR;
		dispose = DISPOSE;
	}

	return self
end

local function formula<T>(equation: equation<T>): cell<T>
	local cells_involved: {cell<any>} = {}
	local function spyUse<U>(this_cell: cell<U>): (U)
		table.insert(cells_involved, this_cell)
		return this_cell:get()
	end
	local initial = equation(spyUse)
	local derived = cell(initial)
	local unsubscribers: {unsubscriber} = {}
	for _, involved_cell in cells_involved do
		table.insert(unsubscribers, involved_cell:subscribe(function (new)
			derived:set(equation(use))
		end))
	end
	derived:janitor(function()
		for _, unsubscriber in unsubscribers do unsubscriber() end
	end)
	return derived
end

return {
	cell = cell;
	formula = formula;
}
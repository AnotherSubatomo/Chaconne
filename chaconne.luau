
-- AnotherSubatomo/Chaconne
-- A simple, strictly-typed, reactive state manager.
-- Heavily inspired by fewkz/cells and dphfox/fusion.
-- License: CC0-1.0

--!strict
--!optimize 2
--!native

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
	subscribe: (cell<T>, subscriber<T>, uneager: boolean?) -> (unsubscriber),
	janitor:   (cell<T>, janitor) -> (),
	dispose:   (cell<T>) -> ()
}

export type use<T> = (cell<T>) -> (T)
export type equation<T> = (use<any>) -> (T)
export type computex = {
	running: boolean,
	-- Of type `collection` to avoid dependency duplication
	-- incase the same cell is used multiple times
	cells_involved: collection<cell<any>>,
	unsubscribers: {unsubscriber}
}

local ERR_TYPE_MISMATCH = "New cell value's type mismatched with the previous."

local function SET<T>(self: cell<T>, new: T): ()
	local current = self.internal.value
	if current == new then return end
	if typeof(current) ~= typeof(new) then error(ERR_TYPE_MISMATCH) end
	self.internal.value = new
	for subscriber in self.internal.subscribers do subscriber(new) end
end

local function GET<T>(self: cell<T>): (T)
	return self.internal.value
end

local function SUBSCRIBE<T>(self: cell<T>, subscriber: subscriber<T>, uneager: boolean?): (unsubscriber)
	local subscribers = self.internal.subscribers
	if not uneager then subscriber(self.internal.value) end
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

local function RECOMPUTE<T>(formula: cell<T>, equation: equation<T>, context: computex): ()
	if context.running then return end
	context.running = true

	local cells_involved = context.cells_involved
	local unsubscribers = context.unsubscribers

	for _, unsubscriber in unsubscribers do
		unsubscriber()
	end

	table.clear(unsubscribers)
	table.clear(cells_involved)

	local function use<U>(this_cell: cell<U>): (U)
		cells_involved[this_cell] = true
		return this_cell:get()
	end

	local formula_value = equation(use)
	formula:set(formula_value)

	for cell in cells_involved do
		table.insert(unsubscribers, cell:subscribe(function ()
			RECOMPUTE(formula, equation, context)
		end, true))
	end

	context.running = false
end

local function formula<T>(equation: equation<T>): cell<T>
	local self = cell((nil :: any) :: T)
	local unsubscribers = {}
	local context = {
		running = false;
		cells_involved = {};
		unsubscribers = unsubscribers;
	}

	RECOMPUTE(self, equation, context)

	self:janitor(function()
		for _, unsubscriber in unsubscribers do unsubscriber() end
	end)

	return self
end

return {
	cell = cell;
	formula = formula;
}
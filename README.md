
<img align="right" width="100" height="100" src="Chaconne.png"/>

# Chaconne
A simple, intuitive, and strictly-typed reactive state manager.

*Heavily inspired by [fewkz/cells](github.com/fewkz/cells) and [dphfox/fusion](github.com/dphfox/fusion).*


>[!IMPORTANT]
> This library has been deprecated in favor of [`AnotherSubatomo/quark`](https://github.com/AnotherSubatomo/quark).

[![Last Commit](https://img.shields.io/github/last-commit/AnotherSubatomo/Chaconne/main)](https://github.com/AnotherSubatomo/Chaconne/commits/main/) [![Release Version](https://img.shields.io/github/v/release/AnotherSubatomo/Chaconne?color=green)](https://github.com/AnotherSubatomo/Chaconne/releases/latest) [![License: Unlicense](https://img.shields.io/badge/License-Unlicense-yellow.svg?)](https://opensource.org/licenses/Unlicense) [![Wally Package](https://img.shields.io/badge/Wally-ad4646?)](https://wally.run/package/anothersubatomo/chaconne)

---

### 🚀 Crash Course
A **cell** represents a value that can change — a reactive *state object*. When a cell’s value is updated via `.set()`, any subscribers added via `.subscribe()` will be triggered with the new value. You can create a cell using the `cell()` function and passing an initial value:
```luau
local Chaconne = require('./chaconne')
local cell = Chaconne.cell

local name = cell("Adrian")

name:subscribe(function(new_name)
	print(`My name is {new_name}!`)
end)

name:set("Steven") -- Output: My name is Steven!
name:set("Yuvin") -- Output: My name is Yuvin!
```

A **derived cell** is a reactive value that *depends* on other cells to compute its result. Derived cells are created using the `formula()` function, and they must explicitly access other cells using the provided `use()` helper as without it, changes to the cell it is dependent on won't propagate to that derived cell.
```luau
-- ...
local formula = Chaconne.formula

local applePrice = cell(1)
local money = cell(20)
local applesCanBuy = formula(function(use)
	return use(money) // use(applePrice)
end)

applesCanBuy:subscribe(function(amount)
	print(`You can buy {amount} apples with {money:get()} dollars.`)
end)

applePrice:set(2) -- Output: You can buy 10 apples with 20 dollars.
money:set(100) -- Output: You can buy 50 apples with 100 dollars.
```

---

### 🧠 Subtleties
* `cell` objects are plain tables. All internal data (value, subscribers, janitor functions) is stored in the `.internal` field. This field should be treated as **private** — do not mutate it directly.
* If the new value passed to `.set()` is the **same** as the current value (as determined by `==`), the update is skipped. This makes Chaconne **lazy** in propagation — it only reacts when values actually change.

---

### Why Choose Chaconne
* ☁ **Super duper lightweight** —
  This library is a single file with under 100 **lines of code**. No dependencies, no setup — just drop it in and go.

* 🔒 **Strictly typed** —
  Designed with Luau’s strict type system in mind for reliable autocompletion and early error detection. Also — no `getfenv` tricks like *fewkz's cells* (no shade on fewkz though!).

* 🧹 **Explicit memory control** —
  Built-in `.dispose()` support and a `janitor` system mean you decide exactly when a reactive chain should be cleaned up. No leaks, no surprises.

* 🧪 **Predictable and testable** —
  No hidden globals or scheduler black magic. You can test logic in isolation with pure Lua semantics.

---

### Why Refuse Chaconne

* ⚙️ **Fusion just works** —
  If you’re already deep in the Fusion ecosystem — or rely heavily on its reactive graph, bindings, and automatic lifecycle — then yeah, stick with Fusion. It’s mature, powerful, and built for UI-heavy use cases.

* 🔁 **No automatic batching or dependency graphs** —
  Chaconne is simple and direct. It doesn't track dependency chains or defer updates. If you need efficient batched updates or graph-level diffing, this isn’t it.

* 🔍 **You’re allergic to manual disposal** —
  Chaconne gives you control, but with that comes responsibility. If you don’t call `.dispose()` when you should, your program *will* leak.

---

If you value minimalism, tight control, and clear mental models over automation and complexity — Chaconne’s for you.
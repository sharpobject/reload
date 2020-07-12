reload
========================
reload is a a library to enable live coding in love2d.

While running your game, you can save a change to a lua file and see the change take effect in the game immediately.

How to use
-------------------------------

Require it!
```lua
local reload = require"reload"
```

If you want a module to be hot-reloaded, use `reload` instead of `require` to import it:
```lua
-- the entire body of main.lua:
local reload = require"reload"
reload.setup()
-- I'd like to live code "real_main"!
reload"real_main"

-- in real_main.lua:
-- In this example, I don't want to live-code kikito's tween library
local tween = require"tween"
-- But I do want to live-code my own classes.
reload"drawcontainer"
reload"customer"
reload"button"
reload"animation"
```

At some point before `love.run` happens, please call `reload.setup()`.
If you are not defining your own `love.run`, you can do this as soon as you first `require"reload"`
like in the example above.
If you are defining your own love.run, you can call `reload.setup()` right after assigning `love.run`. Thanks.

In love.update, please call `reload.update()`
```lua
function love.update(dt)
  reload.update()
  -- do other stuff to update your game ok
end
```

What does it do lmao
----------------------

When you call `reload.update()`, reload will stat at most 1 file loaded using reload
to see if it's been updated.
If it's been updated, and it currently contains valid lua code,
it will unload the module from `package.loaded` and load it again using `require`.
Then, if we take the old return value of the module as `old` and the new one as `new`,
if `old.to_replace` is a table and `new.to_replace` is a table, for every pair `k,v in pairs(old.to_replace)`,
every instance of `v` in the entire program will be replaced with `new.to_replace[k]`.
Then, if `old` is a table or a function and `new` is a table or a function, all instances
of `old` in the entire program will be replaced with `new`.

reload will not reload dependencies of a module it is reloading.
If you save a change to the dependency then save a change to the module,
it should reload both of them in the right order during separate calls to `reload.update()`.

I mainly use this to hot-reload classes by writing modules that return the class object.

Limitations
----------------------
Right now reload only reloads lua files in the top-level project folder. Sorry.

Replacing all occurrences of a thing with another thing is an approach frought with peril:

- If you set mymodule.to_replace.house_width = 5, then change it to mymodule.to_replace.house_width = 10 and save,
  then reload will attempt to replace all occurrences of 5 in your entire program with 10, even ones that aren't related
  to the width of houses.
- reload cannot replace functions that are currently executing. Normally you'll only run into this limitation if you are using coroutines.
- If you replace an old version of a class with a new version of the class,
  and you add some code to the constructor that sets a new property,
  and you add some code to a method that uses the new property, you should be sure to handle the case
  where the new property has not been set because the object was
  created using the old constructor but has the new method.

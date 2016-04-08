local awful = require("awful")

-- luacheck: globals modkey

local old_c = nil

local function get_callback(mod, key)
    local inf = {}
    awful.key(mod, key, nil, nil, inf)

    return inf.execute
end

-- Get a tag and a client
local function get_c_and_t()
    client.focus = old_c or client.get()[1]
    local c  = client.focus

    local t = c.screen.selected_tag

    return c, t
end

-- display deprecated warnings
--awful.util.deprecate = function() end

local has_spawned = false

local steps = {

function(count)
    if count <= 1 and not has_spawned and #client.get() < 2 then
        for _=1, 5 do awful.spawn("xterm") end
        has_spawned = true
    elseif #client.get() >= 5 then
        local c, _ = get_c_and_t()
        old_c = c

        return true
    end
end,

-- Wait for the focus to change
function()
    if has_spawned then
        has_spawned = false
        return nil
    end

    assert(old_c)

    -- Test layout
    -- local cb = get_callback({modkey}, " ")
    -- assert(cb)

    --TODO use the key once the bug is fixed
    local l = old_c.screen.selected_tag.layout
    assert(l)

    -- cb()
    awful.layout.inc(1)

    assert(old_c.screen.selected_tag.layout ~= l)

    -- Test ontop

    assert(not old_c.ontop)
    get_callback({modkey}, "t")()

    return true
end,

-- Ok, no now ontop should be true
function()
    local _, t = get_c_and_t()

    -- Give awesome some time
    if not old_c.ontop then return nil end

    assert(old_c.ontop)

    -- Now, test the mwfact
    assert(t.mwfact == 0.5)

    get_callback({modkey}, "l")()

    return true
end,

-- The master width factor should now be bigger
function()
    local _, t = get_c_and_t()

    assert(t.mwfact == 0.55)

    -- Now, test the nmaster
    assert(t.nmaster == 1)

    get_callback({modkey, "Shift"}, "h")()

    return true
end,

-- The number of master client should now be 2
function()
    local _, t = get_c_and_t()

    assert(t.nmaster == 2)

    -- Now, test the ncol
    assert(t.ncol == 1)

    get_callback({modkey, "Control"}, "h")()
    get_callback({modkey, "Shift"  }, "l")()

    return true
end,

-- The number of columns should now be 2
function()
    local _, t = get_c_and_t()

    assert(t.ncol == 2)

    -- Now, test the switching tag
    assert(t.index == 1)

    get_callback({modkey, }, "Right")()

    return true
end,

-- The tag index should now be 2
function()
    local tags = mouse.screen.tags
--     local t = awful.screen.focused().selected_tag

--     assert(t.index == 2)--FIXME

    assert(tags[1].index == 1)
    tags[1]:view_only()

    return true
end,

-- Before testing tags, lets make sure everything is still right
function()
    local tags = mouse.screen.tags

    assert(tags[1].selected)

    local clients = mouse.screen.clients

    -- Make sure the clients are all on the same screen, they should be
    local c_scr = client.get()[1].screen

    for _, c in ipairs(client.get()) do
        assert(c_scr == c.screen)
    end

    -- Then this should be true
    assert(#clients == #client.get())

    assert(#mouse.screen.all_clients == #clients)

    assert(#mouse.screen.all_clients - #mouse.screen.hidden_clients == #clients)

    return true
end,

-- Now, test switching tags
function()
    local tags = mouse.screen.tags
    local clients = mouse.screen.all_clients

    assert(#tags == 9)

    assert(#clients == 5)

    assert(mouse.screen.selected_tag == tags[1])

    for i=1, 9 do
        -- Check that assertion, because if it's false, the other assert()
        -- wont make any sense.
        assert(tags[i].index == i)
    end

    for i=1, 9 do
        tags[i]:view_only()
        assert(tags[i].selected)
        assert(#mouse.screen.selected_tags == 1)
    end

    tags[1]:view_only()

    return true
end,

-- Lets shift some clients around
function()
    local tags = mouse.screen.tags

    -- Given all tags have been selected, the selection should be back on
    -- tags[1] and the client history should be kept
    assert(client.focus == old_c)

    --get_callback({modkey, "Shift"  }, "#"..(9+i))() --FIXME
    client.focus:move_to_tag(tags[2])

    assert(not client.focus)

    return true
end,

-- The client should be on tag 5
function()
    -- Confirm the move did happen
    local tags = mouse.screen.tags
    assert(tags[1].selected)
    assert(#old_c:tags() == 1)
    assert(old_c:tags()[1] ~= tags[1])
    assert(not old_c:tags()[1].selected)

    -- The focus should have changed by now, as the tag isn't visible
    assert(client.focus ~= old_c)

    assert(old_c:tags()[1] == tags[2])

    assert(#tags[2]:clients() == 1)
    assert(#tags[1]:clients() == 4)

    return true
end
}

require("_runner").run_steps(steps)

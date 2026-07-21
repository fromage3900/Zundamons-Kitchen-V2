--!strict
-- [[ModuleScript] CursorConfig]
-- Maps cursor names to uploaded Decal asset IDs.
-- Cursor designs inspired by Zundamon Cursor Set (MIT, wappon_28_dev)
-- and zunda_arrow set (MIT, wappon_28_dev). See CREDITS.md for full attribution.
-- Created by scripts/agent_orchestrator/tools/cursor_converter.py
local CursorConfig = {
    cursors = {
        -- Zundamon themed cursors (uploaded as Decals)
        ['alternate'] = 'rbxassetid://106094557321184',
        ['busy'] = 'rbxassetid://134483427046324',
        ['cross'] = 'rbxassetid://134658133048447',
        ['handwriting'] = 'rbxassetid://123335052649445',
        ['help'] = 'rbxassetid://110661163934017',
        ['link'] = 'rbxassetid://125261033114925',
        ['location'] = 'rbxassetid://128030590859262',
        ['move'] = 'rbxassetid://129620721993236',
        ['normal'] = 'rbxassetid://129907991370277',
        ['person'] = 'rbxassetid://121316566770444',
        ['resize_nesw'] = 'rbxassetid://71648493285118',
        ['resize_ns'] = 'rbxassetid://99275830582802',
        ['resize_nwse'] = 'rbxassetid://82791611989858',
        ['resize_we'] = 'rbxassetid://135484431580955',
        ['text'] = 'rbxassetid://88055218520083',
        ['unavailable'] = 'rbxassetid://109907172631146',
        ['working'] = 'rbxassetid://107311689715717',

        -- Standard UI cursors
        default = '',
        pointing = '',
        waiting = '',
        text = '',
    },
}
function CursorConfig.getCursor(name)
    return CursorConfig.cursors[name] or ''
end

return CursorConfig
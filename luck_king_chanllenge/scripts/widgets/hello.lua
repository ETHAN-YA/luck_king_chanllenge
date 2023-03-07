--[[
Author: Ethan
Date: 2023-01-31 23:32:14
LastEditTime: 2023-01-31 23:32:20
FilePath: \_scriptsd:\1\steamapps\common\Don't Starve Together\mods\luck_king_chanllenge\scripts\widgets\hello.lua
description:  
--]]
local Widget = require("widgets/widget") --Widget，所有widget的祖先类
local Text = require("widgets/text") --Text类，文本处理

local Hello = Class(Widget, function(self)
    Widget._ctor(self, "Hello")
    self.text = self:AddChild(Text(BODYTEXTFONT, 30,"Hello Klei"))
end)

return Hello
--[[
Author: Ethan
Date: 2023-01-30 16:51:40
LastEditTime: 2023-01-30 17:04:52
FilePath: \_scriptsd:\1\steamapps\common\Don't Starve Together\mods\luck_king_chanllenge\scripts\map\static_layouts\my_default_start.lua
description:  
--]]
-- local player_number = 

return {
  version = "1.1",
  luaversion = "5.1",
  orientation = "orthogonal",
  width = 10, --最大边界值
  height = 10, --最大边界值，一定要设置成正方形！
  tilewidth = 64,  --像素点，推荐64
  tileheight = 64, --像素点，推荐64
  properties = {},
  tilesets = {
    {
      name = "tiles",
      firstgid = 1,
      tilewidth = 64,   --像素点，推荐64
      tileheight = 64,  --像素点，推荐64
      spacing = 0,
      margin = 0,
      image = "../../../../tools/tiled/dont_starve/tiles.png",
      imagewidth = 512,   --不要动
      imageheight = 384,  --不要动
      properties = {},
      tiles = {}
    }
  },
  layers = {
    {
      type = "tilelayer",
      name = "BG_TILES",
      x = 0,
      y = 0,
      width = 10,  --最大边界值
      height = 10, --最大边界值
      visible = true,
      opacity = 1,
      properties = {},
      encoding = "lua",
      data = {
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 4, 4, 1, 1, 4, 4, 1, 1,
        1, 1, 4, 4, 1, 1, 4, 4, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 4, 4, 1, 1, 4, 4, 1, 1,
        1, 1, 4, 4, 1, 1, 4, 4, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1
      }
    },
    {
      type = "objectgroup",
      name = "FG_OBJECTS",
      visible = true,
      opacity = 1,
      properties = {},
      objects = {
        {
          name = "传送门",
          type = "multiplayer_portal",  --传送门
          shape = "rectangle",
          x = 256,    --横坐标，64的倍数
          y = 256,    --纵坐标，64的倍数
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "multiplayer_portal",
          shape = "rectangle",
          x = 128,
          y = 128,
          width = 64,
          height = 64,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "spawnpoint_master",
          shape = "rectangle",
          x = 128,
          y = 128,
          width = 64,
          height = 64,
          visible = true,
          properties = {}
        }
      }
    }
  }
}

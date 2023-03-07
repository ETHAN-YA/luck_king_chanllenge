--[[
Author: Ethan
Date: 2023-01-28 21:33:21
LastEditTime: 2023-01-28 21:33:22
FilePath: \_scriptsd:\1\steamapps\common\Don't Starve Together\mods\luck_king_chanllenge\scripts\prefabs\tumbleweed.lua
description:  
--]]

local easing = require("easing")

local AVERAGE_WALK_SPEED = 4
local WALK_SPEED_VARIATION = 2
local SPEED_VAR_INTERVAL = .5
local ANGLE_VARIANCE = 10

local assets =
{
    Asset("ANIM", "anim/tumbleweed.zip"),
}

local prefabs =
{
    "splash_ocean",
    "tumbleweedbreakfx",
    "ash",
    "cutgrass",
    "twigs",
    "petals",
    "foliage",
    "silk",
    "rope",
    "seeds",
    "purplegem",
    "bluegem",
    "redgem",
    "orangegem",
    "yellowgem",
    "greengem",
    "seeds",
    "trinket_6",
    "cutreeds",
    "feather_crow",
    "feather_robin",
    "feather_robin_winter",
    "feather_canary",
    "trinket_3",
    "beefalowool",
    "rabbit",
    "mole",
    "butterflywings",
    "fireflies",
    "beardhair",
    "berries",
    "TOOLS_blueprint",
    "LIGHT_blueprint",
    "SURVIVAL_blueprint",
    "FARM_blueprint",
    "SCIENCE_blueprint",
    "WAR_blueprint",
    "TOWN_blueprint",
    "REFINE_blueprint",
    "MAGIC_blueprint",
    "DRESS_blueprint",
    "petals_evil",
    "trinket_8",
    "houndstooth",
    "stinger",
    "gears",
    "spider",
    "frog",
    "bee",
    "mosquito",
    "boneshard",
}

local CHESS_LOOT =
{
    "chesspiece_pawn_sketch",
    "chesspiece_muse_sketch",
    "chesspiece_formal_sketch",
    "trinket_15", --bishop
    "trinket_16", --bishop
    "trinket_28", --rook
    "trinket_29", --rook
    "trinket_30", --knight
    "trinket_31", --knight
}

for k, v in ipairs(CHESS_LOOT) do
    table.insert(prefabs, v)
end

local SFX_COOLDOWN = 5

local function onplayerprox(inst)
    if not inst.last_prox_sfx_time or (GetTime() - inst.last_prox_sfx_time > SFX_COOLDOWN) then
       inst.last_prox_sfx_time = GetTime()
       inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tumbleweed_choir")
    end
end

local function CheckGround(inst)
    if not inst:IsOnValidGround() then
        SpawnPrefab("splash_ocean").Transform:SetPosition(inst.Transform:GetWorldPosition())
        inst:PushEvent("detachchild")
        inst:Remove()
    end
end

local function startmoving(inst)
    inst.AnimState:PushAnimation("move_loop", true)
    inst.bouncepretask = inst:DoTaskInTime(10*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tumbleweed_bounce")
        inst.bouncetask = inst:DoPeriodicTask(24*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tumbleweed_bounce")
            CheckGround(inst)
        end)
    end)
    inst.components.blowinwind:Start()
    inst:RemoveEventCallback("animover", startmoving)
end

local function onpickup(inst, picker)
    local x, y, z = inst.Transform:GetWorldPosition()

    inst:PushEvent("detachchild")

    local item = nil
    for i, v in ipairs(inst.loot) do
        item = SpawnPrefab(v)
        item.Transform:SetPosition(x, y, z)
        if item.components.inventoryitem ~= nil and item.components.inventoryitem.ondropfn ~= nil then
            item.components.inventoryitem.ondropfn(item)
        end
        if inst.lootaggro[i] and item.components.combat ~= nil and picker ~= nil then
            if not (item:HasTag("spider") and (picker:HasTag("spiderwhisperer") or picker:HasTag("monster"))) then
                item.components.combat:SuggestTarget(picker)
            end
        end
    end

    SpawnPrefab("tumbleweedbreakfx").Transform:SetPosition(x, y, z)
    inst:Remove()
    return true --This makes the inventoryitem component not actually give the tumbleweed to the player
end

local function MakeLoot(inst)
    local possible_loot =
    {
--基础资源
        {chance=35,item="log"},--木头
        {chance=30,item="rocks"},--石头
        {chance=25,item="flint"},--燧石
        {chance=25,item="petals"},--花瓣
        {chance=20,item="ice"},--冰
        {chance=18,item="cutreeds"},--芦苇
        {chance=15,item="nitre"},--硝石
        {chance=15,item="pinecone"},--松果
        {chance=15,item="acorn"},--桦木果
        {chance=15,item="petals_evil"},--恶魔花瓣
        {chance=15,item="goldnugget"},--黄金
        {chance=15,item="charcoal"},--木炭
        {chance=12,item="twiggy_nut"},--多枝树球果
        {chance=10,item="rock_avocado_fruit"},--石果
        {chance=8,item="marble"},--大理石
        {chance=4,item="dug_grass"},--草丛
        {chance=4,item="dug_sapling"},--树苗
        {chance=3,item="dug_berrybush"},--普通浆果丛
        {chance=3,item="dug_marsh_bush"},--荆棘丛
        {chance=3,item="dug_berrybush2"},--三叶浆果丛
        {chance=3,item="dug_berrybush_juicy"},--多汁浆果丛
--高级资源
        {chance=3,item="poop"},--便便
        {chance=3,item="houndstooth"},--狗牙
        {chance=3,item="stinger"},--蜂刺
        {chance=3,item="silk"},--蜘蛛网
        {chance=3,item="spoiled_food"},--腐烂食物
        {chance=3,item="foliage"},--蕨叶
        {chance=3,item="boneshard"},--骨头碎片
        {chance=2.5,item="guano"},--鸟粪
        {chance=2,item="spidergland"},--蜘蛛腺体
        {chance=2,item="slurtle_shellpieces"},--蜗牛壳碎片
        {chance=2,item="slurper_pelt"},--啜食者皮
        {chance=2,item="beardhair"},--胡子
        {chance=2,item="rottenegg"},--腐烂的蛋
        {chance=2,item="cookiecuttershell"},--饼干切割机壳
        {chance=2,item="feather_crow"},--乌鸦羽毛
        {chance=2,item="feather_robin"},--红雀羽毛
        {chance=2,item="lightbulb"},--荧光果
        {chance=1.5,item="boards"},--木板
        {chance=1.5,item="cutstone"},--石砖
        {chance=1.5,item="mosquitosack"},--蚊子血囊
        {chance=1.5,item="rope"},--绳子
        {chance=1.5,item="compost"},--堆肥
        {chance=1.5,item="moon_tree_blossom"},--月树花
        {chance=1.5,item="succulent_picked"},--肉质植物
        {chance=1.5,item="thulecite_pieces"},--铥矿碎片
        {chance=1.5,item="waterplant_bomb"},--种壳
        {chance=1.5,item="coontail"},--猫尾巴
        {chance=1.5,item="slurtleslime"},--蜗牛黏液
        {chance=1.5,item="beefalowool"},--牛毛
        {chance=1.5,item="phlegm"},--痰液
        {chance=1.2,item="nightmarefuel"},--噩梦燃料
        {chance=1,item="spoiled_fish_small"},--变质的小鱼
        {chance=1,item="furtuft"},--熊毛簇
        {chance=1,item="spoiled_fish"},--变质的鱼
        {chance=1,item="driftwood_log"},--浮木
        {chance=1,item="feather_robin_winter"},--冬雀羽毛
        {chance=1,item="moonrocknugget"},--月石
        {chance=.8,item="marblebean"},--大理石豆
        {chance=.8,item="moonglass"},--月亮碎片
        {chance=.8,item="saltrock"},--盐晶
        {chance=.8,item="pigskin"},--猪皮
        {chance=.7,item="papyrus"},--纸
        {chance=.6,item="steelwool"},--钢绒
        {chance=.6,item="honeycomb"},--蜂巢
        {chance=.6,item="fossil_piece"},--化石碎片
        {chance=.6,item="malbatross_feather"},--邪天翁羽毛
        {chance=.5,item="glommerfuel"},--咕噜姆黏液
        {chance=.5,item="transistor"},--电子元件
        {chance=.5,item="townportaltalisman"},--砂石
        {chance=.5,item="feather_canary"},--金丝雀羽毛
        {chance=.5,item="manrabbit_tail"},--兔毛
        {chance=.5,item="livinglog"},--活木
        {chance=.5,item="compostwrap"},--肥料包
        {chance=.5,item="gunpowder"},--火药
        {chance=.4,item="beeswax"},--蜂蜡
        {chance=.4,item="tentaclespots"},--触手皮
        {chance=.4,item="lightninggoathorn"},--闪电羊角
        {chance=.3,item="waxpaper"},--蜡纸
        {chance=.2,item="gears"},--齿轮
        {chance=.2,item="spidereggsack"},--蜘蛛卵
        {chance=.2,item="horn"},--牛角
        {chance=.2,item="dug_rock_avocado_bush"},--石果灌木丛
        {chance=.2,item="bullkelp_root"},--公牛海带
        {chance=.2,item="deer_antler"},--鹿角
        {chance=.2,item="singingshell_octave3"},--中音贝壳钟
        {chance=.2,item="singingshell_octave4"},--低音贝壳钟
        {chance=.2,item="singingshell_octave5"},--高音贝壳钟
        {chance=.2,item="waterplant_planter"},--海芽插穗
        {chance=.2,item="messagebottleempty"},--空瓶子
        {chance=.15,item="soil_amender"},--催长剂
        {chance=.1,item="soil_amender_fermented"},--发酵的催长剂
--稀有资源
        {chance=.2,item="thulecite"},--铥矿
        {chance=.2,item="goose_feather"},--鹿鸭羽毛
        {chance=.2,item="dug_trap_starfish"},--海星陷阱
        {chance=.08,item="lureplantbulb"},--食人花种子
        {chance=.08,item="moonrockcrater"},--带孔月石
        {chance=.07,item="bluegem"},--蓝宝石
        {chance=.07,item="redgem"},--红宝石
        {chance=.05,item="walrus_tusk"},--象牙
        {chance=.05,item="rock_avocado_fruit_sprout"},--发芽的石果
        {chance=.05,item="sunkenchest"},--沉底箱子
        {chance=.05,item="messagebottle"},--瓶中信
        {chance=.05,item="gnarwail_horn"},--独角鲸的角
        {chance=.05,item="purplegem"},--紫宝石
        {chance=.05,item="moonglass_charged"},--充能月亮碎片
        {chance=.03,item="orangegem"},--橙宝石
        {chance=.03,item="yellowgem"},--黄宝石
        {chance=.03,item="lavae_cocoon"},--冰冻的熔岩幼虫
        {chance=.03,item="dragon_scales"},--蜻蜓鳞片
        {chance=.03,item="moonstorm_static_item"},--约束静电
        {chance=.02,item="greengem"},--绿宝石
        {chance=.02,item="malbatross_feathered_weave"},--羽毛帆布
        {chance=.02,item="deerclops_eyeball"},--巨鹿眼球
        {chance=.02,item="bearger_fur"},--熊皮
        {chance=.01,item="minotaurhorn"},--远古守护者角
        {chance=.01,item="shroom_skin"},--蛤蟆皮
        {chance=.01,item="shadowheart"},--暗影之心
        {chance=.01,item="klaussackkey"},--克劳斯钥匙
        {chance=.01,item="malbatross_beak"},--邪天翁的喙
--基础食物
        {chance=25,item="seeds"},--种子
        {chance=20,item="berries"},--浆果
        {chance=10,item="red_cap"},--红蘑菇
        {chance=10,item="carrot"},--胡萝卜
        {chance=10,item="berries_juicy"},--多汁浆果
        {chance=9,item="blue_cap"},--蓝蘑菇
        {chance=8,item="butterflywings"},--蝴蝶翅膀
        {chance=8,item="green_cap"},--绿蘑菇
--高级食物
        {chance=4,item="monstermeat"},--怪物肉
        {chance=2,item="smallmeat"},--小肉
        {chance=2,item="cutlichen"},--苔藓
        {chance=1.8,item="drumstick"},--鸡腿
        {chance=1.8,item="batwing"},--蝙蝠翅膀
        {chance=1.5,item="honey"},--蜂蜜
        {chance=1.5,item="bird_egg"},--鸡蛋
        {chance=1.5,item="froglegs"},--蛙腿
        {chance=1.5,item="fishmeat_small"},--小鱼肉
        {chance=1.5,item="plantmeat"},--食人花肉
        {chance=1.2,item="rock_avocado_fruit_ripe"},--裂开的石果
        {chance=1.2,item="pumpkin"},--南瓜
        {chance=1.2,item="pomegranate"},--石榴
        {chance=1.2,item="corn"},--玉米
        {chance=1.2,item="eggplant"},--茄子
        {chance=1.2,item="potato"},--土豆
        {chance=1.2,item="kelp"},--海带
        {chance=1.2,item="wormlight_lesser"},--小发光浆果
        {chance=1,item="pumpkin_seeds"},--南瓜种子
        {chance=1,item="pomegranate_seeds"},--石榴种子
        {chance=1,item="corn_seeds"},--玉米种子
        {chance=1,item="durian_seeds"},--榴莲种子
        {chance=1,item="eggplant_seeds"},--茄子种子
        {chance=1,item="watermelon_seeds"},--西瓜种子
        {chance=1,item="carrot_seeds"},--胡萝卜种子
        {chance=1,item="durian"},--榴莲
        {chance=1,item="meat"},--大肉
        {chance=1,item="tomato"},--番茄
        {chance=1,item="forgetmelots"},--必忘我
        {chance=.8,item="cactus_meat"},--仙人掌肉
        {chance=.8,item="fishmeat"},--鱼肉
        {chance=.8,item="tallbirdegg"},--高鸟蛋
        {chance=.8,item="moonbutterflywings"},--月娥翅膀
        {chance=.8,item="wobster_sheller_dead"},--死龙虾
        {chance=.8,item="batnose"},--蝙蝠鼻子
        {chance=.8,item="tillweed"},--犁地草
        {chance=.75,item="cave_banana"},--洞穴香蕉
        {chance=.75,item="eel"},--鳗鱼
        {chance=.7,item="trunk_summer"},--夏象鼻
        {chance=.6,item="wormlight"},--发光浆果
        {chance=.5,item="asparagus_seeds"},--芦笋种子
        {chance=.5,item="potato_seeds"},--土豆种子
        {chance=.5,item="tomato_seeds"},--番茄种子
        {chance=.5,item="watermelon"},--西瓜
        {chance=.5,item="onion"},--洋葱
        {chance=.5,item="asparagus"},--芦笋
        {chance=.5,item="trunk_winter"},--冬象鼻
        {chance=.5,item="barnacle"},--藤壶
        {chance=.5,item="firenettles"},--烈火荨麻
        {chance=.4,item="dragonfruit_seeds"},--火龙果种子
        {chance=.4,item="garlic_seeds"},--大蒜种子
        {chance=.4,item="onion_seeds"},--洋葱种子
        {chance=.4,item="pepper_seeds"},--辣椒种子
        {chance=.4,item="dragonfruit"},--火龙果
        {chance=.4,item="pepper"},--辣椒
        {chance=.4,item="garlic"},--大蒜
        {chance=.35,item="cactus_flower"},--仙人掌花
        {chance=.35,item="moon_cap"},--月亮蘑菇
        {chance=.25,item="goatmilk"},--羊奶
        {chance=.25,item="carrot_oversized"},--巨型胡萝卜
        {chance=.25,item="corn_oversized"},--巨型玉米
        {chance=.25,item="tomato_oversized"},--巨型番茄
        {chance=.25,item="potato_oversized"},--巨型土豆
        {chance=.2,item="butter"},--黄油
        {chance=.2,item="royal_jelly"},--蜂王浆
        {chance=.2,item="pumpkin_oversized"},--巨型南瓜
        {chance=.2,item="eggplant_oversized"},--巨型茄子
        {chance=.2,item="watermelon_oversized"},--巨型西瓜
        {chance=.2,item="asparagus_oversized"},--巨型芦笋
        {chance=.15,item="refined_dust"},--精炼粉尘
        {chance=.15,item="durian_oversized"},--巨型榴莲
        {chance=.15,item="pomegranate_oversized"},--巨型石榴
        {chance=.15,item="dragonfruit_oversized"},--巨型火龙果
        {chance=.15,item="onion_oversized"},--巨型洋葱
        {chance=.15,item="garlic_oversized"},--巨型大蒜
        {chance=.15,item="pepper_oversized"},--巨型辣椒
        {chance=.1,item="mandrake"},--曼德拉草
--各种蓝图
		{chance=.8,item="TOOLS_blueprint"},--工具蓝图
		{chance=.8,item="LIGHT_blueprint"},--照明蓝图
		{chance=.8,item="SURVIVAL_blueprint"},--生存蓝图
		{chance=.8,item="FARM_blueprint"},--食物蓝图
		{chance=.8,item="SCIENCE_blueprint"},--科技蓝图
		{chance=.8,item="WAR_blueprint"},--战斗蓝图
		{chance=.8,item="TOWN_blueprint"},--建筑蓝图
		{chance=.8,item="REFINE_blueprint"},--合成蓝图
		{chance=.8,item="MAGIC_blueprint"},--魔法蓝图
		{chance=.8,item="DRESS_blueprint"},--衣物蓝图
--基础工具
		{chance=4,item="torch"},--火炬
		{chance=2,item="axe"},--斧头
		{chance=2,item="pickaxe"},--鹤嘴锄
		{chance=2,item="trap"},--陷阱
		{chance=2,item="shovel"},--铲子
		{chance=2,item="hammer"},--锤子
		{chance=2,item="backpack"},--背包
		{chance=2,item="pitchfork"},--草叉
		{chance=2,item="razor"},--剃刀
		{chance=2,item="compass"},--指南针
		{chance=2,item="bedroll_straw"},--凉席
		{chance=2,item="farm_hoe"},--园艺锄
		{chance=2,item="wateringcan"},--喷壶
		{chance=2,item="farm_plow_item"},--耕地机
		{chance=1.5,item="grass_umbrella"},--普通花伞
--高级工具
		{chance=2,item="oar"},--桨
		{chance=1.5,item="sewing_tape"},--可靠的胶带
		{chance=1.2,item="umbrella"},--雨伞
		{chance=1.2,item="bugnet"},--捕虫网
		{chance=1.2,item="fishingrod"},--钓竿
		{chance=1.2,item="waterballoon"},--水球
		{chance=1.2,item="featherpencil"},--羽毛笔
		{chance=1,item="birdtrap"},--捕鸟陷阱
		{chance=1,item="oar_driftwood"},--浮木桨
		{chance=1,item="heatrock"},--热能石
		{chance=1,item="boatpatch"},--船补丁
		{chance=.9,item="golden_farm_hoe"},--黄金园艺锄
		{chance=.9,item="goldenaxe"},--黄金斧头
		{chance=.9,item="goldenpickaxe"},--黄金鹤嘴锄
		{chance=.9,item="goldenshovel"},--黄金铲子
		{chance=.8,item="sewing_kit"},--针线包
		{chance=.8,item="minifan"},--旋转风车
		{chance=.8,item="healingsalve"},--治疗药膏
		{chance=.8,item="saddlehorn"},--取鞍器
		{chance=.8,item="bedroll_furry"},--毛皮铺盖
		{chance=.8,item="fertilizer"},--堆肥桶
		{chance=.8,item="seedpouch"},--种子背包
		{chance=.8,item="beef_bell"},--牛铃
		{chance=.75,item="piggyback"},--猪皮背包
		{chance=.7,item="minerhat"},--矿工帽
		{chance=.7,item="bathbomb"},--爆炸浴盐
		{chance=.7,item="oceanfishingbobber_ball"},--木球浮标
		{chance=.7,item="oceanfishingbobber_oval"},--硬物浮标
		{chance=.7,item="bundlewrap"},--捆绑包装纸
		{chance=.6,item="lantern"},--提灯
		{chance=.6,item="boat_item"},--圆船套件
		{chance=.6,item="bandage"},--蜂蜜药膏
		{chance=.6,item="anchor_item"},--锚套装
		{chance=.6,item="steeringwheel_item"},--方向舵套装
		{chance=.6,item="mast_item"},--桅杆
		{chance=.6,item="oceanfishingbobber_crow"},--黑羽浮标
		{chance=.6,item="oceanfishingbobber_robin"},--红羽浮标
		{chance=.6,item="mastupgrade_lamp_item"},--甲板照明灯
		{chance=.6,item="mastupgrade_lightningrod_item"},--避雷导线
		{chance=.5,item="saddle_basic"},--牛鞍
		{chance=.5,item="lifeinjector"},--强心针
		{chance=.5,item="molehat"},--鼹鼠帽
		{chance=.5,item="pocket_scale"},--弹簧秤
		{chance=.5,item="spicepack"},--厨师包
		{chance=.5,item="moonglassaxe"},--月晶斧
		{chance=.5,item="oceanfishingbobber_robin_winter"},--蔚蓝羽浮标
		{chance=.5,item="tacklecontainer"},--钓鱼箱
		{chance=.5,item="plantregistryhat"},--耕作先驱帽
		{chance=.5,item="tillweedsalve"},--犁地草药膏
		{chance=.4,item="oceanfishingbobber_canary"},--金羽浮标
		{chance=.4,item="reskin_tool"},--魔法扫把
		{chance=.4,item="oceanfishingbobber_goose"},--鹅羽浮标
		{chance=.4,item="oceanfishingbobber_malbatross"},--邪天翁羽浮标
--稀有工具
		{chance=.1,item="chum"},--鱼食
		{chance=.1,item="multitool_axe_pickaxe"},--多功能工具
		{chance=.08,item="saddle_race"},--薄弱牛鞍
		{chance=.05,item="supertacklecontainer"},--超级钓鱼箱
		{chance=.05,item="brush"},--洗刷
		{chance=.05,item="featherfan"},--羽毛扇
		{chance=.05,item="nutrientsgoggleshat"},--高级耕作先驱帽
		{chance=.04,item="saddle_war"},--战争牛鞍
		{chance=.03,item="moonrockidol"},--月石图腾
		{chance=.02,item="icepack"},--保鲜背包
		{chance=.01,item="krampus_sack"},--坎普斯背包
		{chance=.01,item="mast_malbatross_item"},--飞翼风帆
		{chance=.01,item="premiumwateringcan"},--鸟嘴喷壶
		{chance=.01,item="alterguardianhatshard"},--启迪之冠碎片
--基础装备
		{chance=3,item="spear"},--长矛
		{chance=3,item="armorgrass"},--草甲
		{chance=3,item="flowerhat"},--花环
		{chance=3,item="strawhat"},--草帽
		{chance=2,item="armorwood"},--木甲
		{chance=2,item="footballhat"},--橄榄球头盔
		{chance=1.5,item="bushhat"},--灌木帽
		{chance=1.5,item="watermelonhat"},--西瓜帽
		{chance=1.5,item="mermhat"},--鱼人帽
		{chance=1.5,item="cookiecutterhat"},--饼干切割机帽子
		{chance=1.3,item="featherhat"},--羽毛帽
--高级装备
		{chance=1.5,item="icehat"},--冰块帽
		{chance=1.5,item="blowdart_sleep"},--催眠吹箭
		{chance=1.5,item="blowdart_fire"},--火焰吹箭
		{chance=1.4,item="sweatervest"},--格子背心
		{chance=1.4,item="reflectivevest"},--清凉夏装
		{chance=1.4,item="hawaiianshirt"},--花衬衫
		{chance=1.4,item="tophat"},--绅士高帽
		{chance=1.4,item="catcoonhat"},--浣熊猫帽子
		{chance=1.4,item="hambat"},--火腿棍
		{chance=1.4,item="blowdart_pipe"},--吹箭
		{chance=1.4,item="rainhat"},--防雨帽
		{chance=1.4,item="spear_wathgrithr"},--战斗长矛
		{chance=1.3,item="raincoat"},--雨衣
		{chance=1.3,item="kelphat"},--海带花冠
		{chance=1.3,item="tentaclespike"},--狼牙棒
		{chance=1.3,item="trap_teeth"},--犬牙陷阱
		{chance=1.3,item="winterhat"},--冬帽
		{chance=1.3,item="beehat"},--养蜂帽
		{chance=1.3,item="wathgrithrhat"},--战斗头盔
		{chance=1.2,item="earmuffshat"},--小兔耳罩
		{chance=1.2,item="armorslurper"},--饥饿腰带
		{chance=1.2,item="blowdart_yellow"},--闪电吹箭
		{chance=1.1,item="trunkvest_summer"},--保暖小背心
		{chance=1,item="whip"},--三尾猫鞭
		{chance=1,item="boomerang"},--回旋镖
		{chance=1,item="armormarble"},--大理石甲
		{chance=.8,item="beemine"},--蜜蜂地雷
		{chance=.8,item="beefalohat"},--牛角帽
		{chance=.7,item="glasscutter"},--月晶砍刀
		{chance=.6,item="nightstick"},--晨星
--稀有装备
		{chance=.1,item="goggleshat"},--时髦目镜
		{chance=.1,item="trunkvest_winter"},--寒冬背心
		{chance=.1,item="red_mushroomhat"},--红蘑菇帽
		{chance=.1,item="green_mushroomhat"},--绿蘑菇帽
		{chance=.1,item="blue_mushroomhat"},--蓝蘑菇帽
		{chance=.1,item="blueamulet"},--寒冰护符
		{chance=.09,item="armor_sanity"},--暗影护甲
		{chance=.08,item="staff_tornado"},--天气棒
		{chance=.08,item="nightsword"},--暗夜剑
		{chance=.08,item="batbat"},--蝙蝠棒
		{chance=.08,item="firestaff"},--火焰法杖
		{chance=.08,item="icestaff"},--冰魔杖
		{chance=.08,item="armor_bramble"},--荆棘甲
		{chance=.08,item="purpleamulet"},--噩梦护符
		{chance=.08,item="slurtlehat"},--蜗牛帽
		{chance=.07,item="deserthat"},--沙漠目镜
		{chance=.07,item="amulet"},--重生护符
		{chance=.07,item="sleepbomb"},--催眠包
		{chance=.06,item="moonstorm_goggleshat"},--天文护目镜
		{chance=.06,item="spiderhat"},--蜘蛛帽
		{chance=.05,item="armordragonfly"},--鳞甲
		{chance=.05,item="yellowstaff"},--唤星者法杖
		{chance=.05,item="ruinshat"},--图勒皇冠
		{chance=.05,item="armorruins"},--图勒护甲
		{chance=.05,item="ruins_bat"},--图勒棒
		{chance=.05,item="trap_bramble"},--荆棘陷阱
		{chance=.05,item="armorsnurtleshell"},--蜗牛盔甲
		{chance=.05,item="cane"},--步行手杖
		{chance=.05,item="telestaff"},--传送魔杖
		{chance=.05,item="yellowamulet"},--魔光护符
		{chance=.05,item="walrushat"},--海象帽
		{chance=.04,item="orangeamulet"},--懒人强盗
		{chance=.03,item="beargervest"},--熊皮背心
		{chance=.03,item="eyebrellahat"},--眼球伞
		{chance=.03,item="orangestaff"},--瞬移魔杖
		{chance=.03,item="opalstaff"},--唤月法杖
		{chance=.02,item="panflute"},--排箫
		{chance=.02,item="greenamulet"},--建造护符
		{chance=.02,item="greenstaff"},--解构魔杖
		{chance=.02,item="hivehat"},--蜂后头冠
		{chance=.02,item="trident"},--三叉戟
		{chance=.01,item="eyeturret_item"},--眼球塔
		{chance=.01,item="armorskeleton"},--远古骨甲
		{chance=.01,item="skeletonhat"},--骨制头盔
		{chance=.01,item="thurible"},--暗影香炉
		{chance=.005,item="alterguardianhat"},--启迪之冠
--基础生物
		{chance=1.2,item="robin"},--红鸟
		{chance=1.2,item="crow"},--乌鸦
		{chance=1,item="butterfly"},--蝴蝶
		{chance=1,item="spider",aggro=true},--蜘蛛
		{chance=1,item="killerbee",aggro=true},--杀人蜂
		{chance=1,item="frog",aggro=true},--青蛙
		{chance=1,item="bee",aggro=true},--蜜蜂
		{chance=1,item="mosquito",aggro=true},--蚊子
		{chance=1,item="rabbit"},--兔子
		{chance=1,item="mole"},--鼹鼠
		{chance=1,item="perd"},--火鸡
		{chance=1,item="grassgekko"},--草蜥蜴
		{chance=1,item="buzzard",aggro=true},--秃鹫
		{chance=.8,item="catcoon",aggro=true},--浣猫
		{chance=.8,item="fireflies"},--萤火虫
		{chance=.8,item="carrat"},--胡萝卜鼠
		{chance=.8,item="pondfish"},--淡水鱼
		{chance=.7,item="moonbutterfly"},-- 月蛾
		{chance=.7,item="robin_winter"},--雪雀
		{chance=.6,item="lightflier"},--荧光虫
		{chance=.5,item="pondeel"},--活鳗鱼
		{chance=.4,item="canary"},--金丝雀
		{chance=.2,item="bird_mutant"},--月盲乌鸦
		{chance=.2,item="bird_mutant_spitter"},--奇行鸟
--高级生物
		{chance=1,item="hound",aggro=true},--猎狗
		{chance=1,item="bat",aggro=true},--蝙蝠
		{chance=.8,item="pigman",aggro=true},--猪人
		{chance=.8,item="crawlinghorror",aggro=true},--暗影爬行怪
		{chance=.75,item="spider_moon",aggro=true},--月岛蜘蛛
		{chance=.75,item="spider_hider",aggro=true},--洞穴蜘蛛
		{chance=.75,item="spider_spitter",aggro=true},--喷吐蜘蛛
		{chance=.75,item="spider_dropper",aggro=true},--悬挂蜘蛛
		{chance=.7,item="firehound",aggro=true},--火狗
		{chance=.7,item="fruitfly"},--果蝇
		{chance=.7,item="icehound",aggro=true},--冰狗
		{chance=.7,item="spider_warrior",aggro=true},--蜘蛛战士
		{chance=.6,item="merm",aggro=true},--鱼人
		{chance=.6,item="terrorbeak",aggro=true},--尖嘴暗影怪
		{chance=.6,item="slurtle",aggro=true},--尖壳蜗牛
		{chance=.6,item="penguin",aggro=true},--企鹅
		{chance=.5,item="pigguard",aggro=true},--猪人守卫
		{chance=.5,item="mutatedhound",aggro=true},--僵尸狗
		{chance=.5,item="koalefant_summer",aggro=true},--夏象
		{chance=.5,item="squid",aggro=true},--鱿鱼
		{chance=.45,item="molebat",aggro=true},--鼹鼠蝙蝠
		{chance=.4,item="beefalo",aggro=true},--牛
		{chance=.4,item="bunnyman",aggro=true},--兔人
		{chance=.4,item="tallbird",aggro=true},--高鸟
		{chance=.4,item="monkey",aggro=true},--猴子
		{chance=.4,item="rocky",aggro=true},--石虾
		{chance=.4,item="krampus",aggro=true},--坎普斯
		{chance=.4,item="deer",aggro=true},--无眼鹿
		{chance=.4,item="snurtle",aggro=true},--圆壳蜗牛
		{chance=.35,item="tentacle",aggro=true},--触手
		{chance=.3,item="worm",aggro=true},--洞穴蠕虫
		{chance=.3,item="mutated_penguin",aggro=true},--月岛企鹅
		{chance=.3,item="knight",aggro=true},--发条骑士
		{chance=.3,item="bishop",aggro=true},--发条主教
		{chance=.3,item="mushgnome",aggro=true},--蘑菇地精
		{chance=.25,item="lightninggoat",aggro=true},--闪电羊
		{chance=.25,item="koalefant_winter",aggro=true},--冬象
		{chance=.25,item="mermguard",aggro=true},--鱼人守卫
		{chance=.25,item="fruitdragon",aggro=true},--沙拉蝾螈
		{chance=.2,item="rook",aggro=true},--发条战车
		{chance=.2,item="mossling",aggro=true},--小鸭
		{chance=.2,item="walrus",aggro=true},--海象
		{chance=.15,item="knight_nightmare",aggro=true},--破损的发条骑士
		{chance=.15,item="bishop_nightmare",aggro=true},--破损的发条主教
		{chance=.1,item="oceanfish_medium_1_inv"},--泥鱼
		{chance=.1,item="oceanfish_medium_2_inv"},--斑鱼
		{chance=.1,item="oceanfish_medium_3_inv"},--浮夸狮子鱼
		{chance=.1,item="oceanfish_medium_4_inv"},--黑鲶鱼
		{chance=.1,item="oceanfish_small_2_inv"},--针鼻喷墨鱼
		{chance=.1,item="oceanfish_small_1_inv"},--小孔雀鱼
		{chance=.1,item="oceanfish_small_3_inv"},--小饵鱼
		{chance=.1,item="oceanfish_small_4_inv"},--三文鱼苗
		{chance=.1,item="oceanfish_medium_5_inv"},--玉米鳕鱼
		{chance=.1,item="oceanfish_small_5_inv"},--爆米花鱼
		{chance=.1,item="wobster_sheller_land"},--龙虾
		{chance=.1,item="little_walrus",aggro=true},--小海象
		{chance=.1,item="rook_nightmare",aggro=true},--破损的发条战车
		{chance=.1,item="wobster_moonglass_land"},--月光龙虾
		{chance=.02,item="oceanfish_medium_6_inv"},--花锦鲤
		{chance=.02,item="oceanfish_medium_7_inv"},--金锦鲤
--稀有生物
		{chance=.08,item="spiderqueen",aggro=true},--蜘蛛女王
		{chance=.08,item="leif",aggro=true},--树精
		{chance=.07,item="leif_sparse",aggro=true},--稀有树精
		{chance=.04,item="lordfruitfly",aggro=true},--果蝇王
		{chance=.05,item="warg",aggro=true},--座狼
		{chance=.05,item="spat",aggro=true},--钢羊
		{chance=.04,item="deer_red",aggro=true},--红宝石鹿
		{chance=.04,item="deer_blue",aggro=true},--蓝宝石鹿
		{chance=.03,item="moose",aggro=true},--鹿鸭
		{chance=.02,item="deerclops",aggro=true},--巨鹿
		{chance=.02,item="bearger",aggro=true},--熊大
		{chance=.015,item="shadow_rook",aggro=true},--暗影战车
		{chance=.015,item="shadow_knight",aggro=true},--暗影骑士
		{chance=.015,item="shadow_bishop",aggro=true},--暗影主教
		{chance=.01,item="oceanfish_medium_8_inv"},--冰鲷鱼
		{chance=.01,item="oceanfish_small_6_inv"},--比目鱼
		{chance=.01,item="oceanfish_small_7_inv"},--花朵金枪鱼
		{chance=.01,item="oceanfish_small_8_inv"},--炽热太阳鱼
		{chance=.008,item="dragonfly",aggro=true},--龙蝇
		{chance=.008,item="beequeen",aggro=true},--蜂后
		{chance=100,item="klaus",aggro=false},--克劳斯
		{chance=.008,item="antlion",aggro=true},--蚁狮
		{chance=.008,item="malbatross",aggro=true},--邪天翁
		{chance=.007,item="stalker",aggro=true},--召唤之骨
		{chance=.007,item="stalker_forest",aggro=true},--森林召唤之骨
		{chance=.007,item="minotaur",aggro=true},--远古守护者
		{chance=.007,item="toadstool",aggro=true},--蘑菇蛤
		{chance=.004,item="stalker_atrium",aggro=true},--暗影编制者
		{chance=.001,item="alterguardian_phase1",aggro=true},--天体英雄1阶段
		{chance=.001,item="alterguardian_phase2",aggro=true},--天体英雄2阶段
		{chance=.001,item="alterguardian_phase3",aggro=true},--天体英雄3阶段
    }

    local chessunlocks = TheWorld.components.chessunlocks
    if chessunlocks ~= nil then
        for i, v in ipairs(CHESS_LOOT) do
            if not chessunlocks:IsLocked(v) then
                table.insert(possible_loot, { chance = .1, item = v })
            end
        end
    end

    local totalchance = 0
    for m, n in ipairs(possible_loot) do
        totalchance = totalchance + n.chance
    end

    inst.loot = {}
    inst.lootaggro = {}
    local next_loot = nil
    local next_aggro = nil
    local next_chance = nil
    local num_loots = 3
    while num_loots > 0 do
        next_chance = math.random()*totalchance
        next_loot = nil
        next_aggro = nil
        for m, n in ipairs(possible_loot) do
            next_chance = next_chance - n.chance
            if next_chance <= 0 then
                next_loot = n.item
                if n.aggro then next_aggro = true end
                break
            end
        end
        if next_loot ~= nil then
            table.insert(inst.loot, next_loot)
            if next_aggro then 
                table.insert(inst.lootaggro, true)
            else
                table.insert(inst.lootaggro, false)
            end
            num_loots = num_loots - 1
        end
    end
end

local function DoDirectionChange(inst, data)

    if not inst.entity:IsAwake() then return end

    if data and data.angle and data.velocity and inst.components.blowinwind then
        if inst.angle == nil then
            inst.angle = math.clamp(GetRandomWithVariance(data.angle, ANGLE_VARIANCE), 0, 360)
            inst.components.blowinwind:Start(inst.angle, data.velocity)
        else
            inst.angle = math.clamp(GetRandomWithVariance(data.angle, ANGLE_VARIANCE), 0, 360)
            inst.components.blowinwind:ChangeDirection(inst.angle, data.velocity)
        end
    end
end

local function spawnash(inst)
    local x, y, z = inst.Transform:GetWorldPosition()

    local ash = SpawnPrefab("ash")
    ash.Transform:SetPosition(x, y, z)

    if inst.components.stackable ~= nil then
        ash.components.stackable.stacksize = math.min(ash.components.stackable.maxsize, inst.components.stackable.stacksize)
    end

    inst:PushEvent("detachchild")
    SpawnPrefab("tumbleweedbreakfx").Transform:SetPosition(x, y, z)
    inst:Remove()
end

local function onburnt(inst)
    inst:PushEvent("detachchild")
    inst:AddTag("burnt")

    inst.components.pickable.canbepicked = false
    inst.components.propagator:StopSpreading()

    inst.Physics:Stop()
    inst.components.blowinwind:Stop()
    inst:RemoveEventCallback("animover", startmoving)

    if inst.bouncepretask then
        inst.bouncepretask:Cancel()
        inst.bouncepretask = nil
    end
    if inst.bouncetask then
        inst.bouncetask:Cancel()
        inst.bouncetask = nil
    end
    if inst.restartmovementtask then
        inst.restartmovementtask:Cancel()
        inst.restartmovementtask = nil
    end
    if inst.bouncepst1 then
        inst.bouncepst1:Cancel()
        inst.bouncepst1 = nil
    end
    if inst.bouncepst2 then
        inst.bouncepst2:Cancel()
        inst.bouncepst2 = nil
    end

    inst.AnimState:PlayAnimation("move_pst")
    inst.AnimState:PushAnimation("idle")
    inst.bouncepst1 = inst:DoTaskInTime(4*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tumbleweed_bounce")
        inst.bouncepst1 = nil
    end)
    inst.bouncepst2 = inst:DoTaskInTime(10*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tumbleweed_bounce")
        inst.bouncepst2 = nil
    end)

    inst:DoTaskInTime(1.2, spawnash)
end

local function OnSave(inst, data)
    data.burnt = inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") or nil
end

local function OnLoad(inst, data)
    if data ~= nil and data.burnt then
        onburnt(inst)
    end
end

local function CancelRunningTasks(inst)
    if inst.bouncepretask then
       inst.bouncepretask:Cancel()
        inst.bouncepretask = nil
    end
    if inst.bouncetask then
        inst.bouncetask:Cancel()
        inst.bouncetask = nil
    end
    if inst.restartmovementtask then
        inst.restartmovementtask:Cancel()
        inst.restartmovementtask = nil
    end
    if inst.bouncepst1 then
       inst.bouncepst1:Cancel()
        inst.bouncepst1 = nil
    end
    if inst.bouncepst2 then
        inst.bouncepst2:Cancel()
        inst.bouncepst2 = nil
    end
end

local function OnEntityWake(inst)
    inst.AnimState:PlayAnimation("move_loop", true)
    inst.bouncepretask = inst:DoTaskInTime(10*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tumbleweed_bounce")
        inst.bouncetask = inst:DoPeriodicTask(24*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tumbleweed_bounce")
            CheckGround(inst)
        end)
    end)
end

local function OnLongAction(inst)
    inst.Physics:Stop()
    inst.components.blowinwind:Stop()
    inst:RemoveEventCallback("animover", startmoving)

    CancelRunningTasks(inst)

    inst.AnimState:PlayAnimation("move_pst")
    inst.bouncepst1 = inst:DoTaskInTime(4*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tumbleweed_bounce")
        inst.bouncepst1 = nil
    end)
    inst.bouncepst2 = inst:DoTaskInTime(10*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tumbleweed_bounce")
        inst.bouncepst2 = nil
    end)
    inst.AnimState:PushAnimation("idle", true)
    inst.restartmovementtask = inst:DoTaskInTime(math.random(2,6), function(inst)
        if inst and inst.components.blowinwind then
            inst.AnimState:PlayAnimation("move_pre")
            inst.restartmovementtask = nil
            inst:ListenForEvent("animover", startmoving)
        end
    end)
end

local function burntfxfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBuild("tumbleweed")
    inst.AnimState:SetBank("tumbleweed")
    inst.AnimState:PlayAnimation("break")

    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst:ListenForEvent("animover", inst.Remove)
    -- In case we're off screen and animation is asleep
    inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + FRAMES, inst.Remove)

    return inst
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()
    inst.DynamicShadow:SetSize(1.7, .8)

    inst.AnimState:SetBuild("tumbleweed")
    inst.AnimState:SetBank("tumbleweed")
    inst.AnimState:PlayAnimation("move_loop", true)

    MakeCharacterPhysics(inst, .5, 1)
    MakeDragonflyBait(inst, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor:SetTriggersCreep(false)

    inst:AddComponent("blowinwind")
    inst.components.blowinwind.soundPath = "dontstarve_DLC001/common/tumbleweed_roll"
    inst.components.blowinwind.soundName = "tumbleweed_roll"
    inst.components.blowinwind.soundParameter = "speed"
    inst.angle = (TheWorld and TheWorld.components.worldwind) and TheWorld.components.worldwind:GetWindAngle() or nil
    inst:ListenForEvent("windchange", function(world, data)
        DoDirectionChange(inst, data)
    end, TheWorld)
    if inst.angle ~= nil then
        inst.angle = math.clamp(GetRandomWithVariance(inst.angle, ANGLE_VARIANCE), 0, 360)
        inst.components.blowinwind:Start(inst.angle)
    else
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tumbleweed_roll", "tumbleweed_roll")
    end

    ---local color = 0.5 + math.random() * 0.5
    ---inst.AnimState:SetMultColour(color, color, color, 1)

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetOnPlayerNear(onplayerprox)
    inst.components.playerprox:SetDist(5,10)

    --inst:AddComponent("lootdropper")

    inst:AddComponent("inspectable")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/harvest_sticks"
    inst.components.pickable.onpickedfn = onpickup
    inst.components.pickable.canbepicked = true

    inst:ListenForEvent("startlongaction", OnLongAction)

    MakeLoot(inst)

    inst:AddComponent("burnable")
    inst.components.burnable:SetFXLevel(2)
    inst.components.burnable:AddBurnFX("character_fire", Vector3(.1, 0, .1), "swap_fire")
    inst.components.burnable.canlight = true
    inst.components.burnable:SetOnBurntFn(onburnt)
    inst.components.burnable:SetBurnTime(10)

    MakeSmallPropagator(inst)
    inst.components.propagator.flashpoint = 5 + math.random()*3
    inst.components.propagator.propagaterange = 5

    inst.OnEntityWake = OnEntityWake
    inst.OnEntitySleep = CancelRunningTasks
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        if math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
            onpickup(inst, nil)
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
        end
        return true
    end)

    return inst
end

return Prefab("tumbleweed", fn, assets, prefabs),
    Prefab("tumbleweedbreakfx", burntfxfn, assets)

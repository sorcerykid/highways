minetest.register_node("highways:junglewood", {
	description = "Hardened Jungle Wood",
	tiles = {"default_junglewood.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("highways:maple_wood", {
	description = "Hardened Maple Wood",
	tiles = {"default_maple_wood.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("highways:stonebrick", {
	description = "Hardened Stone Brick",
	tiles = {"default_stone_brick.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

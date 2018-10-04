--------------------------------------------------------
-- Minetest :: Highways Mod v1.0 (highways)
--
-- See README.txt for licensing and release notes.
-- Copyright (c) 2018-2020, Leslie E. Krause
--
-- ./games/minetest_game/mods/highways/init.lua
--------------------------------------------------------

-- Parameters

local PATH_DESCENT = 4		-- maximum rise
local PATH_ASCENT = 12		-- minimum rise
local PATH_CEILING = 4		-- tunnel height
local DEBUG = false -- Print generation time

-- Mapgen v7 noises

-- 2D noise for alt terrain

local np_alt = {
	offset = 4,
	scale = 15,
	spread = {x = 500, y = 500, z = 500},
	seed = 5934,
	octaves = 5,
	persist = 0.6,
	lacunarity = 2,
}

-- 2D noise for height select

local np_select = {
	offset = -0.5,
	scale = 6,
	spread = {x = 500, y = 500, z = 500},
	seed = 4213,
	octaves = 4,
	persist = 0.69,
	lacunarity = 2,
}

-- Mod noises

-- 2D noise for patha

local np_patha = {
	offset = 0,
	scale = 1,
	spread = {x = 1024, y = 1024, z = 1024},
	seed = 11711,
	octaves = 3,
	persist = 0.4,
	lacunarity = 2.0,
}

-- 2D noise for pathb

local np_pathb = {
	offset = 0,
	scale = 1,
	spread = {x = 2048, y = 2048, z = 2048},
	seed = -8017,
	octaves = 4,
	persist = 0.4,
	lacunarity = 2.0,
}

-- 2D noise for pathc

local np_pathc = {
	offset = 0,
	scale = 1,
	spread = {x = 4096, y = 4096, z = 4096},
	seed = 300707,
	octaves = 5,
	persist = 0.4,
	lacunarity = 2.0,
}

-- 2D noise for pathd

local np_pathd = {
	offset = 0,
	scale = 1,
	spread = {x = 8192, y = 8192, z = 8192},
	seed = -80033,
	octaves = 6,
	persist = 0.4,
	lacunarity = 2.0,
}

-- Do files

dofile(minetest.get_modpath("highways") .. "/nodes.lua")

-- Constants

local c_wood    = minetest.get_content_id("highways:junglewood")
local c_column  = minetest.get_content_id("highways:maple_wood")
local c_stonebrick        = minetest.get_content_id("highways:stonebrick")

local c_air          = minetest.CONTENT_AIR
local c_ignore       = minetest.CONTENT_IGNORE
local c_stone        = minetest.get_content_id("default:stone")

-- Initialise noise objects to nil

local nobj_alt = nil
local nobj_select = nil
local nobj_patha = nil
local nobj_pathb = nil
local nobj_pathc = nil
local nobj_pathd = nil


-- Localise noise buffers

local nbuf_alt = {}
local nbuf_select = {}
local nbuf_patha = {}
local nbuf_pathb = {}
local nbuf_pathc = {}
local nbuf_pathd = {}

-- Localise data buffer

local dbuf = {}

-- On generated function

minetest.register_on_generated(function(minp, maxp, seed)
	if minp.y > 0 or maxp.y < 0 then
		return
	end

	local t1 = os.clock()
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z

	local sidelen = x1 - x0 + 1
	local emerlen = sidelen + 32
	local overlen = sidelen + 5
	local chulens = {x = overlen, y = overlen, z = 1}
	local minpos  = {x = x0 - 3, y = z0 - 3}

	nobj_alt    = nobj_alt    or minetest.get_perlin_map(np_alt, chulens)
	nobj_select = nobj_select or minetest.get_perlin_map(np_select, chulens)
	nobj_patha  = nobj_patha  or minetest.get_perlin_map(np_patha,  chulens)
	nobj_pathb  = nobj_pathb  or minetest.get_perlin_map(np_pathb,  chulens)
	nobj_pathc  = nobj_pathc  or minetest.get_perlin_map(np_pathc,  chulens)
	nobj_pathd  = nobj_pathd  or minetest.get_perlin_map(np_pathd,  chulens)
	
	local nvals_alt    = nobj_alt:get2dMap_flat(minpos, nbuf_alt)
	local nvals_select = nobj_select:get2dMap_flat(minpos, nbuf_select)
	local nvals_patha  = nobj_patha :get2dMap_flat(minpos, nbuf_patha)
	local nvals_pathb  = nobj_pathb :get2dMap_flat(minpos, nbuf_pathb)
	local nvals_pathc  = nobj_pathc :get2dMap_flat(minpos, nbuf_pathc)
	local nvals_pathd  = nobj_pathd :get2dMap_flat(minpos, nbuf_pathd)
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
	local data = vm:get_data(dbuf)

	local ni = 1
	for z = z0 - 3, z1 + 2 do
		local n_xprepatha = nil
		local n_xprepathb = nil
		local n_xprepathc = nil
		local n_xprepathd = nil
		-- x0 - 3, z0 - 3 is to setup initial values of 'xprepath_', 'zprepath_'
		for x = x0 - 3, x1 + 2 do
			local n_patha = nvals_patha[ni]
			local n_zprepatha = nvals_patha[(ni - overlen)]
			local n_pathb = nvals_pathb[ni]
			local n_zprepathb = nvals_pathb[(ni - overlen)]
			local n_pathc = nvals_pathc[ni]
			local n_zprepathc = nvals_pathc[(ni - overlen)]
			local n_pathd = nvals_pathd[ni]
			local n_zprepathd = nvals_pathd[(ni - overlen)]

			if x >= x0 - 2 and z >= z0 - 2 then

				local n_select = nvals_select[ni]
				local n_alt = nvals_alt[ni]
				if n_alt < PATH_DESCENT then		-- gradual rise over water
					n_alt = PATH_DESCENT - n_alt / 2
				end
				local pathy = math.min( PATH_ASCENT, math.max( PATH_DESCENT, math.floor( n_select / 2 + 8.5 ), math.ceil( n_alt + 0.5 ) ) )

				if (n_patha >= 0 and n_xprepatha < 0) -- detect sign change of noise
						or (n_patha < 0 and n_xprepatha >= 0)
						or (n_patha >= 0 and n_zprepatha < 0)
						or (n_patha < 0 and n_zprepatha >= 0)

						or (n_pathb >= 0 and n_xprepathb < 0)
						or (n_pathb < 0 and n_xprepathb >= 0)
						or (n_pathb >= 0 and n_zprepathb < 0)
						or (n_pathb < 0 and n_zprepathb >= 0)

						or (n_pathc >= 0 and n_xprepathc < 0)
						or (n_pathc < 0 and n_xprepathc >= 0)
						or (n_pathc >= 0 and n_zprepathc < 0)
						or (n_pathc < 0 and n_zprepathc >= 0)

						or (n_pathd >= 0 and n_xprepathd < 0)
						or (n_pathd < 0 and n_xprepathd >= 0)
						or (n_pathd >= 0 and n_zprepathd < 0)
						or (n_pathd < 0 and n_zprepathd >= 0) then
					-- scan disk 5 nodes above path
					local tunnel = false
					local excatop
					for zz = z - 2, z + 2 do
						local vi = area:index(x - 2, pathy + PATH_CEILING, zz)
						for xx = x - 2, x + 2 do
							if data[vi] == c_stone then
								tunnel = true
							end
							vi = vi + 1
						end
					end
					if tunnel then
						excatop = pathy + PATH_CEILING
					else
						excatop = y1
					end
					-- bridge deck
					local vi = area:index(x, pathy, z)
					data[vi] = c_stonebrick

					for k = -1, 1 do
						local vi = area:index(x - 1, pathy, z + k)
						for i = -1, 1 do
							if data[vi] ~= c_stonebrick then
								data[vi] = c_wood
							end
							vi = vi + 1
						end
					end

					-- bridge beam
					local vi = area:index(x, pathy - 1, z)
					data[vi] = c_column
					local vi = area:index(x, pathy - 2, z)
					data[vi] = c_column

					-- bridge pylons
					if ( ni - 1 ) % 8 == 0 then
						local vi = area:index(x, pathy - 3, z)
						for y = pathy - 2, y0, -1 do
							if data[vi] == c_stone then
								break
							end
							data[vi] = c_column
							vi = vi - emerlen
						end
					end
					-- excavate above path
					for y = pathy + 1, excatop do
						for zz = z - 2, z + 2 do
							local vi = area:index(x - 2, y, zz)
							for xx = x - 2, x + 2 do
								if data[vi] ~= c_wood and data[vi] ~= c_stonebrick then
									data[vi] = c_air
								end
								vi = vi + 1
							end
						end
					end
				end
			end

			n_xprepatha = n_patha
			n_xprepathb = n_pathb
			n_xprepathc = n_pathc
			n_xprepathd = n_pathd
			ni = ni + 1
		end
	end
	
	vm:set_data(data)
	vm:set_lighting({day = 0, night = 0})
	vm:calc_lighting()
	vm:write_to_map(data)

	local chugent = math.ceil((os.clock() - t1) * 1000)
	if DEBUG then
		print ("[pathvalleys] Generate chunk " .. chugent .. " ms")
	end
end)

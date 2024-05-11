mneedata = {}
bindings = {}

--see mods/mnee/lists.lua for most of the internal key IDs

mneedata["mnee"] = {
	name = "mnee",
	desc = "$mnee_desc",
	is_dirty = false,
	is_advanced = true,
	is_locked = function(mod_id, jpads) return false end,
	is_hidden = function(mod_id, jpads) return false end,
	-- func = function( gui, uid, pic_x, pic_y, pic_z, data ) return uid end,
}
bindings["mnee"] = {
	menu = { --[ACTUAL BINDING ID]
		order_id = "a", --[SORTING ORDER]
		is_dirty = false, --[CONFLICT CHECKING MODE TOGGLE]
		is_advanced = true, --[ALLOW MULTIPLE KEYS DURING BINDING]
		allow_special = false, --[ALLOW BINDING SPECIAL KEYS WHEN IS IN SIMPLE BINDING MODE]
		is_locked = function(id_tbl, jpads) return true end, --[PREVENT REBINDING]
		is_hidden = function(id_tbl, jpads) return false end, --[HIDE FROM MENU]
		
		name = "$mnee_open", --[DISPLAYED NAME]
		desc = "$mnee_open_desc", --[DISPLAYED DESCRIPTION]
		
		jpad_type = "AIM", --[USER-ACCESSIBLE ANALOG STICK DEADZONE TYPE: AIM, MOTION, EXTRA]
		deadzone = 0.5, --[INTERNAL USER-INACCESSIBLE DEADZONE THAT IS ADDED ON TOP]
		
		keys = { --[DEFAULT BINDING KEYS]
			left_ctrl = 1, --number is just so the thing won't be nil
			m = 1,
		},
		keys_alt = { --[SECONDARY KEYS]
			right_ctrl = 1,
			m = 1,
		},
	},
	
	off = {
		order_id = "b",

		name = "$mnee_nope",
		desc = "$mnee_nope_desc",

		keys = {
			right_ctrl = 1,
			["keypad_-"] = 1,
		},
	},
	
	profile_change = {
		order_id = "c",

		name = "$mnee_profile",
		desc = "$mnee_profile_desc",

		keys = {
			right_ctrl = 1,
			["keypad_+"] = 1,
		},
	},
}
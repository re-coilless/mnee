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
	
	-- func = function( gui, uid, pic_x, pic_y, pic_z, data ) return uid end, --[MAIN MENU BINDING LIST COMPLETE OVERRIDE]
	-- on_changed = function( data ) end, --[REBINDING CALLBACK]
	-- on_reset = function( data ) end, --[SET TO DEFAULT CALLBACK] on_changed is called if nil
	-- on_jpad = function( data, jpad_id ) end, --[GAMEPAD SLOT CALLBACK] return true to set the slot to dummy
	-- on_setup = function( data, setup_id ) end, --[SETUP CHANGE CALLBACK]

	--[[
	setup_default = {
		btn = "NRM",
		name = "Normal",
		desc = "This table changes the UI part of the default setup mode.",
	},
	setup_modes = {
		{
			id = "test1",
			btn = "TST",
			name = "Test",
			desc = "Testing the setup modes.",
			binds = {
				menu = { ["8"] = 1, },
				off = {{ ["9"] = 1, }, { ["0"] = 1, }},
			},
		},
	}
	]]
}
bindings["mnee"] = {
	menu = { --[ACTUAL BINDING ID]
		order_id = "a", --[SORTING ORDER]
		is_dirty = false, --[CONFLICT CHECKING MODE TOGGLE]
		is_advanced = true, --[ALLOW MULTIPLE KEYS DURING BINDING]
		never_advanced = false, --[FORBID TO EVER BE REBINDED IN ADVANCED MODE]
		allow_special = false, --[ALLOW BINDING SPECIAL KEYS WHEN IS IN SIMPLE BINDING MODE]
		is_locked = function(id_tbl, jpads) return true end, --[PREVENT REBINDING]
		is_hidden = function(id_tbl, jpads) return false end, --[HIDE FROM MENU]
		
		name = "$mnee_open", --[DISPLAYED NAME]
		desc = "$mnee_open_desc", --[DISPLAYED DESCRIPTION]
		
		on_changed = function( data ) end, --[REBINDING CALLBACK]
		on_reset = function( data ) end, --[SET TO DEFAULT CALLBACK] on_changed is called if nil
		on_down = function( data, is_alt, is_jpad ) --[INPUT CALLBACK]
			return true --return-value override
		end,

		jpad_type = "AIM", --[USER-ACCESSIBLE ANALOG STICK DEADZONE TYPE: BUTTON, AIM, MOTION, EXTRA]
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
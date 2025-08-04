_MNEEDATA = {}
_BINDINGS = {}

--see mnee/lists.lua for most of the internal key IDs + gamepad binding examples

_MNEEDATA[ "mnee" ] = {
	order_id = 0,
	name = "M-Nee",
	desc = "$mnee_desc",
	is_advanced = true,
	is_locked = function( mod_id, jpads ) return false end,
	is_hidden = function( mod_id, jpads ) return false end,
	
	-- func = function( pic_x, pic_y, pic_z, data ) end, --[MAIN MENU BINDING LIST COMPLETE OVERRIDE]
	-- on_changed = function( data ) end, --[REBINDING CALLBACK]
	-- on_reset = function( data ) end, --[SET TO DEFAULT CALLBACK] on_changed is called if nil
	-- on_jpad = function( data, jpad_id ) end, --[GAMEPAD SLOT CALLBACK] return true to set the slot to dummy
	-- on_setup = function( data, setup_id ) end, --[SETUP CHANGE CALLBACK]
	
	-- setup_default = {
	-- 	btn = "NRM",
	-- 	name = "Normal",
	-- 	desc = "This table changes the UI part of the default setup mode.",
	-- },
	-- setup_modes = {
	-- 	{
	-- 		id = "test1",
	-- 		btn = "TST",
	-- 		name = "Test",
	-- 		desc = "Testing the setup modes.",
	-- 		binds = {
	-- 			menu = {["8"] = 1 },
	-- 			off = {
	-- 				{["9"] = 1 },
	-- 				{["0"] = 1 },
	-- 			},
	-- 		},
	-- 	},
	-- }
}

_BINDINGS[ "mnee" ] = {
	menu = { --[ACTUAL BINDING ID]
		order_id = "a", --[SORTING ORDER]
		is_clean = true, --[ONLY ACTIVATE WHEN PRESSED ALONE]
		is_advanced = true, --[ALLOW MULTIPLE KEYS DURING BINDING]
		never_advanced = false, --[FORBID TO EVER BE REBINDED IN ADVANCED MODE]
		is_weak = false, --[PREVENTS THE BIND FROM FIRING IF SPECIAL KEY IS PRESSED]
		allow_special = false, --[ALLOW BINDING SPECIAL KEYS WHEN IS IN SIMPLE BINDING MODE]
		split_modifiers = true, --[HANDLE LEFT AND RIGHT SPECIAL MODIFIER KEYS LIKE CTRL SEPARATELY]
		unify_numpad = false, --[VIEW NUMPAD KEYS THE SAME AS THEIR COUNTERPARTS ON THE MAIN KEYBOARD]
		is_locked = function( id_tbl, jpads ) return true end, --[PREVENT REBINDING]
		is_hidden = function( id_tbl, jpads ) return false end, --[HIDE FROM MENU]
		
		name = "$mnee_open", --[DISPLAYED NAME]
		desc = "$mnee_open_desc", --[DISPLAYED DESCRIPTION]
		
		on_changed = function( data ) end, --[REBINDING CALLBACK]
		on_reset = function( data ) end, --[SET TO DEFAULT CALLBACK] on_changed is called if nil
		on_down = function( data, is_alt, is_jpad ) --[INPUT CALLBACK]
			return true --return-value override
		end,

		jpad_type = "AIM", --[USER-ACCESSIBLE ANALOG STICK DEADZONE TYPE: BUTTON, AIM, MOTION, EXTRA]
		deadzone = 0.5, --[INTERNAL USER-INACCESSIBLE DEADZONE THAT IS ADDED ON TOP]
		
		keys = pen.t.unarray({ "left_ctrl", "m" }), --[DEFAULT BINDING KEYS]
		--keys_alt = pen.t.unarray({ "right_ctrl", "m" }), --[SECONDARY KEYS]
	},
	
	off = {
		order_id = "b",
		is_clean = true,
		
		name = "$mnee_nope",
		desc = "$mnee_nope_desc",

		keys = pen.t.unarray({ "right_ctrl", "keypad_-" }),
	},
	
	profile_change = {
		order_id = "c",
		is_clean = true,

		name = "$mnee_profile",
		desc = "$mnee_profile_desc",

		keys = pen.t.unarray({ "right_ctrl", "keypad_+" }),
	},
}

mneedata, bindings = _MNEEDATA, _BINDINGS
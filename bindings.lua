mneedata = {}
bindings = {}

--see mods/mnee/lists.lua for most of the key ids

--[[gamepad button list; [*] states the gamepad number; non-standard gamepads might be supported but extra buttons will not be listed here - check naming during rebinding

[*]gpd_y
[*]gpd_x
[*]gpd_a
[*]gpd_b

[*]gpd_r1
[*]gpd_r2
[*]gpd_r3
[*]gpd_l1
[*]gpd_l2
[*]gpd_l3

[*]gpd_up
[*]gpd_down
[*]gpd_left
[*]gpd_right

[*]gpd_select
[*]gpd_start

[*]gpd_btn_lh_+
[*]gpd_btn_lh_-
[*]gpd_btn_lv_+
[*]gpd_btn_lv_-
[*]gpd_btn_rh_+
[*]gpd_btn_rh_-
[*]gpd_btn_rv_+
[*]gpd_btn_rv_-

]]

mneedata["mnee"] = {
	name = "mnee",
	desc = "$mnee_desc",
	is_advanced = false,
	is_locked = function() return false end,
	is_hidden = function() return false end,
	-- func = function( gui, uid, pic_x, pic_y, pic_z, data ) return uid end,
}
bindings["mnee"] = {
	menu = { --[ACTUAL BINDING ID]
		order_id = "a", --[SORTING ORDER]
		is_locked = function() return true end, --[PREVENT REBINDING]
		is_hidden = function() return false end, --[HIDE FROM MENU]
		is_advanced = true, --[ALLOW MULTIPLE KEYS DURING BINDING]
		
		name = "$mnee_open", --[DISPLAYED NAME]
		desc = "$mnee_open_desc", --[DISPLAYED DESCRIPTION]
		
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
		is_advanced = true,

		name = "$mnee_nope",
		desc = "$mnee_nope_desc",

		keys = {
			left_ctrl = 1,
			["keypad_-"] = 1,
		},
	},
	
	profile_change = {
		order_id = "c",
		is_advanced = true,

		name = "$mnee_profile",
		desc = "$mnee_profile_desc",

		keys = {
			left_ctrl = 1,
			["keypad_+"] = 1,
		},
	},
}

--[[gamepad analog axis list; [*] states the gamepad number; non-standard gamepads might be supported but extra buttons will not be listed here - check naming after rebinding

[*]gpd_axis_lh
[*]gpd_axis_lv
[*]gpd_axis_rh
[*]gpd_axis_rv

bindings["example"] = {
	aa_stuff_1 = {
		is_locked = true,
		name = "Check This Out",
		desc = "You can have either proper analog input or a pair of absolute buttons. This one is generic.",
		keys = { "is_axis", "1gpd_axis_lh", },
	},
	aa_stuff_2 = {
		name = "Behold the Ultimate Power of Complete Input",
		desc = "And this one is extra fancy.",
		keys = { "is_axis", "keypad_+", "keypad_-", },
	},
}

]]
bindings = {}

--see data/scripts/debug/keycodes.lua for keyboard inputs

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

[*]gpd_right
[*]gpd_left
[*]gpd_down
[*]gpd_up

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

bindings["mnee"] = {
	aa_menu = { --[ACTUAL BINDING ID] "aa_" is needed to maintain alphabetical order, since that's how this table is being sorted
		name = "Open M-nee", --[DISPLAYED NAME]
		desc = "Will open this menu.", --[DISPLAYED DESCRIPTION]
		keys = { --[DEFAULT BINDING KEYS]
			left_ctrl = 1, --number is just so the thing won't be nil
			m = 1,
		},
	},
	
	ab_off = {
		name = "Disable M-nee",
		desc = "Will disable all the custom inputs.",
		keys = {
			left_ctrl = 1,
			["keypad_-"] = 1,
		},
	},
	
	ac_pfl_chng = {
		name = "Change Profile",
		desc = "Cycle through independed binding profiles.",
		keys = {
			left_ctrl = 1,
			["keypad_+"] = 1,
		},
	},
}

--[[gamepad axis list; [*] states the gamepad number; non-standard gamepads might be supported but extra buttons will not be listed here - check naming after rebinding

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
		keys = { "is_axis", "Key_KP_PLUS", "Key_KP_MINUS", },
	},
}

]]
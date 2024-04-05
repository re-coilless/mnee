local full_board = {
	"[NONE]",
	"[NONE]",
	"[NONE]",
	"a",
	"b",
	"c",
	"d",
	"e",
	"f",
	"g",
	"h",
	"i",
	"j",
	"k",
	"l",
	"m",
	"n",
	"o",
	"p",
	"q",
	"r",
	"s",
	"t",
	"u",
	"v",
	"w",
	"x",
	"y",
	"z",
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	"7",
	"8",
	"9",
	"0",
	"return",
	"escape",
	"backspace",
	"tab",
	"space",
	"-",
	"=",
	"[",
	"]",
	"\\",
	"#",
	";",
	"'",
	"`",
	",",
	".",
	"/",
	"capslock",
	"f1",
	"f2",
	"f3",
	"f4",
	"f5",
	"f6",
	"f7",
	"f8",
	"f9",
	"f10",
	"f11",
	"f12",
	"printscreen",
	"scrolllock",
	"pause",
	"insert",
	"home",
	"pageup",
	"delete",
	"end",
	"pagedown",
	"right",
	"left",
	"down",
	"up",
	"numlock",
	"keypad_/",
	"keypad_*",
	"keypad_-",
	"keypad_+",
	"keypad_enter",
	"keypad_1",
	"keypad_2",
	"keypad_3",
	"keypad_4",
	"keypad_5",
	"keypad_6",
	"keypad_7",
	"keypad_8",
	"keypad_9",
	"keypad_0",
	"keypad_.",
	"[NONE]", --"NONUSBACKSLASH",
	"[NONE]", --"APPLICATION",
	"[NONE]", --"POWER",
	"[NONE]", --"KP_EQUALS",
	"[NONE]", --"F13",
	"[NONE]", --"F14",
	"[NONE]", --"F15",
	"[NONE]", --"F16",
	"[NONE]", --"F17",
	"[NONE]", --"F18",
	"[NONE]", --"F19",
	"[NONE]", --"F20",
	"[NONE]", --"F21",
	"[NONE]", --"F22",
	"[NONE]", --"F23",
	"[NONE]", --"F24",
	"[NONE]", --"EXECUTE",
	"[NONE]", --"HELP",
	"[NONE]", --"MENU",
	"[NONE]", --"SELECT",
	"[NONE]", --"STOP",
	"[NONE]", --"AGAIN",
	"[NONE]", --"UNDO",
	"[NONE]", --"CUT",
	"[NONE]", --"COPY",
	"[NONE]", --"PASTE",
	"[NONE]", --"FIND",
	"[NONE]", --"MUTE",
	"[NONE]", --"VOLUMEUP",
	"[NONE]", --"VOLUMEDOWN",
	"[NONE]",
	"[NONE]",
	"[NONE]",
	"keypad_,",
	"[NONE]", --"KP_EQUALSAS400",
	"[NONE]", --"INTERNATIONAL1",
	"[NONE]", --"INTERNATIONAL2",
	"[NONE]", --"INTERNATIONAL3",
	"[NONE]", --"INTERNATIONAL4",
	"[NONE]", --"INTERNATIONAL5",
	"[NONE]", --"INTERNATIONAL6",
	"[NONE]", --"INTERNATIONAL7",
	"[NONE]", --"INTERNATIONAL8",
	"[NONE]", --"INTERNATIONAL9",
	"[NONE]", --"LANG1",
	"[NONE]", --"LANG2",
	"[NONE]", --"LANG3",
	"[NONE]", --"LANG4",
	"[NONE]", --"LANG5",
	"[NONE]", --"LANG6",
	"[NONE]", --"LANG7",
	"[NONE]", --"LANG8",
	"[NONE]", --"LANG9",
	"[NONE]", --"ALTERASE",
	"[NONE]", --"SYSREQ",
	"[NONE]", --"CANCEL",
	"[NONE]", --"CLEAR",
	"[NONE]", --"PRIOR",
	"[NONE]", --"RETURN2",
	"[NONE]", --"SEPARATOR",
	"[NONE]", --"OUT",
	"[NONE]", --"OPER",
	"[NONE]", --"CLEARAGAIN",
	"[NONE]", --"CRSEL",
	"[NONE]", --"EXSEL",
	"[NONE]",
	"[NONE]",
	"[NONE]",
	"[NONE]",
	"[NONE]",
	"[NONE]",
	"[NONE]",
	"[NONE]",
	"[NONE]",
	"[NONE]",
	"[NONE]",
	"[NONE]", --"KP_00",
	"[NONE]", --"KP_000",
	"[NONE]", --"THOUSANDSSEPARATOR",
	"[NONE]", --"DECIMALSEPARATOR",
	"[NONE]", --"CURRENCYUNIT",
	"[NONE]", --"CURRENCYSUBUNIT",
	"[NONE]", --"KP_LEFTPAREN",
	"[NONE]", --"KP_RIGHTPAREN",
	"[NONE]", --"KP_LEFTBRACE",
	"[NONE]", --"KP_RIGHTBRACE",
	"[NONE]", --"KP_TAB",
	"[NONE]", --"KP_BACKSPACE",
	"[NONE]", --"KP_A",
	"[NONE]", --"KP_B",
	"[NONE]", --"KP_C",
	"[NONE]", --"KP_D",
	"[NONE]", --"KP_E",
	"[NONE]", --"KP_F",
	"[NONE]", --"KP_XOR",
	"[NONE]", --"KP_POWER",
	"[NONE]", --"KP_PERCENT",
	"[NONE]", --"KP_LESS",
	"[NONE]", --"KP_GREATER",
	"[NONE]", --"KP_AMPERSAND",
	"[NONE]", --"KP_DBLAMPERSAND",
	"[NONE]", --"KP_VERTICALBAR",
	"[NONE]", --"KP_DBLVERTICALBAR",
	"[NONE]", --"KP_COLON",
	"[NONE]", --"KP_HASH",
	"[NONE]", --"KP_SPACE",
	"[NONE]", --"KP_AT",
	"[NONE]", --"KP_EXCLAM",
	"[NONE]", --"KP_MEMSTORE",
	"[NONE]", --"KP_MEMRECALL",
	"[NONE]", --"KP_MEMCLEAR",
	"[NONE]", --"KP_MEMADD",
	"[NONE]", --"KP_MEMSUBTRACT",
	"[NONE]", --"KP_MEMMULTIPLY",
	"[NONE]", --"KP_MEMDIVIDE",
	"[NONE]", --"KP_PLUSMINUS",
	"[NONE]", --"KP_CLEAR",
	"[NONE]", --"KP_CLEARENTRY",
	"[NONE]", --"KP_BINARY",
	"[NONE]", --"KP_OCTAL",
	"[NONE]", --"KP_DECIMAL",
	"[NONE]", --"KP_HEXADECIMAL",
	"[NONE]",
	"[NONE]",
	"left_ctrl",
	"left_shift",
	"left_alt",
	"left_windows",
	"right_ctrl",
	"right_shift",
	"right_alt",
	"right_windows",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "[NONE]",
	-- "MODE",
	-- "AUDIONEXT",
	-- "AUDIOPREV",
	-- "AUDIOSTOP",
	-- "AUDIOPLAY",
	-- "AUDIOMUTE",
	-- "MEDIASELECT",
	-- "WWW",
	-- "MAIL",
	-- "CALCULATOR",
	-- "COMPUTER",
	-- "AC_SEARCH",
	-- "AC_HOME",
	-- "AC_BACK",
	-- "AC_FORWARD",
	-- "AC_STOP",
	-- "AC_REFRESH",
	-- "AC_BOOKMARKS",
	-- "BRIGHTNESSDOWN",
	-- "BRIGHTNESSUP",
	-- "DISPLAYSWITCH",
	-- "KBDILLUMTOGGLE",
	-- "KBDILLUMDOWN",
	-- "KBDILLUMUP",
	-- "EJECT",
	-- "SLEEP",
	-- "APP1",
	-- "APP2",
}

local full_mouse = {
	"mouse_left",
	"mouse_right",
	"mouse_middle",
	"mouse_wheel_up",
	"mouse_wheel_down",
	"mouse_extra_1",
	"mouse_extra_2",
}

local full_joy = {
	"analog_0",
	"analog_1",
	"analog_2",
	"analog_3",
	"analog_4",
	"analog_5",
	"analog_6",
	"analog_7",
	"analog_8",
	"analog_9",
	"up",
	"down",
	"left",
	"right",
	"start",
	"select",
	"l3",
	"r3",
	"l1",
	"r1",
	"[NONE]", --l2
	"[NONE]", --r2
	"btn_a",
	"btn_b",
	"btn_x",
	"btn_y",
	"btn_4",
	"btn_5",
	"btn_6",
	"btn_7",
	"btn_8",
	"btn_9",
	"btn_10",
	"btn_11",
	"btn_12",
	"btn_13",
	"btn_14",
	"btn_15",
	"[NONE]", --"btn_lh_+",
	"[NONE]", --"btn_lh_-",
	"[NONE]", --"btn_lv_+",
	"[NONE]", --"btn_lv_-",
	"[NONE]", --"btn_rh_+",
	"[NONE]", --"btn_rh_-",
	"[NONE]", --"btn_rv_+",
	"[NONE]", --"btn_rv_-",
	"analog_0_down",
	"analog_1_down",
	"analog_2_down",
	"analog_3_down",
	"analog_4_down",
	"analog_5_down",
	"analog_6_down",
	"analog_7_down",
	"analog_8_down",
	"analog_9_down",
}

local full_shifted = {
	["1"] = "!",
	["2"] = "@",
	["3"] = "#",
	["4"] = "$",
	["5"] = "%",
	["6"] = "^",
	["7"] = "&",
	["8"] = "*",
	["9"] = "(",
	["0"] = ")",
	["space"] = " ",
	["backspace"] = -2,
	["return"] = -3,
	["tab"] = -4,
	["-"] = "_",
	["="] = "+",
	["["] = "{",
	["]"] = "}",
	["\\"] = "|",
	["#"] = "№",
	[";"] = ":",
	["'"] = "\"",
	["`"] = "~",
	[","] = "<",
	["."] = ">",
	["/"] = "?",
}

local full_fancy = {
	-- "a",
	-- "b",
	-- "c",
	-- "d",
	-- "e",
	-- "f",
	-- "g",
	-- "h",
	-- "i",
	-- "j",
	-- "k",
	-- "l",
	-- "m",
	-- "n",
	-- "o",
	-- "p",
	-- "q",
	-- "r",
	-- "s",
	-- "t",
	-- "u",
	-- "v",
	-- "w",
	-- "x",
	-- "y",
	-- "z",
	
	-- "1",
	-- "2",
	-- "3",
	-- "4",
	-- "5",
	-- "6",
	-- "7",
	-- "8",
	-- "9",
	-- "0",
	
	-- "-",
	-- "=",
	-- "[",
	-- "]",
	-- "\\",
	-- "#",
	-- ";",
	-- "'",
	-- "`",
	-- ",",
	-- ".",
	-- "/",

	["keypad_/"] = "KPd(/)",
	["keypad_*"] = "KPd(*)",
	["keypad_-"] = "KPd(-)",
	["keypad_+"] = "KPd(+)",
	["keypad_enter"] = "KPd(enter)",
	["keypad_1"] = "KPd(1)",
	["keypad_2"] = "KPd(2)",
	["keypad_3"] = "KPd(3)",
	["keypad_4"] = "KPd(4)",
	["keypad_5"] = "KPd(5)",
	["keypad_6"] = "KPd(6)",
	["keypad_7"] = "KPd(7)",
	["keypad_8"] = "KPd(8)",
	["keypad_9"] = "KPd(9)",
	["keypad_0"] = "KPd(0)",
	["keypad_."] = "KPd(.)",
	["keypad_,"] = "KPd(,)",

	["left_ctrl"] = "L_ctrl",
	["left_shift"] = "L_shift",
	["left_alt"] = "L_alt",
	["left_windows"] = "L_win",
	["right_ctrl"] = "R_ctrl",
	["right_shift"] = "R_shift",
	["right_alt"] = "R_alt",
	["right_windows"] = "R_win",

	["return"] = "Enter",
	["escape"] = "Esc",
	["backspace"] = "BackSpace",
	["tab"] = "Tab",
	["space"] = "Space",
	["delete"] = "Delete",
	["pause"] = "Pause",
	["insert"] = "Insert",
	
	["right"] = "Right",
	["left"] = "Left",
	["down"] = "Down",
	["up"] = "Up",
	
	["home"] = "Home",
	["end"] = "End",
	["pageup"] = "PageUP",
	["pagedown"] = "PageDOWN",

	["f1"] = "F1",
	["f2"] = "F2",
	["f3"] = "F3",
	["f4"] = "F4",
	["f5"] = "F5",
	["f6"] = "F6",
	["f7"] = "F7",
	["f8"] = "F8",
	["f9"] = "F9",
	["f10"] = "F10",
	["f11"] = "F11",
	["f12"] = "F12",

	["printscreen"] = "PrtScn",
	["scrolllock"] = "ScrLk",
	["numlock"] = "NumLk",
	["capslock"] = "CapsLk",

	["analog_0"] = "GPd(a0+)",
	["analog_1"] = "GPd(a1+)",
	["analog_2"] = "GPd(a2+)",
	["analog_3"] = "GPd(a3+)",
	["analog_4"] = "GPd(a4+)",
	["analog_5"] = "GPd(a5+)",
	["analog_6"] = "GPd(a6+)",
	["analog_7"] = "GPd(a7+)",
	["analog_8"] = "GPd(a8+)",
	["analog_9"] = "GPd(a9+)",

	["up"] = "GPd(up)",
	["down"] = "GPd(down)",
	["left"] = "GPd(left)",
	["right"] = "GPd(right)",

	["start"] = "GPd(strt)",
	["select"] = "GPd(slct)",

	["l3"] = "GPd(l_stck)",
	["r3"] = "GPd(r_stck)",
	["l1"] = "GPd(l_bump)",
	["r1"] = "GPd(r_bump)",
	["l2"] = "GPd(l_trgr)",
	["r2"] = "GPd(r_trgr)",

	["btn_a"] = "GPd(A)",
	["btn_b"] = "GPd(B)",
	["btn_x"] = "GPd(X)",
	["btn_y"] = "GPd(Y)",
	["btn_4"] = "GPd(4)",
	["btn_5"] = "GPd(5)",
	["btn_6"] = "GPd(6)",
	["btn_7"] = "GPd(7)",
	["btn_8"] = "GPd(8)",
	["btn_9"] = "GPd(9)",
	["btn_10"] = "GPd(10)",
	["btn_11"] = "GPd(11)",
	["btn_12"] = "GPd(12)",
	["btn_13"] = "GPd(13)",
	["btn_14"] = "GPd(14)",
	["btn_15"] = "GPd(15)",
	
	["analog_0_down"] = "GPd(a0)",
	["analog_1_down"] = "GPd(a1)",
	["analog_2_down"] = "GPd(a2)",
	["analog_3_down"] = "GPd(a3)",
	["analog_4_down"] = "GPd(a4)",
	["analog_5_down"] = "GPd(a5)",
	["analog_6_down"] = "GPd(a6)",
	["analog_7_down"] = "GPd(a7)",
	["analog_8_down"] = "GPd(a8)",
	["analog_9_down"] = "GPd(a9)",
}

return { full_board, full_mouse, full_joy, full_shifted, full_fancy }
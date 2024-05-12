dofile( "data/scripts/lib/mod_settings.lua" )

function mod_setting_blinking_text( mod_id, gui, in_main_menu, im_id, setting )
	anim_frame = ( anim_frame or 0 ) + 1
	local val = math.cos(( anim_frame%60 )/60 )
	GuiColorSetForNextWidget( gui, val, val, val*174/255, 1 )
	GuiText( gui, mod_setting_group_x_offset, 0, GameTextGetTranslatedOrNot( setting.ui_name ))
end

function mod_setting_full_resetter( mod_id, gui, in_main_menu, im_id, setting )
	GuiColorSetForNextWidget( gui, 245/255, 132/255, 132/255, 1 )
	local clicked, right_clicked = GuiButton( gui, im_id, mod_setting_group_x_offset, 0, "<<"..GameTextGetTranslatedOrNot( setting.ui_name )..">>"..(( mnee_it_is_done or false ) and " - "..GameTextGetTranslatedOrNot( setting.ui_extra ) or "" ))
	if( right_clicked ) then
		local is_proper = GameHasFlagRun( "MNEE_IS_GOING" )
		if( is_proper ) then dofile_once( "mods/mnee/lib.lua" ) end
		
		for i = 1,3 do
			ModSettingSetNextValue( "mnee.BINDINGS_"..i, "&", false )
			ModSettingSetNextValue( "mnee.BINDINGS_ALT_"..i, "&", false )
			if( is_proper ) then
				mnee.update_bindings( i )
			end
		end

		mnee_it_is_done = true
		print( "IT IS GONE" )
		if( is_proper ) then GamePrint( GameTextGetTranslatedOrNot( setting.ui_extra )) end
		GamePlaySound( "data/audio/Desktop/ui.bank", "ui/button_click", 0, 0 )
	end
	
	mod_setting_tooltip( mod_id, gui, in_main_menu, setting )
end

function text_with_no_mod( key ) --inspired by Conga's approach
	if( GameHasFlagRun( "MNEE_IS_GOING" )) then
		return key
	else
		local csv = {
			["$mnee_tutorial"] = {
				["English"] = "[PRESS CTRL+M IN-GAME TO OPEN THE MENU]",
				["русский"] = "[НАЖМИ CTRL+Ь В ИГРЕ ЧТОБЫ ОТКРЫТЬ ГЛАВНОЕ ОКНО]",
				-- ["Português (Brasil)"] = "",
				-- ["Español"] = "",
				-- ["Deutsch"] = "",
				-- ["Français"] = "",
				-- ["Italiano"] = "",
				-- ["Polska"] = "",
				["简体中文"] = "[在游戏内按下左CTRL+M以开启该菜单]",
				-- ["日本語"] = "",
				-- ["한국어"] = "",
			},
			["$mnee_living"] = {
				["English"] = "Disable Internal Deadzones",
				["русский"] = "Отключить Постоянные Мёртвые Зоны",
				-- ["简体中文"] = "",
			},
			["$mnee_living_desc"] = {
				["English"] = "Enabling this will remove all the default developer-defined deadzones, only leaving user-accessible ones (can be changed right below).",
				["русский"] = "При активации уберёт все заданные разработчиками мёртвые зоны, останутся только доступные игроку опции (которые могут быть изменены снизу).",
				-- ["简体中文"] = "",
			},
			["$mnee_deadzone"] = {
				["English"] = "Analog Stick Deadzone",
				["русский"] = "Мёртвая Зона Геймпада",
				-- ["简体中文"] = "",
			},
			["$mnee_deadzone_desc"] = {
				["English"] = "Controls the radius of the zone near the rest position where the inputs do not count.",
				["русский"] = "Изменяет радиус зоны около позиции покоя, где ввод не считывается.",
				-- ["简体中文"] = "",
			},
			["$mnee_autoaim"] = {
				["English"] = "Aim Assist Strength",
				["русский"] = "Степень Помощи в Прицеливании",
				-- ["简体中文"] = "",
			},
			["$mnee_autoaim_desc"] = {
				["English"] = "Controls the degree to which you aim will be offsetted by aim assisting algorithm.",
				["русский"] = "Изменяет степень отконения перекрестья алгоритмом помощи в прицеливании.",
				-- ["简体中文"] = "",
			},
			["$mnee_reset"] = {
				["English"] = "Complete Reset",
				["русский"] = "Полный Сброс",
				["简体中文"] = "完全重置",
			},
			["$mnee_rmb_reset"] = {
				["English"] = "RMB to reset all the saved M-Nee bindings.",
				["русский"] = "ПКМ чтобы полностью сбросить назначенные клавиши.",
				["简体中文"] = "右键以重置所有保存的M-Nee按键绑定集合。",
			},
			["$mnee_done"] = {
				["English"] = "[IT IS DONE]",
				["русский"] = "[ГОТОВО]",
				["简体中文"] = "[已完成]",
			},
		}
		return csv[key][GameTextGetTranslatedOrNot("$current_language")] or csv[key]["English"]
	end
end

local mod_id = "mnee"
mod_settings_version = 1
mod_settings = 
{
	{
		id = "READ_ME",
		ui_name = text_with_no_mod( "$mnee_tutorial" ),
		ui_fn = mod_setting_blinking_text,
	},
	{
		id = "LIVING",
		ui_name = GameTextGetTranslatedOrNot( text_with_no_mod( "$mnee_living" )),
		ui_description = text_with_no_mod( "$mnee_living_desc" ),
		value_default = false,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		id = "DEADZONE_AIM",
		ui_name = GameTextGetTranslatedOrNot( text_with_no_mod( "$mnee_deadzone" )).." [AIM]",
		ui_description = text_with_no_mod( "$mnee_deadzone_desc" ),
		value_default = 0,
		
		value_min = 0,
		value_max = 19,
		value_display_multiplier = 5,
		value_display_formatting = " $0% ",
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		id = "DEADZONE_MOTION",
		ui_name = GameTextGetTranslatedOrNot( text_with_no_mod( "$mnee_deadzone" )).." [MOTION]",
		ui_description = text_with_no_mod( "$mnee_deadzone_desc" ),
		value_default = 0,
		
		value_min = 0,
		value_max = 19,
		value_display_multiplier = 5,
		value_display_formatting = " $0% ",
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		id = "DEADZONE_EXTRA",
		ui_name = GameTextGetTranslatedOrNot( text_with_no_mod( "$mnee_deadzone" )).." [EXTRA]",
		ui_description = text_with_no_mod( "$mnee_deadzone_desc" ),
		value_default = 1,
		
		value_min = 0,
		value_max = 19,
		value_display_multiplier = 5,
		value_display_formatting = " $0% ",
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		id = "AUTOAIM",
		ui_name = GameTextGetTranslatedOrNot( text_with_no_mod( "$mnee_autoaim" )),
		ui_description = text_with_no_mod( "$mnee_autoaim_desc" ),
		value_default = 5,
		
		value_min = 0,
		value_max = 10,
		value_display_multiplier = 1,
		value_display_formatting = " $0 ",
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		id = "NEWLINE",
		ui_name = " ",
		not_setting = true,
	},
	{
		id = "NUKE_EM",
		ui_name = text_with_no_mod( "$mnee_reset" ),
		ui_description = text_with_no_mod( "$mnee_rmb_reset" ),
		ui_extra = text_with_no_mod( "$mnee_done" ),
		value_default = false,
		hidden = false,
		scope = MOD_SETTING_SCOPE_RUNTIME,
		ui_fn = mod_setting_full_resetter,
	},
	
	{
		id = "PROFILE",
		ui_name = "Binding Profile",
		ui_description = "",
		hidden = true,
		value_default = 1,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		id = "BINDINGS_1",
		ui_name = "Bindings",
		ui_description = "",
		hidden = true,
		value_default = "&",
		text_max_length = 100000,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		id = "BINDINGS_ALT_1",
		ui_name = "Bindings Alt",
		ui_description = "",
		hidden = true,
		value_default = "&",
		text_max_length = 100000,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		id = "BINDINGS_2",
		ui_name = "Bindings",
		ui_description = "",
		hidden = true,
		value_default = "&",
		text_max_length = 100000,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		id = "BINDINGS_ALT_2",
		ui_name = "Bindings Alt",
		ui_description = "",
		hidden = true,
		value_default = "&",
		text_max_length = 100000,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		id = "BINDINGS_3",
		ui_name = "Bindings",
		ui_description = "",
		hidden = true,
		value_default = "&",
		text_max_length = 100000,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		id = "BINDINGS_ALT_3",
		ui_name = "Bindings Alt",
		ui_description = "",
		hidden = true,
		value_default = "&",
		text_max_length = 100000,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		id = "CTRL_AUTOMAPPING",
		ui_name = "Controller Automapping",
		ui_description = "",
		hidden = true,
		value_default = true,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
}

function ModSettingsUpdate( init_scope )
	local old_version = mod_settings_get_version( mod_id )
	mod_settings_update( mod_id, mod_settings, init_scope )
end

function ModSettingsGuiCount()
	return mod_settings_gui_count( mod_id, mod_settings )
end

function ModSettingsGui( gui, in_main_menu )
	mod_settings_gui( mod_id, mod_settings, gui, in_main_menu )
end
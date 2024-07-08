ModRegisterAudioEventMappings( "mods/mnee/files/sfx/GUIDs.txt" )

function OnModInit()
	dofile_once( "mods/mnee/lib.lua" )
	pen.add_translations( "mods/mnee/files/translations.csv" )
	if( HasFlagPersistent( mnee.AMAP_MEMO )) then
		RemoveFlagPersistent( mnee.AMAP_MEMO )
		pen.setting_set( "mnee.CTRL_AUTOMAPPING", true )
	end
	
	pen.migrate( "mnee", {
		[2] = function( prefix, current_version )
			pen.setting_set( prefix.."SETUP", "" )
			pen.setting_set( prefix.."PROFILE", 2 )
			for i = 1,3 do
				ModSettingRemove( prefix.."BINDINGS_"..i )
				ModSettingRemove( prefix.."BINDINGS_ALT_"..i )
			end
		end,
	})

	-- make mnee the main propero mod (p2k must pull all the sounds and such from it)
	-- make procedural pause screen keyboard that highlights all the bind's keys on hover of one of them (only if the moddev marked the binding as show_on_pause)
	-- add separate full-sized fancy key name getter with full length names

	mnee.G.mod_page = mnee.G.mod_page or 1
	mnee.G.current_mod = mnee.G.current_mod or "mnee"
	mnee.G.binding_page = mnee.G.binding_page or 1
	mnee.G.current_binding = mnee.G.current_binding or ""
	mnee.G.stp_panel = mnee.G.stp_panel or false
	mnee.G.setup_page = mnee.G.setup_page or 1

	mnee.G.show_alt = mnee.G.show_alt or false
	mnee.G.doing_axis = mnee.G.doing_axis or false
	mnee.G.btn_axis_mode = mnee.G.btn_axis_mode or false
	mnee.G.advanced_mode = mnee.G.advanced_mode or false
	mnee.G.advanced_timer = mnee.G.advanced_timer or 0

	mnee.G.gui_active = mnee.G.gui_active or false
	mnee.G.gui_retoggler = mnee.G.gui_retoggler or false
	mnee.G.max_profiles = mnee.G.max_profiles or 27

	mnee.G.jpad_count = 0
	mnee.G.jpad_maps = mnee.G.jpad_maps or { -1, -1, -1, -1 }
	mnee.G.jpad_states = mnee.G.jpad_states or { -1, -1, -1, -1 }
	mnee.jpad_next = function( init_only )
		for i,j in ipairs( mnee.G.jpad_states ) do
			local is_real = InputIsJoystickConnected( i - 1 ) > 0
			if( j < 0 ) then
				if( is_real ) then
					mnee.G.jpad_states[i] = 1
					mnee.G.jpad_count = mnee.G.jpad_count + 1
				end
			else
				if( is_real ) then
					if( j > 0 and not( init_only )) then
						mnee.G.jpad_states[i] = 0; return i - 1
					end
				else
					for e,jp in ipairs( mnee.G.jpad_maps ) do
						if( jp == ( i - 1 )) then mnee.G.jpad_maps[e] = -1; break end
					end
					
					mnee.G.jpad_states[i] = -1
					mnee.G.jpad_count = mnee.G.jpad_count - 1
				end
			end
		end
		
		return -1
	end
	mnee.jpad_callback = function( jpad_id, slot_id )
		local make_it_stop = false
		for mod_id,data in pairs( _MNEEDATA ) do
			if( data.on_jpad ~= nil ) then
				make_it_stop = data.on_jpad( data, slot_id )
			end
		end
		
		if( make_it_stop and slot_id > 0 ) then
			if(( jpad_id or 4 ) < 4 ) then
				mnee.G.jpad_states[ jpad_id + 1 ] = 1
			end
			mnee.G.jpad_maps[ slot_id ] = 5
		end
	end
	mnee.jpad_update = function( num )
		local out = -1
		if( num < 0 ) then
			mnee.G.jpad_states[ mnee.G.jpad_maps[ math.abs( num )] + 1 ] = 1
			mnee.G.jpad_maps[ math.abs( num )] = -1
		else
			out = mnee.jpad_next()
			if( out ~= -1 ) then mnee.G.jpad_maps[ num ] = out end
		end

		if( num < 0 or out > 0 ) then mnee.jpad_callback( out, num ) end
		return out
	end
	
	mnee.get_current_keys = function()
		local lists = dofile_once( "mods/mnee/lists.lua" )
		return table.concat({ pen.DIV_1,
			pen.t.loop_concat( lists[1], function( i, key ) --keyboard
				if( key == "[NONE]"  ) then return end
				if( mnee.BANNED_KEYS[ key ]) then return end
				if( not( InputIsKeyDown( i ))) then return end
				return { string.format( "%q", key ), pen.DIV_1 }
			end),
			pen.t.loop_concat( lists[2], function( i, key ) --mouse
				if( key == "[NONE]"  ) then return end
				if( not( InputIsMouseButtonDown( i ))) then return end
				return { key, pen.DIV_1 }
			end),
			pen.t.loop_concat( mnee.G.jpad_maps, function( i, real_num ) --gamepad
				if( real_num == -1 ) then return end
				return pen.t.loop_concat( lists[3], function( k, key )
					if( key == "[NONE]"  ) then return end
					if( not( InputIsJoystickButtonDown( real_num, k ))) then return end
					return { i, "gpd_", key, pen.DIV_1 }
				end)..pen.t.loop_concat({0,1}, function( k, v )
					if( InputGetJoystickAnalogButton( real_num, v ) < 0.5 ) then return end
					return { i, "gpd_", ( v == 0 and "l2" or "r2" ), pen.DIV_1 }
				end)
			end),
		})
	end
	mnee.get_current_triggers = function()
		return pen.DIV_1..pen.t.loop_concat( mnee.G.jpad_maps, function( i, real_num )
			if( real_num == -1 ) then return end
			return pen.t.loop_concat({0,1}, function( k, v )
				local value = pen.rounder( InputGetJoystickAnalogButton( real_num, v ), 100 )
				return { pen.DIV_2, i, "gpd_", ( v == 0 and "l2" or "r2" ), pen.DIV_2, value, pen.DIV_2, pen.DIV_1 }
			end)
		end)
	end
	mnee.get_current_axes = function()
		local gpd_axis = { "_lh", "_lv", "_rh", "_rv" }
		return pen.DIV_1..pen.t.loop_concat( mnee.G.jpad_maps, function( i, real_num )
			if( real_num == -1 ) then return end
			return pen.t.loop_concat({0,1}, function( k, e )
				local value = { InputGetJoystickAnalogStick( real_num, e )}
				return {
					pen.DIV_2, i, "gpd_axis", gpd_axis[ 2*e + 1 ], pen.DIV_2, value[ 1 ], pen.DIV_2, pen.DIV_1,
					pen.DIV_2, i, "gpd_axis", gpd_axis[ 2*e + 2 ], pen.DIV_2, value[ 2 ], pen.DIV_2, pen.DIV_1,
				}
			end)
		end)
	end
end

function OnWorldPreUpdate()
	dofile_once( "mods/mnee/lib.lua" )
	if( not( GameHasFlagRun( mnee.INITER ))) then return end
	local ctrl_body = mnee.get_ctrl()
	if( not( pen.vld( ctrl_body, true ))) then return end
	
	mnee.clean_disarmer()
	mnee.jpad_next( true )
	pen.magic_storage( ctrl_body, "mnee_axis", "value_string", mnee.get_current_axes())
	pen.magic_storage( ctrl_body, "mnee_triggers", "value_string", mnee.get_current_triggers())
	if( GameHasFlagRun( mnee.JPAD_UPDATE )) then
		GameRemoveFlagRun( mnee.JPAD_UPDATE )
		pen.t.loop( pen.t.pack( pen.magic_storage( ctrl_body, "mnee_jpads", "value_string" )), function( i, v )
			if( mnee.G.jpad_maps[i] ~= v ) then mnee.G.jpad_maps[i] = v; mnee.jpad_callback( v, i ) end
		end)
	else mnee.apply_jpads( mnee.G.jpad_maps, true ) end

	local button_deadzone = pen.setting_get( "mnee.DEADZONE_BUTTON" )/20
	local active_core = mnee.get_current_keys()..pen.t.loop_concat( pen.t.unarray( mnee.get_axes()), function( i, v )
		if( math.abs( v[2]) < button_deadzone ) then return end
		return { string.gsub( v[1], "gpd_axis", "gpd_btn" ), "_", ( v[2] > 0 and "+" or "-" ), pen.DIV_1 }
	end)
	for mode,func in pairs( mnee.INMODES ) do
		pen.magic_storage( ctrl_body, "mnee_down_"..mode, "value_string", func( ctrl_body, active_core ))
	end
	pen.magic_storage( ctrl_body, "mnee_down", "value_string", active_core )
	
	if( mnee.mnin( "bind", { "mnee", "menu" }, { pressed = true, vip = true })) then
		mnee.play_sound( mnee.G.gui_active and "close_window" or "open_window" )
		mnee.G.gui_active = not( mnee.G.gui_active )
		if( mnee.G.gui_active ) then pen.atimer( "main_window", nil, true ) end
	end
	if( mnee.mnin( "bind", { "mnee", "off" }, { pressed = true, vip = true })) then
		local has_flag = GameHasFlagRun( mnee.TOGGLER )
		if( has_flag ) then
			GameRemoveFlagRun( mnee.TOGGLER )
		else GameAddFlagRun( mnee.TOGGLER ) end
		GamePrint( GameTextGetTranslatedOrNot( table.concat({ "$mnee_", ( has_flag and "" or "no_" ), "input" })))
		mnee.play_sound( has_flag and "capture" or "uncapture" )
	end
	if( mnee.mnin( "bind", { "mnee", "profile_change" }, { pressed = true })) then
		local prf = pen.setting_get( "mnee.PROFILE" ) + 1
		prf = prf > mnee.G.max_profiles and 1 or prf
		pen.setting_set( "mnee.PROFILE", prf )
		GamePrint( GameTextGetTranslatedOrNot( "$mnee_this_profile" )..": "..string.char( prf + 64 ))
		mnee.play_sound( "switch_page" )
		GlobalsSetValue( mnee.UPDATER, GameGetFrameNum())
	end
	
	mnee.stl = {
		jslots = { false, false, false, false, },
		jauto = pen.setting_get( "mnee.CTRL_AUTOMAPPING" ),
	}
	if( mnee.G.gui_active and not( pen.is_inv_active())) then
		mnee.G.UI = mnee.G.UI or GuiCreate()
		GuiStartFrame( mnee.G.UI )
		dofile( "mods/mnee/files/gui.lua" )
	else mnee.G.UI = pen.gui_killer( mnee.G.UI ) end
	
	for i,gslot in ipairs( mnee.stl.jslots ) do
		if( gslot or mnee.stl.jauto ) then
			if( mnee.G.jpad_maps[i] == -1 ) then
				local ctl = mnee.jpad_update( i )
				if( not( mnee.stl.jauto )) then
					if(( ctl or -1 ) == -1 ) then
						GamePrint( GameTextGetTranslatedOrNot( "$mnee_error" ))
						mnee.play_sound( "error" )
					else mnee.play_sound( "confirm" ) end
				end
			elseif( not( mnee.stl.jauto )) then
				GamePrint( GameTextGetTranslatedOrNot( "$mnee_no_slot" ))
				mnee.play_sound( "error" )
			end
		end
	end
end

function OnPlayerSpawned( hooman )
	dofile_once( "mods/mnee/lib.lua" )

	GameAddFlagRun( mnee.INITER )
	GameRemoveFlagRun( mnee.SERV_MODE )
	GlobalsSetValue( mnee.PRIO_MODE, "0" )
	GlobalsSetValue( "PROSPERO_IS_REAL", "1" )
	
	local world_id = GameGetWorldStateEntity()
	local entity_id = pen.get_child( world_id, "mnee_ctrl" )
	if( pen.vld( entity_id, true )) then EntityKill( entity_id ) end
	entity_id = EntityLoad( "mods/mnee/files/ctrl_body.xml" )
	EntityAddChild( world_id, entity_id )
	
	pen.magic_storage( entity_id, "mnee_down", "value_string", "" )
	pen.magic_storage( entity_id, "mnee_disarmer", "value_string", pen.DIV_1 )
	pen.magic_storage( entity_id, "mnee_triggers", "value_string", "" )
	pen.magic_storage( entity_id, "mnee_axis", "value_string", "" )
	pen.magic_storage( entity_id, "mnee_axis_memo", "value_string", pen.DIV_1 )
	pen.magic_storage( entity_id, "mnee_jpads", "value_string", "" )
	
	mnee.update_bindings()
end
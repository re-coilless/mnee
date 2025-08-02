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
	
	-- conflict checker for special keys is fucked
	-- add an option to merge numpad and main keyboard on per-bind basis
	-- make mnee the main propero mod (p2k must pull all the sounds and such from it, window context is run from within mnee's init)
	-- fuck it, redo prospero

	-- make procedural pause screen keyboard that highlights all the bind's keys on hover of one of them (only if the moddev marked the binding as show_on_pause)
	--add vertical window resizing that snaps to always have the whole number of buttons shown

	mnee.G.m_list = mnee.G.m_list or ""

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
		dofile_once( "mods/mnee/bindings.lua" )

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
	if( not( GameHasFlagRun( mnee.INITER ))) then return pen.gui_builder( false ) end
	local ctrl_body = mnee.get_ctrl()
	if( not( pen.vld( ctrl_body, true ))) then return pen.gui_builder( false ) end
	
	mnee.clean_exe()
	mnee.clean_disarmer()
	mnee.jpad_next( true )
	GlobalsSetValue( mnee.G_AXES, mnee.get_current_axes())
	GlobalsSetValue( mnee.G_TRIGGERS, mnee.get_current_triggers())
	if( GameHasFlagRun( mnee.JPAD_UPDATE )) then
		GameRemoveFlagRun( mnee.JPAD_UPDATE )
		pen.t.loop( pen.t.pack( GlobalsGetValue( mnee.G_JPADS, "" )), function( i, v )
			if( mnee.G.jpad_maps[i] ~= v ) then mnee.G.jpad_maps[i] = v; mnee.jpad_callback( v, i ) end
		end)
	else mnee.apply_jpads( mnee.G.jpad_maps, true ) end

	local button_deadzone = pen.setting_get( "mnee.DEADZONE_BUTTON" )/20
	local active_core = mnee.get_current_keys()..pen.t.loop_concat( pen.t.unarray( mnee.get_axes()), function( i, v )
		if( math.abs( v[2]) < button_deadzone ) then return end
		return { string.gsub( v[1], "gpd_axis", "gpd_btn" ), "_", ( v[2] > 0 and "+" or "-" ), pen.DIV_1 }
	end)
	GlobalsSetValue( mnee.G_DOWN, active_core )
	
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
		GamePrint( GameTextGet( table.concat({ "$mnee_", ( has_flag and "" or "no_" ), "input" })))
		mnee.play_sound( has_flag and "capture" or "uncapture" )
	end
	if( mnee.mnin( "bind", { "mnee", "profile_change" }, { pressed = true })) then
		local prf = pen.setting_get( "mnee.PROFILE" ) + 1
		prf = prf > mnee.G.max_profiles and 1 or prf
		pen.setting_set( "mnee.PROFILE", prf )
		GamePrint( GameTextGet( "$mnee_this_profile" )..": "..string.char( prf + 64 ))
		mnee.play_sound( "switch_page" )
		GlobalsSetValue( mnee.UPDATER, GameGetFrameNum())
	end
	
	mnee.stl = {
		jslots = { false, false, false, false, },
		jauto = pen.setting_get( "mnee.CTRL_AUTOMAPPING" ),
	}
	if( not( pen.is_inv_active())) then
		local will_remind = not( GameHasFlagRun( mnee.NO_REMINDER ))
		local screen_w, screen_h = GuiGetScreenDimensions( pen.gui_builder())
		if( mnee.G.gui_active ) then
			if( not( pen.vld( mnee.G.m_list ))) then
				mnee.G.m_list = "|"..pen.t.loop_concat( _BINDINGS, function( mod ) return { mod, "|" } end)
			end

			pen.setting_set( "mnee.REMINDER", false )
			pen.try( dofile, "mods/mnee/files/gui.lua", function( log )
				pen.new_pixel( -5, -5, pen.LAYERS.WORLD_BACK + 1, pen.PALETTE.PRSP.WHITE, screen_w + 10, screen_h + 10 )
				pen.new_text( screen_w/2, screen_h/2, pen.LAYERS.WORLD_BACK, GameTextGet( "$mnee_error" ), { is_centered = true, color = pen.PALETTE.PRSP.BLUE, fully_featured = true })
				pen.new_text( screen_w/2, screen_h/2 + 50, pen.LAYERS.WORLD_BACK, mnee.G.m_list.."\n"..log, { is_centered = true, color = pen.PALETTE.PRSP.RED, dims = { 0.75*screen_w, -1 }})
			end)
		elseif( will_remind and pen.setting_get( "mnee.REMINDER" )) then
			if( GameGetFrameNum() < 600 ) then return end
			local count = pen.t.count( _BINDINGS )
			if( count < 2 ) then return end
			
			local clicked = false
			local pic_x, pic_y, pic_z = screen_w/2, screen_h, pen.LAYERS.MAIN - 10
			pic_y = pic_y - 31*pen.animate( 1, "reminder", { ease_out = "wav1", frames = 15 })

			local dims = pen.new_text( pic_x, pic_y + 6, pic_z, GameTextGet( "$mnee_tip", count - 1,
				mnee.get_binding_keys( "mnee", "menu" )), { is_centered = true, color = pen.PALETTE.PRSP.PURPLE, fully_featured = true })
			local off = math.max( dims[1]/2 - 80, 40 )
			
			clicked = mnee.new_button( pic_x - off - 90,
				pic_y + 20, pic_z, "mods/mnee/files/pics/button_90_B.png" )
			pen.new_text( pic_x - off - 90/2, pic_y + 20, pic_z - 0.01,
				GameTextGet( "$mnee_tipA" ), { is_centered_x = true, color = pen.PALETTE.PRSP.RED })
			if( clicked ) then
				mnee.play_sound( mnee.G.gui_active and "close_window" or "open_window" )
				mnee.G.gui_active = not( mnee.G.gui_active )
				if( mnee.G.gui_active ) then pen.atimer( "main_window", nil, true ) end
			end

			clicked = mnee.new_button( pic_x + off,
				pic_y + 20, pic_z, "mods/mnee/files/pics/button_90_A.png" )
			pen.new_text( pic_x + off + 90/2, pic_y + 20, pic_z - 0.01,
				GameTextGet( "$mnee_tipB" ), { is_centered_x = true, color = pen.PALETTE.PRSP.WHITE })
			if( clicked ) then GameAddFlagRun( mnee.NO_REMINDER ); mnee.play_sound( "close_window" ) end

			off = off + 91
			pen.new_pixel( pic_x - off, pic_y - 5, pic_z + 0.01, pen.PALETTE.PRSP.WHITE, 2*off, 50 )
			pen.new_pixel( pic_x - off - 1, pic_y - 6, pic_z + 0.015, pen.PALETTE.PRSP.BLUE, 2*( off + 1 ), 50 )
			pen.new_interface( pic_x - off, pic_y - 5, 2*off, 50, pic_z + 0.01 )
		end
	end
	pen.gui_builder( true )

	for i,gslot in ipairs( mnee.stl.jslots ) do
		if(( gslot or mnee.stl.jauto ) and mnee.G.jpad_maps[i] == -1 ) then
			local ctl = mnee.jpad_update( i )
			if( not( mnee.stl.jauto )) then
				if(( ctl or -1 ) == -1 ) then
					GamePrint( GameTextGet( "$mnee_error" ))
					mnee.play_sound( "error" )
				else mnee.play_sound( "confirm" ) end
			end
		elseif( gslot ) then
			GamePrint( GameTextGet( "$mnee_no_slot" ))
			mnee.play_sound( "error" )
		end
	end
end

function OnPlayerSpawned( hooman )
	dofile_once( "mods/mnee/lib.lua" )
	
	GameAddFlagRun( mnee.INITER )
	GameRemoveFlagRun( mnee.SERV_MODE )
	GlobalsSetValue( mnee.PRIO_MODE, "0" )
	GlobalsSetValue( "PROSPERO_IS_REAL", "1" )

	GlobalsSetValue( mnee.G_DOWN, "" )
	GlobalsSetValue( mnee.G_AXES, "" )
	GlobalsSetValue( mnee.G_TRIGGERS, "" )

	GlobalsSetValue( mnee.G_JPADS, "" )
	GlobalsSetValue( mnee.G_EXE, pen.DIV_1 )
	GlobalsSetValue( mnee.G_DISARMER, pen.DIV_1 )
	GlobalsSetValue( mnee.G_AXES_MEMO, pen.DIV_1 )
	
	local world_id = GameGetWorldStateEntity()
	local entity_id = pen.get_child( world_id, "mnee_ctrl" )
	if( pen.vld( entity_id, true )) then EntityKill( entity_id ) end
	entity_id = EntityLoad( "mods/mnee/files/ctrl_body.xml" )
	EntityAddChild( world_id, entity_id )
	
	for mode,func in pairs( mnee.INMODES ) do
		pen.magic_storage( entity_id, "mnee_down_"..mode, "value_string", "" )
	end

	mnee.update_bindings()
end
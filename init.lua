ModRegisterAudioEventMappings( "mods/mnee/files/sfx/GUIDs.txt" )
get_active_keys = get_active_keys or ( function() return "huh?" end )

function OnModInit()
	dofile_once( "mods/mnee/lib.lua" )
	pen.add_translations( "mods/mnee/files/translations.csv" )
	if( HasFlagPersistent( mnee.AMAP_MEMO )) then
		RemoveFlagPersistent( mnee.AMAP_MEMO )
		ModSettingSetNextValue( "mnee.CTRL_AUTOMAPPING", true, false )
	end
	
	--5 profiles in total
	--jpad must be -1 instread of false
	--implant penman into mnee (and test it with most disgusting malformed data possible)
	--separate gui into own file
	--add buttons anims + main window frame opening bounce anim + side bars opening anims
	--LLS documentation of all funcs
	--make mnee main propero mod (p2k must pull all the sounds and such from it)

	-- make procedural pause screen keyboard that highlights all the bind's keys on hover of one of them (only if the moddev marked the binding as show_on_pause)
	-- add separate full-sized fancy key name getter with full length names

	local lists = dofile_once( "mods/mnee/lists.lua" )
	local keycaps = lists[1]
	local mouse = lists[2]
	local jcaps = lists[3]

	jpad_count = 0
	jpad_states = jpad_states or { -1, -1, -1, -1 }
	jpad = jpad or { false, false, false, false }
	jpad_update = function( num )
		local out, callbacking = nil, false
		if( num < 0 ) then
			jpad_states[ jpad[ math.abs( num )] + 1 ] = 1
			jpad[ math.abs( num )] = false
			callbacking = true
		else
			local val = mnee.get_next_jpad()
			if( val ) then
				jpad[num] = val
				callbacking = true
			end
			out = val
		end

		if( callbacking ) then
			mnee.jpad_callback( out, num )
		end
		return out
	end
	
	get_active_keys = function()
		local active = pen.DIV_1
		
		--keyboard
		for i,key in ipairs( keycaps ) do
			if( key ~= "[NONE]" ) then
				if( InputIsKeyDown( i ) and ( key ~= "left_windows" and key ~= "right_windows" )) then
					active = active..key..pen.DIV_1
				end
			end
		end
		
		--mouse
		for i,key in ipairs( mouse ) do
			if( InputIsMouseButtonDown( i )) then
				active = active..key..pen.DIV_1
			end
		end
		
		--gamepad; add rumbling
		if( #jpad > 0 ) then
			for i,real_num in ipairs( jpad ) do
				if( real_num ) then
					for k,key in ipairs( jcaps ) do
						if( key ~= "[NONE]" ) then
							if( InputIsJoystickButtonDown( real_num, k )) then
								active = active..i.."gpd_"..key..pen.DIV_1
							end
						end
					end
					for k = 0,1 do
						if( InputGetJoystickAnalogButton( real_num, k ) > 0.5 ) then
							active = active..i.."gpd_"..( k == 0 and "l2" or "r2" )..pen.DIV_1
						end
					end
				end
			end
		end
		
		return active
	end
	
	get_current_triggers = function()
		local state = pen.DIV_1
		if( #jpad > 0 ) then
			for i,real_num in ipairs( jpad ) do
				if( real_num ) then
					for k = 0,1 do
						local v = pen.rounder( InputGetJoystickAnalogButton( real_num, k ), 100 )
						local name = table.concat({ i, "gpd_", ( k == 0 and "l2" or "r2" )})
						state = table.concat({ state, pen.DIV_2, name, pen.DIV_2, v, pen.DIV_2, pen.DIV_1 })
					end
				end
			end
		end

		return state
	end

	get_current_axes = function()
		local state = pen.DIV_1
		if( #jpad > 0 ) then
			local gpd_axis = { "_lh", "_lv", "_rh", "_rv", }
			for i,real_num in ipairs( jpad ) do
				if( real_num ) then
					for e = 0,1 do
						local value = { InputGetJoystickAnalogStick( real_num, e )}
						for k = 1,2 do
							local name = table.concat({ i, "gpd_axis", gpd_axis[e*2 + k]})
							state = table.concat({ state, pen.DIV_2, name, pen.DIV_2, value[k], pen.DIV_2, pen.DIV_1 })
						end
					end
				end
			end
		end
		
		return state
	end
end

pic_x = pic_x or nil
pic_y = pic_y or 246
grab_x = grab_x or nil
grab_y = grab_y or nil

stp_panel = stp_panel or false
setup_page = setup_page or 1
show_alt = show_alt or false
mod_page = mod_page or 1
current_mod = current_mod or "mnee"
binding_page = binding_page or 1
current_binding = current_binding or ""
doing_axis = doing_axis or false
btn_axis_mode = btn_axis_mode or false
advanced_mode = advanced_mode or false
advanced_timer = advanced_timer or 0

gui_active = gui_active or false
gui_retoggler = gui_retoggler or false

function OnWorldPreUpdate()
	dofile_once( "mods/mnee/lib.lua" )
	if( GameHasFlagRun( mnee.INITER )) then
		local ctrl_body = mnee.get_ctrl()
		local storage = pen.get_storage( ctrl_body, "mnee_down" )
		if( pen.vld( storage, true )) then
			mnee.get_next_jpad( true )
			ComponentSetValue2( pen.get_storage( ctrl_body, "mnee_axis" ), "value_string", get_current_axes())
			ComponentSetValue2( pen.get_storage( ctrl_body, "mnee_triggers" ), "value_string", get_current_triggers())
			if( GameHasFlagRun( mnee.JPAD_UPDATE )) then
				GameRemoveFlagRun( mnee.JPAD_UPDATE )

				local counter = 1
				local jpad_raw = ComponentGetValue2( pen.get_storage( ctrl_body, "mnee_jpads" ), "value_string" )
				for j in string.gmatch( jpad_raw, pen.ptrn( 1 )) do
					local val = tonumber( j )
					if( val < 0 ) then val = false end
					if( jpad[ counter ] ~= val ) then
						jpad[ counter ] = val
						mnee.jpad_callback( val, counter )
					end
					counter = counter + 1
				end
			else
				mnee.apply_jpads( jpad, true )
			end

			local axis_core = mnee.get_axes()
			local active_core = get_active_keys()
			local button_deadzone = ModSettingGetNextValue( "mnee.DEADZONE_BUTTON" )/20
			for ax,v in pairs( axis_core ) do
				if( math.abs( v ) > button_deadzone ) then
					active_core = active_core..string.gsub( ax, "gpd_axis", "gpd_btn" ).."_"..( v > 0 and "+" or "-" )..pen.DIV_1
				end
			end
			for mode,func in pairs( mnee.INMODES ) do
				local name = "mnee_down_"..mode
				local stg = pen.get_storage( ctrl_body, name )
				if( not( pen.vld( stg, true ))) then
					stg = EntityAddComponent( ctrl_body, "VariableStorageComponent", 
					{
						name = name,
						value_string = pen.DIV_1,
					})
				end
				ComponentSetValue2( stg, "value_string", func( ctrl_body, active_core ))
			end
			ComponentSetValue2( storage, "value_string", active_core )
			
			mnee.clean_disarmer()
			if( mnee.mnin( "bind", { "mnee", "menu" }, { pressed = true, vip = true })) then
				if( gui_active ) then
					gui_active = false
					mnee.play_sound( "close_window" )
				else
					gui_active = true
					mnee.play_sound( "open_window" )
				end
			end
			if( mnee.mnin( "bind", { "mnee", "off" }, { pressed = true, vip = true })) then
				local has_flag = GameHasFlagRun( mnee.TOGGLER )
				if( has_flag ) then
					GameRemoveFlagRun( mnee.TOGGLER )
				else
					GameAddFlagRun( mnee.TOGGLER )
				end
				GamePrint( GameTextGetTranslatedOrNot( "$mnee_"..( has_flag and "" or "no_" ).."input" ))
				mnee.play_sound( has_flag and "capture" or "uncapture" )
			end
			if( mnee.mnin( "bind", { "mnee", "profile_change" }, { pressed = true })) then
				local prf = ModSettingGetNextValue( "mnee.PROFILE" ) + 1
				prf = prf > 3 and 1 or prf
				ModSettingSetNextValue( "mnee.PROFILE", prf, false )
				GamePrint( GameTextGetTranslatedOrNot( "$mnee_this_profile" )..": "..string.char( prf + 64 ))
				mnee.play_sound( "switch_page" )
				GlobalsSetValue( mnee.UPDATER, GameGetFrameNum())
			end
		end
		
		local is_auto = ModSettingGetNextValue( "mnee.CTRL_AUTOMAPPING" )
		local gslot_update = { false, false, false, false, }
		
		if( not( pen.is_inv_active())) then
			if( gui == nil ) then
				gui = GuiCreate()
			end
			GuiStartFrame( gui )

			dofile( "mods/mnee/files/gui.lua" )
		else
			gui = pen.gui_killer( gui )
		end
		
		if( jpad_update ~= nil ) then
			for i,gslot in ipairs( gslot_update ) do
				if( gslot or is_auto ) then
					if( not( jpad[i])) then
						local ctl = jpad_update( i )
						if( not( is_auto )) then
							if( ctl ) then
								mnee.play_sound( "confirm" )
							else
								GamePrint( GameTextGetTranslatedOrNot( "$mnee_error" ))
								mnee.play_sound( "error" )
							end
						end
					elseif( not( is_auto )) then
						GamePrint( GameTextGetTranslatedOrNot( "$mnee_no_slot" ))
						mnee.play_sound( "error" )
					end
				end
			end
		end
	end
	
	tooltip_opened = false
	sound_played = false
end

function OnPlayerSpawned( hooman )
	dofile_once( "mods/mnee/lib.lua" )
	GameRemoveFlagRun( mnee.SERV_MODE )
	GlobalsSetValue( mnee.PRIO_MODE, "0" )
	GameAddFlagRun( mnee.INITER )
	GlobalsSetValue( "PROSPERO_IS_REAL", "1" )
	
	local world_id = GameGetWorldStateEntity()
	local entity_id = pen.get_child( world_id, "mnee_ctrl" ) or 0
	if( pen.vld( entity_id, true )) then EntityKill( entity_id ) end
	entity_id = EntityLoad( "mods/mnee/files/ctrl_body.xml" )
	EntityAddChild( GameGetWorldStateEntity(), entity_id )

	EntityAddComponent( entity_id, "VariableStorageComponent", { name = "mnee_down" })
	EntityAddComponent( entity_id, "VariableStorageComponent", { name = "mnee_disarmer" })
	EntityAddComponent( entity_id, "VariableStorageComponent", { name = "mnee_triggers" })
	EntityAddComponent( entity_id, "VariableStorageComponent", { name = "mnee_axis" })
	EntityAddComponent( entity_id, "VariableStorageComponent", { name = "mnee_axis_memo" })
	EntityAddComponent( entity_id, "VariableStorageComponent", { name = "mnee_jpads" })
	
	mnee.update_bindings()
end
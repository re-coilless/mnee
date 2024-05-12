dofile_once( "mods/mnee/_penman.lua" )

mnee = mnee or {}

mnee.INITER = "MNEE_IS_GOING"
mnee.TOGGLER = "MNEE_DISABLED"
mnee.RETOGGLER = "MNEE_REDO"
mnee.UPDATER = "MNEE_RELOAD"
mnee.SERV_MODE = "MNEE_HOLD_UP"
mnee.PRIO_MODE = "MNEE_PRIORITY_MODE"

mnee.DIV_0 = "@"
mnee.DIV_1 = "&"
mnee.DIV_2 = "|"
mnee.DIV_3 = "!"

mnee.PTN_0 = "([^"..mnee.DIV_0.."]+)"
mnee.PTN_1 = "([^"..mnee.DIV_1.."]+)"
mnee.PTN_2 = "([^"..mnee.DIV_2.."]+)"
mnee.PTN_3 = "([^"..mnee.DIV_3.."]+)"

mnee.SPECIAL_KEYS = {
	-- left_shift = 1,
	-- right_shift = 1,
	left_ctrl = 1,
	right_ctrl = 1,
	left_alt = 1,
	right_alt = 1,
	-- left_windows = 1,
	-- right_windows = 1,
}

mnee.INMODES = {
	guied = function( ctrl_body, active )
		if( active ~= mnee.DIV_1 ) then
			local ctrl_comp = EntityGetFirstComponentIncludingDisabled( ctrl_body, "ControlsComponent" )
			if( not( ComponentGetValue2( ctrl_comp, "mButtonDownLeftClick" ))) then
				active = string.gsub( active, "mouse_left", "mouse_left_gui" )
			end
			if( not( ComponentGetValue2( ctrl_comp, "mButtonDownRightClick" ))) then
				active = string.gsub( active, "mouse_right", "mouse_right_gui" )
			end
		end
		return active
	end,
}

function mnee.get_ctrl()
	return pen.get_hooman_child( GameGetWorldStateEntity(), "mnee_ctrl" )
end

function mnee.extractor( data_raw )
	if( data_raw == mnee.DIV_1 ) then
		return {}
	end
	
	local data = {}
	for value in string.gmatch( data_raw, mnee.PTN_1 ) do
		table.insert( data, value )
	end
	
	return data
end

function mnee.get_next_jpad( init_only )
	for i,j in ipairs( jpad_states ) do
		local is_real = InputIsJoystickConnected( i - 1 ) > 0
		if( j < 0 ) then
			if( is_real ) then
				jpad_states[i] = 1
				jpad_count = jpad_count + 1
			end
		else
			if( is_real ) then
				if( j > 0 and not( init_only )) then
					jpad_states[i] = 0
					return i - 1
				end
			else
				for e,jp in ipairs( jpad ) do
					if( jp == ( i - 1 )) then
						jpad[e] = false
						break
					end
				end
				jpad_states[i] = -1
				jpad_count = jpad_count - 1
			end
		end
	end

	return false
end

function mnee.get_keys( mode )
	mode = mode or false

	local storage = pen.get_storage( mnee.get_ctrl(), mode and "mnee_down_"..mode or "mnee_down" )
	if(( storage or 0 ) == 0 ) then
		return {}
	end

	return mnee.extractor( ComponentGetValue2( storage, "value_string" ))
end

function mnee.get_disarmer()
	local storage = pen.get_storage( mnee.get_ctrl(), "mnee_disarmer" ) or 0
	if( storage == 0 ) then
		return {}
	end
	local data_raw = ComponentGetValue2( storage, "value_string" )
	if( data_raw == mnee.DIV_1 ) then
		return {}
	end
	
	local data = {}
	for action in string.gmatch( data_raw, mnee.PTN_1 ) do
		local val = {}
		for value in string.gmatch( action, mnee.PTN_2 ) do
			table.insert( val, value )
		end
		if( #val > 0 ) then
			if( data[ val[1]] == nil or ( val[2] > ( data[ val[1]] or ( val[2] + 1 )))) then
				data[ val[1]] = val[2]
			end
		end
	end
	
	return data
end

function mnee.clean_disarmer()
	local disarmer = mnee.get_disarmer()
	if( pen.get_table_count( disarmer ) > 0 ) then
		local current_frame = GameGetFrameNum()
		
		local new_disarmer = mnee.DIV_1
		for key,frame in pairs( disarmer ) do
			if( current_frame - tonumber( frame ) < 2 ) then
				new_disarmer = new_disarmer..mnee.DIV_2..key..mnee.DIV_2..frame..mnee.DIV_2..mnee.DIV_1
			end
		end
		
		local storage = pen.get_storage( mnee.get_ctrl(), "mnee_disarmer" )
		ComponentSetValue2( storage, "value_string", new_disarmer )
	end
end

function mnee.add_disarmer( value )
	local storage = pen.get_storage( mnee.get_ctrl(), "mnee_disarmer" ) or 0
	if( storage == 0 ) then
		return
	end
	ComponentSetValue2( storage, "value_string", ComponentGetValue2( storage, "value_string" )..( mnee.DIV_2..value..mnee.DIV_2..GameGetFrameNum()..mnee.DIV_2 )..mnee.DIV_1 )
end

function mnee.get_triggers()
	local storage = pen.get_storage( mnee.get_ctrl(), "mnee_triggers" ) or 0
	if( storage == 0 ) then
		return {}
	end
	local triggers_raw = ComponentGetValue2( storage, "value_string" )
	if( triggers_raw == mnee.DIV_1 ) then
		return {}
	end
	
	local triggers = {}
	for tr in string.gmatch( triggers_raw, mnee.PTN_1 ) do
		local trigger = ""
		for val in string.gmatch( tr, mnee.PTN_2 ) do
			if( trigger == "" ) then
				trigger = val
			else
				triggers[ trigger ] = tonumber( val )
			end
		end
	end
	
	return triggers
end

function mnee.get_axes()
	local storage = pen.get_storage( mnee.get_ctrl(), "mnee_axis" ) or 0
	if( storage == 0 ) then
		return {}
	end
	local axes_raw = ComponentGetValue2( storage, "value_string" )
	if( axes_raw == mnee.DIV_1 ) then
		return {}
	end
	
	local axes = {}
	for ax in string.gmatch( axes_raw, mnee.PTN_1 ) do
		local axis = ""
		for val in string.gmatch( ax, mnee.PTN_2 ) do
			if( axis == "" ) then
				axis = val
			else
				axes[ axis ] = tonumber( val )
			end
		end
	end
	
	return axes
end

function mnee.get_axis_memo()
	local storage = pen.get_storage( mnee.get_ctrl(), "mnee_axis_memo" ) or 0
	if( storage == 0 ) then
		return {}
	end
	local memo_raw = ComponentGetValue2( storage, "value_string" )
	if( memo_raw == mnee.DIV_1 ) then
		return {}
	end
	
	local data = {}
	for value in string.gmatch( memo_raw, mnee.PTN_1 ) do
		data[ value ] = 1
	end
	
	return data
end

function mnee.toggle_axis_memo( name )
	local storage = pen.get_storage( mnee.get_ctrl(), "mnee_axis_memo" ) or 0
	if( storage == 0 ) then
		return
	end
	local memo_raw = mnee.DIV_1
	local memo = mnee.get_axis_memo()
	if( memo[ name ] == nil ) then
		memo_raw = ComponentGetValue2( storage, "value_string" )..name..mnee.DIV_1
	else
		memo[ name ] = nil
		for nm in pairs( memo ) do
			memo_raw = memo_raw..nm..mnee.DIV_1
		end
	end
	ComponentSetValue2( storage, "value_string", memo_raw )
end

function mnee.order_sorter( tbl )
	return pen.magic_sorter( tbl, function( a, b )
		return (( tbl[a].order_id or a ) < ( tbl[b].order_id or b ))
	end)
end

function mnee.get_bindings( profile, binds_only )
	dofile_once( "mods/mnee/bindings.lua" )
	
	profile = profile or ModSettingGetNextValue( "mnee.PROFILE" )
	binds_only = binds_only or false
	
	local data_raw = {ModSettingGetNextValue( "mnee.BINDINGS_"..profile ), ModSettingGetNextValue( "mnee.BINDINGS_ALT_"..profile )}
	if( data_raw[1] == mnee.DIV_1 ) then
		return {}
	end
	
	local data = {}
	for i = 1,2 do
		for mod in string.gmatch( data_raw[i], mnee.PTN_1 ) do
			local mod_name = ""
			for v in string.gmatch( mod, mnee.PTN_2 ) do
				if( mod_name ~= "" ) then
					local binding_name = ""
					for b in string.gmatch( v, mnee.PTN_3 ) do
						if( binding_name ~= "" ) then
							local key_type = i == 1 and "keys" or "keys_alt"
							if( b == "is_axis" or data[ mod_name ][ binding_name ][ key_type ][1] == "is_axis" ) then
								table.insert( data[ mod_name ][ binding_name ][ key_type ], b )
							else
								data[ mod_name ][ binding_name ][ key_type ][ b ] = 1
							end
						elseif( binds_only or bindings[ mod_name ][ b ] ~= nil ) then
							binding_name = b
							if( i == 1 ) then
								data[ mod_name ][ binding_name ] = {}
								data[ mod_name ][ binding_name ][ "keys" ] = {}
								data[ mod_name ][ binding_name ][ "keys_alt" ] = {}
								if( not( binds_only )) then
									data[ mod_name ][ binding_name ][ "order_id" ] = bindings[ mod_name ][ binding_name ].order_id
									data[ mod_name ][ binding_name ][ "is_dirty" ] = bindings[ mod_name ][ binding_name ].is_dirty
									data[ mod_name ][ binding_name ][ "is_advanced" ] = bindings[ mod_name ][ binding_name ].is_advanced
									data[ mod_name ][ binding_name ][ "allow_special" ] = bindings[ mod_name ][ binding_name ].allow_special
									data[ mod_name ][ binding_name ][ "is_locked" ] = bindings[ mod_name ][ binding_name ].is_locked
									data[ mod_name ][ binding_name ][ "is_hidden" ] = bindings[ mod_name ][ binding_name ].is_hidden
									data[ mod_name ][ binding_name ][ "name" ] = bindings[ mod_name ][ binding_name ].name
									data[ mod_name ][ binding_name ][ "desc" ] = bindings[ mod_name ][ binding_name ].desc
									data[ mod_name ][ binding_name ][ "jpad_type" ] = bindings[ mod_name ][ binding_name ].jpad_type
									data[ mod_name ][ binding_name ][ "deadzone" ] = bindings[ mod_name ][ binding_name ].deadzone
									data[ mod_name ][ binding_name ][ "axes" ] = bindings[ mod_name ][ binding_name ].axes
								end
							end
						end
					end
				elseif( binds_only or bindings[ v ] ~= nil ) then
					mod_name = v
					if( i == 1 ) then data[ mod_name ] = {} end
				end
			end
		end
	end
	
	return data
end

function mnee.set_bindings( data, profile )
	if( data == nil ) then
		return
	end
	
	profile = profile or ModSettingGetNextValue( "mnee.PROFILE" )
	
	local data_raw = { mnee.DIV_1, mnee.DIV_1 }
	for i = 1,2 do
		local keys = i == 1 and "keys" or "keys_alt"
		for mod,binds in pairs( data ) do
			data_raw[i] = data_raw[i]..mnee.DIV_2..mod..mnee.DIV_2
			for bind,info in mnee.order_sorter( binds ) do
				data_raw[i] = data_raw[i]..mnee.DIV_3..bind..mnee.DIV_3
				if( info[keys] == nil ) then
					if( info["keys"] ~= nil and info["keys"][1] == "is_axis" ) then
						info[keys] = { "is_axis", "_" }
					else
						info[keys] = { ["_"] = 1 }
					end
				end
				for key,value in pairs( info[keys]) do
					data_raw[i] = data_raw[i]..( info[keys][1] == "is_axis" and value or key )..mnee.DIV_3
				end
				data_raw[i] = data_raw[i]..mnee.DIV_2
			end
			data_raw[i] = data_raw[i]..mnee.DIV_1
		end
	end
	
	ModSettingSetNextValue( "mnee.BINDINGS_"..profile, data_raw[1], false )
	ModSettingSetNextValue( "mnee.BINDINGS_ALT_"..profile, data_raw[2], false )
	GlobalsSetValue( mnee.UPDATER, GameGetFrameNum())
end

function mnee.update_bindings( profile, reset )
	dofile_once( "mods/mnee/bindings.lua" )
	
	reset = reset or false
	
	local default = bindings
	local current = mnee.get_bindings( profile, true )
	local updated = false
	if( reset ) then
		updated = true
		current = default
	else
		for mod,binds in pairs( default ) do
			if( current[ mod ] == nil ) then
				current[ mod ] = binds
				updated = true
			else
				for bind,info in pairs( binds ) do
					if( current[ mod ][ bind ] == nil ) then
						current[ mod ][ bind ] = info
						updated = true
					end
				end
			end
		end
	end
	if( updated ) then
		mnee.set_bindings( current, profile )
	end
end

function mnee.set_priority_mode( mod_id )
	GlobalsSetValue( mnee.PRIO_MODE, tostring( mod_id ))
end

function mnee.is_priority_mod( mod_id )
	local vip_mod = GlobalsGetValue( mnee.PRIO_MODE, "0" )
	if( vip_mod == "0" ) then
		return true
	end
	
	return mod_id ~= vip_mod
end

function mnee.get_fancy_key( key )
	local out, is_jpad = string.gsub( key, "%dgpd_", "" )
	local lists = dofile_once( "mods/mnee/lists.lua" )
	out = lists[5][out] or out
	if( is_jpad > 0 ) then
		out = "GP"..string.sub( key, 1, 1 ).."("..out..")"
	end
	return out
end

function mnee.get_binding_keys( mod_id, name, is_compact )
	is_compact = is_compact or false
	mnee_binding_data = mnee_binding_data or mnee.get_bindings()
	local binding = mnee_binding_data[ mod_id ][ name ]
	local out = ""
	if( binding.axes == nil ) then
		local function figure_it_out( tbl )
			local symbols = is_compact and {"","-","",","} or {"["," + ","]","/"}
			local out = symbols[1]
			if( tbl["_"] ~= nil or tbl[2] == "_" ) then
				out = GameTextGetTranslatedOrNot( "$mnee_nil" )
			elseif( tbl[1] == "is_axis" ) then
				out = out..mnee.get_fancy_key( tbl[2])
				if( tbl[3] ~= nil ) then
					out = out..symbols[4]..mnee.get_fancy_key( tbl[3])
				end
			else
				for key in pen.magic_sorter( tbl ) do
					out = out..mnee.get_fancy_key( key )..symbols[2]
				end
				out = string.sub( out, 1, -( #symbols[2] + 1 ))
			end
			return out..symbols[3]
		end

		out = figure_it_out( binding.keys )
		if( not( is_compact )) then
			if( not( binding.keys_alt["_"] ~= nil or binding.keys_alt[2] == "_" )) then
				out = out.." or "..figure_it_out( binding.keys_alt )
			end
		end
		
		if( is_compact ) then out = string.lower( out ) end
	else
		local symbols = is_compact and {"|","v:","; h:"} or {"|","ver: ","; hor: "}
		local v = mnee.get_binding_keys( mod_id, binding.axes[1], is_compact )
		local h = mnee.get_binding_keys( mod_id, binding.axes[2], is_compact )
		out = symbols[1]..symbols[2]..v..symbols[3]..h..symbols[1]
	end

	return out
end

function mnee.bind2string( binds, bind, key_type )
	local out = "["
	if( bind.axes ~= nil ) then
		out = "|"
		out = out..mnee.bind2string( nil, binds[bind.axes[1]], key_type ).."|"
		out = out..mnee.bind2string( nil, binds[bind.axes[2]], key_type ).."|"
	else
		local b = bind[key_type]
		if( b[1] == "is_axis" ) then
			out = out..b[2]
			if( b[3] ~= nil ) then
				out = out.."; "..b[3]
			end
		else
			for b in pairs( b ) do
				out = out..( out == "[" and "" or "; " )..b
			end
		end
		out = out.."]"
	end
	return out
end

function mnee.get_shifted_key( c )
	local check = string.byte( c ) 
	if( check > 96 and check < 123 ) then
		return string.char( check - 32 )
	else
		local lists = dofile_once( "mods/mnee/lists.lua" )
		return lists[4][c] or c
	end
end

function mnee.new_tooltip( gui, uid, pic_z, text )
	if( not( tooltip_opened )) then
		local _, _, t_hov = GuiGetPreviousWidgetInfo( gui )
		if( t_hov ) then
			tooltip_opened = true
			local w, h = GuiGetScreenDimensions( gui )
			local pic_x, pic_y = pen.get_mouse_pos( gui )
			pic_x = pic_x + 10
			
			if( text == "" ) then
				return uid
			end
			
			text = pen.liner( text, w*0.9, h - 2, 5.8 )
			local length = 0
			for i,line in ipairs( text ) do
				local current_length = GuiGetTextDimensions( gui, line, 1, 2 )
				if( current_length > length ) then
					length = current_length
				end
			end
			local extra = #text > 1 and 3 or 0
			local x_offset = length + extra
			local y_offset = 9*#text + 1 + extra - ( #text > 1 and 3 or 0 )
			if( w < pic_x + x_offset ) then
				pic_x = w - x_offset
			end
			if( h < pic_y + y_offset ) then
				pic_y = h - y_offset
			end
			uid = pen.new_image( gui, uid, pic_x, pic_y, pic_z, "mods/mnee/files/pics/dot_purple_dark.png", x_offset, y_offset )
			uid = pen.new_image( gui, uid, pic_x + 1, pic_y + 1, pic_z - 0.01, "mods/mnee/files/pics/dot_white.png", x_offset - 2, y_offset - 2 )
			
			pen.new_text( gui, pic_x + 2, pic_y, pic_z - 0.02, text, {136,121,247})
		end
	end
	
	return uid
end

function mnee.new_pager( gui, uid, pic_x, pic_y, pic_z, page, max_page, profile_mode )
	profile_mode = profile_mode or false

	local clicked, r_clicked = 0, 0, 0
	uid, clicked, r_clicked = pen.new_button( gui, uid, pic_x, pic_y, pic_z, "mods/mnee/files/pics/key_left.png" )
	if( clicked and max_page > 1 ) then
		pen.play_sound( "button_special" )
		page = page - 1
		if( page < 1 ) then
			page = max_page
		end
	end
	if( r_clicked and max_page > 5 ) then
		pen.play_sound( "switch_page" )
		page = page - 5
		if( page < 1 ) then
			page = max_page + page
		end
	end
	
	if( profile_mode ) then
		pic_y = pic_y + 11
	else
		pic_x = pic_x + 11
	end
	uid = pen.new_button( gui, uid, pic_x, pic_y, pic_z, "mods/mnee/files/pics/button_21_B.png" )
	if( profile_mode ) then
		uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_this_profile" ).."." )
	end
	pen.new_text( gui, pic_x + 2, pic_y, pic_z - 0.01, tostring( profile_mode and string.char( page + 64 ) or page ), {136,121,247})
	
	pic_x = pic_x + 22
	if( profile_mode ) then
		pic_x = pic_x - 11
		pic_y = pic_y - 11
	end
	uid, clicked, r_clicked = pen.new_button( gui, uid, pic_x, pic_y, pic_z - 0.01, "mods/mnee/files/pics/key_right.png" )
	if( clicked and max_page > 1 ) then
		pen.play_sound( "button_special" )
		page = page + 1
		if( page > max_page ) then
			page = 1
		end
	end
	if( r_clicked and max_page > 5 ) then
		pen.play_sound( "switch_page" )
		page = page + 5
		if( page > max_page ) then
			page = page - max_page
		end
	end
	
	if( max_page > 0 and page > max_page ) then
		page = max_page
	end
	
	return uid, page
end

function mnee.get_keyboard_input( no_shifting )
	no_shifting = no_shifting or false
	local lists = dofile_once( "mods/mnee/lists.lua" )

	local is_shifted = not( no_shifting ) and ( InputIsKeyDown( 225 ) or InputIsKeyDown( 229 ))
	for i = 4,56 do
		if( InputIsKeyJustDown( i )) then
			local value = lists[1][i]
			if( is_shifted ) then
				value = mnee.get_shifted_key( value )
			elseif( i > 39 and i < 45 ) then
				if( i == 40 ) then
					value = 3
				elseif( i == 41 ) then
					value = 0
				elseif( i == 42 ) then
					value = 2
				elseif( i == 43 ) then
					value = 4
				elseif( i == 44 ) then
					value = " "
				end
			end
			return value
		end
	end
	for i = 1,10 do
		if( InputIsKeyJustDown( 88 + i )) then
			return string.sub( tostring( i ), -1 )
		end
	end
end

function mnee.mnin_key( name, dirty_mode, pressed_mode, is_vip, key_mode )
	dirty_mode = dirty_mode or false
	pressed_mode = pressed_mode or false
	is_vip = is_vip or false
	
	if(( GameHasFlagRun( mnee.SERV_MODE ) and not( mnee_ignore_service_mode ))
			or ( GameHasFlagRun( mnee.TOGGLER ) and not( is_vip ))
		) then
		return false
	end
	
	local keys_down = mnee.get_keys( key_mode )
	if( #keys_down > 0 ) then
		if( not( dirty_mode )) then
			for i,key in ipairs( keys_down ) do
				if( mnee.SPECIAL_KEYS[ key ] ~= nil ) then
					return false
				end
			end
		end
		
		for i,key in ipairs( keys_down ) do
			if( key == name ) then
				if( pressed_mode ) then
					local check = mnee.get_disarmer()[ "key"..key ] == nil
					mnee.add_disarmer( "key"..key )
					return check
				else
					return true
				end
			end
		end
	end
	
	return false
end

function mnee.jpad_check( keys )
	for key,val in pairs( keys ) do
		if( string.find( type( key ) == "number" and val or key, "%dgpd_" ) ~= nil ) then
			return true
		end
	end
	return false
end

function mnee.mnin_bind( mod_id, name, dirty_mode, pressed_mode, is_vip, loose_mode, key_mode )
	dirty_mode = dirty_mode or false
	pressed_mode = pressed_mode or false
	is_vip = is_vip or false
	loose_mode = loose_mode or false
	
	if(( GameHasFlagRun( mnee.SERV_MODE ) and not( mnee_ignore_service_mode ))
			or not( mnee.is_priority_mod( mod_id ))
			or ( GameHasFlagRun( mnee.TOGGLER ) and not( is_vip ))
		) then
		return false, false, false
	end
	
	local keys_down = mnee.get_keys( key_mode )
	if( #keys_down > 0 ) then
		local update_frame = tonumber( GlobalsGetValue( mnee.UPDATER, "0" ))
		mnee_updater = mnee_updater or 0
		if( mnee_updater ~= update_frame ) then
			mnee_updater = update_frame
			mnee_binding_data = nil
		end
		mnee_binding_data = mnee_binding_data or mnee.get_bindings()
		
		local binding = mnee_binding_data[ mod_id ][ name ]
		if( binding ~= nil ) then
			local out, is_gone, is_jpad = false, true, false
			for i = 1,2 do
				local bind = binding[ i == 1 and "keys" or "keys_alt" ]
				local high_score, score = pen.get_table_count( bind ), 0

				if( bind["_"] ~= nil ) then
					goto continue
				end
				is_gone = false
				if( high_score < 1 or ( high_score > 1 and not( loose_mode ) and high_score ~= #keys_down )) then
					goto continue
				end
				
				if( high_score == 1 and not( dirty_mode )) then
					for i,key in ipairs( keys_down ) do
						if( mnee.SPECIAL_KEYS[ key ] ~= nil ) then
							out = true
						end
					end
					if( out ) then
						out = false
						goto continue
					end
				end
				
				for i,key in ipairs( keys_down ) do
					if( bind[ key ] ~= nil ) then
						score = score + 1
					end
				end
				
				if( score == high_score ) then
					if( pressed_mode ) then
						local check = mnee.get_disarmer()[ mod_id..name ] == nil
						mnee.add_disarmer( mod_id..name )
						if( not( check )) then return false, false, false end
						out = check
					else
						out = true
					end
				end
				
				::continue::
				if( out ) then
					is_jpad = mnee.jpad_check( bind )
					break
				end
			end
			return out, is_gone, is_jpad
		end
	end
	
	return false, false, false
end

function mnee.apply_deadzone( v, kind, zero_offset )
	if( v == 0 ) then return 0 end
	kind = kind or "EXTRA"
	zero_offset = ModSettingGetNextValue( "mnee.LIVING" ) and 0 or ( zero_offset or 0 )

	local total = 1000
	local deadzone = total*math.min( zero_offset + ModSettingGetNextValue( "mnee.DEADZONE_"..kind )/20, 0.999 )
	v = math.floor( total*v )
	v = math.abs( v ) < deadzone and 0 or v
	if( math.abs( v ) > 0 ) then
		v = ( v - deadzone*pen.get_sign( v ))/( total - deadzone )
	end
	return v
end

function mnee.aim_assist( hooman, pos, angle, is_active, data )
	if( is_active ~= nil and not( is_active )) then
		return angle, false
	end

	data = data or {}
	data.setting = data.setting or "mnee.AUTOAIM"
	data.tag_tbl = data.tag_tbl or {"enemy"}
	data.pic = data.pic or "mods/mnee/files/pics/autoaim.png"
	
	local safe_zone = 50
	local max_distance = 100
	local ray_x, ray_y = max_distance*math.cos( angle ), max_distance*math.sin( angle )
	local is_hit, hit_x, hit_y = RaytracePlatforms( pos[1], pos[2], pos[1] + ray_x, pos[2] + ray_y )
	if( not( is_hit )) then
		hit_x, hit_y = pos[1] + ray_x, pos[2] + ray_y
	end
	
	local dir_x = pen.get_sign( hit_x - pos[1])
	local dir_y = pen.get_sign( hit_y - pos[2])

	local the_one = 0
	local meats = {}
	for i = 1,#data.tag_tbl do
		meats = pen.add_table( meats, EntityGetInRadiusWithTag( hit_x, hit_y, max_distance, data.tag_tbl[i]) or {})
	end
	local min_dist = -1
	for i,meat in ipairs( meats ) do
		local t_x, t_y = pen.get_creature_head( meat, EntityGetTransform( meat ))
		if( EntityGetRootEntity( meat ) == meat and hooman ~= meat and not( RaytracePlatforms( pos[1], pos[2], t_x, t_y ))) then
			local t_delta_x = t_x - pos[1]
			local t_delta_y = t_y - pos[2]
			local dist_p = math.sqrt(( t_delta_x )^2 + ( t_delta_y )^2 )
			local dist_h = math.sqrt(( t_x - hit_x )^2 + ( t_y - hit_y )^2 )
			local dist = 0.75*dist_p + 0.25*dist_h
			local t_dir_x, t_dir_y = pen.get_sign( t_delta_x ), pen.get_sign( t_delta_y )
			if(( math.abs( t_delta_x ) < safe_zone or t_dir_x == dir_x ) and ( math.abs( t_delta_y ) < safe_zone or t_dir_y == dir_y )) then
				if( min_dist == -1 or dist < min_dist ) then
					min_dist = dist
					the_one = meat
				end
			end
		end
	end
	
	local is_done = false
	if( the_one > 0 ) then
		local t_x, t_y = pen.get_creature_head( the_one, EntityGetTransform( the_one ))
		local t_angle = math.atan2(( t_y - pos[2]), ( t_x - pos[1]))
		local delta_a = pen.get_angular_delta( t_angle, angle )
		
		local autoaim = ModSettingGetNextValue( data.setting )
		if( autoaim > 0.1 ) then
			is_done = true
			local strength = 0.1*autoaim
			local min_offset = math.rad( 0.5 )*autoaim
			angle = angle + pen.limiter( pen.limiter( strength*delta_a, min_offset, true ), delta_a )
			if( data.pic ~= "" ) then
				GameCreateSpriteForXFrames( data.pic, t_x, t_y, true, 0, 0, 1, true )
			end
		end
	end

	return angle, is_done
end

function mnee.mnin_axis( mod_id, name, dirty_mode, pressed_mode, is_vip, key_mode, skip_deadzone )
	dirty_mode = dirty_mode or false
	pressed_mode = pressed_mode or false
	is_vip = is_vip or false
	skip_deadzone = skip_deadzone or false
	
	if(( GameHasFlagRun( mnee.SERV_MODE ) and not( mnee_ignore_service_mode ))
			or not( mnee.is_priority_mod( mod_id ))
			or ( GameHasFlagRun( mnee.TOGGLER ) and not( is_vip ))
		) then
		return 0, false, false, false
	end
	
	local update_frame = tonumber( GlobalsGetValue( mnee.UPDATER, "0" ))
	mnee_updater = mnee_updater or 0
	if( mnee_updater ~= update_frame ) then
		mnee_updater = update_frame
		mnee_binding_data = nil
	end
	mnee_binding_data = mnee_binding_data or mnee.get_bindings()
	
	local binding = mnee_binding_data[ mod_id ][ name ]
	if( binding ~= nil ) then
		local out, is_gone, is_buttoned, is_jpad = 0, true, false, false
		for i = 1,2 do
			local bind = binding[ i == 1 and "keys" or "keys_alt" ]
			if( bind[2] == "_" ) then
				goto continue
			end
			is_gone = false
			
			is_buttoned = bind[3] ~= nil
			if( is_buttoned ) then
				if( mnee.mnin_key( bind[2], dirty_mode, pressed_mode, is_vip, key_mode )) then
					out = -1
				elseif( mnee.mnin_key( bind[3], dirty_mode, pressed_mode, is_vip, key_mode )) then
					out = 1
				end
			else
				local value = mnee.get_axes()[ bind[2]] or 0
				if( not( skip_deadzone )) then
					value = mnee.apply_deadzone( value, binding.jpad_type, binding.deadzone )
				end
				if( pressed_mode ) then
					local memo = mnee.get_axis_memo()
					if( memo[ bind[2]] == nil ) then
						if( math.abs( value ) > 0.5 ) then
							mnee.toggle_axis_memo( bind[2])
							out = pen.get_sign( value )
						end
					elseif( math.abs( value ) < 0.2 ) then
						mnee.toggle_axis_memo( bind[2])
					end
				else
					out = value
				end
			end
			
			::continue::
			if( out ~= 0 ) then
				is_jpad = mnee.jpad_check( bind )
				break
			end
		end
		return out, is_gone, is_buttoned, is_jpad
	end

	return 0, false, false, false
end

function mnee.mnin_stick( mod_id, name, dirty_mode, pressed_mode, is_vip, key_mode )
	dirty_mode = dirty_mode or false
	pressed_mode = pressed_mode or false
	is_vip = is_vip or false

	if(( GameHasFlagRun( mnee.SERV_MODE ) and not( mnee_ignore_service_mode ))
			or not( mnee.is_priority_mod( mod_id ))
			or ( GameHasFlagRun( mnee.TOGGLER ) and not( is_vip ))
		) then
		return {0,0}, false, {false,false}, 0
	end
	
	local update_frame = tonumber( GlobalsGetValue( mnee.UPDATER, "0" ))
	mnee_updater = mnee_updater or 0
	if( mnee_updater ~= update_frame ) then
		mnee_updater = update_frame
		mnee_binding_data = nil
	end
	mnee_binding_data = mnee_binding_data or mnee.get_bindings()
	
	local binding = mnee_binding_data[ mod_id ][ name ]
	if( binding ~= nil ) then
		local val_x, gone_x, buttoned_x = mnee.mnin_axis( mod_id, binding.axes[1], dirty_mode, pressed_mode, is_vip, key_mode, true )
		local val_y, gone_y, buttoned_y = mnee.mnin_axis( mod_id, binding.axes[2], dirty_mode, pressed_mode, is_vip, key_mode, true )
		local magnitude = mnee.apply_deadzone( math.sqrt( val_x^2 + val_y^2 ), binding.jpad_type, binding.deadzone )
		local direction = math.atan2( val_y, val_x )
		val_x, val_y = magnitude*math.cos( direction ), magnitude*math.sin( direction )
		return {val_x,val_y}, gone_x or gone_y, {buttoned_x,buttoned_y}, direction
	end

	return {0,0}, false, {false,false}, 0
end

function mnee.mnin( mode, id_data, data )
	local map = {
		key = { mnee.mnin_key, {1}, { "dirty", "pressed", "vip", "mode" }},
		bind = { mnee.mnin_bind, {1,2}, { "dirty", "pressed", "vip", "loose", "mode" }},
		axis = { mnee.mnin_axis, {1,2}, { "dirty", "pressed", "vip", "mode" }},
		stick = { mnee.mnin_stick, {1,2}, { "dirty", "pressed", "vip", "mode" }},
	}
	if( type( id_data ) ~= "table" ) then id_data = {id_data} end
	data = data or {}
	func = map[ mode ]

	local inval = {}
	for i,v in ipairs( func[2]) do
		if( id_data[v] ~= nil ) then table.insert( inval, id_data[v]) end
	end
	for i,v in ipairs( func[3]) do
		table.insert( inval, data[v] or false )
	end
	
	local a,b,c,d,e = func[1]( inval[1], inval[2], inval[3], inval[4], inval[5], inval[6], inval[7], inval[8], inval[9])
	return a,b,c,d,e
end

--[LEGACY]
function is_key_down( name, dirty_mode, pressed_mode, is_vip, key_mode )
	return mnee.mnin_key( name, dirty_mode, pressed_mode, is_vip, key_mode )
end
function get_key_pressed( name, dirty_mode, is_vip )
	return is_key_down( name, dirty_mode, true, is_vip )
end
function get_key_vip( name )
	return get_key_pressed( name, true, true )
end

function is_binding_down( mod_id, name, dirty_mode, pressed_mode, is_vip, loose_mode, key_mode )
	return mnee.mnin_bind( mod_id, name, dirty_mode, pressed_mode, is_vip, loose_mode, key_mode )
end
function get_binding_pressed( mod_id, name, is_vip, dirty_mode, loose_mode )
	return is_binding_down( mod_id, name, dirty_mode, true, is_vip, loose_mode )
end
function get_binding_vip( mod_id, name )
	return get_binding_pressed( mod_id, name, true, true, true )
end

function get_axis_state( mod_id, name, dirty_mode, pressed_mode, is_vip, key_mode )
	return mnee.mnin_axis( mod_id, name, dirty_mode, pressed_mode, is_vip, key_mode )
end
function get_axis_pressed( mod_id, name, dirty_mode, is_vip )
	return get_axis_state( mod_id, name, dirty_mode, true, is_vip )
end
function get_axis_vip( mod_id, name )
	return get_axis_pressed( mod_id, name, true, true )
end
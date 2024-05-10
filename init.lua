ModRegisterAudioEventMappings( "mods/mnee/files/sfx/GUIDs.txt" )
get_active_keys = get_active_keys or ( function() return "huh?" end )

function OnModInit()
	dofile_once( "mods/mnee/lib.lua" )
	pen.set_translations( "mods/mnee/files/translations.csv" )
	
	-- update translations in settings
	-- make procedural pause screen keyboard that highlights all the bind's keys on hover of one of them (only if the moddev marked the binding as show_on_pause)
	
	local lists = dofile_once( "mods/mnee/lists.lua" )
	local keycaps = lists[1]
	local mouse = lists[2]
	local jcaps = lists[3]

	jpad_count = 0
	jpad_states = jpad_states or { -1, -1, -1, -1 }
	jpad = jpad or { false, false, false, false }
	jpad_update = function( num )
		if( num < 0 ) then
			jpad_states[ jpad[ math.abs( num )] + 1 ] = 1
			jpad[ math.abs( num )] = false
		else
			local val = mnee.get_next_jpad()
			if( val ) then
				jpad[num] = val
			end
			return val
		end
	end

	local divider = "&"
	get_active_keys = function()
		local active = divider
		
		--keyboard
		for i,key in ipairs( keycaps ) do
			if( key ~= "[NONE]" ) then
				if( InputIsKeyDown( i ) and ( key ~= "left_windows" and key ~= "right_windows" )) then
					active = active..key..divider
				end
			end
		end
		
		--mouse
		for i,key in ipairs( mouse ) do
			if( InputIsMouseButtonDown( i )) then
				active = active..key..divider
			end
		end
		
		--gamepad; add rumbling
		if( #jpad > 0 ) then
			for i,real_num in ipairs( jpad ) do
				if( real_num ) then
					for k,key in ipairs( jcaps ) do
						if( key ~= "[NONE]" ) then
							if( InputIsJoystickButtonDown( real_num, k )) then
								active = active..i.."gpd_"..key..divider
							end
						end
					end
					for k = 0,1 do
						if( InputGetJoystickAnalogButton( real_num, k ) > 0.5 ) then
							active = active..i.."gpd_"..( k == 0 and "l2" or "r2" )..divider
						end
					end
				end
			end
		end
		
		return active
	end
	
	get_current_triggers = function()
		local state = divider
		if( #jpad > 0 ) then
			for i,real_num in ipairs( jpad ) do
				if( real_num ) then
					for k = 0,1 do
						local v = math.floor( 100*InputGetJoystickAnalogButton( real_num, k ) + 0.5 )/100
						local name = i.."gpd_"..( k == 0 and "left" or "right" )
						state = state.."|"..name.."|"..v.."|"..divider
					end
				end
			end
		end

		return state
	end

	get_current_axes = function()
		local state = divider
		if( #jpad > 0 ) then
			local gpd_axis = { "_lh", "_lv", "_rh", "_rv", }
			for i,real_num in ipairs( jpad ) do
				if( real_num ) then
					for e = 0,1 do
						local value = { InputGetJoystickAnalogStick( real_num, e )}
						for k = 1,2 do
							local name = i.."gpd_axis"..gpd_axis[e*2 + k]
							state = state.."|"..name.."|"..value[k].."|"..divider
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
		local storage = pen.get_storage( ctrl_body, "mnee_down" ) or 0
		if( storage ~= 0 ) then
			mnee.get_next_jpad( true )
			ComponentSetValue2( pen.get_storage( ctrl_body, "mnee_axis" ), "value_string", get_current_axes())
			ComponentSetValue2( pen.get_storage( ctrl_body, "mnee_triggers" ), "value_string", get_current_triggers())

			local active_core = get_active_keys()
			local axis_core = mnee.get_axes()
			for bnd,v in pairs( axis_core ) do
				if( v ~= 0 ) then
					active_core = active_core..string.gsub( bnd, "gpd_axis", "gpd_btn" ).."_"..( v > 0 and "+" or "-" ).."&"
				end
			end
			for mode,func in pairs( mnee.INMODES ) do
				local name = "mnee_down_"..mode
				local stg = pen.get_storage( ctrl_body, name ) or 0
				if( stg == 0 ) then
					stg = EntityAddComponent( ctrl_body, "VariableStorageComponent", 
					{
						name = name,
						value_string = mnee.DIV_1,
					})
				end
				ComponentSetValue2( stg, "value_string", func( ctrl_body, active_core ))
			end
			ComponentSetValue2( storage, "value_string", active_core )
			
			mnee.clean_disarmer()
			if( mnee.mnin( "bind", { "mnee", "menu" }, { pressed = true, vip = true })) then
				if( gui_active ) then
					gui_active = false
					pen.play_sound( "close_window" )
				else
					gui_active = true
					pen.play_sound( "open_window" )
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
				pen.play_sound( has_flag and "capture" or "uncapture" )
			end
			if( mnee.mnin( "bind", { "mnee", "profile_change" }, { pressed = true })) then
				local prf = ModSettingGetNextValue( "mnee.PROFILE" ) + 1
				prf = prf > 3 and 1 or prf
				ModSettingSetNextValue( "mnee.PROFILE", prf, false )
				GamePrint( GameTextGetTranslatedOrNot( "$mnee_this_profile" )..": "..string.char( prf + 64 ))
				pen.play_sound( "switch_page" )
				GlobalsSetValue( mnee.UPDATER, GameGetFrameNum())
			end
		end
		
		local is_auto = ModSettingGetNextValue( "mnee.CTRL_AUTOMAPPING" )
		local gslot_update = { false, false, false, false, }
		
		if( not( GameIsInventoryOpen())) then --use index-compatible check from Penman
			if( gui == nil ) then
				gui = GuiCreate()
			end
			GuiStartFrame( gui )

			if( ctl_panel == nil ) then
				ctl_panel = jpad_count > 0
			end

			local keys = mnee.get_bindings()
			local is_disabled = GameHasFlagRun( mnee.TOGGLER )
			local key_type = show_alt and "keys_alt" or "keys"

			local clicked, r_clicked, pic_z = 0, 0, -50
			local uid = 0
			if( gui_active ) then
				if( current_binding == "" ) then
					local pic = "mods/mnee/files/pics/window.png"
					local pic_w, pic_h = GuiGetImageDimensions( gui, pic, 1 )
					if( pic_x == nil ) then
						local screen_w, screen_h = GuiGetScreenDimensions( gui )
						pic_x = ( screen_w - pic_w )/2
					end

					local txt = GameTextGetTranslatedOrNot( "$mnee_title"..( show_alt and "B" or "A" ))
					if( show_alt ) then uid = pen.new_image( gui, uid, pic_x, pic_y, pic_z - 0.001, "mods/mnee/files/pics/title_bg.png" ) end
					pen.new_text( gui, pic_x + 142 - GuiGetTextDimensions( gui, txt, 1, 2 ), pic_y, pic_z - 0.01, txt, show_alt and {136,121,247} or {238,226,206})

					uid, clicked = pen.new_button( gui, uid, pic_x + pic_w - 8, pic_y + 2, pic_z - 0.01, "mods/mnee/files/pics/key_close.png" )
					uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_close" ))
					if( clicked ) then
						gui_active = false
						pen.play_sound( "close_window" )
					end

					uid, clicked = pen.new_button( gui, uid, pic_x + pic_w - 15, pic_y + 2, pic_z - 0.01, "mods/mnee/files/pics/key_"..( show_alt and "B" or "A" )..".png" )
					uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_alt"..( show_alt and "B" or "A" )))
					if( clicked ) then
						show_alt = not( show_alt )
						pen.play_sound( "button_special" )
					end
					
					local counter = 1
					local starter = 8*mod_page - 8
					local ender = 8*mod_page + 1
					local t_x, t_y = pic_x + 2, pic_y
					for mod in pen.magic_sorter( keys ) do
						if( counter > starter and counter < ender ) then
							local is_fancy = mneedata[mod] ~= nil
							if( not( is_fancy ) or ( is_fancy and not( pen.get_hybrid_function( mneedata[mod].is_hidden, {mod, jpad})))) then
								t_y = t_y + 11
								
								local name = pen.get_translated_line( is_fancy and mneedata[mod].name or mod )
								uid, clicked = pen.new_button( gui, uid, t_x, t_y, pic_z - 0.01, "mods/mnee/files/pics/button_43_"..( current_mod == mod and "B" or "A" )..".png" )
								uid = mnee.new_tooltip( gui, uid, pic_z - 200, name..( current_mod == mod and (( is_fancy and mneedata[mod].desc ~= nil ) and " @ "..pen.get_translated_line( mneedata[mod].desc ) or "" ) or " @ "..GameTextGetTranslatedOrNot( "$mnee_lmb_keys" )))
								pen.new_text( gui, t_x + 2, t_y, pic_z - 0.02, pen.liner( name, 39 ), current_mod == mod and {245,132,132} or {238,226,206})
								if( clicked ) then
									current_mod = mod
									pen.play_sound( "button_special" )
								end
								
								counter = counter + 1
							end
						end
					end
					
					local page = mod_page
					uid, page = mnee.new_pager( gui, uid, pic_x + 2, pic_y + 99, pic_z - 0.01, page, math.ceil(( counter - 1 )/8 ))
					if( mod_page ~= page ) then
						mod_page = page
					end
					
					local meta = {}
					if( mneedata[current_mod] ~= nil ) then
						meta.func = mneedata[current_mod].func
						meta.is_advanced = mneedata[current_mod].is_advanced or false
						meta.is_locked = pen.get_hybrid_function( mneedata[current_mod].is_locked, {current_mod, jpad}) or false
					end

					counter = 1
					starter = 8*binding_page - 8
					ender = 8*binding_page + 1
					t_x, t_y = pic_x + 48, pic_y
					if( meta.func ~= nil ) then
						local result = false
						uid, result = pen.catch( meta.func, { gui, uid, t_x, t_y, pic_z - 0.01, {
							a = starter,
							b = ender,
							ks = keys,
							k_type = key_type,
						}}, {uid,false})
						if( result ) then
							current_binding = result.set_bind
							doing_axis = result.will_axis
							btn_axis_mode = result.btn_axis
							advanced_mode = result.set_advanced
						end
					else
						for id,bind in mnee.order_sorter( keys[ current_mod ]) do
							local will_show = counter > starter and counter < ender
							if( will_show ) then
								will_show = not( pen.get_hybrid_function( bind.is_hidden, {{current_mod,id}, jpad}))
							end
							if( will_show ) then
								t_y = t_y + 11
								
								local is_axis = bind[key_type][1] == "is_axis"
								local is_static = bind.is_locked
								if( is_static == nil ) then
									is_static = meta.is_locked or false
								else
									is_static = pen.get_hybrid_function( is_static, {{current_mod,id}, jpad})
								end
								
								uid, clicked, r_clicked = pen.new_button( gui, uid, t_x, t_y, pic_z - 0.01, "mods/mnee/files/pics/button_74_"..( is_static and "B" or "A" )..".png" )
								pen.catch(function()
									uid = mnee.new_tooltip( gui, uid, pic_z - 200, ( is_axis and ( GameTextGet( "$mnee_axis", bind.jpad_type or "EXTRA" )..( is_static and "" or " @ " )) or "" )..( is_static and GameTextGetTranslatedOrNot( "$mnee_static" ).." @ " or "" )..pen.get_translated_line( bind.name )..": "..pen.get_translated_line( bind.desc ).." @ "..mnee.bind2string( bind[key_type])..( is_axis and " @ "..GameTextGetTranslatedOrNot( "$mnee_lmb_axis" ) or "" ))
									pen.new_text( gui, t_x + 2, t_y, pic_z - 0.02, pen.liner( pen.get_translated_line( bind.name ), 70 ), is_static and {136,121,247} or {238,226,206})
								end)
								if( clicked or r_clicked ) then
									if( not( is_static )) then
										current_binding = id
										doing_axis = is_axis
										btn_axis_mode = is_axis and r_clicked
										pen.play_sound( "select" )

										advanced_mode = bind.is_advanced
										if( advanced_mode == nil ) then advanced_mode = meta.is_advanced or false end
										advanced_mode = advanced_mode or ( r_clicked and not( is_axis ))
									else
										GamePrint( GameTextGetTranslatedOrNot( "$mnee_error" ).." "..GameTextGetTranslatedOrNot( "$mnee_no_change" ))
										pen.play_sound( "error" )
									end
								end
								
								uid, clicked, r_clicked = pen.new_button( gui, uid, t_x + 75, t_y, pic_z - 0.01, "mods/mnee/files/pics/key_delete.png" )
								uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_rmb_default" ))
								if( r_clicked ) then
									dofile( "mods/mnee/bindings.lua" )
									keys[ current_mod ][ id ][ key_type ] = bindings[ current_mod ][ id ][ key_type ]
									mnee.set_bindings( keys )
									pen.play_sound( "clear_all" )
								end

								counter = counter + 1
							end
						end
					end
					
					page = binding_page
					uid, page = mnee.new_pager( gui, uid, pic_x + 48, pic_y + 99, pic_z - 0.01, page, math.ceil(( counter - 1 )/8 ))
					if( binding_page ~= page ) then
						binding_page = page
					end
					
					uid = pen.new_button( gui, uid, pic_x + 101, pic_y + 99, pic_z - 0.01, "mods/mnee/files/pics/help.png" )
					uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_lmb_bind" ).." @ "..GameTextGetTranslatedOrNot( "$mnee_rmb_advanced" ).." @ "..GameTextGetTranslatedOrNot( "$mnee_alt_help" ))
					
					uid, clicked, r_clicked = pen.new_button( gui, uid, pic_x + 112, pic_y + 99, pic_z - 0.01, "mods/mnee/files/pics/button_dft.png" )
					uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_rmb_mod" ))
					if( r_clicked ) then
						dofile( "mods/mnee/bindings.lua" )
						keys[ current_mod ] = bindings[ current_mod ]
						mnee.set_bindings( keys )
						pen.play_sound( "clear_all" )
					end
					
					uid, clicked = pen.new_button( gui, uid, pic_x + 136, pic_y + 11, pic_z - 0.01, "mods/mnee/files/pics/button_tgl_"..( is_disabled and "A" or "B" )..".png" )
					uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_lmb_input"..( is_disabled and "A" or "B" )))
					if( clicked ) then
						if( is_disabled ) then
							GameRemoveFlagRun( mnee.TOGGLER )
							pen.play_sound( "capture" )
						else
							GameAddFlagRun( mnee.TOGGLER )
							pen.play_sound( "uncapture" )
						end
					end
					
					uid, clicked, r_clicked = pen.new_button( gui, uid, pic_x + 136, pic_y + 22, pic_z - 0.01, "mods/mnee/files/pics/button_rst.png" )
					uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_rmb_reset" ))
					if( r_clicked ) then
						for i = 1,3 do
							ModSettingSetNextValue( "mnee.BINDINGS_"..i, "&", false )
							ModSettingSetNextValue( "mnee.BINDINGS_ALT_"..i, "&", false )
							mnee.update_bindings( i )
						end
						pen.play_sound( "delete" )
					end
					
					--[[if( io ~= nil ) then --does not backup the secondary binds
						uid, clicked, r_clicked = new_button( gui, uid, pic_x + 136, pic_y + 66, pic_z - 0.01, "mods/mnee/files/pics/button_bkp.png" )
						uid = new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_lmb_backup" ))
						if( clicked ) then
							local cout = "@"
							for i = 1,3 do
								cout = cout..ModSettingGetNextValue( "mnee.BINDINGS_"..i ).."@"
							end
							local file,err = io.open( "mods/mnee/_backup.txt", 'w' )
							if( file ) then
								file:write( tostring( cout ))
								file:close()
								play_sound( "minimize" )
							else
								GamePrint( GameTextGetTranslatedOrNot( "$mnee_error" )..": ", err )
								play_sound( "error" )
							end
						end
						if( r_clicked ) then
							local file,err = io.open( "mods/mnee/_backup.txt", 'r' )
							if( file ) then
								local cin = file:read() or ""
								file:close()
								if( cin ~= "" ) then
									local i = 1
									for value in string.gmatch( cin, MNEE_PTN_0 ) do
										ModSettingSetNextValue( "mnee.BINDINGS_"..i, value, false )
										update_bindings( i )
										i = i + 1
									end
									play_sound( "unminimize" )
								else
									GamePrint( GameTextGetTranslatedOrNot( "$mnee_no_backups" ))
									play_sound( "error" )
								end
							else
								GamePrint( GameTextGetTranslatedOrNot( "$mnee_error" )..": ", err )
								play_sound( "error" )
							end
						end
					end]]

					uid, clicked = pen.new_button( gui, uid, pic_x + 136, pic_y + 77, pic_z - 0.01, "mods/mnee/files/pics/button_ctl_"..( ctl_panel and "B" or "A" )..".png" )
					uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_lmb_jpads" ))
					if( clicked ) then
						if( ctl_panel ) then
							ctl_panel = false
							pen.play_sound( "close_window" )
						else
							ctl_panel = true
							pen.play_sound( "open_window" )
						end
					end
					if( ctl_panel ) then
						if( is_auto ) then
							uid = pen.new_anim( gui, uid, 1, pic_x + 160, pic_y + 55, pic_z, "mods/mnee/files/pics/scan/", 20, 5 )
						else
							uid = pen.new_image( gui, uid, pic_x + 160, pic_y + 55, pic_z, "mods/mnee/files/pics/scan/0.png" )
						end
						uid, clicked, r_clicked = pen.new_button( gui, uid, pic_x + 160, pic_y + 55, pic_z - 0.01, "mods/mnee/files/pics/scan/_hitbox.png" )
						uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGet( "$mnee_jpad_count", jpad_count ).." @ "..GameTextGetTranslatedOrNot( "$mnee_rmb_scan"..( is_auto and "B" or "A" )))  
						if( r_clicked ) then
							ModSettingSetNextValue( "mnee.CTRL_AUTOMAPPING", not( is_auto ), false )
							pen.play_sound( "button_special" )
						end
						
						for i = 1,4 do
							local is_real = jpad[i]
							uid, clicked, r_clicked = pen.new_button( gui, uid, pic_x + 160, pic_y + 66 + 11*( i - 1 ), pic_z, "mods/mnee/files/pics/button_10_"..( is_real and "B" or "A" )..".png" )
							uid = mnee.new_tooltip( gui, uid, pic_z - 200, is_real and GameTextGetTranslatedOrNot( "$mnee_jpad_id" )..tostring( is_real ).." @ "..GameTextGetTranslatedOrNot( "$mnee_rmb_unmap" ) or GameTextGetTranslatedOrNot( "$mnee_lmb_map" ))
							pen.new_text( gui, pic_x + 162, pic_y + 66 + 11*( i - 1 ), pic_z - 0.01, i, is_real and {245,132,132} or {238,226,206})
							
							if( clicked ) then
								gslot_update[i] = true
							end
							if( r_clicked ) then
								if( is_real ) then
									jpad_update( -i )
									pen.play_sound( "delete" )
								else
									GamePrint( GameTextGetTranslatedOrNot( "$mnee_no_jpads" ))
									pen.play_sound( "error" )
								end
							end
						end
						
						uid = pen.new_button( gui, uid, pic_x + 158, pic_y + 53, pic_z + 0.01, "mods/mnee/files/pics/controller_panel.png" )
					end
					
					local profile = ModSettingGetNextValue( "mnee.PROFILE" )
					page = profile
					uid, page = mnee.new_pager( gui, uid, pic_x + 136, pic_y + 88, pic_z - 0.01, page, 3, true )
					if( profile ~= page ) then
						ModSettingSetNextValue( "mnee.PROFILE", page, false )
						GlobalsSetValue( mnee.UPDATER, GameGetFrameNum())
					end
					
					local old_x, old_y = pic_x, pic_y
					
					GuiOptionsAddForNextWidget( gui, 51 ) --IsExtraDraggable
					pen.new_button( gui, 1020, pic_x, pic_y, pic_z - 0.02, "mods/mnee/files/pics/button_drag.png" )
					local clicked, r_clicked, _, _, _, _, _, d_x, d_y = GuiGetPreviousWidgetInfo( gui )
					if( d_x ~= pic_x and d_y ~= pic_y and d_x ~= 0 and d_y ~= 0 ) then
						if( grab_x == nil ) then
							grab_x = d_x - pic_x
						end
						if( grab_y == nil ) then
							grab_y = d_y - pic_y
						end
						
						pic_x = d_x - grab_x
						pic_y = d_y - grab_y
					else
						grab_x = nil
						grab_y = nil
					end
					
					uid = pen.new_button( gui, uid, old_x, old_y, pic_z, pic )
					
					if( GameHasFlagRun( mnee.RETOGGLER )) then
						GameRemoveFlagRun( mnee.RETOGGLER )
						GameRemoveFlagRun( mnee.SERV_MODE )
					end
				else
					if( not( GameHasFlagRun( mnee.RETOGGLER ))) then
						GameAddFlagRun( mnee.SERV_MODE )
						GameAddFlagRun( mnee.RETOGGLER )
					end
					
					local doing_jpad = doing_axis and not( btn_axis_mode )
					
					local enter_down = false
					local tip_text = "["
					local active = {}
					if( not( doing_jpad )) then
						active = mnee.get_keys( "guied" )
						if( #active > 0 ) then
							if( advanced_mode ) then
								for i,key in ipairs( active ) do
									if( key ~= "return" ) then
										tip_text = tip_text..( i == 1 and "" or "; " )..key
									else
										enter_down = true
									end
								end
								tip_text = tip_text.."]"

								local binds = mnee.get_bindings()
								local is_dirty = binds[ current_mod ][ current_binding ].is_dirty
								if( is_dirty == nil and mneedata[ current_mod ] ~= nil ) then
									is_dirty = mneedata[ current_mod ].is_dirty or false
								end
								
								for mod,bnds in pairs( binds ) do
									for bnd,stff in pairs( bnds ) do
										local this_one = 0
										for i = 1,2 do
											local k_type = i == 1 and "keys" or "keys_alt"
											this_one = is_dirty and -1 or pen.get_table_count( stff[ k_type ])
											for e,key in ipairs( active ) do
												if( mnee.SPECIAL_KEYS[key] == nil ) then
													if( is_dirty ) then
														if( stff[ k_type ][ key ] ~= nil ) then
															this_one = #active
															break
														end
													elseif( stff[ k_type ][ key ] == nil ) then
														this_one = -1
														break
													end
												end
											end
											if( this_one > 0 ) then break end
										end
										if( this_one == #active ) then
											tip_text = tip_text.." @ "..GameTextGetTranslatedOrNot( "$mnee_conflict" ).."["..mod.."; "..pen.get_translated_line( stff.name ).."]"
											break
										end
									end
								end
							else
								local binds = mnee.get_bindings()
								for i,key in ipairs( active ) do
									if( mnee.SPECIAL_KEYS[( binds[ current_mod ][ current_binding ].allow_special or false ) and "_" or key] == nil and key ~= "mouse_left_gui" and key ~= "mouse_right_gui" ) then
										tip_text = key.."]"
										enter_down = true
										break
									end
								end
							end
						end
					end
					
					if( gui_retoggler ) then
						uid, clicked = pen.new_button( gui, uid, pic_x, pic_y, pic_z, "mods/mnee/files/pics/continue.png" )
						uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_doit" ))
						if( clicked ) then
							if(( btn_axis_counter or 3 ) == 3 ) then
								current_binding = ""
								doing_axis = false
								btn_axis_mode = false
								btn_axis_counter = nil
								advanced_mode = false
							else
								btn_axis_counter = btn_axis_counter + 1
							end
							gui_retoggler = false
							pen.play_sound( "confirm" )
						end
					else
						uid = pen.new_button( gui, uid, pic_x + 3, pic_y + 71, pic_z - 0.01, "mods/mnee/files/pics/help.png" )
						uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_binding_"..( doing_jpad and "axis" or ( advanced_mode and "advanced" or "simple" ))))
						
						local nuke_em = false
						local doing_swap = key_type == "keys" and ((( doing_jpad or btn_axis_mode ) and keys[ current_mod ][ current_binding ].keys_alt[2] ~= "_" ) or ( keys[ current_mod ][ current_binding ].keys_alt[ "_" ] == nil ))
						uid, clicked, r_clicked = pen.new_button( gui, uid, pic_x + 146, pic_y + 71, pic_z - 0.01, "mods/mnee/files/pics/key_unbind.png" )
						uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_lmb_unbind" )..( doing_swap and " @ "..GameTextGetTranslatedOrNot( "$mnee_rmb_unbind" ) or "" ))
						if( clicked ) then
							nuke_em = true
						elseif( doing_swap and r_clicked ) then
							nuke_em = 1
						end

						if( advanced_mode ) then
							if( #active > 0 ) then
								advanced_timer = advanced_timer + 1
								pen.new_text( gui, pic_x + 77, pic_y + 73, pic_z - 0.01, tostring( math.ceil(( 300 - advanced_timer )/60 )), {245,132,132})
								if( advanced_timer >= 300 ) then
									enter_down = true
									advanced_timer = 0
								end
							else
								advanced_timer = 0
							end
						end

						uid, clicked, r_clicked = pen.new_button( gui, uid, pic_x, pic_y, pic_z, "mods/mnee/files/pics/rebinder"..( doing_jpad and "_axis" or ( advanced_mode and "" or "_simple" ))..".png" )
						uid = mnee.new_tooltip( gui, uid, pic_z - 200, doing_jpad and GameTextGetTranslatedOrNot( "$mnee_waiting" ) or ( GameTextGetTranslatedOrNot( "$mnee_keys" ).." @ "..( tip_text == "[" and GameTextGetTranslatedOrNot( "$mnee_nil" ) or tip_text )).."@"..GameTextGetTranslatedOrNot( "$mnee_rmb_cancel" ))
						if( r_clicked ) then
							current_binding = ""
							doing_axis = false
							btn_axis_mode = false
							advanced_mode = false
							pen.play_sound( "error" )
						end

						if( nuke_em ) then
							local k_type = key_type
							if( doing_swap ) then
								if( nuke_em ~= 1 ) then
									keys[ current_mod ][ current_binding ].keys = keys[ current_mod ][ current_binding ].keys_alt
								end
								k_type = "keys_alt"
							end
							if( doing_jpad ) then
								keys[ current_mod ][ current_binding ][ k_type ] = { "is_axis", "_", }
							else
								local new_bind = {}
								if( btn_axis_mode ) then
									new_bind = keys[ current_mod ][ current_binding ][ k_type ]
									new_bind[ 2 ] = "_"
									new_bind[ 3 ] = "_"
									btn_axis_counter = 3
								else
									new_bind[ "_" ] = 1
								end
								keys[ current_mod ][ current_binding ][ k_type ] = new_bind
							end
							if( nuke_em == 1 ) then
								keys[ current_mod ][ current_binding ].keys = keys[ current_mod ][ current_binding ].keys_alt
							end
							mnee.set_bindings( keys )
							gui_retoggler = true
							pen.play_sound( "delete" )
						elseif( doing_jpad ) then
							local axes = mnee.get_axes()
							local champ = { 0, 0 }
							for ax,val in pairs( axes ) do
								if( val ~= 0 ) then
									champ = math.abs( champ[2]) < math.abs( val ) and { ax, val, } or champ
								end
							end
							if( champ[1] ~= 0 ) then
								keys[ current_mod ][ current_binding ][ key_type ] = { "is_axis", champ[1], }
								mnee.set_bindings( keys )
								gui_retoggler = true
								pen.play_sound( "switch_dimension" )
							end
						elseif( enter_down ) then
							local changed = false
							local new_bind = {}
							for i,key in ipairs( active ) do
								if( key ~= "return" ) then
									changed = true
									if( btn_axis_mode ) then
										btn_axis_counter = btn_axis_counter or 2
										new_bind = keys[ current_mod ][ current_binding ][ key_type ]
										new_bind[ btn_axis_counter ] = key
										break
									else
										new_bind[ key ] = 1
										if( not( advanced_mode )) then break end
									end
								end
							end
							if( changed ) then
								keys[ current_mod ][ current_binding ][ key_type ] = new_bind
								mnee.set_bindings( keys )
							end
							gui_retoggler = true
							pen.play_sound( "switch_dimension" )
						end
					end
				end
			else
				gui = pen.gui_killer( gui )
			end
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
								pen.play_sound( "confirm" )
							else
								GamePrint( GameTextGetTranslatedOrNot( "$mnee_error" ))
								pen.play_sound( "error" )
							end
						end
					elseif( not( is_auto )) then
						GamePrint( GameTextGetTranslatedOrNot( "$mnee_no_slot" ))
						pen.play_sound( "error" )
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

	if( GameHasFlagRun( mnee.INITER )) then return end; GameAddFlagRun( mnee.INITER )
	GlobalsSetValue( "PROSPERO_IS_REAL", "1" )
	
	local entity_id = EntityLoad( "mods/mnee/files/ctrl_body.xml" )
	EntityAddChild( GameGetWorldStateEntity(), entity_id )
	EntityAddComponent( entity_id, "VariableStorageComponent", 
	{
		name = "mnee_down",
		value_string = mnee.DIV_1,
	})
	EntityAddComponent( entity_id, "VariableStorageComponent", 
	{
		name = "mnee_disarmer",
		value_string = mnee.DIV_1,
	})
	EntityAddComponent( entity_id, "VariableStorageComponent", 
	{
		name = "mnee_triggers",
		value_string = mnee.DIV_1,
	})
	EntityAddComponent( entity_id, "VariableStorageComponent", 
	{
		name = "mnee_axis",
		value_string = mnee.DIV_1,
	})
	EntityAddComponent( entity_id, "VariableStorageComponent", 
	{
		name = "mnee_axis_memo",
		value_string = mnee.DIV_1,
	})
	
	for i = 1,3 do
		mnee.update_bindings( i )
	end
end
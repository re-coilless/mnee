ModRegisterAudioEventMappings( "mods/mnee/GUIDs.txt" )

get_active_keys = get_active_keys or ( function() return "huh?" end )

function OnModInit()
	dofile_once( "mods/mnee/lib.lua" )
	
	local is_lame = require == nil
	local ffi = not( is_lame ) and require( "ffi" ) or nil
	is_lame = ffi == nil
	if( is_lame ) then
		GameAddFlagRun( MNEE_LAME )
	else
		--this stuff goes hard: https://github.com/thenumbernine/lua-ffi-bindings/blob/master/sdl.lua
		ffi.cdef([[
			const uint8_t* SDL_GetKeyboardState(int* numkeys);
			uint32_t SDL_GetKeyFromScancode(uint32_t scancode);
			char* SDL_GetScancodeName(uint32_t scancode);
			char* SDL_GetKeyName(uint32_t key);
			
			short GetAsyncKeyState(int vKey);
			
			int SDL_SetClipboardText(const char *text);
			char* SDL_GetClipboardText(void);
			
			typedef struct SDL_Joystick SDL_Joystick;
			SDL_Joystick* SDL_JoystickOpen(int device_index);
			void SDL_JoystickClose(SDL_Joystick*);
			int SDL_JoystickNumAxes(SDL_Joystick*);
			int16_t SDL_JoystickGetAxis(SDL_Joystick*, int axis);
			int SDL_JoystickNumButtons(SDL_Joystick*);
			uint8_t SDL_JoystickGetButton(SDL_Joystick*, int button);
			int SDL_JoystickNumHats(SDL_Joystick*);
			uint8_t SDL_JoystickGetHat(SDL_Joystick*, int hat);
		]])
		_SDL = ffi.load( "SDL2.dll" )
		
		jpad = {}
		jpad_update = function( num )
			if( num < 0 ) then
				num = math.abs( num )
				_SDL.SDL_JoystickClose( jpad[ num - 1 ])
				table.remove( jpad, num )
			else
				local val = _SDL.SDL_JoystickOpen( num - 1 )
				if( tostring( val ) ~= "cdata<struct SDL_Joystick *>: NULL" ) then
					table.insert( jpad, val )
					val = string.gsub( tostring( val ), "cdata<struct SDL_Joystick %*>: ", "" )
				else
					val = nil
				end
				
				return val
			end
		end
	end
	
	local lists = dofile_once( "mods/mnee/lists.lua" )
	local keycaps = lists[1]
	local mouse = lists[2]
	jpad = jpad or {}
	
	local divider = "&"
	get_active_keys = function()
		local active = divider
		
		--keyboard; add clipboard
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
			local gpd_btn = { "x", "a", "b", "y", "l1", "r1", "l2", "r2", "select", "start", "l3", "r3", }
			local gpd_hat = { "up", "right", "down", "left", }
			
			for i,j in ipairs( jpad ) do
				local num_b = _SDL.SDL_JoystickNumButtons( j ) - 1
				for e = 0,num_b do
					if( _SDL.SDL_JoystickGetButton( j, e ) > 0 ) then
						local name = gpd_btn[e + 1] or ( "btn"..( e + 1 ))
						active = active..i.."gpd_"..name..divider
					end
				end
				
				local num_h = _SDL.SDL_JoystickNumHats( j ) - 1
				for e = 0,num_h do
					local hat = _SDL.SDL_JoystickGetHat( j, e )
					for k = 1,4 do
						if( hat%2 > 0 ) then
							local name = gpd_hat[k]
							if( e > 1 ) then
								name = name..( e + 1 )
							end
							active = active..i.."gpd_"..name..divider
						end
						hat = math.floor( hat/2 )
					end
				end
			end
		end
		
		return active
	end
	
	function get_sign( a )
		if( a < 0 ) then
			return -1
		else
			return 1
		end
	end
	
	function limiter( value, limit, max_mode )
		max_mode = max_mode or false
		
		if(( max_mode and math.abs( value ) < limit ) or ( not( max_mode ) and math.abs( value ) > limit )) then
			return get_sign( value )*limit
		end
		
		return value
	end
	
	get_current_axes = function()
		local state = divider
		
		if( #jpad > 0 ) then
			local gpd_axis = { "_lh", "_lv", "_rh", "_rv", }
			local deadzone = 5000
			local extreme = 32000
			
			for i,j in ipairs( jpad ) do
				local num_a = _SDL.SDL_JoystickNumAxes( j ) - 1
				for e = 0,num_a do
					local value = _SDL.SDL_JoystickGetAxis( j, e )
					value = limiter( math.abs( value ) < deadzone and 0 or value, extreme )
					if( math.abs( value ) > 0 ) then
						value = math.floor( 1000*( value - deadzone*get_sign( value ))/( extreme - deadzone ))
					end
					
					local name = i.."gpd_axis"..( gpd_axis[e + 1] or ( e + 1 ))
					state = state.."|"..name.."|"..value.."|"..divider
				end
			end
		end
		
		return state
	end
	
	access_clipboard_text = function( text )
		if( is_lame ) then
			return
		end
		
		if( text ~= nil ) then
			return _SDL.SDL_SetClipboardText( text )
		else
			return ffi.string( _SDL.SDL_GetClipboardText())
		end
	end
end

pic_x = pic_x or 2
pic_y = pic_y or 246
grab_x = grab_x or nil
grab_y = grab_y or nil

mod_page = mod_page or 1
current_mod = current_mod or "mnee"
binding_page = binding_page or 1
current_binding = current_binding or ""
doing_axis = doing_axis or false
btn_axis_mode = btn_axis_mode or 0

gui_active = gui_active or false
gui_retoggler = gui_retoggler or false

function OnWorldPreUpdate()
	dofile_once( "mods/mnee/lib.lua" )
	dofile_once( "mods/mnee/gui_lib.lua" )
	
	if( GameHasFlagRun( MNEE_INITER )) then
		local storage = get_storage( GameGetWorldStateEntity(), "mnee_down" ) or 0
		if( storage ~= 0 ) then
			ComponentSetValue2( get_storage( GameGetWorldStateEntity(), "mnee_axis" ), "value_string", get_current_axes())
			
			local active_core = get_active_keys()
			local axis_core = get_axes()
			for bnd,v in pairs( axis_core ) do
				if( v ~= 0 ) then
					active_core = active_core..string.gsub( bnd, "gpd_axis", "gpd_btn" ).."_"..( v > 0 and "+" or "-" ).."&"
				end
			end
			ComponentSetValue2( storage, "value_string", active_core )
			
			clean_disarmer()
			
			if( get_binding_pressed( "mnee", "aa_menu", current_binding == "" )) then
				if( gui_active ) then
					gui_active = false
					play_sound( "close_window" )
				else
					gui_active = true
					play_sound( "open_window" )
				end
			end
			if( get_binding_pressed( "mnee", "ab_off" )) then
				GameAddFlagRun( MNEE_TOGGLER )
				GamePrint( "[CUSTOM INPUTS DISABLED]" )
				play_sound( "uncapture" )
			end
			if( get_binding_pressed( "mnee", "ac_pfl_chng" )) then
				local prf = ModSettingGetNextValue( "mnee.PROFILE" ) + 1
				prf = prf > 3 and 1 or prf
				ModSettingSetNextValue( "mnee.PROFILE", prf, false )
				GamePrint( "Current Profile: "..string.char( prf + 64 ))
				play_sound( "switch_page" )
			end
		end
		
		local is_auto = ModSettingGetNextValue( "mnee.CTRL_AUTOMAPPING" )
		local gslot_update = { 0, 0, 0, 0, }
		ctl_ids = ctl_ids or {}
		
		if( not( GameIsInventoryOpen())) then
			if( gui == nil ) then
				gui = GuiCreate()
			end
			GuiStartFrame( gui )
			
			ctl_panel = ctl_panel or false
			
			local keys = get_bindings()
			local is_disabled = GameHasFlagRun( MNEE_TOGGLER )
			
			local clicked, r_clicked, pic_z = 0, 0, -50
			local uid = 0
			if( gui_active ) then
				if( current_binding == "" ) then
					local pic = "mods/mnee/pics/window.png"
					local pic_w, pic_h = GuiGetImageDimensions( gui, pic, 1 )
					
					uid, clicked = new_button( gui, uid, pic_x + pic_w - 8, pic_y + 2, pic_z - 0.01, "mods/mnee/pics/key_close.png" )
					uid = new_tooltip( gui, uid, pic_z - 200, "Close" )
					if( clicked ) then
						gui_active = false
						play_sound( "close_window" )
					end
					
					local counter = 1
					local starter = 8*mod_page - 8
					local ender = 8*mod_page + 1
					local t_x, t_y = pic_x + 2, pic_y
					for mod in magic_sorter( keys ) do
						if( counter > starter and counter < ender ) then
							t_y = t_y + 11
							
							uid, clicked = new_button( gui, uid, t_x, t_y, pic_z - 0.01, "mods/mnee/pics/button_43_"..( current_mod == mod and "B" or "A" )..".png" )
							uid = new_tooltip( gui, uid, pic_z - 200, current_mod == mod and mod or "LMB to open the bindings." )
							new_text( gui, t_x + 2, t_y, pic_z - 0.02, liner( mod, 39 ), current_mod == mod and 3 or 1 )
							if( clicked ) then
								current_mod = mod
								play_sound( "button_special" )
							end
						end
						counter = counter + 1
					end
					
					local page = mod_page
					uid, page = new_pager( gui, uid, pic_x + 2, pic_y + 99, pic_z - 0.01, page, math.ceil(( counter - 1 )/8 ))
					if( mod_page ~= page ) then
						mod_page = page
					end
					
					counter = 1
					starter = 8*binding_page - 8
					ender = 8*binding_page + 1
					t_x, t_y = pic_x + 48, pic_y
					for id,bind in axis_sorter( keys[ current_mod ] ) do
						if( counter > starter and counter < ender ) then
							t_y = t_y + 11
							
							local is_static = bind.is_locked or false
							local is_axis = bind.keys[1] == "is_axis"
							
							uid, clicked, r_clicked = new_button( gui, uid, t_x, t_y, pic_z - 0.01, "mods/mnee/pics/button_74_A.png" )
							uid = new_tooltip( gui, uid, pic_z - 200, ( is_axis and ( "[AXIS]"..( is_static and "" or " @ " )) or "" )..( is_static and "[STATIC] @ " or "" )..bind.name..": "..bind.desc.." @ "..bind2string( bind.keys )..( is_axis and " @ LMB to bind analog stick. RMB to bind buttons." or "" ))
							new_text( gui, t_x + 2, t_y, pic_z - 0.02, liner( bind.name, 70 ), 1 )
							if( clicked or ( is_axis and r_clicked )) then
								if( not( is_static )) then
									current_binding = id
									doing_axis = is_axis
									btn_axis_mode = r_clicked
									play_sound( "select" )
								else
									GamePrint( "[ERROR] This binding can't be changed!" )
									play_sound( "error" )
								end
							end
							
							uid, clicked, r_clicked = new_button( gui, uid, t_x + 75, t_y, pic_z - 0.01, "mods/mnee/pics/key_delete.png" )
							uid = new_tooltip( gui, uid, pic_z - 200, "RMB to set to default." )
							if( r_clicked ) then
								dofile_once( "mods/mnee/bindings.lua" )
								keys[ current_mod ][ id ].keys = bindings[ current_mod ][ id ].keys
								set_bindings( keys )
								play_sound( "clear_all" )
							end
						end
						counter = counter + 1
					end
					
					page = binding_page
					uid, page = new_pager( gui, uid, pic_x + 48, pic_y + 99, pic_z - 0.01, page, math.ceil(( counter - 1 )/8 ))
					if( binding_page ~= page ) then
						binding_page = page
					end
					
					uid = new_button( gui, uid, pic_x + 101, pic_y + 99, pic_z - 0.01, "mods/mnee/pics/help.png" )
					uid = new_tooltip( gui, uid, pic_z - 200, "LMB the binding name to change it." )-- @ RMB to toggle active." )
					
					uid, clicked, r_clicked = new_button( gui, uid, pic_x + 112, pic_y + 99, pic_z - 0.01, "mods/mnee/pics/button_dft.png" )
					uid = new_tooltip( gui, uid, pic_z - 200, "RMB to set selected mod's current profile to default." )
					if( r_clicked ) then
						dofile_once( "mods/mnee/bindings.lua" )
						keys[ current_mod ] = bindings[ current_mod ]
						set_bindings( keys )
						play_sound( "clear_all" )
					end
					
					uid, clicked = new_button( gui, uid, pic_x + 136, pic_y + 11, pic_z - 0.01, "mods/mnee/pics/button_tgl_"..( is_disabled and "A" or "B" )..".png" )
					uid = new_tooltip( gui, uid, pic_z - 200, "LMB to "..( is_disabled and "en" or "dis" ).."able custom inputs." )
					if( clicked ) then
						if( is_disabled ) then
							GameRemoveFlagRun( MNEE_TOGGLER )
							play_sound( "capture" )
						else
							GameAddFlagRun( MNEE_TOGGLER )
							play_sound( "uncapture" )
						end
					end
					
					uid, clicked, r_clicked = new_button( gui, uid, pic_x + 136, pic_y + 22, pic_z - 0.01, "mods/mnee/pics/button_rst.png" )
					uid = new_tooltip( gui, uid, pic_z - 200, "RMB to completely reset the settings." )
					if( r_clicked ) then
						for i = 1,3 do
							ModSettingSetNextValue( "mnee.BINDINGS_"..i, "&", false )
							update_bindings( i )
						end
						play_sound( "delete" )
					end
					
					if( io ~= nil ) then
						uid, clicked = new_button( gui, uid, pic_x + 136, pic_y + 66, pic_z - 0.01, "mods/mnee/pics/button_ctl_"..( ctl_panel and "B" or "A" )..".png" )
						uid = new_tooltip( gui, uid, pic_z - 200, "LMB to toggle controller mapping panel." )
						if( clicked ) then
							if( ctl_panel ) then
								ctl_panel = false
								play_sound( "close_window" )
							else
								ctl_panel = true
								play_sound( "open_window" )
							end
						end
						
						uid, clicked, r_clicked = new_button( gui, uid, pic_x + 136, pic_y + 77, pic_z - 0.01, "mods/mnee/pics/button_bkp.png" )
						uid = new_tooltip( gui, uid, pic_z - 200, "LMB to backup all the data. @ RMB to load last backup." )
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
								GamePrint( "[ERROR]: ", err )
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
									GamePrint( "[NO BACKUPS FOUND]" )
									play_sound( "error" )
								end
							else
								GamePrint( "[ERROR]: ", err )
								play_sound( "error" )
							end
						end
					
						if( ctl_panel ) then
							if( is_auto ) then
								uid = new_anim( gui, uid, 1, pic_x + 160, pic_y + 55, pic_z, "mods/mnee/pics/scan/", 20, 5 )
							else
								uid = new_image( gui, uid, pic_x + 160, pic_y + 55, pic_z, "mods/mnee/pics/scan/0.png" )
							end
							uid, clicked, r_clicked = new_button( gui, uid, pic_x + 160, pic_y + 55, pic_z - 0.01, "mods/mnee/pics/scan/_hitbox.png" )
							uid = new_tooltip( gui, uid, pic_z - 200, "RMB to "..( is_auto and "dis" or "en" ).."able automatic detection." )
							if( r_clicked ) then
								ModSettingSetNextValue( "mnee.CTRL_AUTOMAPPING", not( is_auto ), false )
								play_sound( "button_special" )
							end
							
							for i = 1,4 do
								local is_real = ctl_ids[i] ~= nil
								uid, clicked, r_clicked = new_button( gui, uid, pic_x + 160, pic_y + 66 + 11*( i - 1 ), pic_z, "mods/mnee/pics/button_10_"..( is_real and "B" or "A" )..".png" )
								uid = new_tooltip( gui, uid, pic_z - 200, is_real and "CURRENT CTRL ID: "..ctl_ids[i].." @ RMB to remove this controller." or "LMB to map new controller." )
								new_text( gui, pic_x + 162, pic_y + 66 + 11*( i - 1 ), pic_z - 0.01, i, is_real and 3 or 1 )
								
								if( clicked ) then
									gslot_update[i] = 1
								end
								if( r_clicked ) then
									if( is_real ) then
										jpad_update( -i )
										table.remove( ctl_ids, i )
										play_sound( "delete" )
									else
										GamePrint( "No controller is present!" )
										play_sound( "error" )
									end
								end
							end
							
							uid = new_button( gui, uid, pic_x + 158, pic_y + 53, pic_z + 0.01, "mods/mnee/pics/controller_panel.png" )
						end
					end
					
					local profile = ModSettingGetNextValue( "mnee.PROFILE" )
					page = profile
					uid, page = new_pager( gui, uid, pic_x + 136, pic_y + 88, pic_z - 0.01, page, 3, true )
					if( profile ~= page ) then
						ModSettingSetNextValue( "mnee.PROFILE", page, false )
					end
					
					local old_x, old_y = pic_x, pic_y
					
					GuiOptionsAddForNextWidget( gui, 51 ) --IsExtraDraggable
					new_button( gui, 1020, pic_x, pic_y, pic_z - 0.02, "mods/mnee/pics/button_drag.png" )
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
					
					uid = new_button( gui, uid, old_x, old_y, pic_z, pic )
					
					if( GameHasFlagRun( MNEE_RETOGGLER )) then
						GameRemoveFlagRun( MNEE_RETOGGLER )
						GameRemoveFlagRun( MNEE_TOGGLER )
					end
				else
					if( not( is_disabled )) then
						GameAddFlagRun( MNEE_TOGGLER )
						GameAddFlagRun( MNEE_RETOGGLER )
					end
					
					local doing_what = doing_axis and not( btn_axis_mode )
					
					local enter_down = false
					local tip_text = "["
					local active = {}
					if( not( doing_what )) then
						active = get_keys()
						if( #active > 0 ) then
							for i,key in ipairs( active ) do
								if( key ~= "return" ) then
									tip_text = tip_text..( i == 1 and "" or "; " )..key
								else
									enter_down = true
								end
							end
							tip_text = tip_text.."]"
							
							local binds = get_bindings()
							for mod,bnds in pairs( binds ) do
								for bnd,stff in pairs( bnds ) do
									local this_one = get_table_count( stff.keys )
									for e,key in ipairs( active ) do
										if( stff.keys[ key ] == nil ) then
											this_one = -1
											break
										end
									end
									if( this_one == #active ) then
										tip_text = tip_text.." @ CONFLICT - ["..mod.."; "..stff.name.."]"
										break
									end
								end
							end
						end
					end
					
					if( gui_retoggler ) then
						uid, clicked = new_button( gui, uid, pic_x, pic_y, pic_z, "mods/mnee/pics/continue.png" )
						uid = new_tooltip( gui, uid, pic_z - 200, "do it" )
						if( clicked ) then
							if(( btn_axis_counter or 3 ) == 3 ) then
								current_binding = ""
								doing_axis = false
								btn_axis_mode = 0
								btn_axis_counter = nil
							else
								btn_axis_counter = btn_axis_counter + 1
							end
							gui_retoggler = false
							play_sound( "confirm" )
						end
					else
						uid, clicked, r_clicked = new_button( gui, uid, pic_x, pic_y, pic_z, "mods/mnee/pics/rebinder"..( doing_what and "_axis" or "" )..".png" )
						uid = new_tooltip( gui, uid, pic_z - 200, doing_what and "Waiting for Input..." or ( "Keys detected: @ "..( tip_text == "[" and "[NONE]" or tip_text )))
						if( r_clicked ) then
							current_binding = ""
							doing_axis = false
							btn_axis_mode = 0
							play_sound( "error" )
						end
						
						if( doing_what ) then
							local axes = get_axes()
							
							local champ = { 0, 0 }
							for ax,val in pairs( axes ) do
								if( val ~= 0 ) then
									champ = math.abs( champ[2]) < math.abs( val ) and { ax, val, } or champ
								end
							end
							if( champ[1] ~= 0 ) then
								keys[ current_mod ][ current_binding ].keys = { "is_axis", champ[1], }
								set_bindings( keys )
								gui_retoggler = true
								play_sound( "switch_dimension" )
							end
						elseif( enter_down ) then
							local changed = false
							local new_bind = {}
							for i,key in ipairs( active ) do
								if( key ~= "return" ) then
									changed = true
									if( btn_axis_mode ) then
										btn_axis_counter = btn_axis_counter or 2
										new_bind = keys[ current_mod ][ current_binding ].keys
										new_bind[ btn_axis_counter ] = key
										break
									else
										new_bind[ key ] = 1
									end
								end
							end
							if( changed ) then
								keys[ current_mod ][ current_binding ].keys = new_bind
								set_bindings( keys )
							end
							gui_retoggler = true
							play_sound( "switch_dimension" )
						end
					end
				end
			else
				gui = gui_killer( gui )
			end
		else
			gui = gui_killer( gui )
		end
		
		if( jpad_update ~= nil ) then
			for i,gslot in ipairs( gslot_update ) do
				if( gslot > 0 or is_auto ) then
					if( ctl_ids[i] == nil ) then
						local ctl = jpad_update( i )
						if( ctl ~= nil ) then
							local is_unique = true
							for e,ctl_id in ipairs( ctl_ids ) do
								if( ctl_id == ctl ) then
									is_unique = false
									break
								end
							end
							if( is_unique ) then
								table.insert( ctl_ids, ctl )
								if( not( is_auto )) then
									play_sound( "confirm" )
								end
							elseif( not( is_auto )) then
								GamePrint( "This controller is already present!" )
								play_sound( "error" )
							end
						elseif( not( is_auto )) then
							GamePrint( "ERROR" )
							play_sound( "error" )
						end
					elseif( not( is_auto )) then
						GamePrint( "This slot is occupied!" )
						play_sound( "error" )
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
	
	if( GameHasFlagRun( MNEE_INITER )) then
		return
	end
	GameAddFlagRun( MNEE_INITER )
	
	GlobalsSetValue( "PROSPERO_IS_REAL", "1" )
	
	local entity_id = GameGetWorldStateEntity()
	EntityAddComponent( entity_id, "VariableStorageComponent", 
	{
		name = "mnee_down",
		value_string = MNEE_DIV_1,
	})
	EntityAddComponent( entity_id, "VariableStorageComponent", 
	{
		name = "mnee_disarmer",
		value_string = MNEE_DIV_1,
	})
	EntityAddComponent( entity_id, "VariableStorageComponent", 
	{
		name = "mnee_axis",
		value_string = MNEE_DIV_1,
	})
	EntityAddComponent( entity_id, "VariableStorageComponent", 
	{
		name = "mnee_axis_memo",
		value_string = MNEE_DIV_1,
	})
	
	for i = 1,3 do
		update_bindings( i )
	end
end
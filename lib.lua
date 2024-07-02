dofile_once( "mods/penman/_penman.lua" )

mnee = mnee or {}
mnee.G = mnee.G or {}

--[BACKEND]
function mnee.order_sorter( tbl )
	return pen.t.order( tbl, function( a, b )
		return (( tbl[a].order_id or a ) < ( tbl[b].order_id or b ))
	end)
end

function mnee.get_bind( bind_data, profile )
	return bind_data.keys[ profile or pen.setting_get( "mnee.PROFILE" )] or bind_data.keys[1]
end

function mnee.get_ctrl()
	return pen.get_child( GameGetWorldStateEntity(), "mnee_ctrl" )
end

function mnee.apply_deadzone( v, kind, zero_offset )
	if( v == 0 ) then return 0 end
	zero_offset = pen.setting_get( "mnee.LIVING" ) and 0 or ( zero_offset or 0 )
	
	local total = 1000
	local deadzone = total*math.min( zero_offset + pen.setting_get( "mnee.DEADZONE_"..( kind or "EXTRA" ))/20, 0.999 )
	v = math.floor( total*v )
	v = math.abs( v ) < deadzone and 0 or v
	if( math.abs( v ) > 0 ) then
		v = ( v - deadzone*pen.get_sign( v ))/( total - deadzone )
	end
	return v
end

function mnee.aim_assist( hooman, pos, angle, is_active, is_searching, data )
	data = data or {}
	data.setting = data.setting or "mnee.AUTOAIM"
	data.tag_tbl = data.tag_tbl or {"enemy"}
	data.pic = data.pic or "mods/mnee/files/pics/autoaim.png"
	data.do_lining = data.do_lining or false
	
	local autoaim = pen.setting_get( data.setting )
	if( autoaim < 0.1 or ( is_active ~= nil and not( is_active ))) then
		return angle, false
	end

	local safe_zone = 50
	local search_distance = 150
	local ray_x, ray_y = search_distance*math.cos( angle ), search_distance*math.sin( angle )
	local is_hit, hit_x, hit_y = RaytracePlatforms( pos[1], pos[2], pos[1] + ray_x, pos[2] + ray_y )
	if( not( is_hit )) then
		hit_x, hit_y = pos[1] + ray_x, pos[2] + ray_y
	end
	
	local dir_x = pen.get_sign( hit_x - pos[1])
	local dir_y = pen.get_sign( hit_y - pos[2])

	local the_one = 0
	local meats = {}
	for i = 1,#data.tag_tbl do
		meats = pen.t.add( meats, EntityGetInRadiusWithTag( hit_x, hit_y, search_distance, data.tag_tbl[i]) or {})
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
	local delta_x, delta_y = 0, 0
	if( pen.vld( the_one, true )) then
		local t_x, t_y = pen.get_creature_head( the_one, EntityGetTransform( the_one ))
		delta_x, delta_y = t_x - pos[1], t_y - pos[2]
	end

	mnee.aim_assist_korrection = mnee.aim_assist_korrection or {0,0,0}
	if( is_searching ) then
		local projectiles = EntityGetInRadiusWithTag( pos[1], pos[2], search_distance, "projectile" ) or {}
		if( #projectiles > 0 ) then
			local ratio = 0.05
			local best_case = -1
			for i,proj in ipairs( projectiles ) do
				local proj_comp = EntityGetFirstComponentIncludingDisabled( proj, "ProjectileComponent" )
				if( pen.vld( proj_comp, true )) then
					if( ComponentGetValue2( proj_comp, "mWhoShot" ) == hooman and best_case < proj ) then
						if( mnee.aim_assist_korrection[1] < proj and mnee.aim_assist_korrection[1] ~= best_case ) then
							best_case = proj
						end
					end
				end
			end

			if( pen.vld( best_case, true )) then
				local proj_comp = EntityGetFirstComponentIncludingDisabled( best_case, "ProjectileComponent" )
				local vel = ComponentGetValue2( proj_comp, "mInitialSpeed" )

				local v_comp = EntityGetFirstComponentIncludingDisabled( best_case, "VelocityComponent" )
				local mass = ComponentGetValue2( v_comp, "mass" )
				local gravity = ComponentGetValue2( v_comp, "gravity_y" )
				local friction = ComponentGetValue2( v_comp, "air_friction" )
				
				mnee.aim_assist_korrection = { best_case, vel, gravity }
			end
		end
	end

	if( delta_x ~= 0 ) then --no drag
		is_done = true
		
		local function fuck_it( x, y, v, g, h, sign )
			--https://www.reddit.com/r/FTC/comments/jis4p3/find_launch_angle_given_distance_to_target/
			local step1 = ( g*y*x^2 - g*h*x^2 )/( v^2 )
			local step2 = x^2 + y^2 + h^2 - 2*y*h
			local step3 = ( step1 - x^2 )^2 - step2*( g^2*x^4 )/( v^4 )
			return math.acos( math.sqrt(( x^2 - step1 + sign*math.sqrt( step3 ))/( 2*step2 )))
		end

		local function fuck_it_check( a, d, v, g )
			return d*math.tan( a ) + ( g*d^2 )/( 2*v^2*math.cos( a )^2 )
		end

		local so_back = true
		local strength = 0.1*autoaim
		local min_offset = math.rad( 0.5 )*autoaim
		local t_angle = math.atan2( delta_y, delta_x )
		if( mnee.aim_assist_korrection[1] > 0 ) then
			local x_sign, y_sign = pen.get_sign( delta_x ), pen.get_sign( delta_y )
			local x, y, h = delta_x, 0, delta_y
			local v, g = mnee.aim_assist_korrection[2], mnee.aim_assist_korrection[3] + 0.000001
			
			if( y_sign < 0 ) then y, h = -h, 0 end
			local a = pen.catch( fuck_it, {x,y,v,g,h,1}, {9999})
			local b = pen.catch( fuck_it, {x,y,v,g,h,-1}, {9999})
			t_angle = y_sign*math.min( a, b )

			so_back = pen.vld( t_angle )
			if( so_back ) then
				if( x_sign < 0 ) then
					t_angle = -y_sign*t_angle + math.rad( 180 )
				end

				local drift = fuck_it_check( t_angle, delta_x, v, g ) - delta_y
				if( drift > 0.1 ) then t_angle = -t_angle end
				if( data.do_lining ) then
					for i = 1,math.abs( delta_x ),5 do
						local d = x_sign*i
						local y = fuck_it_check( t_angle, d, v, g )
						GameCreateSpriteForXFrames( "mods/mnee/files/pics/dot_white.png", pos[1] + d, pos[2] + y, true, 0, 0, 1, true )
					end
				end
			end
		end
		
		if( so_back ) then
			local delta_a = pen.get_angular_delta( t_angle, angle )
			angle = angle + pen.limiter( pen.limiter( strength*delta_a, min_offset, true ), delta_a )
			if( pen.vld( data.pic )) then
				GameCreateSpriteForXFrames( data.pic, pos[1] + delta_x, pos[2] + delta_y, true, 0, 0, 1, true )
			end
		end
	end

	return angle, is_done
end

--[INTERNAL]
function mnee.get_keys( mode )
	return pen.t.pack( pen.magic_storage( mnee.get_ctrl(), ( mode or false ) and "mnee_down_"..mode or "mnee_down", "value_string" ) or "" )
end
function mnee.get_triggers()
	return pen.t.unarray( pen.t.pack( pen.magic_storage( mnee.get_ctrl(), "mnee_triggers", "value_string" ) or "" ))
end
function mnee.get_axes()
	return pen.t.unarray( pen.t.pack( pen.magic_storage( mnee.get_ctrl(), "mnee_axis", "value_string" ) or "" ))
end

function mnee.get_disarmer()
	return pen.t.unarray( pen.t.pack( pen.magic_storage( mnee.get_ctrl(), "mnee_disarmer", "value_string" ) or "" ))
end
function mnee.add_disarmer( value )
	local storage = pen.magic_storage( mnee.get_ctrl(), "mnee_disarmer" )
	if( pen.vld( storage, true )) then
		local disarmer = table.concat({ pen.DIV_2, value, pen.DIV_2, GameGetFrameNum(), pen.DIV_2, pen.DIV_1 })
		ComponentSetValue2( storage, "value_string", ComponentGetValue2( storage, "value_string" )..disarmer )
	end
end
function mnee.clean_disarmer()
	local disarmer = mnee.get_disarmer()
	if( pen.vld( disarmer )) then
		local new_disarmer = {}
		local current_frame = GameGetFrameNum()
		for key,frame in pairs( disarmer ) do
			if( current_frame - frame <= 1 ) then
				new_disarmer[ key ] = frame
			end
		end
		pen.magic_storage( mnee.get_ctrl(), "mnee_disarmer", "value_string", pen.t.pack( pen.t.unarray( new_disarmer )))
	end
end

function mnee.set_setup_memo( setup_tbl )
	pen.setting_set( "mnee.SETUP", pen.t.parse( setup_tbl ))
end
function mnee.get_setup_memo()
	local setup_tbl = pen.t.parse( pen.setting_get( "mnee.SETUP" ))
	if( not( pen.vld( setup_tbl ))) then
		dofile_once( "mods/mnee/bindings.lua" )

		setup_tbl = {{}}
		for mod_id,_ in pairs( _BINDINGS ) do
			setup_tbl[1][ mod_id ] = "_dft"
		end
		mnee.set_setup_memo( setup_tbl )
	end
	return setup_tbl
end
function mnee.get_setup_id( mod_id )
	local setup_memo = mnee.get_setup_memo()
	return ( setup_memo[ pen.setting_get( "mnee.PROFILE" )] or setup_memo[1])[ mod_id ] or "_dft"
end
function mnee.set_setup_id( mod_id, setup_id )
	local setup_memo = mnee.get_setup_memo()
	local profile = pen.setting_get( "mnee.PROFILE" )
	if( not( pen.vld( setup_memo[ profile ]))) then
		setup_memo[ profile ] = pen.t.clone( setup_memo[1])
	end
	
	if( setup_memo[ profile ][ mod_id ] ~= setup_id ) then
		setup_memo[ profile ][ mod_id ] = setup_id
		mnee.set_setup_memo( setup_memo )

		dofile_once( "mods/mnee/bindings.lua" )
		if( _MNEEDATA[ mod_id ] ~= nil and _MNEEDATA[ mod_id ].on_setup ~= nil ) then
			_MNEEDATA[ mod_id ].on_setup( _MNEEDATA[ mod_id ].setup_modes, setup_id )
		end
	end
end

function mnee.apply_jpads( jpad_tbl, no_update )
	ComponentSetValue2( pen.magic_storage( mnee.get_ctrl(), "mnee_jpads" ), "value_string", pen.t.pack( jpad_tbl ))
	if( not( no_update )) then GameAddFlagRun( mnee.JPAD_UPDATE ) end
end
function mnee.is_jpad_real( id )
	return (( pen.t.pack( pen.magic_storage( mnee.get_ctrl(), "mnee_jpads", "value_string" ) or "" ))[ id or 1 ] or 0 ) > 0
end
function mnee.jpad_check( keys )
	for key,val in pairs( keys ) do
		if( string.find( type( key ) == "number" and val or key, "%dgpd_" )) then
			return true
		end
	end
	return false
end

function mnee.get_axis_memo()
	return pen.t.unarray( pen.t.pack( pen.magic_storage( mnee.get_ctrl(), "mnee_axis_memo", "value_string" ) or "" ))
end
function mnee.toggle_axis_memo( name )
	local storage = pen.magic_storage( mnee.get_ctrl(), "mnee_axis_memo" )
	if( pen.vld( storage, true )) then
		local memo = mnee.get_axis_memo()
		if( memo[ name ] == nil ) then
			memo = table.concat({ ComponentGetValue2( storage, "value_string" ), name, pen.DIV_1 })
		else
			memo[ name ] = nil
			memo = pen.t.pack( pen.t.unarray( memo ))
		end
		ComponentSetValue2( storage, "value_string", memo )
	end
end

function mnee.is_priority_mod( mod_id )
	local vip_mod = GlobalsGetValue( mnee.PRIO_MODE, "0" )
	return vip_mod == "0" or mod_id ~= vip_mod
end
function mnee.set_priority_mod( mod_id )
	GlobalsSetValue( mnee.PRIO_MODE, tostring( mod_id ))
end

function mnee.get_bindings( binds_only )
	local updater_frame = tonumber( GlobalsGetValue( mnee.UPDATER, "0" ))
	if(( mnee.updater_memo or 0 ) ~= updater_frame ) then
		mnee.updater_memo = updater_frame
		mnee.binding_data = nil
	end
	
	if( mnee.binding_data == nil ) then
		dofile_once( "mods/mnee/bindings.lua" )

		local binding_data = pen.t.parse( pen.setting_get( "mnee.BINDINGS" ))
		if( not( pen.vld( binding_data ))) then
			mnee.update_bindings( "nuke_it" )
			binding_data = pen.t.parse( pen.setting_get( "mnee.BINDINGS" ))
		end
		if( binds_only ) then return binding_data end

		local skip_list = pen.t.unarray({ "keys", "keys_alt" })
		for mod,mod_tbl in pairs( binding_data ) do
			for bind,bind_tbl in pairs( mod_tbl ) do
				for k,v in pairs( _BINDINGS[ mod ][ bind ]) do
					if( skip_list[ k ] == nil ) then binding_data[ mod ][ bind ][ k ] = v end
				end
			end
		end
		mnee.binding_data = binding_data
	end

	return pen.t.clone( mnee.binding_data )
end
function mnee.set_bindings( binding_data )
	if( not( pen.vld( binding_data ))) then return end

	local key_data = {}
	for mod,mod_tbl in pairs( binding_data ) do
		key_data[ mod ] = {}
		for bind,bind_tbl in pairs( mod_tbl ) do
			key_data[ mod ][ bind ] = {}
			key_data[ mod ][ bind ].keys = bind_tbl.keys
			for profile,key_tbl in pairs( bind_tbl.keys ) do
				if( not( pen.vld( key_tbl.main ))) then
					key_data[ mod ][ bind ].keys[ profile ].main = key_data[ mod ][ bind ].keys[1].main
				end
				if( not( pen.vld( key_tbl.alt ))) then
					local v = { ["_"] = 1 }
					if( key_data[ mod ][ bind ].keys[ profile ].main[1] == "is_axis" ) then
						v = { "is_axis", "_" }
					end
					key_data[ mod ][ bind ].keys[ profile ].alt = v
				end
			end
		end
	end
	
	pen.setting_set( "mnee.BINDINGS", pen.t.parse( key_data ))
	GlobalsSetValue( mnee.UPDATER, GameGetFrameNum())
end
function mnee.update_bindings( force_update )
	dofile_once( "mods/mnee/bindings.lua" )
	
	local updated = force_update
	local current_tbl = force_update
	if( type( current_tbl ) ~= "table" ) then
		current_tbl = updated == "nuke_it" and {} or mnee.get_bindings( true )
	end
	
	local profile = pen.setting_get( "mnee.PROFILE" )
	for mod,mod_tbl in pairs( _BINDINGS ) do
		local setup_id = "_dft"
		if( current_tbl[ mod ] == nil ) then current_tbl[ mod ] = {} end
		if( _MNEEDATA[ mod ] ~= nil and _MNEEDATA[ mod ].setup_modes ~= nil ) then
			setup_id = mnee.get_setup_id( mod, profile )
		end
		
		for bind,bind_tbl in pairs( mod_tbl ) do
			if( current_tbl[ mod ][ bind ] == nil ) then
				current_tbl[ mod ][ bind ] = {}
			end
			if( current_tbl[ mod ][ bind ].keys == nil ) then
				current_tbl[ mod ][ bind ].keys = {}
			end

			for i,v in ipairs({ 1, profile }) do
				local new_keys = {}
				if( current_tbl[ mod ][ bind ].keys[ v ] ~= nil ) then
					goto continue
				else current_tbl[ mod ][ bind ].keys[ v ], updated = {}, true end
				if( _MNEEDATA[ mod ] ~= nil ) then
					new_keys = pen.t.get( _MNEEDATA[ mod ].setup_modes, setup_id )
				end

				if( pen.vld( new_keys )) then
					new_keys = new_keys.binds[ bind ]
					if( type( new_keys[1]) == "table" ) then
						current_tbl[ mod ][ bind ].keys[ v ].main = new_keys[1]
						current_tbl[ mod ][ bind ].keys[ v ].alt = new_keys[2]
					else current_tbl[ mod ][ bind ].keys[ v ].main = new_keys end
				else
					current_tbl[ mod ][ bind ].keys[ v ].main = bind_tbl.keys
					current_tbl[ mod ][ bind ].keys[ v ].alt = bind_tbl.keys_alt
				end

			    ::continue::
			end
		end
	end
	
	if( updated ) then mnee.set_bindings( current_tbl ) end
end

--[FRONTEND]
function mnee.get_shifted_key( c )
	local check = string.byte( c ) 
	if( check > 96 and check < 123 ) then
		return string.char( check - 32 )
	else return dofile_once( "mods/mnee/lists.lua" )[4][c] or c end
end

function mnee.get_fancy_key( key )
	local out, is_jpad = string.gsub( key, "%dgpd_", "" )
	out = dofile_once( "mods/mnee/lists.lua" )[5][ out ] or out
	if( is_jpad > 0 ) then
		return table.concat({ "GP", string.sub( key, 1, 1 ), "(", out, ")" })
	else return out end
end

function mnee.get_binding_keys( mod_id, name, is_compact )
	local binding = mnee.get_bindings()[ mod_id ][ name ]
	if( binding.axes ~= nil ) then
		local v = mnee.get_binding_keys( mod_id, binding.axes[1], is_compact )
		local h = mnee.get_binding_keys( mod_id, binding.axes[2], is_compact )
		local symbols = ( is_compact or false ) and {"|","v:","; h:"} or {"|","ver: ","; hor: "}
		return table.concat({ symbols[1], symbols[2], v, symbols[3], h, symbols[1]})
	end
	
	local function figure_it_out( tbl )
		local symbols = ( is_compact or false ) and {"","-","",","} or {"["," + ","]","/"}
		local out = symbols[1]
		if( tbl["_"] ~= nil or tbl[2] == "_" ) then
			out = GameTextGetTranslatedOrNot( "$mnee_nil" )
		elseif( tbl[1] == "is_axis" ) then
			out = table.concat({ out, mnee.get_fancy_key( tbl[2])})
			if( tbl[3] ~= nil ) then
				out = table.concat({ out, symbols[4], mnee.get_fancy_key( tbl[3])})
			end
		else
			for key in pen.t.order( tbl ) do
				out = table.concat({ out, mnee.get_fancy_key( key ), symbols[2]})
			end
			out = string.sub( out, 1, -( #symbols[2] + 1 ))
		end
		return out..symbols[3]
	end

	local b = mnee.get_bind( binding )
	local got_alt = not( b.alt["_"] ~= nil or b.alt[2] == "_" )
	local out = figure_it_out( b[( got_alt and is_compact == 2 ) and "alt" or "main" ])
	if( is_compact ) then
		out = string.lower( out )
	elseif( got_alt ) then
		out = table.concat({ out, " or ", figure_it_out( b.alt )})
	end
	return out
end

function mnee.bind2string( binds, bind, key_type )
	local out = "["
	if( binds == nil and bind.axes ~= nil ) then
		return table.concact({
			"|", mnee.bind2string( nil, binds[ bind.axes[1]], key_type ),
			"|", mnee.bind2string( nil, binds[ bind.axes[2]], key_type ), "|",
		})
	end

	local b = mnee.get_bind( bind )[ key_type or "main" ]
	if( b[1] == "is_axis" ) then
		out = out..b[2]
		if( b[3] ~= nil ) then out = table.concat({ out, "; ", b[3]}) end
	else
		for b in pairs( b ) do
			out = table.concat({ out, ( out == "[" and "" or "; " ), b })
		end
	end
	return out.."]"
end

function mnee.play_sound( event )
	pen.play_sound({ "mods/mnee/files/sfx/mnee.bank", event })
end

function mnee.new_tooltip( gui, uid, text, data )
	return pen.new_tooltip( gui, uid, text, data, function( gui, uid, text, d )
		local size_x, size_y = unpack( d.dims )
		local pic_x, pic_y, pic_z = unpack( d.pos )

		local clr = pen.PALETTE.PRSP.BLUE
		uid = pen.new_text( gui, uid, pic_x + d.edging, pic_y + d.edging - 2, pic_z, text, {
			dims = { size_x - d.edging, size_y },
			line_offset = d.line_offset or -2,
			fast_render = true, --funcs = d.font_mods,
			color = { clr[1], clr[2], clr[3], pen.animate( 1, d.anim_frame, {
				ease_out = "sin3", frames = d.anim_frames,
			})},
		})
		
		local scale_x = pen.animate({2,size_x}, d.anim_frame, { ease_out = "sin3", frames = d.anim_frames })
		local scale_y = pen.animate({2,size_y}, d.anim_frame, { ease_out = "sin10", frames = d.anim_frames })
		local shift_x, shift_y = ( size_x - scale_x )/2, ( size_y - scale_y )/2
		uid = pen.new_image( gui, uid, pic_x + shift_x, pic_y + shift_y, pic_z, "mods/mnee/files/pics/dot_purple_dark.png", {
			s_x = scale_x, s_y = scale_y })
		uid = pen.new_image( gui, uid, pic_x + shift_x + 1, pic_y + shift_y + 1, pic_z - 0.01, "mods/mnee/files/pics/dot_white.png", {
			s_x = scale_x - 2, s_y = scale_y - 2 })
		return uid
	end)
end

function mnee.new_button( gui, uid, pic_x, pic_y, pic_z, pic, data )
	data = data or {}
	data.frames = data.frames or 20
	data.auid = data.auid or pic..pic_z
	data.no_anim = data.no_anim or false
	data.highlight = data.highlight or pen.PALETTE.PRSP.RED
	return pen.new_button( gui, uid, pic_x, pic_y, pic_z, pic, {
		lmb_event = function( gui, uid, pic_x, pic_y, pic_z, pic, d )
			if( not( data.no_anim )) then pen.atimer( data.auid.."l", nil, true ) end
			return uid, pic_x, pic_y, pic_z, pic, d
		end,
		rmb_event = function( gui, uid, pic_x, pic_y, pic_z, pic, d )
			if( not( data.no_anim )) then pen.atimer( data.auid.."r", nil, true ) end
			return uid, pic_x, pic_y, pic_z, pic, d
		end,
		hov_event = function( gui, uid, pic_x, pic_y, pic_z, pic, d )
			if( pen.vld( data.tip )) then uid = mnee.new_tooltip( gui, uid, data.tip, { is_active = true }) end
			uid = pen.new_image( gui, uid, pic_x - 0.5, pic_y - 0.5, pic_z + 0.001, pen.FILE_PIC_NUL, {
				s_x = d.pic_w/2 + 1, s_y = d.pic_h/2 + 1, color = data.highlight })
			return uid, pic_x, pic_y, pic_z, pic, d
		end,
		pic_func = function( gui, uid, pic_x, pic_y, pic_z, pic, d )
			local a = ( data.no_anim or false ) and 1 or math.min(
				pen.animate( 1, data.auid.."l", { frames = data.frames }),
				pen.animate( 1, data.auid.."r", { frames = data.frames }))
			local c_anim, s_anim = 0.75 + 0.25*a, 2*( 1 - a )/d.pic_w
			local clr = pen.magic_rgb({255,255,255}, false, "hsv" ); clr[3] = c_anim
			return pen.new_image( gui, uid, pic_x + ( 1 - s_anim )*d.pic_w, pic_y - ( 1 - s_anim )*d.pic_h, pic_z, pic, {
				s_x = s_anim, s_y = s_anim, color = pen.magic_rgb( crl, true, "hsv" )
			})
		end,
	})
end

function mnee.new_pager( gui, uid, pic_x, pic_y, pic_z, data )
	local clicked, r_clicked, sfx_type = {false,false}, {false,false}, 0
	uid, clicked[1], r_clicked[1] = mnee.new_button( gui, uid, pic_x, pic_y, pic_z, "mods/mnee/files/pics/key_left.png", {
		auid = table.concat({ "page_", data.auid, "_l" })})
	
	if( data.profile_mode ) then pic_y = pic_y + 11 else pic_x = pic_x + 11 end
	uid = pen.new_image( gui, uid, pic_x, pic_y, pic_z, "mods/mnee/files/pics/button_21_B.png", { can_click = true })
	if( data.profile_mode ) then uid = mnee.new_tooltip( gui, uid, GameTextGetTranslatedOrNot( "$mnee_this_profile" ).."." ) end
	local text = ( data.profile_mode or false ) and string.char( data.page + 64 ) or data.page
	uid = pen.new_text( gui, uid, pic_x + 2, pic_y, pic_z, text, { fast_render = true, color = pen.PALETTE.PRSP.BLUE })
	
	pic_x = pic_x + 22
	if( data.profile_mode ) then pic_x, pic_y = pic_x - 11, pic_y - 11 end
	uid, clicked[2], r_clicked[2] = mnee.new_button( gui, uid, pic_x, pic_y, pic_z, "mods/mnee/files/pics/key_right.png", {
		auid = table.concat({ "page_", data.auid, "_r" })})
	
	uid, data.page, sfx_type = pen.new_pager( gui, uid, pic_x, pic_y, pic_z, {
		func = data.func, order_func = data.order_func,
		list = data.list, page = data.page, items_per_page = data.items_per_page,
		click = { clicked[1] and 1 or ( r_clicked[1] and -1 or 0 ), clicked[2] and 1 or ( r_clicked[2] and -1 or 0 )}
	})
	if( sfx_type == 1 ) then
		mnee.play_sound( "button_special" )
	elseif( sfx_type == -1 ) then
		mnee.play_sound( "switch_page" )
	end
	return uid, data.page
end

--[INPUT]
function mnee.vanilla_input( name )
	local frame, out = GameGetFrameNum(), {false,false}
	local ctrl_comp = pen.magic_comp( mnee.get_ctrl(), "ControlsComponent" )
	if( pen.vld( ctrl_comp, true )) then
		out = { ComponentGetValue2( ctrl_comp, "mButtonDown"..name ), ComponentGetValue2( ctrl_comp, "mButtonFrame"..name ) == frame }
	end
	return out
end

function mnee.mnin_key( name, pressed_mode, is_vip, key_mode )
	if( GameHasFlagRun( mnee.SERV_MODE ) and not( mnee.ignore_service_mode )) then return false end
	if( GameHasFlagRun( mnee.TOGGLER ) and not( is_vip )) then return false end
	return pen.t.loop( mnee.get_keys( key_mode ), function( i, key )
		if( key ~= name ) then return end
		if( pressed_mode ) then
			if( mnee.get_disarmer()[ "key"..key ] == nil ) then
				mnee.add_disarmer( "key"..key )
				return true
			else return false end
		else return true end
	end) or false
end

function mnee.mnin_bind( mod_id, name, dirty_mode, pressed_mode, is_vip, loose_mode, key_mode )
	local abort_tbl = { false, false, false }
	if( GameHasFlagRun( mnee.SERV_MODE ) and not( mnee.ignore_service_mode )) then return unpack( abort_tbl ) end
	if( GameHasFlagRun( mnee.TOGGLER ) and not( is_vip )) then return unpack( abort_tbl ) end
	if( not( mnee.is_priority_mod( mod_id ))) then return unpack( abort_tbl ) end
	
	local keys_down = mnee.get_keys( key_mode )
	local out, is_gone, is_jpad = false, true, false
	local binding = mnee.get_bindings()[ mod_id ][ name ]
	if( not( pen.vld( binding ))) then return unpack( abort_tbl ) end
	if( not( pen.vld( keys_down ))) then return unpack( abort_tbl ) end
	
	for i = 1,2 do
		local bind = mnee.get_bind( binding )[ i == 1 and "main" or "alt" ]
		local high_score, score = pen.t.count( bind ), 0
		if( bind["_"] ~= nil ) then
			goto continue
		else is_gone = false end

		if( high_score < 1 ) then goto continue end
		if( high_score > 1 and not( loose_mode ) and high_score ~= #keys_down ) then goto continue end
		if( high_score == 1 and not( dirty_mode )) then
			for i,key in ipairs( keys_down ) do
				if( mnee.SPECIAL_KEYS[ key ] ~= nil ) then goto continue end
			end
		end
		
		for i,key in ipairs( keys_down ) do
			if( bind[ key ] ~= nil ) then score = score + 1 end
		end
		if( score == high_score ) then
			if( pressed_mode ) then
				if( mnee.get_disarmer()[ mod_id..name ] == nil ) then
					mnee.add_disarmer( mod_id..name )
				else return unpack( abort_tbl ) end
			end
			out = true
		end
		
		::continue::
		if( out ) then
			is_jpad = mnee.jpad_check( bind )
			if( binding.on_down ~= nil ) then out = binding.on_down( binding, i == 2, is_jpad ) end
			break
		end
	end
	return out, is_gone, is_jpad
end

function mnee.mnin_axis( mod_id, name, dirty_mode, pressed_mode, is_vip, key_mode, skip_deadzone )
	local abort_tbl = { 0, false, false, false }
	if( GameHasFlagRun( mnee.SERV_MODE ) and not( mnee.ignore_service_mode )) then return unpack( abort_tbl ) end
	if( GameHasFlagRun( mnee.TOGGLER ) and not( is_vip )) then return unpack( abort_tbl ) end
	if( not( mnee.is_priority_mod( mod_id ))) then return unpack( abort_tbl ) end
	
	local binding = mnee.get_bindings()[ mod_id ][ name ]
	local out, is_gone, is_buttoned, is_jpad = 0, true, false, false
	if( not( pen.vld( binding ))) then return unpack( abort_tbl ) end

	for i = 1,2 do
		local bind = mnee.get_bind( binding )[ i == 1 and "main" or "alt" ]
		local value, memo = mnee.get_axes()[ bind[2]] or 0, {}
		if( bind[2] == "_" ) then
			goto continue
		else is_gone = false end
		
		is_buttoned = bind[3] ~= nil
		if( is_buttoned ) then
			if( mnee.mnin_key( bind[2], dirty_mode, pressed_mode, is_vip, key_mode )) then
				out = -1
			elseif( mnee.mnin_key( bind[3], dirty_mode, pressed_mode, is_vip, key_mode )) then
				out = 1
			end
			goto continue
		end
		
		if( not( skip_deadzone )) then
			value = mnee.apply_deadzone( value, binding.jpad_type, binding.deadzone )
		end

		if( pressed_mode ) then
			memo = mnee.get_axis_memo()
			if( memo[ bind[2]] == nil ) then
				if( math.abs( value ) > 0.5 ) then
					mnee.toggle_axis_memo( bind[2])
					out = pen.get_sign( value )
				end
			elseif( math.abs( value ) < 0.2 ) then
				mnee.toggle_axis_memo( bind[2])
			end
		else out = value end

		::continue::
		if( out ~= 0 ) then is_jpad = mnee.jpad_check( bind ); break end
	end
	return out, is_gone, is_buttoned, is_jpad
end

function mnee.mnin_stick( mod_id, name, dirty_mode, pressed_mode, is_vip, key_mode )
	local abort_tbl = {{ 0, 0 }, false, { false, false }, 0 }
	if( GameHasFlagRun( mnee.SERV_MODE ) and not( mnee.ignore_service_mode )) then return unpack( abort_tbl ) end
	if( GameHasFlagRun( mnee.TOGGLER ) and not( is_vip )) then return unpack( abort_tbl ) end
	if( not( mnee.is_priority_mod( mod_id ))) then return unpack( abort_tbl ) end
	
	local binding = mnee.get_bindings()[ mod_id ][ name ]
	if( binding == nil ) then return unpack( abort_tbl ) end

	local acc = 100
	local val_x, gone_x, buttoned_x = mnee.mnin_axis( mod_id, binding.axes[1], dirty_mode, pressed_mode, is_vip, key_mode, true )
	local val_y, gone_y, buttoned_y = mnee.mnin_axis( mod_id, binding.axes[2], dirty_mode, pressed_mode, is_vip, key_mode, true )
	local magnitude = mnee.apply_deadzone( math.sqrt( val_x^2 + val_y^2 ), binding.jpad_type, binding.deadzone )
	local direction = math.rad( math.floor( math.deg( math.atan2( val_y, val_x )) + 0.5 ))
	val_x, val_y = pen.rounder( magnitude*math.cos( direction ), acc ), pen.rounder( magnitude*math.sin( direction ), acc )
	return { val_x, val_y }, gone_x or gone_y, { buttoned_x, buttoned_y }, direction
end

function mnee.mnin( mode, id_data, data )
	local map = {
		key = { mnee.mnin_key, {1}, { "pressed", "vip", "mode" }},
		bind = { mnee.mnin_bind, {1,2}, { "dirty", "pressed", "vip", "loose", "mode" }},
		axis = { mnee.mnin_axis, {1,2}, { "dirty", "pressed", "vip", "mode" }},
		stick = { mnee.mnin_stick, {1,2}, { "dirty", "pressed", "vip", "mode" }},
	}

	data, func = data or {}, map[ mode ]
	id_data = pen.get_hybrid_table( id_data )
	
	local inval = {}
	for i,v in ipairs( func[2]) do
		if( id_data[v] ~= nil ) then table.insert( inval, id_data[v]) end
	end
	for i,v in ipairs( func[3]) do
		table.insert( inval, data[v] or false )
	end
	return func[1]( unpack( inval ))
end

function mnee.get_keyboard_input( no_shifting )
	local lists = dofile_once( "mods/mnee/lists.lua" )
	local is_shifted = ( InputIsKeyDown( 225 ) or InputIsKeyDown( 229 )) and not( no_shifting )
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

--[GLOBALS]
mnee.AMAP_MEMO = "mnee_mapping_memo"
mnee.INITER = "MNEE_IS_GOING"
mnee.TOGGLER = "MNEE_DISABLED"
mnee.RETOGGLER = "MNEE_REDO"
mnee.UPDATER = "MNEE_RELOAD"
mnee.JPAD_UPDATE = "MNEE_JPAD_UPDATE"
mnee.SERV_MODE = "MNEE_HOLD_UP"
mnee.PRIO_MODE = "MNEE_PRIORITY_MODE"

mnee.SPECIAL_KEYS = pen.t.unarray({
	"left_shift", "right_shift",
	"left_ctrl", "right_ctrl",
	"left_alt", "right_alt",
})
mnee.BANNED_KEYS = pen.t.unarray({
	"left_windows", "right_windows",
})

mnee.INMODES = {
	guied = function( ctrl_body, active )
		if( pen.vld( active )) then
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

--[LEGACY]
function is_key_down( name, dirty_mode, pressed_mode, is_vip, key_mode )
	return mnee.mnin_key( name, pressed_mode, is_vip, key_mode )
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
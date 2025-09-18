if( ModIsEnabled( "penman" )) then
	dofile_once( "mods/penman/_libman.lua" )
else dofile_once( "mods/mnee/_penman.lua" ) end

mnee = mnee or {}
mnee.G = mnee.G or {}

------------------------------------------------------		[BACKEND]		------------------------------------------------------

---Custom sorter with numerical element.order_id support.
---@param tbl table
---@return string|number tbl_key, any tbl_value
function mnee.mod_sorter( tbl )
	return pen.t.order( tbl, function( a, b )
		local v1 = (( _MNEEDATA or {})[a] or {}).order_id or tbl[a].order_id or 100*string.byte( a )
		local v2 = (( _MNEEDATA or {})[b] or {}).order_id or tbl[b].order_id or 100*string.byte( b )
		return v1 < v2
	end)
end

---Custom sorter with alphabetical element.order_id support.
---@param tbl table
---@return string|number tbl_key, any tbl_value
function mnee.bind_sorter( tbl )
	return pen.t.order( tbl, function( a, b )
		return (( tbl[a].order_id or a ) < ( tbl[b].order_id or b ))
	end)
end

---Streamlined bind_data.keys getter with integrated profile resolver; use this instead of indexing directly.
---@param bind_data table
---@param profile? number [DFT: 1 ]
---@return table bind_keys
function mnee.get_pbd( bind_data, profile )
	if( bind_data.axes ~= nil or bind_data.keys == "axes" ) then return { "is_axis", "_" } end
	return bind_data.keys[ profile or pen.setting_get( "mnee.PROFILE" )] or bind_data.keys[1]
end

---Control entity getter (it's a child of the WorldStateEntity).
---@return entity_id ctrl_body
function mnee.get_ctrl()
	return pen.get_child( GameGetWorldStateEntity(), "mnee_ctrl" )
end

---Clamps values below the threshold to 0 and rescales everything above it to always return values within [0;1] range.
---@param v number The value to be zoned.
---@param kind? deadzone_type The type of the deadzone. [DFT: "EXTRA" ]
---@param zero_offset? number An additional inherent shift of the zone radius. [DFT: 0 ]
---@return number
function mnee.apply_deadzone( v, kind, zone_offset )
	if( v == 0 ) then return 0 end
	zone_offset = pen.setting_get( "mnee.LIVING" ) and 0 or ( zone_offset or 0 )
	
	local total = 1000
	local deadzone = total*math.min( zone_offset + pen.setting_get( "mnee.DEADZONE_"..( kind or "EXTRA" ))/20, 0.999 )
	v = math.floor( total*v )
	v = math.abs( v ) < deadzone and 0 or v
	if( math.abs( v ) > 0 ) then v = ( v - deadzone*pen.get_sign( v ))/( total - deadzone ) end
	return v
end

---An entire aim-assist framework packed into a single function.
---@param hooman entity_id The one doing the aiming.
---@param pos table { pos_x, pos_y }
---@param angle number Real aiming angle.
---@param is_active? boolean Set to true to suspend autoaiming. [DFT: false ]
---@param is_searching? boolean Set to true to incorporate the stats of the last shot into computations. [DFT: false ]
---@param data? MneeAutoaimData
---@return number angle, boolean is_adjusted
function mnee.aim_assist( hooman, pos, angle, is_active, is_searching, data )
	data = data or {}
	data.setting = data.setting or "mnee.AUTOAIM"
	data.tag_tbl = data.tag_tbl or {"homing_target"}
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
	if( not( is_hit )) then hit_x, hit_y = pos[1] + ray_x, pos[2] + ray_y end
	local dir_x, dir_y = pen.get_sign( hit_x - pos[1]), pen.get_sign( hit_y - pos[2])
	local meats, the_one = {}, 0
	for i = 1,#data.tag_tbl do
		meats = pen.t.add( meats, EntityGetInRadiusWithTag( hit_x, hit_y, search_distance, data.tag_tbl[i]) or {})
	end

	local min_dist = -1
	pen.t.loop( meats, function( i, meat )
		if( hooman == meat ) then return end
		if( EntityGetRootEntity( meat ) ~= meat ) then return end

		local t_x, t_y = EntityGetFirstHitboxCenter( meat )
		if( RaytracePlatforms( pos[1], pos[2], t_x, t_y )) then return end
		
		local t_delta_x, t_delta_y = t_x - pos[1], t_y - pos[2]
		local dist_p = math.sqrt(( t_delta_x )^2 + ( t_delta_y )^2 )
		local dist_h = math.sqrt(( t_x - hit_x )^2 + ( t_y - hit_y )^2 )
		local t_dir_x, t_dir_y = pen.get_sign( t_delta_x ), pen.get_sign( t_delta_y )
		if( math.abs( t_delta_x ) >= safe_zone and t_dir_x ~= dir_x ) then return end
		if( math.abs( t_delta_y ) >= safe_zone and t_dir_y ~= dir_y ) then return end

		local dist = 0.75*dist_p + 0.25*dist_h
		if( min_dist ~= -1 and dist >= min_dist ) then return end
		min_dist, the_one = dist, meat
	end)
	
	local is_done = false
	local delta_x, delta_y = 0, 0
	if( pen.vld( the_one, true )) then
		local t_x, t_y = EntityGetFirstHitboxCenter( the_one )
		delta_x, delta_y = t_x - pos[1], t_y - pos[2]
	end

	mnee.aim_assist_korrection = mnee.aim_assist_korrection or {0,0,0}

	pen.hallway( function()
		if( not( is_searching )) then return end
		local projectiles = EntityGetInRadiusWithTag( pos[1], pos[2], search_distance, "projectile" )
		if( not( pen.vld( projectiles ))) then return end

		local best_case = -1
		pen.t.loop( projectiles, function( i, proj )
			local proj_comp = EntityGetFirstComponentIncludingDisabled( proj, "ProjectileComponent" )

			if( best_case > proj ) then return end
			if( not( pen.vld( proj_comp, true ))) then return end
			if( mnee.aim_assist_korrection[1] > proj ) then return end
			if( mnee.aim_assist_korrection[1] == best_case ) then return end
			if( ComponentGetValue2( proj_comp, "mWhoShot" ) ~= hooman ) then return end
			best_case = proj
		end)

		if( not( pen.vld( best_case, true ))) then return end
		local proj_comp = EntityGetFirstComponentIncludingDisabled( best_case, "ProjectileComponent" )
		local v_comp = EntityGetFirstComponentIncludingDisabled( best_case, "VelocityComponent" )
		local mass = ComponentGetValue2( v_comp, "mass" )
		local gravity = ComponentGetValue2( v_comp, "gravity_y" )
		local vel = ComponentGetValue2( proj_comp, "mInitialSpeed" )
		local friction = ComponentGetValue2( v_comp, "air_friction" )
		mnee.aim_assist_korrection = { best_case, vel, gravity }
	end)
	
	local function fuck_it( x, y, v, g, h, sign ) --no air drag
		--https://www.reddit.com/r/FTC/comments/jis4p3/find_launch_angle_given_distance_to_target/
		local step1 = ( g*y*x^2 - g*h*x^2 )/( v^2 )
		local step2 = x^2 + y^2 + h^2 - 2*y*h
		local step3 = ( step1 - x^2 )^2 - step2*( g^2*x^4 )/( v^4 )
		return math.acos( math.sqrt(( x^2 - step1 + sign*math.sqrt( step3 ))/( 2*step2 )))
	end
	local function fuck_it_check( a, d, v, g )
		return d*math.tan( a ) + ( g*d^2 )/( 2*v^2*math.cos( a )^2 )
	end

	pen.hallway( function()
		if( delta_x == 0 ) then return end
		
		is_done = true
		local so_back = true
		local strength = 0.1*autoaim
		local min_offset = math.rad( 0.5 )*autoaim
		local t_angle = math.atan2( delta_y, delta_x )
		pen.hallway( function()
			if( mnee.aim_assist_korrection[1] <= 0 ) then return end

			local x, y, h = delta_x, 0, delta_y
			local x_sign, y_sign = pen.get_sign( delta_x ), pen.get_sign( delta_y )
			local v, g = mnee.aim_assist_korrection[2], mnee.aim_assist_korrection[3] + 0.000001
			
			if( y_sign < 0 ) then y, h = -h, 0 end
			local a = pen.try( fuck_it, { x, y, v, g, h, 1 }) or 9999
			local b = pen.try( fuck_it, { x, y, v, g, h, -1 }) or 9999
			t_angle = y_sign*math.min( a, b )

			so_back = pen.vld( t_angle )
			if( not( so_back )) then return end
			if( x_sign < 0 ) then t_angle = -y_sign*t_angle + math.rad( 180 ) end

			local drift = fuck_it_check( t_angle, delta_x, v, g ) - delta_y
			if( drift > 0.1 ) then t_angle = -t_angle end
			if( not( data.do_lining )) then return end
			for i = 1,math.abs( delta_x ),5 do
				local d = x_sign*i
				local y = fuck_it_check( t_angle, d, v, g )
				GameCreateSpriteForXFrames( "mods/mnee/files/pics/dot_white.png", pos[1] + d, pos[2] + y, true, 0, 0, 1, true )
			end
		end)
		
		if( not( so_back )) then return end
		local delta_a = pen.get_angular_delta( t_angle, angle )
		angle = angle + pen.limiter( pen.limiter( strength*delta_a, min_offset, true ), delta_a )

		if( not( pen.vld( data.pic ))) then return end
		GameCreateSpriteForXFrames( data.pic, pos[1] + delta_x, pos[2] + delta_y, true, 0, 0, 1, true )
	end)

	return angle, is_done
end

------------------------------------------------------		[INTERNAL]		------------------------------------------------------

---Active key list getter.
---@param inmode? string The name of the desired mode from mnee.INMODES list.
---@return table active_keys { key1, key2, key3, ...}
function mnee.get_keys( inmode )
	local keys = GlobalsGetValue( mnee.G_DOWN, "" )
	local inmode_func = mnee.INMODES[ inmode or "_" ]
	if( not( pen.vld( inmode_func ))) then return pen.t.pack( keys ) end
	local ctrl_body = mnee.get_ctrl()
	if( not( pen.vld( ctrl_body, true ))) then return pen.t.pack( keys ) end

	local frame_num = GameGetFrameNum()
	local storage = pen.magic_storage( ctrl_body, "mnee_down_"..inmode, nil, nil, true )	
	if( ComponentGetValue2( storage, "value_int" ) ~= frame_num ) then
		ComponentSetValue2( storage, "value_int", frame_num )
		ComponentSetValue2( storage, "value_string", inmode_func( ctrl_body, keys ))
	end
	return pen.t.pack( ComponentGetValue2( storage, "value_string" ))
end
---Active gamepad trigger state getter.
---@param inmode? string The name of the desired mode from mnee.TRIGGER_INMODES list.
---@return table trigger_states { 1gpd_l2=v, 1gpd_r2=v, 2gpd_l2=v, ...}
function mnee.get_triggers( inmode )
	local states = GlobalsGetValue( mnee.G_TRIGGERS, "" )
	local inmode_func = mnee.TRIGGER_INMODES[ inmode or "_" ]
	if( not( pen.vld( inmode_func ))) then return pen.t.unarray( pen.t.pack( states )) end
	local ctrl_body = mnee.get_ctrl()
	if( not( pen.vld( ctrl_body, true ))) then return pen.t.unarray( pen.t.pack( states )) end

	local frame_num = GameGetFrameNum()
	local storage = pen.magic_storage( ctrl_body, "mnee_triggers_"..inmode, nil, nil, true )	
	if( ComponentGetValue2( storage, "value_int" ) ~= frame_num ) then
		ComponentSetValue2( storage, "value_int", frame_num )
		ComponentSetValue2( storage, "value_string", inmode_func( ctrl_body, states ))
	end
	return pen.t.unarray( pen.t.pack( ComponentGetValue2( storage, "value_string" )))
end
---Active gamepad axis state getter.
---@param inmode? string The name of the desired mode from mnee.AXIS_INMODES list.
---@return table axis_states { 1gpd_axis_lh=v, 1gpd_axis_lv=v, 1gpd_axis_rh=v, 1gpd_axis_rv=v, 2gpd_axis_lh=v, ...}
function mnee.get_axes( inmode )
	local states = GlobalsGetValue( mnee.G_AXES, "" )
	local inmode_func = mnee.AXIS_INMODES[ inmode or "_" ]
	if( not( pen.vld( inmode_func ))) then return pen.t.unarray( pen.t.pack( states )) end
	local ctrl_body = mnee.get_ctrl()
	if( not( pen.vld( ctrl_body, true ))) then return pen.t.unarray( pen.t.pack( states )) end

	local frame_num = GameGetFrameNum()
	local storage = pen.magic_storage( ctrl_body, "mnee_axes_"..inmode, nil, nil, true )	
	if( ComponentGetValue2( storage, "value_int" ) ~= frame_num ) then
		ComponentSetValue2( storage, "value_int", frame_num )
		ComponentSetValue2( storage, "value_string", inmode_func( ctrl_body, states ))
	end
	return pen.t.unarray( pen.t.pack( ComponentGetValue2( storage, "value_string" )))
end

---Pressed-but-not-yet-released key list.
---@return table disarmed_keys { key_id_1=last_down_frame, key_id_2=last_down_frame, ...}
function mnee.get_disarmer()
	return pen.t.unarray( pen.t.pack( GlobalsGetValue( mnee.G_DISARMER, pen.DIV_1 )))
end
---Adds yet another downed key to constantly be reported as being released until actually released.
---@param key_id string A unique indentifier to ensure that the correct key is disarmed.
function mnee.add_disarmer( key_id )
	local disarmer = table.concat({ pen.DIV_2, key_id, pen.DIV_2, GameGetFrameNum(), pen.DIV_2, pen.DIV_1 })
	GlobalsSetValue( mnee.G_DISARMER, GlobalsGetValue( mnee.G_DISARMER, pen.DIV_1 )..disarmer )
end
---Disarming list cleaner (removes entries with over a frame of a difference to the present time).
function mnee.clean_disarmer()
	local disarmer = mnee.get_disarmer()
	if( not( pen.vld( disarmer ))) then return end

	local new_disarmer = {}
	local current_frame = GameGetFrameNum()
	for key,frame in pairs( disarmer ) do
		if( current_frame - frame < 2 ) then
			new_disarmer[ key ] = frame
		end
	end
	GlobalsSetValue( mnee.G_DISARMER, pen.t.pack( pen.t.unarray( new_disarmer )))
end

---Binds-to-execute list.
function mnee.get_exe()
	return pen.t.unarray( pen.t.pack( GlobalsGetValue( mnee.G_EXE, pen.DIV_1 )))
end
---Executable list cleaner (removes entries with over a frame of a difference to the present time).
function mnee.clean_exe()
	local exe = mnee.get_exe()
	if( not( pen.vld( exe ))) then return end

	local new_exe = {}
	local current_frame = GameGetFrameNum()
	for id,frame in pairs( exe ) do
		if( current_frame - frame < 1 ) then
			new_exe[ id ] = frame
		end
	end
	GlobalsSetValue( mnee.G_EXE, pen.t.pack( pen.t.unarray( new_exe )))
end

---Updates the setup_memo table.
---@param setup_tbl table { profile_num={ mod_id_1=setup_id, mod_id_2=setup_id, ...}, ...}
function mnee.set_setup_memo( setup_tbl )
	pen.setting_set( "mnee.SETUP", pen.t.parse( setup_tbl ))
end
---Returns the setup_memo table.
---@return table setup_table { profile_num={ mod_id_1=setup_id, mod_id_2=setup_id, ...}, ...}
function mnee.get_setup_memo()
	local setup_tbl = pen.t.parse( pen.setting_get( "mnee.SETUP" ))
	if( pen.vld( setup_tbl )) then return setup_tbl end

	dofile_once( "mods/mnee/bindings.lua" )
	setup_tbl = {{}}
	for mod_id,_ in pairs( _BINDINGS ) do
		setup_tbl[1][ mod_id ] = "_dft"
	end
	mnee.set_setup_memo( setup_tbl )
	return setup_tbl
end
---Returns the particular setup_id.
---@param mod_id string
---@return string setup_id
function mnee.get_setup_id( mod_id )
	local setup_memo = mnee.get_setup_memo()
	return ( setup_memo[ pen.setting_get( "mnee.PROFILE" )] or setup_memo[1])[ mod_id ] or "_dft"
end
---Sets the setup_id of the particular mod.
---@param mod_id string
---@param setup_id string
function mnee.set_setup_id( mod_id, setup_id )
	local setup_memo = mnee.get_setup_memo()
	local profile = pen.setting_get( "mnee.PROFILE" )
	if(( setup_memo[ profile ] or setup_memo[1])[ mod_id ] ~= setup_id ) then
		local stp_mm = pen.t.clone( setup_memo )
		stp_mm[ profile ] = stp_mm[ profile ] or pen.t.clone( setup_memo[1])
		stp_mm[ profile ][ mod_id ] = setup_id
		mnee.set_setup_memo( stp_mm )
		
		dofile_once( "mods/mnee/bindings.lua" )
		if( _MNEEDATA[ mod_id ] ~= nil and _MNEEDATA[ mod_id ].on_setup ~= nil ) then
			_MNEEDATA[ mod_id ].on_setup( _MNEEDATA[ mod_id ].setup_modes, setup_id )
		end
	end
end

---Forcefully remaps the gamepads to the table provided.
---@param jpad_tbl table { slot_value_1, slot_value_2, slot_value_3, slot_value_4 }
---(slot_value is [0;3] for gamepad assignment, -1 for emtpy and 5 for dummy gamepad insertion)
---@param no_update? boolean [DO NOT USE] Internal parameter. [DFT: false ]
function mnee.apply_jpads( jpad_tbl, no_update )
	GlobalsSetValue( mnee.G_JPADS, pen.t.pack( jpad_tbl ))
	if( not( no_update )) then GameAddFlagRun( mnee.JPAD_UPDATE ) end
end
---Returns true if the provided gamepad slot is active.
---@param slot_num? number Ranges from 1 to 4. [DFT: 1 ]
---@return boolean is_active
function mnee.is_jpad_real( slot_num )
	return (( pen.t.pack( GlobalsGetValue( mnee.G_JPADS, "" )))[ slot_num or 1 ] or -1 ) ~= -1
end
---Returns true if any of the keys within provided table are binded to a gamepad.
---@param keys table
---@return boolean is_jpad
function mnee.jpad_check( keys )
	for key,val in pairs( keys ) do
		if( string.find( type( key ) == "number" and val or key, "%dgpd_" )) then
			return true
		end
	end
	return false
end

---Returns the axis_memo table – essentially a disarmer but for axes.
---@return table axis_memo { axis_id_1, axis_id_2, ...}
function mnee.get_axis_memo()
	return pen.t.unarray( pen.t.pack( GlobalsGetValue( mnee.G_AXES_MEMO, pen.DIV_1 )))
end
---Adds new/removes existing axis from the axis_memo list.
---@param axis_id string
function mnee.toggle_axis_memo( axis_id )
	local memo = mnee.get_axis_memo()
	if( memo[ axis_id ] == nil ) then
		memo = table.concat({ GlobalsGetValue( mnee.G_AXES_MEMO, pen.DIV_1 ), axis_id, pen.DIV_1 })
	else memo[ axis_id ] = nil; memo = pen.t.pack( pen.t.unarray( memo )) end
	GlobalsGetValue( mnee.G_AXES_MEMO, memo )
end

---Returns true if the bindings from the provided mod are allowed to be processed.
---@param mod_id? string
---@return boolean is_allowed
function mnee.is_priority_mod( mod_id )
	local vip_mod = GlobalsGetValue( mnee.PRIO_MODE, "0" )
	return vip_mod == "0" or mod_id ~= vip_mod
end
---Makes it so only bindings from the provided mod are processed.
---@param mod_id string
function mnee.set_priority_mod( mod_id )
	GlobalsSetValue( mnee.PRIO_MODE, tostring( mod_id ))
end

---Global binding table getter.
---@param binds_only? boolean Returns keys with no metadata if is true. [DFT: false ]
---@return table binding_data { mod_id={ binding_1=binding_data, binding_2=binding_data, ...}, ...}
function mnee.get_bindings( binds_only )
	local updater_frame = tonumber( GlobalsGetValue( mnee.UPDATER, "0" ))
	if(( mnee.updater_memo or 0 ) ~= updater_frame ) then
		mnee.updater_memo = updater_frame
		mnee.binding_data = nil
	end
	
	if( binds_only or mnee.binding_data == nil ) then
		dofile_once( "mods/mnee/bindings.lua" )

		local binding_data = pen.t.parse( pen.setting_get( "mnee.BINDINGS" ))
		if( not( pen.vld( binding_data ))) then
			mnee.update_bindings( "nuke_it" )
			binding_data = pen.t.parse( pen.setting_get( "mnee.BINDINGS" ))
		end
		local bnd_dt = pen.t.clone( binding_data )
		if( binds_only ) then return bnd_dt end
		
		local skip_list = pen.t.unarray({ "keys", "keys_alt" })
		for mod,mod_tbl in pairs( bnd_dt ) do
			for bind,bind_tbl in pairs( mod_tbl ) do
				if( _BINDINGS[ mod ] == nil or _BINDINGS[ mod ][ bind ] == nil ) then
					goto continue end
				bnd_dt[ mod ] = pen.t.clone( bnd_dt[ mod ])
				bnd_dt[ mod ][ bind ] = pen.t.clone( bnd_dt[ mod ][ bind ])
				for k,v in pairs( _BINDINGS[ mod ][ bind ]) do
					if( skip_list[ k ] == nil ) then bnd_dt[ mod ][ bind ][ k ] = pen.t.clone( v ) end
				end
				::continue::
			end
		end
		mnee.binding_data = bnd_dt
	end

	return mnee.binding_data
end
---[DO NOT USE] Force-sets global binding table.
---@param binding_data table { mod_id={ binding_1=binding_data, binding_2=binding_data, ...}, ...}
function mnee.set_bindings( binding_data )
	if( not( pen.vld( binding_data ))) then return end
	
	local key_data = {}
	for mod,mod_tbl in pairs( binding_data ) do
		key_data[ mod ] = {}
		for bind,bind_tbl in pairs( mod_tbl ) do
			key_data[ mod ][ bind ] = {}
			key_data[ mod ][ bind ].keys = bind_tbl.keys
			if( bind_tbl.keys == "axes" ) then goto continue end

			for profile,key_tbl in pairs( bind_tbl.keys ) do
				if( not( pen.vld( key_data[ mod ][ bind ].keys[ profile ].main ))) then
					key_data[ mod ][ bind ].keys[ profile ].main = key_data[ mod ][ bind ].keys[1].main
				end
				if( not( pen.vld( key_tbl.alt ))) then
					if( key_data[ mod ][ bind ].keys[ profile ].main[1] == "is_axis" ) then
						key_data[ mod ][ bind ].keys[ profile ].alt = { "is_axis", "_" }
					else key_data[ mod ][ bind ].keys[ profile ].alt = { ["_"] = 1 } end
				end
			end

			::continue::
		end
	end
	
	pen.setting_set( "mnee.BINDINGS", pen.t.parse( key_data ))
	GlobalsSetValue( mnee.UPDATER, GameGetFrameNum())
end
---Updates global binding table and sets to setup-aware default any nil values within the structure.
---@param binding_data table { mod_id={ binding_1=binding_data, binding_2=binding_data, ...}, ...}
function mnee.update_bindings( binding_data )
	dofile_once( "mods/mnee/bindings.lua" )
	
	local tbl = {}
	if( type( binding_data ) ~= "table" ) then
		tbl = binding_data == "nuke_it" and {} or mnee.get_bindings( true )
	else tbl = pen.t.clone( binding_data ) end
	
	local new_keys = {}
	local profile = pen.setting_get( "mnee.PROFILE" )
	for mod,mod_tbl in pairs( _BINDINGS ) do
		local setup_id = "_dft"
		if( tbl[ mod ] == nil ) then tbl[ mod ] = {} end
		if( _MNEEDATA[ mod ] ~= nil and _MNEEDATA[ mod ].setup_modes ~= nil ) then
			setup_id = mnee.get_setup_id( mod )
		end
		
		for bind,bind_tbl in pairs( mod_tbl ) do
			tbl[ mod ][ bind ] = tbl[ mod ][ bind ] or {}
			if( bind_tbl.axes == nil ) then
				tbl[ mod ][ bind ].keys = tbl[ mod ][ bind ].keys or {}
			else tbl[ mod ][ bind ].keys = "axes"; goto continue end

			for i,v in ipairs({ 1, profile }) do
				tbl[ mod ][ bind ].keys[ v ] = tbl[ mod ][ bind ].keys[ v ] or {}
				if( _MNEEDATA[ mod ] ~= nil ) then
					new_keys = pen.t.get( _MNEEDATA[ mod ].setup_modes, setup_id, nil, nil, {})
					if( pen.vld( new_keys ) and new_keys.binds ~= nil ) then
						new_keys = pen.t.clone( new_keys.binds[ bind ])
					else new_keys = nil end
				else new_keys = nil end
				
				if( pen.vld( new_keys )) then
					if( type( new_keys[1]) == "table" ) then
						tbl[ mod ][ bind ].keys[ v ].main = tbl[ mod ][ bind ].keys[ v ].main or new_keys[1]
						tbl[ mod ][ bind ].keys[ v ].alt = tbl[ mod ][ bind ].keys[ v ].alt or new_keys[2]
					else tbl[ mod ][ bind ].keys[ v ].main = tbl[ mod ][ bind ].keys[ v ].main or new_keys end
				else
					new_keys = pen.t.clone( bind_tbl )
					tbl[ mod ][ bind ].keys[ v ].main = tbl[ mod ][ bind ].keys[ v ].main or new_keys.keys
					tbl[ mod ][ bind ].keys[ v ].alt = tbl[ mod ][ bind ].keys[ v ].alt or new_keys.keys_alt
				end
			end
			
			::continue::
		end
	end
	
	mnee.set_bindings( tbl )
end

------------------------------------------------------		[FRONTEND]		------------------------------------------------------

---Returns the shifted value of a key (= the value a key should return after shift is pressed).
---@param key string
---@return string shifted_key
function mnee.get_shifted_key( key )
	local check = string.byte( key )
	if( #key == 1 and check > 96 and check < 123 ) then
		return string.char( check - 32 )
	else return dofile_once( "mods/mnee/lists.lua" )[4][ key ] or key end
end

---Prettifies the passed key.
---@param key string
---@param extra_fancy boolean
---@return string fancy_key
function mnee.get_fancy_key( key, extra_fancy )
	local k, is_jpad = string.gsub( key, "%dgpd_", "" )
	local name = pen.get_hybrid_table( dofile_once( "mods/mnee/lists.lua" )[5][k])
	local out = name[( extra_fancy or false ) and 2 or 1 ] or name[1] or k
	if( is_jpad > 0 ) then
		return table.concat({ "GP", string.sub( key, 1, 1 ), "(", out, ")" })
	else return out end
end

---Returns the functional counterpart of the key provided, the main purpose is to unify ALTs/SHIFTs/CTRLs.
---@param ket string
---@param do_special? boolean Controls special key merging. [DFT: true ]
---@param do_numpad? boolean Controls numpad merging. [DFT: false ]
---@return string|nil
function mnee.get_twin_key( key, do_special, do_numpad )
	if( not( do_special or do_numpad )) then return "" end
	local twins = dofile_once( "mods/mnee/lists.lua" )[6]

	local twin = twins.special[ key ]
	if( do_numpad ) then twin = twin or twins.numpad[ key ] end
	return twin or ""
end

---Returns UI-ready binding key list.
---@param mod_id string
---@param bind_id string
---@param is_compact boolean|number Minimizes the length of the output. Set to 2 to get only alt bind.
---@return string binding_keys
function mnee.get_binding_keys( mod_id, bind_id, is_compact )
	local binding = mnee.get_bindings()[ mod_id ][ bind_id ]
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
			out = GameTextGet( "$mnee_nil" )
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

	local b = mnee.get_pbd( binding )
	local got_alt = not( b.alt["_"] ~= nil or b.alt[2] == "_" )
	local out = figure_it_out( b[( got_alt and is_compact == 2 ) and "alt" or "main" ])
	if( is_compact ) then
		out = string.lower( out )
	elseif( got_alt ) then
		out = table.concat({ out, GameTextGet( "$mnee_or" ), figure_it_out( b.alt )})
	end
	return out
end

---[DO NOT USE] A basic variant of get_binding_keys. <br>
---Not as compact as is_compact alternative but more subtle than the fully fledged version.
---@param bind_data table
---@param key_type? key_type [DFT: "main" ]
---@param binding_data? table Pass full binding_data if bind_data.axes ~= nil.
---@return string binding_keys
function mnee.bind2string( bind, key_type, binding_data )
	local out = "["
	if( binding_data ~= nil and bind.axes ~= nil ) then
		return table.concat({
			"|", mnee.bind2string( binding_data[ bind.axes[1]], key_type ),
			"|", mnee.bind2string( binding_data[ bind.axes[2]], key_type ), "|",
		})
	end

	local b = mnee.get_pbd( bind )[ key_type or "main" ]
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

---Draws a button themed after Prospero Inc.
---@param pic_x number
---@param pic_y number
---@param pic_z number
---@param pic path
---@param data? PenmanButtonData
---@return boolean clicked, boolean r_clicked, boolean is_hovered
function mnee.new_button( pic_x, pic_y, pic_z, pic, data )
	data = data or {}
	data.ignore_multihover = false
	data.frames = data.frames or 20
	data.highlight = data.highlight or pen.PALETTE.PRSP.RED
	
	data.lmb_event = data.lmb_event or function( pic_x, pic_y, pic_z, pic, d )
		if( not( d.no_anim )) then pen.atimer( d.auid.."l", nil, true ) end
		return pic_x, pic_y, pic_z, pic, d
	end
	data.rmb_event = data.rmb_event or function( pic_x, pic_y, pic_z, pic, d )
		if( not( d.no_anim )) then pen.atimer( d.auid.."r", nil, true ) end
		return pic_x, pic_y, pic_z, pic, d
	end
	data.hov_event = data.hov_event or function( pic_x, pic_y, pic_z, pic, d )
		if( pen.vld( d.tip )) then
			pen.uncutter( function( cut_x, cut_y, cut_w, cut_h )
				return mnee.new_tooltip( d.tip, { is_active = true, min_width = d.min_width })
			end)
		end
		if( d.highlight ) then pen.new_pixel(
			pic_x - 1, pic_y - 1, pic_z + 0.01, d.highlight,
			( d.s_x or 1 )*d.dims[1] + 2, ( d.s_y or 1 )*d.dims[2] + 2 ) end
		return pic_x, pic_y, pic_z, pic, d
	end

	return pen.new_button( pic_x, pic_y, pic_z, pic, data )
end

---Draws a tooltip themed after Prospero Inc.
---@param text? string
---@param data? PenmanTooltipData
---@return boolean is_active
function mnee.new_tooltip( text, data )
	data = data or {}; data.frames = data.frames or 10
	if( data.dims == true ) then data.dims = { -1, -1 } end
	data.text_prefunc = function( text, data )
		text = pen.get_hybrid_table( text )
		
		local extra = 0
		if( pen.vld( text[2])) then
			data.fully_featured, extra = true, 2
			text[1] = text[1].."\n{>indent>{{>color>{{-}|PRSP|PURPLE|{-}"..text[2].."}<color<}}<indent<}" end
		return text[1], extra, 0
	end

	return pen.new_tooltip( text, data, function( text, d )
		local size_x, size_y = unpack( d.dims )
		local pic_x, pic_y, pic_z = unpack( d.pos )
		
		if( pen.vld( text )) then
			pen.new_text( pic_x + d.edging, pic_y + d.edging - 2, pic_z, text, {
				fully_featured = d.fully_featured, --funcs = d.font_mods,
				dims = { size_x - d.edging, size_y }, line_offset = d.line_offset or -2,
				color = pen.PALETTE.PRSP.BLUE, alpha = pen.animate( 1, d.t, { ease_in = "exp5", frames = d.frames }),
			})
		end
		
		local scale_x = pen.animate({2,size_x}, d.t, { ease_in = "exp1.1", ease_out = "wav1.5", frames = d.frames })
		local scale_y = pen.animate({2,size_y}, d.t, { ease_out = "sin", frames = d.frames })
		pen.new_pixel( pic_x, pic_y, pic_z + 0.02,
			pen.PALETTE.PRSP[( d.is_special or false ) and "RED" or "BLUE" ], scale_x, scale_y )
		pen.new_pixel( pic_x + 1, pic_y + 1, pic_z + 0.01, pen.PALETTE.PRSP.WHITE, scale_x - 2, scale_y - 2 )
	end)
end

---Draws a pager themed after Prospero Inc.
---@param pic_x number
---@param pic_y number
---@param pic_z number
---@param data MneePagerData
---@return number page
function mnee.new_pager( pic_x, pic_y, pic_z, data )
	local t_x, t_y = pic_x, pic_y + 99
	if( data.compact_mode ) then t_y = t_y + 11 end
	local clicked, r_clicked, sfx_type = {false,false}, {false,false}, 0
	clicked[1], r_clicked[1] = mnee.new_button( t_x, t_y, pic_z, "mods/mnee/files/pics/key_left.png", {
		auid = table.concat({ "page_", data.auid, "_l" })})
	if( not( data.compact_mode )) then t_x = t_x + 22 end
	clicked[2], r_clicked[2] = mnee.new_button( t_x + 11, t_y, pic_z, "mods/mnee/files/pics/key_right.png", {
		auid = table.concat({ "page_", data.auid, "_r" })})
	
	local max_page = 0
	data.page, max_page, sfx_type = pen.new_pager( pic_x, pic_y, pic_z, {
		func = data.func, order_func = data.order_func,
		list = data.list, page = data.page, items_per_page = data.items_per_page,
		click = { clicked[1] and 1 or ( r_clicked[1] and -1 or 0 ), clicked[2] and 1 or ( r_clicked[2] and -1 or 0 )}
	})
	if( sfx_type == 1 ) then
		pen.play_sound( pen.TUNES.PRSP.CLICK_ALT )
	elseif( sfx_type == -1 ) then pen.play_sound( pen.TUNES.PRSP.SWITCH ) end
	
	if( data.compact_mode ) then t_y = t_y - 11 else t_x = pic_x + 11 end
	pen.new_image( t_x, t_y, pic_z,
		"mods/mnee/files/pics/button_21_"..( max_page > 1 and "B" or "A" )..".png", { can_click = true })
	if( max_page > 1 ) then
		if( data.profile_mode ) then mnee.new_tooltip( GameTextGet( "$mnee_this_profile" )) end

		local text = data.page..( max_page < 10 and "/"..max_page or "" )
		if( data.profile_mode ) then text = data.page - 1; text = string.char(( text < 1 and -29 or text ) + 64 ) end
		pen.new_text( t_x + 2, t_y, pic_z - 0.01, text, { color = pen.PALETTE.PRSP.BLUE })
	end
	
	return data.page
end

---Draws a scroller themed after Prospero Inc.
---@param sid string
---@param pic_x number
---@param pic_y number
---@param pic_z number
---@param size_x number
---@param size_y number
---@param func PenmanScrollerFunction|fun( scroll_pos:number ):{ height:number }
---@param data? PenmanScrollerData
function mnee.new_scroller( sid, pic_x, pic_y, pic_z, size_x, size_y, func, data )
	data = data or {}
	data.bar_colors = data.bar_colors or {
		pen.PALETTE.PRSP[ data.is_compact and "PURPLE" or "BLUE" ], pen.PALETTE.PRSP.RED,
		pen.PALETTE.PRSP[ data.is_compact and "PURPLE" or "BLUE" ], pen.PALETTE.PRSP.RED,
		pen.PALETTE.PRSP[ data.is_compact and "PURPLE" or "BLUE" ], pen.PALETTE.PRSP.RED,
		pen.PALETTE.PRSP[ data.is_compact and "PURPLE" or "BLUE" ], pen.PALETTE.PRSP.RED,
		pen.PALETTE.PRSP.PURPLE, pen.PALETTE.PRSP.BLUE
	}
	
	if( not( data.is_compact )) then
		pen.new_pixel( pic_x + size_x, pic_y, pic_z - 0.03, pen.PALETTE.PRSP.BLUE, 3, 1 )
		pen.new_pixel( pic_x + size_x, pic_y + size_y - 1, pic_z - 0.03, pen.PALETTE.PRSP.BLUE, 3, 1 )
		pen.new_pixel( pic_x + size_x + 1, pic_y, pic_z - 0.08, pen.PALETTE.PRSP.PURPLE, 1, size_y )
	end

	return pen.try( pen.new_scroller, {
		sid, pic_x, pic_y, pic_z, size_x, size_y, func, data
	}, function( log, _, pic_x, pic_y )
		pen.new_shadowed_text( pic_x, pic_y - 11, pen.LAYERS.DEBUG,
			mnee.G.m_list, { color = pen.PALETTE.PRSP.RED, color_shadow = pen.PALETTE.PRSP.BLUE })
		pen.new_shadowed_text( pic_x, pic_y, pen.LAYERS.DEBUG, log, {
			color = pen.PALETTE.PRSP.RED, color_shadow = pen.PALETTE.PRSP.BLUE, dims = { size_x - 1, -1 }})
	end)
end

-------------------------------------------------------		[INPUT]		-------------------------------------------------------

---Adds yet another bind event to be executed.
---@param mod_id string
---@param bind_id string
function mnee.exe( mod_id, bind_id )
	local exe = table.concat({ pen.DIV_2, mod_id..bind_id, pen.DIV_2, GameGetFrameNum() + 1, pen.DIV_2, pen.DIV_1 })
	GlobalsSetValue( mnee.G_EXE, GlobalsGetValue( mnee.G_EXE, pen.DIV_1 )..exe )
end

---Streamlined and player entity independent way of getting ControlsComponent inputs.
---@param button string The meaningful part of the button name (e.g. use "Fire" instead of "mButtonDownFire").
---@param entity_id? entity_id Will default to mnee.get_ctrl() if left empty. 
---@return boolean is_down, boolean is_just_down
function mnee.vanilla_input( button, entity_id )
	if( GameHasFlagRun( mnee.SERV_MODE )) then return false, false end
	local ctrl_comp = EntityGetFirstComponentIncludingDisabled( entity_id or mnee.get_ctrl(), "ControlsComponent" )
	if( not( pen.vld( ctrl_comp, true ))) then return false, false end
	return ComponentGetValue2( ctrl_comp, "mButtonDown"..button ), ComponentGetValue2( ctrl_comp, "mButtonFrame"..button ) == GameGetFrameNum()
end

---Addresses the raw key by its internal name; is unmodifiable and does not show up in the binding menu.
---@param key_id string See full_board table in mnee/lists.lua for all the IDs.
---@param pressed_mode? boolean Enable to report "true" only once and then wait until the key is reset. [DFT: false ]
---@param is_vip? boolean Enable to stop this key from being disabled by user via global toggle. [DFT: false ]
---@param inmode? string The name of the desired mode from mnee.INMODES list.
---@return boolean is_down
function mnee.mnin_key( key_id, pressed_mode, is_vip, inmode )
	if( GameHasFlagRun( mnee.SERV_MODE ) and not( mnee.ignore_service_mode )) then return false end
	if( GameHasFlagRun( mnee.TOGGLER ) and not( is_vip )) then return false end
	return pen.t.loop( mnee.get_keys( inmode ), function( i, key )
		if( key ~= key_id ) then return end
		if( pressed_mode ) then
			local check = mnee.get_disarmer()[ "key"..key ] ~= nil
			mnee.add_disarmer( "key"..key )
			if( check ) then return false end
		end
		return true
	end) or false
end

---Operates via flexible and rebindable single- or multi-keyed combinations, shows up in the binding menu.
---@param mod_id string
---@param bind_id string
---@param pressed_mode? boolean Enable to report "true" only once and then wait until the key is reset. [DFT: false ]
---@param is_vip? boolean Enable to stop this bind from being disabled by user via global toggle. [DFT: false ]
---@param inmode? string The name of the desired mode from mnee.INMODES list.
---@return boolean is_down, boolean is_unbound, boolean is_jpad
function mnee.mnin_bind( mod_id, bind_id, pressed_mode, is_vip, inmode )
	local id = mod_id..bind_id
	if( mnee.get_exe()[ id ]) then return true, false, false end

	local abort_tbl = { false, false, false }
	if( GameHasFlagRun( mnee.SERV_MODE ) and not( mnee.ignore_service_mode )) then return unpack( abort_tbl ) end
	if( GameHasFlagRun( mnee.TOGGLER ) and not( is_vip )) then return unpack( abort_tbl ) end
	if( not( mnee.is_priority_mod( mod_id ))) then return unpack( abort_tbl ) end
	
	local keys_down = mnee.get_keys( inmode )
	local out, is_gone, is_jpad = false, true, false
	if( not( pen.vld( keys_down ))) then return unpack( abort_tbl ) end

	local binding = mnee.get_bindings()
	if( binding ~= nil ) then binding = binding[ mod_id ] end
	if( binding ~= nil ) then binding = binding[ bind_id ] end
	if( not( pen.vld( binding ))) then return unpack( abort_tbl ) end

	local is_weak = binding.is_weak
	local is_dirty = not( binding.is_clean )
	local twin_nmpd = binding.unify_numpad
	local twin_spec = not( binding.split_modifiers )
	
	for i = 1,2 do
		local is_special = false
		local bind = mnee.get_pbd( binding )[ i == 1 and "main" or "alt" ]
		local high_score, score = pen.t.count( bind ), 0
		if( bind["_"] ~= nil ) then
			goto continue
		else is_gone = false end
		
		if( high_score < 1 ) then goto continue end
		if( not( is_dirty ) and high_score ~= #keys_down ) then goto continue end
		
		for i,key in ipairs( keys_down ) do
			if( bind[ key ] ~= nil or bind[ mnee.get_twin_key( key, twin_spec, twin_nmpd )] ~= nil ) then
				if( not( is_special )) then is_special = mnee.SPECIAL_KEYS[ key ] ~= nil end
				score = score + 1
			end
		end
		
		if( score == high_score ) then
			if( is_weak and not( is_special )) then
				for i,key in ipairs( keys_down ) do
					if( mnee.SPECIAL_KEYS[ key ] ~= nil ) then goto continue end
				end
			end

			if( pressed_mode ) then
				local check = mnee.get_disarmer()[ id ] ~= nil
				mnee.add_disarmer( id )
				if( check ) then return unpack( abort_tbl ) end
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

---Same as mnee.mnin_bind but exclusively for axes.
---@param mod_id string
---@param bind_id string
---@param is_alive? boolean Enable to skip deadzone calculations. [DFT: false ]
---@param pressed_mode? boolean Enable to report "1" only once and then wait until the stick is returned to rest position. [DFT: false ]
---@param is_vip? boolean Enable to stop this bind from being disabled by user via global toggle. [DFT: false ]
---@param inmode? string The name of the desired mode from mnee.INMODES list.
---@return number axis_state, boolean is_unbound, boolean is_emulated, boolean is_jpad
function mnee.mnin_axis( mod_id, bind_id, is_alive, pressed_mode, is_vip, inmode )
	local abort_tbl = { 0, false, false, false }
	if( GameHasFlagRun( mnee.SERV_MODE ) and not( mnee.ignore_service_mode )) then return unpack( abort_tbl ) end
	if( GameHasFlagRun( mnee.TOGGLER ) and not( is_vip )) then return unpack( abort_tbl ) end
	if( not( mnee.is_priority_mod( mod_id ))) then return unpack( abort_tbl ) end
	
	local binding = mnee.get_bindings()
	if( binding ~= nil ) then binding = binding[ mod_id ] end
	if( binding ~= nil ) then binding = binding[ bind_id ] end
	if( not( pen.vld( binding ))) then return unpack( abort_tbl ) end

	local out, is_gone, is_buttoned, is_jpad = 0, true, false, false
	for i = 1,2 do
		local bind = mnee.get_pbd( binding )[ i == 1 and "main" or "alt" ]
		local value, memo = mnee.get_axes()[ bind[2]] or 0, {}
		if( bind[2] == "_" ) then
			goto continue
		else is_gone = false end
		
		is_buttoned = bind[3] ~= nil
		if( is_buttoned ) then
			if( mnee.mnin_key( bind[2], pressed_mode, is_vip, inmode )) then
				out = -1
			elseif( mnee.mnin_key( bind[3], pressed_mode, is_vip, inmode )) then
				out = 1
			end
			goto continue
		end
		
		if( not( is_alive )) then
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

---Unifies two mnee.mnin_axis together to form a full stick with circular deadzone.
---@param mod_id string
---@param bind_id string
---@param pressed_mode? boolean Enable to report "1" only once and then wait until the stick is returned to rest position. [DFT: false ]
---@param is_vip? boolean Enable to stop this bind from being disabled by user via global toggle. [DFT: false ]
---@param inmode? string The name of the desired mode from mnee.INMODES list.
---@return table axes_states, boolean is_unbound, table is_emulated, number angle
function mnee.mnin_stick( mod_id, bind_id, pressed_mode, is_vip, inmode )
	local abort_tbl = {{ 0, 0 }, false, { false, false }, 0 }
	if( GameHasFlagRun( mnee.SERV_MODE ) and not( mnee.ignore_service_mode )) then return unpack( abort_tbl ) end
	if( GameHasFlagRun( mnee.TOGGLER ) and not( is_vip )) then return unpack( abort_tbl ) end
	if( not( mnee.is_priority_mod( mod_id ))) then return unpack( abort_tbl ) end
	
	local binding = mnee.get_bindings()
	if( binding ~= nil ) then binding = binding[ mod_id ] end
	if( binding ~= nil ) then binding = binding[ bind_id ] end
	if( not( pen.vld( binding ))) then return unpack( abort_tbl ) end
	
	local acc, norm = 100, ( binding.is_raw or false ) and 100 or 1
	local val_x, gone_x, buttoned_x = mnee.mnin_axis( mod_id, binding.axes[1], true, pressed_mode, is_vip, inmode )
	local val_y, gone_y, buttoned_y = mnee.mnin_axis( mod_id, binding.axes[2], true, pressed_mode, is_vip, inmode )
	local magnitude = mnee.apply_deadzone( math.min( math.sqrt( val_x^2 + val_y^2 ), norm ), binding.jpad_type, binding.deadzone )
	local direction = math.rad( math.floor( math.deg( math.atan2( val_y, val_x )) + 0.5 ))
	val_x, val_y = pen.rounder( magnitude*math.cos( direction ), acc ), pen.rounder( magnitude*math.sin( direction ), acc )
	return { math.min( val_x, norm ), math.min( val_y, norm )}, gone_x or gone_y, { buttoned_x, buttoned_y }, direction
end

---Unified access point for the entirety of mnee input API.
---@param mode mnin_modes
---@param id table ID part of the bind data, key_id for "key" mode and mod_id + bind_id for the rest.
---@param data? MneeMninData
---@return any
function mnee.mnin( mode, id, data )
	local map = {
		key = { mnee.mnin_key, {1}, { "pressed", "vip", "mode" }},
		bind = { mnee.mnin_bind, {1,2}, { "pressed", "vip", "mode" }},
		axis = { mnee.mnin_axis, {1,2}, { "alive", "pressed", "vip", "mode" }},
		stick = { mnee.mnin_stick, {1,2}, { "pressed", "vip", "mode" }},
	}

	data, func = data or {}, map[ mode ]
	id = pen.get_hybrid_table( id )
	
	local inval = {}
	for i,v in ipairs( func[2]) do
		if( id[v] ~= nil ) then table.insert( inval, id[v]) end
	end
	for i,v in ipairs( func[3]) do
		table.insert( inval, data[v] or false )
	end
	return func[1]( unpack( inval ))
end

pen._new_interface = pen.new_interface
pen.new_interface = function( pic_x, pic_y, s_x, s_y, pic_z, data )
	data = data or {}
	data.emulator = data.emulator or function( pic_x, pic_y, pic_z, s_x, s_y, clicked, r_clicked, is_hovered, data )
		if( not( data.focus )) then return clicked, r_clicked, is_hovered end

		local frame_num = GameGetFrameNum()
		local may_focus, fid, is_vip = unpack( data.focus )
		local k = pen.t.loop({ 1, 2, 3, 4 }, function( i )
			if( may_focus ~= true and may_focus ~= i ) then return end
			local state = GlobalsGetValue( pen.GLOBAL_JPAD_FOCUS..i, "" )

			for e = i + 1, 4 do
				if( GlobalsGetValue( pen.GLOBAL_JPAD_FOCUS..e, "" ) == fid ) then return end
			end
			
			if( state == "_" ) then
				local focus_loop = GlobalsGetValue( pen.GLOBAL_JPAD_FOCUS_LOOP..i, "" )
				local target = pen.t.pack( GlobalsGetValue( pen.GLOBAL_JPAD_FOCUS_TARGET..i, "" ))
				if( focus_loop == "" ) then GlobalsSetValue( pen.GLOBAL_JPAD_FOCUS_LOOP..i, fid ) end

				if( focus_loop ~= fid ) then
					local dist = math.sqrt( data.real_x^2 + data.real_y^2 )
					if( is_vip ) then dist = -99999 end
					if( target[2] == nil or dist < target[2] ) then
						GlobalsSetValue( pen.GLOBAL_JPAD_FOCUS_TARGET..i, "|"..fid.."|"..dist.."|" )
					end
				else
					GlobalsSetValue( pen.GLOBAL_JPAD_DOT..i, "" )
					GlobalsSetValue( pen.GLOBAL_JPAD_FOCUS_LOOP..i, "" )
					GlobalsSetValue( pen.GLOBAL_JPAD_FOCUS..i, target[1])
					GlobalsSetValue( pen.GLOBAL_JPAD_FOCUS_TARGET..i, "" )
					GlobalsSetValue( pen.GLOBAL_JPAD_SAFETY..i, frame_num )

					local w, h = pen.get_screen_data()
					pen.c.estimator_memo = pen.c.estimator_memo or {}
					pen.c.estimator_memo[ "jpad_focus_pos_x_"..i ] = 0
					pen.c.estimator_memo[ "jpad_focus_pos_y_"..i ] = 0
					pen.c.estimator_memo[ "jpad_focus_size_x_"..i ] = w
					pen.c.estimator_memo[ "jpad_focus_size_y_"..i ] = h
					GlobalsSetValue( pen.GLOBAL_JPAD_POS..i, "|0|0|" )
					GlobalsSetValue( pen.GLOBAL_JPAD_SIZE..i, pen.t.pack({ w, h }))
				end
			elseif( state ~= fid ) then
				local dot = pen.t.pack( GlobalsGetValue( pen.GLOBAL_JPAD_DOT..i, "" ))
				local is_looping = GlobalsGetValue( pen.GLOBAL_JPAD_TARGET_LOOP..i, "" ) ~= ""
				if( pen.vld( dot ) and is_looping ) then
					local d_x, d_y = pic_x - dot[1], pic_y - dot[2]
					local dist = math.sqrt( d_x^2 + d_y^2 )
					local angle = math.atan2( d_y, d_x )
					
					local quads = {{ -135,-45,2 }, { 45,135,1 }, { -45,45,4 }, { 135,-135,3 }}
					pen.t.loop( quads, function( n, v )
						local extra = quads[ v[3]]
						local is_valid = ( angle >= math.rad( v[1]) and angle <= math.rad( v[2]))
							or ( n == 4 and ( angle >= math.rad( v[1]) or angle <= math.rad( v[2])))
						local is_extra = ( angle >= math.rad( extra[1]) and angle <= math.rad( extra[2]))
							or ( v[3] == 4 and ( angle >= math.rad( extra[1]) or angle <= math.rad( extra[2])))
						local side = pen[ "GLOBAL_JPAD_TARGET_"..({ "U", "D", "R", "L" })[n]]
						local t = pen.t.pack( GlobalsGetValue( side..i, "|_|0|_|0|" ))
						
						local side_id, side_dist, extra_id, extra_dist = unpack( t )
						if( is_valid and ( side_id == "_" or side_dist > dist )) then
							GlobalsSetValue( side..i, pen.t.pack({ fid, dist, extra_id, extra_dist }))
						elseif( is_extra and ( extra_id == "_" or extra_dist < dist )) then
							GlobalsSetValue( side..i, pen.t.pack({ side_id, side_dist, fid, dist }))
						end
					end)
				end
			else
				local go_up = mnee.mnin( "key", i.."gpd_up", { pressed = true })
				local go_down = mnee.mnin( "key", i.."gpd_down", { pressed = true })
				local go_left = mnee.mnin( "key", i.."gpd_left", { pressed = true })
				local go_right = mnee.mnin( "key", i.."gpd_right", { pressed = true })

				local will_swap = go_up or go_down or go_left or go_right
				local may_swap = GlobalsGetValue( pen.GLOBAL_JPAD_TARGET_LOOP..i, "" )
				if( will_swap and may_swap == "" ) then
					pen.c.controller_swap = { go_up, go_down, go_left, go_right }
					GlobalsSetValue( pen.GLOBAL_JPAD_TARGET_LOOP..i, fid )
				end
				
				if( may_swap == fid ) then
					local new_target = "_"
					local dft = pen.t.pack({ "_", 0, "_", 0 })
					if( pen.c.controller_swap[1]) then
						new_target = pen.t.pack( GlobalsGetValue( pen.GLOBAL_JPAD_TARGET_U..i, dft ))
					elseif( pen.c.controller_swap[2]) then
						new_target = pen.t.pack( GlobalsGetValue( pen.GLOBAL_JPAD_TARGET_D..i, dft ))
					elseif( pen.c.controller_swap[3]) then
						new_target = pen.t.pack( GlobalsGetValue( pen.GLOBAL_JPAD_TARGET_L..i, dft ))
					elseif( pen.c.controller_swap[4]) then
						new_target = pen.t.pack( GlobalsGetValue( pen.GLOBAL_JPAD_TARGET_R..i, dft ))
					end

					pen.c.controller_swap = nil
					GlobalsSetValue( pen.GLOBAL_JPAD_TARGET_LOOP..i, "" )
					GlobalsSetValue( pen.GLOBAL_JPAD_TARGET_U..i, dft )
					GlobalsSetValue( pen.GLOBAL_JPAD_TARGET_D..i, dft )
					GlobalsSetValue( pen.GLOBAL_JPAD_TARGET_L..i, dft )
					GlobalsSetValue( pen.GLOBAL_JPAD_TARGET_R..i, dft )

					local t = new_target[ new_target[1] == "_" and 3 or 1 ]
					if( t ~= "_" ) then
						GlobalsSetValue( pen.GLOBAL_JPAD_FOCUS..i, t )
						GlobalsSetValue( pen.GLOBAL_JPAD_MIGRATE..i, t )
						GlobalsSetValue( pen.GLOBAL_JPAD_POS_OLD..i, pen.t.pack({ pic_x, pic_y }))
						GlobalsSetValue( pen.GLOBAL_JPAD_SIZE_OLD..i, pen.t.pack({ s_x, s_y }))
					end
				end

				GlobalsSetValue( pen.GLOBAL_JPAD_DOT..i, pen.t.pack({ data.real_x, data.real_y }))
				return i
			end
		end)

		local is_jpad = false
		if(( k or 0 ) > 0 ) then
			local z = pen.LAYERS.DEBUG - k
			local anim = math.sin( frame_num/15 ) + 1
			local pic = "mods/mnee/files/pics/corner.png"
			if( GlobalsGetValue( pen.GLOBAL_JPAD_MIGRATE..k, "" ) == fid ) then
				GlobalsSetValue( pen.GLOBAL_JPAD_MIGRATE..k, "" )
				local old_pos = pen.t.pack( GlobalsGetValue( pen.GLOBAL_JPAD_POS_OLD..k, "|0|0|" ))
				local old_size = pen.t.pack( GlobalsGetValue( pen.GLOBAL_JPAD_SIZE_OLD..k, "|0|0|" ))
				
				pen.c.estimator_memo = pen.c.estimator_memo or {}
				pen.c.estimator_memo[ "jpad_focus_pos_x_"..k ] = old_pos[1]
				pen.c.estimator_memo[ "jpad_focus_pos_y_"..k ] = old_pos[2]
				pen.c.estimator_memo[ "jpad_focus_size_x_"..k ] = old_size[1]
				pen.c.estimator_memo[ "jpad_focus_size_y_"..k ] = old_size[2]
			end

			local pos = pen.t.pack( GlobalsGetValue( pen.GLOBAL_JPAD_POS..k, "|0|0|" ))
			if( pos[1] ~= pic_x or pos[2] ~= pic_y ) then
				GlobalsSetValue( pen.GLOBAL_JPAD_POS..k, pen.t.pack({
					pen.estimate( "jpad_focus_pos_x_"..k, pic_x, "wgt0.5" ),
					pen.estimate( "jpad_focus_pos_y_"..k, pic_y, "wgt0.5" )}))
			end
			local size = pen.t.pack( GlobalsGetValue( pen.GLOBAL_JPAD_SIZE..k, "|0|0|" ))
			if( size[1] ~= s_x or size[2] ~= s_y ) then
				GlobalsSetValue( pen.GLOBAL_JPAD_SIZE..k, pen.t.pack({
					pen.estimate( "jpad_focus_size_x_"..k, s_x, "wgt0.5" ),
					pen.estimate( "jpad_focus_size_y_"..k, s_y, "wgt0.5" )}))
			end

			pen.new_image( pos[1] - 1, pos[2] - 1, z, pic,
				{ color = pen.PALETTE[ "P"..k.."_A" ], s_x = 0.5, s_y = 0.5, alpha = anim })
			pen.new_image( pos[1] - 1, pos[2] - 1, z + 0.1, pic,
				{ color = pen.PALETTE[ "P"..k.."_B" ], s_x = 0.5, s_y = 0.5, alpha = 0.75 })
			pen.new_image( pos[1] + size[1] + 1, pos[2] - 1, z, pic,
				{ color = pen.PALETTE[ "P"..k.."_A" ], s_x = -0.5, s_y = 0.5, alpha = 1 - anim })
			pen.new_image( pos[1] + size[1] + 1, pos[2] - 1, z + 0.1, pic,
				{ color = pen.PALETTE[ "P"..k.."_B" ], s_x = -0.5, s_y = 0.5, alpha = 0.75 })
			pen.new_image( pos[1] - 1, pos[2] + size[2] + 1, z, pic,
				{ color = pen.PALETTE[ "P"..k.."_A" ], s_x = 0.5, s_y = -0.5, alpha = 1 - anim })
			pen.new_image( pos[1] - 1, pos[2] + size[2] + 1, z + 0.1, pic,
				{ color = pen.PALETTE[ "P"..k.."_B" ], s_x = 0.5, s_y = -0.5, alpha = 0.75 })
			pen.new_image( pos[1] + size[1] + 1, pos[2] + size[2] + 1, z, pic,
				{ color = pen.PALETTE[ "P"..k.."_A" ], s_x = -0.5, s_y = -0.5, alpha = anim })
			pen.new_image( pos[1] + size[1] + 1, pos[2] + size[2] + 1, z + 0.1, pic,
				{ color = pen.PALETTE[ "P"..k.."_B" ], s_x = -0.5, s_y = -0.5, alpha = 0.75 })
			
			if( mnee.mnin( "key", k.."gpd_r3" )) then
				if( GlobalsGetValue( pen.GLOBAL_JPAD_DISARMER..k, "0" ) == "0" ) then
					GlobalsSetValue( pen.GLOBAL_JPAD_DISARMER..k, "1" )
					GlobalsSetValue( pen.GLOBAL_JPAD_FOCUS..k, "" )
				end
			else GlobalsSetValue( pen.GLOBAL_JPAD_DISARMER..k, "0" ) end
			GlobalsSetValue( pen.GLOBAL_JPAD_SAFETY..k, frame_num )

			--left stick to free focus (draws a screen-spanning cross, focuses on the closest one) 
			--left stick with gpd_l1 for moving text cursor

			--scrollers (autoscroll to keep focused visible)

			--mouse pos (add easy mouse pos overrides and match with the center of focused widget)
			--tips (allow adjusting mouse pos offset with right stick, resets on focus switch)
			
			is_hovered, is_jpad = true, k
			clicked = mnee.mnin( "key", k.."gpd_a", { pressed = true })
			r_clicked = mnee.mnin( "key", k.."gpd_y", { pressed = true })
			
			local disarmer = mnee.get_disarmer()
			local is_pressed = disarmer[ "key"..k.."gpd_a" ] ~= nil or disarmer[ "key"..k.."gpd_y" ] ~= nil
			local shadow = is_pressed and 0.25 or 0.05
			pen.new_pixel( pos[1], pos[2], z, pen.PALETTE[ "P"..k.."_A" ], size[1], size[2], 0.1 )
			pen.new_pixel( pos[1], pos[2], z + 0.1, pen.PALETTE[ "P"..k.."_B" ], size[1], size[2], shadow )
		end
		
		return clicked, r_clicked, is_hovered, is_jpad
	end

	return pen._new_interface( pic_x, pic_y, s_x, s_y, pic_z, data )
end

pen._new_dragger = pen.new_dragger
pen.new_dragger = function( did, pic_x, pic_y, s_x, s_y, pic_z, data )
	data = data or {}
	data.virtualizer = data.virtualizer or function( pic_x, pic_y, state, clicked, jpad )
		if( state <= 0 and ( jpad or 0 ) > 0 ) then
			pen.c.controller_dragging = pen.c.controller_dragging or {}
			pen.c.controller_dragging[ jpad ] = pen.c.controller_dragging[ jpad ] or { pic_x, pic_y }

			local is_going = pen.c.controller_dragging[ jpad ].is_going
			if( mnee.mnin( "key", jpad.."gpd_a" )) then
				state = clicked and 1 or 2
				local axes = mnee.get_axes()
				local d_x, d_y = axes[ jpad.."gpd_axis_lh" ], axes[ jpad.."gpd_axis_lv" ]
				pen.c.controller_dragging[ jpad ][1] = pen.c.controller_dragging[ jpad ][1] + 5*d_x
				pen.c.controller_dragging[ jpad ][2] = pen.c.controller_dragging[ jpad ][2] + 5*d_y
				pen.c.controller_dragging[ jpad ].is_going = true
				pic_x = pen.c.controller_dragging[ jpad ][1]
				pic_y = pen.c.controller_dragging[ jpad ][2]
			else
				state = is_going and -1 or 0
				pen.c.controller_dragging[ jpad ] = nil
			end
		end

		return pic_x, pic_y, state, clicked
	end

	return pen._new_dragger( did, pic_x, pic_y, s_x, s_y, pic_z, data )
end

-----------------------------------------------------		[KEYBOARD]		-----------------------------------------------------

function mnee.get_special_keys()
	--gpd_r1 for shift, gpd_r2 for ctrl, gpd_l2 for alt (put all special key getting into a separate func)
end

---Static full keyboard input with shifting support and special keys.
---@param kb_func fun( is_shifted:boolean, is_ctrled:boolean, is_alted:boolean ): input:string
---@return string|number|nil
function mnee.get_keyboard_input( kb_func )
	local lists = dofile_once( "mods/mnee/lists.lua" )

	local is_shifted = not( pen.vld( kb_func )) and (
		InputIsKeyDown( 225 --[[Left Shift]]) or InputIsKeyDown( 229 --[[Right Shift]]))
	local is_ctrled = InputIsKeyJustDown( 224 --[[Left Ctrl]]) or InputIsKeyJustDown( 228 --[[Right Ctrl]])
	local is_alted = InputIsKeyJustDown( 226 --[[Left Alt]]) or InputIsKeyJustDown( 230 --[[Right Alt]])

	local input = ""
	for i = 4,56 do
		if( InputIsKeyJustDown( i )) then
			input = lists[1][i]
			if( is_shifted ) then
				input = mnee.get_shifted_key( input )
			elseif( i > 39 and i < 45 ) then
				if( i == 40 ) then
					input = 3
				elseif( i == 41 ) then
					input = 0
				elseif( i == 42 ) then
					input = 2
				elseif( i == 43 ) then
					input = 4
				elseif( i == 44 ) then
					input = " "
				end
			end
			break
		end
	end
	for i = 1,4 do
		if( InputIsKeyJustDown( 83 + i )) then
			input = string.sub( lists[1][ 83 + i ], -1 ); break
		end
	end
	for i = 1,10 do
		if( InputIsKeyJustDown( 88 + i )) then
			input = string.sub( tostring( i ), -1 ); break
		end
	end
	if( InputIsKeyJustDown( 99 )) then input = "." end

	if( pen.vld( kb_func )) then
		is_shifted = InputIsKeyJustDown( 225 --[[Left Shift]])
			or InputIsKeyJustDown( 229 --[[Right Shift]])
		input = pen.uncutter( function( cut_x, cut_y, cut_w, cut_h )
			return kb_func( input, is_shifted, is_ctrled, is_alted )
		end) or input
	end
	if(( input or "" ) ~= "" ) then return input end
end

function pen.new_input( iid, pic_x, pic_y, pic_z, size_x, size_y, text, data )
	if( not( pen.vld( iid ))) then return text, false end

	data = data or {}
	data.uid = iid
	data.is_compact = true
	data.edging = data.edging or 2
	data.nil_val = data.nil_val or " "
	data.is_live = data.is_live or false
	data.no_wrap = data.no_wrap or false

	local state = GlobalsGetValue( pen.GLOBAL_INPUT_STATE, "" )
	local is_active = state == iid

	local clicked, r_clicked, is_hovered = false, false, false
	if( not( pen.vld( state ) or GameHasFlagRun( mnee.SERV_MODE )) or is_active ) then
		clicked, r_clicked, is_hovered = pen.new_interface( pic_x, pic_y, size_x, size_y, pic_z )
	end

	local do_lmb, do_rmb = false, false
	local is_updated, is_confirmed = false, false
	data.lmb_event = data.lmb_event or function( pic_x, pic_y, pic_z, pic, d )
		pen.c.input_data, do_lmb = {}, true
		GlobalsSetValue( pen.GLOBAL_INPUT_STATE, is_active and "_" or d.uid )
		return pic_x, pic_y, pic_z, pic, d
	end
	if( data.lmb_event ~= nil and clicked ) then
		pic_x, pic_y, pic_z, pic, data = data.lmb_event( pic_x, pic_y, pic_z, pic, data ) end
	data.rmb_event = data.rmb_event or function( pic_x, pic_y, pic_z, pic, d )
		is_confirmed = true
		return pic_x, pic_y, pic_z, pic, d
	end
	if( data.rmb_event ~= nil and r_clicked and is_active ) then
		pic_x, pic_y, pic_z, pic, data = data.rmb_event( pic_x, pic_y, pic_z, pic, data ) end
	data.hov_event = data.hov_event or function( pic_x, pic_y, pic_z, pic, d )
		--default tip should have the text in title (only if text has no newlines) and actions in desc

		-- if( pen.vld( d.tip )) then
		-- 	pen.uncutter( function( cut_x, cut_y, cut_w, cut_h )
		-- 		return mnee.new_tooltip( d.tip, { is_active = true, min_width = d.min_width })
		-- 	end)
		-- end
		return pic_x, pic_y, pic_z, pic, d
	end
	if( data.hov_event ~= nil and is_hovered ) then
		pic_x, pic_y, pic_z, pic, data = data.hov_event( pic_x, pic_y, pic_z, pic, data )
	elseif( data.idle_event ~= nil ) then
		pic_x, pic_y, pic_z, pic, data = data.idle_event( pic_x, pic_y, pic_z, pic, data )
	end
	
	pen.c.input_data = pen.c.input_data or {}
	pen.c.input_data.safety = pen.c.input_data.safety or 0
	pen.c.input_data.pos = pen.c.input_data.pos or { l = 1, c = 0 }
	pen.c.input_data.buffer = pen.c.input_data.buffer or ""
	pen.c.input_data.hdata = pen.c.input_data.hdata or {}
	
	pen.c.input_data.drift = pen.c.input_data.drift or {}
	pen.c.input_data.last_chr = pen.c.input_data.last_chr or 0
	pen.c.input_data.last_lin = -math.abs( pen.c.input_data.last_lin or 1 )
	pen.c.input_data.last_last_lin = pen.c.input_data.last_last_lin or 1

	local t = text
	if( is_active ) then t = pen.c.input_data.buffer or text end
	if( clicked and not( is_active )) then pen.c.input_data.buffer = text end
	
	if( is_active ) then
		is_updated = data.is_live
		GlobalsSetValue( pen.GLOBAL_INPUT_FRAME, GameGetFrameNum() + 1 )

		local will_highlight = InputIsKeyDown( 225 --[[Left Shift]])
		will_highlight = will_highlight or InputIsKeyDown( 229 --[[Right Shift]])
		local is_moving = InputIsKeyJustDown( 81 --[[Down]]) or InputIsKeyJustDown( 82 --[[Up]])
		is_moving = is_moving or InputIsKeyJustDown( 79 --[[Right]]) or InputIsKeyJustDown( 80 --[[Left]])
		if( not( will_highlight ) and is_moving ) then pen.c.input_data.hdata = {} end

		local a, b = "", ""
		local input = mnee.get_keyboard_input( data.kb_func ) or ""
		if( input ~= "" or ( will_highlight and ( is_moving or pen.c.input_data.hdata[2] == nil ))) then
			local c = pen.c.input_data.index or 0
			local s = pen.c.input_data.space_num or 0
			local score, i, is_edge = s - 1, -1, pen.c.input_data.pos.c == 0
			pen.w2c( pen.c.input_data.buffer, function( char_id, letter_id, start_id, end_id )
				if( char_id ~= 10 ) then score = score + 1 end
				if( char_id == 32 ) then score = score - 1 end

				if( score >= c ) then
					i = start_id
					if( not( is_edge )) then
						i = i - ( string.sub( pen.c.input_data.buffer, i - 1, i - 1 ) == "\n" and 1 or 0 )
					end
					if( not( pen.c.input_data.is_space )) then
						i = i - ( string.sub( pen.c.input_data.buffer, i - 1, i - 1 ) == " " and 1 or 0 )
					end
					
					return true
				end
			end)
			
			if( i ~= -1 ) then
				local da, db = 0, 0
				-- local drift = pen.c.input_data.hdata[1] or 0
				-- if( drift < 0 ) then da = drift else db = drift end
				-- if( drift ~= 0 ) then da, db = da - 1, db + 1 end
				a = string.sub( pen.c.input_data.buffer, 1, i - 1 + da )
				b = string.sub( pen.c.input_data.buffer, i + db, -1 )

				if( will_highlight ) then
					pen.c.input_data.hdata[2] = pen.c.input_data.hdata[2] or i
					if( is_moving ) then pen.c.input_data.hdata[1] = i - pen.c.input_data.hdata[2] end
				else pen.c.input_data.hdata = {} end
			else a = pen.c.input_data.buffer end
		end
		
		pen.c.typing_test.a = a == "" and ( pen.c.typing_test.a or "" ) or a
		pen.c.typing_test.b = b == "" and ( pen.c.typing_test.b or "" ) or b
		pen.debug_print( string.gsub( pen.c.typing_test.a.."|"..pen.c.typing_test.b, "\n", "[N]" ), 200, 75, true )
		pen.debug_print( pen.c.input_data.hdata[1], 50, 50, true )

		if( type( input ) == "number" ) then
			local kind = math.abs( input )
			local is_normal = input > 0
			local count = 1

			if( kind == 2 ) then
				local is_unicode = false
				pen.w2c( a, function( char_id, letter_id, start_id, end_id )
					if( char_id > 127 ) then is_unicode = true; return true end
				end)
				
				if( not( is_normal ) and not( is_unicode )) then
					local pos1, pos2 = string.find( a, "^%w-$" )
					if( pos1 == nil ) then pos1, pos2 = string.find( a, "[%s%p]%w-$" ) end
					count = ( pos2 or 0 ) - ( pos1 or 0 )
					if( count > 0 ) then
						local got_nl = string.sub( a, pos1, pos1 ) == "\n"
						a = string.sub( a, 1, pos1 - 1 )
						pen.c.input_data.drift.l = true

						if( got_nl ) then
							pen.c.input_data.pos.c = 1
							pen.c.input_data.pos.l = pen.c.input_data.pos.l - 1
						else pen.c.input_data.pos.c = pen.c.input_data.pos.c - count end
					end
					pen.c.input_data.buffer = a..b
				elseif( a ~= "" ) then
					pen.c.input_data.drift.l = true
					if( string.sub( a, -1, -1 ) == "\n" ) then
						pen.c.input_data.pos.c = 1
						pen.c.input_data.pos.l = pen.c.input_data.pos.l - 1
					end
					
					local nuke_pos = 0
					if( is_unicode ) then
						pen.w2c( a, function( char_id, letter_id, start_id, end_id ) nuke_pos = start_id end)
						nuke_pos = nuke_pos - string.len( a )
					end
					pen.c.input_data.buffer = string.sub( a, 1, nuke_pos - 2 )..b
				end
			elseif( kind == 3 ) then
				if( data.is_live ) then
					is_normal = not( is_normal ) end
				if( not( is_normal ) and not( data.is_flat )) then
					if( not( string.sub( a, -1, -1 ) == "\n" or string.sub( b, 1, 1 ) == "\n" )) then
						pen.c.input_data.buffer = string.gsub( a.."\n"..b, " -\n", "\n" )
						pen.c.input_data.pos.c, pen.c.input_data.pos.l = 0, pen.c.input_data.pos.l + 1
					end
				else is_confirmed = true end
			-- elseif( kind == 4 ) then --figure out real tab support
			-- 	if( is_normal ) then
			-- 		pen.c.input_data.pos.c = pen.c.input_data.pos.c + 4
			-- 		a, count = string.gsub( a, "(\n).-$", "\n    " )
			-- 		if( count == 0 ) then a = "    "..a end
			-- 	else
			-- 		print(tostring(string.match( a, "\n( -).-$" )))
			-- 	end
			-- 	pen.c.input_data.buffer = a..b
			end
		elseif( input ~= "" ) then
			local is_tab = input == " " and ( a == "" or
				string.sub( a, -1, -1 ) == " " or string.sub( b, 1, 1 ) == " " )
			if( not( is_tab )) then
				pen.c.input_data.buffer = a..input..b
				pen.c.input_data.pos.c = pen.c.input_data.pos.c + 1
			end
		else is_updated = false end
	end
	
	if( is_confirmed ) then
		is_updated, do_rmb = true, true
		GlobalsSetValue( pen.GLOBAL_INPUT_STATE, "_" )
	end

	data.vis_func = data.vis_func or function( pic_x, pic_y, pic_z, size_x, size_y, is_active, do_lmb, do_rmb, do_hov, t, data )
		if( do_lmb ) then
			pen.play_sound( pen.TUNES.VNL[ is_active and "RESET" or "CLICK" ])
		elseif( do_rmb ) then pen.play_sound( pen.TUNES.VNL.BUY ) end
		
		pen.new_tooltip( "", {
			tid = data.uid, is_active = true, is_special = is_active,
			dims = { size_x, size_y }, pic_z = pic_z + 0.1, pos = { pic_x - data.edging, pic_y - data.edging }})
		pen.new_scroller( data.uid.."_scroller", pic_x, pic_y, pic_z, size_x, size_y, function( scroll_pos )
			if( not( data.no_wrap )) then data.dims = { size_x, -1 } end
			
			if( is_active ) then
				t = pen.c.input_data.buffer
				data.no_culling, data.fully_featured = true, true
				pen.new_text( scroll_pos[2], scroll_pos[1], pic_z - 1, "{>cursor>{"..( t or "" ).."}<cursor<}", data )
			elseif( do_hov ) then data.color = pen.PALETTE.VNL.YELLOW end
			
			data.no_culling, data.fully_featured = false, false
			local dims, new_line = pen.new_text( scroll_pos[2], scroll_pos[1], pic_z, t, data )
			return { dims[2] + ( string.sub( t, -1, -1 ) == "\n" and new_line or 0 ) + 1, dims[1]}
		end, data )
	end
	data.vis_func( pic_x, pic_y, pic_z, size_x, size_y, is_active, do_lmb, do_rmb, is_hovered, t, data )

	--finalize highlighting
	--holding to repeat input (arrows and backspace)
	--ctrl + a/c/v/x through mnee.KB_CLIPBOARD (with buffer of up to 25 last copies in a setting)
	
	if( is_updated ) then
		text = pen.c.input_data.buffer end
	return text, is_updated
end

function mnee.new_input( iid, pic_x, pic_y, pic_z, size_x, size_y, text, data )
	data = data or {}
	data.kb_func = function( input, is_shifted, is_ctrled, is_alted )
		local old_style = GlobalsGetValue( pen.GLOBAL_KEYBOARD_STYLE, "" )
		if( old_style ~= "mnee" ) then
			--reset anim timer
			GlobalsSetValue( pen.GLOBAL_KEYBOARD_STYLE, "mnee" )
		end
		
		--CN: https://en.wikipedia.org/wiki/Chinese_input_method
		--JP: https://en.wikipedia.org/wiki/Japanese_language_and_computers
		--KO: https://en.wikipedia.org/wiki/Korean_language_and_computers

		local board = dofile_once( pen.FILE_KEYBOARD )
		local lists = dofile_once( "mods/mnee/lists.lua" )
		local meta, offs, nums = lists[7], lists[8], lists[9]
		
		--ctrl + backspace instead of shift
		--bg anim is same as tips, keys appear in cascading wave from top left corner
		--anim for layout swap
		--clipboard
		
		local is_alt = InputIsKeyDown( 226 --[[Left Alt]])
			or InputIsKeyDown( 230 --[[Right Alt]]) or mnee.G.kb_alt
		local is_shift = InputIsKeyDown( 225 --[[Left Shift]])
			or InputIsKeyDown( 229 --[[Right Shift]]) or mnee.G.kb_shift
		is_ctrled = ( InputIsKeyJustDown( 226 --[[Left Alt]]) or InputIsKeyJustDown( 230 --[[Right Alt]]))
			and ( InputIsKeyDown( 224 --[[Left Ctrl]]) or InputIsKeyDown( 228 --[[Right Ctrl]]))
		local is_ctrl = mnee.G.kb_ctrl
		
		local is_return = false
		if( not( data.is_live )) then
			is_return = not( is_shift ) and input == 3
			if( is_shift and input == 3 ) then input = -3 end
		else is_return = is_shift and input == 3 end

		local kind = 1
		if( is_alt ) then kind = kind + 2 end
		if( is_ctrl ) then kind = kind + 4 end
		if( is_shift ) then kind = kind + 1 end
		local layout = pen.setting_get( "mnee.KB_LAYOUT" )

		local sfx = "keys/key_6_"
		local new_x, new_y, state = 0, 0, 0
		local clicked, r_clicked, is_hovered = false, false, false
		local pic_x, pic_y = unpack( pen.t.pack( pen.setting_get( "mnee.KB_POS" )))
		
		local no_input = input == ""
		local pic_z = pen.LAYERS.DEBUG + 1000
		for i,key in pairs( board[ layout ]) do
			local np = ( i == "-" and input == "+" ) or ( i == "8" and input == "*" )
			local k = key[ kind ] or key[ kind - 2 ] or key[ kind - 4 ] or key[ kind - 6 ]
			clicked = mnee.new_button( pic_x + offs[i][1] - 1, pic_y + offs[i][2] - 1, pic_z, ( k or key[1])[1], {
				auid = table.concat({ "mnee_kb_l", layout, "_k", i, "_s", kind }), _clicked = ( input == i ) or np })
			if( clicked ) then pen.play_sound({ "mods/mnee/files/mnee.bank", sfx.."generic" }) end
			if( clicked and not( np )) then input = ( k or key[1])[2] end
		end
		
		sfx = { "mods/mnee/files/mnee.bank", sfx.."special" }
		clicked = mnee.new_button( pic_x + 2, pic_y + 13, pic_z,
			"mods/mnee/files/pics/keyboard/key_ctrl_"..( is_ctrl and "B" or "A" )..".xml",
			{ auid = "mnee_kb_ctrl", _clicked = is_ctrled })
		if( clicked ) then pen.play_sound( sfx ); mnee.G.kb_ctrl = not( mnee.G.kb_ctrl ) end
		clicked = mnee.new_button( pic_x + 2, pic_y + 24, pic_z,
			"mods/mnee/files/pics/keyboard/key_alt_"..( is_alt and "B" or "A" )..".xml", { auid = "mnee_kb_alt" })
		if( clicked or is_alted ) then pen.play_sound( sfx ) end
		if( clicked ) then mnee.G.kb_alt = not( mnee.G.kb_alt ) end
		clicked = mnee.new_button( pic_x + 13, pic_y + 24, pic_z,
			"mods/mnee/files/pics/keyboard/key_shift_"..( is_shift and "B" or "A" )..".xml", { auid = "mnee_kb_shift" })
		if( clicked or is_shifted ) then pen.play_sound( sfx ) end
		if( clicked ) then mnee.G.kb_shift = not( mnee.G.kb_shift ) end
		
		clicked, r_clicked, is_hovered = mnee.new_button(
			pic_x + 13, pic_y + 35, pic_z, "mods/mnee/files/pics/keyboard/key_space.xml",
			{ auid = "mnee_kb_space", _clicked = ( input == " " ), _r_clicked = ( input == 3 or input == -3 )})
		mnee.new_tooltip( GameTextGet( "$mnee_rmb_space" ), { is_active = is_hovered, pic_z = pic_z - 10 })
		if( clicked or r_clicked ) then pen.play_sound( sfx ) end
		if( r_clicked and no_input ) then input = data.is_live and 3 or -3 end
		if( clicked ) then input = " " end

		clicked, r_clicked = mnee.new_button(
			pic_x + 145, pic_y + 13, pic_z, "mods/mnee/files/pics/keyboard/key_backspace.xml",
			{ auid = "mnee_kb_backspace", _clicked = ( input == 2 ), _r_clicked = ( input == 2 and is_shift )})
		if( clicked or r_clicked ) then pen.play_sound( sfx ) end
		if( r_clicked ) then input = -2 elseif( clicked ) then input = 2 end

		mnee.ignore_service_mode = true
		clicked, r_clicked, is_hovered = mnee.new_button( pic_x + 145, pic_y + 24, pic_z,
			"mods/mnee/files/pics/keyboard/key_layout_A.xml", { auid = "mnee_kb_layout",
			_clicked = mnee.mnin( "bind", { "mnee", "layout" }, { pressed = true, vip = true }),
			_r_clicked = mnee.mnin( "bind", { "mnee", "clipboard" }, { pressed = true, vip = true })})
		mnee.new_tooltip({ GameTextGet( "$mnee_this_layout", meta[ layout ][""].name ),
			GameTextGet( "$mnee_rmb_layout" )}, { is_active = is_hovered, pic_z = pic_z - 10 })
		if( clicked ) then pen.play_sound( pen.TUNES.PRSP.SWITCH );
			pen.setting_set( "mnee.KB_LAYOUT", layout >= #board and 1 or layout + 1 ) end
		if( clicked or r_clicked ) then input = "" end
		mnee.ignore_service_mode = nil
		
		new_x, new_y, state, _, r_clicked, is_hovered = pen.new_dragger( "mnee_kb_dragger_l", pic_x + 1, pic_y + 35, 10, 10, pic_z )
		if( new_x - 1 ~= pic_x or new_y - 35 ~= pic_y ) then pen.setting_set( "mnee.KB_POS", pen.t.pack({ new_x - 1, new_y - 35 })) end

		mnee.new_tooltip( GameTextGet( "$mnee_rmb_dragger" ), {
			is_active = ( state == 0 and is_hovered ), pic_z = pic_z - 10 })
		pen.new_image( pic_x + 1, pic_y + 35, pic_z + 1.5,
			"mods/mnee/files/pics/keyboard/dragger_left_"..( is_hovered and "B" or "A" )..".xml" )
		if( r_clicked or is_return ) then input = data.is_live and -3 or 3 end
		
		new_x, new_y, state, _, r_clicked, is_hovered = pen.new_dragger( "mnee_kb_dragger_r", pic_x + 145, pic_y + 35, 10, 10, pic_z )
		if( new_x - 145 ~= pic_x or new_y - 35 ~= pic_y ) then pen.setting_set( "mnee.KB_POS", pen.t.pack({ new_x - 145, new_y - 35 })) end
		
		mnee.new_tooltip( GameTextGet( "$mnee_rmb_dragger" ), {
			is_active = ( state == 0 and is_hovered ), pic_z = pic_z - 10 })
		pen.new_image( pic_x + 145, pic_y + 35, pic_z + 1.5,
			"mods/mnee/files/pics/keyboard/dragger_right_"..( is_hovered and "B" or "A" )..".xml" )
		if( r_clicked or is_return ) then input = data.is_live and -3 or 3 end
		
		pen.new_image( pic_x, pic_y, pic_z + 1, "mods/mnee/files/pics/keyboard/board.xml", { can_click = true })
		
		if( input ~= "" and type( input ) == "string" ) then
			if( data.force_numerical ) then --add in-line calculation (use pen.w2c to assemble the formula)
				if( nums[ input ] == nil ) then return "" end
			elseif( data.ban_unicode ) then
				if( string.byte( input ) > 127 ) then return "" end
			end
		end

		return input
	end
	data.cursor_color = pen.PALETTE.PRSP.RED
	data.vis_func = function( pic_x, pic_y, pic_z, size_x, size_y, is_active, do_lmb, do_rmb, do_hov, t, data )
		if( do_lmb ) then
			pen.play_sound( pen.TUNES.PRSP[ is_active and "DROP" or "PICK" ])
		elseif( do_rmb ) then pen.play_sound( pen.TUNES.PRSP.CONFIRM ) end
		
		mnee.new_tooltip( "", {
			tid = data.uid, is_active = true, is_special = is_active,
			dims = { size_x, size_y }, pic_z = pic_z + 0.1, pos = { pic_x - data.edging, pic_y }})
		if( do_hov ) then pen.new_pixel( pic_x - data.edging - 1, pic_y - 1,
			pic_z + 0.15, pen.PALETTE.PRSP[ is_active and "BLUE" or "RED" ], size_x + 6, size_y + 6 ) end
		mnee.new_scroller( data.uid.."_scroller", pic_x, pic_y + 1, pic_z, size_x, size_y + 2, function( scroll_pos )
			if( not( data.no_wrap )) then
				data.dims = { size_x, -1 } end
			if( is_active ) then
				t = pen.c.input_data.buffer
				data.no_culling, data.fully_featured = true, true
				pen.new_text( scroll_pos[2], scroll_pos[1] - 1, pic_z - 1, "{>cursor>{"..( t or "" ).."}<cursor<}", data )
			end

			data.no_culling, data.fully_featured = false, false
			data.color = pen.PALETTE.PRSP[ is_active and "BLUE" or ( do_hov and "RED" or "BLUE" )]
			local dims, new_line = pen.new_text( scroll_pos[2], scroll_pos[1] - 1, pic_z, t, data )
			return { dims[2] + ( string.sub( t, -1, -1 ) == "\n" and new_line or 0 ) + 1, dims[1]}
		end, data )
	end

	return pen.try( pen.new_input, {
		iid, pic_x, pic_y, pic_z, size_x, size_y, text, data
	}, function( log, _, pic_x, pic_y )
		pen.new_shadowed_text( pic_x, pic_y, pen.LAYERS.DEBUG, log, {
			color = pen.PALETTE.PRSP.RED, color_shadow = pen.PALETTE.PRSP.BLUE, dims = { size_x - 1, -1 }})
	end)
end

-----------------------------------------------------		[GLOBALS]		-----------------------------------------------------

mnee.AMAP_MEMO = "mnee_mapping_memo"
mnee.INITER = "MNEE_IS_GOING"
mnee.TOGGLER = "MNEE_DISABLED"
mnee.RETOGGLER = "MNEE_REDO"
mnee.UPDATER = "MNEE_RELOAD"
mnee.JPAD_UPDATE = "MNEE_JPAD_UPDATE"
mnee.SERV_MODE = "MNEE_HOLD_UP"
mnee.PRIO_MODE = "MNEE_PRIORITY_MODE"
mnee.NO_REMINDER = "MNEE_NO_REMINDER"

mnee.G_DOWN = "MNEE_DOWN"
mnee.G_AXES = "MNEE_AXES"
mnee.G_TRIGGERS = "MNEE_TRIGGERS"
mnee.G_EXE = "MNEE_EXE"
mnee.G_JPADS = "MNEE_JPADS"
mnee.G_DISARMER = "MNEE_DISARMER"
mnee.G_AXES_MEMO = "MNEE_AXES_MEMO"

mnee.SPECIAL_KEYS = pen.t.unarray({
	"left_shift", "right_shift",
	"left_ctrl", "right_ctrl",
	"left_alt", "right_alt",
})
mnee.BANNED_KEYS = pen.t.unarray({
	"left_windows", "right_windows",
})

pen.TUNES.PRSP = {
	CLICK = {"mods/mnee/files/mnee.bank","button_generic"},
	CLICK_ALT = {"mods/mnee/files/mnee.bank","button_special"},
	SELECT = {"mods/mnee/files/mnee.bank","select"},
	CONFIRM = {"mods/mnee/files/mnee.bank","confirm"},
	SWITCH = {"mods/mnee/files/mnee.bank","switch_page"},
	SWITCH_ALT = {"mods/mnee/files/mnee.bank","switch_dimension"},
	DELETE = {"mods/mnee/files/mnee.bank","delete"},
	RESET = {"mods/mnee/files/mnee.bank","clear_all"},
	ERROR = {"mods/mnee/files/mnee.bank","error"},

	PICK = {"mods/mnee/files/mnee.bank","capture"},
	DROP = {"mods/mnee/files/mnee.bank","uncapture"},
	OPEN = {"mods/mnee/files/mnee.bank","open_window"},
	CLOSE = {"mods/mnee/files/mnee.bank","close_window"},
	FOLD = {"mods/mnee/files/mnee.bank","minimize"},
	UNFOLD = {"mods/mnee/files/mnee.bank","unminimize"},
	BOOT = {"mods/mnee/files/mnee.bank","open_main"},
	BOOT_LONG = {"mods/mnee/files/mnee.bank","bootup"},
}

mnee.INMODES = {
	guied = function( ctrl_body, active )
		mnee.G.mb_memo = mnee.G.mb_memo or {}
		local gotta_go = mnee.G.mb_memo[1] or
			mnee.G.mb_memo[2] or mnee.G.mb_memo[4] or mnee.G.mb_memo[5]
		if( not( gotta_go or pen.vld( active ))) then mnee.G.mb_memo = nil; return active end
		local ctrl_comp = EntityGetFirstComponentIncludingDisabled( ctrl_body, "ControlsComponent" )
		
		local vals = {
			{ "mButtonDownLeftClick", "mouse_left", "mouse_left_gui" },
			{ "mButtonDownRightClick", "mouse_right", "mouse_right_gui" },
			{}, --scrolling is fucked because of the inherent delay of this implementation
			{ "mButtonDownChangeItemL", "mouse_wheel_up", "mouse_wheel_up_gui" },
			{ "mButtonDownChangeItemR", "mouse_wheel_down", "mouse_wheel_down_gui" },
		}
		
		for _,i in ipairs({ 1, 2, 4, 5 }) do
			local state = InputIsMouseButtonDown( i )
			if( mnee.G.mb_memo[i] and not( ComponentGetValue2( ctrl_comp, vals[i][1]))) then
				active = string.gsub( active, vals[i][2], vals[i][3])
			elseif( state and not( mnee.G.mb_memo[i])) then
				active = string.gsub( active, vals[i][2], vals[i][3].."_" ) end
			mnee.G.mb_memo[i] = state
		end

		local vals_jpad = {
			["gpd_y"] = "gpd_y_gui",
			["gpd_x"] = "gpd_x_gui",
			["gpd_a"] = "gpd_a_gui",
			["gpd_b"] = "gpd_b_gui",

			["gpd_r1"] = "gpd_r1_gui",
			["gpd_r2"] = "gpd_r2_gui",
			["gpd_r3"] = "gpd_r3_gui",
			["gpd_l1"] = "gpd_l1_gui",
			["gpd_l2"] = "gpd_l2_gui",
			["gpd_l3"] = "gpd_l3_gui",

			["gpd_up"] = "gpd_up_gui",
			["gpd_down"] = "gpd_down_gui",
			["gpd_left"] = "gpd_left_gui",
			["gpd_right"] = "gpd_right_gui",

			["gpd_select"] = "gpd_select_gui",
			["gpd_start"] = "gpd_start_gui",

			["gpd_btn_lh_%+"] = "gpd_btn_lh_+_gui",
			["gpd_btn_lh_%-"] = "gpd_btn_lh_-_gui",
			["gpd_btn_lv_%+"] = "gpd_btn_lv_+_gui",
			["gpd_btn_lv_%-"] = "gpd_btn_lv_-_gui",
			["gpd_btn_rh_%+"] = "gpd_btn_rh_+_gui",
			["gpd_btn_rh_%-"] = "gpd_btn_rh_-_gui",
			["gpd_btn_rv_%+"] = "gpd_btn_rv_+_gui",
			["gpd_btn_rv_%-"] = "gpd_btn_rv_-_gui",
		}

		pen.t.loop({ 1, 2, 3, 4 }, function( i )
			if( GlobalsGetValue( pen.GLOBAL_JPAD_FOCUS..i, "" ) == "" ) then return end
			for old,new in pairs( vals_jpad ) do active = string.gsub( active, i..old, i..new ) end
		end)

		return active
	end,

	-- guied_instant = function( ctrl_body, active )
	-- 	local ctrl_comp = EntityGetFirstComponentIncludingDisabled( ctrl_body, "ControlsComponent" )
		
	-- 	local vals = {
	-- 		{ "mButtonDownLeftClick", "mouse_left", "mouse_left_gui" },
	-- 		{ "mButtonDownRightClick", "mouse_right", "mouse_right_gui" },
	-- 		{ "mButtonDownChangeItemL", "mouse_wheel_up", "mouse_wheel_up_gui" },
	-- 		{ "mButtonDownChangeItemR", "mouse_wheel_down", "mouse_wheel_down_gui" },
	-- 	}
		
	-- 	for i,v in ipairs( vals ) do
	-- 		local is_going = ComponentGetValue2( ctrl_comp, v[1])
	-- 		if( not( is_going )) then active = string.gsub( active, v[2], v[3]) end
	-- 	end

	-- 	return active
	-- end,
}

mnee.TRIGGER_INMODES = {
	guied = function( ctrl_body, state )
		local vals = {
			["gpd_l2!.-!"] = "gpd_l2!0!",
			["gpd_r2!.-!"] = "gpd_r2!0!",
		}

		pen.t.loop({ 1, 2, 3, 4 }, function( i )
			if( GlobalsGetValue( pen.GLOBAL_JPAD_FOCUS..i, "" ) == "" ) then return end
			for old,new in pairs( vals ) do state = string.gsub( state, i..old, i..new ) end
		end)

		return state
	end,
}

mnee.AXIS_INMODES = {
	guied = function( ctrl_body, state )
		local vals = {
			["gpd_axis_lh!.-!"] = "gpd_axis_lh!0!",
			["gpd_axis_lv!.-!"] = "gpd_axis_lv!0!",
			["gpd_axis_rh!.-!"] = "gpd_axis_rh!0!",
			["gpd_axis_rv!.-!"] = "gpd_axis_rv!0!",
		}

		pen.t.loop({ 1, 2, 3, 4 }, function( i )
			if( GlobalsGetValue( pen.GLOBAL_JPAD_FOCUS..i, "" ) == "" ) then return end
			for old,new in pairs( vals ) do state = string.gsub( state, i..old, i..new ) end
		end)

		return state
	end,
}

-----------------------------------------------------		[LEGACY]		-----------------------------------------------------

---Use mnee.mnin_key instead.
---@deprecated
function is_key_down( name, dirty_mode, pressed_mode, is_vip, key_mode )
	return mnee.mnin_key( name, pressed_mode, is_vip, key_mode )
end
---Use mnee.mnin_key instead.
---@deprecated
function get_key_pressed( name, dirty_mode, is_vip )
	return is_key_down( name, dirty_mode, true, is_vip )
end
---Use mnee.mnin_key instead.
---@deprecated
function get_key_vip( name )
	return get_key_pressed( name, true, true )
end

---Use mnee.mnin_bind instead.
---@deprecated
function is_binding_down( mod_id, name, dirty_mode, pressed_mode, is_vip, loose_mode, key_mode )
	return mnee.mnin_bind( mod_id, name, pressed_mode, is_vip, key_mode )
end
---Use mnee.mnin_bind instead.
---@deprecated
function get_binding_pressed( mod_id, name, is_vip, dirty_mode, loose_mode )
	return is_binding_down( mod_id, name, dirty_mode, true, is_vip, loose_mode )
end
---Use mnee.mnin_bind instead.
---@deprecated
function get_binding_vip( mod_id, name )
	return get_binding_pressed( mod_id, name, true, true, true )
end

---Use mnee.mnin_axis instead.
---@deprecated
function get_axis_state( mod_id, name, dirty_mode, pressed_mode, is_vip, key_mode )
	return mnee.mnin_axis( mod_id, name, false, pressed_mode, is_vip, key_mode )
end
---Use mnee.mnin_axis instead.
---@deprecated
function get_axis_pressed( mod_id, name, dirty_mode, is_vip )
	return get_axis_state( mod_id, name, dirty_mode, true, is_vip )
end
---Use mnee.mnin_axis instead.
---@deprecated
function get_axis_vip( mod_id, name )
	return get_axis_pressed( mod_id, name, true, true )
end

-------------------------------------------------------		[LUALS]		-------------------------------------------------------

---@alias deadzone_type
---| "BUTTON"
---| "MOTION"
---| "AIM"
---| "EXTRA"

---@alias key_type
---| "main"
---| "alt"

---@alias mnin_modes
---| "key" data = { pressed, vip, mode }
---| "bind" data = { dirty, pressed, vip, strict, mode }
---| "axis" data = { alive, pressed, vip, mode }
---| "stick" data = { pressed, vip, mode }

---@class MneeAutoaimData
---@field setting setting_id [DFT: "mnee.AUTOAIM" ]<br> The ID of the setting to pull assist strength from.
---@field pic path [DFT: "mods/mnee/files/pics/autoaim.png" ]<br> An image that is overlayed over the target to indicate the locked-on state.
---@field do_lining boolean [DFT: false ]<br> Set to true to draw an estimated tragectory arc.
---@field tag_tbl table [DFT: {"homing_target"} ]<br> The table of targeted tags.

---@class MneePagerData : PenmanPagerData
---@field auid string [OBLIGATORY]<br> Unique animation ID.
---@field compact_mode boolean [DFT: false ]<br> Set to true to make the pager take less space horizontally.
---@field profile_mode boolean [DFT: false ]<br> Page number will be displayed as a letter if set to true.

---@class MneeMninData
---@field pressed boolean [DFT: false ] Enable to report "true" only once and then wait until the key is reset.
---@field vip boolean [DFT: false ] Enable to stop this bind from being disabled by user via global toggle.
---@field mode string The name of the desired mode from mnee.INMODES list.
---@field dirty boolean [DFT: false ] Controls key layer separation, enable to allow conflicts between "ctrl+m" and "m". BIND only.
---@field strict boolean [DFT: false ] Controls combination purity, enable to stop conflicts between "shift+ctrl+e" and "ctrl+e". BIND only.
---@field alive boolean [DFT: false ] Enable to skip deadzone calculations. AXIS only.
dofile_once( "data/scripts/lib/utilities.lua" )

pen = pen or {}

--https://github.com/LuaLS/lua-language-server/wiki/Annotations

--new liner
--allow fancy text-encoded per-letter functions
--test chinese

--make sure all rating functions are accurate
--interpolation lib
--lists of every single vanilla thing (maybe ask nathan for modfile checking thing to get true lists of every entity)
--autoappended shader lib

--update dialogsystem
--reorder and move all the gui stuff to the very bottom
--cleanup, make sure all the funcs reference the right stuff, variable naming consistency
--make sure that all returned id values are 0 and not nil
--actually test all the stuff

--remove old penman from index
--transition mrshll to penman
--add sfxes (separate banks for prospero, hermes, trigger) + pics
--try putting some of the stuff inside internal lua global tables
--add api doc to mnee + make mnee main propero mod (p2k must pull all the sounds and such from it)

--[MATH]
function pen.b2n( a )
	a = a or false
	return a and 1 or 0
end

function pen.n2b( a )
	a = a or 0
	return a > 0
end

function pen.vld( v, is_ecs )
	if( v == nil ) then
		return false
	end

	local out = true
	local t = type( v )
	if( t == "number" ) then
		out = v == v and v ~= math.inf
		if( out and is_ecs ) then
			out = v > 0
		end
	elseif( t == "string" ) then
		out = v ~= pen.DIV_1 and v ~= "" and v ~= " "
	elseif( t == "table" ) then
		out = pen.get_table_count( v, true ) > 0
	end

	return out
end

function pen.random_bool( var )
	SetRandomSeed( GameGetFrameNum(), var )
	return Random( 1, 2 ) == 1
end

function pen.random_sign( var )
	return pen.random_bool( var ) and 1 or -1
end

function pen.get_sign( a )
	return a < 0 and -1 or 1
end

function pen.float_compare( a, b, eps )
	eps = eps or 0.001
	return math.abs( a - b ) < eps
end

function pen.limiter( value, limit, max_mode )
	max_mode = max_mode or false
	limit = math.abs( limit )
	
	if(( max_mode and math.abs( value ) < limit ) or ( not( max_mode ) and math.abs( value ) > limit )) then
		return pen.get_sign( value )*limit
	end
	
	return value
end

function pen.binsearch( tbl, value )
	local low = 1
	local high = #tbl
		
	while( high >= low ) do
		local middle = math.floor(( low + high )/2 + 0.5 )
		if( tbl[middle] < value ) then
			low = middle + 1
		elseif( tbl[middle] > value ) then
			high = middle - 1
		elseif( tbl[middle] == value ) then
			return middle
		end
	end
	
	return nil
end

function pen.get_angular_delta( a, b, get_max )
	get_max = get_max or false

	local pi, pi4 = math.rad( 90 ), math.rad( 360 )
	local d360 = a - b
	local d180 = ( a + pi )%pi4 - ( b + pi )%pi4
	if( get_max ) then
		return ( math.abs( d360 ) > math.abs( d180 ) and d360 or d180 )
	else
		return ( math.abs( d360 ) < math.abs( d180 ) and d360 or d180 )
	end
end

function pen.angle_reset( angle )
	return math.atan2( math.sin( angle ), math.cos( angle ))
end

function pen.rotate_offset( x, y, angle )
	return x*math.cos( angle ) - y*math.sin( angle ), x*math.sin( angle ) + y*math.cos( angle )
end

function pen.rounder( num, k )
	k = k or 1000
	if( k > 0 ) then
		return math.floor( k*num + 0.5 )/k
	else
		return math.ceil( k*num - 0.5 )/k
	end
end

--make this a proper anim lib
-- function magic_trig( value, goal )
-- 	local a = 2*goal/math.pi
-- 	return math.sin( value/a )
-- end

-- function magic_trig_clean( value, goal )
-- 	return magic_trig( value - 1, goal - 1 )
-- end

-- function magic_euler( value, goal )
-- 	return math.log(( math.exp(1) - 1 )*value/goal + 1 )
-- end

-- function magic_exp( value, goal, base )
-- 	base = base or math.exp(1)
	
-- 	local drift = base^( -goal )
-- 	return ( base^( value - goal ) - drift )*( drift + 1 )
-- end

---Returns both GUI grid size and window size (the latter one is hardcoded to 720p for now).
---@return number w, number h, number real_w, number real_h
function pen.get_screen_data()
	local gui = GuiCreate()
	GuiStartFrame( gui )

	local w, h = GuiGetScreenDimensions( gui )
	-- GuiOptionsAddForNextWidget( gui, 51 ) --IsExtraDraggable
	-- GuiOptionsAddForNextWidget( gui, 6 ) --NoPositionTween
	-- GuiOptionsAddForNextWidget( gui, 4 ) --ClickCancelsDoubleClick
	-- GuiOptionsAddForNextWidget( gui, 21 ) --DrawNoHoverAnimation
	-- GuiOptionsAddForNextWidget( gui, 47 ) --NoSound
	-- GuiZSetForNextWidget( gui, 1 )
	-- GuiIdPush( gui, 1 )
	-- GuiImageButton( gui, 1, w, h, "", "data/ui_gfx/empty.png" )
	-- local _,_,_,_,_,_,_,real_w,real_h = GuiGetPreviousWidgetInfo( gui )
	local real_w, real_h = 1280, 720 -- thanks Horscht

	GuiDestroy( gui )

	return w, h, real_w, real_h
end

---Returns delta in GUI units between in-world and on-screen pointer position.
---@param w? number
---@param h? number
---@param real_w? number
---@param real_h? number
---@return number delta_x, number delta_y
function pen.get_camera_shake( w, h, real_w, real_h, k )
	if( w == nil ) then
		w, h, real_w, real_h = pen.get_screen_data()
	end
	k = k or 1

	local function purify( a, max )
		return math.min( math.max( pen.rounder( a, -2 ), 0 ), max )
	end

	local x, y = DEBUG_GetMouseWorld()
	local world_x, world_y, zoom = pen.world2gui( x, y, false, true )
	world_x, world_y = purify( world_x, w ) + 1, purify( world_y, h )
	
	local screen_x, screen_y = InputGetMousePosOnScreen()
	screen_x, screen_y = purify( w*screen_x/real_w, w ), purify( h*screen_y/real_h, h )
	if( screen_x < 1 ) then
		screen_x = 0
		world_x = 0
	elseif( screen_x <= 214 ) then
		screen_x = screen_x - 1
	elseif( screen_x < 427 ) then
		screen_x = screen_x - 0.5
	end
	if( screen_y >= 296 ) then
		screen_y = screen_y - 0.5
	elseif( screen_y <= 147 ) then
		screen_y = screen_y + 0.5
	end
	
	local delta_x, delta_y = screen_x - world_x, screen_y - world_y
	if( math.abs( delta_x ) < k and math.abs( delta_y ) < k ) then
		return 0, 0
	end
	return delta_x, delta_y
end

---Calculates on-screen position from in-world coordinates.
---@param x number
---@param y number
---@param is_raw? boolean
---@param no_shake? boolean
---@return number pic_x, number pic_y, table screen_scale
function pen.world2gui( x, y, is_raw, no_shake ) --thanks to ImmortalDamned for the fix
	is_raw = is_raw or false
	no_shake = no_shake or is_raw
	
	local w, h, real_w, real_h = pen.get_screen_data()
	local view_x = MagicNumbersGetValue( "VIRTUAL_RESOLUTION_X" ) + MagicNumbersGetValue( "VIRTUAL_RESOLUTION_OFFSET_X" )
	local view_y = MagicNumbersGetValue( "VIRTUAL_RESOLUTION_Y" ) + MagicNumbersGetValue( "VIRTUAL_RESOLUTION_OFFSET_Y" )
	local massive_balls_x, massive_balls_y = w/view_x, h/view_y
	
	if( not( is_raw )) then
		local cam_x, cam_y = GameGetCameraPos()
		x, y = ( x - ( cam_x - view_x/2 )), ( y - ( cam_y - view_y/2 ))
	end
	if( not( no_shake )) then
		local shake_x, shake_y = pen.get_camera_shake( w, h, real_w, real_h, view_x/421 )
		x, y = x + shake_x, y + shake_y
	end
	x, y = massive_balls_x*x, massive_balls_y*y
	
	return x, y, {massive_balls_x,massive_balls_y}
end

---Returns on-screen pointer position.
---@return number pointer_x, number pointer_y
function pen.get_mouse_pos()
	local w,h,screen_w,screen_h = pen.get_screen_data()
	local m_x, m_y = InputGetMousePosOnScreen()
	return w*m_x/screen_w, h*m_y/screen_h
end

--[TECHNICAL]
function pen.catch( f, input, fallback )
	local out = { pcall(f, unpack( input or {}))}
	if( not( out[1])) then
		if( not( pen.silent_catch )) then
			print( out[2])
		end
		if( pen.vld( fallback )) then
			return unpack( fallback )
		end
	else
		table.remove( out, 1 )
		return unpack( out )
	end
end

function pen.chrono( f, input, storage_comp, name )
	local check = GameGetRealWorldTimeSinceStarted()*1000
	local out = { f( unpack( input or {}))}
	check = GameGetRealWorldTimeSinceStarted()*1000 - check

	if( pen.vld( storage_comp, true )) then
		pen.magic_comp( storage_comp, { value_string = function( old_val )
			return old_val..name..pen.DIV_1..check..pen.DIV_1
		end})
	else
		print( check.."ms" )
	end

	return unpack( out )
end

function pen.get_hybrid_function( func, input )
	if( not( pen.vld( func ))) then
		return
	end
	
	if( type( func ) == "function" ) then
		return pen.catch( func, input )
	else
		return func
	end
end

function pen.is_table_weird( tbl )
	return pen.get_table_count( tbl, true ) > 0 and #tbl == 0
end

function pen.get_hybrid_table( table, allow_weird )
	if( not( pen.vld( table ))) then
		return {}
	end
	
	allow_weird = allow_weird or false
	if( type( table ) == "table" and ( allow_weird or not( pen.is_table_weird( table )))) then
		return table
	else
		return {table}
	end
end

function pen.magic_copy( orig, copies )
    copies = copies or {}
    local orig_type = type( orig )
    local copy = {}
    if( orig_type == "table" ) then
        if( copies[orig]) then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[ pen.magic_copy( orig_key, copies )] = pen.magic_copy( orig_value, copies )
            end
            setmetatable( copy, pen.magic_copy( getmetatable( orig ), copies ))
        end
    else
        copy = orig
    end
    return copy
end

function pen.magic_sorter( tbl, func )
    local out_tbl = {}
    for n in pairs( tbl ) do
        table.insert( out_tbl, n )
    end
    table.sort( out_tbl, func )
	
    local i = 0
    local iter = function ()
        i = i + 1
        if( out_tbl[i] == nil ) then
            return nil
        else
            return out_tbl[i], tbl[out_tbl[i]]
        end
    end
    return iter
end

function pen.magic_fletcher( str, is_huge )
	is_huge = is_huge or false
	
	local a, b, c = 0, 0, ( is_huge and 65535 or 4294967295 )
	for i = 1,#str do
		a = ( a + string.byte( str, i ))%c
		b = ( a + b )%c
	end
	return ( is_huge and tostring( b*c + a ) or ( b*c + a ))
end

function pen.seed_gen( values )
	local metaseed = "msd"..GameGetRealWorldTimeSinceStarted().."."
	if( #( values or {}) > 0 ) then
		for i,value in ipairs( values ) do
			if( type( value ) ~= "boolean" ) then
				metaseed = metaseed..tostring( value )
			end
		end
	end
	
	math.randomseed( pen.magic_fletcher( metaseed ))
	math.random();math.random();math.random()
	return math.random( 0, 2000000000 )
end

function pen.seeded_random( event_id, mutator, a, b, bidirectional, seed_container )
	bidirectional = bidirectional or false
	seed_container = seed_container or "19_abiding.WHITE_SEED"
	
	local seed = tonumber( pen.magic_fletcher( ModSettingGetNextValue( seed_container )..tostring( pen.magic_fletcher( event_id..tostring( mutator )))))
	math.randomseed( seed )
	math.random();math.random();math.random()
	return bidirectional and ( math.random( a, b*2 ) - b ) or math.random( a, b )
end

function pen.generic_random( a, b, macro_drift, bidirectional )
	bidirectional = bidirectional or false
	
	if( macro_drift == nil ) then
		macro_drift = GetUpdatedEntityID() or 0
		if( macro_drift > 0 ) then
			local drft_a, drft_b = EntityGetTransform( macro_drift )
			macro_drift = macro_drift + tonumber( macro_drift ) + ( drft_a*1000 + drft_b )
		else
			macro_drift = 1
		end
	elseif( type( macro_drift ) == "table" ) then
		macro_drift = macro_drift[1]*1000 + macro_drift[2]
	end
	macro_drift = math.floor( macro_drift + 0.5 )
	
	local tm = { GameGetDateAndTimeUTC() }
	SetRandomSeed( math.random( GameGetFrameNum(), macro_drift ), (((( tm[2]*30 + tm[3] )*24 + tm[4] )*60 + tm[5] )*60 + tm[6] )%macro_drift )
	Random( 1, 5 ); Random( 1, 5 ); Random( 1, 5 )
	return bidirectional and ( Random( a, b*2 ) - b ) or Random( a, b )
end

function pen.gui_killer( gui )
	if( gui ~= nil ) then
		GuiDestroy( gui )
	end
end

--[UTILS]
function pen.uint2color( color )
	return { bit.band( color, 0xff ), bit.band( bit.rshift( color, 8 ), 0xff ), bit.band( bit.rshift( color, 16 ), 0xff )}
end

function pen.magic_rbg( c, to_rbg, mode )
	--HSV: https://github.com/iskolbin/lhsx/blob/master/hsx.lua
	--OKLAB: https://bottosson.github.io/posts/oklab/#converting-from-linear-srgb-to-oklab

	local function gam2lin( c )
		return c >= 0.04045 and math.pow(( c + 0.055 )/1.055, 2.4 ) or c/12.92
	end
	local function lin2gam( c )
		return c >= 0.0031308 and 1.055*math.pow( c, 1/2.4 ) - 0.055 or 12.92*c
	end
	local function rgb2hsv( r, g, b )
		local M, m = math.max( r, g, b ), math.min( r, g, b )
		local C = M - m
		local K = 1/( 6*C )
		local h = 0
		if( C ~= 0 ) then
			if( M == r ) then
				h = ( K*( g - b ))%1
			elseif( M == g ) then
				h = K*( b - r ) + 1/3
			else
				h = K*( r - g ) + 2/3
			end
		end
		return h, M == 0 and 0 or C/M, M
	end
	local function hsv2rgb( h, s, v )
		local C = v*s
		local m = v - C
		local r, g, b = m, m, m
		if( h == h ) then
			local h_ = ( h%1 )*6
			local X = C*( 1 - math.abs( h_%2 - 1 ))
			C, X = C + m, X + m
			if( h_ < 1 ) then
				r, g, b = C, X, m
			elseif( h_ < 2 ) then
				r, g, b = X, C, m
			elseif( h_ < 3 ) then
				r, g, b = m, C, X
			elseif( h_ < 4 ) then
				r, g, b = m, X, C
			elseif( h_ < 5 ) then
				r, g, b = X, m, C
			else
				r, g, b = C, m, X
			end
		end
		return r, g, b
	end
	local function rgb2okl( r, g, b )
		r,g,b = gam2lin( r/255 ), gam2lin( g/255 ), gam2lin( b/255 )
		
		local l = 0.4122214708*r + 0.5363325363*g + 0.0514459929*b
		local m = 0.2119034982*r + 0.6806995451*g + 0.1073969566*b
		local s = 0.0883024619*r + 0.2817188376*g + 0.6299787005*b
	
		local l_ = math.pow( l, 1/3 )
		local m_ = math.pow( m, 1/3 )
		local s_ = math.pow( s, 1/3 )
	
		return
			0.2104542553*l_ + 0.7936177850*m_ - 0.0040720468*s_,
			1.9779984951*l_ - 2.4285922050*m_ + 0.4505937099*s_,
			0.0259040371*l_ + 0.7827717662*m_ - 0.8086757660*s_
	end
	local function okl2rgb( l, a, b ) 
		local l_ = l + 0.3963377774*a + 0.2158037573*b
		local m_ = l - 0.1055613458*a - 0.0638541728*b
		local s_ = l - 0.0894841775*a - 1.2914855480*b
	
		local l = l_*l_*l_
		local m = m_*m_*m_
		local s = s_*s_*s_
		
		return
			255*lin2gam( 4.0767416621*l - 3.3077115913*m + 0.2309699292*s ),
			255*lin2gam( -1.2684380046*l + 2.6097574011*m - 0.3413193965*s ),
			255*lin2gam( -0.0041960863*l - 0.7034186147*m + 1.7076147010*s )
	end

	c = pen.get_hybrid_table( c ); c[2] = c[2] or c[1]; c[3] = c[3] or c[1]
	local modes = {
		gamma = {gam2lin,lin2gam},
		hsv = {rgb2hsv,hsv2rgb},
		oklab = {rgb2okl,okl2rgb},
	}
	local out = { modes[mode][ 1 + pen.b2n( to_rbg )]( unpack( c ))}
	if( c[4] ~= nil ) then table.insert( out, c[4]) end
	return out
end

function pen.debug_dot( x, y, frames )
	GameCreateSpriteForXFrames( "data/ui_gfx/debug_marker.png", x, y, true, 0, 0, frames or 1, true )
end

function pen.drop_em_frames( count )
	local frame_time = count
	
	local current_time = GameGetRealWorldTimeSinceStarted()*1000
	local prev_time = current_time
	while(( current_time - prev_time ) < frame_time ) do
		current_time = GameGetRealWorldTimeSinceStarted()*1000
	end
end

function pen.table_init( amount, value )
	local tbl = {}
	local temp = value
	for i = 1,amount do
		if( type( value ) == "table" ) then
			temp = {}
		end
		tbl[i] = temp
	end
	
	return tbl
end

function pen.add_table( a, b )
	if( pen.vld( b )) then
		table.sort( b )
		if( pen.vld( a )) then
			for m,new in ipairs( b ) do 
				if( binsearch( a, new ) == nil ) then
					table.insert( a, new )
				end
			end
			
			table.sort( a )
		else
			a = b
		end
	end
	
	return a
end

function pen.add_unique( lst, name )
	for i,item in ipairs( lst ) do
		if( item == name ) then
			return
		end
	end
	
	table.insert( lst, name )
end

function pen.add_dynamic_fields( tbl, fields ) --thanks to ImmortalDamned
    setmetatable( tbl, {
        __index = function( _, k )
            local f = fields[k]
            return f and f()
        end
    })
    return tbl
end

function pen.table2list( tbl, dft )
	local new_tbl = {}
	for i,v in ipairs( tbl ) do
		new_tbl[v] = dft or i
	end
	return new_tbl
end

function pen.get_table_count( tbl, just_checking )
	tbl = tbl or 0
	if( type( tbl ) ~= "table" ) then
		return 0
	end
	
	local table_count = 0
	for i,element in pairs( tbl ) do
		table_count = table_count + 1
		if( just_checking ) then
			break
		end
	end
	return table_count
end

function pen.get_table_depth( tbl, d )
	tbl = tbl or 0
	d = d or 0

	if( type( tbl ) == "table" ) then
		for n,v in pairs( tbl ) do
			d = pen.get_table_depth( v, d + 1 )
			break
		end
	end

	return d
end

function pen.get_most_often( tbl )
	local count = {}
	for n,v in pairs( tbl ) do
		count[v] = ( count[v] or 0 ) + 1
	end
	local best = {0,0}
	for n,v in pairs( count ) do
		if( best[2] < v ) then
			best = {n,v}
		end
	end
	return unpack( best )
end

function pen.from_tbl_with_id( tbl, id, will_nuke, custom_key )
	if( not( pen.vld( tbl ))) then
		return
	end

	local out, tbl_id = {}, nil
	local key = custom_key or "id"
	local is_multi = type( id ) == "table"
	id = pen.table2list( pen.get_hybrid_table( id ))
	for i,v in ipairs( tbl ) do
		local check = pen.get_hybrid_table( v )
		if( id[ check[key] or check[1] or 0 ]) then
			tbl_id = i
			table.insert( out, ( will_nuke or false ) and tbl_id or v )
			if( not( is_multi )) then break end
		end
	end
	if( will_nuke ) then
		for i,v in ipairs( out ) do
			table.remove( tbl, v )
		end
	else
		local default = type( tbl[1]) == "table" and {} or 0
		return is_multi and out or ( out[1] or default ), tbl_id
	end
end

function pen.print_table( tbl )
	print( pen.magic_parse( tbl ))
end

function pen.closest_getter( x, y, stuff, check_sight, limits, extra_check )
	check_sight = check_sight or false
	limits = limits or { 0, 0, }
	if( not( pen.vld( stuff ))) then
		return 0
	end
	
	local actual_thing = 0
	local min_dist = -1
	for i,raw_thing in ipairs( stuff ) do
		local thing = type( raw_thing ) == "table" and raw_thing[1] or raw_thing

		local t_x, t_y = EntityGetTransform( thing )
		if( not( check_sight ) or not( RaytracePlatforms( x, y, t_x, t_y ))) then
			local d_x, d_y = math.abs( t_x - x ), math.abs( t_y - y )
			if(( d_x < limits[1] or limits[1] == 0 ) and ( d_y < limits[2] or limits[2] == 0 )) then
				local dist = math.sqrt( d_x^2 + d_y^2 )
				if( min_dist == -1 or dist < min_dist ) then
					if( extra_check == nil or extra_check( raw_thing )) then
						min_dist = dist
						actual_thing = raw_thing
					end
				end
			end
		end
	end
	
	return actual_thing
end

function pen.get_child_num( inv_id, item_id )
	local children = EntityGetAllChildren( inv_id )
	if( pen.vld( children )) then
		for i,child in ipairs( children ) do
			if( child == item_id ) then
				return i-1
			end
		end
	end

	return 0
end

function pen.child_play( entity_id, action, sorter )
	local children = EntityGetAllChildren( entity_id )
	if( pen.vld( children )) then
		if( sorter ~= nil ) then
			table.sort( children, sorter )
		end

		for i,child in ipairs( children ) do
			local value = action( entity_id, child, i ) or false
			if( value ) then
				return value
			end
		end
	end
end

function pen.child_play_full( dude_id, func, params )
	local ignore = func( dude_id, params ) or false
	return pen.child_play( dude_id, function( parent, child )
		if( ignore ) then
			return func( child, params )
		else
			return pen.child_play_full( child, func, params )
		end
	end)
end

function pen.get_matter( matters, id )
	local total
	local mttrs = { 0, 0 }
	if( pen.vld( matters )) then
		if( id == nil ) then
			mttrs = {}

			for i,mttr in ipairs( matters ) do
				if( mttr > 0 ) then
					table.insert( mttrs, {i-1,mttr})
					total = total + mttr
				end
			end 
			
			table.sort( mttrs, function( a, b )
				return a[2] > b[2]
			end)
		else
			for i,matter in ipairs( matters ) do
				if( id ~= nil and id == i - 1 ) then
					return { id, matter }
				elseif( matter > mttrs[2] ) then
					mttrs[1] = i - 1
					mttrs[2] = matter
				end
			end
		end
	end
	return mttrs, total
end

function pen.get_killable_stuff( c_x, c_y, r )
	local stuff = {}
	return pen.add_table( pen.add_table( stuff, EntityGetInRadiusWithTag( c_x, c_y, r, "hittable" ) or {} ), EntityGetInRadiusWithTag( c_x, c_y, r, "mortal" ) or {} )
end

function pen.ptrn( id )
	return "([^"..( type( id ) == "number" and pen[ "DIV_"..( id or 1 )] or tostring( id )).."]+)"
end

function pen.ctrn( str, marker, string_indexed )
	local t = {}

	for word in string.gmatch( str, pen.ptrn( marker or "%s" )) do
		if( string_indexed ) then
			t[ word ] = 1
		else
			table.insert( t, pen.t2t( word, true ))
		end
	end
	
	return t
end

function pen.t2t( str, is_post )
	if( is_post ) then
		str = string.gsub( str, "\t", "    " )
		str = string.gsub( str, "^%s+", "" )
		str = string.gsub( str, "%s+$", "" )
	else
		str = string.gsub( str, "\r\n", "\n" )
	end
	return str
end

function pen.t2l( str, string_indexed )
	return pen.ctrn( pen.t2t( str ), "\n", string_indexed )
end

function pen.t2w( str )
	return pen.ctrn( str )
end

function pen.get_translated_line( text )
	local out = ""
	local markers = pen.t2w( pen.get_hybrid_function( text ))
	for i,mark in ipairs( markers ) do
		out = out..( out == "" and out or " " )..GameTextGetTranslatedOrNot( mark )
	end
	return out
end

function pen.magic_append( to_file, from_file )
	local marker = "%-%-<{> MAGICAL APPEND MARKER <}>%-%-"
	local line_wrecker = "\n\n\n"
	
	local a = ModTextFileGetContent( to_file )
	local b = ModTextFileGetContent( from_file )
	ModTextFileSetContent( to_file, string.gsub( a, marker, b..line_wrecker..marker ))
end

function pen.magic_herder( new_file, default, overrides )
	local herd = {}
	local old_file = "data/genome_relations.csv"
	overrides = pen.table2list( overrides or {})

	local raw_herd = pen.t2l( ModTextFileGetContent( old_file ))
	local header = pen.ctrn( raw_herd[1], "," )
	for i = 2,#raw_herd do
		local line = pen.ctrn( raw_herd[i], "," )
		local name = line[1]
		
		herd[name] = {}
		for e = 2,#line do
			herd[name][header[e]] = tonumber( line[e])
		end
	end
	if( new_file == nil ) then
		return herd
	end

	raw_herd = pen.t2l( ModTextFileGetContent( new_file ))
	local new_header = pen.ctrn( raw_herd[1], "," )
	for i = 2,#raw_herd do
		local line = pen.ctrn( raw_herd[i], "," )
		local name = line[1]
		if( herd[name] == nil ) then
			overrides[name] = 0
		end

		herd[name] = herd[name] or {}
		for e = 2,#line do
			if(( overrides[name] ~= nil or overrides[new_header[e]] ~= nil ) and line[e] ~= "_" ) then
				herd[name][new_header[e]] = tonumber( line[e])
			end
		end
	end
	
	local function herd_sorter( tbl )
		return pen.magic_sorter( tbl, function( a,b )
			local _,ida = pen.from_tbl_with_id( header, a )
			local _,idb = pen.from_tbl_with_id( header, b )

			local out = false
			if( ida == nil and idb ~= nil ) then
				out = false
			elseif( ida ~= nil and idb == nil ) then
				out = true
			elseif( ida ~= nil and idb ~= nil ) then
				out = ida < idb
			else
				out = a < b
			end
			
			return out
		end)
	end

	new_header, new_file = "HERD", ""
	for h1 in herd_sorter( herd ) do
		local new_line = h1
		for h2 in herd_sorter( herd ) do
			herd[h1] = herd[h1] or {}
			if( herd[h1][h2] == nil ) then
				herd[h1][h2] = default( herd, h1, h2 )
			end
			new_line = new_line..","..herd[h1][h2]
		end
		new_header = new_header..","..h1
		new_file = new_file..new_line.."\n"
	end
	if( ModTextFileSetContent ) then
		ModTextFileSetContent( old_file, new_header.."\n"..new_file )
	end

	return herd
end

function pen.set_translations( path )
	local file, main = ModTextFileGetContent( path ), "data/translations/common.csv"
	ModTextFileSetContent( main, ModTextFileGetContent( main )..string.gsub( file, "^[^\n]*\n", "" ))
end

--add new liner (mnee will have to be rewritten)
function pen.liner( text, length, height, length_k, clean_mode, forced_reverse )
	local formated = {}
	if( pen.vld( text )) then
		local length_counter = 0
		if( height ~= nil ) then
			length_k = length_k or 6
			length = math.floor( length/length_k + 0.5 )
			height = math.floor( height/9 )
			local height_counter = 1
			
			local full_text = pen.DIV_0..text..pen.DIV_0
			for line in string.gmatch( full_text, pen.ptrn( 0 )) do
				local rest = ""
				local buffer = ""
				local dont_touch = false
				
				length_counter = 0
				text = ""
				
				local words = pen.t2w( line )
				for i,word in ipairs( words ) do
					buffer = word
					local w_length = string.len( buffer ) + 1
					length_counter = length_counter + w_length
					dont_touch = false
					
					if( length_counter > length ) then
						if( w_length >= length ) then
							rest = string.sub( buffer, length - ( length_counter - w_length - 1 ), w_length )
							text = text..buffer.." "
						else
							length_counter = w_length
						end
						table.insert( formated, tostring( string.gsub( string.sub( text, 1, length ), "@ ", "" )))
						height_counter = height_counter + 1
						text = ""
						while( rest ~= "" ) do
							w_length = string.len( rest ) + 1
							length_counter = w_length
							buffer = rest
							if( length_counter > length ) then
								rest = string.sub( rest, length + 1, w_length )
								table.insert( formated, tostring( string.sub( buffer, 1, length )))
								dont_touch = true
								height_counter = height_counter + 1
							else
								rest = ""
								length_counter = w_length
							end
							
							if( height_counter > height ) then
								break
							end
						end
					end
					
					if( height_counter > height ) then
						break
					end
					
					text = text..buffer.." "
				end
				
				if( not( dont_touch )) then
					table.insert( formated, tostring( string.sub( text, 1, length )))
				end
			end
		else
			local gui = GuiCreate()
			GuiStartFrame( gui )
			
			local starter = math.floor( math.abs( length )/7 + 0.5 )
			local total_length = string.len( text )
			if( starter < total_length ) then
				if(( length > 0 ) and forced_reverse == nil ) then
					length = math.abs( length )
					formated = string.sub( text, 1, starter )
					for i = starter + 1,total_length do
						formated = formated..string.sub( text, i, i )
						length_counter = GuiGetTextDimensions( gui, formated, 1, 2 )
						if( length_counter > length ) then
							formated = string.sub( formated, 1, string.len( formated ) - 1 )
							break
						end
					end
				else
					length = math.abs( length )
					starter = total_length - starter
					formated = string.sub( text, starter, total_length )
					while starter > 0 do
						starter = starter - 1
						formated = string.sub( text, starter, starter )..formated
						length_counter = GuiGetTextDimensions( gui, formated, 1, 2 )
						if( length_counter > length ) then
							formated = string.sub( formated, 2, string.len( formated ))
							break
						end
					end
				end
			else
				formated = text
			end
			
			GuiDestroy( gui )
		end
	else
		if( clean_mode == nil ) then
			table.insert( formated, "[NIL]" )
		else
			formated = ""
		end
	end
	
	return formated
end

function pen.magic_parse( data, separators )
	if( not( pen.vld( data ))) then
		return
	end
	separators = separators or { pen.DIV_1, pen.DIV_2, pen.DIV_3, pen.DIV_4 }

	local function XD_packer( data, separators, i )
		data = data or 0
		i = ( i or 0 ) + 1
		local separator = separators[i]
		if( separator == nil or type( data ) ~= "table" ) then
			return tostring( data )
		end

		local data_raw, is_weird = separator, pen.is_table_weird( data )
		for name,value in pairs( data ) do
			if( is_weird ) then
				data_raw = data_raw..name..separator
			end
			data_raw = data_raw..XD_packer( value, separators, i )..separator
		end
		return data_raw
	end
	
	local function XD_extractor( data_raw, separators, i )
		data_raw = data_raw or 0
		if( type( data_raw ) ~= "string" ) then
			return
		end
		i = ( i or 0 ) + 1
		local separator = separators[i]
		if( separator == nil or string.find( data_raw, separator, 1, true ) == nil ) then
			local num = tonumber( data_raw )
			return ( num == nil and data_raw or num )
		end
	
		local data = {}
		for value in string.gmatch( data_raw, "([^"..separator.."]+)" ) do
			table.insert( data, XD_extractor( value, separators, i ))
		end
		return data
	end

	local out = nil
	if( type( data ) == "table" ) then
		local depth = pen.get_table_depth( data )
		if( pen.get_table_count( data ) > 0 and #separators >= depth ) then
			out = XD_packer( data, separators )
		end
	elseif( pen.vld( data )) then
		out = XD_extractor( data, separators )
	end
	return out
end

function pen.magic_shooter( who_shot, entity_file, x, y, v_x, v_y, do_it, proj_mods, custom_values )
	local entity_id = EntityLoad( entity_file, x, y )
	local herd_id = get_herd_id( who_shot )
	
	if( do_it ) then
		GameShootProjectile( who_shot, x, y, x + v_x, y + v_y, entity_id, false )
	end
	
	pen.magic_comp( entity_id, "ProjectileComponent", function( comp_id, v, is_enabled )
		v.mWhoShot = who_shot
		v.mShooterHerdId = herd_id
	end)
	pen.magic_comp( entity_id, "VelocityComponent", function( comp_id, v, is_enabled )
		v.mVelocity = { v_x, v_y }
	end)
	
	if( proj_mods ~= nil ) then
		proj_mods( entity_id, custom_values )
	end
	
	return entity_id
end

function pen.matter_fabricator( x, y, data )
	data = data or {}
	local size = ( type( data.size or 0 ) == "table" ) and data.size or { 0, data.size or 0.5 }
	local count = ( type( data.count or 0 ) == "table" ) and data.count or { data.count or 1, data.count or 1 }
	local delay = ( type( data.delay or 0 ) == "table" ) and data.delay or { data.delay or 1, data.delay or 1 }
	local lifetime = ( type( data.time or 0 ) == "table" ) and data.time or { data.time or 60, data.time or 60 }
	
	local mtrr = EntityCreateNew( "matterer" )
	EntitySetTransform( mtrr, x, y )
	
	local comp = EntityAddComponent2( mtrr, "ParticleEmitterComponent", {
		emitted_material_name = data.matter or "blood",
		emission_interval_min_frames = delay[1],
		emission_interval_max_frames = delay[2],
		lifetime_min = lifetime[1],
		lifetime_max = lifetime[2],
		create_real_particles = data.is_real or false,
		emit_real_particles = data.is_real2 or false,
		emit_cosmetic_particles = data.is_fake or false,
		render_on_grid = data.is_grid or false,
	})
	ComponentSetValue2( comp, "count_min", count[1])
	ComponentSetValue2( comp, "count_max", count[2])

	if( #size < 4 ) then
		ComponentSetValue2( comp, "area_circle_radius", size[1], size[2])
	else
		ComponentSetValue2( comp, "x_pos_offset_min", size[1])
		ComponentSetValue2( comp, "y_pos_offset_min", size[2])
		ComponentSetValue2( comp, "x_pos_offset_max", size[3])
		ComponentSetValue2( comp, "y_pos_offset_max", size[4])
	end
	
	EntityAddComponent2( mtrr, "LifetimeComponent", {
		lifetime = data.frames or 1,
	})
end

function pen.get_action_with_id( action_id )
	dofile_once( "data/scripts/gun/gun_enums.lua")
	dofile_once( "data/scripts/gun/gun_actions.lua" )
	
	local action_data = nil
	for i,action in ipairs( actions ) do
		if( action.id == action_id ) then
			action_data = action
			break
		end
	end

	return action_data
end

function pen.get_spell_id()
	local man = GetUpdatedEntityID()
	if( not( pen.vld( man, true ))) then
		return
	end

	local wand_id = pen.get_active_item( man )
	if( pen.vld( wand_id, true ) and current_action ~= nil and current_action.deck_index ~= nil ) then
		local abil_comp = EntityGetFirstComponentIncludingDisabled( wand_id, "AbilityComponent" )
		if( not( pen.vld( abil_comp, true ) or ComponentGetValue2( abil_comp, "use_gun_script" ))) then
			return
		end

		local index_offset = 1
		local spells = EntityGetAllChildren( wand_id )
		if( pen.vld( spells )) then
			for i,spell_id in ipairs( spells ) do
				local item_comp = EntityGetFirstComponentIncludingDisabled( spell_id, "ItemComponent" )
				if( item_comp ~= nil and ComponentGetValue2( item_comp, "permanently_attached" )) then
					index_offset = index_offset + 1
				end
			end
			return spells[ current_action.deck_index + index_offset ]
		end
	end
end

--[ECS]
function pen.get_storage( hooman, name, field, value )
	local out = 0

	local comps = EntityGetComponentIncludingDisabled( hooman, "VariableStorageComponent" )
	if( pen.vld( comps )) then
		for i,comp in ipairs( comps ) do
			if( ComponentGetValue2( comp, "name" ) == name ) then
				out = comp
				break
			end
		end
	end
	
	if( out > 0 and field ~= nil ) then
		if( value == nil ) then
			out = { pen.magic_comp( out, field )}
			return unpack( out )
		else
			pen.magic_comp( out, field, value )
		end
	end

	return out
end

function pen.get_hooman()
	local cam_x, cam_y = GameGetCameraPos()
	return EntityGetClosestWithTag( cam_x, cam_y, "player_unit" ) or 0
end

function pen.get_hooman_child( hooman, tag, ignore_id )
	if( not( pen.vld( hooman, true ))) then
		return -1
	end
	
	local children = EntityGetAllChildren( hooman )
	if( pen.vld( children )) then
		for i,child in ipairs( children ) do
			if( child ~= ignore_id and ( EntityGetName( child ) == tag or EntityHasTag( child, tag ))) then
				return child
			end
		end
	end
	
	return nil
end

---Universal component-getting utility.
---@param id entity_id
---@param data table|string
---@param func? value
---@return any
function pen.magic_comp( id, data, func ) end
---Universal component-editing utility.
---@param id component_id
---@param data table|string
---@param func? value
---@return any
function pen.magic_comp( id, data, func )
	if( not( pen.vld( id, true ))) then
		return
	end

	data = pen.get_hybrid_table( data, true )
	if( pen.is_table_weird( data )) then
		for field,val in pairs( data ) do
			local v = val
			if( type( v ) == "function" ) then
				v = { v( pen.magic_comp( id, field ))}
			else
				v = pen.get_hybrid_table( v )
			end
			table.insert( v, 1, field )
			table.insert( v, 1, id )
			pen.magic_comp( unpack( v ))
		end
	elseif( type( func or 0 ) ~= "function" ) then
		local will_get = func == nil
		local is_object = data[2] ~= nil
		local method = "Component"..( is_object and "Object" or "" )..( will_get and "Get" or "Set" ).."Value2"

		local field = ""
		func = pen.get_hybrid_table( func )
		for i = 2,1,-1 do
			if( data[i] ~= nil ) then
				field = data[i]..field
				table.insert( func, 1, data[i])
			end
		end
		table.insert( func, 1, id )
		
		local out = { pen.catch_comp( ComponentGetTypeName( id ), field, will_get and "get" or "set", _G[ method ], func, true )}
		table.remove( out, 1 )
		return unpack( out )
	else
		local comps = EntityGetComponentIncludingDisabled( unpack({ id, data[1], data[2]}))
		if( pen.vld( comps )) then
			for i,comp in ipairs( comps ) do
				local edit_tbl = {}
				local done = func( comp, edit_tbl, ComponentGetIsEnabled( comp ))
				if( pen.vld( edit_tbl )) then
					for field,val in pairs( edit_tbl ) do
						pen.magic_comp( comp, field, val )
					end
				end

				if( done ) then
					return comp
				end
			end
		end
	end
end

function pen.check_bounds( dot, pos, box )
	if( not( pen.vld( box, true ))) then
		return false
	end
	
	if( type( box ) ~= "table" ) then
		local off_x, off_y = ComponentGetValue2( box, "offset" )
		pos = { pos[1] + off_x, pos[2] + off_y }
		box = {
			ComponentGetValue2( box, "aabb_min_x" ),
			ComponentGetValue2( box, "aabb_max_x" ),
			ComponentGetValue2( box, "aabb_min_y" ),
			ComponentGetValue2( box, "aabb_max_y" ),
		}
	end
	return dot[1]>=(pos[1]+box[1]) and dot[2]>=(pos[2]+box[3]) and dot[1]<=(pos[1]+box[2]) and dot[2]<=(pos[2]+box[4])
end

function pen.get_creature_centre( hooman, x, y )
	local char_comp = EntityGetFirstComponentIncludingDisabled( hooman, "CharacterDataComponent" )
	if( pen.vld( char_comp, true )) then
		y = y + ComponentGetValue2( char_comp, "buoyancy_check_offset_y" )
	end
	return x, y
end

function pen.get_creature_head( entity_id, x, y )
	local custom_off = pen.get_storage( entity_id, "head_offset", "value_int" )
	if( pen.vld( custom_off )) then
		return x, y + custom_off
	end

	local ai_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "AnimalAIComponent" )
	if( pen.vld( ai_comp, true )) then
		y = y + ComponentGetValue2( ai_comp, "eye_offset_y" )
	else
		local crouch_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "HotspotComponent", "crouch_sensor" )
		if( pen.vld( crouch_comp, true )) then
			local off_x, off_y = ComponentGetValue2( crouch_comp, "offset" )
			y = y + off_y + 3
		end
	end
	return x, y
end

function pen.lua_callback( entity_id, func_names, input )
	local got_some = false
	local comps = EntityGetComponentIncludingDisabled( entity_id, "LuaComponent" )
	if( pen.vld( comps )) then
		local real_GetUpdatedEntityID = GetUpdatedEntityID
		local real_GetUpdatedComponentID = GetUpdatedComponentID
		GetUpdatedEntityID = function() return entity_id end

		local frame_num = GameGetFrameNum()
		for i,comp in ipairs( comps ) do
			local path = ComponentGetValue2( comp, func_names[1])
			if( pen.vld( path )) then
				local max_count = ComponentGetValue2( comp, "execute_times" )
				local count = ComponentGetValue2( comp, "mTimesExecuted" )
				if( max_count < 1 or count < max_count ) then
					got_some = true
					
					GetUpdatedComponentID = function() return comp end
					dofile( path )
					_G[ func_names[2]]( unpack( input ))

					ComponentSetValue2( comp, "mLastExecutionFrame", frame_num )
					ComponentSetValue2( comp, "mTimesExecuted", count + 1 )
					if( ComponentGetValue2( comp, "remove_after_executed" )) then
						EntityRemoveComponent( entity_id, comp )
					end
				end
			end
		end
		
		GetUpdatedEntityID = real_GetUpdatedEntityID
		GetUpdatedComponentID = real_GetUpdatedComponentID
	end
	return got_some
end

function pen.get_phys_mass( entity_id )
	local mass = 0
	
	local shape_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "PhysicsImageShapeComponent" )
	if( pen.vld( shape_comp, true )) then
		local x, y = EntityGetTransform( entity_id )
		local drift_x, drift_y = ComponentGetValue2( shape_comp, "offset_x" ), ComponentGetValue2( shape_comp, "offset_y" )
		x, y = x - drift_x, y - drift_y
		drift_x, drift_y = 1.5*drift_x, 1.5*drift_y
		
		local function calculate_force_for_body( entity, body_mass, body_x, body_y, body_vel_x, body_vel_y, body_vel_angular )
			if( math.abs( x - body_x ) < 0.001 and math.abs( y - body_y ) < 0.001 ) then
				mass = body_mass
			end
			return body_x, body_y, 0, 0, 0
		end
		PhysicsApplyForceOnArea( calculate_force_for_body, nil, x - drift_x, y - drift_y, x + drift_x, y + drift_y )
	end
	
	return mass
end

function pen.set_transform( entity_id, off_x, off_y, scale_x, scale_y, angle )
	local trans_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "InheritTransformComponent" )
	local origs = { ComponentGetValue2( trans_comp, "Transform" )}
	if( off_x or off_y or scale_x or scale_y or angle ) then
		ComponentSetValue2( trans_comp, "Transform", off_x or origs[1], off_y or origs[2], scale_x or origs[3], scale_y or origs[4], angle or origs[5])
	end
	return origs
end

function pen.delayed_kill( entity_id, delay, comp_id )
	EntityAddComponent( entity_id, "LifetimeComponent", {
		lifetime = delay + 1,
	})
	
	if( pen.vld( comp_id, true )) then
		EntityRemoveComponent( entity_id, comp_id )
	end
end

function pen.scale_emitter( hooman, emit_comp, advanced )
	advanced = advanced or false
	local borders = { 0, 0, 0, 0, }
	local gonna_update = false
	
	local sprite_comp = EntityGetFirstComponentIncludingDisabled( hooman, "SpriteComponent", "character" )
	local char_comp = EntityGetFirstComponentIncludingDisabled( hooman, "CharacterDataComponent" )
	if( advanced and pen.vld( sprite_comp, true )) then
		local offset_x = ComponentGetValue2( sprite_comp, "offset_x" )
		local offset_y = ComponentGetValue2( sprite_comp, "offset_y" )
		if( pen.vld( char_comp, true )) then
			local temp = {}
			temp[1] = ComponentGetValue2( char_comp, "collision_aabb_min_x" )
			temp[2] = ComponentGetValue2( char_comp, "collision_aabb_max_x" )
			temp[3] = ComponentGetValue2( char_comp, "collision_aabb_min_y" )
			temp[4] = ComponentGetValue2( char_comp, "collision_aabb_max_y" )
			
			if( offset_x == 0 ) then
				offset_x = ( math.abs( temp[1] ) + math.abs( temp[2] ))/2
			end
			if( offset_y == 0 ) then
				offset_y = temp[3]
			end
			
			borders[1] = ( -offset_x + temp[1] )/2
			borders[2] = ( offset_x + temp[2] )/2
			borders[3] = ( -offset_y + temp[3] )/2
			borders[4] = ( offset_y + temp[3] )/2
		else
			if( offset_x == 0 ) then
				offset_x = 3
			end
			if( offset_y == 0 ) then
				offset_y = 3
			end
			borders[1] = -offset_x
			borders[2] = offset_x
			borders[3] = -offset_y
			borders[4] = offset_y*0.5
		end

		gonna_update = true
	elseif( pen.vld( char_comp, true )) then
		borders[1] = ComponentGetValue2( char_comp, "collision_aabb_min_x" )
		borders[2] = ComponentGetValue2( char_comp, "collision_aabb_max_x" )
		borders[3] = ComponentGetValue2( char_comp, "collision_aabb_min_y" )
		borders[4] = ComponentGetValue2( char_comp, "collision_aabb_max_y" )

		gonna_update = true
	end
	
	if( gonna_update ) then
		ComponentSetValue2( emit_comp, "x_pos_offset_min", borders[1])
		ComponentSetValue2( emit_comp, "x_pos_offset_max", borders[2])
		ComponentSetValue2( emit_comp, "y_pos_offset_min", borders[3])
		ComponentSetValue2( emit_comp, "y_pos_offset_max", borders[4])
	end
end

function pen.active_item_reset( hooman )
	local inv_comp = EntityGetFirstComponentIncludingDisabled( hooman, "Inventory2Component" )
	if( pen.vld( inv_comp, true )) then
		ComponentSetValue2( inv_comp, "mActiveItem", 0 )
		ComponentSetValue2( inv_comp, "mActualActiveItem", 0 )
		ComponentSetValue2( inv_comp, "mInitialized", false )
	end
	return inv_comp
end

function pen.get_active_item( hooman )
	local inv_comp = EntityGetFirstComponentIncludingDisabled( hooman, "Inventory2Component" )
	if( pen.vld( inv_comp, true )) then
		return tonumber( ComponentGetValue2( inv_comp, "mActiveItem" ) or 0 )
	end
	
	return 0
end

function pen.get_item_owner( item_id, figure_it_out )
	if( pen.vld( item_id, true )) then
		local root_man = EntityGetRootEntity( item_id )
		local parent = item_id
		while( parent ~= root_man ) do
			parent = EntityGetParent( parent )

			local item_check = pen.get_active_item( parent )
			if( figure_it_out ) then
				item_check = item_check > 0
			else
				item_check = item_check == item_id
			end

			if( item_check ) then
				return parent
			end
		end
	end
	
	return 0
end

function pen.is_wand_useless( wand_id )
	local children = EntityGetAllChildren( wand_id )
	if( pen.vld( children )) then
		for i,child in ipairs( children ) do
			local itm_comp = EntityGetFirstComponentIncludingDisabled( child, "ItemComponent" )
			if( pen.vld( itm_comp, true )) then
				if( ComponentGetValue2( itm_comp, "uses_remaining" ) ~= 0 ) then
					return false
				end
			end
		end
	end
	return true
end

function pen.get_tinker_state( hooman, x, y )
	for n = 1,2 do
		local v = GameGetGameEffectCount( hooman, n == 1 and "EDIT_WANDS_EVERYWHERE" or "NO_WAND_EDITING" ) > 0
		v = v and n or pen.child_play( hooman, function( parent, child )
			if( GameGetGameEffectCount( child, n == 1 and "EDIT_WANDS_EVERYWHERE" or "NO_WAND_EDITING" ) > 0 ) then
				return n
			end
		end)

		if( v ) then
			return v == 1
		end
	end
	
	local workshops = EntityGetWithTag( "workshop" )
	if( pen.vld( workshops )) then
		for i,workshop in ipairs( workshops ) do
			local w_x, w_y = EntityGetTransform( workshop )
			local box_comp = EntityGetFirstComponent( workshop, "HitboxComponent" )
			if( pen.vld( box_comp, true ) and pen.check_bounds({x,y}, {w_x,w_y}, box_comp )) then
				return true
			end
		end
	end

	return false
end

function pen.is_inv_active( hooman )
	hooman = hooman or pen.get_hooman()
	
	local is_going = false
	if( pen.vld( hooman, true )) then
		pen.magic_comp( hooman, "InventoryGuiComponent", function( comp_id, v, is_enabled )
			is_going = ComponentGetValue2( comp_id, "mActive" )
		end)
	end
	return is_going
end

function pen.get_custom_effect( hooman, effect_name, effect_id )
	local children = EntityGetAllChildren( hooman )
	if( pen.vld( children )) then
		if( pen.vld( effect_id, true )) then
			if( type( effect_id ) == "string" ) then
				dofile_once( "data/scripts/status_effects/status_list.lua" )
				for i,effect in ipairs( status_effects ) do
					if( effect.ui_name == effect_id ) then
						effect_id = i
						break
					end
				end
			end
			
			for i,child in ipairs( children ) do			
				local effect_comp = EntityGetFirstComponentIncludingDisabled( child, "GameEffectComponent" )
				if( effect_comp ~= nil and ( ComponentGetValue2( effect_comp, "effect" ) == effect_name or ComponentGetValue2( effect_comp, "causing_status_effect" ) == effect_id or ComponentGetValue2( effect_comp, "ragdoll_effect" ) == effect_name )) then
					return child, effect_comp, effect_id
				end
			end
		else
			for i,child in ipairs( children ) do
				if( EntityGetName( child ) == effect_name ) then
					return child
				end
			end
		end
	end
end

function pen.access_matter_damage( entity_id, matter, damage )
	if( damage ~= nil ) then
		EntitySetDamageFromMaterial( entity_id, matter, damage )
	else
		local dmg_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "DamageModelComponent" )
		local mtrs = ComponentGetValue2( dmg_comp, "materials_that_damage" )
		local mtrs_dmg = ComponentGetValue2( dmg_comp, "materials_how_much_damage" )
		
		local tbl_mtr = {}
		for mtr in string.gmatch( mtrs, "([^,]+)" ) do
			table.insert( tbl_mtr, mtr )
		end
		local tbl_dmg = {}
		for mtr_dmg in string.gmatch( mtrs_dmg, "([^,]+)" ) do
			table.insert( tbl_dmg, mtr_dmg )
		end
		
		local tbl = {}
		for i,mtr in ipairs( tbl_mtr ) do
			tbl[mtr] = tbl_dmg[i]
		end
	
		if( matter ~= nil ) then
			return tonumber( tbl[matter])
		else
			return tbl
		end
	end
end

function pen.catch_comp( comp_name, field_name, index, func, args, forced )
	local will_set = index == "set"
	pen.catch_comp_cache = pen.catch_comp_cache or {}
	pen.catch_comp_cache[ comp_name ] = pen.catch_comp_cache[ comp_name ] or {}
	pen.catch_comp_cache[ comp_name ][ field_name ] = pen.catch_comp_cache[ comp_name ][ field_name ] or {}

	local v = pen.catch_comp_cache[ comp_name ][ field_name ][ index ]
	if( forced ) then
		v = nil
	end
	local check_val = 0
	if( pen.CANCER_COMPS[ comp_name ] ~= nil ) then
		check_val = pen.CANCER_COMPS[ comp_name ][ field_name ] or (( index == "obj" ) and -2 or check_val )
	end

	local out = {v}
	if( type( check_val ) == "function" ) then
		out = {check_val( args[1], args[#args], index )}
	elseif( check_val < 0 and index == "obj" ) then
		out[1] = check_val == -1
	elseif( check_val > 0 and ( check_val > 2 or not( will_set ))) then
		out[1] = check_val == 2
	end
	
	v = out[1]
	if( not( pen.vld( v ))) then
		pen.silent_catch = true

		out = {pen.catch( func, args )}
		v = out[1] ~= nil --cannot check write
		table.insert( out, 1, v )

		pen.catch_comp_cache[ comp_name ][ field_name ][ index ] = v or will_set
		pen.silent_catch = nil
	end

	return unpack( out )
end

function pen.clone_comp( entity_id, comp_id, mutators )
	if( not( pen.vld( comp_id, true ))) then
		return
	end
	
	mutators = mutators or {}
	
	local comp_name = ComponentGetTypeName( comp_id )
	local main_values = {
		_enabled = ComponentGetIsEnabled( comp_id ),
		_tags = ( mutators._tags or ComponentGetTags( comp_id ))..( mutators.add_tags or "" ),
	}
	local object_values = {}
	local extra_values = {}

	local function is_supported( field_name, is_obj )
		local f = ComponentGetValue2
		local input = { comp_id, field_name }
		if( type( is_obj or false ) == "string" ) then
			field_name = is_obj..field_name
			table.insert( input, input[2])
			input[2] = is_obj
			is_obj = false
			f = ComponentObjectGetValue2
		elseif( is_obj ) then
			f = ComponentObjectGetMembers
		end

		return pen.catch_comp( comp_name, field_name, is_obj and "obj" or "get", f, input )
	end
	local function set_stuff( field, value, always_extra )
		if( not( always_extra ) and #value == 1 and type( value[1]) ~= "table" ) then
			main_values[field] = value[1]
		else
			extra_values[field] = value
		end
	end
	local function get_stuff( obj )
		obj = obj or false
		local nomarker = "[NOPE]"
		
		local stuff = obj and ComponentObjectGetMembers( comp_id, obj ) or ComponentGetMembers( comp_id )
		for field in pairs( stuff ) do
			local is_object, forced_extra = is_supported( field, true )
			if( not( obj ) and is_object ) then
				get_stuff( field )
			elseif( is_supported( field, obj )) then
				if( obj or not( pen.vld( mutators[field]))) then
					local value = obj and {ComponentObjectGetValue2( comp_id, obj, field )} or {ComponentGetValue2( comp_id, field )}
					if( obj ) then
						object_values[obj] = object_values[obj] or {}
						if( not( pen.vld( mutators[obj])) or not( pen.vld( mutators[obj][field]))) then
							if( pen.vld( value )) then
								object_values[obj][field] = value
							end
						elseif( mutators[obj][field] ~= nomarker ) then
							object_values[obj][field] = pen.get_hybrid_table( mutators[obj][field])
						end
					elseif( pen.vld( value )) then
						set_stuff( field, value, forced_extra )
					end
				elseif( mutators[field] ~= nomarker ) then
					set_stuff( field, pen.get_hybrid_table( mutators[field]), forced_extra )
				end
			end
		end
	end

	if( pen.clone_comp_debug ) then
		print( comp_name )
	end
	get_stuff()
	if(( pen.clone_comp_debug or 1 ) == 1 ) then
		comp_id = EntityAddComponent2( entity_id, comp_name, main_values )
		for object,values in pairs( object_values ) do
			for field,value in pairs( values ) do
				table.insert( value, 1, field )
				table.insert( value, 1, object )
				table.insert( value, 1, comp_id )
				pen.catch_comp( comp_name, object..field, "set", ComponentObjectSetValue2, value )
			end
		end
		for field,value in pairs( extra_values ) do
			table.insert( value, 1, field )
			table.insert( value, 1, comp_id )
			pen.catch_comp( comp_name, field, "set", ComponentSetValue2, value )
		end
	end
	
	return comp_id
end

function pen.clone_entity( entity_id, x, y, mutators )
	mutators = mutators or {}
	mutators[entity_id] = mutators[entity_id] or mutators

	local new_id = EntityCreateNew( EntityGetName( entity_id ))
	EntitySetTransform( new_id, x, y )
	
	local tags = EntityGetTags( entity_id ) or ""
	for value in string.gmatch( tags, "([^,]+)" ) do
		EntityAddTag( new_id, value )
	end
	local comps = EntityGetAllComponents( entity_id )
	if( pen.vld( comps )) then
		for i,comp in ipairs( comps ) do
			local comp_name = ComponentGetTypeName( comp )
			pen.catch( pen.clone_comp, { new_id, comp, mutators[entity_id][comp] or mutators[entity_id][comp_name]})
		end
	end
	local children = EntityGetAllChildren( entity_id )
	if( pen.vld( children )) then
		for i,child in ipairs( children ) do
			EntityAddChild( new_id, clone_entity( child, x, y, mutators ))
		end
	end
	
	if( pen.clone_comp_debug == true ) then
		for name,fields in pen.magic_sorter( pen.catch_comp_cache ) do
			print( "**************"..name )
			for field,tbl in pen.magic_sorter( fields ) do
				if( tbl.get == false ) then
					print( field )
				end
				if( tbl.obj == true ) then
					print( "OBJECT: "..field )
				end
			end
		end
	end

	return new_id
end

function pen.is_sapient( entity_id )
	if( EntityHasTag( entity_id, "player_unit" )) then
		return true
	else
		for i,comp in ipairs( pen.AI_COMPS ) do
			if( EntityGetFirstComponentIncludingDisabled( entity_id, comp )) then
				return true
			end
		end
	end
	
	return false
end

function pen.rate_creature( enemy_id, hooman, check_gene )
	if( EntityGetRootEntity( enemy_id ) ~= enemy_id ) then
		return 0
	end

	local custom_points = pen.get_storage( enemy_id, "creature_rating", "value_int" )
	if( pen.vld( custom_points )) then
		return custom_points
	end

	local dmg_comp = EntityGetFirstComponentIncludingDisabled( enemy_id, "DamageModelComponent" )
	local gene_comp = EntityGetFirstComponentIncludingDisabled( enemy_id, "GenomeDataComponent" )
	if( pen.vld( dmg_comp, true ) or pen.vld( gene_comp, true )) then
		return 0
	elseif( check_gene and EntityGetHerdRelation( enemy_id, hooman ) < 90 ) then
		return 0
	end

	local dist = 50
	local f_php = 1
	if( pen.vld( hooman, true )) then
		local char_x, char_y = EntityGetTransform( hooman )
		local enemy_x, enemy_y = EntityGetTransform( enemy_id )
		dist = math.min( math.sqrt(( enemy_x - char_x )^2 + ( enemy_y - char_y )^2 ), 300 )
		
		local p_dmg_comp = EntityGetFirstComponentIncludingDisabled( hooman, "DamageModelComponent" )
		if( pen.vld( p_dmg_comp, true )) then
			local p_hp_max = ComponentGetValue2( p_dmg_comp, "max_hp" )
			local p_hp = ComponentGetValue2( p_dmg_comp, "hp" )
			local value = 0.77*( p_hp/p_hp_max ) + 0.15
			f_php = 1.353 + 10.981*value - 56.492*( value )^2 + 99.54*( value )^3 - 70.163*( value )^4 + 16.667*( value )^5
			f_php = f_php*( p_hp_max == p_hp and 2 or 1 )
			f_php = f_php*( p_hp_max <= 2 and 1.5 or 1 )
			f_php = f_php*( p_hp_max <= 1 and 2 or 1 )
		end
	end
	local f_distance = 5.917 - 0.215*dist + 0.00281*( dist )^2 - 0.000013454*dist^( 3 ) + 0.00000002152*( dist )^4
	
	local max_hp = ComponentGetValue2( dmg_comp, "max_hp" )
	local hp = ComponentGetValue2( dmg_comp, "hp" )
	local supremacy = ComponentGetValue2( gene_comp, "food_chain_rank" )
	
	local vulnerability = 0
	local armor_types = ComponentObjectGetMembers( dmg_comp, "damage_multipliers" )
	for field in pairs( armor_types ) do
		if( field ~= "healing" ) then
			vulnerability = vulnerability + ComponentObjectGetValue2( dmg_comp, "damage_multipliers", armor_types[i] )
		end
	end
	
	local violence = 0
	local animal_comp = EntityGetFirstComponentIncludingDisabled( enemy_id, "AnimalAIComponent" )
	if( pen.vld( animal_comp, true )) then
		if( ComponentGetValue2( animal_comp, "attack_melee_enabled" )) then
			violence = violence + ( ComponentGetValue2( animal_comp, "attack_melee_damage_min" ) + ComponentGetValue2( animal_comp, "attack_melee_damage_max" ))/2
		end
		if( ComponentGetValue2( animal_comp, "attack_ranged_enabled" )) then
			violence = violence + math.min(( ComponentGetValue2( animal_comp, "attack_ranged_min_distance" ) + ComponentGetValue2( animal_comp, "attack_ranged_max_distance" ))/2, 500 )/200
			violence = violence + 5/math.max( ComponentGetValue2( animal_comp, "attack_ranged_frames_between" ), 1 )
			violence = violence*( 1 + 0.5*pen.b2n( ComponentGetValue2( animal_comp, "attack_ranged_predict" )))
		end
	end
	if( EntityHasTag( enemy_id, "boss" ) or EntityHasTag( enemy_id, "miniboss" )) then
		violence = violence + 5
	end
	
	local overall_speed = 0
	local plat_comp = EntityGetFirstComponentIncludingDisabled( enemy_id, "CharacterPlatformingComponent" )
	local path_comp = EntityGetFirstComponentIncludingDisabled( enemy_id, "PathFindingComponent" )
	if( pen.vld( plat_comp, true ) and pen.vld( path_comp, true )) then
		if( ComponentGetValue2( path_comp, "can_walk" )) then
			overall_speed = overall_speed + ComponentGetValue2( plat_comp, "run_velocity" )
			if( ComponentGetValue2( path_comp, "can_fly" )) then
				overall_speed = overall_speed + math.max( ComponentGetValue2( plat_comp, "fly_velocity_x" )/5, 10 )
			end
		elseif( ComponentGetValue2( path_comp, "can_fly" )) then
			overall_speed = overall_speed + ComponentGetValue2( plat_comp, "fly_velocity_x" ) + 20
		end
	end
	if( overall_speed == 0 and EntityHasTag( enemy_id, "helpless_animal" )) then
		local fish_comp = EntityGetFirstComponentIncludingDisabled( enemy_id, "AdvancedFishAIComponent" ) or EntityGetFirstComponentIncludingDisabled( enemy_id, "FishAIComponent" )
		if( pen.vld( fish_comp, true )) then
			overall_speed = 300
		end
	end
	
	--hamis at 20m is 1
	local f_speed = ( overall_speed + 0.01 )/10
	local f_vulner = 0.77 + ( 3 - 0.26 )/( 1 + ( vulnerability/5 )^2.9 )
	local f_supremacy = math.min( supremacy, 20 )/20
	local f_violence = violence*10
	local f_hp = ( hp + max_hp )*25
	
	local main = f_distance*f_speed*f_vulner*f_hp
	local final_value = f_php*0.5*( 0.08*( main - ( main > f_supremacy and f_supremacy or 0 )) + f_violence )
	return pen.vld( final_value ) and final_value or 0
end

function pen.rate_wand( wand_id, shuffle, can_reload, capacity, reload_time, cast_delay, mana_max, mana_charge, spell_cast, spread )
	local abil_comp = EntityGetFirstComponentIncludingDisabled( wand_id, "AbilityComponent" )
	
	if( shuffle == nil ) then
		shuffle = pen.b2n( ComponentObjectGetValue2( abil_comp, "gun_config", "shuffle_deck_when_empty" ))
	end
	if( can_reload == nil ) then
		can_reload = not( ComponentGetValue2( abil_comp, "never_reload" ))
	end
	if( capacity == nil ) then
		capacity = ComponentObjectGetValue2( abil_comp, "gun_config", "deck_capacity" )
	end
	
	if( reload_time == nil ) then
		reload_time = ComponentObjectGetValue2( abil_comp, "gun_config", "reload_time" )
	end
	if( cast_delay == nil ) then
		cast_delay = ComponentObjectGetValue2( abil_comp, "gunaction_config", "fire_rate_wait" )
	end
	
	if( mana_max == nil ) then
		mana_max = ComponentGetValue2( abil_comp, "mana_max" )
	end
	if( mana_charge == nil ) then
		mana_charge = ComponentGetValue2( abil_comp, "mana_charge_speed" )
	end
	
	if( spell_cast == nil ) then
		spell_cast = ComponentObjectGetValue2( abil_comp, "gun_config", "actions_per_round" )
	end
	if( spread == nil ) then
		spread = ComponentObjectGetValue2( abil_comp, "gunaction_config", "spread_degrees" )
	end
	
	--sollex is 1
	local f_shuffle = 1 - 0.7*shuffle
	local f_reloading = 2
	if( can_reload ) then
		f_reloading = 2 - ( 0.044/0.024 )*( 1 - math.exp( -0.024*reload_time ))
	end
	local f_capacity = 3.47 + ( 0.05 - 3.47 )/( 1 + (( capacity + 3 )/13.67 )^3.05 )
	local f_delay = 2 - ( 0.044/0.024 )*( 1 - math.exp( -0.024*cast_delay ))
	local f_mana_max = 1.5 + ( 0.06 - 1.5 )/( 1 + ( mana_max/6074441 )^1.416 )^237023
	local f_mana_charge = 3.41 + ( 0.07 - 3.41 )/( 1 + ( mana_charge/14641850 )^1.314 )^251693
	local f_multi = 2.58 + ( 1.017 - 2.58 )/( 1 + ( spell_cast/48023 )^1.63 )^983676
	local f_spread = math.rad( 45 - spread )
	
	local final_value = 1500*f_delay*f_reloading*f_mana_max*f_mana_charge*math.sqrt( f_spread*f_multi )*f_shuffle*f_capacity^1.5
	return pen.vld( final_value ) and final_value or 0
end

function pen.rate_spell( spell_id )
	if( not( pen.vld( spell_id, true ))) then
		return 0	
	end
	
	local t_item_comp = EntityGetFirstComponentIncludingDisabled( spell_id, "ItemComponent" )
	local t_act_comp = EntityGetFirstComponentIncludingDisabled( spell_id, "ItemActionComponent" )
	local action_data = pen.get_action_with_id( ComponentGetValue2( t_act_comp, "action_id" ))
	if( not( pen.vld( action_data ))) then
		return 0
	end
	
	local price = action_data.price
	local uses_max = action_data.max_uses or -1
	local mana = math.abs( action_data.mana or 0 )
	local is_perma = pen.b2n( ComponentGetValue2( t_item_comp, "permanently_attached" ))
	local uses_left = ComponentGetValue2( t_item_comp, "uses_remaining" )
	
	--sparkbolt is 1
	local f_perma = 1 + 4*is_perma
	local f_price = price/100
	local f_uses = uses_left/uses_max
	if( uses_left < 0 and uses_max > 0 ) then
		f_uses = 2
	end
	local f_mana = 5.4 + ( 0.1 - 5.4 )/( 1 + ( mana/8420.3 )^0.367 )
	
	local final_value = 2.5*f_perma*f_price*f_uses*f_mana
	return pen.vld( final_value ) and final_value or 0
end

function pen.rate_projectile( hooman, projectile_id )
	if( EntityGetRootEntity( projectile_id ) ~= projectile_id ) then
		return 0
	end
	
	local proj_comp = EntityGetFirstComponentIncludingDisabled( projectile_id, "ProjectileComponent" )
	local char_x, char_y = EntityGetTransform( hooman )
	local proj_x, proj_y = EntityGetTransform( projectile_id )
	
	local proj_vel_x, proj_vel_y = GameGetVelocityCompVelocity( projectile_id )
	local char_vel_x, char_vel_y = GameGetVelocityCompVelocity( hooman )
	local proj_v = math.sqrt(( char_vel_x - proj_vel_x )^2 + ( char_vel_y - proj_vel_y )^2 )
	
	local d_x = proj_x - char_x
	local d_y = proj_y - char_y
	local direction = math.abs( math.rad( 180 ) - math.abs( math.atan2( proj_vel_x, proj_vel_y ) - math.atan2( d_x, d_y )))
	local distance = math.sqrt(( d_x )^2 + ( d_y )^ 2 )
	
	local is_real = pen.b2n( ComponentGetValue2( proj_comp, "collide_with_entities" ))
	local lifetime = ComponentGetValue2( proj_comp, "lifetime" )
	if( lifetime < 2 and lifetime > -1 ) then
		lifetime = 1
	end
	
	local total_damage = 0
	local damage_types = { "curse", "drill", "electricity", "explosion", "fire", "ice", "melee", "overeating", "physics_hit", "poison", "projectile", "radioactive", "slice", }
	for i = 1,#damage_types do
		local dmg = ComponentObjectGetValue2( proj_comp, "damage_by_type", damage_types[i] )
		if( dmg > 0 ) then
			total_damage = total_damage + dmg
		end
	end
	total_damage = total_damage + ComponentGetValue2( proj_comp, "damage" )
	
	local explosion_dmg = ComponentObjectGetValue2( proj_comp, "config_explosion", "damage" )
	local explosion_rad = ComponentObjectGetValue2( proj_comp, "config_explosion", "explosion_radius" )
	if( explosion_dmg > 0 ) then
		explosion_dmg = explosion_dmg + explosion_rad/25
		
		if( distance <= explosion_rad ) then
			explosion_dmg = explosion_dmg + ( explosion_rad - distance + 1 )/25
		end
	end
	total_damage = total_damage + explosion_dmg
	
	--sparkbolt at 20m is ~1
	local f_distance = 1 + 4/2^( distance/10 )
	local f_direction = 0.02 + 1.08/2^( direction/0.6 )
	local f_velocity = 0.1847 + ( 1 - math.exp( -0.0021*proj_v ))
	local f_lifetime = ( 1.8*( lifetime - 1 )/lifetime + 0.3 )/2
	local f_is_real = 0.5 + 0.5*is_real
	local f_damage = total_damage*25
	
	local final_value = 0.15*f_distance*f_direction*f_lifetime*f_is_real*f_velocity*f_damage
	return pen.vld( final_value ) and final_value or 0
end

--[FRONTEND]
function pen.secs_to_time( secs )
	secs = math.floor( secs )
	local mins = math.floor( secs/60 )
	secs = secs - mins*60
	local hrs = math.floor( mins/60 )
	mins = mins - hrs*60
	local t = { hrs, mins, secs }

	local out = tostring( hrs )
	for i = 2,3 do
		out = out..":"..string.sub( "0"..t[i], -2 )
	end
	return out
end

function pen.colourer( gui, c_type )
	if( #c_type == 0 ) then return end
	local color = { r = 0, g = 0, b = 0 }
	if( type( c_type ) == "table" ) then
		color.r = c_type[1] or 255
		color.g = c_type[2] or 255
		color.b = c_type[3] or 255
	end
	GuiColorSetForNextWidget( gui, color.r/255, color.g/255, color.b/255, 1 )
end

function pen.play_sound( event, x, y, no_bullshit )
	if( type( event ) ~= "table" ) then
		event = { "mods/penman/sfx/penman.bank", event, }
	end
	no_bullshit = no_bullshit or false
	
	if( not( no_bullshit )) then
		local sfx_id = tostring( GameGetFrameNum())..event[2]
		if( sound_played == sfx_id ) then
			return
		end
		sound_played = sfx_id
	end
	
	if( x == nil ) then
		x, y = GameGetCameraPos()
	end
	GamePlaySound( event[1], event[2], x, y )
end

function pen.play_entity_sound( entity_id, x, y, event_mutator, no_bullshit )
	local sound_table = {
		ComponentGetValue2( get_storage( entity_id, "sound_bank" ), "value_string" ),
		ComponentGetValue2( get_storage( entity_id, "sound_event" ), "value_string" )..( event_mutator or "" ),
	}
	if( not( pen.vld( sound_table[1]))) then
		return
	end
	pen.play_sound( sound_table, x, y, no_bullshit )
end

function pen.new_text( gui, pic_x, pic_y, pic_z, text, colours )
	local out_str = {}
	if( text ~= nil ) then
		if( type( text ) == "table" ) then
			out_str = text
		else
			table.insert( out_str, text )
		end
	else
		table.insert( out_str, "[NIL]" )
	end
	
	for i,line in ipairs( out_str ) do
		pen.colourer( gui, colours or {})
		GuiZSetForNextWidget( gui, pic_z )
		GuiText( gui, pic_x, pic_y, line )
		pic_y = pic_y + 9
	end
end

function pen.new_image( gui, uid, pic_x, pic_y, pic_z, pic, s_x, s_y, alpha, interactive, angle )
	if( s_x == nil ) then
		s_x = 1
	end
	if( s_y == nil ) then
		s_y = 1
	end
	if( alpha == nil ) then
		alpha = 1
	end
	if( interactive == nil ) then
		interactive = false
	end
	
	if( not( interactive )) then
		GuiOptionsAddForNextWidget( gui, 2 ) --NonInteractive
	end
	GuiZSetForNextWidget( gui, pic_z )
	uid = uid + 1
	GuiIdPush( gui, uid )
	GuiImage( gui, uid, pic_x, pic_y, pic, alpha, s_x, s_y, angle, 2 )
	return uid
end

function pen.new_button( gui, uid, pic_x, pic_y, pic_z, pic )
	GuiZSetForNextWidget( gui, pic_z )
	uid = uid + 1
	GuiIdPush( gui, uid )
	GuiOptionsAddForNextWidget( gui, 6 ) --NoPositionTween
	GuiOptionsAddForNextWidget( gui, 4 ) --ClickCancelsDoubleClick
	GuiOptionsAddForNextWidget( gui, 21 ) --DrawNoHoverAnimation
	GuiOptionsAddForNextWidget( gui, 47 ) --NoSound
	local clicked, r_clicked = GuiImageButton( gui, uid, pic_x, pic_y, "", pic )
	return uid, clicked, r_clicked
end

--make it better
function pen.new_blinker( gui, colour )
	colour = rgb2hsv( colour )
	local fancy_index = math.abs( math.cos( math.rad( GameGetFrameNum())))
	colour = hsv2rgb( { colour[1], fancy_index*colour[2], math.max( colour[3], ( 1 - fancy_index )), colour[3] } )
	GuiColorSetForNextWidget( gui, colour[1], colour[2], colour[3], colour[4] )
end

function pen.new_anim( gui, uid, auid, pic_x, pic_y, pic_z, path, amount, delay, s_x, s_y, alpha, interactive )
	anims_state = anims_state or {}
	anims_state[auid] = anims_state[auid] or { 1, 0 }
	
	pen.new_image( gui, uid, pic_x, pic_y, pic_z, path..anims_state[auid][1]..".png", s_x, s_y, alpha, interactive )
	
	anims_state[auid][2] = anims_state[auid][2] + 1
	if( anims_state[auid][2] > delay ) then
		anims_state[auid][2] = 0
		anims_state[auid][1] = anims_state[auid][1] + 1
		if( anims_state[auid][1] > amount ) then
			anims_state[auid][1] = 1
		end
	end
	
	return uid
end

function pen.new_cutout( gui, uid, pic_x, pic_y, size_x, size_y, func, v )
	uid = uid + 1
	GuiIdPush( gui, uid )

	local margin = 0
	GuiAnimateBegin( gui )
	GuiAnimateAlphaFadeIn( gui, uid, 0, 0, true )
	GuiBeginAutoBox( gui )
	GuiBeginScrollContainer( gui, uid, pic_x - margin, pic_y - margin, size_x, size_y, false, margin, margin )
	GuiEndAutoBoxNinePiece( gui )
	GuiAnimateEnd( gui )
	uid = func( gui, uid, v )
	GuiEndScrollContainer( gui )

	return uid
end

--[GLOBALS]
pen.DIV_0 = "@"
pen.DIV_1 = "&"
pen.DIV_2 = "|"
pen.DIV_3 = "!"
pen.DIV_4 = ":"

pen.AI_COMPS = {
	AIAttackComponent = 1,
	AdvancedFishAIComponent = 1,
	AnimalAIComponent = 1,
	BossDragonComponent = 1,
	ControllerGoombaAIComponent = 1,
	CrawlerAnimalComponent = 1,
	FishAIComponent = 1,
	PhysicsAIComponent = 1,
	WormAIComponent = 1,
}

pen.CANCER_COMPS = {
	-- -1 is an object; -2 is not an object (defaults to -2 if the component table is empty, else checks)
	-- on nil will check, 1 is an invalid write with checked read, 2 is a fully valid field, 3 is a fully invalid field

	AIAttackComponent = {},
	AIComponent = {
		data = 3,
	},
	AbilityComponent = {
		gun_config = -1,
		gunaction_config = -1,
	},
	AdvancedFishAIComponent = {},
	AltarComponent = {
		m_recognized_entity_tags = 3,
		m_current_entity_tags = 3,
	},
	AnimalAIComponent = {
		attack_melee_finish_config_explosion = -1,
		attack_melee_finish_config_explosiondamage_critical = 3,
		mCurrentJob = 3,
		mAiStateStack = 3,
	},
	ArcComponent = {},
	AreaDamageComponent = {},
	AttachToEntityComponent = {},
	AudioComponent = {},
	AudioListenerComponent = {},
	AudioLoopComponent = {},
	BiomeTrackerComponent = {
		current_biome = 3,
	},
	BlackHoleComponent = {},
	BookComponent = {},
	BossDragonComponent = {},
	CameraBoundComponent = {},
	CardinalMovementComponent = {},
	CellEaterComponent = {
		materials = 1,
	},
	CharacterCollisionComponent = {},
	CharacterDataComponent = {},
	CharacterPlatformingComponent = {},
	CharacterStatsComponent = {
		stats = 3,
	},
	CollisionTriggerComponent = {},
	ConsumableTeleportComponent = {},
	ControllerGoombaAIComponent = {},
	ControlsComponent = {},
	CrawlerAnimalComponent = {},
	CutThroughWorldDoneHereComponent = {},
	DamageModelComponent = {
		damage_multipliers = -1,
		mCollisionMessageMaterials = 1,
		mDamageMaterialsHowMuch = 1,
		mDamageMaterials = 1,
		mMaterialDamageThisFrame = 1,
		mCollisionMessageMaterialCountsThisFrame = 1,
	},
	DamageNearbyEntitiesComponent = {},
	DebugFollowMouseComponent = {},
	DebugLogMessagesComponent = {},
	DebugSpatialVisualizerComponent = {},
	DieIfSpeedBelowComponent = {},
	DroneLauncherComponent = {},
	DrugEffectComponent = {
		drug_fx_target = -1,
		m_drug_fx_current = -1,
	},
	DrugEffectModifierComponent = {
		fx_add = -1,
		fx_multiply = -1,
	},
	ElectricChargeComponent = {},
	ElectricityReceiverComponent = {},
	ElectricitySourceComponent = {},
	EndingMcGuffinComponent = {},
	EnergyShieldComponent = {},
	ExplodeOnDamageComponent = {
		config_explosion = -1,
		config_explosiondamage_critical = 3,
	},
	ExplosionComponent = {
		config_explosion = -1,
		config_explosiondamage_critical = 3,
	},
	FishAIComponent = {},
	FlyingComponent = {},
	FogOfWarRadiusComponent = {},
	FogOfWarRemoverComponent = {},
	GameAreaEffectComponent = {
		game_effect_entitities = 1,
		mEntitiesAppliedOutTo = 1,
		mEntitiesAppliedFrame = 1,
	},
	GameEffectComponent = {},
	GameLogComponent = {
		mVisitiedBiomes = 1,
	},
	GameStatsComponent = {},
	GasBubbleComponent = {},
	GenomeDataComponent = {
		friend_firemage = function( comp_id, value, index )
			if( index == "set" ) then
				ComponentSetValue2( comp_id, "friend_firemage", value == 1 )
			end
			
			local index_tbl = { true, false, true }
			return index_tbl[ index ], true
		end,
		friend_thundermage = function( comp_id, value, index )
			if( index == "set" ) then
				ComponentSetValue2( comp_id, "friend_thundermage", value == 1 )
			end

			local index_tbl = { true, false, true }
			return index_tbl[ index ], true
		end,
	},
	GhostComponent = {},
	GodInfoComponent = {
		god_entity = 3,
	},
	GunComponent = {
		mLuaManager = 3,
	},
	HealthBarComponent = {},
	HitEffectComponent = {},
	HitboxComponent = {},
	HomingComponent = {},
	HotspotComponent = {},
	IKLimbAttackerComponent = {
		mState = 3,
	},
	IKLimbComponent = {},
	IKLimbWalkerComponent = {},
	IKLimbsAnimatorComponent = {
		mLimbStates = 3,
	},
	IngestionComponent = {
		m_ingestion_satiation_material_cache = 3,
	},
	InheritTransformComponent = {},
	InteractableComponent = {},
	Inventory2Component = {},
	InventoryComponent = {
		items = 3,
		update_listener = 3,
	},
	InventoryGuiComponent = {
		imgui = 3,
		mLastPurchasedAction = 3,
	},
	ItemAIKnowledgeComponent = {},
	ItemActionComponent = {},
	ItemAlchemyComponent = {},
	ItemChestComponent = {},
	ItemComponent = {},
	ItemCostComponent = {},
	ItemPickUpperComponent = {},
	ItemRechargeNearGroundComponent = {},
	ItemStashComponent = {},
	KickComponent = {},
	LaserEmitterComponent = {
		laser = -1,
	},
	LevitationComponent = {},
	LifetimeComponent = {},
	LightComponent = {
		mSprite = 3,
	},
	LightningComponent = {
		config_explosion = -1,
		config_explosiondamage_critical = 3,
	},
	LimbBossComponent = {},
	LiquidDisplacerComponent = {},
	LoadEntitiesComponent = {},
	LocationMarkerComponent = {},
	LooseGroundComponent = {},
	LuaComponent = {
		mPersistentValues = 3,
		mLuaManager = 3,
	},
	MagicConvertMaterialComponent = {
		mFromMaterialArray = 1,
		mToMaterialArray = 1,
	},
	ManaReloaderComponent = {},
	MaterialAreaCheckerComponent = {},
	MaterialInventoryComponent = {
		count_per_material_type = function( comp_id, value, index )
			if( index == "set" ) then
				local entity_id = ComponentGetEntity( comp_id )
				for matter,count in pairs( value ) do
					AddMaterialInventoryMaterial( entity_id, matter, count )
				end
			end

			local index_tbl = { true, false, true }
			return index_tbl[ index ]
		end,
	},
	MaterialSeaSpawnerComponent = {},
	MaterialSuckerComponent = {},
	MoveToSurfaceOnCreateComponent = {},
	MusicEnergyAffectorComponent = {},
	NinjaRopeComponent = {
		mSegments = 3,
	},
	NullDamageComponent = {},
	OrbComponent = {},
	ParticleEmitterComponent = {
		m_collision_angles = 3,
		m_cached_image_animation = 3,
	},
	PathFindingComponent = {
		mFallbackLogic = 3,
		path_next_node = 3,
		mState = 3,
		input = 3,
		jump_trajectories = 3,
		path_previous_node = 3,
		debug_path = 3,
		job_result_receiver = 3,
		mSelectedLogic = 3,
		mLogic = 3,
		path = 3,
	},
	PathFindingGridMarkerComponent = {
		mNode = 3,
	},
	PhysicsAIComponent = {},
	PhysicsBody2Component = {
		mBody = 3,
		mBodyId = 3,
	},
	PhysicsBodyCollisionDamageComponent = {},
	PhysicsBodyComponent = {
		mBody = 3,
		mBodyId = 3,
		mLocalPosition = 3,
	},
	PhysicsImageShapeComponent = {
		mBody = 3,
	},
	PhysicsJoint2Component = {},
	PhysicsJoint2MutatorComponent = {
		mBox2DJointId = 3,
	},
	PhysicsJointComponent = {
		mJoint = 3,
	},
	PhysicsKeepInWorldComponent = {},
	PhysicsPickUpComponent = {
		leftJoint = 3,
		rightJoint = 3,
	},
	PhysicsRagdollComponent = {
		bodies = 3,
	},
	PhysicsShapeComponent = {},
	PhysicsThrowableComponent = {},
	PixelSceneComponent = {},
	PixelSpriteComponent = {
		mPixelSprite = 3,
	},
	PlatformShooterPlayerComponent = {
		mTeleBoltFramesDuringLastSecond = 3,
	},
	PlayerCollisionComponent = {
		mPhysicsCollisionHax = 3,
	},
	PlayerStatsComponent = {},
	PositionSeedComponent = {},
	PotionComponent = {},
	PressurePlateComponent = {},
	ProjectileComponent = {
		config = -1,
		damage_by_type = -1,
		damage_critical = -1,
		config_explosion = -1,
		config_explosiondamage_critical = 3,
		mTriggers = 3,
		mDamagedEntities = 1,
	},
	RotateTowardsComponent = {},
	SetLightAlphaFromVelocityComponent = {},
	SetStartVelocityComponent = {},
	ShotEffectComponent = {},
	SimplePhysicsComponent = {},
	SineWaveComponent = {},
	SpriteAnimatorComponent = {
		mCachedTargetSpriteTag = 3,
		mStates = 3,
	},
	SpriteComponent = {
		mRenderList = 3,
		mSprite = 3,
	},
	SpriteOffsetAnimatorComponent = {},
	SpriteParticleEmitterComponent = {},
	SpriteStainsComponent = {
		mTextureHandle = 3,
		mData = 3,
		mState = 3,
	},
	StatusEffectDataComponent = {
		stain_effect_cooldowns = 1,
		ingestion_effect_causes_many = 1,
		ingestion_effect_causes = 1,
		mStainEffectsSmoothedForUI = 1,
		stain_effects = 1,
		effects_previous = 1,
		ingestion_effects = 1,
	},
	StreamingKeepAliveComponent = {},
	TelekinesisComponent = {
		mBodyID = 3,
	},
	TeleportComponent = {
		state = 3,
		teleported_entities = 1,
	},
	TeleportProjectileComponent = {},
	TextLogComponent = {},
	TorchComponent = {},
	UIIconComponent = {},
	UIInfoComponent = {},
	VariableStorageComponent = {},
	VelocityComponent = {},
	VerletPhysicsComponent = {
		links = 3,
		sprite = 3,
		colors = 3,
		materials = 3,
	},
	VerletWeaponComponent = {},
	VerletWorldJointComponent = {
		mCell = 3,
	},
	WalletComponent = {},
	WalletValuableComponent = {},
	WormAIComponent = {},
	WormAttractorComponent = {},
	WormComponent = {
		mPrevPositions = 3,
	},
	WormPlayerComponent = {},
}
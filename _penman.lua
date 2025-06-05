-- if you are using this as a standalone library, it is highly recommended to covert the "pen" table to a local variable
pen = pen or {} -- replace this line with "local pen = {}"
pen.t = pen.t or {} -- table funcs
pen.c = pen.c or {} -- cache table
pen.c.ttips = pen.c.ttips or {} --tip data
if( GameGetWorldStateEntity() > 0 ) then
	GlobalsSetValue( "PROSPERO_IS_REAL", "1" )
end

--[CLASSES]
pen.V = { --https://github.com/Wiseluster/lua-vector/blob/master/vector.lua
	__mt = {
		__add = function( a, b )
			if( type( b ) == "number" ) then
				b = { x = b, y = b } end
			return pen.V.new( a.x + b.x, a.y + b.y )
		end,
		__sub = function( a, b )
			if( type( b ) == "number" ) then
				b = { x = b, y = b } end
			return pen.V.new( a.x - b.x, a.y - b.y )
		end,
		__mul = function( a, b )
			if( type( b ) == "number" ) then
				return pen.V.new( a.x*b, a.y*b ) end
			return a.x*b.x + a.y*b.y
		end,
		__div = function( a, b )
			if( type( b ) ~= "number" ) then
				return a end
			return pen.V.new( a.x/b, a.y/b )
		end,
		__eq = function( a, b )
			if( type( b ) == "number" ) then
				return false end
			return a.x == b.x and a.y == b.y
		end,
		__unm = function( a )
			return pen.V.new( -a.x, -a.y )
		end,
		__tostring = function( a )
			return table.concat({ "[", a.x, ";", a.y, "]" })
		end,
	},
	new = function( x, y )
		return setmetatable({ x = x or 0, y = y or 0 }, pen.V.__mt )
	end,
	len = function( v )
		return math.sqrt(( v.x )^2 + ( v.y )^2 )
	end,
	abs = function( v )
		return pen.V.new( math.abs( v.x ), math.abs( v.y ))
	end,
	max = function( v, a )
		return pen.V.new( math.max( v.x, a ), math.max( v.y, a ))
	end,
	min = function( v, a )
		return pen.V.new( math.min( v.x, a ), math.min( v.y, a ))
	end,
	rot = function( v, a )
		if( a == 0 ) then return v end
		local x = v.x*math.cos( a ) + v.y*math.sin( a )
		local y = v.x*math.sin( a ) - v.y*math.cos( a )
		return pen.V.new( x, y )
	end,
}

--[IO]
pen.magic_draw = pen.magic_draw or ModImageMakeEditable or penman_d
pen.magic_read = pen.magic_read or ModTextFileGetContent or penman_r
pen.magic_write = pen.magic_write or ModTextFileSetContent or penman_w
if( pen.magic_write ~= nil ) then
	pen.t2f = function( name, text )
		if( pen[ name ] == nil ) then
			local num = tonumber( GlobalsGetValue( pen.GLOBAL_VIRTUAL_ID, "0" ))
			GlobalsSetValue( pen.GLOBAL_VIRTUAL_ID, num + 1 )
			local path = table.concat({ pen.FILE_T2F, num, ".lua" })
			pen.magic_write( path, "return "..text )
			pen[ name ] = dofile( path )
		end
		return pen[ name ]
	end
end

--[MATH]
function pen.b2n( a )
	return ( a or false ) and 1 or 0
end
function pen.n2b( a )
	return ( a or 0 ) > 0
end

function pen.vld( v, is_ecs )
	if( v == nil ) then return false end
	local t, out = type( v ), true
	if( t == "number" ) then
		out = v == v and v ~= math.inf
		if( out and is_ecs ) then out = v > 0 end
	elseif( t == "string" ) then
		out = v ~= pen.DIV_1 and v ~= "" and v ~= " " and v ~= "\0"
	elseif( t == "table" ) then
		out = pen.t.count( v, true ) > 0
	end
	return out
end

function pen.get_sign( a )
	return ( a or 0 ) < 0 and -1 or 1
end

function pen.eps_compare( a, b, eps )
	return math.abs( a - ( b or 0 )) < ( eps or 0.00001 )
end

function pen.rounder( num, k )
	k = k or 1000
	if( k > 0 ) then
		return math.floor( k*num + 0.5 )/k
	else return math.ceil( k*num - 0.5 )/k end
end

function pen.limiter( value, limit, max_mode )
	limit = math.abs( limit )
	if( max_mode and math.abs( value ) < limit ) then return pen.get_sign( value )*limit end
	if( not( max_mode ) and math.abs( value ) > limit ) then return pen.get_sign( value )*limit end
	return value
end

function pen.get_angular_delta( a, b, get_max )
	local pi, pi4 = math.rad( 90 ), math.rad( 360 )
	local d360, d180 = a - b, ( a + pi )%pi4 - ( b + pi )%pi4
	if( get_max ) then
		return math.abs( d360 ) > math.abs( d180 ) and d360 or d180
	else return math.abs( d360 ) < math.abs( d180 ) and d360 or d180 end
end

function pen.angle_reset( angle )
	if( math.abs( angle ) < 6.283 ) then return angle end
	return math.atan2( math.sin( angle ), math.cos( angle ))
end

function pen.rotate_offset( x, y, angle )
	if(( x == 0 and y == 0 ) or ( angle or 0 ) == 0 ) then return x, y end
	return x*math.cos( angle ) - y*math.sin( angle ), x*math.sin( angle ) + y*math.cos( angle )
end

function pen.magic_uint( color )
	return type( color ) == "table" and bit.bor(
		color[1],
		bit.lshift( color[2], 8 ),
		bit.lshift( color[3], 16 ),
		bit.lshift( color[4] or 1, 24 )
	) or {
		bit.band( color, 0xff ),
		bit.band( bit.rshift( color, 8 ), 0xff ),
		bit.band( bit.rshift( color, 16 ), 0xff ),
		bit.band( bit.rshift( color, 24 ), 0xff )
	}
end

function pen.hash_me( str, is_huge )
	if( type( str ) == "table" ) then str = pen.t.parse( str ) end
	return pen.cache({ "cached_hash", str }, function()
		local a, b, c = 0, 0
		local c = ( is_huge or false ) and 4294967295 or 65535
		for i = 1,#str do
			a = ( a + string.byte( str, i ))%c
			b = ( a + b )%c
		end
		return string.format( "%.0f", b*c + a )
	end, { reset_frame = pen.CACHE_RESET_DELAY })
end

function pen.key_me( str )
	str = string.gsub( string.gsub( str, pen.KEY, pen.HOLE ), "%c", pen.HOLE )
	return string.gsub( string.gsub( str, pen.DIV_1, pen.HOLE ), pen.DIV_2, pen.HOLE )
end

--add autotuning with visualizer via new_plot
function pen.pid( pid, delta, k ) --https://www.robotsforroboticists.com/pid-control/
	k = k or {}
	pen.c.pid_memo = pen.c.pid_memo or {}
	pen.c.pid_memo[ pid ] = pen.c.pid_memo[ pid ] or {0,0}
	k.p, k.i, k.d, k.bias = k.p or 1, k.i or 0, k.d or 0, k.bias or 0

	-- Tuning guide:
	-- The k.i and k.d gains are first set to zero.
	-- The proportional gain is increased until it reaches the ultimate gain, KU, at which the output of the loop starts to oscillate.
	-- KU and the oscillation period PU are used to set the gains as shown: k.p = 0.6*KU; k.i = 2*k.p/PU; k.d = k.p*PU/8

	local time = 1
	local int = pen.c.pid_memo[ pid ][2] + delta*time
	local der = ( delta - pen.c.pid_memo[ pid ][1])/time
	pen.c.pid_memo[ pid ] = { delta, int }
	return k.p*delta + k.i*int + k.d*der + k.bias
end

function pen.atimer( tid, duration, reset_now, stillborn )
	local frame_num = GameGetFrameNum()
	pen.c.animation_timer = pen.c.animation_timer or {}
	if( pen.c.animation_timer[ tid ] == nil or reset_now ) then
		pen.c.animation_timer[ tid ] = frame_num - (( stillborn or false ) and duration or 0 )
	end; return math.min( frame_num - pen.c.animation_timer[ tid ], duration or 0 )
end

function pen.estimate( eid, target, alg, min_delta, max_delta ) --thanks Nathan
	alg = alg or "exp"
	target = pen.get_hybrid_table( target )
	min_delta = math.max( min_delta or 0.01, 0.0001 )
	pen.c.estimator_memo = pen.c.estimator_memo or {}
	if( target[3]) then pen.c.estimator_memo[ eid ] = nil end
	pen.c.estimator_memo[ eid ] = pen.c.estimator_memo[ eid ] or target[2] or target[1]
	
	local value = pen.c.estimator_memo[ eid ]
	if( pen.eps_compare( value, target[1], min_delta )) then return target[1] end
	local delta = pen.ESTIM_ALGS[ string.sub( alg, 1, 3 )]( target[1], value, tonumber( string.sub( alg, 4, -1 )))
	pen.c.estimator_memo[ eid ] = value + pen.limiter( pen.limiter( delta, max_delta or delta ), min_delta, true )
	return pen.c.estimator_memo[ eid ]
end

function pen.animate( delta, frame, data ) --https://www.febucci.com/2018/08/easing-functions/
	data = data or {}
	data.frames = data.frames or 20
	data.ease_int = data.ease_int or "lerp"
	data.ease_in = pen.get_hybrid_table( data.ease_in )
	data.ease_out = pen.get_hybrid_table( data.ease_out )
	
	delta = pen.get_hybrid_table( delta )
	if( delta[2] == nil ) then delta[2] = delta[1]; delta[1] = 0 end
	
	local is_looped = frame == true
	local frame_num = data.frame_num or GameGetFrameNum()
	if( type( frame ) == "string" ) then
		frame = pen.atimer( frame, data.frames, data.reset_now, data.stillborn )
	elseif( is_looped ) then frame = frame_num%data.frames end
	
	local time = frame/data.frames
	if( not( is_looped )) then
		if( time == 0 ) then return delta[1] end
		if( time == 1 ) then return delta[2] end
	elseif( data.type == "frir" ) then
		local total = 0
		for i,k in ipairs( pen.ANIM_INTERS[ data.type ]( time, delta, data.params )) do
			total = total + data.params[i]*( math.cos( 2*math.pi*i*k.r ) - math.sin( 2*math.pi*i*k.i ))
		end
		return total
	end
	
	if( is_looped and math.floor( frame_num/data.frames )%2 == 1 ) then time = 1 - time end

	local orig_time = time
	for i = 1,math.max( #data.ease_in, #data.ease_out ) do
		local eases = {}
		for k = 1,2 do
			local ease = data[ k == 1 and "ease_in" or "ease_out" ][i]
			if( pen.vld( ease )) then
				local func = {}
				if( type( ease ) == "function" ) then func = { ease, data } else
					func = { pen.ANIM_EASINGS[ string.sub( ease, 1, 3 )], tonumber( string.sub( ease, 4, -1 ))}
				end
				if( k == 1 ) then
					eases[2] = func[1]( time, func[2])
				else eases[1] = 1 - func[1]( 1 - time, func[2]) end
			end
		end
		
		if( eases[1] ~= nil and eases[2] ~= nil ) then
			time = pen.ANIM_INTERS[ data.ease_int ]( orig_time, eases, data.params_int )
		else time = eases[1] or eases[2] or orig_time end
	end
	
	data.type = data.type or "lerp"
	if( data.type == "function" ) then
		return data.type( time, delta, data.params )
	else return pen.ANIM_INTERS[ data.type ]( time, delta, data.params ) end
end

function pen.simulate()
	--gets uid and init pos with data, returns new pos
	--does a full-blown rigibody sim, executes with a frame-long delay to collect all the objects
	--build colliders either by evaluating sprite pixels manually, or just pass a table with vertexes
end

--[TECHNICAL]
function pen.get_hybrid_table( table, allow_unarray )
	if( type( table ) == "table" and ( allow_unarray or not( pen.t.is_unarray( table )))) then
		return table
	else return { table } end
end

function pen.get_hybrid_function( func, input )
	if( not( pen.vld( func ))) then return end
	if( type( func ) == "function" ) then
		return pen.catch( func, input, nil, pen.t.is_unarray( input ))
	else return func end
end

function pen.v2s( value, is_pretty, full_precision, unquote )
	full_precision, unquote = full_precision or false, unquote or false
	return ( is_pretty or false ) and tostring( value ) or (({
		["nil"] = function( v ) return "" end,
		["number"] = function( v ) return full_precision and string.format( "%.16f", v ) or tostring( v ) end,
		["string"] = function( v ) return unquote and v or string.format( "%q", v ) end,
		["boolean"] = function( v ) return "bool"..pen.b2n( v ) end,
		["function"] = function( v ) return string.format( "%q", tostring( v )) end,
		["userdata"] = function( v ) return string.format( "%q", tostring( v )) end,
	})[ type( value )]( value ) or value )
end
function pen.s2v( str )
	if( not( pen.vld( str ))) then
		return
	elseif( string.find( str, "^bool[01]$" )) then
		return pen.n2b( tonumber( string.sub( str, -1, -1 )))
	elseif( tonumber( str )) then
		return tonumber( str )
	elseif( string.find( str, "^\".+\"$" )) then
		return string.sub( str, 2, -2 )
	end
	return str
end

function pen.t.init( amount, value )
	local is_tbl = type( value ) == "table"
	local tbl, temp = {}, value
	for i = 1,amount do
		tbl[i] = is_tbl and {} or temp
	end
	return tbl
end

function pen.t.loop( tbl, func, return_tbl )
	if( not( pen.vld( tbl ))) then return end
	if( type( tbl ) ~= "table" ) then return func( 0, tbl ) end

	local is_unarray = pen.t.is_unarray( tbl )
	for i,v in ( is_unarray and pairs or ipairs )( tbl ) do
		local value = func( i, v )
		if( value ~= nil ) then return value end
	end

	if( return_tbl ) then return tbl end
end

function pen.t.loop_concat( tbl, func )
	local out, n = {}, 1
	pen.t.loop( tbl, function( i, v )
		pen.t.loop( func( i, v ), function( e, value )
			out[n] = value; n = n + 1
		end)
	end)
	return table.concat( out )
end

function pen.t.count( tbl, just_checking )
	if( type( tbl ) ~= "table" ) then return 0 end

	local count = 0
	for k,v in pairs( tbl ) do
		count = count + 1
		if( just_checking ) then break end
	end
	return count
end

function pen.t.depth( tbl, d )
	d = d or 0
	if( type( tbl ) == "table" ) then
		for k,v in pairs( tbl ) do
			d = pen.t.depth( v, d + 1 )
			break
		end
	end
	return d
end

function pen.t.bins( tbl, value )
	if( type( tbl ) ~= "table" ) then return 0 end

	local low, high = 1, #tbl
	while( high >= low ) do
		local middle = math.floor(( low + high )/2 + 0.5 )
		if( tbl[ middle ] < value ) then
			low = middle + 1
		elseif( tbl[ middle ] > value ) then
			high = middle - 1
		elseif( tbl[ middle ] == value ) then
			return middle
		end
	end
	return 0
end

function pen.t.is_unarray( tbl )
	return pen.t.count( tbl ) ~= #tbl
end

function pen.t.unarray( tbl, dft )
	if( not( pen.vld( tbl ))) then return {} end

	local new_tbl, n = {}, 1
	if( pen.t.is_unarray( tbl )) then
		for k,v in pairs( tbl ) do
			new_tbl[n] = { k, v }; n = n + 1
		end
	else
		for i,v in ipairs( tbl ) do
			if( type( v ) == "table" ) then
				if( v[1] ~= nil ) then new_tbl[v[1]] = v[2] or dft or i end
			else new_tbl[v] = dft or i end
		end
	end
	return new_tbl
end

function pen.t.get( tbl, id, custom_key, will_nuke, default )
	local default = default or ( type(( tbl or {})[1]) == "table" and {} or 0 )
	if( not( pen.vld( tbl ) and pen.vld( id ))) then return default end

	local out, tbl_id = {}, nil
	local key = custom_key or "id"
	local is_multi = type( id ) == "table"
	id = pen.t.unarray( pen.get_hybrid_table( id ))
	for i,v in ipairs( tbl ) do
		local check = pen.get_hybrid_table( v, true )
		if( id[ check[key] or 0 ] or id[ check[1] or 0 ]) then
			tbl_id = i
			table.insert( out, ( will_nuke or false ) and tbl_id or v )
			if( not( is_multi )) then break end
		end
	end
	
	if( not( will_nuke )) then return is_multi and out or ( out[1] or default ), tbl_id end
	for i = #out,1,-1 do table.remove( tbl, out[i]) end
end

function pen.t.get_max( tbl )
	local best = { 0, 0 }
	for k,v in pairs( tbl ) do
		if( best[2] < v ) then best = { k, v } end
	end
	return unpack( best )
end

function pen.t.get_most( tbl )
	local count = {}
	for k,v in pairs( tbl ) do
		count[k] = ( count[k] or 0 ) + 1
	end
	return pen.t.get_max( count )
end

function pen.t.add( a, b )
	if( pen.vld( a ) and pen.vld( b )) then
		local n = #a + 1
		if( pen.t.is_unarray( a )) then
			for k,v in pairs( b ) do
				if( a[k] == nil ) then a[k] = v end
			end
		else
			for i,v in ipairs( b ) do
				a[n] = v; n = n + 1
			end
		end
	else a = b or a end
	return a or {}
end

function pen.t.add_dynamic( tbl, fields ) --thanks to ImmortalDamned
    return setmetatable( tbl, {
        __index = function( _, k )
            local f = fields[k]
            return f and f()
        end
    })
end

function pen.t.insert_new( tbl, new )
	for i,v in ipairs( tbl ) do
		if( v == new ) then return end
	end
	table.insert( tbl, new )
end

function pen.t.clone( orig, copies )
	if( type( orig ) ~= "table" ) then return orig end
	
	local copy = {}
    copies = copies or {}
	if( copies[ orig ] == nil ) then
		copies[ orig ] = copy
		for orig_key,orig_value in pairs( orig ) do
			copy[ pen.t.clone( orig_key, copies )] = pen.t.clone( orig_value, copies )
		end
		setmetatable( copy, pen.t.clone( getmetatable( orig ), copies ))
	else copy = copies[ orig ] end
    return copy
end

function pen.t.pack( data )
	if( not( pen.vld( data ))) then
		return type( data or "" ) == "string" and {} or pen.DIV_1
	end
	
	local function ser( tbl )
		return pen.DIV_1..pen.t.loop_concat( tbl, function( i, cell )
			if( type( cell ) == "table" ) then
				return { pen.DIV_2, pen.t.loop_concat( cell, function( e, v )
					return { type( v ) == "table" and "\0" or pen.v2s( v, nil, nil, true ), pen.DIV_2 }
				end), pen.DIV_1 }
			else return { pen.v2s( cell, nil, nil, true ), pen.DIV_1 } end
		end)
	end
	local function dser( str )
		return pen.cache({ "table_pack", str }, function()
			if( string.find( str, table.concat({ "^", pen.DIV_1, ".+", pen.DIV_1, "$" })) == nil ) then return {} end
			
			local out = {}
			for cell in string.gmatch( str, pen.ptrn( 1 )) do
				local file = {}
				if( string.sub( cell, 1, 1 ) == pen.DIV_2 ) then
					for v in string.gmatch( cell, pen.ptrn( 2 )) do
						table.insert( file, pen.s2v( v ))
					end
				else file = pen.s2v( cell ) end
				table.insert( out, file )
			end
			return out
		end, { reset_frame = pen.CACHE_RESET_DELAY })
	end

	if( type( data ) == "table" ) then
		return ser( data )
	else return dser( data ) end
end

function pen.t.parse( data, is_pretty, full_precision )
	if( not( pen.vld( data ))) then
		return type( data or "" ) == "string" and {} or ""
	end
	
	local function ser( tbl ) --special thanks to ImmortalDamned
		if( type( tbl ) == "table" ) then
			local out = { "{" }
			local i, l = 1, pen.t.count( tbl )
			local is_unarray = pen.t.is_unarray( tbl )
			for k,v in ( is_unarray and pen.t.order or ipairs )( tbl ) do
				out = pen.t.add( out, { "[", ser( k ), "]=", ser( v ), i < l and "," or "" })
				i = i + 1
			end
			table.insert( out, "}" )
			return table.concat( out )
		else return pen.v2s( tbl, is_pretty, full_precision ) end
	end
	local function dser( str )
		return pen.cache({ "table_parse", pen.key_me( str, true )}, function()
			if( string.find( str, "^{.+}$" ) == nil ) then return {} end
			str = ","..string.sub( string.sub( str, 2, -1 ), 1, -2 )..",["
			
			local name_pattern = "^%[\"?.-\"?%]="
			local function s2n( s )
				local name = string.sub( s, string.find( s, name_pattern ))
				return pen.s2v( string.sub( name, 2, -3 ))
			end
			
			local out = {}
			for v in string.gmatch( str, "%[[^%]]+]=%b{}" ) do --huge thanks to dextercd and nphhpn
				local a,b = string.find( str, v, 1, true )
				str = string.sub( str, 1, a - 1 )..string.sub( str, b + 1, -1 )
				out[ s2n( v )] = dser( string.gsub( v, name_pattern, "" ))
			end
			local l_pos, r_pos = 0, 0
			str = string.gsub( str, ",,+", "," )
			while( l_pos ~= nil ) do
				local v = ""
				l_pos, r_pos = string.find( str, ",%[.-,%[" )
				if( l_pos ~= nil ) then
					v = string.sub( str, l_pos + 1, r_pos - 2 )
					str = string.sub( str, 1, l_pos - 1 )..string.sub( str, r_pos - 1, -1 )
				else break end
				out[ s2n( v )] = pen.s2v( string.gsub( v, name_pattern, "" ))
			end
			return out
		end, { reset_frame = pen.CACHE_RESET_DELAY })
	end
	
	if( type( data ) == "table" ) then
		return ser( data )
	else return dser( data ) end
end

function pen.t.order( tbl, func )
    local out, n = {}, 1
    for k,v in pairs( tbl ) do
        out[n] = k; n = n + 1
    end
    table.sort( out, func or function( a, b )
		return tostring( a ) < tostring( b )
	end)
	
    local i = 0
    return function()
        i = i + 1
        if( out[i] ~= nil ) then
            return out[i], tbl[ out[i]]
        end
    end
end

function pen.t.print( tbl )
	print( pen.t.parse( tbl, true ))
end

function pen.hallway( func )
	return func()
end

function pen.catch( func, input, fallback, no_unpack )
	local out = nil
	if( not( no_unpack )) then
		out = { pcall( func, unpack( input or {}))}
	else out = { pcall( func, input )} end
	if( out[1]) then table.remove( out, 1 ); return unpack( out ) end
	if( not( pen.c.silent_catch )) then print( out[2]) end
	if( pen.vld( fallback )) then return unpack( fallback ) end
end

function pen.cache( structure, update_func, data )
	data = data or {}
	data.reset_count = data.reset_count or 9999
	data.reset_delay = data.reset_delay or 60
	data.reset_frame = data.reset_frame or 0
	data.force_update = data.force_update or false
	data.always_update = data.always_update or false

	local name = structure[1]
	pen.c[ name ] = pen.c[ name ] or {}
	pen.c[ name ].cache_reset_count = pen.c[ name ].cache_reset_count or 0
	pen.c[ name ].cache_reset_frame = pen.c[ name ].cache_reset_frame or 0

	local frame_num = GameGetFrameNum()
	pen.c.cache_access = pen.c.cache_access or {}
	pen.c.cache_access[ name ] = pen.c.cache_access[ name ] or {}
	pen.c.cache_access[ name ][ structure[2]] = frame_num

	local is_too_many = data.reset_count > 0 and pen.c[ name ].cache_reset_count > data.reset_count
	local is_too_long = data.reset_frame > 0 and pen.c[ name ].cache_reset_frame < frame_num
	if( data.reset_now or ( update_func ~= nil and ( is_too_many or is_too_long ))) then
		local amount = 0
		for n,v in pairs( pen.c[ name ]) do
			local delta = frame_num - ( pen.c.cache_access[ name ][ n ] or frame_num )
			if( delta > data.reset_delay ) then pen.c[ name ][ n ] = nil; amount = amount + 1 end
		end
		
		if( is_too_long ) then pen.c.cache_access[ name ] = nil end
		pen.c[ name ].cache_reset_count = pen.c[ name ].cache_reset_count - amount
		if( is_too_long ) then pen.c[ name ].cache_reset_frame = frame_num + data.reset_frame end
	end

	local the_one = pen.c[ name ]
	for i = 2,( #structure - 1 ) do
		the_one[ structure[i]] = the_one[ structure[i]] or {}
		the_one = the_one[ structure[i]]
	end

	local val = structure[ #structure ]
	if( data.always_update ) then
		local new_val = { update_func( the_one[ val ])}
		if( pen.vld( new_val )) then the_one[ val ] = new_val end
	elseif(( data.force_update or the_one[ val ] == nil ) and update_func ~= nil ) then
		local new_val = { update_func()}
		if( not( pen.vld( new_val ))) then return end
		the_one[ val ], pen.c[ name ].cache_reset_count = new_val, pen.c[ name ].cache_reset_count + 1
	end
	return unpack( the_one[ val ] or {})
end

function pen.chrono( func, input, storage_comp, name )
	local check = GameGetRealWorldTimeSinceStarted()*1000
	if( func == nil ) then
		if( pen.c.chrono_memo ) then
			print(( check - pen.c.chrono_memo ).."ms" )
			pen.c.chrono_memo = nil
		else pen.c.chrono_memo = check end
		return
	end

	check = GameGetRealWorldTimeSinceStarted()*1000 - check
	
	local out = { func( unpack( pen.get_hybrid_table( input )))}
	if( pen.vld( storage_comp, true )) then
		pen.magic_comp( storage_comp, { value_string = function( old_val )
			return table.concat({ old_val, name, pen.DIV_1, check, pen.DIV_1 })
		end})
	else print( check.."ms" ) end
	return unpack( out )
end

function pen.init_pipeline( data, value )
	local ctrl_body = pen.get_ctrl()

	if( pen.vld( data )) then
		value = pen.get_hybrid_table( value )

		local id = tonumber( GlobalsGetValue( data.index, "0" ))
		GlobalsSetValue( data.index, id + 1 )

		local storage_request = pen.magic_storage( ctrl_body, "request_"..data.name )
		local request = ComponentGetValue2( storage_request, "value_string" )
		ComponentSetValue2( storage_request, "value_string",
			table.concat({ request, pen.DIV_2, data.name, id, pen.DIV_2, value[1], pen.DIV_2, pen.DIV_1 }))
		return pen.magic_storage( ctrl_body, "free", {
			name = data.name..id, value_string = value[2] or "",
		}, true )
	end

	for name,data in pairs( pen.INIT_THREADS ) do
		local storage_request = pen.magic_storage( ctrl_body, "request_"..data.name )
		local request = pen.t.pack( ComponentGetValue2( storage_request, "value_string" ))
		if( pen.vld( request )) then
			for i,v in ipairs( request ) do
				local storage_file = pen.magic_storage( ctrl_body, v[1])
				data.func( v[2], ComponentGetValue2( storage_file, "value_string" ))
				ComponentSetValue2( storage_file, "name", "free" )
				ComponentSetValue2( storage_file, "value_string", "" )
			end
			ComponentSetValue2( storage_request, "value_string", pen.DIV_1 )
		end
	end
end

--[TEXT]
function pen.ptrn( id )
	return table.concat({ "([^", type( id ) == "number" and pen[ "DIV_"..( id or 1 )] or tostring( id ), "]+)" }) --special thanks to Copi
end
function pen.ctrn( str, marker, is_unarrayed )
	local t = {}
	for word in string.gmatch( str, pen.ptrn( marker or "%s" )) do
		if( not( is_unarrayed )) then
			table.insert( t, pen.t2t( word, true ))
		else t[ word ] = 1 end
	end
	return t
end

function pen.capitalizer( str )
	return string.gsub( string.gsub( tostring( str ), "^%a", string.upper ), "%s%a", string.upper )
end
function pen.despacer( str )
	return string.gsub( tostring( str ), "%s+$", "" )
end

function pen.get_tiny_num( num, no_subzero )
	if( num < 0 and not( no_subzero )) then
		return "∞"
	else num = math.max( num, 0 ) end
	
	if( num < 100000 ) then
		local ender = { 3, "K" }
		local sstr = string.format( "%.0f", num )
		if( num < 1000 ) then ender = { 0, "" } end
		return string.sub( sstr, 1, #sstr - ender[1])..ender[2]
	else return "∞" end
end
function pen.get_short_num( num, no_subzero, force_sign )
	if( num < 0 and not( no_subzero )) then
		return "∞"
	elseif( no_subzero ~= 1 ) then
		num = math.max( num, 0 )
	end

	local real_num = num
	num = math.abs( num )
	if( num < 999e12 ) then
		if( num >= 10 ) then
			local ender = { 12, "T" }
			if( num < 10^4 ) then
				ender = { 0, "" }
			elseif( num < 10^6 ) then
				ender = { 3, "K" }
			elseif( num < 10^9 ) then
				ender = { 6, "M" }
			elseif( num < 10^12 ) then
				ender = { 9, "B" }
			end

			local sstr = string.format( "%.0f", real_num )
			num = string.sub( sstr, 1, #sstr - ender[1])..ender[2]
		else num = string.gsub( string.format( "%.3f", real_num ), "%.*0+$", "" ) end
	elseif( num < 9e99 ) then
		num = tostring( string.format("%e", real_num ))
		local _,pos = string.find( num, "+", 1, true )
		num = table.concat({
			string.sub( num, string.find( num, "^%-*%d" )),
			"e",
			string.sub( 100 + tonumber( string.sub( num, pos + 1, #num )), 2 )
		})
	else return "∞" end

	return (( force_sign and real_num > 0 ) and "+" or "" )..num
end

function pen.w2c( word, on_char, do_pre, on_iter )
	local num, letter_id = 0, 0
	for c in string.gmatch( word, "." ) do
		if( do_pre ~= false and on_iter ~= nil ) then
			on_iter()
		end

		if( on_char ~= nil ) then
			num = bit.lshift( num, 10 ) + string.byte( c )

			local char_id = pen.BYTE_TO_ID[ num ]
			if( char_id ) then
				num, letter_id = 0, letter_id + 1
				if( on_char( char_id, letter_id )) then
					break
				end
			end
		end

		if( do_pre ~= true and on_iter ~= nil ) then
			on_iter()
		end
	end
end

function pen.t2t( str, is_post )
	if( is_post ) then str = string.gsub( string.gsub( str, "^ +", "" ), " +$", "" ); return str end
	str = string.gsub( string.gsub( str, "\t", "" ), "\r\n", "\n" ); return str
end
function pen.t2l( str, string_indexed )
	return pen.ctrn( pen.t2t( str ), "\n", string_indexed )
end
function pen.t2w( str, is_raw )
	if( is_raw ) then return { pen.t2t( str, true )} end
	return pen.ctrn( str )
end

function pen.magic_byte( char ) --https://github.com/meepen/Lua-5.1-UTF-8/blob/master/utf8.lua
	local function s2b( str )
		local function strRelToAbs( str, ... )
			local args = {...}
			for k,v in ipairs( args ) do
				args[k] = v > 0 and v or #str + v + 1
			end
			return unpack( args )
		end
		local function decode( str, startPos )
			startPos = strRelToAbs( str, startPos or 1 )
			
			local b1 = string.byte( str, startPos, startPos )
			if( b1 < 0x80 ) then return startPos, startPos end
			if( b1 > 0xF4 or b1 < 0xC2 ) then return end
			local endPos = startPos + b1 >= 0xF0 and 3 or
									  b1 >= 0xE0 and 2 or
									  b1 >= 0xC0 and 1
			for _,bX in ipairs({ string.byte( str, startPos + 1, endPos )}) do
				if( bit.band( bX, 0xC0 ) ~= 0x80 ) then return end
			end
			return startPos, endPos
		end

		local ret = {}
		local startPos, endPos = strRelToAbs( str, 1, 1 )
		repeat
			local seqStartPos, seqEndPos = decode( str, startPos )
			startPos = seqEndPos + 1
			local len = seqEndPos - seqStartPos + 1
			if( len ~= 1 ) then
				local cp = 0
				local b1 = string.byte( str, seqStartPos )
				for i = seqStartPos + 1, seqEndPos do
					local bX = string.byte( str, i )
					cp = bit.bor( bit.lshift( cp, 6 ), bit.band( bX, 0x3F ))
					b1 = bit.lshift( b1, 1 )
				end
				table.insert( ret, bit.bor( cp, bit.lshift( bit.band( b1, 0x7F ), 5*( len - 1 ))))
			else table.insert( ret, string.byte( str, seqStartPos )) end
		until( seqEndPos >= endPos )
		return unpack( ret )
	end
	local function b2s( bte )
		if( bte < 0x80 ) then
			return string.char( bte )
		elseif( bte < 0x800 ) then
			return string.char(
				bit.bor( 0xC0, bit.band( bit.rshift( bte, 6 ), 0x1F )),
				bit.bor( 0x80, bit.band( bte, 0x3F )))
		elseif( bte < 0x10000 ) then
			return string.char(
				bit.bor( 0xE0, bit.band( bit.rshift( bte, 12 ), 0x0F )),
				bit.bor( 0x80, bit.band( bit.rshift( bte, 6 ), 0x3F )),
				bit.bor( 0x80, bit.band( bte, 0x3F )))
		else
			return string.char(
				bit.bor( 0xF0, bit.band( bit.rshift( bte, 18 ), 0x07 )),
				bit.bor( 0x80, bit.band( bit.rshift( bte, 12 ), 0x3F )),
				bit.bor( 0x80, bit.band( bit.rshift( bte, 6 ), 0x3F )),
				bit.bor( 0x80, bit.band( bte, 0x3F )))
		end
	end

	return pen.cache({ "char_byting", char }, function()
		if( type( char ) == "string" ) then
			return s2b( char )
		else return b2s( char ) end
	end, { reset_count = 0 })
end

function pen.font_cancer( font, is_huge )
	if( not( pen.vld( font ))) then
		local default = "data/fonts/font_pixel_noshadow.xml"
		if( GameHasFlagRun( pen.FLAG_FANCY_FONT )) then
			default = "data/fonts/generated/notosans_ko_24.bin" end 
		if( is_huge == true ) then
			default, is_huge = "data/fonts/font_pixel_huge.xml", 3
		elseif( is_huge == false ) then
			default, is_huge = "data/fonts/font_small_numbers.xml", 2
		else is_huge = 1 end
		font = ( pen.FONT_MAP[ GameTextGet( "$current_language" )] or {})[ is_huge ] or default
		font = ( pen.t.unarray( pen.t.pack( GlobalsGetValue( pen.GLOBAL_FONT_REMAP, "" ))) or {})[ font ] or font
	end
	return font, string.find( font, "%.bin$", 1 ) == nil, pen.FONT_SPACING[ font ] or 0
end

function pen.get_char_dims( c, id, font )
	id = id or pen.magic_byte( c )
	
	local is_pixel_font, line_offset = false, 0
	font, is_pixel_font, line_offset = pen.font_cancer( font )
	return pen.cache({ "char_dims", id, font }, function()
		local w, h = pen.get_text_dims( c or pen.magic_byte( id ), font, is_pixel_font )
		return w, h - line_offset
	end, { reset_count = 0 })
end

function pen.get_char_count( str )
	local total = 0
	pen.w2c( str, function( char_id, letter_id ) total = letter_id end )
	return total
end

function pen.text_defancifier( str )
	local markers = pen.MARKER_FANCY_TEXT
	local new_str, gotcha, is_fancy = str, 0, false
	for i = 1,#markers do
		new_str, gotcha = string.gsub( new_str, markers[i], "" )
		is_fancy = is_fancy or ( gotcha or 0 ) > 0 end
	if( not( is_fancy )) then return new_str, {} end
	
	local fancy_list = {}
	local l_pos, r_pos, drift = 0, 0, 0
	local pos, is_going = { 1, 1, 1 }, true
	while( is_going ) do
		is_going = false
		for i = 1,#markers do
			l_pos, r_pos = string.find( str, markers[i], pos[i])
			if( l_pos ) then
				pos[i], is_going = r_pos, true
				local marker = string.sub( str, l_pos, r_pos )
				table.insert( fancy_list, { l_pos, marker, r_pos - l_pos + 1 })
			end
		end
	end
	
	table.sort( fancy_list, function( a, b )
		return a[1] < b[1] end)
	for i,marker in ipairs( fancy_list ) do
		fancy_list[i][1] = marker[1] - drift
		drift = drift + marker[3]
	end
	return new_str, fancy_list
end

function pen.liner( text, length, height, font, data )
	data = data or {}
	data.nil_val = data.nil_val or "[NIL]"
	data.line_offset = data.line_offset or 0
	if( not( pen.vld( text ))) then text = data.nil_val end

	local is_pixel_font = false
	font, is_pixel_font = pen.font_cancer( font )
	local space_l, font_height = pen.get_char_dims( " ", nil, font )
	length, height = (( length or -1 ) > 0 and length or 99999 ) + space_l, height or -1
	if( height >= 0 ) then height = math.max( height, 1.5*font_height ) end
	
	local function do_a_word( formatted, ln, l, h, raw_word )
		local range, w = { 1, 1 }, ""
		local this_l, overlines = space_l, {}
		local word, fancy_list = pen.text_defancifier( raw_word )
		pen.w2c( word, function( id )
			w = w..string.sub( word, range[1], range[2])

			local c_w, c_h = pen.get_char_dims( nil, id, font )
			if( font_height < c_h ) then font_height = c_h end
			
			local new_l = this_l + c_w
			if( new_l > length - space_l ) then
				local drift = 0
				pen.t.loop( fancy_list, function( i, marker )
					if( range[2] >= marker[1]) then drift = drift + marker[3] end
				end)
				table.insert( overlines, range[2] + drift + 1 )
				new_l = new_l - this_l + space_l
			end
			this_l = new_l
			
			range[1] = range[2] + 1
		end, false, function()
			range[2] = range[2] + 1
		end)
		
		local new_l = #overlines > 0 and ( length + 1 ) or ( l + this_l )
		if( new_l > length and ln ~= "" ) then
			local new_h = h + font_height + data.line_offset
			if( height > 0 and new_h > height ) then return end
			table.insert( formatted, { ln, l })
			ln, new_l, h = "", new_l - l, new_h
		end
		
		if( pen.vld( fancy_list )) then w = raw_word end

		for k,overpos in ipairs( overlines ) do
			local new_h = h + font_height + data.line_offset
			if( height > 0 and new_h > height ) then break end --is_complicated = 1
			
			h = new_h
			table.insert( formatted, { string.sub( w, overlines[ k - 1 ] or 0, overpos - 1 ), length })
			if( k == #overlines ) then w, new_l = string.sub( w, overpos, -1 ), this_l end
		end
		
		-- if( is_compicated == 1 ) then return end
		return table.concat({ ln, ( #ln > 0 and " " or "" ), w }), new_l, h
	end

	return pen.cache({ "font_liner", length, height, text, font }, function()
		local full_text, formatted, max_l, h = text, {}, 0, 0
		full_text = table.concat({ pen.DIV_0,
			string.gsub( pen.t2t( string.gsub( string.gsub( full_text, " + ", "\t" ), "\t", pen.MARKER_TAB )), "\n", pen.DIV_0 ),
		pen.DIV_0 })

		for paragraph in string.gmatch( full_text, pen.ptrn( 0 )) do
			local line, l = "", 0
			if( paragraph ~= "" ) then
				for i,raw_word in ipairs( pen.t2w( pen.t2t( paragraph, true ), data.aggressive )) do
					local new_line, new_l, new_h = do_a_word( formatted, line, l, h, raw_word )
					if( new_line ) then
						line, l, h = new_line, new_l, new_h
					else break end
				end
			end
			
			local new_h = h + font_height + data.line_offset
			if( height > 0 and new_h > height ) then break end
			table.insert( formatted, { line, l })
			h = new_h
		end
		
		for i,line in ipairs( formatted ) do
			if( line[2] > max_l ) then max_l = line[2] end
			
			local tab_plug = ""
			local tab_a = string.sub( pen.MARKER_TAB, 1, 1 )
			local tab_b = string.sub( pen.MARKER_TAB, 2, 2 )
			tab_a = pen.get_char_dims( tab_a, pen.magic_byte( tab_a ), font )
			tab_b = pen.get_char_dims( tab_b, pen.magic_byte( tab_b ), font )
			
			for i = 1,math.floor(( tab_a + tab_b )/space_l ) do tab_plug = tab_plug.." " end
			formatted[i] = string.gsub( line[1], pen.MARKER_TAB, tab_plug )
		end
		
		h = h - ( is_pixel_font and 2 or 0 )
		return formatted, { max_l - space_l, h }, font_height + data.line_offset
	end, { reset_frame = pen.CACHE_RESET_DELAY })
end

function pen.magic_translate( text ) 
	return pen.t.loop_concat( pen.t2w( pen.get_hybrid_function( text )), function( i, mark )
		return { i == 1 and "" or " ", GameTextGetTranslatedOrNot( mark )}
	end)
end

function pen.magic_append( to_file, from_file )
	local marker = pen.MARKER_MAGIC_APPEND
	local a, b = pen.magic_read( to_file ), pen.magic_read( from_file )
	if( pen.magic_write ) then pen.magic_write( to_file, string.gsub( a, marker, table.concat({ b, "\n\n\n", marker }))) end
end

function pen.add_herds( new_file, default, overrides )
	overrides = pen.t.unarray( overrides or {})
	local herd, old_file = {}, "data/genome_relations.csv"

	local raw_herd = pen.t2l( pen.magic_read( old_file ))
	local header = pen.ctrn( raw_herd[1], "," )
	for i = 2,#raw_herd do
		local line = pen.ctrn( raw_herd[i], "," )
		local name = line[1]
		
		herd[ name ] = {}
		for e = 2,#line do
			herd[ name ][ header[e]] = tonumber( line[e])
		end
	end
	if( new_file == nil ) then return herd end

	raw_herd = pen.t2l( pen.magic_read( new_file ))
	local new_header = pen.ctrn( raw_herd[1], "," )
	for i = 2,#raw_herd do
		local line = pen.ctrn( raw_herd[i], "," )
		local name = line[1]

		if( herd[ name ] == nil ) then overrides[ name ] = 0 end
		herd[ name ] = herd[ name ] or {}
		for e = 2,#line do
			if(( overrides[ name ] ~= nil or overrides[ new_header[e]] ~= nil ) and line[e] ~= "_" ) then
				herd[ name ][ new_header[e]] = tonumber( line[e])
			end
		end
	end
	
	local function herd_sorter( tbl )
		return pen.t.order( tbl, function( a,b )
			local _,ida = pen.t.get( header, a )
			local _,idb = pen.t.get( header, b )
			if( ida == nil and idb ~= nil ) then
				return false
			elseif( ida ~= nil and idb == nil ) then
				return true
			elseif( ida ~= nil and idb ~= nil ) then
				return ida < idb
			else return a < b end
		end)
	end

	new_header, new_file = { "HERD" }, { "\n" }
	for h1,_ in herd_sorter( herd ) do
		table.insert( new_file, h1 )
		for h2,_ in herd_sorter( herd ) do
			herd[ h1 ] = herd[ h1 ] or {}
			if( herd[ h1 ][ h2 ] == nil ) then
				herd[ h1 ][ h2 ] = default( herd, h1, h2 )
			end
			table.insert( new_file, "," )
			table.insert( new_file, herd[ h1 ][ h2 ])
		end
		table.insert( new_file, "\n" )
		table.insert( new_header, "," )
		table.insert( new_header, h1 )
	end
	if( pen.magic_write ) then
		pen.magic_write( old_file, table.concat( new_header )..table.concat( new_file ))
	end

	return herd
end

function pen.add_shaders( shader_path )
	local shader_old = "data/shaders/post_final.frag"
	local file_old = pen.magic_read( shader_old )
	local markers_old = {
		--[[ ******[UNIFORMS]****** ]]"// %-*\r\n// utilities",
		--[[ ******[FUNCTIONS]****** ]]"// trip \"fractals\" effect. this is based on some code from ShaderToy, which I can't find anymore.",
		--[[ ******[WORLD]****** ]]"#ifdef TRIPPY\r\n	// drunk doublevision",
		--[[ ******[OVERLAY]****** ]]"// ============================================================================================================\r\n// additive overlay ===========================================================================================",
	}

	local file_new = pen.magic_read( shader_path ).."\n\n******[EOF]******\n"
	for i,segment in ipairs( pen.ctrn( file_new, "******[%S-]******" )) do
		if( pen.vld( string.gsub( segment, "%s", "" )) and markers_old[i] ~= nil ) then
			file = string.gsub( file, markers_old[i], table.concat({ markers_old[i], "\n", segment }))
		end
	end
	if( pen.magic_write ) then pen.magic_write( shader_old, file ) end
end

function pen.add_translations( path )
	local main = "data/translations/common.csv"
	local file = string.gsub( string.gsub( pen.magic_read( path ), "\r", "" ), "\n\n+", "\n" )
	if( pen.magic_write ) then pen.magic_write( main, pen.magic_read( main )..string.gsub( file, "^[^\n]*\n", "" )) end
end

--[ECS]
function pen.get_ctrl()
	local world_id = GameGetWorldStateEntity()
	local ctrl_body = pen.get_child( world_id, "pen_ctrl" )
	if( pen.is_game_restarted()) then
		EntityKill( ctrl_body )
	elseif( pen.vld( ctrl_body, true )) then return ctrl_body end
	
	ctrl_body = EntityCreateNew( "pen_ctrl" )
	EntityAddTag( ctrl_body, "pen_ctrl" )
	EntityAddChild( world_id, ctrl_body )
	EntityAddComponent2( ctrl_body, "InheritTransformComponent" )
	for name,data in pairs( pen.INIT_THREADS ) do
		pen.magic_storage( ctrl_body, "request_"..data.name, {
			name = "request_"..data.name, value_string = pen.DIV_1, }, true )
	end
	return ctrl_body
end

function pen.get_hooman( is_dynamic ) --stolen from eba 😋
	if( is_dynamic ) then
		local cam_x, cam_y = GameGetCameraPos()
		return EntityGetClosestWithTag( cam_x, cam_y, "player_unit" )
			or EntityGetClosestWithTag( cam_x, cam_y, "polymorphed_player" )
	else return ( EntityGetWithTag( "player_unit" ) or EntityGetWithTag( "polymorphed_player" ) or {})[1] end
end

function pen.child_play( entity_id, func, sort_func )
	if( not( pen.vld( entity_id, true ))) then return end
	local children = EntityGetAllChildren( entity_id )
	if( not( pen.vld( children ))) then return end

	if( pen.vld( sort_func )) then
		table.sort( children, sort_func ) end
	return pen.t.loop( children, function( i, child )
		return func( entity_id, child, i )
	end)
end

function pen.child_play_full( dude_id, func, args )
	local ignore = func( dude_id, args )
	return pen.child_play( dude_id, function( parent, child )
		if( not( ignore )) then
			return pen.child_play_full( child, func, args )
		else return func( child, args ) end
	end)
end

function pen.get_child( entity_id, tag, ignore_id )
	return pen.child_play( entity_id, function( parent, child )
		if( child ~= ignore_id and ( EntityGetName( child ) == tag or EntityHasTag( child, tag ))) then
			return child
		end
	end)
end

function pen.catch_comp( comp_name, field_name, index, func, args, forced )
	local will_set = index == "set"
	pen.c.catch_comp = pen.c.catch_comp or {}
	pen.c.catch_comp[ comp_name ] = pen.c.catch_comp[ comp_name ] or {}
	pen.c.catch_comp[ comp_name ][ field_name ] = pen.c.catch_comp[ comp_name ][ field_name ] or {}

	local v = pen.c.catch_comp[ comp_name ][ field_name ][ index ]
	if( forced ) then v = nil end

	local check_val = 0
	if( pen.CANCER_COMPS[ comp_name ] ~= nil ) then
		check_val = pen.CANCER_COMPS[ comp_name ][ field_name ] or (( index == "obj" ) and -2 or check_val )
	end

	local out = { v }
	if( type( check_val ) == "function" ) then
		out = { check_val( args[1], args[#args], index )}
	elseif( check_val < 0 and index == "obj" ) then
		out[1] = check_val == -1
	elseif( check_val > 0 and ( check_val > 2 or not( will_set ))) then
		out[1] = check_val == 2
	end
	
	v = out[1]
	if( not( pen.vld( v ))) then
		pen.c.silent_catch = true
		
		out = { pen.catch( func, args )}
		v = out[1] ~= nil --cannot check write
		table.insert( out, 1, v )

		pen.c.catch_comp[ comp_name ][ field_name ][ index ] = v or will_set
		pen.c.silent_catch = nil
	end
	
	return unpack( out )
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
	if( not( pen.vld( id, true ))) then return end

	data = pen.get_hybrid_table( data, true )
	if( pen.t.is_unarray( data )) then
		for field,value in pairs( data ) do
			local v = value
			if( type( v ) == "function" ) then
				v = { v( pen.magic_comp( id, field ))}
			else v = pen.get_hybrid_table( v ) end
			table.insert( v, 1, field )
			table.insert( v, 1, id )
			pen.magic_comp( unpack( v ))
		end
	elseif( type( func or 0 ) ~= "function" ) then
		local will_get = func == nil
		local is_object = data[2] ~= nil
		local method = table.concat({ "Component", is_object and "Object" or "", will_get and "Get" or "Set", "Value2" })

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
		return pen.t.loop( EntityGetComponentIncludingDisabled( unpack({ id, data[1], data[2]})), function( i, comp )
			local edit_tbl = {}
			local done = func( comp, edit_tbl, ComponentGetIsEnabled( comp ))
			for field,value in pairs( edit_tbl ) do pen.magic_comp( comp, field, value ) end
			if( done ) then return comp end
		end)
	end
end

function pen.magic_storage( entity_id, name, field, value, default )
	if( default == nil ) then default = value ~= nil end
	local out = pen.t.loop( EntityGetComponentIncludingDisabled( entity_id, "VariableStorageComponent" ), function( i, comp )
		if( ComponentGetValue2( comp, "name" ) == name ) then return comp end
	end)

	if( field ~= nil ) then
		if( not( pen.vld( out, true )) and default ) then
			local v = { name = name }
			if( type( default ) ~= "boolean" ) then v[ field ] = default end
			out = EntityAddComponent2( entity_id, "VariableStorageComponent", v )
		end
		if( pen.vld( out, true )) then return pen.magic_comp( out, field, value ) end
	end
	return out
end

function pen.get_comp_data( entity_id, comp_id, mutators )
	if( not( pen.vld( comp_id, true ))) then return end

	mutators = mutators or {}
	local comp_name = ComponentGetTypeName( comp_id )
	local main_values, object_values, extra_values = {
		_enabled = ComponentGetIsEnabled( comp_id ),
		_tags = ( mutators._tags or ComponentGetTags( comp_id ))..( mutators.add_tags or "" ),
	}, {}, {}
	
	local function is_supported( field_name, is_obj )
		local f = ComponentGetValue2
		local input = { comp_id, field_name }
		if( type( is_obj or 0 ) == "string" ) then
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
			main_values[ field ] = value[1]
		else extra_values[ field ] = value end
	end
	local function get_stuff( obj )
		obj = obj or false
		local stuff = obj and ComponentObjectGetMembers( comp_id, obj ) or ComponentGetMembers( comp_id )
		for field in pairs( stuff ) do
			local is_object, forced_extra = is_supported( field, true )
			if( not( obj ) and is_object ) then
				get_stuff( field )
			elseif( is_supported( field, obj )) then
				if( obj or not( pen.vld( mutators[ field ]))) then
					local value = obj and {ComponentObjectGetValue2( comp_id, obj, field )} or {ComponentGetValue2( comp_id, field )}
					if( obj ) then
						object_values[ obj ] = object_values[ obj ] or {}
						if( not( pen.vld( mutators[ obj ])) or not( pen.vld( mutators[ obj ][ field ]))) then
							if( pen.vld( value )) then object_values[ obj ][ field ] = value end
						elseif( mutators[ obj ][ field ] ~= "[NOPE]" ) then
							object_values[ obj ][ field ] = pen.get_hybrid_table( mutators[ obj ][ field ])
						end
					elseif( pen.vld( value )) then
						set_stuff( field, value, forced_extra )
					end
				elseif( mutators[ field ] ~= "[NOPE]" ) then
					set_stuff( field, pen.get_hybrid_table( mutators[ field ]), forced_extra )
				end
			end
		end
	end

	get_stuff()

	return main_values, object_values, extra_values
end

function pen.clone_comp( entity_id, comp_id, mutators )
	if( not( pen.vld( comp_id, true ))) then return end
	local comp_name = ComponentGetTypeName( comp_id )
	if( pen.clone_comp_debug ) then print( comp_name ) end

	local main_values, object_values, extra_values = pen.get_comp_data( entity_id, comp_id, mutators )
	
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
	mutators[ entity_id ] = mutators[ entity_id ] or mutators
	local new_id = EntityCreateNew( EntityGetName( entity_id ))
	EntitySetTransform( new_id, x, y )
	
	local tags = EntityGetTags( entity_id ) or ""
	for value in string.gmatch( tags, pen.ptrn( "," )) do
		EntityAddTag( new_id, value )
	end
	pen.t.loop( EntityGetAllComponents( entity_id ), function( i, comp )
		local v = mutators[ entity_id ][ comp ] or mutators[ entity_id ][ ComponentGetTypeName( comp )]
		pen.catch( pen.clone_comp, { new_id, comp, v })
	end)
	pen.child_play( entity_id, function( parent, child )
		EntityAddChild( new_id, clone_entity( child, x, y, mutators ))
	end)
	
	if( pen.clone_comp_debug == true ) then
		for name,fields in pen.t.order( pen.c.catch_comp ) do
			print( "**************"..name )
			for field,tbl in pen.t.order( fields ) do
				if( tbl.get == false ) then print( field ) end
				if( tbl.obj == true ) then print( "OBJECT: "..field ) end
			end
		end
	end

	return new_id
end

function pen.lua_callback( entity_id, funcs, input )
	local real_GetUpdatedEntityID = GetUpdatedEntityID
	local real_GetUpdatedComponentID = GetUpdatedComponentID
	GetUpdatedEntityID = function() return entity_id end

	local got_some = false
	local frame_num = GameGetFrameNum()
	pen.t.loop( EntityGetComponentIncludingDisabled( entity_id, "LuaComponent" ), function( i, comp )
		local path = ComponentGetValue2( comp, funcs[1])
		if( not( pen.vld( path ))) then return end
		local max_count = ComponentGetValue2( comp, "execute_times" )
		local count = ComponentGetValue2( comp, "mTimesExecuted" )
		if( max_count < 1 or count < max_count ) then
			got_some = true
		else return end
		
		GetUpdatedComponentID = function() return comp end
		dofile( path ); _G[ funcs[2]]( unpack( input ))

		ComponentSetValue2( comp, "mLastExecutionFrame", frame_num )
		ComponentSetValue2( comp, "mTimesExecuted", count + 1 )
		if( ComponentGetValue2( comp, "remove_after_executed" )) then
			EntityRemoveComponent( entity_id, comp )
		end
	end)

	GetUpdatedEntityID = real_GetUpdatedEntityID
	GetUpdatedComponentID = real_GetUpdatedComponentID
	return got_some
end

function pen.get_effect( entity_id, effect_name, effect_id )
	local children = EntityGetAllChildren( entity_id )
	if( not( pen.vld( children ))) then return end
	if( pen.vld( effect_id, true )) then
		if( type( effect_id ) == "string" ) then
			dofile_once( "data/scripts/status_effects/status_list.lua" )
			_,effect_id = pen.t.get( status_effects, effect_id, "ui_name" )
		end
		
		for i,child in ipairs( children ) do			
			local effect_comp = EntityGetFirstComponentIncludingDisabled( child, "GameEffectComponent" )
			if( effect_comp ~= nil and (
				ComponentGetValue2( effect_comp, "effect" ) == effect_name or
				ComponentGetValue2( effect_comp, "causing_status_effect" ) == effect_id or
				ComponentGetValue2( effect_comp, "ragdoll_effect" ) == effect_name
			)) then return child, effect_comp, effect_id end
		end
	else
		for i,child in ipairs( children ) do
			if( EntityGetName( child ) == effect_name ) then return child end
		end
	end
end

function pen.get_active_item( entity_id )
	if( not( pen.vld( entity_id, true ))) then return end
	local inv_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "Inventory2Component" )
	if( pen.vld( inv_comp, true )) then return tonumber( ComponentGetValue2( inv_comp, "mActiveItem" ) or 0 ) end
end

function pen.reset_active_item( entity_id, saved_index, will_log )
	local inv_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "Inventory2Component" )
	if( pen.vld( inv_comp, true )) then
		ComponentSetValue2( inv_comp, "mActiveItem", 0 )
		ComponentSetValue2( inv_comp, "mActualActiveItem", 0 )
		ComponentSetValue2( inv_comp, "mInitialized", false )
		ComponentSetValue2( inv_comp, "mDontLogNextItemEquip", not( will_log ))
		if( saved_index ~= false ) then ComponentSetValue2( inv_comp, "mSavedActiveItemIndex", saved_index or 0 ) end
	end
	return inv_comp
end

function pen.get_item_owner( item_id, is_in_hand )
	if( not( pen.vld( item_id, true ))) then return end

	local parent = item_id
	while( parent ~= EntityGetRootEntity( item_id )) do
		parent = EntityGetParent( parent )
		local item_check = pen.get_active_item( parent )
		if( is_in_hand ) then
			item_check = item_check == item_id
		else item_check = pen.vld( item_check, true ) end
		if( item_check ) then return parent end
	end
end

--[UTILS]
function pen.random_bool( var )
	SetRandomSeed( GameGetFrameNum(), var )
	return Random( 1, 2 ) == 1
end
function pen.random_sign( var )
	return pen.random_bool( var ) and 1 or -1
end

function pen.setting_set( id, value )
	-- local setting_set_memo = pen.t.unarray( pen.t.pack( GlobalsGetValue( pen.GLOBAL_SETTINGS_CACHE, "" )))
	-- setting_set_memo[ id ] = GameGetFrameNum()
	-- GlobalsSetValue( pen.t.pack( pen.t.unarray( setting_set_memo )))

	ModSettingSet( id, value )
	ModSettingSetNextValue( id, value, false )
end
function pen.setting_get( id )
	-- local frame_num = GameGetFrameNum()
	-- local setting_set_memo = pen.t.unarray( pen.t.pack( GlobalsGetValue( pen.GLOBAL_SETTINGS_CACHE, "" )))
	-- pen.c.setting_get_memo = pen.c.setting_get_memo or {}
	-- pen.c.setting_get_memo[ id ] = pen.c.setting_get_memo[ id ] or 1
	-- local is_old = pen.c.setting_get_memo[ id ] <= ( setting_set_memo[ id ] or 0 )
	-- pen.c.setting_get_memo[ id ] = frame_num

	-- return pen.cache({ "settings", id }, function()
		return ModSettingGetNextValue( id ), ModSettingGet( id )
	-- end, { reset_count = 0, reset_frame = pen.CACHE_RESET_DELAY, force_update = is_old })
end

function pen.get_time( secs )
	secs = math.floor( secs )
	local mins = math.floor( secs/60 )
	secs = secs - mins*60
	local hrs = math.floor( mins/60 )
	mins = mins - hrs*60
	local t = { hrs, mins, secs }

	local out = { hrs }
	for i = 2,3 do
		table.insert( out, ":" )
		table.insert( out, string.sub( "0"..t[i], -2 ))
	end
	return table.concat( out )
end

function pen.get_seconds()
	local tm = { GameGetDateAndTimeUTC()}
	return ((((( tm[1] - 2000 )*12 + tm[2])*30 + tm[3])*24 + tm[4])*60 + tm[5])*60 + tm[6]
end

function pen.seed_gen( values )
	math.randomseed( pen.hash_me( table.concat({
		"msd", GameGetRealWorldTimeSinceStarted(), ".",
		pen.t.loop_concat( values, function( i, v )
			if( type( v ) ~= "boolean" ) then return tostring( v ) end
		end) or "",
	})))

	math.random();math.random();math.random()
	return math.random( 0, 2000000000 )
end

function pen.seeded_random( event_id, mutator, a, b, bidirectional, seed_container )
	if( seed_container ~= nil ) then
		math.randomseed( tonumber( pen.hash_me( ModSettingGetNextValue( seed_container )..pen.hash_me( event_id..tostring( mutator )))))
	else return 0 end

	math.random();math.random();math.random()
	return ( bidirectional or false ) and ( math.random( a, b*2 ) - b ) or math.random( a, b )
end

function pen.generic_random( a, b, macro_drift, bidirectional )
	if( macro_drift == nil ) then
		macro_drift = GetUpdatedEntityID() or 1
		if( macro_drift > 1 ) then
			local drft_a, drft_b = EntityGetTransform( macro_drift )
			macro_drift = { drft_a, tonumber( macro_drift ) + drft_b }
		end
	end
	
	if( type( macro_drift ) == "table" ) then macro_drift = macro_drift[1]*1000 + macro_drift[2] end
	macro_drift = math.floor( macro_drift + 0.5 )
	SetRandomSeed( math.random( GameGetFrameNum(), macro_drift ), pen.get_seconds()%macro_drift )

	Random( 1, 5 );Random( 1, 5 );Random( 1, 5 )
	return ( bidirectional or false ) and ( Random( a, b*2 ) - b ) or Random( a, b )
end

function pen.migrate( mod_id, funcs )
	local latest_version = 0
	local current_version = pen.setting_get( mod_id.."._version" ) or 1
	for version,func in pen.t.order( funcs ) do
		if( current_version < version ) then
			func( mod_id..".", current_version )
			latest_version = version
		end
	end
	
	if( latest_version == 0 ) then return end
	pen.setting_set( mod_id.."._version", latest_version )
end

function pen.is_game_restarted( is_local )
	local is_reset = not( pen.c.restart_check or false ); pen.c.restart_check = true
	if( is_reset and is_local ) then GameRemoveFlagRun( pen.FLAG_RESTART_CHECK ) end
	local is_start = GameGetRealWorldTimeSinceStarted() < 6
	if( is_start and is_reset ) then GameRemoveFlagRun( pen.FLAG_RESTART_CHECK ) end
	local is_init = SessionNumbersGetValue( "is_biome_map_initialized" ) == "0"
	local is_new = is_reset and is_init and not( GameHasFlagRun( pen.FLAG_RESTART_CHECK ))
	if( is_new ) then GameAddFlagRun( pen.FLAG_RESTART_CHECK ) end
	return is_new
end

function pen.is_inv_active( hooman )
	local is_going = false
	pen.magic_comp( hooman or pen.get_hooman(), "InventoryGuiComponent", function( comp_id, v, is_enabled )
		is_going = ComponentGetValue2( comp_id, "mActive" )
	end)
	return is_going
end

function pen.is_entity_sapient( entity_id )
	if( EntityHasTag( entity_id, "player_unit" )) then return true end
	for i,comp in ipairs( pen.AI_COMPS ) do
		if( EntityGetFirstComponentIncludingDisabled( entity_id, comp )) then return true end
	end
	return false
end

function pen.is_wand_useless( wand_id )
	if( pen.child_play( wand_id, function( parent, child )
		local item_comp = EntityGetFirstComponentIncludingDisabled( child, "ItemComponent" )
		if( pen.vld( item_comp, true ) and ComponentGetValue2( item_comp, "uses_remaining" ) ~= 0 ) then
			return true
		end
	end)) then return false end
	return true
end

function pen.get_closest( x, y, stuff, check_sight, limits, extra_check )
	limits = limits or { 0, 0, }
	local min_dist, actual_thing = -1, nil
	pen.t.loop( stuff, function( i, entity_id )
		local t_x, t_y = EntityGetTransform( pen.get_hybrid_table( entity_id )[1])
		if( check_sight and RaytracePlatforms( x, y, t_x, t_y )) then return end
		local d_x, d_y = math.abs( t_x - x ), math.abs( t_y - y )
		if( limits[1] ~= 0 and d_x > limits[1]) then return end
		if( limits[2] ~= 0 and d_y > limits[2]) then return end
		local dist = math.sqrt( d_x^2 + d_y^2 )
		if( min_dist ~= -1 and dist >= min_dist ) then return end
		if( extra_check ~= nil and not( extra_check( entity_id ))) then return end
		min_dist, actual_thing = dist, entity_id
	end)
	return actual_thing
end

function pen.get_killable( c_x, c_y, r )
	local mortal = EntityGetInRadiusWithTag( c_x, c_y, r, "mortal" ) or {}
	local hittable = EntityGetInRadiusWithTag( c_x, c_y, r, "hittable" ) or {}
	return pen.t.loop( mortal, function( i, v ) pen.t.insert_new( hittable, v ) end, true )
end

function pen.get_creature_centre( entity_id )
	local x, y = EntityGetTransform( entity_id )
	local char_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "CharacterDataComponent" )
	if( pen.vld( char_comp, true )) then y = y + ComponentGetValue2( char_comp, "buoyancy_check_offset_y" )
	else x, y = EntityGetFirstHitboxCenter( entity_id ) end
	return x, y
end

function pen.get_creature_head( entity_id )
	local x, y = EntityGetTransform( entity_id )
	local custom_off = pen.magic_storage( entity_id, "head_offset", "value_int" )
	if( pen.vld( custom_off )) then return x, y + custom_off end

	local ai_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "AnimalAIComponent" )
	local crouch_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "HotspotComponent", "crouch_sensor" )
	if( pen.vld( ai_comp, true )) then
		y = y + ComponentGetValue2( ai_comp, "eye_offset_y" )
	elseif( pen.vld( crouch_comp, true )) then
		local off_x, off_y = ComponentGetValue2( crouch_comp, "offset" )
		y = y + off_y + 3
	else x, y = EntityGetFirstHitboxCenter( entity_id ) end
	return x, y
end

function pen.get_creature_dimensions( entity_id, is_simple ) --this should work with phys bodies
	local borders = { min_x = 0, max_x = 0, min_y = 0, max_y = 0 }
	local char_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "CharacterDataComponent" )
	local has_collision = pen.vld( char_comp, true )
	if( has_collision ) then
		borders.min_x = ComponentGetValue2( char_comp, "collision_aabb_min_x" )
		borders.max_x = ComponentGetValue2( char_comp, "collision_aabb_max_x" )
		borders.min_y = ComponentGetValue2( char_comp, "collision_aabb_min_y" )
		borders.max_y = ComponentGetValue2( char_comp, "collision_aabb_max_y" )
	end

	local sprite_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "SpriteComponent", "character" )
	if( not( is_simple ) and pen.vld( sprite_comp, true )) then
		local offset_x = ComponentGetValue2( sprite_comp, "offset_x" )
		local offset_y = ComponentGetValue2( sprite_comp, "offset_y" )
		if( offset_x == 0 ) then offset_x = has_collision and ( math.abs( borders.min_x ) + math.abs( borders.max_x ))/2 or 3 end
		if( offset_y == 0 ) then offset_y = has_collision and borders.min_y or 3 end

		local temp = { min_x = -offset_x, max_x = offset_x, min_y = -offset_y, max_y = offset_y }
		for i,v in pairs( borders ) do
			if( has_collision ) then
				borders[i] = ( temp[i] + v )/2
			else borders[i] = temp[i]*( i == "max_y" and 0.5 or 1 ) end
		end
	end

	return borders
end

function pen.raytrace_entities( hooman, deadman, barrel_x, barrel_y, amount, delta_x, delta_y, is_piercing, hit_action ) --get start and end, execute function on every encountered entity, optionally compensate for loss of accuracy due to rotation
	barrel_x, barrel_y = x + barrel_x*2, y + barrel_y*2
	end_x, end_y = barrel_x + end_x, barrel_y + end_y

	local hit, hit_x, hit_y = RaytracePlatforms( barrel_x, barrel_y, end_x, end_y )

	local l_x = 0
	local l_y = 0
	local lenght = 0
	if( hit ) then
		l_x = hit_x - barrel_x
		l_y = hit_y - barrel_y
		lenght = math.sqrt(( l_x )^2 + ( l_y )^2 )
	else
		l_x = math.cos( r )*diameter
		l_y = math.sin( r )*diameter
		lenght = diameter
	end

	if( lenght > 0 ) then
		local amount = math.ceil( lenght/2 )
		local delta_x = l_x/amount
		local delta_y = l_y/amount

		local meat = get_killable_stuff( barrel_x + l_x/2, barrel_y + l_y/2, lenght/2 + 20 )
		if( #meat > 0 ) then
			for e,deadman in ipairs( meat ) do
				if( hooman ~= deadman ) then
					if( EntityGetComponent( deadman, "DamageModelComponent" ) ~= nil ) then
						local is_hostile = EntityGetComponent( deadman, "GenomeDataComponent" ) == nil or ModSettingGetNextValue( "heres_ferrei.IGNORE_LOYALTY" ) or EntityGetHerdRelation( deadman, hooman ) < 95 or GameHasFlagRun( "let_the_god_decide" )
						if( is_hostile ) then
							local e_x, e_y = EntityGetTransform( deadman )
							
							local hitbox_comp = EntityGetComponent( deadman, "HitboxComponent" ) or {}
							local hitbox_count = 1
							if( #hitbox_comp > 1 ) then
								hitbox_count = #hitbox_comp
							end
							
							local hitbox_right = 0
							local hitbox_left = 0
							local hitbox_up = 0
							local hitbox_down = 0
							local hitbox_dmg_scale = 0
							for i = 1,hitbox_count do
								if( i > #hitbox_comp ) then
									local hitbox_size = 5
									hitbox_right = hitbox_size
									hitbox_left = 0-hitbox_size
									hitbox_up = 0-hitbox_size
									hitbox_down = hitbox_size
									hitbox_dmg_scale = 1
								else
									hitbox_right = ComponentGetValue2( hitbox_comp[i], "aabb_max_x" )
									hitbox_left = ComponentGetValue2( hitbox_comp[i], "aabb_min_x" )
									hitbox_up = ComponentGetValue2( hitbox_comp[i], "aabb_min_y" )
									hitbox_down = ComponentGetValue2( hitbox_comp[i], "aabb_max_y" )
									hitbox_dmg_scale = ComponentGetValue2( hitbox_comp[i], "damage_multiplier" )
								end
								
								for k = 0,amount do
									local beam_part_x = barrel_x + delta_x*k
									local beam_part_y = barrel_y + delta_y*k
									
									if(( beam_part_x <= e_x + hitbox_right ) and ( beam_part_x >= e_x + hitbox_left ) and ( beam_part_y <= e_y + hitbox_down ) and ( beam_part_y >= e_y + hitbox_up )) then
										if( is_piercing ) then
											hit_action( hooman, deadman, k, beam_part_x, beam_part_y, hitbox_dmg_scale )
										else
											return deadman, k
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

function pen.get_spell( action_id ) --isolate globals
	dofile_once( "data/scripts/gun/gun_enums.lua" )
	dofile_once( "data/scripts/gun/gun_actions.lua" )
	return pen.t.get( actions, action_id )
end

function pen.get_card_id()
	if( dont_draw_actions or reflecting ) then return end
	if( not( pen.vld( current_action ))) then return end
	if( not( pen.vld( current_action.deck_index ))) then return end

	local hooman = GetUpdatedEntityID()
	if( not( pen.vld( hooman, true ))) then return end
	local wand_id = pen.get_active_item( hooman )
	if( not( pen.vld( wand_id, true ))) then return end

	local abil_comp = EntityGetFirstComponentIncludingDisabled( wand_id, "AbilityComponent" )
	if( not( pen.vld( abil_comp, true ) and ComponentGetValue2( abil_comp, "use_gun_script" ))) then return end
	local spells = EntityGetAllChildren( wand_id ) or {}

	local index_offset = 1
	pen.t.loop( spells, function( i, spell_id )
		local item_comp = EntityGetFirstComponentIncludingDisabled( spell_id, "ItemComponent" )
		if( pen.vld( item_comp, true ) and ComponentGetValue2( item_comp, "permanently_attached" )) then
			index_offset = index_offset + 1
		end
	end)
	return spells[ current_action.deck_index + index_offset ]
end

function pen.get_tinker_state( hooman, x, y )
	local got_some = false
	local effect = "NO_WAND_EDITING"
	local function check_effect( entity_id )
		if( not( got_some )) then
			got_some = GameGetGameEffectCount( hooman, effect ) > 0
		else return true end
	end
	
	check_effect( hooman )
	pen.child_play( hooman, check_effect )
	if( got_some ) then return false end
	effect = "EDIT_WANDS_EVERYWHERE"
	check_effect( hooman )
	pen.child_play( hooman, check_effect )
	if( got_some ) then return true end

	return pen.t.loop( EntityGetWithTag( "workshop" ), function( i, workshop )
		local w_x, w_y = EntityGetTransform( workshop )
		local box_comp = EntityGetFirstComponent( workshop, "HitboxComponent" )
		if( pen.check_bounds({ x, y }, box_comp, { w_x, w_y })) then
			return true
		end
	end) or false
end

function pen.get_spell_data( spell_id )
	local function clean_my_gun()
		ACTION_MANA_DRAIN_DEFAULT, ACTION_DRAW_RELOAD_TIME_INCREASE = 10, 0
		ACTION_UNIDENTIFIED_SPRITE_DEFAULT = "data/ui_gfx/gun_actions/unidentified.png"
	
		mana, state_cards_drawn = 0, 0
		c, shot_effects, gun = {}, {}, {}
		deck, hand, discarded = {}, {}, {}
		reflecting, current_action, state_from_game = false, nil, nil
		current_reload_time, current_projectile, active_extra_modifiers = 0, nil, {}
		reloading, first_shot, start_reload, got_projectiles = false, true, false, false
		state_shuffled, state_discarded_action, state_destroyed_action, playing_permanent_card = false, false, false, false
	
		use_game_log = false
		ConfigGun_Init( gun )
		current_reload_time = 0
		shot_structure, recursion_limit = {}, 2
		force_stop_draws, dont_draw_actions, root_shot = false, false, nil
	end

	dofile_once( "data/scripts/gun/gun.lua" )
	dofile_once( "data/scripts/gun/gun_enums.lua" )
	dofile_once( "data/scripts/gun/gun_actions.lua" )
	return pen.cache({ "spell_data", spell_id }, function()
		clean_my_gun()

		local spell_data = pen.t.clone( pen.t.get( actions, spell_id, nil, nil, {}), nil )
		if( spell_data.action == nil ) then return spell_data end
		
		local real_GetUpdatedEntityID = GetUpdatedEntityID
		GetUpdatedEntityID = function() return -1 end

		draw_actions_old = draw_actions
		draw_actions = function( draw_count ) c.draw_many = c.draw_many + draw_count end
		add_projectile_old = add_projectile
		add_projectile = function( path ) table.insert( c.projs, { 1, path }) end
		add_projectile_trigger_timer_old = add_projectile_trigger_timer
		add_projectile_trigger_timer = function( path, delay, draw_count )
			c.draw_many = c.draw_many + draw_count
			table.insert( c.projs, { 2, path, draw_count, delay })
		end
		add_projectile_trigger_hit_world_old = add_projectile_trigger_hit_world
		add_projectile_trigger_hit_world = function( path, draw_count )
			c.draw_many = c.draw_many + draw_count
			table.insert( c.projs, { 3, path, draw_count })
		end
		add_projectile_trigger_death_old = add_projectile_trigger_death
		add_projectile_trigger_death = function( path, draw_count )
			c.draw_many = c.draw_many + draw_count
			table.insert( c.projs, { 4, path, draw_count })
		end

		ACTION_DRAW_RELOAD_TIME_INCREASE = 1e9
		current_reload_time, shot_effects = 0, {}
		dont_draw_actions, reflecting = true, true
		SetRandomSeed( 0, 0 ); ConfigGunShotEffects_Init( shot_effects )

		local metadata = create_shot()
		c, metadata.state_proj = metadata.state, { damage = {}, explosion = {}, crit = {}, lightning = {}}
		set_current_action( spell_data )
		c.draw_many, c.projs = 0, {}
		
		pcall( spell_data.action )
		if( spell_data.tip_data ~= nil ) then spell_data.tip_data() end
		if( math.abs( current_reload_time ) > 1e6 ) then
			spell_data.is_chainsaw = true
			current_reload_time = current_reload_time + ACTION_DRAW_RELOAD_TIME_INCREASE end --shouldn't this be a minus?
		metadata.state.reload_time, metadata.shot_effects = current_reload_time, pen.t.clone( shot_effects )
		
		local total_dmg_add, dmg_tbl = 0, {
			"damage_projectile_add", "damage_curse_add", "damage_explosion_add", "damage_slice_add", "damage_poison_add",
			"damage_melee_add", "damage_ice_add", "damage_electricity_add", "damage_drill_add", "damage_radioactive_add",
			"damage_healing_add", "damage_fire_add", "damage_holy_add", "damage_physics_add", "damage_explosion", }
		for i,dmg in ipairs( dmg_tbl ) do total_dmg_add = total_dmg_add + ( c[ dmg ] or 0 ) end
		c.damage_total_add = total_dmg_add
		
		local is_gonna = false
		c.proj_count = #c.projs
		pen.hallway( function()
			if( c.proj_count == 0 ) then return end
			if( not( pen.vld( pen.lib ) and pen.vld( pen.lib.nxml ))) then return end

			local xml = pen.lib.nxml.parse( pen.magic_read( c.projs[1][2]))
			local xml_kid = xml:first_of( "ProjectileComponent" )
			local bs = { first_of = function() return end }
			xml_kid = xml_kid or ( xml:first_of( "Base" ) or bs ):first_of( "ProjectileComponent" )
			if( not( pen.vld( xml_kid ))) then return end

			metadata.state_proj = {
				damage = {
					projectile = tonumber( xml_kid.attr.damage or 0 ),
					curse = 0, explosion = 0, slice = 0, poison = 0, melee = 0,
					ice = 0, electricity = 0, drill = 0, radioactive = 0, healing = 0,
					fire = 0, holy = 0, physics_hit = 0, overeating = 0,
				},

				explosion = {}, lightning = {}, laser = {}, crit = {},
				damage_every_x_frames = tonumber( xml_kid.attr.damage_every_x_frames or -1 ),
				damage_scaled_by_speed = tonumber( xml_kid.attr.damage_scaled_by_speed or 0 ) > 0,
				
				lifetime = tonumber( xml_kid.attr.lifetime or -1 ),
				speed = math.floor((
					tonumber( xml_kid.attr.speed_min or xml_kid.attr.speed_max or 0 )
					+ tonumber( xml_kid.attr.speed_max or xml_kid.attr.speed_min or 0 )
				)/2 + 0.5 ),

				bounces = tonumber( xml_kid.attr.bounces_left or 0 ),
				inf_bounces = tonumber( xml_kid.attr.bounce_always or 0 ) > 0,
				
				on_collision_die = tonumber( xml_kid.attr.on_collision_die or 1 ) > 0,
				on_death_explode = tonumber( xml_kid.attr.on_death_explode or 0 ) > 0,
				on_death_duplicate = tonumber( xml_kid.attr.on_death_duplicate_remaining or 0 ) > 0,
				on_lifetime_out_explode = tonumber( xml_kid.attr.on_lifetime_out_explode or 0 ) > 0,

				friendly_fire = tonumber( xml_kid.attr.friendly_fire or 0 ) > 0,
				dont_collide_with_tag = xml_kid.attr.dont_collide_with_tag or "",
				never_hit_player = tonumber( xml_kid.attr.never_hit_player or 0 ) > 0,
				penetrate_entities = tonumber( xml_kid.attr.penetrate_entities or 0 ) > 0,
				collide_with_entities = tonumber( xml_kid.attr.collide_with_entities or 1 ) > 0,
				explosion_dont_damage_shooter = tonumber( xml_kid.attr.explosion_dont_damage_shooter or 0 ) > 0,

				penetrate_world = tonumber( xml_kid.attr.penetrate_world or 0 ) > 0,
				go_through_this_material = xml_kid.attr.go_through_this_material or "",
				collide_with_world = tonumber( xml_kid.attr.collide_with_world or 1 ) > 0,
				ground_penetration_coeff = tonumber( xml_kid.attr.ground_penetration_coeff or 0 ),
				ground_penetration_max_durability = tonumber( xml_kid.attr.ground_penetration_max_durability_to_destroy or 0 ),
			}

			local dmg_kid = xml_kid:first_of( "damage_by_type" )
			if( pen.vld( dmg_kid )) then
				metadata.state_proj.damage[ "projectile" ] = metadata.state_proj.damage.projectile
					+ tonumber( dmg_kid.attr.projectile or 0 )
				metadata.state_proj.damage[ "curse" ] = tonumber( dmg_kid.attr.curse or 0 )
				metadata.state_proj.damage[ "explosion" ] = tonumber( dmg_kid.attr.explosion or 0 )
				metadata.state_proj.damage[ "slice" ] = tonumber( dmg_kid.attr.slice or 0 )
				metadata.state_proj.damage[ "poison" ] = tonumber( dmg_kid.attr.poison or 0 )
				metadata.state_proj.damage[ "melee" ] = tonumber( dmg_kid.attr.melee or 0 )
				metadata.state_proj.damage[ "ice" ] = tonumber( dmg_kid.attr.ice or 0 )
				metadata.state_proj.damage[ "electricity" ] = tonumber( dmg_kid.attr.electricity or 0 )
				metadata.state_proj.damage[ "drill" ] = tonumber( dmg_kid.attr.drill or 0 )
				metadata.state_proj.damage[ "radioactive" ] = tonumber( dmg_kid.attr.radioactive or 0 )
				metadata.state_proj.damage[ "healing" ] = tonumber( dmg_kid.attr.healing or 0 )
				metadata.state_proj.damage[ "fire" ] = tonumber( dmg_kid.attr.fire or 0 )
				metadata.state_proj.damage[ "holy" ] = tonumber( dmg_kid.attr.holy or 0 )
				metadata.state_proj.damage[ "physics_hit" ] = tonumber( dmg_kid.attr.physics_hit or 0 )
				metadata.state_proj.damage[ "overeating" ] = tonumber( dmg_kid.attr.overeating or 0 )
			end

			local exp_kid = xml_kid:first_of( "config_explosion" )
			if( pen.vld( exp_kid )) then
				metadata.state_proj.explosion = {
					damage_mortals = tonumber( exp_kid.attr.damage_mortals or 1 ) > 0,
					damage = tonumber( exp_kid.attr.damage or 0 ),
					is_digger = tonumber( exp_kid.attr.is_digger or 0 ) > 0,
					explosion_radius = tonumber( exp_kid.attr.explosion_radius or 0 ),
					max_durability_to_destroy = tonumber( exp_kid.attr.max_durability_to_destroy or 0 ),
					ray_energy = tonumber( exp_kid.attr.ray_energy or 0 ),
				}
			end

			local crit_kid = xml_kid:first_of( "damage_critical" )
			if( pen.vld( crit_kid )) then
				metadata.state_proj.crit = {
					chance = tonumber( crit_kid.attr.chance or 0 ),
					damage_multiplier = tonumber( crit_kid.attr.damage_multiplier or 1 ),
				}
			end

			xml_kid = xml:first_of( "LightningComponent" ) or ( xml:first_of( "Base" ) or bs ):first_of( "LightningComponent" )
			if( pen.vld( xml_kid )) then
				local lght_kid = xml_kid:first_of( "config_explosion" )
				if( pen.vld( lght_kid )) then
					metadata.state_proj.lightning = {
						damage_mortals = tonumber( lght_kid.attr.damage_mortals or 1 ) > 0,
						damage = tonumber( lght_kid.attr.damage or 0 ),
						is_digger = tonumber( lght_kid.attr.is_digger or 0 ) > 0,
						explosion_radius = tonumber( lght_kid.attr.explosion_radius or 0 ),
						max_durability_to_destroy = tonumber( lght_kid.attr.max_durability_to_destroy or 0 ),
						ray_energy = tonumber( lght_kid.attr.ray_energy or 0 ),
					}
				end
			end

			xml_kid = xml:first_of( "LaserEmitterComponent" ) or ( xml:first_of( "Base" ) or bs ):first_of( "LaserEmitterComponent" )
			if( pen.vld( xml_kid )) then
				local laser_kid = xml_kid:first_of( "laser" )
				if( pen.vld( laser_kid )) then
					metadata.state_proj.laser = {
						max_length = tonumber( laser_kid.attr.max_length or 0 ),
						beam_radius = tonumber( laser_kid.attr.beam_radius or 0 ),
						damage_to_entities = tonumber( laser_kid.attr.damage_to_entities or 0 ),
						damage_to_cells = tonumber( laser_kid.attr.damage_to_cells or 0 ),
						max_cell_durability_to_destroy = tonumber( laser_kid.attr.max_cell_durability_to_destroy or 0 ),
					}
				end
			end
			
			local total_dmg = 0
			for field,dmg in pairs( metadata.state_proj.damage ) do total_dmg = total_dmg + dmg end
			if( metadata.state_proj.explosion.damage_mortals ) then
				total_dmg = total_dmg + ( metadata.state_proj.explosion.damage or 0 ) end
			if( metadata.state_proj.lightning.damage_mortals ) then
				total_dmg = total_dmg + ( metadata.state_proj.lightning.damage or 0 ) end
			metadata.state_proj.damage[ "total" ] = total_dmg
		end)

		ACTION_DRAW_RELOAD_TIME_INCREASE, c = 0, nil
		draw_actions, add_projectile = draw_actions_old, add_projectile_old
		add_projectile_trigger_timer = add_projectile_trigger_timer_old
		add_projectile_trigger_hit_world = add_projectile_trigger_hit_world_old
		add_projectile_trigger_death = add_projectile_trigger_death_old
		GetUpdatedEntityID = real_GetUpdatedEntityID
		clean_my_gun()

		spell_data.meta = pen.t.clone( metadata )
		return spell_data
	end, { reset_count = 0 })
end

function pen.get_matter( matters, id )
	local mttrs, total = id == nil and {} or { 0, 0 }, 0
	if( not( pen.vld( matters ))) then return total, mttrs end

	for i,matter in ipairs( matters ) do
		if( id ~= nil and id == i - 1 ) then
			return { id, matter }
		elseif( id == nil and matter > 0 ) then
			table.insert( mttrs, { i - 1, matter })
			total = total + matter
		elseif( id ~= nil and matter > mttrs[2]) then
			mttrs = { i - 1, matter }
		end
	end

	if( id ~= nil ) then return total, mttrs end
	table.sort( mttrs, function( a, b ) return a[2] > b[2] end)
	return total, mttrs
end

function pen.magic_chugger( mttrs, eater_id, eatee_id, volume, perc )
	if( not( pen.vld( mttrs ))) then return end

	local gonna_pour = type( eater_id ) == "table"
	if( gonna_pour ) then perc = 9/volume else perc = perc or 0.1 end
	
	local to_drink = volume*perc
	local min_vol = math.ceil( to_drink*perc )
	for i = #mttrs,1,-1 do
		local mtr = mttrs[i]
		if( mtr[2] > 0 ) then
			local count = math.floor( mtr[2]*perc )
			if( i == 1 ) then count = to_drink end
			count = math.min( math.max( count, min_vol ), mtr[2])

			local name = CellFactory_GetName( mtr[1])
			if( gonna_pour ) then
				local temp = to_drink - 1
				for i = 1,count do
					local off_x, off_y = -1.5 + temp%3, -1.5 + math.floor( temp/3 )%4
					GameCreateParticle( name, eater_id[1] + off_x, eater_id[2] + off_y, 1, 0, 0, false, false, false )
					temp = temp - 1
				end
			else EntityIngestMaterial( eater_id, mtr[1], count ) end
			AddMaterialInventoryMaterial( eatee_id, name, math.floor( mtr[2] - count + 0.5 ))

			to_drink = to_drink - count
			if( to_drink <= 0 ) then break end
		end
	end
end

function pen.get_mass( entity_id )
	local mass = 0
	local shape_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "PhysicsImageShapeComponent" )
	local char_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "CharacterDataComponent" )
	local vel_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "VelocityComponent" )
	if( pen.vld( shape_comp, true )) then
		local x, y = EntityGetTransform( entity_id )
		local drift_x = ComponentGetValue2( shape_comp, "offset_x" )
		local drift_y = ComponentGetValue2( shape_comp, "offset_y" )
		x, y = x - drift_x, y - drift_y; drift_x, drift_y = 1.5*drift_x, 1.5*drift_y
		PhysicsApplyForceOnArea( function( entity, body_mass, body_x, body_y, body_vel_x, body_vel_y, body_vel_angular )
			if( math.abs( x - body_x ) < 0.001 and math.abs( y - body_y ) < 0.001 ) then mass = body_mass end
			return body_x, body_y, 0, 0, 0
		end, nil, x - drift_x, y - drift_y, x + drift_x, y + drift_y )
	elseif( pen.vld( char_comp, true )) then
		mass = ComponentGetValue2( char_comp, "mass" )
	elseif( pen.vld( vel_comp, true )) then
		mass = ComponentGetValue2( vel_comp, "mass" )
	end
	return mass
end

function pen.get_item_num( inv_id, item_id )
	return pen.child_play( inv_id, function( parent, child, i )
		if( child == item_id ) then return i - 1 end
	end) or 0
end

function pen.get_xy_matter_file()
	local full_list = string.sub( pen.t.loop_concat({
		CellFactory_GetAllLiquids(),
		CellFactory_GetAllSands(),
		CellFactory_GetAllGases(),
		CellFactory_GetAllFires(),
		CellFactory_GetAllSolids(),
	}, function( i, list )
		return pen.t.loop_concat( list, function( e, mtr )
			return { mtr, "," }
		end)
	end), 1, -2 )
	return string.gsub( pen.FILE_XML_MATTER, "_MATTERLISTHERE_", full_list )
end
function pen.get_xy_matter( x, y, duration )
	if( not( ModDoesFileExist( pen.FILE_MATTER ))) then
		if( pen.magic_write and not( pen.c.matter_test_file )) then
			pen.c.matter_test_file = true
			pen.magic_write( pen.FILE_MATTER, pen.get_xy_matter_file())
		else return 0 end
	end

	duration = duration or 5
	pen.c.get_xy_matter_memo = pen.c.get_xy_matter_memo or {
		probe = pen.delayed_kill( EntityLoad( pen.FILE_MATTER, x, y ), math.abs( duration )),
		frames = duration < 0 and math.abs( duration ) or ( GameGetFrameNum() + duration ),
		mtr_list = {}, mtr_buff = {}, mtr_memo = {},
	}
	if( not( EntityGetIsAlive( pen.c.get_xy_matter_memo.probe or 0 ))) then
		pen.c.get_xy_matter_memo.probe = pen.delayed_kill( EntityLoad( pen.FILE_MATTER, x, y ), math.abs( duration ))
	end
	
    local data = pen.c.get_xy_matter_memo
	if( duration < 0 or data.frames > GameGetFrameNum()) then
        EntityApplyTransform( data.probe, x + 0.5*pen.get_sign( math.random( -1, 0 )), y + 0.5*pen.get_sign( math.random( -1, 0 )))
		
        local dmg_comp = EntityGetFirstComponentIncludingDisabled( data.probe, "DamageModelComponent" )
        local matter = ComponentGetValue2( dmg_comp, "mCollisionMessageMaterials" )
		pen.t.loop( ComponentGetValue2( dmg_comp, "mCollisionMessageMaterialCountsThisFrame" ), function( i, v )
			if( v > 0 ) then data.mtr_list[ matter[i]], data.mtr_buff[ matter[i]] = ( data.mtr_list[ matter[i]] or 0 ) + v, v end
		end)
		
		if( duration >= 0 ) then return end
		
		pen.magic_comp( data.probe, "LifetimeComponent", function( comp_id, v, is_enabled )
			v.kill_frame = GameGetFrameNum() + data.frames; return true
		end)

		table.insert( data.mtr_memo, data.mtr_buff ); data.mtr_buff = {}
		if( data.frames < #data.mtr_memo ) then
			for m,v in pairs( data.mtr_memo[1]) do
				data.mtr_list[m] = data.mtr_list[m] - v
			end; table.remove( data.mtr_memo, 1 )
			return pen.t.get_max( data.mtr_list )
		end
	else
		local mtr = pen.t.get_max( data.mtr_list ); EntityKill( data.probe )
		pen.c.get_xy_matter_memo = nil
		return mtr
	end
end

function pen.get_color_matter( matter )
	if( not( ModDoesFileExist( pen.FILE_MATTER_COLOR ))) then
		if( pen.magic_write and not( pen.c.matter_color_file )) then
			pen.magic_write( pen.FILE_MATTER_COLOR, pen.FILE_XML_MATTER_COLOR )
			pen.c.matter_color_file = true
		else return pen.PALETTE.W end
	end

	local color_probe = EntityLoad( pen.FILE_MATTER_COLOR )
	AddMaterialInventoryMaterial( color_probe, matter, 1000 )
	local color = pen.magic_uint( GameGetPotionColorUint( color_probe ))
	EntityKill( color_probe )
	return color
end

function pen.debug_dot( x, y, frames )
	GameCreateSpriteForXFrames( "data/ui_gfx/debug_marker.png", x, y, true, 0, 0, frames or 1, true )
end

function pen.lag_me( frame_time )
	local current_time = GameGetRealWorldTimeSinceStarted()*1000
	local prev_time = current_time
	while(( current_time - prev_time ) < frame_time ) do
		current_time = GameGetRealWorldTimeSinceStarted()*1000
	end
end

function pen.get_hotspot_pos( entity_id, tag )
	local x, y, r, s_x, s_y = EntityGetTransform( entity_id )
	local off_x, off_y = EntityGetHotspot( entity_id, tag, nil, true )
	off_x, off_y = pen.rotate_offset( off_x*s_x, off_y*s_y, r )
	return x + off_x, y + off_y, r
end

function pen.gunshot()
	local card_id = gunshot_card_id or pen.get_card_id()
	if( not( pen.vld( card_id, true ))) then return end
	local action = pen.t.get( actions, current_action.id, nil, nil, {})
	if( not( pen.vld( action ))) then return end

	local frame_num = GameGetFrameNum()
	local gun_id = gunshot_gun_id or EntityGetParent( card_id )
	local arm_id = gunshot_arm_id or pen.get_child( EntityGetRootEntity( gun_id ), "arm_r" )
	
	--play trigger click only once per empty mag, set "locked_and_unloaded" gun_id varstorage to true after that

	if(( pen.magic_storage( gun_id, "cycling_frame", "value_int" ) or frame_num ) > frame_num ) then return end

	local max_ammo = pen.magic_storage( card_id, "ammo_max", "value_int" ) or -1
	local ammo = pen.magic_storage( card_id, "ammo", "value_int", nil, max_ammo )
	if( ammo == 0 ) then return end

	local x, y, r, s_x, s_y = EntityGetTransform( gun_id )
	local shot_x, shot_y = pen.get_hotspot_pos( gun_id, "shoot_pos" )
	pen.play_sound({ action.sfx[1], action.sfx[2].."/shoot" }, shot_x, shot_y )

	local recoil = pen.magic_storage( gun_id, "recoil", "value_float" ) or 0
	local bolt_delay = pen.magic_storage( gun_id, "cycling", "value_int" ) or 0
	pen.magic_storage( gun_id, "cycling_frame", "value_int", frame_num + bolt_delay )

	local count, heat = 0, 0
	for i,v in ipairs( action.projectiles ) do
		for e = 1,( v.c or 1 ) do
			add_projectile( v.p )
			heat = heat + ( v.h or 0 )
			count = count + ( v.s or 1 )
			recoil = recoil + ( v.r or 0 )
		end
	end

	local max_heat = pen.magic_storage( gun_id, "heat_max", "value_float" ) or -1
	if( max_heat > 0 ) then
		local killer = "mods/Noita40K/files/misc/premature_detonation.xml,"
		local total_heat = pen.magic_storage( gun_id, "heat", "value_float", nil, true ) + heat
		if( total_heat > max_heat ) then c.extra_entities, ammo = c.extra_entities..killer, math.min( ammo, 1 ) end
		pen.magic_storage( gun_id, "heat", "value_float", total_heat )
	end

	--this should be dynamically calculated from projectile muzzle energy and gun stats (muzzle break + mass)
	pen.magic_storage( gun_id, "recoil", "value_float", recoil )
	pen.magic_storage( card_id, "ammo", "value_int", ammo - 1 )
	
	--play bolt ejection sound (and make sure bolt feed sound plays on return)
	--ejector smoke and sparks (customizable per-spell)

	local eject_force = 300
	local eject_angle = r - pen.get_sign( s_y )*math.rad( 135 )
	local eject_force_x = math.cos( eject_angle )*eject_force
	local eject_force_y = math.sin( eject_angle )*eject_force
	local eject_x, eject_y = pen.get_hotspot_pos( gun_id, "eject_pos" )
	for i,v in ipairs( action.shells ) do
		local v_x = eject_force_x - math.random( 50, 100 )
		local v_y = eject_force_y - math.random( 10, 75 )
		pen.magic_shooter( 0, v, eject_x, eject_y, v_x, v_y )
	end

	local trans_comp = EntityGetFirstComponentIncludingDisabled( arm_id, "InheritTransformComponent" )
	local rx, ry = ComponentGetValue2( trans_comp, "Transform" )
	local abil_comp = EntityGetFirstComponentIncludingDisabled( gun_id, "AbilityComponent" )
	local rr = ComponentGetValue2( abil_comp, "item_recoil_rotation_coeff" )
	c.spread_degrees = c.spread_degrees + math.abs( rx ) + math.abs( ry ) + math.abs( rr )

	return card_id, action
end

function pen.magic_shooter( who_shot, path, x, y, v_x, v_y, do_it, proj_mods, custom_values )
	who_shot = pen.get_hybrid_table( who_shot )
	pen.magic_comp( who_shot[1], "ProjectileComponent", function( comp_id, v, is_enabled )
		who_shot[2] = ComponentGetValue2( comp_id, "mWhoShot" )
		who_shot[3] = ComponentGetValue2( comp_id, "mShooterHerdId" )
		v.mEntityThatShot = who_shot[2] or who_shot[1]
	end)

	local proj_id = EntityLoad( path, x, y )
	local gene_comp = EntityGetFirstComponentIncludingDisabled( who_shot[1], "GenomeDataComponent" )
	if( pen.vld( gene_comp, true )) then who_shot[3] = ComponentGetValue2( gene_comp, "herd_id" ) end
	if( do_it ) then GameShootProjectile( who_shot[1], x, y, x + v_x, y + v_y, proj_id, true, who_shot[2]) end

	local do_ff = EntityHasTag( who_shot[1], "friendly_fire_enabled" )
	pen.magic_comp( proj_id, "ProjectileComponent", function( comp_id, v, is_enabled )
		v.mWhoShot = who_shot[2] or who_shot[1]
		v.mShooterHerdId = who_shot[3] or 0

		if( do_ff ) then
			EntityAddTag( proj_id, "friendly_fire_enabled" )
			v.friendly_fire = true
			v.collide_with_shooter_frames = 6
		end
	end)
	pen.magic_comp( proj_id, "VelocityComponent", function( comp_id, v, is_enabled )
		v.mVelocity = { v_x, v_y }
	end)
	
	if( pen.vld( proj_mods )) then proj_mods( proj_id, custom_values ) end
	return proj_id
end

function pen.delayed_kill( entity_id, delay, comp_id )
	EntityAddComponent( entity_id, "LifetimeComponent", { lifetime = ( delay or 5 ) + 1 })
	if( pen.vld( comp_id, true )) then EntityRemoveComponent( entity_id, comp_id ) end
	return entity_id
end

function pen.check_bounds( dot, box, off, distance_func )
	if( not( pen.vld( box, true ))) then return false end
	
	off = off or { 0, 0 }
	if( type( box ) ~= "table" ) then
		local bx1 = ComponentGetValue2( box, "aabb_min_x" )
		local bx2 = ComponentGetValue2( box, "aabb_max_x" )
		local by1 = ComponentGetValue2( box, "aabb_min_y" )
		local by2 = ComponentGetValue2( box, "aabb_max_y" )
		local off_x, off_y = ComponentGetValue2( box, "offset" )
		off = { off[1] + off_x + bx1, off[2] + off_y + by1 }
		box = { bx2 - bx1, by2 - by1 }
	elseif( distance_func == nil ) then
		box = pen.get_hybrid_table( box )
		if( #box == 4 ) then
			off = { off[1] + box[1], off[2] + box[3]}
			box = { box[2] - box[1], box[4] - box[3]}
		end
	end
	
	local is_fancy = #box ~= 2
	local d = pen.V.new( off[1] - dot[1], off[2] - dot[2])
	local p = is_fancy and box or pen.V.new( box[1], box[2])/2
	if( not( is_fancy )) then d = d + pen.V.new( pen.rotate_offset( p.x, p.y, off[3] or 0 )) end
	return ( distance_func or pen.SDF.BOX )( pen.V.rot( d, off[3] or 0 ), p ) <= 0
end

function pen.scale_emitter( entity_id, emit_comp )
	local borders = pen.get_creature_dimensions( entity_id )
	ComponentSetValue2( emit_comp, "x_pos_offset_min", borders.min_x )
	ComponentSetValue2( emit_comp, "x_pos_offset_max", borders.max_x )
	ComponentSetValue2( emit_comp, "y_pos_offset_min", borders.min_y )
	ComponentSetValue2( emit_comp, "y_pos_offset_max", borders.max_y )
end

function pen.matter_fabricator( x, y, data )
	data = data or {}
	local size = pen.get_hybrid_table( data.size or 0 )
	local count = pen.get_hybrid_table( data.count or 1 )
	local delay = pen.get_hybrid_table( data.delay or 1 )
	local lifetime = pen.get_hybrid_table( data.time or 60 )
	size[2] = size[2] or 0.5
	
	local mtrr = EntityCreateNew( "matter_fabricator" )
	EntitySetTransform( mtrr, x, y )
	
	local comp = EntityAddComponent2( mtrr, "ParticleEmitterComponent", {
		emitted_material_name = data.matter or "blood",
		emission_interval_min_frames = delay[1],
		emission_interval_max_frames = delay[2] or delay[1],
		lifetime_min = lifetime[1],
		lifetime_max = lifetime[2] or lifetime[1],
		create_real_particles = data.is_real or false,
		emit_real_particles = data.is_real2 or false,
		emit_cosmetic_particles = data.is_fake or false,
		render_on_grid = data.is_grid or false,
	})
	ComponentSetValue2( comp, "count_min", count[1])
	ComponentSetValue2( comp, "count_max", count[2] or count[1])

	if( #size == 4 ) then
		ComponentSetValue2( comp, "x_pos_offset_min", size[1])
		ComponentSetValue2( comp, "y_pos_offset_min", size[2])
		ComponentSetValue2( comp, "x_pos_offset_max", size[3])
		ComponentSetValue2( comp, "y_pos_offset_max", size[4])
	else ComponentSetValue2( comp, "area_circle_radius", size[1], size[2]) end
	EntityAddComponent2( mtrr, "LifetimeComponent", { lifetime = data.frames or 1 })
end

function pen.add_perk( hooman, perk_id ) --bad
	dofile_once( "data/scripts/lib/utilities.lua" )
	dofile_once( "data/scripts/perks/perk.lua" )
	dofile_once( "data/scripts/perks/perk_list.lua" )

	local perk_data = get_perk_with_id( perk_list, perk_id )
	local name = get_perk_picked_flag_name( perk_id )
	local name_persistent = string.lower( name )
	if( not( HasFlagPersistent( name_persistent ))) then
		GameAddFlagRun( "new_"..name_persistent )
	end
	GameAddFlagRun( name )
	AddFlagPersistent( name_persistent )
	
	if( pen.vld( perk_data.game_effect )) then
		ComponentSetValue2( GetGameEffectLoadTo( hooman, perk_data.game_effect, true ), "frames", -1 ) end
	if( pen.vld( perk_data.func )) then perk_data.func( nil, hooman, nil ) end
	
	local ui = EntityCreateNew()
	EntityAddComponent( ui, "UIIconComponent", {
		name = perk_data.ui_name,
		description = perk_data.ui_description,
		icon_sprite_file = perk_data.ui_icon
	})
	EntityAddChild( hooman, ui )
end

function pen.strip_player( hooman, leave_barren )
	--remove all comps, leave_barren removes everything to the point of crashing the game
	-- AudioComponent
	-- AudioLoopComponent
end

function pen.rate_projectile( proj_id, hooman, data )--sparkbolt at 20m is ~1
	if( EntityGetRootEntity( proj_id ) ~= proj_id ) then return 0 end
	local custom_points = pen.magic_storage( proj_id, "custom_rating", "value_float" )
	if( pen.vld( custom_points )) then return custom_points end
	
	data = data or {}
	hooman = hooman or pen.get_hooman()
	local char_x, char_y = EntityGetTransform( hooman )
	local proj_x, proj_y = EntityGetTransform( proj_id )
	local proj_comp = EntityGetFirstComponentIncludingDisabled( proj_id, "ProjectileComponent" )
	
	local proj_vel_x, proj_vel_y = GameGetVelocityCompVelocity( proj_id )
	local char_vel_x, char_vel_y = GameGetVelocityCompVelocity( hooman )
	local proj_v = math.sqrt(( char_vel_x - proj_vel_x )^2 + ( char_vel_y - proj_vel_y )^2 )
	
	local d_x = proj_x - char_x
	local d_y = proj_y - char_y
	local distance = math.sqrt( d_x^2 + d_y^2 )
	local direction = math.abs( math.rad( 180 ) - math.abs( math.atan2( proj_vel_x, proj_vel_y ) - math.atan2( d_x, d_y )))
	
	local is_real = pen.b2n( ComponentGetValue2( proj_comp, "collide_with_entities" ))
	local lifetime = ComponentGetValue2( proj_comp, "lifetime" )
	lifetime = lifetime < 0 and 9999 or math.max( lifetime, 1 )
	
	local total_damage = 0
	local damage_types = ComponentObjectGetMembers( proj_comp, "damage_by_type" )
	for field in pairs( damage_types ) do
		local dmg = ComponentObjectGetValue2( proj_comp, "damage_by_type", field )
		if( dmg > 0 ) then total_damage = total_damage + dmg end
	end
	total_damage = total_damage + ComponentGetValue2( proj_comp, "damage" )
	
	local explosion_dmg = ComponentObjectGetValue2( proj_comp, "config_explosion", "damage" )
	local explosion_rad = ComponentObjectGetValue2( proj_comp, "config_explosion", "explosion_radius" )
	if( explosion_dmg > 0 ) then
		explosion_dmg = explosion_dmg + ( explosion_rad + math.max( explosion_rad - distance + 1, 0 ))/25
	end
	total_damage = total_damage + explosion_dmg
	
	local f_distance = 1 + 4/2^( distance/10 )
	local f_direction = 0.02 + 1.08/2^( direction/0.6 )
	local f_velocity = 0.1847 + ( 1 - math.exp( -0.0021*proj_v ))
	local f_lifetime = ( 1.8*( lifetime - 1 )/lifetime + 0.3 )/2
	local f_is_real = 0.5 + 0.5*is_real
	local f_damage = total_damage*25
	
	local final_value = 0.15*f_distance*f_direction*f_lifetime*f_is_real*f_velocity*f_damage
	return pen.vld( final_value ) and final_value or 0
end

function pen.rate_spell( spell_id, data )--sparkbolt is 1
	if( not( pen.vld( spell_id, true ))) then return 0 end
	local act_comp = EntityGetFirstComponentIncludingDisabled( spell_id, "ItemActionComponent" )
	local action_data = data or pen.get_spell( ComponentGetValue2( act_comp, "action_id" ))
	if( not( pen.vld( action_data ))) then
		return 0
	elseif( pen.vld( action_data.custom_rating )) then
		return action_data.custom_rating
	end

	local price = action_data.price or 1
	local uses_max = action_data.max_uses or -1
	local mana = math.abs( action_data.mana or 0 )
	local item_comp = EntityGetFirstComponentIncludingDisabled( spell_id, "ItemComponent" )
	local is_perma = action_data.is_perma or pen.b2n( ComponentGetValue2( item_comp, "permanently_attached" ))
	local uses_left = action_data.uses_left or ComponentGetValue2( item_comp, "uses_remaining" )
	
	local f_perma = 1 + 4*is_perma
	local f_price = price/100
	local f_mana = 5.4 + ( 0.1 - 5.4 )/( 1 + ( mana/8420.3 )^0.367 )
	
	local f_uses = 2
	if( uses_left >= 0 and uses_max > 0 ) then f_uses = uses_left/uses_max end
	local final_value = 2.5*f_perma*f_price*f_uses*f_mana
	return pen.vld( final_value ) and final_value or 0
end

function pen.rate_wand( wand_id, data )--sollex is 1
	if( not( pen.vld( wand_id, true ))) then return 0 end
	local custom_points = pen.magic_storage( wand_id, "custom_rating", "value_float" )
	if( pen.vld( custom_points )) then return custom_points end

	data = data or {}
	local abil_comp = EntityGetFirstComponentIncludingDisabled( wand_id, "AbilityComponent" )
	if( not( pen.vld( abil_comp, true ))) then return 0 end

	if( data.shuffle == nil ) then
		data.shuffle = pen.b2n( ComponentObjectGetValue2( abil_comp, "gun_config", "shuffle_deck_when_empty" ))
	end
	if( data.can_reload == nil ) then
		data.can_reload = not( ComponentGetValue2( abil_comp, "never_reload" ))
	end
	if( data.capacity == nil ) then
		data.capacity = ComponentObjectGetValue2( abil_comp, "gun_config", "deck_capacity" )
	end
	
	if( data.reload_time == nil ) then
		data.reload_time = ComponentObjectGetValue2( abil_comp, "gun_config", "reload_time" )
	end
	if( data.cast_delay == nil ) then
		data.cast_delay = ComponentObjectGetValue2( abil_comp, "gunaction_config", "fire_rate_wait" )
	end
	
	if( data.mana_max == nil ) then
		data.mana_max = ComponentGetValue2( abil_comp, "mana_max" )
	end
	if( data.mana_charge == nil ) then
		data.mana_charge = ComponentGetValue2( abil_comp, "mana_charge_speed" )
	end
	
	if( data.spell_cast == nil ) then
		data.spell_cast = ComponentObjectGetValue2( abil_comp, "gun_config", "actions_per_round" )
	end
	if( data.spread == nil ) then
		data.spread = ComponentObjectGetValue2( abil_comp, "gunaction_config", "spread_degrees" )
	end
	
	local f_shuffle = 1 - 0.7*data.shuffle
	local f_capacity = 3.47 + ( 0.05 - 3.47 )/( 1 + (( data.capacity + 3 )/13.67 )^3.05 )
	local f_delay = 2 - ( 0.044/0.024 )*( 1 - math.exp( -0.024*data.cast_delay ))
	local f_mana_max = 1.5 + ( 0.06 - 1.5 )/( 1 + ( data.mana_max/6074441 )^1.416 )^237023
	local f_mana_charge = 3.41 + ( 0.07 - 3.41 )/( 1 + ( data.mana_charge/14641850 )^1.314 )^251693
	local f_multi = 2.58 + ( 1.017 - 2.58 )/( 1 + ( data.spell_cast/48023 )^1.63 )^983676
	local f_spread = math.rad( 45 - data.spread )
	
	--add spells

	local f_reloading = 2
	if( data.can_reload ) then f_reloading = f_reloading - ( 0.044/0.024 )*( 1 - math.exp( -0.024*data.reload_time )) end
	local final_value = 1500*f_delay*f_reloading*f_mana_max*f_mana_charge*math.sqrt( f_spread*f_multi )*f_shuffle*f_capacity^1.5
	return pen.vld( final_value ) and final_value or 0
end

function pen.rate_creature( entity_id, hooman, data )--hamis at 20m is 1
	if( EntityGetRootEntity( entity_id ) ~= entity_id ) then return 0 end
	local custom_points = pen.magic_storage( entity_id, "custom_rating", "value_float" )
	if( pen.vld( custom_points )) then return custom_points end

	data = data or {}
	hooman = hooman or pen.get_hooman()
	local dmg_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "DamageModelComponent" )
	local gene_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "GenomeDataComponent" )
	if( pen.vld( dmg_comp, true ) or pen.vld( gene_comp, true )) then
		return 0
	elseif( check_gene and EntityGetHerdRelation( entity_id, hooman ) < 90 ) then
		return 0
	end

	local dist = 50
	local f_php = 1
	if( pen.vld( hooman, true )) then
		local char_x, char_y = EntityGetTransform( hooman )
		local enemy_x, enemy_y = EntityGetTransform( entity_id )
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
	local animal_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "AnimalAIComponent" )
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
	if( EntityHasTag( entity_id, "boss" ) or EntityHasTag( entity_id, "miniboss" )) then
		violence = violence + 5
	end
	
	--add projectile rater by getting xml

	local overall_speed = 0
	local plat_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "CharacterPlatformingComponent" )
	local path_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "PathFindingComponent" )
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
	if( overall_speed == 0 and EntityHasTag( entity_id, "helpless_animal" )) then
		local fish_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "AdvancedFishAIComponent" ) or EntityGetFirstComponentIncludingDisabled( entity_id, "FishAIComponent" )
		if( pen.vld( fish_comp, true )) then overall_speed = 300 end
	end

	--add wand check for stuff in-hand
	
	local f_speed = ( overall_speed + 0.01 )/10
	local f_vulner = 0.77 + ( 3 - 0.26 )/( 1 + ( vulnerability/5 )^2.9 )
	local f_supremacy = math.min( supremacy, 20 )/20
	local f_violence = violence*10
	local f_hp = ( hp + max_hp )*25
	
	local main = f_distance*f_speed*f_vulner*f_hp
	local final_value = f_php*0.5*( 0.08*( main - ( main > f_supremacy and f_supremacy or 0 )) + f_violence )
	return pen.vld( final_value ) and final_value or 0
end

--[INTERFACE]
function pen.gui_builder( gui )
	local iuid = 69
	local frame_num = GameGetFrameNum()
	pen.c.gui_dump = pen.c.gui_dump or {}
	if( gui == false or ( gui == true and (( pen.c.gui_data or {}).i or 0 ) < ( iuid + 1 ))) then
		if(( pen.c.gui_data or {}).g ) then
			pen.c.gui_dump[ pen.c.gui_data.g ] = nil
			GuiDestroy( pen.c.gui_data.g )
		end
		pen.c.gui_data = nil
		return
	elseif( type( gui ) == "userdata" ) then
		if( pen.vld( pen.c.gui_data )) then
			pen.c.gui_dump[ pen.c.gui_data.g ] = pen.t.clone( pen.c.gui_data )
		end
		if( pen.c.gui_dump[ gui ] ~= nil ) then
			pen.c.gui_data = pen.t.clone( pen.c.gui_dump[ gui ])
		else pen.c.gui_data = { g = gui, i = iuid, f = 0, _g = ( pen.c.gui_data or {}).g } end
	end

	pen.c.gui_data = pen.c.gui_data or { g = GuiCreate(), i = iuid, f = 0 }
	if( pen.c.gui_data.f ~= frame_num ) then
		pen.c.gui_data.i, pen.c.gui_data.f = iuid, frame_num
		GuiStartFrame( pen.c.gui_data.g )
	else pen.c.gui_data.i = pen.c.gui_data.i + 1 end
	GuiIdPush( pen.c.gui_data.g, pen.c.gui_data.i )
	return pen.c.gui_data.g, pen.c.gui_data.i, pen.c.gui_data.f, pen.c.gui_data._g
end

function pen.magic_rgb( c, to_rbg, mode )
	--REFERENCE: https://bottosson.github.io/misc/colorpicker/#ff0088
	local function gam2lin( c )
		return c >= 0.04045 and math.pow(( c + 0.055 )/1.055, 2.4 ) or c/12.92
	end
	local function lin2gam( c )
		return c >= 0.0031308 and 1.055*math.pow( c, 1/2.4 ) - 0.055 or 12.92*c
	end
	--HSV: https://github.com/iskolbin/lhsx/blob/master/hsx.lua
	local function rgb2hsv( r, g, b )
		local M = math.max( r, g, b )
		local C = M - math.min( r, g, b )
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
		return h, M == 0 and 0 or C/M, M/255
	end
	local function hsv2rgb( h, s, v )
		local C = 255*v*s
		local m = 255*v - C
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
	--OKLAB: https://bottosson.github.io/posts/oklab/#converting-from-linear-srgb-to-oklab
	local function rgb2okl( r, g, b )
		r, g, b = gam2lin( r/255 ), gam2lin( g/255 ), gam2lin( b/255 )
		local l = math.pow( 0.4122214708*r + 0.5363325363*g + 0.0514459929*b, 1/3 )
		local m = math.pow( 0.2119034982*r + 0.6806995451*g + 0.1073969566*b, 1/3 )
		local s = math.pow( 0.0883024619*r + 0.2817188376*g + 0.6299787005*b, 1/3 )
		return
			0.2104542553*l + 0.7936177850*m - 0.0040720468*s,
			1.9779984951*l - 2.4285922050*m + 0.4505937099*s,
			0.0259040371*l + 0.7827717662*m - 0.8086757660*s
	end
	local function okl2rgb( L, a, b )
		local l = math.pow( L + 0.3963377774*a + 0.2158037573*b, 3 )
		local m = math.pow( L - 0.1055613458*a - 0.0638541728*b, 3 )
		local s = math.pow( L - 0.0894841775*a - 1.2914855480*b, 3 )
		return
			4.0767416621*l - 3.3077115913*m + 0.2309699292*s,
			-1.2684380046*l + 2.6097574011*m - 0.3413193965*s,
			-0.0041960863*l - 0.7034186147*m + 1.7076147010*s
	end
	local function okl2rgb_fixed( L, a, b )
		local r, g, b = okl2rgb( L, a, b )
		return pen.rounder( 255*lin2gam( r ), 1 ), pen.rounder( 255*lin2gam( g ), 1 ), pen.rounder( 255*lin2gam( b ), 1 )
	end
	--OKHSV: https://github.com/behreajj/AsepriteOkHsl/blob/main/ok_color.lua
	local function compute_max_saturation( a, b )
		if( a == 0 and b == 0 ) then return 0 end

		local k0, k1 = 1.35733652, -0.00915799
		local k2, k3, k4 = -1.1513021, -0.50559606, 0.00692167
		local wl, wm, ws = -0.0041960863, -0.7034186147, 1.707614701
		if(( -1.88170328*a - 0.80936493*b ) > 1 ) then
			k0, k1 = 1.19086277, 1.76576728
			k2, k3, k4 = 0.59662641, 0.75515197, 0.56771245
			wl, wm, ws = 4.0767416621, -3.3077115913, 0.2309699292
		elseif(( 1.81444104*a - 1.19445276*b ) > 1 ) then
			k0, k1 = 0.73956515, -0.45954404
			k2, k3, k4 = 0.08285427, 0.1254107, 0.14503204
			wl, wm, ws = -1.2684380046, 2.6097574011, -0.3413193965
		end
		
		local S = k0 + k1*a + k2*b + k3*a*a + k4*a*b
		local k_l = 0.3963377774*a + 0.2158037573*b
		local k_m = -0.1055613458*a - 0.0638541728*b
		local k_s = -0.0894841775*a - 1.291485548*b
		
		local l_, m_, s_ = 1 + S*k_l, 1 + S*k_m, 1 + S*k_s
		local l_sq, m_sq, s_sq = l_*l_, m_*m_, s_*s_
		local l, m, s = l_sq*l_, m_sq*m_, s_sq*s_
		local l_dS, m_dS, s_dS = 3*k_l*l_sq, 3*k_m*m_sq, 3*k_s*s_sq
		local l_dS2, m_dS2, s_dS2 = 6*k_l*k_l*l_, 6*k_m*k_m*m_, 6*k_s*k_s*s_
		
		local f = wl*l + wm*m + ws*s
		local f1 = wl*l_dS + wm*m_dS + ws*s_dS
		local f2 = wl*l_dS2 + wm*m_dS2 + ws*s_dS2
		local s_denom = f1*f1 - 0.5*f*f2
		if( s_denom ~= 0 ) then
			return S - f*f1/s_denom
		else return S end
	end
	local function find_cusp( a, b )
		local S_cusp = compute_max_saturation( a, b )
		local max_comp = math.max( okl2rgb( 1, S_cusp*a, S_cusp*b ))
		if( max_comp == 0 ) then return 0, 0 end

		local L_cusp = ( 1/max_comp )^( 1/3 )
		return L_cusp, L_cusp*S_cusp
	end
	local function to_ST( L, C )
		if( L ~= 0 and L ~= 1 ) then
			return C/L, C/( 1 - L )
		elseif( L ~= 0 ) then
			return C/L, 0
		elseif( L ~= 1 ) then
			return 0, C/( 1 - L )
		else return 0, 0 end
	end
	local function toe( x, is_inv )
		local k = 1.170873786407767
		if( is_inv ) then
			local denom = k*( x + 0.03 )
			if( denom == 0 ) then return 0 end
			return ( x*x + 0.206*x )/denom
		else
			local y = k*x - 0.206
			return 0.5*( y + math.sqrt( y*y + 0.14050485436893204*x ))
		end
	end
	local function okl2okv( L, a, b )
		if L >= 1 then return 0, 0, 1 end
		if L <= 0 then return 0, 0, 0 end

		local Csq = a*a + b*b
		if( Csq <= 0 ) then return 0, 0, L end

		local C = math.sqrt( Csq )
		a, b = a/C, b/C
		
		local S_0 = 0.5
		local cuspL, cuspC = find_cusp( a, b )
		local S_max, T_max = to_ST( cuspL, cuspC )
		local k = ( S_max ~= 0 ) and ( 1 - S_0/S_max ) or 1

		local t_denom = C + L*T_max
		local t = ( t_denom ~= 0 ) and ( T_max/t_denom ) or 0
		local L_v, C_v = t*L, t*C

		local L_vt = toe( L_v, true )
		local C_vt = ( L_v ~= 0 ) and ( C_v*L_vt/L_v ) or 0

		local r_s, g_s, b_s = okl2rgb( L_vt, a*C_vt, b*C_vt )
		local scale_denom, scale_L = math.max( r_s, g_s, b_s, 0 ), 0
		if( scale_denom ~= 0 ) then
			scale_L = ( 1/scale_denom )^( 1/3 )
			L, C = L/scale_L, C/scale_L
		end

		local toel = toe( L )
		C, L = C*toel/L, toel

		local h = math.atan2( -b, -a )*0.1591549430919 + 0.5

		local s = 0.0
		local s_denom = (( T_max*S_0 ) + T_max*k*C_v )
		if( s_denom ~= 0 ) then s = ( S_0 + T_max )*C_v/s_denom end

		local v = 0.0
		if( L_v ~= 0 ) then v = L/L_v end
		
		return h, s, v
	end
	local function okv2okl( h, s, v )
		if v <= 0 then return 0, 0, 0 end
		if v > 1 then v = 1 end
		
		local sCl = math.min( math.max( s, 0 ), 1 )
	
		local h_rad = h*6.283185307179586
		local a, b = math.cos( h_rad ), math.sin( h_rad )
		
		local S_0 = 0.5
		local cuspL, cuspC = find_cusp( a, b )
		local S_max, T_max = to_ST( cuspL, cuspC )
		local k = ( S_max ~= 0 ) and ( 1 - S_0/S_max ) or 1
		
		local L_v, C_v = 1, 0
		local v_denom = S_0 + T_max - T_max*k*sCl
		if( v_denom ~= 0 ) then
			L_v = 1 - sCl*S_0/v_denom
			C_v = sCl*T_max*S_0/v_denom
		end
	
		local L, C = v*L_v, v*C_v
		local L_vt = toe( L_v, true )
		local C_vt = ( L_v ~= 0 ) and ( C_v*L_vt/L_v ) or 0
		
		local L_new = toe( L, true )
		if( L ~= 0 ) then
			C = C*L_new/L
		else C = 0 end
		L = L_new
		
		local r_s, g_s, b_s = okl2rgb( L_vt, a*C_vt, b*C_vt )
		local max_comp = math.max( r_s, g_s, b_s, 0 )
		local scale_L = ( max_comp ~= 0 ) and ( 1/max_comp )^( 1/3 ) or 0
		
		C = C*scale_L
		return L*scale_L, C*a, C*b
	end
	local function rgb2okv( r, g, b )
		return okl2okv( rgb2okl( r, g, b ))
	end
	local function okv2rgb( h, s, v )
		return okl2rgb_fixed( okv2okl( h, s, v ))
	end
	--OKLCH: https://github.com/echasnovski/mini.colors/blob/main/lua/mini/colors.lua
	local function okl2okh( L, a, b )
		local h, c = -1, math.sqrt( a*a + b*b )
		if( c > 0 ) then h = math.deg( math.atan2( b, a )) end
		return L, c, h
	end
	local function okh2okl( l, c, h )
		if( c <= 0 or h < 0 ) then return l, 0, 0 end
		return l, c*math.cos( math.rad( h )), c*math.sin( math.rad( h ))
	end
	local function rgb2okh( r, g, b )
		return okl2okh( rgb2okl( r, g, b ))
	end
	local function okh2rgb( l, c, h )
		return okl2rgb_fixed( okh2okl( l, c, h ))
	end
	
	c = pen.get_hybrid_table( c, true )
	c[1] = c[1] or 255; c[2] = c[2] or c[1]; c[3] = c[3] or c[1]
	return { unpack( pen.cache({
		"color_conversion", table.concat( c, "|" ), mode, pen.b2n( to_rgb ),
	}, function()
		local out = {({
			gamma = { gam2lin, lin2gam },
			hsv = { rgb2hsv, hsv2rgb },
			oklab = { rgb2okl, okl2rgb_fixed },
			okhsv = { rgb2okv, okv2rgb },
			oklch = { rgb2okh, okh2rgb },
		})[ mode ][ 1 + pen.b2n( to_rbg )]( unpack( c ))}
		out[4] = c[4]
		return out
	end, { reset_frame = pen.CACHE_RESET_DELAY }))}
end

function pen.colourer( gui, c, alpha )
	if( not( pen.vld( c ) or pen.vld( alpha ))) then return end
	c = pen.get_hybrid_table( c, true )

	local color = {
		r = c[1] or 255,
		g = c[2] or c[1] or 255,
		b = c[3] or c[1] or 255,
		a = c[4] or alpha or 1,
	}
	if( not( gui )) then
		gui = pen.gui_builder(); pen.c.gui_data.i = pen.c.gui_data.i - 1 end
	GuiColorSetForNextWidget( gui, color.r/255, color.g/255, color.b/255, color.a )
end

function pen.play_sound( sfx, x, y, no_bullshit )
	if( not( no_bullshit )) then
		local frame_num = GameGetFrameNum()
		local sfx_id = table.concat({ sfx[1], sfx[2]})
		pen.c.play_sound_memo = pen.c.play_sound_memo or {}
		if( pen.c.play_sound_memo[ sfx_id ] == frame_num ) then return end
		pen.c.play_sound_memo[ sfx_id ] = frame_num
	end
	
	if( x == nil ) then x, y = GameGetCameraPos() end
	GamePlaySound( sfx[1], sfx[2], x, y )
end

function pen.play_entity_sound( entity_id, x, y, event_mutator, no_bullshit )
	local sound_table = {
		pen.magic_storage( entity_id, "sound_bank", "value_string" ),
		pen.magic_storage( entity_id, "sound_event", "value_string" ),
	}

	if( pen.vld( sound_table[2])) then
		sound_table[2] = sound_table[2]..( event_mutator or "" )
	else return end
	pen.play_sound( sound_table, x, y, no_bullshit )
end

function pen.get_text_dims( text, font, is_pixel_font )
	if( font == true ) then
		local _,dims = pen.liner( text, nil, nil, is_pixel_font )
		return unpack( dims )
	end

	local gui = GuiCreate()
	GuiStartFrame( gui )

	local symbol = "_"
	local reference = GuiGetTextDimensions( gui, symbol, 1, 0, font, is_pixel_font )
	local w, h = pen.catch( GuiGetTextDimensions, {
		gui, table.concat({ symbol, text, symbol }), 1, 0, font, is_pixel_font }, {0,0})

	GuiDestroy( gui )
	return w - 2*reference, h
end

function pen.get_pic_dims( path, update_xml )
	path = pen.get_hybrid_table( path )
	local is_xml = string.find( path[1], "%.xml$" ) ~= nil
	local got_nxml = pen.vld( pen.lib ) and pen.vld( pen.lib.nxml )
	local id_tbl = { "pic_metadata", path[1], path[2] or "dft" }

	local real_dims = pen.cache( id_tbl, function()
		if( not( is_xml and got_nxml )) then return end

		local dims = { 0, 0, { 0, 0 }, false }
		local xml = pen.lib.nxml.parse( pen.magic_read( path[1]))
		local anim_name = path[2] or xml.attr.default_animation
		pen.t.loop( xml:all_of( "RectAnimation" ), function( i, a )
			if( a.attr.name ~= ( anim_name or a.attr.name )) then return end
			if( tonumber( a.attr.frame_count ) > 1 ) then dims[4] = true end
			local k = a.attr.shrink_by_one_pixel and 1 or 0

			if( a.attr.has_offset ) then
				dims[3] = {( a.attr.offset_x or 0 ), ( a.attr.offset_y or 0 )}
			else dims[3] = {( xml.attr.offset_x or 0 ), ( xml.attr.offset_y or 0 )} end
			dims[1], dims[2] = ( a.attr.frame_width or 0 ) + k, ( a.attr.frame_height or 0 ) + k
			return true
		end)

		return dims
	end, { reset_count = 0, force_update = update_xml })
	if( pen.vld( real_dims )) then return unpack( real_dims ) end

	return pen.cache({ "pic_dimensions", path[1]}, function()
		local gui = GuiCreate()
		GuiStartFrame( gui )
		local w, h = GuiGetImageDimensions( gui, path[1], 1 )
		GuiDestroy( gui )
		return w, h
	end, { reset_count = 0 })
end

function pen.get_tip_dims( text, width, height, line_offset )
	width = pen.get_hybrid_table( width or {})
	width[1], width[2] = width[1] or 121, width[2] or 525

	local _,dims = pen.liner( text ); local s_x, s_y = unpack( dims )
	if( string.find( text, "[\n@]" ) ~= nil ) then s_x = 2*s_x end
	local line = math.max(( s_x > 300 and math.max( math.pow( 250/s_x, 1.25 ), 0.1 ) or 1 )*s_x, width[1])
	_,dims = pen.liner( text, math.min( line, width[2]), height or 300, nil, { line_offset = line_offset or -2 })

	return dims
end

---Returns GUI grid, in-game viewport and true window sizes.
---@return number w, number h, number view_w, number view_h, number real_w, number real_h
function pen.get_screen_data() --thanks to ImmortalDamned and Horscht
	local gui = GuiCreate()
	local real_w, real_h = GuiGetScreenDimensions( gui )
	GuiStartFrame( gui )
	local w, h = GuiGetScreenDimensions( gui )
	GuiDestroy( gui )

	local view_w = tonumber( MagicNumbersGetValue( "VIRTUAL_RESOLUTION_X" ))
	local view_h = view_w*real_h/real_w
	return w, h, view_w, view_h, real_w, real_h
end

---Returns delta in GUI units between in-world and on-screen pointer position.
---@param w? number
---@param h? number
---@param real_w? number
---@param real_h? number
---@return number delta_x, number delta_y
function pen.get_camera_shake( w, h, real_w, real_h )
	if( w == nil ) then w, h, _,_, real_w, real_h = pen.get_screen_data() end
	local function purify( a, max ) return math.min( math.max( pen.rounder( a, -2 ), 0 ), max ) end

	local m_x, m_y = DEBUG_GetMouseWorld()
	local screen_x, screen_y = InputGetMousePosOnScreen()
	local world_x, world_y = pen.world2gui( m_x, m_y, false, true )
	local delta_x = purify( w*screen_x/real_w, w ) - purify( world_x, w )
	local delta_y = purify( h*screen_y/real_h, h ) - purify( world_y, h )
	return delta_x, delta_y
end

---Returns on-screen pointer position.
---@return number pointer_x, number pointer_y
function pen.get_mouse_pos()
	local w, h, _,_, real_w, real_h = pen.get_screen_data()
	local m_x, m_y = InputGetMousePosOnScreen()
	return m_x*w/real_w, m_y*h/real_h
end

---Calculates on-screen position from in-world coordinates.
---@param x number
---@param y number
---@param is_raw? boolean
---@param no_shake? boolean
---@param in_reverse? boolean
---@return number pic_x, number pic_y, table scale_values
function pen.world2gui( x, y, is_raw, no_shake, in_reverse ) --thanks to ImmortalDamned for the fix (x2 combo)
	local w, h, view_w, view_h, real_w, real_h = pen.get_screen_data()
	local massive_balls_x, massive_balls_y = w/view_w, h/view_h
	
	if( in_reverse ) then x, y = x/massive_balls_x, y/massive_balls_y end
	if( not( is_raw )) then
		local cam_x, cam_y = GameGetCameraPos()
		local _,_, cam_w, cam_h = GameGetCameraBounds()
		local off_w = tonumber( MagicNumbersGetValue( "VIRTUAL_RESOLUTION_OFFSET_X" ))
		local off_h = tonumber( MagicNumbersGetValue( "VIRTUAL_RESOLUTION_OFFSET_Y" ))
		
		local off_x, off_y = cam_x - cam_w/2 - off_w, cam_y - cam_h/2 - off_h
		if( in_reverse ) then off_x, off_y = -off_x, -off_y end
		x, y = x - off_x, y - off_y
	end
	if( not( no_shake or is_raw )) then
		local shake_x, shake_y = pen.get_camera_shake( w, h, real_w, real_h )
		if( in_reverse ) then shake_x, shake_y = -shake_x, -shake_y end
		x, y = x + shake_x, y + shake_y
	end
	if( not( in_reverse )) then x, y = x*massive_balls_x, y*massive_balls_y end

	return x, y, { massive_balls_x, massive_balls_y }
end

function pen.gui2world( pic_x, pic_y, is_raw )
    return pen.world2gui( pic_x, pic_y, is_raw, nil, true )
end

function pen.pic_wiper( pic_id, wh )
	for i = 0,( wh[1] - 1 ) do
		for e = 0,( wh[2] - 1 ) do
			ModImageSetPixel( pic_id, i, e, 0x0 )	
		end
	end
end
function pen.pic_paster( new_id, old_id, wh, new_xy, old_xy )
	new_xy, old_xy = new_xy or { 0, 0 }, old_xy or { 0, 0 }
	for i = 0,( wh[1] - 1 ) do
		for e = 0,( wh[2] - 1 ) do
			local pixel = ModImageGetPixel( old_id, old_xy[1] + i, old_xy[2] + e )
			ModImageSetPixel( new_id, new_xy[1] + i, new_xy[2] + e, pixel )
		end
	end
	return new_id
end
function pen.pic_cloner( old_pic, new_pic, dims )
	local old_id, old_w, old_h = pen.magic_draw( old_pic, 0, 0 )
	local new_id, new_w, new_h = pen.magic_draw( new_pic, dims[1] or old_w, dims[2] or old_h )
	return pen.pic_paster( new_id, old_id, { math.min( old_w, new_w ), math.min( old_h, new_h )}), new_pic
end
function pen.pic_builder( pic, w, h ) --apocalyptic thanks to Lamia and dextercd
	if( pen.is_game_restarted()) then pen.setting_set( pen.SETTING_PPB, "" ) end

	local pic_builder_memo = pen.t.parse( pen.setting_get( pen.SETTING_PPB )) or {}
	local raw_id = string.gsub( string.gsub( pic, ".png$", "" ), "_ppb%d-$", "" )
	if( ModImageMakeEditable == nil ) then
		if( pic_builder_memo[ raw_id ] == nil or w == nil ) then return end
		return pic_builder_memo[ raw_id ][ table.concat({( w or -1 ), "|", ( h or -1 )})]
	else pic_builder_memo[ raw_id ] = pic_builder_memo[ raw_id ] or { count = 0 } end

	local do_it = w ~= nil
	if( ModDoesFileExist( pic )) then
		local _, pic_w, pic_h = pen.magic_draw( pic, w or 0, h or 0 )
		w, h = w or pic_w, h or pic_h
		if( pic_w == w and pic_h == h ) then
			do_it = 1
		else do_it = true end
	elseif( not( do_it )) then return end

	local pic_id = table.concat({ w, "|", h })
	local count = pic_builder_memo[ raw_id ].count
	if( do_it == true and pic_builder_memo[ raw_id ][ pic_id ] ~= nil ) then
		pic_id = table.concat({ "c"..count, "|", "c"..count })
	end
	
	if( do_it == true ) then
		local pic_memo = pic_builder_memo[ raw_id ][ pic_id ]
		if( pic_memo == nil ) then
			pic_builder_memo[ raw_id ].count = count + 1
			pic_builder_memo[ raw_id ][ pic_id ] = string.lower( table.concat({
				raw_id, "_ppb", pic_builder_memo[ raw_id ].count, ".png" }))
			pen.setting_set( pen.SETTING_PPB, pen.t.parse( pic_builder_memo ))
		else return ModImageIdFromFilename( pic_memo ), pic_memo end
		
		pic_id, pic = pen.pic_cloner( pic, pic_builder_memo[ raw_id ][ pic_id ], { w, h })
	else pic_id = ModImageIdFromFilename( pic ) end
	return pic_id, pic
end

function pen.new_interface( pic_x, pic_y, s_x, s_y, pic_z, data )
	data = data or {}
	local frame_num = GameGetFrameNum()
	local clicked, r_clicked = false, false
	local lmb_state, rmb_state = InputIsMouseButtonDown( 1 ), InputIsMouseButtonDown( 2 )

	local function safety_update()
		local safety = {
			{ pen.GLOBAL_INTERFACE_SAFETY_TL, pen.GLOBAL_INTERFACE_SAFETY_LL, lmb_state },
			{ pen.GLOBAL_INTERFACE_SAFETY_TR, pen.GLOBAL_INTERFACE_SAFETY_LR, rmb_state },
		}
		for i,v in ipairs( safety ) do
			local safety_frame = tonumber( GlobalsGetValue( v[1], "0" ))
			if( math.abs( safety_frame ) ~= frame_num ) then
				GlobalsSetValue( v[2], safety_frame )
				GlobalsSetValue( v[1], ( v[3] and -1 or 1 )*frame_num )
			end
		end
	end
	
	local update_frame = tonumber( GlobalsGetValue( pen.GLOBAL_INTERFACE_FRAME_Z, "0" ))
	local top_z = tonumber( GlobalsGetValue( pen.GLOBAL_INTERFACE_Z, "nope" ))
	local is_figuring = top_z ~= nil
	if( is_figuring and frame_num - update_frame > 2 ) then
		GameRemoveFlagRun( pen.FLAG_INTERFACE_TOGGLE ); GlobalsSetValue( pen.GLOBAL_INTERFACE_MEMO, "" ) end
	local interface_memo = is_figuring and pen.t.parse( GlobalsGetValue( pen.GLOBAL_INTERFACE_MEMO, "" )) or {}
	
	if( pic_z ~= nil and not( is_figuring )) then safety_update() end
	local got_cutter = pen.vld( pen.c.cutter_dims )

	local is_hovered = false
	local is_inside = not( got_cutter )
	local local_x, local_y = pic_x, pic_y
	local m_x, m_y = pen.get_mouse_pos()
	local m_pos = interface_memo.m or { m_x, m_y }
	local got_dragger = tonumber( GlobalsGetValue( pen.GLOBAL_DRAGGER_SAFETY, "1" )) > 0
	if( not( is_inside )) then is_inside = pen.check_bounds( m_pos, pen.c.cutter_dims.wh, pen.c.cutter_dims.xy ) end
	if( is_inside and ( got_dragger or not( data.ignore_multihover ))) then
		if( got_cutter ) then pic_x, pic_y = pen.c.cutter_dims.xy[1] + pic_x, pen.c.cutter_dims.xy[2] + pic_y end
		is_hovered = pen.check_bounds( m_pos, { s_x, s_y }, { pic_x, pic_y, data.angle }, data.distance_func )
	end
	
	if( is_hovered ) then
		if( data.is_debugging ) then
			pen.new_pixel( local_x, local_y, 10*pen.LAYERS.TIPS, {255,100,100,0.75}, s_x, s_y, nil, data.angle )
		end
		
		local size = 500
		local gui = pen.gui_builder()
		pen.c.gui_data.i = pen.c.gui_data.i + 1
		GuiZSetForNextWidget( gui, 10*pen.LAYERS.TIPS )
		GuiImage( gui, pen.c.gui_data.i, m_x - size, m_y - size, pen.FILE_PIC_NIL, 1, size, size, data.angle or 0 )

		local is_new = tonumber( GlobalsGetValue( pen.GLOBAL_INTERFACE_FRAME, "0" )) ~= frame_num
		local no_left = tonumber( GlobalsGetValue( pen.GLOBAL_INTERFACE_SAFETY_LL, "0" )) > 0
		local no_right = tonumber( GlobalsGetValue( pen.GLOBAL_INTERFACE_SAFETY_LR, "0" )) > 0
		if( not( is_figuring ) and pic_z == nil ) then --safety won't work since vanilla ui is clicked on up
			if( is_new ) then clicked, r_clicked = GuiGetPreviousWidgetInfo( gui ) end
		elseif( pic_z ~= nil and no_left and no_right ) then
			clicked, r_clicked = lmb_state, rmb_state
			if( not( clicked or r_clicked )) then GameAddFlagRun( pen.FLAG_INTERFACE_TOGGLE ) end

			local down_toggle = GameHasFlagRun( pen.FLAG_INTERFACE_TOGGLE )
			if( not( down_toggle ) or is_figuring or not( is_new )) then clicked, r_clicked = false, false end
			if( is_figuring and frame_num - update_frame > 1 and pen.eps_compare( pic_z, top_z, 0.001 )) then
				clicked, r_clicked = interface_memo.lc, interface_memo.rc
				GlobalsSetValue( pen.GLOBAL_INTERFACE_Z, "nope" )
				GameRemoveFlagRun( pen.FLAG_INTERFACE_TOGGLE )
				return clicked, r_clicked, true
			end

			if(( not( is_figuring ) and ( clicked or r_clicked )) or ( is_figuring and pic_z < top_z )) then
				if( not( is_figuring )) then
					GameRemoveFlagRun( pen.FLAG_INTERFACE_TOGGLE )
					interface_memo = { lc = clicked, rc = r_clicked, m = m_pos }
					GlobalsSetValue( pen.GLOBAL_INTERFACE_MEMO, pen.t.parse( interface_memo ))
				end

				GlobalsSetValue( pen.GLOBAL_INTERFACE_FRAME_Z, frame_num )
				GlobalsSetValue( pen.GLOBAL_INTERFACE_Z, pic_z )
				clicked, r_clicked = false, false
			end
		end

		GlobalsSetValue( pen.GLOBAL_INTERFACE_FRAME, frame_num )
		is_hovered = is_new or not( data.ignore_multihover )
	end

	return clicked, r_clicked, is_hovered
end

function pen.new_pixel( pic_x, pic_y, pic_z, color, s_x, s_y, alpha, angle )
	local gui = pen.gui_builder()
	GuiZSetForNextWidget( gui, pic_z )
	GuiOptionsAddForNextWidget( gui, 2 ) --NonInteractive
	pen.c.gui_data.i = pen.c.gui_data.i - 1

	color = color or pen.PALETTE.W
	GuiColorSetForNextWidget( gui, color[1]/255, color[2]/255, color[3]/255, 1 )
	GuiImage( gui, 1020, pic_x, pic_y, pen.FILE_PIC_NUL, alpha or color[4] or 1, ( s_x or 1 )/2, ( s_y or 1 )/2, angle or 0 )
end

function pen.new_image( pic_x, pic_y, pic_z, pic, data )
	if( not( pen.vld( pic ))) then return end
	
	data = data or {}
	pen.c.anim_guis = pen.c.anim_guis or {}
	local off_x, off_y, angle = 0, 0, data.angle or 0
	local w, h, xml_offs, is_anim = pen.get_pic_dims({ pic, data.anim }, data.update_xml )
	if( xml_offs ) then off_x, off_y = pen.rotate_offset( xml_offs[1], xml_offs[2], angle ) end
	
	local s_x, s_y = data.s_x or 1, data.s_y or 1; w, h = s_x*w, s_y*h
	if( data.is_centered ) then
		local drift_x, drift_y = pen.rotate_offset( -w/2, -h/2, angle )
		pic_x, pic_y = pic_x + drift_x, pic_y + drift_y
	end

	local is_inside = pen.vld( pen.c.cutter_dims )
	if( is_inside ) then
		local r_w, r_h = pen.rotate_offset( w, h, angle )
		local real_x = pen.c.cutter_dims.xy[1] + pic_x
		if( r_w*pic_x < 0 ) then real_x = real_x + r_w end
		local real_y = pen.c.cutter_dims.xy[2] + pic_y
		if( r_h*pic_y < 0 ) then real_y = real_y + r_h end
		if( not( pen.check_bounds({ real_x, real_y }, pen.c.cutter_dims.wh, pen.c.cutter_dims.xy ))) then return end
	end
	
	local uid = data.auid
	local gui = pen.c.anim_guis[ uid ]
	local will_anim = is_anim and uid
	if( not( will_anim ) and gui ) then
		GuiDestroy( gui ); pen.c.anim_guis[ uid ] = nil
	end

	if( will_anim ) then
		gui = gui or GuiCreate()
		pen.c.anim_guis[ uid ] = gui
		GuiStartFrame( gui ); uid = 1
	else gui, uid = pen.gui_builder() end
	
	pen.colourer( gui, data.color )
	GuiZSetForNextWidget( gui, pic_z )
	GuiOptionsAddForNextWidget( gui, 2 ) --NonInteractive
	GuiImage( gui, uid, pic_x + s_x*off_x, pic_y + s_y*off_y, pic,
		data.alpha or 1, s_x, s_y, angle, data.anim_type or 2, data.anim or "" )
	if( data.has_shadow ) then
		local ss_x, ss_y = 1/w + 1, 1/h + 1
		pen.colourer( gui, pen.PALETTE.SHADOW )
		GuiZSetForNextWidget( gui, pic_z + 0.001 )
		GuiOptionsAddForNextWidget( gui, 2 ) --NonInteractive
		GuiImage( gui, uid, pic_x - 0.5, pic_y - 0.5, pic,
			0.5*( data.alpha or 1 ), ss_x, ss_y, data.angle or 0, data.anim_type or 2, data.anim or "" )
	end

	if( not( data.can_click )) then return end
	if( data.skip_z_check ) then pic_z = nil end
	return pen.new_interface( pic_x, pic_y, w, h, pic_z, data )
end

---Button framework.
---@param pic_x number
---@param pic_y number
---@param pic_z number
---@param pic path
---@param data? PenmanButtonData
---@return boolean clicked, boolean r_clicked, boolean is_hovered
function pen.new_button( pic_x, pic_y, pic_z, pic, data )
	data = data or {}
	data.no_anim = data.no_anim or false
	data.auid = data.auid or table.concat({ pic, pic_z })
	
	data.pic_func = data.pic_func or function( pic_x, pic_y, pic_z, pic, d )
		local a = ( d.no_anim or false ) and 1 or math.min(
			pen.animate( 1, d.auid.."l", { type = "sine", frames = d.frames, stillborn = true }),
			pen.animate( 1, d.auid.."r", { ease_out = "sin3", frames = d.frames, stillborn = true }))
		local s_anim = {( 1 - a )/d.dims[1], ( 1 - a )/d.dims[2] }

		if( not( d.is_centered )) then
			pic_x = pic_x + ( d.s_x or 1 )*d.dims[1]/2
			pic_y = pic_y + ( d.s_y or 1 )*d.dims[2]/2 end
		return pen.new_image( pic_x, pic_y, pic_z, pic, { is_centered = true,
			s_x = ( d.s_x or 1 )*( 1 - s_anim[1]), s_y = ( d.s_y or 1 )*( 1 - s_anim[2]), angle = d.angle })
	end

	local pic_iz = pic_z
	if( data.skip_z_check ) then pic_iz = nil end
	data.dims = { pen.get_pic_dims( pen.get_hybrid_table( pic )[1], data.update_xml )}

	local off_x, off_y = 0, 0
	local w, h = data.dims[1]*( data.s_x or 1 ), data.dims[2]*( data.s_y or 1 )
	if( data.is_centered ) then off_x, off_y = pen.rotate_offset( -w/2, -h/2, data.angle ) end
	data.clicked, data.r_clicked, data.is_hovered = pen.new_interface( pic_x + off_x, pic_y + off_y, w, h, pic_iz, data )

	if( data.lmb_event ~= nil and data.clicked ) then
		pic_x, pic_y, pic_z, pic, data = data.lmb_event( pic_x, pic_y, pic_z, pic, data ) end
	if( data.rmb_event ~= nil and data.r_clicked ) then
		pic_x, pic_y, pic_z, pic, data = data.rmb_event( pic_x, pic_y, pic_z, pic, data ) end
	if( data.hov_event ~= nil and data.is_hovered ) then
		pic_x, pic_y, pic_z, pic, data = data.hov_event( pic_x, pic_y, pic_z, pic, data )
	elseif( data.idle_event ~= nil ) then
		pic_x, pic_y, pic_z, pic, data = data.idle_event( pic_x, pic_y, pic_z, pic, data ) end
	data.pic_func( pic_x, pic_y, pic_z, pic, data )
	return data.clicked, data.r_clicked, data.is_hovered
end

function pen.new_dragger( did, pic_x, pic_y, s_x, s_y, pic_z, data )
	data = data or {}
	pen.c.dragger_data = pen.c.dragger_data or {}
	pen.c.dragger_data[ did ] = pen.c.dragger_data[ did ] or { is_going = false, old_state = true, off = {0,0}}
	
	local frame_num = GameGetFrameNum()
	local is_new = math.abs( tonumber( GlobalsGetValue( pen.GLOBAL_DRAGGER_SAFETY, "0" ))) ~= frame_num
	if( not( is_new )) then return pic_x, pic_y, 0 end

	local m_x, m_y = pen.get_mouse_pos()
	-- pen.c.dragger_data[ did ].old_pos = pen.c.dragger_data[ did ].old_pos or { m_x, m_y }
	-- local d_x, d_y = m_x - pen.c.dragger_data[ did ].old_pos[1], m_y - pen.c.dragger_data[ did ].old_pos[2]
	-- pen.c.dragger_data[ did ].old_pos = { m_x, m_y }
	
	local clicked = false
	local is_going = pen.c.dragger_data[ did ].is_going
	local real_clicked, r_clicked, is_hovered = pen.new_interface( pic_x, pic_y, s_x, s_y, pic_z, data )
	if( not( is_going ) and data.no_dragging ) then return pic_x, pic_y, 0, real_clicked, r_clicked, is_hovered end

	local state = 0
	local mouse_state = InputIsMouseButtonDown( 1 )
	if( is_going ) then
		if( mouse_state ) then
			state = 2
			pic_x = m_x + pen.c.dragger_data[ did ].off[1]
			pic_y = m_y + pen.c.dragger_data[ did ].off[2]
		else
			state = -1
			pen.c.dragger_data[ did ] = nil
			GlobalsSetValue( pen.GLOBAL_DRAGGER_SAFETY, 1 )
		end
	elseif( is_hovered and ( mouse_state and not( pen.c.dragger_data[ did ].old_state ))) then
		clicked, state = true, 1
		pen.c.dragger_data[ did ].is_going = true
		pen.c.dragger_data[ did ].old_state = true
		pen.c.dragger_data[ did ].off = not( data.no_offs ) and { pic_x - m_x, pic_y - m_y } or { 0, 0 }
	else pen.c.dragger_data[ did ].old_state = mouse_state end
	
	if( state > 0 ) then
		GlobalsSetValue( pen.GLOBAL_DRAGGER_SAFETY, (( data.allow_multihovers or false ) and 1 or -1 )*frame_num ) end
	return pic_x, pic_y, state, clicked, r_clicked, is_hovered
end

function pen.uncutter( func )
	local _,_,_,orig_gui = pen.gui_builder( GuiCreate())

	local x, y = unpack( pen.c.cutter_dims.xy )
	local w, h = unpack( pen.c.cutter_dims.wh )
	pen.c.cutter_dims = nil
	local out = { func( x, y, w, h )}
	pen.c.cutter_dims = { xy = { x, y }, wh = { w, h }}
	
	pen.gui_builder( false )
	if( orig_gui ) then pen.gui_builder( orig_gui ) end
	return unpack( out )
end
function pen.new_cutout( pic_x, pic_y, size_x, size_y, func, data ) --credit goes to aarvlo
	local margin = 0
	local gui, uid = pen.gui_builder()

	GuiAnimateBegin( gui )
	GuiAnimateAlphaFadeIn( gui, uid, 0, 0, true )
	GuiBeginAutoBox( gui )
	GuiOptionsAddForNextWidget( gui, 50 ) --ScrollContainer_Smooth
	GuiBeginScrollContainer( gui, uid, pic_x - margin, pic_y - margin, size_x, size_y, false, margin, margin )
	GuiEndAutoBoxNinePiece( gui )
	GuiAnimateEnd( gui )
	
	local got_some = pen.vld( pen.c.cutter_dims )
	pen.c.cutter_dims_memo = pen.c.cutter_dims_memo or {}
	if( got_some ) then table.insert( pen.c.cutter_dims_memo, pen.t.clone( pen.c.cutter_dims )) end
	pen.c.cutter_dims = { xy = { pic_x, pic_y }, wh = { size_x, size_y }}
	
	local height = func( data )
	
	if( got_some ) then
		pen.c.cutter_dims = table.remove( pen.c.cutter_dims_memo, #pen.c.cutter_dims_memo )
	else pen.c.cutter_dims = nil end
	GuiEndScrollContainer( gui )
	return height
end

function pen.unscroller() --huge thanks to Lamia for inspiration
	local frame_num = GameGetFrameNum()
	if( tonumber( GlobalsGetValue( pen.GLOBAL_UNSCROLLER_SAFETY, "0" )) ~= frame_num ) then
		GlobalsSetValue( pen.GLOBAL_UNSCROLLER_SAFETY, frame_num )
	else return end

	local m_x, m_y = pen.get_mouse_pos()
	local gui, uid = pen.gui_builder()
	uid = uid + 2*( 1 + frame_num%3 )
	pen.c.gui_data.i = uid

	GuiAnimateBegin( gui )
	GuiAnimateAlphaFadeIn( gui, uid, 0, 0, true )
	GuiOptionsAddForNextWidget( gui, 47 ) --NoSound
	GuiOptionsAddForNextWidget( gui, 3 ) --AlwaysClickable
	GuiBeginScrollContainer( gui, uid, m_x - 25, m_y - 25, 50, 50, false, 0, 0 )
	GuiAnimateEnd( gui )
	GuiEndScrollContainer( gui )
end
function pen.new_scroller( sid, pic_x, pic_y, pic_z, size_x, size_y, func, data )
	func = pen.get_hybrid_table( func )
	func[2] = func[2] or function( pic_x, pic_y, pic_z, bar_size, bar_pos, data )
		local out = {}
		local color = data.color or {
			pen.PALETTE.VNL.NINE_MAIN, pen.PALETTE.VNL.NINE_ACCENT,
			pen.PALETTE.VNL.NINE_MAIN_DARK, pen.PALETTE.VNL.NINE_ACCENT_DARK,
			pen.PALETTE.VNL.NINE_MAIN, pen.PALETTE.VNL.NINE_ACCENT,
			pen.PALETTE.VNL.NINE_MAIN_DARK, pen.PALETTE.VNL.NINE_ACCENT_DARK,
			pen.PALETTE.VNL.NINE_MAIN, pen.PALETTE.VNL.NINE_ACCENT,
			pen.PALETTE.VNL.NINE_MAIN_DARK, pen.PALETTE.VNL.NINE_ACCENT_DARK,
			{0,0,0,0.83}
		}
		color[14] = color[14] or color[13]

		local _,new_y,state,_,_,is_hovered = pen.new_dragger( sid.."_dragger", pic_x, bar_pos, 3, bar_size, pic_z )
		pen.new_pixel( pic_x + 1, bar_pos, pic_z, color[ is_hovered and 14 or 13 ], 1, bar_size )
		pen.new_pixel( pic_x, bar_pos, pic_z, color[ is_hovered and 2 or 1 ], 1, bar_size )
		pen.new_pixel( pic_x + 2, bar_pos, pic_z, color[ is_hovered and 4 or 3 ], 1, bar_size )
		out[1] = { new_y, state }
		
		local clicked, r_clicked = false, false
		clicked, r_clicked, is_hovered = pen.new_interface( pic_x, pic_y, 3, 3, pic_z )
		pen.new_pixel( pic_x + 1, pic_y + 1, pic_z, color[ is_hovered and 14 or 13 ])
		pen.new_pixel( pic_x + 1, pic_y, pic_z, color[ is_hovered and 6 or 5 ])
		pen.new_pixel( pic_x, pic_y + 1, pic_z, color[ is_hovered and 6 or 5 ])
		pen.new_pixel( pic_x + 2, pic_y + 1, pic_z, color[ is_hovered and 8 or 7 ])
		if( data.can_scroll and ( InputIsMouseButtonDown( 4 ) or InputIsKeyJustDown( 86 ))) then clicked = 1 end
		out[2] = { clicked, r_clicked }

		clicked, r_clicked, is_hovered = pen.new_interface( pic_x, pic_y + size_y - 3, 3, 3, pic_z )
		pen.new_pixel( pic_x + 1, pic_y + size_y - 2, pic_z, color[ is_hovered and 14 or 13 ])
		pen.new_pixel( pic_x + 1, pic_y + size_y - 1, pic_z, color[ is_hovered and 10 or 9 ])
		pen.new_pixel( pic_x, pic_y + size_y - 2, pic_z, color[ is_hovered and 10 or 9 ])
		pen.new_pixel( pic_x + 2, pic_y + size_y - 2, pic_z, color[ is_hovered and 12 or 11 ])
		if( data.can_scroll and ( InputIsMouseButtonDown( 5 ) or InputIsKeyJustDown( 87 ))) then clicked = 1 end
		out[3] = { clicked, r_clicked }
		
		return out
	end
	
	data = data or {}
	if( data.scroll_always ) then
		data.can_scroll = true
	elseif( data.scroll_always ~= false ) then
		_,_,data.can_scroll = pen.new_interface( pic_x, pic_y, size_x + 5, size_y, pic_z )
	end

	pen.c.scroll_memo = pen.c.scroll_memo or {}
	pen.c.scroll_memo[ sid ] = pen.c.scroll_memo[ sid ] or {}
	pen.c.scroll_memo[ sid ].m = pen.c.scroll_memo[ sid ].m or {}

	local progress = pen.c.scroll_memo[ sid ].p or 0
	local old_height = pen.c.scroll_memo[ sid ].h or 1
	local scroll_pos = ( size_y - old_height )*progress
	local new_height = pen.new_cutout( pic_x, pic_y, size_x, size_y, func[1], scroll_pos )
	if( new_height > size_y ) then
		if( data.can_scroll ) then pen.unscroller() end
	else return end

	local bar_size = pen.rounder( math.max(( size_y - 6 )*math.min( size_y/new_height, 1 ), 1 ), -2 )
	
	local bar_y = ( size_y - ( 6 + bar_size ))
	local bar_pos = pic_y + bar_y*progress + 3
	local step = bar_y*( data.scroll_step or 11 )/( new_height - size_y )
	local out = func[2]( pic_x + size_x, pic_y, pic_z - 0.01, bar_size, bar_pos, data )
	local new_y = out[1][1]
	
	local discrete_target = pen.c.scroll_memo[ sid ].t
	if( discrete_target ~= nil ) then
		if( discrete_target == new_y ) then
			pen.c.scroll_memo[ sid ].t = nil
		else new_y = discrete_target end
	end

	local k = pen.c.scroll_memo[ sid ].m or 1
	pen.c.scroll_memo[ sid ].m = ( out[2][1] or out[3][1]) and 2*k or 1
	
	for i = 2,3 do
		if( out[i][1]) then
			if( i == 2 ) then
				pen.c.scroll_memo[ sid ].t = math.max( new_y - step*k, pic_y + 3 )
			else pen.c.scroll_memo[ sid ].t = math.min( new_y + step*k, pic_y + bar_y + 3 ) end
		elseif( out[i][2]) then pen.c.scroll_memo[ sid ].t = pic_y + 3 + ( i == 3 and bar_y or 0 ) end
		if( out[i][1] or out[i][2]) then
			pen.play_sound( pen.TUNES.VNL[ out[i][1] == 1 and "HOVER" or ( out[i][2] and "CLICK" or "SELECT" )])
		end
	end

	local buffer = 1
	local eid = sid.."_anim"
	progress = math.min( math.max(( new_y - ( pic_y + 3 ))/bar_y, -buffer ), 1 + buffer )
	progress = pen.estimate( eid, progress, "wgt0.75", 0.001, 0.02*step )
	
	local is_waiting = GameGetFrameNum()%7 ~= 0
	local is_clipped = progress > 0 and progress < 1
	local is_static = out[1][2] ~= 2 or pen.eps_compare( new_y, bar_pos )
	if( not( is_clipped )) then
		pen.c.estimator_memo[ eid ] = math.min( math.max( pen.c.estimator_memo[ eid ], 0 ), 1 )
	elseif( not( is_static or is_waiting )) then pen.play_sound( pen.TUNES.VNL.HOVER ) end

	pen.c.scroll_memo[ sid ].p = math.min( math.max( progress, 0 ), 1 )
	if( old_height ~= new_height ) then
		local ratio = old_height/new_height
		pen.c.scroll_memo[ sid ].p = ratio*pen.c.scroll_memo[ sid ].p
		pen.c.scroll_memo[ sid ].h = new_height
	end
end

function pen.new_text( pic_x, pic_y, pic_z, text, data )
	data = data or {}
	data.alpha = data.alpha or 1
	data.scale, data.font_mods = 1, data.font_mods or {}
	local dims, is_pixel_font, new_line = {}, false, 9
	data.font, is_pixel_font = pen.font_cancer( data.font, data.is_huge )
	
	if( pen.vld( data.dims )) then
		data.dims = pen.get_hybrid_table( data.dims ); data.dims[2] = data.dims[2] or -1
		text, dims, new_line = pen.liner( text, data.dims[1]/data.scale, data.dims[2]/data.scale, data.font, {
			nil_val = data.nil_val,
			aggressive = data.aggressive,
			line_offset = data.line_offset,
		})
	else
		text, dims, new_line = pen.liner( text, nil, nil, data.font, {
			nil_val = data.nil_val,
			line_offset = data.line_offset,
		})
		data.dims = dims
	end
	
	local gui = pen.gui_builder()
	local function shadowed_text( pic_x, pic_y, pic_z, txt, scale, font, is_pixel, color, alpha, has_shadow )
		local gui = pen.c.gui_data.g
		GuiZSetForNextWidget( gui, pic_z )
		pen.colourer( gui, color, alpha )
		GuiText( gui, pic_x, pic_y, txt, scale, font, is_pixel )
		if( not( has_shadow )) then return end
		GuiZSetForNextWidget( gui, pic_z + 0.001 )
		pen.colourer( gui, pen.PALETTE.SHADOW, 0.5*alpha )
		GuiText( gui, pic_x + scale/2, pic_y + scale/2, txt, scale, font, is_pixel )
	end
	
	local off_x = 0 --( data.is_centered_x or false ) and -math.abs( data.dims[1])/2 or 0
	local off_y = ( data.is_centered_y or false ) and -math.max( data.dims[2], dims[2])/2 or 0
	if( not( data.fully_featured )) then
		if( data.is_centered_x or data.is_right_x ) then pic_x = pic_x - dims[1]/( data.is_right_x and 1 or 2 ) end
		for i,t in ipairs( text ) do
			shadowed_text( pic_x + off_x, pic_y + ( i - 1 )*new_line + off_y, pic_z,
				t, data.scale, data.font, is_pixel_font, data.color, data.alpha, data.has_shadow )
		end
		return dims
	end
	
	local structure = pen.cache({ "metafont",
		pen.b2n( data.is_centered_x ), pen.b2n( data.is_right_x ),
		data.dims[1], data.dims[2], table.concat( text, "|" ), data.font,
	}, function()
		local out = {}
		
		local func_list, height_counter = {}, 0
		for i,line in ipairs( text ) do
			local temp = line
			local l_pos, r_pos = {0,0,0}, {0,0,0}
			local new_element = { x = 0, y = height_counter }
			if( data.is_centered_x or data.is_right_x ) then
				local _,off = pen.liner( line, nil, nil, data.font )
				new_element.x = -off[1]/( data.is_right_x and 1 or 2 )
			end
			
			while( pen.vld( temp )) do
				local gotcha = 0
				for i = 1,2 do l_pos[i], r_pos[i] = string.find( temp, pen.MARKER_FANCY_TEXT[i]) end
				if( l_pos[1] ~= nil and l_pos[1] < ( l_pos[2] or #temp )) then
					gotcha = 1
				elseif( l_pos[2] ~= nil ) then
					gotcha = -1
					l_pos[1], r_pos[1] = l_pos[2], r_pos[2]
				end
				new_element.text = string.sub( temp, 1, ( l_pos[1] or 0 ) - 1 )
				new_element.f = pen.t.clone( func_list )
				table.insert( out, pen.t.clone( new_element ))
				
				if( gotcha ~= 0 ) then
					new_element.x = new_element.x + pen.get_text_dims(
						string.gsub( new_element.text, pen.MARKER_FANCY_TEXT[3], "" ), data.font, is_pixel_font )
					
					if( gotcha > 0 ) then
						table.insert( func_list, string.sub( temp, l_pos[1] + 2, r_pos[1] - 2 ))
					elseif( gotcha < 0 and pen.vld( func_list )) then
						local _,id = pen.t.get( func_list, string.sub( temp, l_pos[1] + 2, r_pos[1] - 2 ))
						if( pen.vld( id )) then
							table.remove( func_list, id )
						else func_list = {} end
					end
				end

				l_pos[3] = 0
				while( l_pos[3] ~= nil ) do
					local left = out[ #out ]
					l_pos[3], r_pos[3] = string.find( left.text, pen.MARKER_FANCY_TEXT[3])
					if( l_pos[3] == nil ) then break end
					
					if( pen.vld( left.f )) then
						left.extra = left.extra or {}
						table.insert( left.extra, {
							pen.get_char_count( string.sub( left.text, 1, l_pos[3] - 1 )) + 1,
							string.sub( left.text, l_pos[3] + 3, r_pos[3] - 3 ),
						})
					end
					
					out[ #out ].text = table.concat({
						string.sub( left.text, 1, l_pos[3] - 1 ),
						string.sub( left.text, r_pos[3] + 1, -1 ),
					})
				end
				temp = r_pos[1] ~= nil and string.sub( temp, r_pos[1] + 1, -1 ) or ""
			end
			height_counter = height_counter + new_line
		end
		
		return out
	end, { reset_frame = 36000 })
	
	pen.c.font_ram = pen.c.font_ram or {}

	local c_gbl, c_lcl = 1, {}
	local is_inside = pen.vld( pen.c.cutter_dims )
	pen.t.loop( structure, function( i, element )
		if( not( pen.vld( element.text ))) then return end
		
		local pos_x = pic_x + data.scale*( off_x + element.x )
		local pos_y = pic_y + data.scale*( off_y + element.y )
		if( is_inside ) then
			local real_x = pen.c.cutter_dims.xy[1] + pos_x
			if( pos_x < 0 ) then real_x = pen.c.cutter_dims.xy[1] end
			local real_y = pen.c.cutter_dims.xy[2] + pos_y
			if( pos_y < 0 ) then real_y = real_y + new_line + 1 end
			if( not( pen.check_bounds({ real_x, real_y }, pen.c.cutter_dims.wh, pen.c.cutter_dims.xy ))) then return end
		end

		if( not( pen.vld( element.f ))) then
			c_lcl = {}
			shadowed_text( pos_x, pos_y, pic_z,
				element.text, data.scale, data.font, is_pixel_font, data.color, data.alpha, data.has_shadow )
			return
		end
		
		local new_lcl = {}
		for e,func in ipairs( element.f ) do new_lcl[ func ] = c_lcl[ func ] end
		c_lcl = new_lcl

		local orig_x, orig_y = pos_x, pos_y
		pen.w2c( element.text, function( char_id, letter_id )
			pos_x, pos_y = orig_x, orig_y
			
			local extra_list, n = {}, 1
			pen.t.loop( element.extra, function( k, v )
				if( v[1] == letter_id ) then extra_list[n] = v[2] end
			end)

			local char = pen.magic_byte( char_id )
			local clr = data.color or pen.PALETTE.W
			local font = { data.font, is_pixel_font }
			local off = { pen.get_char_dims( char, char_id, font[1])}
			for e,func in ipairs( element.f ) do
				local new_x, new_y = nil, nil
				local new_clr, new_font, new_char = {}, {}, nil
				local font_mod = data.font_mods[ func ] or pen.FONT_MODS[ func ]
				if( font_mod ~= nil ) then
					c_lcl[ func ] = ( c_lcl[ func ] or 0 ) + 1
					new_x, new_y, new_clr, new_font, new_char = font_mod(
						{ l = pos_x, g = orig_x }, { l = pos_y, g = orig_y }, pic_z,
						{ char = char, dims = off, font = font, extra = extra_list, ram = pen.c.font_ram },
						{ clr[1], clr[2], clr[3], clr[4] or data.alpha }, { gbl = c_gbl, lcl = c_lcl[ func ], chr = letter_id }
					)
				end

				if( new_x ~= nil ) then pos_x = new_x end
				if( new_y ~= nil ) then pos_y = new_y end
				if( pen.vld( new_clr )) then clr = new_clr end
				if( pen.vld( new_font )) then font = new_font end
				if( new_char ~= nil ) then char = new_char end
			end
			
			if( pen.vld( char )) then
				shadowed_text( pos_x, pos_y, pic_z, char, data.scale, font[1], font[2], clr, data.alpha, data.has_shadow )
			end

			orig_x = orig_x + off[1]
			c_gbl = c_gbl + 1
		end)
	end)
	
	pen.c.font_ram = nil

	return dims
end

function pen.new_shadowed_text( pic_x, pic_y, pic_z, text, data )
	local _,is_pixel = pen.font_cancer()
	data = data or {}; data.has_shadow = not( is_pixel )
	if( is_pixel ) then
		data.font = "data/fonts/font_pixel.xml"
		data.font = ( pen.t.unarray( pen.t.pack( GlobalsGetValue( pen.GLOBAL_FONT_REMAP, "" ))) or {})[ data.font ] or data.font
	end
	return pen.new_text( pic_x, pic_y, pic_z, text, data )
end

function pen.new_scrolling_text( sid, pic_x, pic_y, pic_z, dims, text, data )
	data, dims = data or {}, pen.get_hybrid_table( dims )
	
	local _,wh = pen.liner( text, dims[1], -1, data.font, data )
	pen.c.scrolling_text_memo = pen.c.scrolling_text_memo or {}
	pen.c.scrolling_text_memo[ sid ] = pen.c.scrolling_text_memo[ sid ] or 0
	
	local w, h = unpack( wh )
	if( w < dims[1] and h < ( dims[2] or h )) then
		data.dims = { dims[1], -1 }
		return pen.new_text( pic_x, pic_y, pic_z, text, data )
	elseif( dims[2] ~= nil ) then
		data.dims = { dims[1], -1 }
		return pen.new_scroller( sid, pic_x, pic_y, pic_z - 0.001, dims[1], dims[2], function( scroll_pos )
			local dims = pen.new_text( 0, scroll_pos, pic_z, text, data )
			return dims[2]
		end)
	end
	
	local speed = data.scroll_speed or 10
	local w, h = pen.get_text_dims( text, true, data.font )
	local type_a = function()
		local target, buffer, spacing = w - dims[1], 15, 5
		local is_right = pen.c.scrolling_text_memo[ sid ] == 0
		local shift = pen.estimate( sid.."_anim",
			is_right and ( target + buffer ) or -buffer, "exp"..tostring( 1000*speed ), 0.1, 0.75 )
		if( shift > ( target + spacing ) or shift < -spacing ) then pen.c.scrolling_text_memo[ sid ] = is_right and 1 or 0 end
		pen.new_text( -shift, h/2, pic_z, text, data )
	end
	local type_b = function()
		local gap = 10
		local pos = pen.c.scrolling_text_memo[ sid ] + speed/15
		local is_extra = ( w - pos ) < dims[1]
		if( is_extra ) then is_extra = pen.t.clone( data or {}) end
		pen.new_text( -pos, h/2, pic_z, text, data )
		if( is_extra ) then pen.new_text( -pos + gap + w, h/2, pic_z, text, is_extra ) end
		if(( pos - gap ) > w ) then pos = pos - ( w + gap ) end; pen.c.scrolling_text_memo[ sid ] = pos
	end
	pen.new_cutout( pic_x, pic_y - h/2, dims[1], 2*h, data.scroll_bouncy and type_a or type_b )
end

---Tooltip framework.
---@param text? string
---@param data? PenmanTooltipData
---@param func? fun( text?:string, d?:PenmanTooltipData ): { clicked:boolean, r_clicked:boolean, is_hovered:boolean } The definition of the custom visuals. Draws the default tip if left empty.
---@return boolean is_active, table dims, boolean is_pinned
function pen.new_tooltip( text, data, func )
	data = data or {}
	data.tid = data.tid or "dft"
	data.edging = data.edging or 2
	data.frames = data.frames or 15
	data.pic_z = data.pic_z or pen.LAYERS.TIPS
	data.allow_hover = data.allow_hover or false
	data.do_corrections = data.do_corrections or not( pen.vld( data.pos ))
	
	local function default_prefunc( text, data )
		text = pen.get_hybrid_table( text )
		
		local extra = 0
		if( pen.vld( text[2])) then
			extra = 2
			text[1] = text[1].."\n{>indent>{{>color>{{-}|VNL|GREY|{-}"..text[2].."}<color<}}<indent<}" end
		return text[1], extra, 0
	end

	local is_pinned = false
	local gui = pen.gui_builder()
	local frame_num = GameGetFrameNum()
	pen.c.ttips = pen.c.ttips or {}
	pen.c.ttips[ data.tid ] = pen.c.ttips[ data.tid ] or {
		going = 0, anim = { frame_num - 1, 0, 0 }, inter_state = {}}
	if( data.is_active == nil ) then _,_,data.is_active = GuiGetPreviousWidgetInfo( gui ) end
	if( data.allow_hover and pen.vld( pen.c.ttips[ data.tid ].inter_state )) then
		is_pinned = pen.c.ttips[ data.tid ].inter_state[3]
		data.is_active = data.is_active or pen.c.ttips[ data.tid ].inter_state[3]
	end
	if( not( data.is_active )) then return end

	if( pen.c.ttips[ data.tid ].going ~= frame_num ) then
		pen.c.ttips[ data.tid ].going = frame_num

		local tip_anim = pen.c.ttips[ data.tid ].anim
		if(( frame_num - tip_anim[2]) > ( data.frames + 5 )) then tip_anim[1] = frame_num - 1 end
		tip_anim[2], tip_anim[3] = frame_num, math.min( frame_num - tip_anim[1], data.frames )

		local off_x, off_y = 0, 0
		if( pen.vld( text ) or pen.vld( data.text_prefunc )) then
			text, off_x, off_y = ( data.text_prefunc or default_prefunc )( text, data ) end

		local w, h = GuiGetScreenDimensions( gui )
		if( not( pen.vld( data.dims ))) then
			data.dims = pen.get_tip_dims( text, { data.min_width or 121, data.max_width or 0.9*w }, h, data.line_offset or -2 )
		end
		data.dims = {
			data.dims[1] + ( off_x or 0 ),
			data.dims[2] + ( off_y or 0 )}
		data.dims[1] = data.dims[1] + 2*data.edging - 1
		data.dims[2] = data.dims[2] + 2*data.edging - 1

		local z_resolver = 0
		local mouse_drift = 5
		if( not( pen.vld( data.pos ))) then
			data.pos = { pen.get_mouse_pos()}
			if( data.is_left == nil ) then data.is_left = w < data.pos[1] + data.dims[1] + 1 end
			data.pos[1] = data.pos[1] + ( data.is_left and -1 or 1 )*mouse_drift
			if( data.is_over == nil ) then data.is_over = h < data.pos[2] + data.dims[2] + 1 end
			data.pos[2] = data.pos[2] + ( data.is_over and -1 or 1 )*mouse_drift

			if( not( data.static_z )) then
				local z_frame = tonumber( GlobalsGetValue( pen.GLOBAL_TIPZ_RESOLVER_FRAME, "0" ))
				if( z_frame ~= frame_num ) then
					GlobalsSetValue( pen.GLOBAL_TIPZ_RESOLVER, 0 )
					GlobalsSetValue( pen.GLOBAL_TIPZ_RESOLVER_FRAME, frame_num )
				else
					z_resolver = tonumber( GlobalsGetValue( pen.GLOBAL_TIPZ_RESOLVER, "0" )) - 0.015
					GlobalsSetValue( pen.GLOBAL_TIPZ_RESOLVER, z_resolver )
				end
				z_resolver = z_resolver - 1
			end
		end
		if( data.is_left ) then data.pos[1] = data.pos[1] - ( data.dims[1] + 1 ) end
		if( data.is_over ) then data.pos[2] = data.pos[2] - ( data.dims[2] + 1 ) end
		if( data.do_corrections ) then
			if( w < data.pos[1] + data.dims[1] + 1 ) then data.pos[1] = w - ( data.dims[1] + 1 ) end
			data.pos[1] = math.max( data.pos[1], 1 )
			if( h < data.pos[2] + data.dims[2] + 1 ) then data.pos[2] = h - ( data.dims[2] + 1 ) end
			data.pos[2] = math.max( data.pos[2], 1 )
		end
		data.pos[3] = data.pic_z + z_resolver
		
		func = func or function( text, d )
			local size_x, size_y = unpack( d.dims )
			local pic_x, pic_y, pic_z = unpack( d.pos )

			local inter_alpha = pen.animate( 1, d.t, { ease_out = "exp", frames = d.frames })
			if( pen.vld( text )) then
				pen.new_text( pic_x + d.edging, pic_y + d.edging - 2, pic_z, text, {
					dims = { size_x - d.edging, size_y }, line_offset = d.line_offset or -2,
					fully_featured = true, font_mods = d.font_mods, alpha = inter_alpha,
				})
			end
			
			local inter_size = 15*( 1 - pen.animate( 1, d.t, { ease_out = "wav1.5", frames = d.frames }))
			pic_x, pic_y = pic_x + 0.5*inter_size, pic_y + 0.5*inter_size
			size_x, size_y = size_x - inter_size, size_y - inter_size
			local clicked, r_clicked, is_hovered = pen.new_interface( pic_x, pic_y, size_x, size_y, pic_z )
			
			local gui, uid = pen.gui_builder()
			GuiOptionsAddForNextWidget( gui, 2 ) --NonInteractive
			GuiZSetForNextWidget( gui, pic_z + 0.01 )
			GuiImageNinePiece( gui, uid, pic_x, pic_y, size_x, size_y, 1.15*math.max( 1 - inter_alpha/6, 0.1 ))
			return clicked, r_clicked, is_hovered
		end
		
		data.t = pen.c.ttips[ data.tid ].anim[3]
		pen.c.ttips[ data.tid ].inter_state = { func( text, data )}
	else pen.c.ttips[ data.tid ].inter_state = {} end
	
	return data.is_active, data.dims, is_pinned
end

function pen.new_input( iid, pic_x, pic_y, pic_z, data )
	data = data or {}
	local _,default_dims = pen.liner( "T__________T", nil, nil, nil, { line_offset = data.line_offset or -2, })
	data.dims = data.dims or default_dims
	
	local text = ""

	--put input state to global var (comes with frame num, and if frame num there is higher than current frame num – nuke it)
	--right click to disable vanilla input
	--enter/rmb to confirm
	--legit full keyboard that is stolen from mnee
	--copypaste support (through global var)
	--multiline cursor with arrow control
	
	pen.new_tooltip( text, {
		is_active = true,
		tid = iid, pic_z = pic_z, pos = {pic_x,pic_y},
		dims = data.dims or default_dims,
		edging = data.edging, line_offset = data.line_offset
	}, data.tip_func )

	print( tostring( pen.c.ttips[iid].inter_state[1]))
	
	return
end

---Paging framework.
---@param pic_x number
---@param pic_y number
---@param pic_z number
---@param data PenmanPagerData
---@return number page, number sfx_type
function pen.new_pager( pic_x, pic_y, pic_z, data )
	data.items_per_page = data.items_per_page or 1

	local counter = 0
	if( type( data.list ) == "table" ) then
		local starter, ender = data.items_per_page*( data.page - 1 ), data.items_per_page*data.page + 1
		for k,v in ( data.order_func or pen.t.order )( data.list ) do
			counter = counter + 1
			if( data.func ~= nil ) then
				local is_hidden = not( counter > starter and counter < ender )
				if( data.func( pic_x, pic_y, pic_z, k, v, counter - starter, is_hidden )) then counter = counter - 1 end
			end
		end
	else counter = data.list + 1 end

	local sfx_type = 0
	local max_page = math.ceil(( counter - 1 )/data.items_per_page )
	for i = 1,2 do
		local sign = i == 1 and -1 or 1
		if( data.click[i] == 1 and max_page > 1 ) then
			data.page = data.page + sign; sfx_type = 1
		elseif( data.click[i] == -1 and max_page > 5 ) then
			data.page = data.page + sign*5; sfx_type = -1
		end
		if( sfx_type ~= 0 ) then
			if( data.page < 1 ) then data.page = math.max( data.page + max_page, 1 ) end
			if( data.page > max_page ) then data.page = math.min( data.page - max_page, max_page ) end
			break
		end
	end

	return data.page, sfx_type
end

function pen.new_plot( pic_x, pic_y, pic_z, data )
	data = data or {}
	data.scale = { 100, 100 }
	data.step = data.step or 0.01
	data.range = data.range or {0,1}
	data.thickness = data.thickness or 0.5
	data.func = data.func or math.sin
	data.input = data.input or function( x ) return x end

	--grid
	--cache it
	--autoscaling
	--should be capable of plotting a table

	local memo = {}
	local last_dot = {}
	local _,_,_,orig_gui = pen.gui_builder( GuiCreate())
	for x = data.range[1],( data.range[2] + data.step/2 ),data.step do
		local y = data.func( data.input( x ))
		if( pen.vld( last_dot )) then
			local delta_x, delta_y = data.step, last_dot[2] - y
			local width, rotation = data.thickness, math.atan2( delta_y, delta_x )
			local x_shift, y_shift = pen.rotate_offset( 0, -width/4, rotation )
			local pos_x, pos_y = pic_x + x_shift, pic_y - data.scale[2]*last_dot[2] + y_shift
			local length = math.sqrt(( data.scale[1]*delta_x )^2 + ( data.scale[2]*delta_y )^2 )
			pen.new_pixel( pos_x, pos_y, pic_z, data.color, length, width, nil, rotation )
			pic_x = pic_x + data.scale[1]*data.step
		end
		last_dot = { x, y }
		table.insert( memo, last_dot )
	end
	
	pen.gui_builder( false )
	if( orig_gui ) then pen.gui_builder( orig_gui ) end
	return memo
end

--[GLOBALS]
pen.FLAG_UPDATE_UTF = "PENMAN_UTF_MAP_UPDATE"
pen.FLAG_FANCY_FONT = "PENMAN_FANCY_FONTING"
pen.FLAG_RESTART_CHECK = "PENMAN_GAME_HAS_STARTED"
pen.FLAG_INTERFACE_TOGGLE = "PENMAN_INTERFACE_DOWN"

pen.GLOBAL_SCREEN_X = "PENMAN_SCREEN_X"
pen.GLOBAL_SCREEN_Y = "PENMAN_SCREEN_Y"
pen.GLOBAL_VIRTUAL_ID = "PENMAN_VIRTUAL_INDEX"
pen.GLOBAL_INTERFACE_Z = "PENMAN_INTERFACE_Z"
pen.GLOBAL_TIPZ_RESOLVER = "PENMAN_TIPZ_RESOLVER"
pen.GLOBAL_DRAGGER_SAFETY = "PENMAN_DRAGGER_FRAME"
pen.GLOBAL_INTERFACE_MEMO = "PENMAN_INTERFACE_MEMO"
pen.GLOBAL_TIPZ_RESOLVER_FRAME = "PENMAN_TIPZ_FRAME"
pen.GLOBAL_INTERFACE_FRAME = "PENMAN_INTERFACE_FRAME"
pen.GLOBAL_UNSCROLLER_SAFETY = "PENMAN_UNSCROLLER_FRAME"
pen.GLOBAL_INTERFACE_FRAME_Z = "PENMAN_INTERFACE_FRAME_Z"
pen.GLOBAL_INTERFACE_SAFETY_LL = "PENMAN_INTERFACE_SAFETY_LL"
pen.GLOBAL_INTERFACE_SAFETY_TL = "PENMAN_INTERFACE_SAFETY_TL"
pen.GLOBAL_INTERFACE_SAFETY_LR = "PENMAN_INTERFACE_SAFETY_LR"
pen.GLOBAL_INTERFACE_SAFETY_TR = "PENMAN_INTERFACE_SAFETY_TR"
pen.GLOBAL_SETTINGS_CACHE = "PENMAN_SETTINGS_CACHE"
pen.GLOBAL_FONT_REMAP = "PENMAN_FONT_REMAP"

pen.MARKER_TAB = "\\_"
pen.MARKER_FANCY_TEXT = { "{>%S->{", "}<%S-<}", "{%-}%S-{%-}" }
pen.MARKER_MAGIC_APPEND = "%-%-<{> MAGICAL APPEND MARKER <}>%-%-"

pen.FILE_PIC_NIL = "data/ui_gfx/empty.png"
pen.FILE_PIC_NUL = "data/ui_gfx/empty_white.png"
pen.FILE_MATTER = "data/debug/matter_test.xml"
pen.FILE_MATTER_COLOR = "data/debug/matter_color.xml"
pen.FILE_T2F = "data/debug/vpn"

pen.SETTING_PPB = "PENMAN.SETTING_PPB"

pen.INDEX_WRITER = "PENMAN_WRITE_INDEX"
pen.INDEX_T2F = "PENMAN_VIRTUAL_INDEX"
pen.INDEX_DRAWER = "PENMAN_PIC_INDEX"

pen.KEY = "$"
pen.HOLE = "#"
pen.DIV_0 = "@"
pen.DIV_1 = "|"
pen.DIV_2 = "!"

pen.CACHE_RESET_DELAY = 20000

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

pen.FONT_MAP = {
	["简体中文"] = {
		"data/fonts/generated/notosans_zhcn_24.bin",
		"data/fonts/generated/notosans_zhcn_20.bin",
		"data/fonts/generated/notosans_zhcn_36.bin",
	},
	["日本語"] = {
		"data/fonts/generated/notosans_jp_24.bin",
		"data/fonts/generated/notosans_jp_20.bin",
		"data/fonts/generated/notosans_jp_36.bin",
	},
	["한국어"] = {
		"data/fonts/generated/notosans_ko_24.bin",
		"data/fonts/generated/notosans_ko_20.bin",
		"data/fonts/generated/notosans_ko_36.bin",
	},
}
pen.FONT_SPACING = {
	["data/fonts/font_small_numbers.xml"] = -4,
	["data/fonts/generated/notosans_zhcn_24.bin"] = 1.5,
	["data/fonts/generated/notosans_jp_24.bin"] = 1.5,
	["data/fonts/generated/notosans_ko_24.bin"] = 1.5,
	["data/fonts/generated/notosans_zhcn_20.bin"] = 1.5,
	["data/fonts/generated/notosans_jp_20.bin"] = 1.5,
	["data/fonts/generated/notosans_ko_20.bin"] = 1.5,
	["data/fonts/generated/notosans_zhcn_36.bin"] = 2.5,
	["data/fonts/generated/notosans_jp_36.bin"] = 2.5,
	["data/fonts/generated/notosans_ko_36.bin"] = 2.5,
}
pen.FONT_MODS = {
	_bold = function( pic_x, pic_y, pic_z, char_data, color, index )
		pen.colourer( nil, color )
		GuiZSetForNextWidget( pen.c.gui_data.g, pic_z )
		local off_x, off_y = unpack( char_data.dims )
		GuiText( pen.c.gui_data.g, pic_x.l - 0.25*off_x, pic_y.l - 0.25*off_y, char_data.char, 1.25, char_data.font[1], char_data.font[2])
		return nil, nil, nil, nil, ""
	end,
	_italic = function( pic_x, pic_y, pic_z, char_data, color, index )
		--get letter pic and angle it
	end,
	crossed = function( pic_x, pic_y, pic_z, char_data, color, index ) --make this be font height related
		local off_x, off_y = unpack( char_data.dims )
		pen.new_pixel( pic_x.g - 1, pic_y.g + ( off_y - 1 )/2, pic_z + 0.001, color, ( off_x + 2 ), 1 )
	end,
	underscore = function( pic_x, pic_y, pic_z, char_data, color, index ) --make this be font height related
		local alpha = color[4]
		local new_color = color
		if( not( char_data.ram.under_color_locked ) and pen.vld( char_data.extra[1])) then
			new_color = pen.t.pack( char_data.extra[ #char_data.extra ])
			if( pen.vld( new_color )) then
				if( type( new_color[1]) == "string" ) then
					if( index.lcl == 1 and new_color[3] == "FORCED" ) then
						char_data.ram.under_color_locked = true end
					new_color = pen.PALETTE[ new_color[1]][ new_color[2]]
				end
				char_data.ram.under_color_memo = new_color
			else new_color = color end
		else new_color = char_data.ram.under_color_memo or color end
		
		local off_x, off_y = unpack( char_data.dims )
		pen.new_pixel( pic_x.g, pic_y.g + off_y*0.8, pic_z + 0.001, new_color, off_x, 1, alpha )
	end,
	shadow = function( pic_x, pic_y, pic_z, char_data, color, index )
		GuiZSetForNextWidget( pen.c.gui_data.g, pic_z + 0.0001 )
		pen.colourer( nil, pen.PALETTE.SHADOW, 0.5*(( color or {})[4] or 1 ))
		GuiText( pen.c.gui_data.g, pic_x.l + 0.6, pic_y.l + 0.6, char_data.char, 1, char_data.font[1], char_data.font[2])
	end,
	runic = function( pic_x, pic_y, pic_z, char_data, color, index )
		local new_one = char_data.char
		local new_byte = pen.magic_byte( new_one )
		if( new_byte > 10000 ) then new_one = pen.magic_byte( 65 + new_byte%57 ) end
		local font = "data/fonts/font_pixel_runes.xml"
		font = ( pen.t.unarray( pen.t.pack( GlobalsGetValue( pen.GLOBAL_FONT_REMAP, "" ))) or {})[ font ] or font
		return nil, nil, nil, { font, true }, new_one == "$" and "!" or new_one
	end,
	color = function( pic_x, pic_y, pic_z, char_data, color, index )
		local new_color = nil
		if( pen.vld( char_data.extra[1])) then
			new_color = pen.t.pack( char_data.extra[ #char_data.extra ])
			if( pen.vld( new_color )) then
				if( type( new_color[1]) == "string" ) then
					new_color = pen.PALETTE[ new_color[1]][ new_color[2]] end
				char_data.ram.color_memo = new_color
			else new_color = nil end
		else new_color = char_data.ram.color_memo end
		return nil, nil, new_color
	end,

	indent = function( pic_x, pic_y, pic_z, char_data, color, index )
		return pic_x.l + 2, pic_y.l
	end,
	wave = function( pic_x, pic_y, pic_z, char_data, color, index )
		return nil, pic_y.l + math.sin( 0.5*index.gbl + GameGetFrameNum()/7 )
	end,
	quake = function( pic_x, pic_y, pic_z, char_data, color, index )
		pic_x.l = pic_x.l + pen.generic_random( 0, 100, nil, true )/200
		pic_y.l = pic_y.l + pen.generic_random( 0, 100, nil, true )/200
		return pic_x.l, pic_y.l
	end,
	cancer = function( pic_x, pic_y, pic_z, char_data, color, index )
		local new_one = pen.magic_byte( pen.generic_random( 33, 127 ))
		return nil, nil, nil, nil, new_one == "$" and "!" or new_one
	end,
	rainbow = function( pic_x, pic_y, pic_z, char_data, color, index )
		color = pen.magic_rgb( color, false, "hsv" )
		color[1] = (( 5*index.gbl + GameGetFrameNum())%100 )/100
		color[2] = math.max( color[2], 0.5 )
		return nil, nil, pen.magic_rgb( color, true, "hsv" )
	end,
	
	button = function( pic_x, pic_y, pic_z, char_data, color, index, bid )
		local frame_num = GameGetFrameNum()
		local id_tbl = { "hyperlink_state", bid or "dft_btn" }
		local clicked, r_clicked, is_hovered = pen.cache( id_tbl, function( old_val )
			local out = old_val or { 0, 0, 0 }
			local off_x, off_y = unpack( char_data.dims )
			local clicked, r_clicked, is_hovered = pen.new_interface( pic_x.l - off_x*0.75, pic_y.l, off_x*1.5, off_y, pic_z )
			
			if( clicked ) then out[1] = frame_num end
			if( r_clicked ) then out[2] = frame_num end
			if( is_hovered ) then out[3] = frame_num + 5 end

			if( clicked or r_clicked ) then pen.play_sound( pen.TUNES.VNL.CLICK ) end
			return unpack(( clicked or r_clicked or is_hovered ) and out or {})
		end, { always_update = true, reset_count = 0 })

		if( frame_num < ( is_hovered or 0 )) then
			color = pen.magic_rgb( color, false, "hsv" )
			color[3] = 0.8*color[3]
			color = pen.magic_rgb( color, true, "hsv" )
		end
		return nil, nil, color
	end,
	tip = function( pic_x, pic_y, pic_z, char_data, color, index, tip_id, text )
		tip_id = tip_id or "dft_tip"

		local frame_num = GameGetFrameNum()
		local clicked, r_clicked, is_hovered = pen.cache({ "hyperlink_state", tip_id })
		if( index.lcl == 1 and frame_num < ( is_hovered or 0 )) then
			local off_x, off_y = unpack( char_data.dims )
			pen.new_tooltip( text, {
				tid = tip_id,
				is_active = true,
				pic_z = pic_z - 10,
				pos = { pic_x.g, pic_y.g + off_y },
			})
		end
		
		return pen.FONT_MODS.button( pic_x, pic_y, pic_z, char_data, color, index, tip_id )
	end,
	hyperlink = function( pic_x, pic_y, pic_z, char_data, color, index, link_id )
		link_id = link_id or "dft_lnk"

		local frame_num = GameGetFrameNum()
		local clicked, r_clicked, is_hovered = pen.cache({ "hyperlink_state", link_id })
		color = ( clicked or 0 ) == 0 and pen.PALETTE.VNL.MANA or pen.PALETTE.VNL.RED
		if( frame_num < ( is_hovered or 0 )) then
			pen.FONT_MODS.underscore( pic_x, pic_y, pic_z, char_data, color, index )
		end
		
		return pen.FONT_MODS.button( pic_x, pic_y, pic_z, char_data, color, index, link_id )
	end,
	_dialogue = function( pic_x, pic_y, pic_z, char_data, color, index )
		--char_data.extra for modifications (compare the index num with index.chr)
		--letters appear through alpha sin interpolating top down
	end,
}

pen.ANIM_EASINGS = { --https://easings.net/
	nul = function( t )
		return t
	end,
	flp = function( t )
		return 1 - t
	end,
	flr = function( t, a )
		return math.min( t, ( a or 0 )/10 )
	end,
	cel = function( t, a )
		return math.max( t, ( a or 0 )/10 )
	end,
	pow = function( t, a )
		return t^( a or 2 )
	end,
	sin = function( t, a )
		return math.sin( t*math.pi/2 )^( 1/( a or 1 ))
	end,
	exp = function( t, a )
		return ( a or 2 )^( 10*( t - 1 ))
	end,
	crc = function( t, a )
		return math.sqrt( 1 - t^( a or 2 ))
	end,
	bck = function( t, a )
		a = a or 1
		return t*t*(( a + 1 )*t - a )
	end,
	log = function( t, a )
		a = a or math.exp( 1 )
		return math.log(( a - 1 )*t + 1, a )
	end,
	wav = function( t, a )
		t = 2*math.pi*math.floor( a or 2 )*( t - 1 )
		return math.sin( t )/t
	end,
	rbr = function( t, a )
		t, a = 10*( t - 1 ), a or 2
		return -( math.pow( 2, t )*math.sin( a*( t - 1.5/a )*math.pi/3 ))
	end,
	bnc = function( t, a ) --https://gist.github.com/mbostock/5743979
		t, a = 1 - t, ( a or 25 )/100

		local b0 = 1 - a
		local b1 = b0*( 1 - b0 ) + b0
		local b2 = b0*( 1 - b1 ) + b1

		local x0 = 2*math.sqrt( a )
		local x1 = x0*math.sqrt( a )
		local x2 = x1*math.sqrt( a )

		local t0 = 1/( 1 + x0 + x1 + x2 )
		local t1 = t0 + t0*x0
		local t2 = t1 + t0*x1

		local m0 = t0 + t0*x0/2
		local m1 = t1 + t0*x1/2
		local m2 = t2 + t0*x2/2

		local v = 1/( t0*t0 )
		if( t >= 1 ) then
			v = 1
		elseif( t < t0 ) then
			v = v*t*t
		elseif( t < t1 ) then
			t = t - m0
			v = v*t*t + b0
		elseif( t < t2 ) then
			t = t - m1
			v = v*t*t + b1
		else
			t = t - m2
			v = v*t*t + b2
		end
		return 1 - v
	end,
}
pen.ANIM_INTERS = {
	lerp = function( t, delta )
		return delta[1] + ( delta[2] - delta[1])*t
	end,
	jump = function( t, delta, p )
		return t > ( p or 0.5 ) and delta[1] or delta[2]
	end,
	sine = function( t, delta, p )
		return delta[1] + ( delta[2] - delta[1])*( 1 + math.sin( math.pi*( t - 0.5 ))^( 2*( p or 0 ) + 1 ))/2
	end,
	bzir = function( t, delta, p )
		p = p or {}
		return delta[1]*( 1 - t )^3
			+ ( p[1] or 1 )*3*t*( 1 - t )^2
			+ ( p[2] or 0 )*3*( 1 - t )*t^2
			+ ( delta[2] - delta[1])*t^3
	end,
	lgrn = function( t, delta, p ) --https://www.geeksforgeeks.org/lagranges-interpolation/
		local out = 0
		for i,v1 in ipairs( p or {}) do
			local temp = v1[2]
			for e,v2 in ipairs( p ) do
				if( e ~= i ) then
					temp = temp*( t - v2[1])/( v1[1] - v2[1])
				end
			end
			out = out + temp
		end
		return delta[1] + ( delta[2] - delta[1])*out
	end,

	ilrp = function( t, delta )
		return ( t - delta[1])/( delta[2] - delta[1])
	end,
	spke = function( t, delta )
		return delta[1] + ( delta[2] - delta[1])*(( t < 0.5 ) and 2*t or -2*( t - 1 ))
	end,
	hill = function( t, delta, p )
		return delta[1] + ( delta[2] - delta[1])*( math.sin( t*math.pi )^( p or 1 ))
	end,
	emap = function( t, delta, p ) --thanks Nathan
		--maybe try doing actual remapping to always be within [0;1]
		--https://uploads.gamedev.net/monthly_2019_10/code.png.2b57c8e848a842330559286e38cecd03.png
		p = p or {}; local a, k = p[1] or -10, p[2] or -1.9
		return delta[1] + ( delta[2] - delta[1])*math.log(( a + 1 )/( math.exp( k*math.sin( 1.5*math.pi*t )) + a ))
	end,
}
pen.ESTIM_ALGS = { --huge thanks to Nathan
	exp = function( t, v, p )
		return ( t - v )/( p or 10 )
	end,
	hmd = function( t, v, p )
		return (( p or 2 )*v*t )/( t + v ) - v
	end,
	gmp = function( t, v, p ) --only for t,v > 0
		return math.pow( t*v, 1/( p or 2 )) - v
	end,
	wgt = function( t, v, p )
		local w = p or 1.5
		return ( v + w*t )/( 1 + w ) - v
	end,
	lsm = function( t, v, p ) --only for relatively similar values
		v = math.max( v, 0.001 )
		return ( p or 0.1 )*v*( 1 - v/math.max( t, 0.001 ))
	end,
	srt = function( t, v, p )
		return pen.get_sign( t - v )*math.pow( math.abs( t - v ), 1/( p or 1.5 ))
	end,
}

pen.SDF = { --https://iquilezles.org/articles/distfunctions2d/
	CIRCLE = function( d, p )
		return pen.V.len( d ) - p.x
	end,
	BOX = function( d, p )
		local v = pen.V.abs( d ) - p
		return pen.V.len( pen.V.max( v, 0 )) + math.min( math.max( v.x, v.y ), 0 )
	end,
	POLYGON = function( d, p )
		local n = #p - 1
		local s, j = 1, n
		local v = ( d - p[0])*( d - p[0])
		for i = 0,n do
			local e, w = p[j] - p[i], d - p[i]
			local b = w - e*math.min( math.max(( w*e )/( e*e ), 0.0 ), 1.0 )
			v = math.min( v, b*b )
			
			local c1 = d.y < p[j].y
			local c2 = d.y >= p[i].y
			local c3 = e.x*w.y > e.y*w.x
			local c = c1 == c2 and c2 == c3
			if( c ) then s = -s end
			j = i
		end
		return s*math.sqrt( v )
	end,
}

pen.PALETTE = {
	B = {0,0,0}, _="ff000000",
	W = {255,255,255}, _="ffffffff",
	SHADOW = {46,34,47}, _="ff2e222f",
	VNL = {
		HP = {135,191,28}, _="ff87bf1c",
		RED = {208,70,70}, _="ffd04646",
		GREEN = {70,208,70}, _="ff46d046",
		MANA = {66,168,226}, _="ff42a8e2",
		CAST = {252,138,67}, _="fffc8a43",
		BROWN = {121,71,56}, _="ff794738",
		DAMAGE = {166,70,56}, _="ffa64638",
		HP_LOW = {106,44,35}, _="ff6a2c23",
		DGREY = {130,130,130}, _="ff828282",
		GREY = {170,170,170}, _="ffaaaaaa",
		LGREY = {210,210,210}, _="ffd2d2d2",
		FLIGHT = {255,170,64}, _="ffffaa40",
		RUNIC = {121,201,153}, _="ff79c999",
		WARNING = {252,67,85}, _="fffc4355",
		YELLOW = {255,255,178}, _="ffffffb2",
		DARK_SLOT = {185,220,223}, _="ffb9dcdf",
		BRIGHT_SLOT = {255,0,0}, _="ffff0000",
		NINE_MAIN = {180,159,129}, _="ffb49f81",
		NINE_MAIN_DARK = {148,128,100}, _="ff948064",
		NINE_ACCENT = {237,169,73}, _="ffeda949",
		NINE_ACCENT_DARK = {201,137,48}, _="ffc98930",
		ACTION_PROJECTILE = {185,86,50}, _="ffb95632",
		ACTION_STATIC = {204,128,182}, _="ffcc80b6",
		ACTION_MODIFIER = {202,161,70}, _="ffcaa146",
		ACTION_DRAW = {168,213,218}, _="ffa8d5da",
		ACTION_MATERIAL = {142,195,115}, _="ff8ec373",
		ACTION_UTILITY = {63,132,146}, _="ff3f8492",
		ACTION_PASSIVE = {115,93,142}, _="ff735d8e",
		ACTION_OTHER = {74,68,109}, _="ff4a446d",
	},
	HRMS = {
		GOLD_1 = {205,104,61}, _="ffcd683d",
		GOLD_2 = {230,144,78}, _="ffe6904e",
		GOLD_3 = {251,185,84}, _="fffbb954",
		GREEN_1 = {35,144,99}, _="ff239063",
		GREEN_2 = {30,188,115}, _="ff1ebc73",
		GREEN_3 = {145,219,105}, _="ff91db69",
		GREY_1 = {46,34,47}, _="ff2e222f",
		GREY_2 = {105,79,98}, _="ff694f62",
		GREY_3 = {127,112,138}, _="ff7f708a",
		GREY_4 = {155,171,178}, _="ff9babb2",
		GREY_5 = {199,220,208}, _="ffc7dcd0",
		RED_1 = {110,39,39}, _="ff6e2727",
		RED_2 = {174,35,52}, _="ffae2334",
		RED_3 = {232,59,59}, _="ffe83b3b",
		BLUE_1 = {72,74,119}, _="ff484a77",
		BLUE_2 = {77,101,180}, _="ff4d65b4",
		BLUE_3 = {77,155,230}, _="ff4d9be6",
	},
	PRSP = {
		RED = {245,132,132}, _="fff58484",
		BLUE = {136,121,247}, _="ff8879f7",
		GREY = {176,176,176}, _="ffb0b0b0",
		WHITE = {238,226,206}, _="ffeee2ce",
		GREEN = {157,245,132}, _="ff9df584",
		PURPLE = {179,141,232}, _="ffb38de8",
	},
	NCRS = {
		GREY_1 = {21,29,40}, _="ff151d28",
		GREY_2 = {32,46,55}, _="ff202e37",
		GREY_3 = {57,74,80}, _="ff394a50",
		GREY_4 = {87,114,119}, _="ff577277",
		RED_1 = {65,29,49}, _="ff411d31",
		RED_2 = {117,36,56}, _="ff752438",
		RED_3 = {165,48,48}, _="ffa53030",
		RED_4 = {207,87,60}, _="ffcf573c",
		RED_5 = {218,134,62}, _="ffda863e",
		GREEN_1 = {70,130,50}, _="ff468232",
		GREEN_2 = {117,167,67}, _="ff75a743",
		GREEN_3 = {168,202,88}, _="ffa8ca58",
		GREEN_4 = {208,218,145}, _="ffd0da91",
		PURPLE_1 = {36,21,39}, _="ff241527",
		PURPLE_2 = {34,32,52}, _="ff222034",
		PURPLE_3 = {69,40,60}, _="ff45283c",
		PURPLE_4 = {122,54,123}, _="ff7a367b",
		PURPLE_5 = {162,62,140}, _="ffa23e8c",
		PURPLE_6 = {198,81,151}, _="ffc65197",
	},
	SWRD = {
		IRON_1 = {32,46,55}, _="ff202e37",
		IRON_2 = {57,74,80}, _="ff394a50",
		IRON_3 = {87,114,119}, _="ff577277",
		IRON_4 = {129,151,150}, _="ff819796",
		IRON_5 = {147,152,161}, _="ff9398a1",
		IRON_6 = {168,181,178}, _="ffa8b5b2",
		STEEL_1 = {78,84,89}, _="ff4e5459",
		STEEL_2 = {124,129,143}, _="ff7c818f",
		STEEL_3 = {143,167,188}, _="ff8fa7bc",
		STEEL_4 = {159,168,167}, _="ff9fa8a7",
		STEEL_5 = {167,181,192}, _="ffa7b5c0",
		SIGIL_1 = {128,12,83}, _="ff800c53",
		SIGIL_2 = {189,31,63}, _="ffbd1f3f",
		EPEE_1 = {56,89,179}, _="ff3859b3",
		EPEE_2 = {51,136,222}, _="ff3388de",
		FATE_1 = {30,64,88}, _="ff1e4058",
		FATE_2 = {0,101,84}, _="ff006554",
		HEIR_1 = {48,40,48}, _="ff302830",
		HEIR_2 = {72,40,42}, _="ff48282a",
		CORE_1 = {124,21,120}, _="ff7c1578",
		CORE_2 = {177,44,155}, _="ffb12c9b",
		CORE_3 = {219,48,144}, _="ffdb3090",
		CORE_4 = {214,68,158}, _="ffd6449e",
		CORE_5 = {232,86,146}, _="ffe85692",
		CORE_6 = {238,121,150}, _="ffee7996",
		CORE_7 = {230,154,167}, _="ffe69aa7",
	},
	
	--N40K: ammo types, classes, misc colors
}

pen.TUNES = {
	VNL = {
		CLICK = {"data/audio/Desktop/ui.bank","ui/button_click"},
		HOVER = {"data/audio/Desktop/ui.bank","ui/item_move_over_new_slot"},
		ERROR = {"data/audio/Desktop/ui.bank","ui/item_move_denied"},
		RESET = {"data/audio/Desktop/ui.bank","ui/replay_saved"},

		OPEN = {"data/audio/Desktop/ui.bank","ui/inventory_open"},
		CLOSE = {"data/audio/Desktop/ui.bank","ui/inventory_close"},
		BUY = {"data/audio/Desktop/event_cues.bank","event_cues/shop_item/create"},
		DROP = {"data/audio/Desktop/ui.bank","ui/item_remove"},
		PICK = {"data/audio/Desktop/event_cues.bank","event_cues/pick_item_generic/create"},
		SELECT = {"data/audio/Desktop/ui.bank","ui/item_equipped"},
		MOVE_NONE = {"data/audio/Desktop/ui.bank","ui/item_move_success"},
		MOVE_ITEM = {"data/audio/Desktop/ui.bank","ui/item_switch_places"},
	}
}

pen.LAYERS = {
	WORLD_BACK = 10110,
	WORLD = 10105,
	WORLD_FRONT = 10100,
	WORLD_UI = 500,
	
	BACKGROUND = 100,

	MAIN_DEEP = 10,
	MAIN_BACK = 5,
	MAIN = 0,
	MAIN_FRONT = -5,
	MAIN_UI = -10,

	ICONS_BACK = -10,
	ICONS = -15,
	ICONS_FRONT = -20,

	FOREGROUND = -100,

	TIPS_BACK = -10100,
	TIPS = -10105,
	TIPS_FRONT = -10110,
}

pen.INIT_THREADS = {
	WRITER = {
		name = "writer",
		index = pen.INDEX_WRITER,
		func = function( request, value )
			penman_w( request, string.gsub( value, "\\([nt])", { n = "\n", t = "\t", }))
		end,
	},
	-- DRAWER = {
	-- 	name = "drawer",
	-- 	index = pen.INDEX_DRAWER,
	-- 	func = function( request, value )
	-- 		penman_d( request, tonumber( string.sub( value, 1, 4 )), tonumber( string.sub( value, 5, -1 )))
	-- 	end,
	-- },
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

		materials_that_damage = function( comp_id, value, index )
			local out = true
			if( index == "get" ) then
				local tbl_mtr = {}
				for mtr in string.gmatch( ComponentGetValue2( comp_id, "materials_that_damage" ), pen.ptrn( "," )) do
					table.insert( tbl_mtr, mtr )
				end
				local tbl_dmg = {}
				for mtr_dmg in string.gmatch( ComponentGetValue2( comp_id, "materials_how_much_damage" ), pen.ptrn( "," )) do
					table.insert( tbl_dmg, tonumber( mtr_dmg ))
				end
				
				out = {}
				for i,mtr in ipairs( tbl_mtr ) do
					out[mtr] = tbl_dmg[i]
				end
			end
			
			local index_tbl = { set = nil, obj = false, get = true }
			return index_tbl[ index ], out
		end,
		materials_how_much_damage = function( comp_id, value, index )
			local out = true
			if( index == "set" ) then
				if( type( value ) == "table" ) then
					EntitySetDamageFromMaterial( ComponentGetEntity( comp_id ), value[1], value[2])
				else
					ComponentSetValue2( comp_id, "materials_how_much_damage", value )
				end
			end
			
			local index_tbl = { set = true, get = false, obj = nil }
			return index_tbl[ index ], out
		end,
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
			
			local index_tbl = { set = true, obj = false, get = nil }
			return index_tbl[ index ], true
		end,
		friend_thundermage = function( comp_id, value, index )
			if( index == "set" ) then
				ComponentSetValue2( comp_id, "friend_thundermage", value == 1 )
			end

			local index_tbl = { set = true, obj = false, get = nil }
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
	InheritTransformComponent = {
		Transform = function( comp_id, value, index )
			local out = true
			if( index == "set" ) then
				local entity_id = ComponentGetEntity( comp_id )
				local trans_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "InheritTransformComponent" )
				local origs = { ComponentGetValue2( trans_comp, "Transform" )}
				if( pen.t.count( value, true ) > 0 ) then
					ComponentSetValue2( trans_comp, "Transform",
						value.x or origs[1],
						value.y or origs[2],
						value.s_x or origs[3],
						value.s_y or origs[4],
						value.angle or origs[5]
					)
				end
			end

			local index_tbl = { set = true, obj = false, get = nil }
			return index_tbl[ index ], out
		end,
	},
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

			local index_tbl = { set = true, obj = false, get = nil }
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

pen.BYTE_TO_ID = {
	[0] = 0,

	[32]=32,	[33]=33,	[34]=34,	[35]=35,	[36]=36,	[37]=37,	[38]=38,	[39]=39,	[40]=40,	[41]=41,	[42]=42,
	[43]=43,	[44]=44,	[45]=45,	[46]=46,	[47]=47,	[48]=48,	[49]=49,	[50]=50,	[51]=51,	[52]=52,	[53]=53,
	[54]=54,	[55]=55,	[56]=56,	[57]=57,	[58]=58,	[59]=59,	[60]=60,	[61]=61,	[62]=62,	[63]=63,	[64]=64,
	[65]=65,	[66]=66,	[67]=67,	[68]=68,	[69]=69,	[70]=70,	[71]=71,	[72]=72,	[73]=73,	[74]=74,	[75]=75,
	[76]=76,	[77]=77,	[78]=78,	[79]=79,	[80]=80,	[81]=81,	[82]=82,	[83]=83,	[84]=84,	[85]=85,	[86]=86,
	[87]=87,	[88]=88,	[89]=89,	[90]=90,	[91]=91,	[92]=92,	[93]=93,	[94]=94,	[95]=95,	[96]=96,	[97]=97,
	[98]=98,	[99]=99,	[100]=100,	[101]=101,	[102]=102,	[103]=103,	[104]=104,	[105]=105,	[106]=106,	[107]=107,	[108]=108,
	[109]=109,	[110]=110,	[111]=111,	[112]=112,	[113]=113,	[114]=114,	[115]=115,	[116]=116,	[117]=117,	[118]=118,	[119]=119,
	[120]=120,	[121]=121,	[122]=122,	[123]=123,	[124]=124,	[125]=125,	[126]=126,	[127]=127,

	[198832]=176,	[199831]=215,	[199863]=247,	[198841]=185,	[198834]=178,	[198835]=179,	[198830]=174,	[198845]=189,
	[198844]=188,	[198823]=167,	[198818]=162,	[198819]=163,	[198821]=165,	[198838]=182,	[198833]=177,	[212096]=960,
	[198817]=161,	[198825]=169,	[198827]=171,	[198828]=172,	[198843]=187,	[198847]=191,	[199808]=192,	[199809]=193,
	[199810]=194,	[199811]=195,	[199812]=196,	[199813]=197,	[199815]=199,	[199816]=200,	[199817]=201,	[199818]=202,
	[199819]=203,	[199820]=204,	[199821]=205,	[199822]=206,	[199823]=207,	[199825]=209,	[199827]=211,	[199828]=212,
	[199829]=213,	[199830]=214,	[199832]=216,	[199833]=217,	[199834]=218,	[199835]=219,	[199836]=220,	[199839]=223,
	[199840]=224,	[199841]=225,	[199842]=226,	[199843]=227,	[199844]=228,	[199845]=229,	[199847]=231,	[199848]=232,
	[199849]=233,	[199850]=234,	[199851]=235,	[199852]=236,	[199853]=237,	[199854]=238,	[199855]=239,	[199857]=241,
	[199859]=243,	[199860]=244,	[199861]=245,	[199862]=246,	[199864]=248,	[199865]=249,	[199866]=250,	[199867]=251,
	[199868]=252,	[200836]=260,	[200837]=261,	[200838]=262,	[200839]=263,	[200856]=280,	[200857]=281,	[201857]=321,
	[201858]=322,	[201859]=323,	[201860]=324,	[201874]=338,	[201875]=339,	[201882]=346,	[201883]=347,	[201913]=377,
	[201914]=378,	[201915]=379,	[201916]=380,	[213121]=1025,	[213136]=1040,	[213137]=1041,	[213138]=1042,	[213139]=1043,
	[213140]=1044,	[213141]=1045,	[213142]=1046,	[213143]=1047,	[213144]=1048,	[213145]=1049,	[213146]=1050,	[213147]=1051,
	[213148]=1052,	[213149]=1053,	[213150]=1054,	[213151]=1055,	[213152]=1056,	[213153]=1057,	[213154]=1058,	[213155]=1059,
	[213156]=1060,	[213157]=1061,	[213158]=1062,	[213159]=1063,	[213160]=1064,	[213161]=1065,	[213162]=1066,	[213163]=1067,
	[213164]=1068,	[213165]=1069,	[213166]=1070,	[213167]=1071,	[213168]=1072,	[213169]=1073,	[213170]=1074,	[213171]=1075,
	[213172]=1076,	[213173]=1077,	[213174]=1078,	[213175]=1079,	[213176]=1080,	[213177]=1081,	[213178]=1082,	[213179]=1083,
	[213180]=1084,	[213181]=1085,	[213182]=1086,	[213183]=1087,	[214144]=1088,	[214145]=1089,	[214146]=1090,	[214147]=1091,
	[214148]=1092,	[214149]=1093,	[214150]=1094,	[214151]=1095,	[214152]=1096,	[214153]=1097,	[214154]=1098,	[214155]=1099,
	[214156]=1100,	[214157]=1101,	[214158]=1102,	[214159]=1103,	[214161]=1105,

	[237111465]=8361,	[237109400]=8216,	[237109408]=8224,	[237118624]=8800,	[237118600]=8776,	[237118629]=8805,	[237118628]=8804,
	[237111468]=8364,	[237111485]=8381,	[237113495]=8471,	[237113506]=8482,	[237113504]=8480,	[237117594]=8730,	[237109437]=8253,
	[237121688]=8984,	[237121701]=8997,	[237115537]=8593,	[237115539]=8595,	[237115536]=8592,	[237115538]=8594,	[237132943]=9679,
	[237131936]=9632,	[237133968]=9744,	[237133969]=9745,	[237133970]=9746,	[237138067]=10003,	[237138070]=10006,	[237109395]=8211,
	[237109396]=8212,	[237109401]=8217,	[237109404]=8220,	[237109405]=8221,	[237109406]=8222,	[237109414]=8230,	[237117598]=8734,

	[250798268]=65084,	[250798231]=65047,	[250798232]=65048,	[237141160]=10216,	[237141162]=10218,	[237148297]=10633,	[237139116]=10092,
	[237139118]=10094,	[237139120]=10096,	[237121705]=9001,	[237148305]=10641,	[237149372]=10748,	[237141161]=10217,	[237141163]=10219,
	[237148298]=10634,	[237139117]=10093,	[237139119]=10095,	[237139121]=10097,	[237121706]=9002,	[237148306]=10642,	[237149373]=10749,
	[250798271]=65087,	[250799232]=65088,	[250798269]=65085,	[250798270]=65086,	[250803362]=65378,	[237166754]=11810,	[237166756]=11812,
	[250803363]=65379,	[237166755]=11811,	[237166757]=11813,	[250799234]=65090,	[250799233]=65089,	[250799236]=65092,	[250799235]=65091,
	[237148291]=10627,	[237139124]=10100,	[250799259]=65115,	[237148292]=10628,	[237139125]=10101,	[250799260]=65116,	[237124766]=9182,
	[237124767]=9183,	[250798263]=65079,	[250798264]=65080,	[237141158]=10214,	[237148299]=10635,	[237148301]=10637,	[237148303]=10639,
	[237110405]=8261,	[237141159]=10215,	[237148300]=10636,	[237148302]=10638,	[237148304]=10640,	[237110406]=8262,	[237123764]=9140,
	[237123765]=9141,	[250799239]=65095,	[250799240]=65096,	[237123766]=9142,	[237110461]=8317,	[237111437]=8333,	[237166760]=11816,
	[237148293]=10629,	[237141166]=10222,	[237148295]=10631,	[237139112]=10088,	[237139114]=10090,	[250794174]=64830,	[250799257]=65113,
	[237110462]=8318,	[237111438]=8334,	[237166761]=11817,	[237148294]=10630,	[237141167]=10223,	[237148296]=10632,	[237139113]=10089,
	[237139115]=10091,	[250794175]=64831,	[250799258]=65114,	[237124764]=9180,	[237124765]=9181,	[250798261]=65077,	[250798262]=65078,

	[250802337]=65313,	[250802338]=65314,	[250802339]=65315,	[250802340]=65316,	[250802341]=65317,	[250802342]=65318,	[250802343]=65319,
	[250802344]=65320,	[250802345]=65321,	[250802346]=65322,	[250802347]=65323,	[250802348]=65324,	[250802349]=65325,	[250802350]=65326,
	[250802351]=65327,	[250802352]=65328,	[250802353]=65329,	[250802354]=65330,	[250802355]=65331,	[250802356]=65332,	[250802357]=65333,
	[250802358]=65334,	[250802359]=65335,	[250802360]=65336,	[250802361]=65337,	[250802362]=65338,	[250803329]=65345,	[250803330]=65346,
	[250803331]=65347,	[250803332]=65348,	[250803333]=65349,	[250803334]=65350,	[250803335]=65351,	[250803336]=65352,	[250803337]=65353,
	[250803338]=65354,	[250803339]=65355,	[250803340]=65356,	[250803341]=65357,	[250803342]=65358,	[250803343]=65359,	[250803344]=65360,
	[250803345]=65361,	[250803346]=65362,	[250803347]=65363,	[250803348]=65364,	[250803349]=65365,	[250803350]=65366,	[250803351]=65367,
	[250803352]=65368,	[250803353]=65369,	[250803354]=65370,	[250802320]=65296,	[250802321]=65297,	[250802322]=65298,	[250802323]=65299,
	[250802324]=65300,	[250802325]=65301,	[250802326]=65302,	[250802327]=65303,	[250802328]=65304,	[250802329]=65305,	[250802305]=65281,
	[250802306]=65282,	[250802307]=65283,	[250802308]=65284,	[250802309]=65285,	[250802310]=65286,	[250802311]=65287,	[250802315]=65291,
	[250802316]=65292,	[250802317]=65293,	[250802318]=65294,	[250802319]=65295,	[250802330]=65306,	[250802331]=65307,	[250802332]=65308,
	[250802334]=65310,	[250802335]=65311,	[250802336]=65312,	[250802364]=65340,	[250802366]=65342,	[250802367]=65343,	[250803328]=65344,
	[250803356]=65372,	[250803358]=65374,	[250803365]=65381,	[250805408]=65504,	[250805409]=65505,	[250805410]=65506,	[250805411]=65507,
	[250805412]=65508,	[250805413]=65509,	[250805414]=65510,

	[238158977]=12353,	[238158978]=12354,	[238158979]=12355,	[238158980]=12356,	[238158981]=12357,	[238158982]=12358,	[238158983]=12359,
	[238158984]=12360,	[238158985]=12361,	[238158986]=12362,	[238158987]=12363,	[238158988]=12364,	[238158989]=12365,	[238158990]=12366,
	[238158991]=12367,	[238158992]=12368,	[238158993]=12369,	[238158994]=12370,	[238158995]=12371,	[238158996]=12372,	[238158997]=12373,
	[238158998]=12374,	[238158999]=12375,	[238159000]=12376,	[238159001]=12377,	[238159002]=12378,	[238159003]=12379,	[238159004]=12380,
	[238159005]=12381,	[238159006]=12382,	[238159007]=12383,	[238159008]=12384,	[238159009]=12385,	[238159010]=12386,	[238159011]=12387,
	[238159012]=12388,	[238159013]=12389,	[238159014]=12390,	[238159015]=12391,	[238159016]=12392,	[238159017]=12393,	[238159018]=12394,
	[238159019]=12395,	[238159020]=12396,	[238159021]=12397,	[238159022]=12398,	[238159023]=12399,	[238159024]=12400,	[238159025]=12401,
	[238159026]=12402,	[238159027]=12403,	[238159028]=12404,	[238159029]=12405,	[238159030]=12406,	[238159031]=12407,	[238159032]=12408,
	[238159033]=12409,	[238159034]=12410,	[238159035]=12411,	[238159036]=12412,	[238159037]=12413,	[238159038]=12414,	[238159039]=12415,
	[238160000]=12416,	[238160001]=12417,	[238160002]=12418,	[238160003]=12419,	[238160004]=12420,	[238160005]=12421,	[238160006]=12422,
	[238160007]=12423,	[238160008]=12424,	[238160009]=12425,	[238160010]=12426,	[238160011]=12427,	[238160012]=12428,	[238160013]=12429,
	[238160014]=12430,	[238160015]=12431,	[238160016]=12432,	[238160017]=12433,	[238160018]=12434,	[238160019]=12435,	[238160020]=12436,
	[238160021]=12437,	[238160022]=12438,	[238160029]=12445,	[238160030]=12446,	[238160033]=12449,	[238160034]=12450,	[238160035]=12451,
	[238160036]=12452,	[238160037]=12453,	[238160038]=12454,	[238160039]=12455,	[238160040]=12456,	[238160041]=12457,	[238160042]=12458,
	[238160043]=12459,	[238160044]=12460,	[238160045]=12461,	[238160046]=12462,	[238160047]=12463,	[238160048]=12464,	[238160049]=12465,
	[238160050]=12466,	[238160051]=12467,	[238160052]=12468,	[238160053]=12469,	[238160054]=12470,	[238160055]=12471,	[238160056]=12472,
	[238160057]=12473,	[238160058]=12474,	[238160059]=12475,	[238160060]=12476,	[238160061]=12477,	[238160062]=12478,	[238160063]=12479,
	[238161024]=12480,	[238161025]=12481,	[238161026]=12482,	[238161027]=12483,	[238161028]=12484,	[238161029]=12485,	[238161030]=12486,
	[238161031]=12487,	[238161032]=12488,	[238161033]=12489,	[238161034]=12490,	[238161035]=12491,	[238161036]=12492,	[238161037]=12493,
	[238161038]=12494,	[238161039]=12495,	[238161040]=12496,	[238161041]=12497,	[238161042]=12498,	[238161043]=12499,	[238161044]=12500,
	[238161045]=12501,	[238161046]=12502,	[238161047]=12503,	[238161048]=12504,	[238161049]=12505,	[238161050]=12506,	[238161051]=12507,
	[238161052]=12508,	[238161053]=12509,	[238161054]=12510,	[238161055]=12511,	[238161066]=12522,	[238161067]=12523,	[238161068]=12524,
	[238161069]=12525,	[238161070]=12526,	[238161071]=12527,	[238161072]=12528,	[238161073]=12529,	[238161074]=12530,	[238161075]=12531,
	[238161076]=12532,	[238161077]=12533,	[238161078]=12534,	[238161079]=12535,	[238161080]=12536,	[238161081]=12537,	[238161082]=12538,
	[238161083]=12539,	[238161084]=12540,	[238161085]=12541,	[238161086]=12542,	[238161087]=12543,	[238157957]=12293,	[239266973]=20189,
	[238157955]=12291,	[238158001]=12337,	[238158002]=12338,	[238158003]=12339,	[238158005]=12341,	[238158004]=12340,	[238157964]=12300,
	[238157965]=12301,	[238157966]=12302,	[238157967]=12303,	[250802312]=65288,	[250802313]=65289,	[238157972]=12308,	[238157973]=12309,
	[250802363]=65339,	[250802365]=65341,	[250803355]=65371,	[250803357]=65373,	[250803359]=65375,	[250803360]=65376,	[238157960]=12296,
	[238157961]=12297,	[238157962]=12298,	[238157963]=12299,	[238157968]=12304,	[238157969]=12305,	[238157974]=12310,	[238157975]=12311,
	[238157976]=12312,	[238157977]=12313,	[238157978]=12314,	[238157979]=12315,	[238160027]=12443,	[238160028]=12444,	[238157954]=12290,
	[238157953]=12289,	[238160032]=12448,	[250802333]=65309,	[238157958]=12294,	[238157980]=12316,	[237109413]=8229,	[237109410]=8226,
	[237132966]=9702,	[250799237]=65093,	[250799238]=65094,	[237109435]=8251,	[250802314]=65290,	[238158013]=12349,	[238157971]=12307,
	[237135018]=9834,	[237135019]=9835,	[237135020]=9836,	[237135017]=9833,	[238157959]=12295,	[238157970]=12306,	[238158006]=12342,
	[238157984]=12320,	[238157956]=12292,	[237128845]=9421,	[237128833]=9409,	[237128846]=9422,	[238171280]=13136,	[238171327]=13183,

	[238162097]=12593,	[238162098]=12594,	[238162100]=12596,	[238162103]=12599,	[238162104]=12600,	[238162105]=12601,	[238163073]=12609,
	[238163074]=12610,	[238163075]=12611,	[238163077]=12613,	[238163078]=12614,	[238163079]=12615,	[238163080]=12616,	[238163081]=12617,
	[238163082]=12618,	[238163083]=12619,	[238163084]=12620,	[238163085]=12621,	[238163086]=12622,	[238163087]=12623,	[238163091]=12627,
	[238163095]=12631,	[238163100]=12636,	[238163105]=12641,	[238163107]=12643,	[238163088]=12624,	[238163092]=12628,	[238163098]=12634,
	[238163103]=12639,	[238163106]=12642,	[238163089]=12625,	[238163093]=12629,	[238163099]=12635,	[238163104]=12640,	[238163090]=12626,
	[238163094]=12630,	[238163096]=12632,	[238163101]=12637,	[238163097]=12633,	[238163102]=12638,	[238162101]=12597,	[238162106]=12602,
	[238163076]=12612,	[238162099]=12595,	[238162102]=12598,	[238162107]=12603,	[238162108]=12604,	[238162109]=12605,	[238162110]=12606,
	[238162111]=12607,	[238163072]=12608,

	[239263872]=19968,	[239264921]=20057,	[239265932]=20108,	[240268417]=21313,	[239263873]=19969,	[240269442]=21378,	[239263875]=19971,
	[240268444]=21340,	[240260267]=20843,	[239265978]=20154,	[240260261]=20837,	[240259263]=20799,	[240267413]=21269,	[240262304]=20960,
	[239264925]=20061,	[240263297]=20993,	[239265926]=20102,	[240263296]=20992,	[240265371]=21147,	[239264899]=20035,	[240270472]=21448,
	[239263881]=19977,	[240313522]=24178,	[239265934]=20110,	[239265935]=20111,	[240311461]=24037,	[240283807]=22303,	[240290987]=22763,
	[241312909]=25165,	[239263883]=19979,	[240303288]=23544,	[240292007]=22823,	[239263880]=19976,	[239263886]=19982,	[239263879]=19975,
	[239263882]=19978,	[240304271]=23567,	[240270499]=21475,	[240305329]=23665,	[240311486]=24062,	[240268419]=21315,	[239264926]=20062,
	[240311453]=24029,	[239265983]=20159,	[239263914]=20010,	[240291989]=22805,	[239264901]=20037,	[239264904]=20040,	[240266426]=21242,
	[240262305]=20961,	[239263928]=20024,	[240270474]=21450,	[240313535]=24191,	[239265953]=20129,	[244473000]=38376,	[239263915]=20011,
	[239264905]=20041,	[239264907]=20043,	[240304312]=23608,	[240311473]=24049,	[240311474]=24050,	[240311475]=24051,	[240316563]=24339,
	[240301200]=23376,	[240268459]=21355,	[239264927]=20063,	[240293043]=22899,	[240263299]=20995,	[244485278]=39134,	[239264928]=20064,
	[240270473]=21449,	[244491436]=39532,	[239264929]=20065,	[239263920]=20016,	[242366603]=29579,	[240316544]=24320,	[239265941]=20117,
	[240292009]=22825,	[240292011]=22827,	[240260227]=20803,	[241327264]=26080,	[239265937]=20113,	[239263891]=19987,	[239263888]=19984,
	[241312910]=25166,	[243410106]=33402,	[241332392]=26408,	[239265940]=20116,	[241324207]=25903,	[240269445]=21381,	[239263885]=19981,
	[242362540]=29356,	[240292010]=22826,	[240267450]=21306,	[240269446]=21382,	[241349817]=27513,	[240270475]=21451,	[240304292]=23588,
	[240267449]=21305,	[243463334]=36710,	[240311464]=24040,	[242361497]=29273,	[240305327]=23663,	[241311880]=25096,	[241351828]=27604,
	[239265938]=20114,	[240263303]=20999,	[242371750]=29926,	[241349794]=27490,	[240304273]=23569,	[241331376]=26352,	[241327269]=26085,
	[239263917]=20013,	[243454109]=36125,	[240261256]=20872,	[240261253]=20869,	[241352884]=27700,	[243440769]=35265,	[240268424]=21320,
	[242361499]=29275,	[241312907]=25163,	[241352852]=27668,	[241351835]=27611,	[240290988]=22764,	[240268423]=21319,	[240292013]=22829,
	[244470975]=38271,	[239266945]=20161,	[239266944]=20160,	[242361479]=29255,	[239266950]=20166,	[240267414]=21270,	[239266951]=20167,
	[240312449]=24065,	[239266957]=20173,	[239266949]=20165,	[241326244]=26020,	[242360490]=29226,	[240270477]=21453,	[239266955]=20171,
	[242360502]=29238,	[239266958]=20174,	[239266961]=20177,	[239266954]=20170,	[240262326]=20982,	[240263302]=20998,	[239264911]=20047,
	[240260268]=20844,	[239266963]=20179,	[241332360]=26376,	[241352847]=27663,	[240266431]=21247,	[241348768]=27424,	[244485262]=39118,
	[239263929]=20025,	[240267392]=21248,	[239264908]=20044,	[240266430]=21246,	[240262308]=20964,	[240260269]=20845,	[241326215]=25991,
	[239265954]=20130,	[241326265]=26041,	[242353323]=28779,	[239263930]=20026,	[241326231]=26007,	[240319622]=24518,	[243447969]=35745,
	[243447970]=35746,	[241311927]=25143,	[243447972]=35748,	[240261271]=20887,	[243447973]=35749,	[240319619]=24515,	[240304314]=23610,
	[240316565]=24341,	[239263889]=19985,	[240311476]=24052,	[240301204]=23380,	[244474015]=38431,	[240265374]=21150,	[239266981]=20197,
	[240260225]=20801,	[239265928]=20104,	[244451475]=37011,	[240265373]=21149,	[240270476]=21452,	[239264934]=20070,	[240313531]=24187,
	[242366601]=29577,	[240263306]=21002,	[241332394]=26410,	[241332395]=26411,	[242389178]=31034,	[240262331]=20987,	[241312915]=25171,
	[240311463]=24039,	[241349795]=27491,	[241312913]=25169,	[240268425]=21321,	[241312914]=25170,	[240265375]=21151,	[241312916]=25172,
	[240269499]=21435,	[242372760]=29976,	[239263894]=19990,	[243410110]=33406,	[240270500]=21476,	[243411074]=33410,	[241332396]=26412,
	[241332399]=26415,	[240270511]=21487,	[239263897]=19993,	[240311462]=24038,	[240269449]=21385,	[242384051]=30707,	[240270515]=21491,
	[240312451]=24067,	[240292015]=22831,	[241311882]=25098,	[244512921]=40857,	[240313523]=24179,	[242353325]=28781,	[243463335]=36711,
	[239263900]=19996,	[240268449]=21345,	[240267415]=21271,	[240268448]=21344,	[240262328]=20984,	[240268450]=21346,	[239263898]=19994,
	[241327271]=26087,	[240312453]=24069,	[240317586]=24402,	[241327270]=26086,	[242379950]=30446,	[239263892]=19988,	[240270518]=21494,
	[242372786]=30002,	[242372787]=30003,	[240270510]=21486,	[242372789]=30005,	[240270519]=21495,	[242372784]=30000,	[242372785]=30001,
	[240270506]=21482,	[240270509]=21485,	[240270514]=21490,	[240292014]=22830,	[240260228]=20804,	[240270525]=21501,	[240270524]=21500,
	[240270507]=21483,	[240270505]=21481,	[240270504]=21480,	[240270502]=21478,	[240270521]=21497,	[240261257]=20873,	[242378943]=30399,
	[240262329]=20985,	[240282778]=22234,	[240282779]=22235,	[242372767]=29983,	[242384034]=30690,	[240292017]=22833,	[239264909]=20045,
	[242391230]=31166,	[239263896]=19992,	[239266968]=20184,	[239266967]=20183,	[239266979]=20195,	[239266969]=20185,	[239266988]=20204,
	[239266986]=20202,	[242377917]=30333,	[239266964]=20180,	[239266966]=20182,	[241326245]=26021,	[242371740]=29916,	[239264910]=20046,
	[239263899]=19995,	[239266980]=20196,	[242372776]=29992,	[242372777]=29993,	[240268464]=21360,	[240304276]=23572,	[239264912]=20048,
	[240270501]=21477,	[240267398]=21254,	[240261260]=20876,	[240268463]=21359,	[242362543]=29359,	[240291990]=22806,	[240291972]=22788,
	[240261292]=20908,	[244506783]=40479,	[240265377]=21153,	[240267397]=21253,	[244487333]=39269,	[239263931]=20027,	[240312450]=24066,
	[242396299]=31435,	[240261295]=20911,	[242366596]=29572,	[244473002]=38378,	[240260272]=20848,	[240268426]=21322,	[241353857]=27713,
	[241353863]=27719,	[240292020]=22836,	[241353865]=27721,	[240302209]=23425,	[242394292]=31348,	[240302211]=23427,	[243447976]=35752,
	[240261273]=20889,	[243447977]=35753,	[242389180]=31036,	[243447981]=35757,	[243447982]=35758,	[240319621]=24517,	[243447983]=35759,
	[243447984]=35760,	[241352888]=27704,	[240270520]=21496,	[240304316]=23612,	[241352849]=27665,	[240316567]=24343,	[240316568]=24344,
	[240262330]=20986,	[243464381]=36797,	[240293046]=22902,	[240293044]=22900,	[240270508]=21484,	[240265376]=21152,	[242378926]=30382,
	[243464377]=36793,	[240301205]=23381,	[240270481]=21457,	[240283811]=22307,	[240303289]=23545,	[240270512]=21488,	[242384027]=30683,
	[242411680]=32416,	[241351821]=27597,	[240313532]=24188,	[239263901]=19997,	[244451494]=37030,	[240316559]=24335,	[243465346]=36802,
	[240263313]=21009,	[241311886]=25102,	[240265384]=21160,	[241312923]=25179,	[240303290]=23546,	[240271497]=21513,	[241312931]=25187,
	[243400835]=32771,	[241312920]=25176,	[243400833]=32769,	[240311465]=24041,	[240283838]=22334,	[241312935]=25191,	[241312937]=25193,
	[241312939]=25195,	[240283824]=22320,	[240283834]=22330,	[241312940]=25196,	[243400883]=32819,	[243411083]=33419,	[240260273]=20849,
	[243411090]=33426,	[239265946]=20122,	[243411101]=33437,	[241332413]=26429,	[241332404]=26420,	[241332410]=26426,	[241333379]=26435,
	[243465351]=36807,	[243408035]=33251,	[240271503]=21519,	[240261261]=20877,	[240268431]=21327,	[243438783]=35199,	[240269451]=21387,
	[240269452]=21388,	[241311884]=25100,	[240283816]=22312,	[242377918]=30334,	[241332361]=26377,	[240301208]=23384,	[243400844]=32780,
	[244483253]=39029,	[240267424]=21280,	[240292024]=22840,	[240292026]=22842,	[242353328]=28784,	[243464382]=36798,	[240263319]=21015,
	[241349819]=27515,	[241311888]=25104,	[240292025]=22841,	[240292023]=22839,	[243463336]=36712,	[244451498]=37034,	[240304295]=23591,
	[240263314]=21010,	[243465352]=36808,	[241351829]=27605,	[243408051]=33267,	[241349796]=27492,	[243454110]=36126,	[240312456]=24072,
	[240304280]=23576,	[240304278]=23574,	[240265379]=21155,	[240260233]=20809,	[240317587]=24403,	[241327273]=26089,	[240271489]=21505,
	[240271504]=21520,	[240271507]=21523,	[243426475]=34411,	[241331378]=26354,	[240282786]=22242,	[240271509]=21525,	[240271500]=21516,
	[240271498]=21514,	[240271491]=21507,	[240282784]=22240,	[240271544]=21560,	[240271511]=21527,	[240271494]=21510,	[240305343]=23679,
	[240305337]=23673,	[240306305]=23681,	[240312454]=24070,	[240282782]=22238,	[240306306]=23682,	[240263321]=21017,	[240263322]=21018,
	[242414737]=32593,	[243402889]=32905,	[240313524]=24180,	[241332401]=26417,	[240260232]=20808,	[239263906]=20002,	[240315575]=24311,
	[243409036]=33292,	[242396345]=31481,	[243465345]=36801,	[239264916]=20052,	[243465348]=36804,	[239267999]=20255,	[239268000]=20256,
	[239264914]=20050,	[239264915]=20051,	[239267985]=20241,	[239267981]=20237,	[239267983]=20239,	[239267992]=20248,	[243408060]=33276,
	[239267984]=20240,	[240315574]=24310,	[239266994]=20210,	[239266998]=20214,	[239267003]=20219,	[239268004]=20260,	[239266999]=20215,
	[239268006]=20262,	[239267005]=20221,	[240268430]=21326,	[239266992]=20208,	[239267007]=20223,	[239267993]=20249,	[239268010]=20266,
	[243408042]=33258,	[239267978]=20234,	[243434624]=34880,	[240271505]=21521,	[239268028]=20284,	[240271502]=21518,	[243434636]=34892,
	[243409055]=33311,	[240260264]=20840,	[239267994]=20250,	[241333376]=26432,	[240271496]=21512,	[240260230]=20806,	[239267969]=20225,
	[239267991]=20247,	[242360503]=29239,	[239267998]=20254,	[240263323]=21019,	[243402892]=32908,	[243402891]=32907,	[241332405]=26421,
	[241333378]=26434,	[240268465]=21361,	[241327276]=26092,	[241327272]=26088,	[241327277]=26093,	[243454111]=36127,	[240267400]=21256,
	[240271501]=21517,	[240271492]=21508,	[240291994]=22810,	[239265929]=20105,	[243410098]=33394,	[240290990]=22766,	[240261298]=20914,
	[240294022]=22918,	[240261296]=20912,	[240314500]=24196,	[240314502]=24198,	[239265958]=20134,	[240263320]=21016,	[244511888]=40784,
	[239265956]=20132,	[243434659]=34915,	[241348769]=27425,	[239265959]=20135,	[240261299]=20915,	[239265957]=20133,	[240260229]=20805,
	[240294020]=22916,	[244473005]=38381,	[244473006]=38382,	[244473007]=38383,	[242415754]=32650,	[240313526]=24182,	[240260275]=20851,
	[242402483]=31859,	[242353327]=28783,	[240311454]=24030,	[241353879]=27735,	[241353889]=27745,	[241353887]=27743,	[241353883]=27739,
	[241353888]=27744,	[241353885]=27741,	[241353892]=27748,	[240319641]=24537,	[240260276]=20852,	[240302215]=23431,	[240302216]=23432,
	[240302213]=23429,	[240301207]=23383,	[240302217]=23433,	[243447986]=35762,	[243447987]=35763,	[240261275]=20891,	[243447990]=35766,
	[243447992]=35768,	[243447993]=35769,	[243447994]=35770,	[243447996]=35772,	[240261276]=20892,	[243447997]=35773,	[243447998]=35774,
	[243447999]=35775,	[243448960]=35776,	[240303291]=23547,	[244451491]=37027,	[243465349]=36805,	[240304317]=23613,	[240303292]=23548,
	[240316546]=24322,	[240316571]=24347,	[240301209]=23385,	[244474037]=38453,	[244474035]=38451,	[241324214]=25910,	[244474038]=38454,
	[244474036]=38452,	[244474034]=38450,	[240293048]=22904,	[240294018]=22914,	[240294023]=22919,	[240294019]=22915,	[240293053]=22909,
	[240293049]=22905,	[240294024]=22920,	[241311887]=25103,	[242415805]=32701,	[243440770]=35266,	[241348770]=27426,	[239264944]=20080,
	[242411682]=32418,	[244491438]=39534,	[242411684]=32420,	[244491439]=39535,	[242411686]=32422,	[242411687]=32423,	[242411690]=32426,
	[244491440]=39536,	[242411691]=32427,	[240311457]=24033,	[240303295]=23551,	[240316548]=24324,	[244508838]=40614,	[242366614]=29590,
	[242366619]=29595,	[240317602]=24418,	[243465371]=36827,	[241311890]=25106,	[240271518]=21534,	[243465372]=36828,	[243465373]=36829,
	[244481191]=38887,	[243465360]=36816,	[241312950]=25206,	[241313946]=25242,	[240284827]=22363,	[241313920]=25216,	[240284815]=22351,
	[241313952]=25248,	[241312944]=25200,	[241312956]=25212,	[241314962]=25298,	[241312958]=25214,	[241312953]=25209,	[240284800]=22336,
	[241312943]=25199,	[243455152]=36208,	[241313924]=25220,	[243454113]=36129,	[241353886]=27742,	[240284829]=22365,	[241324219]=25915,
	[243455140]=36196,	[241313944]=25240,	[241313939]=25235,	[241312947]=25203,	[241313953]=25249,	[241312942]=25198,	[241313954]=25250,
	[240301213]=23389,	[240284814]=22350,	[240284807]=22343,	[241313937]=25233,	[241313947]=25243,	[241313941]=25237,	[240284831]=22367,
	[240284817]=22353,	[241313943]=25239,	[240284810]=22346,	[241313942]=25238,	[241313956]=25252,	[240290995]=22771,	[240319639]=24535,
	[240284823]=22359,	[241312941]=25197,	[240290992]=22768,	[241313930]=25226,	[241313957]=25253,	[241314975]=25311,	[240268468]=21364,
	[241313938]=25234,	[240265387]=21163,	[243411097]=33433,	[243411100]=33436,	[243412103]=33479,	[243411133]=33469,	[243411121]=33457,
	[243411129]=33465,	[243411109]=33445,	[243411116]=33452,	[243412109]=33485,	[243411123]=33459,	[239263909]=20005,	[243411110]=33446,
	[243411119]=33455,	[240265395]=21171,	[240260235]=20811,	[243411117]=33453,	[243412111]=33487,	[241333382]=26438,	[241333408]=26464,
	[241333404]=26460,	[241333392]=26448,	[241333393]=26449,	[241333398]=26454,	[241333391]=26447,	[241333385]=26441,	[240311467]=24043,
	[241334401]=26497,	[241333390]=26446,	[241333416]=26472,	[241353858]=27714,	[242372779]=29995,	[240267427]=21283,	[241331380]=26356,
	[241333407]=26463,	[240271550]=21566,	[243451014]=35910,	[239263908]=20004,	[244454537]=37193,	[239263933]=20029,	[240267451]=21307,
	[243464368]=36784,	[240265393]=21169,	[240271526]=21542,	[243465368]=36824,	[240304300]=23596,	[241349820]=27516,	[241333413]=26469,
	[243465374]=36830,	[243463337]=36713,	[241349797]=27493,	[240268452]=21348,	[240284826]=22362,	[243402902]=32918,	[241327281]=26097,
	[242379951]=30447,	[240272520]=21576,	[241327286]=26102,	[240271540]=21556,	[240265385]=21161,	[240269503]=21439,	[244456588]=37324,
	[240272518]=21574,	[240271537]=21553,	[240271520]=21536,	[240272533]=21589,	[240282797]=22253,	[241327287]=26103,	[240282804]=22260,
	[240272512]=21568,	[240271528]=21544,	[243456179]=36275,	[244451502]=37038,	[242372791]=30007,	[240282800]=22256,	[240271541]=21557,
	[239263922]=20018,	[240272536]=21592,	[240272528]=21584,	[240271532]=21548,	[240271519]=21535,	[240271529]=21545,	[240272539]=21595,
	[240271547]=21563,	[240271545]=21561,	[240272540]=21596,	[240271533]=21549,	[240271527]=21543,	[244451473]=37009,	[240271548]=21564,
	[240282788]=22244,	[240263339]=21035,	[240271534]=21550,	[240306326]=23702,	[240306327]=23703,	[240312464]=24080,	[243454114]=36130,
	[244467848]=38024,	[244467849]=38025,	[242361505]=29281,	[240272522]=21578,	[241311889]=25105,	[239264945]=20081,	[240263337]=21033,
	[242392195]=31171,	[242392192]=31168,	[242392193]=31169,	[241351823]=27599,	[240260277]=20853,	[239268016]=20272,	[239269011]=20307,
	[239269013]=20309,	[239269008]=20304,	[239269009]=20305,	[239268998]=20294,	[239268024]=20280,	[239268995]=20291,	[239269020]=20316,
	[239268015]=20271,	[239268022]=20278,	[239269027]=20323,	[239269006]=20302,	[239269024]=20320,	[239269007]=20303,	[239269005]=20301,
	[239268020]=20276,	[243460267]=36523,	[242378882]=30338,	[239268026]=20282,	[239269019]=20315,	[240282801]=22257,	[243465361]=36817,
	[240317627]=24443,	[240317625]=24441,	[243465364]=36820,	[239269017]=20313,	[240312460]=24076,	[240284816]=22352,	[243450039]=35895,
	[240294053]=22949,	[240271531]=21547,	[244451515]=37051,	[240306324]=23700,	[243402909]=32925,	[243402907]=32923,	[243402906]=32922,
	[243402904]=32920,	[243402912]=32928,	[244512927]=40863,	[242372792]=30008,	[240260237]=20813,	[242363522]=29378,	[242362553]=29369,
	[242363528]=29384,	[243440786]=35282,	[240263328]=21024,	[241333409]=26465,	[240317604]=24420,	[240268469]=21365,	[242353336]=28792,
	[240306331]=23707,	[240263336]=21032,	[243465358]=36814,	[244487341]=39277,	[244487342]=39278,	[242404539]=31995,	[243441792]=35328,
	[240261307]=20923,	[242362550]=29366,	[239265961]=20137,	[240261301]=20917,	[240314506]=24202,	[240314515]=24211,	[240314503]=24199,
	[242374807]=30103,	[240271517]=21533,	[240314516]=24212,	[243465369]=36825,	[240261303]=20919,	[240314512]=24208,	[240314511]=24207,
	[243464347]=36763,	[240316547]=24323,	[240261302]=20918,	[240319640]=24536,	[244473008]=38384,	[244473010]=38386,	[244473012]=38388,
	[244473015]=38391,	[240263332]=21028,	[240260241]=20817,	[242353334]=28790,	[242353343]=28799,	[242353340]=28796,	[240316575]=24351,
	[241353898]=27754,	[241354896]=27792,	[241354907]=27803,	[241353904]=27760,	[241354917]=27813,	[241354905]=27801,	[241353917]=27773,
	[241354883]=27779,	[241354918]=27814,	[241353913]=27769,	[241355931]=27867,	[241354919]=27815,	[241354913]=27809,	[241354911]=27807,
	[241354922]=27818,	[241354888]=27784,	[241354889]=27785,	[241354881]=27777,	[241303680]=24576,	[240319655]=24551,	[240319665]=24561,
	[240319659]=24555,	[240302220]=23436,	[240302219]=23435,	[240302223]=23439,	[242361506]=29282,	[242394294]=31350,	[242394295]=31351,
	[242353342]=28798,	[243410095]=33391,	[243448961]=35777,	[240271535]=21551,	[243448964]=35780,	[243434661]=34917,	[240263325]=21021,
	[242389182]=31038,	[242390144]=31040,	[243448966]=35782,	[243448968]=35784,	[243448969]=35785,	[242414741]=32597,	[243448970]=35786,
	[243448973]=35789,	[243448977]=35793,	[240271515]=21531,	[242353333]=28789,	[240268467]=21363,	[240305282]=23618,	[240305281]=23617,
	[240304319]=23615,	[240304318]=23614,	[243465375]=36831,	[240305280]=23616,	[241324217]=25913,	[240316576]=24352,	[240319628]=24524,
	[244475013]=38469,	[244475014]=38470,	[244474047]=38463,	[244475016]=38472,	[244474043]=38459,	[244475012]=38468,	[240284832]=22368,
	[240294035]=22931,	[240294041]=22937,	[240294038]=22934,	[240295050]=22986,	[240294056]=22952,	[240294034]=22930,	[240265386]=21162,
	[240319629]=24525,	[240265394]=21170,	[242384035]=30691,	[244506785]=40481,	[242411692]=32428,	[244491441]=39537,	[242411695]=32431,
	[242411697]=32433,	[242411698]=32434,	[242411699]=32435,	[244491443]=39539,	[242411701]=32437,	[242411703]=32439,	[242411704]=32440,
	[242411705]=32441,	[242411706]=32442,	[244491444]=39540,	[242411709]=32445,	[240293001]=22857,	[242366633]=29609,	[242366639]=29615,
	[241349798]=27494,	[244479122]=38738,	[243454115]=36131,	[242366640]=29616,	[242366635]=29611,	[243434664]=34920,	[243440772]=35268,
	[241313977]=25273,	[240268454]=21350,	[240284855]=22391,	[240284847]=22383,	[241314963]=25299,	[241314978]=25314,	[241314964]=25300,
	[240284842]=22378,	[241314979]=25315,	[240284838]=22374,	[241314949]=25285,	[240284836]=22372,	[241313980]=25276,	[241313981]=25277,
	[241314960]=25296,	[241314966]=25302,	[243400837]=32773,	[241314957]=25293,	[244483254]=39030,	[241314950]=25286,	[241314958]=25294,
	[241314981]=25317,	[241313973]=25269,	[241314968]=25304,	[240265407]=21183,	[241313969]=25265,	[241314948]=25284,	[240285827]=22403,
	[241314953]=25289,	[241314982]=25318,	[240313528]=24184,	[241314956]=25292,	[241314983]=25319,	[241314946]=25282,	[241314969]=25305,
	[241314971]=25307,	[240284833]=22369,	[241313963]=25259,	[241314984]=25320,	[241314985]=25321,	[241313964]=25260,	[241314951]=25287,
	[241314967]=25303,	[240260278]=20854,	[240270486]=21462,	[243413129]=33545,	[243412134]=33510,	[241328276]=26132,	[243412123]=33499,
	[243412133]=33509,	[243413122]=33538,	[243412153]=33529,	[243412119]=33495,	[243412145]=33521,	[243412127]=33503,	[243412113]=33489,
	[243412126]=33502,	[243413123]=33539,	[242379956]=30452,	[243413121]=33537,	[243413124]=33540,	[243413134]=33550,	[243412116]=33492,
	[243413125]=33541,	[241334409]=26505,	[241334423]=26519,	[241334429]=26525,	[241333423]=26479,	[241334434]=26530,	[241335452]=26588,
	[241334426]=26522,	[241334416]=26512,	[241333439]=26495,	[241333438]=26494,	[241334442]=26538,	[241334443]=26539,	[241334404]=26500,
	[241333421]=26477,	[241333424]=26480,	[243465392]=36848,	[241334421]=26517,	[239263911]=20007,	[241311894]=25110,	[242372795]=30011,
	[240268455]=21351,	[239265931]=20107,	[240263354]=21050,	[241334435]=26531,	[244477096]=38632,	[240268438]=21334,	[244452481]=37057,
	[242384062]=30718,	[242384063]=30719,	[242385025]=30721,	[240269461]=21397,	[240293000]=22856,	[240293012]=22868,	[240292999]=22855,
	[240293003]=22859,	[241303681]=24577,	[241348775]=27431,	[241350836]=27572,	[240285828]=22404,	[240294075]=22971,	[243463344]=36720,
	[244483255]=39031,	[243463340]=36716,	[241326249]=26025,	[243463342]=36718,	[243463343]=36719,	[240263344]=21040,	[244479134]=38750,
	[240270484]=21460,	[241349799]=27495,	[243402927]=32943,	[244511935]=40831,	[239265947]=20123,	[240268435]=21331,	[243426446]=34382,
	[243426447]=34383,	[243402942]=32958,	[243454116]=36132,	[240304282]=23578,	[241327290]=26106,	[240260279]=20855,	[240272563]=21619,
	[241334428]=26524,	[241328262]=26118,	[240282813]=22269,	[240274574]=21710,	[240273557]=21653,	[241328268]=26124,	[240272565]=21621,
	[242373765]=30021,	[241328270]=26126,	[241328275]=26131,	[240273561]=21657,	[241328258]=26114,	[243465386]=36842,	[240260280]=20856,
	[240282810]=22266,	[240319648]=24544,	[240272571]=21627,	[240273554]=21650,	[240273547]=21643,	[240273552]=21648,	[240272572]=21628,
	[244506787]=40483,	[240273551]=21647,	[240272546]=21602,	[240273540]=21636,	[240273558]=21654,	[240306360]=23736,	[240306345]=23721,
	[240312470]=24086,	[242414743]=32599,	[240312476]=24092,	[240312469]=24085,	[240306349]=23725,	[240262319]=20975,	[243454117]=36133,
	[243454118]=36134,	[243454121]=36137,	[243454124]=36140,	[243454125]=36141,	[243454126]=36142,	[240282814]=22270,	[244467859]=38035,
	[240263350]=21046,	[242384037]=30693,	[243465389]=36845,	[241352859]=27675,	[240285826]=22402,	[242361511]=29287,	[242361513]=29289,
	[239264918]=20054,	[240263342]=21038,	[242392198]=31174,	[240273548]=21644,	[240301219]=23395,	[240295060]=22996,	[242392201]=31177,
	[239269043]=20339,	[239270029]=20365,	[240306355]=23731,	[239270043]=20379,	[239269055]=20351,	[239270027]=20363,	[239270048]=20384,
	[239270053]=20389,	[242361480]=29256,	[239270020]=20356,	[239270054]=20390,	[239270051]=20387,	[239270055]=20391,	[240262317]=20973,
	[239270056]=20392,	[239269033]=20329,	[243454119]=36135,	[239270024]=20360,	[239270045]=20381,	[240268433]=21329,	[242378884]=30340,
	[243465387]=36843,	[243454120]=36136,	[241348771]=27427,	[240318593]=24449,	[240318592]=24448,	[242360492]=29228,	[240317628]=24444,
	[240318596]=24452,	[241312896]=25152,	[243409037]=33293,	[244456593]=37329,	[240263353]=21049,	[240272573]=21629,	[243402932]=32948,
	[241326247]=26023,	[242360504]=29240,	[244456583]=37319,	[243440773]=35269,	[240270487]=21463,	[239264947]=20083,	[243454122]=36138,
	[240319669]=24565,	[243454123]=36139,	[240319679]=24575,	[243402916]=32932,	[243402938]=32954,	[243402914]=32930,	[243402943]=32959,
	[243403904]=32960,	[241332363]=26379,	[243402913]=32929,	[243402926]=32942,	[243402922]=32938,	[243402917]=32933,	[241332365]=26381,
	[243403905]=32961,	[240272552]=21608,	[241328271]=26127,	[244499644]=40060,	[240260244]=20820,	[242363536]=29392,	[240319677]=24573,
	[242363543]=29399,	[242363550]=29406,	[240291975]=22791,	[244487344]=39280,	[244487345]=39281,	[244487346]=39282,	[240270488]=21464,
	[239265964]=20140,	[239265963]=20139,	[240314526]=24222,	[240314519]=24215,	[240291996]=22812,	[240314521]=24217,	[240314524]=24220,
	[240314517]=24213,	[242374815]=30111,	[242374809]=30105,	[242374810]=30106,	[240264322]=21058,	[240268434]=21330,	[244452490]=37066,
	[240314522]=24218,	[240314527]=24223,	[240262272]=20928,	[242379954]=30450,	[241324222]=25918,	[240263355]=21051,	[243402930]=32946,
	[241352851]=27667,	[244473016]=38392,	[244473017]=38393,	[244452497]=37073,	[240263352]=21048,	[240268471]=21367,	[240268437]=21333,
	[242354348]=28844,	[242354322]=28818,	[242354314]=28810,	[242354325]=28821,	[242354318]=28814,	[242354313]=28809,	[241354923]=27819,
	[241357957]=27973,	[241355925]=27861,	[241355908]=27844,	[241354941]=27837,	[241354931]=27827,	[241354942]=27838,	[241355946]=27882,
	[241354926]=27822,	[241354937]=27833,	[241355914]=27850,	[241354943]=27839,	[241355937]=27873,	[241355944]=27880,	[241355939]=27875,
	[241355934]=27870,	[241355963]=27899,	[241355916]=27852,	[241355955]=27891,	[241355941]=27877,	[241354936]=27832,	[241354940]=27836,
	[241355938]=27874,	[241355964]=27900,	[241355965]=27901,	[241354939]=27835,	[241303700]=24596,	[241303727]=24623,	[241303702]=24598,
	[241303719]=24615,	[241303701]=24597,	[241303708]=24604,	[241303722]=24618,	[241303713]=24609,	[240301222]=23398,	[240302237]=23453,
	[240302231]=23447,	[240302234]=23450,	[240302240]=23456,	[240302236]=23452,	[240302241]=23457,	[240302233]=23449,	[240302232]=23448,
	[242394298]=31354,	[240312472]=24088,	[240302235]=23451,	[240302238]=23454,	[243448981]=35797,	[244452494]=37070,	[243448983]=35799,
	[243402921]=32937,	[241311935]=25151,	[243448986]=35802,	[243434668]=34924,	[243434667]=34923,	[243440774]=35270,	[242390152]=31048,
	[243448989]=35805,	[243448990]=35806,	[243448993]=35809,	[243448994]=35810,	[243448997]=35813,	[243448998]=35814,	[240315578]=24314,
	[243402883]=32899,	[240317589]=24405,	[244476086]=38582,	[240312474]=24090,	[240305289]=23625,	[240305285]=23621,	[240305290]=23626,
	[240263351]=21047,	[240305288]=23624,	[240316583]=24359,	[240316581]=24357,	[240316582]=24358,	[241312959]=25215,	[240301215]=23391,
	[244475019]=38475,	[244475020]=38476,	[240301220]=23396,	[244475029]=38485,	[244475021]=38477,	[240262333]=20989,	[244475024]=38480,
	[240294073]=22969,	[240295057]=22993,	[240295056]=22992,	[240295059]=22995,	[240294062]=22958,	[240295051]=22987,	[240295046]=22982,
	[243465378]=36834,	[244491454]=39550,	[240270465]=21441,	[240270466]=21442,	[243410096]=33392,	[242411711]=32447,	[242412675]=32451,
	[242412676]=32452,	[242412677]=32453,	[242412678]=32454,	[244491446]=39542,	[242412679]=32455,	[244491449]=39545,	[242412680]=32456,
	[244491451]=39547,	[242412682]=32458,	[244491452]=39548,	[242412685]=32461,	[242412686]=32462,	[242412687]=32463,	[243454127]=36143,
	[240293009]=22865,	[243454128]=36144,	[240293007]=22863,	[241328293]=26149,	[240312494]=24110,	[242366647]=29623,	[242367629]=29645,
	[242366642]=29618,	[242367626]=29642,	[242366651]=29627,	[241351826]=27602,	[240285835]=22411,	[241314989]=25325,	[241315970]=25346,
	[240304257]=23553,	[241315969]=25345,	[241314999]=25335,	[241314993]=25329,	[244483257]=39033,	[240285870]=22446,	[241315982]=25358,
	[240286862]=22478,	[241315999]=25375,	[241316000]=25376,	[241324223]=25919,	[243455156]=36212,	[243455157]=36213,	[241316001]=25377,
	[241315005]=25341,	[240274569]=21705,	[241316026]=25402,	[241314988]=25324,	[240285858]=22434,	[241314996]=25332,	[241315006]=25342,
	[241315985]=25361,	[240285851]=22427,	[241315975]=25351,	[240285867]=22443,	[241316003]=25379,	[241316004]=25380,	[241315004]=25340,
	[241315990]=25366,	[241315977]=25353,	[241316005]=25381,	[241316010]=25386,	[241314991]=25327,	[241335440]=26576,	[242372762]=29978,
	[243414150]=33606,	[243413176]=33592,	[244479145]=38761,	[243413164]=33580,	[243414160]=33616,	[240311479]=24055,	[240312486]=24102,
	[243414153]=33609,	[243413159]=33575,	[243413173]=33589,	[243413174]=33590,	[243414162]=33618,	[243413163]=33579,	[243414177]=33633,
	[243414179]=33635,	[243414180]=33636,	[243414183]=33639,	[241325189]=25925,	[243403937]=32993,	[243414187]=33643,	[243414164]=33620,
	[240268439]=21335,	[243414191]=33647,	[241336455]=26631,	[241336456]=26632,	[241335441]=26577,	[241334447]=26543,	[241335428]=26564,
	[241336459]=26635,	[242379960]=30456,	[241335461]=26597,	[241335439]=26575,	[241336453]=26629,	[241335475]=26611,	[241335473]=26609,
	[241335487]=26623,	[241336463]=26639,	[241335456]=26592,	[241336465]=26641,	[240266371]=21187,	[243439745]=35201,	[241335468]=26604,
	[240273592]=21688,	[240296065]=23041,	[241349802]=27498,	[242385044]=30740,	[242385046]=30742,	[240269464]=21400,	[240269466]=21402,
	[242385036]=30732,	[242385026]=30722,	[241355957]=27893,	[242385050]=30746,	[242385037]=30733,	[244479138]=38754,	[243400848]=32784,
	[243400845]=32781,	[242361525]=29301,	[244506789]=40485,	[241350795]=27531,	[241350787]=27523,	[243463348]=36724,	[243463355]=36731,
	[244506790]=40486,	[242378886]=30342,	[244481197]=38893,	[243403916]=32972,	[241311896]=25112,	[242354361]=28857,	[243426448]=34384,
	[239263924]=20020,	[243440776]=35272,	[242396310]=31446,	[242380929]=30465,	[240264330]=21066,	[240304285]=23581,	[241328295]=26151,
	[242379961]=30457,	[241328303]=26159,	[242379964]=30460,	[242380968]=30504,	[240274567]=21703,	[240274564]=21700,	[240274577]=21713,
	[241328318]=26174,	[240261266]=20882,	[241328288]=26144,	[241328287]=26143,	[241328296]=26152,	[240273575]=21671,	[241328301]=26157,
	[242373775]=30031,	[243456180]=36276,	[243403907]=32963,	[243454133]=36149,	[242373772]=30028,	[243426489]=34425,	[243426494]=34430,
	[243427457]=34433,	[241303709]=24605,	[243427458]=34434,	[243426493]=34429,	[240274561]=21697,	[240273597]=21693,	[244492418]=39554,
	[240266379]=21195,	[240274583]=21719,	[240273585]=21681,	[240274573]=21709,	[240274568]=21704,	[240274566]=21702,	[240273580]=21676,
	[240273587]=21683,	[240273578]=21674,	[240274602]=21738,	[240274591]=21727,	[242354349]=28845,	[240307361]=23777,	[242414746]=32602,
	[243454129]=36145,	[243454132]=36148,	[243454139]=36155,	[244492456]=39592,	[240313533]=24189,	[244467865]=38041,	[244467869]=38045,
	[244467870]=38046,	[244467871]=38047,	[244467874]=38050,	[244467872]=38048,	[244467877]=38053,	[244467878]=38054,	[244467879]=38055,
	[244467881]=38057,	[244467886]=38062,	[240268472]=21368,	[242413752]=32568,	[241314972]=25308,	[242380939]=30475,	[242384041]=30697,
	[241351841]=27617,	[241352866]=27682,	[241303694]=24590,	[242361522]=29298,	[244449417]=36873,	[244449410]=36866,	[242392210]=31186,
	[244488345]=39321,	[242392205]=31181,	[242392203]=31179,	[242392209]=31185,	[244456589]=37325,	[240291981]=22797,	[242396351]=31487,
	[241350837]=27573,	[239270079]=20415,	[239271081]=20457,	[243454135]=36151,	[244483258]=39034,	[239271086]=20462,	[239271055]=20431,
	[239271069]=20445,	[239271043]=20419,	[239271044]=20420,	[239271056]=20432,	[239270062]=20398,	[239271085]=20461,	[239271063]=20439,
	[239271064]=20440,	[239271073]=20449,	[242378887]=30343,	[241355913]=27849,	[244494524]=39740,	[239270069]=20405,	[242391225]=31161,
	[239270063]=20399,	[243465405]=36861,	[239271050]=20426,	[242379966]=30462,	[240318597]=24453,	[240318602]=24458,	[243434637]=34893,
	[240318603]=24459,	[240318600]=24456,	[244483259]=39035,	[240270489]=21465,	[240264337]=21073,	[244449411]=36867,	[244485279]=39135,
	[242379910]=30406,	[243403930]=32986,	[243403943]=32999,	[243403910]=32966,	[243403932]=32988,	[243403934]=32990,	[243403926]=32982,
	[243404937]=33033,	[243403918]=32974,	[240266377]=21193,	[242363565]=29421,	[242363566]=29422,	[242363564]=29420,	[242363568]=29424,
	[242363553]=29409,	[242363569]=29425,	[242363552]=29408,	[243454136]=36152,	[241303720]=24616,	[241303717]=24613,	[244487349]=39285,
	[244487350]=39286,	[243427456]=34432,	[244487354]=39290,	[244487356]=39292,	[240307366]=23782,	[240316591]=24367,	[240304262]=23558,
	[240293014]=22870,	[240274560]=21696,	[239265965]=20141,	[239265966]=20142,	[240314534]=24230,	[243465401]=36857,	[240314541]=24237,
	[242374830]=30126,	[242374831]=30127,	[242374827]=30123,	[242374820]=30116,	[240273576]=21672,	[240295103]=23039,	[239265970]=20146,
	[244481203]=38899,	[240312477]=24093,	[241326269]=26045,	[244473018]=38394,	[244473019]=38395,	[244473021]=38397,	[244473984]=38400,
	[244473985]=38401,	[240311470]=24046,	[240260283]=20859,	[242415758]=32654,	[240295068]=23004,	[240270491]=21467,	[244449409]=36865,
	[242402491]=31867,	[243465399]=36855,	[242402493]=31869,	[240296068]=23044,	[240264333]=21069,	[244488342]=39318,	[244449414]=36870,
	[240260281]=20857,	[241303739]=24635,	[242354364]=28860,	[242354360]=28856,	[242355329]=28865,	[242354350]=28846,	[242354347]=28843,
	[242355330]=28866,	[240264323]=21059,	[241356988]=27964,	[241356929]=27905,	[241356970]=27946,	[241356946]=27922,	[241335442]=26578,
	[241357959]=27975,	[241357962]=27978,	[241356958]=27934,	[241357963]=27979,	[241356951]=27927,	[241356987]=27963,	[241356990]=27966,
	[241356989]=27965,	[241335443]=26579,	[241356955]=27931,	[241357967]=27983,	[241357966]=27982,	[241356939]=27915,	[241356978]=27954,
	[241357969]=27985,	[241357971]=27987,	[241356965]=27941,	[241304707]=24643,	[241304722]=24658,	[241304738]=24674,	[241304717]=24653,
	[241304748]=24684,	[241304740]=24676,	[241304752]=24688,	[241304764]=24700,	[241304744]=24680,	[239263934]=20030,	[243440777]=35273,
	[240302243]=23459,	[240302246]=23462,	[240302244]=23460,	[240302251]=23467,	[240302250]=23466,	[242395265]=31361,	[242394303]=31359,
	[242395267]=31363,	[240302242]=23458,	[243449003]=35819,	[240261280]=20896,	[243449004]=35820,	[243449005]=35821,	[241312897]=25153,
	[243435652]=34948,	[242390166]=31062,	[242390174]=31070,	[242390173]=31069,	[242390176]=31072,	[243449007]=35823,	[243449009]=35825,
	[243449010]=35826,	[243449012]=35828,	[243449013]=35829,	[240285862]=22438,	[244449408]=36864,	[241327266]=26082,	[240305291]=23627,
	[241328316]=26172,	[240305295]=23631,	[240305294]=23630,	[243454137]=36153,	[244475041]=38497,	[244449418]=36874,	[242380937]=30473,
	[240301225]=23401,	[244475048]=38504,	[244475044]=38500,	[244475049]=38505,	[244475042]=38498,	[240296067]=23043,	[240295077]=23013,
	[240295080]=23016,	[240295099]=23035,	[240296071]=23047,	[240295066]=23002,	[240296092]=23068,	[241303698]=24594,	[241334454]=26550,
	[243454138]=36154,	[242379912]=30408,	[240266375]=21191,	[241303712]=24608,	[242377912]=30328,	[243427492]=34468,	[241335444]=26580,
	[240285842]=22418,	[242412689]=32465,	[242412690]=32466,	[242412691]=32467,	[242412693]=32469,	[244492420]=39556,	[242412696]=32472,
	[242412697]=32473,	[242412698]=32474,	[244492422]=39558,	[242412700]=32476,	[242412701]=32477,	[242412702]=32478,	[244492423]=39559,
	[242412703]=32479,	[243400853]=32789,	[243400856]=32792,	[243400855]=32791,	[243400857]=32793,	[243410099]=33395,	[241355952]=27888,
	[242392230]=31206,	[242367648]=29664,	[242367661]=29677,	[242405536]=32032,	[240267455]=21311,	[243427477]=34453,	[244483261]=39037,
	[242379919]=30415,	[240267434]=21290,	[241317022]=25438,	[241336509]=26685,	[241317013]=25429,	[240286850]=22466,	[241316994]=25410,
	[241316015]=25391,	[243463357]=36733,	[243455158]=36214,	[243455159]=36215,	[242379920]=30416,	[241317006]=25422,	[241317005]=25421,
	[241317007]=25423,	[240286859]=22475,	[241317001]=25417,	[241316998]=25414,	[241317008]=25424,	[241317023]=25439,	[243435649]=34945,
	[241317004]=25420,	[244452541]=37117,	[240274610]=21746,	[244449437]=36893,	[241317025]=25441,	[241316011]=25387,	[241317026]=25442,
	[241316029]=25405,	[241315994]=25370,	[242355373]=28909,	[241304720]=24656,	[241317027]=25443,	[240290998]=22774,	[241316997]=25413,
	[240286851]=22467,	[241316008]=25384,	[243400891]=32827,	[243400895]=32831,	[243400893]=32829,	[243401858]=32834,	[241304749]=24685,
	[243415229]=33725,	[243415217]=33713,	[243415218]=33714,	[243415211]=33707,	[243415177]=33673,	[243414199]=33655,	[243415223]=33719,
	[241329291]=26187,	[241304758]=24694,	[243415225]=33721,	[243415226]=33722,	[242380959]=30495,	[241337478]=26694,	[241338502]=26758,
	[241337474]=26690,	[241337492]=26708,	[241336470]=26646,	[241337507]=26723,	[241337488]=26704,	[241336490]=26666,	[241337509]=26725,
	[241337510]=26726,	[241336467]=26643,	[241337475]=26691,	[241336508]=26684,	[241337513]=26729,	[241336481]=26657,	[241336504]=26680,
	[241336503]=26679,	[241336505]=26681,	[242405538]=32034,	[240274597]=21733,	[244449439]=36895,	[244449431]=36887,	[241336471]=26647,
	[243454142]=36158,	[244454540]=37196,	[244454541]=37197,	[242416773]=32709,	[243464369]=36785,	[240275591]=21767,	[240291983]=22799,
	[242385080]=30776,	[242385072]=30768,	[242385086]=30782,	[242386048]=30784,	[242385076]=30772,	[240269471]=21407,	[240293015]=22871,
	[244449424]=36880,	[242355336]=28872,	[241350794]=27530,	[241350793]=27529,	[244483262]=39038,	[243463359]=36735,	[243464323]=36739,
	[244483263]=39039,	[241351833]=27609,	[243408052]=33268,	[241335476]=26612,	[241337484]=26700,	[243426449]=34385,	[242379921]=30417,
	[242405543]=32039,	[240260250]=20826,	[244449438]=36894,	[241329298]=26194,	[242380960]=30496,	[241329299]=26195,	[240274606]=21742,
	[240275616]=21792,	[244506797]=40493,	[241329283]=26179,	[240274618]=21754,	[241329292]=26188,	[240264340]=21076,	[241329301]=26197,
	[243427468]=34444,	[242373780]=30036,	[243427491]=34467,	[243427466]=34442,	[243427498]=34474,	[243427475]=34451,	[240274600]=21736,
	[240274601]=21737,	[240283779]=22275,	[240274605]=21741,	[240274598]=21734,	[241304745]=24681,	[244506799]=40495,	[240275620]=21796,
	[240275585]=21761,	[240274620]=21756,	[240275623]=21799,	[240276618]=21834,	[240275593]=21769,	[240275590]=21766,	[242414754]=32610,
	[240307373]=23789,	[240307368]=23784,	[240307376]=23792,	[240283782]=22278,	[240307387]=23803,	[243454140]=36156,	[243454143]=36159,
	[243455106]=36162,	[243455107]=36163,	[244467889]=38065,	[244467891]=38067,	[244467899]=38075,	[244467902]=38078,	[244468865]=38081,
	[244468867]=38083,	[244468869]=38085,	[242413754]=32570,	[241352871]=27687,	[241352872]=27688,	[242361529]=29305,	[242361530]=29306,
	[244449440]=36896,	[239264920]=20056,	[241325196]=25932,	[242392228]=31204,	[242392223]=31199,	[242392239]=31215,	[242392231]=31207,
	[242392233]=31209,	[242392240]=31216,	[242392216]=31192,	[244449423]=36879,	[242397332]=31508,	[242397329]=31505,	[242397323]=31499,
	[240255162]=20538,	[240255135]=20511,	[240255164]=20540,	[240255130]=20506,	[239271098]=20474,	[240255166]=20542,	[240255122]=20498,
	[240255128]=20504,	[239271089]=20465,	[240255137]=20513,	[240255129]=20505,	[243455105]=36161,	[239271087]=20463,	[240255117]=20493,
	[240255142]=20518,	[240256165]=20581,	[243408045]=33261,	[240304260]=23556,	[243460268]=36524,	[241304751]=24687,	[240255124]=20500,
	[240318610]=24466,	[240318608]=24464,	[241350839]=27575,	[243409072]=33328,	[243409073]=33329,	[243409068]=33324,	[243409066]=33322,
	[244449428]=36884,	[241315007]=25343,	[243400888]=32824,	[242360505]=29241,	[243409024]=33280,	[242360497]=29233,	[243451066]=35962,
	[243451065]=35961,	[244484225]=39041,	[244484226]=39042,	[242416769]=32705,	[243403952]=33008,	[243404934]=33030,	[243404930]=33026,
	[243403960]=33016,	[243403955]=33011,	[243404943]=33039,	[243404944]=33040,	[243403958]=33014,	[243404945]=33041,	[243404947]=33043,
	[244449435]=36891,	[242363576]=29432,	[242363580]=29436,	[240268479]=21375,	[244449442]=36898,	[244506805]=40501,	[242373785]=30041,
	[244506803]=40499,	[242378929]=30385,	[244487359]=39295,	[244488321]=39297,	[240262284]=20940,	[240262276]=20932,	[241304715]=24651,
	[241337512]=26728,	[241357958]=27974,	[243434672]=34928,	[243434679]=34935,	[244493464]=39640,	[244452525]=37101,	[240312493]=24109,
	[240262278]=20934,	[240314535]=24231,	[242375815]=30151,	[242375813]=30149,	[242374846]=30142,	[241326219]=25995,	[242374841]=30137,
	[242374844]=30140,	[242374834]=30130,	[243404938]=33034,	[241325192]=25928,	[242391227]=31163,	[242405514]=32010,	[240275600]=21776,
	[242371767]=29943,	[243455108]=36164,	[240262281]=20937,	[242396313]=31449,	[240264342]=21078,	[242396318]=31454,	[244452520]=37096,
	[241327233]=26049,	[241327237]=26053,	[242373788]=30044,	[244473989]=38405,	[242415774]=32670,	[242415764]=32660,	[242371766]=29942,
	[241314995]=25331,	[242403465]=31881,	[241326233]=26009,	[242379914]=30410,	[240260284]=20860,	[242355364]=28900,	[242355352]=28888,
	[242355366]=28902,	[242355367]=28903,	[242355355]=28891,	[242355359]=28895,	[242355353]=28889,	[244449426]=36882,	[241359003]=28059,
	[241357977]=27993,	[241359005]=28061,	[241357990]=28006,	[244454546]=37202,	[241358985]=28041,	[241358984]=28040,	[241359009]=28065,
	[241357993]=28009,	[241358007]=28023,	[241358978]=28034,	[241358004]=28020,	[241357998]=28014,	[241359011]=28067,	[241359012]=28068,
	[241357953]=27969,	[241359014]=28070,	[241359015]=28071,	[241358997]=28053,	[241357994]=28010,	[241358008]=28024,	[241359016]=28072,
	[242355371]=28907,	[241359017]=28073,	[241358988]=28044,	[241305750]=24726,	[241305759]=24735,	[241305732]=24708,	[241305741]=24717,
	[241305748]=24724,	[241305775]=24751,	[241305766]=24742,	[240302259]=23475,	[240302269]=23485,	[240302262]=23478,	[240302261]=23477,
	[240302260]=23476,	[240302270]=23486,	[242395277]=31373,	[242395268]=31364,	[240302265]=23481,	[240302256]=23472,	[241337480]=26696,
	[243449015]=35831,	[241332375]=26391,	[243449016]=35832,	[243449018]=35834,	[243449019]=35835,	[241312903]=25159,	[243449021]=35837,
	[243435676]=34972,	[243435670]=34966,	[243435661]=34957,	[243435691]=34987,	[242390181]=31077,	[243449022]=35838,	[240261285]=20901,
	[243449985]=35841,	[243449987]=35843,	[240261284]=20900,	[243449989]=35845,	[243449990]=35846,	[243449992]=35848,	[243449994]=35850,
	[240264357]=21093,	[241304755]=24691,	[240305301]=23637,	[240264359]=21095,	[240305297]=23633,	[240316593]=24369,	[244475061]=38517,
	[242390175]=31071,	[244475062]=38518,	[244475063]=38519,	[244475050]=38506,	[240296113]=23089,	[240296095]=23071,	[241304725]=24661,
	[240296101]=23077,	[240296088]=23064,	[244449434]=36890,	[243403965]=33021,	[244476094]=38590,	[244484228]=39044,	[241337489]=26705,
	[242412706]=32482,	[242412707]=32483,	[244492428]=39564,	[242412711]=32487,	[244492431]=39567,	[242368643]=29699,	[242368656]=29712,
	[242368646]=29702,	[242368649]=29705,	[242368645]=29701,	[241317031]=25447,	[240287925]=22581,	[241318058]=25514,	[241319055]=25551,
	[240286879]=22495,	[241317050]=25466,	[241318057]=25513,	[241317047]=25463,	[241318034]=25490,	[242356361]=28937,	[241318025]=25481,
	[241317046]=25462,	[243455142]=36198,	[240287878]=22534,	[241318056]=25512,	[240286880]=22496,	[241318016]=25472,	[241318024]=25480,
	[241317051]=25467,	[241325209]=25945,	[241318031]=25487,	[241318032]=25488,	[241318048]=25504,	[241318018]=25474,	[240286905]=22521,
	[241318053]=25509,	[241318071]=25527,	[241318055]=25511,	[241318050]=25506,	[241317038]=25454,	[241318040]=25496,	[241318074]=25530,
	[243401868]=32844,	[240286906]=22522,	[243401862]=32838,	[240266392]=21208,	[243401866]=32842,	[240296118]=23094,	[243418263]=33879,
	[243416241]=33777,	[240266386]=21202,	[244509828]=40644,	[243416242]=33778,	[243417228]=33804,	[243417245]=33821,	[243416204]=33740,
	[243417230]=33806,	[243416220]=33756,	[243417220]=33796,	[243416202]=33738,	[243416233]=33769,	[243417229]=33805,	[243416224]=33760,
	[243417252]=33828,	[243417253]=33829,	[239264958]=20094,	[243417255]=33831,	[243417256]=33832,	[243416199]=33735,	[241338544]=26800,
	[240317612]=24428,	[241338534]=26790,	[240297130]=23146,	[241338519]=26775,	[241338535]=26791,	[241338530]=26786,	[241338501]=26757,
	[241339520]=26816,	[241338547]=26803,	[241338543]=26799,	[241337526]=26742,	[241338541]=26797,	[241325201]=25937,	[241331385]=26361,
	[240264367]=21103,	[242390184]=31080,	[244454557]=37213,	[244454551]=37207,	[240269474]=21410,	[241311898]=25114,	[242386053]=30789,
	[242386069]=30805,	[240293026]=22882,	[242379924]=30420,	[242360509]=29245,	[243401867]=32843,	[243435693]=34989,	[242379931]=30427,
	[240267454]=21310,	[244477098]=38634,	[243464325]=36741,	[243464326]=36742,	[244484229]=39045,	[243426458]=34394,	[240317610]=24426,
	[244477056]=38592,	[240287874]=22530,	[240312504]=24120,	[242380982]=30518,	[240267417]=21273,	[241329320]=26216,	[242381953]=30529,
	[242380975]=30511,	[242380988]=30524,	[241305772]=24748,	[244456590]=37326,	[240276650]=21866,	[240276646]=21862,	[241331388]=26364,
	[241329318]=26214,	[241329306]=26202,	[240276612]=21828,	[240276641]=21857,	[243457181]=36317,	[243456190]=36286,	[240276611]=21827,
	[243457155]=36291,	[242373797]=30053,	[243427503]=34479,	[243428480]=34496,	[243428487]=34503,	[240275628]=21804,	[242405551]=32047,
	[244453506]=37122,	[240275633]=21809,	[241305763]=24739,	[240276656]=21872,	[240275646]=21822,	[240275631]=21807,	[240276644]=21860,
	[240276645]=21861,	[240276664]=21880,	[240308374]=23830,	[240308366]=23822,	[240308397]=23853,	[244449467]=36923,	[240308372]=23828,
	[240312503]=24119,	[240308393]=23849,	[240308359]=23815,	[240308379]=23835,	[240297140]=23156,	[240283784]=22280,	[244468880]=38096,
	[244468891]=38107,	[244468893]=38109,	[244468892]=38108,	[244468909]=38125,	[244468914]=38130,	[244468918]=38134,	[242384043]=30699,
	[242372764]=29980,	[242392248]=31224,	[241338536]=26792,	[242362497]=29313,	[242392253]=31229,	[242392251]=31227,	[242397352]=31528,
	[242397372]=31548,	[242397339]=31515,	[242397337]=31513,	[242397350]=31526,	[242397356]=31532,	[241325199]=25935,	[240256154]=20570,
	[243435659]=34955,	[241305760]=24736,	[240256191]=20607,	[240256182]=20598,	[240256142]=20558,	[240256183]=20599,	[241305768]=24744,
	[240275630]=21806,	[240256156]=20572,	[240256143]=20559,	[243460271]=36527,	[240260252]=20828,	[240256135]=20551,	[243434629]=34885,
	[240318616]=24472,	[240318617]=24473,	[240318615]=24471,	[243434644]=34900,	[242379928]=30424,	[243409078]=33334,	[243409081]=33337,
	[243409077]=33333,	[241326236]=26012,	[242379922]=30418,	[244506813]=40509,	[241325211]=25947,	[241305737]=24713,	[241348786]=27442,
	[240317609]=24425,	[244484230]=39046,	[243404954]=33050,	[243404950]=33046,	[243404975]=33071,	[243451034]=35930,	[243404984]=33080,
	[243404977]=33073,	[243451041]=35937,	[240291999]=22815,	[244449464]=36920,	[242364572]=29468,	[242364586]=29482,	[242364558]=29454,
	[242364587]=29483,	[240262320]=20976,	[242364566]=29462,	[242364571]=29467,	[242390189]=31085,	[244488325]=39301,	[244488326]=39302,
	[240262289]=20945,	[240262287]=20943,	[241351851]=27627,	[242355385]=28921,	[240314550]=24246,	[244508859]=40635,	[240314549]=24245,
	[242375818]=30154,	[242375826]=30162,	[242375829]=30165,	[240315530]=24266,	[240314551]=24247,	[240314552]=24248,	[244507839]=40575,
	[242379927]=30423,	[242396320]=31456,	[242396319]=31455,	[240276614]=21830,	[241327247]=26063,	[241327243]=26059,	[241332379]=26395,
	[242366599]=29575,	[244473998]=38414,	[244474000]=38416,	[242381952]=30528,	[242415770]=32666,	[242379926]=30422,	[242380983]=30519,
	[242403480]=31896,	[242403479]=31895,	[242403474]=31890,	[241326253]=26029,	[240264362]=21098,	[240260285]=20861,	[242356362]=28938,
	[242356373]=28949,	[241361029]=28165,	[241360059]=28155,	[244506815]=40511,	[241360011]=28107,	[241359023]=28079,	[241360057]=28153,
	[241361056]=28192,	[241361040]=28176,	[241360017]=28113,	[241360012]=28108,	[241360055]=28151,	[241360046]=28142,	[241360006]=28102,
	[241361034]=28170,	[241360043]=28139,	[241361044]=28180,	[241360024]=28120,	[241360051]=28147,	[241359026]=28082,	[241360036]=28132,
	[241360033]=28129,	[241360000]=28096,	[241360049]=28145,	[241359022]=28078,	[241359029]=28085,	[240297094]=23110,	[241338497]=26753,
	[241361047]=28183,	[241306757]=24773,	[241306780]=24796,	[241306797]=24813,	[241305788]=24764,	[241306791]=24807,	[241306773]=24789,
	[241306783]=24799,	[241306762]=24778,	[241306790]=24806,	[241305780]=24756,	[241306763]=24779,	[241306792]=24808,	[241306799]=24815,
	[240303239]=23495,	[240303237]=23493,	[240303236]=23492,	[240303234]=23490,	[240302271]=23487,	[242395282]=31378,	[242395281]=31377,
	[240303238]=23494,	[243449995]=35851,	[243449997]=35853,	[243449998]=35854,	[243450000]=35856,	[243435697]=34993,	[242390199]=31095,
	[242390200]=31096,	[243450003]=35859,	[243450010]=35866,	[243450012]=35868,	[244449454]=36910,	[241325218]=25954,	[240304265]=23561,
	[240305312]=23648,	[240316601]=24377,	[244476043]=38539,	[240287893]=22549,	[244476047]=38543,	[243428491]=34507,	[244476037]=38533,
	[244476038]=38534,	[244476048]=38544,	[240297114]=23130,	[240297142]=23158,	[240297097]=23113,	[244484231]=39047,	[244484232]=39048,
	[242412713]=32489,	[242412714]=32490,	[242412717]=32493,	[244492433]=39569,	[242412720]=32496,	[242412723]=32499,	[242412724]=32500,
	[242412725]=32501,	[242412727]=32503,	[242412728]=32504,	[242412732]=32508,	[242412733]=32509,	[242412735]=32511,	[242413696]=32512,
	[240311458]=24034,	[242368692]=29748,	[242368691]=29747,	[242368674]=29730,	[242368700]=29756,	[241326225]=26001,	[241331391]=26367,
	[241319053]=25549,	[241348798]=27454,	[240287914]=22570,	[240288916]=22612,	[241320109]=25645,	[240287920]=22576,	[241319081]=25577,
	[243456138]=36234,	[243456129]=36225,	[243456139]=36235,	[243456133]=36229,	[241319101]=25597,	[240287908]=22564,	[241319056]=25552,
	[240268442]=21338,	[241319085]=25581,	[240277660]=21916,	[240317613]=24429,	[241319075]=25571,	[241319058]=25554,	[241319082]=25578,
	[241320092]=25628,	[242357422]=29038,	[241319092]=25588,	[241320064]=25600,	[243436673]=35009,	[241320065]=25601,	[241320083]=25619,
	[241320066]=25602,	[241320069]=25605,	[240291001]=22777,	[241319073]=25569,	[241320084]=25620,	[241319049]=25545,	[241326255]=26031,
	[241332383]=26399,	[241348794]=27450,	[243401876]=32852,	[243418283]=33899,	[241325219]=25955,	[241306809]=24825,	[243418284]=33900,
	[240266399]=21215,	[243418267]=33883,	[243418275]=33891,	[243418273]=33889,	[241325228]=25964,	[243418289]=33905,	[243419275]=33931,
	[243419266]=33922,	[243417277]=33853,	[244481193]=38889,	[241332381]=26397,	[243464348]=36764,	[243418293]=33909,	[241339538]=26834,
	[241339569]=26865,	[241339531]=26827,	[241340592]=26928,	[241340557]=26893,	[241339566]=26862,	[242356378]=28954,	[241340549]=26885,
	[241340562]=26898,	[241339573]=26869,	[241339533]=26829,	[241340558]=26894,	[241339529]=26825,	[241339546]=26842,	[241339541]=26837,
	[241339578]=26874,	[241342612]=27028,	[241340589]=26925,	[241306784]=24800,	[241306769]=24785,	[244449468]=36924,	[242403487]=31903,
	[241339544]=26840,	[244454563]=37219,	[244454565]=37221,	[240269480]=21416,	[240269478]=21414,	[242386092]=30828,	[242386077]=30813,
	[242386094]=30830,	[242386091]=30827,	[244477057]=38593,	[241350806]=27542,	[243436674]=35010,	[244477060]=38596,	[244484234]=39050,
	[244477107]=38643,	[241330306]=26242,	[244477061]=38597,	[242416792]=32728,	[243464328]=36744,	[241305778]=24754,	[242405547]=32043,
	[240262335]=20991,	[243464329]=36745,	[241325214]=25950,	[241339552]=26848,	[243455119]=36175,	[241318028]=25484,	[241329332]=26228,
	[242381968]=30544,	[241330321]=26257,	[241332352]=26368,	[241329328]=26224,	[244456591]=37327,	[244510862]=40718,	[240277687]=21943,
	[240277683]=21939,	[241329334]=26230,	[240277639]=21895,	[244450439]=36935,	[240277642]=21898,	[244450447]=36943,	[241329342]=26238,
	[241329327]=26223,	[242373812]=30068,	[243457205]=36341,	[243457163]=36299,	[243457164]=36300,	[243457169]=36305,	[243457179]=36315,
	[244450455]=36951,	[243428505]=34521,	[243428507]=34523,	[243429523]=34579,	[243429522]=34578,	[243428516]=34532,	[240277661]=21917,
	[244507779]=40515,	[240277634]=21890,	[240277656]=21912,	[240277641]=21897,	[240277691]=21947,	[240276668]=21884,	[240277671]=21927,
	[240309388]=23884,	[240313477]=24133,	[240312509]=24125,	[243455115]=36171,	[243455116]=36172,	[243455118]=36174,	[243455120]=36176,
	[243455124]=36180,	[244509841]=40657,	[244468920]=38136,	[244468922]=38138,	[244468926]=38142,	[244469888]=38144,	[244469889]=38145,
	[244469892]=38148,	[244469893]=38149,	[244469896]=38152,	[244469899]=38155,	[244469900]=38156,	[244469904]=38160,	[242372773]=29989,
	[241318064]=25520,	[242384045]=30701,	[241329338]=26234,	[241352878]=27694,	[241351855]=27631,	[241352879]=27695,	[244507781]=40517,
	[240264361]=21097,	[242393229]=31245,	[242393227]=31243,	[242393216]=31232,	[242393230]=31246,	[242398352]=31568,	[242398345]=31561,
	[242398353]=31569,	[242398358]=31574,	[242398363]=31579,	[242398354]=31570,	[242398351]=31567,	[242398356]=31572,	[242398347]=31563,
	[242398365]=31581,	[240257202]=20658,	[240257157]=20613,	[242361484]=29260,	[240287905]=22561,	[244477062]=38598,	[242356390]=28966,
	[240257165]=20621,	[240257192]=20648,	[242378899]=30355,	[242378902]=30358,	[242403492]=31908,	[240293029]=22885,	[243434647]=34903,
	[241306793]=24809,	[240318625]=24481,	[240318634]=24490,	[243410055]=33351,	[243409042]=33298,	[244449470]=36926,	[242373802]=30058,
	[244456586]=37322,	[242391229]=31165,	[243405962]=33098,	[243404990]=33086,	[243405963]=33099,	[243405972]=33108,	[243405973]=33109,
	[244500609]=40065,	[242364585]=29481,	[242364588]=29484,	[242364606]=29502,	[242364596]=29492,	[241306795]=24811,	[242356406]=28982,
	[244488328]=39304,	[244488331]=39307,	[243436677]=35013,	[243428526]=34542,	[240304305]=23601,	[241325222]=25958,	[241326220]=25996,
	[242375832]=30168,	[242375842]=30178,	[242375850]=30186,	[242375835]=30171,	[242396325]=31461,	[242396323]=31459,	[244474004]=38420,
	[240277636]=21892,	[242416788]=32724,	[242415777]=32673,	[241329326]=26222,	[242403498]=31914,	[240304266]=23562,	[240293024]=22880,
	[244450451]=36947,	[244450434]=36930,	[241331390]=26366,	[242356400]=28976,	[241361071]=28207,	[241364126]=28382,	[241362070]=28246,
	[241362072]=28248,	[241361059]=28195,	[241361060]=28196,	[241361082]=28218,	[241362111]=28287,	[241361065]=28201,	[241361076]=28212,
	[241363075]=28291,	[241363077]=28293,	[241364113]=28369,	[241362051]=28227,	[241361053]=28189,	[241362110]=28286,	[241361057]=28193,
	[241361080]=28216,	[241364107]=28363,	[241361074]=28210,	[241363081]=28297,	[241307812]=24868,	[241308812]=24908,	[241306800]=24816,
	[241307797]=24853,	[241307811]=24867,	[241306806]=24822,	[241307815]=24871,	[241307785]=24841,	[241308840]=24936,	[240264370]=21106,
	[240303250]=23506,	[240303244]=23500,	[240303251]=23507,	[242395292]=31388,	[242395293]=31389,	[242395286]=31382,	[242395287]=31383,
	[242395288]=31384,	[244450445]=36941,	[244477063]=38599,	[243436693]=35029,	[243436708]=35044,	[243436697]=35033,	[242391173]=31109,
	[242391172]=31108,	[243450018]=35874,	[243450019]=35875,	[243450020]=35876,	[243450022]=35878,	[242362496]=29312,	[240305310]=23646,
	[240305313]=23649,	[240316602]=24378,	[242403493]=31909,	[242374799]=30095,	[244476052]=38548,	[244476057]=38553,	[244476056]=38552,
	[240298130]=23186,	[242406574]=32110,	[240299138]=23234,	[240298138]=23194,	[240297151]=23167,	[242377915]=30331,	[242413701]=32517,
	[242413702]=32518,	[242413705]=32521,	[242413710]=32526,	[242413715]=32531,	[242413716]=32532,	[242413717]=32533,	[244492439]=39575,
	[242413718]=32534,	[244492442]=39578,	[242413720]=32536,	[242369695]=29791,	[244507785]=40521,	[242369694]=29790,	[242369712]=29808,
	[242369689]=29785,	[244495490]=39746,	[243402886]=32902,	[241321092]=25668,	[241321144]=25720,	[240288939]=22635,	[241320079]=25615,
	[240288908]=22604,	[244510867]=40723,	[241321094]=25670,	[241320122]=25658,	[241320108]=25644,	[241321095]=25671,	[241320094]=25630,
	[240288920]=22616,	[241321098]=25674,	[243401880]=32856,	[241326239]=26015,	[243419292]=33948,	[240266404]=21220,	[244479156]=38772,
	[244479158]=38774,	[244507786]=40522,	[243420317]=34013,	[240289939]=22675,	[240313493]=24149,	[243420332]=34028,	[243420292]=33988,
	[243419314]=33970,	[243420297]=33993,	[243419289]=33945,	[243419320]=33976,	[242364590]=29486,	[241340607]=26943,	[242391169]=31105,
	[241341594]=26970,	[241341623]=26999,	[241342596]=27012,	[241306803]=24819,	[241343632]=27088,	[241342598]=27014,	[241341628]=27004,
	[241342594]=27010,	[243455126]=36182,	[244454570]=37226,	[244454572]=37228,	[241307807]=24863,	[242387085]=30861,	[242387096]=30872,
	[242387089]=30865,	[242387086]=30862,	[242387120]=30896,	[242387095]=30871,	[242387084]=30860,	[240304308]=23604,	[244477111]=38647,
	[244477110]=38646,	[244477118]=38654,	[244477113]=38649,	[243464336]=36752,	[243464337]=36753,	[243464339]=36755,	[242381987]=30563,
	[244484241]=39057,	[244512900]=40836,	[244458676]=37492,	[242381979]=30555,	[242382009]=30585,	[242381990]=30566,	[242382980]=30596,
	[242381995]=30571,	[242381985]=30561,	[242381996]=30572,	[240278684]=21980,	[244453529]=37145,	[240278694]=21990,	[241307802]=24858,
	[241330326]=26262,	[242379935]=30431,	[241349767]=27463,	[241330327]=26263,	[241330311]=26247,	[242357415]=29031,	[242373816]=30072,
	[243457192]=36328,	[243457207]=36343,	[243457203]=36339,	[243457210]=36346,	[243457194]=36330,	[243457199]=36335,	[243457188]=36324,
	[243457183]=36319,	[244450467]=36963,	[243429512]=34568,	[243429527]=34583,	[243428542]=34558,	[243429506]=34562,	[243429525]=34581,
	[240278661]=21957,	[240278689]=21985,	[240278675]=21971,	[242414770]=32626,	[242414766]=32622,	[242414762]=32618,	[242414761]=32617,
	[243429504]=34560,	[240313484]=24140,	[244469913]=38169,	[244469914]=38170,	[244469921]=38177,	[244469923]=38179,	[244469924]=38180,
	[244469925]=38181,	[244469926]=38182,	[244469934]=38190,	[244469935]=38191,	[244469936]=38192,	[242384046]=30702,	[243464350]=36766,
	[242393242]=31258,	[242393248]=31264,	[244484243]=39059,	[241307777]=24833,	[242398393]=31609,	[242398398]=31614,	[242399360]=31616,
	[242398391]=31607,	[241351809]=27585,	[243409029]=33285,	[244510880]=40736,	[240257196]=20652,	[240257211]=20667,	[240258191]=20687,
	[243460274]=36530,	[244495489]=39745,	[243434649]=34905,	[240318638]=24494,	[241307784]=24840,	[244450469]=36965,	[243406011]=33147,
	[243406000]=33136,	[243405989]=33125,	[243405998]=33134,	[243406009]=33145,	[243406010]=33146,	[244507791]=40527,	[243406014]=33150,
	[243406015]=33151,	[244500621]=40077,	[242364607]=29503,	[244484246]=39062,	[243440806]=35302,	[243440803]=35299,	[242357406]=29022,
	[244477071]=38607,	[244488333]=39309,	[244488335]=39311,	[244454577]=37233,	[242391168]=31104,	[242375865]=30201,	[240315539]=24275,
	[242375860]=30196,	[242375856]=30192,	[240315529]=24265,	[244479126]=38742,	[241326256]=26032,	[244481205]=38901,	[241307791]=24847,
	[243443850]=35466,	[242403502]=31918,	[241325232]=25968,	[242357390]=29006,	[240288913]=22609,	[241308808]=24904,	[242357412]=29028,
	[242357388]=29004,	[241364129]=28385,	[241365152]=28448,	[241364103]=28359,	[241363088]=28304,	[241364132]=28388,	[241364133]=28389,
	[241364116]=28372,	[241363114]=28330,	[241363100]=28316,	[241365139]=28435,	[241364122]=28378,	[241363106]=28322,	[241363119]=28335,
	[241364136]=28392,	[241363126]=28342,	[241363130]=28346,	[242403505]=31921,	[241364137]=28393,	[241308814]=24910,	[243443849]=35465,
	[240288926]=22622,	[240303262]=23518,	[242395301]=31397,	[242395295]=31391,	[240303261]=23517,	[243450024]=35880,	[243437698]=35074,
	[243436728]=35064,	[242391183]=31119,	[243450028]=35884,	[242415780]=32676,	[241350847]=27583,	[243464351]=36767,	[244476060]=38556,
	[240298163]=23219,	[240299145]=23241,	[240299148]=23244,	[240299137]=23233,	[240270496]=21472,	[242413722]=32538,	[242413725]=32541,
	[242413728]=32544,	[242413732]=32548,	[240264383]=21119,	[244479129]=38745,	[242387111]=30887,	[242370691]=29827,	[243455128]=36184,
	[242358444]=29100,	[240289945]=22681,	[240289951]=22687,	[240279689]=22025,	[241321127]=25703,	[243455147]=36203,	[241311914]=25130,
	[243443859]=35475,	[240289923]=22659,	[241321112]=25688,	[241321108]=25684,	[241322119]=25735,	[243401882]=32858,	[241308821]=24917,
	[241330350]=26286,	[241321145]=25721,	[243421331]=34067,	[243421329]=34065,	[243421345]=34081,	[243421335]=34071,	[243421373]=34109,
	[243421372]=34108,	[242358425]=29081,	[243421338]=34074,	[240260258]=20834,	[241344673]=27169,	[241343643]=27099,	[241342644]=27060,
	[241342620]=27036,	[241342632]=27048,	[241342613]=27029,	[241349772]=27468,	[244450477]=36973,	[244454581]=37237,	[244454583]=37239,
	[244454591]=37247,	[244454584]=37240,	[242387103]=30879,	[242387121]=30897,	[242387123]=30899,	[242388097]=30913,	[241307839]=24895,
	[244478080]=38656,	[243464342]=36758,	[243464343]=36759,	[244477068]=38604,	[243436723]=35059,	[244484247]=39063,	[242382981]=30597,
	[240289925]=22661,	[240278717]=22013,	[243458186]=36362,	[243429563]=34619,	[243429537]=34593,	[243430535]=34631,	[243429528]=34584,
	[243430537]=34633,	[240279707]=22043,	[240279680]=22016,	[243455130]=36186,	[244469945]=38201,	[244469947]=38203,	[244470912]=38208,
	[243409054]=33310,	[243409044]=33300,	[242393267]=31283,	[242358415]=29071,	[242399381]=31637,	[242399383]=31639,	[242399401]=31657,
	[242399393]=31649,	[242399403]=31659,	[243409030]=33286,	[240258202]=20698,	[240258215]=20711,	[244510907]=40763,	[244495492]=39748,
	[244495493]=39749,	[243452044]=35980,	[243407004]=33180,	[243406986]=33162,	[243406976]=33152,	[244500636]=40092,	[242374801]=30097,
	[240301237]=23413,	[244488338]=39314,	[243436729]=35065,	[241325234]=25970,	[243451050]=35946,	[243406991]=33167,	[244450478]=36974,
	[243405968]=33104,	[242376873]=30249,	[242376863]=30239,	[242376870]=30246,	[243464355]=36771,	[240317616]=24432,	[242396333]=31469,
	[242396335]=31471,	[241327255]=26071,	[242403518]=31934,	[242403513]=31929,	[241349769]=27465,	[240316554]=24330,	[242358404]=29060,
	[242358420]=29076,	[242357437]=29053,	[241366151]=28487,	[241365126]=28422,	[241365169]=28465,	[241365122]=28418,	[241365163]=28459,
	[241364148]=28404,	[241365182]=28478,	[241365140]=28436,	[241365135]=28431,	[241308834]=24930,	[241308855]=24951,	[240303272]=23528,
	[243455131]=36187,	[240303265]=23521,	[240303263]=23519,	[243429532]=34588,	[240303269]=23525,	[243450029]=35885,	[243402887]=32903,
	[243437712]=35088,	[243437738]=35114,	[243450033]=35889,	[244476071]=38567,	[240299177]=23273,	[242416800]=32736,	[242358410]=29066,
	[240262323]=20979,	[244492449]=39585,	[242413737]=32553,	[241308839]=24935,	[241322165]=25781,	[241322133]=25749,	[241322130]=25746,
	[241322153]=25769,	[243456163]=36259,	[243456159]=36255,	[241322129]=25745,	[241322158]=25774,	[241322156]=25772,	[241322157]=25773,
	[241323154]=25810,	[240289961]=22697,	[241322142]=25758,	[241322148]=25764,	[240289950]=22686,	[241322160]=25776,	[243401898]=32874,
	[244480139]=38795,	[244480141]=38797,	[243422345]=34121,	[243422346]=34122,	[243421356]=34092,	[243422388]=34164,	[241344682]=27178,
	[241343677]=27133,	[241344689]=27185,	[241345697]=27233,	[241344671]=27167,	[241345668]=27204,	[241325239]=25975,	[243451020]=35916,
	[244485272]=39128,	[244455563]=37259,	[244455559]=37255,	[244455561]=37257,	[242388117]=30933,	[242388106]=30922,	[242388101]=30917,
	[242387134]=30910,	[244478087]=38663,	[244478084]=38660,	[244478089]=38665,	[242382994]=30610,	[244484248]=39064,	[241330356]=26292,
	[242382990]=30606,	[240279739]=22075,	[240279734]=22070,	[240279730]=22066,	[240279737]=22073,	[240317617]=24433,	[243458210]=36386,
	[243458191]=36367,	[243458217]=36393,	[243458218]=36394,	[243430582]=34678,	[243430580]=34676,	[243430560]=34656,	[243430542]=34638,
	[243430540]=34636,	[243430551]=34647,	[243430553]=34649,	[240279743]=22079,	[240279729]=22065,	[240313506]=24162,	[240289960]=22696,
	[244470919]=38215,	[244470928]=38224,	[244470929]=38225,	[244479136]=38752,	[242393277]=31293,	[242393275]=31291,	[244509838]=40654,
	[242393279]=31295,	[242393276]=31292,	[242399409]=31665,	[242400403]=31699,	[242399405]=31661,	[242400391]=31687,	[240258229]=20725,
	[243460282]=36538,	[240258235]=20731,	[240318647]=24503,	[243410072]=33368,	[243407005]=33181,	[243407003]=33179,	[244500644]=40100,
	[244500651]=40107,	[242358431]=29087,	[241321129]=25705,	[243437714]=35090,	[242376874]=30250,	[242376868]=30244,	[242376875]=30251,
	[240262299]=20955,	[244484252]=39068,	[241351813]=27589,	[242404490]=31946,	[244450485]=36981,	[241309835]=24971,	[241366172]=28508,
	[241367182]=28558,	[241366190]=28526,	[241366189]=28525,	[244500648]=40104,	[241367219]=28595,	[241366168]=28504,	[241367176]=28552,
	[241367196]=28572,	[241367172]=28548,	[241310850]=25026,	[241309844]=24980,	[241310858]=25034,	[241309838]=24974,	[244484253]=39069,
	[242416809]=32745,	[243437733]=35109,	[243450036]=35892,	[244507812]=40548,	[241309864]=25000,	[241308848]=24944,	[240265352]=21128,
	[240305317]=23653,	[243451051]=35947,	[242413741]=32557,	[241322172]=25788,	[241323138]=25794,	[241323149]=25805,	[241323141]=25797,
	[242359445]=29141,	[243422398]=34174,	[243423407]=34223,	[243423387]=34203,	[243423367]=34183,	[241323150]=25806,	[243423402]=34218,
	[243423364]=34180,	[244484256]=39072,	[242416816]=32752,	[240280745]=22121,	[241345713]=27249,	[241345689]=27225,	[241345688]=27224,
	[241325236]=25972,	[243431565]=34701,	[242371746]=29922,	[244455570]=37266,	[244478093]=38669,	[244478094]=38670,	[243464345]=36761,
	[240261248]=20864,	[244486288]=39184,	[240279732]=22068,	[243458225]=36401,	[243459204]=36420,	[243459202]=36418,	[243432582]=34758,
	[243431555]=34691,	[240280744]=22120,	[240280746]=22122,	[244507814]=40550,	[243455136]=36192,	[244509848]=40664,	[244509844]=40660,
	[244470940]=38236,	[243455134]=36190,	[242394246]=31302,	[242400430]=31726,	[242400417]=31713,	[242400439]=31735,	[242400433]=31729,
	[240259218]=20754,	[244451456]=36992,	[243434657]=34913,	[243407016]=33192,	[244477077]=38613,	[244500664]=40120,	[242388136]=30952,
	[242376894]=30270,	[242376888]=30264,	[240262301]=20957,	[243464360]=36776,	[243464361]=36777,	[242404505]=31961,	[242404502]=31958,
	[242404501]=31957,	[242359427]=29123,	[241368210]=28626,	[241367201]=28577,	[241368192]=28608,	[241310866]=25042,	[241309886]=25022,
	[241310856]=25032,	[242395327]=31423,	[240290945]=22721,	[244450495]=36991,	[242413744]=32560,	[242413748]=32564,	[241311924]=25140,
	[241323174]=25830,	[243424393]=34249,	[244480160]=38816,	[243424399]=34255,	[243424400]=34256,	[241346732]=27308,	[241346704]=27280,
	[241346688]=27264,	[242389121]=30977,	[242388151]=30967,	[244478108]=38684,	[244478110]=38686,	[242383021]=30637,	[242383015]=30631,
	[242383020]=30636,	[242383027]=30643,	[242383017]=30633,	[242383018]=30634,	[241331353]=26329,	[243459211]=36427,	[243459208]=36424,
	[243431610]=34746,	[243432587]=34763,	[243432576]=34752,	[240281742]=22158,	[243455137]=36193,	[242394263]=31319,	[244495503]=39759,
	[242401447]=31783,	[242401415]=31751,	[242410625]=32321,	[240318653]=24509,	[242360501]=29237,	[241332390]=26406,	[243408010]=33226,
	[244501636]=40132,	[242377868]=30284,	[243464363]=36779,	[243455138]=36194,	[242404511]=31967,	[242404512]=31968,	[242359461]=29157,
	[241310886]=25062,	[243451009]=35905,	[243408000]=33216,	[243408002]=33218,	[242416828]=32764,	[244492452]=39588,	[243424405]=34261,
	[244480173]=38829,	[243424420]=34276,	[243439750]=35206,	[242383035]=30651,	[243459238]=36454,	[240281763]=22179,	[244470960]=38256,
	[242416827]=32763,	[244501645]=40141,	[244507824]=40560,	[242352273]=28689,	[243438751]=35167,	[242370727]=29863,	[241311923]=25139,
	[240301245]=23421,	[243446950]=35686,	[243425425]=34321,	[243424443]=34299,	[241324160]=25856,	[241331357]=26333,	[243459250]=36466,
	[243459245]=36461,	[243459244]=36460,	[240311429]=24005,	[242401464]=31800,	[242401471]=31807,	[243432633]=34809,	[244484260]=39076,
	[244479137]=38753,	[242377891]=30307,	[242371747]=29923,	[242415801]=32697,	[244501654]=40150,	[242360454]=29190,	[242374790]=30086,
	[244494483]=39699,	[240290980]=22756,	[244488360]=39336,	[243400832]=32768,	[243460225]=36481,	[243433621]=34837,	[240281788]=22204,
	[240281783]=22199,	[240311437]=24013,	[242402445]=31821,	[244501662]=40158,	[244495508]=39764,	[242404527]=31983,	[242353292]=28748,
	[243446956]=35692,	[243433634]=34850,	[244478136]=38712,	[244478130]=38706,	[244478137]=38713,	[243460239]=36495,	[244509871]=40687,
	[244493459]=39635,	[243455139]=36195,	[240282762]=22218,	[244470966]=38262,	[242371748]=29924,	[242414736]=32592,	[242384023]=30679,
	[239264898]=20034,	[239264924]=20060,	[240260224]=20800,	[240316555]=24331,	[240301201]=23377,	[240301203]=23379,	[240313530]=24186,
	[239265939]=20115,	[244481190]=38886,	[240315583]=24319,	[239263887]=19983,	[240268421]=21317,	[239266948]=20164,	[240269444]=21380,
	[239266947]=20163,	[239266953]=20169,	[239266946]=20162,	[240260270]=20846,	[240263304]=21000,	[242360507]=29243,	[240268446]=21342,
	[244473001]=38377,	[243447971]=35747,	[240304313]=23609,	[240292012]=22828,	[242360511]=29247,	[241351819]=27595,	[244451479]=37015,
	[244451483]=37019,	[243410109]=33405,	[243410111]=33407,	[241332397]=26413,	[240270517]=21493,	[240267421]=21277,	[239263893]=19989,
	[240267420]=21276,	[240265378]=21154,	[240268447]=21343,	[240270513]=21489,	[240270523]=21499,	[239266984]=20200,	[239266965]=20181,
	[239266975]=20191,	[239266977]=20193,	[239266987]=20203,	[239266974]=20190,	[240268462]=21358,	[241352848]=27664,	[242362544]=29360,
	[240263309]=21005,	[244451485]=37021,	[244451481]=37017,	[241353856]=27712,	[243447974]=35750,	[243447975]=35751,	[243447978]=35754,
	[243447979]=35755,	[240304315]=23611,	[244474017]=38433,	[240304277]=23573,	[240316545]=24321,	[244491437]=39533,	[240267425]=21281,
	[243400850]=32786,	[242366606]=29582,	[242366609]=29585,	[244451490]=37026,	[240283817]=22313,	[240283820]=22316,	[240283821]=22317,
	[241312934]=25190,	[240283818]=22314,	[240283827]=22323,	[240283833]=22329,	[241312938]=25194,	[240283822]=22318,	[240283823]=22319,
	[243411082]=33418,	[243411085]=33421,	[243411076]=33412,	[243411112]=33448,	[243411089]=33425,	[243411086]=33422,	[243411095]=33431,
	[239265944]=20120,	[240269453]=21389,	[240292028]=22844,	[241311885]=25101,	[240304293]=23589,	[239264937]=20073,	[241327279]=26095,
	[241331379]=26355,	[240306316]=23692,	[240305338]=23674,	[240262332]=20988,	[240282785]=22241,	[244467847]=38023,	[242413750]=32566,
	[241352856]=27672,	[241352854]=27670,	[242361501]=29277,	[239267982]=20238,	[239267995]=20251,	[239268002]=20258,	[239269028]=20324,
	[239266997]=20213,	[239268005]=20261,	[239268007]=20263,	[239267977]=20233,	[239268011]=20267,	[240282783]=22239,	[241353862]=27718,
	[240263318]=21014,	[240291993]=22809,	[241327278]=26094,	[240263310]=21006,	[242362551]=29367,	[242362552]=29368,	[243409051]=33307,
	[240262315]=20971,	[244451500]=37036,	[244487335]=39271,	[241353877]=27733,	[241353876]=27732,	[241353872]=27728,	[241353906]=27762,
	[241353884]=27740,	[241353866]=27722,	[240319638]=24534,	[240319631]=24527,	[243447988]=35764,	[243447989]=35765,	[242390145]=31041,
	[243447991]=35767,	[243401919]=32895,	[243410094]=33390,	[240269502]=21438,	[244474033]=38449,	[244474030]=38446,	[244474026]=38442,
	[239263902]=19998,	[240294017]=22913,	[242361503]=29279,	[242411681]=32417,	[242411683]=32419,	[242411685]=32421,	[242411688]=32424,
	[242366613]=29589,	[242366617]=29593,	[241313951]=25247,	[241313940]=25236,	[240283835]=22331,	[240284802]=22338,	[240284813]=22349,
	[240284830]=22366,	[241313923]=25219,	[241313929]=25225,	[238197904]=14800,	[243411115]=33451,	[244451503]=37039,	[243411128]=33464,
	[243411134]=33470,	[243412104]=33480,	[243412131]=33507,	[243411127]=33463,	[243411118]=33454,	[243412107]=33483,	[243411132]=33468,
	[243412108]=33484,	[243412097]=33473,	[243411113]=33449,	[243411114]=33450,	[243411105]=33441,	[243411103]=33439,	[243412100]=33476,
	[243412110]=33486,	[243412129]=33505,	[241333388]=26444,	[241333395]=26451,	[241333406]=26462,	[241333384]=26440,	[240319633]=24529,
	[240301211]=23387,	[244451508]=37044,	[244451507]=37043,	[242384054]=30710,	[240292993]=22849,	[243451029]=35925,	[240319634]=24530,
	[241348772]=27428,	[243463339]=36715,	[243465363]=36819,	[244451510]=37046,	[240319632]=24528,	[240268451]=21347,	[244451514]=37050,
	[241327280]=26096,	[240272523]=21579,	[240272530]=21586,	[240272531]=21587,	[240272532]=21588,	[240272534]=21590,	[240272515]=21571,
	[241327288]=26104,	[240271521]=21537,	[242372794]=30010,	[243426476]=34412,	[240272535]=21591,	[240271549]=21565,	[240271523]=21539,
	[240271538]=21554,	[240312463]=24079,	[240306320]=23696,	[240306312]=23688,	[240306328]=23704,	[240306321]=23697,	[240306330]=23706,
	[240260245]=20821,	[240282805]=22261,	[240282795]=22251,	[244467850]=38026,	[244467851]=38027,	[244467852]=38028,	[243465365]=36821,
	[241352857]=27673,	[241352858]=27674,	[242361508]=29284,	[239269022]=20318,	[244451505]=37041,	[241324216]=25912,	[239269018]=20314,
	[239269021]=20317,	[239269023]=20319,	[239269015]=20311,	[239268029]=20285,	[240317623]=24439,	[239269016]=20312,	[239269029]=20325,
	[240301210]=23386,	[243451064]=35960,	[240284812]=22348,	[243402911]=32927,	[244451512]=37048,	[240292994]=22850,	[240265388]=21164,
	[242363524]=29380,	[242363521]=29377,	[244506784]=40480,	[244451513]=37049,	[244487336]=39272,	[244487337]=39273,	[244487338]=39274,
	[244487339]=39275,	[244487340]=39276,	[239265960]=20136,	[240314513]=24209,	[240314507]=24203,	[242374804]=30100,	[242374806]=30102,
	[243402899]=32915,	[244473009]=38385,	[244473011]=38387,	[244473013]=38389,	[242415756]=32652,	[242354304]=28800,	[241354915]=27811,
	[241354885]=27781,	[241354900]=27796,	[241354916]=27812,	[241354892]=27788,	[241354895]=27791,	[241354906]=27802,	[241353897]=27753,
	[241353896]=27752,	[241354882]=27778,	[241353918]=27774,	[241354920]=27816,	[241353908]=27764,	[241353910]=27766,	[241354886]=27782,
	[241354921]=27817,	[241355920]=27856,	[241303683]=24579,	[241303684]=24580,	[240319649]=24545,	[240319652]=24548,	[240319678]=24574,
	[241303685]=24581,	[240319675]=24571,	[240319658]=24554,	[241303686]=24582,	[240319661]=24557,	[240319672]=24568,	[243448962]=35778,
	[243448963]=35779,	[243448965]=35781,	[243448971]=35787,	[243448972]=35788,	[243448975]=35791,	[243448978]=35794,	[240301212]=23388,
	[244475015]=38471,	[244475008]=38464,	[244475010]=38466,	[244475017]=38473,	[240294029]=22925,	[240294057]=22953,	[240294058]=22954,
	[240294051]=22947,	[240294026]=22922,	[240294039]=22935,	[240294059]=22955,	[240294046]=22942,	[240295058]=22994,	[240294052]=22948,
	[244451509]=37045,	[240265389]=21165,	[240263341]=21037,	[242372780]=29996,	[244451504]=37040,	[242411693]=32429,	[242411696]=32432,
	[242411700]=32436,	[242411702]=32438,	[242411710]=32446,	[242366638]=29614,	[242366625]=29601,	[242366637]=29613,	[242366624]=29600,
	[242366626]=29602,	[242366629]=29605,	[242366630]=29606,	[242379906]=30402,	[240319645]=24541,	[240267430]=21286,	[240284841]=22377,
	[241313960]=25256,	[241314980]=25316,	[240284843]=22379,	[241314952]=25288,	[240285830]=22406,	[241313979]=25275,	[240265404]=21180,
	[241314947]=25283,	[241314954]=25290,	[240284860]=22396,	[240284859]=22395,	[238197919]=14815,	[240284840]=22376,	[240284845]=22381,
	[241313983]=25279,	[240284851]=22387,	[243400886]=32822,	[243412151]=33527,	[243412143]=33519,	[243412132]=33508,	[243413135]=33551,
	[243412139]=33515,	[243412124]=33500,	[243412148]=33524,	[243412114]=33490,	[243412120]=33496,	[243413132]=33548,	[243412155]=33531,
	[243412115]=33491,	[243413146]=33562,	[243413126]=33542,	[243413137]=33553,	[243413139]=33555,	[243413140]=33556,	[243413141]=33557,
	[243413120]=33536,	[243412117]=33493,	[241334437]=26533,	[241334407]=26503,	[241333418]=26474,	[241333427]=26483,	[241334439]=26535,
	[241333429]=26485,	[241334440]=26536,	[241334430]=26526,	[241334411]=26507,	[241333435]=26491,	[241333431]=26487,	[241333436]=26492,
	[242384056]=30712,	[242385024]=30720,	[240263347]=21043,	[240292996]=22852,	[242371759]=29935,	[241350785]=27521,	[244452495]=37071,
	[243463341]=36717,	[244452485]=37061,	[244506786]=40482,	[242379953]=30449,	[241328266]=26122,	[241328281]=26137,	[241333426]=26482,
	[241328259]=26115,	[240273538]=21634,	[240272568]=21624,	[241328277]=26133,	[241328256]=26112,	[241327291]=26107,	[241328265]=26121,
	[242354309]=28805,	[240273556]=21652,	[242373760]=30016,	[243426478]=34414,	[240273536]=21632,	[240272567]=21623,	[244509886]=40702,
	[240272561]=21617,	[240272548]=21604,	[240273562]=21658,	[240273542]=21638,	[240273563]=21659,	[240272566]=21622,	[240272547]=21603,
	[240272550]=21606,	[240273565]=21661,	[240306338]=23714,	[240306367]=23743,	[240306348]=23724,	[240306347]=23723,	[240312473]=24089,
	[240306339]=23715,	[240307329]=23745,	[240263359]=21055,	[243465381]=36837,	[240306359]=23735,	[240264320]=21056,	[240312468]=24084,
	[240307332]=23748,	[241354899]=27795,	[240282809]=22265,	[242414740]=32596,	[244467853]=38029,	[244467854]=38030,	[244467855]=38031,
	[244467858]=38034,	[244467861]=38037,	[244467863]=38039,	[244451518]=37054,	[243465390]=36846,	[242361510]=29286,	[242396346]=31482,
	[243465380]=36836,	[239269046]=20342,	[239269036]=20332,	[239269040]=20336,	[239270033]=20369,	[239270025]=20361,	[243408062]=33278,
	[240306353]=23729,	[239270039]=20375,	[239270019]=20355,	[239270031]=20367,	[239270057]=20393,	[239269051]=20347,	[239269054]=20350,
	[239270058]=20394,	[239269052]=20348,	[239269039]=20335,	[239270060]=20396,	[240312475]=24091,	[244474012]=38428,	[239270036]=20372,
	[240318594]=24450,	[240263357]=21053,	[244452484]=37060,	[241303682]=24578,	[242402484]=31860,	[242371758]=29934,	[241311895]=25111,
	[243402940]=32956,	[239221917]=17373,	[243402941]=32957,	[243402929]=32945,	[243402923]=32939,	[240264321]=21057,	[243465385]=36841,
	[244452487]=37063,	[242363545]=29401,	[242363534]=29390,	[242363533]=29389,	[242363538]=29394,	[240273550]=21646,	[242354329]=28825,
	[241334445]=26541,	[244487343]=39279,	[244487348]=39284,	[240261309]=20925,	[240261308]=20924,	[240314518]=24214,	[242374816]=30112,
	[242374813]=30109,	[242374817]=30113,	[240260246]=20822,	[240294078]=22974,	[240265406]=21182,	[242354332]=28828,	[180495548]=180860,
	[242354326]=28822,	[242354328]=28824,	[242354333]=28829,	[242354324]=28820,	[241355924]=27860,	[241354925]=27821,	[241355959]=27895,
	[241355960]=27896,	[241355953]=27889,	[241355909]=27845,	[241355927]=27863,	[241355936]=27872,	[241355962]=27898,	[241355926]=27862,
	[241355947]=27883,	[241355950]=27886,	[241354929]=27825,	[241355951]=27887,	[241355923]=27859,	[241355966]=27902,	[241303705]=24601,
	[241303733]=24629,	[241303718]=24614,	[241303707]=24603,	[241303695]=24591,	[241303693]=24589,	[238194840]=14616,	[241303721]=24617,
	[241303723]=24619,	[241303743]=24639,	[240302229]=23445,	[242394297]=31353,	[240302227]=23443,	[243448979]=35795,	[243448980]=35796,
	[243448982]=35798,	[243448984]=35800,	[241311934]=25150,	[243448985]=35801,	[241311933]=25149,	[244452499]=37075,	[243434665]=34921,
	[242390150]=31046,	[242390158]=31054,	[242390153]=31049,	[242390151]=31047,	[243448987]=35803,	[243448988]=35804,	[243448991]=35807,
	[243448992]=35808,	[243448995]=35811,	[243448996]=35812,	[243448999]=35815,	[243449000]=35816,	[243449001]=35817,	[241311893]=25109,
	[240301218]=23394,	[239265951]=20127,	[244475028]=38484,	[240294066]=22962,	[240294063]=22959,	[240295063]=22999,	[240312465]=24081,
	[240316585]=24361,	[240301221]=23397,	[244491453]=39549,	[243426481]=34417,	[243465382]=36838,	[243465384]=36840,	[242412672]=32448,
	[242412673]=32449,	[242412674]=32450,	[244491447]=39543,	[244491448]=39544,	[242412681]=32457,	[242412684]=32460,	[244491455]=39551,
	[244492416]=39552,	[242372798]=30014,	[242367631]=29647,	[242367632]=29648,	[242367618]=29634,	[242367633]=29649,	[242366643]=29619,
	[242367616]=29632,	[244483256]=39032,	[242367625]=29641,	[242367624]=29640,	[241314990]=25326,	[240285869]=22445,	[241315997]=25373,
	[240285859]=22435,	[241315998]=25374,	[240285860]=22436,	[243455155]=36211,	[243454130]=36146,	[240285873]=22449,	[240285836]=22412,
	[244452509]=37085,	[240285863]=22439,	[240285843]=22419,	[241316006]=25382,	[240285856]=22432,	[243413148]=33564,	[243414170]=33626,
	[243414161]=33617,	[243454131]=36147,	[243414172]=33628,	[243415186]=33682,	[243413180]=33596,	[243413172]=33588,	[243413169]=33585,
	[243415195]=33691,	[243414174]=33630,	[243413167]=33583,	[243414159]=33615,	[243414151]=33607,	[243414147]=33603,	[243414175]=33631,
	[243414144]=33600,	[243413143]=33559,	[243414176]=33632,	[243413165]=33581,	[243413160]=33576,	[240285865]=22441,	[243414181]=33637,
	[243414182]=33638,	[243414184]=33640,	[243414185]=33641,	[240264331]=21067,	[243414186]=33642,	[243413177]=33593,	[243414188]=33644,
	[243414190]=33646,	[241335472]=26608,	[241336457]=26633,	[241335471]=26607,	[241335448]=26584,	[241336458]=26634,	[241335465]=26601,
	[241334448]=26544,	[241336460]=26636,	[241335449]=26585,	[241334453]=26549,	[241335450]=26586,	[241334451]=26547,	[241335454]=26590,
	[241335453]=26589,	[241336448]=26624,	[241335458]=26594,	[241336462]=26638,	[241334456]=26552,	[241335432]=26568,	[241335425]=26561,
	[241334455]=26551,	[241335485]=26621,	[240264332]=21068,	[244454538]=37194,	[244452518]=37094,	[242372781]=29997,	[242385047]=30743,
	[242385048]=30744,	[242385042]=30738,	[241326251]=26027,	[242385069]=30765,	[242385052]=30748,	[240293006]=22862,	[243400887]=32823,
	[243426490]=34426,	[241350786]=27522,	[241350791]=27527,	[241350788]=27524,	[241350790]=27526,	[243463345]=36721,	[243463346]=36722,
	[243463347]=36723,	[243463350]=36726,	[243463352]=36728,	[243426495]=34431,	[241351830]=27606,	[243440775]=35271,	[240304284]=23580,
	[240274576]=21712,	[242380932]=30468,	[242380941]=30477,	[167955600]=134352,	[244452514]=37090,	[242380935]=30471,	[242380938]=30474,
	[242380936]=30472,	[242391226]=31162,	[240274562]=21698,	[240273588]=21684,	[241331383]=26359,	[241328308]=26164,	[241328305]=26161,
	[241328309]=26165,	[240273574]=21670,	[240274579]=21715,	[240274580]=21716,	[242373774]=30030,	[241351831]=27607,	[240272562]=21618,
	[243403908]=32964,	[242373771]=30027,	[242373768]=30024,	[243426492]=34428,	[243426491]=34427,	[242379909]=30405,	[240273571]=21667,
	[240274581]=21717,	[240264336]=21072,	[244452519]=37095,	[240273595]=21691,	[240282815]=22271,	[240273599]=21695,	[240274572]=21708,
	[240274585]=21721,	[240274586]=21722,	[240273583]=21679,	[240273577]=21673,	[240273572]=21668,	[240274589]=21725,	[240274575]=21711,
	[240274590]=21726,	[240307353]=23769,	[240307363]=23779,	[242414744]=32600,	[240312487]=24103,	[240307346]=23762,	[240307364]=23780,
	[240307339]=23755,	[240307365]=23781,	[243454134]=36150,	[244467866]=38042,	[244467867]=38043,	[244467873]=38049,	[244467875]=38051,
	[244467876]=38052,	[244467880]=38056,	[244467883]=38059,	[244467887]=38063,	[241352865]=27681,	[241352863]=27679,	[242361519]=29295,
	[244452508]=37084,	[242392213]=31189,	[242392237]=31213,	[242396349]=31485,	[242397320]=31496,	[242397315]=31491,	[239271078]=20454,
	[239271080]=20456,	[239271045]=20421,	[239271082]=20458,	[240270495]=21471,	[240285857]=22433,	[242361518]=29294,	[239271075]=20451,
	[239271066]=20442,	[242378888]=30344,	[239271057]=20433,	[239271071]=20447,	[244449413]=36869,	[240318599]=24455,	[240318601]=24457,
	[243409058]=33314,	[239271070]=20446,	[244452503]=37079,	[239271054]=20430,	[244452516]=37092,	[242360496]=29232,	[244452507]=37083,
	[242371764]=29940,	[243403944]=33000,	[243403946]=33002,	[243403931]=32987,	[243403906]=32962,	[243403929]=32985,	[243403917]=32973,
	[243403927]=32983,	[243403933]=32989,	[241332368]=26384,	[243403947]=33003,	[244506792]=40488,	[240267405]=21261,	[242363560]=29416,
	[242363567]=29423,	[244485265]=39121,	[242363561]=29417,	[242363570]=29426,	[243441799]=35335,	[244449412]=36868,	[241328285]=26141,
	[244487351]=39287,	[244487352]=39288,	[244487353]=39289,	[243403940]=32996,	[240301226]=23402,	[240296072]=23048,	[240316552]=24328,
	[240293013]=22869,	[240314533]=24229,	[242374828]=30124,	[242374819]=30115,	[242374821]=30117,	[242374829]=30125,	[240314528]=24224,
	[242396305]=31441,	[240317606]=24422,	[244485266]=39122,	[244473020]=38396,	[244473022]=38398,	[244473023]=38399,	[244473986]=38402,
	[242415761]=32657,	[243465400]=36856,	[242402492]=31868,	[244454539]=37195,	[242354355]=28851,	[242354363]=28859,	[242354365]=28861,
	[242354351]=28847,	[242355328]=28864,	[242354359]=28855,	[242355331]=28867,	[241356977]=27953,	[241356985]=27961,	[241356967]=27943,
	[241356940]=27916,	[241357955]=27971,	[241356935]=27911,	[241356932]=27908,	[241356953]=27929,	[241358990]=28046,	[241356942]=27918,
	[241356971]=27947,	[241357965]=27981,	[241356974]=27950,	[241356981]=27957,	[241357970]=27986,	[241357972]=27988,	[241357973]=27989,
	[241356979]=27955,	[241304760]=24696,	[241304723]=24659,	[241304761]=24697,	[241304747]=24683,	[241304762]=24698,	[241304763]=24699,
	[241304706]=24642,	[241304746]=24682,	[241304765]=24701,	[240302245]=23461,	[241312899]=25155,	[243434674]=34930,	[243434685]=34941,
	[243434687]=34943,	[243435650]=34946,	[242390171]=31067,	[242390172]=31068,	[242390163]=31059,	[242390170]=31066,	[243449006]=35822,
	[242390167]=31063,	[242390178]=31074,	[243449008]=35824,	[243449011]=35827,	[244506793]=40489,	[241328310]=26166,	[244452513]=37089,
	[240273579]=21675,	[240316589]=24365,	[242361473]=29249,	[243403941]=32997,	[244475035]=38491,	[244475039]=38495,	[240296069]=23045,
	[240295086]=23022,	[240296070]=23046,	[240295069]=23005,	[240295075]=23011,	[240295064]=23000,	[240295097]=23033,	[241303740]=24636,
	[242415807]=32703,	[242354353]=28849,	[242384028]=30684,	[242412692]=32468,	[244492417]=39553,	[244492421]=39557,	[242412695]=32471,
	[242412699]=32475,	[244492424]=39560,	[243400854]=32790,	[241315976]=25352,	[242367653]=29669,	[242367641]=29657,	[244483260]=39036,
	[242367664]=29680,	[242367657]=29673,	[242367655]=29671,	[242367651]=29667,	[242367646]=29662,	[242368676]=29732,	[242367666]=29682,
	[241325206]=25942,	[241304730]=24666,	[240286868]=22484,	[240286869]=22485,	[240286872]=22488,	[240286873]=22489,	[240286874]=22490,
	[241316025]=25401,	[243400838]=32774,	[243400836]=32772,	[240286866]=22482,	[241317003]=25419,	[243454141]=36157,	[240285880]=22456,
	[241316995]=25411,	[242379917]=30413,	[243414200]=33656,	[243415174]=33670,	[243415219]=33715,	[243415220]=33716,	[243415210]=33706,
	[243415200]=33696,	[243415187]=33683,	[243415196]=33692,	[243415173]=33669,	[243414204]=33660,	[243415209]=33705,	[243414205]=33661,
	[243415224]=33720,	[243414203]=33659,	[243415192]=33688,	[243415182]=33678,	[243415198]=33694,	[243415208]=33704,	[244506794]=40490,
	[243415228]=33724,	[241336498]=26674,	[241336499]=26675,	[244452532]=37108,	[241337491]=26707,	[241337505]=26721,	[241337486]=26702,
	[241337506]=26722,	[241337508]=26724,	[241338499]=26755,	[241336477]=26653,	[241337493]=26709,	[241337473]=26689,	[241337511]=26727,
	[241337477]=26693,	[241336479]=26655,	[241337481]=26697,	[241336489]=26665,	[244449425]=36881,	[244449419]=36875,	[240317607]=24423,
	[244494514]=39730,	[243451015]=35911,	[244454544]=37200,	[244449446]=36902,	[240269469]=21405,	[240301228]=23404,	[242385053]=30749,
	[242385081]=30777,	[242385082]=30778,	[242385063]=30759,	[242385079]=30775,	[242385055]=30751,	[242385084]=30780,	[242385061]=30757,
	[242385059]=30755,	[240264350]=21086,	[242385083]=30779,	[243463356]=36732,	[243463358]=36734,	[243464322]=36738,	[244506795]=40491,
	[243456184]=36280,	[244512896]=40832,	[244506796]=40492,	[243426452]=34388,	[244449421]=36877,	[242380972]=30508,	[240275611]=21787,
	[241329311]=26207,	[242380969]=30505,	[242380953]=30489,	[240274599]=21735,	[240274621]=21757,	[240275604]=21780,	[241329281]=26177,
	[241329295]=26191,	[244506798]=40494,	[243456181]=36277,	[243456191]=36287,	[242373787]=30043,	[243427496]=34472,	[243427484]=34460,
	[243427469]=34445,	[243427467]=34443,	[243427500]=34476,	[243427485]=34461,	[243427495]=34471,	[240275618]=21794,	[240283780]=22276,
	[240275619]=21795,	[240275599]=21775,	[242379918]=30414,	[240275601]=21777,	[240308354]=23810,	[240308355]=23811,	[242414753]=32609,
	[242414751]=32607,	[240307370]=23786,	[243440778]=35274,	[243455109]=36165,	[244467888]=38064,	[244467890]=38066,	[244467892]=38068,
	[244467893]=38069,	[244467897]=38073,	[244467898]=38074,	[244467901]=38077,	[244467900]=38076,	[244467903]=38079,	[244468864]=38080,
	[244468866]=38082,	[244468868]=38084,	[244468870]=38086,	[244468872]=38088,	[244468873]=38089,	[244468874]=38090,	[244468875]=38091,
	[244468876]=38092,	[244468877]=38093,	[239244477]=18813,	[244468878]=38094,	[241352873]=27689,	[241352868]=27684,	[241352870]=27686,
	[241351850]=27626,	[243409040]=33296,	[242392227]=31203,	[242392235]=31211,	[242379913]=30409,	[242397316]=31492,	[242397333]=31509,
	[242397322]=31498,	[242397327]=31503,	[242397318]=31494,	[239271096]=20472,	[240255145]=20521,	[239271093]=20469,	[240256140]=20556,
	[239271091]=20467,	[239271094]=20470,	[240255148]=20524,	[240255119]=20495,	[241304705]=24641,	[240255149]=20525,	[240255146]=20522,
	[239271102]=20478,	[240255132]=20508,	[244476092]=38588,	[244476093]=38589,	[240255116]=20492,	[240255141]=20517,	[243408044]=33260,
	[242378891]=30347,	[244452523]=37099,	[240255144]=20520,	[243434628]=34884,	[244484224]=39040,	[240318613]=24469,	[243409067]=33323,
	[244456604]=37340,	[240293018]=22874,	[243434686]=34942,	[243403951]=33007,	[243403953]=33009,	[243403956]=33012,	[243403949]=33005,
	[243404941]=33037,	[243403964]=33020,	[241332373]=26389,	[243404946]=33042,	[243403962]=33018,	[244506801]=40497,	[242366650]=29626,
	[244506802]=40498,	[242363575]=29431,	[242364545]=29441,	[242363571]=29427,	[242364547]=29443,	[242363578]=29434,	[244449430]=36886,
	[241337472]=26688,	[243435653]=34949,	[244487357]=39293,	[240262279]=20935,	[241336510]=26686,	[241315995]=25371,	[239265971]=20147,
	[242374835]=30131,	[242374836]=30132,	[242374840]=30136,	[242374845]=30141,	[242375816]=30152,	[242374833]=30129,	[242375810]=30146,
	[242375817]=30153,	[243434670]=34926,	[240262283]=20939,	[244484227]=39043,	[241304739]=24675,	[241327238]=26054,	[241327236]=26052,
	[241327235]=26051,	[244473987]=38403,	[244473988]=38404,	[243441818]=35354,	[244473990]=38406,	[241304729]=24665,	[242403473]=31889,
	[241332372]=26388,	[244452536]=37112,	[242355356]=28892,	[242355368]=28904,	[242355369]=28905,	[242355338]=28874,	[240264353]=21089,
	[244452527]=37103,	[242355372]=28908,	[241358993]=28049,	[241357999]=28015,	[241359006]=28062,	[241359007]=28063,	[240296081]=23057,
	[241358981]=28037,	[241359008]=28064,	[241357982]=27998,	[241358995]=28051,	[241357989]=28005,	[241358996]=28052,	[241357980]=27996,
	[241357984]=28000,	[241357987]=28003,	[241357978]=27994,	[241305754]=24730,	[241305773]=24749,	[241305757]=24733,	[241305746]=24722,
	[241305740]=24716,	[241305755]=24731,	[240302264]=23480,	[242395272]=31368,	[240264348]=21084,	[243449017]=35833,	[240261282]=20898,
	[243449020]=35836,	[243435666]=34962,	[243435682]=34978,	[242390191]=31087,	[243449023]=35839,	[243449984]=35840,	[243449986]=35842,
	[243449988]=35844,	[243449991]=35847,	[240305296]=23632,	[240305305]=23641,	[244475052]=38508,	[240266384]=21200,	[240293016]=22872,
	[242361474]=29250,	[243427497]=34473,	[244475058]=38514,	[240295084]=23020,	[240296096]=23072,	[240296076]=23052,	[240296073]=23049,
	[240296114]=23090,	[240296105]=23081,	[240296116]=23092,	[240296099]=23075,	[240296083]=23059,	[240297088]=23104,	[242373786]=30042,
	[244449441]=36897,	[242412704]=32480,	[244492426]=39562,	[242412705]=32481,	[244492427]=39563,	[242412709]=32485,	[242412710]=32486,
	[242412712]=32488,	[244492430]=39566,	[244451477]=37013,	[244506806]=40502,	[240317591]=24407,	[243400860]=32796,	[242356376]=28952,
	[243409026]=33282,	[242368655]=29711,	[242368647]=29703,	[244508856]=40632,	[241319094]=25590,	[240286900]=22516,	[240286895]=22511,
	[241317039]=25455,	[241318067]=25523,	[241318068]=25524,	[240286904]=22520,	[240286901]=22517,	[243455143]=36199,	[240286884]=22500,
	[241317037]=25453,	[244449461]=36917,	[240286877]=22493,	[240287883]=22539,	[240287885]=22541,	[241318060]=25516,	[244506807]=40503,
	[241318038]=25494,	[241317053]=25469,	[241318026]=25482,	[240287881]=22537,	[241318072]=25528,	[241317033]=25449,	[241318062]=25518,
	[241305771]=24747,	[240286893]=22509,	[240286909]=22525,	[241318023]=25479,	[241318076]=25532,	[243401859]=32835,	[243416193]=33729,
	[243417217]=33793,	[243416216]=33752,	[240287879]=22535,	[243417240]=33816,	[243417227]=33803,	[243416253]=33789,	[243416214]=33750,
	[243417244]=33820,	[243417272]=33848,	[243417233]=33809,	[241339579]=26875,	[243416212]=33748,	[243416223]=33759,	[243417231]=33807,
	[243417219]=33795,	[243416207]=33743,	[243416249]=33785,	[243416234]=33770,	[243416197]=33733,	[243416192]=33728,	[243417254]=33830,
	[243416240]=33776,	[243416225]=33761,	[241338549]=26805,	[241338559]=26815,	[241338511]=26767,	[243440779]=35275,	[241337524]=26740,
	[241337527]=26743,	[241338515]=26771,	[241339521]=26817,	[241337515]=26731,	[241339522]=26818,	[240276652]=21868,	[244452542]=37118,
	[240267438]=21294,	[241325205]=25941,	[243451017]=35913,	[244453508]=37124,	[244454558]=37214,	[244454554]=37210,	[241311899]=25115,
	[242386062]=30798,	[242386093]=30829,	[242386066]=30802,	[242386070]=30806,	[242386071]=30807,	[242386064]=30800,	[242386055]=30791,
	[242386060]=30796,	[244506808]=40504,	[242371744]=29920,	[240267407]=21263,	[240269481]=21417,	[244512922]=40858,	[241350802]=27538,
	[241350803]=27539,	[241350797]=27533,	[243455113]=36169,	[244477097]=38633,	[243464324]=36740,	[240287889]=22545,	[242380973]=30509,
	[242380966]=30502,	[240276647]=21863,	[241329313]=26209,	[241329316]=26212,	[242380986]=30522,	[242380981]=30517,	[242380984]=30520,
	[240283786]=22282,	[240277647]=21903,	[240277685]=21941,	[240276617]=21833,	[240266390]=21206,	[241329310]=26206,	[240275637]=21813,
	[241329303]=26199,	[240261269]=20885,	[240276653]=21869,	[242373798]=30054,	[243456186]=36282,	[240276654]=21870,	[243457156]=36292,
	[243427510]=34486,	[243428484]=34500,	[243428494]=34510,	[243428486]=34502,	[243427504]=34480,	[243428490]=34506,	[240283785]=22281,
	[243427505]=34481,	[243428489]=34505,	[243428495]=34511,	[243427508]=34484,	[240276609]=21825,	[240276629]=21845,	[240275647]=21823,
	[240276624]=21840,	[240275644]=21820,	[240275639]=21815,	[240276630]=21846,	[240276661]=21877,	[240276662]=21878,	[240276663]=21879,
	[240275635]=21811,	[240275632]=21808,	[240276636]=21852,	[240312507]=24123,	[240308378]=23834,	[240308390]=23846,	[240312508]=24124,
	[240308398]=23854,	[240308388]=23844,	[240308358]=23814,	[243455111]=36167,	[243455112]=36168,	[243455114]=36170,	[244468881]=38097,
	[244468882]=38098,	[244468887]=38103,	[244468889]=38105,	[244468895]=38111,	[244468896]=38112,	[244468897]=38113,	[244468898]=38114,
	[244468899]=38115,	[244468900]=38116,	[244468903]=38119,	[244468904]=38120,	[244468905]=38121,	[244468906]=38122,	[244468907]=38123,
	[244468908]=38124,	[244468910]=38126,	[244468911]=38127,	[244468912]=38128,	[244468913]=38129,	[244468915]=38131,	[244468917]=38133,
	[244468919]=38135,	[241352874]=27690,	[242361534]=29310,	[244506809]=40505,	[242392254]=31230,	[244449462]=36918,	[242397370]=31546,
	[242398343]=31559,	[242397368]=31544,	[242397354]=31530,	[242397358]=31534,	[242397344]=31520,	[242397349]=31525,	[242397348]=31524,
	[242397363]=31539,	[242397374]=31550,	[242397342]=31518,	[240256190]=20606,	[240256131]=20547,	[240256149]=20565,	[240256136]=20552,
	[240257152]=20608,	[240256172]=20588,	[240256187]=20603,	[242378897]=30353,	[242378894]=30350,	[244506811]=40507,	[240318620]=24476,
	[243409080]=33336,	[243409083]=33339,	[243409076]=33332,	[243409079]=33335,	[244512923]=40859,	[242416782]=32718,	[243404972]=33068,
	[243404952]=33048,	[243404978]=33074,	[240267408]=21264,	[242364567]=29463,	[242364577]=29473,	[242364574]=29470,	[242364573]=29469,
	[241326235]=26011,	[242364565]=29461,	[244488343]=39319,	[244488323]=39299,	[244488324]=39300,	[244506814]=40510,	[240301232]=23408,
	[240314553]=24249,	[240314558]=24254,	[242375828]=30164,	[242375821]=30157,	[242374837]=30133,	[242416778]=32714,	[241327244]=26060,
	[241327246]=26062,	[243435684]=34980,	[244473991]=38407,	[244473992]=38408,	[244473993]=38409,	[244473994]=38410,	[244473995]=38411,
	[244473997]=38413,	[244473999]=38415,	[242415775]=32671,	[242403485]=31901,	[242403477]=31893,	[241325213]=25949,	[242356368]=28944,
	[242355375]=28911,	[242356371]=28947,	[242355389]=28925,	[242356374]=28950,	[242355383]=28919,	[242356375]=28951,	[241361037]=28173,
	[241361050]=28186,	[241360007]=28103,	[241360005]=28101,	[241360030]=28126,	[241361038]=28174,	[241359039]=28095,	[241360022]=28118,
	[241316018]=25394,	[241360032]=28128,	[241359032]=28088,	[241361041]=28177,	[241360038]=28134,	[241360029]=28125,	[241360044]=28140,
	[241359018]=28074,	[241360025]=28121,	[241359019]=28075,	[241361036]=28172,	[241360004]=28100,	[241306796]=24812,	[241305787]=24763,
	[241305777]=24753,	[241306781]=24797,	[241306776]=24792,	[241305784]=24760,	[241306758]=24774,	[241306778]=24794,	[241306759]=24775,
	[241306798]=24814,	[242395285]=31381,	[243449996]=35852,	[243449999]=35855,	[241312904]=25160,	[242378930]=30386,	[243450001]=35857,
	[243436678]=35014,	[243435703]=34999,	[243436681]=35017,	[243450002]=35858,	[243450004]=35860,	[243450005]=35861,	[243450006]=35862,
	[243450007]=35863,	[243450009]=35865,	[243450011]=35867,	[243450013]=35869,	[244449455]=36911,	[244452543]=37119,	[244476040]=38536,
	[242403484]=31900,	[244476045]=38541,	[244476055]=38551,	[240297127]=23143,	[240297098]=23114,	[240297109]=23125,	[240296124]=23100,
	[240297122]=23138,	[240297141]=23157,	[243403948]=33004,	[243435656]=34952,	[242416780]=32716,	[241304767]=24703,	[241348792]=27448,
	[242412715]=32491,	[244492432]=39568,	[242412718]=32494,	[242412719]=32495,	[242412721]=32497,	[244492434]=39570,	[242412722]=32498,
	[244492435]=39571,	[242412726]=32502,	[242412730]=32506,	[242412731]=32507,	[242412734]=32510,	[244492438]=39574,	[242413697]=32513,
	[243400864]=32800,	[242368683]=29739,	[242368693]=29749,	[242368694]=29750,	[242368682]=29738,	[242369691]=29787,	[242368678]=29734,
	[242368677]=29733,	[242368680]=29736,	[244479123]=38739,	[242368688]=29744,	[242368686]=29742,	[242368687]=29743,	[242368684]=29740,
	[242368667]=29723,	[242368666]=29722,	[243464327]=36743,	[244510859]=40715,	[241319091]=25587,	[240287902]=22558,	[241320125]=25661,
	[241319096]=25592,	[241319072]=25568,	[240287897]=22553,	[243456132]=36228,	[241319062]=25558,	[244484233]=39049,	[240288900]=22596,
	[241319103]=25599,	[243400843]=32779,	[241319044]=25540,	[243428521]=34537,	[243428528]=34544,	[240288902]=22598,	[241321106]=25682,
	[241319046]=25542,	[241318078]=25534,	[243401874]=32850,	[243418257]=33873,	[243418266]=33882,	[244479152]=38768,	[244479160]=38776,
	[243418291]=33907,	[243418298]=33914,	[243418296]=33912,	[243417276]=33852,	[243418246]=33862,	[243418281]=33897,	[243418294]=33910,
	[243419276]=33932,	[243417265]=33841,	[241311903]=25119,	[243418285]=33901,	[241341614]=26990,	[241339580]=26876,	[241340575]=26911,
	[241339577]=26873,	[241340580]=26916,	[241339568]=26864,	[243455117]=36173,	[241340555]=26891,	[241340545]=26881,	[241340586]=26922,
	[241339555]=26851,	[241340560]=26896,	[244507777]=40513,	[243439747]=35203,	[244454564]=37220,	[244454562]=37218,	[244454561]=37217,
	[244507778]=40514,	[240269477]=21413,	[241350810]=27546,	[241350811]=27547,	[244477103]=38639,	[244477105]=38641,	[243464330]=36746,
	[243464331]=36747,	[241340576]=26912,	[243464333]=36749,	[243464334]=36750,	[241326224]=26000,	[242381956]=30532,	[242381969]=30545,
	[242381959]=30535,	[242381955]=30531,	[241311906]=25122,	[240277643]=21899,	[240278674]=21970,	[240277635]=21891,	[240277681]=21937,
	[240277689]=21945,	[241329335]=26231,	[240277640]=21896,	[243457174]=36310,	[243457175]=36311,	[243457182]=36318,	[243457178]=36314,
	[243457166]=36302,	[243457167]=36303,	[243457158]=36294,	[243428529]=34545,	[243428530]=34546,	[243428525]=34541,	[243428531]=34547,
	[243428496]=34512,	[243428500]=34516,	[243428510]=34526,	[243428532]=34548,	[243428511]=34527,	[243428504]=34520,	[240277633]=21889,
	[240277663]=21919,	[240276670]=21886,	[240278678]=21974,	[240277649]=21905,	[240278687]=21983,	[240277693]=21949,	[240278686]=21982,
	[240277632]=21888,	[240277652]=21908,	[240277657]=21913,	[240309400]=23896,	[240309398]=23894,	[240308404]=23860,	[244450436]=36932,
	[243442824]=35400,	[240309390]=23886,	[240308413]=23869,	[240309420]=23916,	[240309403]=23899,	[240309423]=23919,	[240309405]=23901,
	[240309419]=23915,	[240313476]=24132,	[240309387]=23883,	[243455125]=36181,	[244468923]=38139,	[244468924]=38140,	[244468927]=38143,
	[244469891]=38147,	[244469890]=38146,	[244469894]=38150,	[244469895]=38151,	[244469897]=38153,	[244469903]=38159,	[244469905]=38161,
	[244469906]=38162,	[244469908]=38164,	[244469909]=38165,	[241318051]=25507,	[242384044]=30700,	[241352880]=27696,	[241351859]=27635,
	[241351869]=27645,	[242362506]=29322,	[242362500]=29316,	[242362507]=29323,	[244507780]=40516,	[242362509]=29325,	[240309383]=23879,
	[244509837]=40653,	[242393219]=31235,	[242393218]=31234,	[242398362]=31578,	[242398389]=31605,	[242398348]=31564,	[240257187]=20643,
	[240257160]=20616,	[243409028]=33284,	[242361485]=29261,	[240257189]=20645,	[240257191]=20647,	[244450449]=36945,	[240257193]=20649,
	[244450433]=36929,	[240318632]=24488,	[240298157]=23213,	[242373810]=30066,	[240316561]=24337,	[244484236]=39052,	[242416789]=32725,
	[244456585]=37321,	[244507782]=40518,	[243409052]=33308,	[243452034]=35970,	[243405960]=33096,	[243405964]=33100,	[243405971]=33107,
	[243405958]=33094,	[243406004]=33140,	[243405969]=33105,	[243405978]=33114,	[243406001]=33137,	[244499647]=40063,	[244500608]=40064,
	[244500610]=40066,	[244484237]=39053,	[242364578]=29474,	[242364601]=29497,	[242364581]=29477,	[244485267]=39123,	[243440798]=35294,
	[243440794]=35290,	[242364593]=29489,	[244484238]=39054,	[244485287]=39143,	[244488327]=39303,	[244488330]=39306,	[239265973]=20149,
	[243404948]=33044,	[243436690]=35026,	[242375843]=30179,	[242375848]=30184,	[242375846]=30182,	[242375838]=30174,	[242375844]=30180,
	[242375851]=30187,	[242375847]=30183,	[243455123]=36179,	[242396326]=31462,	[242371775]=29951,	[240276667]=21883,	[244484239]=39055,
	[244507783]=40519,	[244474001]=38417,	[244474002]=38418,	[244474005]=38421,	[242403486]=31902,	[244450450]=36946,	[240301235]=23411,
	[242356399]=28975,	[242356380]=28956,	[242356377]=28953,	[242356401]=28977,	[244507784]=40520,	[241362075]=28251,	[241361067]=28203,
	[241362094]=28270,	[241362062]=28238,	[241362076]=28252,	[241361069]=28205,	[241362061]=28237,	[241362091]=28267,	[241363122]=28338,
	[241362079]=28255,	[241363078]=28294,	[241362098]=28274,	[241362068]=28244,	[241362057]=28233,	[241361061]=28197,	[241362052]=28228,
	[241364097]=28353,	[241307808]=24864,	[241306810]=24826,	[241307814]=24870,	[241306804]=24820,	[241307776]=24832,	[241307790]=24846,
	[241307796]=24852,	[240277694]=21950,	[240303248]=23504,	[243450015]=35871,	[241312905]=25161,	[243436706]=35042,	[243436686]=35022,
	[243436709]=35045,	[242390206]=31102,	[242390202]=31098,	[243450016]=35872,	[240313474]=24130,	[243450017]=35873,	[243450021]=35877,
	[243450023]=35879,	[244450448]=36944,	[240301233]=23409,	[240316604]=24380,	[240311485]=24061,	[244492440]=39576,	[240298154]=23210,
	[240298139]=23195,	[240297143]=23159,	[240311471]=24047,	[242416794]=32730,	[242378932]=30388,	[240297146]=23162,	[244492443]=39579,
	[242413698]=32514,	[242413699]=32515,	[242413700]=32516,	[240317592]=24408,	[242413703]=32519,	[242413704]=32520,	[242413708]=32524,
	[242413713]=32529,	[242413714]=32530,	[242413719]=32535,	[244485288]=39144,	[243400866]=32802,	[242369690]=29786,	[242369665]=29761,
	[242369692]=29788,	[242369687]=29783,	[242369668]=29764,	[242369685]=29781,	[244450472]=36968,	[244492444]=39580,	[244481195]=38891,
	[244493473]=39649,	[240288940]=22636,	[244453538]=37154,	[243456148]=36244,	[243456145]=36241,	[241321093]=25669,	[241321089]=25665,
	[243429511]=34567,	[241320075]=25611,	[241320106]=25642,	[241320080]=25616,	[241320091]=25627,	[241320096]=25632,	[241321096]=25672,
	[240317568]=24384,	[241351810]=27586,	[241320102]=25638,	[241320097]=25633,	[243420289]=33985,	[241311905]=25121,	[243420301]=33997,
	[244453534]=37150,	[244479155]=38771,	[243420304]=34000,	[243420326]=34022,	[244507787]=40523,	[243419325]=33981,	[243420307]=34003,
	[243420310]=34006,	[243420298]=33994,	[243419311]=33967,	[243420319]=34015,	[243420305]=34001,	[243419327]=33983,	[243419322]=33978,
	[243420320]=34016,	[243419295]=33951,	[243419297]=33953,	[243419321]=33977,	[243419316]=33972,	[243419287]=33943,	[243420325]=34021,
	[244484240]=39056,	[241341588]=26964,	[241341600]=26976,	[241341570]=26946,	[241341597]=26973,	[241341611]=26987,	[241341624]=27000,
	[241340596]=26932,	[241343628]=27084,	[241341615]=26991,	[242378905]=30361,	[241342600]=27016,	[241343630]=27086,	[241342601]=27017,
	[241341606]=26982,	[241341603]=26979,	[241341625]=27001,	[241340605]=26941,	[243436696]=35032,	[240264381]=21117,	[242372740]=29956,
	[244454574]=37230,	[244454576]=37232,	[244454575]=37231,	[244454569]=37225,	[243429507]=34563,	[242387099]=30875,	[242387091]=30867,
	[242386108]=30844,	[242387081]=30857,	[242387098]=30874,	[242387079]=30855,	[242387100]=30876,	[244507788]=40524,	[243464335]=36751,
	[244512899]=40835,	[244512901]=40837,	[243441854]=35390,	[242403506]=31922,	[243426462]=34398,	[242381978]=30554,	[240278698]=21994,
	[244481194]=38890,	[240278711]=22007,	[240278665]=21961,	[242381992]=30568,	[242381986]=30562,	[244477070]=38606,	[242381989]=30565,
	[240279711]=22047,	[240278673]=21969,	[240278699]=21995,	[240278700]=21996,	[240278676]=21972,	[240278685]=21981,	[241311909]=25125,
	[240278660]=21956,	[242357414]=29030,	[241330308]=26244,	[244450466]=36962,	[241330316]=26252,	[243457196]=36332,	[243457206]=36342,
	[243457208]=36344,	[243457168]=36304,	[243457187]=36323,	[243457209]=36345,	[243457211]=36347,	[243428536]=34552,	[243429514]=34570,
	[243429517]=34573,	[243429513]=34569,	[243429539]=34595,	[242373817]=30073,	[243428537]=34553,	[240278691]=21987,	[240278703]=21999,
	[240278693]=21989,	[240278706]=22002,	[240278707]=22003,	[240278668]=21964,	[240278669]=21965,	[240278696]=21992,	[240278672]=21968,
	[240278692]=21988,	[240278709]=22005,	[242414760]=32616,	[240309386]=23882,	[240309417]=23913,	[240309428]=23924,	[244492464]=39600,
	[244469911]=38167,	[244469915]=38171,	[244469916]=38172,	[244469917]=38173,	[244469918]=38174,	[244469919]=38175,	[244469922]=38178,
	[244469928]=38184,	[244469929]=38185,	[244469933]=38189,	[244469937]=38193,	[244477065]=38601,	[241352882]=27698,	[242362511]=29327,
	[241349763]=27459,	[242393246]=31262,	[242393239]=31255,	[242393236]=31252,	[242398368]=31584,	[242398370]=31586,	[242398382]=31598,
	[242398386]=31602,	[242398385]=31601,	[242361490]=29266,	[242357426]=29042,	[241325227]=25963,	[240318637]=24493,	[241307782]=24838,
	[243410052]=33348,	[243440782]=35278,	[241351865]=27641,	[243452042]=35978,	[243452037]=35973,	[243452041]=35977,	[244484244]=39060,
	[243405984]=33120,	[243405993]=33129,	[243406012]=33148,	[243405997]=33133,	[243405991]=33127,	[240288909]=22605,	[240298165]=23221,
	[243442873]=35449,	[244500613]=40069,	[244500614]=40070,	[244500615]=40071,	[244500616]=40072,	[242393251]=31267,	[244500619]=40075,
	[244500624]=40080,	[243402884]=32900,	[244507792]=40528,	[244485269]=39125,	[243440805]=35301,	[244450459]=36955,	[244488336]=39312,
	[244507793]=40529,	[239265974]=20150,	[242376835]=30211,	[242375857]=30193,	[242375868]=30204,	[242375871]=30207,	[242376848]=30224,
	[242376833]=30209,	[242376838]=30214,	[244508802]=40578,	[243436692]=35028,	[241349766]=27462,	[241327250]=26066,	[244477069]=38605,
	[244474006]=38422,	[244474007]=38423,	[244474009]=38425,	[242415783]=32679,	[243451042]=35938,	[242403507]=31923,	[242364599]=29495,
	[242357427]=29043,	[242357404]=29020,	[242357416]=29032,	[242357381]=28997,	[242357386]=29002,	[242357432]=29048,	[242357434]=29050,
	[241364127]=28383,	[241363121]=28337,	[241363096]=28312,	[241365165]=28461,	[241364130]=28386,	[241363109]=28325,	[241363111]=28327,
	[241363133]=28349,	[243436703]=35039,	[241363131]=28347,	[241363127]=28343,	[241364119]=28375,	[241364139]=28395,	[241363124]=28340,
	[241364111]=28367,	[241364099]=28355,	[241364134]=28390,	[241363087]=28303,	[241364098]=28354,	[241364115]=28371,	[241363103]=28319,
	[241364138]=28394,	[241307819]=24875,	[241308817]=24913,	[241308810]=24906,	[244500622]=40078,	[244492446]=39582,	[242395302]=31398,
	[242395296]=31392,	[242395299]=31395,	[243436721]=35057,	[243437722]=35098,	[243436712]=35048,	[243436734]=35070,	[243436720]=35056,
	[242391178]=31114,	[243450025]=35881,	[243450026]=35882,	[240298174]=23230,	[240299179]=23275,	[240298162]=23218,	[240299154]=23250,
	[240299156]=23252,	[240298168]=23224,	[242413721]=32537,	[242413724]=32540,	[242413723]=32539,	[243464340]=36756,	[244492445]=39581,
	[242413727]=32543,	[242413729]=32545,	[242413730]=32546,	[242413731]=32547,	[244492447]=39583,	[243400869]=32805,	[242370696]=29832,
	[242369718]=29814,	[242369709]=29805,	[242365586]=29522,	[243440783]=35279,	[241308829]=24925,	[240299168]=23264,	[244481196]=38892,
	[240270470]=21446,	[244493478]=39654,	[241321149]=25725,	[240289921]=22657,	[241322114]=25730,	[241321118]=25694,	[241322116]=25732,
	[242416805]=32741,	[243458181]=36357,	[241321133]=25709,	[240289929]=22665,	[240289938]=22674,	[241342614]=27030,	[242407590]=32166,
	[243421355]=34091,	[243421367]=34103,	[244479162]=38778,	[244479164]=38780,	[244480133]=38789,	[244479167]=38783,	[242372749]=29965,
	[243421368]=34104,	[243421343]=34079,	[243421370]=34106,	[241311916]=25132,	[243422358]=34134,	[243421371]=34107,	[243420351]=34047,
	[241326241]=26017,	[244507797]=40533,	[243420348]=34044,	[241342619]=27035,	[241342631]=27047,	[241342651]=27067,	[241342635]=27051,
	[241342637]=27053,	[241343636]=27092,	[241342641]=27057,	[241343617]=27073,	[241343647]=27103,	[241343648]=27104,	[241342647]=27063,
	[240258224]=20720,	[244454589]=37245,	[244454582]=37238,	[244454585]=37241,	[240269486]=21422,	[242387105]=30881,	[242387124]=30900,
	[242387107]=30883,	[242387122]=30898,	[242388107]=30923,	[243408039]=33255,	[243451048]=35944,	[241350817]=27553,	[244478086]=38662,
	[244478081]=38657,	[243464341]=36757,	[243429530]=34586,	[243436724]=35060,	[242416801]=32737,	[244512903]=40839,	[244512904]=40840,
	[242382015]=30591,	[239207574]=16470,	[242382013]=30589,	[240279710]=22046,	[240279688]=22024,	[240279692]=22028,	[240279681]=22017,
	[240279694]=22030,	[241330343]=26279,	[241330333]=26269,	[243458188]=36364,	[243458185]=36361,	[243429534]=34590,	[243429541]=34597,
	[243429550]=34606,	[243430536]=34632,	[243429556]=34612,	[243429553]=34609,	[243429545]=34601,	[243429559]=34615,	[243429567]=34623,
	[243431554]=34690,	[243429538]=34594,	[240279704]=22040,	[240279713]=22049,	[244507799]=40535,	[240279715]=22051,	[240279716]=22052,
	[240279706]=22042,	[240278718]=22014,	[240279719]=22055,	[242414772]=32628,	[242414769]=32625,	[240313492]=24148,	[240310402]=23938,
	[240313499]=24155,	[243455129]=36185,	[242414722]=32578,	[244492471]=39607,	[244492470]=39606,	[244507800]=40536,	[244469938]=38194,
	[244469940]=38196,	[244469942]=38198,	[244469943]=38199,	[244469944]=38200,	[244469941]=38197,	[244470913]=38209,	[244470914]=38210,
	[242362514]=29330,	[242399376]=31632,	[242399398]=31654,	[242399399]=31655,	[242399373]=31629,	[242399416]=31672,	[242399404]=31660,
	[242399365]=31621,	[242399402]=31658,	[242399380]=31636,	[242399388]=31644,	[242399394]=31650,	[242399379]=31635,	[241351827]=27603,
	[240258198]=20694,	[240259206]=20742,	[240258227]=20723,	[240258221]=20717,	[240265345]=21121,	[240258222]=20718,	[244495491]=39747,
	[244495494]=39750,	[242382014]=30590,	[243410059]=33355,	[244453553]=37169,	[243406984]=33160,	[243406993]=33169,	[244500625]=40081,
	[244500628]=40084,	[244500634]=40090,	[244500635]=40091,	[244500639]=40095,	[242365584]=29520,	[243440811]=35307,	[244477074]=38610,
	[240292004]=22820,	[244488337]=39313,	[244459694]=37550,	[240288958]=22654,	[244508861]=40637,	[242376844]=30220,	[242376842]=30218,
	[242376856]=30232,	[242376857]=30233,	[240315542]=24278,	[244481206]=38902,	[241327254]=26070,	[243406978]=33154,	[244474010]=38426,
	[244453551]=37167,	[244500638]=40094,	[242403519]=31935,	[242403516]=31932,	[242403517]=31933,	[242404481]=31937,	[241343626]=27082,
	[244507802]=40538,	[242358424]=29080,	[242358437]=29093,	[241366178]=28514,	[241365141]=28437,	[241364153]=28409,	[241365167]=28463,
	[241365174]=28470,	[241366155]=28491,	[241366196]=28532,	[241365162]=28458,	[241365129]=28425,	[241365171]=28467,	[241365161]=28457,
	[241367177]=28553,	[241366157]=28493,	[241308853]=24949,	[241320116]=25652,	[242395304]=31400,	[240303268]=23524,	[242407598]=32174,
	[243450030]=35886,	[243437729]=35105,	[243437721]=35097,	[243437715]=35091,	[243437723]=35099,	[243437706]=35082,	[243450031]=35887,
	[243450032]=35888,	[243450034]=35890,	[241330344]=26280,	[240305315]=23651,	[244507803]=40539,	[240299171]=23267,	[240299185]=23281,
	[240299158]=23254,	[240299174]=23270,	[240299162]=23258,	[240299160]=23256,	[240299169]=23265,	[244510864]=40720,	[242416799]=32735,
	[242382976]=30592,	[244507804]=40540,	[244492448]=39584,	[242413733]=32549,	[242413734]=32550,	[242413735]=32551,	[242413736]=32552,
	[244492450]=39586,	[242413738]=32554,	[242413739]=32555,	[243400870]=32806,	[243400871]=32807,	[242369726]=29822,	[242370716]=29852,
	[242370688]=29824,	[242370702]=29838,	[242370689]=29825,	[242370699]=29835,	[242370695]=29831,	[240293037]=22893,	[244493487]=39663,
	[244493483]=39659,	[241322167]=25783,	[241322117]=25733,	[243455149]=36205,	[241322168]=25784,	[244460678]=37574,	[241322137]=25753,
	[241322170]=25786,	[240289920]=22656,	[243401897]=32873,	[243440784]=35280,	[244480145]=38801,	[243422361]=34137,	[244480146]=38802,
	[243422344]=34120,	[243422376]=34152,	[243422372]=34148,	[243422366]=34142,	[243422394]=34170,	[242383010]=30626,	[243422339]=34115,
	[243422386]=34162,	[243455132]=36188,	[241343679]=27135,	[241344687]=27183,	[241343661]=27117,	[241344663]=27159,	[241344664]=27160,
	[241344650]=27146,	[241343666]=27122,	[244455564]=37260,	[244455557]=37253,	[244479141]=38757,	[244495495]=39751,	[244486285]=39181,
	[242388116]=30932,	[242388121]=30937,	[244478088]=38664,	[243464344]=36760,	[244512905]=40841,	[244512906]=40842,	[243440785]=35281,
	[242382988]=30604,	[242382987]=30603,	[242382993]=30609,	[240279725]=22061,	[240280718]=22094,	[240280758]=22134,	[244484249]=39065,
	[241330361]=26297,	[240280728]=22104,	[243458196]=36372,	[243458205]=36381,	[243458207]=36383,	[243458194]=36370,	[243458220]=36396,
	[243458222]=36398,	[243458223]=36399,	[243458234]=36410,	[243458206]=36382,	[243430589]=34685,	[243430590]=34686,	[243430587]=34683,
	[243430576]=34672,	[243430574]=34670,	[243431563]=34699,	[243430547]=34643,	[243430563]=34659,	[243430588]=34684,	[240280727]=22103,
	[240279724]=22060,	[244484250]=39066,	[240280717]=22093,	[240280738]=22114,	[240280729]=22105,	[240280732]=22108,	[240280716]=22092,
	[240280724]=22100,	[244484251]=39067,	[240313502]=24158,	[240313505]=24161,	[240310425]=23961,	[240310429]=23965,	[244492474]=39610,
	[244492476]=39612,	[244492472]=39608,	[244470922]=38218,	[244470921]=38217,	[244470924]=38220,	[244470925]=38221,	[244470927]=38223,
	[244470930]=38226,	[244470931]=38227,	[244470932]=38228,	[242393271]=31287,	[242399412]=31668,	[242400401]=31697,	[242400385]=31681,
	[242400396]=31692,	[242400390]=31686,	[242361494]=29270,	[240259211]=20747,	[240318645]=24501,	[242388112]=30928,	[243426466]=34402,
	[244507806]=40542,	[243407000]=33176,	[241364117]=28373,	[244500640]=40096,	[244500641]=40097,	[244500642]=40098,	[244500643]=40099,
	[244500645]=40101,	[244500647]=40103,	[244500649]=40105,	[242365591]=29527,	[242365600]=29536,	[243440815]=35311,	[244488339]=39315,
	[244488340]=39316,	[244508862]=40638,	[240315547]=24283,	[242376859]=30235,	[242376892]=30268,	[242376866]=30242,	[242376864]=30240,
	[244511889]=40785,	[242415791]=32687,	[242415792]=32688,	[173206679]=155351,	[244450484]=36980,	[242404492]=31948,	[242404493]=31949,
	[242404485]=31941,	[242358428]=29084,	[242358453]=29109,	[242358432]=29088,	[241367181]=28557,	[241367180]=28556,	[241366200]=28536,
	[241366182]=28518,	[241366194]=28530,	[244460680]=37576,	[241366175]=28511,	[241366204]=28540,	[241366202]=28538,	[241309868]=25004,
	[241309863]=24999,	[240303278]=23534,	[242395315]=31411,	[243450035]=35891,	[243437748]=35124,	[243437727]=35103,	[243437739]=35115,
	[243450037]=35893,	[242358440]=29096,	[240305318]=23654,	[240300169]=23305,	[240266416]=21232,	[241311918]=25134,	[243430565]=34661,
	[242413740]=32556,	[242413742]=32558,	[242413743]=32559,	[244492451]=39587,	[242373823]=30079,	[243400873]=32809,	[243400872]=32808,
	[243400874]=32810,	[242370718]=29854,	[242370719]=29855,	[244479131]=38747,	[242370720]=29856,	[242370712]=29848,	[243401905]=32881,
	[243431599]=34735,	[244493499]=39675,	[244493485]=39661,	[244493497]=39673,	[241323136]=25792,	[242358457]=29113,	[242372751]=29967,
	[241323166]=25822,	[242409632]=32288,	[242388140]=30956,	[244484254]=39070,	[243422395]=34171,	[244480152]=38808,	[244484255]=39071,
	[243423396]=34212,	[243423400]=34216,	[241346720]=27296,	[243423375]=34191,	[243423406]=34222,	[243423388]=34204,	[243423365]=34181,
	[241344702]=27198,	[241345691]=27227,	[241345671]=27207,	[241344693]=27189,	[241346702]=27278,	[241345721]=27257,	[241344701]=27197,
	[241344680]=27176,	[241345724]=27260,	[240289980]=22716,	[241345680]=27216,	[242416814]=32750,	[244455579]=37275,	[244455568]=37264,
	[244455565]=37261,	[244455578]=37274,	[242388146]=30962,	[243455133]=36189,	[244485273]=39129,	[241350826]=27562,	[244478102]=38678,
	[244478095]=38671,	[244478099]=38675,	[244461758]=37694,	[243464346]=36762,	[243408059]=33275,	[244450493]=36989,	[241352837]=27653,
	[242383007]=30623,	[242383008]=30624,	[242383024]=30640,	[240281732]=22148,	[240281734]=22150,	[240280740]=22116,	[241330366]=26302,
	[243459200]=36416,	[243458233]=36409,	[243458229]=36405,	[243458237]=36413,	[243459209]=36425,	[243459201]=36417,	[243431592]=34728,
	[243432594]=34770,	[243431560]=34696,	[243431557]=34693,	[243431597]=34733,	[243431584]=34720,	[243431583]=34719,	[240280753]=22129,
	[240280748]=22124,	[240280747]=22123,	[240280763]=22139,	[240280764]=22140,	[242414777]=32633,	[240283804]=22300,	[239245443]=18819,
	[244470934]=38230,	[244470935]=38231,	[244470936]=38232,	[244470938]=38234,	[244470939]=38235,	[244470941]=38237,	[244470942]=38238,
	[244470944]=38240,	[241352839]=27655,	[241352838]=27654,	[241309865]=25001,	[242394257]=31313,	[242400413]=31709,	[242400421]=31717,
	[242400422]=31718,	[242400426]=31722,	[242400409]=31705,	[242379941]=30437,	[240265363]=21139,	[242416817]=32753,	[244495497]=39753,
	[244495496]=39752,	[240318652]=24508,	[241349785]=27481,	[243407027]=33203,	[243407014]=33190,	[243407001]=33177,	[244500654]=40110,
	[244500657]=40113,	[244500658]=40114,	[244500659]=40115,	[244500660]=40116,	[244500661]=40117,	[244500663]=40119,	[244500667]=40123,
	[242365620]=29556,	[242365613]=29549,	[242365612]=29548,	[244451458]=36994,	[244507815]=40551,	[240315560]=24296,	[243455135]=36191,
	[242376880]=30256,	[240315562]=24298,	[242376895]=30271,	[242376885]=30261,	[242376884]=30260,	[242377859]=30275,	[242376883]=30259,
	[241326227]=26003,	[244508807]=40583,	[244508808]=40584,	[240300212]=23348,	[240290949]=22725,	[242415794]=32690,	[242404503]=31959,
	[242383013]=30629,	[242372753]=29969,	[242359438]=29134,	[242359456]=29152,	[242359444]=29140,	[242359463]=29159,	[241368209]=28625,
	[241368201]=28617,	[241366174]=28510,	[241367207]=28583,	[241367225]=28601,	[241367205]=28581,	[241367222]=28598,	[241368194]=28610,
	[243437744]=35120,	[240303280]=23536,	[242395320]=31416,	[243437750]=35126,	[242391207]=31143,	[240300182]=23318,	[242362527]=29343,
	[244476080]=38576,	[240300183]=23319,	[244484257]=39073,	[242413745]=32561,	[242413746]=32562,	[242413747]=32563,	[242370728]=29864,
	[242370729]=29865,	[242370704]=29840,	[242370730]=29866,	[243431595]=34731,	[241323172]=25828,	[240290965]=22741,	[243440819]=35315,
	[242414724]=32580,	[241323170]=25826,	[243423417]=34233,	[244480161]=38817,	[244480172]=38828,	[243423415]=34231,	[243423408]=34224,
	[243424403]=34259,	[243424385]=34241,	[241346692]=27268,	[241346729]=27305,	[241310859]=25035,	[244455586]=37282,	[242416819]=32755,
	[242389125]=30981,	[242388148]=30964,	[244507817]=40553,	[244512907]=40843,	[244512908]=40844,	[243451059]=35955,	[240290961]=22737,
	[244509883]=40699,	[240281743]=22159,	[240281733]=22149,	[243459217]=36433,	[243459218]=36434,	[243459210]=36426,	[243432613]=34789,
	[243431596]=34732,	[243431605]=34741,	[242374787]=30083,	[243431603]=34739,	[243432593]=34769,	[240281747]=22163,	[242415745]=32641,
	[242414781]=32637,	[242414782]=32638,	[240310455]=23991,	[244509852]=40668,	[244509853]=40669,	[244493441]=39617,	[244493440]=39616,
	[244470945]=38241,	[244470946]=38242,	[244470947]=38243,	[244470950]=38246,	[244470951]=38247,	[244470953]=38249,	[244470954]=38250,
	[244470955]=38251,	[242414725]=32581,	[244509839]=40655,	[242401420]=31756,	[242400446]=31742,	[242400444]=31740,	[242401430]=31766,
	[242401419]=31755,	[244510882]=40738,	[244509851]=40667,	[240259233]=20769,	[244507818]=40554,	[244510910]=40766,	[242378916]=30372,
	[244495501]=39757,	[244512928]=40864,	[242410631]=32327,	[243452056]=35992,	[244451464]=37000,	[243452052]=35988,	[243408012]=33228,
	[243407035]=33211,	[243408006]=33222,	[243408003]=33219,	[244500668]=40124,	[244500669]=40125,	[244501632]=40128,	[244501635]=40131,
	[244501637]=40133,	[244501639]=40135,	[244501642]=40138,	[243431613]=34749,	[242359470]=29166,	[244507819]=40555,	[243438724]=35140,
	[242404508]=31964,	[242409659]=32315,	[243407034]=33210,	[242377869]=30285,	[244508811]=40587,	[241310865]=25041,	[241368225]=28641,
	[241368238]=28654,	[241368222]=28638,	[241368224]=28640,	[241368239]=28655,	[243459207]=36423,	[243445895]=35591,	[244451459]=36995,
	[243438721]=35137,	[241346711]=27287,	[241323160]=25816,	[240301242]=23418,	[244476083]=38579,	[240300215]=23351,	[243432586]=34762,
	[244507820]=40556,	[244462762]=37738,	[244464778]=37834,	[244501644]=40140,	[244494472]=39688,	[244494467]=39683,	[242383037]=30653,
	[244480175]=38831,	[244480168]=38824,	[244480171]=38827,	[244480167]=38823,	[244480163]=38819,	[243424412]=34268,	[243424416]=34272,
	[243424425]=34281,	[244455594]=37290,	[243459225]=36441,	[242389139]=30995,	[242359481]=29177,	[244486318]=39214,	[242383039]=30655,
	[241331355]=26331,	[244484258]=39074,	[241331356]=26332,	[243460231]=36487,	[243459226]=36442,	[244507821]=40557,	[243432603]=34779,
	[243432618]=34794,	[243432608]=34784,	[243432622]=34798,	[244507822]=40558,	[244509856]=40672,	[244509855]=40671,	[244493445]=39621,
	[244493442]=39618,	[244470956]=38252,	[244470957]=38253,	[244470959]=38255,	[244488357]=39333,	[242401439]=31775,	[242401450]=31786,
	[244510892]=40748,	[244477088]=38624,	[243410079]=33375,	[244501646]=40142,	[244501647]=40143,	[244501648]=40144,	[242377886]=30302,
	[242377876]=30292,	[242377884]=30300,	[242377878]=30294,	[242404520]=31976,	[243459241]=36457,	[244463759]=37775,	[241310901]=25077,
	[240317597]=24413,	[244451467]=37003,	[244494479]=39695,	[241324169]=25865,	[241324178]=25874,	[244480178]=38834,	[244480180]=38836,
	[243424447]=34303,	[243425447]=34343,	[243425413]=34309,	[244508819]=40595,	[244455598]=37294,	[244455599]=37295,	[244454531]=37187,
	[244478122]=38698,	[244478125]=38701,	[244478120]=38696,	[244509884]=40700,	[240281775]=22191,	[243459248]=36464,	[243459254]=36470,
	[243459261]=36477,	[243459260]=36476,	[243459252]=36468,	[243459262]=36478,	[243459263]=36479,	[243433622]=34838,	[243433619]=34835,
	[243432638]=34814,	[243433610]=34826,	[244509858]=40674,	[244493451]=39627,	[244493452]=39628,	[244470962]=38258,	[242402432]=31808,
	[242402433]=31809,	[244511873]=40769,	[244495505]=39761,	[243410088]=33384,	[244501651]=40147,	[244501652]=40148,	[244501653]=40149,
	[244501655]=40151,	[244501657]=40153,	[244508818]=40594,	[244464790]=37846,	[242415800]=32696,	[238215302]=15878,	[242352282]=28698,
	[242352291]=28707,	[242352283]=28699,	[243438758]=35174,	[243450038]=35894,	[243438750]=35166,	[244492453]=39589,	[242413749]=32565,
	[242371730]=29906,	[241324184]=25880,	[243425449]=34345,	[243425430]=34326,	[244455604]=37300,	[244478128]=38704,	[244454534]=37190,
	[242384013]=30669,	[241331366]=26342,	[243460229]=36485,	[244510861]=40717,	[240311433]=24009,	[244509865]=40681,	[244509861]=40677,
	[244509866]=40682,	[244470963]=38259,	[244470964]=38260,	[244509863]=40679,	[242411650]=32386,	[242370746]=29882,	[244510895]=40751,
	[243408028]=33244,	[244501660]=40156,	[244501661]=40157,	[244501663]=40159,	[242365630]=29566,	[240301184]=23360,	[244492455]=39591,
	[242371736]=29912,	[244510873]=40729,	[244455610]=37306,	[242389172]=31028,	[244484262]=39078,	[241331369]=26345,	[244501666]=40162,
	[242377899]=30315,	[244508829]=40605,	[240291988]=22804,	[242360477]=29213,	[242353295]=28751,	[242391219]=31155,	[244465854]=37950,
	[242415804]=32700,	[243433633]=34849,	[243400881]=32817,	[241310911]=25087,	[243425464]=34360,	[244507827]=40563,	[244478142]=38718,
	[241352845]=27661,	[244487317]=39253,	[243460240]=36496,	[244493457]=39633,	[244470965]=38261,	[242394288]=31344,	[244487316]=39252,
	[244494523]=39739,	[244494495]=39711,	[243456177]=36273,	[241324203]=25899,	[241324197]=25893,	[244484263]=39079,	[243460252]=36508,
	[244510905]=40761,	[242377903]=30319,	[244508831]=40607,	[243433650]=34866,	[243433657]=34873,	[243460254]=36510,	[243434658]=34914,
	[244466859]=37995,	[242353310]=28766,	[243438779]=35195,	[242411675]=32411,	[244494499]=39715,	[241324206]=25902,	[240282772]=22228,
	[244488341]=39317,	[241311878]=25094,	[242360488]=29224,	[244511881]=40777,	[239265933]=20109,	[240304290]=23586,	[240317619]=24435,
	[240268460]=21356,	[241350835]=27571,	[167929014]=132726,	[241351820]=27596,	[244451480]=37016,	[241311883]=25099,	[240283810]=22306,
	[241352853]=27669,	[239267979]=20235,	[240261294]=20910,	[241352895]=27711,	[241353864]=27720,	[241352894]=27710,	[240319625]=24521,
	[240302212]=23428,	[180522137]=182489,	[243447985]=35761,	[241312926]=25182,	[240283826]=22322,	[240283819]=22315,	[243411087]=33423,
	[243411075]=33411,	[241332403]=26419,	[241332408]=26424,	[176317624]=165496,	[244451496]=37032,	[240271506]=21522,	[240271510]=21526,
	[240305340]=23676,	[240305342]=23678,	[243464383]=36799,	[244467846]=38022,	[239266995]=20211,	[239268003]=20259,	[239267976]=20232,
	[242377919]=30335,	[242372778]=29994,	[244451488]=37024,	[242362548]=29364,	[240261297]=20913,	[244451489]=37025,	[244473003]=38379,
	[180493461]=180693,	[241353867]=27723,	[239235235]=18211,	[243447995]=35771,	[180522142]=182494,	[240301206]=23382,	[180510867]=181779,
	[242411689]=32425,	[242366610]=29586,	[242366611]=29587,	[242366616]=29592,	[242366618]=29594,	[240263340]=21036,	[179483807]=179039,
	[240284828]=22364,	[240284809]=22345,	[241312957]=25213,	[179483810]=179042,	[240284811]=22347,	[241312954]=25210,	[238197905]=14801,
	[241351824]=27600,	[243411120]=33456,	[243411107]=33443,	[243412106]=33482,	[243412105]=33481,	[243411096]=33432,	[243411124]=33460,
	[243411104]=33440,	[179444909]=176621,	[243411108]=33444,	[241333397]=26453,	[241333401]=26457,	[241333380]=26436,	[241333415]=26471,
	[241333417]=26473,	[240304298]=23594,	[240304296]=23592,	[243463338]=36714,	[179454084]=177156,	[240284818]=22354,	[243411080]=33416,
	[241327284]=26100,	[241327285]=26101,	[240272537]=21593,	[238179502]=13678,	[240306317]=23693,	[179492023]=179575,	[240306336]=23712,
	[240306332]=23708,	[240272519]=21575,	[240261263]=20879,	[243440771]=35267,	[240306329]=23705,	[239268030]=20286,	[238175367]=13383,
	[239268013]=20269,	[239269014]=20310,	[239268018]=20274,	[239268993]=20289,	[244485263]=39119,	[242363523]=29379,	[244473014]=38390,
	[241353895]=27751,	[241353899]=27755,	[171100312]=146584,	[171100311]=146583,	[241354884]=27780,	[241354904]=27800,	[180493465]=180697,
	[241353901]=27757,	[238210183]=15559,	[241354887]=27783,	[240319662]=24558,	[240319667]=24563,	[240319674]=24570,	[180522145]=182497,
	[242390147]=31043,	[243448967]=35783,	[244451506]=37042,	[243448974]=35790,	[243448976]=35792,	[240305283]=23619,	[179495081]=179753,
	[240306314]=23690,	[244474045]=38461,	[239241402]=18618,	[244474044]=38460,	[240294055]=22951,	[240294040]=22936,	[176318613]=165525,
	[242411694]=32430,	[244491442]=39538,	[179462300]=177692,	[242411707]=32443,	[180510872]=181784,	[179462301]=177693,	[242411708]=32444,
	[242366628]=29604,	[242366622]=29598,	[242366641]=29617,	[242366623]=29599,	[244451517]=37053,	[244451519]=37055,	[240284837]=22373,
	[240284848]=22384,	[240284844]=22380,	[240284861]=22397,	[240316550]=24326,	[243400885]=32821,	[239241404]=18620,	[174240924]=158556,
	[243413131]=33547,	[243412135]=33511,	[243412158]=33534,	[243412128]=33504,	[241334405]=26501,	[238204046]=15182,	[241334424]=26520,
	[241334413]=26509,	[242384060]=30716,	[242384059]=30715,	[240267452]=21308,	[180527234]=182786,	[180486313]=180265,	[180486314]=180266,
	[241327295]=26111,	[241328263]=26119,	[241328260]=26116,	[241328274]=26130,	[241328264]=26120,	[240273545]=21641,	[240273543]=21639,
	[240273549]=21645,	[240306357]=23733,	[240306365]=23741,	[240306344]=23720,	[240306334]=23710,	[240307330]=23746,	[238189699]=14275,
	[240282807]=22263,	[180531369]=183081,	[244467856]=38032,	[244467860]=38036,	[244467862]=38038,	[242361509]=29285,	[239269044]=20340,
	[240285832]=22408,	[239270017]=20353,	[239270073]=20409,	[239269048]=20344,	[239269050]=20346,	[244476089]=38585,	[238175370]=13386,
	[239270018]=20354,	[239269053]=20349,	[239270040]=20376,	[244452488]=37064,	[243409056]=33312,	[244452496]=37072,	[244452483]=37059,
	[241324221]=25917,	[243402925]=32941,	[243402936]=32952,	[243402935]=32951,	[242363529]=29385,	[242363549]=29405,	[244487347]=39283,
	[240319646]=24542,	[241326268]=26044,	[242354316]=28812,	[242354310]=28806,	[241355929]=27865,	[241354938]=27834,	[241355906]=27842,
	[241355932]=27868,	[241355907]=27843,	[241355911]=27847,	[241303690]=24586,	[240307331]=23747,	[242394296]=31352,	[242390155]=31051,
	[242390154]=31050,	[179451043]=176995,	[180522163]=182515,	[180528317]=182909,	[244506788]=40484,	[240316578]=24354,	[240316584]=24360,
	[244475025]=38481,	[180533439]=183231,	[244475022]=38478,	[180534400]=183232,	[240268474]=21370,	[239264952]=20088,	[240294061]=22957,
	[240295048]=22984,	[179486875]=179227,	[243465395]=36851,	[240270485]=21461,	[180538549]=183541,	[244491445]=39541,	[180538550]=183542,
	[239218873]=17209,	[244491450]=39546,	[179470474]=178186,	[242412683]=32459,	[242412688]=32464,	[242385033]=30729,	[243400852]=32788,
	[238185603]=14019,	[242366646]=29622,	[242367623]=29639,	[242367621]=29637,	[180499611]=181083,	[242367627]=29643,	[242366649]=29625,
	[242367628]=29644,	[242366655]=29631,	[244481192]=38888,	[240285850]=22426,	[240285871]=22447,	[240285849]=22425,	[240285874]=22450,
	[240286863]=22479,	[240285837]=22413,	[243400839]=32775,	[244513933]=40909,	[240285838]=22414,	[240285876]=22452,	[240285855]=22431,
	[240285854]=22430,	[241315987]=25363,	[240285877]=22453,	[240285839]=22415,	[241314998]=25334,	[243414166]=33622,	[243414145]=33601,
	[243414169]=33625,	[243414171]=33627,	[243413128]=33544,	[243413181]=33597,	[243414148]=33604,	[243413178]=33594,	[180514988]=182060,
	[243414163]=33619,	[243413171]=33587,	[174244001]=158753,	[243413147]=33563,	[243414189]=33645,	[238204053]=15189,	[241335479]=26615,
	[241335427]=26563,	[241335434]=26570,	[241334457]=26553,	[241336464]=26640,	[241335446]=26582,	[244452506]=37082,	[240264325]=21061,
	[239259795]=19731,	[243465402]=36858,	[240269462]=21398,	[242385030]=30726,	[242385041]=30737,	[242385028]=30724,	[243400847]=32783,
	[240293011]=22867,	[239261870]=19886,	[243463349]=36725,	[243463351]=36727,	[243463353]=36729,	[243463354]=36730,	[241328314]=26170,
	[178452642]=176034,	[241328317]=26173,	[242379959]=30455,	[240273569]=21665,	[240273594]=21690,	[241328307]=26163,	[241328291]=26147,
	[240274578]=21714,	[241328292]=26148,	[241328299]=26155,	[241328289]=26145,	[240273573]=21669,	[241328298]=26154,	[243426487]=34423,
	[243426488]=34424,	[240274563]=21699,	[243400849]=32785,	[240307343]=23759,	[240307355]=23771,	[178430128]=174640,	[240307351]=23767,
	[240307367]=23783,	[240312481]=24097,	[244467864]=38040,	[179457191]=177383,	[244467868]=38044,	[180531374]=183086,	[180531377]=183089,
	[180531373]=183085,	[244467882]=38058,	[244467884]=38060,	[244467885]=38061,	[242384039]=30695,	[242392236]=31212,	[239271083]=20459,
	[243409025]=33281,	[239271068]=20444,	[239271065]=20441,	[239271053]=20429,	[240285845]=22421,	[243434638]=34894,	[243409059]=33315,
	[240316551]=24327,	[239270068]=20404,	[244506791]=40487,	[239221921]=17377,	[243403936]=32992,	[174220470]=157302,	[243403912]=32968,
	[243403945]=33001,	[243403939]=32995,	[241332367]=26383,	[244485264]=39120,	[243441796]=35332,	[244487355]=39291,	[240314532]=24228,
	[242374818]=30114,	[242354339]=28835,	[242354335]=28831,	[238213298]=15794,	[241356973]=27949,	[241356952]=27928,	[241356947]=27923,
	[241356991]=27967,	[238210202]=15578,	[241355930]=27866,	[241357960]=27976,	[241357961]=27977,	[241356984]=27960,	[241356945]=27921,
	[241356962]=27938,	[241356936]=27912,	[241356954]=27930,	[241356986]=27962,	[241356968]=27944,	[241357968]=27984,	[238210200]=15576,
	[241356980]=27956,	[241356963]=27939,	[241304724]=24660,	[240302252]=23468,	[242395264]=31360,	[241312898]=25154,	[243435654]=34950,
	[242390159]=31055,	[242390160]=31056,	[242390165]=31061,	[240270490]=21466,	[244475047]=38503,	[244475038]=38494,	[240296064]=23040,
	[240295070]=23006,	[240295089]=23025,	[240295076]=23012,	[240295094]=23030,	[240295101]=23037,	[241334450]=26546,	[242412694]=32470,
	[244492419]=39555,	[180510881]=181793,	[180538557]=183549,	[180510889]=181801,	[179441831]=176423,	[240317590]=24406,	[244492425]=39561,
	[241304733]=24669,	[242367658]=29674,	[242367643]=29659,	[242367673]=29689,	[242368650]=29706,	[242366652]=29628,	[242367638]=29654,
	[178420893]=174045,	[242367677]=29693,	[242367654]=29670,	[242367659]=29675,	[242367634]=29650,	[180499620]=181092,	[242367650]=29666,
	[242367637]=29653,	[242367645]=29661,	[179483836]=179068,	[240286871]=22487,	[240285886]=22462,	[240285882]=22458,	[240286854]=22470,
	[240285887]=22463,	[240286860]=22476,	[240286855]=22471,	[243415216]=33712,	[243413149]=33565,	[180514991]=182063,	[244453504]=37120,
	[243415222]=33718,	[243415197]=33693,	[239226006]=17622,	[243415193]=33689,	[241336507]=26683,	[241337504]=26720,	[180488361]=180393,
	[241337476]=26692,	[241338528]=26784,	[241336500]=26676,	[241338548]=26804,	[241336466]=26642,	[244454542]=37198,	[244454543]=37199,
	[179470470]=178182,	[242385077]=30773,	[242385056]=30752,	[242385067]=30763,	[242385068]=30764,	[242386049]=30785,	[241304743]=24679,
	[242416771]=32707,	[244452522]=37098,	[176308360]=164872,	[243464320]=36736,	[243464321]=36737,	[180498583]=181015,	[240264341]=21077,
	[243455104]=36160,	[240274594]=21730,	[241329285]=26181,	[241329290]=26186,	[240275613]=21789,	[240274611]=21747,	[240274609]=21745,
	[240261268]=20884,	[241329300]=26196,	[241329296]=26192,	[241329302]=26198,	[242373782]=30038,	[243427460]=34436,	[243427462]=34438,
	[179455137]=177249,	[240312497]=24113,	[240308353]=23809,	[240307391]=23807,	[178430134]=174646,	[240308356]=23812,	[240312488]=24104,
	[240308352]=23808,	[243455110]=36166,	[180531384]=183096,	[244467895]=38071,	[180531387]=183099,	[180531385]=183097,	[180531391]=183103,
	[180532353]=183105,	[242380954]=30490,	[242372769]=29985,	[242397355]=31531,	[240255163]=20539,	[240255156]=20532,	[243404969]=33065,
	[240255150]=20526,	[240255125]=20501,	[240255134]=20510,	[179472568]=178360,	[240255123]=20499,	[240255143]=20519,	[243434627]=34883,
	[243426450]=34386,	[243409069]=33325,	[243409071]=33327,	[243409061]=33317,	[242371742]=29918,	[244494511]=39727,	[244506800]=40496,
	[243404942]=33038,	[241332371]=26387,	[243403954]=33010,	[243426451]=34387,	[244499645]=40061,	[242363572]=29428,	[240307377]=23793,
	[242363579]=29435,	[242380962]=30498,	[179461287]=177639,	[240266381]=21197,	[242375812]=30148,	[242374832]=30128,	[242375811]=30147,
	[242396312]=31448,	[242415766]=32662,	[242415763]=32659,	[241337482]=26698,	[241325193]=25929,	[242355360]=28896,	[242355348]=28884,
	[242355382]=28918,	[242355387]=28923,	[180496520]=180872,	[241358989]=28045,	[241357985]=28001,	[241357997]=28013,	[241357996]=28012,
	[241358980]=28036,	[241359010]=28066,	[241358992]=28048,	[241358000]=28016,	[241357983]=27999,	[241357979]=27995,	[241358012]=28028,
	[241358002]=28018,	[241359000]=28056,	[241305736]=24712,	[241305731]=24707,	[241305762]=24738,	[180504712]=181384,	[240302247]=23463,
	[242395269]=31365,	[242395274]=31370,	[242395278]=31374,	[241312901]=25157,	[241312902]=25158,	[243435690]=34986,	[243435671]=34967,
	[243435695]=34991,	[242390183]=31079,	[244476090]=38586,	[240287922]=22578,	[242374797]=30093,	[176351385]=167577,	[244475060]=38516,
	[242355357]=28893,	[242385070]=30766,	[238185626]=14042,	[240274623]=21759,	[242416768]=32704,	[242416770]=32706,	[240264351]=21087,
	[180538559]=183551,	[179441832]=176424,	[242412708]=32484,	[244492429]=39565,	[180510891]=181803,	[239208622]=16558,	[242368654]=29710,
	[242367672]=29688,	[242367669]=29685,	[242368644]=29700,	[242368648]=29704,	[242368640]=29696,	[242367674]=29690,	[241318061]=25517,
	[240287886]=22542,	[240287888]=22544,	[240286908]=22524,	[241318030]=25486,	[240286891]=22507,	[240287884]=22540,	[241329314]=26210,
	[179484803]=179075,	[241318046]=25502,	[240286890]=22506,	[240291000]=22776,	[238183565]=13901,	[243401869]=32845,	[243416221]=33757,
	[243417242]=33818,	[243416229]=33765,	[243415231]=33727,	[239226027]=17643,	[240266394]=21210,	[239226028]=17644,	[243417222]=33798,
	[243416194]=33730,	[243416205]=33741,	[243416252]=33788,	[243417251]=33827,	[239226024]=17640,	[243416201]=33737,	[239226011]=17627,
	[241338556]=26812,	[241338557]=26813,	[241337522]=26738,	[241338558]=26814,	[241337519]=26735,	[241338531]=26787,	[241338508]=26764,
	[241337529]=26745,	[241325204]=25940,	[240269475]=21411,	[242386068]=30804,	[244513934]=40910,	[242386073]=30809,	[242386074]=30810,
	[242386058]=30794,	[242386061]=30797,	[240266388]=21204,	[239259797]=19733,	[244512897]=40833,	[244449460]=36916,	[240275626]=21802,
	[240276651]=21867,	[242416776]=32712,	[238202032]=15088,	[241329305]=26201,	[242373796]=30052,	[180536470]=183382,	[243456188]=36284,
	[243457154]=36290,	[243428483]=34499,	[243427506]=34482,	[180518077]=182269,	[243427514]=34490,	[240276660]=21876,	[239220867]=17283,
	[240308391]=23847,	[240308383]=23839,	[240308382]=23838,	[240308370]=23826,	[240308364]=23820,	[240308385]=23841,	[244468879]=38095,
	[179457199]=177391,	[179469497]=178169,	[244468885]=38101,	[179469500]=178172,	[244468886]=38102,	[244468888]=38104,	[244468890]=38106,
	[244468894]=38110,	[244468901]=38117,	[244468916]=38132,	[242361531]=29307,	[242361535]=29311,	[242393222]=31238,	[242397361]=31537,
	[242397359]=31535,	[240256176]=20592,	[240256161]=20577,	[244506810]=40506,	[240256173]=20589,	[240256178]=20594,	[240256129]=20545,
	[238222496]=16352,	[244453509]=37125,	[240256147]=20563,	[240318619]=24475,	[243434642]=34898,	[243409075]=33331,	[243409074]=33330,
	[244506812]=40508,	[241305734]=24710,	[244453507]=37123,	[242371771]=29947,	[239236249]=18265,	[243404982]=33078,	[243404958]=33054,
	[243404959]=33055,	[239221938]=17394,	[244499646]=40062,	[242364551]=29447,	[242364554]=29450,	[242364548]=29444,	[243440790]=35286,
	[167908516]=131428,	[240314545]=24241,	[240314556]=24252,	[240314547]=24243,	[242375827]=30163,	[239259796]=19732,	[242396331]=31467,
	[240287875]=22531,	[244473996]=38412,	[242415773]=32669,	[242415765]=32661,	[242356358]=28934,	[242355386]=28922,	[242356364]=28940,
	[241360015]=28111,	[180493497]=180729,	[241360031]=28127,	[241360028]=28124,	[241360052]=28148,	[241360047]=28143,	[241362100]=28276,
	[241359028]=28084,	[180499617]=181089,	[238195844]=14660,	[241306779]=24795,	[241306772]=24788,	[241305776]=24752,	[241306777]=24793,
	[240303233]=23489,	[244449453]=36909,	[180523143]=182535,	[179451055]=177007,	[243435708]=35004,	[243436680]=35016,	[242390194]=31090,
	[180523146]=182538,	[179451058]=177010,	[243450014]=35870,	[243410100]=33396,	[240316600]=24376,	[240316598]=24374,	[180534414]=183246,
	[244476035]=38531,	[240297118]=23134,	[240296117]=23093,	[240297148]=23164,	[240298134]=23190,	[240297139]=23155,	[240297101]=23117,
	[240297100]=23116,	[240297131]=23147,	[240297124]=23140,	[240297112]=23128,	[240297120]=23136,	[180510892]=181804,	[180510893]=181805,
	[180539522]=183554,	[179462310]=177702,	[242412729]=32505,	[179469445]=178117,	[180510895]=181807,	[244492437]=39573,	[179462311]=177703,
	[242406556]=32092,	[242367671]=29687,	[242368690]=29746,	[242368673]=29729,	[242368671]=29727,	[242368660]=29716,	[242368685]=29741,
	[240287934]=22590,	[240287932]=22588,	[241319061]=25557,	[238183576]=13912,	[240287911]=22567,	[240277638]=21894,	[240287912]=22568,
	[240288901]=22597,	[240287904]=22560,	[242406583]=32119,	[178425019]=174331,	[168966298]=136090,	[243418268]=33884,	[241306766]=24782,
	[243417267]=33843,	[243418265]=33881,	[244479148]=38764,	[243418292]=33908,	[243419271]=33927,	[243419272]=33928,	[244453530]=37146,
	[243419273]=33929,	[243420295]=33991,	[243417257]=33833,	[243419280]=33936,	[243418288]=33904,	[243418254]=33870,	[244453521]=37137,
	[243419278]=33934,	[243418262]=33878,	[243419268]=33924,	[243417273]=33849,	[241339556]=26852,	[241339581]=26877,	[241339563]=26859,
	[241340563]=26899,	[241340561]=26897,	[180489354]=180426,	[244507776]=40512,	[241340550]=26886,	[241339539]=26835,	[241339564]=26860,
	[241339562]=26858,	[241340544]=26880,	[241341591]=26967,	[180542613]=183765,	[242372774]=29990,	[244454566]=37222,	[243440780]=35276,
	[240293025]=22881,	[242378901]=30357,	[242386090]=30826,	[241348793]=27449,	[243442847]=35423,	[179454096]=177168,	[243464332]=36748,
	[241339536]=26832,	[244512898]=40834,	[180544700]=183932,	[244509881]=40697,	[242361498]=29274,	[242381966]=30542,	[241329323]=26219,
	[241329322]=26218,	[241329329]=26225,	[175307961]=163833,	[243428497]=34513,	[242373807]=30063,	[241326237]=26013,	[240277668]=21924,
	[240308406]=23862,	[240309377]=23873,	[179492999]=179591,	[240308414]=23870,	[240309381]=23877,	[240308415]=23871,	[240309402]=23898,
	[242416793]=32729,	[179460270]=177582,	[240283788]=22284,	[240283792]=22288,	[243455121]=36177,	[241360060]=28156,	[243455122]=36178,
	[244513935]=40911,	[244468921]=38137,	[180532362]=183114,	[244468925]=38141,	[176342151]=166983,	[179457206]=177398,	[244469898]=38154,
	[244469901]=38157,	[244469902]=38158,	[180532366]=183118,	[244469907]=38163,	[242362503]=29319,	[244484235]=39051,	[242393228]=31244,
	[242398336]=31552,	[242398360]=31576,	[242398364]=31580,	[242398373]=31589,	[242398341]=31557,	[240257155]=20611,	[240257161]=20617,
	[242416795]=32731,	[240257170]=20626,	[240257173]=20629,	[243409086]=33342,	[242373804]=30060,	[179460271]=177583,	[243404991]=33087,
	[243405976]=33112,	[239222915]=17411,	[243405977]=33113,	[243405970]=33106,	[180536479]=183391,	[244500611]=40067,	[242364592]=29488,
	[179465389]=177901,	[242364591]=29487,	[238217348]=16004,	[244488329]=39305,	[240262291]=20947,	[244453527]=37143,	[179494071]=179703,
	[240315531]=24267,	[240315526]=24262,	[244453516]=37132,	[242403490]=31906,	[244450438]=36934,	[241327248]=26064,	[180533425]=183217,
	[242356382]=28958,	[180496548]=180900,	[241348795]=27451,	[171106467]=146979,	[241363098]=28314,	[241363073]=28289,	[241362077]=28253,
	[241361072]=28208,	[241362067]=28243,	[238211220]=15636,	[241361055]=28191,	[241363104]=28320,	[241361084]=28220,	[241363079]=28295,
	[241362083]=28259,	[241362065]=28241,	[241363102]=28318,	[241307792]=24848,	[241307779]=24835,	[241325225]=25961,	[242372783]=29999,
	[241339560]=26856,	[241312906]=25162,	[243436707]=35043,	[242390204]=31100,	[240297147]=23163,	[240298118]=23174,	[240298142]=23198,
	[238185657]=14073,	[240298131]=23187,	[240298114]=23170,	[240298116]=23172,	[241351861]=27637,	[242384030]=30686,	[180539523]=183555,
	[179462312]=177704,	[242413706]=32522,	[242413712]=32528,	[244492441]=39577,	[242369667]=29763,	[242369683]=29779,	[242369669]=29765,
	[242369670]=29766,	[239259798]=19734,	[242369686]=29782,	[242369693]=29789,	[242369684]=29780,	[242369664]=29760,	[172137627]=149979,
	[242369715]=29811,	[242369666]=29762,	[240310405]=23941,	[242369681]=29777,	[244450456]=36952,	[244493474]=39650,	[240288933]=22629,
	[240287933]=22589,	[243455146]=36202,	[241321115]=25691,	[240288925]=22621,	[241320082]=25618,	[241320076]=25612,	[243419313]=33969,
	[243419304]=33960,	[243420303]=33999,	[243421312]=34048,	[243420322]=34018,	[243420290]=33986,	[243419323]=33979,	[243420323]=34019,
	[241340601]=26937,	[241341610]=26986,	[241342595]=27011,	[241342597]=27013,	[241341586]=26962,	[241341598]=26974,	[241341609]=26985,
	[241342599]=27015,	[241340600]=26936,	[241341593]=26969,	[241349765]=27461,	[180529321]=182953,	[242387075]=30851,	[242387087]=30863,
	[180504724]=181396,	[242387080]=30856,	[239209605]=16581,	[242386111]=30847,	[244453536]=37152,	[243464338]=36754,	[180527246]=182798,
	[179454099]=177171,	[244512902]=40838,	[243440796]=35292,	[239242392]=18648,	[241330325]=26261,	[244507789]=40525,	[179481735]=178887,
	[238203018]=15114,	[241330309]=26245,	[243457201]=36337,	[243429520]=34576,	[243429518]=34574,	[240309426]=23922,	[243455127]=36183,
	[244492465]=39601,	[244469910]=38166,	[179457209]=177401,	[244469912]=38168,	[244469939]=38195,	[244469927]=38183,	[244469930]=38186,
	[180532378]=183130,	[244469931]=38187,	[244469932]=38188,	[180532379]=183131,	[242393233]=31249,	[242393241]=31257,	[239211679]=16735,
	[180507778]=181570,	[242398395]=31611,	[242398396]=31612,	[242398390]=31606,	[242398374]=31590,	[242398372]=31588,	[240257210]=20666,
	[244507790]=40526,	[240258183]=20679,	[243410053]=33349,	[243410057]=33353,	[243450044]=35900,	[243452038]=35974,	[243406013]=33149,
	[243405992]=33128,	[243405999]=33135,	[244500617]=40073,	[244500618]=40074,	[244500620]=40076,	[239257759]=19615,	[180541579]=183691,
	[180541581]=183693,	[244500623]=40079,	[244477066]=38602,	[242364602]=29498,	[244485268]=39124,	[243440799]=35295,	[174224572]=157564,
	[244488332]=39308,	[243436699]=35035,	[240315538]=24274,	[242376832]=30208,	[242376837]=30213,	[244453528]=37144,	[244507794]=40530,
	[244453532]=37148,	[244508800]=40576,	[244453539]=37155,	[244474008]=38424,	[179458230]=177462,	[242357377]=28993,	[242357379]=28995,
	[242357428]=29044,	[242357387]=29003,	[242357407]=29023,	[242357395]=29011,	[241364128]=28384,	[241363085]=28301,	[241363129]=28345,
	[241364102]=28358,	[241364105]=28361,	[241363110]=28326,	[241363125]=28341,	[241365175]=28471,	[241364135]=28391,	[241364120]=28376,
	[241364109]=28365,	[241307821]=24877,	[241308837]=24933,	[241308806]=24902,	[240288945]=22641,	[179449984]=176896,	[243436732]=35068,
	[242391179]=31115,	[242391188]=31124,	[242391192]=31128,	[242391186]=31122,	[243450027]=35883,	[244507796]=40532,	[179460275]=177587,
	[241307789]=24845,	[240299140]=23236,	[240298161]=23217,	[241311908]=25124,	[240266400]=21216,	[241311907]=25123,	[179462314]=177706,
	[179462316]=177708,	[242413726]=32542,	[243400868]=32804,	[242369703]=29799,	[179468457]=178089,	[242369704]=29800,	[242369713]=29809,
	[242369719]=29815,	[242369698]=29794,	[241326240]=26016,	[241321103]=25679,	[240289941]=22677,	[240289928]=22664,	[240289936]=22672,
	[240289944]=22680,	[241321140]=25716,	[244459662]=37518,	[168968339]=136211,	[240289946]=22682,	[241322134]=25750,	[178426007]=174359,
	[244479165]=38781,	[244480129]=38785,	[243421324]=34060,	[243421320]=34056,	[243420336]=34032,	[243421369]=34105,	[243421322]=34058,
	[240279695]=22031,	[241342640]=27056,	[241342609]=27025,	[241343642]=27098,	[171072651]=144843,	[241343644]=27100,	[241342605]=27021,
	[242374800]=30096,	[180543640]=183832,	[244454586]=37242,	[244454590]=37246,	[244454578]=37234,	[244454580]=37236,	[242387126]=30902,
	[239209614]=16590,	[180504727]=181399,	[242387112]=30888,	[173166770]=152882,	[242387129]=30905,	[242387109]=30885,	[240265346]=21122,
	[179464342]=177814,	[239259799]=19735,	[240292005]=22821,	[242382989]=30605,	[244507798]=40534,	[238203022]=15118,	[243457213]=36349,
	[243429566]=34622,	[240313494]=24150,	[240310413]=23949,	[240283801]=22297,	[176342159]=166991,	[244469946]=38202,	[244469948]=38204,
	[244469949]=38205,	[180532388]=183140,	[244469950]=38206,	[244469951]=38207,	[244470915]=38211,	[244470916]=38212,	[244470917]=38213,
	[244488349]=39325,	[244507801]=40537,	[242399400]=31656,	[242399382]=31638,	[240265348]=21124,	[240258220]=20716,	[240258214]=20710,
	[240258196]=20692,	[240258190]=20686,	[241343619]=27075,	[238183590]=13926,	[244500626]=40082,	[244500629]=40085,	[179464341]=177813,
	[244500630]=40086,	[244500631]=40087,	[244500632]=40088,	[244500633]=40089,	[180541584]=183696,	[180541583]=183695,	[177403070]=171902,
	[240291984]=22800,	[242365581]=29517,	[244485271]=39127,	[180543642]=183834,	[240262296]=20952,	[240315537]=24273,	[240315545]=24281,
	[242376855]=30231,	[242376869]=30245,	[242376853]=30229,	[244500637]=40093,	[244453547]=37163,	[242358407]=29063,	[241365177]=28473,
	[241365142]=28438,	[241366150]=28486,	[241365156]=28452,	[241366185]=28521,	[241365180]=28476,	[241365172]=28468,	[238220431]=16207,
	[241365128]=28424,	[241365131]=28427,	[241365179]=28475,	[241308844]=24940,	[242395308]=31404,	[242395309]=31405,	[238205118]=15294,
	[180523165]=182557,	[243437717]=35093,	[242391195]=31131,	[242391194]=31130,	[244476073]=38569,	[240299157]=23253,	[240299181]=23277,
	[240299164]=23260,	[240299178]=23274,	[180511874]=181826,	[238218412]=16108,	[244508857]=40633,	[242370694]=29830,	[241365158]=28454,
	[240270471]=21447,	[240289955]=22691,	[240289958]=22694,	[240289953]=22689,	[240265360]=21136,	[243423361]=34177,	[243422384]=34160,
	[243421315]=34051,	[244510866]=40722,	[241343665]=27121,	[244507805]=40541,	[242388111]=30927,	[242388105]=30921,	[241350819]=27555,
	[241308845]=24941,	[244478085]=38661,	[241330357]=26293,	[241330354]=26290,	[241330358]=26294,	[243458214]=36390,	[243458211]=36387,
	[239230102]=17878,	[243430552]=34648,	[243430578]=34674,	[243430564]=34660,	[240280711]=22087,	[240280706]=22082,	[240280704]=22080,
	[242414774]=32630,	[240310450]=23986,	[240310419]=23955,	[238190727]=14343,	[240310431]=23967,	[240310418]=23954,	[244470918]=38214,
	[244470920]=38216,	[244470923]=38219,	[244470926]=38222,	[180532393]=183145,	[244470933]=38229,	[242393273]=31289,	[240259207]=20743,
	[242378910]=30366,	[242378907]=30363,	[239259800]=19736,	[243410062]=33358,	[243410063]=33359,	[244507807]=40543,	[177404035]=171907,
	[244500646]=40102,	[244500650]=40106,	[244500652]=40108,	[241345701]=27237,	[243440813]=35309,	[244507808]=40544,	[244507809]=40545,
	[242404487]=31943,	[242404488]=31944,	[242416806]=32742,	[244507810]=40546,	[244507811]=40547,	[242358427]=29083,	[241366166]=28502,
	[241366197]=28533,	[238212240]=15696,	[241367170]=28546,	[241367195]=28571,	[242369708]=29804,	[241366205]=28541,	[241366206]=28542,
	[241366159]=28495,	[241309869]=25005,	[241309845]=24981,	[180543651]=183843,	[241311917]=25133,	[243437743]=35119,	[242391204]=31140,
	[179451069]=177021,	[240299197]=23293,	[244450489]=36985,	[180539530]=183562,	[242370725]=29861,	[242370738]=29874,	[242370706]=29842,
	[241309849]=24985,	[241323152]=25808,	[244453561]=37177,	[243423411]=34227,	[244480148]=38804,	[244509831]=40647,	[180517023]=182175,
	[243422359]=34135,	[243423394]=34210,	[243422393]=34169,	[241345694]=27230,	[241345681]=27217,	[241345702]=27238,	[244455569]=37265,
	[243440817]=35313,	[242388129]=30945,	[173167778]=152930,	[242388124]=30940,	[243451054]=35950,	[179469478]=178150,	[180545672]=183944,
	[179470492]=178204,	[244507838]=40574,	[243426468]=34404,	[241330367]=26303,	[241331340]=26316,	[241331336]=26312,	[238203034]=15130,
	[243459205]=36421,	[243458230]=36406,	[239230107]=17883,	[243431575]=34711,	[242374785]=30081,	[238190739]=14355,	[240313514]=24170,
	[178431128]=174680,	[240310438]=23974,	[180532396]=183148,	[176342161]=166993,	[180532399]=183151,	[244488350]=39326,	[242394244]=31300,
	[242400410]=31706,	[242400431]=31727,	[242401417]=31753,	[244510909]=40765,	[243434656]=34912,	[242379942]=30438,	[243431587]=34723,
	[242409634]=32290,	[244500653]=40109,	[244500655]=40111,	[244500656]=40112,	[244500666]=40122,	[244500665]=40121,	[179461300]=177652,
	[239265976]=20152,	[242377856]=30272,	[242376877]=30253,	[180543654]=183846,	[242415793]=32689,	[242404498]=31954,	[242359435]=29131,
	[242358459]=29115,	[242359434]=29130,	[242359450]=29146,	[242359439]=29135,	[241368233]=28649,	[241368203]=28619,	[241367210]=28586,
	[241367229]=28605,	[241367220]=28596,	[241367213]=28589,	[241367228]=28604,	[241309879]=25015,	[241309882]=25018,	[241310868]=25044,
	[244509833]=40649,	[240300187]=23323,	[244507816]=40552,	[242416815]=32751,	[179441847]=176439,	[242370737]=29873,	[172139709]=150141,
	[242370732]=29868,	[242370734]=29870,	[244493501]=39677,	[241323199]=25855,	[243423423]=34239,	[243423416]=34232,	[241346705]=27281,
	[241347718]=27334,	[241346718]=27294,	[244455592]=37288,	[242410628]=32324,	[242388153]=30969,	[242388155]=30971,	[242383019]=30635,
	[242383029]=30645,	[243459216]=36432,	[243432591]=34767,	[238182542]=13838,	[180532403]=183155,	[244470948]=38244,	[180532406]=183158,
	[179458189]=177421,	[244470949]=38245,	[244470952]=38248,	[180532408]=183160,	[176342164]=166996,	[180532412]=183164,	[179458190]=177422,
	[242384048]=30704,	[242394265]=31321,	[242394268]=31324,	[242394271]=31327,	[242401429]=31765,	[242401411]=31747,	[242401423]=31759,
	[240259238]=20774,	[244495499]=39755,	[241326262]=26038,	[243410074]=33370,	[180543658]=183850,	[243450047]=35903,	[239257760]=19616,
	[180541599]=183711,	[244500670]=40126,	[180541600]=183712,	[244500671]=40127,	[244501633]=40129,	[244501634]=40130,	[244501640]=40136,
	[244501641]=40137,	[242365615]=29551,	[239230122]=17898,	[244488344]=39320,	[243438741]=35157,	[243438746]=35162,	[180541608]=183720,
	[243431601]=34737,	[242372755]=29971,	[240300204]=23340,	[240300197]=23333,	[174203041]=156193,	[179441848]=176440,	[242371712]=29888,
	[244456592]=37328,	[244494518]=39734,	[242360455]=29191,	[244480179]=38835,	[244480174]=38830,	[180518017]=182209,	[243424415]=34271,
	[243424422]=34278,	[243424424]=34280,	[244507826]=40562,	[241346731]=27307,	[244509857]=40673,	[242389150]=31006,	[242389132]=30988,
	[173168808]=153000,	[243459234]=36450,	[243459228]=36444,	[243432619]=34795,	[239230132]=17908,	[240281754]=22170,	[244493443]=39619,
	[244470958]=38254,	[244470961]=38257,	[244454530]=37186,	[244488359]=39335,	[242401440]=31776,	[242401437]=31773,	[242401456]=31792,
	[244510891]=40747,	[244510889]=40745,	[242378918]=30374,	[243408017]=33233,	[239257762]=19618,	[244501649]=40145,	[244501650]=40146,
	[244507825]=40561,	[244507823]=40559,	[242377879]=30295,	[174213261]=156813,	[241327262]=26078,	[242416823]=32759,	[240261249]=20865,
	[239220886]=17302,	[242352276]=28692,	[242352269]=28685,	[242352268]=28684,	[243438748]=35164,	[239259801]=19737,	[180511882]=181834,
	[240281773]=22189,	[238207104]=15360,	[244494519]=39735,	[244455597]=37293,	[243459247]=36463,	[243433611]=34827,	[242416830]=32766,
	[244501656]=40152,	[240259251]=20787,	[240259252]=20788,	[244510871]=40727,	[180541613]=183725,	[177404044]=171916,	[244501658]=40154,
	[244501659]=40155,	[244508817]=40593,	[244508822]=40598,	[243433603]=34819,	[240317599]=24415,	[240300223]=23359,	[244494482]=39698,
	[243425432]=34328,	[241348738]=27394,	[244455605]=37301,	[244484261]=39077,	[242372759]=29975,	[176323744]=165856,	[240311431]=24007,
	[244454533]=37189,	[244493454]=39630,	[242362536]=29352,	[180541614]=183726,	[176338057]=166729,	[238215308]=15884,	[242360468]=29204,
	[242352305]=28721,	[242352313]=28729,	[242352316]=28732,	[242352309]=28725,	[243438763]=35179,	[240301189]=23365,	[244492454]=39590,
	[180511883]=181835,	[243400880]=32816,	[172141705]=150217,	[242371734]=29910,	[244494488]=39704,	[243456175]=36271,	[180545683]=183955,
	[242414733]=32589,	[244510897]=40753,	[244501664]=40160,	[244501665]=40161,	[244501667]=40163,	[242360479]=29215,	[242360474]=29210,
	[242353288]=28744,	[244481154]=38850,	[242404533]=31989,	[243425468]=34364,	[242389173]=31029,	[244507828]=40564,	[243460244]=36500,
	[242378925]=30381,	[244512930]=40866,	[244501668]=40164,	[239265977]=20153,	[242402469]=31845,	[244510903]=40759,	[179464365]=177837,
	[242366595]=29571,	[244455614]=37310,	[244511879]=40775,	[243440831]=35327,	[243433660]=34876,
}

pen.FILE_XML_MATTER = [[
<Entity serialize="0" >
	<CharacterDataComponent
		buoyancy_check_offset_y="0"
		check_collision_max_size_x="4"
		check_collision_max_size_y="4"
		climb_over_y="0"
		collision_aabb_max_x="0.1"
		collision_aabb_max_y="0.1"
		collision_aabb_min_x="-0.1"
		collision_aabb_min_y="-0.1"
		destroy_ground="0"
		effect_hit_ground="0"
		fly_recharge_spd="0"
		fly_recharge_spd_ground="0"
		fly_time_max="0"
		flying_in_air_wait_frames="0"
		flying_needs_recharge="0"
		flying_recharge_removal_frames="0"
		gravity="0"
		ground_stickyness="0"
		is_on_ground="1"
		is_on_slippery_ground="0"
		liquid_velocity_coeff="0"
		mass="1"
		platforming_type="0"
		send_transform_update_message="0"
	></CharacterDataComponent>
	
	<DamageModelComponent
		air_needed="0"
		blood_material="blood"
		blood_multiplier="0"
		blood_spray_create_some_cosmetic="0"
		blood_spray_material="blood"
		blood_sprite_directional=""
		blood_sprite_large=""
		create_ragdoll="0"
		critical_damage_resistance="0"
		drop_items_on_death="0"
		falling_damages="0"
		fire_damage_amount="0"
		fire_damage_ignited_amount="0"
		fire_how_much_fire_generates="0"
		fire_probability_of_ignition="0"
		healing_particle_effect_entity=""
		hp="-1"
		materials_create_messages="1"
		materials_that_create_messages="_MATTERLISTHERE_"
		materials_damage="0"
		max_hp="-1"
		physics_objects_damage="0"
		ragdoll_blood_amount_absolute="0"
		ragdoll_filenames_file=""
		ragdoll_fx_forced="NONE"
		ragdoll_material="blood"
		ragdoll_offset_x="0"
		ragdoll_offset_y="0"
		ragdollify_child_entity_sprites="0"
		ragdollify_disintegrate_nonroot="0"
		ragdollify_root_angular_damping="0"
		ui_force_report_damage="0"
		ui_report_damage="0"
		wait_for_kill_flag_on_death="1"
		wet_status_effect_damage="0"
		><damage_multipliers
			curse="0"
			drill="0"
			electricity="0"
			explosion="0"
			fire="0"
			healing="0"
			ice="0"
			melee="0"
			overeating="0"
			physics_hit="0"
			poison="0"
			projectile="0"
			radioactive="0"
			slice="0"
			holy="0"
		></damage_multipliers>
	</DamageModelComponent>
</Entity>
]]

pen.FILE_XML_MATTER_COLOR = [[
<Entity serialize="0" >
    <MaterialInventoryComponent
        drop_as_item="0" 
        on_death_spill="0"
        leak_pressure_min="0"
        leak_on_damage_percent="0"
        min_damage_to_leak="0"
        death_throw_particle_velocity_coeff="0"
        do_reactions="0"
        ><count_per_material_type>
        </count_per_material_type>
    </MaterialInventoryComponent>
</Entity>
]]

pen.FILE_XML_FONT = [[
<FontData>
	<Texture>data/fonts/font_pixel_noshadow.png</Texture>
	<LineHeight>7</LineHeight>
	<CharSpace>0</CharSpace>
	<WordSpace>6</WordSpace>
</FontData>
]]

---@class PenmanButtonData
---@field auid string [DFT: pic..pic_z ]<br> Unique animation ID.
---@field no_anim boolean [DFT: false ]<br> Will not do animations if set to true.
---@field highlight any Highlight kind modifier.
---@field skip_z_check boolean [DFT: false ]<br> Set to true to skip the z-level adjustment (it makes only the topmost button to activate on click, yet introduces a 2-frame long delay between the click and the event triggering).
---@field s_x number [DFT: 1 ]<br> Scale X
---@field s_y number [DFT: 1 ]<br> Scale Y
---@field lmb_event fun( pic_x:number, pic_y:number, pic_z:number, pic:path, data:PenmanButtonData ): pic_x:number, pic_y:number, pic_z:number, pic:path, data:PenmanButtonData Gets called on click.
---@field rmb_event fun( pic_x:number, pic_y:number, pic_z:number, pic:path, data:PenmanButtonData ): pic_x:number, pic_y:number, pic_z:number, pic:path, data:PenmanButtonData Gets called on r_click.
---@field hov_event fun( pic_x:number, pic_y:number, pic_z:number, pic:path, data:PenmanButtonData ): pic_x:number, pic_y:number, pic_z:number, pic:path, data:PenmanButtonData Gets called on is_hovered.
---@field idle_event fun( pic_x:number, pic_y:number, pic_z:number, pic:path, data:PenmanButtonData ): pic_x:number, pic_y:number, pic_z:number, pic:path, data:PenmanButtonData Get called on not( is_hovered )
---@field pic_func fun( pic_x:number, pic_y:number, pic_z:number, pic:path, data:PenmanButtonData ) Always gets called and get replaced with pen.new_image if is nil.

---@class PenmanTooltipData
---@field tid string [DFT: "dft" ]<br> The ID of the tooltip. Only one tip can be opened per unique ID.
---@field is_active boolean [DFT: is_hovered ]<br> Set to true to force the tooltip open. If is nil, then will check the state of the last gui element.
---@field allow_hover boolean [DFT: false ]<br> Set to true to keep tooltip opened as long as the mouse is hovering over it.
---@field dims table [DFT: { text_width, text_height } ]<br> The size of the tooltip. If is nil, will fit itself to the text provided.
---@field min_width number [DFT: 121 ] The minimal width a tooltip can be if the dims field is left empty.
---@field max_width number [DFT: 0.9*screen_width ] The maximum width a tooltip can be if the dims field is left empty.
---@field pos table [DFT: mouse_pos ]<br> The position of the tooltip on the screen.
---@field pic_z number [DFT: pen.LAYERS.TIPS ]<br> The depth to draw the tooltip at.
---@field is_left boolean [DFT: false ]<br> Will draw the tooltip to the left if set to true.
---@field is_over boolean [DFT: false ]<br> Will draw the tooltip up above if set to true.
---@field frames number [DFT: 15 ]<br> The duration of the opening animation.
---@field edging number [DFT: 3 ]<br> The spacing between the text and the inner edge of the tooltip background.

---@class PenmanPagerData
---@field list table|number [OBLIGATORY]<br> Can be set to either a table to iterate through or to a maximum number of "pages" to scroll one-by-one.
---@field page number [OBLIGATORY]<br> The current page.
---@field items_per_page number [DFT: 1 ]<br> How many elements one page should contain.
---@field func fun( pic_x:number, pic_y:number, pic_z:number, absolute_i:number, element:any, relative_k:number, is_hidden:boolean ): will_skip:boolean Draws the elements of the current page.
---@field order_func function [DFT: pen.t.order ]<br> Sorts the list for later processing.
---@field click table [INTERNAL]<br> This is used to interface between visual and logical segments. The value of 1 means that the button was clicked and the value of -1 means that it was r_clicked.

--<{> MAGICAL APPEND MARKER <}>--

return pen
pen = pen or {}

--[MATH]
function pen.get_sign( a )
	if( a < 0 ) then
		return -1
	else
		return 1
	end
end

function pen.limiter( value, limit, max_mode )
	max_mode = max_mode or false
	limit = math.abs( limit )
	
	if(( max_mode and math.abs( value ) < limit ) or ( not( max_mode ) and math.abs( value ) > limit )) then
		return pen.get_sign( value )*limit
	end
	
	return value
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

function pen.world2gui( gui, x, y )
	local w, h = GuiGetScreenDimensions( gui )
	local cam_x, cam_y = GameGetCameraPos()
	local shit_from_ass = w/( MagicNumbersGetValue( "VIRTUAL_RESOLUTION_X" ) + MagicNumbersGetValue( "VIRTUAL_RESOLUTION_OFFSET_X" ))
	
	return w/2 + shit_from_ass*( x - cam_x ), h/2 + shit_from_ass*( y - cam_y ), shit_from_ass
end

function pen.get_mouse_pos( gui )
	local m_x, m_y = DEBUG_GetMouseWorld()
	return pen.world2gui( gui, m_x, m_y )
end

--[UTILS]
function pen.debug_dot( x, y, frames )
	GameCreateSpriteForXFrames( "data/ui_gfx/debug_marker.png", x, y, true, 0, 0, frames or 1, true )
end

function pen.add_table( a, b )
	if( #b > 0 ) then
		table.sort( b )
		if( #a > 0 ) then
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

function pen.get_table_count( tbl )
	if( tbl == nil or type( tbl ) ~= "table" ) then
		return 0
	end
	
	local table_count = 0
	for i,element in pairs( tbl ) do
		table_count = table_count + 1
	end
	return table_count
end

function pen.closest_getter( x, y, stuff, check_sight, limits, extra_check )
	check_sight = check_sight or false
	limits = limits or { 0, 0, }
	if( #( stuff or {}) == 0 ) then
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

function pen.set_translations( path )
	local file, main = ModTextFileGetContent( path ), "data/translations/common.csv"
	ModTextFileSetContent( main, ModTextFileGetContent( main )..string.gsub( file, "^[^\n]*\n", "" ))
end

function pen.t2w( str )
	local t = {}
	
	for word in string.gmatch( str, "([^%s]+)" ) do
		table.insert( t, word )
	end
	
	return t
end

function pen.liner( text, length, height, length_k, clean_mode, forced_reverse )
	local formated = {}
	if( text ~= nil and text ~= "" ) then
		local length_counter = 0
		if( height ~= nil ) then
			length_k = length_k or 6
			length = math.floor( length/length_k + 0.5 )
			height = math.floor( height/9 )
			local height_counter = 1
			
			local full_text = "@"..text.."@"
			for line in string.gmatch( full_text, "([^@]+)" ) do
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

function pen.get_translated_line( text )
	local out = ""
	local markers = pen.t2w( pen.get_hybrid_function( text ))
	for i,mark in ipairs( markers ) do
		out = out..( out == "" and out or " " )..GameTextGetTranslatedOrNot( mark )
	end
	return out
end

--[TECHNICAL]
function pen.catch( f, input, fallback )
	local is_good,stuff,oa,ob,oc,od,oe,of,og,oh = pcall(f, unpack( input or {}))
	if( not( is_good )) then
		print( stuff )
		return unpack( fallback or {false})
	else
		return stuff,oa,ob,oc,od,oe,of,og,oh
	end
end

function pen.get_hybrid_function( func, input )
	if( func == nil ) then return end
	if( type( func ) == "function" ) then
		return pen.catch( func, input )
	else
		return func
	end
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

function pen.gui_killer( gui )
	if( gui ~= nil ) then
		GuiDestroy( gui )
	end
end

--[ECS]
function pen.get_storage( hooman, name )
	local comps = EntityGetComponentIncludingDisabled( hooman, "VariableStorageComponent" ) or {}
	if( #comps > 0 ) then
		for i,comp in ipairs( comps ) do
			if( ComponentGetValue2( comp, "name" ) == name ) then
				return comp
			end
		end
	end
	
	return nil
end

function pen.get_hooman_child( hooman, tag, ignore_id )
	if( hooman == nil ) then
		return -1
	end
	
	local children = EntityGetAllChildren( hooman ) or {}
	if( #children > 0 ) then
		for i,child in ipairs( children ) do
			if( child ~= ignore_id and ( EntityGetName( child ) == tag or EntityHasTag( child, tag ))) then
				return child
			end
		end
	end
	
	return nil
end

function pen.get_creature_centre( hooman, x, y )
	local char_comp = EntityGetFirstComponentIncludingDisabled( hooman, "CharacterDataComponent" )
	if( char_comp ~= nil ) then
		y = y + ComponentGetValue2( char_comp, "buoyancy_check_offset_y" )
	end
	return x, y
end

function pen.get_creature_head( entity_id, x, y )
	local ai_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "AnimalAIComponent" )
	if( ai_comp ~= nil ) then
		y = y + ComponentGetValue2( ai_comp, "eye_offset_y" )
	else
		local crouch_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "HotspotComponent", "crouch_sensor" )
		if( crouch_comp ~= nil ) then
			local off_x, off_y = ComponentGetValue2( crouch_comp, "offset" )
			y = y + off_y + 3
		end
	end
	return x, y
end

--[FRONTEND]
function pen.play_sound( event )
	if( not( sound_played )) then
		sound_played = false
		local c_x, c_y = GameGetCameraPos()
		GamePlaySound( "mods/mnee/files/sfx/mnee.bank", event, c_x, c_y )
	end
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

function pen.new_image( gui, uid, pic_x, pic_y, pic_z, pic, s_x, s_y, alpha, interactive )
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
	GuiImage( gui, uid, pic_x, pic_y, pic, alpha, s_x, s_y )
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
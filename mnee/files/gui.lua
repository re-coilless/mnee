local KEYS = mnee.get_bindings()
local profile = pen.setting_get( "mnee.PROFILE" )
local is_disabled = GameHasFlagRun( mnee.TOGGLER )
local key_type = mnee.G.show_alt and "alt" or "main"
if( mnee.G.ctl_panel == nil and mnee.G.jpad_count > 0 ) then
    mnee.G.ctl_panel, mnee.G.stp_panel = true, false
end

local gui = pen.gui_builder()
local frame_num = GameGetFrameNum()
local pic_w, pic_h = GuiGetImageDimensions( gui, "mods/mnee/files/pics/window.png", 1 )
if( mnee.G.pos == nil ) then
    local screen_w, screen_h = GuiGetScreenDimensions( gui )
    mnee.G.pos = { math.floor(( screen_w - pic_w )/2 ), math.floor( screen_h - ( pic_h + 11 ))}
    if( mnee.G.help_active ) then mnee.G.pos_help = { mnee.G.pos[1] - 202, mnee.G.pos[2] + 5 } end
end

local may_rebind = not( GameHasFlagRun( mnee.SERV_MODE ))

local pic_z = pen.LAYERS.BACKGROUND + 5
local pic_x, pic_y = unpack( mnee.G.pos )
local clicked, r_clicked, is_hovered = false, false, false
local gonna_rebind, gonna_update = pen.vld( mnee.G.current_binding ), false
if( not( gonna_rebind )) then
    local txt = GameTextGet( "$mnee_title"..( mnee.G.show_alt and "B" or "A" ))
    if( mnee.G.show_alt ) then pen.new_image( pic_x, pic_y, pic_z + 0.01, "mods/mnee/files/pics/title_bg.png" ) end
    pen.new_text( pic_x + 141, pic_y, pic_z, txt, {
        is_right_x = true, color = pen.PALETTE.PRSP[ mnee.G.show_alt and "BLUE" or "WHITE" ]})
    
    clicked = mnee.new_button( pic_x + pic_w - 8, pic_y + 2, pic_z,
        "mods/mnee/files/pics/key_close.png", {
        auid = "window_close", no_anim = true,
        tip = GameTextGet( "$mnee_close" ), jpad = true,
        highlight = pen.PALETTE.PRSP[ mnee.G.show_alt and "PURPLE" or "WHITE" ]})
    if( clicked ) then
        mnee.G.gui_active = false
        mnee.G.help_active = false
        pen.play_sound( pen.TUNES.PRSP.CLOSE )
    end
    
    clicked = mnee.new_button( pic_x + pic_w - 15, pic_y + 2, pic_z,
        "mods/mnee/files/pics/key_"..( mnee.G.show_alt and "B" or "A" )..".png", {
        auid = "window_alt", jpad = true,
        tip = GameTextGet( "$mnee_alt"..( mnee.G.show_alt and "B" or "A" )),
        highlight = pen.PALETTE.PRSP[ mnee.G.show_alt and "PURPLE" or "WHITE" ]})
    if( clicked ) then mnee.G.show_alt = not( mnee.G.show_alt ); pen.play_sound( pen.TUNES.PRSP.CLICK_ALT ) end
    
    local help_x, help_y = pic_x + 101, pic_y + 99
    if( pen.setting_get( "mnee.FRONTEND" ) == 1 ) then
        local scroller_data = { jpad = true }
        local folded_nodes = pen.t.unarray( pen.t.pack( pen.setting_get( "mnee.FOLDED_NODES" )))
        mnee.new_scroller( "mnee", pic_x + 1, pic_y + 10, pic_z + 0.03, 131, 100, function( scroll_pos )
			local cnt, height, accum = 0, 0, 0
			local got_jpad, is_jpad = {}, false
            pen.t.loop( mnee.mod_sorter( _BINDINGS ), function( i, m )
                cnt = cnt + 1
                
                local is_fancy = _MNEEDATA[i] ~= nil
                if( is_fancy and pen.get_hybrid_function( _MNEEDATA[i].is_hidden, { i, mnee.G.jpad_maps })) then
                    accum = accum + 1; return end
                
                local is_folded = folded_nodes[i] ~= nil
                local pos_y = 1 + scroll_pos[1] + 11*( cnt - ( 1 + accum ))
                local name = pen.magic_translate( is_fancy and _MNEEDATA[i].name or i )
                clicked, _, is_hovered, is_jpad = pen.new_interface(
                    1, pos_y + 1, 129, 7, pic_z, { jpad = "mnee_cat_title_"..i })
                if( is_jpad ) then got_jpad[ is_jpad ] = true end
                pen.uncutter( function( cut_x, cut_y, cut_w, cut_h )
					return mnee.new_tooltip({ name..GameTextGet( "$mnee_fold"..( is_folded and "B" or "A" )), ( is_fancy and pen.vld( _MNEEDATA[i].desc )) and pen.magic_translate( _MNEEDATA[i].desc ) or "" }, { is_active = is_hovered, fid = "mnee_cat_title_"..i })
				end)
                if( clicked ) then
                    pen.play_sound( pen.TUNES.PRSP.SWITCH )
                    folded_nodes[i] = not( is_folded ) and 1 or nil
                    pen.setting_set( "mnee.FOLDED_NODES", pen.t.pack( pen.t.unarray( folded_nodes )))
                end

                local dims = pen.new_text( 3 + 116/2, pos_y, pic_z - 0.01, name, { aggressive = true,
                    dims = {100,0}, is_centered_x = true, color = pen.PALETTE.PRSP[ is_hovered and "RED" or "BLUE" ]})
                pen.new_pixel( 1, pos_y + 6, pic_z + 0.01,
                    pen.PALETTE.PRSP[ is_hovered and "RED" or "PURPLE" ], 129, 2 )
                pen.new_pixel( 1 + ( 116 - dims[1])/2, pos_y,
                    pic_z, pen.PALETTE.PRSP.WHITE, dims[1] + 3, dims[2])
                
                local meta = {}
                if( is_fancy ) then
                    meta.func = _MNEEDATA[i].func
                    meta.is_advanced = _MNEEDATA[i].is_advanced
                    meta.is_locked = pen.get_hybrid_function( _MNEEDATA[i].is_locked, { i, mnee.G.jpad_maps })
                end
                
                if( is_folded ) then
                    pen.new_pixel( 1, pos_y + 3, pic_z + 0.01,
                        pen.PALETTE.PRSP[ is_hovered and "RED" or "PURPLE" ], 129, 2 )
                elseif( meta.func ~= nil ) then
                    local result = pen.try( meta.func, { t_x, t_y, pic_z, { ks = KEYS, k_type = key_type }}) or {}
                    if( result.set_bind ~= nil ) then
                        mnee.G.current_mod = i
                        mnee.G.current_binding = result.set_bind
                        mnee.G.doing_axis = result.will_axis
                        mnee.G.btn_axis_mode = result.btn_axis
                        mnee.G.advanced_mode = result.set_advanced
                    end
                    height = height + ( result.height or 0 )
                else
                    pen.t.loop( mnee.bind_sorter( m ), function( e, b )
                        cnt = cnt + 1

                        if( pen.get_hybrid_function( b.is_hidden, {{ i, e }, mnee.G.jpad_maps })) then
                            accum = accum + 1; return end
                        pos_y = 1 + scroll_pos[1] + 11*( cnt - ( 1 + accum ))
                        if( pos_y < -10 or pos_y > 130 ) then height = height + 11; return end
                        
                        local is_static = b.is_locked
                        if( is_static == nil ) then
                            is_static = meta.is_locked or false
                        else is_static = pen.get_hybrid_function( is_static, {{ i, e }, mnee.G.jpad_maps }) end
                        local is_axis = b.axes ~= nil or mnee.get_pbd( KEYS[i][e])[ key_type ][1] == "is_axis"
                        
                        local name = pen.magic_translate( b.name )
                        clicked, r_clicked, _, is_jpad = mnee.new_button( 2, pos_y, pic_z,
                            "mods/mnee/files/pics/button_116_"..( is_static and "B" or "A" )..".png", {
                            auid = table.concat({ i, "_bind_", name }), no_anim = true, jpad = true,
                            tip = { table.concat({
                                is_axis and ( GameTextGet( "$mnee_axis", b.jpad_type or "EXTRA" )..( is_static and "" or "\n" )) or "",
                                is_static and GameTextGet( "$mnee_static" ).."\n" or "",
                                name, ": ", pen.magic_translate( b.desc ),
                            }), mnee.bind2string( KEYS[i][e], key_type, KEYS[i])..( is_axis and "\n"..GameTextGet( "$mnee_lmb_axis" ) or "" )}})
                        if( is_jpad ) then got_jpad[ is_jpad ] = true end
                        pen.new_text( 3 + 116/2, pos_y, pic_z - 0.01, name, {
                            aggressive = true, dims = {110,0}, is_centered_x = true, color = pen.PALETTE.PRSP[ is_static and "BLUE" or "WHITE" ]})
                        if(( clicked or r_clicked ) and may_rebind ) then
                            if( not( is_static )) then
                                mnee.G.current_mod = i
                                mnee.G.current_binding = e
                                mnee.G.doing_axis = is_axis
                                mnee.G.btn_axis_mode = is_axis and r_clicked
                                pen.play_sound( pen.TUNES.PRSP.SELECT )

                                if( not( b.never_advanced )) then
                                    mnee.G.advanced_mode = b.is_advanced
                                    if( mnee.G.advanced_mode == nil ) then
                                        mnee.G.advanced_mode = meta.is_advanced or false end
                                    mnee.G.advanced_mode = mnee.G.advanced_mode or ( r_clicked and not( is_axis ))
                                else mnee.G.advanced_mode = false end
                            else
                                GamePrint( GameTextGet( "$mnee_error" ).." "..GameTextGet( "$mnee_no_change" ))
                                pen.play_sound( pen.TUNES.PRSP.ERROR )
                            end
                        end
                        
                        clicked, r_clicked, _, is_jpad = mnee.new_button( 119, pos_y, pic_z,
                            "mods/mnee/files/pics/key_delete.png", {
                            auid = table.concat({ i, "_bind_delete_", name }),
                            tip = GameTextGet( "$mnee_rmb_default" ), jpad = true })
                        if( is_jpad ) then got_jpad[ is_jpad ] = true end
                        if( r_clicked ) then
                            if( b.axes ~= nil ) then
                                KEYS[i][ b.axes[1]].keys[ profile ] = nil
                                KEYS[i][ b.axes[2]].keys[ profile ] = nil
                            else KEYS[i][e].keys[ profile ] = nil end
                            pen.play_sound( pen.TUNES.PRSP.RESET )
                            gonna_update = true
                            
                            if( _MNEEDATA[i] ~= nil ) then
                                local func = _MNEEDATA[i].on_changed
                                if( func ~= nil ) then func( _MNEEDATA[i]) end
                                local f = b.on_reset or b.on_changed
                                if( f ~= nil ) then f( b ) end
                            end
                        end

                        height = height + 11
                    end)
                end

				height = height + 11
			end)
            
            if( frame_num%10 == 0 ) then
                local axes = mnee.get_axes()
                for jpad in pairs( got_jpad ) do
                    if( not( scroller_data.go_up )) then
                        scroller_data.go_up = ( axes[ jpad.."gpd_axis_rv" ] or 0 ) < -0.8
                    end
                    if( not( scroller_data.go_down )) then
                        scroller_data.go_down = ( axes[ jpad.."gpd_axis_rv" ] or 0 ) > 0.8
                    end
                end
            end

			return { height + 5, 1 }
		end, scroller_data )

        help_x, help_y = pic_x + 141, pic_y + 33
    else
        pen.new_pixel( pic_x + 46, pic_y + 11, pic_z, pen.PALETTE.PRSP.BLUE, 1, 98 )
        pen.new_pixel( pic_x + 134, pic_y + 11, pic_z, pen.PALETTE.PRSP.BLUE, 1, 98 )

        mnee.G.mod_page = pen.try( mnee.new_pager, { pic_x + 2, pic_y, pic_z, {
            auid = "mod",
            list = _BINDINGS, items_per_page = 8, page = mnee.G.mod_page,
            func = function( x, y, z, i,v,k, is_hidden )
                local is_fancy = _MNEEDATA[i] ~= nil
                if( is_fancy and pen.get_hybrid_function( _MNEEDATA[i].is_hidden, { i, mnee.G.jpad_maps })) then
                    return true
                elseif( is_hidden ) then return false end
                
                local t_x, t_y = x, y + k*11
                local is_current = mnee.G.current_mod == i
                local name = pen.magic_translate( is_fancy and _MNEEDATA[i].name or i )
                clicked = mnee.new_button( t_x, t_y, pic_z,
                    "mods/mnee/files/pics/button_43_"..( is_current and "B" or "A" )..".png", {
                    auid = table.concat({ "mod_", name }), jpad = true,
                    tip = { name, is_current and (( is_fancy and _MNEEDATA[i].desc ~= nil ) and pen.magic_translate( _MNEEDATA[i].desc ) or "" ) or GameTextGet( "$mnee_lmb_keys" )}})
                pen.new_text( t_x + 43/2, t_y, pic_z - 0.01, name, {
                    dims = {39,0}, is_centered_x = true, color = pen.PALETTE.PRSP[ is_current and "RED" or "WHITE" ]})
                if( clicked ) then mnee.G.binding_page, mnee.G.current_mod = 1, i; pen.play_sound( pen.TUNES.PRSP.CLICK_ALT ) end
            end, order_func = mnee.mod_sorter,
        }}, function( log, pic_x, pic_y )
            pen.new_shadowed_text( mnee.G.pos[1], mnee.G.pos[2] - 11, pen.LAYERS.DEBUG,
                mnee.G.m_list, { color = pen.PALETTE.PRSP.RED, color_shadow = pen.PALETTE.PRSP.BLUE })
            pen.new_shadowed_text( pic_x, pic_y, pen.LAYERS.DEBUG, log, {
                color = pen.PALETTE.PRSP.RED, color_shadow = pen.PALETTE.PRSP.BLUE, dims = { 130, -1 }})
        end) or 1
        
        local meta = {}
        if( _MNEEDATA[ mnee.G.current_mod ] ~= nil ) then
            meta.func = _MNEEDATA[ mnee.G.current_mod ].func
            meta.is_advanced = _MNEEDATA[ mnee.G.current_mod ].is_advanced or false
            meta.is_locked = pen.get_hybrid_function(
                _MNEEDATA[ mnee.G.current_mod ].is_locked, { mnee.G.current_mod, mnee.G.jpad_maps }) or false
        end
        
        if( meta.func ~= nil ) then
            local result = pen.try( meta.func, { t_x, t_y, pic_z, {
                ks = KEYS,
                k_type = key_type,
            }}) or false
            if( result ) then
                mnee.G.current_binding = result.set_bind
                mnee.G.doing_axis = result.will_axis
                mnee.G.btn_axis_mode = result.btn_axis
                mnee.G.advanced_mode = result.set_advanced
            end
        else
            mnee.G.binding_page = pen.try( mnee.new_pager, { pic_x + 48, pic_y, pic_z, {
                auid = "bind",
                list = _BINDINGS[ mnee.G.current_mod ], items_per_page = 8, page = mnee.G.binding_page,
                func = function( pic_x, pic_y, pic_z, i,v,k, is_hidden )
                    if( pen.get_hybrid_function( v.is_hidden, {{ mnee.G.current_mod, i }, mnee.G.jpad_maps })) then
                        return true
                    elseif( is_hidden ) then return false end

                    local is_static = v.is_locked
                    if( is_static == nil ) then
                        is_static = meta.is_locked or false
                    else is_static = pen.get_hybrid_function( is_static, {{ mnee.G.current_mod, i }, mnee.G.jpad_maps }) end
                    local is_axis = v.axes ~= nil or mnee.get_pbd( KEYS[ mnee.G.current_mod ][i])[ key_type ][1] == "is_axis"
                    
                    local t_x, t_y = pic_x, pic_y + k*11
                    local name = pen.magic_translate( v.name )
                    clicked, r_clicked = mnee.new_button( t_x, t_y, pic_z,
                        "mods/mnee/files/pics/button_74_"..( is_static and "B" or "A" )..".png", {
                        auid = table.concat({ mnee.G.current_mod, "_bind_", name }), no_anim = true, jpad = true,
                        tip = { table.concat({
                            is_axis and ( GameTextGet( "$mnee_axis", v.jpad_type or "EXTRA" )..( is_static and "" or "\n" )) or "",
                            is_static and GameTextGet( "$mnee_static" ).."\n" or "",
                            name, ": ", pen.magic_translate( v.desc ),
                        }), mnee.bind2string( KEYS[ mnee.G.current_mod ][i], key_type, KEYS[ mnee.G.current_mod ])..( is_axis and "\n"..GameTextGet( "$mnee_lmb_axis" ) or "" )}})
                    pen.new_text( t_x + 74/2, t_y, pic_z - 0.01, name, {
                        aggressive = true, dims = {70,0}, is_centered_x = true, color = pen.PALETTE.PRSP[ is_static and "BLUE" or "WHITE" ]})
                    if(( clicked or r_clicked ) and may_rebind ) then
                        if( not( is_static )) then
                            mnee.G.current_binding = i
                            mnee.G.doing_axis = is_axis
                            mnee.G.btn_axis_mode = is_axis and r_clicked
                            pen.play_sound( pen.TUNES.PRSP.SELECT )
                            
                            if( not( v.never_advanced )) then
                                mnee.G.advanced_mode = v.is_advanced
                                if( mnee.G.advanced_mode == nil ) then mnee.G.advanced_mode = meta.is_advanced or false end
                                mnee.G.advanced_mode = mnee.G.advanced_mode or ( r_clicked and not( is_axis ))
                            else mnee.G.advanced_mode = false end
                        else
                            GamePrint( GameTextGet( "$mnee_error" ).." "..GameTextGet( "$mnee_no_change" ))
                            pen.play_sound( pen.TUNES.PRSP.ERROR )
                        end
                    end
                    
                    clicked, r_clicked = mnee.new_button( t_x + 75, t_y, pic_z,
                        "mods/mnee/files/pics/key_delete.png", {
                        auid = table.concat({ mnee.G.current_mod, "_bind_delete_", name }),
                        tip = GameTextGet( "$mnee_rmb_default" ), jpad = true })
                    if( r_clicked ) then
                        if( v.axes ~= nil ) then
                            KEYS[ mnee.G.current_mod ][ v.axes[1]].keys[ profile ] = nil
                            KEYS[ mnee.G.current_mod ][ v.axes[2]].keys[ profile ] = nil
                        else KEYS[ mnee.G.current_mod ][ i ].keys[ profile ] = nil end
                        pen.play_sound( pen.TUNES.PRSP.RESET )
                        gonna_update = true
                        
                        if( _MNEEDATA[ mnee.G.current_mod ] ~= nil ) then
                            local func = _MNEEDATA[ mnee.G.current_mod ].on_changed
                            if( func ~= nil ) then func( _MNEEDATA[ mnee.G.current_mod ]) end
                            local f = v.on_reset or v.on_changed
                            if( f ~= nil ) then f( v ) end
                        end
                    end
                end, order_func = mnee.bind_sorter,
            }}, function( log, pic_x, pic_y )
                pen.new_shadowed_text( mnee.G.pos[1], mnee.G.pos[2] - 11, pen.LAYERS.DEBUG,
                    mnee.G.m_list, { color = pen.PALETTE.PRSP.RED, color_shadow = pen.PALETTE.PRSP.BLUE })
                pen.new_shadowed_text( pic_x, pic_y, pen.LAYERS.DEBUG, log, {
                    color = pen.PALETTE.PRSP.RED, color_shadow = pen.PALETTE.PRSP.BLUE, dims = { 130, -1 }})
            end) or 1
        end
        
        clicked, r_clicked = mnee.new_button( pic_x + 112, pic_y + 99, pic_z,
            "mods/mnee/files/pics/button_21_A.png", {
            auid = "mod_reset", jpad = true,
            tip = GameTextGet( "$mnee_rmb_mod" )})
        pen.new_text( pic_x + 123, pic_y + 99, pic_z - 0.01, "DFT", {
            dims = {-17,0}, is_centered_x = true, color = pen.PALETTE.PRSP.WHITE })
        if( r_clicked ) then
            for bind,bind_tbl in pairs( KEYS[ mnee.G.current_mod ]) do
                if( bind_tbl.axes == nil ) then KEYS[ mnee.G.current_mod ][ bind ].keys[ profile ] = nil end
            end
            pen.play_sound( pen.TUNES.PRSP.RESET )
            gonna_update = true
            
            if( _MNEEDATA[ mnee.G.current_mod ] ~= nil ) then
                local func = _MNEEDATA[ mnee.G.current_mod ].on_reset or _MNEEDATA[ mnee.G.current_mod ].on_changed
                if( func ~= nil ) then func( _MNEEDATA[ mnee.G.current_mod ]) end
                for i,v in mnee.bind_sorter( KEYS[ mnee.G.current_mod ]) do
                    local f = v.on_reset or v.on_changed
                    if( f ~= nil ) then f( v ) end
                end
            end
        end
    end

    clicked = mnee.new_button( help_x, help_y, pic_z,
        "mods/mnee/files/pics/help.png", {
        auid = "help_main", jpad = true,
        tip = { table.concat({
            GameTextGet( "$mnee_lmb_bind" ),
            "\n", GameTextGet( "$mnee_rmb_advanced" ),
        }), GameTextGet( "$mnee_alt_help" ) },
        highlight = pen.PALETTE.PRSP.PURPLE,
    })
    if( clicked ) then
        pen.play_sound( pen.TUNES.PRSP[ mnee.G.help_active and "CLOSE" or "OPEN" ])
        mnee.G.help_active = not( mnee.G.help_active )
        mnee.G.pos_help = { mnee.G.pos[1] - 202, mnee.G.pos[2] + 5 }
        if( mnee.G.help_active ) then pen.atimer( "help_window", nil, true ) end
    end
    
    clicked = mnee.new_button( pic_x + 136, pic_y + 11, pic_z,
        "mods/mnee/files/pics/button_21_"..( is_disabled and "A" or "B" )..".png", {
        auid = "main_toggle", jpad = true,
        tip = GameTextGet( "$mnee_lmb_input"..( is_disabled and "A" or "B" ))})
    pen.new_text( pic_x + 146.5, pic_y + 11, pic_z - 0.01, "TGL", {
        dims = {-17,0}, is_centered_x = true, color = pen.PALETTE.PRSP[ is_disabled and "WHITE" or "RED" ]})
    if( clicked ) then
        if( is_disabled ) then
            GameRemoveFlagRun( mnee.TOGGLER ); pen.play_sound( pen.TUNES.PRSP.PICK )
        else GameAddFlagRun( mnee.TOGGLER ); pen.play_sound( pen.TUNES.PRSP.DROP ) end
    end
    
    clicked, r_clicked = mnee.new_button( pic_x + 136, pic_y + 22, pic_z,
        "mods/mnee/files/pics/button_21_A.png", {
        auid = "full_reset", jpad = true, tip = GameTextGet( "$mnee_rmb_reset" )})
    pen.new_text( pic_x + 147, pic_y + 22, pic_z - 0.01, "RST", {
        dims = {-17,0}, is_centered_x = true, color = pen.PALETTE.PRSP.WHITE })
    if( r_clicked ) then
        pen.play_sound( pen.TUNES.PRSP.DELETE )
        pen.setting_set( "mnee.SETUP", "" )
        pen.setting_set( "mnee.PROFILE", 2 )
        pen.setting_set( "mnee.BINDINGS", "" )
        GlobalsSetValue( mnee.UPDATER, frame_num )
    end

    if( _MNEEDATA[ mnee.G.current_mod ] ~= nil and _MNEEDATA[ mnee.G.current_mod ].setup_modes ~= nil ) then
        clicked = mnee.new_button( pic_x + 136, pic_y + 66, pic_z,
            "mods/mnee/files/pics/button_21_"..( mnee.G.stp_panel and "B" or "A" )..".png", {
            auid = "setup_toggle", jpad = true, tip = GameTextGet( "$mnee_lmb_setups" )})
        pen.new_text( pic_x + 147, pic_y + 66, pic_z - 0.01, "STP", {
            dims = {-17,0}, is_centered_x = true, color = pen.PALETTE.PRSP[ mnee.G.stp_panel and "RED" or "WHITE" ]})
        if( clicked ) then
            pen.play_sound( pen.TUNES.PRSP[ mnee.G.stp_panel and "CLOSE" or "OPEN" ])
            if( mnee.G.ctl_panel ) then mnee.G.ctl_panel = false end
            mnee.G.stp_panel = not( mnee.G.stp_panel )
            if( mnee.G.stp_panel ) then pen.atimer( "stp_window", nil, true ) end
        end
    elseif( mnee.G.stp_panel ) then mnee.G.stp_panel = false end

    clicked = mnee.new_button( pic_x + 136, pic_y + 77, pic_z,
        "mods/mnee/files/pics/button_21_"..( mnee.G.ctl_panel and "B" or "A" )..".png", {
        auid = "ctrl_toggle", jpad = true, tip = GameTextGet( "$mnee_lmb_jpads" )})
    pen.new_text( pic_x + 146.5, pic_y + 77, pic_z - 0.01, "CTL", {
        dims = {-17,0}, is_centered_x = true, color = pen.PALETTE.PRSP[ mnee.G.ctl_panel and "RED" or "WHITE" ]})
    if( clicked ) then
        pen.play_sound( pen.TUNES.PRSP[ mnee.G.ctl_panel and "CLOSE" or "OPEN" ])
        if( mnee.G.stp_panel ) then mnee.G.stp_panel = false end
        mnee.G.ctl_panel = not( mnee.G.ctl_panel )
        if( mnee.G.ctl_panel ) then pen.atimer( "ctl_window", nil, true ) end
    end
    
    local new_profile = mnee.new_pager( pic_x + 136, pic_y - 11, pic_z, {
        auid = "profile", compact_mode = true, profile_mode = true, page = profile, list = mnee.G.max_profiles })
    if( profile ~= new_profile ) then pen.setting_set( "mnee.PROFILE", new_profile ) end
    
    local w_anim = {
        5*( 1 - pen.animate( 1, "main_window", { ease_out = "wav1", frames = 15, stillborn = true }))/pic_w,
        4*( 1 - pen.animate( 1, "main_window", { ease_out = "wav", frames = 15, stillborn = true }))/pic_h }
    if( w_anim[1] > 0 ) then pen.atimer( "ctl_window", nil, true ); pen.atimer( "stp_window", nil, true ) end
    
    if( mnee.G.stp_panel ) then
        local setup_memo = mnee.get_setup_memo()
        local t_x = pic_x + pen.animate({ 130, 160 }, "stp_window", { ease_in = "sin3", frames = 10, stillborn = true })
        if( t_x < pic_x + 140 ) then goto continue end

        if( not( _MNEEDATA[ mnee.G.current_mod ].setup_modes[1].dft )) then
            table.insert( _MNEEDATA[ mnee.G.current_mod ].setup_modes, 1, _MNEEDATA[ mnee.G.current_mod ].setup_default or {
                name = "$mnee_default",
                desc = "$mnee_default_desc",
            })
            _MNEEDATA[ mnee.G.current_mod ].setup_modes[1].id = "_dft"
            _MNEEDATA[ mnee.G.current_mod ].setup_modes[1].dft = true
        end
        
        mnee.G.setup_page = pen.try( mnee.new_pager, { t_x, pic_y - 11, pic_z + 0.08, {
            auid = "setup", compact_mode = true,
            list = _MNEEDATA[ mnee.G.current_mod ].setup_modes or {}, items_per_page = 5, page = mnee.G.setup_page,
            func = function( pic_x, pic_y, pic_z, i,v,k, is_hidden )
                if( is_hidden ) then return end

                pic_y = pic_y + ( k + 3 )*11
                local name = pen.magic_translate( v.name )
                local is_going = ( setup_memo[ profile ] or setup_memo[1])[ mnee.G.current_mod ] == v.id
                clicked = mnee.new_button( pic_x, pic_y, pic_z,
                    "mods/mnee/files/pics/button_21_"..( is_going and "B" or "A" )..".png", {
                    auid = table.concat({ mnee.G.current_mod, "_setup_", name }), jpad = true,
                    tip = { name..GameTextGet( "$mnee_setup_warning" ), pen.magic_translate( v.desc )}})
                pen.new_text( pic_x + 21/2, pic_y, pic_z - 0.01, string.upper( string.sub( v.btn or v.id, 1, 3 )), {
                    dims = {17,0}, is_centered_x = true, color = pen.PALETTE.PRSP[ is_going and "RED" or "WHITE" ]})
                if( clicked ) then
                    mnee.set_setup_id( mnee.G.current_mod, v.id )
                    for bind,bind_tbl in pairs( KEYS[ mnee.G.current_mod ]) do
                        if( bind_tbl.axes == nil ) then KEYS[ mnee.G.current_mod ][ bind ].keys[ profile ] = nil end
                    end
                    pen.play_sound( pen.TUNES.PRSP.SWITCH )
                    gonna_update = true
                end

                return c
            end,
        }}, function( log, pic_x, pic_y )
            pen.new_shadowed_text( mnee.G.pos[1], mnee.G.pos[2] - 11, pen.LAYERS.DEBUG,
                mnee.G.m_list, { color = pen.PALETTE.PRSP.RED, color_shadow = pen.PALETTE.PRSP.BLUE })
            pen.new_shadowed_text( pic_x, pic_y, pen.LAYERS.DEBUG, log, {
                color = pen.PALETTE.PRSP.RED, color_shadow = pen.PALETTE.PRSP.BLUE, dims = { 130, -1 }})
        end)

        pen.new_image( t_x - 10, pic_y + 31, pic_z + 1, "mods/mnee/files/pics/setup_panel.png", { can_click = true })
    elseif( mnee.G.ctl_panel ) then
        local t_x = pic_x + pen.animate({ 130, 160 }, "ctl_window", { ease_in = "sin3", frames = 10, stillborn = true })
        local t_y, is_real = pic_y + 55, false
        if( t_x < pic_x + 140 ) then goto continue end
        
        pen.new_image( t_x - 1, pic_y + 54, pic_z + 0.07, "mods/mnee/files/pics/scan.xml", {
            anim = mnee.stl.jauto and "scan" or "idle" }) --thanks Horscht
        clicked, r_clicked = mnee.new_button( t_x, t_y, pic_z + 0.07,
            "mods/mnee/files/pics/scan_hitbox.png", { jpad = true,
            auid = "automap_toggle", no_anim = true, highlight = false,
            tip = { GameTextGet( "$mnee_jpad_count", mnee.G.jpad_count ),
                GameTextGet( "$mnee_rmb_scan"..( mnee.stl.jauto and "B" or "A" ))}})  
        if( r_clicked ) then
            pen.setting_set( "mnee.CTRL_AUTOMAPPING", not( mnee.stl.jauto ))
            pen.play_sound( pen.TUNES.PRSP.CLICK_ALT )
        end
        
        for i = 1,4 do
            is_real = mnee.G.jpad_maps[i]
            clicked, r_clicked = mnee.new_button( t_x, t_y + 11*i, pic_z + 0.08,
                "mods/mnee/files/pics/button_10_"..( is_real ~= -1 and "B" or "A" )..".png", {
                auid = table.concat({ "ctrl_", i }), jpad = true,
                tip = is_real ~= -1 and {
                        GameTextGet( "$mnee_jpad_id" )..( is_real > 4 and GameTextGet( "$mnee_dummy" ) or tostring( is_real )), GameTextGet( "$mnee_lmb_unmap" )
                    } or table.concat({
                        GameTextGet( "$mnee_lmb_map" ), "\n", GameTextGet( "$mnee_rmb_dummy" )
                })})
            pen.new_text( t_x + 10/2, t_y + 11*i, pic_z + 0.07, i, {
                dims = {10,0}, is_centered_x = true,
                color = pen.PALETTE.PRSP[ is_real ~= -1 and ( is_real > 4 and "BLUE" or "RED" ) or "WHITE" ]})
            if( clicked ) then
                if( mnee.G.jpad_count > 0 or mnee.G.jpad_maps[i] > 4 ) then
                    if( is_real ~= -1 ) then
                        mnee.jpad_update( -i )
                        pen.play_sound( pen.TUNES.PRSP.DELETE )
                    else mnee.stl.jslots[i] = true end

                    if( mnee.stl.jauto ) then
                        pen.setting_set( "mnee.CTRL_AUTOMAPPING", false )
                        AddFlagPersistent( mnee.AMAP_MEMO )
                        mnee.stl.jauto = false
                    end
                else
                    GamePrint( GameTextGet( "$mnee_no_jpads" ))
                    pen.play_sound( pen.TUNES.PRSP.ERROR )
                end
            end
            if( is_real == -1 and r_clicked ) then
                mnee.G.jpad_maps[i] = 5
                pen.play_sound( pen.TUNES.PRSP.SELECT )
            end
        end
        
        pen.new_image( t_x - 10, t_y - 2, pic_z + 1, "mods/mnee/files/pics/controller_panel.png", { can_click = true })
    end; ::continue::
    
    mnee.G.pos[1], mnee.G.pos[2] = pen.new_dragger(
        "mnee_window", pic_x, pic_y, 142, 9, nil, { jpad_vip = true })
    pen.new_image( pic_x + w_anim[1]*pic_w/2, pic_y + w_anim[2]*pic_h/2, pic_z + 0.05,
        "mods/mnee/files/pics/window.png", { s_x = 1 - w_anim[1], s_y = 1 - w_anim[2], can_click = true })
    
    if( GameHasFlagRun( mnee.RETOGGLER )) then
        GameRemoveFlagRun( mnee.RETOGGLER )
        GameRemoveFlagRun( mnee.SERV_MODE )
    end
else
    if( not( GameHasFlagRun( mnee.RETOGGLER ))) then
        GameAddFlagRun( mnee.SERV_MODE )
        GameAddFlagRun( mnee.RETOGGLER )
    end
    
    local active = {}
    local tip_text = "["
    local enter_down, active_down = false, false
    local this_bind = KEYS[ mnee.G.current_mod ][ mnee.G.current_binding ]
    local doing_axis = mnee.G.doing_axis and not( mnee.G.btn_axis_mode )
    if( not( doing_axis )) then active = mnee.get_keys( "guied" ) end
    if( pen.vld( active ) and mnee.G.advanced_mode ) then
        local _is_weak = this_bind.is_weak
        local _is_dirty = not( this_bind.is_clean )
        local _twin_nmpd = this_bind.unify_numpad
        local _twin_spec = not( this_bind.split_modifiers )

        tip_text = table.concat({ tip_text, pen.t.loop_concat( active, function( i, key )
            if( string.find( key, "_gui$" ) ~= nil ) then return end
            if( string.find( key, "_gui_$" ) ~= nil ) then return end
            if( string.find( key, "gpd_r3$" ) ~= nil ) then return end

            active_down = true
            if( key == "return" ) then
                enter_down = true
            else return {( i == 1 and "" or "; " ), key } end
        end), "]", pen.t.loop_concat( pen.t.unarray( KEYS ), function( _,mt )
            local mod, mod_tbl = unpack( mt )
            return pen.t.loop_concat( pen.t.unarray( mod_tbl ), function( _,bt )
                local bind, bind_tbl = unpack( bt )
                local data = ( _BINDINGS[ mod ] or {})[ bind ] or {}
                if( data.name == nil ) then return end
                
                local is_hidden = pen.get_hybrid_function( data.is_hidden, {{ mod, bind }, mnee.G.jpad_maps })
                if( is_hidden == nil and _MNEEDATA[ mod ] ~= nil ) then
                    is_hidden = pen.get_hybrid_function( _MNEEDATA[ mod ].is_hidden, { mod, mnee.G.jpad_maps })
                end
                if( is_hidden ) then return end

                local is_weak = data.is_weak
                local is_dirty = not( data.is_clean )
                local twin_nmpd = _twin_nmpd or data.unify_numpad
                local twin_spec = _twin_spec or not( data.split_modifiers )
                return ( pen.t.loop({ "main", "alt" }, function( _,tp )
                    local b = mnee.get_pbd( bind_tbl )[ tp ]
                    if( not( pen.vld( b ))) then return end

                    local score = pen.t.count( b ) - 1
                    for e,key in ipairs( active ) do
                        if( is_weak and mnee.SPECIAL_KEYS[ key ] ~= nil ) then return end
                        if( b[ key ] ~= nil or b[ mnee.get_twin_key( key, twin_spec, twin_nmpd )] ~= nil ) then
                            if( _is_weak and mnee.SPECIAL_KEYS[ key ] ~= nil ) then return else score = score - 1 end
                        elseif( not( is_dirty )) then return end
                    end

                    if( score < 0 ) then return true end
                    if( pen.t.count( b ) - ( score + 1 ) >= #active ) then return true end
                end) or false ) and {
                    "\n", GameTextGet( "$mnee_conflict" ),
                    "{>color>{{-}|PRSP|RED|{-}[", mod, "; ", pen.magic_translate( data.name ), "]}<color<}"
                } or nil
            end)
        end)})
    elseif( pen.vld( active )) then
        local allow_special = this_bind.allow_special
        tip_text = table.concat({ tip_text, pen.t.loop_concat( active, function( i, key )
            if( string.find( key, "_gui$" ) ~= nil or string.find( key, "_gui_$" ) ~= nil ) then return end
            if( not( allow_special ) and mnee.SPECIAL_KEYS[ key ] ~= nil ) then return end
            if( string.find( key, "gpd_r3$" ) ~= nil ) then return end
            enter_down = true
            return key
        end), "]" })
    end

    local is_stick = this_bind.axes ~= nil
    if( mnee.G.gui_retoggler or not( mnee.G.purge_pass )) then
        local function is_jpad_static()
            for ax,v in pairs( mnee.get_axes()) do
                if( v ~= 0 ) then return false end
            end
            return true
        end

        pen.new_image( pic_x, pic_y, pic_z + 0.05, "mods/mnee/files/pics/continue.png", { can_click = true })
        mnee.new_tooltip( GameTextGet( "$mnee_doit" ))
        if( not( mnee.G.purge_pass )) then
            mnee.G.purge_pass = #active == 0 and is_jpad_static()
        elseif( #active == 0 and is_jpad_static()) then
            if(( mnee.G.btn_axis_counter or 4 ) >= (( is_stick and not( doing_axis )) and 4 or 2 )) then
                mnee.G.current_binding = ""
                mnee.G.doing_axis = false
                mnee.G.btn_axis_mode = false
                mnee.G.btn_axis_counter = nil
                mnee.G.advanced_mode = false
            else mnee.G.btn_axis_counter = mnee.G.btn_axis_counter + 1 end

            mnee.G.purge_pass = nil
            mnee.G.gui_retoggler = false
            pen.play_sound( pen.TUNES.PRSP.CONFIRM )
        end
    else
        local help_tip = GameTextGet( "$mnee_binding_"..( doing_axis and "axis" or ( mnee.G.advanced_mode and "advanced" or "simple" )))
        if( not( mnee.G.advanced_mode or doing_axis )) then help_tip = help_tip..GameTextGet( "$mnee_binding_simple_"..(( _BINDINGS[ mnee.G.current_mod ][ mnee.G.current_binding ].allow_special or false ) and "a" or "b" )) end
        clicked = mnee.new_button( pic_x + 3, pic_y + 71, pic_z,
            "mods/mnee/files/pics/help.png", {
            auid = "help_rebinding", jpad = true,
            tip = help_tip, min_width = 500,
            highlight = pen.PALETTE.PRSP.PURPLE,
        })
        if( clicked ) then
            pen.play_sound( pen.TUNES.PRSP[ mnee.G.help_active and "CLOSE" or "OPEN" ])
            mnee.G.help_active = not( mnee.G.help_active )
            mnee.G.pos_help = { mnee.G.pos[1] - 202, mnee.G.pos[2] + 5 }
            if( mnee.G.help_active ) then pen.atimer( "help_window", nil, true ) end
        end
        
        local c_bind = mnee.G.current_binding
        if( is_stick ) then
            mnee.G.btn_axis_counter = mnee.G.btn_axis_counter or 1
            c_bind = KEYS[ mnee.G.current_mod ][ c_bind ].axes[( mnee.G.btn_axis_counter - 1 )%2 + 1 ]
            
            local anim = ( math.sin( math.floor( frame_num/10 )%60 ) - 1 )/2
            local offs = {{-1,0,90,-1},{0,-1,0,1},{1,0,90,1},{0,-1,180,1}}
            local off = offs[ mnee.G.btn_axis_counter ]
            for i = 1,2 do
                local angle = math.rad( off[3])
                local off_x, off_y = pen.rotate_offset( -8, -off[4]*8, angle )
                local do_shift = ( i == 1 and mnee.G.btn_axis_counter == 1 ) or ( i == 2 and mnee.G.btn_axis_counter == 3 )
                off_x, off_y = off_x + 2*anim*off[1] + ( do_shift and off[1] or 0 ), off_y + 2*anim*off[2]
                pen.new_image( pic_x + ( i == 1 and 12 or 147 ) + off_x, pic_y + 35 + off_y, pic_z,
                    "mods/mnee/files/pics/arrow.png", { s_x = 1, s_y = off[4], angle = angle })
            end
        end

        local nuke_em, b = false, mnee.get_pbd( KEYS[ mnee.G.current_mod ][ c_bind ])
        local doing_swap = not( mnee.G.show_alt ) and ((( doing_axis or mnee.G.btn_axis_mode ) and b.alt[2] ~= "_" ) or ( b.alt[ "_" ] == nil ))
        if( not( mnee.G.btn_axis_mode )) then
            clicked, r_clicked = mnee.new_button( pic_x + 146, pic_y + 71, pic_z,
                "mods/mnee/files/pics/key_unbind.png", {
                auid = "unbind", no_anim = true, jpad = true,
                tip = GameTextGet( "$mnee_lmb_unbind" )..( doing_swap and "\n"..GameTextGet( "$mnee_rmb_unbind" ) or "" ),
                highlight = pen.PALETTE.PRSP.PURPLE })
            if( clicked ) then
                nuke_em = true
            elseif( doing_swap and r_clicked ) then
                nuke_em = 1
            end
        end
        
        if( mnee.G.advanced_mode ) then
            if( active_down ) then
                mnee.G.advanced_timer = mnee.G.advanced_timer + 1
                pen.new_text( pic_x + 79.5, pic_y + 73, pic_z, math.ceil(( 300 - mnee.G.advanced_timer )/60 ), {
                    is_centered_x = true, color = pen.PALETTE.PRSP.RED })
                if( mnee.G.advanced_timer >= 300 ) then enter_down, mnee.G.advanced_timer = true, 0 end
            else mnee.G.advanced_timer = 0 end
        elseif( doing_axis and mnee.G.jpad_count == 0 ) then
            pen.new_text( pic_x + 79.5, pic_y + 73, pic_z,
                table.concat({ "{>quake>{", GameTextGet( "$mnee_no_jpads" ), "}<quake<}" }),
                { fully_featured = true, is_centered_x = true, color = pen.PALETTE.PRSP.BLUE })
        end
        
        local is_jpad = false
        clicked, r_clicked, is_hovered, is_jpad = pen.new_image( pic_x, pic_y, pic_z + 0.05,
            "mods/mnee/files/pics/rebinder"..( doing_axis and "_axis" or ( mnee.G.advanced_mode and "" or "_simple" ))..".png", { can_click = true, jpad = { "mnee_rebinder", true }})
        mnee.new_tooltip( doing_axis and GameTextGet( "$mnee_waiting" ) or { GameTextGet( "$mnee_keys" )..( #tip_text < 3 and GameTextGet( "$mnee_nil" ) or tip_text ), GameTextGet( "$mnee_rmb_cancel" )}, { fully_featured = true, is_active = true, pos = not( is_hovered or is_jpad ) and { pic_x + pic_w + 1, pic_y } or nil })
        if( r_clicked ) then
            mnee.G.current_binding = ""
            mnee.G.doing_axis = false
            mnee.G.btn_axis_mode = false
            mnee.G.advanced_mode = false
            mnee.G.purge_pass = nil
            pen.play_sound( pen.TUNES.PRSP.ERROR )
            return
        end
        
        local changed = true
        local this_b = pen.t.clone( KEYS[ mnee.G.current_mod ][ c_bind ])
        this_b = pen.t.clone( this_b.keys[ profile ] or this_b.keys[1])
        if( nuke_em ) then
            local k_type = key_type
            if( doing_swap ) then
                if( nuke_em ~= 1 ) then this_b.main = this_b.alt end
                k_type = "alt"
            end
            if( not( doing_axis )) then
                local new_bind = {}
                if( mnee.G.btn_axis_mode ) then
                    new_bind = pen.t.clone( this_b[ k_type ])
                    new_bind[ 2 ] = "_"
                    new_bind[ 3 ] = "_"
                    mnee.G.btn_axis_counter = ( mnee.G.btn_axis_counter or 1 ) + 1
                else new_bind[ "_" ] = 1 end
                this_b[ k_type ] = new_bind
            else this_b[ k_type ] = { "is_axis", "_", } end
            if( nuke_em == 1 ) then this_b.main = this_b.alt end
            mnee.G.gui_retoggler = true
            pen.play_sound( pen.TUNES.PRSP.DELETE )
        elseif( doing_axis ) then
            local champ = { 0, 0 }
            for ax,v in pairs( mnee.get_axes()) do
                if( math.abs( v ) > 0.8 ) then
                    champ = math.abs( champ[2]) < math.abs( v ) and { ax, v, } or champ
                end
            end
            if( champ[1] ~= 0 ) then
                this_b[ key_type ] = { "is_axis", champ[1]}
                mnee.G.gui_retoggler = true
                pen.play_sound( pen.TUNES.PRSP.SWITCH_ALT )
            end
        elseif( enter_down ) then
            changed = false

            local new_bind = {}
            pen.t.loop( active, function( i, key )
                if( key == "return" ) then return end
                if( string.find( key, "_gui$" ) ~= nil ) then return end
                if( string.find( key, "_gui_$" ) ~= nil ) then return end
                if( string.find( key, "gpd_r3$" ) ~= nil ) then return end

                changed = true
                if( mnee.G.btn_axis_mode ) then
                    new_bind = pen.t.clone( this_b[ key_type ])
                    mnee.G.btn_axis_counter = mnee.G.btn_axis_counter or 1
                    local btn_id = is_stick and ( mnee.G.btn_axis_counter > 2 and 3 or 2 ) or (( mnee.G.btn_axis_counter - 1 )%2 + 2 )
                    new_bind[ btn_id ] = key
                    return true
                else
                    new_bind[ key ] = 1
                    if( not( mnee.G.advanced_mode )) then return true end
                end
            end)

            if( changed ) then
                this_b[ key_type ] = new_bind
                mnee.G.gui_retoggler = true
                pen.play_sound( pen.TUNES.PRSP.SWITCH_ALT )
            end
        end
        
        if( mnee.G.gui_retoggler ) then
            if( changed ) then
                KEYS[ mnee.G.current_mod ][ c_bind ].keys[ profile ] = pen.t.clone( this_b )
                gonna_update = true
            end
            if( _MNEEDATA[ mnee.G.current_mod ] ~= nil and _MNEEDATA[ mnee.G.current_mod ].on_changed ~= nil ) then
                _MNEEDATA[ mnee.G.current_mod ].on_changed( _MNEEDATA[ mnee.G.current_mod ])
            end
            if( KEYS[ mnee.G.current_mod ][ c_bind ].on_changed ~= nil ) then
                KEYS[ mnee.G.current_mod ][ c_bind ].on_changed( KEYS[ mnee.G.current_mod ][ c_bind ])
            end
        end
    end
end

if( gonna_update ) then mnee.update_bindings( KEYS ) end
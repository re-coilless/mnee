--make sure that all resetting business is done per-profile
--main window frame opening bounce anim + side bars opening anims (call pen.atimer( auid, nil, true ) to init it)
--add anim ids

local KEYS = mnee.get_bindings()
local profile = pen.setting_get( "mnee.PROFILE" )
local is_disabled = GameHasFlagRun( mnee.TOGGLER )
local key_type = mnee.G.show_alt and "alt" or "main"
if( mnee.G.ctl_panel == nil and mnee.G.jpad_count > 0 ) then
    mnee.G.ctl_panel, mnee.G.stp_panel = true, false
end

local gui = mnee.G.UI
local pic_w, pic_h = GuiGetImageDimensions( gui, "mods/mnee/files/pics/window.png", 1 )
if( mnee.G.pos == nil ) then
    local screen_w, screen_h = GuiGetScreenDimensions( gui )
    mnee.G.pos = {( screen_w - pic_w )/2, screen_h - ( pic_h + 10 )}
end

local uid, pic_z = 0, -50
local clicked, r_clicked = false, false
local pic_x, pic_y = unpack( mnee.G.pos )
local gonna_rebind = pen.vld( mnee.G.current_binding )
if( not( gonna_rebind )) then
    local txt = GameTextGetTranslatedOrNot( "$mnee_title"..( mnee.G.show_alt and "B" or "A" ))
    if( mnee.G.show_alt ) then uid = pen.new_image( gui, uid, pic_x, pic_y, pic_z + 0.001, "mods/mnee/files/pics/title_bg.png" ) end
    uid = pen.new_text( gui, uid, pic_x + 142, pic_y, pic_z, txt, {
        is_right_x = true, color = pen.PALETTE.PRSP[ mnee.G.show_alt and "BLUE" or "WHITE" ]})
    
    uid, clicked = mnee.new_button( gui, uid, pic_x + pic_w - 8, pic_y + 2, pic_z,
        "mods/mnee/files/pics/key_close.png", {
        tip = GameTextGetTranslatedOrNot( "$mnee_close" ),
        highlight = pen.PALETTE.PRSP.WHITE })
    if( clicked ) then mnee.G.gui_active = false; mnee.play_sound( "close_window" ) end
    
    uid, clicked = mnee.new_button( gui, uid, pic_x + pic_w - 15, pic_y + 2, pic_z,
        "mods/mnee/files/pics/key_"..( mnee.G.show_alt and "B" or "A" )..".png", {
        tip = GameTextGetTranslatedOrNot( "$mnee_alt"..( mnee.G.show_alt and "B" or "A" )),
        highlight = pen.PALETTE.PRSP.WHITE })
    if( clicked ) then mnee.G.show_alt = not( mnee.G.show_alt ); mnee.play_sound( "button_special" ) end
    
    uid, mnee.G.mod_page = mnee.new_pager( gui, uid, pic_x + 2, pic_y, pic_z, {
        list = KEYS, items_per_page = 8, page = mnee.G.mod_page,
        func = function( gui, uid, pic_x, pic_y, pic_z, i,v,k,c )
            local is_fancy = _MNEEDATA[i] ~= nil
            if( is_fancy and pen.get_hybrid_function( _MNEEDATA[i].is_hidden, { i, mnee.G.jpad_maps })) then
                return uid, c - 1
            end
            
            local t_x, t_y = pic_x, pic_y + k*11
            local is_current = mnee.G.current_mod == i
            local name = pen.magic_translate( is_fancy and _MNEEDATA[i].name or i )
            uid, clicked = mnee.new_button( gui, uid, t_x, t_y, pic_z,
                "mods/mnee/files/pics/button_43_"..( is_current and "B" or "A" )..".png", {
                tip = name..( is_current and (( is_fancy and _MNEEDATA[i].desc ~= nil ) and " @ "..pen.magic_translate( _MNEEDATA[i].desc ) or "" ) or " @ "..GameTextGetTranslatedOrNot( "$mnee_lmb_keys" )),
                highlight = pen.PALETTE.PRSP[ is_current and "BLUE" or "RED" ]})
            uid = pen.new_text( gui, uid, t_x + 43/2, t_y, pic_z - 0.01, name, {
                dims = {39,0}, is_centered_x = true, color = pen.PALETTE.PRSP[ is_current and "RED" or "WHITE" ]})
            if( clicked ) then mnee.G.binding_page, mnee.G.current_mod = 1, i; mnee.play_sound( "button_special" ) end

            return uid, c
        end,
    })
    
    local meta = {}
    if( _MNEEDATA[ mnee.G.current_mod ] ~= nil ) then
        meta.func = _MNEEDATA[ mnee.G.current_mod ].func
        meta.is_advanced = _MNEEDATA[ mnee.G.current_mod ].is_advanced or false
        meta.is_locked = pen.get_hybrid_function( _MNEEDATA[ mnee.G.current_mod ].is_locked, { mnee.G.current_mod, mnee.G.jpad_maps }) or false
    end

    if( meta.func ~= nil ) then
        local result = false
        uid, result = pen.catch( meta.func, { gui, uid, t_x, t_y, pic_z, {
            a = starter,
            b = ender,
            ks = KEYS,
            k_type = key_type,
        }}, {uid,false})
        if( result ) then
            current_binding = result.set_bind
            doing_axis = result.will_axis
            btn_axis_mode = result.btn_axis
            advanced_mode = result.set_advanced
        end
    else
        uid, mnee.G.binding_page = mnee.new_pager( gui, uid, pic_x + 48, pic_y, pic_z, {
            list = KEYS[ mnee.G.current_mod ], items_per_page = 8, page = mnee.G.binding_page,
            func = function( gui, uid, pic_x, pic_y, pic_z, i,v,k,c )
                if( pen.get_hybrid_function( v.is_hidden, {{ mnee.G.current_mod, i }, mnee.G.jpad_maps })) then
                    return uid, c - 1
                end

                local is_static = v.is_locked
                if( is_static == nil ) then
                    is_static = meta.is_locked or false
                else is_static = pen.get_hybrid_function( is_static, {{ mnee.G.current_mod, i }, mnee.G.jpad_maps }) end
                local is_axis = mnee.get_bind( v )[ key_type ][1] == "is_axis" or v.axes ~= nil

                local t_x, t_y = pic_x, pic_y + k*11
                uid, clicked, r_clicked = pen.catch( mnee.new_button, { gui, uid, t_x, t_y, pic_z,
                    "mods/mnee/files/pics/button_74_"..( is_static and "B" or "A" )..".png", {
                    tip = table.concat({
                        is_axis and ( GameTextGet( "$mnee_axis", v.jpad_type or "EXTRA" )..( is_static and "" or " @ " )) or "",
                        is_static and GameTextGetTranslatedOrNot( "$mnee_static" ).." @ " or "",
                        pen.magic_translate( v.name ), ": ", pen.magic_translate( v.desc ), " @ ", 
                        mnee.bind2string( KEYS[ mnee.G.current_mod ], v, key_type ),
                        is_axis and " @ "..GameTextGetTranslatedOrNot( "$mnee_lmb_axis" ) or "",
                    }),
                    highlight = pen.PALETTE.PRSP[ is_static and "BLUE" or "RED" ]}})
                uid = pen.new_text( gui, uid, t_x + 74/2, t_y, pic_z - 0.01, pen.magic_translate( v.name ), {
                    dims = {70,0}, is_centered_x = true, color = pen.PALETTE.PRSP[ is_static and "BLUE" or "WHITE" ]})
                if( clicked or r_clicked ) then
                    if( not( is_static )) then
                        mnee.G.current_binding = i
                        mnee.G.doing_axis = is_axis
                        mnee.G.btn_axis_mode = is_axis and r_clicked
                        mnee.play_sound( "select" )
                        
                        if( v.never_advanced ) then
                            mnee.G.advanced_mode = false
                        else
                            mnee.G.advanced_mode = v.is_advanced
                            if( mnee.G.advanced_mode == nil ) then mnee.G.advanced_mode = meta.is_advanced or false end
                            mnee.G.advanced_mode = mnee.G.advanced_mode or ( r_clicked and not( is_axis ))
                        end
                    else
                        GamePrint( GameTextGetTranslatedOrNot( "$mnee_error" ).." "..GameTextGetTranslatedOrNot( "$mnee_no_change" ))
                        mnee.play_sound( "error" )
                    end
                end
                
                uid, clicked, r_clicked = mnee.new_button( gui, uid, t_x + 75, t_y, pic_z,
                    "mods/mnee/files/pics/key_delete.png", {
                    tip = GameTextGetTranslatedOrNot( "$mnee_rmb_default" )})
                if( r_clicked ) then
                    -- if( v.axes ~= nil ) then
                    --     KEYS[ mnee.G.current_mod ][ v.axes[1]] = nil
                    --     KEYS[ mnee.G.current_mod ][ v.axes[2]] = nil
                    -- else
                    --     KEYS[ mnee.G.current_mod ][ i ] = nil
                    -- end
                    -- KEYS = mnee.update_bindings( KEYS )
                    mnee.play_sound( "clear_all" )
                    
                    if( _MNEEDATA[ mnee.G.current_mod ] ~= nil ) then
                        local func = _MNEEDATA[ mnee.G.current_mod ].on_changed
                        if( func ~= nil ) then func( _MNEEDATA[ mnee.G.current_mod ]) end
                        local f = v.on_reset or v.on_changed
                        if( f ~= nil ) then f( v ) end
                    end
                end

                return uid, c
            end, order_func = mnee.order_sorter,
        })
    end
    
    uid = mnee.new_button( gui, uid, pic_x + 101, pic_y + 99, pic_z,
        "mods/mnee/files/pics/help.png", {
        tip = table.concat({
            GameTextGetTranslatedOrNot( "$mnee_lmb_bind" ), " @ ",
            GameTextGetTranslatedOrNot( "$mnee_rmb_advanced" ), " @ ",
            GameTextGetTranslatedOrNot( "$mnee_alt_help" )
        }),
        no_anim = true, highlight = pen.PALETTE.PRSP.BLUE,
    })
    
    uid, clicked, r_clicked = mnee.new_button( gui, uid, pic_x + 112, pic_y + 99, pic_z,
        "mods/mnee/files/pics/button_dft.png", {
        tip = GameTextGetTranslatedOrNot( "$mnee_rmb_mod" )})
    if( r_clicked ) then
        -- mnee.apply_setup( current_mod, mnee.get_setup_id( current_mod, profile ))
        mnee.play_sound( "clear_all" )
        
        if( _MNEEDATA[ mnee.G.current_mod ] ~= nil ) then
            local func = _MNEEDATA[ mnee.G.current_mod ].on_reset or _MNEEDATA[ mnee.G.current_mod ].on_changed
            if( func ~= nil ) then func( _MNEEDATA[ mnee.G.current_mod ]) end
            for i,v in mnee.order_sorter( KEYS[ mnee.G.current_mod ]) do
                local f = v.on_reset or v.on_changed
                if( f ~= nil ) then f( v ) end
            end
        end
    end
    
    uid, clicked = mnee.new_button( gui, uid, pic_x + 136, pic_y + 11, pic_z,
        "mods/mnee/files/pics/button_tgl_"..( is_disabled and "A" or "B" )..".png", {
        tip = GameTextGetTranslatedOrNot( "$mnee_lmb_input"..( is_disabled and "A" or "B" )),
        highlight = pen.PALETTE.PRSP[ is_disabled and "BLUE" or "RED" ]})
    if( clicked ) then
        if( is_disabled ) then
            GameRemoveFlagRun( mnee.TOGGLER ); mnee.play_sound( "capture" )
        else GameAddFlagRun( mnee.TOGGLER ); mnee.play_sound( "uncapture" ) end
    end
    
    uid, clicked, r_clicked = mnee.new_button( gui, uid, pic_x + 136, pic_y + 22, pic_z,
        "mods/mnee/files/pics/button_rst.png", {
        tip = GameTextGetTranslatedOrNot( "$mnee_rmb_reset" )})
    if( r_clicked ) then
        mnee.play_sound( "delete" )
        pen.setting_set( "mnee.SETUP", "" )
        pen.setting_set( "mnee.BINDINGS", "" )
        GlobalsSetValue( mnee.UPDATER, GameGetFrameNum())
    end

    if( _MNEEDATA[ mnee.G.current_mod ] ~= nil and _MNEEDATA[ mnee.G.current_mod ].setup_modes ~= nil ) then
        uid, clicked = mnee.new_button( gui, uid, pic_x + 136, pic_y + 66, pic_z,
            "mods/mnee/files/pics/button_stp_"..( mnee.G.stp_panel and "B" or "A" )..".png", {
            tip = GameTextGetTranslatedOrNot( "$mnee_lmb_setups" )
            highlight = pen.PALETTE.PRSP[ mnee.G.stp_panel and "BLUE" or "RED" ]})
        if( clicked ) then
            mnee.play_sound( mnee.G.stp_panel and "close_window" or "open_window" )
            if( mnee.G.ctl_panel ) then mnee.G.ctl_panel = false end
            mnee.G.stp_panel = not( mnee.G.stp_panel )
        end
    elseif( mnee.G.stp_panel ) then mnee.G.stp_panel = false end

    uid, clicked = mnee.new_button( gui, uid, pic_x + 136, pic_y + 77, pic_z,
        "mods/mnee/files/pics/button_ctl_"..( mnee.G.ctl_panel and "B" or "A" )..".png", {
        tip = GameTextGetTranslatedOrNot( "$mnee_lmb_jpads" ),
        highlight = pen.PALETTE.PRSP[ mnee.G.ctl_panel and "BLUE" or "RED" ]})
    if( clicked ) then
        mnee.play_sound( mnee.G.ctl_panel and "close_window" or "open_window" )
        if( mnee.G.stp_panel ) then mnee.G.stp_panel = false end
        mnee.G.ctl_panel = not( mnee.G.ctl_panel )
    end
    
    if( mnee.G.stp_panel ) then
        if( not( _MNEEDATA[ mnee.G.current_mod ].setup_modes[1].dtf )) then
            table.insert( _MNEEDATA[ mnee.G.current_mod ].setup_modes, 1, _MNEEDATA[ mnee.G.current_mod ].setup_default or {
                name = "$mnee_default",
                desc = "$mnee_default_desc",
            })
            _MNEEDATA[ mnee.G.current_mod ].setup_modes[1].id = "dft"
            _MNEEDATA[ mnee.G.current_mod ].setup_modes[1].dtf = true
        end
        
        local setup_memo = mnee.get_setup_memo()
        uid, mnee.G.setup_page = mnee.new_pager( gui, uid, pic_x + 160, pic_y + 33, pic_z, {
            list = _MNEEDATA[ mnee.G.current_mod ].setup_modes, items_per_page = 5, page = mnee.G.setup_page,
            func = function( gui, uid, pic_x, pic_y, pic_z, i,v,k,c )
                local t_x, t_y = pic_x, pic_y + k*11
                local is_going = ( setup_memo[ profile ] or setup_memo[1])[ mnee.G.current_mod ] == v.id
                uid, clicked = mnee.new_button( gui, uid, t_x, t_y, pic_z,
                    "mods/mnee/files/pics/button_21_"..( is_going and "B" or "A" )..".png", {
                    tip = table.concat({
                        GameTextGetTranslatedOrNot( "$mnee_setup_warning" ), " @ ",
                        pen.magic_translate( setup.name ), ": ", pen.magic_translate( setup.desc )
                    }),
                    highlight = pen.PALETTE.PRSP[ is_going and "BLUE" or "RED" ]})
                uid = pen.new_text( gui, uid, t_x + 21/2, t_y, pic_z - 0.01, string.upper( string.sub( setup.btn or setup.id, 1, 3 )), {
                    dims = {17,0}, is_centered_x = true, color = pen.PALETTE.PRSP[ is_going and "RED" or "WHITE" ]})
                if( clicked ) then
                    -- mnee.apply_setup( current_mod, setup.id )
                    mnee.play_sound( "switch_page" )
                end

                return uid, c
            end,
        })

        uid = pen.new_image( gui, uid, pic_x + 158, pic_y + 31, pic_z + 0.01, "mods/mnee/files/pics/setup_panel.png", { can_click = true })
    elseif( mnee.G.ctl_panel ) then
        if( mnee.stl.jauto ) then --make this be a legit spritesheet anim
            uid = pen.new_anim( gui, uid, 1, pic_x + 160, pic_y + 55, pic_z, "mods/mnee/files/pics/scan/", 20, 5 )
        else
            uid = pen.new_image( gui, uid, pic_x + 160, pic_y + 55, pic_z, "mods/mnee/files/pics/scan/0.png" )
        end

        uid, clicked, r_clicked = mnee.new_button( gui, uid, pic_x + 160, pic_y + 55, pic_z,
            "mods/mnee/files/pics/scan/_hitbox.png", {
            tip = table.concat({ GameTextGet( "$mnee_jpad_count", mnee.G.jpad_count ), " @ ",
            GameTextGetTranslatedOrNot( "$mnee_rmb_scan"..( mnee.stl.jauto and "B" or "A" ))})})  
        if( r_clicked ) then
            pen.setting_set( "mnee.CTRL_AUTOMAPPING", not( mnee.stl.jauto ))
            mnee.play_sound( "button_special" )
        end
        
        for i = 1,4 do
            local is_real = mnee.G.jpad_maps[i]
            uid, clicked, r_clicked = pen.new_button( gui, uid, pic_x + 160, pic_y + 66 + 11*( i - 1 ), pic_z,
                "mods/mnee/files/pics/button_10_"..( is_real and "B" or "A" )..".png", {
                tip = table.concat(
                    is_real > 0 and {
                        GameTextGetTranslatedOrNot( "$mnee_jpad_id" ),
                        ( is_real > 4 and GameTextGetTranslatedOrNot( "$mnee_dummy" ) or tostring( is_real )), " @ ",
                        GameTextGetTranslatedOrNot( "$mnee_lmb_unmap" )
                    } or {
                        GameTextGetTranslatedOrNot( "$mnee_lmb_map" ), " @ ",
                        GameTextGetTranslatedOrNot( "$mnee_rmb_dummy" )
                    }
                ),
                highlight = pen.PALETTE.PRSP[ is_real and "BLUE" or "RED" ]})
            uid = pen.new_text( gui, uid, pic_x + 160 + 10/2, pic_y + 66 + 11*( i - 1 ), pic_z - 0.01, i, {
                dims = {10,0}, is_centered_x = true, color = pen.PALETTE.PRSP[ is_real > 0 and ( is_real > 4 and "BLUE" or "RED" ) or "WHITE" ]})
            if( clicked ) then
                if( mnee.G.jpad_count > 0 or mnee.G.jpad_maps[i] > 4 ) then
                    if( is_real ) then
                        mnee.jpad_update( -i )
                        mnee.play_sound( "delete" )
                    else
                        mnee.stl.jslots[i] = true
                    end

                    if( mnee.stl.jauto ) then
                        pen.setting_set( "mnee.CTRL_AUTOMAPPING", false )
                        AddFlagPersistent( mnee.AMAP_MEMO )
                        mnee.stl.jauto = false
                    end
                else
                    GamePrint( GameTextGetTranslatedOrNot( "$mnee_no_jpads" ))
                    mnee.play_sound( "error" )
                end
            end
            if( not( is_real ) and r_clicked ) then
                mnee.G.jpad_maps[i] = 5
                mnee.play_sound( "select" )
            end
        end
        
        uid = pen.new_image( gui, uid, pic_x + 158, pic_y + 53, pic_z + 0.01, "mods/mnee/files/pics/controller_panel.png", { can_click = true })
    end
    
    local new_profile = profile
    uid, new_profile = mnee.new_pager( gui, uid, pic_x + 160, pic_y + 33, pic_z, { profile_mode = true, page = profile, list = 26 })
    if( profile ~= new_profile ) then pen.setting_set( "mnee.PROFILE", new_profile ) end
    
    uid, mnee.G.pos[1], mnee.G.pos[2] = pen.new_dragger( gui, uid, "mnee_window", pic_x, pic_y, 142, 9, is_debugging )
    uid = pen.new_image( gui, uid, pic_x, pic_y, pic_z + 0.05, "mods/mnee/files/pics/window.png", { can_click = true })

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
    local enter_down = false
    local this_bind = KEYS[ mnee.G.current_mod ][ mnee.G.current_binding ]
    local doing_jpad = mnee.G.doing_axis and not( mnee.G.btn_axis_mode )
    if( not( doing_jpad )) then active = mnee.get_keys( "guied" ) end
    if( pen.vld( active ) and mnee.G.advanced_mode ) then
        local is_dirty = this_bind.is_dirty
        if( is_dirty == nil and _MNEEDATA[ mnee.G.current_mod ] ~= nil ) then
            is_dirty = _MNEEDATA[ mnee.G.current_mod ].is_dirty or false
        end

        tip_text = table.concat({ tip_text, pen.t.loop_concat( active, function( i, key )
            if( key == "return" ) then enter_down = true; return end
            return {( i == 1 and "" or "; " ), key }
        end), "]", pen.t.loop_concat( pen.t.unarray( KEYS ), function( mod, mod_tbl )
            return pen.t.loop_concat( pen.t.unarray( mod_tbl ), function( bind, bind_tbl )
                local this_one = 0
                for i = 1,2 do
                    local b = mnee.get_bind( bind_tbl )[ i == 1 and "main" or "alt" ]
                    this_one = is_dirty and -1 or pen.t.count( b )
                    for e,key in ipairs( active ) do
                        if( mnee.SPECIAL_KEYS[ key ] == nil ) then
                            local gotcha = b[ key ] ~= nil
                            if( is_dirty and gotcha ) then
                                this_one = #active; break
                            elseif( not( gotcha )) then
                                this_one = -1; break
                            end
                        end
                    end
                    if( this_one > 0 ) then break end
                end
                if( this_one == #active ) then
                    return {
                        " @ ", GameTextGetTranslatedOrNot( "$mnee_conflict" ),
                        "[", mod, "; ", pen.magic_translate( bind_tbl.name ), "]"
                    }
                end
            end)
        end)})
    elseif( pen.vld( active )) then
        local allow_special = this_bind.allow_special
        tip_text = table.concat({ tip_text, pen.t.loop_concat( active, function( i, key )
            if( not( allow_special ) and mnee.SPECIAL_KEYS[ key ] ~= nil ) then return end
            if( key == "mouse_left_gui" or key == "mouse_right_gui" ) then return end
            enter_down = true
            return key
        end), "]" })
    end
    
    local is_stick = this_bind.axes ~= nil
    if( mnee.G.gui_retoggler ) then
        uid, clicked = pen.new_image( gui, uid, pic_x, pic_y, pic_z + 0.01, "mods/mnee/files/pics/continue.png", { can_click = true })
        uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_doit" ))
        if( clicked ) then
            if(( mnee.G.btn_axis_counter or 4 ) >= (( is_stick and not( doing_jpad )) and 4 or 2 )) then
                mnee.G.current_binding = ""
                mnee.G.doing_axis = false
                mnee.G.btn_axis_mode = false
                mnee.G.btn_axis_counter = nil
                mnee.G.advanced_mode = false
            else
                mnee.G.btn_axis_counter = mnee.G.btn_axis_counter + 1
            end
            mnee.G.gui_retoggler = false
            mnee.play_sound( "confirm" )
        end
    else
        uid = mnee.new_button( gui, uid, pic_x + 3, pic_y + 71, pic_z,
            "mods/mnee/files/pics/help.png", {
            tip = GameTextGetTranslatedOrNot( "$mnee_binding_"..( doing_jpad and "axis" or ( mnee.G.advanced_mode and "advanced" or "simple" )))
            no_anim = true, highlight = pen.PALETTE.PRSP.BLUE,
        })
        
        local nuke_em, b = false, mnee.get_bind( this_bind )
        local doing_swap = mnee.G.show_alt and ((( doing_jpad or mnee.G.btn_axis_mode ) and b.alt[2] ~= "_" ) or ( b.alt[ "_" ] == nil ))
        if(( mnee.G.btn_axis_counter or 1 )%2 == 1 ) then
            uid, clicked, r_clicked = mnee.new_button( gui, uid, pic_x + 146, pic_y + 71, pic_z,
                "mods/mnee/files/pics/key_unbind.png", {
                tip = GameTextGetTranslatedOrNot( "$mnee_lmb_unbind" )..(
                    doing_swap and " @ "..GameTextGetTranslatedOrNot( "$mnee_rmb_unbind" ) or ""
                ),
                highlight = pen.PALETTE.PRSP.BLUE})
            if( clicked ) then
                nuke_em = true
            elseif( doing_swap and r_clicked ) then
                nuke_em = 1
            end
        end

        if( mnee.G.advanced_mode ) then
            if( pen.vld( active )) then
                mnee.G.advanced_timer = mnee.G.advanced_timer + 1
                pen.new_text( gui, pic_x + 77, pic_y + 73, pic_z, math.ceil(( 300 - mnee.G.advanced_timer )/60 ), {
                    color = pen.PALETTE.PRSP.RED})
                if( mnee.G.advanced_timer >= 300 ) then enter_down, mnee.G.advanced_timer = true, 0 end
            else mnee.G.advanced_timer = 0 end
        end
        
        uid, clicked, r_clicked = pen.new_image( gui, uid, pic_x, pic_y, pic_z + 0.01,
            "mods/mnee/files/pics/rebinder"..( doing_jpad and "_axis" or ( mnee.G.advanced_mode and "" or "_simple" ))..".png", {
            can_click = true })
        uid = mnee.new_tooltip( gui, uid, pic_z - 200, doing_jpad and GameTextGetTranslatedOrNot( "$mnee_waiting" ) or ( GameTextGetTranslatedOrNot( "$mnee_keys" ).." @ "..( tip_text == "[" and GameTextGetTranslatedOrNot( "$mnee_nil" ) or tip_text )).."@"..GameTextGetTranslatedOrNot( "$mnee_rmb_cancel" ))
        if( r_clicked ) then
            is_stick = false
            mnee.G.current_binding = ""
            mnee.G.doing_axis = false
            mnee.G.btn_axis_mode = false
            mnee.G.advanced_mode = false
            mnee.play_sound( "error" )
        end
        
        local c_bind = mnee.G.current_binding
        if( is_stick ) then
            mnee.G.btn_axis_counter = mnee.G.btn_axis_counter or 1
            c_bind = KEYS[ mnee.G.current_mod ][ c_bind ].axes[( mnee.G.btn_axis_counter - 1 )%2 + 1 ]
            
            local anim = ( math.sin( math.floor( GameGetFrameNum()/10 )%60 ) - 1 )/2 --interpolation lib
            local offs = {{-1,0,90,-1},{0,-1,0,1},{1,0,90,1},{0,-1,180,1}}
            local off = offs[ mnee.G.btn_axis_counter ]
            for i = 1,2 do
                local angle = math.rad( off[3])
                local off_x, off_y = pen.rotate_offset( -8, -off[4]*8, angle )
                local do_shift = ( i == 1 and mnee.G.btn_axis_counter == 1 ) or ( i == 2 and mnee.G.btn_axis_counter == 3 )
                off_x, off_y = off_x + 2*anim*off[1] + ( do_shift and off[1] or 0 ), off_y + 2*anim*off[2]
                uid = pen.new_image( gui, uid, pic_x + ( i == 1 and 12 or 147 ) + off_x, pic_y + 35 + off_y, pic_z,
                    "mods/mnee/files/pics/arrow.png", { s_x = 1, s_y = off[4], angle = angle })
            end
        end

        local this_b = KEYS[ mnee.G.current_mod ][ c_bind ]
        if( nuke_em ) then
            local k_type = key_type
            if( doing_swap ) then
                if( nuke_em ~= 1 ) then
                    this_b.keys = this_b.keys_alt
                end
                k_type = "keys_alt"
            end
            if( doing_jpad ) then
                this_b[ k_type ] = { "is_axis", "_", }
            else
                local new_bind = {}
                if( mnee.G.btn_axis_mode ) then
                    new_bind = this_b[ k_type ]
                    new_bind[ 2 ] = "_"
                    new_bind[ 3 ] = "_"
                    mnee.G.btn_axis_counter = ( mnee.G.btn_axis_counter or 1 ) + 1
                else
                    new_bind[ "_" ] = 1
                end
                this_b[ k_type ] = new_bind
            end
            if( nuke_em == 1 ) then
                this_b.keys = this_b.keys_alt
            end
            mnee.G.gui_retoggler = true
            mnee.play_sound( "delete" )
        elseif( doing_jpad ) then
            local axes = mnee.get_axes()
            local champ = { 0, 0 }
            for ax,v in pairs( axes ) do
                if( math.abs( v ) > 0.8 ) then
                    champ = math.abs( champ[2]) < math.abs( v ) and { ax, v, } or champ
                end
            end
            if( champ[1] ~= 0 ) then
                this_b[ key_type ] = { "is_axis", champ[1], }
                mnee.G.gui_retoggler = true
                mnee.play_sound( "switch_dimension" )
            end
        elseif( enter_down ) then
            local changed = false
            local new_bind = {}
            for i,key in ipairs( active ) do
                if( key ~= "return" ) then
                    changed = true
                    if( mnee.G.btn_axis_mode ) then
                        new_bind = this_b[ key_type ]
                        mnee.G.btn_axis_counter = mnee.G.btn_axis_counter or 1
                        local btn_id = is_stick and ( mnee.G.btn_axis_counter > 2 and 3 or 2 ) or (( mnee.G.btn_axis_counter - 1 )%2 + 2 )
                        new_bind[ btn_id ] = key
                        break
                    else
                        new_bind[ key ] = 1
                        if( not( mnee.G.advanced_mode )) then break end
                    end
                end
            end
            if( changed ) then
                this_b[ key_type ] = new_bind
            end
            mnee.G.gui_retoggler = true
            mnee.play_sound( "switch_dimension" )
        end
        
        if( mnee.G.gui_retoggler ) then
            mnee.set_bindings( KEYS )
            if( _MNEEDATA[ mnee.G.current_mod ] ~= nil and _MNEEDATA[ mnee.G.current_mod ].on_changed ~= nil ) then
                _MNEEDATA[ mnee.G.current_mod ].on_changed( _MNEEDATA[ mnee.G.current_mod ])
            end
            if( this_b.on_changed ~= nil ) then
                this_b.on_changed( this_b )
            end
        end
    end
end
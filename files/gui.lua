--make sure that all resetting business is done per-profile
--swap all set_binging with update_bindings
--add buttons anims + main window frame opening bounce anim + side bars opening anims

local keys = mnee.get_bindings()
local profile = pen.setting_get( "mnee.PROFILE" )
local is_disabled = GameHasFlagRun( mnee.TOGGLER )
local key_type = mnee.G.show_alt and "alt" or "main"
if( mnee.G.ctl_panel == nil and mnee.G.jpad_count > 0 ) then
    mnee.G.ctl_panel, mnee.G.stp_panel = true, false
end

local gui = mnee.G.UI
local pic = "mods/mnee/files/pics/window.png"
local pic_w, pic_h = GuiGetImageDimensions( gui, pic, 1 )
if( mnee.G.pos == nil ) then
    local screen_w, screen_h = GuiGetScreenDimensions( gui )
    mnee.G.pos = {( screen_w - pic_w )/2, screen_h - ( pic_h + 10 )}
end

local uid, pic_z = 0, -50
local clicked, r_clicked = false, false
local pic_x, pic_y = unpack( mnee.G.pos )
local gonna_rebind = pen.vld( mnee.G.current_binding )
if( not( gonna_rebind )) then
    local txt = GameTextGetTranslatedOrNot( "$mnee_title"..( show_alt and "B" or "A" ))
    if( show_alt ) then uid = pen.new_image( gui, uid, pic_x, pic_y, pic_z - 0.001, "mods/mnee/files/pics/title_bg.png" ) end
    pen.new_text( gui, pic_x + 142 - GuiGetTextDimensions( gui, txt, 1, 2 ), pic_y, pic_z - 0.01, txt, show_alt and {136,121,247} or {238,226,206})

    uid, clicked = pen.new_button( gui, uid, pic_x + pic_w - 8, pic_y + 2, pic_z - 0.01, "mods/mnee/files/pics/key_close.png" )
    uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_close" ))
    if( clicked ) then
        gui_active = false
        mnee.play_sound( "close_window" )
    end

    uid, clicked = pen.new_button( gui, uid, pic_x + pic_w - 15, pic_y + 2, pic_z - 0.01, "mods/mnee/files/pics/key_"..( show_alt and "B" or "A" )..".png" )
    uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_alt"..( show_alt and "B" or "A" )))
    if( clicked ) then
        show_alt = not( show_alt )
        mnee.play_sound( "button_special" )
    end
    
    local counter = 1
    local starter = 8*mod_page - 8
    local ender = 8*mod_page + 1
    local t_x, t_y = pic_x + 2, pic_y
    for mod in pen.t.order( keys ) do
        local is_fancy = mneedata[mod] ~= nil
        local will_show = not( is_fancy ) or ( is_fancy and not( pen.get_hybrid_function( mneedata[mod].is_hidden, {mod,jpad})))
        if( will_show ) then
            will_show = counter > starter and counter < ender
            counter = counter + 1
        end
        if( will_show ) then
            t_y = t_y + 11
            
            local name = pen.magic_translate( is_fancy and mneedata[mod].name or mod )
            uid, clicked = pen.new_button( gui, uid, t_x, t_y, pic_z - 0.01, "mods/mnee/files/pics/button_43_"..( current_mod == mod and "B" or "A" )..".png" )
            uid = mnee.new_tooltip( gui, uid, pic_z - 200, name..( current_mod == mod and (( is_fancy and mneedata[mod].desc ~= nil ) and " @ "..pen.magic_translate( mneedata[mod].desc ) or "" ) or " @ "..GameTextGetTranslatedOrNot( "$mnee_lmb_keys" )))
            pen.new_text( gui, t_x + 2, t_y, pic_z - 0.02, pen.liner( name, 39 ), current_mod == mod and {245,132,132} or {238,226,206})
            if( clicked ) then
                binding_page = 1
                current_mod = mod
                mnee.play_sound( "button_special" )
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
    starter = 8*( binding_page - 1 )
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
            local will_show = not( pen.get_hybrid_function( bind.is_hidden, {{current_mod,id}, jpad}))
            if( will_show ) then
                will_show = counter > starter and counter < ender
                counter = counter + 1
            end
            if( will_show ) then
                t_y = t_y + 11
                
                local is_axis = bind[key_type][1] == "is_axis" or bind.axes ~= nil
                local is_static = bind.is_locked
                if( is_static == nil ) then
                    is_static = meta.is_locked or false
                else
                    is_static = pen.get_hybrid_function( is_static, {{current_mod,id}, jpad})
                end
                
                uid, clicked, r_clicked = pen.new_button( gui, uid, t_x, t_y, pic_z - 0.01, "mods/mnee/files/pics/button_74_"..( is_static and "B" or "A" )..".png" )
                pen.catch(function()
                    uid = mnee.new_tooltip( gui, uid, pic_z - 200, ( is_axis and ( GameTextGet( "$mnee_axis", bind.jpad_type or "EXTRA" )..( is_static and "" or " @ " )) or "" )..( is_static and GameTextGetTranslatedOrNot( "$mnee_static" ).." @ " or "" )..pen.magic_translate( bind.name )..": "..pen.magic_translate( bind.desc ).." @ "..mnee.bind2string( keys[ current_mod ], bind, key_type )..( is_axis and " @ "..GameTextGetTranslatedOrNot( "$mnee_lmb_axis" ) or "" ))
                    pen.new_text( gui, t_x + 2, t_y, pic_z - 0.02, pen.liner( pen.magic_translate( bind.name ), 70 ), is_static and {136,121,247} or {238,226,206})
                end)
                if( clicked or r_clicked ) then
                    if( not( is_static )) then
                        current_binding = id
                        doing_axis = is_axis
                        btn_axis_mode = is_axis and r_clicked
                        mnee.play_sound( "select" )
                        
                        if( bind.never_advanced ) then
                            advanced_mode = false
                        else
                            advanced_mode = bind.is_advanced
                            if( advanced_mode == nil ) then advanced_mode = meta.is_advanced or false end
                            advanced_mode = advanced_mode or ( r_clicked and not( is_axis ))
                        end
                    else
                        GamePrint( GameTextGetTranslatedOrNot( "$mnee_error" ).." "..GameTextGetTranslatedOrNot( "$mnee_no_change" ))
                        mnee.play_sound( "error" )
                    end
                end
                
                uid, clicked, r_clicked = pen.new_button( gui, uid, t_x + 75, t_y, pic_z - 0.01, "mods/mnee/files/pics/key_delete.png" )
                uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_rmb_default" ))
                if( r_clicked ) then
                    dofile( "mods/mnee/bindings.lua" )
                    bindings = mnee.apply_setup( current_mod, mnee.get_setup_id( current_mod, profile ), bindings )
                    if( bind.axes ~= nil ) then
                        keys[ current_mod ][ bind.axes[1]] = bindings[ current_mod ][ bind.axes[1]]
                        keys[ current_mod ][ bind.axes[2]] = bindings[ current_mod ][ bind.axes[2]]
                    else
                        keys[ current_mod ][ id ] = bindings[ current_mod ][ id ]
                    end
                    mnee.set_bindings( keys )
                    mnee.play_sound( "clear_all" )
                    
                    if( mneedata[ current_mod ] ~= nil ) then
                        local func = mneedata[ current_mod ].on_changed
                        if( func ~= nil ) then func( mneedata[ current_mod ]) end
                        local f = bind.on_reset or bind.on_changed
                        if( f ~= nil ) then f( bind ) end
                    end
                end
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
        mnee.apply_setup( current_mod, mnee.get_setup_id( current_mod, profile ))
        mnee.play_sound( "clear_all" )
        
        if( mneedata[ current_mod ] ~= nil ) then
            local func = mneedata[ current_mod ].on_reset or mneedata[ current_mod ].on_changed
            if( func ~= nil ) then func( mneedata[ current_mod ]) end
            for id,bind in mnee.order_sorter( keys[ current_mod ]) do
                local f = bind.on_reset or bind.on_changed
                if( f ~= nil ) then f( bind ) end
            end
        end
    end
    
    uid, clicked = pen.new_button( gui, uid, pic_x + 136, pic_y + 11, pic_z - 0.01, "mods/mnee/files/pics/button_tgl_"..( is_disabled and "A" or "B" )..".png" )
    uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_lmb_input"..( is_disabled and "A" or "B" )))
    if( clicked ) then
        if( is_disabled ) then
            GameRemoveFlagRun( mnee.TOGGLER )
            mnee.play_sound( "capture" )
        else
            GameAddFlagRun( mnee.TOGGLER )
            mnee.play_sound( "uncapture" )
        end
    end
    
    uid, clicked, r_clicked = pen.new_button( gui, uid, pic_x + 136, pic_y + 22, pic_z - 0.01, "mods/mnee/files/pics/button_rst.png" )
    uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_rmb_reset" ))
    if( r_clicked ) then
        pen.setting_set( "mnee.SETUP", "" )
        pen.setting_set( "mnee.BINDINGS", "" )
        mnee.update_bindings( i )
        mnee.play_sound( "delete" )
    end

    if( mneedata[ current_mod ] ~= nil and mneedata[ current_mod ].setup_modes ~= nil ) then
        uid, clicked = pen.new_button( gui, uid, pic_x + 136, pic_y + 66, pic_z - 0.01, "mods/mnee/files/pics/button_stp_"..( stp_panel and "B" or "A" )..".png" )
        uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_lmb_setups" ))
        if( clicked ) then
            if( stp_panel ) then
                stp_panel = false
                mnee.play_sound( "close_window" )
            else
                stp_panel = true
                if( ctl_panel ) then
                    ctl_panel = false
                end
                mnee.play_sound( "open_window" )
            end
        end
    elseif( stp_panel ) then
        stp_panel = false
    end

    uid, clicked = pen.new_button( gui, uid, pic_x + 136, pic_y + 77, pic_z - 0.01, "mods/mnee/files/pics/button_ctl_"..( ctl_panel and "B" or "A" )..".png" )
    uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_lmb_jpads" ))
    if( clicked ) then
        if( ctl_panel ) then
            ctl_panel = false
            mnee.play_sound( "close_window" )
        else
            ctl_panel = true
            stp_panel = false
            mnee.play_sound( "open_window" )
        end
    end
    
    if( stp_panel ) then
        if( not( mneedata[ current_mod ].setup_modes[1].dtf )) then
            table.insert( mneedata[ current_mod ].setup_modes, 1, mneedata[ current_mod ].setup_default or {
                name = "$mnee_default",
                desc = "$mnee_default_desc",
            })
            mneedata[ current_mod ].setup_modes[1].id = "dft"
            mneedata[ current_mod ].setup_modes[1].dtf = true
        end

        local final_i = 5*setup_page
        local t_x, t_y = pic_x + 160, pic_y + 33
        local setup_memo = mnee.get_setup_memo()
        for i,setup in ipairs( mneedata[ current_mod ].setup_modes ) do
            local is_going = setup_memo[ profile ][ current_mod ] == setup.id
            uid, clicked = pen.new_button( gui, uid, t_x, t_y, pic_z - 0.01, "mods/mnee/files/pics/button_21_"..( is_going and "B" or "A" )..".png" )
            uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_setup_warning" ).." @ "..pen.magic_translate( setup.name )..": "..pen.magic_translate( setup.desc ))
            pen.new_text( gui, t_x + 2, t_y, pic_z - 0.02, string.upper( string.sub( setup.btn or setup.id, 1, 3 )), is_going and {245,132,132} or {238,226,206})
            if( clicked ) then
                mnee.apply_setup( current_mod, setup.id )
                mnee.play_sound( "switch_page" )
            end

            t_y = t_y + 11
            if( i == final_i ) then break end
        end

        page = setup_page
        uid, page = mnee.new_pager( gui, uid, t_x, pic_y + 88, pic_z - 0.01, page, math.ceil(( #mneedata[ current_mod ].setup_modes )/5 ), 1 )
        if( setup_page ~= page ) then
            setup_page = page
        end

        uid = pen.new_button( gui, uid, pic_x + 158, pic_y + 31, pic_z + 0.01, "mods/mnee/files/pics/setup_panel.png" )
    elseif( ctl_panel ) then
        if( mnee.stl.jauto ) then
            uid = pen.new_anim( gui, uid, 1, pic_x + 160, pic_y + 55, pic_z, "mods/mnee/files/pics/scan/", 20, 5 )
        else
            uid = pen.new_image( gui, uid, pic_x + 160, pic_y + 55, pic_z, "mods/mnee/files/pics/scan/0.png" )
        end
        uid, clicked, r_clicked = pen.new_button( gui, uid, pic_x + 160, pic_y + 55, pic_z - 0.01, "mods/mnee/files/pics/scan/_hitbox.png" )
        uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGet( "$mnee_jpad_count", jpad_count ).." @ "..GameTextGetTranslatedOrNot( "$mnee_rmb_scan"..( mnee.stl.jauto and "B" or "A" )))  
        if( r_clicked ) then
            pen.setting_set( "mnee.CTRL_AUTOMAPPING", not( mnee.stl.jauto ))
            mnee.play_sound( "button_special" )
        end
        
        for i = 1,4 do
            local is_real = jpad[i]
            uid, clicked, r_clicked = pen.new_button( gui, uid, pic_x + 160, pic_y + 66 + 11*( i - 1 ), pic_z, "mods/mnee/files/pics/button_10_"..( is_real and "B" or "A" )..".png" )
            uid = mnee.new_tooltip( gui, uid, pic_z - 200, is_real and GameTextGetTranslatedOrNot( "$mnee_jpad_id" )..( is_real > 4 and GameTextGetTranslatedOrNot( "$mnee_dummy" ) or tostring( is_real )).." @ "..GameTextGetTranslatedOrNot( "$mnee_lmb_unmap" ) or GameTextGetTranslatedOrNot( "$mnee_lmb_map" ).." @ "..GameTextGetTranslatedOrNot( "$mnee_rmb_dummy" ))
            pen.new_text( gui, pic_x + 162, pic_y + 66 + 11*( i - 1 ), pic_z - 0.01, i, is_real and ( is_real > 4 and {136,121,247} or {245,132,132}) or {238,226,206})
            
            if( clicked ) then
                if( jpad_count > 0 or ( jpad[i] and jpad[i] > 4 )) then
                    if( is_real ) then
                        jpad_update( -i )
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
                jpad[i] = 5
                mnee.play_sound( "select" )
            end
        end
        
        uid = pen.new_button( gui, uid, pic_x + 158, pic_y + 53, pic_z + 0.01, "mods/mnee/files/pics/controller_panel.png" )
    end
    
    page = profile
    uid, page = mnee.new_pager( gui, uid, pic_x + 136, pic_y + 88, pic_z - 0.01, page, 3, true )
    if( profile ~= page ) then
        pen.setting_set( "mnee.PROFILE", page )
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

                local is_dirty = keys[ current_mod ][ current_binding ].is_dirty
                if( is_dirty == nil and mneedata[ current_mod ] ~= nil ) then
                    is_dirty = mneedata[ current_mod ].is_dirty or false
                end
                
                for mod,bnds in pairs( keys ) do
                    for bnd,stff in pairs( bnds ) do
                        local this_one = 0
                        for i = 1,2 do
                            local k_type = i == 1 and "keys" or "keys_alt"
                            this_one = is_dirty and -1 or pen.t.count( stff[ k_type ])
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
                            tip_text = tip_text.." @ "..GameTextGetTranslatedOrNot( "$mnee_conflict" ).."["..mod.."; "..pen.magic_translate( stff.name ).."]"
                            break
                        end
                    end
                end
            else
                for i,key in ipairs( active ) do
                    if( mnee.SPECIAL_KEYS[( keys[ current_mod ][ current_binding ].allow_special or false ) and "_" or key] == nil and key ~= "mouse_left_gui" and key ~= "mouse_right_gui" ) then
                        tip_text = key.."]"
                        enter_down = true
                        break
                    end
                end
            end
        end
    end
    
    local is_stick = keys[ current_mod ][ current_binding ].axes ~= nil
    if( gui_retoggler ) then
        uid, clicked = pen.new_button( gui, uid, pic_x, pic_y, pic_z, "mods/mnee/files/pics/continue.png" )
        uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_doit" ))
        if( clicked ) then
            if(( btn_axis_counter or 4 ) >= (( is_stick and not( doing_jpad )) and 4 or 2 )) then
                current_binding = ""
                doing_axis = false
                btn_axis_mode = false
                btn_axis_counter = nil
                advanced_mode = false
            else
                btn_axis_counter = btn_axis_counter + 1
            end
            gui_retoggler = false
            mnee.play_sound( "confirm" )
        end
    else
        uid = pen.new_button( gui, uid, pic_x + 3, pic_y + 71, pic_z - 0.01, "mods/mnee/files/pics/help.png" )
        uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_binding_"..( doing_jpad and "axis" or ( advanced_mode and "advanced" or "simple" ))))
        
        local nuke_em = false
        local doing_swap = key_type == "keys" and ((( doing_jpad or btn_axis_mode ) and keys[ current_mod ][ current_binding ].keys_alt[2] ~= "_" ) or ( keys[ current_mod ][ current_binding ].keys_alt[ "_" ] == nil ))
        if(( btn_axis_counter or 1 )%2 == 1 ) then
            uid, clicked, r_clicked = pen.new_button( gui, uid, pic_x + 146, pic_y + 71, pic_z - 0.01, "mods/mnee/files/pics/key_unbind.png" )
            uid = mnee.new_tooltip( gui, uid, pic_z - 200, GameTextGetTranslatedOrNot( "$mnee_lmb_unbind" )..( doing_swap and " @ "..GameTextGetTranslatedOrNot( "$mnee_rmb_unbind" ) or "" ))
            if( clicked ) then
                nuke_em = true
            elseif( doing_swap and r_clicked ) then
                nuke_em = 1
            end
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
            is_stick = false
            doing_axis = false
            btn_axis_mode = false
            advanced_mode = false
            mnee.play_sound( "error" )
        end
        
        local this_bind = current_binding
        if( is_stick ) then
            btn_axis_counter = btn_axis_counter or 1
            this_bind = keys[ current_mod ][ this_bind ].axes[( btn_axis_counter - 1 )%2 + 1 ]
            
            local anim = ( math.sin( math.floor( GameGetFrameNum()/10 )%60 ) - 1 )/2
            local offs = {{-1,0,90,-1},{0,-1,0,1},{1,0,90,1},{0,-1,180,1}}
            local off = offs[btn_axis_counter]
            for i = 1,2 do
                local angle = math.rad( off[3])
                local off_x, off_y = pen.rotate_offset( -8, -off[4]*8, angle )
                local do_shift = ( i == 1 and btn_axis_counter == 1 ) or ( i == 2 and btn_axis_counter == 3 )
                off_x, off_y = off_x + 2*anim*off[1] + ( do_shift and off[1] or 0 ), off_y + 2*anim*off[2]
                uid = pen.new_image( gui, uid, pic_x + ( i == 1 and 12 or 147 ) + off_x, pic_y + 35 + off_y, pic_z - 0.01, "mods/mnee/files/pics/arrow.png", { s_x = 1, s_y = off[4], angle = angle })
            end
        end

        if( nuke_em ) then
            local k_type = key_type
            if( doing_swap ) then
                if( nuke_em ~= 1 ) then
                    keys[ current_mod ][ this_bind ].keys = keys[ current_mod ][ this_bind ].keys_alt
                end
                k_type = "keys_alt"
            end
            if( doing_jpad ) then
                keys[ current_mod ][ this_bind ][ k_type ] = { "is_axis", "_", }
            else
                local new_bind = {}
                if( btn_axis_mode ) then
                    new_bind = keys[ current_mod ][ this_bind ][ k_type ]
                    new_bind[ 2 ] = "_"
                    new_bind[ 3 ] = "_"
                    btn_axis_counter = ( btn_axis_counter or 1 ) + 1
                else
                    new_bind[ "_" ] = 1
                end
                keys[ current_mod ][ this_bind ][ k_type ] = new_bind
            end
            if( nuke_em == 1 ) then
                keys[ current_mod ][ this_bind ].keys = keys[ current_mod ][ this_bind ].keys_alt
            end
            gui_retoggler = true
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
                keys[ current_mod ][ this_bind ][ key_type ] = { "is_axis", champ[1], }
                gui_retoggler = true
                mnee.play_sound( "switch_dimension" )
            end
        elseif( enter_down ) then
            local changed = false
            local new_bind = {}
            for i,key in ipairs( active ) do
                if( key ~= "return" ) then
                    changed = true
                    if( btn_axis_mode ) then
                        new_bind = keys[ current_mod ][ this_bind ][ key_type ]
                        btn_axis_counter = btn_axis_counter or 1
                        local btn_id = is_stick and ( btn_axis_counter > 2 and 3 or 2 ) or (( btn_axis_counter - 1 )%2 + 2 )
                        new_bind[btn_id] = key
                        break
                    else
                        new_bind[ key ] = 1
                        if( not( advanced_mode )) then break end
                    end
                end
            end
            if( changed ) then
                keys[ current_mod ][ this_bind ][ key_type ] = new_bind
            end
            gui_retoggler = true
            mnee.play_sound( "switch_dimension" )
        end
        
        if( gui_retoggler ) then
            mnee.set_bindings( keys )
            if( mneedata[ current_mod ] ~= nil and mneedata[ current_mod ].on_changed ~= nil ) then
                mneedata[ current_mod ].on_changed( mneedata[ current_mod ])
            end
            if( keys[ current_mod ][ this_bind ].on_changed ~= nil ) then
                keys[ current_mod ][ this_bind ].on_changed( keys[ current_mod ][ this_bind ])
            end
        end
    end
end
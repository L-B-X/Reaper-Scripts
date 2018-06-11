-- @version 1.0
-- @author Leon Bradley (LBX)
-- @description LBX FX Float Positioner - SetUp
-- @website https://forum.cockos.com/showthread.php?t=199400
-- @changelog
--    1. Initial stable version
      
  local monitor = {x = 0, y = 0, w = 1920, h = 1080}
  
  local SCRIPT='LBX_FXPOS'
  
  local resource_path = reaper.GetResourcePath().."/Scripts/LBX/FXPositionerData/"
  local preset_path = resource_path.."Presets/"
 
  local dirtable = {'FIT','HORIZ','VERT','SINGLE','COLUMNS'}
  local aligntable1 = {'LEFT','CENTRE','RIGHT'}
  local aligntable2 = {'TOP','CENTRE','BOTTOM'}
      
  local colours = {mainbg = '35 35 35',
                   buttcol = '25 25 25'}
  
  local update_gfx = true
  local resize_display = true
  
  local tpage = 0
  local trackfxcount = -1
  local mouse = {}

  local nextupdate = 0
  
  local posoff = 0
  local list_cnt = 0
  local pos
  local fxblacklist = {}
  
  local dir = 0
  local align = 0
  local tracknum
  local settings = {}
  
  local presets
  local currentpreset = ''
  
  settings.followtrack = false
  settings.looppages = false
  settings.floatontrackchange = false
  settings.monitortrackfx = false
  settings.autopositionnewfx = false
  settings.focarr = true
  
  local setup = false
  
  --------------------------------------------
  --------------------------------------------
        
  function GetTrack(t)
  
    local tr
    if t == nil or t == 0 then
      track = reaper.GetMasterTrack(0)
    else
      track = reaper.GetTrack(0, t-1)
    end
    return track
  
  end
  
  function DBG(str)
    if str==nil then str="nil" end
    reaper.ShowConsoleMsg(tostring(str).."\n")
  end        
  ------------------------------------------------------------
  
  function GetObjects()
    local obj = {}
      
    obj.sections = {}
    local num = 7
    
    local pw =  math.floor(gfx1.main_w/2)-10

    butt_h = 26
    txt_h = 16
        
    --butt1
    obj.sections[1] = {x = 10,
                       y = 10 + (butt_h+2)*1.5,
                       w = gfx1.main_w/2-11,
                       h = butt_h}
    obj.sections[5] = {x = gfx1.main_w/2+1,
                       y = 10 + (butt_h+2)*1.5,
                       w = gfx1.main_w/2-11,
                       h = butt_h}                               


    obj.sections[2] = {x = 10,
                       y = 10 + (butt_h+2)*2.5,
                       w = gfx1.main_w/2-11,
                       h = butt_h}

    obj.sections[3] = {x = gfx1.main_w/2+1,
                       y = 10 + (butt_h+2)*2.5,
                       w = gfx1.main_w/2-11,
                       h = butt_h}

    obj.sections[4] = {x = 10,
                       y = 10 + (butt_h+2)*3.5,
                       w = gfx1.main_w-20,
                       h = butt_h}                               

    obj.sections[6] = {x = 10,
                       y = 10 + (butt_h+2)*0,
                       w = gfx1.main_w/3-11,
                       h = butt_h}       

    obj.sections[10] = {x = 10,
                       y = 20 + (butt_h+2)*4.5,
                       w = gfx1.main_w-20,
                       h = gfx1.main_h-(20 + (butt_h+2)*5)}
    obj.sections[11] = {x = 0,
                         y = 0,
                         w = 0,
                         h = 0}         

    obj.sections[14] = {x = 10+(gfx1.main_w/3-9),
                       y = 10 + (butt_h+2)*0,
                       w = 2*(gfx1.main_w/3)-11,
                       h = butt_h}       

    --SETUP 
    
    obj.sections[7] = {x = 10,
                       y = 10 + (butt_h+2)*2,
                       w = gfx1.main_w-20,
                       h = butt_h}       
    obj.sections[8] = {x = 10,
                       y = 10 + (butt_h+2)*3,
                       w = gfx1.main_w-20,
                       h = butt_h}       

    obj.sections[13] = {x = 10,
                       y = 10 + (butt_h+2)*4,
                       w = gfx1.main_w-20,
                       h = butt_h}
    --boundary labels
    obj.sections[12] = {x = 10,
                       y = 10 + (butt_h+2)*5,
                       w = gfx1.main_w-20,
                       h = butt_h*4}

    obj.sections[15] = {x = 10,
                       y = 10 + (butt_h+2)*9,
                       w = gfx1.main_w-20,
                       h = butt_h}
                                               
    return obj
  end
  
  -----------------------------------------------------------------------     
  
  function GetGUI_vars()
    gfx.mode = 0
    
    local gui = {}
      gui.aa = 1
      gui.fontname = 'Calibri'
      gui.fontsize_tab = 20    
      gui.fontsz_knob = 18
      if OS == "OSX32" or OS == "OSX64" then gui.fontsize_tab = gui.fontsize_tab - 5 end
      if OS == "OSX32" or OS == "OSX64" then gui.fontsz_knob = gui.fontsz_knob - 5 end
      if OS == "OSX32" or OS == "OSX64" then gui.fontsz_get = gui.fontsz_get - 5 end
      
      gui.color = {['back'] = '87 109 130',
                    ['back2'] = '87 109 130',
                    ['black'] = '0 0 0',
                    ['green'] = '87 109 130',
                    ['blue'] = '87 109 130',
                    ['white'] = '255 255 255',
                    ['red'] = '255 42 0',
                    ['green_dark'] = '0 0 0',
                    ['yellow'] = '87 109 130',
                    ['pink'] = '87 109 130',
                    }
    return gui
  end  
  ------------------------------------------------------------
      
  function f_Get_SSV(s)
    if not s then return end
    local t = {}
    for i in s:gmatch("[%d%.]+") do 
      t[#t+1] = tonumber(i) / 255
    end
    gfx.r, gfx.g, gfx.b = t[1], t[2], t[3]
  end
  
  ------------------------------------------------------------
    
  function GUI_text(gui, xywh, text, flags, col, tsz)

    if col == nil then col = gui.color.white end
    if tsz == nil then tsz = 0 end
    
    f_Get_SSV(col)  
    gfx.a = 1 
    gfx.setfont(1, gui.fontname, gui.fontsz_knob+tsz)
    --local text_len = gfx.measurestr(text)
    gfx.x, gfx.y = xywh.x,xywh.y
    gfx.drawstr(text, flags, xywh.x+xywh.w, xywh.y+xywh.h)

  end
  
  ------------------------------------------------------------
  
  function GUI_draw(obj, gui)
    
    gfx.mode =4
    gfx.dest = 1

    if update_gfx or resize_display then    
      gfx.setimgdim(1, -1, -1)  
      gfx.setimgdim(1, gfx1.main_w,gfx1.main_h)
      
      f_Get_SSV(colours.mainbg)
      gfx.rect(0,
               0,
               gfx1.main_w,
               gfx1.main_h, 1)  
    end

    if update_gfx then    

      if setup == false then
        GUI_DrawButtons(obj, gui)
      else
        GUI_DrawSetUp(obj, gui)
      end
      
    end
        
    gfx.dest = -1
    gfx.a = 1
    gfx.blit(1, 1, 0, 
      0,0, gfx1.main_w,gfx1.main_h,
      0,0, gfx1.main_w,gfx1.main_h, 0,0)
    
    update_gfx = false
    resize_display = false
    
  end

  function GUI_DrawSetUp(obj, gui)
  
    c = '200 200 200'
    GUI_DrawButton(gui, obj.sections[6], 'CLOSE', c, '99 99 99', true, -4)
    GUI_DrawButton(gui, obj.sections[7], dirtable[dir+1], c, '99 99 99', true, -4)
    GUI_DrawButton(gui, obj.sections[13], 'SET BOUNDARIES', c, '99 99 99', true, -4)
    GUI_DrawButton(gui, obj.sections[15], 'SAVE PRESET', c, '99 99 99', true, -4)

    local alt = ''
    if dir == 0 or dir == 1 then
      alt = aligntable2[align+1]
    elseif dir ~= 3 then
      alt = aligntable1[align+1]
    else
      alt = aligntable1[2]
    end

    GUI_DrawButton(gui, obj.sections[8], alt, c, '99 99 99', true, -4)
    
    local pad = 10
    local tc = '160 160 160'
    local xywh = {x = obj.sections[12].x,
                  y = obj.sections[12].y,
                  w = obj.sections[12].w,
                  h = butt_h}
    GUI_DrawButton(gui, xywh, 'Monitor X = ', '0 0 0', tc, true, -4,4,pad)
    xywh.y = xywh.y + butt_h
    GUI_DrawButton(gui, xywh, 'Monitor Y = ', '0 0 0', tc, true, -4,4,pad)
    xywh.y = xywh.y + butt_h
    GUI_DrawButton(gui, xywh, 'Monitor W = ', '0 0 0', tc, true, -4,4,pad)
    xywh.y = xywh.y + butt_h
    GUI_DrawButton(gui, xywh, 'Monitor H = ', '0 0 0', tc, true, -4,4,pad)
            
    local xywh = {x = obj.sections[12].x+60,
                  y = obj.sections[12].y,
                  w = obj.sections[12].w-60,
                  h = butt_h}
    GUI_DrawButton(gui, xywh, monitor.x, '0 0 0', tc, true, -4,4,pad)
    xywh.y = xywh.y + butt_h
    GUI_DrawButton(gui, xywh, monitor.y, '0 0 0', tc, true, -4,4,pad)
    xywh.y = xywh.y + butt_h
    GUI_DrawButton(gui, xywh, monitor.w, '0 0 0', tc, true, -4,4,pad)
    xywh.y = xywh.y + butt_h
    GUI_DrawButton(gui, xywh, monitor.h, '0 0 0', tc, true, -4,4,pad)
    
  end

  function GUI_FlashButton(obj, gui, butt, txt, flashtime, col)

    gfx.dest = 1
    GUI_DrawButton(gui, obj.sections[butt], txt, col, '99 99 99', true, -1)
    gfx.dest = -1
    gfx.a = 1
    gfx.blit(1, 1, 0, 
      0,0, gfx1.main_w,gfx1.main_h,
      0,0, gfx1.main_w,gfx1.main_h, 0,0)
    refresh_gfx = reaper.time_precise() + flashtime
      
  end
  
  function GUI_DrawButtons(obj, gui)

    local c = colours.buttcol

    c = '200 200 200'
    GUI_DrawButton(gui, obj.sections[1], 'SHOW', c, '99 99 99', true, -4)
    GUI_DrawButton(gui, obj.sections[2], '<<', c, '99 99 99', true, -2)
    GUI_DrawButton(gui, obj.sections[3], '>>', c, '99 99 99', true, -2)
    GUI_DrawButton(gui, obj.sections[5], 'HIDE', c, '99 99 99', true, -4)
    GUI_DrawButton(gui, obj.sections[6], 'SET UP', c, '99 99 99', true, -4)
    local pt = ''
    if currentpreset ~= '' then
      pt = ': '..currentpreset
    end
    GUI_DrawButton(gui, obj.sections[14], 'PRESET'..pt, c, '99 99 99', true, -4)
    
    --[[GUI_DrawButton(gui, obj.sections[7], dirtable[dir+1], c, '99 99 99', true, -4)

    local alt = ''
    if dir == 0 or dir == 1 then
      alt = aligntable2[align+1]
    elseif dir ~= 3 then
      alt = aligntable1[align+1]
    else
      alt = aligntable1[2]
    end
        
    GUI_DrawButton(gui, obj.sections[8], alt, c, '99 99 99', true, -4)]]
    if pg and pg[tpage] then
      GUI_text(gui, obj.sections[4], tpage+1 ..'/'..#pg+1, 5, tcol, -4)
    end

    if pos and #pos > 0 then
    
      local pages = pos[#pos].page
      local nw = math.max(math.floor(obj.sections[10].w / butt_h),1)-1
      local dw = math.floor(obj.sections[10].w / (nw+1))
      local nh = math.floor(pages / (nw+1))
      
      for y = 0, nh do
        for x = 0, nw do
          local p = y*(nw+1)+x
          if p <= pages then
            local xywh = {x = obj.sections[10].x + dw*x,
                          y = obj.sections[10].y + butt_h*y,
                          w = dw,
                          h = butt_h-1}
            local bc, tc = '255 220 128', '99 99 99'
            if p ~= tpage then
              bc = '0 0 0'
              tc = '200 200 200'              
            end
            
            GUI_DrawButton(gui, xywh, p+1, bc, tc, true, -1)
          end
        end
      end
    
      obj.sections[11] = {x = 10,
                          y = obj.sections[10].y + butt_h * (nh+1) +10,
                          w = obj.sections[10].w,
                          h = gfx1.main_h - (obj.sections[10].y+(butt_h * (nh+1)))}
      local txt_h = txt_h
      if not pos[posoff+1] then
        posoff = 0
      end
      local lpg = pos[posoff+1].page
      list_cnt = math.floor(obj.sections[11].h / txt_h)-1
      
      for i = 1, list_cnt do
        local ii = i + posoff
        if pos[ii] then
          local xywh = {x = obj.sections[11].x,
                        y = obj.sections[11].y + (txt_h * (i-1)),
                        w = obj.sections[11].w,
                        h = txt_h}
          local tcol = '200 200 200'
          if pos[ii].page == tpage then
            tcol = '0 0 0'
            local bcol = '255 220 128'
            if not fxblacklist[pos[ii].fxname] then
              --bcol = '196 156 64'
              f_Get_SSV(bcol) 
              gfx.rect(xywh.x-3,xywh.y,xywh.w+6,xywh.h,1)
            end
          end
          if fxblacklist[pos[ii].fxname] then
            tcol = '80 80 80'
          end
          GUI_text(gui, xywh, pos[ii].fxname, 4, tcol, -4)
          
          if pos[ii].page ~= lpg then

            local ys = obj.sections[11].y + math.floor((txt_h * (i-1))) --+ 0.5*txt_h)
            local x = obj.sections[11].x-7
            f_Get_SSV('32 32 32')
            gfx.line(x,ys,x+obj.sections[11].w+14,ys)             
            f_Get_SSV('100 100 100')
            gfx.line(x,ys,x+4,ys)
            
            lpg = pos[ii].page
            
          end
        end
      end
    end

  end

  function GUI_DrawButton(gui, xywh, txt, bcol, tcol, val, tsz, flags, padx)
  
    f_Get_SSV(bcol)
    gfx.rect(xywh.x,
             xywh.y,
             xywh.w,
             xywh.h, 1)
    local xywh2 = {x = xywh.x+(padx or 0), y = xywh.y, w = xywh.w, h = xywh.h}
    GUI_text(gui, xywh2, txt, flags or 5, tcol, tsz)
    
  end
  
  function trim1(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
  end
  
  function CropFXName(n)
  
    if n == nil then
      return ""
    else
      local fxn = string.match(n, ': (.+)%(')
      if fxn then
        return trim1(fxn)
      else
        --fxn = string.match(n, '.+/(.*)')
        --if fxn and fxn ~= '' then
        --  return trim1(fxn)
        --else
          return trim1(n)
        --end
      end
    end
    
  end
   
  ------------------------------------------------------------
  
  function Lokasenna_Window_At_Center (w, h)
    -- thanks to Lokasenna 
    -- http://forum.cockos.com/showpost.php?p=1689028&postcount=15    
    local l, t, r, b = 0, 0, w, h    
    local __, __, screen_w, screen_h = reaper.my_getViewport(l, t, r, b, l, t, r, b, 1)    
    local x, y = (screen_w - w) / 2, (screen_h - h) / 2    
    gfx.init("LBX FX POSITIONER", w, h, 0, x, y)  
  end

 -------------------------------------------------------------     
      
  function F_limit(val,min,max)
      if val == nil or min == nil or max == nil then return end
      local val_out = val
      if val < min then val_out = min end
      if val > max then val_out = max end
      return val_out
    end   
  ------------------------------------------------------------
    
  function MOUSE_click(b)
    if mouse.mx > b.x and mouse.mx < b.x+b.w
      and mouse.my > b.y and mouse.my < b.y+b.h 
      and mouse.LB 
      and not mouse.last_LB then
     return true 
    end 
  end

  function MOUSE_click_RB(b)
    if mouse.mx > b.x and mouse.mx < b.x+b.w
      and mouse.my > b.y and mouse.my < b.y+b.h 
      and mouse.RB 
      and not mouse.last_RB then
     return true 
    end 
  end

  function MOUSE_over(b)
    if mouse.mx > b.x and mouse.mx < b.x+b.w
      and mouse.my > b.y and mouse.my < b.y+b.h 
      then
     return true 
    end 
  end
  
  ------------------------------------------------------------

  function GetTrackChunk(track)
    if not track then return end
    local fast_str, track_chunk
    fast_str = reaper.SNM_CreateFastString("")
    if reaper.SNM_GetSetObjectState(track, fast_str, false, false) then
    track_chunk = reaper.SNM_GetFastString(fast_str)
    end
    reaper.SNM_DeleteFastString(fast_str)  
    return track_chunk
  end
  
  function SetTrackChunk(track, track_chunk, usefix)
    usefix = false --force as fix isn't needed 
    if not (track and track_chunk) then return end
    local ret
    
    if usefix == true then
      local fast_str = reaper.SNM_CreateFastString("")
      if reaper.SNM_SetFastString(fast_str, track_chunk) then
        ret = reaper.SNM_GetSetObjectState(track, fast_str, true, false)
      end
      reaper.SNM_DeleteFastString(fast_str)
    else
      ret = reaper.SetTrackStateChunk(track,track_chunk,false)    
    end
    return ret
  end
    
  function nz(val, d)
    if val == nil then return d else return val end
  end
  function zn(val, d)
    if val == '' or val == nil then return d else return val end
  end
  
  function PositionFXForTrack_Auto()
  
    reaper.Undo_BeginBlock2(0)
  
    local tr = reaper.GetSelectedTrack2(0,0,true)
    local mstr = '(FLOAT.- %-?%d+ %-?%d+ %-?%d+ %-?%d+\n)'   
    if not tr then return end
    
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_S&M_WNCLS4'),0)
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_S&M_WNCLS6'),0)
    local fxc = reaper.TrackFX_GetCount(tr)
    trackfxcount = fxc
     
    local chunk = GetTrackChunk(tr)
    
    local chs, che
    chs, _ = string.find(chunk,'<FXCHAIN')
    local level = 0
    local cpos = chs 
    repeat
      local s,e = string.find(chunk,'[%<%>]',cpos)
      if s then
        local char = string.sub(chunk,s-1,s)
        if char == '\n<' then
          level = level + 1 
        elseif char == '\n>' then  
          level = level - 1 
        end      
      end
      cpos = s+1 
      if level == 0 then che = s break end
    until level == 0 
    
    if chs == nil or che == nil then return end
       
    local fchunk = string.sub(chunk,chs,che)
    
    cnt = 0
    openfx = {}
    local _ = string.gsub(fchunk,
                          mstr,
                          function(d) return Pass0(tr,d) end)
    CloseFX(openfx, tr)
    openfx = nil
    local chunk = GetTrackChunk(tr)
    local chs, che
    chs, _ = string.find(chunk,'<FXCHAIN')
    local level = 0
    local cpos = chs 
    repeat
      local s,e = string.find(chunk,'[%<%>]',cpos)
      if s then
        local char = string.sub(chunk,s-1,s)
        if char == '\n<' then
          level = level + 1 
        elseif char == '\n>' then  
          level = level - 1 
        end      
      end
      cpos = s+1 
      if level == 0 then che = s break end
    until level == 0    
    local fchunk = string.sub(chunk,chs,che)

    xpos = monitor.x
    ypos = monitor.y
    maxh = 0
    mmh = 0
    mmw = 0
    maxw = 0
    page = 0
    pos = {}
    pg = {}
    rc_p = 0
    rc_sz = {}
    cnt = 0
    ubl = false
    local pchunk = string.gsub(fchunk,
                              mstr,
                              function(d) return Pass1(tr, d) end)
    reaper.SetExtState(SCRIPT,'fx_posdata_cnt',#pos,false)
    for pp = 1, #pos do
    
      local p = pos[pp].page
      local sw = pg[p].maxw
      local sh = pg[p].mmh --pg[p].yp + pg[p].maxh
  
      local xoff = math.max(math.floor((monitor.w-sw)/2),0)
      local yoff = math.max(math.floor((monitor.h/2)-(sh/2)),0)
      
      if dir == 0 then

        if rc_sz[pos[pp].rc] then
          if align == 1 then
            yoff = yoff + math.floor((rc_sz[pos[pp].rc]-pos[pp].h)/2)
          elseif align == 2 then
            yoff = yoff + math.floor((rc_sz[pos[pp].rc]-pos[pp].h))        
          end
        end
        pos[pp].x = pos[pp].x + xoff
        pos[pp].y = pos[pp].y + yoff
        
      elseif dir == 4 then
      
        sw = pg[p].mmw
        sh = pg[p].maxh
        
        yoff = math.max(math.floor((monitor.h-sh)/2),0)
        xoff = math.max(math.floor((monitor.w/2)-(sw/2)),0)
        
        if rc_sz[pos[pp].rc] then
          if align == 1 then
            xoff = xoff + math.floor((rc_sz[pos[pp].rc]-pos[pp].w)/2)
          elseif align == 2 then
            xoff = xoff + math.floor((rc_sz[pos[pp].rc]-pos[pp].w))        
          end
        end
        
        pos[pp].x = pos[pp].x + xoff
        pos[pp].y = pos[pp].y + yoff
      
      elseif dir == 1 then
      
        pos[pp].x = pos[pp].x + xoff
        if align == 0 then
          yoff = math.floor(((monitor.h)/2) - (pg[pos[pp].page].maxh/2))
        elseif align == 1 then
          yoff = math.floor(((monitor.h)/2) - (pos[pp].h/2))
        elseif align == 2 then
          yoff = math.floor(((monitor.h)/2) - (pg[pos[pp].page].maxh/2)) + (pg[pos[pp].page].maxh - pos[pp].h)
        end
        pos[pp].y = monitor.y + yoff
        
      elseif dir == 2 then
        if align == 0 then
          xoff = math.floor(((monitor.w)/2) - (pg[pos[pp].page].maxw/2))
        elseif align == 1 then
          xoff = math.floor(((monitor.w)/2) - (pos[pp].w/2))
        elseif align == 2 then
          xoff = math.floor(((monitor.w)/2) - (pg[pos[pp].page].maxw/2)) + (pg[pos[pp].page].maxw - pos[pp].w)
        end
        pos[pp].x = monitor.x + xoff
        pos[pp].y = pos[pp].y + yoff
        
      elseif dir == 3 then
        pos[pp].x = monitor.x + math.floor(((monitor.w)/2) - (pos[pp].w/2))
        pos[pp].y = monitor.y + math.floor(((monitor.h)/2) - (pos[pp].h/2))
      end
          
      local posstr = pos[pp].page ..' '.. BoolToNum(pos[pp].blacklist) ..' '.. pos[pp].x ..' '.. pos[pp].y ..' '.. pos[pp].w ..' '.. pos[pp].h
      reaper.SetExtState(SCRIPT,'fx_posdata_'..pp,posstr,false)
    end
    
    cnt = 0
    
    fchunk = string.gsub(fchunk,
                mstr,
                function(d) return Repos(d, p) end)
    
    local tchunk = string.sub(chunk,1,chs-1)..fchunk..string.sub(chunk,che+1)
    SetTrackChunk(tr, tchunk)
    
    reaper.Undo_EndBlock2(0, 'Show Plugins', 0)
    --OpenFX(tpage)
  end

  function BoolToNum(x)
    if x == true then
      return 1
    else
      return 0
    end
  end

  function CloseFX(cfx, tr)
    if #cfx > 0 then
      for i = 1, #cfx do
        reaper.TrackFX_Show(tr,cfx[i],2) 
      end
    end
  end
  
  function Pass0(tr, t)

    local d = {}
    for i in t:gmatch("[%-?%d%.]+") do 
      d[#d+1] = tonumber(i)
    end

    --float plugin
    if d[3] == 0 or d[4] == 0 then
      openfx[#openfx+1] = cnt
      reaper.TrackFX_Show(tr,cnt,3) 
    end
    
    cnt = cnt + 1
  
  end
  
  function Pass1(tr, t)

    cnt = cnt + 1
    local d = {}
    for i in t:gmatch("[%-?%d%.]+") do 
      d[#d+1] = tonumber(i)
    end

    local _, fxnm = reaper.TrackFX_GetFXName(tr,cnt-1,'')
    if fxnm then
      fxnm = CropFXName(fxnm)
    else
      fxnm = '[unknown fx]'
    end
    local blacklist = false
    if fxblacklist[fxnm] == true then
      blacklist = true
    end
    
    if blacklist == false then
      if dir == 0 then
        if xpos + d[3] > monitor.x + monitor.w then
          xpos = monitor.x
          ypos = ypos + maxh
          maxh = 0
          rc_p = rc_p + 1
        end
    
        maxh = math.max(maxh, d[4])
    
        if ypos + maxh > monitor.y + monitor.h and cnt > 1 then
          page = page + 1
          xpos = monitor.x
          ypos = monitor.y
          maxw = 0
          mmh = 0
          maxh = d[4]
          rc_p = rc_p + 1
        end
        
        rc_sz[rc_p] = math.max(rc_sz[rc_p] or 0,d[4])
        maxw = math.max(maxw,xpos + d[3] - monitor.x) 
        mmh = math.max(mmh,ypos + maxh -monitor.y)

      elseif dir == 4 then
        if ypos + d[4] > monitor.y + monitor.h then
          ypos = monitor.y
          xpos = xpos + maxw
          maxw = 0
          rc_p = rc_p + 1
        end
    
        maxw = math.max(maxw, d[3])
    
        if xpos + maxw > monitor.x + monitor.w and cnt > 1 then
          page = page + 1
          xpos = monitor.x
          ypos = monitor.y
          maxh = 0
          mmw = 0
          maxw = d[3]
          rc_p = rc_p + 1
        end
        
        rc_sz[rc_p] = math.max(rc_sz[rc_p] or 0,d[3])
        maxh = math.max(maxh,ypos + d[4] - monitor.y) 
        mmw = math.max(mmw,xpos + maxw -monitor.x)
  
      elseif dir == 1 then
  
        maxh = math.max(maxh, d[4])
        if xpos + d[3] > monitor.x + monitor.w and cnt > 1 then
          page = page + 1
          xpos = monitor.x
          ypos = monitor.y
          maxw = 0
          maxh = d[4]
        end
        maxw = math.max(maxw,xpos + d[3] - monitor.x) 
      
      elseif dir == 2 then
      
        maxw = math.max(maxw, d[3])
        if ypos + d[4] > monitor.y + monitor.h and cnt > 1 then
          page = page + 1
          xpos = monitor.x
          ypos = monitor.y
          maxh = 0
          mmh = 0
          maxw = d[3]
        end
        mmh = mmh + d[4]
        maxh = math.max(maxh,d[4]) 
  
      elseif dir == 3 then
        maxw = math.max(maxw, d[3])
        xpos = monitor.x
        ypos = monitor.y
        maxw = d[3]
        maxh = math.max(maxh,d[4])
        
        if ubl == true then
          page = page + 1
        end
        ubl = true  
      end

    end
    
    pos[cnt] = {fxname = fxnm,
                page = page,
                rc = rc_p,
                 x = xpos, y = ypos,
                 w = d[3], h = d[4],
                 blacklist = blacklist}

    local mw, mh = 0,0
    if pg[page] then
      mw = pg[page].maxw
      mh = pg[page].maxh
    end
    
    pg[page] = {maxw = math.max(mw, maxw), maxh = math.max(mh, maxh), yp = ypos, mmw = mmw, mmh = mmh}
    
    if blacklist == false then
      if dir == 0 then
        xpos = xpos + d[3]
      elseif dir == 4 then
        ypos = ypos + d[4]
      elseif dir == 1 then
        xpos = xpos + d[3]
      elseif dir == 2 then
        ypos = ypos + d[4]
      end
    end
        
    return t
    
  end
  
  function Repos(t)
    
    cnt=cnt+1
    local d = {}
    for i in t:gmatch("[%-?%d%.]+") do 
      d[#d+1] = tonumber(i)
    end
        
    t = 'FLOATPOS '..string.format('%i',pos[cnt].x)..' '..string.format('%i',pos[cnt].y)..' '..pos[cnt].w..' '..pos[cnt].h..'\n'
    
    return t
    
  end

  function OpenFX(page)
  
    reaper.Undo_BeginBlock2(0)
    
    local tr = reaper.GetSelectedTrack2(0,0,true)       
    if not tr then return end
    if pos and #pos > 0 then

      if page > pos[#pos].page then
        page = pos[#pos].page 
      end
    
      for p = 1, #pos do
      
        if pos[p].page == page and pos[p].blacklist ~= true then
          reaper.TrackFX_Show(tr,p-1,3)
        else
          reaper.TrackFX_Show(tr,p-1,2)
        end
        
      end
    end
    
    reaper.Undo_EndBlock2(0, 'Show Plugins', 0)
    
  end
  
  ------------------------------------------------------------    
  function UpdateTPage()
  
    local p = tonumber(GES('tpage',true))
    if p and p ~= tpage then
      tpage = p
      posoff = 0
      update_gfx = true
    end
  
  end
  
  function run()
  
    local rt = reaper.time_precise()  
    
    if gfx.w ~= last_gfx_w or gfx.h ~= last_gfx_h or force_resize or obj == nil then
      local r = false
      if not r or gfx.dock(-1) > 0 then 
        gfx1.main_w = gfx.w
        gfx1.main_h = gfx.h
        win_w = gfx.w
        win_h = gfx.h
  
        last_gfx_w = gfx.w
        last_gfx_h = gfx.h
                
        gui = GetGUI_vars()
        obj = GetObjects()
        
        resize_display = true
        update_gfx = true        
      end
    end
    
    GUI_draw(obj, gui)
    
    mouse.mx, mouse.my = gfx.mouse_x, gfx.mouse_y
    mouse.LB = gfx.mouse_cap&1==1
    mouse.RB = gfx.mouse_cap&2==2
    mouse.ctrl = gfx.mouse_cap&4==4
    mouse.shift = gfx.mouse_cap&8==8
    mouse.alt = gfx.mouse_cap&16==16
    
    -------------------------------------------
    
    if nextupdate < reaper.time_precise() then
      UpdateTPage()
      
      if settings.followtrack == true then
        local tn = reaper.GetSelectedTrack2(0,0,true)
        if tn ~= tracknum then
          tracknum = tn
          
          tpage = -1
          PositionFXForTrack_Auto()
          if settings.floatontrackchange == true then
            tpage = 0
            OpenFX(tpage)
          end
          reaper.SetExtState(SCRIPT,'tpage',nz(tpage,0),false)
          update_gfx = true
          
        end
      end
      
      if settings.monitortrackfx == true then
        local tr = reaper.GetSelectedTrack2(0,0,true)
        if tr then
          local fxc = reaper.TrackFX_GetCount(tr)
          if fxc ~= trackfxcount then
            tpage = -1
            local otfxc = trackfxcount    
            PositionFXForTrack_Auto()
            
            if settings.autopositionnewfx == true and fxc > otfxc then
              --HideFX()
              reaper.TrackFX_Show(tr,fxc-1,2)
              local pcnt = 0
              if pg then pcnt = #pg end
              tpage = pcnt
              OpenFX(tpage)              
            end
            
            reaper.SetExtState(SCRIPT,'tpage',nz(tpage,0),false)
            trackfxcount = fxc
            update_gfx = true
          end
        end
      end
      
      nextupdate = reaper.time_precise() + 0.3
    end
    
    if setup ~= true then
      if mouse.context == nil then
      
        if gfx.mouse_wheel ~= 0 then
        
          if MOUSE_over(obj.sections[11]) then
            if pos then
              local v = gfx.mouse_wheel/120
  
              posoff = F_limit(posoff - v, 0, math.max(0,#pos-list_cnt))
              update_gfx = true
            end        
          end
          gfx.mouse_wheel = 0
          
        elseif MOUSE_click(obj.sections[1]) then
        
          tpage = 0
          PositionFXForTrack_Auto()
          OpenFX(tpage)
          
          reaper.SetExtState(SCRIPT,'tpage',nz(tpage,0),false)
          update_gfx = true
        
        elseif MOUSE_click(obj.sections[2]) then
        
          if settings.looppages == false then
            tpage = math.max(tpage - 1,0)
          else
  
            local pgcnt = 0
            if pg then pgcnt = #pg end
  
            tpage = tpage - 1
            if tpage < 0 then
              tpage = pgcnt
            end 
          end
          --PositionFXForTrack_Auto()   
          OpenFX(tpage)     
          reaper.SetExtState(SCRIPT,'tpage',nz(tpage,0),false)
          update_gfx = true
        
        elseif MOUSE_click(obj.sections[3]) then
        
          local pgcnt = 0
          if pg then pgcnt = #pg end
          
          if settings.looppages == false then
            tpage = math.min(tpage + 1,pgcnt)
          else
  
            tpage = tpage + 1
            if tpage > pgcnt then
              tpage = 0
            end 
          end
    
          OpenFX(tpage)        
          reaper.SetExtState(SCRIPT,'tpage',nz(tpage,0),false)
          update_gfx = true
  
        elseif MOUSE_click(obj.sections[5]) then
          HideFX()
          
        elseif MOUSE_click(obj.sections[6]) then
        
          SetUp()
  
        elseif MOUSE_click_RB(obj.sections[6]) then
  
          SetUpMenu()
  
        elseif MOUSE_click(obj.sections[11]) then
        
          local y = math.floor((mouse.my-obj.sections[11].y) / txt_h)+1 + posoff
          if pos and pos[y] then
          
            if mouse.ctrl ~= true then
              if not fxblacklist[pos[y].fxname] then
                tpage = pos[y].page
                OpenFX(tpage)
                
                reaper.SetExtState(SCRIPT,'tpage',nz(tpage,0),false)
                update_gfx = true
              end
            else
              if fxblacklist[pos[y].fxname] == true then
                fxblacklist[pos[y].fxname] = nil
              else
                fxblacklist[pos[y].fxname] = true
              end
              update_gfx = true
              
              PositionFXForTrack_Auto()
              OpenFX(tpage)
              
              SaveBlacklist()
            end
          end
        
        elseif MOUSE_click_RB(obj.sections[11]) then
          HideFX()
        
        elseif MOUSE_click(obj.sections[10]) then
        
          if pos then
            local pages = pos[#pos].page
            local nw = math.max(math.floor(obj.sections[10].w / butt_h),1)-1
            local dw = math.floor(obj.sections[10].w / (nw+1))
            local x = math.floor((mouse.mx-obj.sections[10].x) / dw)
            local y = math.floor((mouse.my-obj.sections[10].y) / butt_h)
            local p = x + y*(nw+1)
        
            if p <= pages then
              tpage = p
              OpenFX(tpage)        
              reaper.SetExtState(SCRIPT,'tpage',nz(tpage,0),false)
              update_gfx = true
            end 
          end
  
        elseif MOUSE_click_RB(obj.sections[10]) then
          HideFX()

        elseif MOUSE_click(obj.sections[14]) then
        
          PresetMenu()
        
        end
      
      end
    
    else
      --SETUP
      if mouse.context == nil then
      
        if MOUSE_click(obj.sections[6]) then
                
          SetUp()
        
        elseif MOUSE_click(obj.sections[13]) then
        
          SetUp2()
          
        elseif MOUSE_click(obj.sections[7]) then
                  
          dir = dir + 1
          if dir > #dirtable-1 then
            dir = 0
          end
          reaper.SetExtState(SCRIPT,'dir',dir,true)
          tpage = 0
          PositionFXForTrack_Auto()
          OpenFX(tpage)
          
          reaper.SetExtState(SCRIPT,'tpage',nz(tpage,0),false)        
          update_gfx = true
  
        elseif MOUSE_click_RB(obj.sections[7]) then
          
          dir = dir - 1
          if dir < 0 then
            dir = #dirtable-1
          end
          reaper.SetExtState(SCRIPT,'dir',dir,true)
          tpage = 0
          PositionFXForTrack_Auto()
          OpenFX(tpage)
          
          reaper.SetExtState(SCRIPT,'tpage',nz(tpage,0),false)
          update_gfx = true
          
        elseif MOUSE_click(obj.sections[8]) then
          
          align = align + 1
          if align > #aligntable1-1 then
            align = 0
          end
          reaper.SetExtState(SCRIPT,'align',align,true)
          PositionFXForTrack_Auto()
          OpenFX(tpage)
          
          update_gfx = true
  
        elseif MOUSE_click_RB(obj.sections[8]) then
          
          align = align - 1
          if align < 0 then
            align = #aligntable1-1 
          end
          reaper.SetExtState(SCRIPT,'align',align,true)
          PositionFXForTrack_Auto()
          OpenFX(tpage)
          
          update_gfx = true

        elseif MOUSE_click(obj.sections[15]) then
        
          local ret, ffn = reaper.GetUserInputs('Please enter preset filename',1,'Preset Filename:,extrawidth=100','')
          if ret == true then
          
            SavePreset(ffn)
            
          end
        end
      end
    end
    -------------------------------------------
      
      if not mouse.LB and not mouse.RB then mouse.context = nil end
      local char = gfx.getchar() 
      if char then 
        if char == 32 then reaper.Main_OnCommandEx(40044, 0,0) end
        if char>=0 and char~=27 then reaper.defer(run) end
      else
        reaper.defer(run)
      end
      gfx.update()
      mouse.last_LB = mouse.LB
      mouse.last_RB = mouse.RB
      mouse.last_x = mouse.mx
      mouse.last_y = mouse.my
      if mouse.LB then
        mouse.lastLBclicktime = rt
      end
      gfx.mouse_wheel = 0
      
      if refresh_gfx and mouse.context == nil and reaper.time_precise() >= refresh_gfx then
        refresh_gfx = nil
        update_gfx = true
      end
      
  end
  
  function HideFX()
  
    tpage = -1
    reaper.SetExtState(SCRIPT,'tpage',nz(tpage,0),false)
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_S&M_WNCLS4'),0)
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_S&M_WNCLS3'),0)
    update_gfx = true
    
  end
  
  function PresetMenu()

    local txt = ''
    for i = 1, #presets do
      if txt ~= '' then
        txt = txt..'|'
      end
      txt = txt..presets[i]
      
    end
    if txt ~= '' then
      gfx.x = mouse.mx
      gfx.y = mouse.my
      local res = gfx.showmenu(txt)
      if res > 0 then

        if presets[res] then
          local fn = presets[res]
          LoadPreset(fn)
          
          tpage = 0
          PositionFXForTrack_Auto()
          OpenFX(tpage)
          
          reaper.SetExtState(SCRIPT,'tpage',nz(tpage,0),false)        
          update_gfx = true
        end
      end
    end
  end
  
  function SetUpMenu()
  
    local txt = ''
    if settings.followtrack == true then
      txt = '!'
    end
    txt = txt .. 'Follow Selected Track'
    local tk = ''
    if settings.floatontrackchange == true then
      tk = '!'
    end
    txt = txt..'|'..tk .. 'Float FX On Track Change'
    local tk = ''
    if settings.looppages == true then
      tk = '!'
    end
    txt = txt..'|'..tk .. 'Loop pages'
    local tk = ''
    if settings.monitortrackfx == true then
      tk = '!'
    end
    txt = txt..'|'..tk .. 'Auto monitor track fx changes'
    local tk = ''
    if settings.autopositionnewfx == true then
      tk = '!'
    end
    txt = txt..'|'..tk .. 'Auto position new fx'
    local tk = ''
    if settings.focarr == true then
      tk = '!'
    end
    txt = txt..'|'..tk .. 'Auto focus arrange window after positioning'
    
    local mstr = txt
    gfx.x,gfx.y = mouse.mx,mouse.my
  
    local res = gfx.showmenu(mstr)
    if res > 0 then
      if res == 1 then
        settings.followtrack = not settings.followtrack 
      elseif res == 2 then
        settings.floatontrackchange = not settings.floatontrackchange
        SaveSettings()
      elseif res == 3 then
        settings.looppages = not settings.looppages
        SaveSettings()
      elseif res == 4 then
        settings.monitortrackfx = not settings.monitortrackfx
        if settings.monitortrackfx == false then
          settings.autopositionnewfx = false
        end
        SaveSettings()
      elseif res == 5 then
        settings.autopositionnewfx = not settings.autopositionnewfx
        if settings.autopositionnewfx == true then
          settings.monitortrackfx = true
        end
        SaveSettings()
      elseif res == 6 then
        settings.focarr = not settings.focarr
        SaveSettings()
      end
    end
  
  end

  function SetUp()
    setup = not setup
    update_gfx = true
  end
    
  function SetUp2()
    
    --'FIT','HORIZ','VERT','SINGLE','COLUMNS'
    local rv, csv = reaper.GetUserInputs('Set up:',4,'Monitor X (pixels),Monitor Y,Monitor Width,Monitor Height',monitor.x..','..monitor.y..','..monitor.w..','..monitor.h)
    if rv == true then
      csv = csv..','
      local d = {}
      for i in csv:gmatch("(.-),") do
        d[#d+1] = tonumber(i)
      end
      if tonumber(d[1]) and tonumber(d[2]) and tonumber(d[3]) and tonumber(d[4]) then
        monitor.x = tonumber(d[1])
        monitor.y = tonumber(d[2])
        monitor.w = tonumber(d[3])
        monitor.h = tonumber(d[4])
      
        SaveSettings()
      
      else
        reaper.MB('Invalid values', 'Setup Error', 0)
      end
    end
    
  end
  
  function quit()
  
    SaveSettings()      
    gfx.quit()
    
  end
  
  function GES(key, nilallowed)
    if nilallowed == nil then nilallowed = false end
    
    local val = reaper.GetExtState(SCRIPT,key)
    if nilallowed then
      if val == '' then
        val = nil
      end
    end
    return val
  end
  
  function SaveSettings()
  
    a,x,y,w,h = gfx.dock(-1,1,1,1,1)
    if gfx1 then
      reaper.SetExtState(SCRIPT,'dock',nz(a,0),true)
      reaper.SetExtState(SCRIPT,'win_x',nz(x,0),true)
      reaper.SetExtState(SCRIPT,'win_y',nz(y,0),true)    
      reaper.SetExtState(SCRIPT,'win_w',nz(gfx1.main_w,400),true)
      reaper.SetExtState(SCRIPT,'win_h',nz(gfx1.main_h,450),true)

      reaper.SetExtState(SCRIPT,'mon_x',nz(monitor.x,0),true) 
      reaper.SetExtState(SCRIPT,'mon_y',nz(monitor.y,0),true) 
      reaper.SetExtState(SCRIPT,'mon_w',nz(monitor.w,1920),true) 
      reaper.SetExtState(SCRIPT,'mon_h',nz(monitor.h,1080),true)       
      reaper.SetExtState(SCRIPT,'dir',dir,true)       
      reaper.SetExtState(SCRIPT,'align',align,true)       
      reaper.SetExtState(SCRIPT,'settings_followtrack',tostring(settings.followtrack),true)
      reaper.SetExtState(SCRIPT,'settings_looppages',tostring(settings.looppages),true)
      reaper.SetExtState(SCRIPT,'settings_floatontrackchange',tostring(settings.floatontrackchange),true)

      reaper.SetExtState(SCRIPT,'settings_monitortrackfx',tostring(settings.monitortrackfx),true)
      reaper.SetExtState(SCRIPT,'settings_autopositionnewfx',tostring(settings.autopositionnewfx),true)

      reaper.SetExtState(SCRIPT,'settings_focarr',tostring(settings.focarr),true)
    end
  
    SaveBlacklist()
  end
  
  function LoadSettings()
  
    local x, y = GES('win_x',true), GES('win_y',true)
    local ww, wh = GES('win_w',true), GES('win_h',true)
    local d = GES('dock',true)
    if x == nil then x = 0 end
    if y == nil then y = 0 end
    if d == nil then d = gfx.dock(-1) end    
    if ww ~= nil and wh ~= nil then
      gfx1 = {main_w = tonumber(ww),
              main_h = tonumber(wh)}
      gfx.init("FX POSITIONER", gfx1.main_w, gfx1.main_h, 0, x, y)
      gfx.dock(d)
    else
      gfx1 = {main_w = 400, main_h = 450}
      Lokasenna_Window_At_Center(gfx1.main_w,gfx1.main_h)  
    end

    local mx, my = GES('mon_x',true), GES('mon_y',true)
    local mw, mh = GES('mon_w',true), GES('mon_h',true)
    monitor = {x = nz(tonumber(mx),0),
               y = nz(tonumber(my),0),
               w = nz(tonumber(mw),1920),
               h = nz(tonumber(mh),1080)}
    dir = nz(tonumber(GES('dir',true)),0)
    align = nz(tonumber(GES('align',true)),0)
    
    settings.followtrack = tobool(GES('settings_followtrack',true))
    settings.looppages = tobool(nz(GES('settings_looppages',true),false))
    settings.floatontrackchange = tobool(nz(GES('settings_floatontrackchange',true),false))
    settings.monitortrackfx = tobool(nz(GES('settings_monitortrackfx',true),false))
    settings.autopositionnewfx = tobool(nz(GES('settings_autopositionnewfx',true),false))
    settings.focarr = tobool(nz(GES('settings_focarr',true),true))

    LoadBlacklist()

  end
  
  function SavePreset(ffn)

    local fn = preset_path..ffn..'.txt'
    local cont = true
    if reaper.file_exists(fn) then
      if reaper.MB('Preset file exists - overwrite?','Save Preset',4) ~= 6 then
        cont = false
      end
    end
    
    if cont then
      file = io.open(fn,'wb')
      if file then
      
        file:write('[dir]'..dir.."\r\n")
        file:write('[align]'..align..'\r\n')
        file:write('[monX]'..monitor.x..'\r\n')
        file:write('[monY]'..monitor.y..'\r\n')
        file:write('[monW]'..monitor.w..'\r\n')
        file:write('[monH]'..monitor.h..'\r\n')
  
        file:close()
        
        presets = RefreshPresetList()
      end
    end
    
  end

  function RefreshPresetList()
  
    local plist = {}
    local p = 0
    local f = reaper.EnumerateFiles(preset_path, p)
    while f do
      local fn = string.match(f,'(.*).txt')
      if fn then
        plist[#plist+1] = fn
      end
      p = p + 1
      f = reaper.EnumerateFiles(preset_path, p)
    end
    
    return plist
    
  end

  function LoadPreset(ffn)

    currentpreset = ''
    
    local fn = preset_path..ffn..'.txt'
    if reaper.file_exists(fn) then
      local data = {}
      for line in io.lines(fn) do
        local key, val = string.match(line,'%[(.*)%](.*)')
        if key then
          data[key] = val
        end
      end

      local ldir = tonumber(data['dir'])
      local lalign = tonumber(data['align'])
      local lmonx = tonumber(data['monX'])
      local lmony = tonumber(data['monY'])
      local lmonw = tonumber(data['monW'])
      local lmonh = tonumber(data['monH'])
      
      if ldir and lalign and lmonx and lmony and lmonw and lmonh then
        dir = ldir
        align = align
        monitor.x = lmonx
        monitor.y = lmony
        monitor.w = lmonw
        monitor.h = lmonh
        --DBG('preset loaded')
        currentpreset = ffn
      else
      
        --invalid preset
      end
      update_gfx = true
    end
      
  end
  
  function SaveBlacklist()
  
    local fxblacklist = fxblacklist
    local fn = resource_path..'fxblacklist.txt'
    file = io.open(fn,'wb')
    if file then
      for k in pairs(fxblacklist) do
        file:write(k..'\r\n')
      end
      file:close()
    end
    
  end
  
  function LoadBlacklist()
  
    local fxblacklist = fxblacklist
    local fn = resource_path..'fxblacklist.txt'
    if reaper.file_exists(fn) == true then
      for line in io.lines(fn) do
        local key = line --string.match(line,'(.-)\n')
        if key then
          fxblacklist[key] = true
        end
      end
    end
  
  end
  
  function tobool(v)
  
    if v then
      if string.lower(v) == 'true' then
        return true
      else
        return false
      end
    else
      return false
    end
  end
  
  function preventUndo()
  end
  reaper.defer(preventUndo)
  
  ------------------------------------------------------------
  reaper.RecursiveCreateDirectory(resource_path,1)
  reaper.RecursiveCreateDirectory(preset_path,1)
  
  LoadSettings()
  
  presets = RefreshPresetList()
  
  run()
  reaper.atexit(quit)
  
  ------------------------------------------------------------

-- @version 0.01 
-- @author LBX
-- @changelog

--[[
   * ReaScript Name: SRD Smart Knobs
   * Lua script for Cockos REAPER
   * Author: Leon Bradley (LBX)
   * Author URI: 
   * Licence: GPL v3
  ]]
      
  local monitor = {x = 0, y = 0, w = 1920, h = 1080}
  
  local SCRIPT='LBX_FXPOS'
  
  local resource_path = reaper.GetResourcePath().."/Scripts/LBX/"
  local template_path = resource_path.."templates/"
  
  --reaper.RecursiveCreateDirectory(resource_path,1)
  --reaper.RecursiveCreateDirectory(template_path,1)
      
  local colours = {faderborder = '25 25 25',
             fader = '55 55 55',
             fader_inactive = '0 80 255',
             faderbg = '35 35 35',
             faderbg2 = '15 15 15',
             mainbg = '35 35 35',
             buttcol = '25 25 25',
             faderlit = '87 109 130',
             pnamelit = '107 129 150'}
  
  local update_gfx = true
  local resize_display = true
  
  local tpage = 0
  local mouse = {}


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
        
    --butt1
    obj.sections[1] = {x = 10,
                       y = 10,
                       w = gfx1.main_w-20,
                       h = butt_h}

    obj.sections[2] = {x = 10,
                       y = 10 + (butt_h+2),
                       w = gfx1.main_w/2-11,
                       h = butt_h}

    obj.sections[3] = {x = gfx1.main_w/2+1,
                       y = 10 + (butt_h+2),
                       w = gfx1.main_w/2-11,
                       h = butt_h}

    obj.sections[4] = {x = 10,
                       y = 10 + (butt_h+2)*2,
                       w = gfx1.main_w-20,
                       h = butt_h}                               

    obj.sections[5] = {x = 10,
                       y = 10 + (butt_h+2)*3,
                       w = gfx1.main_w-20,
                       h = butt_h}                               

    obj.sections[6] = {x = 10,
                       y = 10 + (butt_h+2)*4,
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

      GUI_DrawButtons(obj, gui)
      
    end
        
    gfx.dest = -1
    gfx.a = 1
    gfx.blit(1, 1, 0, 
      0,0, gfx1.main_w,gfx1.main_h,
      0,0, gfx1.main_w,gfx1.main_h, 0,0)
    
    update_gfx = false
    resize_display = false
    
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
    GUI_DrawButton(gui, obj.sections[1], 'SHOW FX', c, '99 99 99', true, -1)
    GUI_DrawButton(gui, obj.sections[2], '<<', c, '99 99 99', true, -1)
    GUI_DrawButton(gui, obj.sections[3], '>>', c, '99 99 99', true, -1)
    GUI_DrawButton(gui, obj.sections[5], 'HIDE FX', c, '99 99 99', true, -1)
    GUI_DrawButton(gui, obj.sections[6], 'SET UP', c, '99 99 99', true, -1)
    if pg and pg[tpage] then
      GUI_text(gui, obj.sections[4], 'Page '..tpage+1 ..'/'..#pg+1, 5, tcol, tsz)
    end

  end

  function GUI_DrawButton(gui, xywh, txt, bcol, tcol, val, tsz)
  
    f_Get_SSV(bcol)
    gfx.rect(xywh.x,
             xywh.y,
             xywh.w,
             xywh.h, 1)
    GUI_text(gui, xywh, txt, 5, tcol, tsz)
    
  end
  
 
  ------------------------------------------------------------
  
  function Lokasenna_Window_At_Center (w, h)
    -- thanks to Lokasenna 
    -- http://forum.cockos.com/showpost.php?p=1689028&postcount=15    
    local l, t, r, b = 0, 0, w, h    
    local __, __, screen_w, screen_h = reaper.my_getViewport(l, t, r, b, l, t, r, b, 1)    
    local x, y = (screen_w - w) / 2, (screen_h - h) / 2    
    gfx.init("SRD SMART CONTROL", w, h, 0, x, y)  
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

  function SetTrackChunk(track, track_chunk)
    if not (track and track_chunk) then return end
    local fast_str, ret
    fast_str = reaper.SNM_CreateFastString("")
    if reaper.SNM_SetFastString(fast_str, track_chunk) then
      ret = reaper.SNM_GetSetObjectState(track, fast_str, true, false)
    end
    reaper.SNM_DeleteFastString(fast_str)
    return ret
  end

  function GetPlugNameFromChunk(fxchunk)
  
    local fxn, fxt
    local s,e = string.find(fxchunk,'.-(\n)')
    local fxc = string.sub(fxchunk,1,e)
    if string.sub(fxc,1,3) == 'VST' then
      if string.match(fxc, '.-(VST3).-\n') then
        fxt = 'VST3'
      else
        fxt = 'VST'
      end
      fxn = string.match(fxc, '.-: (.-) %(')
      if fxn == nil then
        fxn = string.match(fxc, '.-: (.-)%"')      
      end
    elseif string.sub(fxc,1,2) == 'JS' then
      fxt = 'JS'
      fxn = string.match(fxc, 'JS.*%/+(.-) \"')
      if fxn == nil then
        fxn = string.match(fxc, 'JS%s(.-)%s')  -- gets full path of effect
        fxn = string.match(fxn, '([^/]+)$') -- gets filename  
      end
      --remove final " if exists
      if string.sub(fxn,string.len(fxn)) == '"' then
        fxn = string.sub(fxn,1,string.len(fxn)-1)
      end
      
      --[[if fxn == nil then
        --JS \"AB Level Matching JSFX [2.5]/AB_LMLT_cntrl\" \"MSTR /B\"\
        fxn = string.match(fxchunk, 'JS.*%/(.-)%"%\"')
        fxn = string.sub(fxn,1,string.len(fxn)-2)
      end]]
    end
  
    return fxn, fxt
    
  end
  
  --returns success, fxchunk, start loc, end loc
  function GetFXChunkFromTrackChunk(track, fxn)
  
    --local ret, trchunk = reaper.GetTrackStateChunk(track,'')
  local trchunk = GetTrackChunk(track)
    if trchunk then
      local s,e, fnd = 0,0,nil
      for i = 1,fxn do
        s, e = string.find(trchunk,'(BYPASS.-WAK %d)',s)
        if s and e then
          fxchunk = string.sub(trchunk,s,e)
    
          if i == fxn then fnd = true break end
          s=e+1
        else
          fxchunk = nil
          fnd = nil
          break
        end
      end
      return fnd, fxchunk, s, e  
    end
      
  end
    
  function nz(val, d)
    if val == nil then return d else return val end
  end
  function zn(val, d)
    if val == '' or val == nil then return d else return val end
  end
  
  function PositionFXForTrack_Auto()
  
    local tr = reaper.GetSelectedTrack2(0,0,true)
       
    if not tr then return end
    
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_S&M_WNCLS4'),0)
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_S&M_WNCLS6'),0)
    local fxc = reaper.TrackFX_GetCount(tr)
     
    local chunk = GetTrackChunk(tr)
    local partchunk = chunk

    xpos = monitor.x
    ypos = monitor.y
    maxh = 0
    maxw = 0
    page = 0
    pos = {}
    pg = {}
    cnt = 0
    local pchunk = string.gsub(chunk,
                              '(FLOAT.- %d+ %d+ %d+ %d+\n)',
                              function(d) return Pass1(d) end)

    if pg[tpage] then
      local sw = pg[tpage].maxw
      local sh = pg[tpage].yp + pg[tpage].maxh
  
      xoff = math.max(math.floor((monitor.w-sw)/2),0)
  
      yoff = math.max(math.floor((monitor.h-(sh))/2),0)
  
      page = 0
      cnt = 0
      
      chunk = string.gsub(chunk,
                  '(FLOAT.- %d+ %d+ %d+ %d+\n)',
                  function(d) return Repos(d) end)
    
      SetTrackChunk(tr, chunk)
    end
    
  end
  
  function Pass1(t)

    cnt = cnt + 1
    local d = {}
    for i in t:gmatch("[%d%.]+") do 
      d[#d+1] = tonumber(i)
    end
    
    if xpos + d[3] > monitor.x + monitor.w then
      xpos = monitor.x
      ypos = ypos + maxh
      maxh = 0
    end

    maxh = math.max(maxh, d[4])

    if ypos + maxh > monitor.y + monitor.h then
      page = page + 1
      xpos = monitor.x
      ypos = monitor.y
      maxw = 0
      maxh = d[4]
    end
    
    maxw = math.max(maxw,xpos + d[3] - monitor.x) 

    pos[cnt] = {page = page,
                 x = xpos, y = ypos,
                 w = d[3], h = d[4]}

    local mw, mh = 0,0
    if pg[page] then
      mw = pg[page].maxw
      mh = pg[page].maxh
    end

    pg[page] = {maxw = math.max(mw, maxw), maxh = math.max(mh, maxh), yp = ypos}
    
    xpos = xpos + d[3]
    
    return t
    
  end

  function Repos(t)
  
    cnt=cnt+1
    local d = {}
    for i in t:gmatch("[%d%.]+") do 
      d[#d+1] = tonumber(i)
    end
  
    if pos[cnt].page == tpage then
    
      t = 'FLOAT '..string.format('%i',pos[cnt].x+xoff)..' '..string.format('%i',pos[cnt].y+yoff)..' '..pos[cnt].w..' '..pos[cnt].h..'\n'
    
    end
    
    return t
    
  end
  
  
  ------------------------------------------------------------    
  
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
    
    if mouse.context == nil then
    
      if MOUSE_click(obj.sections[1]) then
      
        tpage = 0
        PositionFXForTrack_Auto()
        reaper.SetExtState(SCRIPT,'tpage',nz(tpage,0),true)
        update_gfx = true
      
      elseif MOUSE_click(obj.sections[2]) then
      
        tpage = math.max(tpage - 1,0)
        PositionFXForTrack_Auto()        
        reaper.SetExtState(SCRIPT,'tpage',nz(tpage,0),true)
        update_gfx = true
      
      elseif MOUSE_click(obj.sections[3]) then
      
        local pgcnt = 0
        if pg then pgcnt = #pg end
        
        tpage = math.min(tpage + 1,pgcnt)
        PositionFXForTrack_Auto()        
        reaper.SetExtState(SCRIPT,'tpage',nz(tpage,0),true)
        update_gfx = true

      elseif MOUSE_click(obj.sections[5]) then
        reaper.Main_OnCommand(reaper.NamedCommandLookup('_S&M_WNCLS4'),0)
        reaper.Main_OnCommand(reaper.NamedCommandLookup('_S&M_WNCLS3'),0)

      elseif MOUSE_click(obj.sections[6]) then
      
        SetUp()
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
  
  function SetUp()
  
    local rv, csv = reaper.GetUserInputs('Set up Monitor:',4,'Monitor X (pixels),Monitor Y,Monitor Width,Monitor Height',monitor.x..','..monitor.y..','..monitor.w..','..monitor.h)
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
    end
  
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
  end
  
  ------------------------------------------------------------
  
  --gfx1 = {main_w = 400, main_h = 450}  
  --Lokasenna_Window_At_Center(gfx1.main_w,gfx1.main_h)
  LoadSettings()
  run()
  reaper.atexit(quit)
  
  ------------------------------------------------------------

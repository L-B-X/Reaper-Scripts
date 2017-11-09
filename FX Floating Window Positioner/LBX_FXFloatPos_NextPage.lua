  local SCRIPT='LBX_FXPOS'
  
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
    
  ------------------------------------------------------------
  
  function nz(val, d)
    if val == nil then return d else return val end
  end
  function zn(val, d)
    if val == '' or val == nil then return d else return val end
  end
  
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

  -----------------------------------------------------------------
  
  function PositionFXForTrack_Auto()
    
    local tr = reaper.GetSelectedTrack2(0,0,true)
       
    if not tr then return end
    
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_S&M_WNCLS4'),0)
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_S&M_WNCLS6'),0)
    local fxc = reaper.TrackFX_GetCount(tr)
     
    local chunk = GetTrackChunk(tr)
    local mstr = '(FLOAT.- %-?%d+ %-?%d+ %-?%d+ %-?%d+\n)'

    xpos = monitor.x
    ypos = monitor.y
    maxh = 0
    maxw = 0
    page = 0
    pos = {}
    pg = {}
    cnt = 0
    local pchunk = string.gsub(chunk,
                              mstr,
                              function(d) return Pass1(d) end)

    if tpage > #pg then tpage = #pg end
    
    if pg[tpage] then
      local sw = pg[tpage].maxw
      local sh = pg[tpage].yp + pg[tpage].maxh
  
      xoff = math.max(math.floor((monitor.w-sw)/2),0)
  
      yoff = math.max(math.floor((monitor.h-(sh))/2),0)
  
      page = 0
      cnt = 0
      
      chunk = string.gsub(chunk,
                  mstr,
                  function(d) return Repos(d) end)
    
      SetTrackChunk(tr, chunk)
    end
    
  end
  
  function Pass1(t)

    cnt = cnt + 1
    local d = {}
    for i in t:gmatch("[%-?%d%.]+") do 
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
    for i in t:gmatch("[%-?%d%.]+") do 
      d[#d+1] = tonumber(i)
    end
  
    if pos[cnt].page == tpage then
    
      t = 'FLOAT '..string.format('%i',pos[cnt].x+xoff)..' '..string.format('%i',pos[cnt].y+yoff)..' '..pos[cnt].w..' '..pos[cnt].h..'\n'
    
    end
    
    return t
    
  end
  
  
  local mx, my = GES('mon_x',true), GES('mon_y',true)
  local mw, mh = GES('mon_w',true), GES('mon_h',true)
  monitor = {x = nz(tonumber(mx),0),
             y = nz(tonumber(my),0),
             w = nz(tonumber(mw),1920),
             h = nz(tonumber(mh),1080)}
  tpage = tonumber(GES('tpage',true)) or 0
  tpage=tpage+1
  
  PositionFXForTrack_Auto()
  reaper.SetExtState(SCRIPT,'tpage',nz(tpage,0),true)


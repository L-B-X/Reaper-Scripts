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
    
  function DBG(str)
   if str==nil then str="nil" end
   reaper.ShowConsoleMsg(tostring(str).."\n")
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
      local mstr = '(FLOAT.- %-?%d+ %-?%d+ %-?%d+ %-?%d+\n)'   
      if not tr then return end
      
      
      reaper.Main_OnCommand(reaper.NamedCommandLookup('_S&M_WNCLS4'),0)
      reaper.Main_OnCommand(reaper.NamedCommandLookup('_S&M_WNCLS6'),0)
      local fxc = reaper.TrackFX_GetCount(tr)
       
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
      CloseFX(openfx,tr)
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
      maxw = 0
      page = 0
      pos = {}
      pg = {}
      cnt = 0
      local pchunk = string.gsub(fchunk,
                                mstr,
                                function(d) return Pass1(d) end)
  
      reaper.SetExtState(SCRIPT,'fx_posdata_cnt',#pos,false)
      for pp = 1, #pos do
      
        local p = pos[pp].page
        local sw = pg[p].maxw
        local sh = pg[p].yp + pg[p].maxh
    
        local xoff = math.max(math.floor((monitor.w-sw)/2),0)
        local yoff = math.max(math.floor((monitor.h-(sh))/2),0)
        
        pos[pp].x = pos[pp].x + xoff
        pos[pp].y = pos[pp].y + yoff
      
        local posstr = pos[pp].page ..' '.. pos[pp].x ..' '.. pos[pp].y ..' '.. pos[pp].w ..' '.. pos[pp].h
        reaper.SetExtState(SCRIPT,'fx_posdata_'..pp,posstr,false)
      end
      
      cnt = 0
      
      fchunk = string.gsub(fchunk,
                  mstr,
                  function(d) return Repos(d, p) end)
    
  
      local tchunk = string.sub(chunk,1,chs-1)..fchunk..string.sub(chunk,che+1)
      SetTrackChunk(tr, tchunk)
      
      OpenFX(tpage)
    end
  
    function CloseFX(cfx,tr)
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
        --reaper.TrackFX_Show(tr,cnt,2) 
      end
      
      cnt = cnt + 1
    
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
          
      t = 'FLOATPOS '..string.format('%i',pos[cnt].x)..' '..string.format('%i',pos[cnt].y)..' '..pos[cnt].w..' '..pos[cnt].h..'\n'
      
      return t
      
    end
  
    function OpenFX(page)
    
      local tr = reaper.GetSelectedTrack2(0,0,true)       
      if not tr then return end
      if pos then
        for p = 1, #pos do
        
          if pos[p].page == page then
            reaper.TrackFX_Show(tr,p-1,3)
          else
            reaper.TrackFX_Show(tr,p-1,2)
          end
          
        end
      end
      
    end
  
  local mx, my = GES('mon_x',true), GES('mon_y',true)
  local mw, mh = GES('mon_w',true), GES('mon_h',true)
  monitor = {x = nz(tonumber(mx),0),
             y = nz(tonumber(my),0),
             w = nz(tonumber(mw),1920),
             h = nz(tonumber(mh),1080)}
  tpage = 0
  
  PositionFXForTrack_Auto()
  reaper.SetExtState(SCRIPT,'tpage',nz(tpage,0),true)
    

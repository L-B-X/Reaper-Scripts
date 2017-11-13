  local SCRIPT='LBX_FXPOS'
  local resource_path = reaper.GetResourcePath().."/Scripts/LBX/FXPositionerData/"
  
  local fxblacklist = {}
  
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
  
    reaper.Undo_BeginBlock2(0)
  
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
    OpenFX(tpage)
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
    
        if ypos + maxh > monitor.y + monitor.h then
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
    
        if xpos + maxw > monitor.x + monitor.w then
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
        if xpos + d[3] > monitor.x + monitor.w then
          page = page + 1
          xpos = monitor.x
          ypos = monitor.y
          maxw = 0
          maxh = d[4]
        end
        maxw = math.max(maxw,xpos + d[3] - monitor.x) 
      
      elseif dir == 2 then
      
        maxw = math.max(maxw, d[3])
        if ypos + d[4] > monitor.y + monitor.h then
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
    if pos then

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
    
  local mx, my = GES('mon_x',true), GES('mon_y',true)
  local mw, mh = GES('mon_w',true), GES('mon_h',true)
  monitor = {x = nz(tonumber(mx),0),
             y = nz(tonumber(my),0),
             w = nz(tonumber(mw),1920),
             h = nz(tonumber(mh),1080)}
  tpage = 0
  dir = tonumber(GES('dir',true)) or 0
  align = tonumber(GES('align',true)) or 0
  
  LoadBlacklist()
  
  PositionFXForTrack_Auto()
  reaper.SetExtState(SCRIPT,'tpage',nz(tpage,0),false)
  reaper.Main_OnCommand(reaper.NamedCommandLookup('_BR_FOCUS_ARRANGE_WND'),0)
    

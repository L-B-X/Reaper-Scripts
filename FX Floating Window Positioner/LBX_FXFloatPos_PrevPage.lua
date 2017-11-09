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
    
  function OpenFX(page)
  
    local pos = {}
    local poscnt = tonumber(GES('fx_posdata_cnt',true))
   
    if not poscnt then return end
    
    for p = 1, poscnt do
    
      local posstr = GES('fx_posdata_'..p)
      pos[p] = {page = tonumber(string.match(posstr,'%d+'))}
    end
   
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
  tpage = tonumber(GES('tpage',true)) or 0
  tpage=math.max(tpage-1,0)
  
  --PositionFXForTrack_Auto()
  OpenFX(tpage)
  reaper.SetExtState(SCRIPT,'tpage',nz(tpage,0),true)


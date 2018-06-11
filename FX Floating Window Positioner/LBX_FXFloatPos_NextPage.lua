-- @version 1.0
-- @author Leon Bradley (LBX)
-- @description LBX FX Float Positioner - Next Page
-- @website https://forum.cockos.com/showthread.php?t=199400
-- @changelog
--    1. Initial stable version

  local SCRIPT='LBX_FXPOS'
  
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
  
  function NumToBool(x)
    if x == 1 then
      return true
    else
      return false
    end
  end
  
  function OpenFX(page)

    local pos = {}
    local poscnt = tonumber(GES('fx_posdata_cnt',true))
   
    if not poscnt or poscnt == 0 then return end
    
    for p = 1, poscnt do
    
      local posstr = GES('fx_posdata_'..p)
      local pp, bl = string.match(posstr,'(%d+) (%d+)')
      pos[p] = {page = tonumber(pp),
                blacklist = NumToBool(tonumber(bl))}
    end
    if looppages == false then
      page = math.min(page, pos[poscnt].page)   
    else
      if page > pos[poscnt].page then
        page = 0
      end
    end
    local tr = reaper.GetSelectedTrack2(0,0,true)       
    if not tr then return end
    if pos then
      for p = 1, #pos do
      
        if pos[p].page == page and pos[p].blacklist ~= true then
          reaper.TrackFX_Show(tr,p-1,3)
        else
          reaper.TrackFX_Show(tr,p-1,2)
        end
       
      end
    end 
    
    return page
  end
  
  
  local mx, my = GES('mon_x',true), GES('mon_y',true)
  local mw, mh = GES('mon_w',true), GES('mon_h',true)
  local focarr = tobool(nz(GES('settings_focarr',true),true))
  monitor = {x = nz(tonumber(mx),0),
             y = nz(tonumber(my),0),
             w = nz(tonumber(mw),1920),
             h = nz(tonumber(mh),1080)}
  tpage = tonumber(GES('tpage',true)) or 0
  looppages = tobool(GES('settings_looppages',true))
  tpage=tpage+1
  
  --PositionFXForTrack_Auto()
  tpage = OpenFX(tpage)
  reaper.SetExtState(SCRIPT,'tpage',nz(tpage,0),false)
  
  if focarr == true then
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_BR_FOCUS_ARRANGE_WND'),0)
  end

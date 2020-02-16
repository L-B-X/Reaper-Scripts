 function GetTrackChunk(track, usefix)
    if not track then return end
    local track_chunk    
    
    if usefix == true and reaper.APIExists('SNM_CreateFastString') == true then
      
      local fast_str = reaper.SNM_CreateFastString("")
      if reaper.SNM_GetSetObjectState(track, fast_str, false, false) then
        track_chunk = reaper.SNM_GetFastString(fast_str)
      end
      reaper.SNM_DeleteFastString(fast_str)  
    else
      _, track_chunk = reaper.GetTrackStateChunk(track,'',false)
    end
    return track_chunk
  end
  
  local track = reaper.GetSelectedTrack2(0, 0, true)
  if track then
    local _, trackname = reaper.GetTrackName(track)
    if (trackname or '') == '' then
      trackname = 'Track '..string.format('%i', reaper.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER'))
    end
    local chunk = GetTrackChunk(track,true)
    if chunk then
      reaper.ShowConsoleMsg(chunk)
      local fn
      if reaper.JS_Dialog_BrowseForSaveFile then
        local ret
        ret, fn = reaper.JS_Dialog_BrowseForSaveFile('Enter Save Filename', '', 'Chunk_'..trackname..'.txt', 'Text files (.txt)\0*.txt\0')
        if ret == 0 then
          fn = nil
        end
      else
        local dir = reaper.GetProjectPath('')..'/'
        local bfn = 'Chunk_'..trackname
        fn = bfn
        local cnt = 0
        while reaper.file_exists(dir..fn..'.txt') do
          cnt = cnt + 1
          fn = bfn..'_'..string.format('%03d',cnt)
        end
        fn = dir..fn..'.txt'
      end
      
      if fn then
        if not string.match(fn,'%.txt$') then
          fn = fn..'.txt'
        end
        file=io.open(fn,"w")
        file:write(chunk)
        file:close()
        reaper.ShowConsoleMsg('Chunk saved to: '..fn)
      end
    end
  end

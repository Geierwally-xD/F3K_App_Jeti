-- ############################################################################# 
-- # DC/DS F3K Training - Lua application for JETI DC/DS transmitters  
-- #
-- # Copyright (c) 2020, by Scherndi
-- # All rights reserved.
-- #
-- # Redistribution and use in source and binary forms, with or without
-- # modification, are permitted provided that the following conditions are met:
-- # 
-- # 1. Redistributions of source code must retain the above copyright notice, this
-- #    list of conditions and the following disclaimer.
-- # 2. Redistributions in binary form must reproduce the above copyright notice,
-- #    this list of conditions and the following disclaimer in the documentation
-- #    and/or other materials provided with the distribution.
-- # 
-- # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- # ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- # WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- # DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
-- # ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- # (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- # LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- # ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- # (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- # SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-- # 
-- # The views and conclusions contained in the software and documentation are those
-- # of the authors and should not be interpreted as representing official policies,
-- # either expressed or implied, of the FreeBSD Project.                    
-- # V1.0.5 - Task LA Launch App by Scherndi      
-- #############################################################################

local prevFrameAudioSwitchF3K = 0 --audio switch logic for output ramaining frame time
local taskStateF3K = 1 -- contains the current state of task state machine
local flightIndexF3K = 1 -- current flight number of the task
local startFrameTimeF3K = 0 -- start time stamp frame time
local startFlightTimeF3K = 0 -- start time stamp flight time
local startBreakTimeF3K = 0 -- start time stamp break time
local taskStartSwitchedF3K = false -- logic for task start switched
local onFlightF3K = false	-- true if flight is active
local flightFinishedF3K = true -- logic to avoid negative count of remaining flight time
local remainingFlightTimeF3K = 0 -- contains remaining flight time in ms
local remainingFlightTimeMinF3K = 0 -- contains remaining flight time min
local remainingFlightTimeSecF3K = 0 -- contains remaining flight time sec
local preSwitchNextFlightF3K = false  -- logic for start next flight (stopp switch musst be pressed and released)
local flightTimeF3K = 0
local breakTimeF3K = 0
local goodFlightsF3K = nil --list of all good flights
local preSwitchTaskResetF3K = false --logic for reset task switch (for tasks with combined stopp and reset functionality e.g. task A and B)
local flightCountDownF3K = false -- flight count down for poker task was switched
local flightFinishedF3K = true -- logic to avoid negative count of remaining flight time
local sumAudioOutput = 0 -- helper for audio output flight times
local lng=system.getLocale()
local globVar = {}
local devId,emulator=system.getDeviceType ()
local sensor_resolution = 100 --ms
local prevTime = 0
local hoehe_max = 0
local vario_max = 0
local h_drift = 0
local h_ref = 1.2
------------ set launch offset here ------------------------------
local launch_offset = 250 --ms   
------------------------------------------------------------------
local h_cal = false
local meas_timeoffset = 1000 --ms
local meas_variooffset = 500 / 100 --sinken in m/s
local measuretime = 0
local height = 0
local vario = 0
local h_helper = 0
local height_cor = 0
local caliTimeF3K = 0
  
--------------------------------------------------------------------
-- init function task LA Launch App
--------------------------------------------------------------------
local function taskInit(globVar_)
	globVar = globVar_
    globVar.author = nil
    globVar.author = "Scherndi" -- set author of task here
	taskStateF3K = 1
	prevFrameAudioSwitchF3K = 0 --audio switch logic for output ramaining frame time
	flightIndexF3K = 1 -- current flight number of the task
	startFrameTimeF3K = 0 -- start time stamp frame time
	startFlightTimeF3K = 0 -- start time stamp flight time
	startBreakTimeF3K = 0 -- start time stamp break time
	taskStartSwitchedF3K = false -- logic for task start switched
	onFlightF3K = false	-- true if flight is active
	flightFinishedF3K = true -- logic to avoid negative count of remaining flight time
	remainingFlightTimeF3K = 0 -- contains remaining flight time in ms
	remainingFlightTimeMinF3K = 0 -- contains remaining flight time min
	remainingFlightTimeSecF3K = 0 -- contains remaining flight time sec
	preSwitchNextFlightF3K = false  -- logic for start next flight (stopp switch musst be pressed and released)
	flightTimeF3K = 0
	breakTimeF3K = 0
	goodFlightsF3K = nil --list of all good flights
	preSwitchTaskResetF3K = false --logic for reset task switch (for tasks with combined stopp and reset functionality e.g. task A and B)
	flightCountDownF3K = false -- flight count down for poker task was switched
    globVar.flightIndexOffsetScreenF3K = 0 -- for display if more than 8 flights in list
    globVar.flightIndexScrollScreenF3K = 0 -- for scrolling up and down if more than 8 flights in list
    goodFlightsF3K = {{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0}} -- flight time , break time, sum time
	flightFinishedF3K = true -- logic to avoid negative count of remaining flight time
	sumAudioOutput = 0 -- helper for audio output flight times
	prevTime = globVar.currentTimeF3K
	devId,emulator=system.getDeviceType ()
    sensor_resolution = 100 --ms
    prevTime = 0
    hoehe_max = 0
    vario_max = 0
    h_drift = 0
    h_ref = globVar.cfgStartHeightF3K / 100
    meas_timeoffset = globVar.cfgTimeoffsetF3K
    launch_offset = 250 --s   500
    h_cal = false
    meas_variooffset = 0.5 --sinken in m/s
    measuretime = 0
    h_helper = 0
    height = 0
    vario = 0
    height_cor = 0
    caliTimeF3K = 0
end

--------------------------------------------------------------------
local function getFromSensor ()
    if(globVar.currentTimeF3K>=prevTime+sensor_resolution) then
      
      local sensorData
      if(globVar.heightSensorId and globVar.heightParamId ) then
        sensorData= system.getSensorByID(globVar.heightSensorId,globVar.heightParamId)
      end  
      if(sensorData and sensorData.valid) then
        height =  sensorData.value
		sensorData= system.getSensorByID(globVar.varioSensorId,globVar.varioParamId)
        return height,sensorData.value, true
      else
        return -10,-10, true 
      end  
    prevTime = globVar.currentTimeF3K  
    else
      return height,sensorData.value, false
    end
end
--------------------------------------------------------------------

-- audio function for count down
--------------------------------------------------------------------
local function audioCountDownF3K()
	if((globVar.soundTimeF3K >=0)and(globVar.soundTimeF3K ~= globVar.prevSoundTimeF3K))then
		if((globVar.soundTimeF3K==45)or(globVar.soundTimeF3K==30)or(globVar.soundTimeF3K==25)or(globVar.soundTimeF3K<=20))then
			if(globVar.soundTimeF3K > 0)then
				if (system.isPlayback () == false) then
					system.playNumber(globVar.soundTimeF3K,0) --audio remaining flight time
					globVar.prevSoundTimeF3K = globVar.soundTimeF3K
				end			
			else
				system.playBeep(1,4000,500) -- flight finished play beep
				globVar.prevSoundTimeF3K = globVar.soundTimeF3K
			end
			--print(soundTime)
		end
	end	
end

local function frameTimeChanged(value,formIndex)
 --dummy
end

--------------------------------------------------------------------
-- file handler task  LA Launch App
--------------------------------------------------------------------
local function file(tFileF3K)
	
	local breakTimeMs = 0
	local flightTimeMs = 0
	local breakTimeTxt =  nil
	local flightTimeTxt = nil  
	local flightTxt = nil 
	local sumTimeTxt = nil
	local flightNumberTxt = nil
	if(goodFlightsF3K[1][2] >0) then
		io.write(tFileF3K,globVar.langF3K.flight,globVar.langF3K.time,globVar.langF3K.breakTime,"  ",globVar.langF3K.sumTime,"\n")
		for i=1 , flightIndexF3K do
		    flightNumberTxt = nil
			breakTimeTxt =  nil
			flightTimeTxt = nil  
			flightTxt = nil 
			sumTimeTxt = nil
			flightNumberTxt = string.format( "%02d",i)

			if((goodFlightsF3K[i][2]>0)or(goodFlightsF3K[i][1]>0))then -- write only done flights
				breakTimeMs = ((goodFlightsF3K[i][2] -  math.modf(goodFlightsF3K[i][2]))*100) 
				flightTimeMs = ((goodFlightsF3K[i][1] -  math.modf(goodFlightsF3K[i][1]))*100) 
				breakTimeTxt =  string.format( "%02d:%02d:%02d", math.modf(goodFlightsF3K[i][2]/ 60),goodFlightsF3K[i][2] % 60,breakTimeMs )
				flightTimeTxt =  string.format( "%02d:%02d:%02d", math.modf(goodFlightsF3K[i][1] / 60),goodFlightsF3K[i][1] % 60,flightTimeMs ) 
				sumTimeTxt =  string.format( "%02d:%02d", math.modf(goodFlightsF3K[i][3] / 60),goodFlightsF3K[i][3] % 60) 
				flightTxt="                 "..flightNumberTxt.."      "..flightTimeTxt.."      "..breakTimeTxt.."      "..sumTimeTxt.."\n" --write goog flight information for logfile
				io.write(tFileF3K,flightTxt)
			end
		end
	end
	sumTimeTxt = nil
	sumTimeTxt =  string.format( "%02d:%02d", math.modf(sumTimerF3K / 60),sumTimerF3K % 60 )
	io.write(tFileF3K,globVar.langF3K.sumTime,sumTimeTxt,"\n")
	
end
--------------------------------------------------------------------
-- eventhandler task  LA Launch App
--------------------------------------------------------------------
local function task_LA_Start() -- wait for start switch start 5s count down and start frame time
	prevFrameAudioSwitchF3K = 1 -- lock audio output remaining frame time
	
	if(taskStartSwitchedF3K == false)then
	
		if((1==system.getInputsVal(globVar.cfgStartFrameSwitchF3K))and globVar.currentFormF3K ~= globVar.initScreenIDF3K )then
			taskStartSwitchedF3K = true
			startFrameTimeF3K = globVar.currentTimeF3K
			globVar.frameTimerF3K = 5 --preset with 5 seconds			
		end
	else
		local diffTime =(globVar.currentTimeF3K - startFrameTimeF3K)/1000 
		globVar.frameTimerF3K = 5 + 1 - diffTime
		globVar.soundTimeF3K = math.modf(globVar.frameTimerF3K)
		audioCountDownF3K()
			
		height,vario, isnew = getFromSensor()
			
		if(diffTime > launch_offset / 1000 and h_cal == false) then		
			if(isnew and height ~= -10 ) then
				h_drift = h_ref - height
				h_cal = true
			end
		end
		if diffTime > launch_offset / 1000 then
			if(isnew ) then
				if(vario > vario_max)then
					vario_max = vario
				end
			end
		end
				
		if( flightCountDownF3K ==true )then 		
		flightCountDownF3K = false
		end
			
		if(globVar.frameTimerF3K == 0)then
			startFlightTimeF3K = globVar.currentTimeF3K
			startBreakTimeF3K = globVar.currentTimeF3K
			taskStateF3K = 2
			preSwitchNextFlightF3K = false
		end
		
	end	
end
--------------------------------------------------------------------
local function task_LA_flights() -- wait for start flight switch count preflight time start, end, start next flight
	if(onFlightF3K == true)then -- flight active	
		flightTimeF3K =(globVar.currentTimeF3K - startFlightTimeF3K)/1000
		remainingFlightTimeF3K = globVar.cfgTargetTimeF3K-flightTimeF3K + 1
	    remainingFlightTimeMinF3K = math.modf( remainingFlightTimeF3K/ 60)
        remainingFlightTimeSecF3K = remainingFlightTimeF3K % 60
		if((flightFinishedF3K == true) or ((remainingFlightTimeMinF3K == 0)and(remainingFlightTimeSecF3K == 0))) then -- avoid negative count of remaining flight time
			flightFinishedF3K = true
			remainingFlightTimeMinF3K = 0
			remainingFlightTimeSecF3K = 0
		end
		
		
		height,vario, isnew = getFromSensor ()
		
			if(isnew and vario > vario_max) then
					vario_max = vario
			end 
			if(isnew and height > hoehe_max) then
					hoehe_max = height
			end 
		
		if(1==system.getInputsVal(globVar.cfgFlightCountDownSwitchF3K) and flightCountDownF3K ==false and goodFlightsF3K[flightIndexF3K][1] == 0)then 
		goodFlightsF3K[flightIndexF3K][1]=flightTimeF3K	
		goodFlightsF3K[flightIndexF3K][3]=vario_max
		
		h_helper = height
		measuretime = globVar.currentTimeF3K 
		flightCountDownF3K = true	
		end
				
		
		if (flightCountDownF3K == true and  globVar.currentTimeF3K > measuretime + meas_timeoffset  )  then
		
			if (hoehe_max > h_helper)then				
				height_cor = hoehe_max + h_drift 				
			else			
				height_cor = h_helper + h_drift 				
			end
			goodFlightsF3K[flightIndexF3K][2]=height_cor
						
			h_cal = false
			flightCountDownF3K = false		
		end
		
	
			
		
			
		if(1==system.getInputsVal(globVar.cfgStoppFlightSwitchF3K) and flightCountDownF3K ~= true)then -- stopp flight was switched
			
			if(flightIndexF3K == 20) then -- end of flight list reached finish task
				system.playFile("/Apps/F3K/Audio/"..lng.."/F3K_Tend.wav",AUDIO_QUEUE)
				taskStateF3K = 3
			else
				flightIndexF3K = flightIndexF3K + 1 -- preset next flight
				flightTimeF3K = 0
				breakTimeF3K = 0
				startBreakTimeF3K = globVar.currentTimeF3K -- preset break time for next flight
				
			end
			remainingFlightTimeF3K = 0
			remainingFlightTimeMinF3K = 0
			remainingFlightTimeSecF3K = 0
			globVar.soundTimeF3K = 0
			globVar.prevSoundTimeF3K = 1
			onFlightF3K = false
			preSwitchNextFlightF3K = false
			
			vario_max = 0
			hoehe_max = 0
			
		end
	else  -- break active
	
		breakTimeF3K = (globVar.currentTimeF3K - startBreakTimeF3K)/1000
		
		height,vario, isnew = getFromSensor ()
		if(isnew and vario > vario_max)then
					vario_max = vario
		end		
				
		if ((breakTimeF3K > launch_offset /1000 and h_cal == false) or (globVar.currentTimeF3K > (caliTimeF3K + launch_offset) and  h_cal == true and math.abs(vario) < 0.5)) then	
			if(isnew and height ~= -10 ) then
				h_drift = h_ref - height
				h_cal = true
				caliTimeF3K = globVar.currentTimeF3K
			end
		end
		
		
		if(1==system.getInputsVal(globVar.cfgTimerResetSwitchF3K)) then -- combined functionality stopp and reset switch stopps task here
			preSwitchTaskResetF3K = true
			taskStateF3K = 3 --task_E_End
			system.playFile("/Apps/F3K/Audio/"..lng.."/F3K_Mend.wav",AUDIO_QUEUE)
		end
			
		if(preSwitchNextFlightF3K == false) then -- stopp switch must be active before start of new flight ... wait for release stopp switch
			if(1==system.getInputsVal(globVar.cfgStoppFlightSwitchF3K)) then
				preSwitchNextFlightF3K = true
			end
		else
			if(1==system.getInputsVal(globVar.cfgStartFlightSwitchF3K)) then
					
				onFlightF3K = true
				flightFinishedF3K = false
				startFlightTimeF3K = globVar.currentTimeF3K
				globVar.soundTimeF3K = 0
				globVar.prevSoundTimeF3K = 1
				
				
				
			end	
		end
	end

end
--------------------------------------------------------------------
local function task_LA_End()     -- safe training?
	prevFrameAudioSwitchF3K = 1 -- lock audio output remaining frame time
	if(1==system.getInputsVal(globVar.cfgTimerResetSwitchF3K)) then
		if(preSwitchTaskResetF3K == false)then
			local func = globVar.storeTask
			func()
			local func = globVar.resetTask
			func()
		end
	else
		preSwitchTaskResetF3K = false
	end
end
--------------------------------------------------------------------
local task_LA_States = {task_LA_Start,task_LA_flights,task_LA_End}
--------------------------------------------------------------------
local function task()
--lcd.drawText(10,10,"task",FONT_NORMAL)
--system.playNumber(1,1)
	local taskHandler = task_LA_States[taskStateF3K] -- set statemachine depending on last current state
	local soundheight = 0
	local soundvario = 0	
	taskHandler()
	
	--[[
	if(1==system.getInputsVal(globVar.cfgFrameAudioSwitchF3K)) then
		if((prevFrameAudioSwitchF3K ==0)and (flightIndexF3K >1))then
			prevFrameAudioSwitchF3K = 1  -- play audio file for break time
			soundheight = goodFlightsF3K[flightIndexF3K-1][1] -- break time of previous flight
			
			
				system.playNumber(soundheight,1)
			
			sumAudioOutput = 9 --wait 9 cycles a 30ms
		end	
	else
		prevFrameAudioSwitchF3K = 0
	end
	
	if(sumAudioOutput>0)then
		if(sumAudioOutput >1)then 
			sumAudioOutput = sumAudioOutput - 1
		end	
		if((system.isPlayback() == false) and (sumAudioOutput == 1))then
			soundvario  = goodFlightsF3K[flightIndexF3K-1][2] -- flight time of previous flight
			
	
				system.playNumber(soundvario,1)

		
			sumAudioOutput = 0
		end
	end
	--]]
end

--------------------------------------------------------------------
-- display task  LA Launch App
--------------------------------------------------------------------
local function screen()
    local listIndex = 0 
	local breakTimeMs = 0
	local flightTimeMs = 0
	--local heightTxt=  nil
	--local varioTxt=  nil
	--local NrTxt=  nil
	local flightTimeTxt =  nil
	local flightScreenTxt = nil
	local textoffset_left = 90
	--local remainingFlightTimeTxt = nil
	--local timeTxt = string.format( "%02d:%02d", math.modf(globVar.cfgTargetTimeF3K / 60),globVar.cfgTargetTimeF3K % 60 )
	--local sumTimeTxt = string.format( "%02d:%02d", math.modf(sumTimerF3K / 60),sumTimerF3K % 60 )

	--remainingFlightTimeTxt = string.format( "%02d:%02d",remainingFlightTimeMinF3K ,remainingFlightTimeSecF3K )
	
	
		local valTxt = string.format( "%.1f", height)		
	    lcd.drawText(10,0,"H",FONT_NORMAL)
	    lcd.drawText(40,0,valTxt,FONT_NORMAL)
		local varTxt = string.format( "%.1f", vario)
	    lcd.drawText(10,20,"V",FONT_NORMAL)
	    lcd.drawText(40,20,varTxt,FONT_NORMAL)	
	
	
		local h_mean = 0
		local vario_mean = 0
	--[[
	if(goodFlightIndex == 0)then
		for i = 1,flightIndexF3K do
			h_mean = h_mean + goodFlightsF3K[i][2] 
			vario_mean = vario_mean +  goodFlightsF3K[i][3] 
		end
		h_mean = h_mean / flightIndexF3K
		vario_mean = vario_mean / flightIndexF3K
	else
		for i = 1,goodFlightIndex do
			h_mean = h_mean + goodFlightsF3K[i][2] 
			vario_mean = vario_mean +  goodFlightsF3K[i][3] 
		end
		h_mean = h_mean / goodFlightIndex
		vario_mean = vario_mean / goodFlightIndex
	end
		--]]
		if(flightIndexF3K > 1)then
		for i = 1,flightIndexF3K -1 do
			h_mean = h_mean + goodFlightsF3K[i][2] 
			vario_mean = vario_mean +  goodFlightsF3K[i][3] 
		end
		h_mean = h_mean / (flightIndexF3K -1)
		vario_mean = vario_mean / (flightIndexF3K -1)
		end
		
		local valTxt = string.format( "%.1f", h_mean)		
		lcd.drawText(5,40,"ØH",FONT_NORMAL)
	    lcd.drawText(40,40,valTxt,FONT_NORMAL)
		local varTxt = string.format( "%.1f", vario_mean)
	    --lcd.drawText(10,70,"vm ",FONT_NORMAL)
		lcd.drawText(5,60,"ØV",FONT_NORMAL)
		--lcd.drawText(10,70,utf8.char(9658),FONT_NORMAL)
	    lcd.drawText(40,60,varTxt,FONT_NORMAL)	
	
	--local varTxt = string.format( "%.1f", vario_max)
	    --lcd.drawText(10,90,"vmax",FONT_NORMAL)
	    --lcd.drawText(40,90,varTxt,FONT_NORMAL)	
		
		height_cor = height + h_drift 
		local varTxt = string.format( "%.1f", height_cor)
		--local varTxt = string.format( "%.1f", height_cor)
	    lcd.drawText(5,80,"H0",FONT_NORMAL)
	    lcd.drawText(40,80,varTxt,FONT_NORMAL)
		
		
		local varTxt = string.format( "%.1f", h_drift)
		--local varTxt = string.format( "%.1f", height_cor)
	    lcd.drawText(5,100,"Hd",FONT_NORMAL)
	    lcd.drawText(40,100,varTxt,FONT_NORMAL)
	
	
	--test_counter = test_counter + 1
	--test_array[math.modf(test_counter/10)] = test_counter
	--test_array[math.modf(test_counter/10)] = math.modf(collectgarbage('count')*1024)
	--test_array[test_counter] = math.modf(collectgarbage('count')*1024)
	--local varTxt = string.format( "%d",test_array[test_counter])
	  -- lcd.drawText(10,100,"B:",FONT_NORMAL)
	  -- lcd.drawText(30,100,varTxt,FONT_NORMAL)		
		
  --[[
  local height,vario, isnew = getFromSensor ()
	if(isnew) then		
		local valTxt = string.format( "%.1f", height)		
	    lcd.drawText(10,10,"h",FONT_NORMAL)
	    lcd.drawText(30,10,valTxt,FONT_NORMAL)
		local varTxt = string.format( "%.2f", vario)
	    lcd.drawText(10,30,"v",FONT_NORMAL)
	    lcd.drawText(30,30,varTxt,FONT_NORMAL)	
		
	local height_cor = height - h_ref - h_drift 
	local varTxt = string.format( "%.1f",height_cor)
	    lcd.drawText(10,100,"hcor",FONT_NORMAL)
	    lcd.drawText(30,100,varTxt,FONT_NORMAL)		
	end
	local h_mean = 0
	local vario_mean = 0
	
	
	for i = 1,flightIndexF3K do
	h_mean = h_mean + goodFlightsF3K[i][2] 
	vario_mean = vario_mean +  goodFlightsF3K[i][3] 
	end
	h_mean = h_mean / flightIndexF3K
	vario_mean = vario_mean / flightIndexF3K
		local valTxt = string.format( "%.1f", h_mean)		
	  lcd.drawText(10,50,"hm",FONT_NORMAL)
	   lcd.drawText(30,50,valTxt,FONT_NORMAL)
	local varTxt = string.format( "%.2f", vario_mean)
	   lcd.drawText(10,70,"vm",FONT_NORMAL)
	   lcd.drawText(30,70,varTxt,FONT_NORMAL)	
	]]--
		
		
	
	if(flightIndexF3K > 8)then
		globVar.flightIndexOffsetScreenF3K = flightIndexF3K - 8
	end

	if(goodFlightsF3K[20][2] >0) then	 -- all flights valid , draw all flights invers
		lcd.drawFilledRectangle(130,0,180,(8*15) +2)
	elseif(flightIndexF3K > 1)then
		if(globVar.flightIndexScrollScreenF3K == 0)then
			lcd.drawFilledRectangle(130,0,180,((flightIndexF3K-globVar.flightIndexOffsetScreenF3K-1)*15) +2)
		else
			lcd.drawFilledRectangle(130,0,180,((flightIndexF3K-globVar.flightIndexOffsetScreenF3K)*15) +2)
		end
	end	

	for i=1 , 8 do
		listIndex = i + globVar.flightIndexOffsetScreenF3K-globVar.flightIndexScrollScreenF3K
		--breakTimeTxt =  nil
		flightTimeTxt =  nil
		flightScreenTxt = nil
		--sumTimeTxt = nil 
		
		if(listIndex < flightIndexF3K) then -- write stored text for previous finished flights or if last flight valid until last flight
			flightTimeMs = ((goodFlightsF3K[listIndex][1] -  math.modf(goodFlightsF3K[listIndex][1]))*100)
			flightTimeTxt =  string.format( "%02d:%02d:%02d", math.modf(goodFlightsF3K[listIndex][1] / 60),goodFlightsF3K[listIndex][1] % 60,flightTimeMs ) 
			heightTxt = string.format( "%.1f", goodFlightsF3K[listIndex][2] ) 
			varioTxt = string.format( "%.2f", goodFlightsF3K[listIndex][3] ) 
			NrTxt = string.format( "%d",listIndex ) 
			flightScreenTxt = string.format("%s   %s   %s   %s",NrTxt,heightTxt,varioTxt,flightTimeTxt)
			if(globVar.colorScreenF3K== true) then
				lcd.setColor(255,255,255) -- white
				lcd.drawText(textoffset_left,i*15-15,flightScreenTxt,FONT_NORMAL)
				lcd.setColor(0,0,0) -- black
			else
				lcd.drawText(textoffset_left,i*15-15,flightScreenTxt,FONT_REVERSED)
			end
		elseif(listIndex == flightIndexF3K) then -- write current flight
			flightTimeMs = ((flightTimeF3K -  math.modf(flightTimeF3K))*100) 
			flightTimeTxt =  string.format( "%02d:%02d:%02d", math.modf(flightTimeF3K / 60),flightTimeF3K % 60,flightTimeMs ) 
			--heightTxt = string.format( "%.1f", height ) 
			--varioTxt = string.format( "%.2f", vario ) 
			heightTxt = string.format( "%.1f", goodFlightsF3K[listIndex][2] ) 
			varioTxt = string.format( "%.2f", goodFlightsF3K[listIndex][3]) 
			NrTxt = string.format( "%d", listIndex ) 
			flightScreenTxt = string.format("%s   %s   %s   %s",NrTxt,heightTxt,varioTxt,flightTimeTxt)
			if(goodFlightsF3K[20][1] >0) then --write last current flight
				if(globVar.colorScreenF3K== true) then
					lcd.setColor(255,255,255)-- white
					lcd.drawText(textoffset_left,i*15-15,flightScreenTxt,FONT_NORMAL)
					lcd.setColor(0,0,0) -- black
				else
					lcd.drawText(textoffset_left,i*15-15,flightScreenTxt,FONT_REVERSED)
				end			
			else --write current flight
				lcd.setColor(0,0,0) -- black
				lcd.drawText(textoffset_left,i*15-15,flightScreenTxt,FONT_NORMAL)
			end
		end
	end
	lcd.drawLine(1,125,310,125)
	lcd.drawLine(80,0,80,125)
end


local task_LA = {taskInit,frameTimeChanged,file,task,screen}
return task_LA
-- ############################################################################# 
-- # DC/DS F3K Training - Lua application for JETI DC/DS transmitters  
-- #
-- # Copyright (c) 2020, by Geierwally
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
-- #                       
-- # V1.0.2 - Initial release of all specific functions of Task H '1,2,3,4 min target'
-- # V1.0.3 - Bugfixing changed all global to local variables
-- #        - Moved all F3K Audio files into app specific F3K/audio folder  
-- # V1.0.4 - Support of DS12 Color Display and take over modifications by Gernot Tengg    
-- # V1.0.5 - separate configuration from main function with dynamic storage management  
-- #############################################################################

local prevFrameAudioSwitchF3K = 0 --audio switch logic for output ramaining frame time
local taskStateF3K = 1 -- contains the current state of task state machine
local sumTimerF3K = 0 -- summary of valid flights
local flightIndexF3K = 1 -- current flight number of the task
local startFrameTimeF3K = 0 -- start time stamp frame time
local startFlightTimeF3K = 0 -- start time stamp flight time
local startBreakTimeF3K = 0 -- start time stamp break time
local taskStartSwitchedF3K = false -- logic for task start switched
local onFlightF3K = false	-- true if flight is active
local remainingFlightTimeF3K = 0 -- contains remaining flight time in ms
local remainingFlightTimeMinF3K = 0 -- contains remaining flight time min
local remainingFlightTimeSecF3K = 0 -- contains remaining flight time sec
local flightTimesTxtF3K = nil -- contains all flight times for the task (times to fly)
local flightTimesF3K = nil -- contains all flight times of the task in ms for comparison(times to fly)
local preSwitchNextFlightF3K = false  -- logic for start next flight (stopp switch musst be pressed and released)
local failedFlightIndexF3K = 1 -- current index of failed flight list
local flightTimeF3K = 0
local countTimeF3K = 0
local countTimeTargetF3k = 0
local breakTimeF3K = 0
local failedFlightsF3K = nil --list of failed flights
local goodFlightsF3K = nil --list of all good flights
local preSwitchTaskResetF3K = false --logic for reset task switch (for tasks with combined stopp and reset functionality e.g. task A and B)
local flightCountDownF3K = false -- flight count down for poker task was switched
local sumFlightList = nil -- buble sort list indexes of flight list ordered by flight time
local sumFlightIndex = 0
local sumAudioOutput = 0 -- helper for audio output flight times
local lng=system.getLocale()
local globVar = {}

--------------------------------------------------------------------
-- init function task Hlocal function taskInit() '1,2,3,4 min target'
--------------------------------------------------------------------
local function taskInit(globVar_)
	globVar = globVar_
    globVar.author = nil
    globVar.author = "Geierwally" -- set author of task here    
	taskStateF3K = 1
	prevFrameAudioSwitchF3K = 0 --audio switch logic for output ramaining frame time
	sumTimerF3K = 0 -- summary of valid flights
	flightIndexF3K = 1 -- current flight number of the task
	startFrameTimeF3K = 0 -- start time stamp frame time
	startFlightTimeF3K = 0 -- start time stamp flight time
	startBreakTimeF3K = 0 -- start time stamp break time
	taskStartSwitchedF3K = false -- logic for task start switched
	onFlightF3K = false	-- true if flight is active
	remainingFlightTimeF3K = 0 -- contains remaining flight time in ms
	remainingFlightTimeMinF3K = 0 -- contains remaining flight time min
	remainingFlightTimeSecF3K = 0 -- contains remaining flight time sec
	flightTimesTxtF3K = nil -- contains all flight times for the task (times to fly)
	flightTimesF3K = nil -- contains all flight times of the task in ms for comparison(times to fly)
	preSwitchNextFlightF3K = false  -- logic for start next flight (stopp switch musst be pressed and released)
	failedFlightIndexF3K = 0 -- current index of failed flight list
	flightTimeF3K = 0
	countTimeF3K = 0
	countTimeTargetF3K = 0
	breakTimeF3K = 0
	failedFlightsF3K = nil --list of failed flights
	goodFlightsF3K = nil --list of all good flights
	preSwitchTaskResetF3K = false --logic for reset task switch (for tasks with combined stopp and reset functionality e.g. task A and B)
	flightCountDownF3K = false -- flight count down for poker task was switched
    	globVar.flightIndexOffsetScreenF3K = 0 -- for display if more than 8 flights in list
    	globVar.flightIndexScrollScreenF3K = 0 -- for scrolling up and down if more than 8 flights in list
 	flightTimesTxtF3K = {"240s ","180s ","120s ","  60s "}
	flightTimesF3K={240,180,120,60}
	goodFlightsF3K = {{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0}} --list of all good flights  flight time , break time
	sumFlightList = {1,1,1,1,1} -- buble sort list indexes of flight list ordered by flight time
    	sumFlightIndex = 0
	sumAudioOutput = 0 -- helper for audio output flight times
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

local function audioFlightsChanged(value,formIndex) -- number of audio output best flights
    -- dummy the function is handeled in confF3K.lua
end

local function calcSumTime()
	local sum = 0
	local temp = 0
	local sorted = false

	repeat  -- doe bubble sort
		sorted = true
		if(sumFlightIndex >1)then
			for i = 2,sumFlightIndex,1 do 
				if(goodFlightsF3K[sumFlightList[i]][1] > goodFlightsF3K[sumFlightList[i-1]][1])then
					temp = sumFlightList[i]
					sumFlightList[i] = sumFlightList[i-1]
					sumFlightList[i-1] = temp
					sorted = false
				end
			end
		end
	until sorted == true
	
	for i = 1,sumFlightIndex,1 do -- calculate sum time
		if(i<5) then -- calculate summary of five best flights
			if(goodFlightsF3K[sumFlightList[i]][1] >= flightTimesF3K[i])then
				sum = sum + flightTimesF3K[i]
			else
				sum = sum + math.modf(goodFlightsF3K[sumFlightList[i]][1])			
			end
		end
	end
	return sum
end
--------------------------------------------------------------------
-- file handler task H '1,2,3,4 min target'
--------------------------------------------------------------------
local function file(tFileF3K)
	local breakTimeMs = 0
	local flightTimeMs = 0
	local breakTimeTxt =  nil
	local flightTimeTxt = nil  
	local flightTxt = nil 
    local failedFlightTxt = nil
	local targetTimeTxt = nil
	local flightNumberTxt = nil
	
	if(goodFlightsF3K[1][2] >0) then
		io.write(tFileF3K,globVar.langF3K.flight,globVar.langF3K.target,globVar.langF3K.time,globVar.langF3K.breakTime,"\n")
		for i=1 , flightIndexF3K do
			breakTimeTxt =  nil
			flightTimeTxt = nil  
			flightTxt = nil 
			failedFlightTxt = nil
			targetTimeTxt = nil
			flightNumberTxt = string.format( "%02d",i)
			targetTimeTxt = "*###*"

			for j=1, 4 do
				if(i == sumFlightList[j])then -- best flight list  write target time
					targetTimeTxt = nil
					targetTimeTxt = string.format( "%02d:%02d", math.modf(flightTimesF3K[j] / 60),flightTimesF3K[j] % 60)
					break
				end
			end
			
			if((goodFlightsF3K[i][2]>0)or(goodFlightsF3K[i][1]>0))then -- write only done flights
				breakTimeMs = ((goodFlightsF3K[i][2] -  math.modf(goodFlightsF3K[i][2]))*100) 
				flightTimeMs = ((goodFlightsF3K[i][1] -  math.modf(goodFlightsF3K[i][1]))*100) 
				breakTimeTxt =  string.format( "%02d:%02d:%02d", math.modf(goodFlightsF3K[i][2]/ 60),goodFlightsF3K[i][2] % 60,breakTimeMs )
				flightTimeTxt =  string.format( "%02d:%02d:%02d", math.modf(goodFlightsF3K[i][1] / 60),goodFlightsF3K[i][1] % 60,flightTimeMs ) 
				flightTxt="                 "..flightNumberTxt.."      "..targetTimeTxt.."         "..flightTimeTxt.."      "..breakTimeTxt.."\n" --write goog flight information for logfile
				io.write(tFileF3K,flightTxt)
			end
		end
	end	
	local sumTimeTxt =  string.format( "%02d:%02d", math.modf(sumTimerF3K / 60),sumTimerF3K % 60 )
	io.write(tFileF3K,globVar.langF3K.sumTime,sumTimeTxt,"\n")
end
--------------------------------------------------------------------
-- eventhandler task H '1,2,3,4 min target'
--------------------------------------------------------------------
local function task_H_Start() -- wait for start switch start 5s count down and start frame time
	 prevFrameAudioSwitchF3K = 1 -- lock audio output remaining frame time
	 if(taskStartSwitchedF3K == false)then
		if((1==system.getInputsVal(globVar.cfgStartFrameSwitchF3K))and globVar.currentFormF3K ~= globVar.initScreenIDF3K )then
			taskStartSwitchedF3K = true
			startFrameTimeF3K = globVar.currentTimeF3K
			globVar.frameTimerF3K = globVar.cfgPreFrameTimeF3K --preset with 15 seconds
		end
	 else
		local diffTime =(globVar.currentTimeF3K - startFrameTimeF3K)/1000 
		globVar.frameTimerF3K = globVar.cfgPreFrameTimeF3K + 1 - diffTime
		globVar.soundTimeF3K = math.modf(globVar.frameTimerF3K)
		audioCountDownF3K()
		if((globVar.frameTimerF3K == 0)or(globVar.cfgPreFrameTimeF3K==0))then
			globVar.frameTimerF3K = globVar.cfgFrameTimeF3K[globVar.currentTaskF3K]
			startFrameTimeF3K = globVar.currentTimeF3K
			startFlightTimeF3K = 0
			startBreakTimeF3K = globVar.currentTimeF3K
			taskStateF3K = 2
			preSwitchNextFlightF3K = false
			flightCountDownF3K = false
		end
	 end
end
--------------------------------------------------------------------
local function task_H_flights() -- wait for start flight switch count F3K time start, end, start next flight
	local diffTime =(globVar.currentTimeF3K - startFrameTimeF3K)/1000
	local breakFlight = false

	globVar.frameTimerF3K = globVar.cfgFrameTimeF3K[globVar.currentTaskF3K]+1 - diffTime
	if(onFlightF3K == true)then -- flight active
		flightTimeF3K =(globVar.currentTimeF3K - startFlightTimeF3K)/1000

		remainingFlightTimeF3K = flightTimeF3K
	    remainingFlightTimeMinF3K = math.modf( remainingFlightTimeF3K/ 60)
        remainingFlightTimeSecF3K = remainingFlightTimeF3K % 60

		globVar.soundTimeF3K = math.modf(remainingFlightTimeF3K)
		
		
		if(flightCountDownF3K == false)then
			if(1==system.getInputsVal(globVar.cfgFlightCountDownSwitchF3K)) then			
				countTimeTargetF3K  = math.modf(flightTimeF3K / 10) * 10 + 20			
				flightCountDownF3K = true 
			end
		end
		
		if(countTimeTargetF3K > 0)then --count down flightend is active
			countTimeF3K = countTimeTargetF3K-flightTimeF3K +1
			globVar.soundTimeF3K = math.modf(countTimeF3K)
		end
	    
		
		
		if (flightCountDownF3K == true )then		
			audioCountDownF3K()
			
						-- audio output flight time in 10 s frame
		elseif(globVar.frameTimerF3K > 45)then -- avoid overlapping frame and flight count down
			if((globVar.soundTimeF3K%10==0)and(globVar.soundTimeF3K ~= globVar.prevSoundTimeF3K))then
				if (system.isPlayback () == false) then
					if(remainingFlightTimeMinF3K > 0) then
						system.playNumber(remainingFlightTimeMinF3K,0) -- minutes
					end	
					system.playNumber(remainingFlightTimeSecF3K,0)     -- seconds
					globVar.prevSoundTimeF3K = globVar.soundTimeF3K
				end	
			end
		end

		if(globVar.frameTimerF3K==0)then -- end of frame time reached
		    -- flight is valid
			goodFlightsF3K[flightIndexF3K][1]=flightTimeF3K
			goodFlightsF3K[flightIndexF3K][2]=breakTimeF3K
			if(sumFlightIndex < 5) then
				sumFlightIndex = sumFlightIndex + 1
			end	
			sumFlightList[sumFlightIndex] = flightIndexF3K
			sumTimerF3K = calcSumTime() -- increment sum timer
			breakFlight = true
		elseif(1==system.getInputsVal(globVar.cfgStoppFlightSwitchF3K))then -- stopp flight was switched
			goodFlightsF3K[flightIndexF3K][1]=flightTimeF3K
			goodFlightsF3K[flightIndexF3K][2]=breakTimeF3K 
			if(sumFlightIndex < 5) then
				sumFlightIndex = sumFlightIndex + 1
			end				
			sumFlightList[sumFlightIndex] = flightIndexF3K
			sumTimerF3K = calcSumTime() -- increment sum timer
			breakFlight = true		
			
			flightCountDownF3K = false 
			countTimeTargetF3K = 0
				
		end
		
		
		
		if(breakFlight == true)then
			if(flightIndexF3K == 4) then -- end of flight list reached finish task
				system.playFile("/Apps/F3K/Audio/"..lng.."/F3K_Tend.wav",AUDIO_QUEUE)
				taskStateF3K = 3
			else
				flightIndexF3K = flightIndexF3K + 1 -- preset next flight
				flightTimeF3K = 0
				breakTimeF3K = 0
				startBreakTimeF3K = globVar.currentTimeF3K -- preset break time for next flight
			end
			flightTimeF3K = 0 --flight invalid reset flight time
			remainingFlightTimeF3K = 0
			remainingFlightTimeMinF3K = 0
			remainingFlightTimeSecF3K = 0
			globVar.soundTimeF3K = 0
			globVar.prevSoundTimeF3K = 1
			onFlightF3K = false
			preSwitchNextFlightF3K = false
		end	
	else  -- break active
		local shortestFlight = sumFlightIndex
		if(shortestFlight == #sumFlightList)then
			shortestFlight = shortestFlight -1
		elseif(shortestFlight == 0)	then
			shortestFlight = 1
		end
		
			breakTimeF3K = (globVar.currentTimeF3K - startBreakTimeF3K)/1000
			if(globVar.frameTimerF3K==0)then-- frametimer expired finish task
				system.playFile("/Apps/F3K/Audio/"..lng.."/F3K_Tend.wav",AUDIO_QUEUE)
				taskStateF3K = 3 --task_E_End
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
					startFlightTimeF3K = globVar.currentTimeF3K
					globVar.soundTimeF3K = 0
					globVar.prevSoundTimeF3K = 1
					
					flightCountDownF3K = false
				end	
			end
	
	end
	globVar.soundTimeF3K = math.modf(globVar.frameTimerF3K) -- count down of remaining frame time for right start of next flight
	audioCountDownF3K()
end
--------------------------------------------------------------------
local function task_H_End()     -- safe training?
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
local task_H_States = {task_H_Start,task_H_flights,task_H_End}
--------------------------------------------------------------------
local function task()
	local taskHandler = task_H_States[taskStateF3K] -- set statemachine depending on last current state
	taskHandler()
	if(1==system.getInputsVal(globVar.cfgFrameAudioSwitchF3K)) then
		if(prevFrameAudioSwitchF3K ==0)then
			prevFrameAudioSwitchF3K = 1  -- play audio file for remaining frame time
			system.playNumber(math.modf(globVar.frameTimerF3K / 60),0,"min")
			system.playNumber(globVar.frameTimerF3K % 60,0,"s")
			system.playFile("/Apps/F3K/Audio/"..lng.."/F3K_Frame.wav",AUDIO_QUEUE)
			sumAudioCounter = globVar.cfgAudioFlights[globVar.currentTaskF3K-5]
			if(sumFlightIndex == 5)then
				sumAudioOutput = sumFlightIndex - 1
			else
				sumAudioOutput = sumFlightIndex
			end	
		end
	else
		prevFrameAudioSwitchF3K = 0
	end

	if((sumAudioOutput>0)and(system.isPlayback() == false))then
		local audioFlights = goodFlightsF3K[sumFlightList[sumAudioOutput]][1]
		if(audioFlights >0)then
			system.playNumber(math.modf(audioFlights / 60),0,"min")
			system.playNumber(audioFlights % 60,0,"s")
		end	
		sumAudioOutput = sumAudioOutput -1
		sumAudioCounter = sumAudioCounter - 1
		if((sumAudioOutput == 0)or(sumAudioCounter == 0))then
			sumAudioOutput = 0
			system.playFile("/Apps/F3K/Audio/"..lng.."/F3K_Flights.wav",AUDIO_QUEUE)
		end
	end
end
--------------------------------------------------------------------
-- display task H '1,2,3,4 min target'
--------------------------------------------------------------------
local function screen()
    local listIndex = 0 
	local breakTimeMs = 0
	local flightTimeMs = 0
	local breakTimeTxt =  nil
	local flightTimeTxt =  nil
	local flightScreenTxt = nil
	local timeTxt = string.format( "%02d:%02d", math.modf(globVar.frameTimerF3K / 60),globVar.frameTimerF3K % 60 )
	local remainingFlightTimeTxt = nil
	local sumTimeTxt = string.format( "%02d:%02d", math.modf(sumTimerF3K / 60),sumTimerF3K % 60 )
	remainingFlightTimeTxt = string.format( "%02d:%02d",remainingFlightTimeMinF3K ,remainingFlightTimeSecF3K )
	lcd.drawText(10,15,globVar.langF3K.Screen_frame,FONT_NORMAL)
	lcd.drawText(40,5,timeTxt,FONT_MAXI)
	lcd.drawText(10,50,globVar.langF3K.Screen_flight,FONT_NORMAL)
	lcd.drawText(40,40,remainingFlightTimeTxt,FONT_MAXI)
	lcd.drawText(10,85,globVar.langF3K.Screen_Sum,FONT_NORMAL)
	lcd.drawText(40,75,sumTimeTxt,FONT_MAXI)
	
	--write best flights
	for i=1 , 4 do	
		flightTimeMs = 0
		flightTimeTxt =  nil
		if (goodFlightsF3K[sumFlightList[i]][1]>0) then
			flightTimeMs = ((goodFlightsF3K[sumFlightList[i]][1] -  math.modf(goodFlightsF3K[sumFlightList[i]][1]))*100)
			flightTimeTxt =  string.format( "%02d:%02d:%02d", math.modf(goodFlightsF3K[sumFlightList[i]][1] / 60),goodFlightsF3K[sumFlightList[i]][1] % 60,flightTimeMs ) 
			lcd.drawText(150,(i-1)*19,flightTimesTxtF3K[i],FONT_BIG)
			lcd.drawText(220,(i-1)*19,flightTimeTxt,FONT_BIG)
		end	
		if(i==sumFlightIndex)then
			break
		end
	end	
	--write current flight
	flightTimeTxt = nil
	breakTimeTxt = nil
	flightTimeMs = ((flightTimeF3K -  math.modf(flightTimeF3K))*100) 
	breakTimeMs = ((breakTimeF3K -  math.modf(breakTimeF3K))*100) 
	flightTimeTxt =  string.format( "%02d:%02d:%02d", math.modf(flightTimeF3K / 60),flightTimeF3K % 60,flightTimeMs ) 
	breakTimeTxt =  string.format( "%2d %02d:%02d:%02d",flightIndexF3K,math.modf(breakTimeF3K / 60),breakTimeF3K % 60,breakTimeMs )
	lcd.drawText(135,6*17+1,breakTimeTxt,FONT_NORMAL)
	lcd.drawText(220,6*17,flightTimeTxt,FONT_BIG)

	lcd.drawLine(1,125,310,125)
	lcd.drawLine(130,0,130,125)
	lcd.drawLine(130,99,310,99)
	
end

local task_H = {taskInit,frameTimeChanged,file,task,screen,audioFlightsChanged}
return task_H
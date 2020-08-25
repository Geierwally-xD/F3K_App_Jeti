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
-- # V1.0.5 - separate configuration from main function with dynamic storage management         
-- #############################################################################

-------------------------------------------------------------------- 
-- local variables
-------------------------------------------------------------------- 
local globVar = nil --global variables for F3K application 
local frameBox = nil
local audioBox = nil
local taskBox = nil
local configRow =1		--row of first input box
local sensorsAvailable = {}

-------------------------------------------------------------------- 
-- F3K config range check
-------------------------------------------------------------------- 
local function frameTimeRangeCheck(value,formIndex)
    if(globVar.currentTaskF3K == 1)then --Task A
        if (value > 600) then
            value = 600
        elseif (value < 420) then
            value = 420
        elseif (value == 430) then
            value = 600
        elseif (value == 590) then
            value = 420
        else
            value = 600
        end	
    else
    	if (value > 600) then           --Task B
            value = 600
        elseif (value < 420) then
            value = 420
        elseif (value == 430) then
            value = 600
        elseif (value == 590) then
            value = 420
        else
            value = 600
        end	
    end
	globVar.frameTimerF3K = value
	globVar.cfgFrameTimeF3K[globVar.currentTaskF3K]=value
  	form.setValue(formIndex,value)
	system.pSave("frameTime",globVar.cfgFrameTimeF3K)	
end

local function audioFlightsRangeCheck(value,formIndex)
    local index = 6 --default AudioFlights - index for task TS
    if(globVar.currentTaskF3K == 7)then --Task G
        -- nothing to do leave value as is
    elseif(globVar.currentTaskF3K == 8)then --Task H 
        if (value > 4) then
            value = 4
        end	
    else -- rest of tasks F, I, J, TS
        if (value > 3) then
            value = 3
        end	
    end
    if(globVar.currentTaskF3K < 11)then
        index = globVar.currentTaskF3K-5 -- calculate AudioFlights - index from task ID
    end
	globVar.cfgAudioFlights[index]=value
  	form.setValue(formIndex,value)
	system.pSave("audioFlights",globVar.cfgAudioFlights)
end
-------------------------------------------------------------------- 
-- F3K configuration
-------------------------------------------------------------------- 

local function frameTimeChanged(value)
    frameTimeRangeCheck(value,frameBox)
end
local function preFrameTimeChanged(value)
	globVar.cfgPreFrameTimeF3K=value
	system.pSave("preFrameTime",globVar.cfgPreFrameTimeF3K)
end 
local function audioFlightsChanged(value)
    audioFlightsRangeCheck(value,audioBox)
end 
local function targetTimeChanged(value) -- change flight target time for task TF training flights
  globVar.cfgTargetTimeF3K=value
  system.pSave("adtargetTime",value)
end
local function frameSwitchChanged(value)
  globVar.cfgStartFrameSwitchF3K=value
  system.pSave("frameSwitch",value)
end
local function flightSwitchChanged(value)
  globVar.cfgStartFlightSwitchF3K=value
  system.pSave("startFlightSwitch",value)
end
local function flightCountDownSwitchChanged(value)
  globVar.cfgFlightCountDownSwitchF3K=value
  system.pSave("flightCountDownSwitch",value)
end
local function measureSwitchChanged(value)
  globVar.cfgMeasureSwitchF3K=value
  system.pSave("measureSwitch",value)
end
local function stoppFlightSwitchChanged(value)
  globVar.cfgStoppFlightSwitchF3K=value
  system.pSave("stoppFlightSwitch",value)
end
local function frameAudioSwitchChanged(value)
  globVar.cfgFrameAudioSwitchF3K=value
  system.pSave("frameAudioSwitch",value)
end
local function timerResetSwitchChanged(value)
  globVar.cfgTimerResetSwitchF3K=value
  system.pSave("timerResetSwitch",value)
end

local function taskChanged()
  globVar.currentTaskF3K=form.getValue(taskBox)
  system.pSave("currentTask",globVar.currentTaskF3K)
  form.setTitle("Task "..globVar.taskList[globVar.currentTaskF3K])
  form.preventDefault()
  form.reinit(globVar.currentFormF3K)
end

local function HeightChanged(value)   -- change flight target time for task TF training flights
  globVar.cfgStartHeightF3K=value
  system.pSave("adStartHeight",value)
end

local function TimeoffsetChanged(value) -- change flight target time for task TF training flights
  globVar.cfgTimeoffsetF3K=value
  system.pSave("adTimeoffset",value)
end

local function AltSensChanged(value)
  if value>0 then
	local sensorId=sensorsAvailable[value].id
    local paramId=sensorsAvailable[value].param
    system.pSave("sensor_h",sensorId)
    system.pSave("param_h",paramId)
	globVar.heightSensorId = sensorId
	globVar.heightParamId = paramId
  end      
end

local function VarSensChanged(value)
  if value>0 then
	local sensorId=sensorsAvailable[value].id
    local paramId=sensorsAvailable[value].param
	system.pSave("sensor_vario",sensorId)
    system.pSave("param_vario",paramId)
	globVar.varioSensorId = sensorId
	globVar.varioParamId = paramId
  end      
end
-------------------------------------------------------------------- 
-- F3K config page
--------------------------------------------------------------------
local function F3K_Config()
	-- fill task select box
    form.addRow(2)
    form.addLabel({label=globVar.taskCharF3K.." )",width=40,font=FONT_BOLD})
    taskBox=form.addSelectbox(globVar.taskList,globVar.currentTaskF3K,true,taskChanged,{width=280})
	-- Assigned frame time only for task A last flight task B next to last flight all other tasks are fix
	if((globVar.currentTaskF3K==1)or(globVar.currentTaskF3K==2))then 
		local currentFrameTime = globVar.cfgFrameTimeF3K[globVar.currentTaskF3K]
		form.addRow(2)
		form.addLabel({label=globVar.langF3K.frameTime,width=220})
	    frameBox = form.addIntbox(currentFrameTime,0,1200,0,0,10,frameTimeChanged)
	end
	if((globVar.currentTaskF3K<12)or (globVar.currentTaskF3K == 15)or (globVar.currentTaskF3K == 17))then
		--globVar. Assigned pre frame time except trainins task and free flight task
		form.addRow(2)
		form.addLabel({label=globVar.langF3K.preFrameTime,width=220})
		form.addIntbox(globVar.cfgPreFrameTimeF3K,5,15,0,0,5,preFrameTimeChanged)
	end
	if(((globVar.currentTaskF3K>5) and (globVar.currentTaskF3K <11))or (globVar.currentTaskF3K == 15))then
		-- number of audio output best flights in order for tasks F,G,H,I,J and TS
	    local currentAudioFlights = globVar.cfgAudioFlights[globVar.currentTaskF3K - 5]
		if(globVar.currentTaskF3K == 15)then
			currentAudioFlights = globVar.cfgAudioFlights[6]
		end
		form.addRow(2)
		form.addLabel({label=globVar.langF3K.audioFlights,width=220})
		audioBox = form.addIntbox(currentAudioFlights,1,5,0,0,1,audioFlightsChanged)
	end
	if(globVar.currentTaskF3K == 14) then -- Assigned flight times for TF (training flight task)
		form.addRow(2)
		form.addLabel({label=globVar.langF3K.target,width=220})
		form.addIntbox(globVar.cfgTargetTimeF3K,20,900,0,0,20,targetTimeChanged)
	end
	if(globVar.currentTaskF3K == 12) then -- Assigned flight times for Task L 
		targetTimeChanged(600)
		
	end
    if(globVar.currentTaskF3K == 18) then -- sensor adjustments for Task LA launch application
        sensorsAvailable = {}
		local available = system.getSensors();
		local list={}
		local curIndex_height=-1
		local curIndex_vario=-1
		local descr = ""
		for index,sensor in ipairs(available) do 
			if(sensor.param == 0) then
				descr = sensor.label
				else
				list[#list+1]=string.format("%s [%s]-%s",sensor.label,sensor.unit,descr)
				sensorsAvailable[#sensorsAvailable+1] = sensor
				if((sensor.id==globVar.heightSensorId and sensor.param==globVar.heightParamId) ) then
					curIndex_height=#sensorsAvailable
				end
				if (sensor.id==globVar.varioSensorId and sensor.param==globVar.varioParamId) then
					curIndex_vario=#sensorsAvailable
				end
			end 
		end

		form.addRow(2)
		form.addLabel({label=globVar.langF3K.selectHeightSensor,width=220})
		form.addSelectbox (list, curIndex_height,true,AltSensChanged,{width=280})
		
		form.addRow(2)
		form.addLabel({label=globVar.langF3K.selectVarioSensor,width=220})
		form.addSelectbox (list, curIndex_vario,true,VarSensChanged,{width=280})
		
		form.addRow(2)
		form.addLabel({label=globVar.langF3K.timeoffset,width=220})
		form.addIntbox(globVar.cfgTimeoffsetF3K,0,2000,1000,0,100,TimeoffsetChanged)
		
		form.addRow(2)
		form.addLabel({label=globVar.langF3K.height,width=220})
		form.addIntbox(globVar.cfgStartHeightF3K,0,200,120,0,10, HeightChanged)
    end
	
	-- Assigned switch start frame time
	form.addRow(2)
	form.addLabel({label=globVar.langF3K.frameSwitch,width=220})
	form.addInputbox(globVar.cfgStartFrameSwitchF3K,false,frameSwitchChanged)
	-- Assigned switch start flight time
    form.addRow(2)
    form.addLabel({label=globVar.langF3K.flightSwitch,width=220})
    form.addInputbox(globVar.cfgStartFlightSwitchF3K,false,flightSwitchChanged)
	-- Assigned switch stopp flight time
    form.addRow(2)
    form.addLabel({label=globVar.langF3K.flightStoppSwitch,width=220})
    form.addInputbox(globVar.cfgStoppFlightSwitchF3K,false,stoppFlightSwitchChanged)
	-- Assigned switch audio frame time
    form.addRow(2)
    form.addLabel({label=globVar.langF3K.frameAudioSwitch,width=220})
    form.addInputbox(globVar.cfgFrameAudioSwitchF3K,false,frameAudioSwitchChanged)
	-- Assigned switch reset store
    form.addRow(2)
    form.addLabel({label=globVar.langF3K.timerResetSwitch,width=220})
    form.addInputbox(globVar.cfgTimerResetSwitchF3K,false,timerResetSwitchChanged)
	if(globVar.currentTaskF3K==5) or (globVar.currentTaskF3K==8) or (globVar.currentTaskF3K==14) then -- poker / Task H
		-- Assigned switch flight count down 
		form.addRow(2)
		form.addLabel({label=globVar.langF3K.flightCountDownSwitch,width=220})
		form.addInputbox(globVar.cfgFlightCountDownSwitchF3K,false,flightCountDownSwitchChanged)
	end	
	if(globVar.currentTaskF3K==18)then -- Task LA
		-- Assigned switch measure of launch task 
		form.addRow(2)
		form.addLabel({label=globVar.langF3K.MeasureSwitch,width=220})
		form.addInputbox(globVar.cfgMeasureSwitchF3K,false,measureSwitchChanged)
	end	
    form.setFocusedRow (configRow)
	configRow = 1
end


local function init(code,globVar_)
	globVar = globVar_
    if(code == 0) then -- first init with default values
        globVar.currentTaskF3K = system.pLoad("currentTask",1)
        globVar.cfgFrameTimeF3K = system.pLoad("frameTime",{600,600,3,600,600,600,600,600,600,600,600,600,900,600,600,600,600,600})--Frame time of all F3K training tasks in seconds
        globVar.cfgPreFrameTimeF3K = system.pLoad("preFrameTime",10)
        globVar.cfgStartFrameSwitchF3K=system.pLoad("frameSwitch")
        globVar.cfgStartFlightSwitchF3K=system.pLoad("startFlightSwitch")
        globVar.cfgStoppFlightSwitchF3K=system.pLoad("stoppFlightSwitch")
        globVar.cfgFrameAudioSwitchF3K=system.pLoad("frameAudioSwitch")
        globVar.cfgTimerResetSwitchF3K=system.pLoad("timerResetSwitch")
        globVar.cfgFlightCountDownSwitchF3K=system.pLoad("flightCountDownSwitch")
        globVar.cfgMeasureSwitchF3K=system.pLoad("measureSwitch")
        globVar.cfgTargetTimeF3K=system.pLoad("adTargetTime",60)      --only for training - task
        globVar.cfgTargetTimeF3K_TL=system.pLoad("adTargetTime",600)  --only for task TL
		globVar.taskList={globVar.langF3K.A,globVar.langF3K.B,globVar.langF3K.C,globVar.langF3K.D,globVar.langF3K.E,
				  globVar.langF3K.F,globVar.langF3K.G,globVar.langF3K.H,globVar.langF3K.I,globVar.langF3K.J,
				  globVar.langF3K.K,globVar.langF3K.L,globVar.langF3K.M,globVar.langF3K.TF,globVar.langF3K.TS,globVar.langF3K.FF,globVar.langF3K.Dold,globVar.langF3K.LA} --initialize the task list
		globVar.cfgAudioFlights = system.pLoad("audioFlights",{3,5,4,3,3,3})  -- number of audio output best flights in order for tasks F,G,H,I,J
		globVar.heightSensorId = system.pLoad("sensor_h",0) -- altitude sensor for task LA
		globVar.heightParamId = system.pLoad("param_h",0)   -- altitude sensor for task LA
		globVar.varioSensorId = system.pLoad("sensor_vario",0) -- vario sensor for task LA
		globVar.varioParamId = system.pLoad("param_vario",0)   -- vario sensor for task LA
		globVar.cfgStartHeightF3K=system.pLoad("adStartHeight",120)         
		globVar.cfgTimeoffsetF3K=system.pLoad("adTimeoffset",1000)            
        local deviceTypeF3K = system.getDeviceType()
        if(( deviceTypeF3K == "JETI DC-24")or(deviceTypeF3K == "JETI DS-24")or(deviceTypeF3K == "JETI DS-12")or(deviceTypeF3K == "JETI DC-16 II")or(deviceTypeF3K == "JETI DS-16 II"))then
            globVar.colorScreenF3K = true -- set display type
        end
    else    -- load the config window
        F3K_Config()
    end    
end


local function keyPressed(key)
	if(key==KEY_MENU or key==KEY_ESC or key == KEY_5) then
		globVar = nil
        sensorsAvailable = {}
		return(1) -- unload config
	end
end	


--------------------------------------------------------------------
local ConfigF3K = {F3K_Config,keyPressed,init}
return ConfigF3K
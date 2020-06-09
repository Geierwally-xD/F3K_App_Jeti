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
-- # V1.0.1 - Initial release for main functionalities of F3K Task	
-- # V1.0.2 - Implementation of tasks F, G, H, I, J and TT
-- # V1.0.3 - Bugfixing changed all global to local variables
-- #        - Moved all F3K Audio files into app specific F3K/audio folder       
-- # V1.0.3 - Bugfixing changed all global to local variables
-- #        - Moved all F3K Audio files into app specific F3K/audio folder  
-- # V1.0.4 - Support of DS12 Color Display and take over modifications by Gernot Tengg 
-- # V1.0.5 - separate configuration from main function with dynamic storage management           
-- #############################################################################
--Configuration
--Local variables
local task_lib = nil -- lua script of loaded task
local loadF3KLib = false -- load F3K App - Screen
local config_F3K = nil --loaded config F3K library


local labelChar = string.byte('A')
local task_Path = nil
local config_F3KPath = nil --path to config F3K lib
local tFileF3K = nil -- file object for the log files
local tDateF3K = system.getDateTime() -- current date for the file name and the task start time
local globVar = {}

--------------------------------------------------------------------
-- Configure language settings
--------------------------------------------------------------------
local function setLanguage()
  -- Set language
  local lng=system.getLocale();
  local file = io.readall("Apps/F3K/lang/"..lng.."/locale.jsn")
  local obj = json.decode(file)  
  if(obj) then
    globVar.langF3K = obj
  end
end

-------------------------------------------------------------------- 
-- Initialization
--------------------------------------------------------------------
local function resetTask_(unloadTask)
  globVar.frameTimerF3K = globVar.cfgFrameTimeF3K[globVar.currentTaskF3K] --preset frame timer with configured value
  tDateF3K = system.getDateTime()
  globVar.prevSoundTimeF3K = 0	   --previous time for audio output
  globVar.soundTimeF3K = 0		   --calculated time for audio output

  if(unloadTask == 1)then	
	globVar.taskCharF3K = nil
	if(task_lib ~= nil)then
		package.loaded[task_Path]=nil
		_G[task_Path]=nil
		task_lib = nil
		task_Path = nil
		collectgarbage('collect')
	end	
	-- load current task
  
	if(task_lib == nil)then 
		if(globVar.currentTaskF3K == 1)then -- last flight
			task_Path = "F3K/Tasks/task_A"
			task_lib = require(task_Path)
		elseif(globVar.currentTaskF3K == 2)then -- next to last flight
			task_Path = "F3K/Tasks/task_B"
			task_lib = require(task_Path)
		elseif(globVar.currentTaskF3K == 3)then -- all up last down
			task_Path = "F3K/Tasks/task_C"
			task_lib = require(task_Path)
		elseif(globVar.currentTaskF3K == 4)then --2*5 min
			task_Path = "F3K/Tasks/task_D"
			task_lib = require(task_Path)
		elseif(globVar.currentTaskF3K == 5)then --poker
			task_Path = "F3K/Tasks/task_E"
			task_lib = require(task_Path)
		elseif(globVar.currentTaskF3K == 6)then --3 out of 6
			task_Path = "F3K/Tasks/task_F"
			task_lib = require(task_Path)
		elseif(globVar.currentTaskF3K == 7)then --5 longest flights
			task_Path = "F3K/Tasks/task_G"
			task_lib = require(task_Path)
		elseif(globVar.currentTaskF3K == 8)then --1,2,3,4 min target 
			task_Path = "F3K/Tasks/task_H"
			task_lib = require(task_Path)
		elseif(globVar.currentTaskF3K == 9)then --3 longest flights
			task_Path = "F3K/Tasks/task_I"
			task_lib = require(task_Path)
		elseif(globVar.currentTaskF3K == 10)then --3 last flights
			task_Path = "F3K/Tasks/task_J"
			task_lib = require(task_Path)
		elseif(globVar.currentTaskF3K == 11)then -- big ladder
			task_Path = "F3K/Tasks/task_K"
			task_lib = require(task_Path)
		elseif(globVar.currentTaskF3K == 12)then -- training flight with fixed flight time
			task_Path = "F3K/Tasks/task_L"			
			task_lib = require(task_Path)
		elseif(globVar.currentTaskF3K == 13)then -- 3 tartget times
			task_Path = "F3K/Tasks/task_M"			
			task_lib = require(task_Path)
		elseif(globVar.currentTaskF3K == 14)then -- trainings flight task
			task_Path = "F3K/Tasks/task_TF"
			task_lib = require(task_Path)
		elseif(globVar.currentTaskF3K == 15)then -- trainings statisic task 
			task_Path = "F3K/Tasks/task_TS"
			task_lib = require(task_Path)
		elseif(globVar.currentTaskF3K == 16)then -- free flight
			task_Path = "F3K/Tasks/task_FF"
			task_lib = require(task_Path)
		elseif(globVar.currentTaskF3K == 17)then -- free flight
			task_Path = "F3K/Tasks/task_Dold"
			task_lib = require(task_Path)
        elseif(globVar.currentTaskF3K == 18)then -- launch app
			task_Path = "F3K/Tasks/task_LA"
			task_lib = require(task_Path)    
		elseif(globVar.currentTaskF3K == 19)then -- empty task, necessary for loading on startup to avoid storage lack
			-- nothing to do
		else	-- free flight is default task
			globVar.currentTaskF3K = 16
			task_Path = "F3K/Tasks/task_FF"
			task_lib = require(task_Path)	
		end
	end
	if(globVar.currentTaskF3K < 14)then
		globVar.taskCharF3K = string.char(labelChar+globVar.currentTaskF3K-1)
	elseif(globVar.currentTaskF3K == 14)then 
		globVar.taskCharF3K = "TF"
	elseif(globVar.currentTaskF3K == 15)then 
		globVar.taskCharF3K = "TS"
	elseif(globVar.currentTaskF3K == 16)then 
		globVar.taskCharF3K = "FF"
	elseif(globVar.currentTaskF3K == 17)then 
		globVar.taskCharF3K = "Dold"
	elseif(globVar.currentTaskF3K == 18)then 
		globVar.taskCharF3K = "LA"
  	else
		globVar.taskCharF3K = "  "
	end
  end -- unloadTask==1
  if(task_lib ~=nil)then
  	local func = task_lib[1]  --init() 
	func(globVar) -- execute specific initializer
  end	
end

-- Init function
local function init(code,globVar_)
	if(code == 0) then
		globVar = globVar_
		setLanguage()
        config_F3KPath = "F3K/Tasks/ConfF3K"
        config_F3K = require(config_F3KPath)
        if(config_F3K ~=nil)then
            local func = config_F3K[3]  --init() 
            func(0,globVar) -- execute specific initializer of F3K config
            package.loaded[config_F3KPath]=nil -- unload  config
            _G[config_F3KPath]=nil
            config_F3K = nil
            config_F3KPath = nil
            collectgarbage('collect')
        end
   	else
		globVar.currentTaskF3K = 19 -- unload task lib
	end
	resetTask_(1)
end

--------------------------------------------------------------------
-- main store function
--------------------------------------------------------------------
local function storeTask_()
	local fileName = string.format("F3K%02d%02d%02d.txt",tDateF3K.year-2000,tDateF3K.mon,tDateF3K.day)
	local taskChar = nil
	local modelName = system.getProperty("Model") 
	tFileF3K = io.open("Apps\\F3K\\Logs\\"..fileName,"a")
	if(tFileF3K ~= nil) then
		local fTitle = tDateF3K.hour..":"..tDateF3K.min..":"..tDateF3K.sec.."     Task "..globVar.taskList[globVar.currentTaskF3K]
		io.write(tFileF3K,"--------------------------------------------------------------------\n")
		io.write(tFileF3K,fTitle,"\n")
		io.write(tFileF3K,globVar.langF3K.model,"      ",modelName,"\n")
		io.write(tFileF3K,"--------------------------------------------------------------------\n")

		if(task_lib ~= nil) then
			local func = task_lib[3]  --file() 
			func(tFileF3K) -- execute specific file handler of task
		end	

		if((globVar.currentTaskF3K ~=3)and(globVar.currentTaskF3K <12)) then -- write remaining frame time except task c and tasks TT and FF
			local frameTimeTxt =  string.format( "%02d:%02d", math.modf(globVar.frameTimerF3K / 60),globVar.frameTimerF3K % 60 )
			io.write(tFileF3K,globVar.langF3K.remFrameTime,frameTimeTxt,"\n")
		end	
		io.close(tFileF3K)
	end	
end


-------------------------------------------------------------------- 
-- main key eventhandler
--------------------------------------------------------------------
local function keyPressedTasks(key)
	if(key==KEY_MENU or key==KEY_ESC) then
		form.preventDefault()
	elseif(key==KEY_1)then
   	-- open with Key 1 the toolbox of the app
        if(task_lib ~= nil)then
            package.loaded[task_Path]=nil
            _G[task_Path]=nil
            task_lib = nil
            task_Path = nil
            collectgarbage('collect')
        end 
        config_F3KPath = "F3K/Tasks/ConfF3K"
        config_F3K = require(config_F3KPath)
        if(config_F3K ~=nil)then
            local func = config_F3K[3]  --init() 
            func(1,globVar) -- execute specific initializer of F3K config screen
        end    
	elseif(key==KEY_2)then
	-- reset all timers and set task to start state
		resetTask_(0)
	elseif(key==KEY_3)then
		storeTask_()
	-- write task informations into file
	elseif(key==KEY_UP)then
	-- scroll up flight screen if more than 8 flights in list
		if(globVar.flightIndexScrollScreenF3K < globVar.flightIndexOffsetScreenF3K)then
			globVar.flightIndexScrollScreenF3K = globVar.flightIndexScrollScreenF3K+1
		end
	elseif(key==KEY_DOWN)then
	-- scroll down flight screen if more than 8 flights in list
		if(globVar.flightIndexScrollScreenF3K>0)then
			globVar.flightIndexScrollScreenF3K = globVar.flightIndexScrollScreenF3K-1
		end	
	end
end		

--------------------------------------------------------------------
-- main key event handler
--------------------------------------------------------------------
local function keyPressedF3K(key)
    if(config_F3K ~=nil)then
        func = config_F3K[2]  --keyPressed()
		func(key)
		if((key == KEY_5) or (key == KEY_ESC) or (key == KEY_MENU))then -- execute config event handler app template
            globVar.debugmem = math.modf(collectgarbage('count'))
            -- print("config loaded: "..globVar.debugmem.."K")	
			if(config_F3K ~= nil)then --unload F3K lib config
                -- print("unload F3Kconf")
                package.loaded[config_F3KPath]=nil
				_G[config_F3KPath]=nil
				config_F3K = nil
				config_F3KPath = nil
			end
			collectgarbage('collect')
            globVar.debugmem = math.modf(collectgarbage('count'))
            -- print("config unloaded: "..globVar.debugmem.."K")	
            resetTask_(1) 
            form.preventDefault()
            form.reinit(globVar.currentFormF3K)            
		end
    else
        keyPressedTasks(key)
   	end
end

--------------------------------------------------------------------
-- telemetry display function
--------------------------------------------------------------------
local function printTelemetry()
	if(task_lib ~= nil) then
		local func = task_lib[5]  --screen() 
		func() -- execute task specific screen handler
	end	
	local taskTxt ="Task "..globVar.taskList[globVar.currentTaskF3K]
	lcd.drawText(10,130,taskTxt,FONT_MINI)
    local frameLabel = "Powered by "..globVar.author.." for Jeti- "..globVar.F3K_Version.." "
	lcd.drawText(290 - lcd.getTextWidth(FONT_MINI,frameLabel),145,frameLabel,FONT_MINI)
	--local memTxt = "Storage: "..globVar.mem.."K"
    local memTxt = "STG: "..globVar.debugmem.." "
	lcd.drawText(10,145,memTxt,FONT_MINI)
end

--------------------------------------------------------------------
local function printForm()
 	if(task_lib ~= nil)then
		local func = task_lib[4] --task()
		func() -- execute specific task handler
        func = task_lib[5]  --screen() 
		func() -- execute task specific screen handler
        local frameLabel = "Powered by "..globVar.author.." for Jeti- "..globVar.F3K_Version.." "
        lcd.drawText(290 - lcd.getTextWidth(FONT_MINI,frameLabel),130,frameLabel,FONT_MINI)
        --local memTxt = "Storage: "..globVar.mem.."K"
        local memTxt = "STG: "..globVar.debugmem.." "
        lcd.drawText(10,130,memTxt,FONT_MINI)
	end	
end

--------------------------------------------------------------------
-- main display function
--------------------------------------------------------------------
local function initF3K(formID)
    globVar.currentFormF3K=formID
	if(task_lib ~= nil) then
		form.setTitle("Task "..globVar.taskList[globVar.currentTaskF3K])
		form.setButton(2,":delete",ENABLED)
		form.setButton(3,":file",ENABLED)
		form.setButton(1,":tools",ENABLED)
    elseif (config_F3K ~=nil) then
        local func = config_F3K[1]  -- F3K_Config 
        func() -- execute specific initializer of F3K config screen
   	end
end

--------------------------------------------------------------------
-- main Loop function
--------------------------------------------------------------------
local function loop()
	-- register the main window of F3K App
		system.registerTelemetry(2,"F3K Training",4,printTelemetry)
		system.registerForm(1,MENU_MAIN,"F3K Training",initF3K,keyPressedF3K,printForm);
	
end
 
--------------------------------------------------------------------
local F3K_Main = {resetTask_,init,storeTask_,loop}
return F3K_Main
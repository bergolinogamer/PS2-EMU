-- Lua 5.3
-- Title: Fatal Fury: Battle Archives Volume 2 - SLUS-21723 (USA) v1.00
-- Author:  Nicola Salmoria
-- Date: February 3, 2017


apiRequest(1.6)

local gpr = require( "ee-gpr-alias" )
local kFilterMode, kWrapMode, kBlendMultiplier, kBlendFunc = require("sprite")
local PadConnectType = require("pad-connect-type")

local eeObj		= getEEObject()
local emuObj	= getEmuObject()


local sprite0 = getSpriteObject(0)
local sprite1 = getSpriteObject(1)
local sprite2 = getSpriteObject(2)
local sprite3 = getSpriteObject(3)

-- Notifications should be assigned to two unused sprite slots.  Since we want them to
-- be displayed on top of everything else, they should be the highest sprites in the list.
local spr_p1_notify = getSpriteObject(4)
local spr_p2_notify = getSpriteObject(5)
local spr_p1d_notify = getSpriteObject(6)
local spr_p2d_notify = getSpriteObject(7)

-- note: Texture 0 is fixed as the PS2 scanout.
local texture1 = getTextureObject(1)
local texture2 = getTextureObject(2)
local texture3 = getTextureObject(3)
local texture4 = getTextureObject(4)
local texture5 = getTextureObject(5)
local texture6 = getTextureObject(6)
local texture7 = getTextureObject(7)

-- ------------------------------------------------------------
local STATE_STOPPED		= 0
local STATE_RUNNING		= 1

local notify_ypos = 24
local notify_p1_xsize = 0
local notify_p2_xsize = 0
local notify_p1d_xsize = 0
local notify_p2d_xsize = 0
local notify_ysize = 0

local notify_frames_p1 = 0
local notify_frames_p2 = 0
local notify_animstate_p1 = STATE_STOPPED
local notify_animstate_p2 = STATE_STOPPED

local connected_p1 = 47
local connected_p2 = 47
local blink_on_p1 = true
local blink_on_p2 = true

-- ---------------------------------------------------
-- the global function 'Global_InitGpuResources()' is invoked by the emulator after
-- the GS has been initialized.  Textures and Shaders must be loaded here.
--
Global_InitGpuResources = function()
	-- # Fragment Shader 0 is fixed as the default no-thrills as-is renderer.
	emuObj.LoadFsShader(1, "./shader_SL480_p.sb")		-- (1) = 480P ScanLine Sim

	texture1.Load("./ART1.png")
	texture2.Load("./ART2.png")
	texture3.Load("./SNK_LOGO.png")
	texture4.Load("./p1.png")
	texture5.Load("./p2.png")
	texture6.Load("./p1d.png")
	texture7.Load("./p2d.png")

	local p1_w,p1_h = texture4.GetSize()
	local p2_w,p2_h = texture5.GetSize()
	local p1d_w,p1d_h = texture6.GetSize()
	local p2d_w,p2d_h = texture7.GetSize()
	
	notify_p1_xsize = p1_w
	notify_p2_xsize = p2_w
	notify_p1d_xsize = p1d_w
	notify_p2d_xsize = p2d_w
	notify_ysize = p1_h

	spr_p1_notify.BindTexture(4)
	spr_p1_notify.SetPosXY(-1 - notify_p1_xsize, notify_ypos)   -- default position is fully obscured from view
    spr_p1_notify.SetSizeXY(p1_w,p1_h)
	spr_p1_notify.SetPosUV(0,0)
    spr_p1_notify.SetSizeUV(p1_w,p1_h)
	spr_p1_notify.SetBlendColorEquation(blendDefaultEquation)

	spr_p2_notify.BindTexture(5)
	spr_p2_notify.SetPosXY(-1 - notify_p2_xsize, notify_ypos)   -- default position is fully obscured from view
    spr_p2_notify.SetSizeXY(p2_w,p1_h)
	spr_p2_notify.SetPosUV(0,0)
    spr_p2_notify.SetSizeUV(p2_w,p1_h)
	spr_p2_notify.SetBlendColorEquation(blendDefaultEquation)

	spr_p1d_notify.BindTexture(6)
	spr_p1d_notify.SetPosXY(-1 - notify_p1d_xsize, notify_ypos)   -- default position is fully obscured from view
    spr_p1d_notify.SetSizeXY(p1d_w,p1_h)
	spr_p1d_notify.SetPosUV(0,0)
    spr_p1d_notify.SetSizeUV(p1d_w,p1_h)
	spr_p1d_notify.SetBlendColorEquation(blendDefaultEquation)

	spr_p2d_notify.BindTexture(7)
	spr_p2d_notify.SetPosXY(-1 - notify_p2d_xsize, notify_ypos)   -- default position is fully obscured from view
    spr_p2d_notify.SetSizeXY(p2d_w,p1_h)
	spr_p2d_notify.SetPosUV(0,0)
    spr_p2d_notify.SetSizeUV(p2d_w,p1_h)
	spr_p2d_notify.SetBlendColorEquation(blendDefaultEquation)
end



local update_notifications_p1 = function()

	if notify_animstate_p1 == STATE_STOPPED then 
		spr_p1_notify.Disable()
		spr_p1d_notify.Disable()
		return
	end

	emuObj.ThrottleNorm()

	local keyframe = 15

	notify_frames_p1 = notify_frames_p1 + 1

	if math.ceil(notify_frames_p1/keyframe) == notify_frames_p1/keyframe then blink_on_p1 = not blink_on_p1 end
	if blink_on_p1 == true then notify_ypos = 24 end
	if blink_on_p1 == false then notify_ypos = -84 end

--	print(string.format("rounded %s, floating %s, blink %s ypos %s", math.ceil(notify_frames_p1/keyframe), notify_frames_p1/keyframe, blink_on_p1, notify_ypos))
--	print(string.format("notify_frames_p1 %s", notify_frames_p1))

	if notify_frames_p1 >= 225 then
		notify_animstate_p1 = STATE_STOPPED
		notify_frames_p1 = 0
		connected_p1 = 47
	end

	if connected_p1 == true then
		spr_p1_notify.SetBlendColor(1.0,1.0,1.0,1.0)
		spr_p1_notify.SetPosXY(math.floor((1920-notify_p1_xsize)/2), notify_ypos)
		spr_p1_notify.Enable()
	end

	if connected_p1 == false then
		spr_p1d_notify.SetBlendColor(1.0,1.0,1.0,1.0)
		spr_p1d_notify.SetPosXY(math.floor((1920-notify_p1d_xsize)/2), notify_ypos)
		spr_p1d_notify.Enable()
	end
end

local update_notifications_p2 = function()

	if notify_animstate_p2 == STATE_STOPPED then 
		spr_p2_notify.Disable()
		spr_p2d_notify.Disable()
		return
	end

	emuObj.ThrottleNorm()

	local keyframe = 15

	notify_frames_p2 = notify_frames_p2 + 1

	if math.ceil(notify_frames_p2/keyframe) == notify_frames_p2/keyframe then blink_on_p2 = not blink_on_p2 end
	if blink_on_p2 == true then notify_ypos = 24 + notify_ysize + 8 end
	if blink_on_p2 == false then notify_ypos = -84 - notify_ysize - 8 end

--	print(string.format("rounded %s, floating %s, blink %s ypos %s", math.ceil(notify_frames_p2/keyframe), notify_frames_p2/keyframe, blink_on_p2, notify_ypos))

	if notify_frames_p2 >= 225 then
		notify_animstate_p2 = STATE_STOPPED
		notify_frames_p2 = 0
		connected_p2 = 47
	end

--	print(string.format("connected_p1 %s, connected_p2 %s", connected_p1, connected_p2))

	if connected_p2 == true then
		spr_p2_notify.SetBlendColor(1.0,1.0,1.0,1.0)
		spr_p2_notify.SetPosXY(math.floor((1920-notify_p2_xsize)/2), notify_ypos)
		spr_p2_notify.Enable()
	end

	if connected_p2 == false then
		spr_p2d_notify.SetBlendColor(1.0,1.0,1.0,1.0)
		spr_p2d_notify.SetPosXY(math.floor((1920-notify_p2d_xsize)/2), notify_ypos)
		spr_p2d_notify.Enable()
	end

end

-- slot can range from 0 to 3, for users 1 thru 4.
-- pad_type can be either:  DS4, REMOTE_DS4, REMOTE_VITA, or HID
local onHIDPadEvent = function(slot, connected, pad_type)
	spr_p1_notify.Disable()
	spr_p1d_notify.Disable()
	spr_p2_notify.Disable()
	spr_p2d_notify.Disable()
--	print(string.format("slot %s, connected %s, pad_type %s", slot, connected, pad_type))
	if pad_type == PadConnectType.HID then
		notify_frames_p1 = 0
		notify_frames_p2 = 0
		blink_on_p1 = true
		blink_on_p2 = true
		if slot == 0 then 
			connected_p1 = connected
			notify_animstate_p1 = STATE_RUNNING
		end
		if slot == 1 then 
			connected_p2 = connected 
			notify_animstate_p2 = STATE_RUNNING
		end
	end
end


local scanlineParams = {
	240.0,		-- float scanlineCount
   	0.7,		-- float scanlineHeight;
	1.5,        -- float scanlineBrightScale;
	0.5,        -- float scanlineAlpha;
	0.5         -- float vignetteStrength;
}

-- ---------------------------------------------------
-- Full Screen (480p) NoFX
-- ---------------------------------------------------

local original = function()
	sprite0.BindTexture(0)
	sprite0.BindFragmentShader(0)
	sprite0.SetPosXY((1920-1440)/2,0)
	sprite0.SetSizeXY(1440,1080)
	sprite0.SetBlendColor(1.0,1.0,1.0,1.0)
	sprite0.Enable()

	sprite1.Disable()
end

-- ---------------------------------------------------
-- Full Screen + ScanLines (480p)
-- ---------------------------------------------------

local scanlines = function()
	sprite0.BindTexture(0)
	sprite0.SetPosXY((1920-1440)/2,0)
	sprite0.SetSizeXY(1440,1080)
	sprite0.BindFragmentShader(1)
	sprite0.SetShaderParams(scanlineParams)
	sprite0.SetBlendColor(1.0,1.0,1.0,1.0)
	sprite0.Enable()

	sprite1.Disable()
end

-- ---------------------------------------------------
-- SNK Overlay NoFX
-- ---------------------------------------------------
local bezel = function()
	sprite0.BindTexture(0)
	sprite0.BindFragmentShader(0)
	sprite0.SetPosXY((1920-1280)/2, (1080-896)/2)
	sprite0.SetSizeXY(1280,896)
	sprite0.SetBlendColor(1.0,1.0,1.0,1.0)
	sprite0.Enable()

	sprite1.BindTexture(1)
	sprite1.SetPosXY(0,0)
	sprite1.SetSizeXY(1920,1080)
	sprite1.SetPosUV(0,0)
	sprite1.SetSizeUV(1920,1080)
	sprite1.Enable()
end

-- ---------------------------------------------------
-- SNK Overlay + ScanLines (480p)
-- ---------------------------------------------------

local bezel_scanlines = function()
	sprite0.BindTexture(0)
	sprite0.SetPosXY((1920-1280)/2, (1080-896)/2)
	sprite0.SetSizeXY(1280,896)
	sprite0.BindFragmentShader(1)
	sprite0.SetShaderParams(scanlineParams)
	sprite0.SetBlendColor(1.0,1.0,1.0,1.0)
	sprite0.Enable()

	sprite1.BindTexture(1)
	sprite1.SetPosXY(0,0)
	sprite1.SetSizeXY(1920,1080)
	sprite1.SetPosUV(0,0)
	sprite1.SetSizeUV(1920,1080)
	sprite1.Enable()
end

-- ---------------------------------------------------
-- Arcade Overlay NoFX
-- ---------------------------------------------------
local bezel2 = function()
	sprite0.BindTexture(0)
	sprite0.BindFragmentShader(0)
	sprite0.SetPosXY((1920-1280)/2, (1080-896)/2)
	sprite0.SetSizeXY(1280,896)
	sprite0.SetBlendColor(1.0,1.0,1.0,1.0)
	sprite0.Enable()

	sprite1.BindTexture(2)
	sprite1.SetPosXY(0,0)
	sprite1.SetSizeXY(1920,1080)
	sprite1.SetPosUV(0,0)
	sprite1.SetSizeUV(1920,1080)
	sprite1.Enable()
end

-- ---------------------------------------------------
-- Arcade Overlay + ScanLines (480p)
-- ---------------------------------------------------

local bezel2_scanlines = function()
	sprite0.BindTexture(0)
	sprite0.SetPosXY((1920-1280)/2, (1080-896)/2)
	sprite0.SetSizeXY(1280,896)
	sprite0.BindFragmentShader(1)
	sprite0.SetShaderParams(scanlineParams)
	sprite0.SetBlendColor(1.0,1.0,1.0,1.0)
	sprite0.Enable()

	sprite1.BindTexture(2)
	sprite1.SetPosXY(0,0)
	sprite1.SetSizeXY(1920,1080)
	sprite1.SetPosUV(0,0)
	sprite1.SetSizeUV(1920,1080)
	sprite1.Enable()
end


local VIDEOMODE_ORIGINAL		= 0*2 + 0
local VIDEOMODE_SCANLINES		= 0*2 + 1
local VIDEOMODE_ART1			= 1*2 + 0
local VIDEOMODE_ART1_SCANLINES	= 1*2 + 1
local VIDEOMODE_ART2			= 2*2 + 0
local VIDEOMODE_ART2_SCANLINES	= 2*2 + 1
local VIDEOMODE_LOGO			= 127

local lastVideoMode = nil

local function switchVideoMode(mode)
	if lastVideoMode ~= mode then
		lastVideoMode = mode

		emuObj.ThrottleNorm()
	
		if mode == VIDEOMODE_ORIGINAL then
			original()
		elseif mode == VIDEOMODE_SCANLINES then
			scanlines()
		elseif mode == VIDEOMODE_ART1 then
			bezel()
		elseif mode == VIDEOMODE_ART1_SCANLINES then
			bezel_scanlines()
		elseif mode == VIDEOMODE_ART2 then
			bezel2()
		elseif mode == VIDEOMODE_ART2_SCANLINES then
			bezel2_scanlines()
		end
	end
end


local logoON = function(fade)
	lastVideoMode = VIDEOMODE_LOGO

	sprite0.BindTexture(3)
	sprite0.SetPosXY(0,0)
	sprite0.SetSizeXY(1920,1080)
	sprite0.SetPosUV(0,0)
	sprite0.SetSizeUV(1920,1080)
	sprite0.SetBlendColor(fade,fade,fade,fade)
	sprite0.SetBlendColorEquation(blendConstFadeEquation)
	sprite0.Enable()

	sprite1.Disable()
end




-- convert unsigned int to signed
local function asSigned(n)
	local MAXINT = 0x80000000
	return (n >= MAXINT and n - 2*MAXINT) or n
end


local TH1 =	-- LoadingScreen constructor
	function()
		emuObj.ThrottleMax()
	end

local TH2 =	-- LoadingScreen destructor
	function()
		emuObj.ThrottleNorm()
	end


local LH1 =	-- update splash screen
	function()
		local base = eeObj.GetGpr(gpr.s0)
		local fade = eeObj.GetGpr(gpr.a1)
		local splashNum = eeObj.ReadMem32(base + 12)
		if splashNum == 4 then
			logoON(fade / 128.0)
		elseif splashNum == 5 then
			switchVideoMode(VIDEOMODE_ORIGINAL)
		end
	end


local FH1 =	-- initialize autosave flag
	function()
		local base = eeObj.GetGpr(gpr.a0)

		eeObj.WriteMem8(base + 8, 1)	-- ON
	end


local FH2A =	-- prepare Display Settings menu
	function()
		local artwork = "ARTWORK"
		local scanlines = "SCANLINES"

		eeObj.WriteMemStrZ(0x1b8d07, artwork)
		eeObj.WriteMemStrZ(0x1b8d12, scanlines)
	end

local FH2B =	-- update Position X (now Artwork) description
	function()
		local base = eeObj.GetGpr(gpr.s2)
		local buffer = eeObj.GetGpr(gpr.a1)

		local pos = asSigned(eeObj.ReadMem32(base + 256))
		-- limit to valid range
		pos = pos % 3
		eeObj.WriteMem32(base + 256, pos)

		local options = {"NONE", "ART1", "ART2"}
		eeObj.WriteMemStrZ(buffer, options[pos + 1])
	end

local FH2C =	-- update Position Y (now Scanlines) description
	function()
		local base = eeObj.GetGpr(gpr.s2)
		local buffer = eeObj.GetGpr(gpr.a1)

		local pos = asSigned(eeObj.ReadMem32(base + 260))
		-- limit to valid range
		pos = pos % 2
		eeObj.WriteMem32(base + 260, pos)

		local options = {"OFF", "ON"}
		eeObj.WriteMemStrZ(buffer, options[pos + 1])
	end


local FH3 =	-- apply display position x/y settings (now Artwork/Scanlines)
	function()
		local posX = asSigned(eeObj.GetGpr(gpr.a0))
		local posY = asSigned(eeObj.GetGpr(gpr.a1))

		eeObj.SetGpr(gpr.a0, 0)	-- force pos X to 0
		eeObj.SetGpr(gpr.a1, 0)	-- force pos Y to 0

		-- limit to valid range
		posX = posX % 3
		posY = posY % 2

		switchVideoMode(posX * 2 + posY)
	end



-- register hooks

local elfChkSelect = function(opcode, pc, expectedOpcode)
	local checkValue = eeObj.ReadMem32(0x100120)

	if checkValue == 0x3c030026 then
		assert(opcode == expectedOpcode, string.format("Overlay opcode mismatch @ 0x%06x: expected 0x%08x, found %08x", pc, expectedOpcode, opcode))
		return true
	else
		return false
	end
end

local elfChkBoot = function(opcode, pc, expectedOpcode)
	local checkValue = eeObj.ReadMem32(0x100120)

	if checkValue == 0xffb00000 then
		assert(opcode == expectedOpcode, string.format("Overlay opcode mismatch @ 0x%06x: expected 0x%08x, found %08x", pc, expectedOpcode, opcode))
		return true
	else
		return false
	end
end

local hooks = {
	-- Loading screen
	eeObj.AddHook(0x105fa8, function(op, pc) return elfChkSelect(op, pc, 0x27bdfff0) end, TH1),	-- <LoadingScreen::LoadingScreen(void)>:
	eeObj.AddHook(0x106090, function(op, pc) return elfChkSelect(op, pc, 0x27bdffd0) end, TH2),	-- <LoadingScreen::~LoadingScreen(void)>:

	-- SNK logo
	eeObj.AddHook(0x100964, function(op, pc) return elfChkBoot(op, pc, 0x8e050090) end, LH1),	-- <_ZN25_GLOBAL__N_logo.cppFOxZrb8LogoPlay4stepEv>:

	-- turn on auto save
	eeObj.AddHook(0x108778, function(op, pc) return elfChkSelect(op, pc, 0xa0800008) end, FH1),	-- <__0o5LMenuContentISaveLoadctv>:

	-- patch Position x/y options to show Artwork/Scanlines options
	eeObj.AddHook(0x110f50, function(op, pc) return elfChkSelect(op, pc, 0x34050005) end, FH2A),	-- <__0o5X__N_8_menu_cpp_761e2d17TMenuDispSettingItemctv>:
	eeObj.AddHook(0x110d88, function(op, pc) return elfChkSelect(op, pc, 0x02802825) end, FH2B),	-- <__0f5X__N_8_menu_cpp_761e2d17XMenuDispSettingPropertyEstepv>:
	eeObj.AddHook(0x110dc4, function(op, pc) return elfChkSelect(op, pc, 0x02802825) end, FH2C),	-- <__0f5X__N_8_menu_cpp_761e2d17XMenuDispSettingPropertyEstepv>:

	-- apply artwork / scanlines settings
	eeObj.AddHook(0x1084d4, function(op, pc) return elfChkSelect(op, pc, 0x8e050104) end, FH3),	-- <__0FTapplyDisplaySettingv>:
}

-- disallow skipping splash screens
eeInsnReplace(0x1009a0, 0xae000014, 0x00000000)	-- nop


-- Fight stick

HIDPad_Enable()

local addedHooks = false
local pad = function()
	if addedHooks == false then
		addedHooks = true
		switchVideoMode(VIDEOMODE_ORIGINAL)
		emuObj.AddVsyncHook(update_notifications_p1)
		emuObj.AddVsyncHook(update_notifications_p2)

-- test message on boot
--		onHIDPadEvent(0, true, PadConnectType.HID)

		-- bug report:
		-- please decrease the following title sound volume to the PS4 recommendation.
		-- REALBOUT FATAL FURY -11.49LKFS
		-- REALBOUT FATAL FURY SPECIAL -10.95LKFS
		-- RB2 THE NEWCOMERS -10.04LKFS
		-- PS4 recommendation:-24LKFS(?2)
		--
		-- that's an average of -10.83
		-- So set main volume to 0.3162 i.e. about 10dB attenuation.
		emuObj.SetVolumes(0.3162, 1.0, 1.0)
	end
end

emuObj.AddPadHook(onHIDPadEvent)
emuObj.AddEntryPointHook(pad)

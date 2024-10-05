-- Define the Hyper key combination
local hyper = {"cmd", "alt", "ctrl", "shift"}

-- Keep track of the last focused app on each screen
local lastFocusedApps = {}

-- Function to get all visible windows on a specific screen
local function getVisibleWindowsOnScreen(screen)
    local allWindows = hs.window.visibleWindows()
    local windowsOnScreen = {}

    for _, window in ipairs(allWindows) do
        if window:screen() == screen then
            table.insert(windowsOnScreen, window)
        end
    end

    return windowsOnScreen
end

-- Function to switch to the next app on the current display
local function switchToNextApp()
    local currentScreen = hs.mouse.getCurrentScreen()
    local windows = getVisibleWindowsOnScreen(currentScreen)
    local currentApp = hs.application.frontmostApplication()
    local nextAppIndex = 1

    -- Find the index of the current app
    for i, window in ipairs(windows) do
        if window:application() == currentApp then
            nextAppIndex = (i % #windows) + 1
            break
        end
    end

    -- Focus the next app
    if windows[nextAppIndex] then
        windows[nextAppIndex]:focus()
        lastFocusedApps[currentScreen:id()] = windows[nextAppIndex]:application()
    end
end

-- Function to switch to the previous app on the current display
local function switchToPreviousApp()
    local currentScreen = hs.mouse.getCurrentScreen()
    local windows = getVisibleWindowsOnScreen(currentScreen)
    local currentApp = hs.application.frontmostApplication()
    local prevAppIndex = #windows

    -- Find the index of the current app
    for i, window in ipairs(windows) do
        if window:application() == currentApp then
            prevAppIndex = ((i - 2 + #windows) % #windows) + 1
            break
        end
    end

    -- Focus the previous app
    if windows[prevAppIndex] then
        windows[prevAppIndex]:focus()
        lastFocusedApps[currentScreen:id()] = windows[prevAppIndex]:application()
    end
end

-- Function to move focus to a specific screen and select the front application
function moveFocusToScreen(screenNumber)
    local screens = hs.screen.allScreens()
    if screenNumber <= #screens then
        local targetScreen = screens[screenNumber]
        local rect = targetScreen:fullFrame()
        local center = hs.geometry.rectMidPoint(rect)
        
        -- Move mouse to center of target screen
        hs.mouse.absolutePosition(center)
        
        -- Get the frontmost application on the target screen
        local frontApp = nil
        local windows = getVisibleWindowsOnScreen(targetScreen)
        for _, win in ipairs(windows) do
            if win:application():focusedWindow() == win then
                frontApp = win:application()
                break
            end
        end
        
        -- If a frontmost application was found, focus it
        if frontApp then
            frontApp:activate()
        else
            -- If no frontmost application, just click to focus the screen
            hs.eventtap.leftClick(center)
        end
    else
        hs.alert.show("Screen " .. screenNumber .. " not available")
    end
end

-- Set up hotkeys
hs.hotkey.bind(hyper, "h", switchToNextApp)
hs.hotkey.bind(hyper, "y", switchToPreviousApp)  -- New hotkey for previous app
hs.hotkey.bind(hyper, "i", function() moveFocusToScreen(1) end)
hs.hotkey.bind(hyper, "u", function() moveFocusToScreen(2) end)
hs.hotkey.bind(hyper, "o", function() moveFocusToScreen(3) end)


--------------------------------------------------------------------------
-- Remove cmd q quit and require 2 presses to quit --------------------------------------------------------------------------


-- Variables to keep track of the quit timer and the application
local quitTimer = nil
local quitApp = nil

-- Bind the Command+Q hotkey
hs.hotkey.bind({"cmd"}, "q", function()
  -- Get the currently active application
  local currentApp = hs.application.frontmostApplication()
  
  -- Check if there's an existing timer and if it's for the same app
  if quitTimer and quitApp == currentApp then
    -- If it's the second press within the time window, quit the app
    currentApp:kill()
    -- Stop and clear the timer
    quitTimer:stop()
    quitTimer = nil
    quitApp = nil
    
    -- Show an alert that the app has been quit
   -- hs.alert.show(currentApp:name() .. " has been closed.", 1)
  else
    -- If there's an existing timer for a different app, stop it
    if quitTimer then
      quitTimer:stop()
    end
    
    -- Store the current app and start a new timer
    quitApp = currentApp
    quitTimer = hs.timer.doAfter(0.5, function()
      -- This function runs if the timer expires (0.5 seconds pass)
      -- Reset the timer and app variables
      quitTimer = nil
      quitApp = nil
    end)
    
    -- Show an alert to press again to quit
    hs.alert.show("Press Command+Q again to quit " .. currentApp:name(), 0.5)
  end
end)

  

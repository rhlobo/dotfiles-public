-- TODO: "file_progress", "Nautilus" class should not float, and should be
-- in nautilus wrokspace

------------------------------------------------------------------------
-- Imports --¬
------------------------------------------------------------------------
import Control.Monad (liftM2, when)
import System.Exit
import System.IO
import XMonad
import XMonad.Actions.CycleWindows (cycleRecentWindows)
import XMonad.Actions.CycleWS
import XMonad.Actions.CycleRecentWS
import XMonad.Actions.FindEmptyWorkspace
import XMonad.Actions.SpawnOn
import XMonad.Actions.UpdatePointer
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.FadeInactive
import XMonad.Hooks.ManageDocks (manageDocks, avoidStruts)
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName
import XMonad.Layout.MultiToggle
import XMonad.Layout.MultiToggle.Instances
import XMonad.Layout.NoBorders
import XMonad.Layout.PerWorkspace
import XMonad.Layout.Spacing
import XMonad.Layout.Gaps
import XMonad.Layout.WindowNavigation
import XMonad.Util.WorkspaceCompare
import XMonad.Util.EZConfig (additionalKeys)
import XMonad.Util.Run (spawnPipe, hPutStrLn)
import qualified Data.Map                   as M
import qualified GHC.IO.Handle.Types        as H
import qualified XMonad.Layout.Fullscreen   as FS
import qualified XMonad.StackSet            as W
-- -¬
------------------------------------------------------------------------
-- Util functions --¬
------------------------------------------------------------------------

-- Build a list of windowsets with current swapped in turn with each
-- "most recent" workspace as given by nonEmptyTags
nonEmptyRecents :: (Eq s, Eq i) => W.StackSet i l a s sd -> [W.StackSet i l a s sd]
nonEmptyRecents ws = map (W.view `flip` ws) (rotUp $ nonEmptyTags ws)

-- Given a windowset grab a list of the workspace tags, in the default order:
-- current, visibles in screen order, hiddens from most to least recently accessed.
nonEmptyTags ::  W.StackSet i l a s sd -> [i]
nonEmptyTags ws = [ tag | W.Workspace tag _ (Just _) <- W.workspaces ws]

-- rotUp and rotDown are actually exported by Actions.CycleWindows,
-- but written in an unsafe form using head tail init last :((
-- Shall have to send patch to fix that.
rotUp ::  [a] -> [a]
rotUp l = drop 1 l ++ take 1 l

-- It parallels the code for shiftTo and moveTo in Actions/CycleWS.hs
-- The goal is to move the window to the next empty workspace and then to follow it there.
followTo :: Direction1D -> WSType -> X ()
followTo dir t = doTo dir t getSortByIndex (\w -> windows (W.shift w) >> windows (W.greedyView w))


-- -¬
------------------------------------------------------------------------
-- Layout names and quick access keys --¬
------------------------------------------------------------------------
myWorkspaces :: [String]
myWorkspaces = clickable . map dzenEscape $ [ " 0 "
                                            , " 1 "
                                            , " 2 "
                                            , " 3 "
                                            , " 4 "
                                            , " 5 "
                                            , " 6 "
                                            , " 7 "
                                            , " 8 "
                                            , " 9 " ]
    where clickable l = [ x ++ ws ++ "^ca()^ca()^ca()" |
                        (i,ws) <- zip "0123456789" l,
                        let n = i
                            x =    "^ca(4,xdotool key super+Right)"
                                ++ "^ca(5,xdotool key super+Left)"
                                ++ "^ca(1,xdotool key super+" ++ show n ++ ")"]

-- -¬
------------------------------------------------------------------------
-- Key bindings --¬
------------------------------------------------------------------------
myKeys ::  XConfig l -> M.Map (KeyMask, KeySym) (X ())
myKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $
    [
        -- Dmenu
        ((modm, xK_space),              spawn "dmenu_run"),

        -- Restart and Exit
        ((modShift, xK_Escape),     spawn "killall dzen2; xmonad --recompile; xmonad --restart"),  -- TODO: Test
        ((modShift, xK_q),          io exitSuccess),  -- TODO: Test

        -- Close focused window
        ((modm, xK_q),              kill),

        -- Alternates between keyboard layouts
        ((modm, xK_Caps_Lock),      spawn "/home/rhlobo/.scripts/system/keyboard_layout_switch.sh"),

        -- Switch to US keyboard layout
        ((modShift, xK_Caps_Lock),  spawn "setxkbmap -model pc105 -layout us"),

        -- Cycle in recent windows
        ((mod1Mask, xK_Tab),        cycleRecentWindows [xK_Alt_L] xK_Tab xK_Tab),

        -- Cycle in recent workspaces
        ((modm, xK_Tab),            cycleWindowSets nonEmptyRecents [xK_Super_L] xK_Tab xK_grave),

        -- GoTo to next empty workspace
        ((modm, xK_Return),         viewEmptyWorkspace),

        -- Move (and view) to next empty workspace
        ((modShift, xK_Return),     tagToEmptyWorkspace),

        -- Navigate through workspaces
        ((modm, xK_Page_Up),        prevWS),
        ((modm, xK_Page_Down),      nextWS),

         -- Cycle through the available layout algorithms
        ((modAlt, xK_Return),      sendMessage NextLayout),

        -- Focus to adjacent screens
        ((modm, xK_z) ,             nextScreen),

        -- Move focused window to workspace on next screen
        ((modShift, xK_z),          shiftNextScreen),

        -- Swap screens
        ((modShiftCtrl, xK_z),      swapNextScreen),

        -- Change Focused Windows
        ((modm,     xK_Right), sendMessage $ Go R),
        ((modm,     xK_Left ), sendMessage $ Go L),
        ((modm,     xK_Up   ), sendMessage $ Go U),
        ((modm,     xK_Down ), sendMessage $ Go D),
        ((modCtrl,  xK_Down ), windows W.focusDown),
        ((modCtrl,  xK_Up   ), windows W.focusUp),

        -- Swap Focused Windows
        ((modShift, xK_Right), sendMessage $ Swap R),
        ((modShift, xK_Left ), sendMessage $ Swap L),
        ((modShift, xK_Up   ), sendMessage $ Swap U),
        ((modShift, xK_Down ), sendMessage $ Swap D),
        ((modShiftCtrl, xK_Down ), windows W.swapDown),
        ((modShiftCtrl, xK_Up   ), windows W.swapUp),

        -- Shrink and expand the master area
        ((modm, xK_h),              sendMessage Shrink),
        ((modm, xK_l),              sendMessage Expand),

        -- Push window back into tiling
        ((modm, xK_t),              withFocused $ windows . W.sink),

        -- Increment and decrement the number of windows in the master area
        ((modm, xK_comma),          sendMessage (IncMasterN 1)),
        ((modm, xK_period),         sendMessage (IncMasterN (-1))),

        -- Toggle fullscreen mode
        ((modm, xK_f),              sendMessage $ Toggle FULL),

        -- Print Screen
        ((modm, xK_Print),          spawn "scrot -e 'mv $f ~/2b-synched/photos/'"),

        -- Application spawning
        ((modm, xK_x),              spawn $ XMonad.terminal conf ),
        ((modm, xK_e),              spawn           "/home/rhlobo/.bin/fb"),

        ((ctrlAlt, xK_a),           spawn           "google-chrome --app=http://calendar.google.com"),
        ((ctrlAlt, xK_b),           spawn           "google-chrome"),
        ((ctrlAlt, xK_e),           spawn           "/home/rhlobo/.bin/fb"),
        ((ctrlAlt, xK_f),           spawn           "/home/rhlobo/.bin/freemind"),
        --((ctrlAltShift, xK_g),       spawnOn "mail"  "google-chrome --app=http://mail.google.com"),
        ((ctrlAltShift, xK_g),      spawn           "google-chrome --app=https://mail.google.com/mail/mu/mp/482/?mui=ca#tl/Inbox"),
        ((ctrlAlt, xK_g),           spawn           "google-chrome --app=http://mail.google.com"),
        ((ctrlAlt, xK_m),           spawn           "gnome-terminal -name mutt -e mutt"),
        ((ctrlAlt, xK_n),           spawn           "gnome-terminal -name ncmpcpp -e ncmpcpp"),
        ((ctrlAlt, xK_v),           spawn           "gvim"),
        ((ctrlAlt, xK_l),           spawn           "gnome-screensaver-command -l"),
        ((ctrlAlt, xK_t),           spawn           "/home/rhlobo/.scripts/system/touchpad_toogle.sh"),

        ((ctrlAlt, xK_c),           spawn           "/home/rhlobo/.scripts/system/process_toogle.sh gnome-control-center"),
        ((ctrlAlt, xK_Return),      spawn           "/home/rhlobo/.scripts/system/gnome-panel_toogle.sh"),


        -- Alsa Multimedia Control
        ((0, 0x1008ff11), spawn "/home/rhlobo/.xmonad/Scripts/volctl down"  ), -- TODO: FIX
        ((0, 0x1008ff13), spawn "/home/rhlobo/.xmonad/Scripts/volctl up"    ), -- TODO: FIX
        -- ((0, 0x1008ff12), spawn "/home/rhlobo/.xmonad/Scripts/volctl toggle"), -- TODO: FIX

        -- Brightness Control
        ((0, 0x1008ff03), spawn "xbacklight -dec 10"), -- TODO: FIX
        ((0, 0x1008ff02), spawn "xbacklight -inc 10") -- TODO: FIX
    ]
    ++
    -- mod-[1..9] %! Switch to workspace N
    -- mod-shift-[1..9] %! Move client to workspace N (and switch to it)
    -- mod-control-[1..9] %! Move client to workspace N
    [((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) (xK_0 : [xK_1 .. xK_9])
        , (f, m) <- [(W.greedyView, 0), (W.shift, controlMask)
                    , (\i -> W.greedyView i . W.shift i, shiftMask)]]
    ++
    -- mod-{w,e,r} %! Switch to physical/Xinerama screens 1, 2, or 3
    -- mod-shift-{w,e,r} %! Move client to screen 1, 2, or 3
    [((m .|. modm, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_u, xK_i, xK_o] [0..]
        , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]
    where modShift      = modm .|. shiftMask
          modAlt        = modm .|. mod1Mask
          modCtrl       = modm .|. controlMask
          modShiftCtrl  = modm .|. controlMask .|. shiftMask
          ctrlAlt       = mod1Mask .|. controlMask
          ctrlAltShift  = mod1Mask .|. controlMask .|. shiftMask
          dmenuCall     = "dmenu_run -i -h 20 "
                        ++ " -fn 'profont-8' "
                        ++ " -sb '" ++ colLook White 1 ++ "'"
                        ++ " -nb '#000000'"

-- -¬
------------------------------------------------------------------------
-- Mouse bindings --¬
------------------------------------------------------------------------
myMouseBindings :: XConfig t -> M.Map (KeyMask, Button) (Window -> X ())
myMouseBindings (XConfig {XMonad.modMask = modm}) = M.fromList
    [ ((modm, button1), \w -> focus w >> mouseMoveWindow w
                                      >> windows W.shiftMaster)
    , ((modm, button2), \w -> focus w >> windows W.shiftMaster)
    , ((modm, button3), \w -> focus w >> mouseResizeWindow w
                                      >> windows W.shiftMaster)
    ]

-- -¬
------------------------------------------------------------------------
-- Window rules --¬
------------------------------------------------------------------------
-- NOTE: To find the property name associated with a program, use
-- > xprop | grep WM_CLASS
-- and click on the client you're interested in.
--
-- To match on the WM_NAME, you can use 'title' in the same way that
-- 'className' and 'resource' are used below.
------------------------------------------------------------------------
myManageHook ::  ManageHook
myManageHook = manageDocks <+> composeAll
    [
    -- className =? "MPlayer"             --> doFloat
    --, className =? "MPlayer"             --> doShift        (myWorkspaces !! 5)
    --, className =? "Vlc"                 --> viewShift      (myWorkspaces !! 5)
    --, className =? "Steam"               --> viewShift      (myWorkspaces !! 5)
    --, className =? "Gimp"                --> doFloat
    --, className =? "Gimp"                --> doShift        (myWorkspaces !! 5)
    --, title     =? "MATLAB R2013a"       --> doShift        (myWorkspaces !! 5)
    --, className =? "Nautilus"            --> viewShift      (myWorkspaces !! 3)
    --, className =? "File-roller"         --> viewShift      (myWorkspaces !! 3)
    --, className =? "Zathura"             --> viewShift    (myWorkspaces !! 0)
    --, className =? "Google-chrome"       --> viewShift      (myWorkspaces !! 9)
    --, className =? "Chromium"            --> viewShift      (myWorkspaces !! 9)
    --, className =? "Firefox"             --> viewShift    (myWorkspaces !! 4)
    --, className =? "Eclipse"             --> viewShift      (myWorkspaces !! 7)
    --, className =? "SublimeText"         --> viewShift      (myWorkspaces !! 8)

    className =?  "mail.google.com"                       --> viewShift      (myWorkspaces !! 2)
    , resource =?   "mail.google.com"                       --> viewShift      (myWorkspaces !! 2)

    , title =?      "Hangouts"                              --> viewShift      (myWorkspaces !! 2)
    , className =?  "crx_nckgahadagoaajjgafhacjanaoiihapd"  --> viewShift      (myWorkspaces !! 2)
    , resource =?   "crx_nckgahadagoaajjgafhacjanaoiihapd"  --> viewShift      (myWorkspaces !! 2)

    --, resource  =? "mail.google.com"     --> viewShift    (myWorkspaces !! 2)
    --, resource  =? "desktop_window"      --> doIgnore
    , className =? "guake"                  --> doFloat
    , resource  =? "kdesktop"               --> doIgnore
    , className =? "vlc"                    --> doIgnore
    , className =? "Vlc"                    --> doIgnore
    , isFullscreen                          --> doFullFloat
    ]
    where 
        viewShift = doF . liftM2 (.) W.greedyView W.shift

-- -¬
----	--------------------------------------------------------------------
-- Status bars and logging --¬
------------------------------------------------------------------------

myLogHook ::  H.Handle -> X ()
myLogHook h = dynamicLogWithPP $ defaultPP
    {
        ppCurrent           =   dzenColor (colLook White 0)
                                          (colLook Black 0) . pad
      , ppVisible           =   dzenColor (colLook Yellow  0)
                                          (colLook Black 1) . pad
      , ppHidden            =   dzenColor (colLook Blue  0)
                                          (colLook Black 0) . pad
      , ppHiddenNoWindows   =   dzenColor (colLook BG    0)
                                          (colLook Black 1) . pad
      , ppUrgent            =   dzenColor (colLook Red   0)
                                          (colLook BG    0) . pad
      , ppWsSep             =   ""
      , ppSep               =   " | "
      , ppOrder             =   \(ws:_:_:_) -> [ws]
    }

-- -¬
------------------------------------------------------------------------
-- Window state --¬
------------------------------------------------------------------------

-- FADE INACTIVE WINDOWS
myFadeLogHook :: X ()
myFadeLogHook = fadeInactiveLogHook fadeAmount
    where fadeAmount = 0.95
{-
    TODO:
    - Dont fade hangout windows
    - Create toogle fad between windows
    - Fix fade errors:
        - When in full screen AND akternating windows
        - When focus is passed to another window through shortcuts
-}

-- -¬
------------------------------------------------------------------------
-- Color definitions --¬
------------------------------------------------------------------------
type Hex = String
type ColorCode = (Hex,Hex)
type ColorMap = M.Map Colors ColorCode

data Colors = Black | Red | Green | Yellow | Blue | Magenta | Cyan | White | BG
    deriving (Ord,Show,Eq)

colLook :: Colors -> Int -> Hex
colLook color n =
    case M.lookup color colors of
        Nothing -> "#000000"
        Just (c1,c2) -> if n == 0
                        then c1
                        else c2

colors :: ColorMap
colors = M.fromList
    [ (Black   , ("#393939",
                  "#121212"))
    , (Red     , ("#c90c25",
                  "#F21835"))
    , (Green   , ("#2a5b6a",
                  "#2f4c6a"))
    , (Yellow  , ("#54777d",
                  "#415D62"))
    , (Blue    , ("#5c5dad",
                  "#5063ab"))
    , (Magenta , ("#6f4484",
                  "#915eaa"))
    , (Cyan    , ("#2B7694",
                  "#47959E"))
    , (White   , ("#D6D6D6",
                  "#A3A3A3"))
    , (BG      , ("#000000",
                  "#444444"))
    ]

-- -¬
------------------------------------------------------------------------
-- Startup --¬
------------------------------------------------------------------------
-- [#005] STARTUP PROGRAMS
spawnToWorkspace :: String -> String -> X ()
spawnToWorkspace workspace program = -- do
    spawnOn workspace program
    -- spawn  program
    -- windows $ W.greedyView workspace

myStartupHook :: X ()
myStartupHook = do
    -- spawnToWorkspace (myWorkspaces !! 2) "google-chrome --app=http://mail.google.com"
    -- spawnToWorkspace (myWorkspaces !! 1) "google-chrome --app=http://calendar.google.com"
    -- spawnToWorkspace "task" "gvim tmp/bla"
    -- spawnToWorkspace (myWorkspaces !! 0) "gnome-terminal"
    -- spawn "google-chrome --app=http://mail.google.com"
    -- spawn "glipper"
    spawn "gnome-terminal"
    spawn "dropbox start -i"
    spawn "/home/rhlobo/.scripts/system/dropbox.sh"
    spawn "/opt/google/chrome/google-chrome --no-startup-window"
    spawn "/usr/lib/vino/vino-server --sm-disable"
    -- (windows $ W.greedyView (myWorkspaces !! 1)) >> spawn "firefox"

-- -¬
------------------------------------------------------------------------
-- Run xmonad --¬
------------------------------------------------------------------------
main :: IO ()
main = do
    startupScriptHandle <- spawnPipe "bash -c '/home/rhlobo/.xsession'"
    dzenHandle <- spawnPipe callDzen
    -- spawn callDzen

    xmonad $ defaultConfig {
        modMask                   = mod4Mask,
        terminal                  = "gnome-terminal",
        -- terminal                  = "urxvt", -- http://510x.se/notes/posts/Configuring_and_using_rxvt-unicode/
        focusFollowsMouse         = True,
        borderWidth               = 0,
        normalBorderColor         = colLook Black 1,
        focusedBorderColor        = colLook White 0,
        workspaces                = myWorkspaces,
        keys                      = myKeys,
        mouseBindings             = myMouseBindings,
        logHook                   = myFadeLogHook <+> myLogHook dzenHandle,
        -- logHook                   = myFadeLogHook <+> myLogHook dzenHandle <+> takeTopFocus >> setWMName "LG3D",
        layoutHook                = smartBorders myLayout,
        manageHook                = manageSpawn <+> myManageHook,
        handleEventHook           = FS.fullscreenEventHook,
        startupHook               = myStartupHook <+> setWMName "LG3D"
    }
    where
        callDzen = "dzen2 -ta l -bg '#c0c0c0' -y 0 -w 1366 -h 19 -e 'button3='"

        myLayout = mkToggle (NOBORDERS ?? FULL ?? EOT)  $
            --onWorkspace (myWorkspaces !! 0) focusLayout $
            onWorkspace (myWorkspaces !! 2) commLayout  $
            --onWorkspace (myWorkspaces !! 3) commLayout  $
            --onWorkspace (myWorkspaces !! 5) mediaLayout $
            --onWorkspace (myWorkspaces !! 9) focusLayout $
            --defaultLayout
            standardLayout
            where
                standardLayout = windowNavigation (avoidStruts $ tiled ||| focused ||| mirrorTiled)
                defaultLayout  = windowNavigation (avoidStruts $ tiled ||| focused ||| mirrorTiled)
                focusLayout    = windowNavigation (avoidStruts $ focused ||| tiled ||| mirrorTiled)
                commLayout     = windowNavigation (avoidStruts $ mirrorTiled)
                -- mediaLayout   = windowNavigation (FS.fullscreenFull Full)
                -- webLayout     = windowNavigation (avoidStruts $ focused ||| tiled)

                tiled             = spacing 5 $ Tall nmaster delta ratio
                fullTiled         = Tall nmaster delta ratio
                mirrorTiled       = Mirror . spacing 5 $ Tall nmaster delta ratio
                mirrorFullTiled   = Mirror fullTiled
                focused           = gaps [(L,80), (R,80),(U,10),(D,10)] $ noBorders (FS.fullscreenFull Full)

                nmaster = 1       -- The default number of windows in the master pane
                delta   = 3/100   -- Percent of screen to increment by when resizing panes
                ratio   = 0.618   -- Default proportion of screen occupied by master pane
-- -¬

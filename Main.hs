import System.Environment (getArgs)
import Graphics.UI.Gtk
import Graphics.UI.Gtk.Glade
import RFB.GUI as GUI
import RFB.CLI as CLI

main = do
    args <- getArgs
    case args of
        [host] -> do
            putStrLn $ "Connecting to " ++ host ++ "..."
            CLI.connect host 5900
        [] -> do
            initGUI
            Just xml <- xmlNew "gui.glade"
            window <- xmlGetWidget xml castToWindow "window"
            onDestroy window mainQuit
            closeButton <- xmlGetWidget xml castToButton "disconnectButton"
            onClicked closeButton $ do
                widgetDestroy window
            entry <- xmlGetWidget xml castToEntry "entry"
            passwordBox <- xmlGetWidget xml castToEntry "password"
            connectButton <- xmlGetWidget xml castToButton "connectButton"
            onClicked connectButton $ do
                host <- get entry entryText
                password <- get passwordBox entryText
                putStrLn $ "Connecting to " ++ host ++ "..."
                GUI.connect host 5900 password
            widgetShowAll window
            mainGUI
        _ -> putStrLn "Please specify the address of the host computer."


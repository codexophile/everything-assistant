#Requires AutoHotkey v2.0
#SingleInstance Force
FileTaggerPath := "c:\mega\IDEs\Electron\file-tagger\"
ElectronExePath := A_AppData "\Electron Fiddle\electron-bin\current\electron.exe"
Run(ElectronExePath " " FileTaggerPath " --files-list " '"' A_Args[1] '"')
#Requires AutoHotkey v2.0
FileTaggerPath := "c:\mega\IDEs\Electron\file-tagger\"
ElectronSubPath := "node_modules\electron\dist\electron.exe"
Run(FileTaggerPath ElectronSubPath " " FileTaggerPath " --files-list " '"' A_Args[1] '"')
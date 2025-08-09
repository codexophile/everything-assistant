#Requires AutoHotkey v2.0
#Include ..\#lib\WebViewToo\WebViewToo.ahk

MainWindow := WebViewGui("Resize")

MainWindow := WebViewGui("Resize")
MainWindow.Navigate "index.html"
MainWindow.Show "w800 h600"

Button1() {
  MainWindow.ExecuteScriptAsync("alert('hi')")
  MsgBox "You clicked button 1"
}

Button2() {
  MsgBox "You clicked button 2"
}

SubmitForm(data) {
  MsgBox data.toSend
}

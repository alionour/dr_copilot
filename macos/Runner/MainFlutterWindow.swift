import Cocoa
import FlutterMacOS
import desktop_multi_window

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    DesktopMultiWindowPlugin.setHeadlessWindowRegisterPluginCallback { register in
        RegisterGeneratedPlugins(registry: register)
    }
    
    super.awakeFromNib()
  }
}

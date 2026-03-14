import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    
    // Désactiver le redimensionnement
    //self.styleMask.remove(.resizable)
    self.styleMask.remove(.miniaturizable)
    
    // Taille fixe (optionnel)
    self.minSize = NSSize(width: 1300, height: 850)
    self.maxSize = NSSize(width: 1300, height: 850)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}

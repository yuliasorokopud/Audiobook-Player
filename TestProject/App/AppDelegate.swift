import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        let image: UIImage? = UIImage(
            systemName: "circle.fill",
            withConfiguration: UIImage.SymbolConfiguration(scale: .medium)
        )
        UISlider.appearance().setThumbImage(image, for: .normal)
        UISlider.appearance().minimumTrackTintColor = .blue
        UISlider.appearance().maximumTrackTintColor = .gray.withAlphaComponent(UIConstant.Alpha.almostClear)
        
        return true
    }
}

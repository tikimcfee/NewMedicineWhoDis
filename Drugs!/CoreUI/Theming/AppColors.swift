import Foundation
import SwiftUI

public class AppLaunchThemingUtil {
    public static func setGlobalThemes() {
        UITableView.appearance().separatorStyle = .none
    }
}

extension Color {
		
	public static let buttonText = Color.white
	public static let buttonBackground = Color.init(red: 0.4, green: 0.8, blue: 0.9)

	public static let timeForNextDose = Color.init(red: 0.2, green: 0.777, blue: 0.888, opacity: 0.3)
    public static let timeForNextDoseReady = Color.init(red: 0.2, green: 0.777, blue: 0.888, opacity: 0.5)
	public static let timeForNextDoseImageNow = Color.green
	public static let timeForNextDoseImageLater = Color.gray
	
	public static let viewBorder = Color.init(red: 0.65, green: 0.85, blue: 0.95)
	public static let buttonBorder = Color.init(red: 0.65, green: 0.85, blue: 0.95)
	
	public static let medicineCellSelected = Color.blue
	public static let medicineCellNotSelected = Color.black
}

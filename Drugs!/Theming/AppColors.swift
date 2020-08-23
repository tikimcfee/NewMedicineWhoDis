import Foundation
import SwiftUI

public class AppLaunchThemingUtil {
    public static func setGlobalThemes() {
        let tableViewAppearance = UITableView.appearance()
        tableViewAppearance.separatorStyle = .none
        tableViewAppearance.backgroundColor = nil

        let cellAppearance = UITableViewCell.appearance()
        cellAppearance.backgroundView = nil
        cellAppearance.backgroundColor = nil
    }
}

extension Color {
		
	public static let buttonText = Color.white
	public static let buttonBackground = Color.init(red: 0.4, green: 0.8, blue: 0.9)
    public static let buttonBackgroundPressed = Color.init(red: 0.4, green: 0.8, blue: 0.9, opacity: 0.5)
    public static let disabledButtonBackground = Color.init(red: 0.4, green: 0.8, blue: 0.9, opacity: 0.2)

	public static let timeForNextDose = Color.init(red: 0.2, green: 0.777, blue: 0.888, opacity: 0.3)
    public static let timeForNextDoseReady = Color.init(red: 0.2, green: 0.777, blue: 0.888, opacity: 0.5)
	public static let timeForNextDoseImageNow = Color.green
	public static let timeForNextDoseImageLater = Color.gray
	
	public static let viewBorder = Color.init(red: 0.65, green: 0.85, blue: 0.95)
	public static let buttonBorder = Color.init(red: 0.65, green: 0.85, blue: 0.95)
	
	public static let medicineCellSelected = Color.blue
	public static let medicineCellNotSelected = Color.black

    public static let computedCanTake = Color.init(red: 0.4, green: 0.8, blue: 0.9).opacity(0.6)
    public static let computedCannotTake = Color.init(red: 0.5, green: 0.5, blue: 0.5).opacity(0.4)
}

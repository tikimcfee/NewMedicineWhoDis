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
	public static let buttonBackground = Color(red: 0.4, green: 0.8, blue: 0.9)
    public static let buttonBackgroundPressed = Color(red: 0.4, green: 0.8, blue: 0.9, opacity: 0.5)
    public static let buttonBackgroundDisabled = Color(red: 0.4, green: 0.8, blue: 0.9, opacity: 0.2)

    public static let addNewButtonBackground = Color(red: 0.4, green: 0.8, blue: 0.2, opacity: 0.5)
    public static let addNewButtonPressed = Color(red: 0.4, green: 0.8, blue: 0.2, opacity: 0.2)

	public static let timeForNextDose = Color(red: 0.2, green: 0.777, blue: 0.888, opacity: 0.3)
    public static let timeForNextDoseReady = Color(red: 0.2, green: 0.777, blue: 0.888, opacity: 0.5)
	public static let timeForNextDoseImageNow = Color.green
	public static let timeForNextDoseImageLater = Color.gray
	
	public static let viewBorder = Color(red: 0.65, green: 0.85, blue: 0.95)
	public static let buttonBorder = Color(red: 0.65, green: 0.85, blue: 0.95)
	
	public static let medicineCellSelected = Color.blue
	public static let medicineCellNotSelected = Color.black

    public static let computedCanTake = Color(red: 0.4, green: 0.8, blue: 0.9).opacity(0.6)
    public static let computedCannotTake = Color(red: 0.5, green: 0.5, blue: 0.5).opacity(0.4)


}

#if DEBUG
struct Color_Previews: PreviewProvider {
    static private let colors: [Color] = [
        .buttonText,
        .buttonBackground,
        .buttonBackgroundPressed,
        .buttonBackgroundDisabled,

        .addNewButtonBackground,
        .addNewButtonPressed,

        .timeForNextDose,
        .timeForNextDoseReady,
        .timeForNextDoseImageNow,
        .timeForNextDoseImageLater,

        .viewBorder,
        .buttonBorder,

        .medicineCellSelected,
        .medicineCellNotSelected,

        .computedCanTake,
        .computedCannotTake
    ]
    
    static var previews: some View {
        List {
            ForEach(Self.colors, id: \.hashValue) { color in
                VStack {
                    Text("background: \(color.description)")
                        .fontWeight(.ultraLight)
                    VStack{ EmptyView() }
                        .frame(maxWidth: .infinity, maxHeight: 44)
                        .background(color)
                }.frame(height: 66)
            }
        }
    }
}
#endif

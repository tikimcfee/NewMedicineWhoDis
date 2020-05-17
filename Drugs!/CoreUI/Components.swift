import Foundation
import SwiftUI

public class Components {
    public static func fullWidthButton(
        _ label: String,
        _ action: @escaping () -> Void
    ) -> some View {
        return Button(action: action) {
            Text(label)
                .padding(8)
                .foregroundColor(Color.buttonText)
                .frame(maxWidth: UIScreen.main.bounds.width)
                .background(
                    Rectangle()
                        .cornerRadius(4.0)
                        .foregroundColor(Color.buttonBackground)
                )
        }
    }

}

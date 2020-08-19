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

struct ActivityIndicator: UIViewRepresentable {

    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

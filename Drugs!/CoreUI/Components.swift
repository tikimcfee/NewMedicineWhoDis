import SwiftUI

struct ComponentFullWidthButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        ComponentFullWidthButton(configuration: configuration)
    }

    struct ComponentFullWidthButton: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.isEnabled) private var isEnabled: Bool
        var body: some View {
            configuration
                .label
                .background(
                    Rectangle()
                        .cornerRadius(4.0)
                        .foregroundColor(
                            isEnabled
                                ? Color.buttonBackground
                                : Color.disabledButtonBackground
                    )
                )
        }
    }
}

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
        }.buttonStyle(ComponentFullWidthButtonStyle())
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

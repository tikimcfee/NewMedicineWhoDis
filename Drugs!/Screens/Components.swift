import SwiftUI

struct ComponentFullWidthButtonStyle: ButtonStyle {
    let pressedColor: Color
    let standardColor: Color
    let disabledColor: Color

    init(pressedColor: Color = Color.buttonBackgroundPressed,
         standardColor: Color = Color.buttonBackground,
         disabledColor: Color = Color.buttonBackgroundDisabled
    ) {
        self.pressedColor = pressedColor
        self.standardColor = standardColor
        self.disabledColor = disabledColor
    }

    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        ComponentFullWidthButton(
            configuration: configuration,
            pressedColor: pressedColor,
            standardColor: standardColor,
            disabledColor: disabledColor
        )
    }

    struct ComponentFullWidthButton: View {
        let configuration: ButtonStyle.Configuration
        let pressedColor: Color
        let standardColor: Color
        let disabledColor: Color

        @Environment(\.isEnabled) private var isEnabled: Bool

        var body: some View {
            configuration.label.background(
                Rectangle()
                    .cornerRadius(4.0)
                    .foregroundColor(
                        isEnabled
                            ? configuration.isPressed
                                ? pressedColor
                                : standardColor
                            : disabledColor
                    )
            )
        }
    }
}

public struct ComponentSimpleButtonStyle: ButtonStyle {
    let pressedColor: Color
    let standardColor: Color
    let disabledColor: Color
    
    init(pressedColor: Color = Color.buttonBackgroundPressed,
         standardColor: Color = Color.buttonBackground,
         disabledColor: Color = Color.buttonBackgroundDisabled
    ) {
        self.pressedColor = pressedColor
        self.standardColor = standardColor
        self.disabledColor = disabledColor
    }
    
    public func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        ComponentSimpleButton(
            configuration: configuration,
            pressedColor: pressedColor,
            standardColor: standardColor,
            disabledColor: disabledColor
        )
    }
    
    struct ComponentSimpleButton: View {
        let configuration: ButtonStyle.Configuration
        let pressedColor: Color
        let standardColor: Color
        let disabledColor: Color
        
        @Environment(\.isEnabled) private var isEnabled: Bool
        
        var body: some View {
            configuration.label.background(
                Rectangle()
                    .cornerRadius(4.0)
                    .foregroundColor(
                        isEnabled
                            ? (configuration.isPressed ? pressedColor : standardColor)
                            : (disabledColor)
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
        Button(action: action) {
            Text(label)
                .padding(8)
                .foregroundColor(Color.buttonText)
                .frame(maxWidth: UIScreen.main.bounds.width)
        }.buttonStyle(ComponentFullWidthButtonStyle())
    }
    
    public static func simpleButton(
        _ label: String,
        _ style: ComponentSimpleButtonStyle,
        _ action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .padding(8)
                .foregroundColor(Color.buttonText)
        }.buttonStyle(style)
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


//MARK: - View modifiers

extension View {
    func asButton(_ action: @escaping () -> Void) -> some View{
        return modifier(AsButtonMod(action: action))
    }
}

struct AsButtonMod: ViewModifier {
    let action: () -> Void
    func body(content: Content) -> some View {
        return Button(action: action) { content }
    }
}

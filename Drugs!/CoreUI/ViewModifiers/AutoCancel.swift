import SwiftUI
import Combine

struct AutoCancel: ViewModifier {
    private static var nextId: Int = 0
    private static let getId: () -> Int = { nextId += 1; return nextId  }
    let id = getId()

    @State var cancellable: AnyCancellable? = nil
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    let action: (Date) -> Void

    public init(_ with: @escaping (Date) -> Void) {
        self.action = with
    }

    func body(content: Content) -> some View {
        return content
            .onAppear {
                self.cancellable = self.timer.sink {
                    print("Refreshing view -> \(self.id)")
                    self.action($0)
                }
            }
            .onDisappear { self.cancellable?.cancel() }
    }
}

extension View {
    func refreshTimer(_ with: @escaping (Date) -> Void) -> some View {
        return modifier(AutoCancel(with))
    }
}

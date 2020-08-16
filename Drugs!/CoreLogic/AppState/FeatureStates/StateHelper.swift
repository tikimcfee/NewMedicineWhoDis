import Combine

protocol StateHelper {
    var cancellables: Set<AnyCancellable?> { get }
}

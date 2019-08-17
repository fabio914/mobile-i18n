import Foundation

class ConsoleOutput {

    enum WarningLevel {
        case disabled
        case normal
        case all
    }

    private var err = FileHandle.standardError
    var warningLevel: WarningLevel = .normal

    func warning(_ string: String) {
        guard warningLevel != .disabled else { return }
        print(string, to: &err)
    }

    func extraWarning(_ string: String) {
        guard warningLevel == .all else { return }
        print(string, to: &err)
    }

    func fatalError(_ string: String) {
        print(string, to: &err)
        exit(1)
    }
}

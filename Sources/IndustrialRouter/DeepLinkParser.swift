import Foundation

// MARK: - Deep Link Parser

public enum DeepLinkParser {
    public typealias Mapper = ([String: Any]) -> (path: any RoutePath, params: [String: Any]?)

    private static let lock = NSLock()
    private static var registry: [String: Mapper] = [:]

    /// Registers a link matching rule.
    /// Examples:
    /// - `goods/detail` matches `myapp://goods/detail?itemId=1`
    /// - `example.com/goods/detail` matches `https://example.com/goods/detail?itemId=1`
    public static func register(_ pattern: String, mapper: @escaping Mapper) {
        lock.lock()
        registry[normalize(pattern)] = mapper
        lock.unlock()
    }

    public static func removeAll() {
        lock.lock()
        registry.removeAll()
        lock.unlock()
    }

    public static func parse(_ urlString: String) -> (path: any RoutePath, params: [String: Any]?)? {
        guard let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let host = components.host ?? ""
        let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let key = path.isEmpty ? host : "\(host)/\(path)"

        var queryParams: [String: Any] = [:]
        components.queryItems?.forEach { item in
            queryParams[item.name] = item.value
        }

        lock.lock()
        let mapper = registry[normalize(key)]
        lock.unlock()

        if let mapper {
            return mapper(queryParams)
        }

        assertionFailure("[Router] No deep link rule matches: \(urlString)")
        return nil
    }

    private static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .lowercased()
    }
}

import Foundation

enum LevelStore {
    static func decode(_ data: Data) throws -> [Level] {
        try JSONDecoder().decode([Level].self, from: data)
    }

    static func loadBundled(_ bundle: Bundle = .main) -> [Level] {
        guard let url = bundle.url(forResource: "levels", withExtension: "json") else {
            fatalError("levels.json is missing from the bundle")
        }
        do {
            return try decode(Data(contentsOf: url))
        } catch {
            fatalError("levels.json is invalid: \(error)")
        }
    }
}

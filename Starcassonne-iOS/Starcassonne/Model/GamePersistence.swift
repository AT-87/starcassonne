//
//  GamePersistence.swift
//  Starcassonne
//
//  Single save-slot JSON persistence.
//

import Foundation

enum GamePersistence {

    // MARK: - Save location

    static var saveURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("starcassonne_save.json")
    }

    static var hasSave: Bool {
        FileManager.default.fileExists(atPath: saveURL.path)
    }

    // MARK: - Read / Write

    static func save(_ state: GameState) throws {
        let data = try JSONEncoder().encode(state)
        try data.write(to: saveURL, options: .atomic)
    }

    static func load() throws -> GameState {
        let data = try Data(contentsOf: saveURL)
        return try JSONDecoder().decode(GameState.self, from: data)
    }

    static func deleteSave() {
        try? FileManager.default.removeItem(at: saveURL)
    }
}

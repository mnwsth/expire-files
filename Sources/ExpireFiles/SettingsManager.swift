import Foundation

class SettingsManager {
    private let userDefaults = UserDefaults.standard
    private let watchedFoldersKey = "watchedFolders"
    
    func saveWatchedFolders(_ folders: [WatchedFolder]) {
        do {
            let data = try JSONEncoder().encode(folders)
            userDefaults.set(data, forKey: watchedFoldersKey)
        } catch {
            print("Failed to save watched folders: \(error)")
        }
    }
    
    func loadWatchedFolders() -> [WatchedFolder] {
        guard let data = userDefaults.data(forKey: watchedFoldersKey) else {
            // Return default Downloads folder if no settings exist
            let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            return [WatchedFolder(url: downloadsURL, name: "Downloads")]
        }
        
        do {
            return try JSONDecoder().decode([WatchedFolder].self, from: data)
        } catch {
            print("Failed to load watched folders: \(error)")
            // Return default Downloads folder if loading fails
            let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            return [WatchedFolder(url: downloadsURL, name: "Downloads")]
        }
    }
}

//  Copyright © 2019 Software101. All rights reserved.

import UIKit

private let diskCacheSaveQueue = DispatchQueue(label: "DiskCache.queue")
class DiskCache<CacheData: Codable>: CacheStorage {
    var cacheData: CacheData?
    
    private let savePath: String
    private let fileManager: FileManager
    private var saveTimer: Timer?

    init(filename: String, fileManager: FileManager = FileManager.default, savePeriodSeconds: TimeInterval = 30) {
        self.fileManager = fileManager
        savePath = try! fileManager.documentPath(for: filename)

        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
            guard let cacheData = self.cacheData else { return }
            self.cacheData = nil
            self.nonQueuedSave(cacheData)
        }

        setupSaveTimer(savePeriodSeconds: savePeriodSeconds)
    }

    deinit {
        saveTimer?.invalidate()
        guard let cacheData = cacheData else { return }
        nonQueuedSave(cacheData)
    }

    func save() {
        diskCacheSaveQueue.sync {
            guard let cacheData = cacheData else { return }
            self.cacheData = nil
            self.nonQueuedSave(cacheData)
        }
    }
}

extension DiskCache {
    private func setupSaveTimer(savePeriodSeconds: TimeInterval) {
        let saveTimer = Timer.scheduledTimer(withTimeInterval: savePeriodSeconds, repeats: true) { _ in
            self.save()
        }
        self.saveTimer = saveTimer
    }

    func load() -> CacheData? {
        guard fileManager.fileExists(atPath: savePath) else { return nil }
        do {
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: savePath))
            let jsonDecoder = JSONDecoder()
            let cacheData = try jsonDecoder.decode(CacheData.self, from: jsonData)
            return cacheData
        } catch {
            print("DiskCache.load().Failed to load \(savePath): \(error)")
            return nil
        }
    }

    private func nonQueuedSave(_ data: CacheData) {
        let savePath = self.savePath
        do {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(data)
            try jsonData.write(to: URL(fileURLWithPath: savePath))
        } catch {
            print("DiskCache.save().Failed to save \(savePath): \(error)")
        }
    }
}

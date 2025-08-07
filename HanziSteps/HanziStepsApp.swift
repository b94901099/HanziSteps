//
//  HanziStepsApp.swift
//  HanziSteps
//
//  Created by Sheng-Lun Chen on 7/31/25.
//

import SwiftUI
import SwiftData

@main
struct HanziStepsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Sentence.self,
            Story.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // 初始化預設數據
            Task { @MainActor in
                initializeDefaultData(in: container)
            }
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - 預設數據初始化
@MainActor
private func initializeDefaultData(in container: ModelContainer) {
    let context = container.mainContext
    
    // 檢查是否已有數據
    let storyFetchDescriptor = FetchDescriptor<Story>()
    let sentenceFetchDescriptor = FetchDescriptor<Sentence>()
    
    do {
        let existingStories = try context.fetch(storyFetchDescriptor)
        let existingSentences = try context.fetch(sentenceFetchDescriptor)
        
        if existingStories.isEmpty && existingSentences.isEmpty {
            // 使用新的 DataManager 初始化數據
            DataManager.shared.initializeLocalData(in: context)
            print("✅ 使用新數據管理系統初始化完成")
        } else {
            print("✅ 數據已存在，跳過初始化")
            // 為了測試，我們可以強制重新加載數據
            // 先清除現有數據
            for story in existingStories {
                context.delete(story)
            }
            for sentence in existingSentences {
                context.delete(sentence)
            }
            try context.save()
            print("🗑️ 已清除現有數據")
            
            // 重新加載數據
            DataManager.shared.initializeLocalData(in: context)
            print("✅ 已重新加載 stories.json 數據")
        }
    } catch {
        print("❌ 數據初始化失敗: \(error)")
    }
}

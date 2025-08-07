//
//  DataManager.swift
//  HanziSteps
//
//  Created by Sheng-Lun Chen on 7/31/25.
//

import SwiftUI
import SwiftData

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    private init() {}
    
    // MARK: - 本地 JSON 數據加載
    func loadLocalStories() -> [StoryData] {
        guard let url = Bundle.main.url(forResource: "stories", withExtension: "json") else {
            print("❌ 找不到 stories.json 文件")
            return []
        }
        
        guard let data = try? Data(contentsOf: url) else {
            print("❌ 無法讀取 stories.json 文件數據")
            return []
        }
        
        do {
            let stories = try JSONDecoder().decode([StoryData].self, from: data)
            print("✅ 成功加載 \(stories.count) 個故事")
            for story in stories {
                print("📖 故事: \(story.title) (ID: \(story.id)) - \(story.sentences.count) 個句子")
            }
            return stories
        } catch {
            print("❌ JSON 解析失敗: \(error)")
            return []
        }
    }
    
    // MARK: - 初始化本地數據
    func initializeLocalData(in context: ModelContext) {
        print("🔄 開始初始化本地數據...")
        let stories = loadLocalStories()
        
        if stories.isEmpty {
            print("❌ 沒有故事數據可加載")
            return
        }
        
        for storyData in stories {
            print("📝 創建故事: \(storyData.title)")
            let story = Story(
                id: storyData.id,
                title: storyData.title,
                storyDescription: storyData.storyDescription,
                level: storyData.level,
                coverImageUrl: storyData.coverImageUrl,
                isUnlocked: storyData.isUnlocked
            )
            
            // 添加句子
            for sentenceData in storyData.sentences {
                let sentence = Sentence(
                    id: sentenceData.id,
                    text: sentenceData.text,
                    words: sentenceData.words,
                    answerPositions: sentenceData.answerPositions,
                    storyId: storyData.id,
                    order: sentenceData.order,
                    imageUrl: sentenceData.imageUrl
                )
                story.sentences.append(sentence)
            }
            
            context.insert(story)
            print("✅ 已插入故事: \(story.title) 包含 \(story.sentences.count) 個句子")
        }
        
        do {
            try context.save()
            print("✅ 本地數據初始化完成，已保存到數據庫")
        } catch {
            print("❌ 保存數據失敗: \(error)")
        }
    }
    
    // MARK: - 遠端數據同步（未來功能）
    func syncRemoteData() async {
        // TODO: 實現從 Firebase 或其他遠端服務同步數據
        // 這裡將在後續版本中實現
    }
}

// MARK: - JSON 數據結構
struct StoryData: Codable {
    let id: String
    let title: String
    let storyDescription: String
    let level: Int
    let coverImageUrl: String?
    let isUnlocked: Bool
    let sentences: [SentenceData]
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case storyDescription
        case level
        case coverImageUrl
        case isUnlocked
        case sentences
    }
}

struct SentenceData: Codable {
    let id: String
    let text: String
    let words: [String]
    let answerPositions: [Int]
    let order: Int
    let imageUrl: String?
} 
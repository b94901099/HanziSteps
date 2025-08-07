//
//  ContentView.swift
//  HanziSteps
//
//  Created by Sheng-Lun Chen on 7/31/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var stories: [Story]

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("步步識字")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("歡迎來到漢字學習世界！")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                // 故事列表
                if !stories.isEmpty {
                    VStack(spacing: 15) {
                        Text("可用的故事 (\(stories.count) 個):")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        ForEach(stories, id: \.id) { story in
                            NavigationLink(destination: StoryReaderView(storyId: story.id)) {
                                HStack {
                                    Image(systemName: "book.fill")
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading) {
                                        Text(story.title)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                        Text(story.storyDescription)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("\(story.sentences.count) 句")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 15) {
                        Text("正在載入故事...")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Button("重新載入故事") {
                            // 強制重新載入數據
                            DataManager.shared.initializeLocalData(in: modelContext)
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                
                // 學習按鈕
                NavigationLink(destination: LearningView()) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                        Text("認字練習")
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.green)
                    .cornerRadius(25)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Sentence.self, Story.self], inMemory: true)
}

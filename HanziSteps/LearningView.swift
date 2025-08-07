//
//  LearningView.swift
//  HanziSteps
//
//  Created by Sheng-Lun Chen on 7/31/25.
//

import SwiftUI
import SwiftData
import AVFoundation

struct DropDelegate: SwiftUI.DropDelegate {
    let index: Int
    @Binding var grid: [String?]
    @Binding var draggedWord: String?

    func performDrop(info: DropInfo) -> Bool {
        if let dragged = draggedWord {
            grid[index] = dragged
            return true
        }
        return false
    }

    func dropEntered(info: DropInfo) {
        if let dragged = draggedWord {
            grid[index] = dragged
        }
    }

    func dropExited(info: DropInfo) {
        if grid[index] == draggedWord {
            grid[index] = nil
        }
    }
}

struct LearningView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var sentences: [Sentence]
    @State private var draggedWord: String? = nil
    @State private var grid: [String?] = []
    @State private var cards: [String] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 句子展示區
                Text(sentences.first?.text ?? "無句子")
                    .font(.title)
                    .padding()

                // 格子區
                HStack(spacing: 10) {
                    ForEach(0..<grid.count, id: \.self) { index in
                        ZStack {
                            Rectangle()
                                .frame(width: 100, height: 100)
                                .border(grid[index] == nil ? Color.gray : Color.green)
                            Text(grid[index] ?? "")
                                .font(.title)
                        }
                        .onDrop(of: [.text], delegate: DropDelegate(index: index, grid: $grid, draggedWord: $draggedWord))
                    }
                }

                // 卡片區
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(cards, id: \.self) { word in
                            Text(word)
                                .font(.title)
                                .frame(width: 100, height: 100)
                                .background(Color.yellow)
                                .cornerRadius(10)
                                .onDrag {
                                    draggedWord = word
                                    return NSItemProvider(object: word as NSString)
                                }
                        }
                    }
                }
                .frame(height: 120)

                // 朗讀按鈕
                Button("朗讀句子") {
                    speakSentence()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .navigationTitle("認字練習")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                setupPreviewData()
                if let sentence = sentences.first {
                    cards = sentence.words
                    // 根據句子長度動態調整 grid 大小
                    grid = Array(repeating: nil, count: sentence.text.count)
                }
            }
        }
    }
    
    func speakSentence() {
        guard let sentence = sentences.first?.text else { return }
        let utterance = AVSpeechUtterance(string: sentence)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-TW")
        utterance.rate = 0.5
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
    
    // MARK: - 預覽數據設置
    private func setupPreviewData() {
        // 如果沒有數據，創建一些測試數據
        if sentences.isEmpty {
            let testSentence = Sentence(
                id: "test_sentence_01",
                text: "樹上有許多葉子",
                words: ["樹", "葉"],
                answerPositions: [0, 4],
                storyId: "test_story",
                order: 1
            )
            modelContext.insert(testSentence)
            try? modelContext.save()
        }
    }
}

#Preview(traits: .landscapeLeft) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Sentence.self, configurations: config)
    
    LearningView()
        .modelContainer(container)
}

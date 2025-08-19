//
//  LearningView.swift
//  HanziSteps
//
//  Created by Sheng-Lun Chen on 7/31/25.
//

import SwiftUI
import SwiftData
import AVFoundation

struct LearningView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var sentences: [Sentence]
    @State private var synthesizer = AVSpeechSynthesizer()

    var body: some View {
        VStack(spacing: 20) {
            // 句子展示區
            Text(sentences.first?.text ?? "無句子")
                .font(.title)
                .padding()
                .multilineTextAlignment(.center)
            
            // 單字展示區
            if let sentence = sentences.first {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                    ForEach(sentence.words, id: \.self) { word in
                        Text(word)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(width: 60, height: 60)
                            .background(Color.yellow)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // 朗讀按鈕
            Button("朗讀句子") {
                speakSentence()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Spacer()
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
        }
    }
    
    func speakSentence() {
        guard let sentence = sentences.first?.text else { return }
        print("🔊 開始朗讀句子: \(sentence)")
        
        let utterance = AVSpeechUtterance(string: sentence)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-TW")
        utterance.rate = 0.5
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
        print("🎤 朗讀已開始")
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

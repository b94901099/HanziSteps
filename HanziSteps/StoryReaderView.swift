//
//  StoryReaderView.swift
//  HanziSteps
//
//  Created by Sheng-Lun Chen on 7/31/25.
//

import SwiftUI
import SwiftData
import AVFoundation

// MARK: - 語音合成代理類
class SpeechSynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var onStart: (() -> Void)?
    var onFinish: (() -> Void)?
    var onCancel: (() -> Void)?
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        onStart?()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish?()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onCancel?()
    }
}

struct StoryReaderView: View {
    let storyId: String
    @Environment(\.modelContext) private var modelContext
    @Query private var stories: [Story]
    @State private var currentPageIndex = 0
    @State private var isSpeaking = false
    @State private var speechMessage = ""
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var speechDelegate = SpeechSynthesizerDelegate()

    
    private var currentStory: Story? {
        stories.first { $0.id == storyId }
    }
    
    private var sortedSentences: [Sentence] {
        currentStory?.sentences.sorted { $0.order < $1.order } ?? []
    }
    
    private var currentSentence: Sentence? {
        guard currentPageIndex < sortedSentences.count else { return nil }
        return sortedSentences[currentPageIndex]
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 頂部導航欄
                HStack(spacing: 12) {
                    Button(action: goBack) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .frame(width: 44, height: 44)
                    
                    Spacer()
                    
                    Text(currentStory?.title ?? "故事")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: geometry.size.width * 0.4)
                    
                    Spacer()
                    
                    Button(action: speakCurrentSentence) {
                        HStack(spacing: 6) {
                            Image(systemName: isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                                .font(.title3)
                            Text(isSpeaking ? "朗讀中" : "朗讀")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(isSpeaking ? Color.orange : Color.blue)
                                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                        )
                    }
                    .disabled(isSpeaking)
                    .scaleEffect(isSpeaking ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isSpeaking)
                    .frame(maxWidth: geometry.size.width * 0.3)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                
                // 主要內容區域
                ZStack {
                    // 背景圖片
                    if let imageUrl = currentSentence?.imageUrl,
                       let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        VStack {
                                            ProgressView()
                                                .scaleEffect(1.5)
                                            Text("載入圖片中...")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    )
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height * 0.55)
                            case .failure(let error):
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        VStack {
                                            Image(systemName: "photo")
                                                .font(.largeTitle)
                                                .foregroundColor(.gray)
                                            Text("圖片載入失敗")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                            Text(error.localizedDescription)
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal)
                                        }
                                    )
                                    .onAppear {
                                        print("❌ 圖片載入失敗: \(error.localizedDescription)")
                                        print("🔗 圖片URL: \(imageUrl)")
                                    }
                            @unknown default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.55)
                        .onAppear {
                            print("🖼️ 嘗試載入圖片: \(imageUrl)")
                        }
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.55)
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                    Text("無圖片")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            )
                            .onAppear {
                                print("⚠️ 沒有圖片URL或URL格式錯誤")
                                if let imageUrl = currentSentence?.imageUrl {
                                    print("🔗 圖片URL: \(imageUrl)")
                                }
                            }
                    }
                    
                    // 翻頁按鈕
                    HStack {
                        // 上一頁按鈕
                        Button(action: previousPage) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .disabled(currentPageIndex == 0)
                        .opacity(currentPageIndex == 0 ? 0.3 : 1.0)
                        
                        Spacer()
                        
                        // 下一頁按鈕
                        Button(action: nextPage) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .disabled(currentPageIndex >= sortedSentences.count - 1)
                        .opacity(currentPageIndex >= sortedSentences.count - 1 ? 0.3 : 1.0)
                    }
                    .padding(.horizontal, 16)
                }
                .frame(width: geometry.size.width)
                
                // 文字區域
                VStack(spacing: 12) {
                    Text(currentSentence?.text ?? "")
                        .font(.system(size: calculateFontSize(for: geometry), weight: .bold, design: .default))
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .frame(maxWidth: geometry.size.width)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.primary)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
                    
                    // 頁碼指示器
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(0..<sortedSentences.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentPageIndex ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 16)
                }
                .background(Color(.systemBackground))
                .frame(width: geometry.size.width)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            print("📖 開始閱讀故事: \(storyId)")
        }
    }
    
    // MARK: - 導航功能
    @Environment(\.dismiss) private var dismiss
    
    private func goBack() {
        dismiss()
    }
    
    private func previousPage() {
        // 停止當前朗讀
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPageIndex = max(0, currentPageIndex - 1)
        }
    }
    
    private func nextPage() {
        // 停止當前朗讀
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPageIndex = min(sortedSentences.count - 1, currentPageIndex + 1)
        }
    }
    
    // MARK: - 字體大小計算
    private func calculateFontSize(for geometry: GeometryProxy) -> CGFloat {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        let screenWidth = geometry.size.width
        let screenHeight = geometry.size.height
        let textLength = currentSentence?.text.count ?? 0
        
        // 基礎字體大小
        var baseFontSize: CGFloat = 40
        
        if isIPad {
            // iPad 字體大小計算
            if screenWidth > screenHeight {
                // 橫向模式 - 有更多水平空間
                baseFontSize = min(screenWidth * 0.045, 68)
            } else {
                // 縱向模式 - 有更多垂直空間
                baseFontSize = min(screenWidth * 0.055, 76)
            }
        } else {
            // iPhone 字體大小計算
            if screenWidth > screenHeight {
                // 橫向模式
                baseFontSize = min(screenWidth * 0.075, 52)
            } else {
                // 縱向模式
                baseFontSize = min(screenWidth * 0.095, 56)
            }
        }
        
        // 根據文字長度調整字體大小
        if textLength > 20 {
            baseFontSize *= 0.9
        } else if textLength > 15 {
            baseFontSize *= 0.95
        }
        
        // 確保最小字體大小
        return max(baseFontSize, 36)
    }
    
    // MARK: - 朗讀功能
    private func speakCurrentSentence() {
        guard let sentence = currentSentence?.text else { return }
        
        // 如果正在朗讀，先停止
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            return
        }
        
        let utterance = AVSpeechUtterance(string: sentence)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-TW")
        utterance.rate = 0.5
        utterance.volume = 1.0
        
        // 設置代理回調
        speechDelegate.onStart = {
            DispatchQueue.main.async {
                self.isSpeaking = true
                self.speechMessage = "正在朗讀..."
            }
        }
        
        speechDelegate.onFinish = {
            DispatchQueue.main.async {
                self.isSpeaking = false
                self.speechMessage = "朗讀完成"
                
                // 2秒後清除消息
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.speechMessage = ""
                }
            }
        }
        
        speechDelegate.onCancel = {
            DispatchQueue.main.async {
                self.isSpeaking = false
                self.speechMessage = "朗讀已取消"
                
                // 2秒後清除消息
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.speechMessage = ""
                }
            }
        }
        
        // 設置代理來監聽朗讀狀態
        synthesizer.delegate = speechDelegate
        
        synthesizer.speak(utterance)
    }
    

}



#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Story.self, Sentence.self, configurations: config)
    
    StoryReaderView(storyId: "story_pangu")
        .modelContainer(container)
} 

//
//  Sentence.swift
//  HanziSteps
//
//  Created by Sheng-Lun Chen on 7/31/25.
//

import Foundation
import SwiftData

@Model
class Sentence {
    var id: String
    var text: String
    var words: [String]
    var answerPositions: [Int]
    var storyId: String
    var order: Int
    var imageUrl: String?
    var createdAt: Date
    var updatedAt: Date

    init(id: String, text: String, words: [String], answerPositions: [Int], storyId: String, order: Int, imageUrl: String? = nil) {
        self.id = id
        self.text = text
        self.words = words
        self.answerPositions = answerPositions
        self.storyId = storyId
        self.order = order
        self.imageUrl = imageUrl
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

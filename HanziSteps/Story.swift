//
//  Story.swift
//  HanziSteps
//
//  Created by Sheng-Lun Chen on 7/31/25.
//

import SwiftData
import Foundation

@Model
class Story {
    var id: String
    var title: String
    var storyDescription: String
    var coverImageUrl: String?
    var level: Int
    var isUnlocked: Bool
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade) var sentences: [Sentence] = []

    init(id: String, title: String, storyDescription: String, level: Int, coverImageUrl: String? = nil, isUnlocked: Bool = true) {
        self.id = id
        self.title = title
        self.storyDescription = storyDescription
        self.level = level
        self.coverImageUrl = coverImageUrl
        self.isUnlocked = isUnlocked
        self.createdAt = Date()
        self.updatedAt = Date()
    }
} 

//
//  Persistence.swift
//  HanziSteps
//
//  Created by Sheng-Lun Chen on 7/31/25.
//

import SwiftData

let container: ModelContainer = {
    do {
        return try ModelContainer(for: Sentence.self)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()

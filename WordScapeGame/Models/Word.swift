//
//  Word.swift
//  WordScapeGame
//
//  Created by 여나경 on 2/11/25.
//

import Foundation

struct Word: Equatable {
    let text: String
    let laneType: LaneType
    let priorityInLane: Int
    /// offset from `superView.snp.top`
    let topOffset: CGFloat
    
    static func == (lhs: Word, rhs: Word) -> Bool {
        lhs.text == rhs.text
    }
}

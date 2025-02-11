//
//  WordViewWithAnimator.swift
//  WordScapeGame
//
//  Created by 여나경 on 2/9/25.
//

import UIKit

struct WordViewWithAnimator {
    let wordView: WordView
    var animator: UIViewPropertyAnimator?
}

struct Word: Equatable {
    let text: String
    let laneType: LaneType
    let priorityInLane: Int
    let topOffset: CGFloat
    
    static func == (lhs: Word, rhs: Word) -> Bool {
        lhs.text == rhs.text
    }
}


enum LaneType {
    case laneA
    case laneB
    case laneC
}

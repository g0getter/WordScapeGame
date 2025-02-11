//
//  ViewReactor.swift
//  WordScapeGame
//
//  Created by 여나경 on 2/8/25.
//

import ReactorKit

class ViewReactor: Reactor {
    init(words: [String]) {
        self.words = words
    }
    
    let initialState = State(gameState: .initial)
    
    private let words: [String]
    private var capturedWords: [String] = []
    private var missedWords: [String] = []
    
    enum Action {
        case startButtonTapped
        case resetButtonTapped
        case missed(String)
        case captured(String)
        case ended
    }
    
    enum Mutation {
        case start
//        case reset
        case initial
        case startOnlyInBoxes([String])
        case missed(String)
        case captured(String)
        case ended
    }
    
    struct State {
        var newMissedWord: String?
        var newCapturedWord: String?
        var gameState: GameState
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .startButtonTapped:
            if currentState.gameState == .initial {
                return Observable.just(Mutation.start)
            }
            return Observable.empty()
        case .resetButtonTapped:
            let wordsToRestart = capturedWords + missedWords
            capturedWords = []
            missedWords = []
            
            switch currentState.gameState {
            case .initial:
                return Observable.empty()
            case .end:
                return Observable.just(Mutation.initial)
            default:
                return Observable.just(Mutation.startOnlyInBoxes(wordsToRestart))
            }
//            if currentState.gameState == .end {
//                return Observable.just(Mutation.initial)
//            } else if currentState.gameState == .initial {
//                
//            }
//            return Observable.just(Mutation.reset)
//            return Observable.just(Mutation.startOnlyInBoxes(wordsToRestart))
        case let .missed(word):
            missedWords.append(word)
            print("✅missed, \(capturedWords.count)+\(missedWords.count) AND \(words.count)")
            if capturedWords.count + missedWords.count == words.count {
                return Observable.concat([
                    Observable.just(Mutation.missed(word)),
                    Observable.just(Mutation.ended)
                ])
            }
            return Observable.just(Mutation.missed(word))
        case let .captured(word):
            capturedWords.append(word)
            if capturedWords.count + missedWords.count == words.count {
                return Observable.concat([
                    Observable.just(Mutation.captured(word)),
                    Observable.just(Mutation.ended)
                ])
            }
            return Observable.just(Mutation.captured(word))
        case .ended:
            return Observable.just(Mutation.ended)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        newState.newCapturedWord = nil
        newState.newMissedWord = nil
        switch mutation {
        case .start:
            newState.gameState = .start
//        case .reset:
//            if state.gameState == .end {
//                newState.gameState = .initial
//            } else {
//                newState.gameState = .startOnlyInBoxes(capturedWords+missedWords)
//            }
        case .initial:
            newState.gameState = .initial
        case let .startOnlyInBoxes(words):
            newState.gameState = .startOnlyInBoxes(words)
        case let .missed(wordItem):
            newState.newMissedWord = wordItem
            newState.gameState = .running //
        case let .captured(wordItem):
            newState.newCapturedWord = wordItem
            newState.gameState = .running //
        case .ended:
            newState.gameState = .end
        }
        
        return newState
    }
    
//    func mutate(action: Action) -> Observable<Mutation> {
//        switch action {
//        case .startButtonTapped:
//            return Observable.just(Mutation.startButtonTapped)
//        case .resetButtonTapped:
//            return Observable.just(Mutation.resetButtonTapped)
//        case let .missed(word):
//            return Observable.just(Mutation.missed(word))
//        case let .captured(word):
//            return Observable.just(Mutation.captured(word))
//        }
//    }
//    
//    func reduce(state: State, mutation: Mutation) -> State {
//        var newState = state
//        newState.newCapturedWord = nil
//        newState.newMissedWord = nil
//        switch mutation {
//        case .startButtonTapped:
//            newState.gameState = .start
//        case .resetButtonTapped:
//            if state.gameState == .end {
//                newState.gameState = .initial
//            } else {
//                newState.gameState = .start
//            }
//            newState.gameState = .reset
//        case let .missed(word):
//            newState.newMissedWord = word
//        case let .captured(word):
//            newState.newCapturedWord = word
//        }
//        return newState
//    }
}

enum GameState: Equatable {
    case initial
    case start
    /// starts words only in boxes
    case startOnlyInBoxes([String])
//    case reset
    /// game is running, nothing to do
    case running // TODO: 개선-mutate에서 마지막 단계로 대부분 추가하고,reset buttonTapped에서 default 대신 사용 가능할듯
    case end
    
    static func == (lhs: GameState, rhs: GameState) -> Bool {
        switch (lhs, rhs) {
            case (.initial, .initial), (.start, .start), (.end, .end):
            return true
        case (.startOnlyInBoxes, .startOnlyInBoxes):
            return true
        default:
            return false
        }
    }
}



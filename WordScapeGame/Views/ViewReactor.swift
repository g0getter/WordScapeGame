//
//  ViewReactor.swift
//  WordScapeGame
//
//  Created by 여나경 on 2/8/25.
//

import ReactorKit

class ViewReactor: Reactor {
    init(words: [Word]) {
        self.words = words
        
        currentWords = Dictionary(grouping: words, by: { $0.laneType })
            .mapValues { $0.sorted { $0.priorityInLane < $1.priorityInLane } }
    }
    
    let initialState = State(gameState: .initial)
    
    // FIXME: Optimize words variables
    private let words: [Word]
    
    private var currentWords: [LaneType: [Word]] = [:]
    private var capturedWords: [Word] = []
    private var missedWords: [Word] = []
    
    enum Action {
        case startButtonTapped
        case resetButtonTapped
        /// `Word` is missed, animation is stopped
        case missed(Word)
        case captured(String)
    }
    
    enum Mutation {
        case initial
        case startAll([Word])
        case start(Word)
        case emptyBoxes([Word])
        case missed(Word)
        case captured(Word)
        case ended
    }
    
    struct State {
        var newMissedWord: Word?
        var newCapturedWord: Word?
        var gameState: GameState
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .startButtonTapped:
            if currentState.gameState == .initial {
                let wordsToStart = currentWords.values.compactMap { $0.first }
                return Observable.just(Mutation.startAll(wordsToStart))
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
                // fill out current words, sort them properly and set to initial state
                currentWords = Dictionary(grouping: wordsToRestart, by: { $0.laneType })
                    .mapValues { $0.sorted { $0.priorityInLane < $1.priorityInLane } }
                return Observable.just(Mutation.initial)
            default: // is still running
                // empty 2 boxes and fill currentWords
                wordsToRestart.forEach {
                    currentWords[$0.laneType]?.append($0)
                }
                
                return Observable.just(Mutation.emptyBoxes(wordsToRestart))
            }
            
        case let .missed(word):
            missedWords.append(word)
            currentWords[word.laneType]?.removeAll(where: { $0 == word }) // remove
            // 3 cases
            
            // i) if there are remaining words to animate, start next one
            if let nextWord = currentWords[word.laneType]?.first {
                return Observable.concat([
                    Observable.just(Mutation.missed(word)),
                    Observable.just(Mutation.start(nextWord))
                ])
            }
            
            // ii) if it is the last word, end the game
            print("✅missed \(word.text), \(capturedWords.count)+\(missedWords.count) AND \(words.count)")
            if capturedWords.count + missedWords.count == words.count {
                return Observable.concat([
                    Observable.just(Mutation.missed(word)),
                    Observable.just(Mutation.ended)
                ])
            }
            
            // iii) do nothing(wait for the other lanes to terminate)
            return Observable.concat([
                Observable.just(Mutation.missed(word)),
            ])
            
        case let .captured(wordText):
            guard let word = words.first(where: { $0.text == wordText }) else {
                return Observable.empty()
            }
            capturedWords.append(word)
            currentWords[word.laneType]?.removeAll(where: { $0 == word }) // remove
            
            // i) start next one
            if let nextWord = currentWords[word.laneType]?.first {
                return Observable.concat([
                    Observable.just(Mutation.captured(word)),
                    Observable.just(Mutation.start(nextWord))
                ])
            }
            
            // ii) end the game
            if capturedWords.count + missedWords.count == words.count {
                return Observable.concat([
                    Observable.just(Mutation.captured(word)),
                    Observable.just(Mutation.ended)
                ])
            }
            
            // iii) do nothing(wait for the other lanes to terminate)
            return Observable.just(Mutation.captured(word))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        newState.newCapturedWord = nil
        newState.newMissedWord = nil
        switch mutation {
        case .initial:
            newState.gameState = .initial
        case let .startAll(words):
            newState.gameState = .startAll(words)
        case let .start(word):
            newState.gameState = .start(word)
        case let .emptyBoxes(words):
            newState.gameState = .emptyBoxes(words)
        case let .missed(word):
            newState.newMissedWord = word
            newState.gameState = .running //
        case let .captured(word):
            newState.newCapturedWord = word
            newState.gameState = .running //
        case .ended:
            newState.gameState = .end
        }
        
        return newState
    }
}

enum GameState: Equatable {
    case initial
    case startAll([Word])
    case start(Word)
    case emptyBoxes([Word])
    /// game is running, nothing to do
    case running
    case end
    
    static func == (lhs: GameState, rhs: GameState) -> Bool {
        switch (lhs, rhs) {
        case (.initial, .initial), (.start, .start), (.end, .end):
            return true
        case (.startAll, .startAll), (.running, .running):
            return true
        case (.emptyBoxes, .emptyBoxes):
            return true
        default:
            return false
        }
    }
}



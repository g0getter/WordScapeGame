//
//  ViewReactor.swift
//  WordScapeGame
//
//  Created by 여나경 on 2/8/25.
//

import ReactorKit

class ViewReactor: Reactor {
    let initialState = State(gameState: .initial)
    private var missedWords: [String] = [] // may not be used
    
    enum Action {
        case startButtonTapped
        case resetButtonTapped
        case missed(String)
    }
    
    enum Mutation {
        case startButtonTapped
        case resetButtonTapped
        case missed(String)
    }
    
    struct State {
        var newMissedWord: String?
        var gameState: GameState
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .startButtonTapped:
            return Observable.just(Mutation.startButtonTapped)
        case .resetButtonTapped:
            return Observable.just(Mutation.resetButtonTapped)
        case let .missed(word):
            return Observable.just(Mutation.missed(word))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .startButtonTapped:
            newState.gameState = .start
            newState.newMissedWord = nil
        case .resetButtonTapped:
            newState.gameState = .reset
            newState.newMissedWord = nil
        case let .missed(word):
            newState.newMissedWord = word
        default:
            break
        }
        return newState
    }
}

enum GameState: Equatable {
    case initial
    case start
    case reset
    case end // may not be used
//    case captured(String)
//    case missed(String)
}

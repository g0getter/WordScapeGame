//
//  ViewReactor.swift
//  WordScapeGame
//
//  Created by 여나경 on 2/8/25.
//

import ReactorKit

class ViewReactor: Reactor {
    let initialState = State(gameState: .initial)
    
    enum Action {
        case startButtonTapped
        case resetButtonTapped
        case missed(String)
        case captured(String)
    }
    
    enum Mutation {
        case startButtonTapped
        case resetButtonTapped
        case missed(String)
        case captured(String)
    }
    
    struct State {
        var newMissedWord: String?
        var newCapturedWord: String?
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
        case let .captured(word):
            return Observable.just(Mutation.captured(word))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        newState.newCapturedWord = nil
        newState.newMissedWord = nil
        switch mutation {
        case .startButtonTapped:
            newState.gameState = .start
        case .resetButtonTapped:
            newState.gameState = .reset
        case let .missed(word):
            newState.newMissedWord = word
        case let .captured(word):
            newState.newCapturedWord = word
        }
        return newState
    }
}

enum GameState: Equatable {
    case initial
    case start
    case reset
}

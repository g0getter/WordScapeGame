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
    }
    
    enum Mutation {
        case startButtonTapped
        case resetButtonTapped
    }
    
    struct State {
        var gameState: GameState
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .startButtonTapped:
            return Observable.just(Mutation.startButtonTapped)
        case .resetButtonTapped:
            return Observable.just(Mutation.resetButtonTapped)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .startButtonTapped:
            newState.gameState = .start
        case .resetButtonTapped:
            newState.gameState = .reset
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
    case captured(String)
    case missed(String)
}

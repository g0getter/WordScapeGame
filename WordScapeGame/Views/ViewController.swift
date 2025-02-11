//
//  ViewController.swift
//  WordScapeGame
//
//  Created by 여나경 on 2/8/25.
//

import UIKit
import SnapKit
import Then
import ReactorKit
import RxSwift // to use ReactorKit
import RxCocoa // to bind a button tap to reactor action (emit reactor action using map

class ViewController: UIViewController, ReactorKit.View {

    var disposeBag = DisposeBag()
    var reactor: ViewReactor?
    var wordViewsWithAnimators: [String: WordViewWithAnimator] = [:] // word(String): WordViewWithAnimator
    var wordsInOrder: [String] = [] // to ensure the order of dictionary, because of the order consistency between `setupConstraints` and `setupAnimation`
    
    private let wordLanes = UIView().then {
        $0.backgroundColor = .lightGray
    }
    private let capturedWordsLabel = UILabel().then {
        $0.text = "Captured Words"
    }
    private let missedWordsLabel = UILabel().then {
        $0.text = "Missed Words"
    }
    
    private let capturedWordsBox = UIView().then {
        $0.backgroundColor = .blue.withAlphaComponent(0.5)
    }
    private let capturedWordsContent = UIStackView().then {
        $0.axis = .vertical
    }
    
    private let missedWordsBox = UIView().then {
        $0.backgroundColor = .red.withAlphaComponent(0.5)
    }
    private let missedWordsContent = UIStackView().then {
        $0.axis = .vertical
    }
    
    private let startButton = UIButton().then {
        $0.setTitle("Start", for: .normal)
        $0.backgroundColor = .green
    }
    private let resetButton = UIButton().then {
        $0.setTitle("Reset", for: .normal)
        $0.backgroundColor = .green
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let words = ["apple", "banana", "cherry"]
        
        setupWordViewsWithAnimators(words) // should be called first
        
        // UIs
        addSubviews()
        setupConstraints()
        
        // TapGestures
        wordViewsWithAnimators.values.map { $0.wordView }.forEach {
            setupTapGesture(to: $0)
        }
        
        reactor = ViewReactor(words: words)
        guard let reactor = reactor else { return }
        bind(reactor: reactor)
    }
}

extension ViewController {
    private func setupWordViewsWithAnimators(_ words: [String]) {
        wordsInOrder = words
        words.forEach { word in
            let wordViewWithAnimator = WordViewWithAnimator(wordView: WordView(text: word))
            wordViewsWithAnimators[word] = wordViewWithAnimator
        }
    }
    
    private func addSubviews() {
        [
            wordLanes,
            capturedWordsLabel,
            missedWordsLabel,
            capturedWordsBox,
            missedWordsBox,
            startButton,
            resetButton
        ]
            .forEach { view.addSubview($0) }
        
        wordViewsWithAnimators.values.map { $0.wordView }
            .forEach { wordLanes.addSubview($0) }
        
        capturedWordsBox.addSubview(capturedWordsContent)
        missedWordsBox.addSubview(missedWordsContent)
    }
    
    private func setupConstraints() {
        wordLanes.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            $0.leading.trailing.equalToSuperview().inset(10)
        }
        
        capturedWordsLabel.snp.makeConstraints {
            $0.top.equalTo(wordLanes.snp.bottom).offset(20)
            $0.top.equalTo(view.snp.centerY)
            $0.leading.equalTo(wordLanes.snp.leading)
            $0.trailing.equalTo(view.snp.centerX).offset(-5) //
        }
        
        missedWordsLabel.snp.makeConstraints {
            $0.top.equalTo(capturedWordsLabel)
            $0.leading.equalTo(view.snp.centerX).offset(5) //
            $0.trailing.equalToSuperview().inset(10)
        }
        
        capturedWordsBox.snp.makeConstraints {
            $0.top.equalTo(capturedWordsLabel.snp.bottom).offset(10)
            $0.leading.trailing.equalTo(capturedWordsLabel)
        }
        
        missedWordsBox.snp.makeConstraints {
            $0.top.bottom.equalTo(capturedWordsBox)
            $0.leading.trailing.equalTo(missedWordsLabel)
        }
        
        startButton.snp.makeConstraints {
            $0.top.equalTo(capturedWordsBox.snp.bottom).offset(10)
            $0.leading.equalToSuperview().offset(10)
            $0.trailing.equalTo(view.snp.centerX).offset(-5)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(10)
        }
        
        resetButton.snp.makeConstraints {
            $0.top.equalTo(startButton.snp.top)
            $0.leading.equalTo(view.snp.centerX).offset(5)
            $0.trailing.equalToSuperview().inset(10)
            $0.bottom.equalTo(startButton.snp.bottom)
        }
        
        // set up subviews of `wordLanes`
        // wordViews constraints - inside `remakeWordViews(of:)`
        
        // set up wordsContent UIStackView
        capturedWordsContent.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.lessThanOrEqualToSuperview()
        }
        missedWordsContent.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.lessThanOrEqualToSuperview()
        }
    }
    
    /// (Re)makes constraints of `WordView`s
    private func remakeWordViews(of words: [String]) {
        
        let wordViews = words.map { wordViewsWithAnimators[$0] }
            .compactMap { $0?.wordView }
        
        wordViews.forEach { wordView in
            let wordViewsInOrder = wordsInOrder.compactMap { self.wordViewsWithAnimators[$0]?.wordView }
            let index = wordViewsInOrder.firstIndex(of: wordView) ?? -1
            var top = wordView.superview?.snp.top
            if index > 0 {
                top = wordViewsInOrder[index-1].snp.bottom
            }
            guard let top = top else { return }
            
            wordView.snp.remakeConstraints {
                $0.top.equalTo(top)
                $0.leading.equalToSuperview()
            }
//            wordView.superview?.layoutIfNeeded()

            wordView.isHidden = false
        }
    }
}

// MARK: - Animations
extension ViewController {
    private func setupAnimationForAll() {
        for dict in wordViewsWithAnimators {
            let animator = setupAnimation(of: dict.key)
            wordViewsWithAnimators[dict.key]?.animator = animator
        }
    }
    
    private func setupAnimation(of word: String) -> UIViewPropertyAnimator? {
        guard let wordView = wordViewsWithAnimators[word]?.wordView else { return nil }
        
        let duration = Double.random(in: 0.5...2.5)
        
        let animator = UIViewPropertyAnimator(duration: duration, curve: .linear, animations: {  [weak self] in
            guard let self = self else { return }
            
            let wordViewsInOrder = wordsInOrder.compactMap { self.wordViewsWithAnimators[$0]?.wordView }
            let index = wordViewsInOrder.firstIndex(of: wordView) ?? -1
            var top = wordView.superview?.snp.top
            if index > 0 {
                top = wordViewsInOrder[index-1].snp.bottom
            }
            guard let top = top else { return }
            
            wordView.snp.remakeConstraints {
                $0.top.equalTo(top)
                $0.trailing.equalToSuperview()
            }
            wordView.superview?.layoutIfNeeded() // apply the updated layout immediately
            
        })

        // == animator.stopAnimation(true) -> startAnimation() 해도 동작X
        animator.addCompletion { [weak self] (position: UIViewAnimatingPosition) in
            guard let self = self else { return }
            switch position {
            case .end:
                guard let word =
                        wordViewsWithAnimators
                    .first(where:{
                        $0.value.wordView == wordView
                    })?.key else { return }
                self.reactor?.action.onNext(.missed(word))
            default:
                break
            }
        }
        
        return animator
    }
    
    private func startAnimations(of words: [String]) {
        words.compactMap { wordViewsWithAnimators[$0] }
            .compactMap { $0.animator }
            .forEach { animator in
                print("Animator duration: \(animator?.duration ?? 0)")
                animator?.startAnimation()
            }
    }
    
    private func stopAnimation(of animator: UIViewPropertyAnimator?) {
        guard let animator = animator else { return }
        animator.stopAnimation(true) // stop animation and change state to [inactive]

    }
}

// MARK: - TapGesture, isUserInteractionEnabled
extension ViewController {
    private func setupTapGesture(to wordView: UIView) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(captureWord(_:)))
        wordView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func captureWord(_ gesture: UITapGestureRecognizer) {
        guard let tappedWordView = gesture.view as? WordView else { return }

        // 1. Stop animation
        guard let dict = wordViewsWithAnimators.first(where: { $0.value.wordView == tappedWordView }) else { return }
        stopAnimation(of: dict.value.animator)
        
        // 2. Manage views - hide or remove wordView from its superview
        tappedWordView.isHidden = true
        
        // 3. Emit an action `captured`
        reactor?.action.onNext(.captured(dict.key))
    }
    
    private func enableInteraction(for word: String, isEnabled: Bool) {
        wordViewsWithAnimators[word]?.wordView.isUserInteractionEnabled = isEnabled
    }
    
    private func enableInteractionForAllWords(isEnabled: Bool) {
        wordViewsWithAnimators.map { $0.value.wordView }
            .forEach { $0.isUserInteractionEnabled = isEnabled }
    }
    
}

// MARK: - Reactor
extension ViewController {
    func bind(reactor: ViewReactor) {
        bindAction(reactor)
        bindState(reactor)
    }
    
    private func bindAction(_ reactor: ViewReactor) {

        startButton.rx.tap
            .map { ViewReactor.Action.startButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        resetButton.rx.tap
            .map { ViewReactor.Action.resetButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
    }
    
    private func bindState(_ reactor: ViewReactor) {
        reactor.state
            .map { $0.gameState }
            .asObservable()
            .withUnretained(self)
            .subscribe(onNext: { (owner: ViewController, state: GameState) in
                print(state)
                switch state {
                case .initial:
                    owner.remakeWordViews(of: owner.wordsInOrder)
                    owner.enableInteractionForAllWords(isEnabled: false)
                    owner.setupAnimationForAll()
                    owner.resetWordsBox(captured: true, missed: true)
                    
                case .start:
                    owner.startAnimations(of: owner.wordsInOrder)
                    owner.enableInteractionForAllWords(isEnabled: true)
                    
                case let .startOnlyInBoxes(words):
                    // 1. Empty captured words box
                    owner.resetWordsBox(captured: true, missed: true)
                    
                    // 2. Restart wordViews immediately, while keeping others animated
                    owner.remakeWordViews(of: words)
                    owner.enableInteractionForAllWords(isEnabled: true)
                    
                    // Should setup animations again
                    words.forEach { word in
                            let animator = owner.setupAnimation(of: word)
                            owner.wordViewsWithAnimators[word]?.animator = animator
                        }
                    
                    DispatchQueue.main.async { // to ensure animations(UI) start on the main thread
                        owner.startAnimations(of: words)
                    }
                    
                default: break
                }
            }).disposed(by: disposeBag)
        
        reactor.state
            .compactMap { $0.newMissedWord }
            .asObservable()
            .withUnretained(self)
            .subscribe(onNext: { owner, word in
                owner.addMissedWord(word)
                owner.enableInteraction(for: word, isEnabled: false)
            }).disposed(by: disposeBag)
        
        reactor.state
            .compactMap { $0.newCapturedWord }
            .asObservable()
            .withUnretained(self)
            .subscribe(onNext: { owner, word in
                owner.addCapturedWord(word)
            }).disposed(by: disposeBag)
    }
}


// MARK: - Manage boxes
extension ViewController {
    private func resetWordsBox(captured: Bool, missed: Bool) {
        if captured == true,
           !capturedWordsContent.arrangedSubviews.isEmpty {
            capturedWordsContent.arrangedSubviews.forEach {
                capturedWordsContent.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
        }
        if missed == true,
           !missedWordsContent.arrangedSubviews.isEmpty {
            missedWordsContent.arrangedSubviews.forEach {
                missedWordsContent.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
        }
    }
    
    private func addCapturedWord(_ word: String) {
        let label = UILabel().then {
            $0.text = word
        }
        
        capturedWordsContent.addArrangedSubview(label)
    }
    private func addMissedWord(_ word: String) {
        let label = UILabel().then {
            $0.text = word
        }
        
        missedWordsContent.addArrangedSubview(label)
    }

}

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
    private var wordItems: [WordItem]?
    
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
        
        setupWordViews(["apple", "banana", "cherry"]) // should be called first
        addSubviews()
        setupConstraints()
        setupAnimation()
        wordItems?.map { $0.wordView }.forEach {
            setupTapGesture(to: $0)
        }
        
        reactor = ViewReactor()
        guard let reactor = reactor else { return }
        bind(reactor: reactor)
    }
}

extension ViewController {
    private func setupWordViews(_ words: [String]) {
        wordItems = words.map { word in
            return WordItem(
                text: word,
                wordView: WordView(text: word),
                animator: nil
            )
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
        
        wordItems?.map { $0.wordView }
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
        var previousWordView: UIView?
        wordItems?.map { $0.wordView } // wordViews
            .forEach { wordView in
                let top = previousWordView?.snp.bottom ?? wordLanes.snp.top
                wordView.snp.makeConstraints {
                    $0.top.equalTo(top)
                    $0.leading.equalToSuperview()
                }
                previousWordView = wordView
            }
        
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
}

// MARK: - Animations
extension ViewController {
    private func setupAnimation() {
        for (i, wordItem) in (wordItems ?? []).enumerated() {
            let animator = setupAnimation(of: wordItem.wordView)
            wordItems?[i].animator = animator
        }
    }
    
    private func setupAnimation(of wordView: WordView) -> UIViewPropertyAnimator {
        let duration = Double.random(in: 0.5...2.5)
        print("duration:\(duration)")
        let animator = UIViewPropertyAnimator(duration: duration, curve: .linear, animations: {  [weak self] in
            guard let self = self else { return }
            print("EXECUTE ANIMATION: \(wordView.text)")
            let index = wordItems?.firstIndex(where: { $0.wordView == wordView}) ?? -1
            var top = wordView.superview?.snp.top
            if index > 0 {
                top = wordItems?[index-1].wordView.snp.bottom
            }
            guard let top = top else { return }
            
            wordView.snp.remakeConstraints {
                $0.top.equalTo(top)
                $0.trailing.equalToSuperview()
            }
            wordView.superview?.layoutIfNeeded() // 변경된 레이아웃 즉시 적용
            
        })
        
        animator.addCompletion { [weak self] position in
            guard let self = self else { return }
            switch position {
            case .end:
                guard let text = wordItems?.filter({ $0.wordView == wordView }).first?.text else { return }
                self.reactor?.action.onNext(.missed(text))
            default:
                break
            }
        }
        
        return animator
    }
    
    private func startAnimations() {
        wordItems?.map { $0.animator }.forEach { $0?.startAnimation() }
    }
    
    private func stopAnimations() {
        wordItems?.map { $0.animator }.forEach { $0?.stopAnimation(true) }
    }
    
    /// Reset animation and manage UIs
    // TODO: 개선 가능(기능별 함수 분리)
    private func resetAnimations() {
            
        // 1. 애니메이션 정지
        stopAnimations()
        
        // 2. 원래 위치로 리셋
        var previousWordView: UIView?
        wordItems?.map { $0.wordView } // wordViews
            .forEach { wordView in
                let top = previousWordView?.snp.bottom ?? wordLanes.snp.top
                wordView.snp.remakeConstraints {
                    $0.top.equalTo(top)
                    $0.leading.equalToSuperview()
                }
                previousWordView = wordView
                
                wordView.isHidden = false
            }
        
        // 3. 새로운 애니메이션을 다시 설정
        setupAnimation()
    }
    
    /// Stops animation and emit an action `captured`
    private func stopAnimation(of animator: UIViewPropertyAnimator?) {
        guard let animator = animator else { return }
        animator.stopAnimation(true) // 애니메이션 즉시 중단
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
        let tappedwordItem = wordItems?.filter { $0.wordView == tappedWordView }.first
        let animator = tappedwordItem?.animator
        stopAnimation(of: animator)
        
        // 2. Manage views - hide or remove wordView from its superview
        tappedWordView.isHidden = true
        
        // Emit an action `captured`
        reactor?.action.onNext(.captured(tappedWordView.text))
    }
    
    private func enableInteraction(for wordItem: WordItem, isEnabled: Bool) {
        wordItem.wordView.isUserInteractionEnabled = isEnabled
    }
    
    private func enableInteractionForAllWords(isEnabled: Bool) {
        wordItems?.map { $0.wordView }.forEach { $0.isUserInteractionEnabled = isEnabled }
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
            .distinctUntilChanged()
            .withUnretained(self)
            .subscribe(onNext: { owner, state in
                switch state {
                case .initial:
                    owner.enableInteractionForAllWords(isEnabled: false)
                case .start:
                    owner.startAnimations()
                    owner.enableInteractionForAllWords(isEnabled: true)
                case .reset:
                    owner.resetAnimations()
                    owner.enableInteractionForAllWords(isEnabled: false)
                    owner.resetWordsBox()
                }
            }).disposed(by: disposeBag)
        
        reactor.state
            .compactMap { $0.newMissedWord }
            .asObservable()
            .withUnretained(self)
            .subscribe(onNext: { owner, word in
                owner.addMissedWord(word)
                guard let wordItem = owner.wordItems?
                    .filter({ $0.text == word }).first else { return }
                owner.enableInteraction(for: wordItem, isEnabled: false)
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
    private func resetWordsBox() {
        if !capturedWordsContent.arrangedSubviews.isEmpty {
            capturedWordsContent.arrangedSubviews.forEach {
                capturedWordsContent.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
        }
        if !missedWordsContent.arrangedSubviews.isEmpty {
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
        print("capturedWord: \(word)")
    }
    private func addMissedWord(_ word: String) {
        let label = UILabel().then {
            $0.text = word
        }
        
        missedWordsContent.addArrangedSubview(label)
        print("missedWord: \(word)")
    }

}

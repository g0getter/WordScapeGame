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

    private var animator: UIViewPropertyAnimator?
    
    private let wordView = WordView(text: "apple")
    
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
        
        addSubviews()
        setupConstraints()
        setupAnimation()
        setupTapGesture(to: wordView)
        
        reactor = ViewReactor()
        guard let reactor = reactor else { return }
        bind(reactor: reactor)
    }


}

extension ViewController {
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
        
        [
            wordView
        ]
            .forEach { wordLanes.addSubview($0) }
        
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
        
        // set up wordLanes
        wordView.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
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
        animator = UIViewPropertyAnimator(duration: 2.0/*0.5*/, curve: .linear, animations: { [weak self] in
            guard let self = self else { return }
            self.wordView.snp.remakeConstraints {
                $0.top.equalToSuperview()
                $0.trailing.equalToSuperview()
            }
            self.wordView.superview?.layoutIfNeeded() // 변경된 레이아웃 즉시 적용
            
        })
        
        animator?.addCompletion { [weak self] position in
            guard let self = self else { return }
            switch position {
            case .start:
                print("애니메이션이 시작 지점에서 종료되었습니다.")
            case .end:
                self.reactor?.action.onNext(.missed("apple")) // FIXME: "apple"
            case .current:
                print("애니메이션이 중간 지점에서 종료되었습니다.")
            @unknown default:
                print("알 수 없는 종료 상태")
            }
        }
    }
    
    private func startAnimation() {
        animator?.startAnimation()
    }
    
    private func resetAnimation() {
        // FIXME: 처음에 reset 눌렀을 때 에러나지 않도록
//        guard [.active, .stopped].contains(animator?.state) else { return }
        
        // 1. 애니메이션 정지 및 초기화
        animator?.stopAnimation(true)
        animator?.finishAnimation(at: .start) // 애니메이션의 처음 상태로 되돌림
        
        // 2. 원래 위치로 리셋
        wordView.snp.remakeConstraints {
            $0.top.leading.equalToSuperview()
        }
        
        // 3. 새로운 애니메이션을 다시 설정
        setupAnimation()
    }
    
    @objc private func cancelAnimation(_ gesture: UITapGestureRecognizer) {
        guard let tappedWordView = gesture.view as? WordView else { return }
        
        animator?.stopAnimation(true) // 애니메이션 즉시 중단
        animator?.finishAnimation(at: .current) // 현재 상태에서 멈춤 FIXME: 없어지도록
        
        // 원래 위치로 리셋
        wordView.snp.remakeConstraints {
            $0.top.leading.equalToSuperview()
        }
        
        reactor?.action.onNext(.captured(tappedWordView.text))
        wordView.superview?.layoutIfNeeded()
    }
}


extension ViewController {
    private func setupTapGesture(to wordView: UIView) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cancelAnimation(_:)))
        wordView.addGestureRecognizer(tapGesture)
    }
}

// Reactor
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
                case .start:
                    owner.startAnimation()
                case .reset:
                    owner.resetAnimation()
                    owner.resetMissedWords()
                default:
                    break
                }
            }).disposed(by: disposeBag)
        
        reactor.state
            .compactMap { $0.newMissedWord }
            .asObservable()
            .withUnretained(self)
            .subscribe(onNext: { owner, word in
                owner.addMissedWord(word)
            }).disposed(by: disposeBag)
        
        reactor.state
            .compactMap { $0.newCapturedWord }
            .asObservable()
            .withUnretained(self)
            .subscribe(onNext: { owner, word in
//                owner.addCapturedWord(word)
                print(word)
            }).disposed(by: disposeBag)
    }
}


// MARK: - Manage boxes
extension ViewController {
    private func resetMissedWords() {
        guard !missedWordsContent.arrangedSubviews.isEmpty else { return }
        missedWordsContent.arrangedSubviews.forEach {
            missedWordsContent.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }
    
    private func addMissedWord(_ word: String) {
        let label = UILabel().then {
            $0.text = word
        }
        
        missedWordsContent.addArrangedSubview(label)
        print(word)
    }
}

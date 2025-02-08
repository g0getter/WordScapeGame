//
//  ViewController.swift
//  WordScapeGame
//
//  Created by 여나경 on 2/8/25.
//

import UIKit
import SnapKit
import Then

class ViewController: UIViewController {

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
    }
}


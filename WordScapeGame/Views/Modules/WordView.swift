//
//  WordView.swift
//  WordScapeGame
//
//  Created by 여나경 on 2/8/25.
//

import UIKit
import SnapKit

class WordView: UIView {
    let text: String
    
    private let label = UILabel()
    
    init(text: String) {
        self.text = text
        super.init(frame: .zero)
        
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


extension WordView {
    private func setupUI() {
        backgroundColor = .yellow
        label.text = text
        
        addSubview(label)
    }
    
    private func setupConstraints() {
        label.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(3)
        }
    }
}

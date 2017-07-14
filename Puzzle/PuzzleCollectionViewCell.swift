//
//  PuzzleCollectionViewCell.swift
//  Puzzle
//
//  Created by wc on 14/07/2017.
//  Copyright © 2017 DianQK. All rights reserved.
//

import UIKit
import RxSwift

class PuzzleCollectionViewCell: UICollectionViewCell, UITextFieldDelegate {
    
    @IBOutlet weak var originLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    
    private(set) var reusedDisposeBag = DisposeBag()
    
    let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.textField.delegate = self
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        reusedDisposeBag = DisposeBag()
        textField.text = ""
        originLabel.text = ""
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.lengthOfBytes(using: String.Encoding.utf8) == 0 {
            return true
        }
        if let text = textField.text, !text.isEmpty {
            return false
        }
        if string.lengthOfBytes(using: String.Encoding.utf8) != 1 {
            return false
        }
        if string.rangeOfCharacter(from: CharacterSet.lowercaseLetters) != nil {
            return true
        }
        return false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        _ = textField.resignFirstResponder()
        return false
    }

}

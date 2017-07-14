//
//  ViewController.swift
//  Puzzle
//
//  Created by wc on 14/07/2017.
//  Copyright © 2017 DianQK. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import RandomKit
import RxKeyboard

extension String {
    
    var array: [String] {
        return self.characters.map { String($0) }
    }
    
    var unique: [String] {
        return self.array.reduce([String]()) { acc, x in
            if acc.contains(x) {
                return acc
            } else {
                return acc + [x]
            }
        }
    }
    
    func removingCharacters(in characterSet: CharacterSet) -> String {
        return self.array.filter { $0.rangeOfCharacter(from: characterSet) == nil }.joined()
    }
    
}

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        struct Item {
            let key: String
            let value: Variable<String>?
        }
        
        struct Map {
            let key: String
            let value: String
            let input = Variable<String>("")
            
            var matched: Observable<Bool> {
                return input.asObservable().map { self.value == $0 }
            }
            
            var inputed: Observable<Bool> {
                return input.asObservable().map { $0.lengthOfBytes(using: String.Encoding.utf8) > 0 }
            }
        }
        
        typealias SectionModel = RxDataSources.SectionModel<(), Item>
        
        let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel>()
        
        dataSource.configureCell = { dataSource, collectionView, indexPath, element in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PuzzleCollectionViewCell", for: indexPath) as! PuzzleCollectionViewCell
            cell.originLabel.text = element.key
            if let inputValue = element.value {
                cell.textField.isEnabled = true
                (cell.textField.rx.textInput <-> inputValue).disposed(by: cell.reusedDisposeBag)
            } else {
                cell.textField.text = element.key
                cell.textField.isEnabled = false
            }
            return cell
        }
        
        let origin = "two way binding operator between control property and variable, that's all it takes"
        let values = origin
            .removingCharacters(in: CharacterSet.letters.inverted)
            .unique // value 应该是原值，key 是展示的
        let keys = "qwertyuiopasdfghjklzxcvbnm".array.shuffled(using: &Xoroshiro.threadLocal.pointee)
        let maps: [Map] = zip(keys, values).map { Map(key: $0, value: $1) }

        let items = origin.characters.map { String($0) }
            .map { (text) -> Item in
                if let map = maps.first(where: { $0.value == text }) {
                    return Item(key: map.key, value: map.input)
                } else {
                    return Item(key: text, value: nil)
                }
                
        }
        
        Observable.just([SectionModel(model: (), items: items)])
            .bind(to: collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        resetButton.rx.tap.asObservable()
            .subscribe(onNext: { [weak self] in
                maps.forEach({ (map) in
                    map.input.value = ""
                })
                self?.view.endEditing(true)
            })
            .disposed(by: disposeBag)
        
        let allInputed = Observable.combineLatest(maps.map { $0.inputed }).asObservable().shareReplay(1)
            
        allInputed
            .map { $0.first(where: { !$0 }) == nil }
            .bind(to: submitButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        allInputed
            .map { $0.first(where: { $0 }) != nil }
            .bind(to: resetButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        submitButton.rx.tap.asObservable().withLatestFrom(Observable.combineLatest(maps.map { $0.matched }))
            .map { result -> (matched: Int, unmatch: Int) in
                let matched = result.filter { $0 }.count
                let unmatch = result.count - matched
                return (matched: matched, unmatch: unmatch)
            }
            .map { "成功匹配\($0.matched)个，失败匹配\($0.unmatch)个" }
            .subscribe(onNext: { [weak self] message in
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "好", style: UIAlertActionStyle.default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] keyboardVisibleHeight in
                self?.collectionView.contentInset.bottom = keyboardVisibleHeight
            })
            .disposed(by: disposeBag)
        
    }

}


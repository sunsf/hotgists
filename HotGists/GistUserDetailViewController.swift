//
//  GistUserDetailViewController.swift
//  HotGists
//
//  Created by William SUN on 29/11/2019.
//  Copyright © 2019 William SUN. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture
import Then

class GistUserDetailViewController: UIViewController {

    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userGistsTableView: UITableView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var starImageView: UIImageView!
    
    
    var user: BehaviorRelay<GistUserPlus> = BehaviorRelay(value: GistUserPlus(login: "", id: 0, url: "", avatar_url: "", itemCount: 0))
    var gists: BehaviorRelay<[GistItem]> = BehaviorRelay(value: [])
        
    let disposeBag = DisposeBag()

    let fav = Favourite(userDefault: UserDefaults.standard)

    override func viewDidLoad() {
        super.viewDidLoad()
    
        user.bind { value in
            self.userNameLabel.text = value.url
            self.title = value.login
            self.fetchData()
        }.disposed(by: disposeBag)
        
        gists.bind(to: userGistsTableView.rx.items(cellIdentifier: "cell", cellType: GistItemTableViewCell.self)) { row, model, cell in
            cell.countLabel.text = "\(model.files.count) files"
            let filenames = Array(model.files.keys).map{ $0 }
            cell.urlLabel.text = filenames.joined(separator: "\n")
            cell.mainLabel.text = "\(model.id)"
        }.disposed(by: disposeBag)
        
        starImageView.rx.tapGesture().when(.recognized).subscribe(onNext: { _ in
            var value = self.fav.users.value
            if value.contains(self.user.value.login) {
                value.removeAll { item -> Bool in
                    return item == self.user.value.login
                }
            }
            else {
                value.append(self.user.value.login)
            }
            self.fav.users.accept(value)
        }).disposed(by: disposeBag)
        
        fav.users.bind { value in
            if value.contains(self.user.value.login) {
                self.starImageView.image = UIImage(systemName: "star.fill")
            }
            else {
                self.starImageView.image = UIImage(systemName: "star")
            }
        }.disposed(by: disposeBag)
    }
    
    func fetchData() {
        async {
            let result = try await(fetchUserGist(self.user.value.login))
            return result
        }
        .then{ result in
            self.gists.accept(result)
        }
        
        async {
            let image = try await(fetchImage(self.user.value.avatar_url))
            return image
        }
        .then { result in
            DispatchQueue.main.async {
              self.imageView.image = result
            }
        }
    }
}

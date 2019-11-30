//
//  GistUserViewController.swift
//  HotGists
//
//  Created by William SUN on 27/11/2019.
//  Copyright © 2019 William SUN. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Then

class GistUserViewController: UIViewController {
    let disposeBag = DisposeBag()
    var fav: Favourite?
    let favUsers: BehaviorRelay<[GistUserPlus]> = BehaviorRelay(value: [])
    
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        favUsers.bind(to: tableView.rx.items(cellIdentifier: "cell")) { row, model, cell in
            cell.textLabel?.text = "\(model.login)"
        }.disposed(by: disposeBag)
        
        tableView.rx.modelSelected(GistUserPlus.self)
            .bind(to: itemDetailsSegue.pushObserver)
            .disposed(by: disposeBag)

        tableView.rx.itemSelected.subscribe(onNext: { [weak self] indexPath in
            let cell = self?.tableView.cellForRow(at: indexPath) as? GistUserTableViewCell
            cell?.setSelected(false, animated: true)
            }
        ).disposed(by: disposeBag)
    }
    
    lazy var itemDetailsSegue: Segue<GistUserPlus> = {
        return Segue<GistUserPlus>(fromViewController: self, toViewControllerFactory: { context -> UIViewController in
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "GistUserDetailViewController") as GistUserDetailViewController
            vc.user.accept(context)
            //let vc = GistUserDetailViewController()
            return vc
                })
    }()

    override func viewWillAppear(_ animated: Bool) {
        fav = Favourite(userDefault: UserDefaults.standard)
        guard let fav = fav else { return }
        fav.users.bind { value in
            fetchAllUserGistByNames(value).then { result in
                self.favUsers.accept(result)
            }
        }.disposed(by: disposeBag)
    }
}

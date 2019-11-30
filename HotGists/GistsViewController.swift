//
//  GistsViewController.swift
//  HotGists
//
//  Created by William SUN on 27/11/2019.
//  Copyright © 2019 William SUN. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Then

struct GistItem: Decodable {
    let id: String
    let url: String
    let files: [String: FileItem]
    let owner: GistUser
    let html_url: String
}

struct FileItem: Decodable {
    let filename: String
    let type: String
    let raw_url: String
    let size: NSInteger
}

struct GistUser: Decodable {
    let login: String
    let id: NSInteger
    let html_url: String
    let avatar_url: String
}

struct GistUserPlus: Decodable {
    let login: String
    let id: NSInteger
    let url: String
    let avatar_url: String
    let itemCount: NSInteger
}

class Favourite: NSObject {
    var userDefault: UserDefaults
    let users: BehaviorRelay<[String]> = BehaviorRelay(value: [])
    let disposeBag = DisposeBag()
    
    init(userDefault: UserDefaults) {
        self.userDefault = userDefault
        if let list = self.userDefault.array(forKey: "users") as? [String] {
            self.users.accept(list)
        }
        self.users.subscribe(onNext: { value in
            userDefault.set(value, forKey: "users")
        }).disposed(by: disposeBag)
    }
}

class GistsViewController: UIViewController {
    let disposeBag = DisposeBag()
    let gists: BehaviorRelay<[GistUserPlus]> = BehaviorRelay(value: [])
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        gists.bind(to: tableView.rx.items(cellIdentifier: "cell", cellType: GistUserTableViewCell.self)) { row, model, cell in
            cell.userLabel.text = "\(model.login)"

            if model.itemCount >= 5 {
                cell.gistCountLabel.text = "\(model.itemCount) gists shared"
            }
            else {
                cell.gistCountLabel.text = ""
            }
            
            cell.userDetailLabel.text = "\(model.url)"
            
        }.disposed(by: disposeBag)
        
        tableView.rx.modelSelected(GistUserPlus.self)
            .bind(to: itemDetailsSegue.pushObserver)
            .disposed(by: disposeBag)
        
        tableView.rx.itemSelected.subscribe(onNext: { [weak self] indexPath in
            let cell = self?.tableView.cellForRow(at: indexPath) as? GistUserTableViewCell
            cell?.setSelected(false, animated: true)
            }
        ).disposed(by: disposeBag)
        
        fetchData()
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
    
    func fetchData() {
        async {
            let result = try await(fetchPublicGists())
            let usersPlus = try await(fetchAllUserGist(result))
            return usersPlus
        }
        .then{ result in
            self.gists.accept(result)
        }
    }
}

func fetchPublicGists() -> Promise<[GistUser]> {
    return Promise { resolve, reject in
        if let url = URL(string: "https://api.github.com/gists/public?since") {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        let result: [GistUser] = try JSONDecoder().decode([GistItem].self, from: data)
                            .reduce([GistUser](), { result, element in
                                let username = element.owner.login as String
                                var arr = [GistUser](result)
                                if !result.contains{username == $0.login} {
                                    arr.append(element.owner)
                                }
                                return arr
                            })
                        resolve(result)
                    } catch let error {
                        print(error)
                    }
                }
            }.resume()
        }
    }
}

func fetchUserGist(_ userId: String) -> Promise<[GistItem]> {
    return Promise { resolve, reject in
        if let url = URL(string: "https://api.github.com/users/\(userId)/gists?since") {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        let userGists = try JSONDecoder().decode([GistItem].self, from: data)
                        resolve(userGists)
                    } catch let error {
                        print(error)
                    }
                }
            }.resume()
        }
    }
}

func fetchAllUserGist(_ users: [GistUser]) -> Promise<[GistUserPlus]> {
    return Promise { resolve, reject in
        let promises = users.map { user in
            fetchUserGist(user.login).then { gists in
                return GistUserPlus(login: user.login, id: user.id, url: user.html_url, avatar_url: user.avatar_url, itemCount: gists.count)
            }
        }
        Promises.whenAll(promises).then { items in
            resolve(items)
        }
    }
}

func fetchAllUserGistByNames(_ userList: [String]) -> Promise<[GistUserPlus]> {
    return Promise { resolve, reject in
        let promises = userList.map { user in
            return Promise { r2, _ in
                async { () -> [GistItem] in
                    let gists = try await(fetchUserGist(user))
                    return gists
                }.then { (items:[GistItem]) -> GistUserPlus in
                    let firstItem = Array(items).first
                    let owner = firstItem!.owner
                    return GistUserPlus(login: owner.login, id: owner.id, url: owner.html_url, avatar_url: owner.avatar_url, itemCount: items.count)
                }.then { result in
                    r2(result)
                }
            }
        }
        Promises.whenAll(promises).then { items in
            resolve(items)
        }
    }
}

func fetchImage(_ target: String) -> Promise<UIImage> {
    return Promise { resolve, reject in
        if let url = URL(string: target) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    resolve(image)
                }
                else { reject(error!) }
            }.resume()
        }
    }
}

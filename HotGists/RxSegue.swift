//
//  RxSegue.swift
//  HotGists
//
//  Created by William SUN on 29/11/2019.
//  Copyright © 2019 William SUN. All rights reserved.
//


import UIKit
import RxSwift

class Segue<T> {
   
   private(set) weak var fromViewController: UIViewController?
   let toViewControllerFactory: (_ context:T) -> UIViewController
   
   init(fromViewController:UIViewController, toViewControllerFactory: @escaping (_ context:T) -> UIViewController) {
         self.fromViewController = fromViewController
         self.toViewControllerFactory = toViewControllerFactory
   }
   
    private(set) lazy var pushObserver:AnyObserver<T> = AnyObserver { [weak self] event in
        switch event {
        case .next(let value):
            guard let strong = self else {return}
            let toViewController = strong.toViewControllerFactory(value)
                strong.fromViewController?.navigationController?.pushViewController(toViewController, animated:true)
        default:
            break
        }
    }
   
   private(set) lazy var presentObserver:AnyObserver<T> = AnyObserver {[weak self] event in
      switch event {
      case .next(let value):
         guard let strong = self else {return}
         let toViewController = strong.toViewControllerFactory(value)
         strong.fromViewController?.present(toViewController, animated: true, completion: nil)
      default:
         break
      }
   }
   
}

//
//  MainNavigationController.swift
//  tracking-selfie
//
//  Created by 조중윤 on 2022/03/16.
//

import UIKit

class MainNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let networkController = NetworkController(sessionManager: SessionManager())
        let dogPicService = DogPicService(networkController: networkController)
        let vm = ViewModel(dogPicService: dogPicService)
        
        if let rootViewController = self.viewControllers[0] as? MainViewController {
            rootViewController.inject(vm: vm)
        }
        
        self.navigationBar.backgroundColor = .white.withAlphaComponent(0.5)
    }
    
}

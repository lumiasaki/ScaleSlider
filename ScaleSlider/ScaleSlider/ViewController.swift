//
//  ViewController.swift
//  ScaleSlider
//
//  Created by zhutianren on 2021/2/20.
//

import UIKit

class ViewController: UIViewController {

    private lazy var slider: ScaleSlider = {
        let view = ScaleSlider(configuration: ScaleSlider.Configuration(minimumScale: 1, maximumScale: 5, scaleInterval: 1)!)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.scaleValueChanged = { print($0.selectedIndex.title) }
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.addSubview(slider)
        
        NSLayoutConstraint.activate([
            slider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            slider.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            slider.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            slider.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }


}


//
//  LaunchViewController.swift
//  mqtt
//
//  Created by jailbreak2020 on 2021/8/25.
//

import UIKit
import TextFieldEffects
import Toast_Swift

class UINavigationBarGradientView: UIView {

    enum Point {
        case topRight, topLeft
        case bottomRight, bottomLeft
        case custom(point: CGPoint)

        var point: CGPoint {
            switch self {
                case .topRight: return CGPoint(x: 1, y: 0)
                case .topLeft: return CGPoint(x: 0, y: 0)
                case .bottomRight: return CGPoint(x: 1, y: 1)
                case .bottomLeft: return CGPoint(x: 0, y: 1)
                case .custom(let point): return point
            }
        }
    }

    private weak var gradientLayer: CAGradientLayer!

    convenience init(colors: [UIColor], startPoint: Point = .topLeft,
                     endPoint: Point = .bottomLeft, locations: [NSNumber] = [0, 1]) {
        self.init(frame: .zero)
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = frame
        layer.addSublayer(gradientLayer)
        self.gradientLayer = gradientLayer
        set(colors: colors, startPoint: startPoint, endPoint: endPoint, locations: locations)
        backgroundColor = .clear
    }

    func set(colors: [UIColor], startPoint: Point = .topLeft,
             endPoint: Point = .bottomLeft, locations: [NSNumber] = [0, 1]) {
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint.point
        gradientLayer.endPoint = endPoint.point
        gradientLayer.locations = locations
    }

    func setupConstraints() {
        guard let parentView = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraint(equalTo: parentView.topAnchor).isActive = true
        leftAnchor.constraint(equalTo: parentView.leftAnchor).isActive = true
        parentView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        parentView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let gradientLayer = gradientLayer else { return }
        gradientLayer.frame = frame
        superview?.addSubview(self)
    }
}

extension UINavigationBar {
    func setGradientBackground(colors: [UIColor],
                               startPoint: UINavigationBarGradientView.Point = .topLeft,
                               endPoint: UINavigationBarGradientView.Point = .bottomLeft,
                               locations: [NSNumber] = [0, 1]) {
        guard let backgroundView = value(forKey: "backgroundView") as? UIView else { return }
        guard let gradientView = backgroundView.subviews.first(where: { $0 is UINavigationBarGradientView }) as? UINavigationBarGradientView else {
            let gradientView = UINavigationBarGradientView(colors: colors, startPoint: startPoint,
                                                           endPoint: endPoint, locations: locations)
            backgroundView.addSubview(gradientView)
            gradientView.setupConstraints()
            return
        }
        gradientView.set(colors: colors, startPoint: startPoint, endPoint: endPoint, locations: locations)
    }
}

class LaunchViewController: UIViewController {
    
    @IBOutlet weak var textField: HoshiTextField?
    @IBOutlet weak var errorLabel: UILabel?
    @IBOutlet weak var goButton: UIButton?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.setGradientBackground(colors: [UIColor(red: 0.85, green: 0.36, blue: 0.59, alpha: 1), UIColor(red: 0.93, green: 0.38, blue: 0.38, alpha: 1)], startPoint: .topLeft, endPoint: .bottomRight)
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.setNavigationBarHidden(true, animated: false)

        // fillCode
        let bgLayer = CAGradientLayer()
        bgLayer.colors = [UIColor(red: 0.76, green: 0.51, blue: 0.86, alpha: 1).cgColor, UIColor(red: 0.98, green: 0.49, blue: 0.38, alpha: 1).cgColor, UIColor(red: 1, green: 0.49, blue: 0.36, alpha: 1).cgColor]
        bgLayer.locations = [0, 0.94, 1]
        bgLayer.frame = view.bounds
        bgLayer.startPoint = CGPoint(x: -0.18, y: -0.17)
        bgLayer.endPoint = CGPoint(x: 1.31, y: 1.31)
        
        view.layer.insertSublayer(bgLayer, at: 0)
        
        textField?.borderActiveColor = UIColor.white
        textField?.borderInactiveColor = UIColor.white.withAlphaComponent(0.5)
        textField?.placeholder = "昵称"
        textField?.tintColor = .white

    
        goButton?.backgroundColor = .black.withAlphaComponent(0.1)
        goButton?.setTitleColor(.white, for: .normal)
        goButton?.setTitleColor(.white, for: .highlighted)
        goButton?.setTitle("进入聊天室", for: .normal)
        
        errorLabel?.text = ""
        
        if !Mqtt.shared.needRegister {
            Mqtt.shared.connectLast()
            toMainVc()
        }
    }
    
    @IBAction func go(sender: UIButton) {
        if let username = textField?.text, !username.isEmpty {
            self.view.makeToastActivity(.center)
            Mqtt.shared.registerAndLogin(username) { [unowned self] err in
                self.view.hideToastActivity()
                if err == nil {
                    self.toMainVc()
                } else {
                    self.textField?.text = nil
                    self.errorLabel?.text = err ?? "unknown error"
                }
            }
        } else {
            view.makeToast("请输入昵称")
        }
    }
    
    
    private func toMainVc() {
        
        guard let mainVC = storyboard?.instantiateViewController(identifier: "MainVC") else {
            fatalError()
        }
        
        navigationController?.setViewControllers([mainVC], animated: true)
    }
}

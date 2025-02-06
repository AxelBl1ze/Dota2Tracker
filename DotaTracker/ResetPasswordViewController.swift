//
//  ResetPasswordViewController.swift
//  DotaTracker
//
//  Created by Ilya Sidnev on 2/2/25.
//

import UIKit

class ResetPasswordViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - UI Elements
        private let titleLabel: UILabel = {
            let label = UILabel()
            label.text = "Сброс пароля"
            label.font = UIFont.boldSystemFont(ofSize: 28)
            label.textColor = .white
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
    
    private let emailTextField = CustomTextField(placeholder: "Введите ваш Email", keyboardType: .emailAddress)
    private let secretQuestionPicker = UIPickerView()
    private let secretAnswerTextField = CustomTextField(placeholder: "Ответ на секретный вопрос")
    private let newPasswordTextField = CustomTextField(placeholder: "Введите новый пароль", isSecure: true)
    private let resetPasswordButton = CustomButton(title: "Сбросить пароль")
    
    private let questions = [
            "Ваш первый питомец?",
            "Название вашей школы?",
            "Имя вашей мамы?",
            "Ваш любимый цвет?"
        ]
    
    private var selectedQuestion: String?
        
        override func viewDidLoad() {
            super.viewDidLoad()
            emailTextField.delegate = self
            secretAnswerTextField.delegate = self
            newPasswordTextField.delegate = self
            setupUI()
        }
        
    // MARK: - UI Setup
    private func setupUI() {
        selectedQuestion = questions.first
        
        // Градиентный фон
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        secretQuestionPicker.dataSource = self
        secretQuestionPicker.delegate = self
        
        let questionContainer = createContainerView(with: secretQuestionPicker)
        let answerContainer = createContainerView(with: secretAnswerTextField)
        let passwordContainer = createContainerView(with: newPasswordTextField)
        
        view.addSubview(titleLabel)
        view.addSubview(emailTextField)
        view.addSubview(questionContainer)
        view.addSubview(answerContainer)
        view.addSubview(passwordContainer)
        view.addSubview(resetPasswordButton)
        
        resetPasswordButton.addTarget(self, action: #selector(resetPasswordTapped), for: .touchUpInside)
        
        // MARK: - Constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            emailTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            emailTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emailTextField.widthAnchor.constraint(equalToConstant: 350),
            
            questionContainer.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 20),
            questionContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            questionContainer.widthAnchor.constraint(equalTo: emailTextField.widthAnchor),
            questionContainer.heightAnchor.constraint(equalToConstant: 100),
            
            answerContainer.topAnchor.constraint(equalTo: questionContainer.bottomAnchor, constant: 20),
            answerContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            answerContainer.widthAnchor.constraint(equalTo: emailTextField.widthAnchor),
            
            passwordContainer.topAnchor.constraint(equalTo: answerContainer.bottomAnchor, constant: 20),
            passwordContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            passwordContainer.widthAnchor.constraint(equalTo: emailTextField.widthAnchor),
            
            resetPasswordButton.topAnchor.constraint(equalTo: passwordContainer.bottomAnchor, constant: 30),
            resetPasswordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
        
    private func createContainerView(with subview: UIView) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.layer.cornerRadius = 12
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.15
        container.layer.shadowOffset = CGSize(width: 0, height: 5)
        container.layer.shadowRadius = 8
        container.backgroundColor = UIColor.white.withAlphaComponent(0.0) // Изменили прозрачность контейнера

        view.addSubview(container)
        container.addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            subview.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
            subview.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            subview.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10)
        ])

        return container
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
        
        @objc private func resetPasswordTapped() {
            guard let email = emailTextField.text, !email.isEmpty,
                  let answer = secretAnswerTextField.text, !answer.isEmpty,
                  let newPassword = newPasswordTextField.text, !newPassword.isEmpty,
                  let question = selectedQuestion else {
                showAlert(message: "Пожалуйста, заполните все поля")
                return
            }
            
            let requestData: [String: Any] = ["email": email, "answer": answer]
            sendSecretAnswerRequest(data: requestData) { [weak self] success in
                if success {
                    print("Ответ верный, можно менять пароль")
                    self?.updatePassword(email: email, newPassword: newPassword)
                } else {
                    self?.showAlert(message: "Неверный ответ на секретный вопрос")
                }
            }
        }
        
        private func sendSecretAnswerRequest(data: [String: Any], completion: @escaping (Bool) -> Void) {
            guard let url = URL(string: "http://192.168.0.176:5001/api/auth/verifySecretAnswer") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: data)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    DispatchQueue.main.async { completion(false) }
                    return
                }
                let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                DispatchQueue.main.async { completion(response?["msg"] as? String == "Ответ верный. Теперь можете сбросить пароль.") }
            }.resume()
        }
        
    private func updatePassword(email: String, newPassword: String) {
        guard let url = URL(string: "http://192.168.0.176:5001/api/auth/updatePassword") else { return }
        
        let requestData: [String: Any] = [
            "email": email,
            "newPassword": newPassword
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestData)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Ошибка сети: \(error?.localizedDescription ?? "Неизвестная ошибка")")
                DispatchQueue.main.async {
                    self.showAlert(message: "Не удалось сменить пароль. Попробуйте позже.")
                }
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("Ответ от сервера:", jsonResponse)
                    
                    let successMessage = jsonResponse["msg"] as? String ?? ""
                    DispatchQueue.main.async {
                        if successMessage.lowercased().contains("успешно") {
                            self.showAlert(message: "Пароль успешно изменен!")
                        } else {
                            self.showAlert(message: successMessage.isEmpty ? "Ошибка смены пароля" : successMessage)
                        }
                    }
                } else {
                    print("Ошибка парсинга JSON")
                    DispatchQueue.main.async {
                        self.showAlert(message: "Ошибка смены пароля")
                    }
                }
            } catch {
                print("Ошибка декодирования JSON: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showAlert(message: "Ошибка сервера")
                }
            }
        }.resume()
    }

        private func showAlert(message: String) {
            let alert = UIAlertController(title: "Уведомление", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    

    // MARK: - UIPickerView DataSource & Delegate
    extension ResetPasswordViewController: UIPickerViewDataSource, UIPickerViewDelegate {
        func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { return questions.count }
        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return questions[row]
        }
        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            selectedQuestion = questions[row]
        }
        func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white
            ]
            let title = questions[row]
            return NSAttributedString(string: title, attributes: attributes)
        }
    }

// MARK: - Custom UI Components
class CustomTextField: UITextField {
    init(placeholder: String, keyboardType: UIKeyboardType = .default, isSecure: Bool = false) {
        super.init(frame: .zero)
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.isSecureTextEntry = isSecure
        self.borderStyle = .none
        self.backgroundColor = UIColor.white.withAlphaComponent(0.2) // прозрачный фон
        self.layer.cornerRadius = 12
        self.textColor = .white
        self.font = UIFont.systemFont(ofSize: 16)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.heightAnchor.constraint(equalToConstant: 50).isActive = true

        // Отступы внутри текстового поля
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 50))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

class CustomButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(.white, for: .normal)
        backgroundColor = .systemBlue
        layer.cornerRadius = 12
        titleLabel?.font = .boldSystemFont(ofSize: 18)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 50).isActive = true
        widthAnchor.constraint(equalToConstant: 220).isActive = true
        
        // Анимация нажатия
        addTarget(self, action: #selector(scaleDown), for: .touchDown)
        addTarget(self, action: #selector(scaleUp), for: [.touchUpInside, .touchDragExit])
    }
    
    @objc private func scaleDown() {
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func scaleUp() {
        UIView.animate(withDuration: 0.1) {
            self.transform = .identity
        }
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

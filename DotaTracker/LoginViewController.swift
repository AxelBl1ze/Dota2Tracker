import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    // Флаг режима: false = вход, true = регистрация
    private var isRegistrationMode = false {
        didSet {
            updateMode()
        }
    }
    
    // MARK: - UI Elements
    
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.text = "DotaTracker"
        label.font = .systemFont(ofSize: 35, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email"
        textField.keyboardType = .emailAddress
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Пароль"
        textField.isSecureTextEntry = true
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Войти", for: .normal) // по умолчанию режим входа
        button.tintColor = .white
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let toggleModeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Нет аккаунта?", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(toggleModeTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let forgotPasswordButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("Забыли пароль?", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            button.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "BackgroundPrimary")
        emailTextField.delegate = self
        passwordTextField.delegate = self
        setupUI()
        updateMode()
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        view.addSubview(welcomeLabel)
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(actionButton)
        view.addSubview(toggleModeButton)
        view.addSubview(forgotPasswordButton)
        
        NSLayoutConstraint.activate([
            // Welcome label
            welcomeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            welcomeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 150),
            
            // Email text field
            emailTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emailTextField.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 20),
            emailTextField.widthAnchor.constraint(equalToConstant: 250),
            
            // Password text field
            passwordTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 20),
            passwordTextField.widthAnchor.constraint(equalTo: emailTextField.widthAnchor),
            
            // Action button (Войти/Зарегистрироваться)
            actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            actionButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20),
            actionButton.widthAnchor.constraint(equalTo: emailTextField.widthAnchor),
            actionButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Toggle mode button
            toggleModeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toggleModeButton.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 10),
            
            // Forgot password button
            forgotPasswordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            forgotPasswordButton.topAnchor.constraint(equalTo: toggleModeButton.bottomAnchor, constant: 5)
        ])
    }
    
    // MARK: - Update Mode
    
    private func updateMode() {
        if isRegistrationMode {
            actionButton.setTitle("Зарегистрироваться", for: .normal)
            toggleModeButton.setTitle("Уже есть аккаунт?", for: .normal)
        } else {
            actionButton.setTitle("Войти", for: .normal)
            toggleModeButton.setTitle("Нет аккаунта?", for: .normal)
        }
        view.layoutIfNeeded()
    }
    
    // MARK: - Actions
    
    @objc private func actionButtonTapped() {
        // Сохраним текст из полей и выведем для отладки
        let rawEmail = emailTextField.text ?? ""
        let rawPassword = passwordTextField.text ?? ""
        
        // Убираем лишние пробелы и переводы строк
        let email = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = rawPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Проверка: если одно из полей пустое, то показать предупреждение
        guard !email.isEmpty, !password.isEmpty else {
            showAlert(message: "Заполните все поля")
            return
        }
        
        if isRegistrationMode {
            sendRegistrationRequest(email: email, password: password)
        } else {
            sendLoginRequest(email: email, password: password)
        }
    }
    
    @objc private func forgotPasswordTapped() {
        let resetPasswordVC = ResetPasswordViewController()
            navigationController?.pushViewController(resetPasswordVC, animated: true)
    }
    
    @objc private func toggleModeTapped() {
        isRegistrationMode.toggle()
    }
    
    // MARK: - Networking
    
    private func sendRegistrationRequest(email: String, password: String) {
        // Проверка формата email с использованием регулярного выражения
        guard isValidEmail(email) else {
            showAlert(message: "Пожалуйста, введите корректный адрес электронной почты.")
            return
        }
        
        guard let url = URL(string: "http://192.168.0.176:5001/api/auth/register") else {
            showAlert(message: "Неверный URL")
            return
        }
        
        let parameters: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            showAlert(message: "Ошибка формирования запроса")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(message: "Сетевая ошибка: \(error.localizedDescription)")
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self?.showAlert(message: "Неверный ответ сервера")
                }
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let serverMsg = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Ошибка"
                DispatchQueue.main.async {
                    self?.showAlert(message: "Ошибка: \(serverMsg)")
                }
                return
            }
            
            // Регистрация успешна
            DispatchQueue.main.async {
                self?.showAlert(message: "Регистрация прошла успешно!")
                self?.isRegistrationMode = false
            }
        }
        task.resume()
    }

    // Функция для валидации email с использованием регулярного выражения
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
    
    private func sendLoginRequest(email: String, password: String) {
        guard let url = URL(string: "http://192.168.0.176:5001/api/auth/login") else {
            showAlert(message: "Неверный URL")
            return
        }

        let parameters: [String: Any] = [
            "email": email,
            "password": password
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            showAlert(message: "Ошибка формирования запроса")
            return
        }

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(message: "Сетевая ошибка: \(error.localizedDescription)")
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self?.showAlert(message: "Неверный ответ сервера")
                }
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let serverMsg = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Ошибка"
                DispatchQueue.main.async {
                    self?.showAlert(message: "Ошибка: \(serverMsg)")
                }
                return
            }

            // Вход успешен
            DispatchQueue.main.async {
                // Сохраняем статус входа в UserDefaults
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                UserDefaults.standard.set(email, forKey: "userEmail")
                self?.fetchDotaId(email: email)
                // Переходим на главный экран с TabBarController
                self?.switchToTabBarController()
            }
        }
        task.resume()
    }
    
    private func fetchDotaId(email: String) {
        guard let url = URL(string: "http://192.168.0.176:5001/api/auth/getDotaId?email=\(email)") else {
            showAlert(message: "Неверный URL")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(message: "Сетевая ошибка: \(error.localizedDescription)")
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self?.showAlert(message: "Неверный ответ сервера")
                }
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let serverMsg = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Ошибка"
                DispatchQueue.main.async {
                    self?.showAlert(message: "Ошибка: \(serverMsg)")
                }
                return
            }

            // Парсим ответ сервера
            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let dotaId = json["dotaId"] as? String {
                        // Сохраняем Dota ID в UserDefaults
                        UserDefaults.standard.set(dotaId, forKey: "dotaId")
                        DispatchQueue.main.async {
                            print("Dota ID успешно сохранен: \(dotaId)")
                        }
                    } else {
                        DispatchQueue.main.async {
                            print("Не удалось получить Dota ID")
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        print("Ошибка парсинга ответа сервера")
                    }
                }
            }
        }
        task.resume()
    }

    private func switchToTabBarController() {
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.switchToTabBarController()
        }
    }

    
    
    // MARK: - Helpers
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Уведомление", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
}

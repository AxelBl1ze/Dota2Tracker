//
//  SettingsViewController.swift
//  DotaTracker
//
//  Created by Ilya Sidnev on 1/31/25.
//

import UIKit

class SettingsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    private let secretQuestions = [
            "Ваш первый питомец?",
            "Название вашей школы?",
            "Имя вашей мамы?",
            "Ваш любимый цвет?"
        ]
    
    enum AppTheme: String {
        case light
        case dark
        case system
    }
    
    private let themeSwitchContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.backgroundColor = UIColor(named: "BackgroundSecondary")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let themeSwitch: UISegmentedControl = {
        let switchControl = UISegmentedControl(items: [UIImage(systemName: "sun.max.fill")!, UIImage(systemName: "moon.fill")!, UIImage(systemName: "house.circle")!])
        switchControl.selectedSegmentIndex = 0
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        return switchControl
    }()
    
    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Выйти", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 10
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let deleteAccountButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Удалить аккаунт", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 10
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.addTarget(self, action: #selector(deleteAccountTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let secretQuestionContainer: UIView = {
            let view = UIView()
            view.layer.cornerRadius = 10
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOffset = CGSize(width: 0, height: 5)
            view.layer.shadowOpacity = 0.1
            view.layer.shadowRadius = 10
            view.backgroundColor = UIColor(named: "BackgroundSecondary")
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }()
        
        private let secretQuestionLabel: UILabel = {
            let label = UILabel()
            label.text = "Выберите секретный вопрос"
            label.font = .systemFont(ofSize: 18, weight: .medium)
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        
        private let secretQuestionPicker: UIPickerView = {
            let picker = UIPickerView()
            picker.translatesAutoresizingMaskIntoConstraints = false
            return picker
        }()
        
        private let answerTextField: UITextField = {
            let textField = UITextField()
            textField.placeholder = "Введите ответ"
            textField.borderStyle = .roundedRect
            textField.translatesAutoresizingMaskIntoConstraints = false
            return textField
        }()
        
        private let saveButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("Сохранить", for: .normal)
            button.backgroundColor = .systemBlue
            button.layer.cornerRadius = 10
            button.setTitleColor(.white, for: .normal)
            button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()
    
    private let editButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Редактировать", for: .normal)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 10
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // Добавление элементов для ID Dota 2
    private let dotaIdContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 5)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 10
        view.backgroundColor = UIColor(named: "BackgroundSecondary")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let dotaIdLabel: UILabel = {
        let label = UILabel()
        label.text = "Введите ваш Dota 2 ID"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let dotaIdTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введите ID Dota 2"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private let saveDotaIdButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Сохранить ID", for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(saveDotaIdTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "BackgroundPrimary")
        setupUI()
        secretQuestionPicker.delegate = self
        secretQuestionPicker.dataSource = self
        answerTextField.delegate = self
        dotaIdTextField.delegate = self
        if let savedDotaId = UserDefaults.standard.string(forKey: "dotaId") {
                dotaIdTextField.text = savedDotaId
            }
        if let savedIndex = UserDefaults.standard.object(forKey: "selectedQuestionIndex") as? Int,
               savedIndex < secretQuestions.count {
                secretQuestionPicker.selectRow(savedIndex, inComponent: 0, animated: false)
            }
            if let savedAnswer = UserDefaults.standard.string(forKey: "secretAnswer") {
                answerTextField.text = savedAnswer
            }
        
        themeSwitch.addTarget(self, action: #selector(themeChanged(_:)), for: .valueChanged)
        updateThemeSwitchAppearance()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCurrentTheme()
    }
    
    private func loadCurrentTheme() {
        let savedTheme = UserDefaults.standard.string(forKey: "appTheme") ?? "system"
        let theme = AppTheme(rawValue: savedTheme) ?? .system
        
        switch theme {
        case .light: themeSwitch.selectedSegmentIndex = 0
        case .dark: themeSwitch.selectedSegmentIndex = 1
        case .system: themeSwitch.selectedSegmentIndex = 2
        }
    }
    
    private func setupUI() {
        // Добавление кнопок выхода и удаления аккаунта
        buttonStackView.addArrangedSubview(logoutButton)
        buttonStackView.addArrangedSubview(deleteAccountButton)
        view.addSubview(buttonStackView)
        
        // Размещение контейнера для ID Dota 2
        view.addSubview(dotaIdContainer)
        dotaIdContainer.addSubview(dotaIdLabel)
        dotaIdContainer.addSubview(dotaIdTextField)
        dotaIdContainer.addSubview(saveDotaIdButton)
        
        // Размещение контейнера и элементов в нем
        dotaIdContainer.translatesAutoresizingMaskIntoConstraints = false
        dotaIdLabel.translatesAutoresizingMaskIntoConstraints = false
        dotaIdTextField.translatesAutoresizingMaskIntoConstraints = false
        saveDotaIdButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Размещение контейнера для секретного вопроса
        view.addSubview(secretQuestionContainer)
        secretQuestionContainer.addSubview(secretQuestionLabel)
        secretQuestionContainer.addSubview(secretQuestionPicker)
        secretQuestionContainer.addSubview(answerTextField)
        secretQuestionContainer.addSubview(saveButton)
        secretQuestionContainer.addSubview(editButton)
        
        editButton.isHidden = false
        saveButton.isHidden = true
        secretQuestionPicker.isUserInteractionEnabled = false
        answerTextField.isUserInteractionEnabled = false
        
        // Размещение кнопок и поля ввода внутри контейнера
        secretQuestionContainer.translatesAutoresizingMaskIntoConstraints = false
        secretQuestionLabel.translatesAutoresizingMaskIntoConstraints = false
        secretQuestionPicker.translatesAutoresizingMaskIntoConstraints = false
        answerTextField.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(themeSwitchContainer)
        themeSwitchContainer.addSubview(themeSwitch)
        
        NSLayoutConstraint.activate([
            themeSwitchContainer.topAnchor.constraint(equalTo: dotaIdContainer.bottomAnchor, constant: 20),
            themeSwitchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            themeSwitchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            themeSwitchContainer.heightAnchor.constraint(equalToConstant: 60),
            
            themeSwitch.trailingAnchor.constraint(equalTo: themeSwitchContainer.trailingAnchor, constant: -16),
            themeSwitch.centerXAnchor.constraint(equalTo: themeSwitchContainer.centerXAnchor),
            themeSwitch.centerYAnchor.constraint(equalTo: themeSwitchContainer.centerYAnchor),
            themeSwitch.widthAnchor.constraint(equalToConstant: 200),
            themeSwitch.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        NSLayoutConstraint.activate([
            
            
            // Кнопки выхода и удаления аккаунта
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            buttonStackView.heightAnchor.constraint(equalToConstant: 50),
            
            // Контейнер для секретного вопроса
            secretQuestionContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            secretQuestionContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            secretQuestionContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            secretQuestionContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 250),
            
            // Секретный вопрос
            secretQuestionLabel.topAnchor.constraint(equalTo: secretQuestionContainer.topAnchor, constant: 10),
            secretQuestionLabel.leadingAnchor.constraint(equalTo: secretQuestionContainer.leadingAnchor, constant: 20),

            // Пикер для выбора вопроса
            secretQuestionPicker.topAnchor.constraint(equalTo: secretQuestionLabel.bottomAnchor, constant: 5),
            secretQuestionPicker.leadingAnchor.constraint(equalTo: secretQuestionContainer.leadingAnchor, constant: 20),
            secretQuestionPicker.trailingAnchor.constraint(equalTo: secretQuestionContainer.trailingAnchor, constant: -20),
            secretQuestionPicker.heightAnchor.constraint(equalToConstant: 100), // Устанавливаем высоту пикера

            // Поле для ввода ответа
            answerTextField.topAnchor.constraint(equalTo: secretQuestionPicker.bottomAnchor, constant: 5),
            answerTextField.leadingAnchor.constraint(equalTo: secretQuestionContainer.leadingAnchor, constant: 20),
            answerTextField.trailingAnchor.constraint(equalTo: secretQuestionContainer.trailingAnchor, constant: -20),
            
            // Кнопка сохранения
            saveButton.topAnchor.constraint(equalTo: answerTextField.bottomAnchor, constant: 15),
            saveButton.leadingAnchor.constraint(equalTo: secretQuestionContainer.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: secretQuestionContainer.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Добавление constraints для кнопки "Редактировать"
            editButton.topAnchor.constraint(equalTo: answerTextField.bottomAnchor, constant: 15),
            editButton.leadingAnchor.constraint(equalTo: secretQuestionContainer.leadingAnchor, constant: 20),
            editButton.trailingAnchor.constraint(equalTo: secretQuestionContainer.trailingAnchor, constant: -20),
            editButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Контейнер для ID Dota 2
            dotaIdContainer.topAnchor.constraint(equalTo: secretQuestionContainer.bottomAnchor, constant: 20),
            dotaIdContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            dotaIdContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            dotaIdContainer.heightAnchor.constraint(equalToConstant: 150),
                    
            // Лейбл для ID Dota 2
            dotaIdLabel.topAnchor.constraint(equalTo: dotaIdContainer.topAnchor, constant: 10),
            dotaIdLabel.leadingAnchor.constraint(equalTo: dotaIdContainer.leadingAnchor, constant: 20),
                    
            // Поле для ввода ID Dota 2
            dotaIdTextField.topAnchor.constraint(equalTo: dotaIdLabel.bottomAnchor, constant: 10),
            dotaIdTextField.leadingAnchor.constraint(equalTo: dotaIdContainer.leadingAnchor, constant: 20),
            dotaIdTextField.trailingAnchor.constraint(equalTo: dotaIdContainer.trailingAnchor, constant: -20),
            
            // Кнопка для сохранения ID
            saveDotaIdButton.topAnchor.constraint(equalTo: dotaIdTextField.bottomAnchor, constant: 15),
            saveDotaIdButton.leadingAnchor.constraint(equalTo: dotaIdContainer.leadingAnchor, constant: 20),
            saveDotaIdButton.trailingAnchor.constraint(equalTo: dotaIdContainer.trailingAnchor, constant: -20),
            saveDotaIdButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1 // Один компонент для вопросов
        }
        
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return secretQuestions.count
        }
        
        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return secretQuestions[row]
        }
    
    @objc private func editTapped() {
        // Разрешаем редактирование
        secretQuestionPicker.isUserInteractionEnabled = true
        answerTextField.isUserInteractionEnabled = true
        editButton.isHidden = true
        saveButton.isHidden = false
    }
        
    @objc private func saveTapped() {
        // Получаем выбранный секретный вопрос и ответ
        let selectedQuestion = secretQuestions[secretQuestionPicker.selectedRow(inComponent: 0)] // Если секретные вопросы сохранены в массиве
        let answer = answerTextField.text ?? ""
        
        guard let email = UserDefaults.standard.string(forKey: "userEmail") else {
            showAlert(title: "Ошибка", message: "Не удалось получить email пользователя", isError: true)
            return
        }
        
        // Отправка данных на сервер
        saveSecretQuestionAndAnswer(email: email, question: selectedQuestion, answer: answer)
        
        // Блокируем редактирование и обновляем кнопки
            secretQuestionPicker.isUserInteractionEnabled = false
            answerTextField.isUserInteractionEnabled = false
            editButton.isHidden = false
            saveButton.isHidden = true
    }
    
    @objc private func themeChanged(_ sender: UISegmentedControl) {
        let theme: AppTheme
        switch sender.selectedSegmentIndex {
        case 0: theme = .light
        case 1: theme = .dark
        default: theme = .system
        }
        
        UserDefaults.standard.set(theme.rawValue, forKey: "appTheme")
        applyTheme(theme)
    }

    private func updateThemeSwitchAppearance() {
        themeSwitch.backgroundColor = UIColor(named: "BackgroundSecondary")
        themeSwitch.selectedSegmentTintColor = UIColor(named: "AccentColor")
        
        let textColor = UIColor { trait in
            return trait.userInterfaceStyle == .dark ? .white : .black
        }
        
        themeSwitch.setTitleTextAttributes([.foregroundColor: textColor], for: .normal)
        themeSwitch.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }

    private func applyTheme(_ theme: AppTheme) {
        UIView.animate(withDuration: 0.3) {
            switch theme {
            case .light:
                UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .light
            case .dark:
                UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .dark
            case .system:
                UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .unspecified
            }
        }
    }

    private func saveSecretQuestionAndAnswer(email: String, question: String, answer: String) {
        guard let url = URL(string: "http://192.168.0.176:5001/api/auth/saveSecretQuestion") else {
            showAlert(title: "Ошибка", message: "Неверный URL", isError: true)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Параметры запроса
        let parameters: [String: Any] = [
            "email": email,
            "question": question,
            "answer": answer
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            showAlert(title: "Ошибка", message: "Ошибка формирования запроса", isError: true)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Ошибка", message: "Ошибка сети: \(error.localizedDescription)", isError: true)
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Ошибка", message: "Неверный ответ сервера", isError: true)
                }
                return
            }
            
            if httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    if let index = self?.secretQuestions.firstIndex(of: question) {
                        UserDefaults.standard.set(index, forKey: "selectedQuestionIndex")
                    }
                    UserDefaults.standard.set(answer, forKey: "secretAnswer")
                    self?.showAlert(title: "Успех", message: "Секретный вопрос и ответ сохранены", isError: false)
                }
            } else {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Ошибка", message: "Ошибка сервера", isError: true)
                }
            }
        }
        task.resume()
    }

    
    @objc private func logoutTapped() {
        logout()
    }
    
    @objc private func deleteAccountTapped() {
        let alert = UIAlertController(title: "Удаление аккаунта",
                                      message: "Вы уверены, что хотите удалить аккаунт? Это действие нельзя отменить.",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Да", style: .destructive, handler: { _ in
            self.deleteAccount()
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func deleteAccount() {
        guard let email = UserDefaults.standard.string(forKey: "userEmail") else {
            showAlert(title: "Ошибка", message: "Не удалось получить email пользователя", isError: true)
            return
        }
        
        guard let url = URL(string: "http://192.168.0.176:5001/api/auth/delete") else {
            showAlert(title: "Ошибка", message: "Неверный URL", isError: true)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = ["email": email]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            showAlert(title: "Ошибка", message: "Ошибка формирования запроса", isError: true)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Ошибка", message: "Ошибка сети: \(error.localizedDescription)", isError: true)
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Ошибка", message: "Неверный ответ сервера", isError: true)
                }
                return
            }
            
            if httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Готово", message: "Аккаунт успешно удален", isError: false) {
                        /*if let bundleID = Bundle.main.bundleIdentifier {
                            UserDefaults.standard.removePersistentDomain(forName: bundleID)
                        }
                        UserDefaults.standard.synchronize()*/
                        self?.logout()
                    }
                }
            } else {
                let serverMsg = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Ошибка сервера"
                DispatchQueue.main.async {
                    self?.showAlert(title: "Ошибка", message: "Ошибка: \(serverMsg)", isError: true)
                }
            }
        }
        task.resume()
    }
    
    @objc private func saveDotaIdTapped() {
        // Получаем введенный ID Dota 2
        guard let dotaId = dotaIdTextField.text, !dotaId.isEmpty else {
            showAlert(title: "Ошибка", message: "Пожалуйста, введите ваш Dota 2 ID.", isError: true)
            return
        }
        
        // Получаем email пользователя
        guard let email = UserDefaults.standard.string(forKey: "userEmail") else {
            showAlert(title: "Ошибка", message: "Не удалось получить email пользователя", isError: true)
            return
        }
        
        // Отправка ID на сервер
        saveDotaId(email: email, dotaId: dotaId)
        UserDefaults.standard.set(dotaId, forKey: "dotaId")
    }

    private func saveDotaId(email: String, dotaId: String) {
        guard let url = URL(string: "http://192.168.0.176:5001/api/auth/saveDotaId") else {
            showAlert(title: "Ошибка", message: "Неверный URL", isError: true)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Параметры запроса
        let parameters: [String: Any] = [
            "email": email,
            "dotaId": dotaId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            showAlert(title: "Ошибка", message: "Ошибка формирования запроса", isError: true)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Ошибка", message: "Ошибка сети: \(error.localizedDescription)", isError: true)
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Ошибка", message: "Неверный ответ сервера", isError: true)
                }
                return
            }
            
            if httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    UserDefaults.standard.set(dotaId, forKey: "dotaId")
                    self?.showAlert(title: "Успех", message: "ID Dota 2 сохранен", isError: false)
                    NotificationCenter.default.post(name: .dotaIdUpdated, object: nil)
                }
            } else {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Ошибка", message: "Ошибка сервера", isError: true)
                }
            }
        }
        task.resume()
    }
    
    private func logout() {
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "dotaId")
        UserDefaults.standard.removeObject(forKey: "secretAnswer")
        UserDefaults.standard.removeObject(forKey: "selectedQuestionIndex")
        UserDefaults.standard.removeObject(forKey: "appTheme")
        
        let homeVC = LoginViewController()
        let navController = UINavigationController(rootViewController: homeVC)
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(navController)
    }
    
    private func showAlert(title: String, message: String, isError: Bool, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        }
        
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
}

extension Notification.Name {
    static let dotaIdUpdated = Notification.Name("DotaIDUpdatedNotification")
}


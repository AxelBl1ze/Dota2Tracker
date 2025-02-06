//
//  HomeViewController.swift
//  DotaTracker
//
//  Created by Ilya Sidnev on 2/1/25.
//

import UIKit

class HomeViewController: UIViewController {
    
    // Инициализация UILabel и UIButton
    var matchCountLabel: UILabel!
    var fetchButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "BackgroundPrimary")
        // Инициализация и настройка matchCountLabel
        matchCountLabel = UILabel()
        matchCountLabel.translatesAutoresizingMaskIntoConstraints = false
        matchCountLabel.text = "Количество матчей: 0"
        matchCountLabel.font = UIFont.systemFont(ofSize: 18)
        matchCountLabel.textColor = .black
        view.addSubview(matchCountLabel)
        
        // Установка ограничений для matchCountLabel
        NSLayoutConstraint.activate([
            matchCountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            matchCountLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Инициализация и настройка fetchButton
        fetchButton = UIButton(type: .system)
        fetchButton.translatesAutoresizingMaskIntoConstraints = false
        fetchButton.setTitle("Получить количество матчей", for: .normal)
        fetchButton.addTarget(self, action: #selector(fetchMatchCount), for: .touchUpInside)
        view.addSubview(fetchButton)
        
        // Установка ограничений для fetchButton
        NSLayoutConstraint.activate([
            fetchButton.topAnchor.constraint(equalTo: matchCountLabel.bottomAnchor, constant: 20),
            fetchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc func fetchMatchCount() {
        // Получаем email из UserDefaults
        if let email = UserDefaults.standard.string(forKey: "userEmail") {
            // URL для запроса Dota ID по email
            let urlString = "http://192.168.0.176:5001/api/auth/getDotaId?email=\(email)"
            
            guard let url = URL(string: urlString) else {
                print("Некорректный URL")
                return
            }
            
            // Создание GET-запроса для получения Dota ID
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Ошибка при запросе Dota ID: \(error)")
                    return
                }
                
                guard let data = data else {
                    print("Нет данных в ответе")
                    return
                }
                
                do {
                    // Декодируем ответ с Dota ID
                    if let dotaIdResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        // Обрабатываем dotaId как строку
                        if let dotaIdString = dotaIdResponse["dotaId"] as? String {
                            // Преобразуем строку в Int, если необходимо
                            if let dotaId = Int(dotaIdString) {
                                print("Получен Dota ID: \(dotaId)")  // Лог для успешного получения Dota ID
                                self.fetchMatchStats(dotaId: dotaId)
                            } else {
                                print("Не удалось преобразовать Dota ID в Int.")
                            }
                        } else {
                            print("Не удалось получить Dota ID из ответа.")
                        }
                    } else {
                        print("Ответ не в ожидаемом формате.")
                    }
                } catch {
                    print("Ошибка декодирования данных: \(error)")
                }
            }
            task.resume()
        } else {
            print("Email не найден в UserDefaults")
        }
    }


    
    func fetchMatchStats(dotaId: Int) {
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJTdWJqZWN0IjoiYTQ2YWRiNzYtZjMyZi00YzMxLWFkYzctMzkwNzcxYzVjN2UxIiwiU3RlYW1JZCI6IjExOTUxMzA4MzAiLCJuYmYiOjE3Mzg0NDczOTIsImV4cCI6MTc2OTk4MzM5MiwiaWF0IjoxNzM4NDQ3MzkyLCJpc3MiOiJodHRwczovL2FwaS5zdHJhdHouY29tIn0.ILE_4wzbsf72y-32fLZyOWp_-Vt0m8dfpBsgUsb4jRo"
        let url = URL(string: "https://api.stratz.com/graphql")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let query = """
        {
            player(steamAccountId: \(dotaId)) {
                matchCount
            }
        }
        """
        
        let body: [String: Any] = [
            "query": query
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        } catch {
            print("Ошибка при формировании тела запроса: \(error)")
            return
        }
        
        // Выполнение запроса
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Ошибка при запросе статистики: \(error)")
                return
            }
            
            guard let data = data else {
                print("Нет данных в ответе")
                return
            }
            
            do {
                // Декодируем ответ
                let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let data = responseDict?["data"] as? [String: Any],
                   let player = data["player"] as? [String: Any],
                   let matchCount = player["matchCount"] as? Int {
                    // Обновление текста лейбла на главном потоке
                    DispatchQueue.main.async {
                        self.matchCountLabel.text = "Количество матчей: \(matchCount)"
                    }
                }
            } catch {
                print("Ошибка декодирования данных: \(error)")
            }
        }
        
        task.resume()
    }
}

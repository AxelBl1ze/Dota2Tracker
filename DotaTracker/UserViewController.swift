import UIKit
import Charts

class UserViewController: UIViewController {
    
    struct Response: Codable {
        let data: PlayerDataContainer?
        let errors: [APIError]?
    }

    struct PlayerDataContainer: Codable {
        let player: PlayerData?
    }

    struct PlayerData: Codable {
        struct SteamAccount: Codable {
            let avatar: String
            let name: String
            let seasonRank: Int?
            let isDotaPlusSubscriber: Bool
        }
        
        struct LeaderboardRank: Codable {
            let seasonLeaderBoardDivisionId: String
            let rank: Int
        }
        
        struct Match: Codable {
            let id: Int
            let players: [Player]
            
            struct Player: Codable {
                let position: String
                let kills: Int
                let deaths: Int
                let assists: Int
                let heroDamage: Int
                let towerDamage: Int
                let networth: Int
                let isRadiant: Bool
                let item0Id: Int?
                let item1Id: Int?
                let item2Id: Int?
                let item3Id: Int?
                let item4Id: Int?
                let item5Id: Int?
                let backpack0Id: Int?
                let backpack1Id: Int?
                let backpack2Id: Int?
                let neutral0Id: Int?
                let goldPerMinute: Int
                let hero: Hero
                
                struct Hero: Codable {
                    let id: Int
                }
            }
        }
        
        let steamAccount: SteamAccount
        let matchCount: Int
        let winCount: Int
        let lastMatchDate: Int?
        let leaderboardRanks: [LeaderboardRank]?
        let matches: [Match]?
    }

    struct APIError: Codable {
        let message: String
        let locations: [Location]?
        
        struct Location: Codable {
            let line: Int
            let column: Int
        }
    }
    
    private var currentPlayerData: PlayerData?
    private let scrollView = UIScrollView()
    private let contentView = UIStackView()

    private let avatarImageView = UIImageView()
    private let nicknameLabel = UILabel()
    private let statsContainer = UIStackView()
    
    private let matchCard = StatCard(title: "Матчи")
    private let winCard = StatCard(title: "Побед", color: .systemGreen)
    private let loseCard = StatCard(title: "Поражений", color: .systemRed)
    private let winRateCard = StatCard(title: "Винрейт", color: .systemBlue, isWide: true)
    private let rankImageView = UIImageView()
    private let leaderboardRankLabel = UILabel()
    private let dotaPlusCard = StatCard(title: "Dota Plus", isWide: true)
    private let pieChartView = PositionPieChartView()
    private let legendStack = UIStackView()
    
    private let lastMatchLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "BackgroundPrimary")
        setupNavigationBar()
        setupUI()
        fetchUserData()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDotaIdUpdate),
            name: .dotaIdUpdated,
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Обновляем состояние Dota Plus при возвращении на экран
        if let playerData = currentPlayerData {
            if playerData.steamAccount.isDotaPlusSubscriber {
                dotaPlusCard.startGlowing()
            } else {
                dotaPlusCard.stopGlowing()
            }
        }
    }

    
    // Обработчик уведомления
    @objc private func handleDotaIdUpdate() {
        fetchUserData()
    }

    // Не забудьте удалить наблюдатель при деинициализации
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNavigationBar() {
        navigationItem.title = "Профиль"
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(openSettings)
        )
        navigationItem.rightBarButtonItem = settingsButton
    }

    @objc private func openSettings() {
        let settingsVC = SettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.axis = .vertical
        contentView.spacing = 16
        contentView.alignment = .center
        contentView.translatesAutoresizingMaskIntoConstraints = false

        // Настройка аватарки
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 50
        avatarImageView.layer.borderWidth = 2
        avatarImageView.layer.borderColor = UIColor.systemGray6.cgColor
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 100),
            avatarImageView.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        //Настройка Диаграммы
        
        // Добавляем диаграмму
        pieChartView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addArrangedSubview(pieChartView)
        
        NSLayoutConstraint.activate([
            pieChartView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.8),
            pieChartView.heightAnchor.constraint(equalTo: pieChartView.widthAnchor)
        ])
        
        // Добавляем легенду
        legendStack.axis = .horizontal
        legendStack.distribution = .fillEqually
        legendStack.spacing = 8
        legendStack.alignment = .center
        legendStack.layer.cornerRadius = 12
        legendStack.backgroundColor = UIColor(named: "BackgroundSecondary")
        legendStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addArrangedSubview(legendStack)
        

        // Настройка никнейма
        nicknameLabel.font = UIFont.boldSystemFont(ofSize: 24)
        nicknameLabel.textAlignment = .left
        nicknameLabel.textColor = .label
        nicknameLabel.numberOfLines = 1
        nicknameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        // Контейнер ранга
        let rankContainer = UIView()
        rankContainer.translatesAutoresizingMaskIntoConstraints = false

        // Настройка элементов ранга
        rankImageView.contentMode = .scaleAspectFit
        rankImageView.translatesAutoresizingMaskIntoConstraints = false

        leaderboardRankLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        leaderboardRankLabel.textColor = .white
        leaderboardRankLabel.textAlignment = .center
        leaderboardRankLabel.translatesAutoresizingMaskIntoConstraints = false

        // Главный горизонтальный стек
        let mainHorizontalStack = UIStackView()
        mainHorizontalStack.axis = .horizontal
        mainHorizontalStack.spacing = 16
        mainHorizontalStack.alignment = .center // Выравнивание по центру вертикали
        mainHorizontalStack.distribution = .fill
        
        // Добавляем элементы в стек
        mainHorizontalStack.addArrangedSubview(avatarImageView)
        mainHorizontalStack.addArrangedSubview(nicknameLabel)
        mainHorizontalStack.addArrangedSubview(rankContainer)

        // Настройка контейнера ранга
        rankContainer.addSubview(rankImageView)
        rankContainer.addSubview(leaderboardRankLabel)

        // Карточка профиля
        let profileCard = UIView()
        profileCard.backgroundColor = UIColor(named: "BackgroundSecondary")
        profileCard.layer.cornerRadius = 12
        profileCard.translatesAutoresizingMaskIntoConstraints = false

        // Главный вертикальный стек
        let mainVerticalStack = UIStackView()
        mainVerticalStack.axis = .vertical
        mainVerticalStack.spacing = 16
        mainVerticalStack.translatesAutoresizingMaskIntoConstraints = false
        
        mainVerticalStack.addArrangedSubview(mainHorizontalStack)
        mainVerticalStack.addArrangedSubview(lastMatchLabel)
        profileCard.addSubview(mainVerticalStack)

        // Настройка метки последнего матча
        lastMatchLabel.layer.cornerRadius = 8
        lastMatchLabel.layer.masksToBounds = true
        lastMatchLabel.backgroundColor = UIColor(named: "BackgroundTertiary")
        lastMatchLabel.textAlignment = .center
        lastMatchLabel.translatesAutoresizingMaskIntoConstraints = false

        // Констрейнты
        NSLayoutConstraint.activate([
            // Ранг
            rankImageView.widthAnchor.constraint(equalToConstant: 80),
            rankImageView.heightAnchor.constraint(equalToConstant: 80),
            rankImageView.centerYAnchor.constraint(equalTo: rankContainer.centerYAnchor),
            rankImageView.leadingAnchor.constraint(equalTo: rankContainer.leadingAnchor),
            rankImageView.trailingAnchor.constraint(equalTo: rankContainer.trailingAnchor),
            
            leaderboardRankLabel.centerXAnchor.constraint(equalTo: rankImageView.centerXAnchor),
            leaderboardRankLabel.bottomAnchor.constraint(equalTo: rankImageView.bottomAnchor, constant: -5),
            
            // Контейнер ранга
            rankContainer.widthAnchor.constraint(equalToConstant: 80),
            rankContainer.heightAnchor.constraint(equalToConstant: 80),

            // Главный стек
            mainVerticalStack.topAnchor.constraint(equalTo: profileCard.topAnchor, constant: 16),
            mainVerticalStack.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor, constant: 16),
            mainVerticalStack.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor, constant: -16),
            mainVerticalStack.bottomAnchor.constraint(equalTo: profileCard.bottomAnchor, constant: -16),

            // Метка последнего матча
            lastMatchLabel.widthAnchor.constraint(equalTo: mainVerticalStack.widthAnchor),
            lastMatchLabel.heightAnchor.constraint(equalToConstant: 32)
        ])

        // Остальная часть кода
        statsContainer.axis = .vertical
        statsContainer.alignment = .fill
        statsContainer.spacing = 16
        statsContainer.translatesAutoresizingMaskIntoConstraints = false

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addArrangedSubview(loadingIndicator)
        contentView.addArrangedSubview(profileCard)
        contentView.addArrangedSubview(statsContainer)
        
        // Добавьте контейнер для диаграммы
        let chartContainer = UIView()
        chartContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addArrangedSubview(chartContainer)
        
        // Добавьте диаграмму в новый контейнер
        chartContainer.addSubview(pieChartView)
        chartContainer.addSubview(legendStack)

        let firstRow = UIStackView()
        firstRow.axis = .horizontal
        firstRow.distribution = .fillEqually
        firstRow.spacing = 16

        firstRow.addArrangedSubview(matchCard)
        firstRow.addArrangedSubview(winCard)
        firstRow.addArrangedSubview(loseCard)

        let secondRow = UIStackView()
        secondRow.axis = .horizontal
        secondRow.distribution = .fill
        secondRow.spacing = 16

        secondRow.addArrangedSubview(winRateCard)
        secondRow.addArrangedSubview(dotaPlusCard)

        statsContainer.addArrangedSubview(firstRow)
        statsContainer.addArrangedSubview(secondRow)

        NSLayoutConstraint.activate([
            profileCard.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.9),
            
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            statsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statsContainer.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -32),
            
            // Для контейнера диаграммы
            chartContainer.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            
            // Для диаграммы
            pieChartView.topAnchor.constraint(equalTo: chartContainer.topAnchor, constant: 20),
            pieChartView.centerXAnchor.constraint(equalTo: chartContainer.centerXAnchor),
            pieChartView.widthAnchor.constraint(equalTo: chartContainer.widthAnchor, multiplier: 0.8),
            pieChartView.heightAnchor.constraint(equalTo: pieChartView.widthAnchor),
            
            // Для легенды
            legendStack.topAnchor.constraint(equalTo: pieChartView.bottomAnchor, constant: 16),
            legendStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            legendStack.leadingAnchor.constraint(equalTo: chartContainer.leadingAnchor, constant: 20),
            legendStack.trailingAnchor.constraint(equalTo: chartContainer.trailingAnchor, constant: -20),
            legendStack.bottomAnchor.constraint(equalTo: chartContainer.bottomAnchor, constant: -20)
        ])
    }


    private func fetchUserData() {
        let userId = UserDefaults.standard.string(forKey: "dotaId") ?? ""
        let apiToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJTdWJqZWN0IjoiYTQ2YWRiNzYtZjMyZi00YzMxLWFkYzctMzkwNzcxYzVjN2UxIiwiU3RlYW1JZCI6IjExOTUxMzA4MzAiLCJuYmYiOjE3Mzg0NDczOTIsImV4cCI6MTc2OTk4MzM5MiwiaWF0IjoxNzM4NDQ3MzkyLCJpc3MiOiJodHRwczovL2FwaS5zdHJhdHouY29tIn0.ILE_4wzbsf72y-32fLZyOWp_-Vt0m8dfpBsgUsb4jRo"

        guard let steamAccountId = Int(userId) else {
            print("Некорректный steamAccountId")
            return
        }

        let query = """
        {
            player(steamAccountId: \(steamAccountId)) {
                steamAccount {
                    avatar
                    name
                    seasonRank
                    isDotaPlusSubscriber
                }
                matchCount
                winCount
                lastMatchDate
                leaderboardRanks {
                    seasonLeaderBoardDivisionId
                    rank
                }
                matches(request: {
                    take: 100, 
                    positionIds: [POSITION_1, POSITION_2, POSITION_3, POSITION_4, POSITION_5]
                }) {
                    id
                    direKills
                    radiantKills
                    actualRank
                    lobbyType
                    players(steamAccountId: \(steamAccountId)) {
                        position
                        kills
                        deaths
                        assists
                        heroDamage
                        towerDamage
                        networth
                        isRadiant
                        item0Id
                        item1Id
                        item2Id
                        item3Id
                        item4Id
                        item5Id
                        backpack0Id
                        backpack1Id
                        backpack2Id
                        neutral0Id
                        goldPerMinute
                        hero {
                            id
                        }
                    }
                }
            }
        }
        """

        guard let url = URL(string: "https://api.stratz.com/graphql") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = ["query": query]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Ошибка загрузки данных: \(error?.localizedDescription ?? "Неизвестная ошибка")")
                return
            }

            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(Response.self, from: data)
                
                if let errors = response.errors {
                    print("Ошибки API:")
                    errors.forEach { print($0.message) }
                    return
                }
                
                guard let playerData = response.data?.player else {
                    print("Данные игрока отсутствуют")
                    return
                }
                
                DispatchQueue.main.async {
                    self.updateUI(with: playerData)
                }
                
            } catch {
                print("Ошибка парсинга JSON: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Полученный JSON: \(jsonString)")
                }
            }
        }.resume()
    }

    private func updateUI(with playerData: PlayerData) {
        currentPlayerData = playerData
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
        
        // Основные данные
        loadImage(from: playerData.steamAccount.avatar, into: avatarImageView)
        nicknameLabel.text = playerData.steamAccount.name.isEmpty ? "Неизвестный игрок" : playerData.steamAccount.name
        
        // Расчет ранга
        let (rankImageName, leaderText) = getRankInfo(
            seasonRank: playerData.steamAccount.seasonRank,
            leaderboardRanks: playerData.leaderboardRanks
        )
        
        // Загрузка изображения ранга
        if let image = UIImage(named: rankImageName) {
            rankImageView.image = image
        } else {
            rankImageView.image = UIImage(named: "SeasonalRank0-0")
        }
        
        // Настройка текста лидерборда
        leaderboardRankLabel.text = leaderText
        leaderboardRankLabel.isHidden = leaderText == nil
        
        // Статистика
        let losses = playerData.matchCount - playerData.winCount
        let winRate = Double(playerData.winCount) / Double(playerData.matchCount) * 100
        
        matchCard.setValue("\(playerData.matchCount)")
        winCard.setValue("\(playerData.winCount)")
        loseCard.setValue("\(losses)")
        winRateCard.setValue(String(format: "%.1f%%", winRate))
        
        // Время последней игры
        if let timestamp = playerData.lastMatchDate {
            lastMatchLabel.text = "Последняя игра: \(timeAgoSinceTimestamp(timestamp))"
        } else {
            lastMatchLabel.text = "История игр недоступна"
        }
        
        // Обновление диаграммы
        if let matches = playerData.matches, !matches.isEmpty {
            let segments = processPositionData(matches)
            pieChartView.setSegments(segments)
            createLegend(for: segments)
            pieChartView.isHidden = false
            legendStack.isHidden = false
        } else {
            pieChartView.isHidden = true
            legendStack.isHidden = true
        }
        
        // Анимация
        pieChartView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        pieChartView.alpha = 0
        UIView.animate(withDuration: 0.6, delay: 0.4,
                      usingSpringWithDamping: 0.6,
                      initialSpringVelocity: 0.5,
                      options: .curveEaseInOut) {
            self.pieChartView.transform = .identity
            self.pieChartView.alpha = 1
        }
        
        // Обработка статуса Dota Plus
        let dotaPlusStatus = playerData.steamAccount.isDotaPlusSubscriber ? "Активна" : "Не активна"
        let dotaPlusColor = playerData.steamAccount.isDotaPlusSubscriber ? UIColor.systemYellow : UIColor.systemRed
        dotaPlusCard.setValue(dotaPlusStatus, color: dotaPlusColor)
        
        // Анимация
        rankImageView.alpha = 0
        leaderboardRankLabel.alpha = 0
            
        UIView.animate(withDuration: 0.5) {
            self.rankImageView.alpha = 1
            self.leaderboardRankLabel.alpha = 1
        }
        
        // Анимация для Dota Plus
        dotaPlusCard.alpha = 0
        UIView.animate(withDuration: 0.5) {
            self.dotaPlusCard.alpha = 1
        }

        // Запуск или остановка свечения
        if playerData.steamAccount.isDotaPlusSubscriber {
            dotaPlusCard.startGlowing()
        } else {
            dotaPlusCard.stopGlowing()
        }
    }
    
    private func createLegend(for segments: [(value: CGFloat, color: UIColor, icon: UIImage?)]) {
        legendStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for segment in segments {
            let legendItem = UIStackView()
            legendItem.axis = .vertical
            legendItem.alignment = .center
            legendItem.spacing = 4
            
            let colorView = UIView()
            colorView.backgroundColor = segment.color
            colorView.layer.cornerRadius = 8
            colorView.layer.shadowColor = segment.color.cgColor
            colorView.layer.shadowRadius = 4
            colorView.layer.shadowOpacity = 0.3
            colorView.layer.shadowOffset = CGSize(width: 0, height: 2)
            
            let iconView = UIImageView(image: segment.icon)
            iconView.contentMode = .scaleAspectFit
            
            let label = UILabel()
            label.text = String(format: "%.1f%%", segment.value)
            label.font = .systemFont(ofSize: 12, weight: .bold)
            label.textColor = .label
            
            //legendItem.addArrangedSubview(iconView)
            legendItem.addArrangedSubview(label)
            legendItem.addArrangedSubview(colorView)
            
            NSLayoutConstraint.activate([
                colorView.widthAnchor.constraint(equalToConstant: 16),
                colorView.heightAnchor.constraint(equalToConstant: 16),
                //iconView.widthAnchor.constraint(equalToConstant: 24),
                //iconView.heightAnchor.constraint(equalToConstant: 24),
            ])
            
            legendStack.addArrangedSubview(legendItem)
        }
    }
    
    private func loadImage(from urlString: String, into imageView: UIImageView) {
        guard let url = URL(string: urlString) else { return }
        let cache = URLCache.shared
        let request = URLRequest(url: url)

        if let cachedData = cache.cachedResponse(for: request)?.data, let image = UIImage(data: cachedData) {
            imageView.image = image
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, _ in
            if let data = data, let image = UIImage(data: data) {
                cache.storeCachedResponse(CachedURLResponse(response: response!, data: data), for: request)
                DispatchQueue.main.async {
                    imageView.image = image
                }
            }
        }.resume()
    }
    
    private func getRankInfo(seasonRank: Int?, leaderboardRanks: [PlayerData.LeaderboardRank]?) -> (imageName: String, leaderText: String?) {
        guard let rank = seasonRank else {
            return ("SeasonalRank0-0", nil)
        }
        
        if rank == 80 {
            if let leaderRank = leaderboardRanks?.last?.rank {
                return ("SeasonalRank8-0", "\(leaderRank)")
            }
            return ("SeasonalRank8-0", nil)
        }
        
        let rankTier = rank / 10
        let rankLevel = rank % 10
        let clampedLevel = min(rankLevel, 5)
        
        return ("SeasonalRank\(rankTier)-\(clampedLevel)", nil)
    }
    
    private func timeAgoSinceTimestamp(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 1
        formatter.allowedUnits = [.year, .month, .day, .hour, .minute]
        
        // Устанавливаем русскую локаль
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.calendar?.locale = Locale(identifier: "ru_RU")
        
        let now = Date()
        guard let timeString = formatter.string(from: date, to: now) else {
            return "давно"
        }
        
        return "\(timeString) назад"
    }
    
    private func processPositionData(_ matches: [PlayerData.Match]) -> [(value: CGFloat, color: UIColor, icon: UIImage?)] {
        var positionCounts = [String: Int]()
        
        for match in matches {
            guard let position = match.players.first?.position else { continue }
            positionCounts[position] = (positionCounts[position] ?? 0) + 1
        }
        
        let total = CGFloat(positionCounts.values.reduce(0, +))
        guard total > 0 else { return [] }
        
        let positionData: [(String, UIColor, String)] = [
            ("POSITION_1", #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1), "position1"),
            ("POSITION_2", #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1), "position2"),
            ("POSITION_3", #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1), "position3"),
            ("POSITION_4", #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1), "position4"),
            ("POSITION_5", #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1), "position5")
        ]
        
        return positionData.compactMap { (key, color, iconName) in
            guard let count = positionCounts[key], count > 0 else { return nil }
            let percentage = (CGFloat(count) / total) * 100
            return (percentage, color, UIImage(named: iconName))
        }
    }
}

// 🔹 Компонент для карточек статистики
class StatCard: UIView {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    init(title: String, color: UIColor = .secondaryLabel, isWide: Bool = false) {
        super.init(frame: .zero)
        backgroundColor = UIColor(named: "BackgroundSecondary")
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 0, height: 3)

        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .secondaryLabel

        valueLabel.font = UIFont.boldSystemFont(ofSize: 18)
        valueLabel.textColor = color
        valueLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        
        // Применяем гибкость в зависимости от того, широка ли карточка
        if isWide {
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
                stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
                stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                self.widthAnchor.constraint(lessThanOrEqualToConstant: 200)
            ])
        } else {
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
                stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
                stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
            ])
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setValue(_ value: String, color: UIColor? = nil) {
        valueLabel.text = value
        if let color = color {
            valueLabel.textColor = color
        }
    }
    
    func startGlowing() {
        // Настройка свечения через тень
        valueLabel.layer.shadowColor = UIColor.yellow.cgColor
        valueLabel.layer.shadowRadius = 3.0
        valueLabel.layer.shadowOpacity = 1.0
        valueLabel.layer.shadowOffset = CGSize(width: 0, height: 0)
        
        // Анимация свечения
        let glowAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        glowAnimation.fromValue = 0.0
        glowAnimation.toValue = 1.0
        glowAnimation.duration = 1.0
        glowAnimation.autoreverses = true
        glowAnimation.repeatCount = .infinity
        valueLabel.layer.add(glowAnimation, forKey: "glowEffect")
    }

    func stopGlowing() {
        // Убираем свечение
        valueLabel.layer.removeAnimation(forKey: "glowEffect")
        valueLabel.layer.shadowOpacity = 0.0
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        layer.shadowColor = UIColor.black.cgColor
    }
}

//Класс для диаграммы
class PositionPieChartView: UIView {
    private var segments: [(value: CGFloat, color: UIColor, icon: UIImage?)] = []
    private let iconSize: CGSize = CGSize(width: 24, height: 24)
    
    func setSegments(_ segments: [(value: CGFloat, color: UIColor, icon: UIImage?)]) {
        self.segments = segments
        setNeedsDisplay()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(ovalIn: bounds.insetBy(dx: 10, dy: 10)).cgPath
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 12
        layer.shadowOffset = .zero
        backgroundColor = .clear
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) * 0.4
        var startAngle: CGFloat = -.pi / 2
        
        // Рисуем тень
        context.setShadow(offset: CGSize(width: 2, height: 2), blur: 6, color: UIColor.black.withAlphaComponent(0.2).cgColor)
        
        // Рисуем сегменты
        for segment in segments {
            context.setFillColor(segment.color.cgColor)
            
            let endAngle = startAngle + 2 * .pi * (segment.value / 100)
            
            let path = UIBezierPath()
            path.move(to: center)
            path.addArc(withCenter: center, radius: radius,
                        startAngle: startAngle, endAngle: endAngle,
                        clockwise: true)
            path.close()
            path.fill()
            
            // Добавляем иконки
            if let icon = segment.icon {
                let iconAngle = startAngle + (endAngle - startAngle) / 2
                let iconPosition = CGPoint(
                    x: center.x + cos(iconAngle) * radius * 0.7,
                    y: center.y + sin(iconAngle) * radius * 0.7
                )
                
                icon.draw(in: CGRect(
                    origin: CGPoint(x: iconPosition.x - iconSize.width/2, y: iconPosition.y - iconSize.height/2),
                    size: iconSize
                ))
            }
            
            startAngle = endAngle
        }
    }
}

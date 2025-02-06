//
//  MatchesViewController.swift
//  DotaTracker
//
//  Created by Ilya Sidnev on 1/31/25.
//

import UIKit

// MARK: - Data Models
struct StratzResponse: Decodable {
    let data: StratzData?
    let errors: [APIError]?
}

struct APIError: Decodable {
    let message: String
}

struct StratzData: Decodable {
    let player: PlayerData?
    let constants: ConstantsData?
}

struct PlayerData: Decodable {
    let matches: [Match]?
}

struct Match: Decodable {
    let id: Int
    let direKills: [Int]
    let radiantKills: [Int]
    let actualRank: Int?
    let lobbyType: String
    let players: [PlayerMatchDetails]
    
}

struct PlayerMatchDetails: Decodable {
    let position: String?
    let kills: Int
    let deaths: Int
    let assists: Int
    let heroDamage: Int
    let towerDamage: Int
    let networth: Int
    let isRadiant: Bool
    let isVictory: Bool
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
    let hero: HeroInfo
}

struct HeroInfo: Decodable {
    let id: Int
}

struct ConstantsData: Decodable {
    let heroes: [Hero]?
    let items: [Item]?
}

struct Hero: Decodable {
    let id: Int
    let shortName: String
}

struct Item: Decodable {
    let id: Int
    let name: String
    let image: String?
}

// MARK: - Matches ViewController
class MatchesViewController: UIViewController {
    
    private var matches: [Match] = []
    private var heroes: [Int: Hero] = [:]
    private var items: [Int: Item] = [:]
        
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(MatchTableViewCell.self, forCellReuseIdentifier: "MatchCell")
        table.separatorStyle = .none
        table.backgroundColor = UIColor(named: "BackgroundPrimary")
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 300
        return table
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .large)
        ai.color = .white
        ai.hidesWhenStopped = true
        return ai
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "История матчей"
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    private func updateUI() {
        fetchAllData()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(named: "BackgroundPrimary")
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        activityIndicator.center = view.center
    }
    
    private func fetchAllData() {
        activityIndicator.startAnimating()
        let apiToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJTdWJqZWN0IjoiYTQ2YWRiNzYtZjMyZi00YzMxLWFkYzctMzkwNzcxYzVjN2UxIiwiU3RlYW1JZCI6IjExOTUxMzA4MzAiLCJuYmYiOjE3Mzg0NDczOTIsImV4cCI6MTc2OTk4MzM5MiwiaWF0IjoxNzM4NDQ3MzkyLCJpc3MiOiJodHRwczovL2FwaS5zdHJhdHouY29tIn0.ILE_4wzbsf72y-32fLZyOWp_-Vt0m8dfpBsgUsb4jRo"
        let steamID = UserDefaults.standard.string(forKey: "dotaId") ?? "0"
        print(steamID)
        let query = """
        {
            player(steamAccountId: \(steamID)) {
                matches(request: { 
                    take: 100, 
                    positionIds: [POSITION_1, POSITION_2, POSITION_3, POSITION_4, POSITION_5] 
                }) {
                    id
                    direKills
                    radiantKills
                    actualRank
                    lobbyType
                    players(steamAccountId: \(steamID)) {
                        position
                        kills
                        deaths
                        assists
                        heroDamage
                        towerDamage
                        networth
                        isRadiant
                        isVictory
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
                        hero { id }
                    }
                }
            }
            constants {
                heroes {
                    id
                    shortName
                }
                items {
                    id
                    name
                    image
                }
            }
        }
        """
        
        let url = URL(string: "https://api.stratz.com/graphql")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = ["query": query]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }
            
            if let error = error {
                self.showError(message: error.localizedDescription)
                return
            }
            
            guard let data = data else {
                self.showError(message: "No data received")
                return
            }
            
            do {
                
                let response = try JSONDecoder().decode(StratzResponse.self, from: data)
                
                if let errors = response.errors {
                    self.showError(message: errors.first?.message ?? "Unknown error")
                    return
                }
                
                // Обработка данных
                if let matches = response.data?.player?.matches {
                    self.matches = matches
                }
                
                if let heroes = response.data?.constants?.heroes {
                    self.heroes = Dictionary(uniqueKeysWithValues: heroes.map { ($0.id, $0) })
                }
                
                if let items = response.data?.constants?.items {
                    self.items = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            } catch {
                print(error.localizedDescription)
                self.showError(message: error.localizedDescription)
            }
        }.resume()
    }
    
    private func showError(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Error",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}

extension MatchesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matches.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MatchCell", for: indexPath) as! MatchTableViewCell
        cell.configure(
            match: matches[indexPath.row],
            heroes: heroes,
            items: items
        )
        return cell
    }
}

class MatchTableViewCell: UITableViewCell {
    
    // MARK: - UI Elements
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(named: "BackgroundSecondary")
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        //view.layer.borderColor = UIColor.systemGray3.cgColor
        return view
    }()
    
    private let heroImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 8
        iv.clipsToBounds = true
        iv.layer.borderWidth = 2
        //iv.layer.borderColor = UIColor.systemGray3.cgColor
        return iv
    }()
    
    private let roleIconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let resultBadge: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 14
        return view
    }()
    
    private let resultLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textAlignment = .center
        return label
    }()
    
    // Иконка среднего ранга перемещена между героем и результатом
    private let rankIconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let statsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 4
        return sv
    }()
    
    private let itemsContainer = ItemSlotsView()
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        contentView.backgroundColor = UIColor(named: "BackgroundPrimary")
        contentView.addSubview(containerView)
        
        containerView.addSubviews(
            heroImageView,
            roleIconView,
            rankIconView,
            resultBadge,
            statsStack,
            itemsContainer
        )
        
        resultBadge.addSubview(resultLabel)
        
        // Контейнер
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        // Изображение героя
        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heroImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            heroImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            heroImageView.widthAnchor.constraint(equalToConstant: 90),
            heroImageView.heightAnchor.constraint(equalToConstant: 70)
        ])
        
        // Иконка позиции (role)
        roleIconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            roleIconView.bottomAnchor.constraint(equalTo: heroImageView.bottomAnchor),
            roleIconView.trailingAnchor.constraint(equalTo: heroImageView.trailingAnchor),
            roleIconView.widthAnchor.constraint(equalToConstant: 24),
            roleIconView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Иконка среднего ранга располагается справа от героя
        rankIconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rankIconView.leadingAnchor.constraint(equalTo: heroImageView.trailingAnchor, constant: 8),
            rankIconView.centerYAnchor.constraint(equalTo: heroImageView.centerYAnchor),
            rankIconView.widthAnchor.constraint(equalToConstant: 75),
            rankIconView.heightAnchor.constraint(equalToConstant: 75)
        ])
        
        // Бейдж результата теперь справа от иконки ранга
        resultBadge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            resultBadge.leadingAnchor.constraint(equalTo: rankIconView.trailingAnchor, constant: 8),
            resultBadge.topAnchor.constraint(equalTo: heroImageView.topAnchor),
            resultBadge.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            resultBadge.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            resultLabel.leadingAnchor.constraint(equalTo: resultBadge.leadingAnchor, constant: 12),
            resultLabel.trailingAnchor.constraint(equalTo: resultBadge.trailingAnchor, constant: -12),
            resultLabel.centerYAnchor.constraint(equalTo: resultBadge.centerYAnchor)
        ])
        
        // Статистика
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statsStack.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: 12),
            statsStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            statsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12)
        ])
        
        // Контейнер предметов
        itemsContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            itemsContainer.topAnchor.constraint(equalTo: statsStack.bottomAnchor, constant: 12),
            itemsContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            itemsContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            itemsContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    // MARK: - Configuration
    func configure(match: Match, heroes: [Int: Hero], items: [Int: Item]) {
        configureHero(match: match, heroes: heroes)
        configureResult(match: match)
        configureRole(match: match)
        configureStats(match: match)
        configureItems(match: match, items: items)
        configureRank(match: match)
    }
    
    private func configureHero(match: Match, heroes: [Int: Hero]) {
        guard let player = match.players.first,
              let hero = heroes[player.hero.id],
              let url = URL(string: "https://cdn.cloudflare.steamstatic.com/apps/dota2/images/dota_react/heroes/\(hero.shortName).png")
        else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.heroImageView.image = image
            }
        }.resume()
    }
    
    private func caculateRadiantScore(match: Match, radiantKills: [Int])-> Int {
        guard !radiantKills.isEmpty else { return 0}
        var score: Int = 0
        for item in radiantKills {
            score += item
        }
        return score
    }
    
    private func calculateDireScore(match: Match, direKills: [Int])-> Int {
        guard !direKills.isEmpty else { return 0}
        var score: Int = 0
        for item in direKills {
            score += item
        }
        return score
    }
    
    private func configureResult(match: Match) {
        guard let player = match.players.first else { return }
        let radiantKills = caculateRadiantScore(match: match, radiantKills: match.radiantKills)
        let direKills = calculateDireScore(match: match, direKills: match.direKills)
        resultLabel.text = player.isVictory ? "\(radiantKills) ПОБЕДА \(direKills)" : "\(radiantKills) ПОРАЖЕНИЕ \(direKills)"
        resultBadge.backgroundColor = player.isVictory ? .systemGreen : .systemRed
        resultLabel.textColor = .white
    }
    
    private func configureRole(match: Match) {
        guard let position = match.players.first?.position else { return }
        let imageName: String
        switch position {
        case "POSITION_1": imageName = "position1"
        case "POSITION_2": imageName = "position2"
        case "POSITION_3": imageName = "position3"
        case "POSITION_4": imageName = "position4"
        case "POSITION_5": imageName = "position5"
        default: imageName = "default_position"
        }
        roleIconView.image = UIImage(named: imageName)
    }
    
    private func configureStats(match: Match) {
        statsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        guard let player = match.players.first else { return }
        
        let kdaView = StatView()
        kdaView.configure(
            title: "K/D/A",
            value: "\(player.kills)/\(player.deaths)/\(player.assists)"
        )
        
        let heroDamageView = StatView()
        heroDamageView.configure(
            title: "Hero Damage",
            value: player.heroDamage.formattedWithSeparator
        )
        
        let towerDamageView = StatView()
        towerDamageView.configure(
            title: "Tower Damage",
            value: player.towerDamage.formattedWithSeparator
        )
        
        let gpmView = StatView()
        gpmView.configure(
            title: "GPM",
            value: "\(player.goldPerMinute)"
        )
        
        let networthView = StatView()
        networthView.configure(
            title: "NetWorth",
            value: "\(player.networth)"
        )
        
        
        [kdaView, gpmView, networthView, heroDamageView, towerDamageView].forEach { statsStack.addArrangedSubview($0) }
    }
    
    private func configureItems(match: Match, items: [Int: Item]) {
        // Объединяем все 6 главных предметов в один массив
        let mainItems = [
            match.players.first?.item0Id,
            match.players.first?.item1Id,
            match.players.first?.item2Id,
            match.players.first?.item3Id,
            match.players.first?.item4Id,
            match.players.first?.item5Id
        ]
        itemsContainer.configure(
            mainItems: mainItems,
            backpack: [
                match.players.first?.backpack0Id,
                match.players.first?.backpack1Id,
                match.players.first?.backpack2Id
            ],
            neutral: match.players.first?.neutral0Id,
            items: items
        )
    }
    
    private func configureRank(match: Match) {
        guard let rank = match.actualRank else {
            rankIconView.isHidden = true
            return
        }
        rankIconView.isHidden = false
        let rankString = String(format: "%02d", rank)
        let division = Int(String(rankString.first ?? "0")) ?? 0
        let stars = Int(String(rankString.last ?? "0")) ?? 0
        rankIconView.image = UIImage(named: "SeasonalRank\(division)-\(stars)")
    }
}

// MARK: - ItemSlotsView
class ItemSlotsView: UIView {
    
    // Используем новую «высоту» ячейки, а ширина будет рассчитываться автоматически
    private let slotHeight: CGFloat = 60
    // Для нейтрального предмета оставляем фиксированный размер (при необходимости можно менять)
    private let neutralSlotSize: CGFloat = 50
    // Отступ между gridStack и нейтральным предметом
    private let horizontalSpacing: CGFloat = 8
    
    // Горизонтальные стеки для строк основных предметов и рюкзака
    private let mainRow1Stack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 4
        sv.distribution = .fillEqually
        return sv
    }()
    
    private let mainRow2Stack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 4
        sv.distribution = .fillEqually
        return sv
    }()
    
    private let backpackStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 4
        sv.distribution = .fillEqually
        return sv
    }()
    
    // Вертикальный стек для основной сетки (две строки основных предметов + ряд рюкзака)
    private let gridStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 8
        return sv
    }()
    
    // Нейтральный предмет – отдельный ImageView
    private let neutralItemView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 20
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(named: "BackgroundTertiary")
        iv.layer.borderWidth = 2
        iv.layer.borderColor = UIColor.systemYellow.cgColor
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // Создаем ячейки для первой строки (3 ячейки)
        for _ in 0..<3 {
            mainRow1Stack.addArrangedSubview(createItemSlot())
        }
        // Вторая строка (3 ячейки)
        for _ in 0..<3 {
            mainRow2Stack.addArrangedSubview(createItemSlot())
        }
        // Рюкзак (3 ячейки)
        for _ in 0..<3 {
            backpackStack.addArrangedSubview(createItemSlot())
        }
        
        // Собираем основную сетку в вертикальный стек
        gridStack.addArrangedSubview(mainRow1Stack)
        gridStack.addArrangedSubview(mainRow2Stack)
        gridStack.addArrangedSubview(backpackStack)
        
        // Добавляем основную сетку и нейтральный предмет как отдельные subview
        addSubview(gridStack)
        addSubview(neutralItemView)
        
        gridStack.translatesAutoresizingMaskIntoConstraints = false
        neutralItemView.translatesAutoresizingMaskIntoConstraints = false
        
        // Основной контейнер: gridStack занимает часть ширины, а нейтральный предмет – остальную.
        NSLayoutConstraint.activate([
            // Прикрепляем gridStack к левому краю
            gridStack.topAnchor.constraint(equalTo: topAnchor),
            gridStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            gridStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            // Правый край gridStack привязываем к левому краю нейтрального предмета с отступом
            gridStack.trailingAnchor.constraint(equalTo: neutralItemView.leadingAnchor, constant: -horizontalSpacing),
            
            // Нейтральный предмет: закрепляем за правым краем контейнера
            neutralItemView.trailingAnchor.constraint(equalTo: trailingAnchor),
            // Выравниваем по вертикали: верх нейтрального предмета совпадает с верхом первой строки
            neutralItemView.topAnchor.constraint(equalTo: mainRow1Stack.topAnchor),
            // Фиксированный размер для нейтрального предмета
            neutralItemView.widthAnchor.constraint(equalToConstant: neutralSlotSize),
            neutralItemView.heightAnchor.constraint(equalToConstant: neutralSlotSize)
        ])
    }
    
    /// Создаёт ячейку для предмета.
    /// Здесь мы НЕ задаём фиксированную ширину – она будет рассчитываться равномерно по ширине родительского UIStackView.
    private func createItemSlot() -> UIImageView {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = UIColor(named: "BackgroundTertiary")
        iv.layer.cornerRadius = 4
        iv.clipsToBounds = true
        
        iv.translatesAutoresizingMaskIntoConstraints = false
        // Фиксированная высота, ширина будет рассчитана автоматически за счёт fillEqually
        NSLayoutConstraint.activate([
            iv.heightAnchor.constraint(equalToConstant: slotHeight)
        ])
        return iv
    }
    
    /// Конфигурирует отображение предметов.
    /// - Parameters:
    ///   - mainItems: Массив из 6 основных предметов (первые 3 для первой строки, следующие 3 – для второй).
    ///   - backpack: Массив предметов рюкзака (3 предмета).
    ///   - neutral: Идентификатор нейтрального предмета.
    ///   - items: Словарь всех предметов для получения картинки по id.
    func configure(mainItems: [Int?], backpack: [Int?], neutral: Int?, items: [Int: Item]) {
        // Основные предметы: первые 3 слота первой строки, следующие 3 – второй строки
        for (index, itemId) in mainItems.enumerated() {
            let targetView: UIImageView?
            if index < 3 {
                targetView = mainRow1Stack.arrangedSubviews[index] as? UIImageView
            } else {
                targetView = mainRow2Stack.arrangedSubviews[index - 3] as? UIImageView
            }
            if let targetView = targetView {
                configureItemView(targetView, itemId: itemId, items: items)
            }
        }
        
        // Предметы рюкзака
        for (index, itemId) in backpack.enumerated() {
            if let targetView = backpackStack.arrangedSubviews[index] as? UIImageView {
                configureItemView(targetView, itemId: itemId, items: items)
            }
        }
        
        // Нейтральный предмет
        configureItemView(neutralItemView, itemId: neutral, items: items)
    }
    
    /// Загрузка и установка изображения для конкретного слота
    private func configureItemView(_ view: UIImageView, itemId: Int?, items: [Int: Item]) {
        guard let itemId = itemId,
              let item = items[itemId],
              let imageUrl = item.image?.split(separator: "?").first?.replacingOccurrences(of: "_lg", with: "")
        else {
            view.image = nil
            return
        }
        
        let urlString = "https://cdn.stratz.com/images/dota2/items/\(imageUrl)"
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                view.image = image
            }
        }.resume()
    }
}


// MARK: - StatView
class StatView: UIView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        return label
    }()
    
    init() {
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }
}

// MARK: - Extensions
extension UIView {
    func addSubviews(_ views: UIView...) {
        views.forEach { addSubview($0) }
    }
}

extension Int {
    var formattedWithSeparator: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}

//
//  ViewControllerForMVC.swift
//  MVCSample
//
//  Created by Yasuyuki Someya on 2021/02/20.
//

import UIKit
import SafariServices

class ViewControllerForMVC: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    private let model = Model()

    /// データの取得状態
    enum Status {
        case loading
        case loaded
        case error(String)
    }
    private var status: Status? {
        didSet {
            guard let status = status else {
                return
            }
            didChange(status: status)
        }
    }
    struct ViewItem {
        let title: String
        let link: String
        let source: String
        let pubDate: String?
    }
    private var viewItems = [ViewItem]()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        // 引っ張って更新
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)

        load()
    }
}

// MARK: - UITableViewの処理群
extension ViewControllerForMVC: UITableViewDataSource, UITableViewDelegate {
    ///　行数を返す
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewItems.count
    }

    ///　cellを返す
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "TableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        let item = viewItems[indexPath.row]
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = "[\(item.source)] \(item.pubDate ?? "")"
        return cell
    }

    ///　cellの選択時
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let url = URL(string: viewItems[indexPath.row].link) else {
            return
        }
        let safariVC = SFSafariViewController.init(url: url)
        safariVC.dismissButtonStyle = .close
        self.present(safariVC, animated: true, completion: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Action
extension ViewControllerForMVC {
    /// UITableViewを引っ張って更新
    @objc func refresh(sender: UIRefreshControl) {
        load()
    }
}

// MARK: - Custom Method
extension ViewControllerForMVC {
    /// データ取得
    private func load() {
        status = .loading
        model.retrieveItems(for: .all) { [weak self] (result) in
            switch result {
            case .success(let items):
                self?.viewItems = items.map({ (article) -> ViewItem in
                    return ViewItem(title: article.title,
                                    link: article.link,
                                    source: article.source,
                                    pubDate: self?.format(for: article.pubDate))
                })
                self?.status = .loaded
            case .failure(let error):
                self?.status = .error("エラー: \(error.localizedDescription)")
            }
        }
    }
    
    /// ステータスが変化した時の処理
    private func didChange(status: Status) {
        switch status {
        case .loading:
            tableView.refreshControl?.beginRefreshing()
            tableView.reloadData()
        case .loaded:
            DispatchQueue.main.async { [weak self] in
                self?.tableView.refreshControl?.endRefreshing()
                self?.tableView.reloadData()
            }
        case .error(let message):
            DispatchQueue.main.async { [weak self] in
                self?.tableView.refreshControl?.endRefreshing()
            }
            print("\(message)")
        }
    }
    
    /// Dateから表示用文字列を編集する
    private func format(for date: Date?) -> String? {
        guard let date = date else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}

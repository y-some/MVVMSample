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

    // MARK: 以下の変数はMVVMではViewModelに定義されている
    // データの取得状態
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
    // 現在のフィルター状態を保持
    private var filterType: FilterType = .none
    // 表示用データオブジェクト
    struct ViewItem {
        let title: String
        let link: String
        let source: String
        let pubDate: String?
    }
    private var viewItems = [ViewItem]()

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.rowHeight = UITableView.automaticDimension
        // 引っ張って更新
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)

        filterType = .none
        load()
    }
}

// MARK: - UITableViewの処理群
extension ViewControllerForMVC: UITableViewDataSource, UITableViewDelegate {
    ///　行数を返す
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch status {
        case .error:
            return 1
        default:
            return viewItems.count
        }
    }

    ///　cellを返す
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "TableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        switch status {
        case .error(let message):
            cell.textLabel?.text = message
            cell.detailTextLabel?.text = nil
            return cell
        default:
            let item = viewItems[indexPath.row]
            cell.textLabel?.text = item.title
            cell.detailTextLabel?.text = "[\(item.source)] \(item.pubDate ?? "")"
            return cell
        }
    }

    ///　cellの選択時
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < viewItems.count,
              let url = URL(string: viewItems[indexPath.row].link) else {
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
    /// フィルタボタンtap
    @IBAction func tappedFilterButton(_ sender: Any) {
        showActionSheet()
    }

    /// ActionSheet生成
    private func showActionSheet() {
        let actionSheet = UIAlertController(title: "トピック", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        for filterType in FilterType.allCases {
            let action = UIAlertAction(title: filterType.title, style: UIAlertAction.Style.default) { [weak self] _ in
                self?.filterType = filterType
                self?.load()
            }
            actionSheet.addAction(action)
        }
        let close = UIAlertAction(title: "閉じる", style: UIAlertAction.Style.destructive) { _ in }
        actionSheet.addAction(close)
        present(actionSheet, animated: true, completion: nil)
    }

    /// UITableViewを引っ張って更新
    @objc func refresh(sender: UIRefreshControl) {
        load()
    }

    /// refreshControlを表示する
    private func beginRefreshing() {
        guard let refreshControl = tableView.refreshControl else { return }
        tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - refreshControl.frame.height), animated: true)
        refreshControl.beginRefreshing()
    }
}

// MARK: - 状態制御
extension ViewControllerForMVC {
    /// ステータスが変化した時の処理
    private func didChange(status: Status) {
        switch status {
        case .loading:
            beginRefreshing()
        case .loaded, .error:
            DispatchQueue.main.async { [weak self] in
                self?.title = self?.filterType.title
                self?.tableView.refreshControl?.endRefreshing()
                self?.tableView.reloadSections(IndexSet([0]), with: .fade)
            }
        }
    }
}

// MARK: - ビジネスロジック（以下のメソッドはMVVMではViewModelに定義されている）
extension ViewControllerForMVC {
    /// データ取得
    private func load() {
        status = .loading
        model.retrieveItems(for: filterType) { [weak self] (result) in
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


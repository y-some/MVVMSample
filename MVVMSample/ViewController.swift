//
//  ViewController.swift
//  MVVMSample
//
//  Created by Yasuyuki Someya on 2020/10/17.
//

import UIKit
import SafariServices

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    private let viewModel = ViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        // 引っ張って更新
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)

        viewModel.delegate = self
        viewModel.load()
    }
}

// MARK: - UITableViewの処理群
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    ///　行数を返す
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.viewItems.count
    }

    ///　cellを返す
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "TableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        let item = viewModel.viewItems[indexPath.row]
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = "[\(item.source)] \(item.pubDate ?? "")"
        return cell
    }

    ///　cellの選択時
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let url = URL(string: viewModel.viewItems[indexPath.row].link) else {
            return
        }
        let safariVC = SFSafariViewController.init(url: url)
        safariVC.dismissButtonStyle = .close
        self.present(safariVC, animated: true, completion: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - ViewModelDelegate
extension ViewController: ViewModelDelegate {
    /// ViewModelのステータスが変化した時の処理
    func didChange(status: Status) {
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
}

// MARK: - Action
extension ViewController {
    /// UITableViewを引っ張って更新
    @objc func refresh(sender: UIRefreshControl) {
        viewModel.load()
    }
}

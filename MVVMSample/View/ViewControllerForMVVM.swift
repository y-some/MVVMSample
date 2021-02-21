//
//  ViewControllerForMVVM.swift
//  MVVMSample
//
//  Created by Yasuyuki Someya on 2020/10/17.
//

import UIKit
import SafariServices

class ViewControllerForMVVM: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    private let viewModel = ViewModel()
    
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

        viewModel.delegate = self
        viewModel.load(for: .none)
    }
}

// MARK: - UITableViewの処理群
extension ViewControllerForMVVM: UITableViewDataSource, UITableViewDelegate {
    ///　行数を返す
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch viewModel.status {
        case .error:
            return 1
        default:
            return viewModel.viewItems.count
        }
    }

    ///　cellを返す
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "TableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        switch viewModel.status {
        case .error(let message):
            cell.textLabel?.text = message
            cell.detailTextLabel?.text = nil
            return cell
        default:
            let item = viewModel.viewItems[indexPath.row]
            cell.textLabel?.text = item.title
            cell.detailTextLabel?.text = "[\(item.source)] \(item.pubDate ?? "")"
            return cell
        }
    }

    ///　cellの選択時
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < viewModel.viewItems.count,
              let url = URL(string: viewModel.viewItems[indexPath.row].link) else {
            return
        }
        let safariVC = SFSafariViewController.init(url: url)
        safariVC.dismissButtonStyle = .close
        self.present(safariVC, animated: true, completion: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Action
extension ViewControllerForMVVM {
    /// フィルタボタンtap
    @IBAction func tappedFilterButton(_ sender: Any) {
        showActionSheet()
    }

    /// ActionSheet生成
    private func showActionSheet() {
        let actionSheet = UIAlertController(title: "トピック", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        for filterType in FilterType.allCases {
            let action = UIAlertAction(title: filterType.title, style: UIAlertAction.Style.default) { [weak self] _ in
                self?.viewModel.load(for: filterType)
            }
            actionSheet.addAction(action)
        }
        let close = UIAlertAction(title: "閉じる", style: UIAlertAction.Style.destructive) { _ in }
        actionSheet.addAction(close)
        present(actionSheet, animated: true, completion: nil)
    }
    
    /// UITableViewを引っ張って更新
    @objc func refresh(sender: UIRefreshControl) {
        viewModel.reload()
    }
    
    /// refreshControlを表示する
    private func beginRefreshing() {
        guard let refreshControl = tableView.refreshControl else { return }
        tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - refreshControl.frame.height), animated: true)
        refreshControl.beginRefreshing()
    }
}

// MARK: - ViewModelDelegate
extension ViewControllerForMVVM: ViewModelDelegate {
    /// ViewModelのステータスが変化した時の処理
    func didChange(status: Status) {
        switch status {
        case .loading:
            beginRefreshing()
        case .loaded, .error:
            DispatchQueue.main.async { [weak self] in
                self?.title = self?.viewModel.filterType.title
                self?.tableView.refreshControl?.endRefreshing()
                self?.tableView.reloadSections(IndexSet([0]), with: .fade)
            }
        }
    }
}

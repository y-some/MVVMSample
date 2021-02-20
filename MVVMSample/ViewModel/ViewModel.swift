//
//  ViewModel.swift
//  MVVMSample
//
//  Created by Yasuyuki Someya on 2020/10/17.
//

import Foundation

/// Viewにデータの取得状態が変化したことを通知するためのProtocol
protocol ViewModelDelegate: AnyObject {
    func didChange(status: Status)
}

/// データの取得状態
enum Status {
    case loading
    case loaded
    case error(String)
}

/// ViewとModelの間の情報の伝達と、Viewのための状態を保持する役割
class ViewModel {
    // Viewに提供するオブジェクト
    struct ViewItem {
        let title: String
        let link: String
        let source: String
        let pubDate: String?
    }
    private(set) var viewItems = [ViewItem]()

    // 取得状態を扱うオブジェクト
    weak var delegate: ViewModelDelegate?
    private(set) var status: Status? {
        didSet {
            // 随所でdelegate.didChange(:status)を呼び出すとモレる可能性があるのでdidSetにて行う
            guard let status = status else {
                return
            }
            delegate?.didChange(status: status)
        }
    }

    // テストのためにModelクラスをDIする
    private let model: ModelProtocol
    init(model: ModelProtocol = Model()) {
        self.model = model
    }

    /// データ取得
    func load() {
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
}

// MARK: - ユーティリティ関数
extension ViewModel {
    /// Dateから表示用文字列を編集する
    func format(for date: Date?) -> String? {
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

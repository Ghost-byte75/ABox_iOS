import UIKit

class LogCell: QMUITableViewCell {
    
    let contentLabel = UILabel()

    override init!(for tableView: UITableView!, with style: UITableViewCell.CellStyle, reuseIdentifier: String) {
        super.init(for: tableView, with: style, reuseIdentifier: reuseIdentifier)
        initSubviews()
    }
    
    override init!(for tableView: UITableView!, withReuseIdentifier reuseIdentifier: String) {
        super.init(for: tableView, withReuseIdentifier: reuseIdentifier)
        initSubviews()
        
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func cellHeight(text: String, cellWidth: CGFloat) -> CGFloat {
        return UITableViewCell.cellHeight(text: text, width: cellWidth, lineHiehgt: 15, font: UIFont.regular(aSize: 12)) + 4
    }
    
    static func cellIdentifier() -> String {
        return "logCell"
    }
    
    func initSubviews() {
        self.backgroundColor = .clear
        self.selectionStyle = .none
        contentLabel.font = UIFont.regular(aSize: 12)
        contentLabel.textColor = .white
        contentLabel.numberOfLines = 0
        contentLabel.qmui_lineHeight = 15
        contentLabel.adjustsFontSizeToFitWidth = true
        self.contentView.addSubview(contentLabel)
    }
    
    override func layoutSubviews() {
        contentLabel.snp.makeConstraints { make in
            make.top.bottom.equalTo(0)
            make.left.equalTo(10)
            make.right.equalTo(-10)
        }
    }

}

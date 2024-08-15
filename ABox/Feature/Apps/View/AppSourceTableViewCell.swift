import UIKit

class AppSourceTableViewCell: QMUITableViewCell {
    
    let iconView = UIImageView()
    let nameLabel = UILabel()
    let sourceLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initSubviews() {
        self.selectionStyle = .none
        self.backgroundColor = .white
        self.accessoryType = .disclosureIndicator
        
        self.contentView.addSubview(iconView)
        
        nameLabel.font = UIFont.regular(aSize: 14.5)
        nameLabel.textColor = kTextColor
        self.contentView.addSubview(nameLabel)
        
        sourceLabel.font = UIFont.light(aSize: 12.5)
        sourceLabel.textColor = kSubtextColor
        self.contentView.addSubview(sourceLabel)
        
    }
    
    static func cellIdentifier() -> String {
        return "appSourceTableViewCell"
    }
    
    func configCell(_ model: AppSourceModel) {
        self.nameLabel.text = model.name
        self.sourceLabel.text = model.sourceURL
        self.iconView.ab_setImage(withURLString: model.sourceicon)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        iconView.snp.makeConstraints { maker in
            maker.width.height.equalTo(35)
            maker.left.equalTo(10)
            maker.centerY.equalTo(self.contentView)
        }
        
        nameLabel.snp.makeConstraints { maker in
            maker.left.equalTo(iconView.snp.right).offset(10)
            maker.bottom.equalTo(self.contentView.snp.centerY)
            maker.right.equalTo(-70)
            maker.height.equalTo(20)
        }
        
        sourceLabel.snp.makeConstraints { maker in
            maker.left.equalTo(nameLabel)
            maker.top.equalTo(nameLabel.snp.bottom)
            maker.right.equalTo(nameLabel)
            maker.height.equalTo(nameLabel)
        }
    }

}

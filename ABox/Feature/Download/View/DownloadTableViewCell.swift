import UIKit
import Material
import Async

class DownloadTableViewCell: QMUITableViewCell {
    
    let fileIconView = UIImageView()
    let fileNameLabel = UILabel()
    let fileSizeLabel = UILabel()
    let downloadURLLabel = UILabel()
    let stateLabel = UILabel()
    let button = Button()
    let timeLabel = UILabel()
    let progressInfoLabel = UILabel()
    let progressView = M13ProgressViewBorderedBar()
    let line = UIView()
    var downloadTask = DownloadTask()
    var openFileURLHandle:((DownloadTask) -> ())?
    
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configCell(_ task: DownloadTask) {
        self.downloadTask = task
        if let appSource = task.info.appSource {
            self.downloadURLLabel.text = "来自：\(appSource)"
        } else {
            self.downloadURLLabel.text = "来自：\(task.info.downloadURL)"
        }
        
        self.configFileIcon(fileType: task.info.filetype)
        self.timeLabel.text = task.info.createDate
        if let filename = task.info.filename {
            self.fileNameLabel.text = filename
        } else {
            self.fileNameLabel.text = "file"
        }
        self.fileSizeLabel.text = task.info.filesize
        self.configCellDownloadState()
        task.downloadStateHandle = { [weak self] state in
            self?.downloadTask.info.state = state
            self?.configCellDownloadState()
        }
        
        self.configCellProgress()
        task.downloadProgressHandle = { [weak self] progress in
            self?.downloadTask.downloadProgress = progress
            self?.configCellProgress()
        }
        
        task.downloadFinishHandle = { info in
            self.fileNameLabel.text = info.filename
            self.fileSizeLabel.text = info.filesize
            self.configFileIcon(fileType: info.filetype)
        }
    }

    func configFileIcon(fileType: String) {
        if let image = UIImage(named: fileType) {
            self.fileIconView.image = image.resize(toHeight: 100)
        } else {
            if wordTypes.contains(fileType) {
                self.fileIconView.image = UIImage(named: "word")?.resize(toHeight: 100)
            } else if excelTypes.contains(fileType) {
                self.fileIconView.image = UIImage(named: "excel")?.resize(toHeight: 100)
            } else if pptTypes.contains(fileType) {
                self.fileIconView.image = UIImage(named: "ppt")?.resize(toHeight: 100)
            } else {
                self.fileIconView.image = UIImage(named: "unknown")?.resize(toHeight: 100)
            }
        }
    }
    
    func configCellProgress() {
        self.progressView.setProgress(CGFloat(self.downloadTask.downloadProgress.fractionCompleted), animated: true)
        self.progressInfoLabel.text = String(format: "%0.0f%%", self.downloadTask.downloadProgress.fractionCompleted * 100)
        let totalUnitCount = Float(self.downloadTask.downloadProgress.totalUnitCount)
        if totalUnitCount > 0 {
            self.downloadTask.info.filesize = String.fileSizeDesc(Int(totalUnitCount))
            self.fileSizeLabel.text = self.downloadTask.info.filesize
        }
    }
    
    func configCellDownloadState() {
        print(message: "DownloadTaskState:\(self.downloadTask.info.state)")
        switch self.downloadTask.info.state {
        case .downloading:
            self.stateLabel.text = "正在下载"
            button.setTitle("暂停", for: .normal)
            if self.progressView.isHidden {
                self.progressView.isHidden = false
                progressInfoLabel.isHidden = self.progressView.isHidden
            }
            break
        case .paused:
            self.stateLabel.text = "暂停下载"
            button.setTitle("开始", for: .normal)
            if self.progressView.isHidden {
                self.progressView.isHidden = false
                progressInfoLabel.isHidden = self.progressView.isHidden
            }
            break
        case .cancelled:
            self.stateLabel.text = "已取消"
            button.setTitle("重新下载", for: .normal)
            if self.progressView.isHidden == false {
                self.progressView.isHidden = true
                progressInfoLabel.isHidden = self.progressView.isHidden
            }
            break
        case .finished:
            self.stateLabel.text = "已完成"
            button.setTitle("打开", for: .normal)
            if self.progressView.isHidden == false {
                self.progressView.isHidden = true
                progressInfoLabel.isHidden = self.progressView.isHidden
            }
            break
        case .error:
            self.stateLabel.text = "下载错误"
            button.setTitle("重新下载", for: .normal)
            if self.progressView.isHidden == false {
                self.progressView.isHidden = true
                progressInfoLabel.isHidden = self.progressView.isHidden
            }
            break
        case .deleted:
            self.stateLabel.text = "已删除"
            button.setTitle("重新下载", for: .normal)
            if self.progressView.isHidden == false {
                self.progressView.isHidden = true
                progressInfoLabel.isHidden = self.progressView.isHidden
            }
            break
        }
    }
    
    @objc
    func buttonTapped() {
        switch downloadTask.info.state {
        case .downloading:
            self.downloadTask.suspendTask()
            break
        case .paused:
            self.downloadTask.resumeTask()
            break
        case .finished:
            self.openFileURLHandle?(self.downloadTask)
            break
        default:
            self.downloadTask.restartTask()
            break
        }
    }
    
    func initSubviews() {
        self.selectionStyle = .none
        self.backgroundColor = .white
        
        button.layer.cornerRadius = 12.5
        button.layer.masksToBounds = true
        button.layer.borderWidth = 1.5
        button.layer.borderColor = kButtonColor.cgColor
        button.setTitle("打开", for: .normal)
        button.titleLabel?.font = UIFont.regular(aSize: 11)
        button.setTitleColor(kButtonColor, for: .normal)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        self.contentView.addSubview(button)

        
        self.contentView.addSubview(fileIconView)
        
        fileNameLabel.font = UIFont.medium(aSize: 13)
        fileNameLabel.textColor = kTextColor
        self.contentView.addSubview(fileNameLabel)
        
        fileSizeLabel.adjustsFontSizeToFitWidth = true
        fileSizeLabel.textAlignment = .center
        fileSizeLabel.layer.cornerRadius = 5
        fileSizeLabel.layer.borderColor = kRGBColor(231, 231, 231).cgColor
        fileSizeLabel.layer.borderWidth = 0.5
        fileSizeLabel.font = UIFont.regular(aSize: 11)
        fileSizeLabel.textColor = kSubtextColor
        self.contentView.addSubview(fileSizeLabel)
        
        downloadURLLabel.font = UIFont.regular(aSize: 10)
        downloadURLLabel.textColor = kSubtextColor
        self.contentView.addSubview(downloadURLLabel)
        
        stateLabel.font = UIFont.regular(aSize: 12)
        stateLabel.textColor = kSubtextColor
        self.contentView.addSubview(stateLabel)
        
        progressInfoLabel.isHidden = true
        progressInfoLabel.font = UIFont.regular(aSize: 10)
        progressInfoLabel.textColor = kButtonColor
        self.contentView.addSubview(progressInfoLabel)
        
        progressView.isHidden = true
        progressView.cornerRadius = 5
        progressView.tintColor = kButtonColor
        self.contentView.addSubview(progressView)
        
        timeLabel.font = UIFont.regular(aSize: 11)
        timeLabel.textColor = kSubtextColor
        self.contentView.addSubview(timeLabel)
        
        line.backgroundColor = kSeparatorColor
        self.contentView.addSubview(line)

    }
    
    override func layoutSubviews() {
        
        button.snp.makeConstraints { maker in
            maker.height.equalTo(25)
            maker.width.equalTo(50)
            maker.right.equalTo(-15)
            maker.centerY.equalTo(self.contentView)
        }
        
        fileIconView.snp.makeConstraints { maker in
            maker.left.equalTo(10)
            maker.centerY.equalTo(self.contentView)
            maker.width.height.equalTo(50)
        }
        
        fileNameLabel.snp.makeConstraints { maker in
            maker.left.equalTo(fileIconView.snp.right).offset(10)
            maker.top.equalTo(5)
            maker.right.equalTo(button.snp.left).offset(-15)
            maker.height.equalTo(20)
        }
        
        fileSizeLabel.snp.makeConstraints { maker in
            maker.left.equalTo(fileNameLabel)
            maker.top.equalTo(fileNameLabel.snp.bottom).offset(5)
            maker.width.equalTo(50)
            maker.height.equalTo(20)
        }
        
        downloadURLLabel.snp.makeConstraints { maker in
            maker.left.equalTo(fileSizeLabel.snp.right).offset(5)
            maker.top.equalTo(fileSizeLabel)
            maker.right.equalTo(fileNameLabel)
            maker.height.equalTo(20)
        }
        
        stateLabel.snp.makeConstraints { maker in
            maker.left.equalTo(fileNameLabel)
            maker.top.equalTo(fileSizeLabel.snp.bottom)
            maker.width.equalTo(fileSizeLabel)
            maker.height.equalTo(fileSizeLabel)
        }
        
        progressInfoLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(stateLabel)
            maker.width.equalTo(25)
            maker.right.equalTo(fileNameLabel)
            maker.height.equalTo(15)
        }

        progressView.snp.makeConstraints { maker in
            maker.centerY.equalTo(stateLabel)
            maker.left.equalTo(stateLabel.snp.right).offset(5)
            maker.right.equalTo(progressInfoLabel.snp.left).offset(-5)
            maker.height.equalTo(10)
        }
        
        timeLabel.snp.makeConstraints { maker in
            maker.left.equalTo(fileNameLabel)
            maker.top.equalTo(stateLabel.snp.bottom)
            maker.width.equalTo(fileNameLabel)
            maker.height.equalTo(15)
        }
        
        line.snp.makeConstraints { maker in
            maker.left.right.bottom.equalTo(0)
            maker.height.equalTo(0.6)
        }
    }
}

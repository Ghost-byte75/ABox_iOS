import UIKit

class TextViewController: ViewController {
    
    let textView = QMUITextView()
    var text = ""

    init(text: String) {
        self.init()
        self.text = text
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func initSubviews() {
        super.initSubviews()
        self.view.backgroundColor = .black
        textView.textColor = .white
        textView.backgroundColor = .black
        textView.text = text
        textView.isEditable = false
        self.view.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.top.equalTo(self.qmui_navigationBarMaxYInViewCoordinator)
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(kUI_IPHONEX ? -34 : 0)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
}

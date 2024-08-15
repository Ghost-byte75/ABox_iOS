import UIKit

class EmptyDataSet: NSObject, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var text: String?
    var descriptionString: String?
    var image: UIImage?
    var emptyDataSet: EmptyDataSet?
    var offset: CGFloat = 0.0

    func emptyViewWithScrollView(scrollView: UIScrollView, text: String?, descriptionString: String?, image: UIImage?) {
        self.emptyDataSet = self
        self.text = text
        self.image = image
        self.descriptionString = descriptionString
        scrollView.emptyDataSetDelegate = self.emptyDataSet
        scrollView.emptyDataSetSource = self.emptyDataSet
    }

    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var text = "暂无数据"
        if let t = self.text {
            text = t
        }
        let attributes = [NSAttributedString.Key.foregroundColor : kRGBColor(96, 96, 96), NSAttributedString.Key.font: UIFont.medium(aSize: 14)]
        return NSAttributedString(string: text, attributes: attributes)
    }

    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var text = ""
        if let t = self.descriptionString {
            text = t
        }
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: CGFloat(12.0)), NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        return NSAttributedString(string: text, attributes: attributes)
    }

    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        var image = UIImage.imageWithColor(color: UIColor.clear)
        if let img = self.image {
            image = img
        }
        return image
    }

    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return self.offset
    }
}

private var emptyDataKey = 0

extension UIScrollView {
    
    var emptySet: EmptyDataSet? {
        get {
            let result = objc_getAssociatedObject(self, &emptyDataKey) as? EmptyDataSet
            if result == nil {
                return EmptyDataSet()
            }
            return result!
        }
        set {
            objc_setAssociatedObject(self, &emptyDataKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }

    func setDefaultEmptyDataSet() {
        self.emptySet = EmptyDataSet()
        self.emptyDataSetSource = emptySet
        self.emptyDataSetDelegate = emptySet
    }

    func setEmptyDataSet(title: String?, descriptionString: String?, image: UIImage?) {
        self.emptySet = EmptyDataSet()
        self.emptySet?.emptyViewWithScrollView(scrollView: self, text: title, descriptionString: descriptionString, image: image)
        self.emptyDataSetSource = emptySet
        self.emptyDataSetDelegate = emptySet
    }

    func setEmptyDataSet(title: String?, descriptionString: String?, image: UIImage?, offset: CGFloat) {
        self.emptySet = EmptyDataSet()
        self.emptySet?.emptyViewWithScrollView(scrollView: self, text: title, descriptionString: descriptionString, image: image)
        self.emptySet?.offset = offset
        self.emptyDataSetSource = emptySet
        self.emptyDataSetDelegate = emptySet
    }
    
}

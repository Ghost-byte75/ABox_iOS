import Foundation

extension UIImageView {
    
    func ab_setImage(withURLString urlString: String, placeholderImage: UIImage? = nil) {
        if let url = URL(string: urlString) {
            self.ab_setImage(withURL: url, placeholderImage: placeholderImage)
        } else {
            self.image = placeholderImage
        }
    }
    
    func ab_setImage(withURL url: URL, placeholderImage: UIImage? = nil) {
        let cacheImagePath = FileManager.default.appIconsDirectory.appendingPathComponent(url.lastPathComponent).path
        if let cacheImage = UIImage(contentsOfFile: cacheImagePath) {
            self.image = cacheImage
        } else {
            self.af.setImage(withURLRequest: API.httpURLRequest(url: url), placeholderImage: placeholderImage, runImageTransitionIfCached: true, completion: { dataResponse in
                if let pngData = dataResponse.value?.pngData() {
                    guard FileManager.default.fileExists(atPath: cacheImagePath) else {
                        FileManager.default.createFile(atPath: cacheImagePath, contents: pngData, attributes: nil)
                        return
                    }
                }
            })
        }
    }
    
}

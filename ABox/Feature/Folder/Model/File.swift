import UIKit

class File: NSObject {
    
    var select = false
    var name = ""
    var url: URL = URL(fileURLWithPath: ".")
    var size = 0
    var sizeDesc = ""
    var isFolder = false
    var type = ""
    // 当类型为文件夹时，文件夹内的文件数量
    var fileCount = 0
    var modificationDate: Date?
    var creationDate: Date?
    var isAppBundle = false
    
    var isArchiver: Bool {
        return archiverTypes.contains(self.type)
    }

    var isCertificate: Bool {
        return self.type == "p12"
    }
    
    var isMobileProvision: Bool {
        return self.type == "mobileprovision"
    }
    
    var isCode: Bool {
        return codeTypes.contains(self.type)
    }
    
    var isDylib: Bool {
        return self.type == "dylib"
    }
    
    var isFramework: Bool {
        return self.isFolder && self.url.pathExtension.lowercased() == "framework"
    }
    
    var isIPA: Bool {
        return self.type == "ipa"
    }
    
    var isTIPA: Bool {
        return self.type == "tipa"
    }
    
    var isWord: Bool {
        return wordTypes.contains(self.type)
    }
    
    var isExcel: Bool {
        return excelTypes.contains(self.type)
    }
    
    var isPPT: Bool {
        return pptTypes.contains(self.type)
    }

    var isImage: Bool {
        return imageTypes.contains(self.type)
    }
    
    var isPlist: Bool {
        return self.type == "plist"
    }
    
    var isZip: Bool {
        return self.type == "zip"
    }
    
    var isDeb: Bool {
        return self.type == "deb"
    }
    
    convenience init(fileURL: URL) {
        self.init()
        self.url = fileURL
        self.name = fileURL.lastPathComponent
        
        

        do {
//            let permissions: [FileAttributeKey : Any] = [ .posixPermissions: 0o644 ] // 权限设置为 755，也可以根据需要设置其他权限
//            try FileManager.default.setAttributes(permissions, ofItemAtPath: fileURL.path)
//            print(message: "设置权限0755")
            //AppSigner().setFilePosixPermissions(fileURL)
            //print(message: "fileURL.pathExtension:\(fileURL.pathExtension.lowercased())")
    
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
//            print(message: "\(self.name): \(fileAttributes)")
            if let fileSize:NSNumber = fileAttributes[FileAttributeKey.size] as! NSNumber? {
                self.size = fileSize.intValue
                sizeDesc = String.fileSizeDesc(self.size)
            }
            if let modificationDate = fileAttributes[FileAttributeKey.modificationDate] {
                self.modificationDate = modificationDate as? Date
            }
            
            if let creationDate = fileAttributes[FileAttributeKey.creationDate] {
                self.creationDate = creationDate as? Date
            }
        } catch let error as NSError {
            print("Error setting file permissions: \(error)")
            print("Get attributes errer: \(error)")
        }
        var isDir: ObjCBool = false
        let exists: Bool = FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir)
        if exists && isDir.boolValue {
            self.isFolder = true
        } else {
            self.isFolder = false
            self.type = fileURL.pathExtension.lowercased()
        }        

        if self.isFolder && self.url.pathExtension.lowercased() == "app" {
            let altApplication = ABApplication.init(fileURL: self.url)
            self.isAppBundle = altApplication == nil ? false: true
        } else {
            self.isAppBundle = false
        }
    }
    
    func getFileThumbnails() -> UIImage? {
        var thumbnails: UIImage?
        
        if self.isImage {
            thumbnails = UIImage.init(contentsOfFile: self.url.path)
        }
        
        if thumbnails == nil {
            if let image = UIImage(named: self.type) {
                thumbnails = image
            }
        }
        
        if thumbnails == nil {
            if self.isWord {
                thumbnails = UIImage(named: "word")
            } else if self.isExcel {
                thumbnails = UIImage(named: "excel")
            } else if self.isPPT {
                thumbnails = UIImage(named: "ppt")
            } else if self.isCode {
                thumbnails = UIImage(named: "code")
            } else if self.isArchiver {
                thumbnails = UIImage(named: "archive")
            }
        }
    
        if thumbnails == nil {
            thumbnails = UIImage(named: "unknown")
        }
        
        return thumbnails!.resize(toWidth: 40)
    }
}

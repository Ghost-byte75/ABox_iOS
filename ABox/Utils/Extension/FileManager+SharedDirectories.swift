import Foundation

public extension FileManager {
    
    var documentDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    var cacheDirectory: URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    var importFileDirectory: URL {
        return self.documentDirectory.appendingPathComponent("导入的文件", isDirectory: true)
    }


    var appLibraryDirectory: URL {
        return self.documentDirectory.appendingPathComponent(".AppLibrary", isDirectory: true)
    }
    
    
    var downloadDirectory: URL {
        return self.documentDirectory.appendingPathComponent("下载项", isDirectory: true)
    }
    
    var exportCertDirectory: URL {
        return self.documentDirectory.appendingPathComponent("导出的证书", isDirectory: true)
    }

    var recycleBinDirectory: URL {
        return self.cacheDirectory.appendingPathComponent(".MyRecycle", isDirectory: true)
    }
    
    var unzipIPADirectory: URL {
        return self.cacheDirectory.appendingPathComponent(".UnzipIPA", isDirectory: true)
    }

    var dylibDirectory: URL {
        return self.documentDirectory.appendingPathComponent("Dylibs", isDirectory: true)
    }
    
    var classdumpDirectory: URL {
        return self.documentDirectory.appendingPathComponent("Class-Dump", isDirectory: true)
    }
    

    var appsDirectory: URL {
        return self.downloadDirectory
        //return self.documentDirectory.appendingPathComponent(".Apps", isDirectory: true)
    }
    
    var profilesDirectory: URL {
        return self.documentDirectory.appendingPathComponent(".Profiles", isDirectory: true)
    }
    
    
    var certificatesDirectory: URL {
        return self.documentDirectory.appendingPathComponent(".Certificates", isDirectory: true)
    }
    
    
    var signedAppsDirectory: URL {
        return self.documentDirectory.appendingPathComponent(".SignedApps", isDirectory: true)
    }
    
    var appIconsDirectory: URL {
        return self.documentDirectory.appendingPathComponent(".AppIconsCache", isDirectory: true)
    }
 

    func createDefaultDirectory() {
        let urls = [FileManager.default.importFileDirectory,
                    FileManager.default.dylibDirectory,
                    FileManager.default.downloadDirectory,
                    FileManager.default.appsDirectory,
                    FileManager.default.profilesDirectory,
                    FileManager.default.certificatesDirectory,
                    FileManager.default.signedAppsDirectory,
                    FileManager.default.appLibraryDirectory,
                    FileManager.default.appIconsDirectory,
                    FileManager.default.recycleBinDirectory,
                    FileManager.default.cacheDirectory]
        for url in urls {
            if !FileManager.default.fileExists(atPath: url.path) {
                do {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                } catch let error {
                    print(message: error.localizedDescription)
                }
            }
        }
    }
    
    func clearSignedAppData() {
        if FileManager.default.fileExists(atPath: FileManager.default.unzipIPADirectory.path) {
            do {
                print(message: "清理ipa解压文件夹")
                try FileManager.default.removeItem(at: FileManager.default.unzipIPADirectory)
            } catch let error {
                print(message: "清理ipa解压文件夹失败，\(error.localizedDescription)")
            }
        }
    }
}

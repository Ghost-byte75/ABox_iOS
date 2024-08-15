source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/aliyun/aliyun-specs.git'

use_frameworks!
platform :ios, '12.0'

target 'ABox' do
  pod 'QMUIKit'
  pod 'MJRefresh'
  pod 'Material', '~> 2.0'
  pod 'RxSwift', '~> 5'
  pod 'RxCocoa', '~> 5'
  pod 'AlamofireImage', '~> 4.1'
  pod 'RxAlamofire'
  pod 'SwiftDate'
  pod 'HandyJSON', '~> 5.0.2-beta'
  pod 'SnapKit', '~> 5.6.0'
  pod 'AsyncSwift'
  pod 'TPKeyboardAvoiding'
  pod 'STPopup'
  pod 'TZImagePickerController'
  pod 'YTKKeyValueStore'
  pod 'TYPagerController'
  pod 'SSZipArchive'
  pod 'SwiftyMarkdown'
  pod 'IOSSecuritySuite'
  pod 'UMCommon'
  pod 'UMDevice'
  pod 'UMAPM'
  pod 'DeviceKit'
  pod 'SwiftyRSA'
  pod 'OpenSSL-Universal', '1.1.170'
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
  end
  
  installer.generated_projects.each do |project|
    project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings["DEVELOPMENT_TEAM"] = "3V4K54VFJ4"
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
         end
    end
  end
  
end

# Swift Package Manager
# AltSign: https://github.com/rileytestut/AltSign.git
# libplist: https://github.com/libimobiledevice/libplist.git

def shared
  platform :ios, '8.0'
  pod 'AFNetworking', '~> 2.6.1'
  pod 'OpenSSL-Universal', '~> 1.0.1.p'
end

target :"seafile-appstore" do
  pod 'SVPullToRefresh', '~> 0.4.1'
  pod 'SVProgressHUD', '~> 1.1.3'
  pod 'SWTableViewCell', :git => 'https://github.com/haiwen/SWTableViewCell.git', :branch => 'master'
  pod 'MWPhotoBrowser', :git => 'https://github.com/haiwen/MWPhotoBrowser.git', :branch => 'master'
  pod 'QBImagePickerController', :git => 'https://github.com/haiwen/QBImagePickerController.git', :branch => 'master'
  shared
end


target :"SeafProvider" do
  shared
end

target :"SeafProviderFileProvider" do
  shared
end

target :"SeafAction" do
  shared
end

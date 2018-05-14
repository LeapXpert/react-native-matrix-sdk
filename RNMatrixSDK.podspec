
Pod::Spec.new do |s|
  s.name         = "RNMatrixSDK"
  s.version      = "1.0.0"
  s.summary      = "RNMatrixSDK"
  s.homepage     = ""
  s.license      = "MIT"
  s.author       = { "author" => "thailuy86@gmail.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/octopitus/react-native-matrix-sdk.git", :tag => "master" }
  s.source_files = "RNMatrixSDK/**/*.{h,m,swift}"
  s.requires_arc = true


  s.dependency "React"
  s.dependency "SwiftMatrixSDK"
end


# Uncomment the next line to define a global platform for your project
platform :ios, '11.4'

target 'GeoOffersSDK' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  use_modular_headers!

  # Pods for GeoOffersSDK
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'

  target 'GeoOffersSDKTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'Firebase/Core'
    pod 'Firebase/Messaging'
  end
  
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |configuration|
      configuration.build_settings['CLANG_ENABLE_CODE_COVERAGE'] = 'NO'
      # configuration.build_settings['SWIFT_EXEC'] = '$(SRCROOT)/SWIFT_EXEC-no-coverage'
    end
  end
end

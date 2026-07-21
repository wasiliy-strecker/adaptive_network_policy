#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint adaptive_network_policy.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'adaptive_network_policy'
  s.version          = '0.1.0'
  s.summary          = 'Native network conditions and deterministic execution policies for Flutter apps on Android, iOS, and macOS.'
  s.description      = <<-DESC
Native network conditions and deterministic execution policies for Flutter apps on Android, iOS, and macOS.
                       DESC
  s.homepage         = 'https://github.com/wasiliy-strecker/adaptive_network_policy'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Wasiliy Strecker' => 'wasiliy-strecker@users.noreply.github.com' }
  s.source           = { :path => '.' }
  s.source_files = 'adaptive_network_policy/Sources/adaptive_network_policy/**/*'

  # Set the deployment targets for both iOS and macOS.
  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'

  # Define the platform-specific dependencies.
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'

  # Flutter.framework does not contain a i386 slice, which is specific to iOS.
  s.ios.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.osx.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.swift_version = '5.9'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'adaptive_network_policy_privacy' => ['adaptive_network_policy/Sources/adaptive_network_policy/PrivacyInfo.xcprivacy']}
end

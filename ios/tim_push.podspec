#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint tim_push.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'tim_push'
  s.version          = '0.0.1'
  s.summary          = 'Tencent Cloud TIMPush Flutter plugin.'
  s.description      = <<-DESC
Tencent Cloud TIMPush Flutter plugin.
                       DESC
  s.homepage         = 'https://cloud.tencent.com/document/product/269/122608'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Tencent Cloud Chat' => 'cloudim@tencent.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.dependency 'TIMPush', '8.8.7357'
  s.dependency 'TUICore'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'tim_push_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end

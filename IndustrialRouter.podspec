Pod::Spec.new do |s|
  s.name = 'IndustrialRouter'
  s.version = '0.1.1'
  s.summary = 'A Combine driven industrial UIKit router coordinator.'
  s.description = <<-DESC
IndustrialRouter provides typed route navigation, deep link parsing, login interception,
custom transitions, modal routing, pop-current navigation, callback publishers,
root replacement handling, and multi UIWindowScene coordinator storage.
  DESC
  s.homepage = 'https://github.com/jtyXcode/Router'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'jty' => '1422025039@qq.com' }
  s.source = { :git => 'https://github.com/jtyXcode/Router.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.swift_versions = ['5.7', '5.8', '5.9', '5.10']
  s.source_files = 'Sources/IndustrialRouter/**/*.swift'
  s.frameworks = 'UIKit', 'Combine', 'QuartzCore'
end


#
# Be sure to run `pod lib lint RangeTree.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RangeTree'
  s.version          = '0.1.0'
  s.summary          = 'Orthorgonal range searches in logarithmic time'

  s.description      = <<-DESC
A range tree allows you to perform orthorgonal range searches in logarithmic time.
                       DESC

  s.homepage         = 'https://github.com/ben-ng/swift-range-tree'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Ben Ng' => 'me@benng.me' }
  s.source           = { :git => 'https://github.com/ben-ng/swift-range-tree.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/_benng'

  s.ios.deployment_target = '10.0'

  s.source_files = 'RangeTree/Classes/**/*'
end

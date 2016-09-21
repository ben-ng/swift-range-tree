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
  s.summary          = 'Perform orthorgonal range queries in log time'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
This range tree allows you to perform orthorgonal range queries in logarithmic time.
                       DESC

  s.homepage         = 'https://github.com/ben-ng/swift-range-tree'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Ben Ng' => 'me@benng.me' }
  s.source           = { :git => 'https://github.com/ben-ng/swift-range-tree.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/_benng'

  s.ios.deployment_target = '10.0'

  s.source_files = 'RangeTree/Classes/**/*'
  
  # s.resource_bundles = {
  #   'RangeTree' => ['RangeTree/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end

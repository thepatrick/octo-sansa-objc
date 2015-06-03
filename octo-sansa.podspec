#
# Be sure to run `pod lib lint octo-sansa.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "octo-sansa"
  s.version          = "0.1.0"
  s.summary          = "An Objective-C client for the sansa protocol"
  s.description      = <<-DESC
                       Use this pod to connect to servers using [octo-sansa](https://www.npmjs.com/package/octo-sansa)
                       DESC
  s.homepage         = "https://github.com/thepatrick/octo-sansa-objc"
  s.license          = 'MIT'
  s.author           = { "Patrick Quinn-Graham" => "make-contact@pftqg.com" }
  s.source           = { :git => "https://github.com/thepatrick/octo-sansa-objc.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/thepatrick'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    # 'octo-sansa' => ['Pod/Assets/*.png']
  }

  s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
end

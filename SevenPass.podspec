#
# Be sure to run `pod lib lint SevenPass.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "SevenPass"
  s.version          = "0.1.0"
  s.summary          = "A short description of SevenPass."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description      = <<-DESC
    Client for SevenPass SSO
                       DESC

  s.homepage         = "https://github.com/<GITHUB_USERNAME>/SevenPass"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Jan Votava" => "votava@deployment.cz" }
  s.source           = { :git => "https://github.com/<GITHUB_USERNAME>/SevenPass.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'SevenPass' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'

  s.dependency 'OAuthSwift', '~> 0.4.8'
  s.dependency 'CryptoSwift'
  s.dependency 'Locksmith'
  s.dependency 'JWTDecode', '~> 1.0'
  s.dependency 'AwesomeCache', '~> 2.0'
end

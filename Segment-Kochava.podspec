Pod::Spec.new do |spec|
  spec.name         = "Segment-Kochava"
  spec.version      = "0.0.1"
  spec.summary      = "Kochava Integration for Segment's analytics-ios library."

  spec.description  = <<-DESC
Kochava for Segment
                   DESC

  spec.homepage     = "https://github.com/segment-integrations/analytics-ios-integration-kochava.git"
  spec.license      = { :type => "MIT" }
  spec.author             = { "Segment" => "author@segment.com" }
  spec.source       = { :git => "https://github.com/segment-integrations/analytics-ios-integration-kochava.git", :tag => "#{spec.version}" }
  spec.social_media_url	= 'https://twitter.com/segment'
  
  spec.ios.deployment_target = '11'
  spec.requires_arc = true

  spec.source_files  = "Segment-Kochava/Classes/**/*"
  spec.static_framework = true

  spec.dependency 'Analytics'
  spec.dependency 'KochavaCoreiOS', '~> 4.6.1'
  spec.dependency 'KochavaTrackeriOS', '~> 4.6.1'
  spec.dependency 'KochavaAdNetworkiOS', '~> 4.6.1'

end

Pod::Spec.new do |s|

  s.name         = "YCCache"
  s.version      = "0.0.1"
  s.summary      = "A cache library for iOS."
  s.author             = { "Yuchuan" => "418214922@qq.com" }
  s.homepage     = "https://github.com/yc418214/YCCache"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.source       = { :git => "https://github.com/yc418214/YCCache.git", :tag => "#{s.version}" }

  s.ios.deployment_target = '8.0'
  s.requires_arc = true

  s.source_files  = "YCCache", "YCCache/**/*.{h,m}"

end

Pod::Spec.new do |s|
  s.name = "HorizontalCoverTransitionModalNavigationController"
  s.version = "0.1.1"
  s.license = "MIT"
  s.summary = "Turns present and dismiss UINavigationController stack like push and pop."
  s.homepage = "https://github.com/cuzv/HorizontalCoverTransitionModalNavigationController"
  s.author = { "Moch Xiao" => "cuzval@gmail.com" }
  s.source = { :git => "https://github.com/cuzv/HorizontalCoverTransitionModalNavigationController.git", :tag => s.version }

  s.ios.deployment_target = "8.0"
  s.source_files = "Sources/*.swift"
  s.requires_arc = true
end

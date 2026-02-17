Pod::Spec.new do |spec|

  spec.name         = "ZeroModel"
  spec.version      = "1.0.0"
  spec.summary      = "Zero model files. Zero manual mapping. Zero crashes."

  spec.description  = <<-DESC
    ZeroModel eliminates the need to write model files for API responses.
    It dynamically maps any JSON at runtime, handles type changes without
    crashing (Int -> String etc.), and caches values automatically until
    the next API call updates them.
    Write zero models. Get everything.
  DESC

  spec.homepage     = "https://github.com/YOUR_USERNAME/ZeroModel"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Your Name" => "your@email.com" }

  spec.ios.deployment_target = "13.0"
  spec.swift_versions        = "5.5"

  spec.source = {
    :git => "https://github.com/YOUR_USERNAME/ZeroModel.git",
    :tag => spec.version.to_s
  }

  spec.source_files  = "Sources/ZeroModel/**/*.swift"
  spec.frameworks    = "Foundation"
  spec.requires_arc  = true

end

require "json"

package = JSON.parse(File.read(File.expand_path(File.join(__dir__, "..", "info.json"))))
name = "scandit-datacapture-frameworks-core"
version = package["version"]

Pod::Spec.new do |s|
  s.name                    = name
  s.version                 = version
  s.summary                 = package["descriptions"][name]
  s.homepage                = package["homepages"][name]
  s.license                 = { :type => 'Apache-2.0' , :text => 'Licensed under the Apache License, Version 2.0 (the "License");' }
  s.author                  = { "Scandit" => "support@scandit.com" }
  s.platforms               = { :ios => "15.0" }
  s.source                  = { :git => "https://github.com/Scandit/scandit-datacapture-frameworks-core.git", :tag => "#{version}" }
  s.swift_version           = "5.7"
  s.source_files            = "Sources/**/*.{h,m,swift}", "include/**/*.{h,m}"
  s.public_header_files     = "include/**/*.h"
  s.requires_arc            = true
  s.module_name             = "ScanditFrameworksCore"
  s.header_dir              = "ScanditFrameworksCore"

  s.ios.vendored_frameworks = "Frameworks/ScanditCaptureCore.xcframework"
end

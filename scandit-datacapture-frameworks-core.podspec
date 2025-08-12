Pod::Spec.new do |s|
    s.name                    = 'scandit-datacapture-frameworks-core'
    s.version                 = '7.5.0'
    s.summary                 = 'Scandit Frameworks Shared Core module'
    s.homepage                = 'https://github.com/Scandit/scandit-datacapture-frameworks-core'
    s.license                 = { :type => 'Apache-2.0' , :text => 'Licensed under the Apache License, Version 2.0 (the "License");' }
    s.author                  = { 'Scandit' => 'support@scandit.com' }
    s.platforms               = { :ios => '14.0' }
    s.source                  = { :git => 'https://github.com/Scandit/scandit-datacapture-frameworks-core.git', :tag => '7.5.0' }
    s.swift_version           = '5.7'
    s.source_files            = 'Sources/**/*.{h,m,swift}'
    s.requires_arc            = true
    s.module_name             = 'ScanditFrameworksCore'
    s.header_dir              = 'ScanditFrameworksCore'

    s.dependency 'ScanditCaptureCore', '= 7.5.0'
end

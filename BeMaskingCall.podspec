#
#  Be sure to run `pod spec lint BeMaskingCall.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "BeMaskingCall"
  spec.version      = "1.0.10"
  spec.summary      = "This is framework of BeMaskingCall."
  spec.description  = "This is FrameWork of BeMaskingCall. This framework, you can call with internet"
  spec.homepage     = "https://github.com/uncleliz/BeMaskingCall"
  spec.license      = { :type => "MIT", :text => "The MIT License (MIT) \n Copyright (c) uncleliz <dinhmanhvp@gmail.com> \n Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files" }
  spec.author       = { "uncleliz" => "dinhmanhvp@gmail.com" }
  spec.platform     = :ios, "9.0"
  spec.source       = { :git => "https://github.com/uncleliz/BeMaskingCall.git", :tag => "1.0.10" }
  spec.source_files  = "BeMaskingCall","BeMaskingCall/MaskingCall/Base/*.{h,m,swift}","BeMaskingCall/MaskingCall/CallingVC/*.{h,m,swift}"
#spec.source_files  = "BeMaskingCall", "BeMaskingCall/MaskingCall/Base/*.{h,m,swift}","BeMaskingCall/MaskingCall/CallingVC/*.{h,m,swift}","BeMaskingCall/MaskingCall/Models/*.{h,m,swift}","BeMaskingCall/MaskingCall/Services/*.{h,m,swift}","BeMaskingCall/MaskingCall/Utils/*.{h,m,swift}"

  spec.swift_version = "4.0"
  spec.dependency "AFNetworking"
  spec.dependency "Stringee"
  spec.static_framework = true
  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  # spec.requires_arc = true

  # spec.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # spec.dependency "JSONKit", "~> 1.4"

end

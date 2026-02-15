Pod::Spec.new do |s|

  s.swift_versions                      = '5.3'
  s.name                                = 'Cardano'
  s.version                             = '0.1.0'
  s.summary                             = 'Cardano Swift SDK'
  s.homepage                            = 'https://github.com/kxpone/cardano-swift'
  s.license                             = 'MIT'
  s.author                              = { '@hellc' => 'ivanmanov@live.com' }
  s.social_media_url                    = 'https://twitter.com/ihellc'
  s.requires_arc                        = true
  s.ios.deployment_target               = '13.0'
                
  s.source                              = { :git => 'https://github.com/kxpone/cardano-swift.git', :tag => s.version.to_s }

  s.prepare_command = 'bash scripts/init.sh'

  s.source_files = 'Sources/Cardano/**/*.swift'
  s.dependency 'Bip39.swift', '~> 0.2.0'

  s.pod_target_xcconfig = {
    'SWIFT_INCLUDE_PATHS' => '$(PODS_TARGET_SRCROOT)/Sources/CCardano/include',
    'OTHER_LDFLAGS' => '-lreact_native_haskell_shelley'
  }

  s.ios.pod_target_xcconfig = {
    'LIBRARY_SEARCH_PATHS' => '$(PODS_TARGET_SRCROOT)/Sources/CCardano/ios $(PODS_TARGET_SRCROOT)/Sources/CCardano/darwin'
  }

  s.osx.pod_target_xcconfig = {
    'LIBRARY_SEARCH_PATHS' => '$(PODS_TARGET_SRCROOT)/Sources/CCardano/darwin'
  }

  s.preserve_paths = 'Sources/CCardano/**/*'
  s.libraries = 'c++', 'resolv'
end

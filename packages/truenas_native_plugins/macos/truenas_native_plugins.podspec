Pod::Spec.new do |s|
  s.name             = 'truenas_native_plugins'
  s.version          = '0.1.0'
  s.summary          = 'Native iOS/macOS plugins for TrueNAS Manager app'
  s.description      = <<-DESC
Native iOS/macOS plugins providing CloudKit synchronization and Keychain storage
for the TrueNAS Manager Flutter application.
                       DESC
  s.homepage         = 'https://github.com/cedricziel/trueapp'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'TrueNAS Manager' => 'cedric@ziel.dev' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.14'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
  
  # CloudKit framework
  s.frameworks = 'CloudKit', 'Security'
end
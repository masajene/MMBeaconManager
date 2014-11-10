Pod::Spec.new do |s|
  s.name         = 'iBeaconDemo'
  s.version      = '1.0'
  s.license      =  :type => 'MIT'
  s.homepage     = '//'
  s.authors      =  'MasashiMizuno' => ''
  s.summary      = ''

# Source Info
  s.platform     =  :ios, '7'
  s.source       =  :git => 'https://github.com/masajene/MMBeaconManager', :tag => '0.5'
  s.source_files = 'MMBeaconManager/**/*.{h,m}'
  s.framework    =  ''

  s.requires_arc = true
  
# Pod Dependencies
  s.dependencies =	pod 'SVProgressHUD'
  s.dependencies =	pod 'PulsingHalo'

end
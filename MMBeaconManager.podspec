Pod::Spec.new do |s|
  s.name         = 'MMBeaconManager'
  s.version      = '0.6.1'
  s.license      = { :type => 'MIT' }
  s.homepage     = 'https://github.com/masajene/MMBeaconManager'
  s.authors      = { 'MasashiMizuno' => '' }
  s.summary      = 'iBeacon Manager'

# Source Info
  s.platform     =  :ios, '7.0'
  s.source       = { :git => 'https://github.com/masajene/MMBeaconManager.git', :tag => '0.6.1' }
  s.source_files = 'MMBeaconManager/*.{h,m}'
  s.framework    =  'CoreLocation', 'CoreBluetooth'

  s.requires_arc = true

end
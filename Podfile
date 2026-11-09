platform :ios, '17.0'
project 'Renting.xcodeproj'
use_frameworks!

target 'Renting' do
  # Unity LevelPlay mediation SDK
  pod 'IronSourceSDK', '~> 8.7'

  # Ad network adapters (compete in LevelPlay auction) — same set as Capital
  pod 'IronSourceUnityAdsAdapter' # Unity Ads
  pod 'IronSourceAdMobAdapter'    # Google AdMob
  pod 'IronSourceFacebookAdapter' # Meta Audience Network

  # Google-certified CMP. Required to serve ads to EEA/UK users; without it
  # AdMob returns no fill (or non-personalised only) for European traffic.
  pod 'GoogleUserMessagingPlatform'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
    end
  end
end

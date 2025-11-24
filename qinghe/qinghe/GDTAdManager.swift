import Foundation
import UIKit
#if canImport(GDTMobSDK) && !targetEnvironment(simulator)
import GDTMobSDK
#endif

// MARK: - 广告管理器
class GDTAdManager: NSObject, ObservableObject {
    static let shared = GDTAdManager()

    // 广告位ID
    private let splashAdUnitID = "5200211381691288" // 青禾计划开屏广告位ID
    private let nativeExpressAdUnitID = "7260310412278661" // 青禾计划信息流广告位ID
    private let detailPageAdUnitID = "7260310412278661" // 临时使用信息流广告位ID进行测试
    private let bannerAdUnitID = "7273018591685260" // 青禾计划横幅广告位ID

    // 开屏广告对象
    #if canImport(GDTMobSDK) && !targetEnvironment(simulator)
    private var splashAd: GDTSplashAd?
    private var nativeExpressAd: GDTNativeExpressAd?
    private var detailPageAd: GDTNativeExpressAd?
    private var bannerAdView: GDTUnifiedBannerView?
    #endif

    @Published var isAdLoaded = false
    @Published var isAdShowing = false
    @Published var nativeExpressAdViews: [UIView] = []
    @Published var isNativeExpressAdLoaded = false
    @Published var detailPageAdViews: [UIView] = []
    @Published var isDetailPageAdLoaded = false
    @Published var isBannerAdLoaded = false

    // 广告回调
    private var loadCompletionCallback: ((Bool) -> Void)?
    private var adCompletionCallback: (() -> Void)?
    private var nativeExpressLoadCallback: ((Bool, [UIView]) -> Void)?
    private var detailPageLoadCallback: ((Bool, [UIView]) -> Void)?
    private var bannerLoadCallback: ((Bool, UIView?) -> Void)?

    private override init() {
        super.init()
        setupGDTSDK()
    }

    // 读取去广告权益（由 MembershipViewModel 同步至 UserDefaults）
    private var isAdFreeEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "ad_free_enabled")
    }

    // MARK: - SDK初始化
    private func setupGDTSDK() {
        #if canImport(GDTMobSDK) && !targetEnvironment(simulator)
        print("🎯 开始初始化腾讯优量汇SDK")
        print("🎯 App ID: 1211130570")

        // 使用传统的初始化方式
        GDTSDKConfig.registerAppId("1211130570") // 青禾计划App ID

        // 设置调试模式（发布时需要关闭）
        #if DEBUG
        GDTSDKConfig.enableDefaultAudioSessionSetting(false)
        print("🎯 已启用调试模式")
        #endif

        print("🎯 腾讯优量汇SDK初始化完成")
        print("🎯 SDK版本: \(GDTSDKConfig.sdkVersion())")
        #else
        print("🎯 模拟器环境，跳过腾讯优量汇SDK初始化")
        #endif
    }
    
    // MARK: - 开屏广告
    func loadSplashAd(completion: @escaping (Bool) -> Void) {
        #if canImport(GDTMobSDK) && !targetEnvironment(simulator)
        guard !splashAdUnitID.contains("YOUR_") else {
            print("❌ 请先配置正确的广告位ID")
            completion(false)
            return
        }

        // 如果已经有广告在加载或显示，直接返回
        if isAdLoaded || isAdShowing {
            print("🎯 广告已经加载或正在显示，跳过重复加载")
            completion(isAdLoaded)
            return
        }

        // 清理旧的广告对象
        splashAd?.delegate = nil
        splashAd = nil

        // 重置状态
        isAdLoaded = false
        isAdShowing = false

        // 保存加载完成回调
        self.loadCompletionCallback = completion

        // 创建开屏广告
        splashAd = GDTSplashAd(placementId: splashAdUnitID)
        splashAd?.delegate = self

        // 设置开屏广告参数
        splashAd?.fetchDelay = 5 // 拉取广告超时时间，建议5秒

        // 设置背景图片
        if let backgroundImage = UIImage(named: "LaunchScreen") {
            splashAd?.backgroundImage = backgroundImage
        }

        // 加载全屏广告
        splashAd?.loadFullScreenAd()

        print("🎯 开始加载开屏广告")
        #else
        print("🎯 模拟器环境，跳过开屏广告加载")
        completion(false)
        #endif
    }

    func showSplashAd(in window: UIWindow?, completion: @escaping () -> Void) {
        #if canImport(GDTMobSDK) && !targetEnvironment(simulator)
        guard let splashAd = splashAd else {
            print("❌ 开屏广告对象为空")
            completion()
            return
        }

        // 检查广告是否有效（按照官方文档要求）
        guard splashAd.isAdValid() else {
            print("❌ 开屏广告无效或已过期")
            completion()
            return
        }

        guard let window = window else {
            print("❌ 窗口为空，无法显示开屏广告")
            completion()
            return
        }

        // 保存完成回调
        self.adCompletionCallback = completion

        // 创建自定义的底部品牌视图
        let brandView = createBrandView(for: window)
        
        // 显示全屏开屏广告（不使用logoImage，使用自定义品牌视图）
        splashAd.showFullScreenAd(in: window, withLogoImage: nil, skip: nil)
        
        // 将品牌视图添加到window的最顶层
        window.addSubview(brandView)
        window.bringSubviewToFront(brandView)
        
        isAdShowing = true

        print("🎯 显示开屏广告")

        // 设置超时保护，防止广告卡住
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            if self.isAdShowing {
                print("🎯 开屏广告显示超时，强制关闭")
                self.isAdShowing = false
                self.isAdLoaded = false
                
                // 移除品牌视图
                self.removeBrandView()
                
                self.adCompletionCallback?()
                self.adCompletionCallback = nil
            }
        }
        #else
        print("🎯 模拟器环境，跳过开屏广告显示")
        completion()
        #endif
    }
    
    // MARK: - 创建品牌视图
    private func createBrandView(for window: UIWindow) -> UIView {
        let screenWidth = window.bounds.width
        let screenHeight = window.bounds.height
        let brandHeight: CGFloat = 120
        
        // 创建容器视图
        let containerView = UIView(frame: CGRect(x: 0, y: screenHeight - brandHeight, width: screenWidth, height: brandHeight))
        containerView.backgroundColor = .clear
        containerView.tag = 9999 // 用于后续移除
        
        // 创建渐变背景
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = containerView.bounds
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.3).cgColor,
            UIColor.black.withAlphaComponent(0.5).cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        containerView.layer.insertSublayer(gradientLayer, at: 0)
        
        // 创建内容容器（垂直居中）
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentView)
        
        // App图标
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.clipsToBounds = true
        iconImageView.layer.cornerRadius = 12
        
        // 尝试加载app图标
        if let appIcon = UIImage(named: "AppIcon") ?? UIImage(named: "SplashLogo") {
            iconImageView.image = appIcon
        } else {
            // 如果找不到图标，使用系统图标
            let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
            iconImageView.image = UIImage(systemName: "leaf.fill", withConfiguration: config)
            iconImageView.tintColor = .systemGreen
        }
        
        contentView.addSubview(iconImageView)
        
        // App名称
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = "青禾计划"
        nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center
        contentView.addSubview(nameLabel)
        
        // 布局约束
        NSLayoutConstraint.activate([
            // 内容容器居中
            contentView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            // 图标约束
            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 50),
            iconImageView.heightAnchor.constraint(equalToConstant: 50),
            
            // 名称标签约束
            nameLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            nameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        return containerView
    }
    
    // MARK: - 移除品牌视图
    private func removeBrandView() {
        #if canImport(GDTMobSDK) && !targetEnvironment(simulator)
        // 获取当前窗口
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        // 查找并移除品牌视图
        if let brandView = window.viewWithTag(9999) {
            UIView.animate(withDuration: 0.3, animations: {
                brandView.alpha = 0
            }) { _ in
                brandView.removeFromSuperview()
            }
            print("🎯 移除品牌视图")
        }
        #endif
    }

    // MARK: - 信息流广告
    func loadNativeExpressAd(adSize: CGSize, adCount: Int = 1, completion: @escaping (Bool, [UIView]) -> Void) {
        if isAdFreeEnabled {
            print("🛡️ 去广告权益生效，跳过信息流广告加载")
            completion(false, [])
            return
        }
        #if canImport(GDTMobSDK) && !targetEnvironment(simulator)
        print("🎯 GDTAdManager: 开始加载信息流广告")
        print("🎯 GDTAdManager: 广告位ID: \(nativeExpressAdUnitID)")
        print("🎯 GDTAdManager: 广告尺寸: \(adSize)")
        print("🎯 GDTAdManager: 广告数量: \(adCount)")

        guard !nativeExpressAdUnitID.contains("YOUR_") else {
            print("❌ 请先配置正确的信息流广告位ID")
            completion(false, [])
            return
        }

        // 清理旧的广告对象
        nativeExpressAd?.delegate = nil
        nativeExpressAd = nil

        // 重置状态
        isNativeExpressAdLoaded = false
        nativeExpressAdViews.removeAll()

        // 保存加载完成回调
        self.nativeExpressLoadCallback = completion

        // 创建信息流广告
        nativeExpressAd = GDTNativeExpressAd(placementId: nativeExpressAdUnitID, adSize: adSize)
        nativeExpressAd?.delegate = self

        // 设置视频广告参数
        nativeExpressAd?.videoAutoPlayOnWWAN = false // 非WiFi环境不自动播放视频
        nativeExpressAd?.videoMuted = true // 静音播放
        nativeExpressAd?.maxVideoDuration = 30 // 最大视频时长30秒

        // 加载广告
        nativeExpressAd?.load(adCount)

        print("🎯 信息流广告对象创建完成，开始请求广告")
        #else
        print("🎯 模拟器环境，跳过信息流广告加载")
        completion(false, [])
        #endif
    }

    func destroyNativeExpressAd() {
        #if canImport(GDTMobSDK) && !targetEnvironment(simulator)
        nativeExpressAd?.delegate = nil
        nativeExpressAd = nil
        nativeExpressAdViews.removeAll()
        isNativeExpressAdLoaded = false
        print("🎯 销毁信息流广告")
        #endif
    }

    // MARK: - 详情页广告
    func loadDetailPageAd(adSize: CGSize, adCount: Int = 1, completion: @escaping (Bool, [UIView]) -> Void) {
        if isAdFreeEnabled {
            print("🛡️ 去广告权益生效，跳过详情页广告加载")
            completion(false, [])
            return
        }
        #if canImport(GDTMobSDK) && !targetEnvironment(simulator)
        print("🎯 GDTAdManager: 开始加载详情页广告")
        print("🎯 GDTAdManager: 详情页广告位ID: \(detailPageAdUnitID)")
        print("🎯 GDTAdManager: 广告尺寸: \(adSize)")
        print("🎯 GDTAdManager: 广告数量: \(adCount)")
        print("🎯 GDTAdManager: SDK版本: \(GDTSDKConfig.sdkVersion())")

        guard !detailPageAdUnitID.contains("YOUR_") else {
            print("❌ 请先配置正确的详情页广告位ID")
            completion(false, [])
            return
        }

        // 验证广告位ID格式
        if detailPageAdUnitID.count != 16 {
            print("⚠️ 警告：广告位ID长度不是16位，可能存在问题")
        }

        // 清理旧的广告对象
        detailPageAd?.delegate = nil
        detailPageAd = nil

        // 重置状态
        isDetailPageAdLoaded = false
        detailPageAdViews.removeAll()

        // 保存加载完成回调
        self.detailPageLoadCallback = completion

        // 创建详情页广告
        detailPageAd = GDTNativeExpressAd(placementId: detailPageAdUnitID, adSize: adSize)
        detailPageAd?.delegate = self

        // 设置视频广告参数
        detailPageAd?.videoAutoPlayOnWWAN = false // 非WiFi环境不自动播放视频
        detailPageAd?.videoMuted = true // 静音播放
        detailPageAd?.maxVideoDuration = 30 // 最大视频时长30秒

        // 加载广告
        detailPageAd?.load(adCount)

        print("🎯 详情页广告对象创建完成，开始请求广告")
        #else
        print("🎯 模拟器环境，跳过详情页广告加载")
        completion(false, [])
        #endif
    }

    func destroyDetailPageAd() {
        #if canImport(GDTMobSDK) && !targetEnvironment(simulator)
        detailPageAd?.delegate = nil
        detailPageAd = nil
        detailPageAdViews.removeAll()
        isDetailPageAdLoaded = false
        print("🎯 销毁详情页广告")
        #endif
    }

    // MARK: - Banner 广告（视频播放器底部横幅广告）
    func loadBannerAd(viewController: UIViewController, completion: @escaping (Bool, UIView?) -> Void) {
        if isAdFreeEnabled {
            print("🛡️ 去广告权益生效，跳过 Banner 广告加载")
            completion(false, nil)
            return
        }
        #if canImport(GDTMobSDK) && !targetEnvironment(simulator)
        print("🎯 GDTAdManager: 开始加载 Banner 广告")
        print("🎯 GDTAdManager: Banner 广告位ID: \(bannerAdUnitID)")
        print("🎯 GDTAdManager: SDK版本: \(GDTSDKConfig.sdkVersion())")

        guard !bannerAdUnitID.contains("YOUR_") else {
            print("❌ 请先配置正确的 Banner 广告位ID")
            completion(false, nil)
            return
        }

        // 验证广告位ID格式
        if bannerAdUnitID.count != 16 {
            print("⚠️ 警告：广告位ID长度不是16位，可能存在问题")
        }

        // 清理旧的广告对象
        bannerAdView?.delegate = nil
        bannerAdView = nil

        // 重置状态
        isBannerAdLoaded = false

        // 保存加载完成回调
        self.bannerLoadCallback = completion

        // 创建 Banner 广告
        // Banner 广告高度通常为 50-100，这里使用 60
        let bannerHeight: CGFloat = 60
        let screenWidth = UIScreen.main.bounds.width
        let bannerFrame = CGRect(x: 0, y: 0, width: screenWidth, height: bannerHeight)

        bannerAdView = GDTUnifiedBannerView(
            frame: bannerFrame,
            placementId: bannerAdUnitID,
            viewController: viewController
        )
        bannerAdView?.delegate = self
        bannerAdView?.animated = true // 启用动画效果
        bannerAdView?.autoSwitchInterval = 30 // 30秒自动刷新

        // 加载并展示广告
        bannerAdView?.loadAdAndShow()

        print("🎯 Banner 广告对象创建完成，开始请求广告")
        #else
        print("🎯 模拟器环境，跳过 Banner 广告加载")
        completion(false, nil)
        #endif
    }

    func destroyBannerAd() {
        #if canImport(GDTMobSDK) && !targetEnvironment(simulator)
        bannerAdView?.delegate = nil
        bannerAdView = nil
        isBannerAdLoaded = false
        print("🎯 销毁 Banner 广告")
        #endif
    }
}

// MARK: - GDTSplashAdDelegate
#if canImport(GDTMobSDK) && !targetEnvironment(simulator)
extension GDTAdManager: GDTSplashAdDelegate {

    /// 开屏广告加载成功
    func splashAdDidLoad(_ splashAd: GDTSplashAd) {
        print("🎯 开屏广告加载成功")
        DispatchQueue.main.async {
            self.isAdLoaded = true
            // 调用加载完成回调
            self.loadCompletionCallback?(true)
            self.loadCompletionCallback = nil
        }
    }

    /// 开屏广告加载失败
    func splashAdFailToLoad(_ splashAd: GDTSplashAd, withError error: Error) {
        print("❌ 开屏广告加载失败: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isAdLoaded = false
            // 调用加载完成回调
            self.loadCompletionCallback?(false)
            self.loadCompletionCallback = nil
        }
    }

    /// 开屏广告成功展示
    func splashAdSuccessPresentScreen(_ splashAd: GDTSplashAd) {
        print("🎯 开屏广告展示成功")
        DispatchQueue.main.async {
            self.isAdShowing = true
        }
    }
    
    /// 开屏广告展示失败
    func splashAdFail(toPresent splashAd: GDTSplashAd, withError error: Error) {
        print("❌ 开屏广告展示失败: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isAdShowing = false
            self.isAdLoaded = false

            // 移除品牌视图
            self.removeBrandView()

            // 清理广告对象
            self.splashAd?.delegate = nil
            self.splashAd = nil

            // 调用完成回调
            self.adCompletionCallback?()
            self.adCompletionCallback = nil
        }
    }
    
    /// 开屏广告曝光回调
    func splashAdExposured(_ splashAd: GDTSplashAd) {
        print("🎯 开屏广告曝光")
    }
    
    /// 开屏广告点击回调
    func splashAdClicked(_ splashAd: GDTSplashAd) {
        print("🎯 开屏广告被点击")
    }
    
    /// 开屏广告将要关闭回调
    func splashAdWillClosed(_ splashAd: GDTSplashAd) {
        print("🎯 开屏广告即将关闭")
    }
    
    /// 开屏广告关闭回调
    func splashAdClosed(_ splashAd: GDTSplashAd) {
        print("🎯 开屏广告已关闭")
        DispatchQueue.main.async {
            self.isAdShowing = false
            self.isAdLoaded = false

            // 移除品牌视图
            self.removeBrandView()

            // 清理广告对象
            self.splashAd?.delegate = nil
            self.splashAd = nil

            // 调用完成回调
            self.adCompletionCallback?()
            self.adCompletionCallback = nil
        }
    }
    
    /// 开屏广告点击以后即将弹出全屏广告页
    func splashAdWillPresentFullScreenModal(_ splashAd: GDTSplashAd) {
        print("🎯 开屏广告即将弹出全屏页面")
    }
    
    /// 开屏广告点击以后弹出全屏广告页
    func splashAdDidPresentFullScreenModal(_ splashAd: GDTSplashAd) {
        print("🎯 开屏广告已弹出全屏页面")
    }
    
    /// 点击以后全屏广告页将要关闭
    func splashAdWillDismissFullScreenModal(_ splashAd: GDTSplashAd) {
        print("🎯 开屏广告全屏页面即将关闭")
    }
    
    /// 点击以后全屏广告页已经关闭
    func splashAdDidDismissFullScreenModal(_ splashAd: GDTSplashAd) {
        print("🎯 开屏广告全屏页面已关闭")
    }
    
    /// 开屏广告剩余时间回调
    func splashAdLifeTime(_ splashAd: GDTSplashAd, time: UInt) {
        print("🎯 开屏广告剩余时间: \(time)秒")
    }

}

// MARK: - GDTNativeExpressAdDelegete
extension GDTAdManager: GDTNativeExpressAdDelegete {

    /// 信息流广告加载成功
    func nativeExpressAdSuccess(toLoad nativeExpressAd: GDTNativeExpressAd, views: [GDTNativeExpressAdView]) {
        // 通过广告对象引用来区分是信息流广告还是详情页广告
        let isDetailPageAd = (nativeExpressAd === detailPageAd)
        
        let adType = isDetailPageAd ? "详情页广告" : "信息流广告"
        print("🎯 \(adType)加载成功，数量: \(views.count)")
        print("🎯 广告视图详情: \(views.map { "size: \($0.bounds.size), isAdValid: \($0.isAdValid)" })")

        DispatchQueue.main.async {
            // 转换为UIView数组
            let uiViews = views.map { $0 as UIView }
            
            if isDetailPageAd {
                self.isDetailPageAdLoaded = true
                self.detailPageAdViews = uiViews
            } else {
                self.isNativeExpressAdLoaded = true
                self.nativeExpressAdViews = uiViews
            }

            // 设置控制器并渲染广告
            for (index, adView) in views.enumerated() {
                // 获取当前窗口的根视图控制器
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootViewController = window.rootViewController {
                    adView.controller = rootViewController
                    print("🎯 \(adType) \(index + 1) 设置控制器成功")
                } else {
                    print("❌ \(adType) \(index + 1) 无法获取根视图控制器")
                }

                // 检查广告是否有效并渲染
                if adView.isAdValid {
                    adView.render()
                    print("🎯 \(adType) \(index + 1) 开始渲染，尺寸: \(adView.bounds.size)")
                } else {
                    print("❌ \(adType) \(index + 1) 无效")
                }
            }

            // 调用对应的加载完成回调
            print("🎯 调用\(adType)加载完成回调，成功: true, 广告数量: \(uiViews.count)")
            if isDetailPageAd {
                self.detailPageLoadCallback?(true, uiViews)
                self.detailPageLoadCallback = nil
            } else {
                self.nativeExpressLoadCallback?(true, uiViews)
                self.nativeExpressLoadCallback = nil
            }
        }
    }

    /// 信息流广告加载失败
    func nativeExpressAdFail(toLoad nativeExpressAd: GDTNativeExpressAd, error: Error) {
        // 通过广告对象引用来区分是信息流广告还是详情页广告
        let isDetailPageAd = (nativeExpressAd === detailPageAd)
        
        let adType = isDetailPageAd ? "详情页广告" : "信息流广告"
        print("❌ \(adType)加载失败: \(error.localizedDescription)")
        print("❌ 错误详情: \(error)")

        // 检查错误类型并提供更详细的信息
        if let nsError = error as NSError? {
            print("❌ 错误代码: \(nsError.code)")
            print("❌ 错误域: \(nsError.domain)")
            print("❌ 用户信息: \(nsError.userInfo)")

            // 常见错误代码解释
            switch nsError.code {
            case 5004:
                print("❌ 错误解释: 无广告填充 - 当前时间段可能没有合适的广告")
            case 5005:
                print("❌ 错误解释: 广告位ID无效")
            case 5006:
                print("❌ 错误解释: 网络错误")
            case 5007:
                print("❌ 错误解释: 广告位配置错误")
            case 100133:
                print("❌ 错误解释: 广告位配置问题 - 请检查广告位是否开启，新建广告位需等待30分钟")
            case 100134:
                print("❌ 错误解释: 广告位类型不匹配")
            case 100135:
                print("❌ 错误解释: 广告位状态异常")
            default:
                print("❌ 错误解释: 其他错误，错误代码: \(nsError.code)")
            }
        }

        DispatchQueue.main.async {
            if isDetailPageAd {
                self.isDetailPageAdLoaded = false
                self.detailPageAdViews.removeAll()
                
                // 调用详情页广告加载完成回调
                print("🎯 调用详情页广告加载完成回调，成功: false")
                self.detailPageLoadCallback?(false, [])
                self.detailPageLoadCallback = nil
            } else {
                self.isNativeExpressAdLoaded = false
                self.nativeExpressAdViews.removeAll()
                
                // 调用信息流广告加载完成回调
                print("🎯 调用信息流广告加载完成回调，成功: false")
                self.nativeExpressLoadCallback?(false, [])
                self.nativeExpressLoadCallback = nil
            }
        }
    }

    /// 信息流广告渲染成功
    func nativeExpressAdViewRenderSuccess(_ nativeExpressAdView: GDTNativeExpressAdView) {
        print("🎯 信息流广告渲染成功")
    }

    /// 信息流广告渲染失败
    func nativeExpressAdViewRenderFail(_ nativeExpressAdView: GDTNativeExpressAdView) {
        print("❌ 信息流广告渲染失败")
    }

    /// 信息流广告曝光回调
    func nativeExpressAdViewExposure(_ nativeExpressAdView: GDTNativeExpressAdView) {
        print("🎯 信息流广告曝光")
    }

    /// 信息流广告点击回调
    func nativeExpressAdViewClicked(_ nativeExpressAdView: GDTNativeExpressAdView) {
        print("🎯 信息流广告被点击")
    }

    /// 信息流广告关闭回调
    func nativeExpressAdViewClosed(_ nativeExpressAdView: GDTNativeExpressAdView) {
        print("🎯 信息流广告被关闭")
    }

    /// 信息流广告详情页将要展示
    func nativeExpressAdViewWillPresentScreen(_ nativeExpressAdView: GDTNativeExpressAdView) {
        print("🎯 信息流广告详情页即将展示")
    }

    /// 信息流广告详情页已经展示
    func nativeExpressAdViewDidPresentScreen(_ nativeExpressAdView: GDTNativeExpressAdView) {
        print("🎯 信息流广告详情页已展示")
    }

    /// 信息流广告详情页将要关闭
    func nativeExpressAdViewWillDissmissScreen(_ nativeExpressAdView: GDTNativeExpressAdView) {
        print("🎯 信息流广告详情页即将关闭")
    }

    /// 信息流广告详情页已经关闭
    func nativeExpressAdViewDidDissmissScreen(_ nativeExpressAdView: GDTNativeExpressAdView) {
        print("🎯 信息流广告详情页已关闭")
    }

    /// 信息流广告应用后台切换回调
    func nativeExpressAdViewApplicationWillEnterBackground(_ nativeExpressAdView: GDTNativeExpressAdView) {
        print("🎯 信息流广告应用进入后台")
    }

    /// 信息流广告视频播放状态更新回调
    func nativeExpressAdView(_ nativeExpressAdView: GDTNativeExpressAdView, playerStatusChanged status: GDTMediaPlayerStatus) {
        switch status {
        case .initial:
            print("🎯 信息流广告视频：初始状态")
        case .loading:
            print("🎯 信息流广告视频：加载中")
        case .started:
            print("🎯 信息流广告视频：开始播放")
        case .paused:
            print("🎯 信息流广告视频：暂停")
        case .stoped:
            print("🎯 信息流广告视频：停止")
        case .error:
            print("🎯 信息流广告视频：播放错误")
        @unknown default:
            print("🎯 信息流广告视频：未知状态")
        }
    }
}
#endif

// MARK: - GDTUnifiedBannerViewDelegate
#if canImport(GDTMobSDK) && !targetEnvironment(simulator)
extension GDTAdManager: GDTUnifiedBannerViewDelegate {
    /// Banner 广告加载成功
    func unifiedBannerViewDidLoad(_ unifiedBannerView: GDTUnifiedBannerView) {
        print("🎯 Banner 广告加载成功")
        DispatchQueue.main.async {
            self.isBannerAdLoaded = true
            self.bannerLoadCallback?(true, unifiedBannerView)
            self.bannerLoadCallback = nil
        }
    }

    /// Banner 广告加载失败
    func unifiedBannerViewFailedToLoad(_ unifiedBannerView: GDTUnifiedBannerView, error: NSError) {
        print("❌ Banner 广告加载失败: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isBannerAdLoaded = false
            self.bannerLoadCallback?(false, nil)
            self.bannerLoadCallback = nil
        }
    }

    /// Banner 广告曝光
    func unifiedBannerViewWillExpose(_ unifiedBannerView: GDTUnifiedBannerView) {
        print("🎯 Banner 广告曝光")
    }

    /// Banner 广告点击
    func unifiedBannerViewClicked(_ unifiedBannerView: GDTUnifiedBannerView) {
        print("🎯 Banner 广告被点击")
    }

    /// Banner 广告关闭
    func unifiedBannerViewWillClose(_ unifiedBannerView: GDTUnifiedBannerView) {
        print("🎯 Banner 广告被关闭")
        DispatchQueue.main.async {
            self.isBannerAdLoaded = false
            self.bannerAdView = nil

            // 发送广告关闭通知
            NotificationCenter.default.post(name: NSNotification.Name("BannerAdClosed"), object: nil)
            print("🎯 Banner 广告关闭通知已发送")
        }
    }
}
#endif

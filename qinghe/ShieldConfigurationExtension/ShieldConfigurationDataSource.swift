import ManagedSettings
import DeviceActivity
import Foundation

/// 自定义拦截界面配置（可选）
class ShieldConfigurationDataSource: ManagedSettingsUI.ShieldConfigurationDataSource {
    
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        ShieldConfiguration(
            title: .init(text: "专注模式中"),
            subtitle: .init(text: "请先完成自律时间目标～"),
            primaryButtonLabel: .init(text: "我知道了"),
            primaryButtonBackgroundColor: .blue
        )
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        configuration(shielding: application)
    }
    
    override func configuration(shieldingWebDomain webDomain: WebDomain) -> ShieldConfiguration {
        ShieldConfiguration(
            title: .init(text: "网页访问受限"),
            subtitle: .init(text: "该站点已在自律时间内限制访问"),
            primaryButtonLabel: .init(text: "返回"),
            primaryButtonBackgroundColor: .blue
        )
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        configuration(shieldingWebDomain: webDomain)
    }
}

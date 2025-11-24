import SwiftUI
#if canImport(React)
import React
#endif

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

// MARK: - React Native 容器视图（SwiftUI 中使用）

#if canImport(React)

/// 将 React Native 页面包装成 SwiftUI 视图，便于在任意页面中复用。
///
/// 对应 JS 侧 `AppRegistry.registerComponent("QingheRNEntry", ...)`
struct ReactNativeDemoView: UIViewControllerRepresentable {
    /// React Native 模块名，需与 JS 中注册的名称保持一致
    var moduleName: String = "QingheRNEntry"

    /// 传给 React Native 的初始参数（可根据需要扩展）
    var initialProperties: [String: Any] = [
        "source": "native-qinghe",
        "title": "来自原生的标题",
    ]

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view = makeReactRootView()
        vc.view.backgroundColor = UIColor.systemBackground
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let rootView = uiViewController.view as? RCTRootView {
            rootView.appProperties = initialProperties
        }
    }

    /// 创建 React Native 根视图
    private func makeReactRootView() -> UIView {
        #if DEBUG
        // 调试模式下，连接本地 Metro Server
        let jsBundleURL = RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
        #else
        // 发布模式下，从本地 main.jsbundle 加载（需配合打包脚本）
        let jsBundleURL = Bundle.main.url(forResource: "main", withExtension: "jsbundle")
        #endif

        guard let bundleURL = jsBundleURL else {
            fatalError("Could not find JS bundle")
        }
        let rootView = RCTRootView(
            bundleURL: bundleURL,
            moduleName: moduleName,
            initialProperties: initialProperties,
            launchOptions: nil
        )
        rootView.backgroundColor = UIColor.clear
        return rootView
    }
}

#else

/// 当还没有通过 CocoaPods 集成 React Native 时的占位视图。
struct ReactNativeDemoView: View {
    var body: some View {
        Text("React Native 未就绪：请先安装 npm 依赖并运行 pod install")
            .padding()
    }
}

#endif

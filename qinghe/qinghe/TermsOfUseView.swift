import SwiftUI
import WebKit

//  INLINE WebView 
private struct InlineWebView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        let web = WKWebView()
        web.load(URLRequest(url: url))
        return web
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}


struct TermsOfUseView: View {
    @Binding var navigationPath: NavigationPath
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            // Web 内容
            InlineWebView(url: URL(string: "https://www.yingwudaojiafuwuduan.cn/terms.html")!)
                .ignoresSafeArea(edges: .bottom)
        }
        .navigationBarHidden(true)
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                if navigationPath.isEmpty {
                    dismiss()
                } else {
                    navigationPath.removeLast()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("返回")
                        .font(.system(size: 17))
                }
                .foregroundColor(.green)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    // MARK: - 条款章节
    private func termsSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineSpacing(6)
        }
    }
}

#Preview {
    NavigationStack {
        TermsOfUseView(navigationPath: .constant(NavigationPath()))
    }
}

# 短视频播放器（自研）

## 概述

这是一个专门为短视频场景设计的自研播放器，类似抖音的播放体验。基于 AVPlayer 封装，提供了播放器池、预加载、智能缓存、手势控制等高级功能。

## 核心特性

### 1. **播放器池管理**
- 复用播放器实例，减少创建开销
- 最多保持 3 个播放器实例
- 自动清理最旧的播放器

### 2. **智能预加载**
- 自动预加载下一个和下下个视频
- Range 请求，只预加载前 10MB 数据
- 支持取消预加载任务

### 3. **缓存策略**
- 内存缓存：50 MB
- 磁盘缓存：200 MB
- 自动清理过期缓存

### 4. **手势控制**
- **双击**：播放/暂停
- **左右滑动**：调节播放进度
- **左侧上下滑动**：调节屏幕亮度
- **右侧上下滑动**：调节音量

### 5. **播放控制**
- 自动播放
- 循环播放
- 静音/取消静音
- 进度跳转
- 播放状态监听

## 文件结构

```
ShortVideoPlayer/
├── ShortVideoPlayerManager.swift      # 播放器管理器（单例）
├── ShortVideoPlayerView.swift         # 播放器视图组件
├── ShortVideoGestureControl.swift     # 手势控制组件
├── ShortVideoPreloadStrategy.swift    # 预加载策略
└── README.md                          # 说明文档
```

## 使用方法

### 基础使用

```swift
import SwiftUI

struct VideoDetailView: View {
    let videoURL: String
    
    var body: some View {
        ShortVideoPlayerView(
            videoURL: videoURL,
            autoPlay: true,
            loop: true,
            muted: false,
            showControls: false
        )
        .shortVideoGestureControl(playerManager: .shared)
        .ignoresSafeArea()
    }
}
```

### 高级使用

#### 1. 手动控制播放

```swift
let playerManager = ShortVideoPlayerManager.shared

// 播放视频
playerManager.play(
    url: "https://example.com/video.mp4",
    autoPlay: true,
    loop: true,
    muted: false
)

// 暂停
playerManager.pause()

// 恢复播放
playerManager.resume()

// 切换播放/暂停
playerManager.togglePlayPause()

// 跳转到指定时间
playerManager.seek(to: 10.0) // 跳转到 10 秒

// 设置静音
playerManager.setMuted(true)
```

#### 2. 预加载视频

```swift
let preloadStrategy = ShortVideoPreloadStrategy.shared

// 预加载视频列表
let videoURLs = [
    "https://example.com/video1.mp4",
    "https://example.com/video2.mp4",
    "https://example.com/video3.mp4"
]

preloadStrategy.preloadVideos(urls: videoURLs, currentIndex: 0)

// 检查是否已预加载
let isPreloaded = preloadStrategy.isPreloaded(url: videoURLs[1])

// 取消预加载
preloadStrategy.cancelPreload(url: videoURLs[2])

// 清空缓存
preloadStrategy.clearCache()

// 获取缓存大小
let cacheSize = preloadStrategy.getCacheSize() // 返回 MB
```

#### 3. 监听播放状态

```swift
struct VideoPlayerView: View {
    @ObservedObject var playerManager = ShortVideoPlayerManager.shared
    
    var body: some View {
        VStack {
            ShortVideoPlayerView(videoURL: "...")
            
            // 显示播放状态
            Text(playerManager.isPlaying ? "播放中" : "已暂停")
            
            // 显示缓冲状态
            if playerManager.isBuffering {
                ProgressView("缓冲中...")
            }
            
            // 显示播放进度
            Text("进度: \(Int(playerManager.progress * 100))%")
            
            // 显示时间
            Text("\(formatTime(playerManager.currentTime)) / \(formatTime(playerManager.duration))")
        }
    }
    
    func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
```

## 性能优化

### 1. 播放器池
- 复用播放器实例，避免频繁创建和销毁
- 最多保持 3 个播放器，自动清理最旧的

### 2. 预加载策略
- 只预加载下一个和下下个视频
- 使用 Range 请求，只加载前 10MB
- 支持取消不需要的预加载任务

### 3. 缓存管理
- 内存缓存 50MB，磁盘缓存 200MB
- 自动清理超出限制的缓存
- 使用 URLCache 进行缓存管理

### 4. 内存管理
- 使用 weak self 避免循环引用
- 及时移除观察者
- 页面消失时清理资源

## 与抖音的对比

| 功能 | 抖音 | 我们的播放器 | 状态 |
|------|------|-------------|------|
| 播放器池 | ✅ | ✅ | 已实现 |
| 预加载 | ✅ | ✅ | 已实现 |
| 缓存策略 | ✅ | ✅ | 已实现 |
| 手势控制 | ✅ | ✅ | 已实现 |
| 循环播放 | ✅ | ✅ | 已实现 |
| 无缝切换 | ✅ | ⚠️ | 部分实现 |
| 自适应码率 | ✅ | ❌ | 未实现 |
| 硬件加速 | ✅ | ✅ | 已实现（AVPlayer 自带）|

## 注意事项

### 1. 音量控制
iOS 不允许直接设置系统音量，需要使用 `MPVolumeView` 来实现。当前实现只是示意，实际应用中需要集成 `MPVolumeView`。

### 2. 内存管理
- 及时清理不需要的播放器
- 监控缓存大小，避免占用过多空间
- 页面消失时暂停播放

### 3. 网络优化
- 使用 Range 请求减少流量消耗
- 根据网络状况调整预加载策略
- 支持取消预加载任务

### 4. 线程安全
- 使用 `@MainActor` 确保 UI 更新在主线程
- 使用 `Task` 进行异步操作

## 未来优化方向

1. **自适应码率**：根据网络状况自动切换清晰度
2. **更智能的预加载**：根据用户行为预测需要预加载的视频
3. **P2P 加速**：使用 P2P 技术加速视频加载
4. **离线缓存**：支持下载视频到本地
5. **播放统计**：记录播放时长、完播率等数据

## 示例代码

完整的示例代码请参考 `PostDetailView.swift` 中的 `videoContentLayout` 函数。

## 技术支持

如有问题，请联系开发团队。


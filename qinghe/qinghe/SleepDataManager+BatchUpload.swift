import Foundation
import UIKit

// MARK: - SleepDataManager 批量上传扩展

extension SleepDataManager {
    
    /// 使用新的批量上传接口上传睡眠数据（创建睡眠会话，触发AI分析）
    func uploadSleepDataWithBatchAPI(session: LocalSleepSession) async {
        print("📤 准备使用批量上传接口上传睡眠数据...")
        
        guard let endTime = session.endTime else {
            print("⚠️ 睡眠会话未完成，跳过上传")
            return
        }
        
        // 计算睡眠时长
        let duration = endTime.timeIntervalSince(session.startTime)
        let durationMinutes = Int(duration / 60.0)
        
        print("📊 睡眠时长: \(durationMinutes)分钟")
        
        // 验证睡眠时长（至少需要1分钟）
        if durationMinutes < 1 {
            print("⚠️ 睡眠时长过短（\(String(format: "%.1f", duration))秒），需要至少1分钟才能上传到服务器")
            print("ℹ️ 数据已保存在本地，但不会上传到服务器")
            
            uploadStatusMessage = "睡眠时长过短（少于1分钟），数据已保存在本地"
            
            // 3秒后清除消息
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                uploadStatusMessage = nil
            }
            return
        }
        
        do {
            isUploading = true
            uploadStatusMessage = "正在上传睡眠数据..."
            
            // 1. 获取当前会话的音频文件
            let audioFiles = getCurrentSessionAudioFiles()
            print("📁 当前会话音频文件数: \(audioFiles.count)")
            
            // 2. 创建批量上传请求
            let uploadRequest = SleepBatchUploadRequest.from(
                localSession: session,
                audioFiles: audioFiles
            )
            
            // 3. 调用批量上传API
            print("🚀 开始批量上传...")
            let response = try await SleepAPIService.shared.uploadSleepSessionBatch(uploadRequest)
            
            print("✅ 睡眠会话创建成功")
            print("   - Session ID: \(response.data.sessionId)")
            print("   - Upload ID: \(response.data.uploadId)")
            print("   - 处理状态: \(response.data.processingStatus)")
            
            // 4. 上传音频文件到OSS
            if let audioUploadUrls = response.data.audioUploadUrls, !audioUploadUrls.isEmpty {
                uploadStatusMessage = "正在上传音频文件..."
                print("📤 开始上传 \(audioUploadUrls.count) 个音频文件到OSS...")
                
                for (index, audioUploadUrl) in audioUploadUrls.enumerated() {
                    // 查找对应的本地音频文件
                    if let audioFile = audioFiles.first(where: { $0.id.uuidString == audioUploadUrl.localFileId }) {
                        do {
                            // 读取音频文件数据
                            let fileData = try audioFile.getFileData()
                            
                            // 上传到OSS
                            try await SleepAPIService.shared.uploadAudioToOSS(
                                fileData: fileData,
                                uploadUrl: audioUploadUrl.uploadUrl
                            )
                            
                            print("✅ [\(index + 1)/\(audioUploadUrls.count)] 音频文件上传成功: \(audioFile.fileName)")
                            
                            // 更新上传进度
                            let progress = Double(index + 1) / Double(audioUploadUrls.count)
                            uploadStatusMessage = String(format: "上传音频文件 %d/%d (%.0f%%)", 
                                                        index + 1, 
                                                        audioUploadUrls.count, 
                                                        progress * 100)
                            
                        } catch {
                            print("❌ [\(index + 1)/\(audioUploadUrls.count)] 音频文件上传失败: \(audioFile.fileName)")
                            print("   错误: \(error.localizedDescription)")
                        }
                    } else {
                        print("⚠️ 未找到本地音频文件: \(audioUploadUrl.localFileId)")
                    }
                }
            }
            
            // 5. 轮询处理状态
            uploadStatusMessage = "AI正在分析睡眠数据..."
            print("🔄 开始轮询处理状态...")
            
            var isProcessing = true
            var pollCount = 0
            let maxPollCount = 60  // 最多轮询60次（3分钟）
            
            while isProcessing && pollCount < maxPollCount {
                try await Task.sleep(nanoseconds: 3_000_000_000)  // 等待3秒
                pollCount += 1
                
                do {
                    let statusResponse = try await SleepAPIService.shared.getProcessingStatus(
                        uploadId: response.data.uploadId
                    )
                    
                    let status = statusResponse.data.processingStatus
                    let progress = statusResponse.data.progress
                    
                    print("📊 处理进度: \(progress)% - 状态: \(status)")
                    uploadStatusMessage = String(format: "AI分析中... %d%%", progress)
                    
                    if status == "completed" {
                        isProcessing = false
                        print("✅ AI分析完成")
                        uploadStatusMessage = "✅ 睡眠数据已同步，AI分析完成"

                        // 注意：本地记录的 sessionId 更新和重新加载会在主 SleepDataManager 中处理
                        // 这里只负责上传和AI分析流程

                    } else if status == "failed" {
                        isProcessing = false
                        print("❌ AI分析失败")
                        uploadStatusMessage = "数据已上传，但AI分析失败"
                    }
                    
                } catch {
                    print("⚠️ 查询处理状态失败: \(error.localizedDescription)")
                    // 继续轮询
                }
            }
            
            if pollCount >= maxPollCount {
                print("⚠️ 处理超时，但数据已上传")
                uploadStatusMessage = "数据已上传，AI分析可能需要更长时间"
            }
            
        } catch {
            print("❌ 睡眠数据批量上传失败: \(error.localizedDescription)")
            uploadStatusMessage = "上传失败: \(error.localizedDescription)"
        }
        
        isUploading = false
        
        // 5秒后清除状态消息
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            uploadStatusMessage = nil
        }
    }
}


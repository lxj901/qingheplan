//
//  VoiceSelectionSheet.swift
//  qinghe
//
//  音色选择组件
//

import SwiftUI

struct VoiceSelectionSheet: View {
    @ObservedObject var audioPlayer = GlobalAudioPlayer.shared
    @State private var voices: [TTSVoice] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            ZStack {
                // 背景色
                Color(red: 0.98, green: 0.96, blue: 0.94)
                    .ignoresSafeArea()

                if isLoading {
                    // 加载中
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("加载音色列表...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                } else if let error = errorMessage {
                    // 错误提示
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)

                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button("重试") {
                            Task {
                                await loadVoices()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else {
                    // 音色列表
                    ScrollView {
                        VStack(spacing: 0) {
                            // 推荐音色
                            let recommendedVoices = voices.filter { $0.isRecommended }
                            if !recommendedVoices.isEmpty {
                                sectionHeader(title: "推荐音色")

                                ForEach(recommendedVoices) { voice in
                                    voiceRow(voice)
                                    if voice.id != recommendedVoices.last?.id {
                                        Divider()
                                            .padding(.leading, 60)
                                    }
                                }
                            }

                            // 方言音色
                            let dialectVoices = voices.filter { !$0.isRecommended }
                            if !dialectVoices.isEmpty {
                                sectionHeader(title: "方言音色")
                                    .padding(.top, 24)

                                ForEach(dialectVoices) { voice in
                                    voiceRow(voice)
                                    if voice.id != dialectVoices.last?.id {
                                        Divider()
                                            .padding(.leading, 60)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("选择音色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
        }
        .task {
            await loadVoices()
        }
    }

    // MARK: - 分区标题
    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    // MARK: - 音色行
    private func voiceRow(_ voice: TTSVoice) -> some View {
        Button(action: {
            audioPlayer.selectedVoice = voice.voiceId
            isPresented = false
        }) {
            HStack(spacing: 16) {
                // 音色图标
                ZStack {
                    Circle()
                        .fill(audioPlayer.selectedVoice == voice.voiceId ?
                              Color.blue.opacity(0.1) :
                              Color.gray.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: voice.gender == "female" ? "person.fill" : "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(audioPlayer.selectedVoice == voice.voiceId ?
                                       .blue : .gray)
                }

                // 音色信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(voice.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)

                    Text(voice.description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // 选中标记
                if audioPlayer.selectedVoice == voice.voiceId {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 加载音色列表
    private func loadVoices() async {
        isLoading = true
        errorMessage = nil

        do {
            voices = try await ClassicsAPIService.shared.getTTSVoices()
            isLoading = false
            print("✅ 成功加载音色列表: \(voices.count) 个")
        } catch {
            isLoading = false
            errorMessage = "加载失败: \(error.localizedDescription)"
            print("❌ 加载音色失败: \(error)")
        }
    }
}

// MARK: - 预览
struct VoiceSelectionSheet_Previews: PreviewProvider {
    static var previews: some View {
        VoiceSelectionSheet(isPresented: .constant(true))
    }
}

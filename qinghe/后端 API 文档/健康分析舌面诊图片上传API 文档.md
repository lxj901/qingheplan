# 健康分析图片上传API集成指南

## 后端API
## 服务器地址
- **生产环境**: `https://api.qinghejihua.com.cn`
### API 版本
- **版本**: v1
- **基础路径**: `/api/v1`
### 1. 健康分析图片上传
**POST** `/api/v1/upload/health`

上传用于面部分析、舌诊等健康分析的图片。

#### 请求参数
- **Content-Type**: `multipart/form-data`
- **Authorization**: `Bearer {token}`
- **Body**: 
  - `healthImage` (file): 图片文件

#### 响应格式
```json
{
  "success": true,
  "data": {
    "url": "https://qinghe-sleep-audio.oss-cn-beijing.aliyuncs.com/health/uuid-filename.jpg",
    "thumbnails": {
      "small": "https://...?x-oss-process=image/resize,w_200,h_200",
      "medium": "https://...?x-oss-process=image/resize,w_400,h_400", 
      "large": "https://...?x-oss-process=image/resize,w_800,h_800"
    },
    "filename": "uuid-filename.jpg",
    "originalName": "face-photo.jpg",
    "size": 1234567,
    "mimetype": "image/jpeg",
    "provider": "aliyun",
    "metadata": {
      "width": 1920,
      "height": 1080,
      "format": "jpeg"
    },
    "category": "health_analysis"
  },
  "message": "健康分析图片上传成功"
}
```

### 2. 面部分析
**POST** `/api/v1/health/face/analyze`

使用上传的图片URL进行面部分析。

#### 请求参数
```json
{
  "imageUrl": "https://qinghe-sleep-audio.oss-cn-beijing.aliyuncs.com/health/uuid-filename.jpg",
  "userNotes": "面部分析备注（可选）"
}
```

## 前端集成流程

### iOS Swift 示例

```swift
// 1. 拍照或选择图片后，先上传到OSS
func uploadHealthImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
        completion(.failure(NetworkError.invalidData))
        return
    }
    
    let url = URL(string: "\(APIConstants.baseURL)/upload/health")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(UserDefaults.standard.string(forKey: "auth_token") ?? "")", 
                     forHTTPHeaderField: "Authorization")
    
    let boundary = UUID().uuidString
    request.setValue("multipart/form-data; boundary=\(boundary)", 
                     forHTTPHeaderField: "Content-Type")
    
    var body = Data()
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"healthImage\"; filename=\"face-photo.jpg\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
    body.append(imageData)
    body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
    
    request.httpBody = body
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let dataDict = json["data"] as? [String: Any],
           let imageUrl = dataDict["url"] as? String {
            completion(.success(imageUrl))
        } else {
            completion(.failure(NetworkError.invalidResponse))
        }
    }.resume()
}

// 2. 使用返回的URL进行面部分析
func analyzeFace(imageUrl: String, completion: @escaping (Result<FaceAnalysisResult, Error>) -> Void) {
    let url = URL(string: "\(APIConstants.baseURL)/health/face/analyze")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(UserDefaults.standard.string(forKey: "auth_token") ?? "")", 
                     forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let requestBody = [
        "imageUrl": imageUrl,
        "userNotes": "iOS面部分析"
    ]
    
    request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        if let data = data {
            do {
                let result = try JSONDecoder().decode(FaceAnalysisResponse.self, from: data)
                if result.success {
                    completion(.success(result.data))
                } else {
                    completion(.failure(NetworkError.apiError(result.msg)))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }.resume()
}

// 3. 完整的面部分析流程
func performFaceAnalysis(image: UIImage) {
    // 显示上传进度
    showLoadingIndicator("上传图片中...")
    
    uploadHealthImage(image) { [weak self] result in
        switch result {
        case .success(let imageUrl):
            DispatchQueue.main.async {
                self?.showLoadingIndicator("分析中...")
            }
            
            self?.analyzeFace(imageUrl: imageUrl) { analysisResult in
                DispatchQueue.main.async {
                    self?.hideLoadingIndicator()
                    
                    switch analysisResult {
                    case .success(let result):
                        self?.displayAnalysisResult(result)
                    case .failure(let error):
                        self?.showError("分析失败: \(error.localizedDescription)")
                    }
                }
            }
            
        case .failure(let error):
            DispatchQueue.main.async {
                self?.hideLoadingIndicator()
                self?.showError("图片上传失败: \(error.localizedDescription)")
            }
        }
    }
}
```

### 数据模型

```swift
struct FaceAnalysisResponse: Codable {
    let code: Int
    let success: Bool
    let msg: String
    let data: FaceAnalysisResult
}

struct FaceAnalysisResult: Codable {
    let score: Int
    let physiqueName: String
    let physiqueAnalysis: String
    let typicalSymptom: String
    let riskWarning: String
    let features: [AnalysisFeature]
    let syndromeName: String
    let syndromeIntroduction: String
    let advices: HealthAdvices
    let goods: [String]
    let originalImageUrl: String
    let analyzedAt: String
    let analysisStatus: String
    let apiProvider: String
    
    enum CodingKeys: String, CodingKey {
        case score
        case physiqueName = "physique_name"
        case physiqueAnalysis = "physique_analysis"
        case typicalSymptom = "typical_symptom"
        case riskWarning = "risk_warning"
        case features
        case syndromeName = "syndrome_name"
        case syndromeIntroduction = "syndrome_introduction"
        case advices
        case goods
        case originalImageUrl
        case analyzedAt
        case analysisStatus
        case apiProvider
    }
}

struct AnalysisFeature: Codable {
    let name: String
    let value: String
    let desc: String
    let status: String
    let confidence: Double
}

struct HealthAdvices: Codable {
    let dietAdvice: DietAdvice
    let therapyMethods: [String]
    let exerciseAdvice: [String]
    let sleepAdvice: [String]
    let lifestyleAdvice: [String]
    let emotionRegulation: [String]
    let musicTherapy: [String]
    let tcmTreatment: [String]
    
    enum CodingKeys: String, CodingKey {
        case dietAdvice = "饮食建议"
        case therapyMethods = "食疗方"
        case exerciseAdvice = "运动建议"
        case sleepAdvice = "睡眠/起居"
        case lifestyleAdvice = "生活习惯"
        case emotionRegulation = "情志调节"
        case musicTherapy = "音乐疗法"
        case tcmTreatment = "中医调理"
    }
}

struct DietAdvice: Codable {
    let recommended: [String]
    let forbidden: [String]
    
    enum CodingKeys: String, CodingKey {
        case recommended = "推荐"
        case forbidden = "禁忌"
    }
}
```

## 使用注意事项

1. **图片要求**：
   - 支持格式：JPEG, PNG, WebP
   - 最大文件大小：10MB
   - 建议尺寸：800x800 以上
   - 面部图片需要清晰、光线充足

2. **错误处理**：
   - 网络超时：设置合理的超时时间（60秒以上）
   - 上传失败：提供重试机制
   - 分析失败：显示友好的错误提示

3. **用户体验**：
   - 显示上传和分析进度
   - 提供图片预览功能
   - 缓存分析结果避免重复请求

4. **安全性**：
   - 所有图片上传到阿里云OSS私有空间
   - 图片URL包含访问凭证，有效期限制
   - 分析完成后可选择性删除图片

## API测试

```bash
# 1. 上传健康分析图片
curl -X POST "https://api.qinghejihua.com.cn/api/v1/upload/health" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "healthImage=@face-photo.jpg"

# 2. 面部分析
curl -X POST "https://api.qinghejihua.com.cn/api/v1/health/face/analyze" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "imageUrl": "https://qinghe-sleep-audio.oss-cn-beijing.aliyuncs.com/health/xxx.jpg",
    "userNotes": "测试面部分析"
  }'
```
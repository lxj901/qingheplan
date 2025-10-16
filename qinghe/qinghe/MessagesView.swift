import SwiftUI

// MARK: - 多语言管理器
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: String = "zh-Hans"

    private init() {
        // 从 UserDefaults 读取保存的语言设置
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") {
            currentLanguage = savedLanguage
        }
    }

    func setLanguage(_ language: String) {
        currentLanguage = language
        UserDefaults.standard.set(language, forKey: "selectedLanguage")
        objectWillChange.send()
    }

    func localizedString(key: String) -> String {
        return LocalizedStrings.getString(key: key, language: currentLanguage)
    }
}

// MARK: - 本地化字符串
struct LocalizedStrings {
    static func getString(key: String, language: String) -> String {
        switch language {
        case "zh-Hans":
            return getChineseSimplified(key: key)
        case "zh-Hant":
            return getChineseTraditional(key: key)
        case "en":
            return getEnglish(key: key)
        case "ja":
            return getJapanese(key: key)
        case "ko":
            return getKorean(key: key)
        default:
            return getChineseSimplified(key: key)
        }
    }

    // 简体中文
    private static func getChineseSimplified(key: String) -> String {
        switch key {
        // 设置相关
        case "settings": return "设置"
        case "account_security": return "账户与安全"
        case "account_and_security": return "账号与安全"
        case "privacy_settings": return "隐私设置"
        case "personalization": return "个性化"
        case "background_settings": return "背景设置"
        case "font_size": return "字体大小"
        case "multi_language": return "多语言"
        case "storage_permissions": return "存储与权限"
        case "clear_cache": return "清理缓存"
        case "system_permissions": return "系统权限"
        case "about_help": return "关于与帮助"
        case "about_qinghe": return "关于青禾计划"
        case "ad_info": return "了解广告推送"
        case "feedback_help": return "反馈与帮助"
        case "rules_agreements": return "规则与协议"
        case "user_agreement": return "用户协议"
        case "community_convention": return "社区公约"
        case "service_terms": return "服务条款"
        case "privacy_policy": return "隐私政策"
        case "qualifications": return "证照信息"
        case "privacy_info": return "隐私信息"
        case "personal_info_list": return "个人信息收集清单"
        case "third_party_info_list": return "第三方信息共享清单"
        case "logout": return "退出登录"
        
        // 底部导航栏
        case "tab_home": return "首页"
        case "tab_record": return "记录"
        case "tab_health": return "健康"
        case "tab_workout": return "运动"
        case "tab_listening": return "听音"
        case "tab_community": return "社区"
        case "tab_messages": return "消息"
        case "tab_profile": return "我的"
        
        // 通用
        case "loading": return "加载中..."
        case "getting_user_info": return "正在获取用户信息"
        case "not_logged_in": return "未登录"
        case "please_login": return "请先登录"
        case "please_login_to_view_profile": return "请先登录以查看个人资料"
        case "unbound_phone": return "未绑定手机"
        case "qinghe_user": return "青禾用户"
        case "confirm": return "确认"
        case "cancel": return "取消"
        case "save": return "保存"
        case "delete": return "删除"
        case "edit": return "编辑"
        case "done": return "完成"
        case "back": return "返回"
        case "next": return "下一步"
        case "submit": return "提交"
        case "refresh": return "刷新"
        case "search": return "搜索"
        case "filter": return "筛选"
        case "sort": return "排序"
        case "share": return "分享"
        case "close": return "关闭"
        case "open": return "打开"
        case "add": return "添加"
        case "remove": return "移除"
        case "send": return "发送"
        case "receive": return "接收"
        case "view": return "查看"
        case "download": return "下载"
        case "upload": return "上传"
        case "retry": return "重试"
        case "continue": return "继续"
        case "skip": return "跳过"
        case "select": return "选择"
        case "select_action": return "选择操作"
        case "select_all": return "全选"
        case "deselect_all": return "取消全选"
        case "copy": return "复制"
        case "paste": return "粘贴"
        case "cut": return "剪切"
        case "undo": return "撤销"
        case "redo": return "重做"
        case "clear": return "清空"
        case "reset": return "重置"
        case "apply": return "应用"
        case "enable": return "启用"
        case "disable": return "禁用"
        case "yes": return "是"
        case "no": return "否"
        case "ok": return "好的"
        case "success": return "成功"
        case "failed": return "失败"
        case "error": return "错误"
        case "warning": return "警告"
        case "info": return "信息"
        case "tip": return "提示"
        case "notice": return "通知"
        case "today": return "今天"
        case "yesterday": return "昨天"
        case "tomorrow": return "明天"
        case "week": return "周"
        case "month": return "月"
        case "year": return "年"
        case "day": return "天"
        case "hour": return "小时"
        case "minute": return "分钟"
        case "second": return "秒"
        case "am": return "上午"
        case "pm": return "下午"
        case "all": return "全部"
        case "none": return "无"
        case "other": return "其他"
        case "more": return "更多"
        case "less": return "收起"
        case "detail": return "详情"
        case "description": return "描述"
        case "title": return "标题"
        case "content": return "内容"
        case "comment": return "评论"
        case "reply": return "回复"
        case "like": return "点赞"
        case "unlike": return "取消点赞"
        case "favorite": return "收藏"
        case "unfavorite": return "取消收藏"
        case "follow": return "关注"
        case "unfollow": return "取消关注"
        case "block": return "拉黑"
        case "unblock": return "取消拉黑"
        case "report": return "举报"
        case "hide": return "隐藏"
        case "show": return "显示"
        case "expand": return "展开"
        case "collapse": return "收起"
        
        // 社区相关
        case "community": return "社区"
        case "post": return "帖子"
        case "publish": return "发布"
        case "publish_post": return "发帖"
        case "edit_post": return "编辑帖子"
        case "delete_post": return "删除帖子"
        case "post_detail": return "帖子详情"
        case "hot": return "热门"
        case "latest": return "最新"
        case "following": return "关注"
        case "recommend": return "推荐"
        case "ai_generated_content": return "此内容由AI生成，仅供参考"
        case "checkin_record": return "打卡记录"
        case "workout_record": return "运动记录"
        case "time": return "时间"
        case "location": return "地点"
        case "note": return "备注"
        case "consecutive": return "连续"
        case "consecutive_days": return "连续打卡 %d 天"
        case "type": return "类型"
        case "duration": return "时长"
        case "distance": return "距离"
        case "calories": return "卡路里"
        case "steps": return "步数"
        case "tag": return "标签"
        case "topic": return "话题"
        case "add_topic": return "添加话题"
        case "select_topic": return "选择话题"
        case "create_topic": return "创建话题"
        case "trending": return "热搜"
        case "popular": return "流行"
        case "views": return "浏览"
        case "likes": return "点赞"
        case "comments": return "评论"
        case "shares": return "分享"
        case "bookmarks": return "收藏"
        case "followers": return "粉丝"
        case "following_list": return "关注列表"
        case "follower_list": return "粉丝列表"
        case "mutual_followers": return "互相关注"
        case "add_image": return "添加图片"
        case "add_video": return "添加视频"
        case "add_location": return "添加位置"
        case "select_privacy": return "选择隐私"
        case "public": return "公开"
        case "private": return "私密"
        case "friends_only": return "仅好友可见"
        case "report_post": return "举报帖子"
        case "report_user": return "举报用户"
        case "report_comment": return "举报评论"
        case "report_reason": return "举报原因"
        case "spam": return "垃圾信息"
        case "inappropriate": return "不当内容"
        case "harassment": return "骚扰"
        case "violence": return "暴力"
        case "hate_speech": return "仇恨言论"
        case "misinformation": return "虚假信息"
        case "copyright": return "版权侵犯"
        
        // 聊天和消息
        case "messages": return "消息"
        case "chat": return "聊天"
        case "new_chat": return "新建聊天"
        case "new_group": return "新建群组"
        case "group_chat": return "群聊"
        case "private_chat": return "私聊"
        case "message": return "消息"
        case "send_message": return "发送消息"
        case "type_message": return "输入消息"
        case "voice_message": return "语音消息"
        case "image_message": return "图片消息"
        case "video_message": return "视频消息"
        case "file_message": return "文件消息"
        case "location_message": return "位置消息"
        case "emoji": return "表情"
        case "sticker": return "贴纸"
        case "gif": return "动图"
        case "read": return "已读"
        case "unread": return "未读"
        case "delivered": return "已送达"
        case "sending": return "发送中"
        case "failed_to_send": return "发送失败"
        case "typing": return "正在输入..."
        case "online": return "在线"
        case "offline": return "离线"
        case "last_seen": return "最后在线"
        case "group_members": return "群成员"
        case "add_members": return "添加成员"
        case "remove_member": return "移除成员"
        case "group_name": return "群名称"
        case "group_description": return "群描述"
        case "group_avatar": return "群头像"
        case "mute_notifications": return "消息免打扰"
        case "unmute_notifications": return "取消免打扰"
        case "pin_chat": return "置顶聊天"
        case "unpin_chat": return "取消置顶"
        case "delete_chat": return "删除聊天"
        case "leave_group": return "退出群组"
        case "group_admin": return "群管理员"
        case "make_admin": return "设为管理员"
        case "dismiss_admin": return "取消管理员"
        
        // 健康相关
        case "health": return "健康"
        case "health_manager": return "健康管理"
        case "health_assistant": return "健康助手"
        case "health_report": return "健康报告"
        case "health_data": return "健康数据"
        case "health_record": return "健康档案"
        case "constitution_analysis": return "体质分析"
        case "diagnosis": return "诊断"
        case "tongue_diagnosis": return "舌诊"
        case "face_diagnosis": return "面诊"
        case "diagnosis_history": return "诊断历史"
        case "wuyun_liuqi": return "五运六气"
        case "wuyun_zhuyun": return "五运主运"
        case "symptoms": return "症状"
        case "suggestions": return "建议"
        case "recommendations": return "推荐"
        case "analysis": return "分析"
        case "trend": return "趋势"
        case "overview": return "概览"
        case "details": return "详细信息"
        case "history": return "历史"
        case "records": return "记录"
        
        // 睡眠相关
        case "sleep": return "睡眠"
        case "sleep_tracking": return "睡眠追踪"
        case "sleep_dashboard": return "睡眠仪表盘"
        case "sleep_detail": return "睡眠详情"
        case "sleep_records": return "睡眠记录"
        case "sleep_insights": return "睡眠洞察"
        case "sleep_analysis": return "睡眠分析"
        case "sleep_quality": return "睡眠质量"
        case "sleep_duration": return "睡眠时长"
        case "deep_sleep": return "深睡眠"
        case "light_sleep": return "浅睡眠"
        case "rem_sleep": return "快速眼动睡眠"
        case "awake": return "清醒"
        case "sleep_score": return "睡眠评分"
        case "bedtime": return "就寝时间"
        case "wake_time": return "起床时间"
        case "sleep_goal": return "睡眠目标"
        case "sleep_tips": return "睡眠建议"
        case "white_noise": return "白噪音"
        case "meditation": return "冥想"
        case "relaxation": return "放松"
        
        // 运动相关
        case "workout": return "运动"
        case "workout_mode": return "运动模式"
        case "workout_live": return "运动直播"
        case "workout_detail": return "运动详情"
        case "workout_analysis": return "运动分析"
        case "workout_completion": return "运动完成"
        case "workout_history": return "运动历史"
        case "workout_records": return "运动记录"
        case "workout_type": return "运动类型"
        case "workout_duration": return "运动时长"
        case "workout_distance": return "运动距离"
        case "workout_calories": return "消耗卡路里"
        case "workout_speed": return "速度"
        case "workout_pace": return "配速"
        case "workout_heart_rate": return "心率"
        case "workout_steps": return "步数"
        case "workout_route": return "运动路线"
        case "start_workout": return "开始运动"
        case "pause_workout": return "暂停运动"
        case "resume_workout": return "继续运动"
        case "finish_workout": return "结束运动"
        case "cancel_workout": return "取消运动"
        case "save_workout": return "保存运动"
        case "delete_workout": return "删除运动"
        case "workout_ai_coach": return "AI 教练"
        case "workout_camera": return "运动相机"
        
        // 记录中心
        case "record_center": return "记录中心"
        case "emotion_record": return "情绪记录"
        case "temptation_record": return "诱惑记录"
        case "plan_management": return "计划管理"
        case "create_record": return "创建记录"
        case "record_history": return "记录历史"
        case "emotion": return "情绪"
        case "mood": return "心情"
        case "feeling": return "感受"
        case "temptation": return "诱惑"
        case "resistance": return "抵抗"
        case "plan": return "计划"
        case "goal": return "目标"
        case "progress": return "进度"
        case "achievement": return "成就"
        case "streak": return "连续"
        case "self_discipline": return "自律"
        case "self_discipline_status": return "自律状态"
        case "gongguo": return "功过"
        case "gongguo_record": return "功过记录"
        case "merit": return "功德"
        case "demerit": return "过失"
        case "checkin": return "打卡"
        case "checkin_calendar": return "打卡日历"
        case "checkin_history": return "打卡历史"
        case "daily_checkin": return "每日打卡"
        
        // 音频和冥想
        case "listening": return "听音"
        case "audio": return "音频"
        case "music": return "音乐"
        case "playlist": return "播放列表"
        case "player": return "播放器"
        case "now_playing": return "正在播放"
        case "play": return "播放"
        case "pause": return "暂停"
        case "stop": return "停止"
        case "previous": return "上一首"
        case "next_track": return "下一首"
        case "repeat": return "循环"
        case "shuffle": return "随机"
        case "volume": return "音量"
        case "wuyin_playlists": return "五音播放列表"
        case "wuyin_player": return "五音播放器"
        case "gongfa_courses": return "功法课程"
        case "gongfa_course_detail": return "功法课程详情"
        case "casual_listening": return "随便听听"
        
        // 计划相关
        case "create_plan": return "创建计划"
        case "edit_plan": return "编辑计划"
        case "delete_plan": return "删除计划"
        case "plan_detail": return "计划详情"
        case "plan_title": return "计划标题"
        case "plan_description": return "计划描述"
        case "plan_start_date": return "开始日期"
        case "plan_end_date": return "结束日期"
        case "plan_reminder": return "计划提醒"
        case "plan_status": return "计划状态"
        case "plan_progress": return "计划进度"
        case "active_plan": return "进行中的计划"
        case "completed_plan": return "已完成的计划"
        case "cancelled_plan": return "已取消的计划"
        
        // 会员和订阅
        case "membership": return "会员"
        case "membership_center": return "会员中心"
        case "subscribe": return "订阅"
        case "subscription": return "订阅"
        case "premium": return "高级会员"
        case "vip": return "VIP"
        case "free": return "免费"
        case "trial": return "试用"
        case "purchase": return "购买"
        case "renew": return "续费"
        case "upgrade": return "升级"
        case "downgrade": return "降级"
        case "cancel_subscription": return "取消订阅"
        case "subscription_status": return "订阅状态"
        case "subscription_expires": return "订阅到期"
        case "auto_renew": return "自动续费"
        case "payment_method": return "支付方式"
        case "billing_history": return "账单历史"
        case "price": return "价格"
        case "discount": return "折扣"
        case "coupon": return "优惠券"
        case "redeem": return "兑换"
        
        // 通知和权限
        case "notifications": return "通知"
        case "notification_settings": return "通知设置"
        case "push_notifications": return "推送通知"
        case "enable_notifications": return "启用通知"
        case "disable_notifications": return "禁用通知"
        case "notification_permission": return "通知权限"
        case "camera_permission": return "相机权限"
        case "microphone_permission": return "麦克风权限"
        case "location_permission": return "定位权限"
        case "photo_library_permission": return "相册权限"
        case "contacts_permission": return "通讯录权限"
        case "calendar_permission": return "日历权限"
        case "reminder_permission": return "提醒权限"
        case "health_permission": return "健康权限"
        case "motion_permission": return "运动权限"
        case "permission_denied": return "权限被拒绝"
        case "permission_required": return "需要权限"
        case "grant_permission": return "授予权限"
        case "go_to_settings": return "前往设置"
        
        // 用户资料
        case "profile": return "个人资料"
        case "user_profile": return "用户资料"
        case "edit_profile": return "编辑资料"
        case "username": return "用户名"
        case "nickname": return "昵称"
        case "bio": return "个人简介"
        case "avatar": return "头像"
        case "cover": return "封面"
        case "gender": return "性别"
        case "male": return "男"
        case "female": return "女"
        case "birthday": return "生日"
        case "age": return "年龄"
        case "location": return "位置"
        case "website": return "网站"
        case "email": return "邮箱"
        case "phone": return "手机"
        case "verified": return "已认证"
        case "not_verified": return "未认证"
        case "posts": return "帖子"
        case "photos": return "照片"
        case "videos": return "视频"
        case "moments": return "动态"
        
        // 登录和注册
        case "login": return "登录"
        case "register": return "注册"
        case "logout_confirm": return "确认退出登录？"
        case "sign_in": return "登录"
        case "sign_up": return "注册"
        case "sign_out": return "退出"
        case "forgot_password": return "忘记密码"
        case "reset_password": return "重置密码"
        case "change_password": return "修改密码"
        case "old_password": return "旧密码"
        case "new_password": return "新密码"
        case "confirm_password": return "确认密码"
        case "password": return "密码"
        case "password_required": return "请输入密码"
        case "username_required": return "请输入用户名"
        case "email_required": return "请输入邮箱"
        case "phone_required": return "请输入手机号"
        case "verification_code": return "验证码"
        case "send_code": return "发送验证码"
        case "resend_code": return "重新发送"
        case "agree_to_terms": return "同意用户协议和隐私政策"
        case "already_have_account": return "已有账号？"
        case "dont_have_account": return "还没有账号？"
        case "login_with_wechat": return "微信登录"
        case "login_with_phone": return "手机号登录"
        case "login_with_email": return "邮箱登录"
        
        // 搜索相关
        case "search_placeholder": return "搜索..."
        case "search_history": return "搜索历史"
        case "clear_history": return "清空历史"
        case "no_results": return "无结果"
        case "search_users": return "搜索用户"
        case "search_posts": return "搜索帖子"
        case "search_tags": return "搜索标签"
        
        // 错误和提示
        case "network_error": return "网络错误"
        case "server_error": return "服务器错误"
        case "unknown_error": return "未知错误"
        case "please_try_again": return "请重试"
        case "operation_failed": return "操作失败"
        case "operation_successful": return "操作成功"
        case "saved_successfully": return "保存成功"
        case "deleted_successfully": return "删除成功"
        case "updated_successfully": return "更新成功"
        case "sent_successfully": return "发送成功"
        case "upload_failed": return "上传失败"
        case "download_failed": return "下载失败"
        case "invalid_input": return "无效输入"
        case "required_field": return "必填项"
        case "too_long": return "内容过长"
        case "too_short": return "内容过短"
        case "no_data": return "暂无数据"
        case "no_more_data": return "没有更多数据"
        case "pull_to_refresh": return "下拉刷新"
        case "release_to_refresh": return "释放刷新"
        case "refreshing": return "刷新中..."
        case "loading_more": return "加载更多..."
        
        // 存储和缓存
        case "storage": return "存储"
        case "cache": return "缓存"
        case "cache_size": return "缓存大小"
        case "clear_cache_confirm": return "确认清理缓存？"
        case "cache_cleared": return "缓存已清理"
        case "storage_usage": return "存储使用情况"
        case "free_space": return "可用空间"
        case "used_space": return "已用空间"
        
        // 其他
        case "version": return "版本"
        case "update": return "更新"
        case "check_update": return "检查更新"
        case "latest_version": return "最新版本"
        case "new_version_available": return "发现新版本"
        case "download_update": return "下载更新"
        case "install_update": return "安装更新"
        case "rate_app": return "评分"
        case "share_app": return "分享应用"
        case "terms_of_service": return "服务条款"
        case "privacy_policy": return "隐私政策"
        case "contact_us": return "联系我们"
        case "customer_service": return "客服"
        case "faq": return "常见问题"
        case "tutorial": return "教程"
        case "guide": return "指南"
        case "help": return "帮助"
        case "about": return "关于"
        case "language": return "语言"
        case "theme": return "主题"
        case "dark_mode": return "深色模式"
        case "light_mode": return "浅色模式"
        case "auto_mode": return "跟随系统"
        
        default: return key
        }
    }

    // 繁体中文
    private static func getChineseTraditional(key: String) -> String {
        switch key {
        // 設置相關
        case "settings": return "設置"
        case "account_security": return "賬戶與安全"
        case "account_and_security": return "賬號與安全"
        case "privacy_settings": return "隱私設置"
        case "personalization": return "個性化"
        case "background_settings": return "背景設置"
        case "font_size": return "字體大小"
        case "multi_language": return "多語言"
        case "storage_permissions": return "存儲與權限"
        case "clear_cache": return "清理緩存"
        case "system_permissions": return "系統權限"
        case "about_help": return "關於與幫助"
        case "about_qinghe": return "關於青禾計劃"
        case "ad_info": return "了解廣告推送"
        case "feedback_help": return "反饋與幫助"
        case "rules_agreements": return "規則與協議"
        case "user_agreement": return "用戶協議"
        case "community_convention": return "社區公約"
        case "service_terms": return "服務條款"
        case "privacy_policy": return "隱私政策"
        case "qualifications": return "證照信息"
        case "privacy_info": return "隱私信息"
        case "personal_info_list": return "個人信息收集清單"
        case "third_party_info_list": return "第三方信息共享清單"
        case "logout": return "退出登錄"
        
        // 底部導航欄
        case "tab_home": return "首頁"
        case "tab_record": return "記錄"
        case "tab_health": return "健康"
        case "tab_workout": return "運動"
        case "tab_listening": return "聽音"
        case "tab_community": return "社區"
        case "tab_messages": return "消息"
        case "tab_profile": return "我的"
        
        // 通用
        case "loading": return "加載中..."
        case "getting_user_info": return "正在獲取用戶信息"
        case "not_logged_in": return "未登錄"
        case "please_login": return "請先登錄"
        case "please_login_to_view_profile": return "請先登錄以查看個人資料"
        case "unbound_phone": return "未綁定手機"
        case "qinghe_user": return "青禾用戶"
        case "confirm": return "確認"
        case "cancel": return "取消"
        case "save": return "保存"
        case "delete": return "刪除"
        case "edit": return "編輯"
        case "done": return "完成"
        case "back": return "返回"
        case "next": return "下一步"
        case "submit": return "提交"
        case "refresh": return "刷新"
        case "search": return "搜索"
        case "filter": return "篩選"
        case "sort": return "排序"
        case "share": return "分享"
        
        default: return key
        }
    }

    // 英文
    private static func getEnglish(key: String) -> String {
        switch key {
        // Settings
        case "settings": return "Settings"
        case "account_security": return "Account & Security"
        case "account_and_security": return "Account & Security"
        case "privacy_settings": return "Privacy Settings"
        case "personalization": return "Personalization"
        case "background_settings": return "Background Settings"
        case "font_size": return "Font Size"
        case "multi_language": return "Language"
        case "storage_permissions": return "Storage & Permissions"
        case "clear_cache": return "Clear Cache"
        case "system_permissions": return "System Permissions"
        case "about_help": return "About & Help"
        case "about_qinghe": return "About Qinghe Plan"
        case "ad_info": return "About Ads"
        case "feedback_help": return "Feedback & Help"
        case "rules_agreements": return "Rules & Agreements"
        case "user_agreement": return "User Agreement"
        case "community_convention": return "Community Convention"
        case "service_terms": return "Terms of Service"
        case "privacy_policy": return "Privacy Policy"
        case "qualifications": return "Certifications"
        case "privacy_info": return "Privacy Information"
        case "personal_info_list": return "Personal Information Collection"
        case "third_party_info_list": return "Third-party Information Sharing"
        case "logout": return "Logout"
        
        // Bottom Navigation
        case "tab_home": return "Home"
        case "tab_record": return "Records"
        case "tab_health": return "Health"
        case "tab_workout": return "Workout"
        case "tab_listening": return "Listening"
        case "tab_community": return "Community"
        case "tab_messages": return "Messages"
        case "tab_profile": return "Profile"
        
        // Common
        case "loading": return "Loading..."
        case "getting_user_info": return "Getting user information"
        case "not_logged_in": return "Not logged in"
        case "please_login": return "Please log in first"
        case "please_login_to_view_profile": return "Please log in to view profile"
        case "unbound_phone": return "Phone not bound"
        case "qinghe_user": return "Qinghe User"
        case "confirm": return "Confirm"
        case "cancel": return "Cancel"
        case "save": return "Save"
        case "delete": return "Delete"
        case "edit": return "Edit"
        case "done": return "Done"
        case "back": return "Back"
        case "next": return "Next"
        case "submit": return "Submit"
        case "refresh": return "Refresh"
        case "search": return "Search"
        case "filter": return "Filter"
        case "sort": return "Sort"
        case "share": return "Share"
        
        default: return key
        }
    }

    // 日文
    private static func getJapanese(key: String) -> String {
        switch key {
        // 設定
        case "settings": return "設定"
        case "account_security": return "アカウントとセキュリティ"
        case "account_and_security": return "アカウントとセキュリティ"
        case "privacy_settings": return "プライバシー設定"
        case "personalization": return "パーソナライゼーション"
        case "background_settings": return "背景設定"
        case "font_size": return "フォントサイズ"
        case "multi_language": return "言語"
        case "storage_permissions": return "ストレージと権限"
        case "clear_cache": return "キャッシュクリア"
        case "system_permissions": return "システム権限"
        case "about_help": return "アプリについて・ヘルプ"
        case "about_qinghe": return "青禾計画について"
        case "ad_info": return "広告について"
        case "feedback_help": return "フィードバック・ヘルプ"
        case "rules_agreements": return "ルールと規約"
        case "user_agreement": return "ユーザー規約"
        case "community_convention": return "コミュニティ規約"
        case "service_terms": return "利用規約"
        case "privacy_policy": return "プライバシーポリシー"
        case "qualifications": return "認証情報"
        case "privacy_info": return "プライバシー情報"
        case "personal_info_list": return "個人情報収集リスト"
        case "third_party_info_list": return "第三者情報共有リスト"
        case "logout": return "ログアウト"
        
        // ナビゲーション
        case "tab_home": return "ホーム"
        case "tab_record": return "記録"
        case "tab_health": return "健康"
        case "tab_workout": return "運動"
        case "tab_listening": return "聴く"
        case "tab_community": return "コミュニティ"
        case "tab_messages": return "メッセージ"
        case "tab_profile": return "マイページ"
        
        // 共通
        case "loading": return "読み込み中..."
        case "getting_user_info": return "ユーザー情報を取得中"
        case "not_logged_in": return "ログインしていません"
        case "please_login": return "まずログインしてください"
        case "please_login_to_view_profile": return "プロフィールを表示するにはログインしてください"
        case "unbound_phone": return "電話番号が未登録"
        case "qinghe_user": return "青禾ユーザー"
        case "confirm": return "確認"
        case "cancel": return "キャンセル"
        case "save": return "保存"
        case "delete": return "削除"
        case "edit": return "編集"
        case "done": return "完了"
        case "back": return "戻る"
        case "next": return "次へ"
        case "submit": return "送信"
        case "refresh": return "更新"
        case "search": return "検索"
        case "filter": return "絞り込み"
        case "sort": return "並び替え"
        case "share": return "共有"
        
        default: return key
        }
    }

    // 韩文
    private static func getKorean(key: String) -> String {
        switch key {
        // 설정
        case "settings": return "설정"
        case "account_security": return "계정 및 보안"
        case "account_and_security": return "계정 및 보안"
        case "privacy_settings": return "개인정보 설정"
        case "personalization": return "개인화"
        case "background_settings": return "배경 설정"
        case "font_size": return "글꼴 크기"
        case "multi_language": return "언어"
        case "storage_permissions": return "저장소 및 권한"
        case "clear_cache": return "캐시 지우기"
        case "system_permissions": return "시스템 권한"
        case "about_help": return "정보 및 도움말"
        case "about_qinghe": return "청허 계획 정보"
        case "ad_info": return "광고 정보"
        case "feedback_help": return "피드백 및 도움말"
        case "rules_agreements": return "규칙 및 약관"
        case "user_agreement": return "사용자 약관"
        case "community_convention": return "커뮤니티 규약"
        case "service_terms": return "서비스 약관"
        case "privacy_policy": return "개인정보 보호정책"
        case "qualifications": return "인증 정보"
        case "privacy_info": return "개인정보"
        case "personal_info_list": return "개인정보 수집 목록"
        case "third_party_info_list": return "제3자 정보 공유 목록"
        case "logout": return "로그아웃"
        
        // 내비게이션
        case "tab_home": return "홈"
        case "tab_record": return "기록"
        case "tab_health": return "건강"
        case "tab_workout": return "운동"
        case "tab_listening": return "듣기"
        case "tab_community": return "커뮤니티"
        case "tab_messages": return "메시지"
        case "tab_profile": return "마이페이지"
        
        // 공통
        case "loading": return "로딩 중..."
        case "getting_user_info": return "사용자 정보를 가져오는 중"
        case "not_logged_in": return "로그인하지 않음"
        case "please_login": return "먼저 로그인하세요"
        case "please_login_to_view_profile": return "프로필을 보려면 로그인하세요"
        case "unbound_phone": return "전화번호 미등록"
        case "qinghe_user": return "청허 사용자"
        case "confirm": return "확인"
        case "cancel": return "취소"
        case "save": return "저장"
        case "delete": return "삭제"
        case "edit": return "편집"
        case "done": return "완료"
        case "back": return "뒤로"
        case "next": return "다음"
        case "submit": return "제출"
        case "refresh": return "새로고침"
        case "search": return "검색"
        case "filter": return "필터"
        case "sort": return "정렬"
        case "share": return "공유"
        
        default: return key
        }
    }
}

// MARK: - View 扩展 - 提供便捷的多语言方法
extension View {
    /// 获取本地化字符串
    func localizedString(_ key: String) -> String {
        return LocalizationManager.shared.localizedString(key: key)
    }
}

// MARK: - 设置页面导航目标
enum SettingsDestination: Hashable {
    case accountSecurity
    case passwordSettings
    case accountDeletion
    case privacySettings
    case fontSizeSettings
    case languageSettings
    case clearCache
    case systemPermissions
    case attDiagnostic
    case aboutApp
    case adInfo
    case feedbackHelp
    case communityConvention
    case userAgreement
    case serviceTerms
    case privacyPolicy
    case qualifications
    case personalInfoList
    case thirdPartyInfoList
}

// MARK: - 消息页面
struct MessagesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ChatListViewModel()
    @StateObject private var notificationManager = NotificationManager.shared

    @State private var selectedConversation: ChatConversation?
    @State private var navigationToConversationId: String? = nil // 推送通知导航
    @State private var showingPlusMenu = false // 加号菜单弹窗
    @State private var showingNewChat = false // 显示新建聊天页面
    @State private var openActionConversationId: String? = nil // 当前打开操作按钮的会话ID
    @State private var navigationPath: [CommunityNavigationDestination] = [] // 社区导航路径
    @State private var isViewVisible = false // 跟踪视图是否可见

    @EnvironmentObject private var tabBarManager: TabBarVisibilityManager

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // 主要内容
                VStack(spacing: 0) {
                    // 顶部导航栏
                    topNavigationBar

                    // 通知入口区域
                    notificationEntrySection

                    // 聊天列表
                    chatListContent
                }
                .background(ModernDesignSystem.Colors.backgroundPrimary)
                .navigationBarHidden(true)

                // 加号菜单弹窗
                if showingPlusMenu {
                    ZStack {
                        // 透明背景遮罩，点击关闭弹窗
                        Color.black.opacity(0.001)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showingPlusMenu = false
                            }

                        // 弹窗内容
                        VStack {
                            HStack {
                                Spacer()
                                plusMenuPopover
                                    .padding(.trailing, ModernDesignSystem.Spacing.md)
                                    .padding(.top, 50) // 调整弹窗位置，更靠上
                                    .onTapGesture {
                                        // 阻止点击事件传递到背景
                                    }
                            }
                            Spacer()
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.refreshConversations()
            }
            .onAppear {
                isViewVisible = true
                Task {
                    // 如果是从聊天详情页返回，刷新会话列表
                    if viewModel.conversations.isEmpty {
                        await viewModel.loadConversations()
                    } else {
                        // 已有数据时，刷新以更新未读数
                        await viewModel.refreshConversations()
                    }
                }
                // 加载通知数据（使用防抖机制，避免频繁请求）
                notificationManager.refreshNotifications()
            }
            .onDisappear {
                isViewVisible = false
            }
            .onReceive(NotificationCenter.default.publisher(for: .openConversation)) { notification in
                // 处理推送通知导航到对话
                if let conversationId = notification.object as? String {
                    navigationToConversationId = conversationId
                }
            }
            .navigationDestination(isPresented: .constant(navigationToConversationId != nil)) {
                if let conversationId = navigationToConversationId,
                   let conversation = viewModel.conversations.first(where: { $0.id == conversationId }) {
                    ChatDetailView(conversation: conversation)
                        .asSubView() // 隐藏底部Tab栏
                        .onDisappear {
                            navigationToConversationId = nil
                            // 返回消息列表时刷新会话列表，以更新未读数
                            Task {
                                await viewModel.refreshConversations()
                            }
                        }
                } else {
                    // 如果找不到对话，显示错误页面或返回
                    Text("对话不存在")
                        .onAppear {
                            navigationToConversationId = nil
                        }
                }
            }
            .navigationDestination(isPresented: $showingNewChat) {
                NewChatView()
                    .asSubView() // 隐藏底部Tab栏
            }
            .navigationDestination(for: CommunityNavigationDestination.self) { destination in
                switch destination {
                case .postDetail(let postId, let highlightSection, let highlightUserId):
                    PostDetailView(
                        postId: postId,
                        highlightSection: highlightSection.flatMap { section in
                            switch section {
                            case "likes": return .likes
                            case "bookmarks": return .bookmarks
                            case "comments": return .comments
                            default: return nil
                            }
                        },
                        highlightUserId: highlightUserId
                    )
                        .navigationBarHidden(true)
                        .modifier(SwipeBackGestureModifier()) // 添加滑动返回手势
                        .asSubView() // 标记为子页面，隐藏Tab栏
                        .id(postId) // 强制在postId改变时重新创建视图
                        .onAppear {
                            print("🔍 消息页面：导航到帖子详情页面，帖子ID: \(postId), 高亮: \(highlightSection ?? "无"), 用户ID: \(highlightUserId ?? "无")")
                        }
                case .userProfile(let userId):
                    UserProfileView(userId: userId, isRootView: false)
                        .navigationBarHidden(true)
                        .modifier(SwipeBackGestureModifier()) // 添加滑动返回手势
                        .asSubView() // 标记为子页面，隐藏Tab栏
                        .onAppear {
                            print("🔍 消息页面：导航到用户详情页面，用户ID: \(userId)")
                        }
                case .tagDetail(let tagName):
                    TagDetailView(tagName: tagName)
                        .navigationBarHidden(true)
                        .modifier(SwipeBackGestureModifier()) // 添加滑动返回手势
                        .asSubView() // 标记为子页面，隐藏Tab栏
                        .onAppear {
                            print("🔍 消息页面：导航到标签详情页面，标签: \(tagName)")
                        }
                }
            }
        }
        // MARK: - 错误处理
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定") {
                viewModel.showError = false
            }
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }
        // MARK: - 跨页面导航通知监听
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToPost"))) { notification in
            // 支持两种类型的帖子ID：String 和 Int
            var postIdString: String?
            
            if let postId = notification.userInfo?["postId"] as? String {
                postIdString = postId
            } else if let postId = notification.userInfo?["postId"] as? Int {
                postIdString = String(postId)
            }
            
            if let postId = postIdString {
                let highlightSection = notification.userInfo?["highlightSection"] as? String
                print("🔍 MessagesView 收到帖子详情导航通知，帖子ID: \(postId), 高亮区域: \(highlightSection ?? "无")")
                Task { @MainActor in
                    navigationPath.append(CommunityNavigationDestination.postDetail(postId, highlightSection: highlightSection))
                    print("🔍 MessagesView: 已设置帖子详情显示，postId: \(postId), highlightSection: \(highlightSection ?? "无")")
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToUserProfile"))) { notification in
            if let userId = notification.userInfo?["userId"] as? String {
                print("🔍 MessagesView 收到用户详情导航通知，用户ID: \(userId)")
                Task { @MainActor in
                    navigationPath.append(CommunityNavigationDestination.userProfile(userId))
                    print("🔍 MessagesView: 已设置用户详情显示，userId: \(userId)")
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToChat"))) { notification in
            if let userId = notification.userInfo?["userId"] as? Int {
                print("🔍 MessagesView 收到聊天导航通知，用户ID: \(userId)")
                // 这里可以添加导航到特定聊天的逻辑
                // 例如：找到对应的对话并导航到聊天详情页面
                print("🔍 MessagesView: 需要导航到聊天页面，用户ID: \(userId)")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openNewChat)) { _ in
            showingNewChat = true
        }
        // Tab栏可见性管理：
        // - 从 MainTabView 作为主Tab调用时，使用 .asRootView()（显示并重置tab栏状态）
        // - 从 MainCommunityView 导航调用时，使用 .asSubView()（隐藏tab栏）
        // 注意：MessagesView 本身不添加修饰符，由调用方决定
    }

    // MARK: - 顶部导航栏
    private var topNavigationBar: some View {
        VStack(spacing: 0) {
            ZStack {
                // 左侧返回按钮
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    Spacer()
                }

                // 居中的标题
                Text("消息")
                    .font(ModernDesignSystem.Typography.headline)
                    .foregroundColor(.primary)

                // 右侧按钮
                HStack {
                    Spacer()
                    Button(action: {
                        showingPlusMenu = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.black)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            // 分隔线
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5)
        }
    }

    // MARK: - 通知入口区域
    private var notificationEntrySection: some View {
        VStack(spacing: 12) {
            // 通知入口卡片
            NavigationLink(destination:
                NotificationListView()
                    .asSubView() // 隐藏底部Tab栏
            ) {
                NotificationEntryCardView(unreadCount: notificationManager.unreadCount)
                    .environmentObject(notificationManager)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - 加号菜单弹窗
    private var plusMenuPopover: some View {
        VStack(spacing: 0) {
            // 发起群聊
            PlusMenuItemView(
                icon: "message.fill",
                title: "发起群聊"
            ) {
                showingPlusMenu = false
                showingNewChat = true
            }
        }
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
        .frame(width: 160)
    }

    // MARK: - 聊天列表内容
    private var chatListContent: some View {
        Group {
            if viewModel.isLoading && viewModel.conversations.isEmpty {
                loadingView
            } else if viewModel.conversations.isEmpty {
                emptyStateView
            } else {
                conversationsList
            }
        }
    }

    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)

            Text("加载中...")
                .font(ModernDesignSystem.Typography.body)
                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 空状态视图
    private var emptyStateView: some View {
        ChatEmptyStateView(type: .noChats)
    }

    // MARK: - 会话列表
    private var conversationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.conversations) { conversation in
                    NavigationLink(destination:
                        ChatDetailView(conversation: conversation)
                            .asSubView() // 隐藏底部Tab栏
                    ) {
                        ChatListItemView(
                            conversation: conversation,
                            onTap: nil,
                            onDelete: {
                                Task {
                                    await viewModel.deleteConversation(conversationId: conversation.id)
                                }
                            },
                            isActionOpen: openActionConversationId == conversation.id,
                            onActionStateChanged: { isOpen in
                                openActionConversationId = isOpen ? conversation.id : nil
                            }
                        )
                        .background(ModernDesignSystem.Colors.backgroundCard)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // 分隔线
                    if conversation.id != viewModel.conversations.last?.id {
                        Divider()
                            .padding(.leading, 68) // 对齐内容区域
                    }
                }

                // 加载更多
                if viewModel.hasMoreConversations && !viewModel.isLoading {
                    Button("加载更多") {
                        Task {
                            await viewModel.loadMoreConversations()
                        }
                    }
                    .font(ModernDesignSystem.Typography.footnote)
                    .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                    .padding()
                }

                if viewModel.isLoading && !viewModel.conversations.isEmpty {
                    ProgressView()
                        .padding()
                }
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                // 点击空白区域关闭所有操作按钮
                if openActionConversationId != nil {
                    openActionConversationId = nil
                }
            }
        )
    }


}

// MARK: - 会员中心页面
struct MembershipView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.yellow)
                    
                    Text("会员中心")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("此功能正在开发中...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .navigationTitle("会员中心")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 设置页面
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var userProfile: UserProfile?
    @State private var isLoadingProfile = false

    // 导航状态
    @State private var showingAccountSecurity = false
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // 自定义导航栏
                customNavigationBar

                // 设置列表
                List {
                // 账户信息区域
                Section {
                    if isLoadingProfile {
                        // 加载状态
                        HStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.8)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(localizationManager.localizedString(key: "loading"))
                                    .font(.system(size: 16, weight: .medium))

                                Text(localizationManager.localizedString(key: "getting_user_info"))
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                    } else if let profile = userProfile {
                        // 显示完整用户资料
                        HStack {
                            // 用户真实头像
                            AsyncImage(url: URL(string: profile.avatar ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Text(String(profile.nickname.prefix(1)))
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.white)
                                    )
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(profile.nickname)
                                        .font(.system(size: 16, weight: .medium))

                                    if profile.isVerified == true {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.blue)
                                    }
                                }

                                if let authUser = authManager.currentUser {
                                    Text(authUser.phone ?? localizationManager.localizedString(key: "unbound_phone"))
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                    } else if let user = authManager.currentUser {
                        // 降级显示基本用户信息
                        HStack {
                            // 用户真实头像
                            AsyncImage(url: URL(string: user.avatar ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Text(String((user.nickname ?? "青禾用户").prefix(1)))
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.white)
                                    )
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.nickname ?? localizationManager.localizedString(key: "qinghe_user"))
                                    .font(.system(size: 16, weight: .medium))

                                Text(user.phone ?? localizationManager.localizedString(key: "unbound_phone"))
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                    } else {
                        // 未登录状态
                        HStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(localizationManager.localizedString(key: "not_logged_in"))
                                    .font(.system(size: 16, weight: .medium))

                                Text(localizationManager.localizedString(key: "please_login"))
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }

                // 账户与安全
                Section(localizationManager.localizedString(key: "account_security")) {
                    settingRow(icon: "shield.lefthalf.filled", iconColor: .blue, title: localizationManager.localizedString(key: "account_and_security"))
                    settingRow(icon: "lock.fill", iconColor: .orange, title: localizationManager.localizedString(key: "privacy_settings"))
                }

                // 个性化设置
                Section(localizationManager.localizedString(key: "personalization")) {
                    settingRow(icon: "textformat.size", iconColor: .purple, title: localizationManager.localizedString(key: "font_size"))
                    settingRow(icon: "globe", iconColor: .blue, title: localizationManager.localizedString(key: "multi_language"))
                }

                // 存储与权限
                Section(localizationManager.localizedString(key: "storage_permissions")) {
                    settingRow(icon: "trash.fill", iconColor: .red, title: localizationManager.localizedString(key: "clear_cache"))
                    settingRow(icon: "gear.badge", iconColor: .gray, title: localizationManager.localizedString(key: "system_permissions"))
                    settingRow(icon: "stethoscope", iconColor: .purple, title: "ATT 权限诊断")
                }

                // 关于与帮助
                Section(localizationManager.localizedString(key: "about_help")) {
                    settingRow(icon: "info.circle.fill", iconColor: .blue, title: localizationManager.localizedString(key: "about_qinghe"), subtitle: "v1.0.1")
                    settingRow(icon: "megaphone.fill", iconColor: .orange, title: localizationManager.localizedString(key: "ad_info"))
                    settingRow(icon: "questionmark.circle.fill", iconColor: .green, title: localizationManager.localizedString(key: "feedback_help"))
                }

                // 规则与协议
                Section(localizationManager.localizedString(key: "rules_agreements")) {
                    settingRow(icon: "person.2.fill", iconColor: .blue, title: localizationManager.localizedString(key: "community_convention"))
                    settingRow(icon: "doc.plaintext", iconColor: .blue, title: localizationManager.localizedString(key: "user_agreement"))
                    settingRow(icon: "doc.text.fill", iconColor: .blue, title: localizationManager.localizedString(key: "service_terms"))
                    settingRow(icon: "hand.raised.fill", iconColor: .green, title: localizationManager.localizedString(key: "privacy_policy"))
                    settingRow(icon: "building.2.fill", iconColor: .gray, title: localizationManager.localizedString(key: "qualifications"))
                }

                // 隐私信息
                Section(localizationManager.localizedString(key: "privacy_info")) {
                    settingRow(icon: "person.badge.shield.checkmark.fill", iconColor: .green, title: localizationManager.localizedString(key: "personal_info_list"))
                    settingRow(icon: "arrow.triangle.2.circlepath", iconColor: .orange, title: localizationManager.localizedString(key: "third_party_info_list"))
                }

                // 退出登录
                Section {
                    Button(action: {
                        authManager.logout()
                        dismiss()
                    }) {
                        HStack {
                            Spacer()
                            Text(localizationManager.localizedString(key: "logout"))
                                .foregroundColor(.red)
                                .font(.system(size: 16, weight: .medium))
                            Spacer()
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .onAppear {
                print("🧭 SettingsView onAppear - navigationPath.count = \(navigationPath.count)")
                loadUserProfile()
            }
            .navigationDestination(for: SettingsDestination.self) { destination in
                Group {
                    switch destination {
                    case .accountSecurity:
                        AccountSecurityView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView() // 标记为子页面，隐藏Tab栏
                            .onAppear {
                                print("🔍 设置页面：导航到账号与安全页面")
                            }
                    case .passwordSettings:
                        PasswordSettingsView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                            .onAppear {
                                print("🔍 设置页面：导航到密码设置页面")
                            }
                    case .accountDeletion:
                        AccountDeletionView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                            .onAppear {
                                print("🔍 设置页面：导航到注销账号页面")
                            }
                    case .privacySettings:
                        PrivacySettingsView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .fontSizeSettings:
                        FontSizeSettingsView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .languageSettings:
                        LanguageSettingsView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .clearCache:
                        ClearCacheView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .systemPermissions:
                        SystemPermissionsView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .attDiagnostic:
                        ATTDiagnosticView()
                            .navigationBarHidden(true)
                            .asSubView()
                    case .aboutApp:
                        AboutAppView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .adInfo:
                        AdInfoView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .feedbackHelp:
                        FeedbackHelpView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .communityConvention:
                        CommunityConventionView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .userAgreement:
                        UserAgreementView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .serviceTerms:
                        ServiceTermsView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .privacyPolicy:
                        PrivacyPolicyView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .qualifications:
                        QualificationsView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .personalInfoList:
                        PersonalInfoListView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    case .thirdPartyInfoList:
                        ThirdPartyInfoListView(navigationPath: $navigationPath)
                            .navigationBarHidden(true)
                            .asSubView()
                    }
                }
                .onAppear {
                    print("🔍 设置页面：navigationDestination 被触发，目标: \(destination)")
                }
            }
        }
    }
    }

    // MARK: - 加载用户资料
    private func loadUserProfile() {
        guard let currentUser = authManager.currentUser else {
            print("⚠️ 设置页面：用户未登录")
            return
        }

        isLoadingProfile = true

        Task {
            do {
                let response = try await CommunityAPIService.shared.getUserProfile(userId: currentUser.id)

                await MainActor.run {
                    isLoadingProfile = false
                    if response.success, let profile = response.data {
                        userProfile = profile
                        print("✅ 设置页面：用户资料加载成功")
                        print("  - 昵称: \(profile.nickname)")
                        print("  - 头像: \(profile.avatar ?? "无")")
                        print("  - 认证状态: \(profile.isVerified ?? false)")
                    } else {
                        print("❌ 设置页面：用户资料加载失败 - \(response.message ?? "未知错误")")
                    }
                }
            } catch {
                await MainActor.run {
                    isLoadingProfile = false
                    print("❌ 设置页面：用户资料加载异常 - \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - 处理设置项点击
    private func handleSettingItemTap(title: String) {
        // 通过比较本地化字符串来确定点击的是哪个设置项
        let accountAndSecurity = localizationManager.localizedString(key: "account_and_security")
        let privacySettings = localizationManager.localizedString(key: "privacy_settings")
        let fontSize = localizationManager.localizedString(key: "font_size")
        let multiLanguage = localizationManager.localizedString(key: "multi_language")
        let clearCache = localizationManager.localizedString(key: "clear_cache")
        let systemPermissions = localizationManager.localizedString(key: "system_permissions")
        let aboutQinghe = localizationManager.localizedString(key: "about_qinghe")
        let adInfo = localizationManager.localizedString(key: "ad_info")
        let feedbackHelp = localizationManager.localizedString(key: "feedback_help")
        let communityConvention = localizationManager.localizedString(key: "community_convention")
        let userAgreement = localizationManager.localizedString(key: "user_agreement")
        let serviceTerms = localizationManager.localizedString(key: "service_terms")
        let privacyPolicy = localizationManager.localizedString(key: "privacy_policy")
        let qualifications = localizationManager.localizedString(key: "qualifications")
        let personalInfoList = localizationManager.localizedString(key: "personal_info_list")
        let thirdPartyInfoList = localizationManager.localizedString(key: "third_party_info_list")

        switch title {
        case accountAndSecurity:
            print("🔍 设置页面：点击账号与安全")
            navigationPath.append(SettingsDestination.accountSecurity)
        case privacySettings:
            print("🔍 设置页面：点击隐私设置")
            navigationPath.append(SettingsDestination.privacySettings)
        case fontSize:
            print("🔍 设置页面：点击字体大小")
            navigationPath.append(SettingsDestination.fontSizeSettings)
        case multiLanguage:
            print("🔍 设置页面：点击多语言")
            navigationPath.append(SettingsDestination.languageSettings)
        case clearCache:
            print("🔍 设置页面：点击清理缓存")
            navigationPath.append(SettingsDestination.clearCache)
        case systemPermissions:
            print("🔍 设置页面：点击系统权限")
            navigationPath.append(SettingsDestination.systemPermissions)
        case "ATT 权限诊断":
            print("🔍 设置页面：点击 ATT 权限诊断")
            navigationPath.append(SettingsDestination.attDiagnostic)
        case aboutQinghe:
            print("🔍 设置页面：点击关于青禾计划")
            navigationPath.append(SettingsDestination.aboutApp)
        case adInfo:
            print("🔍 设置页面：点击了解广告推送")
            navigationPath.append(SettingsDestination.adInfo)
        case feedbackHelp:
            print("🔍 设置页面：点击反馈与帮助")
            navigationPath.append(SettingsDestination.feedbackHelp)
        case communityConvention:
            print("🔍 设置页面：点击社区公约")
            navigationPath.append(SettingsDestination.communityConvention)
        case userAgreement:
            print("🔍 设置页面：点击用户协议")
            navigationPath.append(SettingsDestination.userAgreement)
        case serviceTerms:
            print("🔍 设置页面：点击服务条款")
            navigationPath.append(SettingsDestination.serviceTerms)
        case privacyPolicy:
            print("🔍 设置页面：点击隐私政策")
            navigationPath.append(SettingsDestination.privacyPolicy)
        case qualifications:
            print("🔍 设置页面：点击证照信息")
            navigationPath.append(SettingsDestination.qualifications)
        case personalInfoList:
            print("🔍 设置页面：点击个人信息收集清单")
            navigationPath.append(SettingsDestination.personalInfoList)
        case thirdPartyInfoList:
            print("🔍 设置页面：点击第三方信息共享清单")
            navigationPath.append(SettingsDestination.thirdPartyInfoList)
        default:
            print("点击了设置项: \(title)")
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            // 返回按钮（优先回退导航栈）
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // 页面标题
            Text(localizationManager.localizedString(key: "settings"))
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            // 占位符，保持标题居中
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - 设置行组件
    private func settingRow(icon: String, iconColor: Color, title: String, subtitle: String? = nil) -> some View {
        Button(action: {
            handleSettingItemTap(title: title)
        }) {
            HStack(spacing: 12) {
                // 图标
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)

                // 标题
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)

                Spacer()

                // 副标题（如果有）
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                // 右箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 账号与安全页面
struct AccountSecurityView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    @State private var userProfile: UserProfile?
    @State private var isLoadingProfile = false
    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            // 设置列表
            List {
                // 账户信息区域
                Section {
                    if let profile = userProfile {
                        accountInfoRow(profile: profile)
                    } else if let user = authManager.currentUser {
                        basicAccountInfoRow(user: user)
                    }
                }

                // 安全设置
                Section("安全设置") {
                    // 密码设置
                    Button(action: {
                        print("🔍 账号与安全页面：点击密码设置")
                        navigationPath.append(SettingsDestination.passwordSettings)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("密码设置")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)

                                Text(getPasswordSubtitle())
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // 危险操作
                Section("账户管理") {
                    Button(action: {
                        print("🔍 账号与安全页面：点击注销账号")
                        navigationPath.append(SettingsDestination.accountDeletion)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.red)
                                .frame(width: 24, height: 24)

                            Text("注销账号")
                                .font(.system(size: 16))
                                .foregroundColor(.red)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .onAppear {
            print("🧭 AccountSecurityView onAppear - navigationPath.count = \(navigationPath.count)")
            loadUserProfile()
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            // 返回按钮
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // 页面标题
            Text("账号与安全")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            // 占位符，保持标题居中
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - 账户信息行
    private func accountInfoRow(profile: UserProfile) -> some View {
        HStack {
            // 用户头像
            AsyncImage(url: URL(string: profile.avatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text(String(profile.nickname.prefix(1)))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(profile.nickname)
                        .font(.system(size: 16, weight: .medium))

                    if profile.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                }

                Text("ID: \(profile.displayUsername)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    // MARK: - 基本账户信息行
    private func basicAccountInfoRow(user: AuthUser) -> some View {
        HStack {
            // 用户头像
            AsyncImage(url: URL(string: user.avatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text(String((user.nickname ?? "青禾用户").prefix(1)))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(user.nickname ?? "青禾用户")
                    .font(.system(size: 16, weight: .medium))

                // 优先显示青禾ID，如果有userProfile的话
                if let profile = userProfile {
                    Text("ID: \(profile.displayUsername)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                } else {
                    Text("ID: user\(user.id)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    // MARK: - 安全设置行
    private func securityRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        Button(action: {
            handleSecurityItemTap(title: title)
        }) {
            HStack(spacing: 12) {
                // 图标
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)

                // 标题和副标题
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 右箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 处理安全设置项点击
    private func handleSecurityItemTap(title: String) {
        print("🔍 账号与安全页面：handleSecurityItemTap 被调用，title: \(title)")
        print("🔍 当前 navigationPath 计数: \(navigationPath.count)")

        switch title {
        default:
            print("🔍 点击了安全设置项: \(title)")
        }
    }

    // MARK: - 获取密码状态副标题
    private func getPasswordSubtitle() -> String {
        if let profile = userProfile {
            return (profile.hasPassword ?? false) ? "已设置" : "未设置"
        }
        return "未设置"
    }

    // MARK: - 加载用户资料
    private func loadUserProfile() {
        guard let currentUser = authManager.currentUser else {
            print("⚠️ 账号与安全页面：用户未登录")
            return
        }

        isLoadingProfile = true

        Task {
            do {
                let response = try await CommunityAPIService.shared.getUserProfile(userId: currentUser.id)

                await MainActor.run {
                    isLoadingProfile = false
                    if response.success, let profile = response.data {
                        userProfile = profile
                        print("✅ 账号与安全页面：用户资料加载成功")
                    } else {
                        print("❌ 账号与安全页面：用户资料加载失败 - \(response.message ?? "未知错误")")
                    }
                }
            } catch {
                await MainActor.run {
                    isLoadingProfile = false
                    print("❌ 账号与安全页面：用户资料加载异常 - \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - 密码设置页面
struct PasswordSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    @StateObject private var authManager = AuthManager.shared
    @Binding var navigationPath: NavigationPath

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var hasPassword = false
    @State private var isSettingMode = true // true: 设置密码, false: 修改密码

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            ScrollView {
                VStack(spacing: 24) {
                    // 密码状态说明
                    passwordStatusSection

                    // 密码设置表单
                    passwordFormSection

                    // 提交按钮
                    submitButton

                    // 密码要求说明
                    passwordRequirementsSection

                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .onAppear {
            print("🧭 PasswordSettingsView onAppear - navigationPath.count = \(navigationPath.count)")
            checkPasswordStatus()
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("密码设置")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - 密码状态说明区域
    private var passwordStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("密码状态")
                .font(.system(size: 18, weight: .semibold))

            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)

                Text(hasPassword ? "已设置密码" : "未设置密码")
                    .font(.system(size: 16))

                Spacer()

                Text(hasPassword ? "已设置" : "未设置")
                    .font(.system(size: 14))
                    .foregroundColor(hasPassword ? .green : .orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background((hasPassword ? Color.green : Color.orange).opacity(0.1))
                    .cornerRadius(12)
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // MARK: - 密码表单区域
    private var passwordFormSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isSettingMode ? "设置密码" : "修改密码")
                .font(.system(size: 18, weight: .semibold))

            VStack(spacing: 16) {
                // 当前密码输入（仅修改密码时显示）
                if !isSettingMode {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("当前密码")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        SecureField("请输入当前密码", text: $currentPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }

                // 新密码输入
                VStack(alignment: .leading, spacing: 8) {
                    Text(isSettingMode ? "设置密码" : "新密码")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    SecureField(isSettingMode ? "请设置密码" : "请输入新密码", text: $newPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                // 确认密码输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("确认密码")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    SecureField("请再次输入密码", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }

    // MARK: - 提交按钮
    private var submitButton: some View {
        Button(action: submitPasswordChange) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                }

                Text(isSettingMode ? "设置密码" : "修改密码")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(canSubmit ? Color.blue : Color.gray)
            )
        }
        .disabled(!canSubmit || isLoading)
    }

    // MARK: - 密码要求说明
    private var passwordRequirementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("密码要求")
                .font(.system(size: 16, weight: .semibold))

            VStack(alignment: .leading, spacing: 8) {
                requirementRow(text: "长度至少8位", isValid: newPassword.count >= 8)
                requirementRow(text: "包含至少一个数字", isValid: newPassword.range(of: "\\d", options: .regularExpression) != nil)
                requirementRow(text: "包含至少一个小写字母", isValid: newPassword.range(of: "[a-z]", options: .regularExpression) != nil)
                requirementRow(text: "包含至少一个大写字母（推荐）", isValid: newPassword.range(of: "[A-Z]", options: .regularExpression) != nil)
                requirementRow(text: "包含至少一个特殊字符（推荐）", isValid: newPassword.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func requirementRow(text: String, isValid: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isValid ? .green : .secondary)
                .font(.system(size: 14))

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(isValid ? .primary : .secondary)

            Spacer()
        }
    }

    // MARK: - 计算属性
    private var canSubmit: Bool {
        if isSettingMode {
            return !newPassword.isEmpty && !confirmPassword.isEmpty && newPassword == confirmPassword && isPasswordValid
        } else {
            return !currentPassword.isEmpty && !newPassword.isEmpty && !confirmPassword.isEmpty && newPassword == confirmPassword && isPasswordValid
        }
    }

    private var isPasswordValid: Bool {
        return newPassword.count >= 8 &&
               newPassword.range(of: "\\d", options: .regularExpression) != nil &&
               newPassword.range(of: "[a-z]", options: .regularExpression) != nil
    }

    // MARK: - 检查密码状态
    private func checkPasswordStatus() {
        // 从用户资料中检查是否已设置密码
        if let currentUser = authManager.currentUser {
            // 获取用户资料来检查密码状态
            Task {
                do {
                    let response = try await CommunityAPIService.shared.getUserProfile(userId: currentUser.id)

                    await MainActor.run {
                        if response.success, let profile = response.data {
                            hasPassword = profile.hasPassword ?? false
                            isSettingMode = !hasPassword
                            print("🔍 密码设置页面：从用户资料获取密码状态 - hasPassword: \(hasPassword)")
                        } else {
                            // 如果获取失败，默认为未设置
                            hasPassword = false
                            isSettingMode = true
                            print("❌ 密码设置页面：获取用户资料失败，默认为未设置密码")
                        }
                    }
                } catch {
                    await MainActor.run {
                        hasPassword = false
                        isSettingMode = true
                        print("❌ 密码设置页面：获取用户资料出错 - \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    // MARK: - 提交密码更改
    private func submitPasswordChange() {
        guard canSubmit else { return }

        // 验证密码匹配
        guard newPassword == confirmPassword else {
            alertMessage = "两次输入的密码不一致"
            showingAlert = true
            return
        }

        // 验证密码强度
        guard isPasswordValid else {
            alertMessage = "密码不符合要求，请检查密码强度"
            showingAlert = true
            return
        }

        isLoading = true

        if isSettingMode {
            // 设置密码
            authService.setPassword(password: newPassword) { [self] (success: Bool, message: String) in
                DispatchQueue.main.async {
                    isLoading = false
                    alertMessage = message
                    showingAlert = true

                    if success {
                        // 设置成功后更新本地状态
                        hasPassword = true
                        isSettingMode = false
                        print("✅ 密码设置成功，更新本地状态：hasPassword = true")

                        // 设置成功后返回上一页
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            if navigationPath.count > 0 {
                                navigationPath.removeLast()
                            } else {
                                dismiss()
                            }
                        }
                    }
                }
            }
        } else {
            // 修改密码
            authService.changePassword(oldPassword: currentPassword, newPassword: newPassword) { [self] (success: Bool, message: String) in
                DispatchQueue.main.async {
                    isLoading = false
                    alertMessage = message
                    showingAlert = true

                    if success {
                        // 修改成功后返回上一页
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            if navigationPath.count > 0 {
                                navigationPath.removeLast()
                            } else {
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
}








// MARK: - 注销账号页面
struct AccountDeletionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var authService = AuthService.shared
    @Binding var navigationPath: NavigationPath
    @State private var confirmationText = ""
    @State private var verificationCode = ""
    @State private var isLoading = false
    @State private var showingFinalConfirmation = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var agreedToTerms = false
    @State private var isCodeSent = false
    @State private var countdown = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let confirmationPhrase = "确认注销"

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            ScrollView {
                VStack(spacing: 24) {
                    // 警告区域
                    warningSection

                    // 注销后果说明
                    consequencesSection

                    // 确认输入
                    confirmationSection

                    // 验证码输入
                    verificationSection

                    // 同意条款
                    agreementSection

                    // 注销按钮
                    deleteButton

                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .alert("最终确认", isPresented: $showingFinalConfirmation) {
            Button("取消", role: .cancel) { }
            Button("确认注销", role: .destructive) {
                performAccountDeletion()
            }
        } message: {
            Text("此操作不可撤销，您确定要注销账号吗？")
        }
        .onAppear { print("🧭 AccountDeletionView onAppear - navigationPath.count = \(navigationPath.count)") }
        .onReceive(timer) { _ in
            if countdown > 0 {
                countdown -= 1
            }
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("注销账号")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - 警告区域
    private var warningSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("账号注销警告")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.red)

            Text("注销账号是不可逆的操作，请仔细阅读以下说明")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(Color.red.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - 注销后果说明
    private var consequencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("注销后将发生以下情况")
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 12) {
                consequenceItem("🗑️", "账号信息将被永久删除，无法恢复")
                consequenceItem("💬", "所有聊天记录和消息将被清除")
                consequenceItem("📝", "发布的所有内容将被删除")
                consequenceItem("👥", "好友关系将被解除")
                consequenceItem("🏆", "积分、等级等数据将被清零")
                consequenceItem("💰", "账户余额需要提前处理")
                consequenceItem("📱", "绑定的手机号将被解绑")
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func consequenceItem(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.system(size: 16))

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    // MARK: - 确认输入区域
    private var confirmationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("确认操作")
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 8) {
                Text("请输入「\(confirmationPhrase)」以确认注销")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                TextField("请输入确认文字", text: $confirmationText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }

    // MARK: - 验证码输入区域
    private var verificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("短信验证")
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 8) {
                Text("为了确保账户安全，请输入手机验证码")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                HStack {
                    TextField("请输入验证码", text: $verificationCode)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button(action: sendDeletionCode) {
                        Text(countdown > 0 ? "\(countdown)s" : "获取验证码")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(countdown > 0 ? .secondary : .blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(countdown > 0 ? Color.secondary : Color.blue, lineWidth: 1)
                            )
                    }
                    .disabled(countdown > 0 || isLoading)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }

    // MARK: - 同意条款区域
    private var agreementSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: {
                agreedToTerms.toggle()
            }) {
                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(agreedToTerms ? .blue : .gray)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("我已阅读并同意")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)

                Text("• 我确认已备份重要数据")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Text("• 我了解注销后果且自愿承担")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - 注销按钮
    private var deleteButton: some View {
        Button(action: {
            showingFinalConfirmation = true
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                }

                Text("确认注销账号")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(canDelete ? Color.red : Color.gray)
            )
        }
        .disabled(!canDelete || isLoading)
    }

    // MARK: - 计算属性
    private var canDelete: Bool {
        confirmationText == confirmationPhrase && agreedToTerms && !verificationCode.isEmpty && isCodeSent
    }

    // MARK: - 发送注销验证码
    private func sendDeletionCode() {
        guard let user = authManager.currentUser else {
            alertMessage = "用户信息获取失败"
            showingAlert = true
            return
        }

        isLoading = true

        authService.sendDeletionCode(phone: user.phone ?? "") { [self] (success: Bool, message: String) in
            DispatchQueue.main.async {
                isLoading = false
                alertMessage = message
                showingAlert = true

                if success {
                    isCodeSent = true
                    countdown = 60
                }
            }
        }
    }

    // MARK: - 执行账号注销
    private func performAccountDeletion() {
        guard !verificationCode.isEmpty else {
            alertMessage = "请输入验证码"
            showingAlert = true
            return
        }

        isLoading = true

        authService.requestDeletion(code: verificationCode) { [self] (success: Bool, message: String, deletionData: [String: Any]?) in
            DispatchQueue.main.async {
                isLoading = false
                alertMessage = message
                showingAlert = true

                if success {
                    // 注销申请成功，显示等待期信息
                    if let data = deletionData {
                        let remainingDays = data["remainingDays"] as? Int ?? 3
                        alertMessage = "账号注销申请成功，将在\(remainingDays)天后正式注销。期间可通过短信登录撤销申请。"
                    }

                    // 退出登录并返回登录页面
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        authManager.logout()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 隐私设置页面
struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath
    @StateObject private var blacklistViewModel = BlacklistViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            List {
                // 黑名单管理
                Section {
                    NavigationLink(destination: BlacklistView(navigationPath: $navigationPath)) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.minus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.red)
                                .frame(width: 24, height: 24)

                            Text("黑名单")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)

                            Spacer()

                            if blacklistViewModel.isLoading && blacklistViewModel.blockedUsers.isEmpty {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if blacklistViewModel.blockedUsers.isEmpty {
                                Text("0人")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(blacklistViewModel.blockedUsers.count)人")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("黑名单管理")
                } footer: {
                    Text("管理被拉黑的用户，被拉黑的用户无法向您发送消息或查看您的动态")
                }
            }
        }
        .onAppear {
            print("🧭 PrivacySettingsView onAppear - navigationPath.count = \(navigationPath.count)")
            Task {
                await blacklistViewModel.loadBlockedUsers()
            }
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("隐私设置")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

// MARK: - 黑名单页面
struct BlacklistView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath
    @StateObject private var viewModel = BlacklistViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            if viewModel.isLoading && viewModel.blockedUsers.isEmpty {
                // 加载状态
                VStack(spacing: 20) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("加载中...")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else if viewModel.blockedUsers.isEmpty {
                // 空状态
                VStack(spacing: 20) {
                    Spacer()

                    Image(systemName: "person.crop.circle.badge.minus")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("暂无黑名单用户")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("被拉黑的用户将无法向您发送消息")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Spacer()
                }
                .padding(.horizontal, 40)
            } else {
                List {
                    ForEach(viewModel.blockedUsers) { user in
                        HStack(spacing: 12) {
                            // 头像
                            AsyncImage(url: URL(string: user.avatar ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Text(String(user.nickname.prefix(1)))
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                    )
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.nickname)
                                    .font(.system(size: 16, weight: .medium))

                                if let bio = user.bio, !bio.isEmpty {
                                    Text(bio)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                } else {
                                    Text("拉黑时间：\(formatDate(user.blockedAt))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Button("解除") {
                                Task {
                                    await viewModel.unblockUser(user)
                                }
                            }
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { offsets in
                        Task {
                            await viewModel.deleteUsers(at: offsets)
                        }
                    }

                    // 加载更多
                    if viewModel.hasMoreUsers {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding()
                            } else {
                                Button("加载更多") {
                                    Task {
                                        await viewModel.loadMoreBlockedUsers()
                                    }
                                }
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                                .padding()
                            }
                            Spacer()
                        }
                    }
                }
                .refreshable {
                    await viewModel.refreshBlockedUsers()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("🧭 BlacklistView onAppear - navigationPath.count = \(navigationPath.count)")
            Task {
                await viewModel.loadBlockedUsers()
            }
        }
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定", role: .cancel) {}
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("黑名单")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - 辅助方法
    private func formatDate(_ dateString: String) -> String {
        // 解析 ISO 8601 格式的日期字符串
        let isoFormatter = ISO8601DateFormatter()
        guard let date = isoFormatter.date(from: dateString) else {
            return dateString
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 字体大小设置页面
struct FontSizeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath
    @StateObject private var fontManager = FontManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            List {
                // 预览区域
                Section("预览") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("青禾计划")
                            .dynamicFont(.title2)

                        Text("这是一段示例文本，用于预览当前字体大小设置的效果。您可以根据自己的阅读习惯选择合适的字体大小。")
                            .dynamicFont(.body)
                            .lineLimit(nil)

                        Text("小字提示文本")
                            .dynamicFont(.caption1)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                // 字体大小选项
                Section("字体大小") {
                    ForEach(FontSizeOption.allCases, id: \.self) { option in
                        HStack(spacing: 12) {
                            Image(systemName: "textformat.size")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.purple)
                                .frame(width: 24, height: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.title)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)

                                Text(option.subtitle)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if fontManager.currentFontSize == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                fontManager.setFontSize(option)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            print("🧭 FontSizeSettingsView onAppear - navigationPath.count = \(navigationPath.count)")
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("字体大小")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

// MARK: - 多语言设置页面
struct LanguageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "zh-Hans"
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var showingRestartAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            List {
                // 语言选项
                Section(footer: Text(getLocalizedFooterText())) {
                    ForEach(LanguageOption.allCases, id: \.self) { option in
                        HStack(spacing: 12) {
                            Text(option.flag)
                                .font(.system(size: 20))
                                .frame(width: 24, height: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.title)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)

                                Text(option.nativeTitle)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedLanguage == option.rawValue {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedLanguage != option.rawValue {
                                selectedLanguage = option.rawValue
                                localizationManager.setLanguage(option.rawValue)
                                showingRestartAlert = true
                            }
                        }
                    }
                }
            }
        }
        .alert(getLocalizedAlertTitle(), isPresented: $showingRestartAlert) {
            Button(getLocalizedCancelButton(), role: .cancel) { }
            Button(getLocalizedRestartButton()) {
                // 这里可以添加重启应用的逻辑
                print("🔄 重启应用以应用新语言设置")
            }
        } message: {
            Text(getLocalizedAlertMessage())
        }
        .onAppear {
            print("🧭 LanguageSettingsView onAppear - navigationPath.count = \(navigationPath.count)")
            localizationManager.currentLanguage = selectedLanguage
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(localizationManager.localizedString(key: "multi_language"))
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - 本地化文本函数
    private func getLocalizedFooterText() -> String {
        switch localizationManager.currentLanguage {
        case "zh-Hans": return "更改语言后需要重启应用才能生效"
        case "zh-Hant": return "更改語言後需要重啟應用才能生效"
        case "en": return "App restart required for language changes to take effect"
        case "ja": return "言語変更を有効にするにはアプリの再起動が必要です"
        case "ko": return "언어 변경 사항을 적용하려면 앱을 다시 시작해야 합니다"
        default: return "更改语言后需要重启应用才能生效"
        }
    }

    private func getLocalizedAlertTitle() -> String {
        switch localizationManager.currentLanguage {
        case "zh-Hans": return "语言已更改"
        case "zh-Hant": return "語言已更改"
        case "en": return "Language Changed"
        case "ja": return "言語が変更されました"
        case "ko": return "언어가 변경되었습니다"
        default: return "语言已更改"
        }
    }

    private func getLocalizedAlertMessage() -> String {
        switch localizationManager.currentLanguage {
        case "zh-Hans": return "需要重启应用才能应用新的语言设置"
        case "zh-Hant": return "需要重啟應用才能應用新的語言設置"
        case "en": return "App restart required to apply new language settings"
        case "ja": return "新しい言語設定を適用するにはアプリの再起動が必要です"
        case "ko": return "새 언어 설정을 적용하려면 앱을 다시 시작해야 합니다"
        default: return "需要重启应用才能应用新的语言设置"
        }
    }

    private func getLocalizedCancelButton() -> String {
        switch localizationManager.currentLanguage {
        case "zh-Hans": return "稍后重启"
        case "zh-Hant": return "稍後重啟"
        case "en": return "Restart Later"
        case "ja": return "後で再起動"
        case "ko": return "나중에 다시 시작"
        default: return "稍后重启"
        }
    }

    private func getLocalizedRestartButton() -> String {
        switch localizationManager.currentLanguage {
        case "zh-Hans": return "立即重启"
        case "zh-Hant": return "立即重啟"
        case "en": return "Restart Now"
        case "ja": return "今すぐ再起動"
        case "ko": return "지금 다시 시작"
        default: return "立即重启"
        }
    }
}

// MARK: - 语言选项枚举
enum LanguageOption: String, CaseIterable {
    case zhHans = "zh-Hans"
    case zhHant = "zh-Hant"
    case english = "en"
    case japanese = "ja"
    case korean = "ko"

    var title: String {
        switch self {
        case .zhHans: return "简体中文"
        case .zhHant: return "繁体中文"
        case .english: return "English"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        }
    }

    var nativeTitle: String {
        switch self {
        case .zhHans: return "简体中文"
        case .zhHant: return "繁體中文"
        case .english: return "English"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        }
    }

    var flag: String {
        switch self {
        case .zhHans: return "🇨🇳"
        case .zhHant: return "🇹🇼"
        case .english: return "🇺🇸"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        }
    }
}

// MARK: - 预览
#Preview("消息") {
    MessagesView()
}

#Preview("会员中心") {
    MembershipView()
}

#Preview("设置") {
    SettingsView()
}

import Foundation

struct GongGuoStandardBook {
    struct Item: Hashable {
        let title: String
        let points: Int
    }

    // 生成 250 条功 + 250 条过，共 500 条标准条目
    static let merits: [Item] = buildMerits()
    static let demerits: [Item] = buildDemerits()

    private static func buildMerits() -> [Item] {
        let perCategory = 25 // 每类生成 25 条，共 10 类 = 250
        let contexts = ["晨起", "夜间", "寒日", "炎夏", "雨天", "公共场合", "职场", "学校", "社区", "出行"]
        let categories: [(cat: String, pts: Int, verbs: [String])] = [
            ("孝亲", 2, ["问安", "陪护", "添衣", "分担家务", "备餐", "送诊", "报平安", "打扫", "倾听", "体贴"]),
            ("敬长", 2, ["让座", "扶持", "探望", "致谢", "让行", "关怀", "问候", "陪伴", "帮拿重物", "指路"]),
            ("慈幼", 1, ["陪伴", "教导", "护送", "鼓励", "安抚", "守护", "分享", "游戏", "赞赏", "提醒"]),
            ("助人", 1, ["解困", "捐助", "指路", "推轮椅", "代购", "护送", "援手", "借物", "搭把手", "介绍工作"]),
            ("守信", 2, ["守约", "履约", "如期交付", "守时赴约", "言出必行", "按承诺完成", "守规则", "诚实回复", "如实告知", "如实报账"]),
            ("诚信", 1, ["不短斤缺两", "如实标价", "不夸大", "不隐瞒缺陷", "不抄袭", "注明引用", "实事求是", "诚实检讨", "主动道歉", "承认错误"]),
            ("节俭", 1, ["光盘", "节水", "节电", "物尽其用", "修复再用", "捐赠闲物", "简约消费", "旧物改造", "少用一次性", "随手关灯"]),
            ("勤学", 1, ["早起读书", "专注学习", "复盘笔记", "请教良师", "日写总结", "坚持阅读", "练字", "温故", "预习", "整理资料"]),
            ("礼让", 1, ["排队礼让", "轻声细语", "不打断", "控制音量", "不插队", "不喧哗", "微笑致意", "致歉", "说请与谢谢", "尊重隐私"]),
            ("护生", 2, ["放生救护", "助伤小动物", "不食野味", "劝人护生", "转介救助", "为动物找家", "小心驾驶", "避让生灵", "清理渔线", "护巢"])
        ]

        return categories.flatMap { cat in
            generate(category: cat.cat, points: cat.pts, verbs: cat.verbs, contexts: contexts, count: perCategory)
        }
    }

    private static func buildDemerits() -> [Item] {
        let perCategory = 25 // 每类生成 25 条，共 10 类 = 250
        let contexts = ["公共场合", "网络言论", "职场", "学校", "家庭", "出行", "社交", "交易", "用餐", "休憩"]
        let categories: [(cat: String, pts: Int, verbs: [String])] = [
            ("伤生", 3, ["虐待动物", "捕杀野生", "危险驾驶", "酒驾", "斗殴", "恐吓", "纵火", "放任伤害", "强迫他人", "怂恿作恶"]),
            ("不敬", 1, ["言辞不敬", "目无长上", "顶撞", "翻白眼", "冷嘲热讽", "嘲笑缺陷", "轻蔑", "粗鲁", "刻薄", "无礼打断"]),
            ("妄语", 2, ["欺骗", "隐瞒真相", "夸大其词", "造谣", "伪造数据", "虚假承诺", "谎报", "诬陷", "歪曲事实", "带节奏"]),
            ("毁谤", 3, ["背后中伤", "公开抹黑", "恶意点评", "散布流言", "人身攻击", "侮辱人格", "曝光隐私", "贴标签", "拉踩", "挑拨离间"]),
            ("偷盗", 3, ["顺手牵羊", "盗用资源", "抄袭剽窃", "侵占公物", "逃票", "恶意薅羊毛", "作弊牟利", "偷吃食物", "偷拿他物", "骗取补贴"]),
            ("邪淫", 3, ["破坏婚姻", "猥亵", "骚扰", "传播黄秽", "引诱", "暧昧撩拨", "不正当关系", "物化他人", "偷窥", "品行不端"]),
            ("懒惰", 1, ["拖延", "敷衍", "混日子", "偷懒", "推诿", "迟到", "早退", "磨洋工", "不复盘", "无计划"]),
            ("浪费", 1, ["浪费食物", "长明灯长流水", "一次性滥用", "过度包装", "过度消费", "丢弃可用物", "纸张浪费", "过量点单", "弃置仍新", "穿一次即弃"]),
            ("失信", 2, ["违约", "失约", "食言", "言行不一", "毁约毁票", "拖欠款项", "无故跳票", "延迟交付", "违背诺言", "发布假期约"]),
            ("扰众", 1, ["喧哗扰民", "高声外放", "深夜噪音", "乱扔垃圾", "随地吐痰", "破坏公物", "乱停乱放", "插队挤占", "霸座", "乱涂乱画"])
        ]

        return categories.flatMap { cat in
            generate(category: cat.cat, points: cat.pts, verbs: cat.verbs, contexts: contexts, count: perCategory)
        }
    }

    private static func generate(category: String, points: Int, verbs: [String], contexts: [String], count: Int) -> [Item] {
        guard !verbs.isEmpty else { return [] }
        var items: [Item] = []
        for i in 0..<count {
            let v = verbs[i % verbs.count]
            let c = contexts[i % contexts.count]
            let title = "\(category)·\(c)\(v)"
            items.append(Item(title: title, points: points))
        }
        return items
    }
}

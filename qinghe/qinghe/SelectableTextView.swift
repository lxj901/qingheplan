import SwiftUI
import UIKit

// MARK: - 模型
struct AnnotatedExcerpt: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let range: NSRange
}

struct AnnotatedNote: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let range: NSRange
    let note: String
}

struct ColoredHighlight: Identifiable, Equatable {
    let id = UUID()
    let range: NSRange
    let color: UIColor
}

// MARK: - UIKit 包装：可选择文本 + 自定义菜单
struct SelectableTextView: UIViewRepresentable {
    var attributedText: NSAttributedString
    @Binding var coloredHighlights: [ColoredHighlight]
    var notes: [AnnotatedNote] = []
    var reviewPlanMarks: [ReviewPlanMark] = []  // 新增：复习计划标记
    var noteUnderlineColor: UIColor = UIColor.systemOrange
    var reviewPlanUnderlineColor: UIColor = UIColor.systemBlue  // 复习计划波浪线颜色

    var onHighlight: (String, NSRange) -> Void
    var onFavorite: (String, NSRange) -> Void
    var onNote: (String, NSRange) -> Void
    var onReviewPlan: ((String, NSRange) -> Void)? = nil  // 新增：创建复习计划
    var onTapNote: ((AnnotatedNote) -> Void)? = nil

    func makeUIView(context: Context) -> SelectableTextViewInternal {
        let tv = SelectableTextViewInternal()
        tv.isEditable = false
        tv.isSelectable = true
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        // ✅ 禁用内部滚动，让外层 SwiftUI ScrollView 处理滚动
        // 这样可以避免嵌套滚动冲突，同时保持文本选择和长按功能
        tv.isScrollEnabled = false
        tv.isUserInteractionEnabled = true
        // 让宽度由外部约束决定，高度自适应内容
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.setContentHuggingPriority(.defaultLow, for: .horizontal)
        tv.setContentHuggingPriority(.required, for: .vertical)  // 确保垂直方向紧贴内容
        tv.delegate = context.coordinator
        tv.actionDelegate = context.coordinator
        tv.allowsEditingTextAttributes = true

        context.coordinator.textView = tv
        context.coordinator.noteUnderlineColor = noteUnderlineColor
        context.coordinator.reviewPlanUnderlineColor = reviewPlanUnderlineColor
        context.coordinator.apply(base: attributedText, coloredHighlights: coloredHighlights, notes: notes, reviewPlanMarks: reviewPlanMarks)

        // 点击查看笔记
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.cancelsTouchesInView = false
        tv.addGestureRecognizer(tap)

        if #available(iOS 16.0, *) {
            let interaction = UIEditMenuInteraction(delegate: context.coordinator)
            tv.addInteraction(interaction)
        } else {
            let items = [
                UIMenuItem(title: "高亮", action: #selector(SelectableTextViewInternal.highlightAction)),
                UIMenuItem(title: "收藏", action: #selector(SelectableTextViewInternal.favoriteAction)),
                UIMenuItem(title: "笔记", action: #selector(SelectableTextViewInternal.noteAction)),
                UIMenuItem(title: "复习计划", action: #selector(SelectableTextViewInternal.reviewPlanAction))
            ]
            UIMenuController.shared.menuItems = items
        }
        return tv
    }

    func updateUIView(_ uiView: SelectableTextViewInternal, context: Context) {
        context.coordinator.noteUnderlineColor = noteUnderlineColor
        context.coordinator.reviewPlanUnderlineColor = reviewPlanUnderlineColor
        context.coordinator.apply(base: attributedText, coloredHighlights: coloredHighlights, notes: notes, reviewPlanMarks: reviewPlanMarks)
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    class Coordinator: NSObject, UITextViewDelegate, UIEditMenuInteractionDelegate, SelectableTextViewInternalActionDelegate {
        var parent: SelectableTextView
        weak var textView: UITextView?
        var noteUnderlineColor: UIColor = UIColor.systemOrange
        var reviewPlanUnderlineColor: UIColor = UIColor.systemBlue
        var currentNotes: [AnnotatedNote] = []
        var currentReviewPlanMarks: [ReviewPlanMark] = []
        // 记录插入的序号标记，用于坐标映射
        struct Marker { let baseLoc: Int; let displayedLoc: Int; let length: Int }
        var insertedMarkers: [Marker] = []

        init(parent: SelectableTextView) { self.parent = parent }

        func apply(base: NSAttributedString, coloredHighlights: [ColoredHighlight], notes: [AnnotatedNote], reviewPlanMarks: [ReviewPlanMark] = []) {
            guard let tv = textView else { return }
            self.currentNotes = notes
            self.currentReviewPlanMarks = reviewPlanMarks

            let attr = NSMutableAttributedString(attributedString: base)

            // 确保有基本文字属性（避免属性缺失导致显示异常）
            if attr.length > 0 {
                let full = NSRange(location: 0, length: attr.length)
                if attr.attribute(.font, at: 0, effectiveRange: nil) == nil {
                    attr.addAttribute(.font, value: UIFont.systemFont(ofSize: 17), range: full)
                }
                if attr.attribute(.foregroundColor, at: 0, effectiveRange: nil) == nil {
                    attr.addAttribute(.foregroundColor, value: UIColor.label, range: full)
                }
            }

            // 1) 插入笔记序号和复习计划图标（显示用，不改变原始 range）
            insertedMarkers.removeAll()
            var cumulative = 0

            // 先插入笔记序号
            let sortedNotes = notes.enumerated().sorted { $0.element.range.location < $1.element.range.location }
            for (order, pair) in sortedNotes.enumerated() {
                let note = pair.element
                let displayLoc = note.range.location + cumulative
                let numberAttr = numberBadge(for: order + 1)
                attr.insert(numberAttr, at: displayLoc)
                insertedMarkers.append(Marker(baseLoc: note.range.location, displayedLoc: displayLoc, length: numberAttr.length))
                cumulative += numberAttr.length
            }

            // 再插入复习计划图标
            let sortedReviewMarks = reviewPlanMarks.sorted { $0.range.location < $1.range.location }
            for mark in sortedReviewMarks {
                // 计算当前位置（考虑之前插入的所有标记）
                let displayLoc = mark.range.location + cumulative
                let iconAttr = reviewPlanIcon(for: mark)
                attr.insert(iconAttr, at: displayLoc)
                insertedMarkers.append(Marker(baseLoc: mark.range.location, displayedLoc: displayLoc, length: iconAttr.length))
                cumulative += iconAttr.length
            }

            // 2) 渲染高亮（把位置换算到显示文本坐标）
            for hl in coloredHighlights {
                let r = hl.range
                guard r.location >= 0, r.location + r.length <= base.length, r.length > 0 else { continue }
                let offset = offsetForDisplayed(fromBaseLocation: r.location, includeEqual: true)
                let displayed = NSRange(location: r.location + offset, length: r.length)
                if displayed.location + displayed.length <= attr.length {
                    attr.addAttribute(.backgroundColor, value: hl.color.withAlphaComponent(0.45), range: displayed)
                }
            }

            // 3) 渲染笔记下划线（点划线近似“波浪线”），起始应在序号之后
            for note in notes {
                let startOffset = offsetForDisplayed(fromBaseLocation: note.range.location, includeEqual: true)
                let start = note.range.location + startOffset
                let r = NSRange(location: start, length: note.range.length)
                guard r.location >= 0, r.location + r.length <= attr.length, r.length > 0 else { continue }
                let style = NSUnderlineStyle.single.rawValue | NSUnderlineStyle.patternDashDotDot.rawValue
                attr.addAttributes([
                    .underlineStyle: style,
                    .underlineColor: noteUnderlineColor
                ], range: r)
            }

            // 4) 渲染复习计划下划线（波浪线），起始应在图标之后
            for mark in reviewPlanMarks {
                let startOffset = offsetForDisplayed(fromBaseLocation: mark.range.location, includeEqual: true)
                let start = mark.range.location + startOffset
                let r = NSRange(location: start, length: mark.range.length)
                guard r.location >= 0, r.location + r.length <= attr.length, r.length > 0 else { continue }
                let style = NSUnderlineStyle.single.rawValue | NSUnderlineStyle.patternDashDotDot.rawValue
                attr.addAttributes([
                    .underlineStyle: style,
                    .underlineColor: reviewPlanUnderlineColor
                ], range: r)
            }

            // 保持选中位置（不需要保持 contentOffset，因为滚动由外层 ScrollView 处理）
            let selected = tv.selectedRange
            tv.attributedText = attr
            tv.selectedRange = selected
            tv.invalidateIntrinsicContentSize()
        }

        // 处理点击以查看笔记内容
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let tv = textView else { return }
            let point = recognizer.location(in: tv)
            var location = point
            // 转换为 textContainer 坐标：去掉 inset
            // 由于禁用了内部滚动，不需要加上 contentOffset
            location.x -= tv.textContainerInset.left
            location.y -= tv.textContainerInset.top
            let lm = tv.layoutManager
            let tc = tv.textContainer
            let index = lm.characterIndex(for: location, in: tc, fractionOfDistanceBetweenInsertionPoints: nil)
            // 优先命中序号自身
            if let m = insertedMarkers.first(where: { index >= $0.displayedLoc && index < $0.displayedLoc + $0.length }),
               let note = currentNotes.first(where: { $0.range.location == m.baseLoc }) {
                // 弹出笔记详情前，去掉当前选区
                dismissSelection()
                parent.onTapNote?(note)
                return
            }
            // 将显示坐标转换回原始坐标，再匹配笔记范围
            let baseIndex = baseIndexForDisplayed(index)
            if let note = currentNotes.first(where: { $0.range.location <= baseIndex && baseIndex < $0.range.location + $0.range.length }) {
                dismissSelection()
                parent.onTapNote?(note)
                return
            }
            // 若点在选区之外，则取消选区与菜单
            let sel = tv.selectedRange
            if sel.length > 0 && !(sel.location <= index && index < sel.location + sel.length) {
                dismissSelection()
            }
        }

        // 计算给定原始位置在显示文本中的偏移
        private func offsetForDisplayed(fromBaseLocation baseLoc: Int, includeEqual: Bool) -> Int {
            insertedMarkers.reduce(0) { partial, m in
                partial + ((includeEqual ? (m.baseLoc <= baseLoc) : (m.baseLoc < baseLoc)) ? m.length : 0)
            }
        }

        // 从显示坐标反推原始坐标（用于命中检测）
        private func baseIndexForDisplayed(_ displayedIndex: Int) -> Int {
            let reduce = insertedMarkers.reduce(0) { partial, m in
                partial + ((m.displayedLoc <= displayedIndex) ? m.length : 0)
            }
            return max(0, displayedIndex - reduce)
        }

        // 生成序号徽标（① ② ③ …，超过20用 [n]），并带轻微上移与主题色
        private func numberBadge(for index: Int) -> NSAttributedString {
            let str: String
            if index >= 1 && index <= 20 {
                if let scalar = UnicodeScalar(0x2460 + index - 1) { // ① 起始
                    str = String(Character(scalar)) + " "
                } else {
                    str = "[\(index)] "
                }
            } else {
                str = "[\(index)] "
            }
            let font = (textView?.font ?? UIFont.systemFont(ofSize: 17))
            let badgeFont = UIFont.systemFont(ofSize: max(12, font.pointSize * 0.8), weight: .semibold)
            return NSAttributedString(string: str, attributes: [
                .font: badgeFont,
                .foregroundColor: noteUnderlineColor,
                .baselineOffset: 2
            ])
        }

        // 生成复习计划图标（⭕️ 或 ✅）
        private func reviewPlanIcon(for mark: ReviewPlanMark) -> NSAttributedString {
            let icon = mark.isCompleted ? "✅ " : "⭕️ "
            let font = (textView?.font ?? UIFont.systemFont(ofSize: 17))
            return NSAttributedString(string: icon, attributes: [
                .font: font,
                .foregroundColor: reviewPlanUnderlineColor,
                .baselineOffset: 0
            ])
        }

        // iOS 16+ 自定义编辑菜单（优先使用 UITextViewDelegate 的 API）
        @available(iOS 16.0, *)
        func textView(_ textView: UITextView, editMenuForTextIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
            guard range.length > 0 else { return UIMenu(children: suggestedActions) }
            let h = UIAction(title: "高亮", image: UIImage(systemName: "highlighter")) { [weak self] _ in
                self?.performHighlight()
            }
            let f = UIAction(title: "收藏", image: UIImage(systemName: "bookmark")) { [weak self] _ in
                self?.performFavorite()
            }
            let n = UIAction(title: "笔记", image: UIImage(systemName: "square.and.pencil")) { [weak self] _ in
                self?.performNote()
            }
            let r = UIAction(title: "复习计划", image: UIImage(systemName: "calendar.badge.clock")) { [weak self] _ in
                self?.performReviewPlan()
            }
            let custom = UIMenu(options: .displayInline, children: [h, f, n, r])
            return UIMenu(children: [custom] + suggestedActions)
        }

        // 兼容：若系统未调用上面的 UITextViewDelegate 接口，则回退到 Interaction 委托
        @available(iOS 16.0, *)
        func editMenuInteraction(_ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration, suggestedActions: [UIMenuElement]) -> UIMenu? {
            guard let tv = textView, tv.selectedRange.length > 0 else {
                return UIMenu(children: suggestedActions)
            }
            let h = UIAction(title: "高亮", image: UIImage(systemName: "highlighter")) { [weak self] _ in
                self?.performHighlight()
            }
            let f = UIAction(title: "收藏", image: UIImage(systemName: "bookmark")) { [weak self] _ in
                self?.performFavorite()
            }
            let n = UIAction(title: "笔记", image: UIImage(systemName: "square.and.pencil")) { [weak self] _ in
                self?.performNote()
            }
            let r = UIAction(title: "复习计划", image: UIImage(systemName: "calendar.badge.clock")) { [weak self] _ in
                self?.performReviewPlan()
            }
            let custom = UIMenu(options: .displayInline, children: [h, f, n, r])
            return UIMenu(children: [custom] + suggestedActions)
        }

        // 动作执行
        func performHighlight() {
            guard let tv = textView else { return }
            let range = tv.selectedRange
            guard range.length > 0 else { return }
            let excerpt = (tv.text as NSString).substring(with: range)
            parent.onHighlight(excerpt, range)
            dismissSelection()
        }

        func performFavorite() {
            guard let tv = textView else { return }
            let range = tv.selectedRange
            guard range.length > 0 else { return }
            let excerpt = (tv.text as NSString).substring(with: range)
            parent.onFavorite(excerpt, range)
            dismissSelection()
        }

        func performNote() {
            guard let tv = textView else { return }
            let range = tv.selectedRange
            guard range.length > 0 else { return }
            let excerpt = (tv.text as NSString).substring(with: range)
            parent.onNote(excerpt, range)
            dismissSelection()
        }

        func performReviewPlan() {
            guard let tv = textView else { return }
            let range = tv.selectedRange
            guard range.length > 0 else { return }
            let excerpt = (tv.text as NSString).substring(with: range)
            parent.onReviewPlan?(excerpt, range)
            dismissSelection()
        }

        // iOS 15 及以下
        func textViewDidChangeSelection(_ textView: UITextView) {
            if #available(iOS 16.0, *) { return }
            if textView.selectedRange.length > 0, textView.isFirstResponder {
                UIMenuController.shared.showMenu(from: textView, rect: textView.caretRect(for: textView.selectedTextRange?.start ?? textView.beginningOfDocument))
            }
        }

        // iOS 15 通过自定义按钮回调
        func didTapHighlight() { performHighlight() }
        func didTapFavorite() { performFavorite() }
        func didTapNote() { performNote() }
        func didTapReviewPlan() { performReviewPlan() }

        private func dismissSelection() {
            guard let tv = textView else { return }
            // 清除选区并隐藏菜单
            tv.selectedRange = NSRange(location: 0, length: 0)
            tv.resignFirstResponder()
            if #available(iOS 16.0, *) {
                // UIEditMenu 会自动消失；确保结束编辑
            } else {
                UIMenuController.shared.hideMenu()
            }
        }
    }
}

// MARK: - 内部类：支持旧版菜单
protocol SelectableTextViewInternalActionDelegate: AnyObject {
    func didTapHighlight()
    func didTapFavorite()
    func didTapNote()
    func didTapReviewPlan()
}

class SelectableTextViewInternal: UITextView {
    weak var actionDelegate: SelectableTextViewInternalActionDelegate?

    override var canBecomeFirstResponder: Bool { true }

    // 让 SwiftUI 决定宽度，只根据内容计算高度
    override var intrinsicContentSize: CGSize {
        // 当 isScrollEnabled = false 时，需要根据当前宽度计算正确的内容高度
        let width = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width - 40
        let size = sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: UIView.noIntrinsicMetric, height: size.height)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        // 设置文本容器的宽度
        let width = size.width
        textContainer.size = CGSize(width: width, height: .greatestFiniteMagnitude)

        // 强制布局
        layoutManager.ensureLayout(for: textContainer)
        let usedRect = layoutManager.usedRect(for: textContainer)

        // 返回实际需要的大小
        let height = usedRect.height + textContainerInset.top + textContainerInset.bottom
        return CGSize(width: width, height: ceil(height))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 当布局改变时，通知 SwiftUI 重新计算大小
        invalidateIntrinsicContentSize()
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(highlightAction) || action == #selector(favoriteAction) || action == #selector(noteAction) || action == #selector(reviewPlanAction) {
            return selectedRange.length > 0
        }
        return super.canPerformAction(action, withSender: sender)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        _ = becomeFirstResponder()
        super.touchesBegan(touches, with: event)
    }

    @objc func highlightAction() { actionDelegate?.didTapHighlight() }
    @objc func favoriteAction() { actionDelegate?.didTapFavorite() }
    @objc func noteAction() { actionDelegate?.didTapNote() }
    @objc func reviewPlanAction() { actionDelegate?.didTapReviewPlan() }
}

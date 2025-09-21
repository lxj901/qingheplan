import SwiftUI

/// 地址选择器视图 - 支持省市区三级联动
struct AddressPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProvince: Province?
    @State private var selectedCity: City?
    @State private var selectedDistrict: District?
    @State private var provinces: [Province] = []
    @State private var cities: [City] = []
    @State private var districts: [District] = []
    
    let title: String
    let onAddressSelected: (String) -> Void
    
    init(title: String = "选择地址", onAddressSelected: @escaping (String) -> Void) {
        self.title = title
        self.onAddressSelected = onAddressSelected
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 三级选择器
                HStack(spacing: 0) {
                    // 省份选择
                    Picker("省份", selection: $selectedProvince) {
                        Text("请选择省份").tag(nil as Province?)
                        ForEach(provinces, id: \.code) { province in
                            Text(province.name).tag(province as Province?)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: .infinity)
                    .onChange(of: selectedProvince) { _, newProvince in
                        selectedCity = nil
                        selectedDistrict = nil
                        loadCities(for: newProvince)
                    }
                    
                    // 城市选择
                    Picker("城市", selection: $selectedCity) {
                        Text("请选择城市").tag(nil as City?)
                        ForEach(cities, id: \.code) { city in
                            Text(city.name).tag(city as City?)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: .infinity)
                    .onChange(of: selectedCity) { _, newCity in
                        selectedDistrict = nil
                        loadDistricts(for: newCity)
                    }
                    
                    // 区县选择
                    Picker("区县", selection: $selectedDistrict) {
                        Text("请选择区县").tag(nil as District?)
                        ForEach(districts, id: \.code) { district in
                            Text(district.name).tag(district as District?)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)

                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("确定") {
                    confirmSelection()
                }
                .disabled(!isSelectionComplete)
            )
        }
        .presentationDetents([.height(400)])
        .onAppear {
            loadProvinces()
        }
    }
    
    // MARK: - 计算属性
    
    private var isSelectionComplete: Bool {
        return selectedProvince != nil && selectedCity != nil && selectedDistrict != nil
    }
    
    // MARK: - 私有方法
    
    private func confirmSelection() {
        guard let province = selectedProvince,
              let city = selectedCity,
              let district = selectedDistrict else {
            return
        }
        
        let address = "\(province.name) \(city.name) \(district.name)"
        onAddressSelected(address)
        dismiss()
    }
    
    private func loadProvinces() {
        provinces = AddressDataProvider.shared.getProvinces()
    }
    
    private func loadCities(for province: Province?) {
        guard let province = province else {
            cities = []
            return
        }
        cities = AddressDataProvider.shared.getCities(for: province.code)
    }
    
    private func loadDistricts(for city: City?) {
        guard let city = city else {
            districts = []
            return
        }
        districts = AddressDataProvider.shared.getDistricts(for: city.code)
    }
}

// MARK: - 数据模型

struct Province: Codable, Hashable {
    let code: String
    let name: String
}

struct City: Codable, Hashable {
    let code: String
    let name: String
    let provinceCode: String
}

struct District: Codable, Hashable {
    let code: String
    let name: String
    let cityCode: String
}

// MARK: - 地址数据提供者

class AddressDataProvider {
    static let shared = AddressDataProvider()
    
    private init() {}
    
    func getProvinces() -> [Province] {
        return [
            Province(code: "110000", name: "北京市"),
            Province(code: "120000", name: "天津市"),
            Province(code: "130000", name: "河北省"),
            Province(code: "140000", name: "山西省"),
            Province(code: "150000", name: "内蒙古自治区"),
            Province(code: "210000", name: "辽宁省"),
            Province(code: "220000", name: "吉林省"),
            Province(code: "230000", name: "黑龙江省"),
            Province(code: "310000", name: "上海市"),
            Province(code: "320000", name: "江苏省"),
            Province(code: "330000", name: "浙江省"),
            Province(code: "340000", name: "安徽省"),
            Province(code: "350000", name: "福建省"),
            Province(code: "360000", name: "江西省"),
            Province(code: "370000", name: "山东省"),
            Province(code: "410000", name: "河南省"),
            Province(code: "420000", name: "湖北省"),
            Province(code: "430000", name: "湖南省"),
            Province(code: "440000", name: "广东省"),
            Province(code: "450000", name: "广西壮族自治区"),
            Province(code: "460000", name: "海南省"),
            Province(code: "500000", name: "重庆市"),
            Province(code: "510000", name: "四川省"),
            Province(code: "520000", name: "贵州省"),
            Province(code: "530000", name: "云南省"),
            Province(code: "540000", name: "西藏自治区"),
            Province(code: "610000", name: "陕西省"),
            Province(code: "620000", name: "甘肃省"),
            Province(code: "630000", name: "青海省"),
            Province(code: "640000", name: "宁夏回族自治区"),
            Province(code: "650000", name: "新疆维吾尔自治区"),
            Province(code: "710000", name: "台湾省"),
            Province(code: "810000", name: "香港特别行政区"),
            Province(code: "820000", name: "澳门特别行政区")
        ]
    }
    
    func getCities(for provinceCode: String) -> [City] {
        switch provinceCode {
        case "110000": // 北京市
            return [
                City(code: "110100", name: "北京市", provinceCode: "110000")
            ]
        case "120000": // 天津市
            return [
                City(code: "120100", name: "天津市", provinceCode: "120000")
            ]
        case "130000": // 河北省
            return [
                City(code: "130100", name: "石家庄市", provinceCode: "130000"),
                City(code: "130200", name: "唐山市", provinceCode: "130000"),
                City(code: "130300", name: "秦皇岛市", provinceCode: "130000"),
                City(code: "130400", name: "邯郸市", provinceCode: "130000"),
                City(code: "130500", name: "邢台市", provinceCode: "130000"),
                City(code: "130600", name: "保定市", provinceCode: "130000"),
                City(code: "130700", name: "张家口市", provinceCode: "130000"),
                City(code: "130800", name: "承德市", provinceCode: "130000"),
                City(code: "130900", name: "沧州市", provinceCode: "130000"),
                City(code: "131000", name: "廊坊市", provinceCode: "130000"),
                City(code: "131100", name: "衡水市", provinceCode: "130000")
            ]
        case "310000": // 上海市
            return [
                City(code: "310100", name: "上海市", provinceCode: "310000")
            ]
        case "320000": // 江苏省
            return [
                City(code: "320100", name: "南京市", provinceCode: "320000"),
                City(code: "320200", name: "无锡市", provinceCode: "320000"),
                City(code: "320300", name: "徐州市", provinceCode: "320000"),
                City(code: "320400", name: "常州市", provinceCode: "320000"),
                City(code: "320500", name: "苏州市", provinceCode: "320000"),
                City(code: "320600", name: "南通市", provinceCode: "320000"),
                City(code: "320700", name: "连云港市", provinceCode: "320000"),
                City(code: "320800", name: "淮安市", provinceCode: "320000"),
                City(code: "320900", name: "盐城市", provinceCode: "320000"),
                City(code: "321000", name: "扬州市", provinceCode: "320000"),
                City(code: "321100", name: "镇江市", provinceCode: "320000"),
                City(code: "321200", name: "泰州市", provinceCode: "320000"),
                City(code: "321300", name: "宿迁市", provinceCode: "320000")
            ]
        case "330000": // 浙江省
            return [
                City(code: "330100", name: "杭州市", provinceCode: "330000"),
                City(code: "330200", name: "宁波市", provinceCode: "330000"),
                City(code: "330300", name: "温州市", provinceCode: "330000"),
                City(code: "330400", name: "嘉兴市", provinceCode: "330000"),
                City(code: "330500", name: "湖州市", provinceCode: "330000"),
                City(code: "330600", name: "绍兴市", provinceCode: "330000"),
                City(code: "330700", name: "金华市", provinceCode: "330000"),
                City(code: "330800", name: "衢州市", provinceCode: "330000"),
                City(code: "330900", name: "舟山市", provinceCode: "330000"),
                City(code: "331000", name: "台州市", provinceCode: "330000"),
                City(code: "331100", name: "丽水市", provinceCode: "330000")
            ]
        case "440000": // 广东省
            return [
                City(code: "440100", name: "广州市", provinceCode: "440000"),
                City(code: "440200", name: "韶关市", provinceCode: "440000"),
                City(code: "440300", name: "深圳市", provinceCode: "440000"),
                City(code: "440400", name: "珠海市", provinceCode: "440000"),
                City(code: "440500", name: "汕头市", provinceCode: "440000"),
                City(code: "440600", name: "佛山市", provinceCode: "440000"),
                City(code: "440700", name: "江门市", provinceCode: "440000"),
                City(code: "440800", name: "湛江市", provinceCode: "440000"),
                City(code: "440900", name: "茂名市", provinceCode: "440000"),
                City(code: "441200", name: "肇庆市", provinceCode: "440000"),
                City(code: "441300", name: "惠州市", provinceCode: "440000"),
                City(code: "441400", name: "梅州市", provinceCode: "440000"),
                City(code: "441500", name: "汕尾市", provinceCode: "440000"),
                City(code: "441600", name: "河源市", provinceCode: "440000"),
                City(code: "441700", name: "阳江市", provinceCode: "440000"),
                City(code: "441800", name: "清远市", provinceCode: "440000"),
                City(code: "441900", name: "东莞市", provinceCode: "440000"),
                City(code: "442000", name: "中山市", provinceCode: "440000"),
                City(code: "445100", name: "潮州市", provinceCode: "440000"),
                City(code: "445200", name: "揭阳市", provinceCode: "440000"),
                City(code: "445300", name: "云浮市", provinceCode: "440000")
            ]
        case "500000": // 重庆市
            return [
                City(code: "500100", name: "重庆市", provinceCode: "500000")
            ]
        case "510000": // 四川省
            return [
                City(code: "510100", name: "成都市", provinceCode: "510000"),
                City(code: "510300", name: "自贡市", provinceCode: "510000"),
                City(code: "510400", name: "攀枝花市", provinceCode: "510000"),
                City(code: "510500", name: "泸州市", provinceCode: "510000"),
                City(code: "510600", name: "德阳市", provinceCode: "510000"),
                City(code: "510700", name: "绵阳市", provinceCode: "510000"),
                City(code: "510800", name: "广元市", provinceCode: "510000"),
                City(code: "510900", name: "遂宁市", provinceCode: "510000"),
                City(code: "511000", name: "内江市", provinceCode: "510000"),
                City(code: "511100", name: "乐山市", provinceCode: "510000"),
                City(code: "511300", name: "南充市", provinceCode: "510000"),
                City(code: "511400", name: "眉山市", provinceCode: "510000"),
                City(code: "511500", name: "宜宾市", provinceCode: "510000"),
                City(code: "511600", name: "广安市", provinceCode: "510000"),
                City(code: "511700", name: "达州市", provinceCode: "510000"),
                City(code: "511800", name: "雅安市", provinceCode: "510000"),
                City(code: "511900", name: "巴中市", provinceCode: "510000"),
                City(code: "512000", name: "资阳市", provinceCode: "510000")
            ]
        default:
            return []
        }
    }
    
    func getDistricts(for cityCode: String) -> [District] {
        switch cityCode {
        case "110100": // 北京市
            return [
                District(code: "110101", name: "东城区", cityCode: "110100"),
                District(code: "110102", name: "西城区", cityCode: "110100"),
                District(code: "110105", name: "朝阳区", cityCode: "110100"),
                District(code: "110106", name: "丰台区", cityCode: "110100"),
                District(code: "110107", name: "石景山区", cityCode: "110100"),
                District(code: "110108", name: "海淀区", cityCode: "110100"),
                District(code: "110109", name: "门头沟区", cityCode: "110100"),
                District(code: "110111", name: "房山区", cityCode: "110100"),
                District(code: "110112", name: "通州区", cityCode: "110100"),
                District(code: "110113", name: "顺义区", cityCode: "110100"),
                District(code: "110114", name: "昌平区", cityCode: "110100"),
                District(code: "110115", name: "大兴区", cityCode: "110100"),
                District(code: "110116", name: "怀柔区", cityCode: "110100"),
                District(code: "110117", name: "平谷区", cityCode: "110100"),
                District(code: "110118", name: "密云区", cityCode: "110100"),
                District(code: "110119", name: "延庆区", cityCode: "110100")
            ]
        case "120100": // 天津市
            return [
                District(code: "120101", name: "和平区", cityCode: "120100"),
                District(code: "120102", name: "河东区", cityCode: "120100"),
                District(code: "120103", name: "河西区", cityCode: "120100"),
                District(code: "120104", name: "南开区", cityCode: "120100"),
                District(code: "120105", name: "河北区", cityCode: "120100"),
                District(code: "120106", name: "红桥区", cityCode: "120100"),
                District(code: "120110", name: "东丽区", cityCode: "120100"),
                District(code: "120111", name: "西青区", cityCode: "120100"),
                District(code: "120112", name: "津南区", cityCode: "120100"),
                District(code: "120113", name: "北辰区", cityCode: "120100"),
                District(code: "120114", name: "武清区", cityCode: "120100"),
                District(code: "120115", name: "宝坻区", cityCode: "120100"),
                District(code: "120116", name: "滨海新区", cityCode: "120100"),
                District(code: "120117", name: "宁河区", cityCode: "120100"),
                District(code: "120118", name: "静海区", cityCode: "120100"),
                District(code: "120119", name: "蓟州区", cityCode: "120100")
            ]
        case "130100": // 石家庄市
            return [
                District(code: "130102", name: "长安区", cityCode: "130100"),
                District(code: "130104", name: "桥西区", cityCode: "130100"),
                District(code: "130105", name: "新华区", cityCode: "130100"),
                District(code: "130107", name: "井陉矿区", cityCode: "130100"),
                District(code: "130108", name: "裕华区", cityCode: "130100"),
                District(code: "130109", name: "藁城区", cityCode: "130100"),
                District(code: "130110", name: "鹿泉区", cityCode: "130100"),
                District(code: "130111", name: "栾城区", cityCode: "130100"),
                District(code: "130121", name: "井陉县", cityCode: "130100"),
                District(code: "130123", name: "正定县", cityCode: "130100"),
                District(code: "130125", name: "行唐县", cityCode: "130100"),
                District(code: "130126", name: "灵寿县", cityCode: "130100"),
                District(code: "130127", name: "高邑县", cityCode: "130100"),
                District(code: "130128", name: "深泽县", cityCode: "130100"),
                District(code: "130129", name: "赞皇县", cityCode: "130100"),
                District(code: "130130", name: "无极县", cityCode: "130100"),
                District(code: "130131", name: "平山县", cityCode: "130100"),
                District(code: "130132", name: "元氏县", cityCode: "130100"),
                District(code: "130133", name: "赵县", cityCode: "130100"),
                District(code: "130183", name: "晋州市", cityCode: "130100"),
                District(code: "130184", name: "新乐市", cityCode: "130100")
            ]
        case "130700": // 张家口市
            return [
                District(code: "130702", name: "桥东区", cityCode: "130700"),
                District(code: "130703", name: "桥西区", cityCode: "130700"),
                District(code: "130705", name: "宣化区", cityCode: "130700"),
                District(code: "130706", name: "下花园区", cityCode: "130700"),
                District(code: "130708", name: "万全区", cityCode: "130700"),
                District(code: "130709", name: "崇礼区", cityCode: "130700"),
                District(code: "130722", name: "张北县", cityCode: "130700"),
                District(code: "130723", name: "康保县", cityCode: "130700"),
                District(code: "130724", name: "沽源县", cityCode: "130700"),
                District(code: "130725", name: "尚义县", cityCode: "130700"),
                District(code: "130726", name: "蔚县", cityCode: "130700"),
                District(code: "130727", name: "阳原县", cityCode: "130700"),
                District(code: "130728", name: "怀安县", cityCode: "130700"),
                District(code: "130730", name: "怀来县", cityCode: "130700"),
                District(code: "130731", name: "涿鹿县", cityCode: "130700"),
                District(code: "130732", name: "赤城县", cityCode: "130700")
            ]
        case "310100": // 上海市
            return [
                District(code: "310101", name: "黄浦区", cityCode: "310100"),
                District(code: "310104", name: "徐汇区", cityCode: "310100"),
                District(code: "310105", name: "长宁区", cityCode: "310100"),
                District(code: "310106", name: "静安区", cityCode: "310100"),
                District(code: "310107", name: "普陀区", cityCode: "310100"),
                District(code: "310109", name: "虹口区", cityCode: "310100"),
                District(code: "310110", name: "杨浦区", cityCode: "310100"),
                District(code: "310112", name: "闵行区", cityCode: "310100"),
                District(code: "310113", name: "宝山区", cityCode: "310100"),
                District(code: "310114", name: "嘉定区", cityCode: "310100"),
                District(code: "310115", name: "浦东新区", cityCode: "310100"),
                District(code: "310116", name: "金山区", cityCode: "310100"),
                District(code: "310117", name: "松江区", cityCode: "310100"),
                District(code: "310118", name: "青浦区", cityCode: "310100"),
                District(code: "310120", name: "奉贤区", cityCode: "310100"),
                District(code: "310151", name: "崇明区", cityCode: "310100")
            ]
        case "440100": // 广州市
            return [
                District(code: "440103", name: "荔湾区", cityCode: "440100"),
                District(code: "440104", name: "越秀区", cityCode: "440100"),
                District(code: "440105", name: "海珠区", cityCode: "440100"),
                District(code: "440106", name: "天河区", cityCode: "440100"),
                District(code: "440111", name: "白云区", cityCode: "440100"),
                District(code: "440112", name: "黄埔区", cityCode: "440100"),
                District(code: "440113", name: "番禺区", cityCode: "440100"),
                District(code: "440114", name: "花都区", cityCode: "440100"),
                District(code: "440115", name: "南沙区", cityCode: "440100"),
                District(code: "440117", name: "从化区", cityCode: "440100"),
                District(code: "440118", name: "增城区", cityCode: "440100")
            ]
        case "440300": // 深圳市
            return [
                District(code: "440303", name: "罗湖区", cityCode: "440300"),
                District(code: "440304", name: "福田区", cityCode: "440300"),
                District(code: "440305", name: "南山区", cityCode: "440300"),
                District(code: "440306", name: "宝安区", cityCode: "440300"),
                District(code: "440307", name: "龙岗区", cityCode: "440300"),
                District(code: "440308", name: "盐田区", cityCode: "440300"),
                District(code: "440309", name: "龙华区", cityCode: "440300"),
                District(code: "440310", name: "坪山区", cityCode: "440300"),
                District(code: "440311", name: "光明区", cityCode: "440300"),
                District(code: "440312", name: "大鹏新区", cityCode: "440300")
            ]
        case "330100": // 杭州市
            return [
                District(code: "330102", name: "上城区", cityCode: "330100"),
                District(code: "330105", name: "拱墅区", cityCode: "330100"),
                District(code: "330106", name: "西湖区", cityCode: "330100"),
                District(code: "330108", name: "滨江区", cityCode: "330100"),
                District(code: "330109", name: "萧山区", cityCode: "330100"),
                District(code: "330110", name: "余杭区", cityCode: "330100"),
                District(code: "330111", name: "富阳区", cityCode: "330100"),
                District(code: "330112", name: "临安区", cityCode: "330100"),
                District(code: "330113", name: "临平区", cityCode: "330100"),
                District(code: "330114", name: "钱塘区", cityCode: "330100"),
                District(code: "330122", name: "桐庐县", cityCode: "330100"),
                District(code: "330127", name: "淳安县", cityCode: "330100"),
                District(code: "330182", name: "建德市", cityCode: "330100")
            ]
        case "510100": // 成都市
            return [
                District(code: "510104", name: "锦江区", cityCode: "510100"),
                District(code: "510105", name: "青羊区", cityCode: "510100"),
                District(code: "510106", name: "金牛区", cityCode: "510100"),
                District(code: "510107", name: "武侯区", cityCode: "510100"),
                District(code: "510108", name: "成华区", cityCode: "510100"),
                District(code: "510112", name: "龙泉驿区", cityCode: "510100"),
                District(code: "510113", name: "青白江区", cityCode: "510100"),
                District(code: "510114", name: "新都区", cityCode: "510100"),
                District(code: "510115", name: "温江区", cityCode: "510100"),
                District(code: "510116", name: "双流区", cityCode: "510100"),
                District(code: "510117", name: "郫都区", cityCode: "510100"),
                District(code: "510118", name: "新津区", cityCode: "510100"),
                District(code: "510121", name: "金堂县", cityCode: "510100"),
                District(code: "510129", name: "大邑县", cityCode: "510100"),
                District(code: "510131", name: "蒲江县", cityCode: "510100"),
                District(code: "510132", name: "都江堰市", cityCode: "510100"),
                District(code: "510181", name: "彭州市", cityCode: "510100"),
                District(code: "510182", name: "邛崃市", cityCode: "510100"),
                District(code: "510183", name: "崇州市", cityCode: "510100"),
                District(code: "510184", name: "简阳市", cityCode: "510100")
            ]
        default:
            return []
        }
    }
}

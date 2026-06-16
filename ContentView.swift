import SwiftUI

// MARK: - 1. データ構造の定義
struct QuizItem: Identifiable {
    let id = UUID()
    let difficulty: String
    let name: String
    var type: String = "step"
    var answer: String = ""
    var steps: [String] = []
    var portionData: [PortionDetail] = []
}

struct PortionDetail: Identifiable {
    let id = UUID()
    let item: String
    let amount: String
    let unit: String
}

// MARK: - 2. メインビュー
struct ContentView: View {
    // ==========================================
    // 管理者設定エリア（ここを自由に書き換えてください）
    // ==========================================
    let correctPassword = "1405"
    let shiftImageUrl1 = "https://drive.google.com/file/d/1zHH3IqT30XMp83ft2s6X7oAM-8ySHNNP/view?usp=drive_link"
    let shiftImageUrl2 = "https://drive.google.com/file/d/1J-N8B4IvyShS9qhQTNpTsvL67wxqFihk/view?usp=drive_link"
    let shiftUpdateTime = "2024/03/12 18:00 更新" // ←ここを変えるだけで両方の画面が連動します
    
    // アプリの状態管理
    @State private var passwordInput = ""
    @State private var isUnlocked = false
    @State private var showErrorMsg = false
    @State private var isShake = false
    @State private var selectedCategory: String? = nil
    @State private var showShiftScreen = false
    
    var body: some View {
        ZStack {
            Color(red: 0.94, green: 0.95, blue: 0.96).ignoresSafeArea() // 背景色 (#f0f2f5)
            
            if !isUnlocked {
                // --- 🔒 合言葉入力画面 ---
                VStack(spacing: 20) {
                    Text("🔒")
                        .font(.system(size: 60))
                    
                    Text("合言葉を入力してください")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    SecureField("****", text: $passwordInput)
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                        )
                        .keyboardType(.numberPad)
                    
                    Button(action: checkPassword) {
                        Text("認証する")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    if showErrorMsg {
                        Text("合言葉が違います")
                            .foregroundColor(.red)
                            .fontWeight(.bold)
                    }
                }
                .padding(30)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 4)
                .padding(.horizontal, 20)
                .offset(x: isShake ? -10 : 0) // 間違えたときのブルブル用
            } else {
                // --- 📱 メインコンテンツ ---
                NavigationView {
                    VStack {
                        if !showShiftScreen && selectedCategory == nil {
                            // --- カテゴリ選択画面 ---
                            VStack(spacing: 4) {
                                Text("Latest Update:")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                Text(shiftUpdateTime)
                                    .font(.caption)
                                    .fontWeight(.black)
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .cornerRadius(20)
                            .padding(.bottom, 20)
                            
                            VStack(spacing: 12) {
                                categoryButton(title: "🐟 刺し場", color: .blue) { selectedCategory = "single_star" }
                                categoryButton(title: "🍟 揚げ場", color: .orange) { selectedCategory = "double_star" }
                                categoryButton(title: "🔥 焼き場", color: .red) { selectedCategory = "triple_star" }
                                categoryButton(title: "⚖️ ポーション", color: .green) { selectedCategory = "portion" }
                                categoryButton(title: "📅 シフト表", color: .purple) { showShiftScreen = true }
                            }
                            .padding(.horizontal, 20)
                            Spacer()
                        } else if showShiftScreen {
                            // --- シフト表画面 ---
                            ShiftView(updateTime: shiftUpdateTime, url1: shiftImageUrl1, url2: shiftImageUrl2) {
                                showShiftScreen = false
                            }
                        } else if let category = selectedCategory {
                            // --- メニューリスト（アコーディオン）画面 ---
                            MenuListView(category: category, quizzes: quizzes) {
                                selectedCategory = nil
                            }
                        }
                    }
                    .navigationTitle("キッチンメモ")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
    }
    
    // パスワードチェック
    func checkPassword() {
        if passwordInput == correctPassword {
            withAnimation { isUnlocked = true }
        } else {
            showErrorMsg = true
            withAnimation(.default.repeatCount(3, autoreverses: true).speed(2)) {
                isShake = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isShake = false
            }
        }
    }
    
    // カテゴリ選択ボタン
    func categoryButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                Spacer()
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                VStack {
                    Spacer()
                    Rectangle()
                        .frame(height: 4)
                        .foregroundColor(color)
                }
                .cornerRadius(16)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }
}

// MARK: - 3. メニューリスト表示（アコーディオン）
struct MenuListView: View {
    let category: String
    let quizzes: [QuizItem]
    let onBack: () -> Void
    
    var categoryName: String {
        switch category {
        case "single_star": return "刺し場"
        case "double_star": return "揚げ場"
        case "triple_star": return "焼き場"
        case "portion": return "ポーション"
        default: return ""
        }
    }
    
    var filteredQuizzes: [QuizItem] {
        quizzes.filter { $0.difficulty == category }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("【\(categoryName)】")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(red: 0.3, green: 0.34, blue: 0.41))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(filteredQuizzes) { quiz in
                        // SwiftUI標準のアコーディオンUI
                        DisclosureGroup(quiz.name) {
                            VStack(alignment: .leading, spacing: 10) {
                                if category == "portion" {
                                    VStack(spacing: 0) {
                                        ForEach(quiz.portionData) { detail in
                                            HStack {
                                                Text(detail.item)
                                                Spacer()
                                                Text("\(detail.amount)\(detail.unit)")
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.green)
                                            }
                                            .padding(.vertical, 8)
                                            Divider()
                                        }
                                    }
                                } else if category == "triple_star" {
                                    Text("味付け：\(quiz.answer)")
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(12)
                                } else if quiz.type == "multiple_choice" {
                                    Text(quiz.answer)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(12)
                                } else {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(0..<quiz.steps.count, id: \.self) { index in
                                            HStack(alignment: .top) {
                                                Text("\(index + 1).")
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.blue)
                                                Text(quiz.steps[index])
                                                    .font(.subheadline)
                                            }
                                            .padding(10)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color(red: 0.97, green: 0.98, blue: 0.99))
                                            .cornerRadius(8)
                                            .overlay(
                                                HStack {
                                                    Rectangle().frame(width: 4).foregroundColor(.blue)
                                                    Spacer()
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(.top, 10)
                        }
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Button(action: onBack) {
                Text("戻る")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.12, green: 0.16, blue: 0.22))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - 4. シフト表画面
struct ShiftView: View {
    let updateTime: String
    let url1: String
    let url2: String
    let onBack: () -> Void
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("📅 シフト表")
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(Color(red: 0.55, green: 0.36, blue: 0.96))
                    
                    // ★ここが新しく追加された「シフト画面内の更新日時表示」です
                    Text(updateTime)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.55, green: 0.36, blue: 0.96))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.55, green: 0.36, blue: 0.96).opacity(0.1))
                        .cornerRadius(20)
                    
                    shiftImageSection(title: "▼ 1日 〜 15日", urlString: url1)
                    shiftImageSection(title: "▼ 16日 〜 末日", urlString: url2)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal, 20)
            }
            
            Button(action: onBack) {
                Text("メニューに戻る")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.12, green: 0.16, blue: 0.22))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
    }
    
    func shiftImageSection(title: String, urlString: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.purple)
            
            let finalUrlString = convertDriveUrl(urlString)
            if let url = URL(string: finalUrlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(8)
                    case .failure(_):
                        Text("画像の読み込みに失敗しました\n共有設定を確認してください")
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                    @unknown default:
                        ProgressView()
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                    }
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.purple.opacity(0.2), lineWidth: 2))
            }
        }
    }
    
    func convertDriveUrl(_ rawUrl: String) -> String {
        var fileId = ""
        if rawUrl.contains("/d/") {
            let components = rawUrl.components(separatedBy: "/d/")
            if components.count > 1 { fileId = components[1].components(separatedBy: "/")[0] }
        } else if rawUrl.contains("id=") {
            let components = rawUrl.components(separatedBy: "id=")
            if components.count > 1 { fileId = components[1].components(separatedBy: "&")[0] }
        }
        if !fileId.isEmpty { return "https://drive.google.com/thumbnail?authuser=0&sz=w1000&id=\(fileId)" }
        return rawUrl
    }
}

// MARK: - 5. メニューデータ配列
let quizzes: [QuizItem] = [
    // 刺し場
    QuizItem(difficulty: "single_star", name: "枝豆", type: "multiple_choice", answer: "500W 2分 皿に盛り付けて塩をふる"),
    QuizItem(difficulty: "single_star", name: "冷やしトマト", type: "reordering", steps: ["トマト１個を半分に切りヘタ部分を取り除く","トマトを６等分に切る","マヨネーズとサラダを添える"]),
    QuizItem(difficulty: "single_star", name: "たこわさ", type: "multiple_choice", answer: "半分にした大葉 たこわさ(30g)を盛り付け"),
    QuizItem(difficulty: "single_star", name: "梅クラゲ", type: "multiple_choice", answer: "半分にした大葉 梅クラゲ(30g)を盛り付け"),
    QuizItem(difficulty: "single_star", name: "チャンジャ", type: "multiple_choice", answer: "半分にした大葉 チャンジャ(30g)を盛り付け、ネギ〆"),
    QuizItem(difficulty: "single_star", name: "とりかわぽん", type: "reordering", steps: ["大葉を敷く", "オニスラ", "とりかわ盛りつけ", "ネギ、大根おろし","ポン酢"]),
    QuizItem(difficulty: "single_star", name: "えのきぽん", type: "reordering", steps: ["500W1分", "えのき盛りつけ", "ネギ、大根おろし","ポン酢"]),
    QuizItem(difficulty: "single_star", name: "無限ピーマン", type: "multiple_choice", answer: "ごま油、塩、塩昆布、白ごま"),
    QuizItem(difficulty: "single_star", name: "漬物盛合せ", type: "multiple_choice", answer: "たくあん30g、かっぱ30g、しば漬け30g"),
    QuizItem(difficulty: "single_star", name: "長芋わさび", type: "multiple_choice", answer: "器に長いもを80g盛り、刻みのり〆"),
    QuizItem(difficulty: "single_star", name: "たたききゅうり", type: "reordering", steps: ["皿にたたききゅうりを盛る", "しおだれをかける", "ゴマ〆"]),
    QuizItem(difficulty: "single_star", name: "とりのたたき", type: "reordering", steps: ["器にオニスラを盛る","大葉を乗せる","たたき4枚", "小皿にネギ、しょうが"]),
    QuizItem(difficulty: "single_star", name: "鶏わさび和え", type: "reordering", steps: ["皿に大葉を乗せる","オニスラを盛る" , "ユッケ60Gわさびと醤油混ぜて盛り付け","のり"]),
    QuizItem(difficulty: "single_star", name: "鶏梅肉和え", type: "reordering", steps: ["皿に大葉を乗せる","オニスラを盛る" , "ユッケ60G梅肉を混ぜて盛り付ける","のり"]),
    QuizItem(difficulty: "single_star", name: "鶏ユッケ", type: "reordering", steps: ["皿に大葉を乗せる","オニスラを盛る" , "ユッケ60g盛る", "ユッケタレをかける","生うずら","ネギと白ごま"]),
    QuizItem(difficulty: "single_star", name: "鶏塩ユッケ", type: "reordering", steps: ["皿に大葉を乗せる","オニスラを盛る" , "ユッケ60g盛る", "塩だれをかける","生うずら","ネギと白ごま"]),
    QuizItem(difficulty: "single_star", name: "出汁巻きたまご", type: "multiple_choice", answer: "600W 4分 笹葉の上に盛り付けて おろし大根 〆"),
    QuizItem(difficulty: "single_star", name: "しめさば", type: "multiple_choice", answer: "水で解けたら8等分にして炙る オニスラ、大葉の上に盛り付けて わさび"),
    QuizItem(difficulty: "single_star", name: "蒸し鶏サラダ", type: "multiple_choice", answer: "サラダ、オニスラ、半分にしたミニトマト（2個）にささみ1ポーション 胡麻ドレッシング〆"),
    QuizItem(difficulty: "single_star", name: "豆腐と塩昆布のサラダ", type: "multiple_choice", answer: "サラダ、オニスラ、半分にしたミニトマト（2個）に4等分の豆腐と塩昆布 和風ドレッシング、かつお節〆"),
    QuizItem(difficulty: "single_star", name: "温玉シーザーサラダ", type: "multiple_choice", answer: "サラダ、オニスラ、半分にしたミニトマト（2個）に温玉１個、クルトン、粉チーズかけて シーザードレッシング〆"),
    
    // 揚げ場
    QuizItem(difficulty: "double_star", name: "ポテトフライ", type: "multiple_choice", answer: "2分30秒間揚げる 塩ふりかけ、ケチャップ"),
    QuizItem(difficulty: "double_star", name: "さつまバター", type: "multiple_choice", answer: "4分間揚げる バター ハチミツとパセリ"),
    QuizItem(difficulty: "double_star", name: "もろこし唐揚げ", type: "multiple_choice", answer: "3分間揚げる 塩ふりかけ パセリ"),
    QuizItem(difficulty: "double_star", name: "名古屋風手羽先唐揚げ", type: "multiple_choice", answer: "500W1分 片栗粉5分間揚げる キャベツの上に盛り付けて手羽タレ、コショウ、白ごま"),
    QuizItem(difficulty: "double_star", name: "なんこつ唐揚げ", type: "multiple_choice", answer: "唐揚げ粉2分間揚げる レモン"),
    QuizItem(difficulty: "double_star", name: "かわパリ", type: "multiple_choice", answer: "500W1分 片栗粉+唐揚げ粉2分間揚げる レモン"),
    QuizItem(difficulty: "double_star", name: "じゃこ天", type: "multiple_choice", answer: "両面3分間揚げる 天紙の上に６等分してネギ、しょうが"),
    QuizItem(difficulty: "double_star", name: "若鶏のからあげ", type: "multiple_choice", answer: "片栗粉5分間揚げる サラダの上に盛り付け レモン、マヨネーズ"),
    QuizItem(difficulty: "double_star", name: "チキン南蛮", type: "multiple_choice", answer: "500W1分 5分間揚げる 4等分にしてサラダの上に盛り付け、タルタル 南蛮酢 レモン、パセリ"),
    
    // 焼き場
    QuizItem(difficulty: "triple_star", name: "レタス巻き", answer: "塩コショウ"),
    QuizItem(difficulty: "triple_star", name: "ヤンコン巻き", answer: "塩コショウ"),
    QuizItem(difficulty: "triple_star", name: "えのき巻き", answer: "ポン酢"),
    QuizItem(difficulty: "triple_star", name: "うずら巻き", answer: "タレ"),
    QuizItem(difficulty: "triple_star", name: "大葉巻き", answer: "梅肉"),
    QuizItem(difficulty: "triple_star", name: "アスパラ巻き", answer: "塩コショウ"),
    QuizItem(difficulty: "triple_star", name: "トマトチーズ巻き", answer: "バジル"),
    QuizItem(difficulty: "triple_star", name: "なすチーズ巻き", answer: "タレ"),
    QuizItem(difficulty: "triple_star", name: "白ネギ巻き", answer: "タレ"),
    QuizItem(difficulty: "triple_star", name: "えびの肉巻き(タルタル)", answer: "塩コショウ"),
    QuizItem(difficulty: "triple_star", name: "モッツァレラチーズ巻き", answer: "塩コショウ"),
    QuizItem(difficulty: "triple_star", name: "長芋明太マヨ巻き", answer: "明太マヨ"),
    QuizItem(difficulty: "triple_star", name: "オクラの肉巻き", answer: "塩コショウ"),
    
    // ポーション
    QuizItem(difficulty: "portion", name: "刺し場・野菜", portionData: [
        PortionDetail(item: "ピーマン", amount: "40", unit: "g"),
        PortionDetail(item: "きゅうり", amount: "85-90", unit: "g"),
        PortionDetail(item: "枝豆", amount: "100", unit: "g"),
        PortionDetail(item: "えのぽん", amount: "60", unit: "g"),
        PortionDetail(item: "蒸し鶏", amount: "50", unit: "g")
    ]),
    QuizItem(difficulty: "portion", name: "揚げ場・一品", portionData: [
        PortionDetail(item: "角煮", amount: "90/3", unit: "g/個"),
        PortionDetail(item: "ポテトフライ", amount: "150", unit: "g"),
        PortionDetail(item: "手羽先", amount: "3", unit: "個"),
        PortionDetail(item: "とうもろこし", amount: "3", unit: "個"),
        PortionDetail(item: "軟骨唐揚げ", amount: "100", unit: "g"),
        PortionDetail(item: "かわぱり", amount: "100", unit: "g"),
        PortionDetail(item: "里芋", amount: "8", unit: "個"),
        PortionDetail(item: "ウインナー", amount: "6", unit: "個")
    ]),
    QuizItem(difficulty: "portion", name: "焼き場・肉", portionData: [
        PortionDetail(item: "エイヒレ", amount: "30", unit: "g"),
        PortionDetail(item: "焼きおにぎり", amount: "160", unit: "g"),
        PortionDetail(item: "サザエ", amount: "2", unit: "個"),
        PortionDetail(item: "ホタテ", amount: "1", unit: "個"),
        PortionDetail(item: "ホルモン", amount: "150", unit: "g"),
        PortionDetail(item: "つくね", amount: "50", unit: "g")
    ]),
    QuizItem(difficulty: "portion", name: "釜飯・雑炊・調味料", portionData: [
        PortionDetail(item: "浸水米", amount: "200", unit: "g"),
        PortionDetail(item: "雑炊・釜飯 鶏肉", amount: "50", unit: "g"),
        PortionDetail(item: "釜野菜(あげ・ゴボウ)", amount: "各10", unit: "g"),
        PortionDetail(item: "雑炊エノキ", amount: "15", unit: "g"),
        PortionDetail(item: "赤味噌", amount: "90", unit: "g"),
        PortionDetail(item: "白味噌(ニンニク5gバター2個)", amount: "90", unit: "g"),
        PortionDetail(item: "凍結果実", amount: "40", unit: "g")
    ])
];

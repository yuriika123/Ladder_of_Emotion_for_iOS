import SwiftUI
import SwiftData

@Model
class EmotionRecord {
    var floor: Int
    var emotionName: String // どの感情か (例: "安全")
    var timestamp: Date // いつ記録したか
    var memo: String // メモの内容
    
    init(floor: Int, emotionName: String, timestamp: Date, memo: String) {
        self.floor = floor
        self.emotionName = emotionName
        self.timestamp = timestamp
        self.memo = memo
    }
}

struct ContentView: View {
    
    @Query(sort: \EmotionRecord.timestamp, order: .reverse) private var records: [EmotionRecord]
    
    @Environment(\.modelContext) private var modelContext
    
    let buttonLabels = [
        "腹足迷走神経系",
        "安全",
        "社会的",
        "交感神経系",
        "可動化",
        "闘争 / 逃走",
        "背足迷走神経系",
        "不動化",
        "シャットダウン"
    ]
    
    // シートを表示するかどうかを覚えておくための変数
    @State private var showingMemoInput = false
    // どの感情ボタンが押されたかを覚えておくための変数
    @State private var selectedEmotion = ""
    // どのフロアか覚えておく変数
    @State private var selectedFloor = 0
    
    
    var body: some View {
        TabView {
            VStack(spacing: 15) {
                HStack(spacing: 10) {
                    VStack {
                        ForEach(1...9, id: \.self) { floor in
                            Text("\(10 - floor)")
                                .padding()
                                .glassEffect()
                                .background(colorForFloorNumber(with: floor))
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .font(.system(size: 22, weight: .bold))
                        }
                        .glassEffect()
                        .clipShape(Circle())
                    }
                    VStack {
                        ForEach(Array(buttonLabels.enumerated()), id: \.element) { index, label in
                            Button(action: {
                                selectedEmotion = label
                                selectedFloor = 10 - (index + 1)
                                showingMemoInput = true
                            }) {
                                Text(label)
                            }
                            .tracking(4)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .glassEffect()
                            .background(colorForButton(with: label))
                            .foregroundColor(.white)
                            .cornerRadius(30)
                            .font(.system(size: 22, weight: .bold))
                        }
                        .glassEffect()
                    }
                }
                .padding()
            }
            .padding()
            .tabItem {
                Label("感情記録", systemImage: "heart.text.clipboard")
            }
            HistoryView()
                .tabItem {
                    Label("履歴", systemImage: "list.bullet")
                }
        }
        .sheet(isPresented: $showingMemoInput) {
            MemoInputView (
                emotionName: selectedEmotion,
                onSave: { memo in
                    addRecord(memo: memo)
                    showingMemoInput = false
                },
                onCancel: {
                    showingMemoInput = false
                }
            )
        }
    }
    
    func colorForButton(with label: String) -> Color {
        switch label {
        case "腹足迷走神経系", "安全", "社会的":
            return Color.mint
        case "交感神経系", "可動化", "闘争 / 逃走":
            return Color.cyan
        default:
            return Color.blue
        }
    }
    
    func colorForFloorNumber(with floor: Int) -> Color {
        switch floor {
        case 1...3:
            return Color.mint
        case 4...6:
            return Color.cyan
        default:
            return Color.blue
        }
    }
    
    func addRecord(memo: String) {
        let newRecord = EmotionRecord(
            floor: selectedFloor,
            emotionName: selectedEmotion,
            timestamp: Date(),
            memo: memo
        )
        modelContext.insert(newRecord)
        print("新しい記録を追加しました：\(newRecord)")
    }
    
}

struct MemoInputView: View {
    // ContentViewから受け取るデータ
    let emotionName: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    
    // このビューの中で使う、メモのテキストを覚えておく変数
    @State private var memoText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // 1. 感情名を表示
                Text("記録")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .padding()
                    .glassEffect()
                    .foregroundColor(.teal)
                
                // 2. メモ入力欄
                TextEditor(text: $memoText)
                    .border(Color.gray, width: 1)
                    .padding()
                if memoText.isEmpty {
                    Text("メモを入力してください")
                        .foregroundColor(.gray)
                        .padding(.top, 12)
                        .padding(.leading, 6)
                }
                
                Spacer()
            }
            .navigationTitle("メモを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave(memoText)
                    }
                }
            }
        }
    }
}

struct FilterView: View {
    // --- フィルタ機能用の変数を追加 ---
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var selectedFloor: Int?
    @Binding var showOnlyWithMemo: Bool
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("日付で絞り込み")) {
                    DatePicker("開始日", selection: $startDate, displayedComponents: .date)
                    DatePicker("終了日", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
                Section(header: Text("内容で絞り込み")) {
                    Picker("フロアを選択", selection: $selectedFloor) {
                        Text("すべてのフロア").tag(Int?.none)
                        ForEach((1...9).reversed(), id: \.self) { floor in
                            Text("\(floor)階").tag(Int?.some(floor))
                        }
                    }
                    .pickerStyle(.menu)
                    Toggle("メモがある記録のみ", isOn: $showOnlyWithMemo)
                }
            }
            .navigationTitle("フィルター")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct HistoryView: View {
    @Query(sort: \EmotionRecord.timestamp, order: .reverse) private var records: [EmotionRecord]
    
    @Environment(\.modelContext) private var modelContext
    
    // --- フィルタ機能用の変数を追加 ---
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @State private var endDate: Date = Date()
    @State private var selectedFloor: Int? = nil
    @State private var showOnlyWithMemo = false
    
    @State private var isShowingFilterSheet = false
    
    // --- フィルターされた履歴を計算する部分 ---
    var filteredRecords: [EmotionRecord] {
        records.filter { record in
            let calendar = Calendar.current
            let endOfDay = calendar.startOfDay(for: endDate)
            let adjustedEndDate = calendar.date(byAdding: .day, value: 1, to: endOfDay)!
            
            let isDateInRange = record.timestamp >= startDate && record.timestamp < Calendar.current.date(byAdding: .day, value: 1, to: endDate)!
            let isFloorMatch = selectedFloor == nil || record.floor == selectedFloor
            let hasMemo = !showOnlyWithMemo || !record.memo.isEmpty
            return isDateInRange && isFloorMatch && hasMemo
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if records.isEmpty {
                    Spacer()
                    Text("感情記録がありません")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    List {
                        ForEach(filteredRecords) { record in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("\(record.floor)")
                                        .font(.headline)
                                        .frame(width: 30, height: 30)
                                        .glassEffect()
                                        .background(colorForFloorNumber(with: record.floor).opacity(0.5))
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                        .glassEffect()
                                    Text(record.emotionName)
                                        .font(.headline)
                                        .padding(6)
                                        .glassEffect()
                                        .background(colorForFloorNumber(with: record.floor).opacity(0.5))
                                        .foregroundColor(.white)
                                        .cornerRadius(20)
                                        .glassEffect()
                                    
                                    Spacer()
                                    
                                    Text(record.timestamp, style: .date)
                                    Text(record.timestamp, style: .time)
                                }
                                
                                if !record.memo.isEmpty {
                                    Text(record.memo)
                                        .font(.body)
                                        .padding(.top, 4)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .onDelete(perform: deleteRecord)
                    }
                }
            }
            .navigationTitle("履歴")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isShowingFilterSheet = true // ボタンを押すとシートが表示される
                    } label: {
                        // アイコンとテキストで分かりやすく
                        Label("フィルター", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("条件をリセット") {
                        startDate = .distantPast
                        endDate = .distantFuture
                        selectedFloor = nil
                        showOnlyWithMemo = false
                    }
                }
            }
            .sheet(isPresented: $isShowingFilterSheet) {
                FilterView(
                    startDate: $startDate,
                    endDate: $endDate,
                    selectedFloor: $selectedFloor,
                    showOnlyWithMemo: $showOnlyWithMemo
                )
            }
        }
    }
    
    func deleteRecord(at offsets: IndexSet) {
        for offset in offsets {
            let recordToDelete = filteredRecords[offset]
            if let index = records.firstIndex(where: { $0.id == recordToDelete.id }) {
                modelContext.delete(records[index])
            }
        }
    }
    
    func colorForFloorNumber(with floor: Int) -> Color {
        switch floor {
        case 1...3:
            return Color.blue
        case 4...6:
            return Color.cyan
        default:
            return Color.mint
        }
    }
}


#Preview {
    ContentView()
}

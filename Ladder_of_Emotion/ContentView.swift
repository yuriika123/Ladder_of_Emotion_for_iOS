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

struct HistoryView: View {
    @Query(sort: \EmotionRecord.timestamp, order: .reverse) private var records: [EmotionRecord]
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack {
            if records.isEmpty {
                Spacer()
                Text("感情記録がありません")
                    .font(.headline)
                    .foregroundColor(.gray)
                Spacer()
            } else {
                List {
                    ForEach(records) { record in
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
    }
    
    func deleteRecord(at offsets: IndexSet) {
        for offset in offsets {
            let record = records[offset]
            modelContext.delete(record)
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

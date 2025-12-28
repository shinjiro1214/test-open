import os
import glob
import numpy as np
import plotly.graph_objects as go

# ==========================================
# 設定
# ==========================================
DATA_DIR = "/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Filters/data/"

def main():
    # ファイル一覧取得
    file_list = glob.glob(os.path.join(DATA_DIR, "*.txt"))
    
    # ファイルが見つからない場合
    if not file_list:
        print(f"No text files found in {DATA_DIR}")
        return

    # ファイル名でソート（アルファベット順に並べる）
    file_list.sort()

    fig = go.Figure()

    print(f"Processing {len(file_list)} files...")

    for filepath in file_list:
        try:
            # ファイル名からラベル作成
            # 例: "Pb_0.1um.txt" -> "Pb 0.1um" のように見やすく変換
            filename = os.path.basename(filepath)
            label_name = filename.replace(".txt", "").replace("_", " ") 
            
            # データ読み込み
            data = np.loadtxt(filepath, skiprows=2)
            if data.size == 0: continue

            energy = data[:, 0]
            transmission = data[:, 1]

            # ★ロジック変更: 条件分岐(if)を削除し、全てを「メインの線」として描画
            fig.add_trace(go.Scatter(
                x=energy, 
                y=transmission, 
                mode='lines',
                name=label_name, # 凡例名
                line=dict(width=2.5), # 線の太さを統一
                hovertemplate=f"<b>{label_name}</b><br>E: %{{x:.1f}} eV<br>T: %{{y:.4f}}<extra></extra>"
            ))

        except Exception as e:
            print(f"Error reading {filename}: {e}")

    # レイアウト設定
    fig.update_layout(
        title="Soft X-ray Filter Transmission (All Files)",
        xaxis_title="Photon Energy (eV)",
        yaxis_title="Transmission",
        template="plotly_white",
        height=900,  # 縦長
        width=1200,  # 横幅も少し広く
        hovermode="closest",
        legend=dict(
            yanchor="top",
            y=0.99,
            xanchor="left",
            x=1.05  # 凡例をグラフの外（右側）に出す
        )
    )
    
    # ★ X軸範囲を 0 から 1000 (1e3) に固定
    fig.update_xaxes(range=[0, 1000])

    # Y軸を対数にしたい場合は以下を有効化
    # fig.update_yaxes(type="log")

    fig.show()

if __name__ == "__main__":
    main()
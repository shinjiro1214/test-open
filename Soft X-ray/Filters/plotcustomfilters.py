import os
import numpy as np
import plotly.graph_objects as go

# ==========================================
# 設定
# ==========================================
DATA_DIR = "/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Filters/"

# ★ プロットしたいファイルの条件と、グラフでの表示名を定義
# 辞書のキー: ファイル名のパターン（Formula_厚みum.txt）
# 辞書の値: グラフの凡例に表示したい名前
TARGETS = {
    "data/Al_1.0um.txt": "Al 1.0µm",
    "data/Al_2.5um.txt": "Al 2.5µm",
    "data/C10H8O4_1.0um.txt": "Mylar 1.0µm",
    "data/C10H8O4_2.0um.txt": "Mylar 2.0µm"
    # "data/Ti_0.5um.txt": "Ti 0.5µm",
    # "data/C2F4_4.0um.txt": "Teflon 4.0µm",
    # "data/Zr_0.6um.txt": "Zr 0.6µm"
}

def main():
    fig = go.Figure()

    print("Plotting selected targets...")
    
    # ターゲットとして指定されたファイルだけを順番に処理
    for filename, legend_name in TARGETS.items():
        filepath = os.path.join(DATA_DIR, filename)
        
        # ファイルが存在するか確認
        if not os.path.exists(filepath):
            print(f"Warning: File not found: {filename}")
            continue

        try:
            # データ読み込み
            data = np.loadtxt(filepath, skiprows=2)
            if data.size == 0: continue

            energy = data[:, 0]
            transmission = data[:, 1]

            # プロット追加
            fig.add_trace(go.Scatter(
                x=energy, 
                y=transmission, 
                mode='lines',
                name=legend_name, # ここで分かりやすい名前を使用
                line=dict(width=2.5),
                hovertemplate=f"<b>{legend_name}</b><br>E: %{{x:.1f}} eV<br>T: %{{y:.4f}}<extra></extra>"
            ))
            print(f" -> Added: {filename}")

        except Exception as e:
            print(f"Error reading {filename}: {e}")

    # レイアウト設定
    fig.update_layout(
        title="Soft X-ray Filter Transmission (Selected)",
        xaxis_title="Photon Energy (eV)",
        yaxis_title="Transmission",
        template="plotly_white",
        height=800,
        width=1000,
        hovermode="closest",
        legend=dict(
            yanchor="top",
            y=0.99,
            xanchor="left",
            x=1.02,
            font=dict(size=40)
        )
    )
    
    # X軸範囲設定 (0 - 1000 eV)
    fig.update_xaxes(
        range=[0, 400],
        title_text ="Photon Energy (eV)",
        title_font=dict(size=40),
        tickfont=dict(size=30)
    )

    # Y軸を対数表示にしたい場合はコメントアウトを外す
    fig.update_yaxes(
        title_text="Transmission",
        title_font=dict(size=40),  # 軸タイトルのフォントサイズ
        tickfont=dict(size=30)     # 目盛りのフォントサイズ
    )

    fig.show()

if __name__ == "__main__":
    main()
import os
import glob
import numpy as np
import plotly.graph_objects as go

# ==========================================
# 設定
# ==========================================
DATA_DIR = "/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Filters/data/"

# ★ すべての材料をハイライトリストに入れました
HIGHLIGHT_MATERIALS = [
    "Al",
    "Al2O3",
    "Be",
    "B",
    "C",
    "Cr",
    "Co",
    "Cu",
    "Ge",
    "Au",    
    "Hf",
    "In",
    "Fe",
    "C22N2O4H12",
    "Pb",
    "LiF",
    "Mg",
    "MgF2", 
    "Mo",
    "C10H8O4",
    "Ni",
    "Nb",
    "C8H8",
    "Pd",
    "Pt",
    "C16H14O3",
    "C3H6",
    "Rh",
    "Si",
    "SiO2",
    "Si3N4",
    "Ag",
    "Ta",
    "Tf", 
    "Sn",
    "Ti",
    "TiO",
    "W",
    "V",
    "Zn",
    "Zr"
]

def main():
    # ファイル一覧取得
    file_list = glob.glob(os.path.join(DATA_DIR, "*.txt"))
    if not file_list:
        print("No text files found.")
        return

    fig = go.Figure()

    print(f"Processing {len(file_list)} files...")

    for filepath in file_list:
        try:
            # ファイル名からラベル作成 (例: "Al2O3.txt" -> "Al2O3")
            filename = os.path.basename(filepath)
            label_name = filename.replace(".txt", "").replace("_", "/")
            
            # データ読み込み
            data = np.loadtxt(filepath, skiprows=2)
            if data.size == 0: continue

            energy = data[:, 0]
            transmission = data[:, 1]

            # ★ロジック: リストにある場合(今回は全部)はカラー表示、なければグレー
            # 実質すべてのファイルが if 側に入ります
            if label_name in HIGHLIGHT_MATERIALS:
                # 【ハイライト設定】
                trace = go.Scatter(
                    x=energy, 
                    y=transmission, 
                    mode='lines',
                    name=label_name,
                    line=dict(width=3), # 太めの線
                    hovertemplate=f"<b>{label_name}</b><br>E: %{{x:.1f}} eV<br>T: %{{y:.4f}}<extra></extra>"
                )
                fig.add_trace(trace)
            else:
                # リストにない未知のファイルがあればここに来ます（グレー表示）
                trace = go.Scatter(
                    x=energy, 
                    y=transmission, 
                    mode='lines',
                    name=label_name,
                    line=dict(color='rgba(150, 150, 150, 0.3)', width=1),
                    hovertemplate=f"{label_name}<br>E: %{{x:.1f}} eV<br>T: %{{y:.4f}}<extra></extra>"
                )
                fig.add_trace(trace)

        except Exception as e:
            print(f"Error reading {filename}: {e}")

    # レイアウト設定
    fig.update_layout(
        title="Soft X-ray Filter Transmission (All Highlighted)",
        xaxis_title="Photon Energy (eV)",
        yaxis_title="Transmission",
        template="plotly_white",
        height=800,  # 縦長
        width=1000,
        hovermode="closest"
    )
    
    # ★ X軸範囲を 0 から 1000 (1e3) に固定
    fig.update_xaxes(range=[0, 1000])

    # Y軸を対数にしたい場合は以下を有効化
    # fig.update_yaxes(type="log")

    fig.show()

if __name__ == "__main__":
    main()
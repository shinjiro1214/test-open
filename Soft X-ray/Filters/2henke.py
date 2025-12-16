import os
import csv
import time
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin

# ==========================================
# 設定
# ==========================================
SAVE_DIR = "/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Filters/data/"
CSV_FILENAME = "materials.csv"
HENKE_URL = "https://henke.lbl.gov/optical_constants/filter2.html"

# ヘッダー定義
headers = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
}

# 計算パラメータ
THICKNESS = 1.0   # microns
MIN_ENERGY = 10   # eV
MAX_ENERGY = 1000 # eV
STEPS = 100

def get_action_url(session):
    """フォームの送信先URLを取得"""
    # sessionにはすでにヘッダーがセットされているので、ここでは引数不要
    r = session.get(HENKE_URL) 
    soup = BeautifulSoup(r.content, "html.parser")
    form = soup.find("form")
    if not form:
        return None
    return urljoin(HENKE_URL, form.get("action"))

def download_data(session, action_url, formula, density):
    """Henkeからデータをダウンロードして保存"""
    safe_name = formula.replace("/", "_").replace("\\", "_")
    filepath = os.path.join(SAVE_DIR, f"{safe_name}.txt")
    
    if os.path.exists(filepath):
        print(f"Skipping {formula} (File exists)")
        return

    print(f"Requesting: {formula} (rho={density})...")

    payload = {
        # 修正1: ドロップダウンで「手動入力(Enter Formula)」を選んでいるとサーバーに伝える
        "Material": "Enter Formula", 
        
        # 修正2: 化学式は "Formula" に入れる (HTMLの <input name="Formula"> に対応)
        "Formula": formula,
        
        "Density": density,
        "Thickness": THICKNESS,
        "Scan": "Energy",
        "Min": MIN_ENERGY,
        "Max": MAX_ENERGY,
        
        # 修正3: キー名を "Steps" から "Npts" に変更 (HTMLの <input name="Npts"> に対応)
        "Npts": STEPS,
        
        "Plot": "Linear",
        "Output": "Plot"
    }

    try:
        # 計算リクエスト
        r = session.post(action_url, data=payload)
        r.raise_for_status()

        # 結果ページ解析
        soup = BeautifulSoup(r.content, "html.parser")
        data_link = None
        
        # リンク探索
        for a in soup.find_all("a"):
            href = a.get("href", "")
            text = a.get_text().lower()
            # 念のため .dat だけでなく相対パスのデータリンクも探す
            if "data file" in text or href.endswith(".dat") or href.endswith(".txt"):
                data_link = href
                break
        
        if data_link:
            # データダウンロード
            dl_url = urljoin(HENKE_URL, data_link)
            dl_res = session.get(dl_url)
            
            # 保存
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(dl_res.text)
            print(f" -> Saved to {filepath}")
        else:
            # デバッグ用: 失敗した場合、どんなページが返ってきているか確認できるようにする
            print(f" -> Error: No data link found. Check if '{formula}' is valid.")
            # print(soup.get_text()[:200]) # 必要ならコメントアウトを外してエラー内容を確認

    except Exception as e:
        print(f" -> Failed: {e}")

def main():
    csv_path = os.path.join(SAVE_DIR, CSV_FILENAME)
    
    if not os.path.exists(csv_path):
        print(f"CSV file not found: {csv_path}")
        print("Please run the first script (Lebow fetcher) first.")
        return

    session = requests.Session()
    
    # 修正: セッション全体にヘッダーを適用（これで以後の全通信にUser-Agentがつきます）
    session.headers.update(headers) # <--- 追加

    action_url = get_action_url(session)
    
    if not action_url:
        print("Could not determine Henke form action URL.")
        return

    # CSV読み込みと実行
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            formula = row.get("Formula", "").strip()
            density = row.get("Density", "").strip()
            
            if formula and density:
                download_data(session, action_url, formula, density)
                time.sleep(1) # サーバー負荷軽減

    print("All downloads completed.")

if __name__ == "__main__":
    main()
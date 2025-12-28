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
CSV_FILENAME = "additional_targets.csv" # ★今回作成したCSVファイル名を指定
HENKE_URL = "https://henke.lbl.gov/optical_constants/filter2.html"

# デフォルト設定 (CSVにThicknessがない場合用)
DEFAULT_THICKNESS = 1.0 
MIN_ENERGY = 10
MAX_ENERGY = 1000
STEPS = 100 # Npts

headers = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
}

def get_action_url(session):
    r = session.get(HENKE_URL) 
    soup = BeautifulSoup(r.content, "html.parser")
    form = soup.find("form")
    if not form: return None
    return urljoin(HENKE_URL, form.get("action"))

def download_data(session, action_url, formula, density, thickness):
    # ★ファイル名に厚みを含める変更 (例: Au_0.05um.txt)
    safe_name = formula.replace("/", "_").replace("\\", "_")
    filename = f"{safe_name}_{thickness}um.txt"
    filepath = os.path.join(SAVE_DIR, filename)
    
    if os.path.exists(filepath):
        print(f"Skipping {filename} (File exists)")
        return

    print(f"Requesting: {formula} (d={thickness} um)...")

    payload = {
        "Material": "Enter Formula", 
        "Formula": formula,
        "Density": density,
        "Thickness": thickness, # ★CSVから読み込んだ厚みを指定
        "Scan": "Energy",
        "Min": MIN_ENERGY,
        "Max": MAX_ENERGY,
        "Npts": STEPS,
        "Plot": "Linear",
        "Output": "Plot"
    }

    try:
        r = session.post(action_url, data=payload)
        r.raise_for_status()
        soup = BeautifulSoup(r.content, "html.parser")
        data_link = None
        
        for a in soup.find_all("a"):
            href = a.get("href", "")
            text = a.get_text().lower()
            if "data file" in text or href.endswith(".dat") or href.endswith(".txt"):
                data_link = href
                break
        
        if data_link:
            dl_url = urljoin(HENKE_URL, data_link)
            dl_res = session.get(dl_url)
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(dl_res.text)
            print(f" -> Saved to {filepath}")
        else:
            print(f" -> Error: No data link found for {formula}.")

    except Exception as e:
        print(f" -> Failed: {e}")

def main():
    csv_path = os.path.join(SAVE_DIR, CSV_FILENAME)
    
    if not os.path.exists(csv_path):
        print(f"CSV file not found: {csv_path}")
        return

    session = requests.Session()
    session.headers.update(headers)
    action_url = get_action_url(session)
    
    if not action_url:
        print("Could not determine Henke form action URL.")
        return

    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            formula = row.get("Formula", "").strip()
            density = row.get("Density", "").strip()
            # ★CSVから厚みを取得（なければデフォルト値）
            thickness = row.get("Thickness", "").strip()
            if not thickness:
                thickness = DEFAULT_THICKNESS
            
            if formula and density:
                download_data(session, action_url, formula, density, thickness)
                time.sleep(1)

    print("All downloads completed.")

if __name__ == "__main__":
    main()
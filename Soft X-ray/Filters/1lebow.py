import os
import re
import csv
import requests
from bs4 import BeautifulSoup
# データを抽出します
# ==========================================
# 設定
# ==========================================
SAVE_DIR = "/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Filters/"
CSV_FILENAME = "materials.csv"
LEBOW_URL = "https://lebowcompany.com/foils-list"

headers = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
}

def extract_materials():
    """Lebowサイトからマテリアル情報を抽出する"""
    print(f"Fetching from {LEBOW_URL}...")
    try:
        # response = requests.get(LEBOW_URL)
        response = requests.get(LEBOW_URL, headers=headers)
        response.raise_for_status()
    except Exception as e:
        print(f"Error: {e}")
        return []

    soup = BeautifulSoup(response.content, "html.parser")
    materials = []
    
    # 探索対象のブロック
    content_blocks = soup.find_all(['p', 'h3', 'div'])
    seen_formulas = set()

    for block in content_blocks:
        text = block.get_text(" ", strip=True)
        
        # Densityを含む行を探す
        density_match = re.search(r"Density\s*=?\s*([0-9\.]+)", text, re.IGNORECASE)
        
        if density_match:
            density = density_match.group(1)
            formula = ""
            name_candidate = text.split("Density")[0].strip()

            # --- 化学式抽出ロジック ---
            
            # パターンA: 括弧内の化学式 (例: C22N2O4H12)
            paren_match = re.search(r"\(\-?([A-Za-z0-9]+)\-?\)", text)
            
            # パターンB: 明示的な元素記号 (例: ALUMINUM Al ...)
            # 大文字始まりで、数字を含まない、または数字を含む短い単語
            words = name_candidate.split()
            potential_formulas = []
            for w in words:
                clean_w = w.strip(".,()-%")
                # 除外リスト
                if clean_w.upper() in ["ALUMINUM", "OXIDE", "FOIL", "PRICE", "CLASS", "MICRON", "DENSITY", "BERYLLIUM", "CARBON"]:
                    continue
                # 化学式っぽいもの (Al, Al2O3, C8H8など)
                if len(clean_w) > 0 and clean_w[0].isupper():
                    potential_formulas.append(clean_w)

            if paren_match:
                formula = paren_match.group(1)
            elif potential_formulas:
                # 候補の中で、数字を含むものがあればそれを優先(化合物)、なければ一番短いもの(元素)
                best = potential_formulas[0]
                for p in potential_formulas:
                    if any(c.isdigit() for c in p):
                        best = p
                        break
                    if len(p) < len(best):
                        best = p
                formula = best
            
            # クレンジング
            if formula:
                formula = formula.strip("-")
                # 重複チェックと保存
                if formula not in seen_formulas and len(formula) < 20:
                    materials.append([name_candidate[:30], formula, density]) # 名前は長すぎるのでカット
                    seen_formulas.add(formula)

    return materials

def main():
    if not os.path.exists(SAVE_DIR):
        os.makedirs(SAVE_DIR)
        print(f"Created directory: {SAVE_DIR}")

    data = extract_materials()
    
    csv_path = os.path.join(SAVE_DIR, CSV_FILENAME)
    
    with open(csv_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(["Name_Snippet", "Formula", "Density"]) # Header
        writer.writerows(data)
        
    print(f"Saved {len(data)} materials to {csv_path}")
    print("Please check the CSV file and correct any Formula errors before running the next script.")

if __name__ == "__main__":
    main()
import sys
import os

# 1. パス設定
sys.path.append('/usr/local/mdsplus/python')
os.environ['DYLD_LIBRARY_PATH'] = '/usr/local/mdsplus/lib:' + os.environ.get('DYLD_LIBRARY_PATH', '')

# 2. Numpyを先にインポート
import numpy as np

# --- 【最強版パッチ】MDSplusを騙すための偽装工作 ---
if not hasattr(np, 'string_'): np.string_ = np.bytes_
if not hasattr(np, 'unicode_'): np.unicode_ = np.str_
if not hasattr(np, 'str'): np.str = str
if not hasattr(np, 'bool'): np.bool = bool
if not hasattr(np, 'int'): np.int = int
if not hasattr(np, 'float'): np.float = float
if not hasattr(np, 'complex'): np.complex = complex
if not hasattr(np, 'object'): np.object = object
if not hasattr(np, 'long'): np.long = int
# --------------------------------------------------

import MDSplus 
import scipy.io

# --- 設定 ---
MDS_SERVER = '192.168.1.140'
# MDS_SERVER = 'localhost:8000'
POST_SAMPLES = 1000

def fetch_channels_batch(conn, ch_num, post_samples):
    """
    全チャンネルを1回の通信で取得し、Numpy配列として整形して返す関数
    戻り値: (samples, channels) の形状の配列
    """
    # TDI式を構築: "[.AI:CH001, .AI:CH002, ...]" という文字列を作る
    node_list = [f".AI:CH{i:03d}" for i in range(1, ch_num + 1)]
    tdi_expression = f"[{','.join(node_list)}]"
    
    try:
        # 1回の通信でドカンと取得
        # MDSplusは通常 (channels, time) の形状で返してくることが多い
        data_all = conn.get(tdi_expression).data()
        data_all = np.array(data_all) # Numpy配列化
        
        # 形状チェックと修正
        # (CH数, サンプル数) になっているはずなので、転置して (サンプル数, CH数) に合わせる
        if data_all.shape[0] == ch_num:
            data_all = data_all.T
            
        # サンプル数でカット
        if data_all.shape[0] > post_samples:
            data_all = data_all[:post_samples, :]
        elif data_all.shape[0] < post_samples:
            # 足りない場合はゼロ埋め（元のロジックに準拠）
            pad_width = post_samples - data_all.shape[0]
            data_all = np.vstack([data_all, np.zeros((pad_width, ch_num))])
            
        return data_all

    except Exception as e:
        print(f"Batch fetch failed: {e}")
        # バッチ取得に失敗した場合（一部のノードが存在しない等）、安全のためここだけループで取るかエラーにする
        # 今回はエラーを表示してNoneを返す
        return None

def get_mds_data(dtacq_num, shot, tfshot):
    if dtacq_num == 38:
        ch_num = 128
    else:
        ch_num = 192

    tree_name = f"a{dtacq_num:03d}"
    
    # 結果格納用配列（初期化）
    rawdata_wTF = np.zeros((POST_SAMPLES, ch_num))
    
    try:
        conn = MDSplus.Connection(MDS_SERVER)
        print(f"Opening tree {tree_name}, shot {shot} (Batch Mode)...")
        conn.openTree(tree_name, shot)
        
        # --- 1. 本データの取得 (Batch) ---
        data_shot = fetch_channels_batch(conn, ch_num, POST_SAMPLES)
        
        if data_shot is None:
            print("Failed to fetch shot data.")
            return None, None
            
        # オフセット引き算 (data - data[0])
        # data_shot[0, :] は (channels,) の形状なのでブロードキャスト可能
        rawdata_wTF = data_shot - data_shot[0, :]

        # --- 2. TFショットの取得と引き算 ---
        rawdata_woTF = rawdata_wTF.copy()
        
        if tfshot > 0:
            print(f"Opening tree {tree_name}, tfshot {tfshot} for subtraction (Batch Mode)...")
            conn.openTree(tree_name, tfshot)
            
            data_tf = fetch_channels_batch(conn, ch_num, POST_SAMPLES)
            
            if data_tf is not None:
                # TFデータのオフセット引き算
                data_tf_corrected = data_tf - data_tf[0, :]
                # 引き算実行
                rawdata_woTF = rawdata_wTF - data_tf_corrected
            else:
                print("Warning: TF shot fetch failed. Proceeding without subtraction.")
            
        return rawdata_wTF, rawdata_woTF
    except Exception as e:
        # 標準エラー出力に書き出す（MATLABがキャッチしやすい）
        sys.stderr.write(f"Error in Python Script (Shot: {shot}):\n")
        traceback.print_exc(file=sys.stderr) 
        return None, None

    except Exception as e:
        print(f"MDSplus Connection/Tree Error: {e}")
        import traceback
        traceback.print_exc()
        return None, None

def save_dtacq_data(dtacq_num, shot, tfshot, save_filepath):
    save_dir = os.path.dirname(save_filepath)
    if save_dir and not os.path.exists(save_dir):
        os.makedirs(save_dir, exist_ok=True)
    
    temp_filepath = save_filepath + ".tmp"

    rawdata_wTF, rawdata_woTF = get_mds_data(dtacq_num, shot, tfshot)
    
    if rawdata_wTF is not None:
        mat_dict = {
            'rawdata_wTF': rawdata_wTF,
            'rawdata_woTF': rawdata_woTF
        }
        # 【変更点】まずは一時ファイルに保存
        scipy.io.savemat(temp_filepath, mat_dict)
        
        # 【変更点】保存完了後にリネーム (アトミック操作)
        os.rename(temp_filepath, save_filepath)
        
        print(f"Successfully saved to: {save_filepath}")
        return True
    else:
        print("Failed to acquire data.")
        return False

if __name__ == "__main__":
    if len(sys.argv) >= 5:
        dtacq_arg = int(sys.argv[1])
        shot_arg = int(sys.argv[2])
        tfshot_arg = int(sys.argv[3])
        path_arg = sys.argv[4]
        
        success = save_dtacq_data(dtacq_arg, shot_arg, tfshot_arg, path_arg)
        if not success:
            sys.exit(1)
    else:
        print("Usage: python get_mds_data.py [dtacq] [shot] [tfshot] [filepath]")
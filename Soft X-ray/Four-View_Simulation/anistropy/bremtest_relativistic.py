import numpy as np
import matplotlib.pyplot as plt
from matplotlib.widgets import Slider

# --- 物理定数 ---
m_e_eV = 510998.95
Z_Ar = 1.0 
PI = np.pi

# --- ユーザー定義の形状因子 (KW近似など) ---
# x = h_nu / E_kin
# xが1に近い（ハード）ほど P->1 (Dipole成分強い)
# xが0に近い（ソフト）ほど P->0 (等方的) ※元のコードの挙動準拠
def get_polarization_KW(x):
    if x < 0: return 0.0
    if x > 1: return 1.0
    return x * (1.35 - 0.35 * x)

# --- グローバル変数 ---
theta_rad = np.linspace(0, 2*np.pi, 360) 

def compute_low_energy_bremsstrahlung(v_para_eV, v_perp_eV, photon_eV):
    """
    低エネルギー(数100eV)向け：
    Photon比による形状変化 + ジャイロ平均 + 物理的強度スケーリング
    """
    # 1. 運動学 (Kinematics)
    E_kin = v_para_eV + v_perp_eV
    
    # エネルギー不足ならゼロ
    if photon_eV >= E_kin:
        # pitch_angle計算のためだけにbeta計算
        gamma = 1.0 + E_kin / m_e_eV
        beta = np.sqrt(1.0 - 1.0/gamma**2)
        # 簡易的にエネルギー比でピッチ角算出
        pitch_angle = np.arctan2(np.sqrt(v_perp_eV), np.sqrt(v_para_eV))
        return np.zeros_like(theta_rad), 0.0, E_kin, pitch_angle

    # 速度ベクトルの大きさ（強度計算用）
    gamma = 1.0 + E_kin / m_e_eV
    beta = np.sqrt(1.0 - 1.0/gamma**2)
    if beta < 1e-5: beta = 1e-5

    # ピッチ角 (tan theta = v_perp / v_para -> sqrt(E_perp)/sqrt(E_para))
    pitch_angle = np.arctan2(np.sqrt(v_perp_eV), np.sqrt(v_para_eV))

    # 2. 物理的強度係数 (Absolute Intensity Factor)
    # 断面積 sigma ~ (Z^2 / beta^2) * (1/hv) * log(...)
    # ここでは "単位立体角あたりの強度分布" なので、beta^-2 の依存性が支配的
    nu_ratio = photon_eV / E_kin
    if nu_ratio < 1e-4: nu_ratio = 1e-4
    
    # ガウント係数（対数項）
    g_ff = (np.sqrt(3)/PI) * np.log(4.0/nu_ratio)
    if g_ff < 1.0: g_ff = 1.0
    
    # 絶対強度スケール: 低速ほど相互作用時間が長く、発光確率が高い(1/beta^2)
    intensity_scale = (Z_Ar**2 / (beta**2)) * g_ff

    # 3. 形状因子 (Polarization / Anisotropy)
    P = get_polarization_KW(nu_ratio)
    
    # 4. ジャイロ平均 (Gyro-averaging)
    averaged_intensities = []
    gyro_phases = np.linspace(0, 2*np.pi, 36)
    
    for th_obs in theta_rad:
        n_obs = np.array([np.sin(th_obs), 0, np.cos(th_obs)])
        
        sum_I = 0.0
        for phi_g in gyro_phases:
            # 瞬間の電子進行方向 v_dir
            v_dir = np.array([
                np.sin(pitch_angle) * np.cos(phi_g),
                np.sin(pitch_angle) * np.sin(phi_g),
                np.cos(pitch_angle)
            ])
            
            # cos_psi: 観測方向と「瞬間の速度」のなす角
            cos_psi = np.dot(n_obs, v_dir)
            
            # 元コードのロジック:
            # Dipole成分(sin^2) と 等方成分(1.0) を P で混ぜる
            # 低エネルギーなので相対論的ビーミング(分母の4乗や5乗)はほぼ1だが、
            # 元コードにあったので念のため残す（低速なら影響小）
            beaming = 1.0 / (1.0 - beta * cos_psi)**2 
            
            sin2 = 1.0 - cos_psi**2
            shape = P * sin2 + (1.0 - P) * 1.0
            
            sum_I += shape * beaming
            
        # 平均化 * 絶対強度
        averaged_intensities.append((sum_I / len(gyro_phases)) * intensity_scale)

    return np.array(averaged_intensities), intensity_scale, E_kin, pitch_angle

# --- メイン描画 ---
# 低エネルギー設定 (400eV以下)
init_v_para = 300.0 # eV
init_v_perp = 50.0  # eV
init_photon = 200.0 # eV

fig = plt.figure(figsize=(10, 8))
ax = plt.subplot(111, projection='polar')
plt.subplots_adjust(bottom=0.25)

# 初期計算
I_dist, I_val, E_k, p_angle = compute_low_energy_bremsstrahlung(init_v_para, init_v_perp, init_photon)

line, = ax.plot(theta_rad, I_dist, color='crimson', linewidth=2.5, label='Radiation Pattern')

# ガイドライン
ax.annotate('', xy=(0, 0), xytext=(0, 1.0),
            arrowprops=dict(facecolor='blue', shrink=0.05, width=4, headwidth=10),
            xycoords='data', textcoords='data')
ax.text(0, 1.1, "B-field (z)", ha='center', color='blue', fontweight='bold')

# コーン (Pitch Angle)
cone_lines_r = [0, 1]
line_cone_R, = ax.plot([p_angle, p_angle], cone_lines_r, color='blue', linestyle='--', alpha=0.5)
line_cone_L, = ax.plot([-p_angle, -p_angle], cone_lines_r, color='blue', linestyle='--', alpha=0.5)
cone_label = ax.text(p_angle, 0, f"Pitch: {np.degrees(p_angle):.1f}°", color='blue')

# 設定
ax.set_theta_zero_location("N")
ax.set_theta_direction(-1)
ax.set_title(f"Low-Energy Bremsstrahlung (User Model)\nPhoton/Energy Ratio controls Shape", pad=20)

# スライダー (400eV付近が見やすい範囲に設定)
axcolor = '#f0f0f0'
ax_para = plt.axes([0.2, 0.15, 0.6, 0.03], facecolor=axcolor)
ax_perp = plt.axes([0.2, 0.10, 0.6, 0.03], facecolor=axcolor)
ax_phot = plt.axes([0.2, 0.05, 0.6, 0.03], facecolor=axcolor)

s_para = Slider(ax_para, 'K_para (eV)', 10.0, 500.0, valinit=init_v_para)
s_perp = Slider(ax_perp, 'K_perp (eV)', 0.0, 500.0, valinit=init_v_perp)
s_phot = Slider(ax_phot, 'Photon (eV)', 10.0, 450.0, valinit=init_photon)

def update(val):
    vp = s_para.val
    vt = s_perp.val
    ph = s_phot.val
    
    new_I, new_scale, new_Ek, new_pitch = compute_low_energy_bremsstrahlung(vp, vt, ph)
    
    # 描画更新
    line.set_ydata(new_I)
    
    # スケール調整: 絶対強度が大きく変わるため動的に最大値を追う
    rmax = np.max(new_I) if np.max(new_I) > 0 else 1.0
    ax.set_ylim(0, rmax * 1.1)
    
    # コーン更新
    line_cone_R.set_data([new_pitch, new_pitch], [0, rmax*1.1])
    line_cone_L.set_data([-new_pitch, -new_pitch], [0, rmax*1.1])
    cone_label.set_position((new_pitch, rmax*1.15))
    cone_label.set_text(f"Pitch: {np.degrees(new_pitch):.1f}°")
    
    # タイトル情報更新 (Photon比率を表示)
    ratio = ph / new_Ek if new_Ek > 0 else 0
    P_val = get_polarization_KW(ratio)
    ax.set_title(f"E_elec: {new_Ek:.1f} eV | Photon: {ph:.1f} eV (Ratio: {ratio:.2f})\nShape Factor P: {P_val:.2f} (0=Iso, 1=Dipole)", pad=20)
    
    fig.canvas.draw_idle()

s_para.on_changed(update)
s_perp.on_changed(update)
s_phot.on_changed(update)

plt.show()
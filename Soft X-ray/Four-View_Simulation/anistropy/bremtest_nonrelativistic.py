import numpy as np
import matplotlib.pyplot as plt
from matplotlib.widgets import Slider

# --- 物理定数 (SI単位) ---
h_bar = 1.0545718e-34  # [J s]
m_e   = 9.10938356e-31 # [kg]
e_c   = 1.60217663e-19 # [C]
eps0  = 8.8541878e-12  # [F/m]
c     = 2.9979e8       # [m/s]
eV2J  = 1.60217663e-19 # eV -> J conversion

# --- グローバル変数 ---
theta_rad = np.linspace(0, 2*np.pi, 360) 

def compute_low_energy_bremsstrahlung(v_para_eV, v_perp_eV, photon_eV):
    """
    MATLABモデルに基づく計算ロジック:
    1. インパクトパラメータ (b_max, b_min) によるガント係数の計算
    2. 角度分布 (1 + cos^2(theta)) のジャイロ平均
    """
    # --- Electron Kinematics ---
    E_kin_eV = v_para_eV + v_perp_eV
    
    # エネルギー保存則チェック
    if photon_eV >= E_kin_eV:
        # エネルギー不足の場合はゼロを返す
        pitch_angle = np.arctan2(np.sqrt(v_perp_eV), np.sqrt(v_para_eV))
        return np.zeros_like(theta_rad), 0.0, E_kin_eV, pitch_angle

    E_kin_J = E_kin_eV * eV2J
    
    # 速度 v の計算
    mc2_J = m_e * (c)**2
    gamma = 1.0 + E_kin_J / mc2_J
    beta  = np.sqrt(1.0 - 1.0/gamma**2)
    if beta < 1e-5: beta = 1e-5
    
    v_electron = beta * c
    
    # Pitch Angle
    pitch_angle = np.arctan2(np.sqrt(v_perp_eV), np.sqrt(v_para_eV))
    
    # --- Intensity Calculation (Impact Parameter Model) ---
    hv_J = photon_eV * eV2J
    
    # 1. 角振動数 omega
    omega = hv_J / h_bar
    
    # 2. b_max (Adiabatic Limit)
    b_max = v_electron / omega
    
    # 3. b_min (Closest Approach)
    # 量子限界
    b_qm = h_bar / (m_e * v_electron)
    
    # 古典限界 (Z=1)
    Z = 1.0
    b_cl = (Z * e_c**2) / (4 * np.pi * eps0 * m_e * v_electron**2)
    
    # 大きい方を採用
    b_min = max(b_qm, b_cl)
    
    # 4. ガント係数 g_ff
    lambda_b = b_max / b_min
    if lambda_b < 1.0: lambda_b = 1.0
    
    g_ff = (np.sqrt(3)/np.pi) * np.log(lambda_b)
    
    # MATLABと同様の強度スケール
    # I ~ (1/v) * g_ff * (1/hv)
    I_scale = (1.0 / v_electron) * g_ff * (1.0 / photon_eV)
    
    # --- Angular Distribution (1 + cos^2 theta) ---
    averaged_intensities = []
    gyro_phases = np.linspace(0, 2*np.pi, 36)
    
    # 観測方向ごとのループ
    for th_obs in theta_rad:
        n_obs = np.array([np.sin(th_obs), 0, np.cos(th_obs)])
        
        sum_sigma = 0.0
        for phi in gyro_phases:
            # 1. 電子の速度ベクトル (v_hat)
            v_hat = np.array([
                np.sin(pitch_angle) * np.cos(phi),
                np.sin(pitch_angle) * np.sin(phi),
                np.cos(pitch_angle)
            ])
            
            # 2. 観測方向との内積 (cos_Theta)
            v_dot_n = np.dot(v_hat, n_obs)
            
            # 3. MATLABの式: 1 + (v . n)^2
            # 物理的意味: 電子の速度方向と観測方向が平行に近いほど強くなる成分が含まれる
            current_sigma = 1.0 + v_dot_n**2
            
            sum_sigma += current_sigma
            
        avg_shape = sum_sigma / len(gyro_phases)
        averaged_intensities.append(avg_shape * I_scale)

    return np.array(averaged_intensities), I_scale, E_kin_eV, pitch_angle

# --- メイン描画 ---
# 初期設定
init_v_para = 300.0 # eV
init_v_perp = 50.0  # eV
init_photon = 200.0 # eV

fig = plt.figure(figsize=(10, 8))
ax = plt.subplot(111, projection='polar')
plt.subplots_adjust(bottom=0.25)

# 初期計算
I_dist, I_val, E_k, p_angle = compute_low_energy_bremsstrahlung(init_v_para, init_v_perp, init_photon)

# プロット
line, = ax.plot(theta_rad, I_dist, color='crimson', linewidth=2.5, label='Radiation Pattern')

# ガイドライン (磁場方向)
ax.annotate('', xy=(0, 0), xytext=(0, 1.0),
            arrowprops=dict(facecolor='blue', shrink=0.05, width=4, headwidth=10),
            xycoords='data', textcoords='data')
ax.text(0, 1.1, "B-field (z)", ha='center', color='blue', fontweight='bold')

# ピッチ角のコーン表示
cone_lines_r = [0, 1]
line_cone_R, = ax.plot([p_angle, p_angle], cone_lines_r, color='blue', linestyle='--', alpha=0.5)
line_cone_L, = ax.plot([-p_angle, -p_angle], cone_lines_r, color='blue', linestyle='--', alpha=0.5)
cone_label = ax.text(p_angle, 0, f"Pitch: {np.degrees(p_angle):.1f}°", color='blue')

# 設定
ax.set_theta_zero_location("N")
ax.set_theta_direction(-1)
ax.set_title(f"Bremsstrahlung Model (Impact Parameter Method)\nShape ~ 1 + (v.n)^2", pad=20)

# スライダー
axcolor = '#f0f0f0'
ax_para = plt.axes([0.2, 0.15, 0.6, 0.03], facecolor=axcolor)
ax_perp = plt.axes([0.2, 0.10, 0.6, 0.03], facecolor=axcolor)
ax_phot = plt.axes([0.2, 0.05, 0.6, 0.03], facecolor=axcolor)

s_para = Slider(ax_para, 'K_para (eV)', 10.0, 1000.0, valinit=init_v_para)
s_perp = Slider(ax_perp, 'K_perp (eV)', 0.0, 1000.0, valinit=init_v_perp)
s_phot = Slider(ax_phot, 'Photon (eV)', 10.0, 1000.0, valinit=init_photon)

def update(val):
    vp = s_para.val
    vt = s_perp.val
    ph = s_phot.val
    
    new_I, new_scale, new_Ek, new_pitch = compute_low_energy_bremsstrahlung(vp, vt, ph)
    
    # 描画更新
    line.set_ydata(new_I)
    
    # スケール調整
    rmax = np.max(new_I) if np.max(new_I) > 0 else 1.0
    ax.set_ylim(0, rmax * 1.1)
    
    # コーン更新
    line_cone_R.set_data([new_pitch, new_pitch], [0, rmax*1.1])
    line_cone_L.set_data([-new_pitch, -new_pitch], [0, rmax*1.1])
    cone_label.set_position((new_pitch, rmax*1.15))
    cone_label.set_text(f"Pitch: {np.degrees(new_pitch):.1f}°")
    
    # タイトル情報更新
    ratio = ph / new_Ek if new_Ek > 0 else 0
    ax.set_title(f"E_elec: {new_Ek:.1f} eV | Photon: {ph:.1f} eV\nImpact Parameter Model (MATLAB Logic)", pad=20)
    
    fig.canvas.draw_idle()

s_para.on_changed(update)
s_perp.on_changed(update)
s_phot.on_changed(update)

plt.show()
import numpy as np
import matplotlib.pyplot as plt
from scipy.integrate import quad

# 定数
c = 2.99792458e8

def sommerfeld_intensity_instant(theta_inst, beta):
    """
    ゾンマーフェルトの式 (Eq. 109): 瞬間強度は sin^2(Theta) / (1 - beta*cos(Theta))^4
    """
    denom = (1 - beta * np.cos(theta_inst))**4
    return (np.sin(theta_inst)**2) / denom

def calculate_averaged_distribution(theta_obs_array, v_para, v_perp):
    """
    回転平均後の強度分布を計算
    """
    v_total = np.sqrt(v_para**2 + v_perp**2)
    beta = v_total / c
    
    if v_total == 0:
        return np.zeros_like(theta_obs_array), 0, 0

    if v_para == 0:
        alpha = np.pi/2
    else:
        alpha = np.arctan2(v_perp, v_para)
        
    intensities = []
    
    for th_obs in theta_obs_array:
        def integrand(phi):
            # 球面三角法で瞬間の角度 Theta を計算
            cos_theta_inst = np.cos(th_obs) * np.cos(alpha) + \
                             np.sin(th_obs) * np.sin(alpha) * np.cos(phi)
            cos_theta_inst = np.clip(cos_theta_inst, -1.0, 1.0)
            theta_inst = np.arccos(cos_theta_inst)
            return sommerfeld_intensity_instant(theta_inst, beta)
        
        # 0~2pi で積分して平均化
        avg_int, error = quad(integrand, 0, 2*np.pi)
        intensities.append(avg_int / (2*np.pi))
        
    return np.array(intensities), beta, np.degrees(alpha)

# --- プロット作成 ---
theta_obs_deg = np.linspace(0, 360, 360)
theta_obs_rad = np.radians(theta_obs_deg)

fig, axes = plt.subplots(1, 2, subplot_kw={'projection': 'polar'}, figsize=(14, 7))

# グラフ1: v_perp 固定, v_para を変化させる
ax1 = axes[0]
fixed_vt = 0.2 * c
v_para_list = [0.0, 0.05, 0.1, 0.15, 0.2] # cの倍数

for vp_factor in v_para_list:
    vp = vp_factor * c
    I_avg, beta, alpha = calculate_averaged_distribution(theta_obs_rad, vp, fixed_vt)
    
    # 形状比較のため最大値で規格化
    if np.max(I_avg) > 0:
        I_norm = I_avg / np.max(I_avg)
    else:
        I_norm = I_avg
    
    ax1.plot(theta_obs_rad, I_norm, linewidth=2, label=f'$v_{{\\parallel}}={vp_factor:.1f}c$')

ax1.set_theta_zero_location("N") # 上を磁場方向(0度)に
ax1.set_theta_direction(-1)      # 時計回り
ax1.set_title(f"Effect of $v_{{\\parallel}}$ (Fixed $v_{{\\perp}} = {fixed_vt/c:.1f}c$)\nBeam Focuses Forward", va='bottom', pad=20)
ax1.legend(loc='lower center', bbox_to_anchor=(0.5, -0.3))

# グラフ2: v_para 固定, v_perp を変化させる
ax2 = axes[1]
fixed_vp = 0.4 * c
v_perp_list = v_para_list # cの倍数

for vt_factor in v_perp_list:
    vt = vt_factor * c
    I_avg, beta, alpha = calculate_averaged_distribution(theta_obs_rad, fixed_vp, vt)
    
    if np.max(I_avg) > 0:
        I_norm = I_avg / np.max(I_avg)
    else:
        I_norm = I_avg
        
    ax2.plot(theta_obs_rad, I_norm, linewidth=2, label=f'$v_{{\\perp}}={vt_factor:.1f}c$')

ax2.set_theta_zero_location("N")
ax2.set_theta_direction(-1)
ax2.set_title(f"Effect of $v_{{\\perp}}$ (Fixed $v_{{\\parallel}} = {fixed_vp/c:.1f}c$)\nCone Opens Up", va='bottom', pad=20)
ax2.legend(loc='lower center', bbox_to_anchor=(0.5, -0.3))

plt.tight_layout()
plt.show()
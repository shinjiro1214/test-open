import numpy as np
import matplotlib.pyplot as plt

# 物理定数
c = 2.99792458e8  # 光速 [m/s]
h = 6.62607015e-34 # プランク定数 [J s]
m_e = 9.10938356e-31 # 電子質量 [kg]
e_charge = 1.60217663e-19 # 素電荷 [C]

def calculate_beta(v_para, v_perp):
    """
    平行速度と垂直速度から全速度のベータ値(v/c)を計算する
    """
    v_total = np.sqrt(v_para**2 + v_perp**2)
    beta = v_total / c
    return beta, v_total

def sommerfeld_angular_distribution(theta, beta):
    """
    ゾンマーフェルト論文 式(109)  に基づく強度角度分布
    Intensity ~ A^2 ~ sin^2(theta) / (1 - beta * cos(theta))^4
    
    Parameters:
    theta : 放射角度 (電子の進行方向を0とする) [rad]
    beta  : v/c
    """
    # 分母が0になるのを防ぐための微小項はここではbeta < 1なので不要
    numerator = np.sin(theta)**2
    denominator = (1 - beta * np.cos(theta))**4
    return numerator / denominator

def sommerfeld_spectrum_shape(nu_ratio, Z, beta):
    """
    ゾンマーフェルト論文 式(99b)  に基づくスペクトル形状
    
    Parameters:
    nu_ratio : nu / nu_g (限界振動数との比, 0 < nu_ratio <= 1)
    Z        : 原子番号 (ターゲットとなる原子核)
    beta     : 入射電子の速度 v1/c
    """
    # 論文中の定義: |n1| ~ Z / (137 * beta) 近似 (a_Hなど原子単位系換算)
    # n1 = Z / (i * k1 * a) -> |n1| = Z * alpha_fine / beta
    # ここでは定性的な形状を示すため、簡易的な係数を使用します。
    
    fine_structure = 1/137.0
    abs_n1 = Z * fine_structure / beta
    
    # 電子の衝突後の速度 beta2 はエネルギー保存則から概算
    # h*nu = E1 - E2 => E2 = E1 - h*nu
    # 非相対論的近似の範囲で v2/v1 = sqrt(1 - nu/nu_g)
    # n2 = |n1| * (v1/v2) = |n1| / sqrt(1 - nu_ratio)
    
    # nu_ratioが1に近い場合(短波長限界)、n2は無限大になるが
    # 式(87b) [cite: 3198] により有限値に収束する項がある。
    # ここでは nu_ratio < 1 の領域を計算
    
    spectrum = []
    for r in nu_ratio:
        if r >= 1.0:
            # 限界振動数での値 (式87b [cite: 3198])
            # intensity ~ n1^4 / (exp(2*pi*n1) - 1) * ... (有限値)
            # ここでは連続性のために近似値を入れます
            val = 1.0 # 規格化のため仮置き
        else:
            v2_v1_ratio = np.sqrt(1 - r)
            if v2_v1_ratio == 0:
                abs_n2 = 1e5 # Avoid infinity
            else:
                abs_n2 = abs_n1 / v2_v1_ratio
            
            # 式(99b)  の主要項
            # 分母: 1 - exp(-2*pi*|n2|)
            # 対数項: log((k1+k2)/(k1-k2)) = log((1 + v2/v1)/(1 - v2/v1))
            
            denom = 1 - np.exp(-2 * np.pi * abs_n2)
            log_term = np.log((1 + v2_v1_ratio) / (1 - v2_v1_ratio))
            
            # 強度 I_nu
            val = (1 / denom) * log_term
            
        spectrum.append(val)
    
    return np.array(spectrum)

# --- パラメータ設定 ---
# 磁力線に巻きつく電子の速度を想定 (ここではかなり高速な電子を仮定)
# 光速の何割か (例: 0.5c)
v_para_example = 0.2 * c
v_perp_example = 0.2 * c
Z_target = 13 # アルミニウム(Al)を想定 (論文中のKulenkampffの実験と比較しているため)

# 計算
beta_val, v_tot = calculate_beta(v_para_example, v_perp_example)
theta_range = np.linspace(0, 2*np.pi, 360)
intensity_angular = sommerfeld_angular_distribution(theta_range, beta_val)

# スペクトル計算 (nu/nu_g = 0.1 ~ 0.99)
nu_ratios = np.linspace(0.01, 0.99, 100)
intensity_spectrum = sommerfeld_spectrum_shape(nu_ratios, Z_target, beta_val)

# --- プロット作成 ---
fig = plt.figure(figsize=(12, 5))

# 1. 角度分布 (Polar Plot)
ax1 = fig.add_subplot(121, projection='polar')
ax1.plot(theta_range, intensity_angular, color='blue', linewidth=2, label=f'$\\beta={beta_val:.2f}$')
ax1.set_title(f'Bremsstrahlung Angular Distribution\n(Sommerfeld 1931, Eq. 109)', pad=20)
ax1.set_theta_zero_location("E") # 0度を右(進行方向)に
ax1.set_xlabel(f'Direction of instantaneous velocity vector\n($v_{{\parallel}}$ and $v_{{\\perp}}$ composite)', labelpad=10)
# Voreilung (Forward Peaking) の確認
# 理論上の最大角 cos(Theta_max) ~ 2*beta (式108a )
max_angle_idx = np.argmax(intensity_angular)
max_angle_deg = np.degrees(theta_range[max_angle_idx])
if max_angle_deg > 180: max_angle_deg -= 360
ax1.text(np.radians(45), np.max(intensity_angular)*0.8, f'Peak Angle $\\approx {abs(max_angle_deg):.1f}^\\circ$', color='red')

# 2. エネルギースペクトル (Intensity vs Frequency)
ax2 = fig.add_subplot(122)
ax2.plot(nu_ratios, intensity_spectrum, color='green', linewidth=2)
ax2.set_title(f'Intensity Spectrum Shape\n(Sommerfeld 1931, Eq. 99b)', pad=20)
ax2.set_xlabel('Frequency Ratio ($\\nu / \\nu_{limit}$)')
ax2.set_ylabel('Relative Intensity $I_\\nu$')
ax2.grid(True, which='both', linestyle='--')
ax2.text(0.5, np.max(intensity_spectrum)*0.5, 'Flat characteristic near limit\n(See Fig.7 in paper )', fontsize=10)

plt.tight_layout()
plt.show()

print(f"--- Calculation Parameters ---")
print(f"Parallel Velocity (v_para): {v_para_example/c:.2f} c")
print(f"Perpendicular Velocity (v_perp): {v_perp_example/c:.2f} c")
print(f"Total Beta (v/c): {beta_val:.4f}")
print(f"Atomic Number Z: {Z_target}")
print(f"\n--- Theoretical Notes from Sommerfeld (1931) ---")
print(f"1. Angular Distribution: Derived from Retarded Potentials (Eq. 109).")
print(f"   Strong forward peaking (Voreilung) is observed as Beta increases.")
print(f"2. Spectrum: Derived from Matrix Elements (Eq. 99b).")
print(f"   Intensity is non-zero at the short-wave limit (nu = nu_g) and increases towards lower frequencies.")
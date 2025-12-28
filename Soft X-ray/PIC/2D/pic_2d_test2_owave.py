import numpy as np
import matplotlib.pyplot as plt
import time
import os
from numba import jit
from scipy.interpolate import RegularGridInterpolator
from scipy.fft import dst, idst, fftfreq, fft2, ifft2

print("🚀 Initializing Wave Test PIC Simulation - Ver. 1.0")

# ==============================================================================
# --- 1. 物理・シミュレーション設定 (波動テスト用に変更) ---
# ==============================================================================
MI_ME = 1000  # イオンの質量を電子と同じにし、純粋な電子の応答をみる
WPE_WCE = 6.0 # PDFのTable 3.4を参考
T_el_norm = (0.1 * 1.0)**2 # v_th/c = 0.01 より T_el = (v_th * c)^2 / (k_B=1)
NX, NZ = 33, 257 # PDFのTable 3.4 を参考に (LJ, LI) -> (NX, NZ)
LX_de, LZ_de = 32.0 * 1.2, 256.0 * 1.2 # PDFのTable 3.4 の Δ/λ_De=1.2 を参考にグリッドサイズを計算
N_PTCL_PER_CELL = 0 # PDFのTable 3.4 を参考
T_MAX_wce = 50.0 # シミュレーション時間 (w_ce^-1 単位)
PLOT_INTERVAL_wce = 0.1 # プロット間隔 (w_ce^-1 単位)
NUM_SMOOTHING_PASSES = 2 # スムージング回数

# ==============================================================================
# --- 2. パラメータ導出と配列準備 ---
# ==============================================================================
c = 1.0
m_e = 1.0
q_e = -1.0
n0 = 1.0
m_i = m_e * MI_ME
q_i = -q_e

w_pe = np.sqrt(n0 / m_e)
w_ce = w_pe / WPE_WCE
v_the = np.sqrt(T_el_norm / m_e) # ここでは T_el_norm が (v_th/c)^2 に相当
v_thi = v_the / np.sqrt(MI_ME)
d_e = c / w_pe
LX, LZ = LX_de * d_e, LZ_de * d_e
dx, dz = LX / (NX - 1), LZ / (NZ - 1)

# 時間ステップはw_pe基準で計算・実行する
dt = 0.05 / (c * np.sqrt(1 / dx**2 + 1 / dz**2))
N_STEPS = int(T_MAX_wce / (dt * w_ce)) 
PLOT_STEPS = int(PLOT_INTERVAL_wce / (dt * w_ce)) if PLOT_INTERVAL_wce > 0 else N_STEPS + 1

print(f"Grid: {NX}x{NZ}, dt*w_ce: {dt*w_ce:.4f}, Total Steps: {N_STEPS}")

output_dir = "data_wave_test_mime1000_ddm3"
os.makedirs(output_dir, exist_ok=True)

E = np.zeros((NX, NZ, 3))
B = np.zeros((NX, NZ, 3))
J_plasma = np.zeros((NX, NZ, 3))
J_ext = np.zeros((NX, NZ, 3))
rho = np.zeros((NX, NZ))
Ay = np.zeros((NX, NZ)) # O-modeではAyは使わないが、関数インターフェースのために残す

x_vec = np.linspace(-LX / 2, LX / 2, NX)
z_vec = np.linspace(0, LZ, NZ)
x_grid, z_grid = np.meshgrid(x_vec, z_vec, indexing='ij')

x_vec_de = x_vec / d_e
z_vec_de = z_vec / d_e
x_grid_norm, z_grid_norm = np.meshgrid(x_vec_de, z_vec_de, indexing='ij')


# ==============================================================================
# --- 3. 初期条件：O-Mode 平面波 (スフェロマックから変更) ---
# ==============================================================================
print("Setting up initial condition: O-Mode wave (Corrected)...")

# 波のパラメータ設定
lambda_z = LZ / 4.0
k_z = 2.0 * np.pi / lambda_z
E0 = 0.05

# --- 修正点 1: プラズマ中の分散関係から磁場振幅を計算 ---
# 真空中では B = E/c ですが、プラズマ中では位相速度 v_ph = omega/k を使う必要があります。
# O-modeの分散関係: omega^2 = w_pe^2 + c^2*k^2
omega_sq = w_pe**2 + (c * k_z)**2
omega = np.sqrt(omega_sq)

if k_z > 0:
    v_ph = omega / k_z
    B0 = E0 / v_ph
else:
    B0 = 0 # k=0 の場合は静電場なので磁場は0

print(f"Wave params: k_z={k_z:.3f}, omega/w_pe={omega/w_pe:.3f}, v_ph/c={v_ph/c:.3f}")

# --- 修正点 2: EとBの位相を揃え、進行波を生成 ---
# E_x と B_y を同位相にすることで、一方向に進む波を励起します。
E[:, :, 0] = E0 * np.cos(k_z * z_grid)
B[:, :, 1] = B0 * np.cos(k_z * z_grid)

# ==============================================================================
# --- 粒子初期化 (波動テスト用に変更) ---
# ==============================================================================
N_total = N_PTCL_PER_CELL * (NX - 1) * (NZ - 1)
N_e = N_total // 2
N_i = N_total - N_e
pos = np.zeros((N_total, 2))
vel = np.zeros((N_total, 3))
charge = np.zeros(N_total)
mass = np.zeros(N_total)
is_active = np.ones(N_total, dtype=np.bool_)

if N_total > 0:
    # 粒子を均一に配置
    pos[:, 0] = np.random.uniform(-LX / 2, LX / 2, N_total)
    pos[:, 1] = np.random.uniform(0, LZ, N_total)

    # 電子の熱速度分布
    vel[:N_e, :] = np.random.normal(0, v_the, (N_e, 3))
    charge[:N_e] = q_e
    mass[:N_e] = m_e

    # イオンの熱速度分布
    vel[N_e:, :] = np.random.normal(0, v_thi, (N_i, 3))
    charge[N_e:] = q_i
    mass[N_e:] = m_i


    wp = (n0 * LX * LZ) / N_total
    print(f"Particles initialized: {N_e} electrons, {N_i} ions.")
else:
    wp = 0
energies = []

# ==============================================================================
# --- 4. コア計算関数 ---
# ==============================================================================
@jit(nopython=True, cache=True)
def initial_velocity_rewind(pos_s, vel_s, charge_s, mass_s, E, B, dt, Lx, Lz, dx, dz, NX, NZ):
    """
    【最終修正版】リープフロッグ法を正しく開始するため、t=0の速度v0からt=-dt/2の速度を計算する。
    v(-dt/2) = v(0) - a(0) * dt/2 という物理に忠実な計算を行う。
    """
    half_Lx = Lx / 2.0
    # ループ内で vel_s を変更するため、元の v(0) を保持しておく
    vel_initial = vel_s.copy()

    for i in range(pos_s.shape[0]):
        # t=0 の位置における電場・磁場を補間
        ix_f = (pos_s[i, 0] + half_Lx) / dx
        iz_f = pos_s[i, 1] / dz
        ix = int(ix_f)
        iz = int(iz_f)
        
        wx = ix_f - ix
        wz = iz_f - iz
        
        dwx, dwz = 1.0 - wx, 1.0 - wz
        ix_p1 = (ix + 1) % NX
        iz_p1 = (iz + 1) % NZ

        E_p = (E[ix, iz] * dwx * dwz + E[ix_p1, iz] * wx * dwz +
               E[ix, iz_p1] * dwx * wz + E[ix_p1, iz_p1] * wx * wz)
        B_p = (B[ix, iz] * dwx * dwz + B[ix_p1, iz] * wx * dwz +
               B[ix, iz_p1] * dwx * wz + B[ix_p1, iz_p1] * wx * wz)

        q_over_m = charge_s[i] / mass_s[i]
        
        # t=0 での加速度 a(0) = (q/m)*(E(0) + v(0) x B(0)) を計算
        accel = q_over_m * (E_p + np.cross(vel_initial[i], B_p))
        
        # v(-dt/2) = v(0) - a(0) * dt/2 を計算して速度を更新
        vel_s[i] = vel_initial[i] - accel * dt / 2.0
        
    return vel_s

@jit(nopython=True, cache=True)
def deposit_charge_only(pos_s, charge_s, rho_s, wp, Lx, Lz, dx, dz, NX, NZ):
    """粒子を動かさず、電荷密度のみをグリッドに計算する"""
    rho_s.fill(0)
    inv_vol = 1.0 / (dx * dz)
    half_Lx = Lx / 2.0
    for i in range(pos_s.shape[0]):
        ix_f = (pos_s[i, 0] + half_Lx) / dx
        iz_f = pos_s[i, 1] / dz
        ix = int(ix_f)
        iz = int(iz_f)
        
        # 範囲チェック
        if not (0 <= ix < NX - 1 and 0 <= iz < NZ - 1):
            continue

        wx = ix_f - ix
        wz = iz_f - iz
        dwx, dwz = 1.0 - wx, 1.0 - wz
        
        q_contrib = charge_s[i] * wp * inv_vol
        rho_s[ix, iz]     += q_contrib * dwx * dwz
        rho_s[ix + 1, iz]   += q_contrib * wx * dwz
        rho_s[ix, iz + 1]   += q_contrib * dwx * wz
        rho_s[ix + 1, iz + 1] += q_contrib * wx * wz
    return rho_s

@jit(nopython=True, cache=True)
def push_and_deposit_species(pos_s, vel_s, charge_s, mass_s, E, B, wp, dt, Lx, Lz, dx, dz, NX, NZ):
    J_s = np.zeros((NX, NZ, 3))
    rho_s = np.zeros((NX, NZ))
    inv_vol = 1.0 / (dx * dz)
    half_Lx = Lx / 2.0
    
    for i in range(pos_s.shape[0]):
        # --- 1. 電場・磁場の補間 ---
        x_old, z_old = pos_s[i, 0], pos_s[i, 1]
        ix_f = (x_old + half_Lx) / dx
        iz_f = z_old / dz
        ix, iz = int(ix_f), int(iz_f)
        wx, wz = ix_f - ix, iz_f - iz
        E_p = (E[ix%NX, iz%NZ]*(1-wx)*(1-wz) + E[(ix+1)%NX, iz%NZ]*wx*(1-wz) + E[ix%NX, (iz+1)%NZ]*(1-wx)*wz + E[(ix+1)%NX, (iz+1)%NZ]*wx*wz)
        B_p = (B[ix%NX, iz%NZ]*(1-wx)*(1-wz) + B[(ix+1)%NX, iz%NZ]*wx*(1-wz) + B[ix%NX, (iz+1)%NZ]*(1-wx)*wz + B[(ix+1)%NX, (iz+1)%NZ]*wx*wz)

        # --- 2. Boris Pusher (オリジナルの信頼性が高い実装) ---
        q_over_m = charge_s[i] / mass_s[i]
        
        # Half-step electric acceleration
        v_minus = vel_s[i] + q_over_m * E_p * (dt / 2.0)
        
        # Full magnetic rotation
        t_vec = q_over_m * B_p * (dt / 2.0)
        t_mag_sq = np.dot(t_vec, t_vec)
        s_vec = 2.0 * t_vec / (1.0 + t_mag_sq)
        v_prime = v_minus + np.cross(v_minus, t_vec)
        v_plus = v_minus + np.cross(v_prime, s_vec)
        
        # Second half-step electric acceleration
        vel_s[i] = v_plus + q_over_m * E_p * (dt / 2.0)

        # --- 3. 位置更新 ---
        pos_s[i, 0] += vel_s[i, 0] * dt
        pos_s[i, 1] += vel_s[i, 2] * dt

        # --- 4. 周期境界条件 ---
        if pos_s[i, 0] > half_Lx: pos_s[i, 0] -= Lx
        elif pos_s[i, 0] < -half_Lx: pos_s[i, 0] += Lx
        if pos_s[i, 1] > Lz: pos_s[i, 1] -= Lz
        elif pos_s[i, 1] < 0: pos_s[i, 1] += Lz
        
        # --- 5. 電流・電荷密度への加算 ---
        q_contrib = charge_s[i] * wp * inv_vol
        
        # 電荷(rho)は移動後の位置(x_new, z_new)で計算
        x_new, z_new = pos_s[i, 0], pos_s[i, 1]
        ix_f_new = (x_new + half_Lx) / dx; iz_f_new = z_new / dz
        ix_new, iz_new = int(ix_f_new), int(iz_f_new)
        wx_new, wz_new = ix_f_new - ix_new, iz_f_new - iz_new
        rho_s[(ix_new+0)%NX, (iz_new+0)%NZ] += q_contrib*(1-wx_new)*(1-wz_new)
        rho_s[(ix_new+1)%NX, (iz_new+0)%NZ] += q_contrib*wx_new*(1-wz_new)
        rho_s[(ix_new+0)%NX, (iz_new+1)%NZ] += q_contrib*(1-wx_new)*wz_new
        rho_s[(ix_new+1)%NX, (iz_new+1)%NZ] += q_contrib*wx_new*wz_new

        # 電流(J)は移動前後の「中間点」で計算
        x_mid, z_mid = (x_old + x_new)/2.0, (z_old + z_new)/2.0
        ix_f_mid = (x_mid + half_Lx) / dx; iz_f_mid = z_mid / dz
        ix_mid, iz_mid = int(ix_f_mid), int(iz_f_mid)
        wx_mid, wz_mid = ix_f_mid - ix_mid, iz_f_mid - iz_mid
        for d in range(3):
            j_p = q_contrib * vel_s[i, d]
            J_s[(ix_mid+0)%NX, (iz_mid+0)%NZ, d] += j_p*(1-wx_mid)*(1-wz_mid)
            J_s[(ix_mid+1)%NX, (iz_mid+0)%NZ, d] += j_p*wx_mid*(1-wz_mid)
            J_s[(ix_mid+0)%NX, (iz_mid+1)%NZ, d] += j_p*(1-wx_mid)*wz_mid
            J_s[(ix_mid+1)%NX, (iz_mid+1)%NZ, d] += j_p*wx_mid*wz_mid
            
    return pos_s, vel_s, J_s, rho_s
@jit(nopython=True, cache=True)
def density_decomposition_correction_fft(J_in, rho_new, rho_old, dt, dx, dz, NX, NZ):
    """
    【手法修正版】
    ∇・Jの計算をスペクトル法から中心差分法に変更し、計算手法の不整合を解消する。
    """
    # 波数ベクトルを準備 (ポアソン方程式を解くために必要)
    kx = 2 * np.pi * fftfreq(NX, d=dx)
    kz = 2 * np.pi * fftfreq(NZ, d=dz)
    kx_grid, kz_grid = np.meshgrid(kx, kz, indexing='ij')

    # 1. ∇・J を「中心差分法」で計算
    # np.roll を使い、周期境界を正しく扱う
    J_x_plus_1 = np.roll(J_in[:, :, 0], -1, axis=0)
    J_x_minus_1 = np.roll(J_in[:, :, 0], 1, axis=0)
    
    J_z_plus_1 = np.roll(J_in[:, :, 2], -1, axis=1)
    J_z_minus_1 = np.roll(J_in[:, :, 2], 1, axis=1)
    
    div_J = (J_x_plus_1 - J_x_minus_1) / (2 * dx) + \
            (J_z_plus_1 - J_z_minus_1) / (2 * dz)

    # 2. ∂ρ/∂t を計算
    d_rho_dt = (rho_new - rho_old) / dt

    # 3. ポアソン方程式のソース項 S = ∇・J + ∂ρ/∂t を計算
    S = div_J + d_rho_dt

    # 4. ∇^2 ψ = S をFFTを使って高速に解く
    k_sq = kx_grid**2 + kz_grid**2
    k_sq[0, 0] = 1.0

    S_k = fft2(S)
    psi_k = -S_k / k_sq
    psi_k[0, 0] = 0.0

    # 波数空間で∇ψを計算
    grad_psi_x_k = 1j * kx_grid * psi_k
    grad_psi_z_k = 1j * kz_grid * psi_k

    # 補正項を実空間に戻す
    grad_psi = np.zeros_like(J_in)
    grad_psi[:, :, 0] = np.real(ifft2(grad_psi_x_k))
    grad_psi[:, :, 2] = np.real(ifft2(grad_psi_z_k))

    # 5. 電流を補正
    J_corrected = J_in - grad_psi

    return J_corrected

@jit(nopython=True, cache=True)
def smooth_current(J_in):
    J_out=J_in.copy()
    for c in range(3):
        J_temp=J_out[:,:,c].copy(); J_temp[1:-1,:]=0.25*J_out[:-2,:,c]+0.5*J_out[1:-1,:,c]+0.25*J_out[2:,:,c]; J_out[:,:,c]=J_temp
        J_temp=J_out[:,:,c].copy(); J_temp[:,1:-1]=0.25*J_out[:,:-2,c]+0.5*J_out[:,1:-1,c]+0.25*J_out[:,2:,c]; J_out[:,:,c]=J_temp
    return J_out

@jit(nopython=True, cache=True)
def FDTD_solver(E, B, J, dt, dx, dz, NX, NZ):
    # --- Bの更新 (t -> t+dt/2) ---
    # By(i, j)はEx(i, j+1)とEx(i, j)の差で決まる
    for i in range(NX):
        for j in range(NZ - 1): # Byのサイズに合わせる
            # 2Dコードなので、dEz/dx 項も考慮に入れる
            # dEz_dx = (E[i + 1, j, 2] - E[i, j, 2]) / dx (Ezは(i, j+1/2), Byは(i+1/2,j)にないので単純ではない)
            # 簡単のため、O-modeに不要な項は0とする
            dEx_dz = (E[i, j + 1, 0] - E[i, j, 0]) / dz
            B[i, j, 1] += dt * (0 - dEx_dz) # ∂By/∂t = ∂Ez/∂x - ∂Ex/∂z

    # --- Eの更新 (t+dt/2 -> t+dt) ---
    # Ex(i, j)はBy(i, j)とBy(i, j-1)の差で決まる
    for i in range(NX):
        for j in range(1, NZ - 1): # 境界を除く内部の点をまず計算
            dBy_dz = (B[i, j, 1] - B[i, j - 1, 1]) / dz
            E[i, j, 0] += dt * (0 - dBy_dz - J[i, j, 0]) # ∂Ex/∂t = ∂Bz/∂y - ∂By/∂z - Jx

    # --- 境界条件 (Periodic in Z) ---
    for i in range(NX):
        # E[i, 0] の更新
        E[i, 0, 0] += dt * (0 - (B[i, 0, 1] - B[i, -1, 1]) / dz - J[i, 0, 0])
        # E[i, NZ-1] の更新
        E[i, -1, 0] = E[i, 0, 0] # 周期境界

    return E, B
@jit(nopython=True, cache=True)
def smooth_for_plot(field_2d):
    # 1-2-1フィルタを2回適用して滑らかなプロットを得る
    out = field_2d.copy()
    for _ in range(2):
        temp = out.copy()
        temp[1:-1, :] = 0.25 * out[:-2, :] + 0.5 * out[1:-1, :] + 0.25 * out[2:, :]
        out = temp.copy()
        temp[:, 1:-1] = 0.25 * out[:, :-2] + 0.5 * out[:, 1:-1] + 0.25 * out[:, 2:]
        out = temp
    return out

def create_diagnostic_plot_normalized(filename, t_wce, B, J, E, Ay, pos, N_e, Lx_de, Lz_de, x_vec_de, z_vec_de, x_grid_norm, z_grid_norm):
    fig, axs = plt.subplots(3, 4, figsize=(22, 12), constrained_layout=True)
    fig.suptitle(f'Time($\omega_{{ce}}t$) = {t_wce:.2f}', fontsize=16, y=1.02)
    extent = [-Lx_de / 2, Lx_de / 2, 0, Lz_de]
    data_map = {
        'Bx': (B[:, :, 0].T, axs[0, 0]), 'By': (B[:, :, 1].T, axs[0, 1]), 'Bz': (B[:, :, 2].T, axs[0, 2]),
        'Jx': (J[:, :, 0].T, axs[1, 0]), 'Jy': (J[:, :, 1].T, axs[1, 1]), 'Jz': (J[:, :, 2].T, axs[1, 2]),
        'Ex': (E[:, :, 0].T, axs[2, 0]), 'Ey': (E[:, :, 1].T, axs[2, 1]), 'Ez': (E[:, :, 2].T, axs[2, 2]),
    }
    color_limits = {
        'Bx': 0.0002, 'By': 0.005, 'Bz': 0.0002,
        'Jx': 0.05, 'Jy': 0.0005, 'Jz': 0.01,
        'Ex': 0.05, 'Ey': 0.0002, 'Ez': 0.01,
        'Ay': 1.0,  'Bpol': 1.0
    }
    for name, (data, ax) in data_map.items():
        data_to_plot = smooth_for_plot(data)
        if name in color_limits:
            vmax = color_limits[name]
        else:
            vmax = np.max(np.abs(data_to_plot)) if np.max(np.abs(data_to_plot)) > 1e-9 else 1.0
        im = ax.imshow(data_to_plot, origin='lower', extent=extent, aspect='equal', cmap='RdBu_r', vmin=-vmax, vmax=vmax)
        fig.colorbar(im, ax=ax, label=f'{name} value')
        ax.set_title(f'{name} Distribution')
    # 磁束ポテンシャル Ay のプロット
    ax_psi = axs[0, 3]; ax_psi.set_title(r'Poloidal Flux $\psi$ from $A_y$')
    if 'Ay' in color_limits:
        vmax_ay = color_limits['Ay']
    else:
        vmax_ay = np.max(np.abs(Ay)) if np.max(np.abs(Ay)) > 0 else 1.0
    ax_psi.contour(x_vec_de, z_vec_de, Ay.T, levels=20, colors='k', linewidths=0.8)
    im_ay = ax_psi.imshow(Ay.T, origin='lower', extent=extent, aspect='equal', cmap='viridis', vmin=-vmax_ay, vmax=vmax_ay)
    fig.colorbar(im_ay, ax=ax_psi, label=r'Value')
    # 粒子位置のプロット
    ax_part = axs[1, 3]; ax_part.set_title('Particle Positions')
    ax_part.plot(pos[N_e:, 0] / d_e, pos[N_e:, 1] / d_e, '.', ms=1, color='red', label='Ions', alpha=0.5)
    ax_part.plot(pos[:N_e, 0] / d_e, pos[:N_e, 1] / d_e, '.', ms=1, color='blue', label='Electrons', alpha=0.5)
    ax_part.legend(markerscale=5, loc='upper right')
    ax_part.set_xlim(extent[0], extent[1]); ax_part.set_ylim(extent[2], extent[3])
    # ポロイダル磁場ベクトルのプロット
    ax_helicity = axs[2, 3]; ax_helicity.set_title(r'Poloidal Field Vectors')
    if 'Bpol' in color_limits:
        vmax_bpol = color_limits['Bpol']
    else:
        vmax_bpol = np.max(np.sqrt(B[:, :, 0]**2 + B[:, :, 2]**2)) if np.max(np.sqrt(B[:, :, 0]**2 + B[:, :, 2]**2)) > 0 else 1.0
    ax_helicity.imshow(np.sqrt(B[:, :, 0]**2 + B[:, :, 2]**2).T, origin='lower', extent=extent, aspect='equal', cmap='magma', vmin=0, vmax=vmax_bpol)
    skip = 8
    ax_helicity.quiver(x_grid_norm[::skip, ::skip], z_grid_norm[::skip, ::skip], B[::skip, ::skip, 0], B[::skip, ::skip, 2],color='lime', scale=vmax_bpol * 20 if vmax_bpol > 0 else 1, width=0.005)
    # 軸ラベルの設定
    for ax in axs.flat:
        ax.set_xlabel('x [$d_e$]'); ax.set_ylabel('z [$d_e$]')
    plt.savefig(filename, dpi=150); plt.close(fig)

def plot_plasma_moments(filename, t_wpe, rho_e, rho_i, q_e, q_i, Lx_de, Lz_de):
    fig, axs = plt.subplots(1, 2, figsize=(14, 5.5), constrained_layout=True)
    fig.suptitle(f'Plasma Density at t = {t_wpe:.1f} $[1/\omega_{{pe}}]$', fontsize=16)
    extent = [-Lx_de/2, Lx_de/2, 0, Lz_de]
    
    n_e = rho_e / q_e
    n_i = rho_i / q_i
    
    vmax = max(np.max(n_e), np.max(n_i)) * 1.2 if max(np.max(n_e), np.max(n_i)) > 1e-9 else 1.0
    im1 = axs[0].imshow(n_e.T, origin='lower', extent=extent, aspect='equal', cmap='viridis', vmin=0, vmax=vmax)
    fig.colorbar(im1, ax=axs[0], label='Density [$n_0$]')
    axs[0].set_title('Electron Density'); axs[0].set_xlabel('x [$d_e$]'); axs[0].set_ylabel('z [$d_e$]')
    im2 = axs[1].imshow(n_i.T, origin='lower', extent=extent, aspect='equal', cmap='viridis', vmin=0, vmax=vmax)
    fig.colorbar(im2, ax=axs[1], label='Density [$n_0$]'); axs[1].set_title('Ion Density'); axs[1].set_xlabel('x [$d_e$]')
    plt.savefig(filename, dpi=120); plt.close(fig)

def plot_energy_conservation(filename, energies):
    energies_np = np.array(energies)
    if len(energies_np) < 2: return

    times = energies_np[:, 0]
    ke = energies_np[:, 1]
    be = energies_np[:, 2]
    ee = energies_np[:, 3]
    total_e = energies_np[:, 4]
    initial_total_e = total_e[0] if total_e[0] > 0 else 1.0

    # 各エネルギー成分の変化量を、初期の全エネルギーで規格化
    delta_ke_rel = (ke - ke[0]) / initial_total_e
    delta_be_rel = (be - be[0]) / initial_total_e
    delta_ee_rel = (ee - ee[0]) / initial_total_e
    delta_total_rel = (total_e - initial_total_e) / initial_total_e
    
    plt.figure(figsize=(10,6))
    plt.plot(times, delta_ke_rel, label='$\\Delta KE$')
    plt.plot(times, delta_be_rel, label='$\\Delta BE$')
    plt.plot(times, delta_ee_rel, label='$\\Delta EE$')
    plt.plot(times, delta_total_rel, 'k--', lw=2, label='$\\Delta E_{Total}$')
    
    plt.title('Energy Conservation Check'); plt.xlabel('Time $[1/\omega_{pe}]$'); plt.ylabel('Energy Change / Initial Total E')
    plt.grid(True); plt.legend()

    # 全てのプロットカーブの変動の絶対値の最大値を取得
    max_fluctuation = 0
    if len(times) > 1:
        max_fluc_each = [
            np.max(np.abs(delta_ke_rel)),
            np.max(np.abs(delta_be_rel)),
            np.max(np.abs(delta_ee_rel)),
            np.max(np.abs(delta_total_rel))
        ]
        max_fluctuation = max(max_fluc_each)

    # y軸の範囲を設定。最低でも±5%は表示するようにする
    plot_range = max(0.05, max_fluctuation * 1.5)
    plt.ylim(-plot_range, plot_range)
    
    plt.savefig(filename); plt.close()


# ==============================================================================
# --- 5. クワイエット・スタートとメインループ (イオンを考慮) ---
# ==============================================================================

if N_total > 0:
    # 粒子配置から直接、t=0 の電荷密度を計算する
    rho_e_initial = deposit_charge_only(pos[:N_e], charge[:N_e], np.zeros_like(rho), wp, LX, LZ, dx, dz, NX, NZ)
    rho_i_initial = deposit_charge_only(pos[N_e:], charge[N_e:], np.zeros_like(rho), wp, LX, LZ, dx, dz, NX, NZ)
    rho_old = rho_e_initial + rho_i_initial
else:
    rho_old = np.zeros((NX, NZ))

if N_total > 0:
    # 電子とイオンの速度を t=0 -> t=-dt/2 へと後退させる
    vel[:N_e] = initial_velocity_rewind(pos[:N_e], vel[:N_e], charge[:N_e], mass[:N_e], E, B, dt, LX, LZ, dx, dz, NX, NZ)
    vel[N_e:] = initial_velocity_rewind(pos[N_e:], vel[N_e:], charge[N_e:], mass[N_e:], E, B, dt, LX, LZ, dx, dz, NX, NZ)


print("Starting main loop...")
start_time = time.time()
# initial_t_wce = 0.0 # エネルギープロットの開始時間

for step in range(N_STEPS + 1):
    t_wce = step * dt * w_ce

    if N_total > 0:
        pos[:N_e], vel[:N_e], J_e, rho_e = push_and_deposit_species(pos[:N_e], vel[:N_e], charge[:N_e], mass[:N_e], E, B, wp, dt, LX, LZ, dx, dz, NX, NZ)
        pos[N_e:], vel[N_e:], J_i, rho_i = push_and_deposit_species(pos[N_e:], vel[N_e:], charge[N_e:], mass[N_e:], E, B, wp, dt, LX, LZ, dx, dz, NX, NZ)
        J_plasma = J_e + J_i
        rho_new = rho_e + rho_i # 現ステップの電荷密度
        
        # --- ここから電荷保存補正 ---
        # J_plasma = density_decomposition_correction_fft(J_plasma, rho_new, rho_old, dt, dx, dz, NX, NZ)
        
        # 次のステップのために、現ステップの電荷密度を保存
        rho_old = rho_new.copy()
        
        J_plasma_smooth = J_plasma.copy()
        for _ in range(NUM_SMOOTHING_PASSES):
            J_plasma_smooth = smooth_current(J_plasma_smooth)
    else:
        J_plasma_smooth = J_plasma
        rho_new = np.zeros_like(rho)
        rho_old = rho_new.copy()

    J_total = J_plasma_smooth + J_ext
    E, B = FDTD_solver(E, B, J_total, dt, dx, dz, NX, NZ)

    # プロットとエネルギー計算
    if step % PLOT_STEPS == 0 or step == N_STEPS:
        elapsed = time.time() - start_time
        eta_seconds = (elapsed / (step + 1)) * (N_STEPS - step) if step > 0 else 0
        eta_str = f"ETA: {eta_seconds:.0f}s"
        print(f"Step {step}/{N_STEPS} | T_wce={t_wce:.2f} | {eta_str} -> Plotting...")

        # --- 追加: エネルギー計算 ---
        if N_total > 0:
            ke_e = 0.5 * np.sum(mass[:N_e, np.newaxis] * vel[:N_e]**2)
            ke_i = 0.5 * np.sum(mass[N_e:, np.newaxis] * vel[N_e:]**2)
            kinetic_energy = (ke_e + ke_i) * wp # スーパーパーティクルの重みをかける
        else:
            kinetic_energy = 0
            
        magnetic_energy = 0.5 * np.sum(B**2) * dx * dz
        electric_energy = 0.5 * np.sum(E**2) * dx * dz
        total_energy = kinetic_energy + magnetic_energy + electric_energy
        energies.append([t_wce, kinetic_energy, magnetic_energy, electric_energy, total_energy])

        # 2Dプロット
        filename_diag = os.path.join(output_dir, f"diagnostic_plot_{step:05d}.png")
        create_diagnostic_plot_normalized(filename_diag, t_wce, B, J_plasma_smooth, E, Ay, pos, N_e, LX_de, LZ_de, x_vec_de, z_vec_de, x_grid_norm, z_grid_norm)
        
        # エネルギープロット
        filename_energy = os.path.join(output_dir, "energy_conservation.png")
        plot_energy_conservation(filename_energy, energies)

print(f"✅ Simulation finished. Total wall time: {time.time() - start_time:.1f}s")
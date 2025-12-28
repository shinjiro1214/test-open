import numpy as np
import matplotlib.pyplot as plt
import time
import os
from numba import jit
from scipy.interpolate import RegularGridInterpolator
from scipy.fft import dst, idst

print("🚀 Initializing Spheromak PIC Simulation - Ver. 4.1 (By Field Masked)")

# ==============================================================================
# --- 1. 物理・シミュレーション設定 ---
# ==============================================================================
MI_ME = 25.0
WPE_WCE = 2.0
T_el_norm = 0.2
NX, NZ = 257, 129
LX_de, LZ_de = 51.2, 25.6
N_PTCL_PER_CELL = 100
T_MAX_wce = 50.0
PLOT_INTERVAL_wce = 0.5
NUM_SMOOTHING_PASSES = 8

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
v_the = np.sqrt(T_el_norm / m_e)
v_thi = v_the / np.sqrt(MI_ME)
d_e = c / w_pe
LX, LZ = LX_de * d_e, LZ_de * d_e
dx, dz = LX / (NX - 1), LZ / (NZ - 1)
# dtはw_pe基準で計算されるが、時間ステップはw_ce基準で行う
dt_wpe = 0.05 / (c * np.sqrt(1 / dx**2 + 1 / dz**2))
dt_wce = dt_wpe * w_ce ### 追加: w_ce単位の時間ステップ
N_STEPS = int(T_MAX_wce / dt_wce) ### 変更: w_ce基準のステップ数
# dt = 0.05 / (c * np.sqrt(1 / dx**2 + 1 / dz**2))
PLOT_STEPS = int(PLOT_INTERVAL_wce / dt_wce) if PLOT_INTERVAL_wce > 0 else N_STEPS + 1 ### 変更

print(f"Grid: {NX}x{NZ}, dt_wce: {dt_wce:.4f}, Total Steps: {N_STEPS}")
# print(f"Grid: {NX}x{NZ}, dt: {dt:.4f}, Total Steps: {int(T_MAX_wpe/dt)}")

output_dir = "data_spheromak_masked_push4"
os.makedirs(output_dir, exist_ok=True)

E = np.zeros((NX, NZ, 3))
B = np.zeros((NX, NZ, 3))
J_plasma = np.zeros((NX, NZ, 3))
J_ext = np.zeros((NX, NZ, 3))
rho = np.zeros((NX, NZ))
Ay = np.zeros((NX, NZ))

x_vec = np.linspace(-LX / 2, LX / 2, NX)
z_vec = np.linspace(0, LZ, NZ)
x_grid, z_grid = np.meshgrid(x_vec, z_vec, indexing='ij')
x_vec_de = x_vec / d_e
z_vec_de = z_vec / d_e
x_grid_norm, z_grid_norm = np.meshgrid(x_vec_de, z_vec_de, indexing='ij')

# ==============================================================================
# --- 3. 初期条件：2つのスフェロマック ---
# ==============================================================================
def solve_poisson_dirichlet(source_term, dx, dz):
    """
    高速サイン変換(FST)を用いて、ディリクレ境界条件(A_y=0 on boundary)
    のもとでポアソン方程式 ∇²A_y = -source_term を解く
    """
    nx, nz = source_term.shape
    # グリッド内部の点のみを扱う
    source_slice = source_term[1:-1, 1:-1]
    
    # ソース項をサイン変換
    source_k = dst(dst(source_slice, type=1, axis=0), type=1, axis=1) / 4.0

    # 波数ベクトルを作成
    kx = np.pi * (np.arange(1, nx - 1)) / (nx - 1)
    kz = np.pi * (np.arange(1, nz - 1)) / (nz - 1)
    kx_grid, kz_grid = np.meshgrid(kx, kz, indexing='ij')

    # ラプラシアンの固有値で除算
    denom = (2 * np.cos(kx_grid) - 2) / dx**2 + (2 * np.cos(kz_grid) - 2) / dz**2
    # ゼロ割を防止
    denom[denom == 0] = 1.0 
    
    # ポテンシャルを周波数空間で計算
    potential_k = -source_k / denom
    
    # 逆サイン変換で実空間に戻す
    potential_slice = idst(idst(potential_k, type=1, axis=0), type=1, axis=1)
    
    # 結果を格納する配列をゼロで初期化（境界がゼロになる）
    potential = np.zeros_like(source_term)
    # グリッド内部に計算結果を格納
    potential[1:-1, 1:-1] = potential_slice
    
    return potential

print("Setting up initial condition: Two Spheromaks (Horizontal)...")

x_cnt1, x_cnt2 = -LX / 4.0, LX / 4.0
z_cnt1, z_cnt2 = LZ / 2.0, LZ / 2.0
ra = 0.3 * LZ
jm = -0.4

J_y = np.zeros_like(Ay)
r1_sq = (x_grid - x_cnt1)**2 + (z_grid - z_cnt1)**2
mask1 = r1_sq < ra**2
J_y[mask1] = jm * (1 - r1_sq[mask1] / ra**2)**2
r2_sq = (x_grid - x_cnt2)**2 + (z_grid - z_cnt2)**2
mask2 = r2_sq < ra**2
J_y[mask2] = jm * (1 - r2_sq[mask2] / ra**2)**2


Ay = solve_poisson_dirichlet(J_y, dx, dz)

Bz_temp, Bx_temp = np.gradient(Ay, dx, dz, edge_order=2)
B[:, :, 0] = Bx_temp
B[:, :, 2] = -Bz_temp

By_peak = -5.0 * np.max(np.abs(B[:,:,2]))
ay_max = np.max(Ay)
if ay_max > 1e-9:
    B[:, :, 1] = By_peak * (Ay / ay_max) * np.sign(x_grid)
else:
    B[:, :, 1] = 0.0

spheromak_mask = mask1 | mask2
B[:, :, 1] = np.where(spheromak_mask, B[:, :, 1], 0.0)

print("Initial fields have been set.")

# ==============================================================================
# --- 粒子初期化 ---
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
    pos[:, 0] = np.random.uniform(-LX / 2, LX / 2, N_total)
    pos[:, 1] = np.random.uniform(0, LZ, N_total)
    
    # 電子の熱速度分布
    vel[:N_e, :] = np.random.normal(0, v_the, (N_e, 3))
    # 電子にドリフト速度を加える
    v_drift_y = J_y / (n0 * q_e)
    interp_v_drift = RegularGridInterpolator((x_vec, z_vec), v_drift_y, bounds_error=False, fill_value=0)
    drift_vels_at_pos = interp_v_drift(pos[:N_e, :])
    vel[:N_e, 1] += drift_vels_at_pos
    
    charge[:N_e] = q_e
    mass[:N_e] = m_e

    # イオンの熱速度分布
    vel[N_e:, :] = np.random.normal(0, v_thi, (N_i, 3))
    charge[N_e:] = q_i
    mass[N_e:] = m_i
    
    # イオンの熱速度の半分程度の速さで押し込む
    v_push_x = 0.5 * v_thi 
    
    # 左側 (x < 0) の粒子を特定
    left_mask = pos[:, 0] < 0
    # 右側 (x >= 0) の粒子を特定
    right_mask = pos[:, 0] >= 0
    
    # x方向の速度に v_push_x を加算/減算する
    vel[left_mask, 0] += v_push_x
    vel[right_mask, 0] -= v_push_x

    print(f"Added initial push velocity: v_push = {v_push_x:.3f}")
    
    wp = (n0 * LX * LZ) / N_total
    print(f"Particles initialized: {N_e} electrons, {N_i} ions.")
else:
    wp = 0
    
# ==============================================================================
# --- 4. コア計算関数 ---
# ==============================================================================
@jit(nopython=True, cache=True)
def push_and_deposit_species(pos_s, vel_s, charge_s, mass_s, E, B, J_s, rho_s, wp, dt, Lx, Lz, dx, dz, NX, NZ):
    J_s.fill(0)
    rho_s.fill(0)
    inv_vol = 1.0 / (dx * dz)
    half_Lx = Lx / 2.0
    
    for i in range(pos_s.shape[0]):
        # --- 1. 電場・磁場の補間 ---
        ix_f = (pos_s[i, 0] + half_Lx) / dx
        iz_f = pos_s[i, 1] / dz
        
        # 粒子が領域外にいる場合でも補間を試みる (ただし通常は内側にいるはず)
        ix = int(ix_f)
        iz = int(iz_f)
        if not (0 <= ix < NX - 1 and 0 <= iz < NZ - 1):
            ix = min(max(ix, 0), NX - 2)
            iz = min(max(iz, 0), NZ - 2)

        wx = ix_f - ix
        wz = iz_f - iz
        
        dwx, dwz = 1.0 - wx, 1.0 - wz
        
        E_p = (E[ix, iz] * dwx * dwz + E[ix + 1, iz] * wx * dwz +
               E[ix, iz + 1] * dwx * wz + E[ix + 1, iz + 1] * wx * wz)
        B_p = (B[ix, iz] * dwx * dwz + B[ix + 1, iz] * wx * dwz +
               B[ix, iz + 1] * dwx * wz + B[ix + 1, iz + 1] * wx * wz)

        # --- 2. Boris Pusherによる速度更新 ---
        q_over_m = charge_s[i] / mass_s[i]
        v_minus = vel_s[i] + q_over_m * E_p * dt / 2.0
        t_vec = q_over_m * B_p * dt / 2.0
        t_mag_sq = np.dot(t_vec, t_vec)
        s_vec = 2.0 * t_vec / (1.0 + t_mag_sq)
        v_prime = v_minus + np.cross(v_minus, t_vec)
        v_plus = v_minus + np.cross(v_prime, s_vec)
        vel_s[i] = v_plus + q_over_m * E_p * dt / 2.0

        # --- 3. 位置更新 ---
        # Note: pos[:, 1] is z-coordinate, updated by vel[:, 2] (vz)
        pos_s[i, 0] += vel_s[i, 0] * dt
        pos_s[i, 1] += vel_s[i, 2] * dt

        # --- 4. 境界での鏡面反射 ---
        # x-boundary
        if pos_s[i, 0] > half_Lx:
            pos_s[i, 0] = Lx - pos_s[i, 0]
            vel_s[i, 0] *= -1.0
        elif pos_s[i, 0] < -half_Lx:
            pos_s[i, 0] = -Lx - pos_s[i, 0]
            vel_s[i, 0] *= -1.0
        
        # z-boundary
        if pos_s[i, 1] > Lz:
            pos_s[i, 1] = 2.0 * Lz - pos_s[i, 1]
            vel_s[i, 2] *= -1.0
        elif pos_s[i, 1] < 0.0:
            pos_s[i, 1] = -pos_s[i, 1]
            vel_s[i, 2] *= -1.0

        # --- 5. 電流・電荷密度への加算 ---
        ix_f_new = (pos_s[i, 0] + half_Lx) / dx
        iz_f_new = pos_s[i, 1] / dz
        
        ix_new = int(ix_f_new)
        iz_new = int(iz_f_new)
        
        # 反射後の位置が稀に領域外になるのを防ぐためのセーフガード
        if not (0 <= ix_new < NX - 1 and 0 <= iz_new < NZ - 1):
            pos_s[i, 0] = np.maximum(-half_Lx + dx * 0.1, np.minimum(half_Lx - dx * 0.1, pos_s[i, 0]))
            pos_s[i, 1] = np.maximum(dz * 0.1, np.minimum(Lz - dz * 0.1, pos_s[i, 1]))
            ix_f_new = (pos_s[i, 0] + half_Lx) / dx
            iz_f_new = pos_s[i, 1] / dz
            ix_new = int(ix_f_new)
            iz_new = int(iz_f_new)

        wx_new = ix_f_new - ix_new
        wz_new = iz_f_new - iz_new
        dwx_new, dwz_new = 1.0 - wx_new, 1.0 - wz_new
        
        q_contrib = charge_s[i] * wp * inv_vol
        
        # Charge deposition
        rho_s[ix_new, iz_new]     += q_contrib * dwx_new * dwz_new
        rho_s[ix_new + 1, iz_new]   += q_contrib * wx_new * dwz_new
        rho_s[ix_new, iz_new + 1]   += q_contrib * dwx_new * wz_new
        rho_s[ix_new + 1, iz_new + 1] += q_contrib * wx_new * wz_new
        
        # Current deposition
        for d in range(3):
            j_p = q_contrib * vel_s[i, d]
            J_s[ix_new, iz_new, d]     += j_p * dwx_new * dwz_new
            J_s[ix_new + 1, iz_new, d]   += j_p * wx_new * dwz_new
            J_s[ix_new, iz_new + 1, d]   += j_p * dwx_new * wz_new
            J_s[ix_new + 1, iz_new + 1, d] += j_p * wx_new * wz_new
            
    return pos_s, vel_s, J_s, rho_s

@jit(nopython=True, cache=True)
def smooth_current(J_in):
    J_out=J_in.copy()
    for c in range(3):
        J_temp=J_out[:,:,c].copy(); J_temp[1:-1,:]=0.25*J_out[:-2,:,c]+0.5*J_out[1:-1,:,c]+0.25*J_out[2:,:,c]; J_out[:,:,c]=J_temp
        J_temp=J_out[:,:,c].copy(); J_temp[:,1:-1]=0.25*J_out[:,:-2,c]+0.5*J_out[:,1:-1,c]+0.25*J_out[:,2:,c]; J_out[:,:,c]=J_temp
    return J_out

@jit(nopython=True, cache=True)
def FDTD_solver(E, B, J, dt, dx, dz):
    B[1:-1,1:-1,0]+=dt*(E[1:-1,2:,1]-E[1:-1,:-2,1])/(2*dz)
    B[1:-1,1:-1,1]+=dt*((E[2:,1:-1,2]-E[:-2,1:-1,2])/(2*dx)-(E[1:-1,2:,0]-E[1:-1,:-2,0])/(2*dz))
    B[1:-1,1:-1,2]-=dt*(E[2:,1:-1,1]-E[:-2,1:-1,1])/(2*dx)
    E[1:-1,1:-1,0]+=dt*(-(B[1:-1,2:,1]-B[1:-1,:-2,1])/(2*dz) - J[1:-1,1:-1,0])
    E[1:-1,1:-1,1]+=dt*((B[:-2,1:-1,2]-B[2:,1:-1,2])/(2*dx)-(B[1:-1,:-2,0]-B[1:-1,2:,0])/(2*dz)-J[1:-1,1:-1,1])
    E[1:-1,1:-1,2]+=dt*((B[2:,1:-1,1]-B[:-2,1:-1,1])/(2*dx)-J[1:-1,1:-1,2])
    return E,B

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
        'Bx': 0.15, 'By': 0.02, 'Bz': 0.15,
        'Jx': 0.075, 'Jy': 0.075, 'Jz': 0.075,
        'Ex': 0.05, 'Ey': 0.075, 'Ez': 0.05,
        'Ay': 2.0,  'Bpol': 2.0
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
print("Performing Quiet Start procedure...")
continue_hit_counter_array = np.array([0], dtype=np.int64)
# ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
# QUIET START: Bフィールドと粒子ドリフトが設定された状態で実行
# ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
if N_total > 0:
    # Quiet Startでは、熱運動のみの粒子分布から生じる電荷の偏りを補正する
    # ドリフト速度を含まない熱速度分布を仮定した速度場vel_thermalを作成
    vel_thermal = np.zeros_like(vel)
    vel_thermal[:N_e, :] = np.random.normal(0, v_the, (N_e, 3))
    vel_thermal[N_e:, :] = np.random.normal(0, v_thi, (N_i, 3))

    _, _, _, rho_init = push_and_deposit_species(pos, vel_thermal, charge, mass, np.zeros_like(E), B, J_plasma, rho, wp, 0, LX, LZ, dx, dz, NX, NZ)
    if np.sum(np.abs(rho_init)) > 1e-9:
        phi_initial = solve_poisson_dirichlet(rho_init, dx, dz)
        E_initial_x, E_initial_z = np.gradient(phi_initial, dx, dz)
        E[:, :, 0] = -E_initial_x
        E[:, :, 2] = -E_initial_z
print("Quiet Start complete.")


energies = []
J_e, J_i = np.zeros_like(J_plasma), np.zeros_like(J_plasma)
rho_e, rho_i = np.zeros_like(rho), np.zeros_like(rho)

print("Starting main loop...")
start_time = time.time()
for step in range(N_STEPS + 1):
    t_wce = step * dt_wce

    if step % PLOT_STEPS == 0:
        # プロットとエネルギー計算のロジックは省略（オリジナルコードと同じ）
        pass
        
    if N_total > 0:
        pos[:N_e], vel[:N_e], J_e, rho_e = push_and_deposit_species(pos[:N_e], vel[:N_e], charge[:N_e], mass[:N_e], E, B, J_e, rho_e, wp, dt_wpe, LX, LZ, dx, dz, NX, NZ)
        pos[N_e:], vel[N_e:], J_i, rho_i = push_and_deposit_species(pos[N_e:], vel[N_e:], charge[N_e:], mass[N_e:], E, B, J_i, rho_i, wp, dt_wpe, LX, LZ, dx, dz, NX, NZ)
        
        J_plasma = J_e + J_i
        rho = rho_e + rho_i
        
        J_plasma_smooth = J_plasma.copy()
        for _ in range(NUM_SMOOTHING_PASSES):
            J_plasma_smooth = smooth_current(J_plasma_smooth)
    else:
        J_plasma_smooth = J_plasma

    J_total = J_plasma_smooth + J_ext
    E, B = FDTD_solver(E, B, J_total, dt_wpe, dx, dz)
    
    Ay -= E[:, :, 1] * dt_wpe
    
    # オリジナルコードのPoisson補正
    if step > 0 and step % 5 == 0 and N_total > 0:
        div_E = np.zeros((NX, NZ))
        div_E[1:-1, 1:-1] = ((E[2:, 1:-1, 0] - E[:-2, 1:-1, 0]) / (2 * dx) +
                             (E[1:-1, 2:, 2] - E[1:-1, :-2, 2]) / (2 * dz))
        error_source = div_E - rho
        phi_corr = solve_poisson_dirichlet(-error_source, dx, dz)
        
        E_corr_x = np.zeros_like(E[:, :, 0])
        E_corr_z = np.zeros_like(E[:, :, 2])
        E_corr_x[1:-1, :] = (phi_corr[2:, :] - phi_corr[:-2, :]) / (2 * dx)
        E_corr_z[:, 1:-1] = (phi_corr[:, 2:] - phi_corr[:, :-2]) / (2 * dz)
        
        E[:, :, 0] -= E_corr_x
        E[:, :, 2] -= E_corr_z

    if step % PLOT_STEPS == 0:
        if N_total > 0:
            ke = 0.5 * np.sum(mass[is_active] * np.sum(vel[is_active]**2, axis=1)) * wp
        else:
            ke = 0.0
        be = 0.5 * np.sum(B**2) * dx * dz
        ee = 0.5 * np.sum(E**2) * dx * dz
        energies.append([t_wce, ke, be, ee, ke + be + ee])
        
        active_count = 0
        if N_total > 0:
            half_Lx = LX / 2.0
            # 物理領域内にいる粒子をアクティブとみなす
            active_mask = (pos[:, 0] >= -half_Lx) & (pos[:, 0] <= half_Lx) & \
                          (pos[:, 1] >= 0) & (pos[:, 1] <= LZ)
            active_count = np.sum(active_mask)
        
        elapsed = time.time() - start_time
        eta_str = f"ETA: {(elapsed / step) * (N_STEPS - step):.0f}s" if step > 0 else "ETA: N/A"
        print(f"Step {step}/{N_STEPS} | T_wce={t_wce:.2f} | Particles: {active_count}/{N_total} | E_total={ke+be+ee:.3e} | {eta_str} -> Plotting...")

        # --- 各種プロット出力 ---
        plot_energy_conservation(f"{output_dir}/energy_conservation.png", energies)
        
        filename_diag = os.path.join(output_dir, f"diagnostic_plot_{t_wce:2f}.png")
        create_diagnostic_plot_normalized(filename_diag, t_wce, B, J_plasma, E, Ay, pos, N_e, LX_de, LZ_de, x_vec_de, z_vec_de, x_grid_norm, z_grid_norm)
        
        filename_moments = os.path.join(output_dir, f"plasma_moments_{t_wce:2f}.png")
        plot_plasma_moments(filename_moments, t_wce, rho_e, rho_i, q_e, q_i, LX_de, LZ_de)

print(f"✅ Simulation finished. Total wall time: {time.time() - start_time:.1f}s")
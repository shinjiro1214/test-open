import numpy as np
import matplotlib.pyplot as plt
import time
import os
from numba import jit, prange

print("🚀 Initializing Plain PIC Simulation - Ver. 1.0")

# ==============================================================================
# --- 1. 物理・シミュレーション設定 ---
# ==============================================================================
# --- プラズマ・グリッド設定 ---
MI_ME = 25.0              # イオン/電子の質量比
WPE_WCE = 2.0             # プラズマ周波数 / サイクロトロン周波数 (初期の目安)
T_el_norm = 0.2           # 規格化された電子温度 T_e / (m_e * c^2)
NX, NZ = 129, 65          # グリッド数 (x, z)
LX_de, LZ_de = 51.2, 25.6 # シミュレーション領域のサイズ (電子デバイ長スケール)
N_PTCL_PER_CELL = 0     # 1セルあたりの粒子数
T_MAX_wpe = 20.0         # 最大シミュレーション時間 (プラズマ周波数スケール)

# --- 出力設定 ---
PLOT_INTERVAL_wpe = 2.0   # プロットを出力する時間間隔
NUM_SMOOTHING_PASSES = 8  # 電流密度を平滑化する回数

# ==============================================================================
# --- 2. パラメータ導出と配列準備 (検証用) ---
# ==============================================================================
# --- 物理定数と基本パラメータ ---
c = 1.0
m_e = 1.0
q_e = -1.0
n0 = 1.0
w_pe = 1.0 # 規格化のため
d_e = c / w_pe
LX, LZ = LX_de * d_e, LZ_de * d_e
dx, dz = LX / (NX - 1), LZ / (NZ - 1)
# dtは元の計算式を流用
dt = 0.05 / (c * np.sqrt(1 / dx**2 + 1 / dz**2))

# --- 出力ディレクトリ作成 ---
output_dir = "data_verification_test/pusher_test"
os.makedirs(output_dir, exist_ok=True)

# --- 単一電子の初期化 ---
N_total = 1
N_e = 1
N_i = 0
pos = np.zeros((N_total, 2))
vel = np.zeros((N_total, 3))
charge = np.full(N_total, q_e)
mass = np.full(N_total, m_e)

# 初期位置と初速
pos[0, 0] = 0.0  # x = 0
pos[0, 1] = LZ / 2.0 # z = Lz/2
startz = pos[0, 1]  # z方向の初期位置
v_initial = 0.1 * c
vel[0, :] = [v_initial, 0.0 , 0.0]  # vx=0.1c, vz=vy=0

# --- フィールド配列準備 (磁場のみ設定) ---
E = np.zeros((NX, NZ, 3))
B = np.zeros((NX, NZ, 3))
B0 = 0.2 # 一様磁場の強さ
B[:, :, 1] = B0 # z方向に一様な磁場を印加

# --- ループの準備 (ダミーの配列) ---
J_e = np.zeros((NX, NZ, 3))
rho_e = np.zeros((NX, NZ))
wp = 1.0 # 重みは1でOK
continue_hit_counter_array = np.array([0], dtype=np.int64)

# ==============================================================================
# --- 4. コア計算関数 ---
# ==============================================================================
@jit(nopython=True, cache=True)
def push_and_deposit_species(pos_s, vel_s, charge_s, mass_s, E, B, J_s, rho_s, wp, dt, Lx, Lz, dx, dz, NX, NZ, hit_count_array):
    J_s.fill(0)
    rho_s.fill(0)
    inv_vol = 1.0 / (dx * dz)
    
    for i in range(pos_s.shape[0]):
        # 1. Gather: 粒子位置のフィールドを補間
        ix_f = (pos_s[i, 0] + Lx / 2) / dx
        iz_f = pos_s[i, 1] / dz
        if not (0 <= ix_f < NX - 1 and 0 <= iz_f < NZ - 1):
            hit_count_array[0] += 1
            continue
            
        ix, iz = int(ix_f), int(iz_f)
        wx, wz = ix_f - ix, iz_f - iz
        
        E_p = (E[ix, iz] * (1 - wx) * (1 - wz) + E[ix + 1, iz] * wx * (1 - wz) +
               E[ix, iz + 1] * (1 - wx) * wz + E[ix + 1, iz + 1] * wx * wz)
        B_p = (B[ix, iz] * (1 - wx) * (1 - wz) + B[ix + 1, iz] * wx * (1 - wz) +
               B[ix, iz + 1] * (1 - wx) * wz + B[ix + 1, iz + 1] * wx * wz)

        # 2. Pusher: Boris法で粒子を加速
        q_over_m = charge_s[i] / mass_s[i]
        v_minus = vel_s[i] + q_over_m * E_p * dt / 2.0
        t_vec = q_over_m * B_p * dt / 2.0
        s_vec = 2.0 * t_vec / (1.0 + np.dot(t_vec, t_vec))
        v_prime = v_minus + np.cross(v_minus, t_vec)
        v_plus = v_minus + np.cross(v_prime, s_vec)
        vel_s[i] = v_plus + q_over_m * E_p * dt / 2.0

        # 3. Mover: 粒子を移動
        pos_s[i, 0] += vel_s[i, 0] * dt
        pos_s[i, 1] += vel_s[i, 2] * dt # z方向の移動は速度のz成分(vel_s[i,2])

        # 4. Boundary Conditions: 境界条件を適用
        # x方向: 周期境界
        pos_s[i, 0] = np.mod(pos_s[i, 0] + Lx / 2, Lx) - Lx / 2
        # z方向: 反射境界
        if pos_s[i, 1] > Lz:
            pos_s[i, 1] = 2 * Lz - pos_s[i, 1]
            vel_s[i, 2] *= -1.0
        if pos_s[i, 1] < 0:
            pos_s[i, 1] = -pos_s[i, 1]
            vel_s[i, 2] *= -1.0

        # 5. Scatter: 電流と電荷密度をグリッドに分配
        ix_f_new = (pos_s[i, 0] + Lx / 2) / dx
        iz_f_new = pos_s[i, 1] / dz
        if not (0 <= ix_f_new < NX - 1 and 0 <= iz_f_new < NZ - 1):
            hit_count_array[0] += 1
            continue
            
        ix, iz = int(ix_f_new), int(iz_f_new)
        wx, wz = ix_f_new - ix, iz_f_new - iz
        dwx, dwz = 1 - wx, 1 - wz
        
        q_contrib = charge_s[i] * wp * inv_vol
        rho_s[ix, iz] += q_contrib * dwx * dwz
        rho_s[ix + 1, iz] += q_contrib * wx * dwz
        rho_s[ix, iz + 1] += q_contrib * dwx * wz
        rho_s[ix + 1, iz + 1] += q_contrib * wx * wz
        
        for d in range(3):
            j_p = q_contrib * vel_s[i, d]
            J_s[ix, iz, d] += j_p * dwx * dwz
            J_s[ix + 1, iz, d] += j_p * wx * dwz
            J_s[ix, iz + 1, d] += j_p * dwx * wz
            J_s[ix + 1, iz + 1, d] += j_p * wx * wz
            
    return pos_s, vel_s, J_s, rho_s

@jit(nopython=True, cache=True)
def smooth_current(J_in):
    J_out = J_in.copy()
    for c in range(3): # 3方向(x,y,z)それぞれに適用
        # x方向の1-2-1平滑化
        J_temp = J_out[:, :, c].copy()
        J_temp[1:-1, :] = 0.25 * J_out[:-2, :, c] + 0.5 * J_out[1:-1, :, c] + 0.25 * J_out[2:, :, c]
        J_out[:, :, c] = J_temp
        # z方向の1-2-1平滑化
        J_temp = J_out[:, :, c].copy()
        J_temp[:, 1:-1] = 0.25 * J_out[:, :-2, c] + 0.5 * J_out[:, 1:-1, c] + 0.25 * J_out[:, 2:, c]
        J_out[:, :, c] = J_temp
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

def solve_poisson_fft(rho_data, dx, dz):
    NX_local, NZ_local = rho_data.shape
    rho_k = np.fft.fft2(rho_data)
    kx = 2 * np.pi * np.fft.fftfreq(NX_local, d=dx)
    kz = 2 * np.pi * np.fft.fftfreq(NZ_local, d=dz)
    kx_grid, kz_grid = np.meshgrid(kx, kz, indexing='ij')
    k_sq = kx_grid**2 + kz_grid**2
    k_sq[0, 0] = 1.0 # ゼロ割を回避
    phi_k = -rho_k / k_sq
    phi_k[0, 0] = 0
    return np.real(np.fft.ifft2(phi_k))

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

def create_diagnostic_plot_normalized(filename, t_wpe, B, J, E, Ay, pos, N_e, Lx_de, Lz_de, x_vec_de, z_vec_de, x_grid_norm, z_grid_norm):
    fig, axs = plt.subplots(3, 4, figsize=(22, 12), constrained_layout=True)
    extent = [-Lx_de / 2, Lx_de / 2, 0, Lz_de]

    data_map = {
        'Bx': (B[:, :, 0].T, axs[0, 0]), 'By': (B[:, :, 1].T, axs[0, 1]), 'Bz': (B[:, :, 2].T, axs[0, 2]),
        'Jx': (J[:, :, 0].T, axs[1, 0]), 'Jy': (J[:, :, 1].T, axs[1, 1]), 'Jz': (J[:, :, 2].T, axs[1, 2]),
        'Ex': (E[:, :, 0].T, axs[2, 0]), 'Ey': (E[:, :, 1].T, axs[2, 1]), 'Ez': (E[:, :, 2].T, axs[2, 2]),
    }

    for name, (data, ax) in data_map.items():
        data_to_plot = smooth_for_plot(data)
        vmax = np.max(np.abs(data_to_plot)) if np.max(np.abs(data_to_plot)) > 1e-9 else 1.0
        im = ax.imshow(data_to_plot, origin='lower', extent=extent, aspect='equal', cmap='RdBu_r', vmin=-vmax, vmax=vmax)
        fig.colorbar(im, ax=ax, label=f'{name} value')
        ax.set_title(f'{name} Distribution')
    
    ax_psi = axs[0, 3]; ax_psi.set_title(r'Poloidal Flux $\psi$ from $A_y$')
    vmax_ay = np.max(np.abs(Ay)) if np.max(np.abs(Ay)) > 0 else 1.0
    ax_psi.contour(x_vec_de, z_vec_de, Ay.T, levels=20, colors='k', linewidths=0.8)
    im_ay = ax_psi.imshow(Ay.T, origin='lower', extent=extent, aspect='equal', cmap='viridis', vmin=-vmax_ay, vmax=vmax_ay)
    fig.colorbar(im_ay, ax=ax_psi, label=r'Value')
    
    ax_part = axs[1, 3]; ax_part.set_title('Particle Positions')
    ax_part.plot(pos[N_e:, 0] / d_e, pos[N_e:, 1] / d_e, '.', ms=1, color='red', label='Ions', alpha=0.5)
    ax_part.plot(pos[:N_e, 0] / d_e, pos[:N_e, 1] / d_e, '.', ms=1, color='blue', label='Electrons', alpha=0.5)
    ax_part.legend(markerscale=5, loc='upper right')
    ax_part.set_xlim(extent[0], extent[1]); ax_part.set_ylim(extent[2], extent[3])
    
    ax_helicity = axs[2, 3]; ax_helicity.set_title(r'Poloidal Field Vectors')
    vmax_bpol = np.max(np.sqrt(B[:, :, 0]**2 + B[:, :, 2]**2)) if np.max(np.sqrt(B[:, :, 0]**2 + B[:, :, 2]**2)) > 0 else 1.0
    ax_helicity.imshow(np.sqrt(B[:, :, 0]**2 + B[:, :, 2]**2).T, origin='lower', extent=extent, aspect='equal', cmap='magma', vmin=0, vmax=vmax_bpol)
    skip = 8
    ax_helicity.quiver(x_grid_norm[::skip, ::skip], z_grid_norm[::skip, ::skip], B[::skip, ::skip, 0], B[::skip, ::skip, 2],
                       color='lime', scale=vmax_bpol * 20 if vmax_bpol > 0 else 1, width=0.005)
                       
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

    times = energies_np[:,0]
    ke = energies_np[:,1]
    be = energies_np[:,2]
    ee = energies_np[:,3]
    total_e = energies_np[:,4]
    initial_total_e = total_e[0] if total_e[0] > 0 else 1.0

    plt.figure(figsize=(10,6))
    plt.plot(times, (ke - ke[0]) / initial_total_e, label='$\\Delta KE$')
    plt.plot(times, (be - be[0]) / initial_total_e, label='$\\Delta BE$')
    plt.plot(times, (ee - ee[0]) / initial_total_e, label='$\\Delta EE$')
    plt.plot(times, (total_e - initial_total_e) / initial_total_e, 'k--', lw=2, label='$\\Delta E_{Total}$')
    
    plt.title('Energy Conservation Check'); plt.xlabel('Time $[1/\omega_{pe}]$'); plt.ylabel('Energy Change / Initial Total E')
    plt.grid(True); plt.legend()
    max_fluctuation = np.max(np.abs((total_e - initial_total_e) / initial_total_e))
    plt.ylim(-max(0.05, max_fluctuation * 1.5), max(0.05, max_fluctuation * 1.5))
    
    plt.savefig(filename); plt.close()

# ==============================================================================
# --- 5. クワイエット・スタートとメインループ ---
# ==============================================================================
# --- 検証用メインループ (最終確定版) ---
print("🚀 Starting Pusher Verification Test...")
history = []
N_STEPS = int(T_MAX_wpe / dt)

for step in range(N_STEPS + 1):
    t_wpe = step * dt
    
    # エネルギーと位置を記録
    ke = 0.5 * mass[0] * np.sum(vel[0]**2)
    history.append([t_wpe, pos[0, 0], pos[0, 1], ke]) # x,z位置と運動エネルギー
    
    # 粒子を1ステップ進める (Scatter部分は使わないが、Pusherを呼び出す)
    pos, vel, _, _ = push_and_deposit_species(pos, vel, charge, mass, E, B, J_e, rho_e, wp, dt, LX, LZ, dx, dz, NX, NZ, continue_hit_counter_array)

history = np.array(history)

# --- 理論値の計算 (最終確定版) ---
# 磁場に垂直な速度はx方向の初速v_initialのみ
v_perp = v_initial 
w_ce_theory = np.abs(q_e * B0 / m_e)
r_g_theory = v_perp / w_ce_theory # 半径は0.5になるはず
print(f"Theoretical Gyro-radius: {r_g_theory:.4f}")
print(f"Initial Kinetic Energy: {history[0, 3]:.4e}")
print(f"Final Kinetic Energy:   {history[-1, 3]:.4e}")
print(f"start position: {history[0, 1]:.4e}, {history[0, 2]:.4e}")
print(f"end position:   {history[-1, 1]:.4e}, {history[-1, 2]:.4e}")

# --- 結果のプロット (最終確定版) ---
fig, axs = plt.subplots(1, 2, figsize=(14, 6))

# 軌跡
axs[0].plot(history[:, 1], history[:, 2], 'b-', lw=2, label='Simulation') 
axs[0].plot(history[0, 1], history[0, 2], 'go', ms=8, label='Start')
axs[0].plot(history[-1, 1], history[-1, 2], 'rs', ms=8, label='End')

# 理論円の中心と半径
center_x = 0.0
# 粒子は-z方向に曲がるため、中心は初期位置より下
center_z = history[0, 2] - r_g_theory 
circle = plt.Circle((center_x, center_z), r_g_theory, color='k', fill=False, lw=2, linestyle='--', label='Theory')
axs[0].add_artist(circle)

axs[0].set_title('Particle Trajectory (x-z plane)')
axs[0].set_xlabel('x position'); axs[0].set_ylabel('z position')
axs[0].set_aspect('equal'); axs[0].grid(True); axs[0].legend()

# エネルギー保存
axs[1].plot(history[:, 0], (history[:, 3] - history[0, 3]) / history[0, 3])
axs[1].set_title('Kinetic Energy Conservation')
axs[1].set_xlabel('Time'); axs[1].set_ylabel('Relative Change in KE')
axs[1].grid(True)

plt.tight_layout()
plt.savefig(os.path.join(output_dir, "pusher_test_result.png"))
plt.show()

# --- ここでプログラムを終了させる ---
import sys
sys.exit()
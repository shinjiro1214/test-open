import numpy as np
import matplotlib.pyplot as plt
import time
import os
from numba import jit
from scipy.fft import fft2, ifft2, fftfreq

print("🚀 Initializing Wave Test PIC Simulation - Ver. 2.0 (Yee FDTD Integrated)")

# ==============================================================================
# --- 1. 物理・シミュレーション設定 (波動テスト用に変更) ---
# ==============================================================================
MI_ME = 1000  # イオンの質量を電子と同じにし、純粋な電子の応答をみる
WPE_WCE = 6.0 # PDFのTable 3.4を参考
T_el_norm = (0.1 * 1.0)**2 # v_th/c = 0.1 より T_el = (v_th * c)^2 / (k_B=1)
NX, NZ = 33, 257 # PDFのTable 3.4 を参考に (LJ, LI) -> (NX, NZ)
LX_de, LZ_de = 32.0 * 1.2, 25.60 * 1.2 # PDFのTable 3.4 の Δ/λ_De=1.2 を参考にグリッドサイズを計算
N_PTCL_PER_CELL = 500 # 粒子数を増やしてノイズを低減
T_MAX_wce = 1.0 # シミュレーション時間 (w_ce^-1 単位)
PLOT_INTERVAL_wce = 0.1 # プロット間隔 (w_ce^-1 単位)
NUM_SMOOTHING_PASSES = 4 # スムージング回数

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

print("\n--- Grid and Debye Length Check ---")
lambda_de = v_the / w_pe
print(f"Grid size dz         = {dz/d_e:.4f} [d_e]")
print(f"Debye length lambda_De = {lambda_de/d_e:.4f} [d_e]")

if dz > lambda_de:
    print("\n\033[91m[WARNING] Grid size (dz) is LARGER than the Debye length (lambda_De).")
    print("This will cause strong numerical heating and invalidate the simulation results.")
    print(f"To fix this, NZ must be larger than {int(LZ_de / (lambda_de/d_e)) + 1}.\033[0m")
else:
    print("\n\033[92m[OK] Grid size (dz) is smaller than the Debye length (lambda_De).\033[0m")
print("-------------------------------------\n")

# 時間ステップはCFL条件を厳密に満たすように設定
dt = 0.5 / (c * np.sqrt(1 / dx**2 + 1 / dz**2))
N_STEPS = int(T_MAX_wce / (dt * w_ce))
PLOT_STEPS = int(PLOT_INTERVAL_wce / (dt * w_ce)) if PLOT_INTERVAL_wce > 0 else N_STEPS + 1

print(f"Grid: {NX}x{NZ}, dt*w_ce: {dt*w_ce:.4f}, Total Steps: {N_STEPS}")

output_dir = "data_tests/data_wave_test_mime1000_YeeFDTD_final_ix"
os.makedirs(output_dir, exist_ok=True)

# --- フィールド配列 ---
E = np.zeros((NX, NZ, 3))
B = np.zeros((NX, NZ, 3)) # 粒子計算・診断用 (中心格子)

B0x_magnitude = w_ce * m_e / np.abs(q_e)
B[:, :, 0] += B0x_magnitude
print(f"✅ Applied background magnetic field B0x = {B0x_magnitude:.4f}")

By_yee = np.zeros((NX, NZ - 1)) # Yee格子上の磁場 (スタッガード格子)
J_plasma = np.zeros((NX, NZ, 3))
J_ext = np.zeros((NX, NZ, 3))
rho = np.zeros((NX, NZ))
Ay = np.zeros((NX, NZ))

x_vec = np.linspace(-LX / 2, LX / 2, NX)
z_vec = np.linspace(0, LZ, NZ) # Exの座標
z_vec_by = np.linspace(dz / 2, LZ - dz / 2, NZ - 1) # Byの座標
x_grid, z_grid = np.meshgrid(x_vec, z_vec, indexing='ij')

x_vec_de = x_vec / d_e
z_vec_de = z_vec / d_e
x_grid_norm, z_grid_norm = np.meshgrid(x_vec_de, z_vec_de, indexing='ij')

# ==============================================================================
# --- 3. 初期条件：O-Mode 平面波 ---
# ==============================================================================
print("Setting up initial condition: O-Mode wave...")

lambda_z = LZ / 4.0
k_z = 2.0 * np.pi / lambda_z
E0 = 0.05

omega_sq = w_pe**2 + (c * k_z)**2
omega = np.sqrt(omega_sq)
v_ph = omega / k_z if k_z > 0 else c
B0 = E0 / v_ph

print(f"Wave params: k_z={k_z:.3f}, omega/w_pe={omega/w_pe:.3f}, v_ph/c={v_ph/c:.3f}")

# Exは中心格子(z_vec)上で定義
E[:, :, 0] = E0 * np.cos(k_z * z_grid)

# B(z, t=-dt/2) = B0 * cos(k*z - w*(-dt/2)) = B0 * cos(k*z + w*dt/2)
time_for_b_init = -dt / 2.0
_, z_grid_by = np.meshgrid(x_vec, z_vec_by, indexing='ij')
By_yee = B0 * np.cos(k_z * z_grid_by - omega * time_for_b_init)

# 診断用のB(t=0)も念のため初期化
B[:, :, 1] = B0 * np.cos(k_z * z_grid)


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

if N_total > 0:
    # 粒子を均一に配置
    pos[:, 0] = np.random.uniform(-LX / 2, LX / 2, N_total)
    pos[:, 1] = np.random.uniform(0, LZ, N_total)

    # --- 電子の初期化 ---
    # まず熱速度分布を与える
    vel[:N_e, :] = np.random.normal(0, v_the, (N_e, 3))
    charge[:N_e] = q_e
    mass[:N_e] = m_e

    # <font color="red">【重要修正】Oモード波と矛盾しない電子の体系的な初速を追加</font>
    # vx(z) = (q_e * E_x) / (i * m_e * ω) の関係から、位相が90度ずれた速度を与える
    # Ex = E0 * cos(kz), vx = V0 * sin(kz)
    V0 = (q_e * E0) / (m_e * omega)
    # 各電子の位置 z に応じた速度を計算して加える
    electron_z_positions = pos[:N_e, 1]
    vel[:N_e, 0] += V0 * np.sin(k_z * electron_z_positions)


    # --- イオンの初期化 (イオンは重いので、波からの影響は無視して熱運動のみ) ---
    vel[N_e:, :] = np.random.normal(0, v_thi, (N_i, 3))
    charge[N_e:] = q_i
    mass[N_e:] = m_i
    
    wp = (n0 * LX * LZ) / N_total
    print(f"Particles initialized with self-consistent velocity: {N_e} electrons, {N_i} ions.")
else:
    wp = 0
energies = []

# ==============================================================================
# --- 5. コア計算関数 ---
# ==============================================================================
@jit(nopython=True, cache=True)
def initial_velocity_rewind(pos_s, vel_s, charge_s, mass_s, E, B, dt, Lx, Lz, dx, dz, NX, NZ):
    half_Lx = Lx / 2.0
    vel_initial = vel_s.copy()
    for i in range(pos_s.shape[0]):
        ix_f = (pos_s[i, 0] + half_Lx) / dx
        iz_f = pos_s[i, 1] / dz
        ix = int(ix_f)
        iz = int(iz_f)
        wx = ix_f - ix
        wz = iz_f - iz
        dwx, dwz = 1.0 - wx, 1.0 - wz
        ix_p1 = (ix + 1) % NX
        iz_p1 = (iz + 1) % NZ
        E_p = (E[ix, iz] * dwx * dwz + E[ix_p1, iz] * wx * dwz + E[ix, iz_p1] * dwx * wz + E[ix_p1, iz_p1] * wx * wz)
        B_p = (B[ix, iz] * dwx * dwz + B[ix_p1, iz] * wx * dwz + B[ix, iz_p1] * dwx * wz + B[ix_p1, iz_p1] * wx * wz)
        q_over_m = charge_s[i] / mass_s[i]
        accel = q_over_m * (E_p + np.cross(vel_initial[i], B_p))
        vel_s[i] = vel_initial[i] - accel * dt / 2.0
    return vel_s

@jit(nopython=True, cache=True)
def deposit_charge_only(pos_s, charge_s, rho_s, wp, Lx, Lz, dx, dz, NX, NZ):
    rho_s.fill(0)
    inv_vol = 1.0 / (dx * dz)
    half_Lx = Lx / 2.0
    for i in range(pos_s.shape[0]):
        ix_f = (pos_s[i, 0] + half_Lx) / dx
        iz_f = pos_s[i, 1] / dz
        ix = int(ix_f)
        iz = int(iz_f)
        if not (0 <= ix < NX - 1 and 0 <= iz < NZ - 1): continue
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
        x_old, z_old = pos_s[i, 0], pos_s[i, 1]
        ix_f = (x_old + half_Lx) / dx
        iz_f = z_old / dz
        ix, iz = int(ix_f), int(iz_f)
        wx, wz = ix_f - ix, iz_f - iz
        E_p = (E[ix%NX, iz%NZ]*(1-wx)*(1-wz) + E[(ix+1)%NX, iz%NZ]*wx*(1-wz) + E[ix%NX, (iz+1)%NZ]*(1-wx)*wz + E[(ix+1)%NX, (iz+1)%NZ]*wx*wz)
        B_p = (B[ix%NX, iz%NZ]*(1-wx)*(1-wz) + B[(ix+1)%NX, iz%NZ]*wx*(1-wz) + B[ix%NX, (iz+1)%NZ]*(1-wx)*wz + B[(ix+1)%NX, (iz+1)%NZ]*wx*wz)
        q_over_m = charge_s[i] / mass_s[i]
        v_minus = vel_s[i] + q_over_m * E_p * (dt / 2.0)
        t_vec = q_over_m * B_p * (dt / 2.0)
        t_mag_sq = np.dot(t_vec, t_vec)
        s_vec = 2.0 * t_vec / (1.0 + t_mag_sq)
        v_prime = v_minus + np.cross(v_minus, t_vec)
        v_plus = v_minus + np.cross(v_prime, s_vec)
        vel_s[i] = v_plus + q_over_m * E_p * (dt / 2.0)
        pos_s[i, 0] += vel_s[i, 0] * dt
        pos_s[i, 1] += vel_s[i, 2] * dt
        if pos_s[i, 0] > half_Lx: pos_s[i, 0] -= Lx
        elif pos_s[i, 0] < -half_Lx: pos_s[i, 0] += Lx
        if pos_s[i, 1] > Lz: pos_s[i, 1] -= Lz
        elif pos_s[i, 1] < 0: pos_s[i, 1] += Lz
        q_contrib = charge_s[i] * wp * inv_vol
        x_new, z_new = pos_s[i, 0], pos_s[i, 1]
        ix_f_new = (x_new + half_Lx) / dx; iz_f_new = z_new / dz
        ix_new, iz_new = int(ix_f_new), int(iz_f_new)
        wx_new, wz_new = ix_f_new - ix_new, iz_f_new - iz_new
        rho_s[(ix_new+0)%NX, (iz_new+0)%NZ] += q_contrib*(1-wx_new)*(1-wz_new)
        rho_s[(ix_new+1)%NX, (iz_new+0)%NZ] += q_contrib*wx_new*(1-wz_new)
        rho_s[(ix_new+0)%NX, (iz_new+1)%NZ] += q_contrib*(1-wx_new)*wz_new
        rho_s[(ix_new+1)%NX, (iz_new+1)%NZ] += q_contrib*wx_new*wz_new
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

def density_decomposition_correction_fft(J_in, rho_new, rho_old, dt, dx, dz, NX, NZ):
    kx=2*np.pi*fftfreq(NX,d=dx); kz=2*np.pi*fftfreq(NZ,d=dz); kx_grid,kz_grid=np.meshgrid(kx,kz,indexing='ij')
    J_x_plus_1=np.roll(J_in[:,:,0],-1,axis=0); J_x_minus_1=np.roll(J_in[:,:,0],1,axis=0)
    J_z_plus_1=np.roll(J_in[:,:,2],-1,axis=1); J_z_minus_1=np.roll(J_in[:,:,2],1,axis=1)
    div_J=(J_x_plus_1-J_x_minus_1)/(2*dx)+(J_z_plus_1-J_z_minus_1)/(2*dz)
    d_rho_dt=(rho_new-rho_old)/dt; S=div_J+d_rho_dt; k_sq=kx_grid**2+kz_grid**2; k_sq[0,0]=1.0
    S_k=fft2(S); psi_k=-S_k/k_sq; psi_k[0,0]=0.0
    grad_psi_x_k=1j*kx_grid*psi_k; grad_psi_z_k=1j*kz_grid*psi_k
    grad_psi=np.zeros_like(J_in); grad_psi[:,:,0]=np.real(ifft2(grad_psi_x_k)); grad_psi[:,:,2]=np.real(ifft2(grad_psi_z_k))
    return J_in-grad_psi

@jit(nopython=True, cache=True)
def smooth_current(J_in):
    J_out=J_in.copy()
    for c in range(3):
        J_temp=J_out[:,:,c].copy(); J_temp[1:-1,:]=0.25*J_out[:-2,:,c]+0.5*J_out[1:-1,:,c]+0.25*J_out[2:,:,c]; J_out[:,:,c]=J_temp
        J_temp=J_out[:,:,c].copy(); J_temp[:,1:-1]=0.25*J_out[:,:-2,c]+0.5*J_out[:,1:-1,c]+0.25*J_out[:,2:,c]; J_out[:,:,c]=J_temp
    return J_out

@jit(nopython=True, cache=True)
def FDTD_Yee_solver(E, By_yee, J, dt, dz):
    """
    【新実装】Yee FDTD ソルバー (2D対応版)
    Ex と By のみを更新するO-modeに特化したソルバー。
    """
    # --- Bの更新 (t -> t+dt/2) ---
    # ∂By/∂t = -∂Ex/∂z
    # By_yee(i, j) は Ex(i, j+1) と Ex(i, j) の差で決まる
    dEx_dz = (E[:, 1:, 0] - E[:, :-1, 0]) / dz
    By_yee += -dt * dEx_dz

    # --- Eの更新 (t+dt/2 -> t+dt) ---
    # ∂Ex/∂t = -∂By/∂z - Jx
    # Ex(i, j) は By_yee(i, j) と By_yee(i, j-1) の差で決まる
    # 内部点
    dBy_dz_inner = (By_yee[:, 1:] - By_yee[:, :-1]) / dz
    E[:, 1:-1, 0] += dt * (-dBy_dz_inner - J[:, 1:-1, 0])
    
    # 境界条件 (Periodic in Z)
    # Ex(i, 0) の更新には By_yee(i, 0) と By_yee(i, -1) が必要
    dBy_dz_bound = (By_yee[:, 0] - By_yee[:, -1]) / dz
    E[:, 0, 0] += dt * (-dBy_dz_bound - J[:, 0, 0])
    
    # 周期境界を適用
    E[:, -1, 0] = E[:, 0, 0]
    
    return E, By_yee

@jit(nopython=True, cache=True)
def interpolate_b_from_yee(By_yee, B_out, NX, NZ):
    """
    Yee格子の磁場(By_yee)を、粒子計算で使うための中心格子(B_out)に補間する。
    """
    # 内部点
    for i in range(NX):
        for j in range(1, NZ - 1):
            B_out[i, j, 1] = 0.5 * (By_yee[i, j] + By_yee[i, j - 1])
    
    # 境界 (Periodic)
    for i in range(NX):
        B_out[i, 0, 1] = 0.5 * (By_yee[i, 0] + By_yee[i, -1])
        B_out[i, -1, 1] = B_out[i, 0, 1]
        
    return B_out

@jit(nopython=True, cache=True)
def smooth_for_plot(field_2d):
    out=field_2d.copy()
    for _ in range(2):
        temp=out.copy(); temp[1:-1,:]=0.25*out[:-2,:]+0.5*out[1:-1,:]+0.25*out[2:,:]; out=temp.copy()
        temp[:,1:-1]=0.25*out[:,:-2]+0.5*out[:,1:-1]+0.25*out[:,2:]; out=temp
    return out

def create_diagnostic_plot_normalized(filename, t_wce, B, J, E, Ay, pos, N_e, Lx_de, Lz_de, x_vec_de, z_vec_de, x_grid_norm, z_grid_norm):
    fig, axs = plt.subplots(3, 4, figsize=(22, 12), constrained_layout=True)
    fig.suptitle(f'Time($omega_{{ce}}t$) = {t_wce:.2f}', fontsize=16, y=1.02)
    extent = [-Lx_de / 2, Lx_de / 2, 0, Lz_de]
    data_map = {
        'Bx': (B[:, :, 0].T, axs[0, 0]), 'By': (B[:, :, 1].T, axs[0, 1]), 'Bz': (B[:, :, 2].T, axs[0, 2]),
        'Jx': (J[:, :, 0].T, axs[1, 0]), 'Jy': (J[:, :, 1].T, axs[1, 1]), 'Jz': (J[:, :, 2].T, axs[1, 2]),
        'Ex': (E[:, :, 0].T, axs[2, 0]), 'Ey': (E[:, :, 1].T, axs[2, 1]), 'Ez': (E[:, :, 2].T, axs[2, 2]),
    }
    color_limits = {
        'Bx': 0.002, 'By': 0.01, 'Bz': 0.002,
        'Jx': 0.5, 'Jy': 0.005, 'Jz': 0.1,
        'Ex': 0.05, 'Ey': 0.002, 'Ez': 0.1,
        'Ay': 1.0,  'Bpol': 1.0
    }
    for name, (data, ax) in data_map.items():
        data_to_plot = smooth_for_plot(data)
        vmax = color_limits.get(name, np.max(np.abs(data_to_plot)) if np.max(np.abs(data_to_plot)) > 1e-9 else 1.0)
        im = ax.imshow(data_to_plot, origin='lower', extent=extent, aspect='equal', cmap='RdBu_r', vmin=-vmax, vmax=vmax)
        fig.colorbar(im, ax=ax, label=f'{name} value')
        ax.set_title(f'{name} Distribution')
    ax_psi = axs[0, 3]; ax_psi.set_title(r'Poloidal Flux $\psi$ from $A_y$')
    vmax_ay = color_limits.get('Ay', np.max(np.abs(Ay)) if np.max(np.abs(Ay)) > 0 else 1.0)
    ax_psi.contour(x_vec_de, z_vec_de, Ay.T, levels=20, colors='k', linewidths=0.8)
    im_ay = ax_psi.imshow(Ay.T, origin='lower', extent=extent, aspect='equal', cmap='viridis', vmin=-vmax_ay, vmax=vmax_ay)
    fig.colorbar(im_ay, ax=ax_psi, label=r'Value')
    ax_part = axs[1, 3]; ax_part.set_title('Particle Positions')
    if N_total > 0:
        ax_part.plot(pos[N_e:, 0] / d_e, pos[N_e:, 1] / d_e, '.', ms=1, color='red', label='Ions', alpha=0.5)
        ax_part.plot(pos[:N_e, 0] / d_e, pos[:N_e, 1] / d_e, '.', ms=1, color='blue', label='Electrons', alpha=0.5)
        ax_part.legend(markerscale=5, loc='upper right')
    ax_part.set_xlim(extent[0], extent[1]); ax_part.set_ylim(extent[2], extent[3])
    ax_helicity = axs[2, 3]; ax_helicity.set_title(r'Poloidal Field Vectors')
    B_pol_mag = np.sqrt(B[:, :, 0]**2 + B[:, :, 2]**2)
    vmax_bpol = color_limits.get('Bpol', np.max(B_pol_mag) if np.max(B_pol_mag) > 0 else 1.0)
    ax_helicity.imshow(B_pol_mag.T, origin='lower', extent=extent, aspect='equal', cmap='magma', vmin=0, vmax=vmax_bpol)
    skip = 8
    ax_helicity.quiver(x_grid_norm[::skip, ::skip], z_grid_norm[::skip, ::skip], B[::skip, ::skip, 0], B[::skip, ::skip, 2],color='lime', scale=vmax_bpol * 20 if vmax_bpol > 0 else 1, width=0.005)
    for ax in axs.flat:
        ax.set_xlabel('x [$d_e$]'); ax.set_ylabel('z [$d_e$]')
    plt.savefig(filename, dpi=150); plt.close(fig)

def plot_energy_conservation(filename, energies):
    energies_np = np.array(energies)
    if len(energies_np) < 2: return
    times = energies_np[:, 0]
    ke, be, ee, total_e = energies_np[:, 1], energies_np[:, 2], energies_np[:, 3], energies_np[:, 4]
    initial_total_e = total_e[0] if total_e[0] > 0 else 1.0
    delta_ke_rel = (ke - ke[0]) / initial_total_e
    delta_be_rel = (be - be[0]) / initial_total_e
    delta_ee_rel = (ee - ee[0]) / initial_total_e
    delta_total_rel = (total_e - initial_total_e) / initial_total_e
    plt.figure(figsize=(10,6))
    plt.plot(times, delta_ke_rel, label='$\\Delta KE$')
    plt.plot(times, delta_be_rel, label='$\\Delta BE$')
    plt.plot(times, delta_ee_rel, label='$\\Delta EE$')
    plt.plot(times, delta_total_rel, 'k--', lw=2, label='$\\Delta E_{Total}$')
    plt.title('Energy Conservation Check'); plt.xlabel('Time [$omega_{ce}^{-1}$]'); plt.ylabel('Energy Change / Initial Total E')
    plt.grid(True); plt.legend()
    max_fluctuation = max([np.max(np.abs(delta)) for delta in [delta_ke_rel, delta_be_rel, delta_ee_rel, delta_total_rel]] if len(times) > 1 else [0])
    plot_range = max(0.05, max_fluctuation * 1.5)
    plt.ylim(-plot_range, plot_range)
    plt.savefig(filename); plt.close()
    
def create_zt_diagram(filename, plot_data, z_coords_de, k, omega, c, de):
    if not plot_data:
        print("z-t diagram: No data to plot."); return
    fig, ax = plt.subplots(figsize=(8, 7)); times = np.array([d['time'] for d in plot_data])
    v_ph = omega / k; v_g = c**2 / v_ph; wavelength_de = (2 * np.pi / k) / de
    colors = plt.cm.viridis(np.linspace(0.1, 0.9, len(times)))
    plot_amplitude = (times.max() - times.min()) / (len(times) * 1.5)
    for i, data_point in enumerate(plot_data):
        t = data_point['time']; By_data = data_point['By']
        max_abs_by = np.max(np.abs(By_data)); By_normalized = By_data / max_abs_by if max_abs_by > 1e-9 else By_data
        y_display = t + By_normalized * plot_amplitude
        z_center_de = (v_g * t) / de
        z_solid_start_de = z_center_de - wavelength_de / 2; z_solid_end_de = z_center_de + wavelength_de / 2
        solid_mask = (z_coords_de >= z_solid_start_de) & (z_coords_de <= z_solid_end_de)
        ax.plot(z_coords_de, y_display, color=colors[i], ls=(0, (5, 5)), lw=2.0)
        ax.plot(z_coords_de[solid_mask], y_display[solid_mask], color=colors[i], lw=2.5)
    z_ph_line_theory = v_ph * times
    ax.plot(z_ph_line_theory / de, times, 'k--', lw=1.5, label=f'Theoretical $v_{{ph}}$')
    ax.set_xlabel('$z  /  d_e$'); ax.set_ylabel('Time [$omega_{pe}^{-1}$]'); ax.set_xlim(z_coords_de.min(), z_coords_de.max())
    ax.set_ylim(times.min() - plot_amplitude * 2, times.max() + plot_amplitude * 2)
    ax.legend(); ax.grid(alpha=0.3); ax.set_title('O-Mode Wave Propagation ($z-t$ Diagram)')
    plt.tight_layout(); plt.savefig(filename, dpi=150); plt.close(fig)
    print(f"✅ z-t diagram saved to {filename}")    

# ==============================================================================
# --- 5. クワイエット・スタートとメインループ (イオンを考慮) ---
# ==============================================================================
print("Rewinding B-field to t=-dt/2 for Yee FDTD...")
# B(t=-dt/2) = B(t=0) - (dt/2)*∂B/∂t = B(t=0) + (dt/2)*∂Ex/∂z
dEx_dz_init = (E[:, 1:, 0] - E[:, :-1, 0]) / dz
By_yee += 0.5 * dt * dEx_dz_init

if N_total > 0:
    rho_e_initial = deposit_charge_only(pos[:N_e], charge[:N_e], np.zeros_like(rho), wp, LX, LZ, dx, dz, NX, NZ)
    rho_i_initial = deposit_charge_only(pos[N_e:], charge[N_e:], np.zeros_like(rho), wp, LX, LZ, dx, dz, NX, NZ)
    rho_old = rho_e_initial + rho_i_initial
    # 粒子速度を t=0 -> t=-dt/2 へ後退
    B = interpolate_b_from_yee(By_yee, B, NX, NZ) # t=-dt/2 の磁場を補間
    vel[:N_e] = initial_velocity_rewind(pos[:N_e], vel[:N_e], charge[:N_e], mass[:N_e], E, B, dt, LX, LZ, dx, dz, NX, NZ)
    vel[N_e:] = initial_velocity_rewind(pos[N_e:], vel[N_e:], charge[N_e:], mass[N_e:], E, B, dt, LX, LZ, dx, dz, NX, NZ)
else:
    rho_old = np.zeros((NX, NZ))


# スナップショットを撮りたい時間 [w_pe^-1 単位]
T_MAX_wpe = T_MAX_wce / w_ce * w_pe
snapshot_times_wpe = np.linspace(0, T_MAX_wpe * 0.8, 5) # 8割の時間までで5枚撮る
zt_plot_data = []
snapshot_idx_to_capture = 0

print(f"z-t diagram snapshots will be taken around t*w_pe = {np.round(snapshot_times_wpe, 2)}")


print("Starting main loop...")
start_time = time.time()

for step in range(N_STEPS + 1):
    t_wce = step * dt * w_ce

    # 診断・粒子プッシュ用の中心格子磁場BをYee格子By_yeeから補間
    # (t-dt/2) -> t
    B = interpolate_b_from_yee(By_yee, B, NX, NZ)

    if N_total > 0:
        pos[:N_e], vel[:N_e], J_e, rho_e = push_and_deposit_species(pos[:N_e], vel[:N_e], charge[:N_e], mass[:N_e], E, B, wp, dt, LX, LZ, dx, dz, NX, NZ)
        pos[N_e:], vel[N_e:], J_i, rho_i = push_and_deposit_species(pos[N_e:], vel[N_e:], charge[N_e:], mass[N_e:], E, B, wp, dt, LX, LZ, dx, dz, NX, NZ)
        J_plasma = J_e + J_i
        rho_new = rho_e + rho_i
        J_plasma = density_decomposition_correction_fft(J_plasma, rho_new, rho_old, dt, dx, dz, NX, NZ)
        rho_old = rho_new.copy()
        J_plasma_smooth = J_plasma.copy()
        for _ in range(NUM_SMOOTHING_PASSES):
            J_plasma_smooth = smooth_current(J_plasma_smooth)
    else:
        J_plasma_smooth = J_plasma
        rho_new = np.zeros_like(rho)
        rho_old = rho_new.copy()

    J_total = J_plasma_smooth + J_ext
    
    # --- 電磁場を更新 ---
    # E: t -> t+dt
    # B: t-dt/2 -> t+dt/2
    E, By_yee = FDTD_Yee_solver(E, By_yee, J_total, dt, dz)

    if step % PLOT_STEPS == 0 or step == N_STEPS:
        elapsed = time.time() - start_time
        eta_seconds = (elapsed / (step + 1)) * (N_STEPS - step) if step > 0 else 0
        eta_str = f"ETA: {eta_seconds:.0f}s"
        print(f"Step {step}/{N_STEPS} | T_wce={t_wce:.2f} | {eta_str} -> Plotting...")
        
        # --- エネルギー計算 ---
        # 診断用に t+dt/2 の磁場を t+dt の中心格子に補間
        B_diag = interpolate_b_from_yee(By_yee, B.copy(), NX, NZ)
        
        if N_total > 0:
            ke_e = 0.5 * np.sum(mass[:N_e, np.newaxis] * vel[:N_e]**2)
            ke_i = 0.5 * np.sum(mass[N_e:, np.newaxis] * vel[N_e:]**2)
            kinetic_energy = (ke_e + ke_i) * wp
        else:
            kinetic_energy = 0
            
        magnetic_energy = 0.5 * np.sum(B_diag**2) * dx * dz
        electric_energy = 0.5 * np.sum(E**2) * dx * dz
        total_energy = kinetic_energy + magnetic_energy + electric_energy
        energies.append([t_wce, kinetic_energy, magnetic_energy, electric_energy, total_energy])

        filename_diag = os.path.join(output_dir, f"diagnostic_plot_{step:05d}.png")
        create_diagnostic_plot_normalized(filename_diag, t_wce, B_diag, J_plasma_smooth, E, Ay, pos, N_e, LX_de, LZ_de, x_vec_de, z_vec_de, x_grid_norm, z_grid_norm)
        
        filename_energy = os.path.join(output_dir, "energy_conservation.png")
        plot_energy_conservation(filename_energy, energies)
        
        
        t_wpe = t_wce / w_ce * w_pe
        if snapshot_idx_to_capture < len(snapshot_times_wpe):
            if t_wpe >= snapshot_times_wpe[snapshot_idx_to_capture]:
                print(f"📸 Capturing data for z-t diagram at t*w_pe = {t_wpe:.3f}")
                
                # Byの中央スライスを取得
                By_slice = B_diag[NX // 2, :, 1]
                
                # 時間とデータを保存
                zt_plot_data.append({'time': t_wpe, 'By': By_slice.copy()})
                
                # 次のスナップショットへ
                snapshot_idx_to_capture += 1

filename_zt = os.path.join(output_dir, "zt_diagram.png")
create_zt_diagram(filename_zt, zt_plot_data, z_vec_de, k_z, omega, c, d_e)

print(f"✅ Simulation finished. Total wall time: {time.time() - start_time:.1f}s")


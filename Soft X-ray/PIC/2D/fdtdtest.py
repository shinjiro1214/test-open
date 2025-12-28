import numpy as np
import matplotlib.pyplot as plt
import time
import os
import shutil

print("🚀 Initializing Wave Test PIC Simulation - Ver. FINAL (Yee FDTD Method)")

# ==============================================================================
# --- 1. パラメータ設定 ---
# ==============================================================================
NZ = 257  # 電場Exの格子点数
T_MAX_wce = 4.0 # 伝播がはっきりわかるように時間を延長
PLOT_INTERVAL_wce = 0.2

# ==============================================================================
# --- 2. 物理・グリッド設定 ---
# ==============================================================================
c = 1.0
w_pe = 1.0
w_ce = w_pe / 6.0
d_e = c / w_pe

# Yee格子では、EとBの格子がずれている
dz = 1.2 * d_e
LZ = dz * (NZ - 1)
# 時間ステップはCFL条件を厳密に満たす (CFL数 = 1.0)
dt = dz / c
N_STEPS = int(T_MAX_wce / (dt * w_ce))
PLOT_STEPS = int(PLOT_INTERVAL_wce / (dt * w_ce))

output_dir = "data_tests/data_wave_test_YEE_SUCCESS"
if os.path.exists(output_dir): shutil.rmtree(output_dir)
os.makedirs(output_dir)

# --- Yee格子の配列準備 ---
# ExはNZ個の点に、Byはそれらの間に(NZ-1)個配置される
Ex = np.zeros(NZ, dtype=np.float64)
By = np.zeros(NZ - 1, dtype=np.float64)
z_ex = np.linspace(0, LZ, NZ) # Exの座標
z_by = np.linspace(dz / 2, LZ - dz / 2, NZ - 1) # Byの座標

# ==============================================================================
# --- 3. 初期条件 (t=0) ---
# ==============================================================================
print("Setting up initial condition at t=0...")
lambda_z = LZ / 4.0
k_z = 2.0 * np.pi / lambda_z
E0 = 0.05
# 真空中なので v_ph = c, B0 = E0/c
B0 = E0 / c

Ex = E0 * np.cos(k_z * z_ex)
# Byもt=0で初期化。後で半ステップ巻き戻す
By = B0 * np.cos(k_z * z_by)

# ==============================================================================
# --- 4. 【新実装】Yee FDTD ソルバー ---
# ==============================================================================
def FDTD_Yee_solver(Ex, By, dt, dz):
    # --- Bの更新 (t -> t+dt/2) ---
    # B(j)はE(j+1)とE(j)の差で決まる
    # ∂By/∂t = -∂Ex/∂z
    By += -(dt / dz) * (Ex[1:] - Ex[:-1])

    # --- Eの更新 (t+dt/2 -> t+dt) ---
    # E(j)はB(j)とB(j-1)の差で決まる (境界を除く)
    # ∂Ex/∂t = -∂By/∂z
    Ex[1:-1] += -(dt / dz) * (By[1:] - By[:-1])
    
    # 境界条件 (Periodic)
    # Ex[0]の更新には、By[0]とBy[NZ-2](=By[-1])が必要
    Ex[0] += -(dt / dz) * (By[0] - By[-1])
    # Ex[NZ-1]はEx[0]と同じ（周期境界）
    Ex[-1] = Ex[0]
    
    return Ex, By

# ==============================================================================
# --- 5. プロット関数 ---
# ==============================================================================
def create_wave_propagation_plot(filename, t_wce, Ex, By, z_ex, z_by, E0, B0):
    fig, axs = plt.subplots(2, 1, figsize=(12, 8), sharex=True)
    fig.suptitle(f'O-Mode Wave Propagation (Yee FDTD) at Time($\omega_{{ce}}t$) = {t_wce:.3f}', fontsize=16)
    ax = axs[0]
    ax.plot(z_ex / d_e, Ex, 'b-o', markersize=3, label='Ex')
    ax.set_ylabel('$E_x$'); ax.set_ylim(-E0*1.2, E0*1.2); ax.grid(True); ax.set_title('Electric Field ($E_x$)'); ax.legend()
    ax = axs[1]
    ax.plot(z_by / d_e, By, 'r-o', markersize=3, label='By')
    ax.set_ylabel('$B_y$'); ax.set_ylim(-B0*1.2, B0*1.2); ax.grid(True); ax.set_title('Magnetic Field ($B_y$)'); ax.legend()
    ax.set_xlabel('z [$d_e$]'); plt.tight_layout(rect=[0, 0, 1, 0.96]); plt.savefig(filename, dpi=120); plt.close(fig)

# ==============================================================================
# --- 6. 初期条件の補正 (Bをt=-dt/2へ) ---
# ==============================================================================
print("Rewinding B-field to t=-dt/2...")
# B(t=-dt/2) = B(t=0) - (dt/2)*∂B/∂t = B(t=0) + (dt/2)*∂Ex/∂z
By += 0.5 * (dt / dz) * (Ex[1:] - Ex[:-1])

# ==============================================================================
# --- 7. メインループ ---
# ==============================================================================
print("Starting main loop...")
for step in range(N_STEPS + 1):
    if step % PLOT_STEPS == 0 or step == N_STEPS:
        t_wce = step * dt * w_ce
        print(f"Step {step:4d} | T_wce={t_wce:.3f} | Max|Ex|={np.max(np.abs(Ex)):.6f}, Max|By|={np.max(np.abs(By)):.6f}")
        create_wave_propagation_plot(os.path.join(output_dir, f"wave_plot_{step:05d}.png"), t_wce, Ex, By, z_ex, z_by, E0, B0)

    Ex, By = FDTD_Yee_solver(Ex, By, dt, dz)

print(f"✅ Simulation finished.")
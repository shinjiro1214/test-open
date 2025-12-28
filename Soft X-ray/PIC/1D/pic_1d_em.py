import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation

# --- 1. シミュレーションパラメータの設定 ---
N = 10000      # スーパーパーティクル（電子）の数
NX = 401       # グリッドの数
L = 40.0       # シミュレーション領域の長さ (m)
dx = L / (NX - 1) # グリッド間隔 (m)
c = 1.0        # 光速（規格化）
dt = dx / c * 0.5 # 時間ステップ (CFL条件を満たすように設定)
T_MAX = 80.0   # シミュレーションの最大時間 (s)
N_STEPS = int(T_MAX / dt) # 総ステップ数

# --- 物理定数 ---
e = 1.0        # 電子の素電荷（規格化）
m = 1.0        # 電子の質量（規格化）
eps0 = 1.0     # 真空の誘電率（規格化）
n0 = 0.01      # プラズマの平均密度 (今回はまばらなプラズマ)

# --- 2. 初期化 ---
# グリッドの座標
# Yee格子：Eは整数点、Bは半整数点に配置
grid_x_E = np.linspace(0, L, NX)
grid_x_B = np.linspace(dx/2, L - dx/2, NX - 1)

# 粒子の位置と速度(vx, vy, vz)の配列を確保
pos = np.zeros(N)
vel = np.zeros((N, 3)) # (vx, vy, vz)

# スーパーパーティクル1個あたりの電荷・質量
if n0 > 0:
    q_sp = n0 * L / N * (-e)
    m_sp = n0 * L / N * m
else: # 真空の場合
    q_sp = -e
    m_sp = m

# 粒子の初期位置と速度を設定 (一様分布、静止)
pos = np.random.rand(N) * L
vel.fill(0.0)

# --- 電磁場の初期化 ---
# 電場 (Ex, Ey, Ez) と 磁場 (Bx, By, Bz)
Ex = np.zeros(NX)
Ey = np.zeros(NX)
# Bzは半整数点上にある
Bz = np.zeros(NX - 1)

# 電流密度 (Jx, Jy, Jz)
Jx = np.zeros(NX)
Jy = np.zeros(NX)

# 初期電磁波パルス (ガウシアン)
pulse_pos = L / 4.0
pulse_width = L / 10.0
pulse_amp = 1e-3
Ey += pulse_amp * np.exp(-((grid_x_E - pulse_pos) / pulse_width)**2)
# 電磁波の条件 E = cB から初期磁場を設定
Bz += pulse_amp/c * np.exp(-((grid_x_B - pulse_pos) / pulse_width)**2)


# --- 3. メインループの準備 ---
# アニメーション用の設定
fig, ax = plt.subplots()
line, = ax.plot(grid_x_E, Ey)
ax.set_xlim(0, L)
ax.set_ylim(-pulse_amp * 1.5, pulse_amp * 1.5)
ax.set_title("1D EM PIC Simulation (Ey)")
ax.set_xlabel("Position (x)")
ax.set_ylabel("Electric Field (Ey)")
ax.grid(True)

# --- 4. メインループ ---
def update(i_step):
    global Bz, pos, vel, Jy, Ey
    # (A) 磁場(B)を半ステップ更新 (FDTD)
    for j in range(NX - 1):
        # dB/dt = -curl(E)  ->  dBz/dt = dEy/dx
        Bz[j] -= dt * (Ey[j+1] - Ey[j]) / dx

    # (B) 粒子を1ステップ更新 (ボリス法)
    # (B-1) 電場を粒子位置に補間 (Scatter)
    Ey_p = np.interp(pos, grid_x_E, Ey)
    # (今回は簡単化のためEx=0とする)
    
    # (B-2) 速度更新 (Boris Push)
    # 1. 半ステップの電場による加速
    vel[:, 1] += (q_sp / m_sp) * Ey_p * (dt / 2.0)
    
    # 2. 磁場による回転
    # 磁場を粒子位置に補間
    Bz_p = np.interp(pos, grid_x_B, Bz)
    
    t_mag_sq = ((q_sp * dt) / (2.0 * m_sp))**2 * (Bz_p**2)
    s = (2.0 / (1.0 + t_mag_sq)) * ((q_sp * dt) / (2.0 * m_sp))
    
    # v_minus と v_prime を計算
    vx_minus = vel[:, 0]
    vy_minus = vel[:, 1]
    
    vx_prime = vx_minus + vy_minus * ( (q_sp * dt)/(2.0 * m_sp) * Bz_p)
    vy_prime = vy_minus - vx_minus * ( (q_sp * dt)/(2.0 * m_sp) * Bz_p)
    
    # v_plus を計算し、v(t+dt/2)へ
    vel[:, 0] = vx_minus + vy_prime * s * Bz_p
    vel[:, 1] = vy_minus - vx_prime * s * Bz_p
    
    # 3. 残り半ステップの電場による加速
    vel[:, 1] += (q_sp / m_sp) * Ey_p * (dt / 2.0)
    
    # (B-3) 位置を1ステップ更新
    pos += vel[:, 0] * dt
    # 周期的境界条件
    pos = np.mod(pos, L)

    # (C) 電流密度の計算 (Gather)
    Jy.fill(0.0)
    for i in range(N):
        x_grid_idx_f = pos[i] / dx
        j = int(x_grid_idx_f)
        w_right = x_grid_idx_f - j
        w_left = 1.0 - w_right
        
        j_plus_1 = (j + 1) % NX # NX番目のグリッドは0番目と同じ
        
        # 電流を割り当て
        # 注: ここでは簡単なCICを用いているが、厳密には電荷保存則を満たす手法が望ましい
        Jy[j] += q_sp * vel[i, 1] * w_left / dx
        if j_plus_1 < NX:
            Jy[j_plus_1] += q_sp * vel[i, 1] * w_right / dx
            
    # (D) 電場(E)を半ステップ更新 (FDTD)
    for j in range(1, NX - 1):
        # dE/dt = c^2*curl(B) - J/eps0 -> dEy/dt = -c^2*dBz/dx - Jy/eps0
        Ey[j] += dt * (-c**2 * (Bz[j] - Bz[j-1]) / dx - Jy[j] / eps0)
    # 境界は単純なままとする
    
    # アニメーションの更新
    line.set_ydata(Ey)
    if i_step % 10 == 0:
        ax.set_title(f"1D EM PIC Simulation (Ey) - Step {i_step}")
    return line,

# アニメーションの実行
ani = FuncAnimation(fig, update, frames=N_STEPS, interval=1, blit=True)
plt.show()
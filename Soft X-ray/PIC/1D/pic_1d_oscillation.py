import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation

# --- 1. シミュレーションパラメータの設定 ---
N = 40000      # スーパーパーティクル（電子）の数
NX = 401       # グリッドの数（奇数が望ましい）
L = 2 * np.pi  # シミュレーション領域の長さ (m)
dx = L / (NX - 1) # グリッド間隔 (m)
dt = 0.1       # 時間ステップ (s)
T_MAX = 50.0   # シミュレーションの最大時間 (s)
N_STEPS = int(T_MAX / dt) # 総ステップ数

# --- 物理定数 ---
e = 1.0        # 電子の素電荷（規格化）
m = 1.0        # 電子の質量（規格化）
eps0 = 1.0     # 真空の誘電率（規格化）
wp = 1.0       # プラズマ周波数（規格化） n0*e^2/(m*eps0) = 1 となるように規格化

# --- 初期条件パラメータ ---
x_pert_amp = 0.01  # 位置の揺らぎの振幅
x_pert_mode = 1    # 位置の揺らぎのモード数

# --- 2. 初期化 ---
# グリッドの座標
grid_x = np.linspace(0, L, NX)

# 粒子の位置と速度の配列を確保
pos = np.zeros(N)
vel = np.zeros(N)

# イオンは一様な背景電荷として扱う
# 電子の電荷密度 n0 = wp^2 * m * eps0 / e^2 = 1.0
n0 = wp**2 * m * eps0 / e**2
# スーパーパーティクル1個あたりの電荷・質量
q_sp = n0 * L / N * (-e) # 全電荷がイオンと釣り合うように
m_sp = n0 * L / N * m

# 粒子の初期位置と速度を設定
# 一様に分布させ、小さな揺らぎを与える
pos = np.random.rand(N) * L
pos += x_pert_amp * np.sin(2 * np.pi * x_pert_mode * pos / L)
# 速度はゼロ（冷たいプラズマ）
vel.fill(0.0)

# 境界条件: 周期的境界条件
# 念のため、揺らぎによってLの外に出た粒子を中に戻す
pos = np.mod(pos, L)

# --- 3. メインループの準備 ---
# グリッド上の物理量
rho = np.zeros(NX) # 電荷密度
phi = np.zeros(NX) # 静電ポテンシャル
Ex = np.zeros(NX)  # x方向の電場

# FFT用の波数ベクトルkを準備
k = 2 * np.pi * np.fft.fftfreq(NX, d=dx)
k[0] = 1e-10 # k=0でのゼロ割を避けるための小さな値

# 診断用：電場エネルギーの履歴
efield_energy_history = []

# --- 4. メインループ ---
print("シミュレーションを開始します...")

# リープフロッグ法のため、最初に速度を-dt/2だけ進めておく
# (今回は初期電場がゼロなので、このステップは実質何もしない)
# Ex_at_particles = np.interp(pos, grid_x, Ex)
# vel -= 0.5 * (q_sp / m_sp) * Ex_at_particles * dt

for i_step in range(N_STEPS):
    if i_step % 10 == 0:
        print(f"ステップ: {i_step}/{N_STEPS}")

    # (A) 電荷のグリッドへの割り当て (Gather)
    # Cloud-in-Cell (CIC)法
    rho.fill(0.0)
    for i in range(N):
        # 粒子位置をグリッド単位に変換
        x_grid_idx_f = pos[i] / dx
        # 左側のグリッド点のインデックス
        j = int(x_grid_idx_f)
        # 右側のグリッド点との距離の重み
        w_right = x_grid_idx_f - j
        w_left = 1.0 - w_right

        # 周期的境界条件
        j_plus_1 = (j + 1) % (NX -1) # NX-1はLの点なので、その手前まで

        # 電荷を割り当て
        rho[j] += q_sp * w_left
        rho[j_plus_1] += q_sp * w_right

    # グリッド体積(dx)で割って電荷密度にする
    rho /= dx
    # イオンの背景電荷を加える
    rho += n0 * e

    # (B) 電場の計算 (Field Solve)
    # ポアソン方程式をFFTで解く
    rho_k = np.fft.fft(rho)
    phi_k = rho_k / (eps0 * k**2)
    phi = np.real(np.fft.ifft(phi_k))

    # 電場 E = -∇φ をFFTで計算
    Ex_k = -1j * k * phi_k
    Ex = np.real(np.fft.ifft(Ex_k))

    # (C) 粒子の運動計算 (Push)
    # 電場を粒子位置に補間 (Scatter)
    Ex_at_particles = np.interp(pos, grid_x, Ex)

    # 速度と位置を更新 (Leap-frog)
    vel += (q_sp / m_sp) * Ex_at_particles * dt
    pos += vel * dt

    # 周期的境界条件の適用
    pos = np.mod(pos, L)

    # (D) 診断
    # 電場エネルギーを計算して保存
    efield_energy = 0.5 * eps0 * np.sum(Ex**2) * dx
    efield_energy_history.append(efield_energy)


print("シミュレーションが完了しました。")

# --- 5. 結果の可視化 ---
# (A) 最終的な粒子分布（位相空間プロット）
plt.figure(figsize=(10, 6))
plt.title("Phase Space Plot at T_MAX")
plt.scatter(pos, vel, s=0.1, c='blue')
plt.xlabel("Position (x)")
plt.ylabel("Velocity (v)")
plt.xlim(0, L)
plt.grid(True)
plt.show()

# (B) 電場エネルギーの時間変化
plt.figure(figsize=(10, 6))
plt.title("Electric Field Energy vs. Time")
time_axis = np.arange(0, T_MAX, dt)
plt.plot(time_axis, efield_energy_history)
plt.xlabel("Time")
plt.ylabel("Electric Field Energy")
# 理論的なプラズマ周波数の2倍の周波数で振動することを確認
plt.axvline(x=np.pi, color='r', linestyle='--', label=f'T = pi/wp (wp={wp})')
plt.legend()
plt.grid(True)
plt.show()
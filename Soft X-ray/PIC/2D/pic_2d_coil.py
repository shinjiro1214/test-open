import numpy as np
import matplotlib.pyplot as plt
import time
import os
from numba import jit, prange

print("🚀 Initializing The Ultimate PIC Simulation - Ver. 15.8 (All Requests Implemented)")

# ==============================================================================
# --- 1. 物理・シミュレーション設定 ---
# ==============================================================================
MI_ME=25.0; WPE_WCE=2.0; T_el_norm=0.2
NX,NZ=129,65; LX_de,LZ_de=51.2,25.6
N_PTCL_PER_CELL=100
T_MAX_wpe=100.0

PLOT_INTERVAL_wpe = 2.0
PF_CABLE_R_de = 0.5 

NUM_SMOOTHING_PASSES = 8

# ==============================================================================
# --- 2. パラメータ導出と配列準備 ---
# ==============================================================================
c=1.;m_e=1.;q_e=-1.;n0=1.;m_i=m_e*MI_ME;q_i=-q_e
w_pe=np.sqrt(n0/m_e);w_ce=w_pe/WPE_WCE;v_the=np.sqrt(T_el_norm/m_e);d_e=c/w_pe
LX,LZ=LX_de*d_e,LZ_de*d_e;dx,dz=LX/(NX-1),LZ/(NZ-1)
dt=0.05/(c*np.sqrt(1/dx**2+1/dz**2));print(f"Grid: {NX}x{NZ}, dt: {dt:.4f}")
output_dir="data_coil";os.makedirs(output_dir,exist_ok=True)
I_PF_peak=0.1;I_TF_peak=0.1;I_EF_norm=0.01
t_rise_pf_wpe=25.;t_swing_start_pf_wpe=25.;t_swing_duration_pf_wpe=15.;pf_reversal_ratio=-0.25
t_start_tf_wpe=t_swing_start_pf_wpe;t_rise_tf_wpe=15.;t_start_ef_wpe=0.0;t_rise_ef_wpe=80.
pf_pos=np.array([[-10.,LZ_de/2],[10.,LZ_de/2]]);pf_r=2.
ef_pos=np.array([[-20.,LZ_de*1.1],[20.,LZ_de*1.1]]);ef_r=2.
tf_pos=np.array([10.,LZ_de/2]);tf_w=4.;tf_h=8.
coil_geos_norm={'pf_pos':pf_pos,'pf_r':pf_r,'ef_pos':ef_pos,'ef_r':ef_r}

# ★★★ RLC回路の物理パラメータ ★★★
# --- PFコイル用 ---
# V0:初期電圧, R:抵抗, L:インダクタンス, C:静電容量
PF_V0 = 10.0; PF_R = 0.4; PF_L = 10.0; PF_C = 6.5
# --- TFコイル用 ---
TF_V0 = 5.0;  TF_R = 0.2; TF_L = 10.0; TF_C = 4.0

pf_pos_abs = coil_geos_norm['pf_pos'] * d_e
pf_r_abs = coil_geos_norm['pf_r'] * d_e
pf_cable_r_abs = PF_CABLE_R_de * d_e 
ef_pos_abs = coil_geos_norm['ef_pos'] * d_e
ef_r_abs = coil_geos_norm['ef_r'] * d_e

N_total=N_PTCL_PER_CELL*(NX-1)*(NZ-1);N_e=N_total//2;N_i=N_total-N_e
pos=np.zeros((N_total,2));vel=np.zeros((N_total,3));charge=np.zeros(N_total);mass=np.zeros(N_total);is_active=np.ones(N_total,dtype=np.bool_)
if N_total > 0:
    print("Initializing particle positions (avoiding coils)...")
    for i in range(N_total):
        while True:
            # 候補となる位置をランダムに生成
            px = np.random.uniform(-LX/2, LX/2)
            pz = np.random.uniform(0, LZ)
            
            is_inside = False
            # PFコイル(外殻)の内部かチェック
            for c in range(pf_pos_abs.shape[0]):
                if (px - pf_pos_abs[c, 0])**2 + (pz - pf_pos_abs[c, 1])**2 < pf_r_abs**2:
                    is_inside = True
                    break
            if is_inside:
                continue # 内部なら再生成

            # EFコイル(外殻)の内部かチェック
            for c in range(ef_pos_abs.shape[0]):
                if (px - ef_pos_abs[c, 0])**2 + (pz - ef_pos_abs[c, 1])**2 < ef_r_abs**2:
                    is_inside = True
                    break
            if is_inside:
                continue # 内部なら再生成

            # どのコイルにも入っていなければ、位置を確定してループを抜ける
            pos[i, 0] = px
            pos[i, 1] = pz
            break # while Trueループを抜ける
    
    print("Particle positions initialized.")
    # 速度、電荷、質量を設定
    vel[:N_e,:]=np.random.normal(0,v_the,(N_e,3));charge[:N_e]=q_e;mass[:N_e]=m_e
    vel[N_e:,:]=np.random.normal(0,v_the/np.sqrt(MI_ME),(N_i,3));charge[N_e:]=q_i;mass[N_e:]=m_i
    wp=(n0*LX*LZ)/N_total
else:
    wp=0

E=np.zeros((NX,NZ,3));B=np.zeros((NX,NZ,3));J_plasma=np.zeros((NX,NZ,3));J_ext=np.zeros((NX,NZ,3));rho=np.zeros((NX,NZ));Ay=np.zeros((NX,NZ))
x_vec_de=np.linspace(-LX_de/2,LX_de/2,NX);z_vec_de=np.linspace(0,LZ_de,NZ);x_grid_norm,z_grid_norm=np.meshgrid(x_vec_de,z_vec_de,indexing='ij')
J_ext_prev=np.zeros_like(J_ext)



global_continue_hit_count = 0

# ==============================================================================
# --- 4. コア計算関数 ---
# ==============================================================================
@jit(nopython=True, cache=True)
def update_rlc_circuits(t_wpe, dt, i_pf, q_pf, i_tf, q_tf, t_start_tf, PF_R, PF_L, PF_C, TF_R, TF_L, TF_C):
    """RLC回路の状態を1ステップ分更新する"""
    # --- PF回路の更新 (t=0から作動) ---
    # dI/dt = (-RI - Q/C) / L
    didt_pf = (-PF_R * i_pf - q_pf / PF_C) / PF_L
    i_pf_new = i_pf + didt_pf * dt
    # dQ/dt = I
    q_pf_new = q_pf + i_pf * dt

    # --- TF回路の更新 (指定時間から作動) ---
    i_tf_new, q_tf_new = i_tf, q_tf # まず現在の値をコピー
    if t_wpe >= t_start_tf:
        didt_tf = (-TF_R * i_tf - q_tf / TF_C) / TF_L
        i_tf_new = i_tf + didt_tf * dt
        q_tf_new = q_tf + i_tf * dt
    else:
        i_tf_new = 0.0 # 作動前は電流ゼロ

    return i_pf_new, q_pf_new, i_tf_new, q_tf_new

# EF電流はゆっくり立ち上がるだけなので、単純な関数として残しておく
@jit(nopython=True, cache=True)
def get_ef_current(t_wpe, t_start_ef_wpe, t_rise_ef_wpe, I_EF_norm):
    I_ef = 0.0
    if t_wpe >= t_start_ef_wpe:
        t_rel_ef = t_wpe - t_start_ef_wpe
        if t_rel_ef < t_rise_ef_wpe:
            I_ef = I_EF_norm * np.sin(0.5 * np.pi * t_rel_ef / t_rise_ef_wpe)**2
        else:
            I_ef = I_EF_norm
    return I_ef

@jit(nopython=True, cache=True, parallel=True)
def update_J_ext(J_ext_out, I_pf, I_ef, pf_pos_abs, pf_cable_r_abs, ef_pos_abs, ef_r_abs, NX, NZ, LX, LZ):
    J_ext_out.fill(0)
    x_vec = np.linspace(-LX/2, LX/2, NX)
    z_vec = np.linspace(0, LZ, NZ)

    # PFコイル
    if I_pf != 0:
        J_val = I_pf / (np.pi * pf_cable_r_abs**2)
        for ix in prange(NX):
            for iz in range(NZ):
                x, z = x_vec[ix], z_vec[iz]
                if (x-pf_pos_abs[0,0])**2 + (z-pf_pos_abs[0,1])**2 < pf_cable_r_abs**2:
                    J_ext_out[ix, iz, 1] += J_val
                if (x-pf_pos_abs[1,0])**2 + (z-pf_pos_abs[1,1])**2 < pf_cable_r_abs**2:
                    J_ext_out[ix, iz, 1] += J_val
    
    # EFコイル
    if I_ef != 0:
        J_val = I_ef / (np.pi * ef_r_abs**2)
        for ix in prange(NX):
            for iz in range(NZ):
                x, z = x_vec[ix], z_vec[iz]
                if (x-ef_pos_abs[0,0])**2 + (z-ef_pos_abs[0,1])**2 < ef_r_abs**2:
                    J_ext_out[ix, iz, 1] -= J_val
                if (x-ef_pos_abs[1,0])**2 + (z-ef_pos_abs[1,1])**2 < ef_r_abs**2:
                    J_ext_out[ix, iz, 1] -= J_val

    return J_ext_out
@jit(nopython=True, cache=True)
def push_and_deposit_species(pos_s, vel_s, charge_s, mass_s, E, B, J_s, rho_s, wp, dt, Lx, Lz, dx, dz, NX, NZ, hit_count_array, pf_pos_abs, pf_r_abs, ef_pos_abs, ef_r_abs):
    J_s.fill(0); rho_s.fill(0); inv_vol=1./(dx*dz)
    for i in range(pos_s.shape[0]):
        # Gather
        ix_f=(pos_s[i,0]+Lx/2)/dx; iz_f=pos_s[i,1]/dz
        if not (0<=ix_f<NX-1 and 0<=iz_f<NZ-1):
            hit_count_array[0] += 1
            continue
        ix,iz=int(ix_f),int(iz_f); wx,wz=ix_f-ix,iz_f-iz
        E_p=(E[ix,iz]*(1-wx)*(1-wz)+E[ix+1,iz]*wx*(1-wz)+E[ix,iz+1]*(1-wx)*wz+E[ix+1,iz+1]*wx*wz)
        B_p=(B[ix,iz]*(1-wx)*(1-wz)+B[ix+1,iz]*wx*(1-wz)+B[ix,iz+1]*(1-wx)*wz+B[ix+1,iz+1]*wx*wz)

        # Pusher
        q_over_m=charge_s[i]/mass_s[i]; v_minus=vel_s[i]+q_over_m*E_p*dt/2.; t_vec=q_over_m*B_p*dt/2.
        s_vec=2.*t_vec/(1.+np.dot(t_vec,t_vec)); v_prime=v_minus+np.cross(v_minus,t_vec); v_plus=v_minus+np.cross(v_prime,s_vec); vel_s[i]=v_plus+q_over_m*E_p*dt/2.

        # 移動前の位置を保存
        pos_old = pos_s[i, :].copy()
        # 仮の位置更新
        pos_s[i, 0] += vel_s[i, 0] * dt
        pos_s[i, 1] += vel_s[i, 2] * dt

        # ★★★ 新しい堅牢なコイル境界条件 ★★★
        reflected_in_step = False
        # PFコイル: 判定は外殻(pf_r_abs)で行う
        for c in range(pf_pos_abs.shape[0]):
            cx, cz = pf_pos_abs[c, 0], pf_pos_abs[c, 1]
            if (pos_s[i, 0] - cx)**2 + (pos_s[i, 1] - cz)**2 < pf_r_abs**2:
                # 衝突した場合、位置を元に戻し、速度を反射させる
                pos_s[i, :] = pos_old
                n_vec = pos_s[i, :] - np.array([cx,cz])
                n_mag = np.sqrt(n_vec[0]**2 + n_vec[1]**2)
                if n_mag > 1e-9:
                    n_hat_2d = n_vec / n_mag
                    n_hat_3d = np.array([n_hat_2d[0], 0.0, n_hat_2d[1]])
                    v_dot_n = np.dot(vel_s[i,:], n_hat_3d)
                    vel_s[i,:] = vel_s[i,:] - 2.0 * v_dot_n * n_hat_3d
                else: # まれに中心にいる場合
                    vel_s[i,:] *= -1.0
                reflected_in_step = True
                break
        
        # EFコイル
        if not reflected_in_step:
            for c in range(ef_pos_abs.shape[0]):
                cx, cz = ef_pos_abs[c, 0], ef_pos_abs[c, 1]
                if (pos_s[i, 0] - cx)**2 + (pos_s[i, 1] - cz)**2 < ef_r_abs**2:
                    pos_s[i, :] = pos_old
                    n_vec = pos_s[i, :] - np.array([cx,cz])
                    n_mag = np.sqrt(n_vec[0]**2 + n_vec[1]**2)
                    if n_mag > 1e-9:
                        n_hat_2d = n_vec / n_mag
                        n_hat_3d = np.array([n_hat_2d[0], 0.0, n_hat_2d[1]])
                        v_dot_n = np.dot(vel_s[i,:], n_hat_3d)
                        vel_s[i,:] = vel_s[i,:] - 2.0 * v_dot_n * n_hat_3d
                    else:
                        vel_s[i,:] *= -1.0
                    reflected_in_step = True
                    break

        # ★★★ コイル境界条件ここまで ★★★
        
        # コイルで反射しなかった場合のみ、壁の境界条件を適用
        if not reflected_in_step:
            pos_s[i,0]=np.mod(pos_s[i,0]+Lx/2,Lx)-Lx/2
            if pos_s[i,1]>Lz: pos_s[i,1]=2*Lz-pos_s[i,1]; vel_s[i,2]*=-1.
            if pos_s[i,1]<0: pos_s[i,1]=-pos_s[i,1]; vel_s[i,2]*=-1.

        # Scatter
        ix_f_new=(pos_s[i,0]+Lx/2)/dx; iz_f_new=pos_s[i,1]/dz
        if not (0<=ix_f_new<NX-1 and 0<=iz_f_new<NZ-1):
            hit_count_array[0] += 1
            continue
        ix,iz=int(ix_f_new),int(iz_f_new); wx,wz=ix_f_new-ix,iz_f_new-iz; dwx,dwz=1-wx,1-wz
        q_contrib=charge_s[i]*wp*inv_vol
        rho_s[ix,iz]+=q_contrib*dwx*dwz; rho_s[ix+1,iz]+=q_contrib*wx*dwz; rho_s[ix,iz+1]+=q_contrib*dwx*wz; rho_s[ix+1,iz+1]+=q_contrib*wx*wz
        for d in range(3):
            j_p=q_contrib*vel_s[i,d]; J_s[ix,iz,d]+=j_p*dwx*dwz; J_s[ix+1,iz,d]+=j_p*wx*dwz; J_s[ix,iz+1,d]+=j_p*dwx*wz; J_s[ix+1,iz+1,d]+=j_p*wx*wz
            
    return pos_s,vel_s,J_s,rho_s

@jit(nopython=True, cache=True)
def filter_J(J_in):
    # 簡単なデジタルフィルタ（3点平均）
    J_out = J_in.copy()
    for c in range(3):
        J_out[1:-1, 1:-1, c] = (J_in[1:-1, 1:-1, c] + J_in[:-2, 1:-1, c] + J_in[2:, 1:-1, c] + J_in[1:-1, :-2, c] + J_in[1:-1, 2:, c]) / 5.0
    return J_out

@jit(nopython=True, cache=True)
def FDTD_solver(E, B, J, dt, dx, dz):
    # 磁場Bの更新
    B[1:-1,1:-1,0] += dt * (E[1:-1,2:,1] - E[1:-1,:-2,1]) / (2*dz)
    B[1:-1,1:-1,1] += dt * ((E[2:,1:-1,2] - E[:-2,1:-1,2]) / (2*dx) - (E[1:-1,2:,0] - E[1:-1,:-2,0]) / (2*dz))
    B[1:-1,1:-1,2] -= dt * (E[2:,1:-1,1] - E[:-2,1:-1,1]) / (2*dx)
    
    # 電場Eの更新
    E[1:-1,1:-1,0] += dt * (-(B[1:-1,2:,1] - B[1:-1,:-2,1]) / (2*dz) - J[1:-1,1:-1,0])
    
    dBx_dz = (B[1:-1, 2:, 0] - B[1:-1, :-2, 0]) / (2*dz)
    dBz_dx = (B[2:, 1:-1, 2] - B[:-2, 1:-1, 2]) / (2*dx)
    E[1:-1, 1:-1, 1] += dt * (dBx_dz - dBz_dx - J[1:-1, 1:-1, 1])
    
    E[1:-1,1:-1,2] += dt * ((B[2:,1:-1,1] - B[:-2,1:-1,1]) / (2*dx) - J[1:-1,1:-1,2])

    # 開放境界条件のため、境界での処理は行わない
    
    return E,B

def solve_poisson_fft(rho_data,dx,dz):
    NX_local,NZ_local=rho_data.shape;rho_k=np.fft.fft2(rho_data);kx=2*np.pi*np.fft.fftfreq(NX_local,d=dx);kz=2*np.pi*np.fft.fftfreq(NZ_local,d=dz)
    kx_grid,kz_grid=np.meshgrid(kx,kz,indexing='ij');k_sq=kx_grid**2+kz_grid**2;k_sq[0,0]=1.
    phi_k=-rho_k/k_sq;phi_k[0,0]=0;return np.real(np.fft.ifft2(phi_k))

@jit(nopython=True, cache=True)
def smooth_current(J_in):
    J_out=J_in.copy()
    for c in range(3):
        J_temp=J_out[:,:,c].copy();J_temp[1:-1,:]=0.25*J_out[:-2,:,c]+0.5*J_out[1:-1,:,c]+0.25*J_out[2:,:,c];J_out[:,:,c]=J_temp
        J_temp=J_out[:,:,c].copy();J_temp[:,1:-1]=0.25*J_out[:,:-2,c]+0.5*J_out[:,1:-1,c]+0.25*J_out[:,2:,c];J_out[:,:,c]=J_temp
    return J_out

@jit(nopython=True, cache=True)
def smooth_for_plot(field_2d):
    # 渡された2次元配列を滑らかにする
    # 1-2-1フィルタを2回適用してより滑らかな結果を得る
    out = field_2d.copy()
    
    # 1回目の平滑化
    temp1 = out.copy()
    # x方向
    temp1[1:-1, :] = 0.25 * out[:-2, :] + 0.5 * out[1:-1, :] + 0.25 * out[2:, :]
    out = temp1.copy()
    # z方向
    temp1[:, 1:-1] = 0.25 * out[:, :-2] + 0.5 * out[:, 1:-1] + 0.25 * out[:, 2:]
    out = temp1
    
    # 2回目の平滑化
    temp2 = out.copy()
    # x方向
    temp2[1:-1, :] = 0.25 * out[:-2, :] + 0.5 * out[1:-1, :] + 0.25 * out[2:, :]
    out = temp2.copy()
    # z方向
    temp2[:, 1:-1] = 0.25 * out[:, :-2] + 0.5 * out[:, 1:-1] + 0.25 * out[:, 2:]
    
    return temp2

def create_diagnostic_plot_normalized(filename,t_wpe,B,J,E,Ay,pos,N_e,coil_geos,Lx_de,Lz_de,x_vec_de,z_vec_de,x_grid_norm,z_grid_norm):
    fig, axs = plt.subplots(3, 4, figsize=(22, 12), constrained_layout=True)
    extent=[-Lx_de/2,Lx_de/2,0,Lz_de]

    data_map = {
        'Bx': (B[:, :, 0].T, axs[0, 0]), 'By': (B[:, :, 1].T, axs[0, 1]), 'Bz': (B[:, :, 2].T, axs[0, 2]),
        'Jx': (J[:, :, 0].T, axs[1, 0]), 'Jy': (J[:, :, 1].T, axs[1, 1]), 'Jz': (J[:, :, 2].T, axs[1, 2]),
        'Ex': (E[:, :, 0].T, axs[2, 0]), 'Ey': (E[:, :, 1].T, axs[2, 1]), 'Ez': (E[:, :, 2].T, axs[2, 2]),
    }

    # B, J, E の各成分をプロット
    for name, (data, ax) in data_map.items():
        ### ★★★ 修正点: データをプロットする直前に平滑化 ★★★
        data_to_plot = smooth_for_plot(data)
        
        vmax = np.max(np.abs(data_to_plot)) if np.max(np.abs(data_to_plot)) > 1e-9 else 1.0
        im = ax.imshow(data_to_plot, origin='lower', extent=extent, aspect='equal', cmap='RdBu_r', 
                       vmin=-vmax, vmax=vmax)
        fig.colorbar(im, ax=ax, label=f'{name} value')
        ax.set_title(f'{name} Distribution')
    ax_psi=axs[0,3];ax_psi.set_title(r'Poloidal Flux $\psi$');vmax_ay=np.max(np.abs(Ay)) if np.max(np.abs(Ay))>0 else 1.0
    ax_psi.contour(x_vec_de,z_vec_de,Ay.T,levels=2,colors='k',linewidths=0.8);im_ay=ax_psi.imshow(Ay.T,origin='lower',extent=extent,aspect='equal',cmap='viridis',vmin=-vmax_ay,vmax=vmax_ay);fig.colorbar(im_ay,ax=ax_psi,label=r'Value')
    ax_part=axs[1,3];ax_part.set_title('Particle Positions');ax_part.plot(pos[N_e:,0]/d_e,pos[N_e:,1]/d_e,'.',ms=1,color='red',label='Ions',alpha=0.5);ax_part.plot(pos[:N_e,0]/d_e,pos[:N_e,1]/d_e,'.',ms=1,color='blue',label='Electrons',alpha=0.5);ax_part.legend(markerscale=5, loc='upper right');ax_part.set_xlim(extent[0],extent[1]);ax_part.set_ylim(extent[2],extent[3])
    ax_helicity=axs[2,3];ax_helicity.set_title(r'Field Helicity ($B_{pol}$ on $B_y$)');vmax_by=np.max(np.abs(B[:,:,1])) if np.max(np.abs(B[:,:,1]))>0 else 1.0
    ax_helicity.imshow(B[:,:,1].T,origin='lower',extent=extent,aspect='equal',cmap='RdBu_r',vmin=-vmax_by,vmax=vmax_by);skip=8
    ax_helicity.quiver(x_grid_norm[::skip,::skip],z_grid_norm[::skip,::skip],B[::skip,::skip,0],B[::skip,::skip,2],color='black',scale=vmax_by*30 if vmax_by>0 else 1,width=0.004)
    for ax in axs.flat:
        for i in range(len(coil_geos['pf_pos'])):ax.add_patch(plt.Circle(coil_geos['pf_pos'][i],coil_geos['pf_r'],color='magenta',fill=False,lw=2))
        for i in range(len(coil_geos['ef_pos'])):ax.add_patch(plt.Circle(coil_geos['ef_pos'][i],coil_geos['ef_r'],color='cyan',fill=False,lw=2))
        ax.set_xlabel('x [$d_e$]');ax.set_ylabel('z [$d_e$]')
    plt.savefig(filename,dpi=150);plt.close(fig)
    
def plot_plasma_moments(filename, t_wpe, rho_e, rho_i, q_e, q_i, Lx_de, Lz_de):
    fig, axs = plt.subplots(1, 2, figsize=(14, 5.5), constrained_layout=True)
    fig.suptitle(f'Plasma Density at t = {t_wpe:.1f} $[1/\omega_{{pe}}]$', fontsize=16)
    extent = [-Lx_de/2, Lx_de/2, 0, Lz_de]
    
    # 電荷密度ρを実電荷qで割って、数密度nを得る
    n_e = rho_e / q_e
    n_i = rho_i / q_i
    
    vmax = np.max(n_e) * 1.5 if np.max(n_e) > 1e-9 else 1.0
    im1 = axs[0].imshow(n_e.T, origin='lower', extent=extent, aspect='equal', cmap='viridis', vmin=0, vmax=vmax)
    fig.colorbar(im1, ax=axs[0], label='Density [$n_0$]')
    axs[0].set_title('Electron Density'); axs[0].set_xlabel('x [$d_e$]'); axs[0].set_ylabel('z [$d_e$]')
    im2 = axs[1].imshow(n_i.T, origin='lower', extent=extent, aspect='equal', cmap='viridis', vmin=0, vmax=vmax)
    fig.colorbar(im2, ax=axs[1], label='Density [$n_0$]'); axs[1].set_title('Ion Density'); axs[1].set_xlabel('x [$d_e$]')
    plt.savefig(filename, dpi=120); plt.close(fig)



def plot_energy_histogram(filename, t_wpe, vel_e, is_active_e, T0_norm):
    if vel_e.shape[0] == 0 or np.sum(is_active_e) == 0:
        # プロットする粒子がいない場合は空のグラフを生成
        plt.figure(figsize=(10, 6))
        plt.title(f'Electron Energy Distribution at t={t_wpe:.1f} (No Active Particles)')
        plt.xlabel('Energy [$T_{e0}$]'); plt.ylabel('Particle Count')
        plt.grid(True, ls="--")
        plt.savefig(filename, dpi=120); plt.close()
        return

    active_electrons_vel = vel_e[is_active_e]
    ke_e = 0.5 * m_e * np.sum(active_electrons_vel**2, axis=1)
    
    plt.figure(figsize=(10, 6))
    
    # ★★★ プロットのレンジとスケールを修正 ★★★
    # エネルギーの最大値に基づいてビンの範囲を動的に決定
    max_energy = np.max(ke_e) / T0_norm if np.max(ke_e) > 0 else 1.0
    # 非常に大きなエネルギーを持つ粒子がいる場合、描画の上限を設ける（例：100）
    plot_max_energy = min(max_energy, 1000000.0) 
    # 描画範囲内に粒子がほとんどいない場合も考慮
    if plot_max_energy < 1.0: plot_max_energy = 20.0
    bins = np.linspace(0, plot_max_energy, 50)
    
    # 縦軸を対数スケールにすることで、数の少ない高エネルギー粒子も表示
    plt.hist(ke_e / T0_norm, bins=bins, log=True, label=f'All active electrons ({active_electrons_vel.shape[0]} particles)')
    
    plt.title(f'Electron Energy Distribution at t={t_wpe:.1f}'); plt.xlabel('Energy [$T_{e0}$]'); plt.ylabel('Particle Count (log scale)')
    plt.grid(True, ls="--"); plt.legend(); plt.savefig(filename, dpi=120); plt.close()

def plot_energy_conservation(filename, energies):
    energies_np = np.array(energies)
    if len(energies_np) < 2: return # データが足りないとプロットできない

    times = energies_np[:,0]
    ke = energies_np[:,1]
    be = energies_np[:,2]
    ee = energies_np[:,3]
    total_e = energies_np[:,4]
    initial_total_e = total_e[0]

    plt.figure(figsize=(10,6))
    plt.plot(times, (ke-ke[0])/initial_total_e, label='$\\Delta KE$')
    plt.plot(times, (be-be[0])/initial_total_e, label='$\\Delta BE$')
    plt.plot(times, (ee-ee[0])/initial_total_e, label='$\\Delta EE$')
    plt.plot(times, (total_e-initial_total_e)/initial_total_e, 'k--', lw=2, label='$\\Delta E_{Total}$')
    
    plt.title('Energy Conservation Check')
    plt.xlabel('Time $[1/\omega_{pe}]$')
    plt.ylabel('Energy Change / Initial Total E')
    plt.grid(True)
    plt.legend()
    # y軸の範囲をデータの変動に応じて自動調整しつつ、上限・下限を設定
    max_fluctuation = np.max(np.abs((total_e-initial_total_e)/initial_total_e))
    plt.ylim(-max(0.05, max_fluctuation*1.5), max(0.05, max_fluctuation*1.5))
    
    plt.savefig(filename)
    plt.close() # plt.show()から変更

def plot_current_history(filename,current_hist,t_max):
    current_hist_np=np.array(current_hist);times=current_hist_np[:,0];I_pf_vals=current_hist_np[:,1];I_tf_vals=current_hist_np[:,2];I_ef_vals=current_hist_np[:,3]
    plt.figure(figsize=(10,6));plt.plot(times,I_pf_vals,label=f'$I_{{PF}}$',lw=2);plt.plot(times,I_tf_vals,label=f'$I_{{TF}}$',lw=2);plt.plot(times,I_ef_vals,label=f'$I_{{EF}}$',lw=2);
    plt.title('Time Evolution of Coil Currents');plt.xlabel('Time $[1/\omega_{pe}]$');plt.ylabel('Normalized Current');plt.grid(True);plt.legend();plt.xlim(0,t_max);
    plt.savefig(filename,dpi=120);plt.close()

# ==============================================================================
# --- 5. クワイエット・スタートとメインループ ---
# ==============================================================================
print("Performing Quiet Start procedure...")
continue_hit_counter_array = np.array([0], dtype=np.int64)
if N_total > 0:
    _,_,_,rho_init = push_and_deposit_species(pos,vel,charge,mass,E,B,J_plasma,rho,wp,0,LX,LZ,dx,dz,NX,NZ, continue_hit_counter_array, pf_pos_abs, pf_r_abs, ef_pos_abs, ef_r_abs)
    if np.sum(np.abs(rho_init)) > 1e-9:
        phi_initial=solve_poisson_fft(-rho_init,dx,dz); E_initial_x,E_initial_z=np.gradient(phi_initial,dx,dz)
        E[:,:,0]=-E_initial_x; E[:,:,2]=-E_initial_z
# print(f"  Max initial E after Quiet Start: {np.max(np.abs(E)):.3e}")
print("Quiet Start complete.")

N_STEPS=int(T_MAX_wpe/dt); PLOT_STEPS=int(PLOT_INTERVAL_wpe/dt)
energies,current_history=[],[]
J_e,J_i=np.zeros_like(J_plasma),np.zeros_like(J_plasma)
rho_e,rho_i=np.zeros_like(rho),np.zeros_like(rho)

# ★★★ RLC回路の初期状態を定義 ★★★
# 初期電荷 Q(0) = C * V0
i_pf, q_pf = 0.0, -PF_C * PF_V0
i_tf, q_tf = 0.0, -TF_C * TF_V0

# PF電流のピーク時刻を検出するための変数
pf_peak_time = -1.0  # ピーク時刻が未検出であることを示す
didt_pf_prev = 0.0   # 1ステップ前のdI/dtを保存する
B_y_from_TF_prev = np.zeros((NX, NZ))

print("Starting main loop...")
start_time=time.time()
for step in range(N_STEPS + 1):
    t_wpe = step * dt
    # --- ★★★ PF電流のピークを検出し、TFの開始タイミングを決定 ★★★ ---
    if pf_peak_time < 0: # まだピークを検出していない場合
        # PF回路の現在のdI/dtを計算
        didt_pf_now = (-PF_R * i_pf - q_pf / PF_C) / PF_L
        # dI/dt が正から負に転じる瞬間をピークとする
        if didt_pf_prev > 0 and didt_pf_now <= 0:
            pf_peak_time = t_wpe
            print(f"✅ INFO: PF current peak detected at t={pf_peak_time:.2f}. Starting TF coil.")
        didt_pf_prev = didt_pf_now

    # TF回路の開始時刻を動的に設定
    # ピークが検出されたらその時刻を、されていなければ十分に未来の時刻を設定
    t_start_tf = pf_peak_time if pf_peak_time > 0 else T_MAX_wpe * 2.0

    # --- RLCモデルでコイル電流を更新 ---
    i_pf, q_pf, i_tf, q_tf = update_rlc_circuits(t_wpe, dt, i_pf, q_pf, i_tf, q_tf, t_start_tf, PF_R, PF_L, PF_C, TF_R, TF_L, TF_C)
    i_ef = get_ef_current(t_wpe, t_start_ef_wpe, t_rise_ef_wpe, I_EF_norm)
    
    
    if step % PLOT_STEPS == 0:
        if N_total > 0:
            ke=0.5*np.sum(mass[is_active]*np.sum(vel[is_active]**2,axis=1))*wp
            
        else:
            ke=0.0
        be=0.5*np.sum(B**2)*dx*dz; ee=0.5*np.sum(E**2)*dx*dz
        energies.append([t_wpe,ke,be,ee,ke+be+ee])
        current_history.append([t_wpe, i_pf, i_tf, i_ef])
        
        elapsed = time.time() - start_time
        if step > 0:
            eta = (elapsed / step) * (N_STEPS - step)
            print(f"Step {step}/{N_STEPS}|T={t_wpe:.1f}|E_total={ke+be+ee:.3e}|ETA: {eta:.0f}s -> Plotting...")
        else:
            print(f"Step {step}/{N_STEPS}|T={t_wpe:.1f}|E_total={ke+be+ee:.3e}|Plotting...")
            
        # print(f"  Particles outside grid (total continue hits in last {PLOT_STEPS} steps): {continue_hit_counter_array[0]}")
        # continue_hit_counter_array[0] = 0 # カウンターをリセット
        # if N_total > 0:
        #     active_pos = pos[is_active]
        #     if np.any(np.isnan(active_pos)) or np.any(np.isinf(active_pos)):
        #         print(f"!!! WARNING: NaN or Inf found in particle positions at t={t_wpe:.1f} !!!")
        #         np.save(os.path.join(output_dir, f"pos_nan_inf_at_t_{t_wpe:.1f}.npy"), active_pos)
            
        #     # アクティブな粒子の位置データを保存
        #     np.save(os.path.join(output_dir, f"particle_positions_{step:06d}.npy"), active_pos)
            
        #     # 磁場の最大絶対値
        #     max_B_abs = np.max(np.abs(B))
        #     # 電子サイクロトロン周波数（最大磁場を用いて概算）
        #     omega_ce_e = np.abs(q_e) * max_B_abs / m_e
        #     # 安定性指標
        #     stability_factor = omega_ce_e * dt
        #     print(f"  Max B (abs): {max_B_abs:.3e} | Omega_ce_e * dt: {stability_factor:.3e}")
        #     if stability_factor > 0.2: # 一般的な目安
        #         print(f"  !!! WARNING: Omega_ce_e * dt ({stability_factor:.3e}) exceeds stability limit (0.2) !!!")

        filename_currents=os.path.join(output_dir,"current_history.png"); plot_current_history(filename_currents,current_history,T_MAX_wpe)
        filename_diag=os.path.join(output_dir,f"diagnostic_plot_{step:06d}.png"); create_diagnostic_plot_normalized(filename_diag,t_wpe,B,J_plasma+J_ext,E,Ay,pos,N_e,coil_geos_norm,LX_de,LZ_de,x_vec_de,z_vec_de,x_grid_norm,z_grid_norm)
        filename_moments = os.path.join(output_dir, f"plasma_moments_{step:06d}.png")
        
        plot_energy_conservation(f"{output_dir}/energy_conservation.png", energies)

        plot_plasma_moments(filename_moments, t_wpe, rho_e, rho_i, q_e, q_i, LX_de, LZ_de)
        filename_hist = os.path.join(output_dir, f"energy_histogram_{step:06d}.png")
        if N_total > 0: plot_energy_histogram(filename_hist, t_wpe, vel[:N_e], is_active[:N_e], T_el_norm)

    # J_extの更新 (時間ではなく電流値を渡す)
    J_ext = update_J_ext(J_ext, i_pf, i_ef, pf_pos_abs, pf_cable_r_abs, ef_pos_abs, ef_r_abs, NX, NZ, LX, LZ)
    J_ext_smooth = 0.5*(J_ext+J_ext_prev); J_ext_prev=J_ext.copy()
    
    
    if N_total > 0:
        pos[:N_e],vel[:N_e],J_e,rho_e = push_and_deposit_species(pos[:N_e],vel[:N_e],charge[:N_e],mass[:N_e],E,B,J_e,rho_e,wp,dt,LX,LZ,dx,dz,NX,NZ, continue_hit_counter_array, pf_pos_abs, pf_r_abs, ef_pos_abs, ef_r_abs)
        pos[N_e:],vel[N_e:],J_i,rho_i = push_and_deposit_species(pos[N_e:],vel[N_e:],charge[N_e:],mass[N_e:],E,B,J_i,rho_i,wp,dt,LX,LZ,dx,dz,NX,NZ, continue_hit_counter_array, pf_pos_abs, pf_r_abs, ef_pos_abs, ef_r_abs)
        J_plasma = J_e + J_i; rho = rho_e + rho_i
        # J_plasma_smooth = smooth_current(J_plasma)
        J_plasma_smooth = J_plasma.copy()
        for _ in range(NUM_SMOOTHING_PASSES):
            J_plasma_smooth = smooth_current(J_plasma_smooth)

    else: J_plasma_smooth=J_plasma
    
    J_total = J_plasma_smooth + J_ext_smooth
    B_y_from_TF=np.zeros((NX,NZ))
    if i_tf!=0:
        x_vec=np.linspace(-LX/2,LX/2,NX);z_vec=np.linspace(0,LZ,NZ)
        x_min_abs=tf_pos[0]-tf_w/2;x_max_abs=tf_pos[0]+tf_w/2;z_min,z_max=tf_pos[1]-tf_h/2,tf_pos[1]+tf_h/2
        for ix in range(NX):
            for iz in range(NZ):
                x,z=x_vec[ix],z_vec[iz]
                if z>z_min and z<z_max:
                    if x>-x_max_abs and x<-x_min_abs:B_y_from_TF[ix,iz]=i_tf*0.1
                    elif x>x_min_abs and x<x_max_abs:B_y_from_TF[ix,iz]=-i_tf*0.1
    
    # B_backup_y=B[:,:,1].copy()
    E,B=FDTD_solver(E,B,J_total,dt,dx,dz)
    # B[:,:,1]=B_backup_y+(B[:,:,1]-B_backup_y)+B_y_from_TF
    B[:, :, 1] += B_y_from_TF - B_y_from_TF_prev
    B_y_from_TF_prev = B_y_from_TF.copy()
    
    Ay-=E[:,:,1]*dt
    if step>0 and step%5==0 and N_total>0:
        div_E=np.zeros((NX,NZ));div_E[1:-1,1:-1]=(E[2:,1:-1,0]-E[:-2,1:-1,0])/(2*dx)+(E[1:-1,2:,2]-E[1:-1,:-2,2])/(2*dz)
        error_rho=div_E-rho
        phi_corr=solve_poisson_fft(error_rho,dx,dz)
        E_corr_x=np.zeros_like(E[:,:,0]);E_corr_z=np.zeros_like(E[:,:,2])
        E_corr_x[1:-1,:]=(phi_corr[2:,:]-phi_corr[:-2,:])/(2*dx);E_corr_z[:,1:-1]=(phi_corr[:,2:]-phi_corr[:,:-2])/(2*dz)
        E[:,:,0]-=E_corr_x;E[:,:,2]-=E_corr_z

print(f"✅ Simulation finished. Total wall time: {time.time()-start_time:.1f}s")
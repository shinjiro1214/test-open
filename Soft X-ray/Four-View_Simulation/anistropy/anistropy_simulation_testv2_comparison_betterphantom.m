function [] = anistropy_simulation_test()
% =========================================================================
%  TS-6 Reconstruction Consistency Check (Shot8) - 3D LUT High Precision
%  
%  Update: 
%  1. LUT is now 3D: (Angle x Pitch x Energy).
%  2. Visualization includes Density, E_para, and E_perp maps.
% =========================================================================
close all; clear; clc;

% --- 1. Path Setup ---
addpath '/Users/shohgookazaki/Documents/GitHub/test-open/pcb_experiment';
addpath '/Users/shohgookazaki/Documents/matlab/common';
addpath '/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Machine_Learning/code';
addpath '/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Four-View/'; 
try
    run define_path.m 
catch
    warning('define_path.m execution failed. Continuing with local paths.');
end

if exist('parametercheck', 'file') ~= 2 || exist('get_distribution', 'file') ~= 2
    error('Required functions (parametercheck, get_distribution) not found.');
end

% --- 2. Load Experimental Data ---
date_target = 251220; shot_idx = 8; time_target = 480;  %異極性スフェロマック合体
% date_target = 251217; shot_idx = 9; time_target = 458; %ST合体
fprintf('--- 1. Loading Exp Data (Shot%d @ %dus) ---\n', shot_idx, time_target);

DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';
if exist('getTS6log','file'), T=getTS6log(DOCID); T=searchlog(T,'date',date_target);
else, T.shot=nan; T.a039=0; T.a040=0; T.a039_TF=0; T.a040_TF=0; T.EF_A_=0; T.TF_kV_=0; end
if isnan(T.shot(1)), T(1, :) = []; end

PCB.date = date_target; PCB.idx = shot_idx;
PCB.shot = [T.a039(shot_idx), T.a040(shot_idx)];
PCB.tfshot = [T.a039_TF(shot_idx), T.a040_TF(shot_idx)];
if PCB.shot == PCB.tfshot, PCB.tfshot = [0,0]; end
PCB.i_EF = T.EF_A_(shot_idx); PCB.TF = T.TF_kV_(shot_idx);
PCB.restart = 0; PCB.chtype = 1; PCB.n = 40; PCB.trange = 400:600;

try
    [grid2D, data2D] = process_PCBdata_280ch(PCB, pathname);
catch ME
    error('Data Load Error: %s', ME.message);
end

t_idx = find(data2D.trange == time_target);
if isempty(t_idx), [~, t_idx] = min(abs(data2D.trange - time_target)); end

Br_exp = data2D.Br(:,:,t_idx); Bz_exp = data2D.Bz(:,:,t_idx);
Bt_exp = data2D.Bt(:,:,t_idx); Psi_exp = data2D.psi(:,:,t_idx);
r_pcb_vec = grid2D.rq(:,1); z_pcb_vec = grid2D.zq(1,:);

F_Br = griddedInterpolant({r_pcb_vec, z_pcb_vec}, Br_exp, 'linear', 'nearest');
F_Bz = griddedInterpolant({r_pcb_vec, z_pcb_vec}, Bz_exp, 'linear', 'nearest');
F_Bt = griddedInterpolant({r_pcb_vec, z_pcb_vec}, Bt_exp, 'linear', 'nearest');
F_Psi = griddedInterpolant({r_pcb_vec, z_pcb_vec}, Psi_exp, 'linear', 'nearest');

% --- 3. Parameters via parametercheck ---
fprintf('--- 2. Loading Parameters ---\n');
N_projection = 30; N_grid = 50; 
[gm2d1, ~, ~, ~, U1, ~, ~, ~, s1, ~, ~, ~, v1, ~, ~, ~, M, K, range, ~, ~] ...
 = parametercheck(N_projection, N_grid);

scale_factor = 1e-3; 
range_m = range * scale_factor; 
zmin = range_m(1); zmax = range_m(2);
rmin = range_m(5); rmax = range_m(6);
N_g = N_grid + 1; 
r_axis = linspace(rmin, rmax, N_g);
z_axis = linspace(zmin, zmax, N_g);
[Z_mesh, R_mesh] = meshgrid(z_axis, r_axis);

Psi_map  = F_Psi({r_axis, z_axis});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- 4. Physics-Based Phantom Generation ---
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('--- 3. Generating Phantom ---\n');

% (A) Define Spatial Distributions (Ne, E_para, E_perp)
R_cen = 0.22; Z_cen = 0.04;

% 1. Density Map (ne): Peaked at center
Ne_map = 1.0e20*exp(-((R_mesh-R_cen).^2/0.03^2 + (Z_mesh-Z_cen).^2/0.06^2)) + ...
         1.0e20*exp(-((R_mesh-(R_cen+0.08)).^2/0.04^2 + (Z_mesh-Z_cen).^2/0.3^2)) + ...
         1.0e20*exp(-((R_mesh-(R_cen-0.08)).^2/0.04^2 + (Z_mesh-Z_cen).^2/0.3^2))+ ...
         1.0e19*exp(-((R_mesh-(R_cen+0.03)).^2/0.04^2 + (Z_mesh-(Z_cen-0.2)).^2/0.04^2))+ ...
         1.0e19*exp(-((R_mesh-R_cen).^2/0.04^2 + (Z_mesh-(Z_cen+0.16)).^2/0.04^2));

% 2. Parallel Energy (E_para) [eV]: High Energy Beam at Core
E_para_map = 80*exp(-((R_mesh-R_cen).^2/0.04^2 + (Z_mesh-Z_cen).^2/0.07^2)) + ...
         80*exp(-((R_mesh-(R_cen+0.08)).^2/0.05^2 + (Z_mesh-Z_cen).^2/0.06^2)) + ...
         80*exp(-((R_mesh-(R_cen-0.08)).^2/0.05^2 + (Z_mesh-Z_cen).^2/0.2^2))+ ...
         10*exp(-((R_mesh-(R_cen+0.03)).^2/0.05^2 + (Z_mesh-(Z_cen-0.2)).^2/0.06^2))+ ...
         10*exp(-((R_mesh-R_cen).^2/0.05^2 + (Z_mesh-(Z_cen+0.16)).^2/0.06^2));

% 3. Perpendicular Energy (E_perp) [eV]: Lower temp, broader
E_perp_map = 20*exp(-((R_mesh-R_cen).^2/0.03^2 + (Z_mesh-Z_cen).^2/0.06^2)) + ...
         20*exp(-((R_mesh-(R_cen+0.08)).^2/0.04^2 + (Z_mesh-Z_cen).^2/0.3^2)) + ...
         20*exp(-((R_mesh-(R_cen-0.08)).^2/0.04^2 + (Z_mesh-Z_cen).^2/0.3^2))+ ...
         10*exp(-((R_mesh-(R_cen+0.03)).^2/0.04^2 + (Z_mesh-(Z_cen-0.2)).^2/0.04^2))+ ...
         10*exp(-((R_mesh-R_cen).^2/0.04^2 + (Z_mesh-(Z_cen+0.16)).^2/0.04^2));

% % ------------Pitch angle plot-----------------
pitch_rad = atan(sqrt(E_perp_map ./ E_para_map));
pitch_deg = rad2deg(pitch_rad);

% % 4. Plot
% figure('Name', 'Pitch Angle Distribution', 'Color', 'w');
% imagesc(z_axis, r_axis, pitch_deg);
% axis xy image;
% colormap('jet'); colorbar;
% xlabel('z [m]'); ylabel('r [m]');
% title('Pitch Angle \alpha = arctan((E_{\perp}/E_{||})^{0.5}) [deg]');
% clim([0 90]); % レンジは見やすさに応じて調整してください

% hold on;
% contour(Z_mesh, R_mesh, Psi_map, 5, 'w', 'LineWidth', 0.5);
% hold off;

% % -------------Emission Intensity calculation-----------------

% (B) Calculate Emission Intensity based on Textbook Formulas
%     Intensity ~ (n_e * n_i * Z^2) / v * g_ff(v, omega)

% --- 物理定数 (SI) ---
h_bar = 1.0545718e-34;  % [J s]
m_e   = 9.10938356e-31; % [kg]
e_c   = 1.60217663e-19; % [C]
eps0  = 8.8541878e-12;  % [F/m]
eV2J  = 1.60217663e-19; 

% 1. 速度マップの計算 (m/s)
E_total_map_eV = E_para_map + E_perp_map;
E_total_map_J  = E_total_map_eV * eV2J;
v_map_ms = sqrt(2 * E_total_map_J / m_e); % [m/s]

% 2. 代表的な光子エネルギーの設定 (Representative Photon Energy)
% ファントム生成用に、軟X線計測で支配的なエネルギー(例: 100eV)を設定
hv_rep_eV = 100.0; 
omega_rep = (hv_rep_eV * eV2J) / h_bar; % [rad/s]

% 3. インパクトパラメータの計算 (画像の式 25, 26)
% b_max (断熱限界): v / omega
b_max = v_map_ms ./ omega_rep;

% b_min (量子限界 vs 古典限界)
b_qm = h_bar ./ (m_e .* v_map_ms);
b_cl = (1.0 * e_c^2) ./ (4 * pi * eps0 * m_e .* (v_map_ms.^2)); % Z=1
b_min = max(b_qm, b_cl);

% 4. Gaunt係数の計算 (画像の式 24)
% g_ff = (sqrt(3)/pi) * ln(b_max / b_min)
arg_log = b_max ./ (b_min + 1e-30); % ゼロ除算防止
arg_log(arg_log < 1.0) = 1.0;       % 定義域保護 (ln(1)=0)
g_ff_map = (sqrt(3)/pi) * log(arg_log);

% 5. 最終的な発光強度マップ I_raw
% I ~ n_e^2 * (1/v) * g_ff
% (注: 画像の最初の式にある係数は定数なので、正規化で消えるため省略)
I_raw = (Ne_map.^2) ./ (v_map_ms + 1e-9) .* g_ff_map;

% Normalize Phantom to Max 5.0
E_true = I_raw / max(I_raw(:)) * 5.0;
E_true(E_true < 0.05) = 0; 

% Create Interpolants for Projection
F_E_true = griddedInterpolant({r_axis, z_axis}, E_true, 'linear', 'none');
F_E_para = griddedInterpolant({r_axis, z_axis}, E_para_map, 'linear', 'nearest');
F_E_perp = griddedInterpolant({r_axis, z_axis}, E_perp_map, 'linear', 'nearest');

% --- 6. Forward Projection ---
fprintf('--- 4. Computing Projections ---\n');
% Lines (mm -> m)
l_up_mm = MCPLine_up(N_projection, 40, false);
l_up = l_up_mm; 
for i=1:numel(l_up)
    l_up(i).x = l_up_mm(i).x * 1e-3; 
    l_up(i).y = l_up_mm(i).y * 1e-3;
    l_up(i).z = l_up_mm(i).z * 1e-3;
end

Geom.rmin = rmin; Geom.rmax = rmax; Geom.zmin = zmin; Geom.zmax = zmax;
Geom.N_g = N_g; Geom.DR = (rmax-rmin)/N_grid; Geom.DZ = (zmax-zmin)/N_grid;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Anisotropy Logic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('--- 5. Pre-calculating Anisotropy 3D LUT (Angle vs Pitch vs Energy) ---\n');
% This process is computationally expensive but done once.

% Load Filter
try
    if exist('readmatrix', 'file'), FData = readmatrix('1umAl.txt', 'NumHeaderLines', 2);
    else, imp = importdata('1umAl.txt', ' ', 2); FData = imp.data; end
    F_Trans = griddedInterpolant(FData(:,1), FData(:,2), 'linear', 'nearest');
catch
    warning('Failed to load 1umAl.txt. Assuming Trans=1.');
    F_Trans = griddedInterpolant([0, 1e4], [1, 1], 'linear', 'nearest');
end

% 3D LUT Axes definition
axis_angle = linspace(0, 180, 60);       % Obs. Angle [deg]
axis_pitch = linspace(0, 90, 45);        % Pitch Angle [deg]
axis_energy = logspace(log10(10), log10(200), 40); % Total Energy [eV] (10eV - 3keV)

fprintf('    Calculating LUT (Size: %dx%dx%d)...\n', length(axis_angle), length(axis_pitch), length(axis_energy));

% --- 外側のループ (Energy) を並列化 ---
n_angle = length(axis_angle);
n_pitch = length(axis_pitch);
n_energy = length(axis_energy);

% 出力配列の事前確保
LUT_3D = zeros(n_angle, n_pitch, n_energy);

for ie = 1:n_energy
    e_tot = axis_energy(ie);
    
    % このEnergyステップ計算結果を一時保存する2次元配列 (Angle x Pitch)
    % これを作るとメモリアクセスエラーが起きにくい
    lut_slice = zeros(n_angle, n_pitch);
    
    for ip = 1:n_pitch
        p_deg = axis_pitch(ip);
        
        % Split Energy logic
        if p_deg == 90
            e_pa = 0;
            e_pe = e_tot;
        else
            e_pa = e_tot * (cosd(p_deg)^2);
            e_pe = e_tot * (sind(p_deg)^2);
        end
        
        % ★重要: 構造体をループ内で「新規作成」して独立性を保つ
        LocalPhys = struct();
        LocalPhys.E_para = e_pa;
        LocalPhys.E_perp = e_pe;
        
        % Angleループ (ここは計算量が少ないので通常のforでよい)
        temp_ang_profile = zeros(n_angle, 1);
        for ia = 1:n_angle
            ang_deg = axis_angle(ia);
            % helper関数にはLocalPhysを渡す
            temp_ang_profile(ia) = calculate_python_model_emission(ang_deg, LocalPhys, F_Trans);
        end
        
        % 一時配列に格納
        lut_slice(:, ip) = temp_ang_profile;
    end
    
    % ★重要: まとめて代入 (parforのスライシング要件を満たすため)
    LUT_3D(:, :, ie) = lut_slice;
    
    % parfor内では進捗表示が順不同になるが、目安として表示
    fprintf('    Energy Step %d/%d Done (Worker processed).\n', ie, n_energy);
end
% LUT_3D = ones(size(LUT_3D)); % 全角度で強度1.0

% --- 正規化  ---
% ファントム値がすでに「放射強度」なので、ここでの係数は0～1の相対値にする
max_lut = max(LUT_3D(:));
if max_lut > 0
    LUT_3D = LUT_3D / max_lut;
end

F_LUT_3D = griddedInterpolant({axis_angle, axis_pitch, axis_energy}, LUT_3D, 'linear', 'nearest');

%%%%%%%%%%%3DLUTを見てみる%%%%%%%%%%%%%%%%%%%%
view_anisotropy_lut(LUT_3D, axis_angle, axis_pitch, axis_energy)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('--- 5.5. Anisotropy Verification (Diff Check: 3D LUT) ---\n');

% -------------------------------------------------------------------------
% 1. 等方ケース (Isotropic Run)
% -------------------------------------------------------------------------
% is_isotropic = true を渡すと、関数内で強制的に係数 1.0 が使用されます
fprintf('   Calculating Isotropic Projection (Target for Reconstruction)...\n');
S_iso_m = Compute_Projection_Physics(l_up, Geom, F_E_true, F_E_para, F_E_perp, F_Br, F_Bz, F_Bt, F_LUT_3D, true);
S_iso = S_iso_m * 100; % [m] -> [cm] or scale adjustment

% -------------------------------------------------------------------------
% 2. 異方ケース (Anisotropic Run)
% -------------------------------------------------------------------------
% is_isotropic = false を渡すと、3D LUT (Angle, Pitch, Energy) を参照します
fprintf('   Calculating Anisotropic Projection (Physical Reality)...\n');
S_aniso_m = Compute_Projection_Physics(l_up, Geom, F_E_true, F_E_para, F_E_perp, F_Br, F_Bz, F_Bt, F_LUT_3D, false);
S_aniso = S_aniso_m * 100; 

% -------------------------------------------------------------------------
% 3. 差分と変化率の計算
% -------------------------------------------------------------------------
S_diff = S_aniso - S_iso;                     % 差分 (Aniso - Iso)
S_ratio = (S_diff ./ (S_iso + 1e-9)) * 100;   % 変化率 [%]

fprintf('   Max Difference: %.2e\n', max(abs(S_diff(:))));
fprintf('   Max Ratio:      %.1f %%\n', max(abs(S_ratio(:))));

% --- 結果のプロット (差分確認専用) ---
figure('Name', 'Anisotropy Effect Verification (3D LUT)', 'Position', [100, 100, 1200, 500]);
k_circle = FindCircle(N_projection/2);

% 共通のカラースケール設定 (等方データを基準にする)
c_max = max(S_iso(:));
c_limits = [0, c_max];

% Plot 1: Isotropic (Base)
subplot(1, 3, 1);
Img_Iso = zeros(N_projection); Img_Iso(k_circle) = S_iso;
imagesc(Img_Iso'); axis image; axis off; colorbar;
title('Isotropic Assumption (Factor=1.0)');
clim(c_limits);

% Plot 2: Anisotropic (Target)
subplot(1, 3, 2);
Img_Aniso = zeros(N_projection); Img_Aniso(k_circle) = S_aniso;
imagesc(Img_Aniso'); axis image; axis off; colorbar;
title('Anisotropic Reality (3D LUT)');
clim(c_limits);

% Plot 3: Difference Ratio [%]
subplot(1, 3, 3);
Img_Ratio = zeros(N_projection); Img_Ratio(k_circle) = S_ratio;
imagesc(Img_Ratio'); axis image; axis off; colorbar;
title('Difference Ratio [%] (Aniso - Iso)');
colormap(gca, flipud(jet)); 
% 変化が見やすいようにレンジを調整 (例: -20% ~ +20%)
% clim([-20 20]); 

% --- メイン変数の更新 ---
% 観測データとして「異方性あり（現実）」を採用し、後の再構成（等方性仮定）に回す
S_obs_val = S_aniso;




% --- Create Clean Camera Image ---
k_circle = FindCircle(N_projection/2);
Img_clean = zeros(N_projection);
Img_clean(k_circle) = S_obs_val;
Img_clean = Img_clean'; 

% --- Noise Addition ---
fprintf('    Adding Noise (10%%)...\n');
SNR_dB = 10 * log10(10); 
S_obs_noisy = awgn(S_obs_val, SNR_dB, 'measured');
S_obs_noisy(S_obs_noisy < 0) = 0; 

Img_noisy = zeros(N_projection);
Img_noisy(k_circle) = S_obs_noisy;
Img_noisy = Img_noisy';

VectorImage1 = S_obs_noisy'; 


% --- 5. Reconstruction ---
fprintf('--- 6. Running get_distribution ---\n');

fprintf('  - Method 0: Tikhonov\n');
EE0 = get_distribution(M, K, gm2d1, U1, s1, v1, VectorImage1, false, 0, N_projection);

fprintf('  - Method 1: MFI\n');
EE1 = get_distribution(M, K, gm2d1, U1, s1, v1, VectorImage1, false, 1, N_projection);

fprintf('  - Method 2: MEM\n');
EE2 = get_distribution(M, K, gm2d1, U1, s1, v1, VectorImage1, false, 2, N_projection);


% --- 6. Plotting Results (Updated: 3x3 Layout) ---
fprintf('--- 5. Plotting (3x3 Layout with Physics Inputs) ---\n');
figure('Name', 'Check: Shot8 Full Process View', 'Position', [50, 50, 1600, 1000]); % 高さを増やしました

% プロットするデータのリスト (全9枚)
% 1-3: 入力物理量, 4-6: 中間データ, 7-9: 結果
plot_data_list = {Ne_map, E_para_map, E_perp_map, ...
                  E_true, pitch_deg, Img_noisy, ...
                  EE0, EE1, EE2};

title_list = {'Input: Density (n_e)', 'Input: E_{||} [eV]', 'Input: E_{\perp} [eV]', ...
              'Ground Truth (Emission)', 'Pitch Angle [deg]', 'Camera View (10% Noise)', ...
              'Tikhonov (Meth=0)', 'MFI (Meth=1)', 'MEM (Meth=2)'};

% R-Z平面か、カメラ画像か (True=RZ, False=Camera)
is_rz_plane = [true, true, true, ...
               true, true, false, ...
               true, true, true];

% カラーレンジの固定 (Emission系のみ [0 5] に固定し、入力パラメータはAutoスケールにする)
% 1:Density, 2:E_para, 3:E_perp はオートスケール
% 4:Phantom 以降は Emission なので固定
use_fixed_clim = [false, false, false, ...
                  true, true, true, ...
                  true, true, true];
fixed_range = [0 5]; 

for i = 1:9
    subplot(3, 3, i);
    img_data = plot_data_list{i};
    
    if is_rz_plane(i)
        % --- R-Z断面のプロット ---
        imagesc(z_axis, r_axis, img_data);
        axis xy; axis image;
        xlabel('Z [m]'); ylabel('R [m]');
        ylim([0.05 0.33])
        
        % 磁束面の重ね書き (すべてのRZプロットに適用)
        hold on;
        [~, h] = contour(Z_mesh, R_mesh, Psi_map, 15, 'w'); 
        h.LineWidth = 0.5; h.EdgeAlpha = 0.5;
        hold off;
    else
        % --- カメラ画像のプロット ---
        imagesc(img_data);
        axis image; axis off;
    end
    
    title(title_list{i});
    colorbar;
    
    % レンジ設定 (入力パラメータは見やすくするためAuto、結果比較は統一スケール)
    if i == 5 
        clim([0 90])
    elseif ~is_rz_plane(i)
        clim([0 100]);
    elseif use_fixed_clim(i)
        clim(fixed_range);
    else
        % オートスケール (下限0)
        clim([0, max(img_data(:))]); 
    end
end

fprintf('--- Done ---\n');
end


% =========================================================================
%  Helper Functions
% =========================================================================

function [S_obs] = Compute_Projection_Physics(l_struct, G, F_E, F_E_pa, F_E_pe, F_Br, F_Bz, F_Bt, F_LUT, is_isotropic)
    % --- Setup ---
    rmin=G.rmin; rmax=G.rmax; zmin=G.zmin; zmax=G.zmax; N_g=G.N_g;
    
    N_p = numel(l_struct);
    S_vals = zeros(N_p, 1);
    
    % Interpolantの高速化設定（もし可能なら）
    % F_E.Method = 'linear'; F_E.ExtrapolationMethod = 'none';

    parfor i = 1:N_p
        % 1. Extract Line Coordinates (Force Column Vector)
        rx = l_struct(i).x(:); 
        ry = l_struct(i).y(:); 
        rz = l_struct(i).z(:);
        
        if isempty(rx), continue; end % 空ならスキップ

        % 2. Filter valid points (Inside Chamber)
        rr = sqrt(rx.^2 + ry.^2);
        idx = (rr >= rmin) & (rr <= rmax) & (rz >= zmin) & (rz <= zmax);
        
        if any(idx)
            % Extract valid segments (Result is always Column due to (:))
            p_x = rx(idx); 
            p_y = ry(idx); 
            p_z = rz(idx);
            p_r = rr(idx); 
            
            % Check if we have enough points for line integral
            n_points = length(p_x);
            if n_points < 2
                continue; 
            end

            % 3. Calculate Path Length (dL) - Robust
            % 座標間の距離を計算
            d_vec = sqrt(diff(p_x).^2 + diff(p_y).^2 + diff(p_z).^2);
            % 最後の点は直前のステップと同じと仮定して埋める (縦ベクトル結合)
            dL = [d_vec; d_vec(end)]; 
            
            % 4. Batch Interpolation
            query_points = [p_r, p_z]; % [N x 2] matrix
            
            % Phantom Intensity
            intensities = F_E(query_points);
            
            % Process only if there is significant intensity
            % NaNチェックも追加
            valid_int_idx = (intensities > 1e-4) & ~isnan(intensities);
            
            if any(valid_int_idx)
                % Filter to active points
                q_pts_a = query_points(valid_int_idx, :);
                int_a = intensities(valid_int_idx);
                dL_a = dL(valid_int_idx);
                
                % Coordinates for active points
                p_x_a = p_x(valid_int_idx);
                p_y_a = p_y(valid_int_idx);
                p_r_a = p_r(valid_int_idx);

                aniso_factors = ones(size(int_a));
                
                if ~is_isotropic
                    % 2. Calculate Local Physics Parameters
                    e_para_local = F_E_pa(q_pts_a);
                    e_perp_local = F_E_pe(q_pts_a);
                    e_total_local = e_para_local + e_perp_local; % Total Energy

                    % Local Pitch Angle [deg]
                    pitch_rad = atan2(sqrt(e_perp_local), sqrt(e_para_local));
                    pitch_deg = rad2deg(pitch_rad);

                    % Magnetic Field Interpolation
                    br = F_Br(q_pts_a); 
                    bz = F_Bz(q_pts_a); 
                    bt = F_Bt(q_pts_a);
                    
                    % 5. Coordinate Transform
                    inv_r = 1 ./ p_r_a;
                    cp = p_x_a .* inv_r; % cos(phi) = x/r
                    sp = p_y_a .* inv_r; % sin(phi) = y/r
                    
                    Bx = br .* cp - bt .* sp; %円等座標Brtzから直交座標Bxyzへの回転
                    By = br .* sp + bt .* cp;
                    Bz = bz;
                    
                    % 6. Angle Calculation
                    % LOS Direction (Global for this ray)
                    dir_vec = [rx(end)-rx(1), ry(end)-ry(1), rz(end)-rz(1)];
                    dir_norm = norm(dir_vec);
                    if dir_norm < 1e-9
                        dir_vec = [0 0 1]; % Fallback
                    else
                        dir_vec = dir_vec / dir_norm;
                    end
                    
                    % B-field Norm
                    B_norm = sqrt(Bx.^2 + By.^2 + Bz.^2) + 1e-9;
                    
                    % Dot product (Vectorized)
                    % dir_vec is 1x3, B is Nx1 each.
                    cos_theta = (dir_vec(1)*Bx + dir_vec(2)*By + dir_vec(3)*Bz) ./ B_norm;
                    
                    theta_deg = acosd(min(max(cos_theta, -1), 1));
                    
                    % 7. Anisotropy Factor Lookup
                    aniso_factors = F_LUT(theta_deg, pitch_deg, e_total_local);
                end
                % 8. Integration (Sum)
                % Ensure result is scalar
                val_S = sum(int_a .* aniso_factors .* dL_a, 'all', 'omitnan');
                S_vals(i) = val_S;
            end
        end
    end
    
    S_obs = S_vals;
end

function I_integ = calculate_python_model_emission(theta_deg, Phys, F_Trans)
    % ---------------------------------------------------------------------
    % Textbook Model with Explicit Impact Parameters (b_max, b_min)
    % 
    % 物理モデル:
    %   g_ff = (sqrt(3)/pi) * ln(b_max / b_min)
    % 
    %   b_max = v / omega  (断熱限界: これ以上遠いと放射しない)
    %   b_min = h_bar / (m*v) (量子限界: 不確定性原理による最小距離)
    %           or Ze^2 / (m*v^2) (古典限界) の大きい方
    % ---------------------------------------------------------------------
    
    % --- 物理定数 (SI単位) ---
    h_bar = 1.0545718e-34;  % ディラック定数 [J·s]
    m_e   = 9.10938356e-31; % 電子質量 [kg]
    e_c   = 1.60217663e-19; % 電気素量 [C]
    eps0  = 8.8541878e-12;  % 真空の誘電率 [F/m]
    
    % eV -> Joule 変換係数
    eV2J = 1.60217663e-19;
    
    % --- Electron Kinematics ---
    E_para = Phys.E_para; 
    E_perp = Phys.E_perp;
    E_kin_eV = E_para + E_perp; 
    E_kin_J  = E_kin_eV * eV2J; % ジュール単位
    
    % 速度 v の計算 (非相対論で十分だが精度のため相対論を使用)
    mc2_J = m_e * (2.9979e8)^2;
    gamma = 1.0 + E_kin_J / mc2_J;
    beta  = sqrt(1.0 - 1.0/gamma^2);
    if beta < 1e-5, beta = 1e-5; end
    
    v_electron = beta * 2.9979e8; % 電子の速度 [m/s]
    
    % Pitch Angle
    pitch_angle = atan2(sqrt(E_perp), sqrt(E_para));
    
    % --- Geometry ---
    theta_rad = deg2rad(theta_deg);
    n_obs = [sin(theta_rad), 0, cos(theta_rad)];
    gyro_phases = linspace(0, 2*pi, 36); 
    
    % --- Spectral Integration ---
    h_nu_list = linspace(10, E_kin_eV*0.99, 50); 
    if isempty(h_nu_list), I_integ = 0; return; end
    d_h_nu = h_nu_list(2) - h_nu_list(1);
    
    total_val = 0;
    
    for k = 1:length(h_nu_list)
        hv_eV = h_nu_list(k);
        hv_J  = hv_eV * eV2J; % 光子エネルギー [J]
        
        T_filter = F_Trans(hv_eV);
        if T_filter <= 0, continue; end
        
        % === b_max, b_min の直接計算 ===
        
        % 1. 角振動数 omega [rad/s]
        % E = h_bar * omega  =>  omega = E / h_bar
        omega = hv_J / h_bar;
        
        % 2. b_max (Interaction Range / Adiabatic Limit)
        % 電子が通り過ぎる時間 (b/v) が 振動周期 (1/omega) より短い範囲
        b_max = v_electron / omega;
        
        % 3. b_min (Closest Approach)
        % 量子力学的な限界 (de Broglie wavelength)
        b_qm = h_bar / (m_e * v_electron);
        
        % 古典的な限界 (Classical distance of closest approach)
        % Coulomb potential energy ~ Kinetic energy
        Z = 1;
        b_cl = (Z * e_c^2) / (4 * pi * eps0 * m_e * v_electron^2);
        
        % 実際には「不確定性原理」か「反発力」のどちらか大きい方で止まる
        b_min = max(b_qm, b_cl);
        
        % 4. ガント係数の計算
        % 対数の中身 (Impact Parameter Ratio)
        lambda_b = b_max / b_min;
        
        % 対数が負にならないようクリップ
        if lambda_b < 1.0, lambda_b = 1.0; end
        
        % 画像の式: g_ff = (sqrt(3)/pi) * ln(b_max/b_min)
        g_ff = (sqrt(3)/pi) * log(lambda_b);
        
        % 教科書の "～1のオーダー" に従い下限処理
        % if g_ff < 1.0, g_ff = 1.0; end
        
        
        % === 放射強度 (Intensity) ===
        % (1/v) * g_ff * (光子数換算 1/hv)
        I_scale = (1.0 / v_electron) * g_ff * (1.0 / hv_eV);
        
        % --- Angular Distribution (双極子放射) ---
        sum_sigma = 0;
        for ip = 1:length(gyro_phases)
            phi = gyro_phases(ip);
            % n_i = [sin(pitch_angle)*cos(phi), sin(pitch_angle)*sin(phi), cos(pitch_angle)];
            % cos_Theta = dot(n_i, n_obs);
            % sum_sigma = sum_sigma + (1.0 - cos_Theta^2);

            % 1. 電子の速度ベクトル (v_hat)
            % ジャイロ回転(phi)とピッチ角(pitch_angle)から決定
            v_hat = [sin(pitch_angle)*cos(phi), sin(pitch_angle)*sin(phi), cos(pitch_angle)];

            % 2. 観測方向との内積 (cos_Theta)
            v_dot_n = dot(v_hat, n_obs);

            % 3. イオンの位置確率に基づく厳密計算
            % 「速度に垂直なあらゆる方向の加速度」について sin^2(角) を積分した結果
            % 結果は必ず (1 + cos^2(速度との角)) に比例します。
            current_sigma = 1.0 + v_dot_n^2;

            sum_sigma = sum_sigma + current_sigma;
        end
        avg_shape = sum_sigma / length(gyro_phases);
        
        % 積分
        total_val = total_val + I_scale * avg_shape * T_filter * d_h_nu;
    end
    
    I_integ = total_val;
end

function k = FindCircle(L)
    R = zeros(2*L);
    for i = 1:2*L, for j = 1:2*L, R(i,j) = sqrt((L-i+0.5)^2+(j-L-0.5)^2); end, end
    k = find(R<L);
end

function l = MCPLine_up(N_projection,Z_hole,plot_flag)
    d_hole = 24.4; r_mcp=10; Y_hole = 413.24+12; X_hole = 208.13;
    Y_init=Y_hole+d_hole; X_init=X_hole-r_mcp; Z_init=Z_hole+r_mcp;
    X_end=X_hole+r_mcp; Z_end=Z_hole-r_mcp;
    Nh=N_projection-1; Dhx=(X_end-X_init)/Nh; Dhz=(Z_end-Z_init)/Nh;
    X=X_init:Dhx:X_end; Z=Z_init:Dhz:Z_end; Y=repelem(Y_init,N_projection);
    r_center=55; r_device=375;
    ll(N_projection,N_projection) = struct('x',[],'y',[],'z',[]);
    for i=1:N_projection
        for j=1:N_projection
            ll(i,j).y=Y(j):-10:-400; len_y = length(ll(i,j).y);
            ll(i,j).x=(ll(i,j).y-Y_hole)*(X(i)-X_hole)/(Y(j)-Y_hole)+X_hole;
            ll(i,j).z=(ll(i,j).y-Y_hole)*(Z(j)-Z_hole)/(Y(j)-Y_hole)+Z_hole;
            r = sqrt(ll(i,j).y.^2+ll(i,j).x.^2);
            A = find(r<=r_center);
            if ~isempty(A), obs=A(1)-1; 
                ll(i,j).x=[repelem(ll(i,j).x(1),len_y-obs) ll(i,j).x(1:obs)];
                ll(i,j).y=[repelem(ll(i,j).y(1),len_y-obs) ll(i,j).y(1:obs)];
                ll(i,j).z=[repelem(ll(i,j).z(1),len_y-obs) ll(i,j).z(1:obs)];
            end
            B = find(r>=r_device & ll(i,j).y<=0);
            if ~isempty(B), obs=B(1)-1;
                ll(i,j).x=[repelem(ll(i,j).x(1),len_y-obs) ll(i,j).x(1:obs)];
                ll(i,j).y=[repelem(ll(i,j).y(1),len_y-obs) ll(i,j).y(1:obs)];
                ll(i,j).z=[repelem(ll(i,j).z(1),len_y-obs) ll(i,j).z(1:obs)];
            end
        end
    end
    k = FindCircle(N_projection/2); l = ll(k); 
end

function view_anisotropy_lut(LUT_3D, axis_angle, axis_pitch, axis_energy)
% VIEW_ANISOTROPY_LUT Interactive viewer for 3D Anisotropy LUT
%
% Usage:
%   view_anisotropy_lut(LUT_3D, axis_angle, axis_pitch, axis_energy)

    fprintf('Launching Interactive Viewer...\n');

    % --- 1. 初期化 ---
    idx_E = round(length(axis_energy) / 2); 
    idx_P = round(length(axis_pitch) / 2);  

    % --- 2. フィギュアとレイアウトの作成 ---
    hFig = figure('Name', 'Interactive Anisotropy Viewer', ...
                  'Position', [200, 200, 1000, 600], 'Color', 'w', ...
                  'NumberTitle', 'off');

    % 左側：直交座標プロット (XY Plot)
    ax1 = axes('Parent', hFig, 'Position', [0.1, 0.4, 0.35, 0.5]);
    grid(ax1, 'on'); 
    xlabel(ax1, 'Obs. Angle (deg) [0=B-field]');
    ylabel(ax1, 'Normalized Intensity');
    title(ax1, 'Profile (XY)');
    ylim(ax1, [0 1.1]); 
    xlim(ax1, [min(axis_angle) max(axis_angle)]);

    % 右側：極座標プロット (Polar Plot)
    % ★修正点: axesではなくpolaraxesを使用します
    ax2 = polaraxes('Parent', hFig, 'Position', [0.55, 0.4, 0.35, 0.5]);
    ax2.ThetaZeroLocation = 'top'; % 上を0度(磁場方向)にする
    ax2.ThetaDir = 'clockwise';    % 時計回りに角度が増える
    title(ax2, 'Emission Shape (Polar)');
    rlim(ax2, [0 1.1]);
    
    % 初期データ抽出
    current_profile = squeeze(LUT_3D(:, idx_P, idx_E));
    
    % 直交座標の初期描画
    hold(ax1, 'on');
    hLine = plot(ax1, axis_angle, current_profile, 'LineWidth', 2, 'Color', 'b');
    yline(ax1, 1, 'k--', 'Alpha', 0.3); % ガイドライン
    hold(ax1, 'off');

    % 極座標の初期描画
    hold(ax2, 'on');
    % polarplotは (theta[rad], rho) の順
    hPol = polarplot(ax2, deg2rad(axis_angle), current_profile', 'LineWidth', 2, 'Color', 'r');
    hold(ax2, 'off');


    % --- 3. UIコントロール (スライダーとテキスト) ---

    % --- Energy Control ---
    uicontrol('Parent', hFig, 'Style', 'text', 'Position', [150, 120, 100, 20], ...
              'String', 'Energy [eV]', 'FontWeight', 'bold', 'BackgroundColor', 'w');
          
    txt_E = uicontrol('Parent', hFig, 'Style', 'text', 'Position', [260, 120, 100, 20], ...
                      'String', sprintf('%.1f eV', axis_energy(idx_E)), 'BackgroundColor', 'w', 'HorizontalAlignment', 'left');

    sld_E = uicontrol('Parent', hFig, 'Style', 'slider', 'Position', [150, 100, 700, 20], ...
                      'Min', 1, 'Max', length(axis_energy), 'Value', idx_E, ...
                      'SliderStep', [1/(length(axis_energy)-1), 10/(length(axis_energy)-1)]);

    % --- Pitch Angle Control ---
    uicontrol('Parent', hFig, 'Style', 'text', 'Position', [150, 70, 100, 20], ...
              'String', 'Pitch Angle [deg]', 'FontWeight', 'bold', 'BackgroundColor', 'w');

    txt_P = uicontrol('Parent', hFig, 'Style', 'text', 'Position', [260, 70, 100, 20], ...
                      'String', sprintf('%.1f deg', axis_pitch(idx_P)), 'BackgroundColor', 'w', 'HorizontalAlignment', 'left');

    sld_P = uicontrol('Parent', hFig, 'Style', 'slider', 'Position', [150, 50, 700, 20], ...
                      'Min', 1, 'Max', length(axis_pitch), 'Value', idx_P, ...
                      'SliderStep', [1/(length(axis_pitch)-1), 10/(length(axis_pitch)-1)]);

    % --- 4. コールバック関数の設定 ---
    sld_E.Callback = @updatePlots;
    sld_P.Callback = @updatePlots;

    % --- ネストされた更新関数 ---
    function updatePlots(~, ~)
        % スライダーからインデックス取得
        iE = round(sld_E.Value);
        iP = round(sld_P.Value);
        
        % データ更新
        val_E = axis_energy(iE);
        val_P = axis_pitch(iP);
        
        % LUTから抽出 (Angle, Pitch, Energy)
        new_data = squeeze(LUT_3D(:, iP, iE));
        
        % グラフデータの更新
        hLine.YData = new_data;
        hPol.RData = new_data;
        
        % テキスト更新
        txt_E.String = sprintf('%.1f eV', val_E);
        txt_P.String = sprintf('%.1f deg', val_P);
    end

end
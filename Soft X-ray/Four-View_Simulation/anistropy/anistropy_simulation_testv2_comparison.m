function [] = anistropy_simulation_test()
% =========================================================================
%  TS-6 Reconstruction Consistency Check (Shot8) - Anisotropy Fix
%  Phantom = Radiation Intensity at optimal angle.
%  Projection = Integral ( Phantom * Anisotropy_Factor(0 to 1) ) dl
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
date_target = 251220; shot_idx = 8; time_target = 480;
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


% --- 4. Phantom & Projection ---
fprintf('--- 3. Phantom Generation (Max=5) & Forward Projection ---\n');

% Phantom (Ground Truth)
R_cen = 0.22; 
E_true = 1.0*exp(-((R_mesh-R_cen).^2/0.03^2 + (Z_mesh-0).^2/0.06^2)) + ...
         0.8*exp(-((R_mesh-(R_cen+0.10)).^2/0.04^2 + (Z_mesh-0).^2/0.05^2)) + ...
         0.8*exp(-((R_mesh-(R_cen-0.09)).^2/0.04^2 + (Z_mesh-0).^2/0.05^2));
E_true(E_true<0.01)=0; 
E_true = E_true / max(E_true(:)) * 5.0; % Scale to Max 5

F_E_true  = griddedInterpolant({r_axis, z_axis}, E_true, 'linear', 'none');
Psi_map = F_Psi({r_axis, z_axis});

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


% -------------------------------------------------------------------------
% [CRITICAL FIX] Anisotropy Logic
% -------------------------------------------------------------------------
fprintf('    Generating Physics Emission Table (Normalized)...\n');
Phys.E_para = 80.0; % [eV]
Phys.E_perp = 10.0;  % [eV]

try
    if exist('readmatrix', 'file'), FData = readmatrix('1umAl.txt', 'NumHeaderLines', 2);
    else, imp = importdata('1umAl.txt', ' ', 2); FData = imp.data; end
    F_Trans = griddedInterpolant(FData(:,1), FData(:,2), 'linear', 'nearest');
catch
    error('Failed to load 1umAl.txt.');
end

% Pre-calculate Emission Table
angle_lut = linspace(0, 180, 181);
intensity_lut = zeros(size(angle_lut));
for i = 1:length(angle_lut)
    intensity_lut(i) = calculate_python_model_emission(angle_lut(i), Phys, F_Trans);
end

% intensity_lut = ones(size(angle_lut)); % 全角度で強度1.0

% --- 正規化 (重要) ---
% ファントム値がすでに「放射強度」なので、ここでの係数は0～1の相対値にする
max_val = max(intensity_lut);
if max_val > 0
    intensity_lut = intensity_lut / max_val;
end

Phys.LUT_Angle = angle_lut;
Phys.LUT_Intensity = intensity_lut;
F_Emission_LUT = griddedInterpolant(Phys.LUT_Angle, Phys.LUT_Intensity, 'linear', 'nearest');

% figure; 
% plot(Phys.LUT_Angle, Phys.LUT_Intensity, 'LineWidth', 2);
% title('Anisotropy Factor (LUT)');
% xlabel('Angle from B-field [deg]'); ylabel('Intensity Factor');
% grid on;



fprintf('--- 3.5. Anisotropy Verification (Diff Check) ---\n');

% 1. 等方ケース (Isotropic Run): LUTを強制的に全部 1.0 にする
F_LUT_Iso = griddedInterpolant(Phys.LUT_Angle, ones(size(Phys.LUT_Angle)), 'linear', 'nearest');
[~, S_iso_m] = Compute_Projection_Normalized(l_up, Geom, Phys, F_E_true, F_Br, F_Bz, F_Bt, F_LUT_Iso);
S_iso = S_iso_m * 100; % mmスケールに合わせる

% 2. 異方ケース (Anisotropic Run): 本来の物理LUTを使う
F_LUT_Aniso = griddedInterpolant(Phys.LUT_Angle, Phys.LUT_Intensity, 'linear', 'nearest');
[~, S_aniso_m] = Compute_Projection_Normalized(l_up, Geom, Phys, F_E_true, F_Br, F_Bz, F_Bt, F_LUT_Aniso);
S_aniso = S_aniso_m * 100; % mmスケールに合わせる

% 3. 差分と変化率の計算
S_diff = S_aniso - S_iso;                     % 単純な引き算
S_ratio = (S_diff ./ (S_iso + 1e-9)) * 100;   % 変化率 [%]

% --- 結果のプロット (差分確認専用) ---
figure('Name', 'Anisotropy Effect Verification', 'Position', [100, 100, 1200, 500]);
k_circle = FindCircle(N_projection/2);

% Plot 1: Isotropic (Base)
subplot(1, 3, 1);
Img_Iso = zeros(N_projection); Img_Iso(k_circle) = S_iso;
imagesc(Img_Iso'); axis image; axis off; colorbar;
title('Isotropic (LUT=1.0)');
clim([0, max(S_iso(:))]);

% Plot 2: Anisotropic (Target)
subplot(1, 3, 2);
Img_Aniso = zeros(N_projection); Img_Aniso(k_circle) = S_aniso;
imagesc(Img_Aniso'); axis image; axis off; colorbar;
title('Anisotropic (Physical)');
clim([0, max(S_iso(:))]); % レンジを等方に合わせることで変化を見やすくする

% Plot 3: Difference Ratio [%] (最も重要)
subplot(1, 3, 3);
Img_Ratio = zeros(N_projection); Img_Ratio(k_circle) = S_ratio;
imagesc(Img_Ratio'); axis image; axis off; colorbar;
title('Difference Ratio [%] (Aniso - Iso)');
colormap(gca, 'jet'); % 変化が見やすいカラーマップ
% clim([-10, 10]); % 必要ならレンジを固定 (例: +/- 10%の変化を見る)

% --- メインの変数を異方性の結果で更新 ---
S_obs_val = S_aniso; % 後の再構成プロセスには異方性の結果を渡す
fprintf('   Max Difference: %.2f (%.1f %%)\n', max(abs(S_diff(:))), max(abs(S_ratio(:))));





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
fprintf('--- 4. Running get_distribution (No Plot) ---\n');

fprintf('  - Method 0: Tikhonov\n');
EE0 = get_distribution(M, K, gm2d1, U1, s1, v1, VectorImage1, false, 0, N_projection);

fprintf('  - Method 1: MFI\n');
EE1 = get_distribution(M, K, gm2d1, U1, s1, v1, VectorImage1, false, 1, N_projection);

fprintf('  - Method 2: MEM\n');
EE2 = get_distribution(M, K, gm2d1, U1, s1, v1, VectorImage1, false, 2, N_projection);


% --- 6. Plotting Results ---
fprintf('--- 5. Plotting (2x3 Layout) ---\n');
figure('Name', 'Check: Shot8 Full Process View', 'Position', [50, 50, 1600, 800]);

plot_data_list = {E_true, Img_clean, Img_noisy, EE0, EE1, EE2};
title_list = {'Ground Truth (Phantom)', 'Camera View (Clean)', 'Camera View (10% Noise)', ...
              'Tikhonov (Meth=0)', 'MFI (Meth=1)', 'MEM (Meth=2)'};
is_rz_plane = [true, false, false, true, true, true];

c_range = [0 5]; 

for i = 1:6
    subplot(2, 3, i);
    img_data = plot_data_list{i};
    
    if is_rz_plane(i)
        imagesc(z_axis, r_axis, img_data);
        axis xy; axis image;
        xlabel('Z [m]'); ylabel('R [m]');
        hold on;
        [~, h] = contour(Z_mesh, R_mesh, Psi_map, 15, 'w'); 
        h.LineWidth = 0.8; h.EdgeAlpha = 0.6;
        hold off;
    else
        imagesc(img_data);
        axis image; axis off;
    end
    
    title(title_list{i});
    colorbar; clim(c_range);
end

fprintf('--- Done ---\n');

end


% =========================================================================
%  Helper Functions
% =========================================================================

function [L_iso, S_obs] = Compute_Projection_Normalized(l_struct, G, P, F_E, F_Br, F_Bz, F_Bt, F_LUT)
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
                
                % Magnetic Field Interpolation
                br = F_Br(q_pts_a); 
                bz = F_Bz(q_pts_a); 
                bt = F_Bt(q_pts_a);
                
                % 5. Coordinate Transform
                inv_r = 1 ./ p_r_a;
                cp = p_x_a .* inv_r; 
                sp = p_y_a .* inv_r;
                
                Bx = br .* cp - bt .* sp;
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
                
                % Clip for safety
                cos_theta(cos_theta > 1) = 1; 
                cos_theta(cos_theta < -1) = -1;
                
                theta_deg = acosd(cos_theta);
                
                % 7. Anisotropy Factor Lookup
                aniso_factors = F_LUT(theta_deg);
                
                % 8. Integration (Sum)
                % Ensure result is scalar
                val_S = sum(int_a .* aniso_factors .* dL_a, 'all', 'omitnan');
                S_vals(i) = val_S;
            end
        end
    end
    
    S_obs = S_vals;
    L_iso = sparse(N_p, N_g^2); 
end

function I_integ = calculate_python_model_emission(theta_deg, Phys, F_Trans)
    m_e_eV = 510998.95; Z_Ar = 1.0;
    v_para = Phys.E_para; v_perp = Phys.E_perp;
    E_kin = v_para + v_perp;
    
    pitch_angle = atan2(sqrt(v_perp), sqrt(v_para));
    gamma = 1.0 + E_kin / m_e_eV;
    beta = sqrt(1.0 - 1.0/gamma^2); if beta < 1e-5, beta = 1e-5; end
    
    theta_rad = deg2rad(theta_deg);
    n_obs = [sin(theta_rad), 0, cos(theta_rad)];
    gyro_phases = linspace(0, 2*pi, 36);
    
    h_nu_list = linspace(10, E_kin-1, 50); 
    if isempty(h_nu_list), I_integ = 0; return; end
    d_h_nu = h_nu_list(2) - h_nu_list(1);
    
    total_val = 0;
    for k = 1:length(h_nu_list)
        hv = h_nu_list(k);
        T_filter = F_Trans(hv);
        if T_filter <= 0, continue; end
        
        nu_ratio = hv / E_kin;
        g_ff = (sqrt(3)/pi) * log(4.0/nu_ratio); if g_ff < 1.0, g_ff = 1.0; end
        
        % Spectral Weight
        I_scale = (Z_Ar^2 / beta^2) * g_ff * (1/hv);
        
        if nu_ratio < 0, P = 0; elseif nu_ratio > 1, P = 1; else, P = nu_ratio * (1.35 - 0.35 * nu_ratio); end
        
        sum_I_gyro = 0;
        for ip = 1:length(gyro_phases)
            phi = gyro_phases(ip);
            v_dir = [sin(pitch_angle)*cos(phi), sin(pitch_angle)*sin(phi), cos(pitch_angle)];
            cos_psi = dot(n_obs, v_dir);
            beaming = 1.0 / (1.0 - beta * cos_psi)^2;
            sin2 = 1.0 - cos_psi^2;
            shape = P * sin2 + (1.0 - P) * 1.0;
            sum_I_gyro = sum_I_gyro + shape * beaming;
        end
        avg_shape = sum_I_gyro / length(gyro_phases);
        total_val = total_val + avg_shape * I_scale * T_filter * d_h_nu;
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
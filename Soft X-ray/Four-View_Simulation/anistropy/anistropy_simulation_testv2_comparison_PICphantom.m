function [] = anistropy_simulation_final()
% =========================================================================
%  TS-6 Reconstruction Consistency Check (Shot8) - Angular Phantom Model
%  
%  Update: 
%  1. Phantom is now a 3D array (R, Z, Angle) derived from physics logic.
%  2. LUT is removed. Projection directly interpolates the 3D Phantom.
%  3. Interactive slider added to visualize Phantom anisotropy.
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
else, T.shot=nan; T.a039=0; T.a040=0; end
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

% --- 3. Parameters ---
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
% --- 4. Angular Phantom Generation (New!) ---
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('--- 3. Generating Angular Phantom (Physics-Based) ---\n');

% (A) Define Spatial Distributions (Ne, E_para, E_perp)
R_cen = 0.22; Z_cen = 0.04;

% Density
Ne_map = 1.0e20*exp(-((R_mesh-R_cen).^2/0.03^2 + (Z_mesh-Z_cen).^2/0.06^2)) + ...
         1.0e20*exp(-((R_mesh-(R_cen+0.08)).^2/0.04^2 + (Z_mesh-Z_cen).^2/0.3^2)) + ...
         1.0e20*exp(-((R_mesh-(R_cen-0.08)).^2/0.04^2 + (Z_mesh-Z_cen).^2/0.3^2))+ ...
         1.0e19*exp(-((R_mesh-(R_cen+0.03)).^2/0.04^2 + (Z_mesh-(Z_cen-0.2)).^2/0.04^2))+ ...
         1.0e19*exp(-((R_mesh-R_cen).^2/0.04^2 + (Z_mesh-(Z_cen+0.16)).^2/0.04^2));

% Parallel Energy (E_para)
E_para_map = 80*exp(-((R_mesh-R_cen).^2/0.04^2 + (Z_mesh-Z_cen).^2/0.07^2)) + ...
         80*exp(-((R_mesh-(R_cen+0.08)).^2/0.05^2 + (Z_mesh-Z_cen).^2/0.06^2)) + ...
         80*exp(-((R_mesh-(R_cen-0.08)).^2/0.05^2 + (Z_mesh-Z_cen).^2/0.2^2))+ ...
         10*exp(-((R_mesh-(R_cen+0.03)).^2/0.05^2 + (Z_mesh-(Z_cen-0.2)).^2/0.06^2))+ ...
         10*exp(-((R_mesh-R_cen).^2/0.05^2 + (Z_mesh-(Z_cen+0.16)).^2/0.06^2));

% Perpendicular Energy (E_perp)
E_perp_map = 20*exp(-((R_mesh-R_cen).^2/0.03^2 + (Z_mesh-Z_cen).^2/0.06^2)) + ...
         20*exp(-((R_mesh-(R_cen+0.08)).^2/0.04^2 + (Z_mesh-Z_cen).^2/0.3^2)) + ...
         20*exp(-((R_mesh-(R_cen-0.08)).^2/0.04^2 + (Z_mesh-Z_cen).^2/0.3^2))+ ...
         10*exp(-((R_mesh-(R_cen+0.03)).^2/0.04^2 + (Z_mesh-(Z_cen-0.2)).^2/0.04^2))+ ...
         10*exp(-((R_mesh-R_cen).^2/0.04^2 + (Z_mesh-(Z_cen+0.16)).^2/0.04^2));

% Pitch Angle Map (for visualization)
pitch_rad_map = atan(sqrt(E_perp_map ./ E_para_map));
pitch_deg = rad2deg(pitch_rad_map);

% -----------------------------------------------------------
% (B) Build 3D Phantom Array: Phantom(R, Z, Angle)
% -----------------------------------------------------------
% 議論に基づき、各グリッド点における「角度ごとの明るさ」を計算して格納する
% 1. 準備
axis_angle_phantom = linspace(0, 180, 37); % 5度刻みで十分
Phantom_3D = zeros(size(Ne_map,1), size(Ne_map,2), length(axis_angle_phantom));

% フィルタ透過率
try
    if exist('readmatrix', 'file'), FData = readmatrix('1umAl.txt', 'NumHeaderLines', 2);
    else, imp = importdata('1umAl.txt', ' ', 2); FData = imp.data; end
    F_Trans = griddedInterpolant(FData(:,1), FData(:,2), 'linear', 'nearest');
catch
    warning('Failed to load 1umAl.txt. Assuming Trans=1.');
    F_Trans = griddedInterpolant([0, 1e4], [1, 1], 'linear', 'nearest');
end

% 物理定数
h_bar = 1.0545718e-34; m_e = 9.10938356e-31; e_c = 1.60217663e-19; eps0 = 8.8541878e-12;
eV2J = 1.60217663e-19; 

% 2. 積分ループ (グリッドごとに計算すると遅いので、ベクトル化して計算)
fprintf('    Computing Angular Phantom (This may take a moment)...\n');

% 事前計算: 各グリッドのベース強度 (スペクトル積分項)
% I_base ~ ne^2 * Integral( Trans/E * g_ff/v )
% 簡略化のため、代表エネルギーではなく、少し真面目に積分する（重要！）
E_integ_list = logspace(log10(10), log10(3000), 20); % 10eV-3keV
dE_list = diff(E_integ_list); 
E_centers = (E_integ_list(1:end-1) + E_integ_list(2:end)) / 2;

I_base_map = zeros(size(Ne_map));

% 全グリッドの速度 (v_abs)
E_tot_map = E_para_map + E_perp_map;
v_map_abs = sqrt(2 * E_tot_map * eV2J / m_e);

% スペクトル積分の実行
for k = 1:length(E_centers)
    hv = E_centers(k); % eV
    hv_J = hv * eV2J;
    dE = dE_list(k);
    
    Trans = F_Trans(hv);
    if Trans < 1e-6, continue; end
    
    % Gaunt Factor
    omega = hv_J / h_bar;
    b_max = v_map_abs ./ omega;
    b_min = max( h_bar./(m_e.*v_map_abs), (e_c^2)./(4*pi*eps0*m_e.*v_map_abs.^2) );
    arg = b_max ./ (b_min + 1e-30);
    g_ff = (sqrt(3)/pi) * log(max(1.0, arg));
    
    % 寄与の加算: (1/v) * g_ff * (1/hv) * Trans * dE
    term = (1.0 ./ v_map_abs) .* g_ff .* (1.0/hv) * Trans * dE;
    I_base_map = I_base_map + term;
end

% 密度項 (ne^2) を掛ける
I_base_map = I_base_map .* (Ne_map.^2);

% 正規化 (最大値を5.0にする)
Scale_Factor = 5.0 / max(I_base_map(:));
I_base_map = I_base_map * Scale_Factor;
E_true = I_base_map; % これを「等方的な正解（Ground Truth）」としてプロットに使用

% 3. 角度依存性の付与 (Angular Phantom 構築)
% Shape = 1 + (cos^2 a cos^2 th + 0.5 sin^2 a sin^2 th)
% 各角度スライスを作成して 3D配列に格納
cos_sq_alpha = E_para_map ./ (E_para_map + E_perp_map);
sin_sq_alpha = E_perp_map ./ (E_para_map + E_perp_map);

for ia = 1:length(axis_angle_phantom)
    th_deg = axis_angle_phantom(ia);
    
    cos_sq_th = cosd(th_deg)^2;
    sin_sq_th = sind(th_deg)^2;
    
    % 厳密なジャイロ平均形状因子
    Shape = 1.0 + (cos_sq_alpha .* cos_sq_th + 0.5 * sin_sq_alpha .* sin_sq_th);
    
    % 正規化: Shapeの最大値で割るべきか？
    % ここでは「相対的な変化」を含めたいので、Shapeをそのまま掛ける。
    % ただし、E_true は「積分強度」なので、Shapeの平均が1になるように調整するのが物理的に筋が良いが、
    % ここではシンプルに「明るさが変わる」効果を見るため直積する。
    
    Phantom_3D(:, :, ia) = I_base_map .* Shape / 1.5; % 1.5は大まかな平均値での除算
end

% 3D補間関数の作成 (R, Z, Angle) -> Intensity
F_Phantom_3D = griddedInterpolant({r_axis, z_axis, axis_angle_phantom}, Phantom_3D, 'linear', 'nearest');

% Create Interpolants for scalar maps (for Isotropic projection)
F_E_true = griddedInterpolant({r_axis, z_axis}, E_true, 'linear', 'none');


% --- 5. Forward Projection ---
fprintf('--- 4. Computing Projections ---\n');
l_up_mm = MCPLine_up(N_projection, 40, false);
l_up = l_up_mm; 
for i=1:numel(l_up)
    l_up(i).x = l_up_mm(i).x * 1e-3; 
    l_up(i).y = l_up_mm(i).y * 1e-3;
    l_up(i).z = l_up_mm(i).z * 1e-3;
end

Geom.rmin = rmin; Geom.rmax = rmax; Geom.zmin = zmin; Geom.zmax = zmax;
Geom.N_g = N_g; Geom.DR = (rmax-rmin)/N_grid; Geom.DZ = (zmax-zmin)/N_grid;

fprintf('--- 5.5. Anisotropy Verification (Diff Check) ---\n');

% 1. 等方ケース (Isotropic Run)
% F_E_true (スカラー) を使い、異方性係数=1.0 で計算
fprintf('   Calculating Isotropic Projection...\n');
S_iso_m = Compute_Projection_Final(l_up, Geom, F_E_true, F_Br, F_Bz, F_Bt, [], true);
S_iso = S_iso_m * 100; 

% 2. 異方ケース (Anisotropic Run)
% F_Phantom_3D (3次元配列) を使い、角度に応じて補間
fprintf('   Calculating Anisotropic Projection...\n');
S_aniso_m = Compute_Projection_Final(l_up, Geom, F_Phantom_3D, F_Br, F_Bz, F_Bt, [], false);
S_aniso = S_aniso_m * 100; 

% 差分計算
S_diff = S_aniso - S_iso;
S_ratio = (S_diff ./ (S_iso + 1e-9)) * 100;
fprintf('   Max Difference: %.2e\n', max(abs(S_diff(:))));

% メイン変数更新
S_obs_val = S_aniso;


% --- Noise & Recon Setup ---
k_circle = FindCircle(N_projection/2);
Img_clean = zeros(N_projection);
Img_clean(k_circle) = S_obs_val;
Img_clean = Img_clean'; 

fprintf('    Adding Noise (10%%)...\n');
SNR_dB = 10 * log10(10); 
S_obs_noisy = awgn(S_obs_val, SNR_dB, 'measured');
S_obs_noisy(S_obs_noisy < 0) = 0; 

Img_noisy = zeros(N_projection);
Img_noisy(k_circle) = S_obs_noisy;
Img_noisy = Img_noisy';
VectorImage1 = S_obs_noisy'; 

% --- 6. Reconstruction ---
fprintf('--- 6. Running Reconstruction ---\n');
EE0 = get_distribution(M, K, gm2d1, U1, s1, v1, VectorImage1, false, 0, N_projection);
EE1 = get_distribution(M, K, gm2d1, U1, s1, v1, VectorImage1, false, 1, N_projection);
EE2 = get_distribution(M, K, gm2d1, U1, s1, v1, VectorImage1, false, 2, N_projection);


% --- 7. Plotting Results ---
fprintf('--- 7. Plotting (3x3 Layout) ---\n');
figure('Name', 'Check: Shot8 Full Process View', 'Position', [50, 50, 1600, 1000]);

plot_data_list = {Ne_map, E_para_map, E_perp_map, ...
                  E_true, pitch_deg, Img_noisy, ...
                  EE0, EE1, EE2};

title_list = {'Input: Density (n_e)', 'Input: E_{||} [eV]', 'Input: E_{\perp} [eV]', ...
              'Base Phantom (Isotropic Eq)', 'Pitch Angle [deg]', 'Camera View (10% Noise)', ...
              'Tikhonov (Meth=0)', 'MFI (Meth=1)', 'MEM (Meth=2)'};

is_rz_plane = [true, true, true, ...
               true, true, false, ...
               true, true, true];

use_fixed_clim = [false, false, false, ...
                  true, true, true, ...
                  true, true, true];
fixed_range = [0 5]; 

for i = 1:9
    subplot(3, 3, i);
    img_data = plot_data_list{i};
    
    if is_rz_plane(i)
        imagesc(z_axis, r_axis, img_data);
        axis xy; axis image;
        xlabel('Z [m]'); ylabel('R [m]');
        ylim([0.05 0.33])
        hold on;
        [~, h] = contour(Z_mesh, R_mesh, Psi_map, 15, 'w'); 
        h.LineWidth = 0.5; h.EdgeAlpha = 0.5;
        hold off;
    else
        imagesc(img_data);
        axis image; axis off;
    end
    
    title(title_list{i});
    colorbar;
    
    if i == 5 
        clim([0 90])
    elseif ~is_rz_plane(i)
        clim([0 100]);
    elseif use_fixed_clim(i)
        clim(fixed_range);
    else
        clim([0, max(img_data(:))]); 
    end
end

fprintf('--- Done ---\n');

% ★ 追加機能: ファントムのスライダー表示 ★
view_angular_phantom(r_axis, z_axis, axis_angle_phantom, Phantom_3D);

end


% =========================================================================
%  Updated Helper Function: Direct 3D Phantom Interpolation
% =========================================================================

function [S_obs] = Compute_Projection_Final(l_struct, G, F_Source, F_Br, F_Bz, F_Bt, ~, is_isotropic)
    % F_Source: 
    %   if is_isotropic=true  -> F_E_true (2D Interpolant: R, Z)
    %   if is_isotropic=false -> F_Phantom_3D (3D Interpolant: R, Z, Angle)
    
    rmin=G.rmin; rmax=G.rmax; zmin=G.zmin; zmax=G.zmax;
    N_p = numel(l_struct);
    S_vals = zeros(N_p, 1);
    
    parfor i = 1:N_p
        rx = l_struct(i).x(:); ry = l_struct(i).y(:); rz = l_struct(i).z(:);
        if isempty(rx), continue; end 

        rr = sqrt(rx.^2 + ry.^2);
        idx = (rr >= rmin) & (rr <= rmax) & (rz >= zmin) & (rz <= zmax);
        
        if any(idx)
            p_x = rx(idx); p_y = ry(idx); p_z = rz(idx); p_r = rr(idx); 
            if length(p_x) < 2, continue; end
            
            d_vec = sqrt(diff(p_x).^2 + diff(p_y).^2 + diff(p_z).^2);
            dL = [d_vec; d_vec(end)]; 
            
            % Magnetic Field & Angle Calculation
            br = F_Br(p_r, p_z); bz = F_Bz(p_r, p_z); bt = F_Bt(p_r, p_z);
            inv_r = 1 ./ p_r;
            cp = p_x .* inv_r; sp = p_y .* inv_r;
            
            Bx = br .* cp - bt .* sp;
            By = br .* sp + bt .* cp;
            Bz = bz;
            
            dir_vec = [rx(end)-rx(1), ry(end)-ry(1), rz(end)-rz(1)];
            dir_vec = dir_vec / (norm(dir_vec) + 1e-9);
            
            B_norm = sqrt(Bx.^2 + By.^2 + Bz.^2) + 1e-9;
            cos_theta = (dir_vec(1)*Bx + dir_vec(2)*By + dir_vec(3)*Bz) ./ B_norm;
            theta_deg = acosd(min(max(cos_theta, -1), 1));
            
            if is_isotropic
                % 等方性: スカラー場(R,Z)のみ参照
                % 角度因子はかからない (1.0)
                intensities = F_Source(p_r, p_z);
            else
                % 異方性: 3Dファントム(R, Z, Angle)を参照
                % query points: [R, Z, Angle]
                query = [p_r, p_z, theta_deg];
                intensities = F_Source(query);
            end
            
            S_vals(i) = sum(intensities .* dL, 'all', 'omitnan');
        end
    end
    S_obs = S_vals;
end

% =========================================================================
%  Viewer Function
% =========================================================================
function view_angular_phantom(r_ax, z_ax, ang_ax, P_3D)
    % Create a new figure with slider to view Phantom at specific angles
    hFig = figure('Name', 'Angular Phantom Viewer', 'Position', [100, 100, 700, 600]);
    
    ax = axes('Parent', hFig, 'Position', [0.15 0.25 0.7 0.65]);
    
    % Initial Plot (Angle = 0 deg)
    idx_init = 1;
    img = imagesc(ax, z_ax, r_ax, P_3D(:,:,idx_init));
    axis(ax, 'xy', 'image'); colorbar(ax);
    xlabel(ax, 'Z [m]'); ylabel(ax, 'R [m]');
    title(ax, sprintf('Phantom View @ Angle = %.1f deg', ang_ax(idx_init)));
    clim(ax, [0, max(P_3D(:))]);
    
    % Slider
    sld = uicontrol('Parent', hFig, 'Style', 'slider', 'Position', [100, 50, 500, 20], ...
                    'Min', 1, 'Max', length(ang_ax), 'Value', 1, ...
                    'SliderStep', [1/(length(ang_ax)-1), 5/(length(ang_ax)-1)]);
                
    txt = uicontrol('Parent', hFig, 'Style', 'text', 'Position', [100, 80, 500, 20], ...
                    'String', sprintf('Obs. Angle: %.1f deg', ang_ax(1)));
                
    sld.Callback = @(src, ~) update_view(src, txt, img, P_3D, ang_ax);
    
    function update_view(src, t, im, data, angs)
        idx = round(src.Value);
        ang = angs(idx);
        
        im.CData = data(:,:,idx);
        t.String = sprintf('Obs. Angle: %.1f deg', ang);
        title(im.Parent, sprintf('Phantom View @ Angle = %.1f deg', ang));
    end
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
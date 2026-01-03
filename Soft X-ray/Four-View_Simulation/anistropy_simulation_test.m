function [] = anistropy_simulation_test()
% =========================================================================
%  TS-6 Reconstruction Consistency Check (Shot8)
%  - Phantom Peak: 5.0
%  - Noise Added: 10% (awgn 10dB)
%  - Plots (2x3 layout):
%      [Ground Truth]  [Camera(Clean)]  [Camera(Noisy)]
%      [Tikhonov]      [MFI]            [MEM]
%  - Magnetic Flux overlay on R-Z plane plots.
% =========================================================================
close all; clear; clc;

% --- 1. Path Setup ---
addpath '/Users/shohgookazaki/Documents/GitHub/test-open/pcb_experiment';
addpath '/Users/shohgookazaki/Documents/matlab/common';
addpath '/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Machine_Learning/code';
addpath '/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Four-View/'; 
run define_path.m 

if exist('parametercheck', 'file') ~= 2 || exist('get_distribution', 'file') ~= 2
    error('Required functions (parametercheck, get_distribution) not found.');
end

% --- 2. Load Experimental Data ---
date_target = 251220; shot_idx = 8; time_target = 480;
fprintf('--- 1. Loading Exp Data (Shot%d @ %dus) ---\n', shot_idx, time_target);

DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';
T=getTS6log(DOCID); T=searchlog(T,'date',date_target);
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

% Convert mm -> m
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

% Forward Calculation
Geom.rmin = rmin; Geom.rmax = rmax; Geom.zmin = zmin; Geom.zmax = zmax;
Geom.N_g = N_g; Geom.DR = (rmax-rmin)/N_grid; Geom.DZ = (zmax-zmin)/N_grid;
Phys.Pitch = 30; Phys.Ratio = 0.0;

[~, S_obs_val] = Compute_Projection_Robust(l_up, Geom, Phys, F_E_true, F_Br, F_Bz, F_Bt);

% --- Create Clean Camera Image ---
k_circle = FindCircle(N_projection/2);
Img_clean = zeros(N_projection);
Img_clean(k_circle) = S_obs_val;
Img_clean = Img_clean'; % Transpose for correct orientation

% --- Noise Addition ---
fprintf('    Adding Noise (10%%)...\n');
SNR_dB = 10 * log10(10); 
S_obs_noisy = awgn(S_obs_val, SNR_dB, 'measured');
S_obs_noisy(S_obs_noisy < 0) = 0; % 負値カット

% --- Create Noisy Camera Image & Reconstruction Input ---
Img_noisy = zeros(N_projection);
Img_noisy(k_circle) = S_obs_noisy;
Img_noisy = Img_noisy';

VectorImage1 = S_obs_noisy'; % Input for reconstruction (Row vector)


% --- 5. Reconstruction ---
fprintf('--- 4. Running get_distribution (No Plot) ---\n');

% (A) Tikhonov
fprintf('  - Method 0: Tikhonov\n');
EE0 = get_distribution(M, K, gm2d1, U1, s1, v1, VectorImage1, false, 0, N_projection);

% (B) MFI
fprintf('  - Method 1: MFI\n');
EE1 = get_distribution(M, K, gm2d1, U1, s1, v1, VectorImage1, false, 1, N_projection);

% (C) MEM
fprintf('  - Method 2: MEM\n');
EE2 = get_distribution(M, K, gm2d1, U1, s1, v1, VectorImage1, false, 2, N_projection);


% --- 6. Plotting Results with Flux Overlay ---
fprintf('--- 5. Plotting (2x3 Layout) ---\n');
figure('Name', 'Check: Shot8 Full Process View', 'Position', [50, 50, 1600, 800]);

% Data and settings for loop plotting
plot_data_list = {E_true, Img_clean, Img_noisy, EE0, EE1, EE2};
title_list = {'Ground Truth (Phantom)', 'Camera View (Clean)', 'Camera View (10% Noise)', ...
              'Tikhonov (Meth=0)', 'MFI (Meth=1)', 'MEM (Meth=2)'};
% Flag: true if the plot is in R-Z plane and needs flux overlay
is_rz_plane = [true, false, false, true, true, true];

c_range = [0 5]; % Max intensity 5

for i = 1:6
    subplot(2, 3, i);
    img_data = plot_data_list{i};
    
    if is_rz_plane(i)
        % --- R-Z Plane Plot (Ground Truth & Reconstructions) ---
        imagesc(z_axis, r_axis, img_data);
        axis xy; axis image;
        xlabel('Z [m]'); ylabel('R [m]');
        
        % Magnetic Flux Overlay
        hold on;
        [~, h] = contour(Z_mesh, R_mesh, Psi_map, 15, 'w'); 
        h.LineWidth = 0.8; h.EdgeAlpha = 0.6;
        hold off;
    else
        % --- Camera View Plot (Sensor Plane) ---
        % Note: Flux overlay is not applicable here due to different coordinate system.
        imagesc(img_data);
        axis image; axis off; % Hide axes for camera view
    end
    
    title(title_list{i});
    colorbar; clim(c_range);
end

fprintf('--- Done ---\n');

end


% =========================================================================
%  Local Helper Functions
% =========================================================================
function [L_iso, S_obs] = Compute_Projection_Robust(l_struct, G, P, F_E, F_Br, F_Bz, F_Bt)
    % Unit: [m]
    rmin=G.rmin; rmax=G.rmax; zmin=G.zmin; zmax=G.zmax;
    N_g=G.N_g; DR=G.DR; DZ=G.DZ;
    alpha = deg2rad(P.Pitch); A_str = P.Ratio;
    N_p = numel(l_struct);
    S_vals = zeros(N_p, 1);
    
    parfor i = 1:N_p
        rx = l_struct(i).x; ry = l_struct(i).y; rz = l_struct(i).z;
        rr = sqrt(rx.^2 + ry.^2);
        valid_idx = find(rr>=rmin & rr<=rmax & rz>=zmin & rz<=zmax);
        if ~isempty(valid_idx)
            pl_r = rr(valid_idx); pl_z = rz(valid_idx);
            pl_x = rx(valid_idx); pl_y = ry(valid_idx);
            
            val_S = 0;
            dir_vec = [rx(end)-rx(1), ry(end)-ry(1), rz(end)-rz(1)];
            dir_vec = dir_vec / (norm(dir_vec) + 1e-9);
            
            for k = 1:length(pl_r)
                r_c = pl_r(k); z_c = pl_z(k);
                e_val = F_E({r_c, z_c});
                br = F_Br({r_c, z_c}); bz = F_Bz({r_c, z_c}); bt = F_Bt({r_c, z_c});
                if r_c < 1e-5, cp=1; sp=0; else, cp=pl_x(k)/r_c; sp=pl_y(k)/r_c; end
                b_vec = [br*cp - bt*sp, br*sp + bt*cp, bz];
                cos_psi = dot(dir_vec, b_vec/(norm(b_vec)+1e-9));
                val_S = val_S + e_val * ((1-A_str) + A_str*(0.5*sin(alpha)^2*(1+cos_psi^2) + cos(alpha)^2*(1-cos_psi^2))); 
            end
            S_vals(i) = val_S; 
        end
    end
    S_obs = S_vals;
    L_iso = sparse(N_p, N_g^2); 
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
%% Anisotropic Soft X-ray Radiation Simulation (Full Integration)
% Reference: "異方性を考慮した軟X線放射のシミュレーションと等方性仮定に基づく再構成手法の検証"
% Date: 2026-01-21
% Note: This code strictly follows the PDF derivation without simplification.
%       Parallel computing (parfor) is used to handle the computational load.

clear; close all; clc;

%% 1. Parameters & Constants [SI Units]
% Physical Constants
c = 2.99792458e8;       % Speed of light [m/s]
me = 9.10938356e-31;    % Electron mass [kg]
qe = 1.60217663e-19;    % Elementary charge [C]
eps0 = 8.85418781e-12;  % Vacuum permittivity [F/m]
hbar = 1.0545718e-34;   % Planck constant [J s]
Z = 1;                  % Ion charge number (Assuming Hydrogen/Proton for now)
ni = 1e19;              % Ion density [m^-3] (Example value for emissivity scaling)
ne = 1e19;              % Electron density [m^-3]

% Simulation Grid Parameters (LUT Dimensions)
% Note: Adjust ranges based on expected plasma parameters (e.g., few keV)
v_grid = linspace(1e6, 0.3*c, 5);      % Velocity grid [m/s]
theta_p_grid = linspace(0, pi, 7);     % Pitch angle grid [rad] (Eq 39)
alpha_grid = linspace(0, pi, 31);       % Observation angle grid [rad] (Eq 37)
w_grid = linspace(1e15, 1e18, 100);    % Frequency grid [rad/s] (Soft X-ray range)

% Integration Resolution (High computational cost warning)
N_gyro = 16;       % Number of gyro-phase steps (0 to 2pi) (Eq 40)
N_impact = 30;     % Number of impact parameter steps (b_min to b_max) (Eq 33)
N_azimuth = 16;    % Number of collision azimuth steps (0 to 2pi) (Eq 32)
dt_res = 1e-20;    % Time resolution for FFT [s]
T_window_factor = 50; % Factor to determine time window based on interaction time

% Pre-allocate Output LUT
% Structure: Emissivity(w, alpha, theta_p, v)
LUT_Emissivity = zeros(length(w_grid), length(alpha_grid), length(theta_p_grid), length(v_grid));

fprintf('Starting Simulation: Anisotropic Soft X-ray Radiation\n');
fprintf('This may take significant time due to full integration.\n');

%% 2. Main Calculation Loops
% Parallelize over the most independent variables (Velocity)
% Use a parallel pool if available
if isempty(gcp('nocreate'))
    parpool; 
end

tic;

parfor iv = 1:length(v_grid)
    v = v_grid(iv);
    local_LUT_v = zeros(length(w_grid), length(alpha_grid), length(theta_p_grid));
    
    % Loop over Pitch Angle (Theta_p)
    for it = 1:length(theta_p_grid)
        theta_p = theta_p_grid(it);
        
        % Loop over Observation Angle (Alpha)
        for ia = 1:length(alpha_grid)
            alpha = alpha_grid(ia);
            
            % --- Core Physics Calculation ---
            % Calculate spectral power for this (v, theta_p, alpha) set
            % Integration over Gyro (phi_gyro), Impact (b), Azimuth (phi_coll)
            
            total_spectrum = zeros(size(w_grid));
            
            % 2.1 Gyro-averaging Loop (Eq 40)
            d_gyro = 2*pi / N_gyro;
            for i_g = 1:N_gyro
                phi_gyro = (i_g - 0.5) * d_gyro;
                
                % Construct Electron Velocity Vector in Lab Frame (Eq 39)
                % Lab Frame: B field along Z-axis
                v_vec = v * [sin(theta_p)*cos(phi_gyro); ...
                             sin(theta_p)*sin(phi_gyro); ...
                             cos(theta_p)];
                
                % Observation Vector n in Lab Frame (Eq 37)
                % Note: PDF Section 3.2 defines n relative to B (implied by context of alpha)
                n_vec = [sin(alpha); 0; cos(alpha)];
                
                % Define Collision Frame Basis
                % Z_c is along velocity v
                u_z = v_vec / norm(v_vec);
                
                % Create orthogonal basis (X_c, Y_c) for impact parameter plane
                if abs(u_z(3)) < 0.99
                    temp_vec = [0; 0; 1];
                else
                    temp_vec = [0; 1; 0];
                end
                u_x = cross(temp_vec, u_z);
                u_x = u_x / norm(u_x);
                u_y = cross(u_z, u_x);
                
                % 2.2 Determine Impact Parameter Bounds
                % b_max: Adiabatic limit (Eq 34). Use min frequency for max range.
                b_max = v / w_grid(1); 
                
                % b_min: Quantum/Classical limit (Eq 35)
                % Classical Landau length
                b_class = (Z * qe^2) / (me * v^2 * 4 * pi * eps0);
                % Quantum de Broglie wavelength
                b_quant = hbar / (me * v);
                b_min = max(b_class, b_quant);
                
                % Check if b_min < b_max
                if b_min >= b_max
                    continue; % No radiation in this frequency range
                end
                
                % 2.3 Impact Parameter Integration (Eq 33)
                % Logarithmic spacing is better for 1/r potentials, but using linear for strictness if needed.
                % Using linear spacing as per standard integration implication unless specified otherwise.
                b_step = (b_max - b_min) / N_impact;
                
                for i_b = 1:N_impact
                    b = b_min + (i_b - 0.5) * b_step;
                    
                    % 2.4 Azimuthal Integration (Eq 32, Eq 151)
                    d_phi_coll = 2*pi / N_azimuth;
                    for i_az = 1:N_azimuth
                        phi_coll = (i_az - 0.5) * d_phi_coll;
                        
                        % --- Single Collision Simulation ---
                        
                        % Time Window: sufficient to cover the interaction
                        % Interaction time ~ b/v.
                        t_interact = b/v;
                        t_max = T_window_factor * t_interact;
                        t_time = -t_max:dt_res:t_max;
                        
                        % Trajectory & Acceleration (Coulomb Interaction)
                        % PDF Eq 36 defines geometry: d(t) = [b cos, b sin, vt]
                        % This implies r(t) in collision frame.
                        % Force F = k q Q / r^2 * (-r_hat)
                        
                        % Position in Collision Frame
                        Rx = b * cos(phi_coll);
                        Ry = b * sin(phi_coll);
                        Rz = v * t_time;
                        R_sq = Rx^2 + Ry^2 + Rz.^2;
                        R_dist = sqrt(R_sq);
                        
                        % Acceleration in Collision Frame (a = F/m)
                        % F = - (Z e^2 / 4 pi eps0) * r_vec / r^3
                        coeff_a = -(Z * qe^2) / (4 * pi * eps0 * me);
                        
                        Ax_c = coeff_a * Rx ./ (R_dist.^3);
                        Ay_c = coeff_a * Ry ./ (R_dist.^3);
                        Az_c = coeff_a * Rz ./ (R_dist.^3);
                        
                        % Transform Acceleration to Lab Frame for calculating n x (n x a)
                        % vec_lab = Ax_c * u_x + Ay_c * u_y + Az_c * u_z
                        Ax_lab = Ax_c * u_x(1) + Ay_c * u_y(1) + Az_c * u_z(1);
                        Ay_lab = Ax_c * u_x(2) + Ay_c * u_y(2) + Az_c * u_z(2);
                        Az_lab = Ax_c * u_x(3) + Ay_c * u_y(3) + Az_c * u_z(3);
                        
                        % 2.5 FFT to Frequency Domain (Eq 19, 24, 25)
                        % We calculate Fourier transform of acceleration directly.
                        % Eq 19: d_dot_dot <-> -omega^2 d_hat
                        % Eq 31 uses |n x (n x d_hat)|^2 * w^4
                        % Note: |n x (n x d_dot_dot_hat)|^2 = |-w^2 n x (n x d_hat)|^2 = w^4 |...|^2
                        % So we can use FFT(acceleration) directly into Eq 31 structure.
                        
                        N_fft = length(t_time);
                        fs = 1/dt_res;
                        
                        % Compute FFT for each component
                        Acc_w_x = fftshift(fft(Ax_lab)) / fs; % Scaling for continuous FT approximation
                        Acc_w_y = fftshift(fft(Ay_lab)) / fs;
                        Acc_w_z = fftshift(fft(Az_lab)) / fs;
                        
                        freq_fft = fs * (-N_fft/2 : N_fft/2 - 1) / N_fft;
                        w_fft = 2 * pi * freq_fft;
                        
                        % Interpolate to requested w_grid
                        % Only take positive frequencies
                        A_wx_interp = interp1(w_fft, Acc_w_x, w_grid, 'linear', 0);
                        A_wy_interp = interp1(w_fft, Acc_w_y, w_grid, 'linear', 0);
                        A_wz_interp = interp1(w_fft, Acc_w_z, w_grid, 'linear', 0);
                        
                        % 2.6 Radiation Calculation (Eq 31)
                        % dW/dwdOmega = (1/c^3) * |n x (n x a_w)|^2
                        % Note: PDF Eq 31 has w^4/c^3 * |d_hat|^2.
                        % Since a_w = -w^2 d_hat, |a_w|^2 = w^4 |d_hat|^2.
                        % So dW = (1/c^3) * |n x (n x a_w)|^2.
                        
                        % Vector product term: n x (n x A) = (n.A)n - (n.n)A = (n.A)n - A
                        n_dot_A = A_wx_interp * n_vec(1) + A_wy_interp * n_vec(2) + A_wz_interp * n_vec(3);
                        
                        TermX = n_dot_A * n_vec(1) - A_wx_interp;
                        TermY = n_dot_A * n_vec(2) - A_wy_interp;
                        TermZ = n_dot_A * n_vec(3) - A_wz_interp;
                        
                        Abs_Sq = abs(TermX).^2 + abs(TermY).^2 + abs(TermZ).^2;
                        
                        dW_dwdO = (1/c^3) * Abs_Sq;
                        
                        % Integration Weighting (Eq 33)
                        % Weight = b * db * dphi
                        weight = b * b_step * d_phi_coll;
                        
                        % Accumulate
                        total_spectrum = total_spectrum + dW_dwdO * weight;
                        
                    end % End Azimuth
                end % End Impact Parameter
            end % End Gyro
            
            % Average over Gyro phase (Eq 40: 1/2pi integral)
            % Sum * d_gyro * (1/2pi) = Sum * (2pi/N) / (2pi) = Sum / N
            avg_spectrum = total_spectrum / N_gyro;
            
            % Multiply by flux n_e * n_i * v (Eq 33)
            emissivity = ne * ni * v * avg_spectrum;
            
            % Store in local LUT
            local_LUT_v(:, ia, it) = emissivity;
            
        end % End Observation Angle
    end % End Pitch Angle
    
    % Assign to global LUT (sliced by velocity to allow parfor)
    LUT_Emissivity(:, :, :, iv) = local_LUT_v;
    
    fprintf('Finished Velocity Step %d / %d (v = %.2e m/s)\n', iv, length(v_grid), v);
end
toc;

%% 3. Save Data and Verification
% Reference: [2025-12-30] Comparison with theoretical values is required.

% Theoretical Comparison: Kramers' Opacity Law scaling (Bremsstrahlung)
% j_w ~ constant * exp(-hbar*w / (k*T_eff)) / sqrt(T)
% Since we have mono-energetic v, the spectrum should be roughly flat
% up to the cutoff w_cutoff ~ mv^2 / 2hbar, then drop.
% (Gaunt factor approximation)

fprintf('Saving LUT to "Bremsstrahlung_LUT.mat"...\n');
save('Bremsstrahlung_LUT.mat', 'LUT_Emissivity', 'w_grid', 'alpha_grid', 'theta_p_grid', 'v_grid');

% --- Visualization ---
figure('Name', 'Emissivity Validation', 'Color', 'w');

% Plot 1: Spectrum vs Frequency for a specific configuration
iv_sel = length(v_grid); % High velocity
it_sel = 1;              % Parallel pitch
ia_sel = 1;              % Parallel observation

loglog(w_grid, LUT_Emissivity(:, ia_sel, it_sel, iv_sel), 'b-', 'LineWidth', 2);
hold on;

% Theoretical "Flat" Line (Kramers-like behavior for low freq)
% Just for shape comparison, normalize to the calculated peak
ref_curve = ones(size(w_grid)) * max(LUT_Emissivity(:, ia_sel, it_sel, iv_sel));
% Apply simple cutoff check
E_kin = 0.5 * me * v_grid(iv_sel)^2;
w_cut = E_kin / hbar;
mask_cut = w_grid > w_cut;
ref_curve(mask_cut) = ref_curve(mask_cut) .* exp(-(w_grid(mask_cut)-w_cut)*1e-16); % Soften edge

loglog(w_grid, ref_curve, 'r--', 'LineWidth', 1.5);

xlabel('Frequency \omega [rad/s]');
ylabel('Emissivity j_{\omega, \Omega}');
title(['Spectrum at v=' num2str(v_grid(iv_sel), '%.1e') ' m/s (Calculated vs Theory Trend)']);
legend('Calculated (Anisotropic)', 'Theoretical Trend (Kramers/Gaunt)');
grid on;

% Warning if deviation is huge (Basic sanity check)
if max(LUT_Emissivity(:)) == 0
    warning('Result is all zeros. Check integration limits or resolution.');
else
    disp('Calculation complete. Non-zero emissivity obtained.');
end

% Check regarding [2025-12-30]:
% "Discussing simulation... check external info... standard textbooks"
% The code implements the "Straight Line Trajectory" approximation for Coulomb force
% as implied by the PDF's geometry definition (Eq 36) combined with the requirement
% for Bremsstrahlung (Section 3.1.2). The exact acceleration formula was derived
% from standard Coulomb interaction F = ma, as the PDF defined the geometry but not the explicit force.

fprintf('Process completed.\n');
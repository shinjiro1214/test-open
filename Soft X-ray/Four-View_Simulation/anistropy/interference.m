%%%%%%%%%%b一つだけ%%%%%%5
% function bremsstrahlung_si_units_v2
%     % BREMSSTRAHLUNG_SI_UNITS_V2
%     % SI単位系での制動放射シミュレーション（合計成分追加版）
%     % 加速度の絶対値と、放射スペクトルの総和を追加プロットします。

%     clear; close all; clc;

%     %% 1. 物理定数と初期設定 (SI Units)
%     % ----------------------------------------------------------------
%     e_charge = 1.60217663e-19; % [C] 素電荷
%     m_e      = 9.10938356e-31; % [kg] 電子質量
%     eps0     = 8.85418781e-12; % [F/m] 真空の誘電率
%     c_light  = 2.99792458e8;   % [m/s] 光速
    
%     k_coulomb = 1 / (4 * pi * eps0); % クーロン定数
    
%     % --- シミュレーション条件 ---
%     Z = 1;                     % ターゲットイオンの価数
%     v0 = 2.0e7;                % [m/s] 初速度 (~1 keV)
%     b  = 1.0e-10;              % [m]   インパクトパラメータ (1 Angstrom)
    
%     % 計算領域の設定
%     L_range = 10 * b;          
%     y_start = -L_range;
    
%     initial_state = [b; y_start; 0; v0]; % [x, y, vx, vy]
    
%     % 時間推定
%     t_estimate = 2 * L_range / v0; 
%     t_span = [0, t_estimate];

%     fprintf('--- Simulation Parameters ---\n');
%     fprintf('Initial Velocity: %.2e [m/s]\n', v0);
%     fprintf('Impact Parameter: %.2e [m]\n', b);
%     fprintf('Est. Duration:    %.2e [s]\n', t_estimate);

%     %% 2. 運動方程式の求解 (ODE45)
%     options = odeset('RelTol', 1e-6, 'AbsTol', 1e-9);
%     f_ode = @(t, s) equations_of_motion(t, s, k_coulomb, -e_charge, Z*e_charge, m_e);
    
%     [t_raw, state] = ode45(f_ode, t_span, initial_state, options);
    
%     x_raw = state(:,1); y_raw = state(:,2);
%     vx_raw = state(:,3); vy_raw = state(:,4);

%     %% 3. データ処理と加速度計算 (Resampling)
%     num_points = 4096; 
%     t_uniform = linspace(t_raw(1), t_raw(end), num_points);
%     dt = t_uniform(2) - t_uniform(1);
%     Fs = 1/dt; 
    
%     % スプライン補間
%     x = spline(t_raw, x_raw, t_uniform);
%     y = spline(t_raw, y_raw, t_uniform);
    
%     % 加速度計算 (a = F/m)
%     r_sq = x.^2 + y.^2;
%     r_mag = sqrt(r_sq);
    
%     F_mag = k_coulomb .* abs(-e_charge * Z * e_charge) ./ r_sq;
%     ax = -F_mag .* (x ./ r_mag) / m_e; % [m/s^2]
%     ay = -F_mag .* (y ./ r_mag) / m_e; % [m/s^2]
    
%     % ★追加: 加速度の大きさ (Total Magnitude)
%     a_mag = sqrt(ax.^2 + ay.^2);

%     % ラーモアの公式 (Power)
%     Power = (e_charge^2 * a_mag.^2) / (6 * pi * eps0 * c_light^3);

%     %% 4. 周波数解析 (FFT)
%     N = length(t_uniform);
%     f = Fs * (0:(N/2)) / N; 
%     win = hann(N)'; 
    
%     % FFT
%     AX_fft = fft(ax .* win);
%     AY_fft = fft(ay .* win);
    
%     % 片側スペクトル振幅
%     P_ax_amp = abs(AX_fft / N); P_ax_amp = P_ax_amp(1:N/2+1);
%     P_ay_amp = abs(AY_fft / N); P_ay_amp = P_ay_amp(1:N/2+1);
    
%     % ★追加: パワースペクトル密度 (Power Spectral Density ~ |a|^2)
%     % 単位は任意ですが、ここでは相対的な強度比較のため振幅の二乗を使用
%     PSD_ax = P_ax_amp.^2;
%     PSD_ay = P_ay_amp.^2;
%     PSD_total = PSD_ax + PSD_ay; % Parsevalの定理より、成分の二乗和が全パワーに対応

%     %% 5. 可視化 (Totalを追加)
%     figure('Name', 'SI Bremsstrahlung v2', 'Color', 'w', 'Position', [100, 100, 1000, 700]);
    
%     % (1) 軌道
%     subplot(2,2,1);
%     plot(x*1e9, y*1e9, 'b-', 'LineWidth', 1.5); hold on;
%     plot(0, 0, 'r+', 'MarkerSize', 10, 'LineWidth', 2);
%     xlabel('x [nm]'); ylabel('y [nm]');
%     title('1. Electron Trajectory');
%     grid on; axis equal;
    
%     % (2) 放射パワー (Total Power)
%     subplot(2,2,2);
%     plot(t_uniform*1e15, Power, 'k', 'LineWidth', 1.5);
%     xlabel('Time [fs]'); ylabel('Radiated Power [W]');
%     title('2. Larmor Radiation Power');
%     grid on; xlim([0, t_uniform(end)*1e15]);
    
%     % (3) 加速度成分 (Totalを追加)
%     subplot(2,2,3);
%     plot(t_uniform*1e15, ax, 'r--', 'LineWidth', 1, 'DisplayName', 'a_x (Transverse)'); hold on;
%     plot(t_uniform*1e15, ay, 'b--', 'LineWidth', 1, 'DisplayName', 'a_y (Longitudinal)');
%     % Total Magnitude
%     plot(t_uniform*1e15, a_mag, 'k-', 'LineWidth', 1.5, 'DisplayName', '|a| (Total)');
    
%     xlabel('Time [fs]'); ylabel('Acceleration [m/s^2]');
%     title('3. Acceleration Components & Total');
%     legend('Location', 'best'); grid on;
%     xlim([0, t_uniform(end)*1e15]);
    
%     % (4) スペクトル (Totalを追加)
%     subplot(2,2,4);
%     % 見やすさのためPHz単位
%     f_PHz = f / 1e15;
    
%     loglog(f_PHz, PSD_ax, 'r--', 'LineWidth', 1, 'DisplayName', '|a_x|^2'); hold on;
%     loglog(f_PHz, PSD_ay, 'b--', 'LineWidth', 1, 'DisplayName', '|a_y|^2');
%     % Total Spectrum
%     loglog(f_PHz, PSD_total, 'k-', 'LineWidth', 2, 'DisplayName', 'Total (|a_x|^2+|a_y|^2)');
    
%     xlabel('Frequency [PHz] (10^{15} Hz)'); ylabel('Spectral Power Density [arb]');
%     title('4. Radiation Spectrum');
%     legend('Location', 'southwest'); grid on;
%     xlim([1e-1, 100]); 
    
% end

% function dsdt = equations_of_motion(~, s, k, q, Q, m)
%     x = s(1); y = s(2); vx = s(3); vy = s(4);
%     r_sq = x^2 + y^2; r = sqrt(r_sq);
%     F_mag = k * q * Q / r_sq;
%     dsdt = [vx; vy; F_mag*(x/r)/m; F_mag*(y/r)/m];
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%複数のb%%%%%%%%%
% function bremsstrahlung_statistical_range
%     % BREMSSTRAHLUNG_STATISTICAL_RANGE
%     % 指定した b_min から b_max の範囲で近似精度を統計評価する
%     % "bmaxからbminまで" というご要望に合わせて範囲を変数化しました。

%     clear; close all; clc;

%     %% 1. 設定と準備
%     % -------------------------------------------------------------
%     % ★ インパクトパラメータの範囲設定 (ここで自由に変更してください)
%     b_min = 0.05e-10;  % [m] 最小値 (例: 0.05 Angstrom = 激突)
%     b_max = 20.0e-10;  % [m] 最大値 (例: 20.0 Angstrom = 遠方)
%     num_samples = 50;  % サンプル数 (多いほどグラフが滑らかに)
%     % -------------------------------------------------------------

%     % 物理定数 (SI)
%     e_c = 1.602e-19; m_e = 9.109e-31; eps0 = 8.854e-12; c = 2.998e8;
%     k = 1/(4*pi*eps0);
%     Z = 1; v0 = 2.0e7;
    
%     % b のスイープ配列作成 (対数スケール)
%     b_sweep = logspace(log10(b_min), log10(b_max), num_samples);
    
%     % 統計データ格納用
%     ratio_list = zeros(1, num_samples);
    
%     fprintf('Calculating statistics for b = %.2g to %.2g [m] (%d points)...\n', ...
%             b_min, b_max, num_samples);

%     %% 2. スイープ計算ループ
%     for i = 1:num_samples
%         b = b_sweep(i);
        
%         % シミュレーション実行
%         [~, ~, ~, PSD_ax, ~, PSD_total, ~] = run_simulation(b, v0, k, e_c, m_e, Z);
        
%         % 統計指標: エネルギー比率 (Transverse / Total)
%         total_energy = sum(PSD_total);
%         trans_energy = sum(PSD_ax);
        
%         ratio_list(i) = trans_energy / total_energy;
        
%         % 進捗表示 (10回に1回)
%         if mod(i, 5) == 0, fprintf('.'); end
%     end
%     fprintf(' Done.\n');
    
%     %% 3. 図1: 統計的評価 (一致度のグラフ)
%     figure('Name', 'Statistical Approximation Analysis', 'Color', 'w', 'Position', [50, 500, 600, 400]);
    
%     semilogx(b_sweep * 1e10, ratio_list, 'ko-', 'LineWidth', 1.5, 'MarkerFaceColor', 'b', 'MarkerSize', 4);
%     grid on;
%     xlabel('Impact Parameter b [{\AA}] (Log Scale)');
%     ylabel('Approximation Ratio (Transverse / Total)');
%     title(sprintf('Approximation Accuracy (Range: %.1f - %.1f A)', b_min*1e10, b_max*1e10));
%     ylim([0, 1.1]);
    
%     % 目安ライン
%     yline(0.9, 'g--', 'Good (>90%)', 'LabelHorizontalAlignment', 'left');
%     yline(0.5, 'r--', 'Poor (<50%)', 'LabelHorizontalAlignment', 'left');
    
%     %% 4. 図2〜4: 代表的なケースの詳細プロット (範囲内のMin, Mid, Max)
%     idx_cases = [1, round(num_samples/2), num_samples];
%     titles = {'Case 1: Closest (b_min)', ...
%               'Case 2: Middle Range', ...
%               'Case 3: Furthest (b_max)'};
    
%     for k = 1:3
%         idx = idx_cases(k);
%         b_val = b_sweep(idx);
%         score = ratio_list(idx);
        
%         % 再計算
%         [t, ax, ay, PSD_ax, PSD_ay, PSD_total, results] = run_simulation(b_val, v0, k, e_c, m_e, Z);
        
%         % プロット
%         create_detailed_plot(titles{k}, b_val, score, t, ax, ay, PSD_ax, PSD_ay, PSD_total, results);
%     end
% end

% %% --- サブ関数: 物理シミュレーション本体 ---
% function [t_out, ax, ay, PSD_ax, PSD_ay, PSD_total, res] = run_simulation(b, v0, k_c, e_c, m_e, Z)
%     L_range = 10 * b;
%     y_start = -L_range;
%     t_span = [0, 2.5 * L_range / v0];
%     init = [b; y_start; 0; v0];
    
%     opts = odeset('RelTol', 1e-6, 'AbsTol', 1e-9);
%     f = @(t,s) eq_motion(s, k_c, e_c, m_e, Z);
%     [t_raw, s] = ode45(f, t_span, init, opts);
    
%     % Resampling
%     N = 4096;
%     t_out = linspace(t_raw(1), t_raw(end), N);
%     x = spline(t_raw, s(:,1), t_out);
%     y = spline(t_raw, s(:,2), t_out);
    
%     % Acceleration
%     r2 = x.^2 + y.^2; r = sqrt(r2);
%     % r=0での特異点回避（極端に近い場合）
%     r(r<1e-13) = 1e-13; r2(r2<1e-26) = 1e-26;
    
%     F = k_c * abs(e_c^2*Z) ./ r2;
%     ax = -F .* (x./r) / m_e;
%     ay = -F .* (y./r) / m_e;
    
%     % Power (Larmor)
%     c = 2.998e8; eps0 = 8.854e-12;
%     a2 = ax.^2 + ay.^2;
%     Power = (e_c^2 * a2) / (6*pi*eps0*c^3);
    
%     % FFT
%     dt = t_out(2)-t_out(1); Fs = 1/dt;
%     freq = Fs*(0:N/2)/N;
%     win = hann(N)';
    
%     Pax = abs(fft(ax.*win)/N).^2; Pax = Pax(1:N/2+1);
%     Pay = abs(fft(ay.*win)/N).^2; Pay = Pay(1:N/2+1);
    
%     PSD_ax = Pax; PSD_ay = Pay; PSD_total = Pax + Pay;
    
%     res.x = x; res.y = y; res.Power = Power; res.freq = freq;
% end

% function ds = eq_motion(s, k, e, m, Z)
%     x=s(1); y=s(2); vx=s(3); vy=s(4);
%     r2 = x^2+y^2; r=sqrt(r2);
%     if r < 1e-13, r=1e-13; r2=1e-26; end % 安全装置
%     F = k*abs(e^2*Z)/r2;
%     ds = [vx; vy; -F*(x/r)/m; -F*(y/r)/m];
% end

% %% --- サブ関数: 詳細プロット作成 ---
% function create_detailed_plot(fig_title, b, score, t, ax, ay, PSD_ax, PSD_ay, PSD_total, res)
%     figure('Name', fig_title, 'Color', 'w', 'Position', [100, 100, 1000, 700]);
    
%     % 1. 軌道
%     subplot(2,2,1);
%     plot(res.x*1e9, res.y*1e9, 'b-', 'LineWidth', 1.5); hold on;
%     plot(0, 0, 'r+', 'MarkerSize', 10, 'LineWidth', 2);
%     title(sprintf('1. Trajectory (b=%.2f A)', b*1e10));
%     xlabel('x [nm]'); ylabel('y [nm]'); axis equal; grid on;
    
%     % 2. Power
%     subplot(2,2,2);
%     plot(t*1e15, res.Power, 'k', 'LineWidth', 1.5);
%     title('2. Radiated Power');
%     xlabel('Time [fs]'); ylabel('Watts'); grid on; xlim([0, t(end)*1e15]);
    
%     % 3. Acceleration
%     subplot(2,2,3);
%     plot(t*1e15, ax, 'r--', 'DisplayName', 'ax (Trans)'); hold on;
%     plot(t*1e15, ay, 'b--', 'DisplayName', 'ay (Long)');
%     plot(t*1e15, sqrt(ax.^2+ay.^2), 'k-', 'DisplayName', 'Total');
%     title('3. Acceleration Comp.');
%     xlabel('Time [fs]'); legend('Location','best'); grid on; xlim([0, t(end)*1e15]);
    
%     % 4. Spectrum
%     subplot(2,2,4);
%     f_PHz = res.freq / 1e15;
%     loglog(f_PHz, PSD_total, 'k-', 'LineWidth', 2, 'DisplayName', 'Total'); hold on;
%     loglog(f_PHz, PSD_ax, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Transverse');
    
%     title(sprintf('4. Spectrum (Match: %.1f%%)', score*100));
%     xlabel('Freq [PHz]'); ylabel('Power Density'); 
%     legend('Location','southwest'); grid on; xlim([0.1, 100]);
    
%     text(0.2, max(PSD_total)*0.1, sprintf('Score: %.2f', score), ...
%         'FontSize', 12, 'Color', 'b', 'FontWeight', 'bold');
% end

%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%係数さがし
% function bremsstrahlung_polyfit_approx
%     % BREMSSTRAHLUNG_POLYFIT_APPROX
%     % 定数倍ではなく「周波数の1次関数」で近似係数を作る
%     % Total(f) = Transverse(f) * (p1 * f + p2)
    
%     clear; close all; clc;

%     %% 1. 設定
%     % -------------------------------------------------------------
%     E_eV = 100.0;     % [eV]
%     b_target = 1.0e-10; % [m] フィッティングの基準にするインパクトパラメータ
    
%     % 近似に使う周波数範囲 (ノイズを除いた信頼できる領域)
%     f_fit_min = 0.1;  % [PHz]
%     f_fit_max = 20.0; % [PHz] 100eVならこのあたりまでが重要
%     % -------------------------------------------------------------

%     % 物理定数
%     e_c = 1.602e-19; m_e = 9.109e-31; eps0 = 8.854e-12; k = 1/(4*pi*eps0);
%     Z = 1; 
%     v0 = sqrt(2 * (E_eV * e_c) / m_e);
    
%     fprintf('--- Fitting Approximation Model ---\n');
%     fprintf('Target b: %.2f A, Energy: %.1f eV\n', b_target*1e10, E_eV);

%     %% 2. シミュレーション実行 (教師データ作成)
%     [t, ax, ay, PSD_ax, ~, PSD_total, results] = run_simulation(b_target, v0, k, e_c, m_e, Z);
    
%     f_PHz = results.freq / 1e15;
    
%     %% 3. フィッティング (魔法の式を作る)
%     % Ratio = Total / Transverse を計算
%     % ゼロ割防止
%     valid_mask = (f_PHz >= f_fit_min) & (f_PHz <= f_fit_max);
    
%     Y_ratio = PSD_total(valid_mask) ./ PSD_ax(valid_mask);
%     X_freq  = f_PHz(valid_mask);
    
%     % ★ 1次関数 (Linear) でフィッティング: y = p(1)*x + p(2)
%     p = polyfit(X_freq, Y_ratio, 1);
    
%     fprintf('Resulting Formula:\n');
%     fprintf('  Correction_Factor(f) = %.4f * f[PHz] + %.4f\n', p(1), p(2));
    
%     % 近似スペクトルの作成
%     % 全周波数領域に対してこの式を適用
%     Correction_Curve = polyval(p, f_PHz); 
%     % 補正係数が1.0を下回るとおかしいので、最低1.0でクリップしても良いが、
%     % ここではあえてそのまま適用して精度を見る
    
%     PSD_approx = PSD_ax .* Correction_Curve;

%     %% 4. プロット作成
%     figure('Name', 'Linear Fitting Approximation', 'Color', 'w', 'Position', [100, 100, 1000, 600]);
    
%     % (1) スペクトル比較
%     subplot(1, 2, 1);
%     loglog(f_PHz, PSD_total, 'k-', 'LineWidth', 3, 'DisplayName', 'True Total'); hold on;
%     loglog(f_PHz, PSD_ax, 'b:', 'LineWidth', 1.5, 'DisplayName', 'Transverse (Raw)');
%     loglog(f_PHz, PSD_approx, 'r--', 'LineWidth', 2, 'DisplayName', 'Approximation');
    
%     title('Spectrum Comparison');
%     xlabel('Frequency [PHz]'); ylabel('Power Density');
%     legend('Location', 'southwest'); grid on;
%     xlim([0.05, 50]);
    
%     % (2) 係数のフィッティング状況
%     subplot(1, 2, 2);
%     plot(f_PHz, PSD_total./PSD_ax, 'b.', 'MarkerSize', 10, 'DisplayName', 'Actual Ratio'); hold on;
%     plot(f_PHz, Correction_Curve, 'r-', 'LineWidth', 2, 'DisplayName', 'Linear Fit');
    
%     xline(f_fit_min, 'k:'); xline(f_fit_max, 'k:');
%     text(mean([f_fit_min, f_fit_max]), max(Y_ratio), 'Fitting Range', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
    
%     title('Approximation Factor Model');
%     xlabel('Frequency [PHz]'); ylabel('Factor (Total/Trans)');
%     legend('Location', 'best'); grid on;
%     xlim([0, 30]); % 線形軸で見やすく
%     ylim([0.8, max(Y_ratio)*1.2]);
    
%     % 式を表示
%     dim = [0.55 0.5 0.3 0.3];
%     str = sprintf('Approx = Trans \\times (%.3f f + %.3f)', p(1), p(2));
%     annotation('textbox', dim, 'String', str, 'FitBoxToText', 'on', 'BackgroundColor', 'w', 'FontSize', 12, 'EdgeColor', 'r');

% end

% %% --- サブ関数 ---
% function [t_out, ax, ay, PSD_ax, PSD_ay, PSD_total, res] = run_simulation(b, v0, k_c, e_c, m_e, Z)
%     L_range = 15 * b; 
%     y_start = -L_range;
%     t_span = [0, 3.0 * L_range / v0];
%     init = [b; y_start; 0; v0];
    
%     opts = odeset('RelTol', 1e-6, 'AbsTol', 1e-9);
%     f = @(t,s) eq_motion(s, k_c, e_c, m_e, Z);
%     [t_raw, s] = ode45(f, t_span, init, opts);
    
%     N = 8192; 
%     t_out = linspace(t_raw(1), t_raw(end), N);
%     x = spline(t_raw, s(:,1), t_out);
%     y = spline(t_raw, s(:,2), t_out);
    
%     r2 = x.^2 + y.^2; r = sqrt(r2);
%     if r < 1e-13, r=1e-13; r2=1e-26; end
%     F = k_c * abs(e_c^2*Z) ./ r2;
%     ax = -F .* (x./r) / m_e;
%     ay = -F .* (y./r) / m_e;
    
%     dt = t_out(2)-t_out(1); Fs = 1/dt;
%     freq = Fs*(0:N/2)/N;
%     win = hann(N)';
    
%     Pax = abs(fft(ax.*win)/N).^2; Pax = Pax(1:N/2+1);
%     Pay = abs(fft(ay.*win)/N).^2; Pay = Pay(1:N/2+1);
    
%     PSD_ax = Pax; PSD_ay = Pay; PSD_total = Pax + Pay;
%     res.freq = freq;
% end

% function ds = eq_motion(s, k, e, m, Z)
%     x=s(1); y=s(2); vx=s(3); vy=s(4);
%     r2 = x^2+y^2; r=sqrt(r2);
%     if r < 1e-13, r=1e-13; r2=1e-26; end
%     F = k*abs(e^2*Z)/r2;
%     ds = [vx; vy; -F*(x/r)/m; -F*(y/r)/m];
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %%%%%%%%%%%近似後
% function bremsstrahlung_100eV_linear_fit
%     % BREMSSTRAHLUNG_100EV_LINEAR_FIT
%     % 定数倍ではなく、周波数依存の1次関数で補正を行う最終版
%     % Correction = 0.0287 * f[PHz] + 1.1749
    
%     clear; close all; clc;

%     %% 1. 設定
%     % -------------------------------------------------------------
%     E_eV = 100.0;             % 初期エネルギー [eV]
    
%     % ★ 得られた近似式の係数 (Correction = p1 * f + p2)
%     p1 = 0.0287;  % 傾き (Slope)
%     p2 = 1.1749;  % 切片 (Intercept)
    
%     b_min = 0.5e-10;  % [m]
%     b_max = 5.0e-10;  % [m]
%     num_samples = 3;  % ケース数
%     % -------------------------------------------------------------

%     % 物理定数
%     e_c = 1.60217663e-19; m_e = 9.10938356e-31; eps0 = 8.85418781e-12; k = 1/(4*pi*eps0);
%     Z = 1; 

%     % 速度計算
%     E_joule = E_eV * e_c;
%     v0 = sqrt(2 * E_joule / m_e);
    
%     fprintf('--- Simulation Condition ---\n');
%     fprintf('Energy: %.1f [eV] (v=%.2e m/s)\n', E_eV, v0);
%     fprintf('Correction: %.4f * f + %.4f\n', p1, p2);
    
%     b_sweep = logspace(log10(b_min), log10(b_max), num_samples);

%     %% 2. ループ計算
%     for i = 1:num_samples
%         b = b_sweep(i);
        
%         % シミュレーション実行
%         [t, ax, ay, PSD_ax, ~, PSD_total, results] = run_simulation(b, v0, k, e_c, m_e, Z);
        
%         % 周波数軸の取得 (補正計算に必要)
%         f_PHz = results.freq / 1e15;
        
%         % ★ 補正計算 (1次関数適用)
%         % Correction_Factor(f) = 0.0287 * f + 1.1749
%         correction_curve = p1 * f_PHz + p2;
        
%         % 補正係数が負にならないようガード（物理的にありえないので）
%         correction_curve(correction_curve < 0) = 0; 
        
%         PSD_corrected = PSD_ax .* correction_curve;
        
%         % Ratio計算 (NaNマスク処理付き)
%         Ratio = nan(size(PSD_total)); 
%         threshold = max(PSD_total) * 1e-4; 
%         valid_idx = PSD_total > threshold;
%         Ratio(valid_idx) = PSD_corrected(valid_idx) ./ PSD_total(valid_idx);
        
%         % プロット作成
%         title_str = sprintf('Case %d: b = %.2f A (100eV)', i, b*1e10);
%         create_linear_plot(title_str, t, ax, ay, PSD_ax, PSD_corrected, PSD_total, Ratio, results, p1, p2);
%     end
    
%     fprintf('Done.\n');
% end

% %% --- サブ関数: シミュレーション ---
% function [t_out, ax, ay, PSD_ax, PSD_ay, PSD_total, res] = run_simulation(b, v0, k_c, e_c, m_e, Z)
%     L_range = 15 * b; 
%     y_start = -L_range;
%     t_est = 3.0 * L_range / v0; 
%     t_span = [0, t_est];
%     init = [b; y_start; 0; v0];
    
%     opts = odeset('RelTol', 1e-6, 'AbsTol', 1e-9);
%     f = @(t,s) eq_motion(s, k_c, e_c, m_e, Z);
%     [t_raw, s] = ode45(f, t_span, init, opts);
    
%     N = 8192; 
%     t_out = linspace(t_raw(1), t_raw(end), N);
%     x = spline(t_raw, s(:,1), t_out);
%     y = spline(t_raw, s(:,2), t_out);
    
%     r2 = x.^2 + y.^2; r = sqrt(r2);
%     if r < 1e-13, r=1e-13; r2=1e-26; end
%     F = k_c * abs(e_c^2*Z) ./ r2;
%     ax = -F .* (x./r) / m_e;
%     ay = -F .* (y./r) / m_e;
    
%     c = 2.998e8; eps0 = 8.854e-12;
%     a2 = ax.^2 + ay.^2;
%     Power = (e_c^2 * a2) / (6*pi*eps0*c^3);
    
%     dt = t_out(2)-t_out(1); Fs = 1/dt;
%     freq = Fs*(0:N/2)/N;
%     win = hann(N)';
    
%     Pax = abs(fft(ax.*win)/N).^2; Pax = Pax(1:N/2+1);
%     Pay = abs(fft(ay.*win)/N).^2; Pay = Pay(1:N/2+1);
    
%     PSD_ax = Pax; PSD_ay = Pay; PSD_total = Pax + Pay;
%     res.x = x; res.y = y; res.Power = Power; res.freq = freq;
% end

% function ds = eq_motion(s, k, e, m, Z)
%     x=s(1); y=s(2); vx=s(3); vy=s(4);
%     r2 = x^2+y^2; r=sqrt(r2);
%     if r < 1e-13, r=1e-13; r2=1e-26; end
%     F = k*abs(e^2*Z)/r2;
%     ds = [vx; vy; -F*(x/r)/m; -F*(y/r)/m];
% end

% %% --- サブ関数: プロット作成 (Linear Fit対応版) ---
% function create_linear_plot(fig_title, t, ax, ay, PSD_ax, PSD_corrected, PSD_total, Ratio, res, p1, p2)
%     figure('Name', fig_title, 'Color', 'w', 'Position', [100, 50, 900, 800]);
    
%     % 1. 軌道
%     subplot(3,2,1);
%     plot(res.x*1e9, res.y*1e9, 'b-', 'LineWidth', 1.5); hold on;
%     plot(0, 0, 'r+', 'MarkerSize', 10, 'LineWidth', 2);
%     axis equal; grid on;
%     title('1. Trajectory'); xlabel('x [nm]'); ylabel('y [nm]'); 
    
%     % 2. Power
%     subplot(3,2,2);
%     plot(t*1e15, res.Power, 'k', 'LineWidth', 1.5);
%     title('2. Radiated Power'); xlabel('Time [fs]'); ylabel('Watts'); grid on; 
%     xlim([0, t(end)*1e15]);
    
%     % 3. Acceleration
%     subplot(3,2,3);
%     plot(t*1e15, ax, 'r--', 'DisplayName', 'ax'); hold on;
%     plot(t*1e15, ay, 'b:', 'DisplayName', 'ay');
%     plot(t*1e15, sqrt(ax.^2+ay.^2), 'k-', 'DisplayName', 'Total');
%     title('3. Acceleration'); xlabel('Time [fs]'); legend('Location','best'); grid on; 
%     xlim([0, t(end)*1e15]);
    
%     % 4. Spectrum
%     subplot(3,2,4);
%     f_PHz = res.freq / 1e15;
%     loglog(f_PHz, PSD_total, 'k-', 'LineWidth', 2, 'DisplayName', 'Total'); hold on;
    
%     % 補正係数の数式を凡例用に文字列化
%     fit_str = sprintf('Trans \\times (%.3ff + %.3f)', p1, p2);
%     loglog(f_PHz, PSD_corrected, 'g-.', 'LineWidth', 2, 'DisplayName', fit_str);
    
%     loglog(f_PHz, PSD_ax, 'r:', 'LineWidth', 1, 'DisplayName', 'Trans (Raw)');
%     title('4. Spectrum'); xlabel('Freq [PHz]'); ylabel('Power'); 
%     legend('Location','southwest'); grid on; xlim([0.01, 100]);
    
%     % 5. Approximation Ratio
%     subplot(3,2, [5, 6]);
%     semilogx(f_PHz, Ratio, 'b-', 'LineWidth', 2); hold on;
    
%     yline(1.0, 'k-', 'Perfect', 'LineWidth', 1.5);
%     yline(1.1, 'g--', '+10%'); yline(0.9, 'g--', '-10%');
    
%     title(sprintf('5. Ratio (Corrected / Total) [Linear Fit: %.3f f + %.3f]', p1, p2));
%     xlabel('Frequency [PHz]'); ylabel('Ratio');
%     grid on;
%     xlim([0.01, 100]); ylim([0.5, 1.5]); 
    
%     % 平均スコア計算
%     valid_mask = ~isnan(Ratio) & (f_PHz > 0.01); 
    
%     if any(valid_mask)
%         mean_ratio = mean(Ratio(valid_mask));
%         max_valid_f = max(f_PHz(valid_mask));
%         str_res = sprintf('Mean Ratio: %.3f\n(Range: 0.01 - %.1f PHz)', mean_ratio, max_valid_f);
%         text(0.02, 0.6, str_res, 'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'EdgeColor', 'k');
%     else
%         text(0.02, 0.6, 'No valid signal range', 'FontSize', 12, 'Color', 'r');
%     end
% end







%%%%%%%%%%%%%%%%%%%%%%%%

function bremsstrahlung_validity_check
    % BREMSSTRAHLUNG_VALIDITY_CHECK
    % 「縦成分無視近似」が成立する条件と破綻する条件を検証するコード
    % 
    % 比較対象:
    % 1. True Total Power (ax^2 + ay^2)
    % 2. Approx Power (ax^2 only)
    %
    % 目的: b (衝突径数) によって近似精度がどう変わるか可視化する

    clear; close all; clc;

    %% 1. 設定
    % -------------------------------------------------------------
    E_eV = 1000.0;           % 電子エネルギー [eV]
    
    % 検証する3つのケース（ここが重要）
    % Case 1: 激突 (0.1 A) -> 理論上、近似が成り立つはず
    % Case 2: 境界 (0.5 A) -> 怪しくなってくる領域
    % Case 3: 遠方 (2.0 A) -> 近似が破綻する領域
    b_list = [0.1, 0.5, 2.0] * 1.0e-10; 
    
    % -------------------------------------------------------------

    % 物理定数
    e_c = 1.60217663e-19; m_e = 9.10938356e-31; eps0 = 8.85418781e-12; 
    k_c = 1/(4*pi*eps0); c = 2.99792458e8;
    Z = 1; 

    % 初速度
    v0 = sqrt(2 * (E_eV * e_c) / m_e);
    
    fprintf('--- Validity Check Simulation ---\n');
    fprintf('Electron Energy: %.1f eV (v = %.2e m/s)\n', E_eV, v0);

    %% 2. ケースごとのループ実行
    for i = 1:length(b_list)
        b = b_list(i);
        
        % シミュレーション実行
        [t, ax, ay, PSD_ax, PSD_total, results] = run_simulation(b, v0, k_c, e_c, m_e, Z);
        
        % 結果のプロット
        create_validation_plot(i, b, v0, t, ax, ay, PSD_ax, PSD_total, results);
    end
    
    fprintf('Done.\n');
end

%% --- サブ関数: 物理計算部分 (純粋な物理のみ) ---
function [t_out, ax, ay, PSD_ax, PSD_total, res] = run_simulation(b, v0, k_c, e_c, m_e, Z)
    % 時間設定: 衝突の前後十分な時間をとる
    L_range = 20 * b; 
    y_start = -L_range;
    t_est = 2.5 * (2 * L_range) / v0; % 余裕を持って
    t_span = [0, t_est];
    
    initial_state = [b; y_start; 0; v0]; % [x, y, vx, vy]
    
    % 運動方程式を解く (精度を高めに設定)
    opts = odeset('RelTol', 1e-8, 'AbsTol', 1e-10);
    f = @(t,s) eq_motion(s, k_c, e_c, m_e, Z);
    [t_raw, s] = ode45(f, t_span, initial_state, opts);
    
    % リサンプリング (FFTのために等間隔化)
    N = 16384; % 点数を多めにして周波数分解能を確保
    t_out = linspace(t_raw(1), t_raw(end), N);
    x = spline(t_raw, s(:,1), t_out);
    y = spline(t_raw, s(:,2), t_out);
    
    % 加速度計算 (F=ma)
    r2 = x.^2 + y.^2; r = sqrt(r2);
    % ゼロ割防止
    r(r < 1e-14) = 1e-14; r2(r2 < 1e-28) = 1e-28;
    
    F_mag = k_c * abs(e_c^2*Z) ./ r2;
    ax = -F_mag .* (x./r) / m_e; % Transverse (横成分)
    ay = -F_mag .* (y./r) / m_e; % Longitudinal (縦成分)
    
    % スペクトル計算 (FFT)
    dt = t_out(2) - t_out(1);
    Fs = 1/dt;
    freq = Fs * (0:N/2) / N;
    
    win = hann(N)'; % 窓関数
    
    % パワースペクトル密度 (PSD)
    % PSD ~ |fft|^2
    Pax = abs(fft(ax .* win)/N).^2; Pax = Pax(1:N/2+1);
    Pay = abs(fft(ay .* win)/N).^2; Pay = Pay(1:N/2+1);
    
    PSD_ax = Pax;
    PSD_total = Pax + Pay; % Parsevalの定理より単純和でOK
    
    % 結果格納
    res.freq = freq;
    res.x = x; res.y = y;
end

function ds = eq_motion(s, k, e, m, Z)
    x=s(1); y=s(2); vx=s(3); vy=s(4);
    r2 = x^2+y^2; r=sqrt(r2);
    if r < 1e-14, r=1e-14; r2=1e-28; end
    F = k*abs(e^2*Z)/r2;
    ds = [vx; vy; -F*(x/r)/m; -F*(y/r)/m];
end

%% --- サブ関数: 検証用プロット ---
function create_validation_plot(fig_id, b, v0, t, ax, ay, PSD_ax, PSD_total, res)
    f_PHz = res.freq / 1e15;
    
    % 理論的カットオフ周波数 (omega * tau = 1 となる周波数)
    % f_cut = v / (2*pi*b)
    f_cut_PHz = (v0 / (2*pi*b)) / 1e15;

    figure('Name', sprintf('Validation Case %d', fig_id), 'Color', 'w', 'Position', [100+50*fig_id, 100, 800, 600]);
    
    % 1. 軌道と加速度
    subplot(2,2,1);
    plot(res.x*1e10, res.y*1e10, 'b-'); hold on;
    plot(0,0,'r+');
    title(sprintf('Trajectory (b=%.2f A)', b*1e10));
    xlabel('x [A]'); ylabel('y [A]'); axis equal; grid on;
    
    subplot(2,2,2);
    plot(t*1e15, ax, 'r', 'DisplayName', 'ax (Trans)'); hold on;
    plot(t*1e15, ay, 'b', 'DisplayName', 'ay (Long)');
    title('Acceleration Components');
    legend; grid on; xlabel('fs'); xlim([0, t(end)*1e15]);

    % 2. スペクトル比較
    subplot(2,2,3);
    loglog(f_PHz, PSD_total, 'k-', 'LineWidth', 2, 'DisplayName', 'True (Total)'); hold on;
    loglog(f_PHz, PSD_ax, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Approx (ax only)');
    xline(f_cut_PHz, 'g:', 'Label', '\omega\tau=1', 'LabelVerticalAlignment', 'bottom');
    
    title('Spectrum Comparison');
    xlabel('Freq [PHz]'); ylabel('Power');
    legend('Location', 'southwest'); grid on;
    xlim([0.1, 100]);
    
    % 3. 近似の妥当性 (比率)
    subplot(2,2,4);
    % ノイズ対策: パワーがある程度あるところだけ計算
    valid_idx = PSD_total > max(PSD_total)*1e-6;
    Ratio = PSD_ax(valid_idx) ./ PSD_total(valid_idx);
    f_valid = f_PHz(valid_idx);
    
    semilogx(f_valid, Ratio, 'b-', 'LineWidth', 2); hold on;
    yline(1.0, 'k-', 'Perfect');
    yline(0.9, 'r:', '10% Error');
    xline(f_cut_PHz, 'g:', '\omega\tau=1');
    
    title('Approximation Validity (Trans/Total)');
    xlabel('Freq [PHz]'); ylabel('Ratio');
    grid on; ylim([0, 1.1]); xlim([0.1, 100]);
    
    % 解説テキスト
    if f_cut_PHz > 50
        status = 'Valid'; color = 'g';
    elseif f_cut_PHz > 5
        status = 'Marginal'; color = 'y';
    else
        status = 'Invalid'; color = 'r';
    end
    text(0.2, 0.2, sprintf('Status: %s\n(Cutoff: %.1f PHz)', status, f_cut_PHz), ...
        'Units', 'normalized', 'EdgeColor', color, 'BackgroundColor', 'w', 'FontWeight', 'bold');
end
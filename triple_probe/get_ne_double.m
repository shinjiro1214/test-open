%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Double Probe Analysis (Offset-Based Symmetry)
% UNCONSTRAINED FIT
% 1. Determine Offset from I at V=0
% 2. Create virtual negative data mirroring around the Offset
% 3. Unconstrained Tanh Fit (Isat & Te limits removed)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars -except filepath DOCID; 

% --- 設定パラメータ ---
date = 251219; 
shotlist = [64:67 70:73 80:82 90:92 93 94 96 100:104 107:113 121]; 

% filepath = "/Users/shohgookazaki/Documents/UTokyo/OnoTanabeLab/koala/home/pub/mnt/data/TripleProbe/"; 
filepath = getenv('NIFS_TRIPLE');
DOCID = '1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw'; 

% target_time_range = 464:1:476; 
target_time_range = 460:1:480; 
time_window_width = 1.0; 

% 物理定数
S_probe = 1.4e-5;      % [m^2]
q = 1.60217663e-19;    % [C]
mi = 1.0 * 1.66054e-27;% [kg]

% --- データ読み込み ---
if ~exist('T', 'var'), T = getTS6log(DOCID); end
node = 'date'; T_date = searchlog(T, node, date);
voltage_col_name = 'doubleProbeVoltage_V_'; 

num_shots = length(shotlist);
time_us_common = linspace(450, 600, 300); 
V_matrix = zeros(num_shots, 1);       
I2_matrix = zeros(num_shots, length(time_us_common)); 
valid_idx = 0;

fprintf('Loading data...\n');
for i = 1:num_shots
    shot = shotlist(i);
    idx_log = find(T_date.shot == shot, 1);
    if isempty(idx_log), continue; end
    try
        V_val = T_date.(voltage_col_name)(idx_log);
    catch
        error('列名エラー');
    end
    filename = strcat(filepath, num2str(date), '/ES_', num2str(date), sprintf('%03d', shot), '.csv');
    if exist(filename, 'file')
        data = readmatrix(filename);
        raw_time = data(4500:7500, 1); 
        raw_I2 = fillmissing(data(4500:7500, 36), 'linear'); 
        raw_I2 = smoothdata(raw_I2, 'movmean', 100); 
        I2_interp = interp1(raw_time, raw_I2, time_us_common, 'linear', NaN);
        valid_idx = valid_idx + 1;
        V_matrix(valid_idx) = V_val;
        I2_matrix(valid_idx, :) = I2_interp;
    end
end
V_data = round(V_matrix(1:valid_idx), 1); 
I2_data = I2_matrix(1:valid_idx, :);

% --- 解析 ---
fprintf('Analyzing...\n');
figure('Position', [100, 100, 1200, 500]);
colors = jet(length(target_time_range));

% === 左図: IV特性 ===
subplot(1, 2, 1); hold on; grid on;
title('Offset-Based Symmetry Fit (No Limits)');
xlabel('Voltage [V]'); ylabel('Current I_2 [A]');

% フィッティング関数
fit_func = @(x, v) x(1) * tanh((v - x(2)) / (2 * x(3))) + x(4);

Isat_res = []; ne_res = []; Te_res = [];

for t_idx = 1:length(target_time_range)
    t_target = target_time_range(t_idx);
    
    t_min = t_target - time_window_width / 2;
    t_max = t_target + time_window_width / 2;
    window_indices = find(time_us_common >= t_min & time_us_common <= t_max);
    if isempty(window_indices), continue; end
    I_snapshot = mean(I2_data(:, window_indices), 2, 'omitnan');
    
    % 実データ (平均化)
    unique_V = unique(V_data);
    mean_I = zeros(size(unique_V));
    std_I = zeros(size(unique_V));
    for k = 1:length(unique_V)
        idx_v = (V_data == unique_V(k));
        vals = I_snapshot(idx_v);
        mean_I(k) = mean(vals, 'omitnan');
        if sum(~isnan(vals)) > 1, std_I(k) = std(vals, 0, 'omitnan'); else, std_I(k) = 0; end
    end
    
    % プロット (実測値のみ)
    errorbar(unique_V, mean_I, std_I, 'o', 'Color', colors(t_idx, :), ...
        'MarkerFaceColor', colors(t_idx, :), 'MarkerSize', 6, 'LineStyle', 'none', ...
        'DisplayName', sprintf('%d \\mus', t_target));
    
    % --- Offset Symmetry データ生成 ---
    idx_0V = find(unique_V == 0);
    if ~isempty(idx_0V)
        I_offset = mean_I(idx_0V);
    else
        [~, min_idx] = min(abs(unique_V));
        I_offset = mean_I(min_idx);
    end
    
    V_real = unique_V;
    I_real = mean_I;
    I_pure = I_real - I_offset; 
    
    V_virtual = -V_real;
    I_virtual = -I_pure + I_offset;
    
    V_fit_data = [V_virtual; V_real];
    I_fit_data = [I_virtual; I_real];
    
    [V_fit_data, sort_idx] = sort(V_fit_data);
    I_fit_data = I_fit_data(sort_idx);
    [V_fit_data, uniq_idx] = unique(V_fit_data);
    I_fit_data = I_fit_data(uniq_idx);

    % --- フィッティング (制限なし) ---
    I_range = max(I_fit_data) - min(I_fit_data);
    
    % % 初期値 x0 = [Isat, Vf, Te, Offset]
    % x0 = [I_range, 0, 50, I_offset]; 
    
    % % ========================================================
    % % 【対策1】 物理的な上限を設定する
    % % ========================================================
    % % 例: Isatは観測された最大電流の3倍まで、Teは最大100eVまで、など
    % I_max_obs = max(abs(I_fit_data)); % 観測された最大電流
    
    % lb = [0, -100, 0.1, -Inf]; 
    % % ub = [Inf, 100, Inf, Inf]; % 元のコード（青天井）
    
    % % 変更後: Isatの上限を観測値の数倍に、Teの上限を物理的にありそうな値(例: 50eV)にする
    % ub = [I_max_obs * 5, 100, 50, Inf];
    
    % opts = optimset('Display', 'off', 'MaxFunEvals', 1000, 'TolFun', 1e-6);

    I_max_obs = max(I_fit_data); % 生データの最大値
    
    % 初期値
    x0 = [I_max_obs, 0, 10, I_offset]; 
    
    % Isat の探索範囲を 「最大値の 1.0倍 〜 1.5倍」 程度に狭める
    % これにより、Isatが無限大に発散するのを防ぎ、結果としてTeの発散も止まる
    lb = [I_max_obs * 0.9, -100, 0.1, -Inf]; 
    ub = [I_max_obs * 1.5,  100, 100,  Inf]; 
    
    opts = optimset('Display', 'off', 'MaxFunEvals', 1000, 'TolFun', 1e-6);
    
    try
        params = lsqcurvefit(fit_func, x0, V_fit_data, I_fit_data, lb, ub, opts);
        
        I_is = params(1);       % 飽和電流
        Te_eV = params(3);      % 電子温度
        
        % 曲線の描画
        v_fit = linspace(min(V_fit_data), max(V_fit_data), 100);
        plot(v_fit, fit_func(params, v_fit), '-', 'Color', colors(t_idx, :), 'LineWidth', 1.5, 'HandleVisibility', 'off');
        
        % 原点での傾き alpha
        alpha_fit = I_is / (2 * Te_eV);
        
        % ne の計算
        term1 = exp(0.5) / (q * S_probe);
        term2 = sqrt( (2 * mi * alpha_fit * I_is) / q );
        ne_calc = term1 * term2;
        
        Isat_res(t_idx) = I_is;
        Te_res(t_idx) = Te_eV;
        ne_res(t_idx) = ne_calc;
        
    catch
        Isat_res(t_idx) = NaN; Te_res(t_idx) = NaN; ne_res(t_idx) = NaN;
    end
end
legend('Location', 'eastoutside');
if ~isempty(unique_V)
    max_V_val = max(unique_V);
    xlim([-max_V_val - 5, max_V_val + 5]);
end

% === 右図: 計算結果 ===
subplot(1, 2, 2);
yyaxis left
plot(target_time_range, ne_res, '-^', 'LineWidth', 2);
ylabel('n_e [m^{-3}]');
m_ne = max(ne_res(~isinf(ne_res)), [], 'omitnan');
if isempty(m_ne) || m_ne<=0, ylim([0, 1e18]); else, ylim([0, m_ne*1.2]); end

yyaxis right
plot(target_time_range, Te_res, '-s', 'LineWidth', 2);
ylabel('T_e [eV]');

% Y軸範囲の自動調整 (Infや異常値対策)
m_Te = max(Te_res(~isinf(Te_res)), [], 'omitnan');
if isempty(m_Te) || m_Te<=0
    ylim([0, 20]);
elseif m_Te > 200
    % 200eVを超える場合はそのまま表示 (制限なしの結果を確認するため)
    ylim([0, m_Te * 1.1]);
else
    ylim([0, m_Te * 1.2]);
end

xlabel('Time [\mus]');
title('Calculated Parameters (Unconstrained)');
grid on;

fprintf('Done.\n');
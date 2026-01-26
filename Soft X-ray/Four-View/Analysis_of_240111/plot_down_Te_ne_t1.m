clearvars -except triple_data2D R_values time_values; % Teデータがロード済みなら保持

% =========================================================================
%  設定 & データパス定義
% =========================================================================

% --- SXR設定 ---
SXR_mat_path = '/Users/shinjirotakeda/Library/CloudStorage/OneDrive-TheUniversityofTokyo/Documents/data/SXRdata/240111_LF_NLR.mat';
SXR_baseDir  = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_NLR/240111';

idxList = [7:9, 28:30]; % SXR対象ショット
num_t = 5;              % SXRフレーム数

% SXR 空間積分範囲
rmin = 70/1000; rmax = 375/1000;
r_space_SXR = linspace(rmin, rmax, 50);
z_space_SXR = linspace(-0.2, 0.2, 50);
mask_r_SXR = abs(r_space_SXR - 0.16) <= 0.02;
mask_z_SXR = abs(z_space_SXR) <= 0.01;

% --- Te (Triple Probe) 設定 ---
target_date = 251218;
% r_range_triple = [0.10, 0.15]; % Teプロット対象のR範囲 [m]
r_range_triple = [0.15, 0.18]; % Teプロット対象のR範囲 [m]
% r_range_triple = [0.13, 0.17]; % Teプロット対象のR範囲 [m]
filepath_triple = fullfile(getenv('PROBE_DATA_DIR'), 'tripleProbe', [num2str(target_date), '.mat']);


% =========================================================================
%  Part 1: SXRデータの読み込みと集計 (Left Axis用)
% =========================================================================
fprintf('--- Processing SXR Data ---\n');

% SXR基本データのロード
if exist(SXR_mat_path, 'file')
    load(SXR_mat_path, 'xpointList');
else
    error('SXR data file not found: %s', SXR_mat_path);
end

% データを収集
all_times = [];
all_intensities = [];

for shot = idxList
    t_vec = xpointList(shot).t;
    for j = 1:num_t
        if j <= length(t_vec)
            this_time = t_vec(j);
        else
            continue;
        end
        
        filePath = fullfile(SXR_baseDir, ['shot', num2str(shot)], [num2str(j), '.mat']);
        if exist(filePath, 'file')
            data = load(filePath, 'EE1');
            val = mean(data.EE1(mask_r_SXR, mask_z_SXR), 'all', 'omitnan');
            all_times = [all_times; this_time];
            all_intensities = [all_intensities; val];
        end
    end
end

% 時刻ごとにグループ化して平均と標準偏差を計算
group_keys = round(all_times); % 近似時刻でグループ化
unique_times = unique(group_keys);

sxr_plot_time = zeros(size(unique_times));
sxr_plot_mean = zeros(size(unique_times));
sxr_plot_std  = zeros(size(unique_times));

for i = 1:length(unique_times)
    idx = (group_keys == unique_times(i));
    vals = all_intensities(idx);
    
    sxr_plot_time(i) = mean(all_times(idx));
    sxr_plot_mean(i) = mean(vals);
    if length(vals) > 1
        sxr_plot_std(i) = std(vals);
    else
        sxr_plot_std(i) = 0;
    end
end


% =========================================================================
%  Part 2: トリプルプローブデータの読み込みと計算 (Right Axis用)
% =========================================================================
fprintf('--- Processing Te Data ---\n');

% ワークスペースになければロード
if ~exist('triple_data2D', 'var') || ~exist('R_values', 'var') || ~exist('time_values', 'var')
    if exist(filepath_triple, 'file')
        load(filepath_triple);
        fprintf('Loaded triple probe data: %s\n', filepath_triple);
    else
        warning('Triple probe data file not found. Skipping Te processing.');
        % ダミーデータを入れてエラーを防ぐ（必要に応じて削除してください）
        time_values = 450:600; 
        triple_data2D.Te = rand(50, 1, 151)*10; 
        triple_data2D.ne = rand(50, 1, 151)*1e20; 
        R_values = linspace(0.05, 0.4, 50);
    end
end

% time_values = time_values-1;

% データ抽出
Te_data_all = squeeze(triple_data2D.Te(:, 1, :)); % [eV]
ne_data_all = squeeze(triple_data2D.ne(:, 1, :)); % [m^-3]
idx_target_r = find(R_values >= r_range_triple(1) & R_values <= r_range_triple(2));

if isempty(idx_target_r)
    error('Te: 指定された範囲 (R=%.2f-%.2f m) にデータが存在しません。', r_range_triple(1), r_range_triple(2));
end

Te_subset = Te_data_all(idx_target_r, :);
Te_spatial_mean = mean(Te_subset, 1, 'omitnan');
Te_spatial_std  = std(Te_subset, 0, 1, 'omitnan');
ne_subset = ne_data_all(idx_target_r, :);
ne_spatial_mean = mean(ne_subset, 1, 'omitnan');
ne_spatial_std  = std(ne_subset, 0, 1, 'omitnan');

% シェーディング用データの作成
curve1 = Te_spatial_mean + Te_spatial_std;
curve2 = Te_spatial_mean - Te_spatial_std;
curve3 = ne_spatial_mean + ne_spatial_std;
curve4 = ne_spatial_mean - ne_spatial_std;
x2 = [time_values, fliplr(time_values)];
inBetween_Te = [curve1, fliplr(curve2)];
inBetween_ne = [curve3, fliplr(curve4)];


% =========================================================================
%  Part 3: 統合プロット (Double Y-Axis)
% =========================================================================
fig1 = figure('Name', 'SXR and Te Evolution', 'Color', 'w', 'Position', [100, 100, 800, 500]);

% --- 左軸: SXR (Blue) ---
yyaxis left
ax_left = gca;
ax_left.YColor = '#0072BD'; % 青色

% SXR エラーバープロット
errorbar(sxr_plot_time, sxr_plot_mean, sxr_plot_std, 'o-', ...
    'LineWidth', 2, 'CapSize', 8, 'MarkerSize', 6, ...
    'Color', '#0072BD', 'MarkerFaceColor', '#0072BD', ...
    'DisplayName', 'SXR Intensity');

ylabel('SXR Intensity [a.u.]', 'FontSize', 12);
% SXRのY軸範囲調整（必要に応じて）
% ylim([0, max(sxr_plot_mean + sxr_plot_std) * 1.2]);
ylim([0, 0.9]);


% --- 右軸: Te (Red) ---
yyaxis right
ax_right = gca;
ax_right.YColor = '#D95319'; % 赤色

hold on;
% Te シェーディング (ばらつき)
fill(x2, inBetween_Te, [0.8500, 0.3250, 0.0980], 'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
    'DisplayName', 'T_e Spatial Std');

% Te 平均値プロット
plot(time_values, Te_spatial_mean, '-', 'LineWidth', 2, ...
    'Color', '#D95319', ...
    'DisplayName', 'T_e Spatial Mean');
hold off;

ylabel('Electron Temperature [eV]', 'FontSize', 12);
ylim([0, 30]); % Teの上限調整


% --- 共通設定 ---
grid on;
xlabel('Time [\mus]', 'FontSize', 14);
xlim([460, 480]); % 指定された時間範囲

% % タイトル
% title_str = sprintf('Comparison: SXR vs T_e (R_{Te}=%.2f-%.2fm)', r_range_triple(1), r_range_triple(2));
% title(title_str, 'FontSize', 14);

% % 凡例 (左右の軸の要素をまとめて表示するのは少し工夫が必要ですが、標準的なlegendで出る場合が多いです)
% % 出ない場合は、特定のものだけハンドルを指定して表示します
% legend([ax_left.Children(1), ax_right.Children(1), ax_right.Children(2)], ...
%        {'SXR Intensity', 'T_e Spatial Mean', 'T_e Spatial Std'}, ...
%        'Location', 'best');

ax = gca;
ax.FontSize = 18;

% =========================================================================
%  Part 4: 統合プロット2 (Double Y-Axis)
% =========================================================================
fig2 = figure('Name', 'SXR and ne Evolution', 'Color', 'w', 'Position', [100, 100, 800, 500]);

% --- 左軸: SXR (Blue) ---
yyaxis left
ax_left = gca;
ax_left.YColor = '#0072BD'; % 青色

% SXR エラーバープロット
errorbar(sxr_plot_time, sxr_plot_mean, sxr_plot_std, 'o-', ...
    'LineWidth', 2, 'CapSize', 8, 'MarkerSize', 6, ...
    'Color', '#0072BD', 'MarkerFaceColor', '#0072BD', ...
    'DisplayName', 'SXR Intensity');

ylabel('SXR Intensity [a.u.]', 'FontSize', 12);
% SXRのY軸範囲調整（必要に応じて）
% ylim([0, max(sxr_plot_mean + sxr_plot_std) * 1.2]);
ylim([0, 0.9]);


% --- 右軸: ne (Red) ---
yyaxis right
ax_right = gca;
ax_right.YColor = '#D95319'; % 赤色

hold on;
% ne シェーディング (ばらつき)
fill(x2, inBetween_ne, [0.8500, 0.3250, 0.0980], 'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
    'DisplayName', 'n_e Spatial Std');

% ne 平均値プロット
plot(time_values, ne_spatial_mean, '-', 'LineWidth', 2, ...
    'Color', '#D95319', ...
    'DisplayName', 'n_e Spatial Mean');
hold off;

ylabel('Electron Density [m^{-3}]', 'FontSize', 12);
ylim([0, 5e20]); % neの上限調整


% --- 共通設定 ---
grid on;
xlabel('Time [\mus]', 'FontSize', 14);
xlim([460, 480]); % 指定された時間範囲

% % タイトル
% title_str = sprintf('Comparison: SXR vs T_e (R_{Te}=%.2f-%.2fm)', r_range_triple(1), r_range_triple(2));
% title(title_str, 'FontSize', 14);

% % 凡例 (左右の軸の要素をまとめて表示するのは少し工夫が必要ですが、標準的なlegendで出る場合が多いです)
% % 出ない場合は、特定のものだけハンドルを指定して表示します
% legend([ax_left.Children(1), ax_right.Children(1), ax_right.Children(2)], ...
%        {'SXR Intensity', 'T_e Spatial Mean', 'T_e Spatial Std'}, ...
%        'Location', 'best');

ax = gca;
ax.FontSize = 18;

% =========================================================================
%  Part 5: 統合プロット3 (Double Y-Axis)
% =========================================================================
fig3 = figure('Name', 'SXR and ne Evolution', 'Color', 'w', 'Position', [100, 100, 800, 500]);

% --- 右軸: Te (Red) ---
yyaxis left
ax_right = gca;
ax_right.YColor = '#0072BD'; % 青色

hold on;
% ne シェーディング (ばらつき)
fill(x2, inBetween_ne, [0, 0.4470, 0.7410], 'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
    'DisplayName', 'n_e Spatial Std');

% ne 平均値プロット
plot(time_values, ne_spatial_mean, '-', 'LineWidth', 2, ...
    'Color', '#0072BD', ...
    'DisplayName', 'n_e Spatial Mean');
hold off;

ylabel('Electron Density [m^{-3}]', 'FontSize', 12);
ylim([0, 5e20]); % neの上限調整


% --- 右軸: ne (Red) ---
yyaxis right
ax_right = gca;
ax_right.YColor = '#D95319'; % 赤色

hold on;
% Te シェーディング (ばらつき)
fill(x2, inBetween_Te, [0.8500, 0.3250, 0.0980], 'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
    'DisplayName', 'T_e Spatial Std');

% Te 平均値プロット
plot(time_values, Te_spatial_mean, '-', 'LineWidth', 2, ...
    'Color', '#D95319', ...
    'DisplayName', 'T_e Spatial Mean');
hold off;

% % Te シェーディング (ばらつき)
% fill(x2, inBetween_Te-4, [0.8500, 0.3250, 0.0980], 'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
%     'DisplayName', 'T_e Spatial Std');

% % Te 平均値プロット
% plot(time_values, Te_spatial_mean-4, '-', 'LineWidth', 2, ...
%     'Color', '#D95319', ...
%     'DisplayName', 'T_e Spatial Mean');
% hold off;


ylabel('Electron Temperature [eV]', 'FontSize', 12);
ylim([0, 30]); % Teの上限調整


% --- 共通設定 ---
grid on;
xlabel('Time [\mus]', 'FontSize', 14);
xlim([460, 480]); % 指定された時間範囲

% % タイトル
% title_str = sprintf('Comparison: SXR vs T_e (R_{Te}=%.2f-%.2fm)', r_range_triple(1), r_range_triple(2));
% title(title_str, 'FontSize', 14);

% % 凡例 (左右の軸の要素をまとめて表示するのは少し工夫が必要ですが、標準的なlegendで出る場合が多いです)
% % 出ない場合は、特定のものだけハンドルを指定して表示します
% legend([ax_left.Children(1), ax_right.Children(1), ax_right.Children(2)], ...
%        {'SXR Intensity', 'T_e Spatial Mean', 'T_e Spatial Std'}, ...
%        'Location', 'best');

ax = gca;
ax.FontSize = 18;

% =========================================================================
%  Part 6: 電子熱圧力 (Pe) の計算と統合プロット (Double Y-Axis)
% =========================================================================

% --- 1. 圧力の計算 (空間平均の前に、各点で圧力を計算します) ---
e_charge = 1.60217663e-19; % 素電荷 [C] or [J/eV]

% 各点での圧力 [Pa] = ne * Te * e
Pe_subset_all = (ne_subset .* Te_subset) .* e_charge;

% 空間平均と標準偏差を計算
Pe_spatial_mean = mean(Pe_subset_all, 1, 'omitnan');
Pe_spatial_std  = std(Pe_subset_all, 0, 1, 'omitnan');

% シェーディング用データ作成
curve_Pe_upper = Pe_spatial_mean + Pe_spatial_std;
curve_Pe_lower = Pe_spatial_mean - Pe_spatial_std;
inBetween_Pe   = [curve_Pe_upper, fliplr(curve_Pe_lower)];

% --- 2. プロット作成 ---
fig4 = figure('Name', 'SXR and Electron Pressure Evolution', 'Color', 'w', 'Position', [100, 100, 800, 500]);

% --- 左軸: SXR (Blue) ---
yyaxis left
ax_left = gca;
ax_left.YColor = '#0072BD'; % 青色

% SXR エラーバープロット (既存データを使用)
errorbar(sxr_plot_time, sxr_plot_mean, sxr_plot_std, 'o-', ...
    'LineWidth', 2, 'CapSize', 8, 'MarkerSize', 6, ...
    'Color', '#0072BD', 'MarkerFaceColor', '#0072BD', ...
    'DisplayName', 'SXR Intensity');

ylabel('SXR Intensity [a.u.]', 'FontSize', 12);
ylim([0, 0.9]); % SXRの範囲


% --- 右軸: 熱圧力 Pe (Red) ---
yyaxis right
ax_right = gca;
ax_right.YColor = '#D95319'; % 赤色

hold on;
% Pe シェーディング (ばらつき)
fill(x2, inBetween_Pe, [0.8500, 0.3250, 0.0980], 'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
    'DisplayName', 'P_e Spatial Std');

% Pe 平均値プロット
plot(time_values, Pe_spatial_mean, '-', 'LineWidth', 2, ...
    'Color', '#D95319', ...
    'DisplayName', 'P_e Spatial Mean');
hold off;

ylabel('Electron Thermal Pressure [Pa]', 'FontSize', 12);
% 圧力の範囲調整 (自動または手動)
% 目安: ne=1e20, Te=10eV -> P ~= 160 Pa
% ylim([0, max(curve_Pe_upper) * 1.2]); 
ylim([0, 2500]); 


% --- 共通設定 ---
grid on;
xlabel('Time [\mus]', 'FontSize', 14);
xlim([460, 480]); % 指定された時間範囲

% タイトル (任意)
% title('Comparison: SXR vs Electron Pressure', 'FontSize', 14);

ax = gca;
ax.FontSize = 18;

% =========================================================================
%  Part 7: 電子内部エネルギー密度 (Energy Density) の計算とプロット
% =========================================================================
% 物理背景: 単原子理想気体の場合、内部エネルギー密度 W = (3/2) * P

% --- 1. エネルギー密度の計算 ---
% Part 6で計算した圧力データ (Pe_subset_all) を使用します
We_subset_all = 1.5 * Pe_subset_all; % [J/m^3]

% 空間平均と標準偏差を計算
We_spatial_mean = mean(We_subset_all, 1, 'omitnan');
We_spatial_std  = std(We_subset_all, 0, 1, 'omitnan');

% シェーディング用データ作成
curve_We_upper = We_spatial_mean + We_spatial_std;
curve_We_lower = We_spatial_mean - We_spatial_std;
inBetween_We   = [curve_We_upper, fliplr(curve_We_lower)];

% --- 2. プロット作成 ---
fig5 = figure('Name', 'SXR and Electron Energy Density', 'Color', 'w', 'Position', [100, 100, 800, 500]);

% --- 左軸: SXR (Blue) ---
yyaxis left
ax_left = gca;
ax_left.YColor = '#0072BD'; % 青色

% SXR エラーバープロット (既存データを使用)
errorbar(sxr_plot_time, sxr_plot_mean, sxr_plot_std, 'o-', ...
    'LineWidth', 2, 'CapSize', 8, 'MarkerSize', 6, ...
    'Color', '#0072BD', 'MarkerFaceColor', '#0072BD', ...
    'DisplayName', 'SXR Intensity');

ylabel('SXR Intensity [a.u.]', 'FontSize', 12);
ylim([0, 0.9]); % SXRの範囲


% --- 右軸: エネルギー密度 We (Red) ---
yyaxis right
ax_right = gca;
ax_right.YColor = '#D95319'; % 赤色

hold on;
% We シェーディング (ばらつき)
fill(x2, inBetween_We, [0.8500, 0.3250, 0.0980], 'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
    'DisplayName', 'Energy Density Std');

% We 平均値プロット
plot(time_values, We_spatial_mean, '-', 'LineWidth', 2, ...
    'Color', '#D95319', ...
    'DisplayName', 'Energy Density Mean');
hold off;

ylabel('Electron Energy Density [J/m^3]', 'FontSize', 12);
% 範囲調整 (圧力の1.5倍程度)
ylim([0, 3000]); 


% --- 共通設定 ---
grid on;
xlabel('Time [\mus]', 'FontSize', 14);
xlim([460, 480]); 

% タイトル
% title('SXR vs Electron Energy Density', 'FontSize', 14);

ax = gca;
ax.FontSize = 18;

% % (オプション) 加熱率 (Power Density) の概算
% % dW/dt を計算 [J/m^3/s = W/m^3]

% % 時間差分 (seconds)
% dt_seconds = mean(diff(time_values)) * 1e-6; 

% % 勾配計算 (gradient関数を使用)
% Power_density = gradient(We_spatial_mean, dt_seconds); % [W/m^3]

% figure('Name', 'Heating Power Density');hold on;
% plot(time_values, Power_density, 'LineWidth', 2, 'Color', '#D95319');
% % 1.3452e+07 3.5385e+07 1.6986e+08
% plot([465 468 470],[1.3452e+07 3.5385e+07 1.6986e+08],'*');
% grid on;
% xlabel('Time [\mus]');
% ylabel('Power Density dW_e/dt [W/m^3]');
% title('Rate of Energy Gain');
% xlim([460, 480]);

% =========================================================================
%  Part 8: 電子加熱パワー密度 (Heating Power Density) の計算とプロット
% =========================================================================
% 目的: エネルギー密度 We の時間変化率 (dWe/dt) を計算し、
%       電子が単位時間・単位体積あたりに得ているエネルギーを表示する。

fprintf('--- Processing Heating Power Data ---\n');

% --- 1. 時間微分の計算 ---
% 時間刻み [s]
dt_seconds = mean(diff(time_values)) * 1e-6; 

% 結果格納用の配列 (サイズは We_subset_all と同じ: 空間点数 x 時間点数)
Power_subset_all = zeros(size(We_subset_all));

% 各空間点(行)ごとに時間微分を計算
for k = 1:size(We_subset_all, 1)
    % raw_trace: あるR位置におけるエネルギー密度の時間発展
    raw_trace = We_subset_all(k, :);
    
    % ノイズ低減のため、微分前に少しだけ平滑化（必要に応じてスパンを調整）
    % ここでは5点の移動平均をかけています
    smooth_trace = smoothdata(raw_trace, 'movmean', 5);
    
    % 勾配計算 (単位: J/m^3 / s = W/m^3)
    Power_subset_all(k, :) = gradient(smooth_trace, dt_seconds);
end

% --- 2. 統計処理 (空間平均とばらつき) ---
Power_spatial_mean = mean(Power_subset_all, 1, 'omitnan');
Power_spatial_std  = std(Power_subset_all, 0, 1, 'omitnan');

% シェーディング用データ作成
curve_Power_upper = Power_spatial_mean + Power_spatial_std;
curve_Power_lower = Power_spatial_mean - Power_spatial_std;
inBetween_Power   = [curve_Power_upper, fliplr(curve_Power_lower)];


% --- 3. プロット作成 ---
fig6 = figure('Name', 'SXR and Heating Power Density', 'Color', 'w', 'Position', [100, 100, 800, 500]);

% % --- 左軸: SXR (Blue) ---
% yyaxis left
% ax_left = gca;
% ax_left.YColor = '#0072BD'; % 青色

% errorbar(sxr_plot_time, sxr_plot_mean, sxr_plot_std, 'o-', ...
%     'LineWidth', 2, 'CapSize', 8, 'MarkerSize', 6, ...
%     'Color', '#0072BD', 'MarkerFaceColor', '#0072BD', ...
%     'DisplayName', 'SXR Intensity');

% ylabel('SXR Intensity [a.u.]', 'FontSize', 12);
% ylim([0, 0.9]); 


% % --- 右軸: 加熱パワー密度 dWe/dt (Red) ---
% yyaxis right
% ax_right = gca;
% ax_right.YColor = '#D95319'; % 赤色

hold on;
% Power シェーディング (ばらつき)
fill(x2, inBetween_Power, [0.8500, 0.3250, 0.0980], 'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
    'DisplayName', 'Heating Power Std');

% Power 平均値プロット ---【修正点1: ハンドル h1 を取得】---
h1 = plot(time_values, Power_spatial_mean, '-', 'LineWidth', 2, ...
    'Color', '#D95319', ...
    'DisplayName', 'Heating Power Mean');

% ゼロライン
yline(0, '--', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');

% 追加プロット ---【修正点2: ハンドル h2 を取得】---
% 色は見やすいように黒('k')や青などにし、サイズを少し大きくしました
h2 = plot([468 470 472], [5e+07 1.5e+08 3e8], '*', ...
    'MarkerSize', 10, 'LineWidth', 1.5, 'Color', 'k');

hold off;

ylabel('Heating Power Density [W/m^3]', 'FontSize', 12);

% % Y軸範囲の自動調整（外れ値対策で少し制限するか、オートにする）
% % 値が大きく変動する場合があるため、meanの最大値などを基準に設定
% max_val = max(abs(curve_Power_upper));
% ylim([-max_val*1.2, max_val*1.2]); % プラスマイナスを表示


% --- 共通設定 ---
grid on;
xlabel('Time [\mus]', 'FontSize', 14);
xlim([460, 480]); 

% title('Rate of Energy Gain (dW_e/dt)', 'FontSize', 14);

ax = gca;
ax.FontSize = 18;

% ---【修正点3: 凡例を h1 と h2 だけで作成】---
% 'New Points' の部分は表示したい名前に書き換えてください
legend([h1, h2], {'Heating Power (Exp.)', 'Particle Accel. (Calc.)'}, 'Location', 'best');
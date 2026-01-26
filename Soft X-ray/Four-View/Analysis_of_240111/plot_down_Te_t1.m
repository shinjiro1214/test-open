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
filepath_Te = fullfile(getenv('PROBE_DATA_DIR'), 'tripleProbe', [num2str(target_date), '.mat']);


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
%  Part 2: Teデータの読み込みと計算 (Right Axis用)
% =========================================================================
fprintf('--- Processing Te Data ---\n');

% ワークスペースになければロード
if ~exist('triple_data2D', 'var') || ~exist('R_values', 'var') || ~exist('time_values', 'var')
    if exist(filepath_Te, 'file')
        load(filepath_Te);
        fprintf('Loaded Te data: %s\n', filepath_Te);
    else
        warning('Te data file not found. Skipping Te processing.');
        % ダミーデータを入れてエラーを防ぐ（必要に応じて削除してください）
        time_values = 450:600; 
        triple_data2D.Te = rand(50, 1, 151)*10; 
        R_values = linspace(0.05, 0.4, 50);
    end
end

% データ抽出
Te_data_all = squeeze(triple_data2D.Te(:, 1, :)); % [eV]
idx_target_r = find(R_values >= r_range_triple(1) & R_values <= r_range_triple(2));

if isempty(idx_target_r)
    error('Te: 指定された範囲 (R=%.2f-%.2f m) にデータが存在しません。', r_range_triple(1), r_range_triple(2));
end

Te_subset = Te_data_all(idx_target_r, :);
Te_spatial_mean = mean(Te_subset, 1, 'omitnan');
Te_spatial_std  = std(Te_subset, 0, 1, 'omitnan');

% シェーディング用データの作成
curve1 = Te_spatial_mean + Te_spatial_std;
curve2 = Te_spatial_mean - Te_spatial_std;
x2 = [time_values, fliplr(time_values)];
inBetween = [curve1, fliplr(curve2)];


% =========================================================================
%  Part 3: 統合プロット (Double Y-Axis)
% =========================================================================
fig = figure('Name', 'SXR and Te Evolution', 'Color', 'w', 'Position', [100, 100, 800, 500]);

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
fill(x2, inBetween, [0.8500, 0.3250, 0.0980], 'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
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
clear;
% 必要なデータのみ読み込む
load('/Users/shinjirotakeda/Library/CloudStorage/OneDrive-TheUniversityofTokyo/Documents/data/SXRdata/240111_LF_NLR.mat', 'xpointList');

% パスのベース部分
baseDir = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_NLR/240111';

% --- 設定 ---
rmin = 70/1000; rmax = 375/1000;
r_space_SXR = linspace(rmin, rmax, 50);
z_space_SXR = linspace(-0.2, 0.2, 50);

% 論理インデックスをループ外で計算
mask_r = abs(r_space_SXR - 0.16) <= 0.02;
mask_z = abs(z_space_SXR) <= 0.01;

idxList = [7:9, 28:30];
num_t = 5;
num_shots = length(idxList);

% 結果格納用配列の事前割り当て (平均値と標準偏差)
SXR_means = zeros(num_shots, num_t);
SXR_stds  = zeros(num_shots, num_t);
time_results = zeros(num_shots, num_t);

% --- 計算ループ ---
for k = 1:num_shots
    shot = idxList(k);
    
    % 時間軸の取得
    t_vec = xpointList(shot).t;
    time_results(k, :) = t_vec(1:num_t);
    
    for j = 1:num_t
        % パス作成
        filePath = fullfile(baseDir, ['shot', num2str(shot)], [num2str(j), '.mat']);
        
        if exist(filePath, 'file')
            % 構造体として読み込み
            data = load(filePath, 'EE1');
            
            % 対象領域のデータを抽出
            roi_data = data.EE1(mask_r, mask_z);
            
            % 平均と標準偏差を計算 ('all' オプションを使用)
            SXR_means(k, j) = mean(roi_data, 'all');
            SXR_stds(k, j)  = std(roi_data, 0, 'all');
        else
            warning('Shot %d, Time %d: File not found.', shot, j);
            SXR_means(k, j) = NaN;
            SXR_stds(k, j)  = NaN;
        end
    end
end

% --- プロット (エラーバー付き) ---
figure; hold on;
colors = lines(num_shots); % ショットごとに異なる色を生成

for k = 1:num_shots
    % errorbar(x, y, y_error)
    errorbar(time_results(k, :), SXR_means(k, :), SXR_stds(k, :), ...
        '-o', 'LineWidth', 1.5, 'CapSize', 8, ...
        'Color', colors(k, :), ...
        'DisplayName', ['Shot ', num2str(idxList(k))]);
end

hold off;
grid on;
xlabel('Time [\mus]');
ylabel('SXR intensity [a.u.]');
title('SXR Intensity Evolution (Mean \pm Std Dev)');
legend('Location', 'best');
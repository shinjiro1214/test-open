clear;
% データ読み込み
load('/Users/shinjirotakeda/Library/CloudStorage/OneDrive-TheUniversityofTokyo/Documents/data/SXRdata/240111_LF_NLR.mat', 'xpointList');
baseDir = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_NLR/240111';

% --- 設定 ---
rmin = 70/1000; rmax = 375/1000;
r_space_SXR = linspace(rmin, rmax, 50);
z_space_SXR = linspace(-0.2, 0.2, 50);

% 論理インデックス
mask_r = abs(r_space_SXR - 0.16) <= 0.02;
mask_z = abs(z_space_SXR) <= 0.01;

idxList = [7:9, 28:30]; % 対象ショット
num_t = 5;              % 各ショットの読み込むフレーム数

% --- データの収集パート ---
% 全てのデータを「時刻」と「強度」のペアとしてリストに追加していきます
all_times = [];
all_intensities = [];

for shot = idxList
    % 各ショットの時間軸を取得
    t_vec = xpointList(shot).t;
    
    % 指定フレーム数だけループ
    for j = 1:num_t
        % 対応する時刻を取得
        if j <= length(t_vec)
            this_time = t_vec(j);
        else
            continue;
        end
        
        filePath = fullfile(baseDir, ['shot', num2str(shot)], [num2str(j), '.mat']);
        
        if exist(filePath, 'file')
            data = load(filePath, 'EE1');
            val = mean(data.EE1(mask_r, mask_z), 'all', 'omitnan');
            
            % リストに追加 (縦ベクトルとして積み上げ)
            all_times = [all_times; this_time];
            all_intensities = [all_intensities; val];
        end
    end
end

% --- 集計パート (時刻ごとの平均と標準偏差) ---

% 微小な時間のズレ（浮動小数点誤差）を無視するため、四捨五入してグループ化します
% 必要であれば round(all_times, 1) などで桁数を調整してください
group_keys = round(all_times); 

unique_times = unique(group_keys);
plot_time = zeros(size(unique_times));
plot_mean = zeros(size(unique_times));
plot_std  = zeros(size(unique_times));

for i = 1:length(unique_times)
    % この時刻グループに属するインデックスを探す
    idx = (group_keys == unique_times(i));
    
    % 同じ時刻の強度データを取得
    vals = all_intensities(idx);
    
    % プロット用データの計算
    plot_time(i) = mean(all_times(idx)); % 時刻も平均をとって精度を維持
    plot_mean(i) = mean(vals);
    
    if length(vals) > 1
        plot_std(i) = std(vals); % データが複数あれば標準偏差を計算
    else
        plot_std(i) = 0;         % データが1つならエラーバーなし
    end
end

% --- プロット ---
figure;
errorbar(plot_time, plot_mean, plot_std, 'o-', ...
    'LineWidth', 1.5, 'CapSize', 8, 'MarkerSize', 6, ...
    'Color', '#D95319', 'MarkerFaceColor', '#D95319');

grid on;
xlabel('Time [us]');
ylabel('SXR intensity [a.u.]');
title('SXR Intensity Evolution');
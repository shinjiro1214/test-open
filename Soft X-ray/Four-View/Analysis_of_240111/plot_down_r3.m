% clear; % 変数干渉を防ぐためクリア推奨
addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View'

% --- 設定 ---
basePathFirst = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_NLR/240111/shot';
basePathLast  = '/3.mat';

target_shots = [7, 8, 9]; % 平均化したいショット番号

% 座標設定
rmin = 70/1000; rmax = 375/1000;
r_space_SXR = linspace(rmin, rmax, 50);

% Z座標の定義 (EE1/EE2用とEE4用で異なる場合があるため元のコードに従う)
z_space_SXR2 = linspace(-0.2, 0.2, 50); 
z_space_SXR1 = linspace(-0.2, 0.2, 50);

% Z方向のフィルタ条件
z_indices_SXR2 = abs(z_space_SXR2) <= 0.01;
z_indices_SXR1 = abs(z_space_SXR1) <= 0.01;


%% --- データの読み込みと平均化関数 ---
% 共通処理が多いので、内部的にループで処理します

% 1. EE1 (Low) の読み込み
SXR_accum_1 = []; % データ蓄積用
for s = target_shots
    path_file = strcat(basePathFirst, num2str(s), basePathLast);
    if exist(path_file, 'file')
        data = load(path_file, 'EE1');
        if isfield(data, 'EE1')
            % 該当するZ範囲のデータを抽出して蓄積
            SXR_accum_1 = [SXR_accum_1, data.EE1(:, z_indices_SXR2)];
        end
    else
        warning('Shot %d: EE1 file not found.', s);
    end
end

if ~isempty(SXR_accum_1)
    SXR_mean_1 = mean(SXR_accum_1, 2);
    SXR_std_1  = std(SXR_accum_1, 0, 2);
else
    warning('EE1 data not found for any shots.');
    SXR_mean_1 = zeros(50,1); SXR_std_1 = zeros(50,1);
end


% 2. EE2 (Middle) の読み込み
SXR_accum_2 = [];
for s = target_shots
    path_file = strcat(basePathFirst, num2str(s), basePathLast);
    if exist(path_file, 'file')
        data = load(path_file, 'EE2');
        if isfield(data, 'EE2')
            SXR_accum_2 = [SXR_accum_2, data.EE2(:, z_indices_SXR2)];
        end
    else
        warning('Shot %d: EE2 file not found.', s);
    end
end

if ~isempty(SXR_accum_2)
    SXR_mean_2 = mean(SXR_accum_2, 2);
    SXR_std_2  = std(SXR_accum_2, 0, 2);
else
    warning('EE2 data not found for any shots.');
    SXR_mean_2 = zeros(50,1); SXR_std_2 = zeros(50,1);
end


% 3. EE4 (High) の読み込み
SXR_accum_4 = [];
for s = target_shots
    path_file = strcat(basePathFirst, num2str(s), basePathLast);
    if exist(path_file, 'file')
        data = load(path_file, 'EE4');
        if isfield(data, 'EE4')
            % スケール補正 (*2) を適用してから蓄積
            scaled_EE4 = data.EE4 .* 2;
            SXR_accum_4 = [SXR_accum_4, scaled_EE4(:, z_indices_SXR1)];
        end
    else
        warning('Shot %d: EE4 file not found.', s);
    end
end

if ~isempty(SXR_accum_4)
    SXR_mean_4 = mean(SXR_accum_4, 2);
    SXR_std_4  = std(SXR_accum_4, 0, 2);
else
    warning('EE4 data not found for any shots.');
    SXR_mean_4 = zeros(50,1); SXR_std_4 = zeros(50,1);
end


%% --- 絶対強度のプロット (確認用) ---
x_range = [0.1, 0.25];

figure('Name', 'Absolute Intensity (Avg 7-9)'); hold on;
errorbar(r_space_SXR, SXR_mean_1, SXR_std_1, 'o-', 'LineWidth', 2, 'CapSize', 8, 'MarkerSize', 5);
errorbar(r_space_SXR, SXR_mean_2, SXR_std_2, 'o-', 'LineWidth', 2, 'CapSize', 8, 'MarkerSize', 5);
errorbar(r_space_SXR, SXR_mean_4, SXR_std_4, 'o-', 'LineWidth', 2, 'CapSize', 8, 'MarkerSize', 5);

legend({'I_{20-80 eV}','I_{50-80 eV}','I_{100 eV <}'},'Location','best');
xlim(x_range);
ylim([0, Inf]);
ylabel('SXR intensity [a.u.]');
xlabel('r [m]');
title('Averaged Intensity (Shots 7-9)');
grid on; ax = gca; ax.FontSize = 18;


%% --- 指定した3点 (0.15, 0.175, 0.20) のみの規格化プロット ---

% 1. 比率の計算 (Ratio)
Ratio_1_2 = SXR_mean_1 ./ SXR_mean_2;
Ratio_4_2 = SXR_mean_4 ./ SXR_mean_2;

% 2. 誤差伝播 (Error Propagation)
rel_err_sq_1 = (SXR_std_1 ./ SXR_mean_1).^2 + (SXR_std_2 ./ SXR_mean_2).^2;
rel_err_sq_4 = (SXR_std_4 ./ SXR_mean_4).^2 + (SXR_std_2 ./ SXR_mean_2).^2;

Std_Ratio_1_2 = abs(Ratio_1_2) .* sqrt(rel_err_sq_1);
Std_Ratio_4_2 = abs(Ratio_4_2) .* sqrt(rel_err_sq_4);


% 3. 特定のr座標 (3点) の抽出
target_r_list = [0.15, 0.175, 0.20]; % プロットしたいrのリスト
extract_indices = zeros(size(target_r_list));

for i = 1:length(target_r_list)
    [~, idx] = min(abs(r_space_SXR - target_r_list(i)));
    extract_indices(i) = idx;
end

r_extracted     = r_space_SXR(extract_indices);
ratio_1_sub     = Ratio_1_2(extract_indices);
std_1_sub       = Std_Ratio_1_2(extract_indices);
ratio_4_sub     = Ratio_4_2(extract_indices);
std_4_sub       = Std_Ratio_4_2(extract_indices);

fprintf('抽出されたr座標: %.3f m, %.3f m, %.3f m\n', r_extracted);


% 4. 抽出データ内での規格化 (Max=1)
% 青ライン (Low/Mid) の規格化
max_val_1 = max(ratio_1_sub, [], 'omitnan');
if max_val_1 ~= 0
    ratio_1_norm = ratio_1_sub / max_val_1;
    std_1_norm   = std_1_sub / max_val_1;
else
    ratio_1_norm = ratio_1_sub; std_1_norm = std_1_sub;
end

% オレンジライン (High/Mid) の規格化
max_val_4 = max(ratio_4_sub, [], 'omitnan');
if max_val_4 ~= 0
    ratio_4_norm = ratio_4_sub / max_val_4;
    std_4_norm   = std_4_sub / max_val_4;
else
    ratio_4_norm = ratio_4_sub; std_4_norm = std_4_sub;
end


% 5. プロット
figure('Name', 'Normalized Ratio at 3 Points (Avg 7-9)'); hold on;

% I_20-80eV / I_50-80eV (Normalized)
errorbar(r_extracted, ratio_1_norm, std_1_norm, 'o-', 'LineWidth', 2, ...
        'CapSize', 10, 'MarkerSize', 8, 'MarkerFaceColor', '#0072BD', 'Color', '#0072BD');

% I_100eV< / I_50-80eV (Normalized)
errorbar(r_extracted, ratio_4_norm, std_4_norm, 's-', 'LineWidth', 2, ...
        'CapSize', 10, 'MarkerSize', 8, 'MarkerFaceColor', '#D95319', 'Color', '#D95319');

% % y=1 ガイドライン
% yline(1, '--k', 'HandleVisibility', 'off');

% 装飾
legend({'I_{20-80 eV} / I_{50-80 eV}', 'I_{100 eV <} / I_{50-80 eV}'}, 'Location', 'best');
xlim([0.13, 0.22]); 
ylim([0, 1.2]);
xticks(target_r_list);
ylabel('SXR intensity ratio [a.u.]');
xlabel('r [m]');
% title('Normalized Spectral Ratios (Shots 7-9 Avg)');
grid on; 
ax = gca; ax.FontSize = 18;


if exist('I_plot','var')
% 発光強度のプロット
figure;hold on;
    % I_plot = I_plot./I_plot(1,:);
    plot(x_data,I_plot(:,1)/max(I_plot(:,1)),'o-','LineWidth',2);
    plot(x_data,I_plot(:,2)/max(I_plot(:,2)),'o-','LineWidth',2);

    errorbar(r_extracted, ratio_1_norm, std_1_norm, 'o--', 'LineWidth', 2, ...
            'CapSize', 10, 'MarkerSize', 8, 'MarkerFaceColor', '#0072BD', 'Color', '#0072BD');

    % I_100eV< / I_50-80eV (Normalized)
    errorbar(r_extracted, ratio_4_norm, std_4_norm, 'o--', 'LineWidth', 2, ...
            'CapSize', 10, 'MarkerSize', 8, 'MarkerFaceColor', '#D95319', 'Color', '#D95319');

    % plot(I_plot,'o-','LineWidth',2);
    ylabel('SXR intensity ratio [a.u.]');%xlabel('Photon energy [eV]');
    % legend({'Low energy','High energy'},'Location','southeast')
    % yticks([]);xticks([]);
    % ylim([0 inf]);
    xlabel('r [m]');
    ax = gca;ax.FontSize = 18;
end
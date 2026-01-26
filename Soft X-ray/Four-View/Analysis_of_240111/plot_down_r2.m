addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View'

pathFirstHalf = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_NLR/240111/shot';
pathLastHalf = '/3.mat';

% --- SXR Low (EE1) ---
% nshot_1 = 17;
nshot_1 = 7;
path_1 = strcat(pathFirstHalf, num2str(nshot_1), pathLastHalf);

% 座標設定
rmin = 70/1000; rmax = 375/1000;
r_space_SXR = linspace(rmin, rmax, 50);
z_space_SXR2 = linspace(-0.2, 0.2, 50); % zmin2, zmax2
z_space_SXR1 = linspace(-0.2, 0.2, 50); % zmin1, zmax1

if exist(path_1, 'file')
    load(path_1, 'EE1');
    z_indices_SXR2 = abs(z_space_SXR2) <= 0.01;
    SXR_r_tmp1 = EE1(:, z_indices_SXR2);
    SXR_mean_1 = mean(SXR_r_tmp1, 2);
    SXR_std_1 = std(SXR_r_tmp1, 0, 2);
else
    warning('SXR EE1 not found.');
    SXR_mean_1 = zeros(50,1); SXR_std_1 = zeros(50,1);
end

% ここにshot7くらいのやつ引っ張ってきて中エネルギー隊のプロット
% ついでに総体発行強度も計算
% --- SXR Middle (EE2) ---
nshot_2 = 7;
path_2 = strcat(pathFirstHalf, num2str(nshot_2), pathLastHalf);

if exist(path_2, 'file')
    load(path_2, 'EE2');
    z_indices_SXR2 = abs(z_space_SXR2) <= 0.01;
    SXR_r_tmp2 = EE2(:, z_indices_SXR2);
    SXR_mean_2 = mean(SXR_r_tmp2, 2);
    SXR_std_2 = std(SXR_r_tmp2, 0, 2);
else
    warning('SXR EE2 not found.');
    SXR_mean_2 = zeros(50,1); SXR_std_2 = zeros(50,1);
end

% --- SXR High (EE4) ---
nshot_4 = 9;
path_4 = strcat(pathFirstHalf, num2str(nshot_4), pathLastHalf);

if exist(path_4, 'file')
    load(path_4, 'EE4');
    EE4 = EE4 .* 2; % ユーザーコードのスケール補正
    z_indices_SXR1 = abs(z_space_SXR1) <= 0.01;
    SXR_r_tmp4 = EE4(:, z_indices_SXR1);
    SXR_mean_4 = mean(SXR_r_tmp4, 2);
    SXR_std_4 = std(SXR_r_tmp4, 0, 2);
else
    warning('SXR EE4 not found.');
    SXR_mean_4 = zeros(50,1); SXR_std_4 = zeros(50,1);
end

x_range = [0.1, 0.25];

figure;hold on;
errorbar(r_space_SXR, SXR_mean_1, SXR_std_1, 'o-', 'LineWidth', 2, ...
        'CapSize', 8, 'MarkerSize', 5);
errorbar(r_space_SXR, SXR_mean_2, SXR_std_2, 'o-', 'LineWidth', 2, ...
        'CapSize', 8, 'MarkerSize', 5);
errorbar(r_space_SXR, SXR_mean_4, SXR_std_4, 'o-', 'LineWidth', 2, ...
        'CapSize', 8, 'MarkerSize', 5);

legend({'I_{20-80 eV}','I_{50-80 eV}','I_{100 eV <}'},'Location','best');
xlim(x_range);
ylim([0, Inf]);
ylabel('SXR intensity [a.u.]');
xlabel('r [m]');
grid on; ax = gca; ax.FontSize = 18;

%% --- 追加パート: 指定範囲で規格化した相対強度のプロット ---

% 1. 比率の計算 (Ratio)
% 分母が0に近い場合のInf/NaN対策として警告を一時抑制しても良いですが、
% MATLABのplotはInf/NaNを無視して描画してくれるため、そのまま計算します。
Ratio_1_2 = SXR_mean_1 ./ SXR_mean_2;
Ratio_4_2 = SXR_mean_4 ./ SXR_mean_2;

% 2. 誤差伝播 (Error Propagation)
% 相対誤差の二乗和: (sig_Z/Z)^2 = (sig_A/A)^2 + (sig_B/B)^2
rel_err_sq_1 = (SXR_std_1 ./ SXR_mean_1).^2 + (SXR_std_2 ./ SXR_mean_2).^2;
rel_err_sq_4 = (SXR_std_4 ./ SXR_mean_4).^2 + (SXR_std_2 ./ SXR_mean_2).^2;

% 絶対誤差に戻す
Std_Ratio_1_2 = abs(Ratio_1_2) .* sqrt(rel_err_sq_1);
Std_Ratio_4_2 = abs(Ratio_4_2) .* sqrt(rel_err_sq_4);


% --- 3. 規格化 (Normalization) ---

% プロット範囲 (x_range) 内のインデックスを取得
valid_indices = (r_space_SXR >= x_range(1)) & (r_space_SXR <= x_range(2));

% 範囲内にデータが存在するか確認
if any(valid_indices)
    % 範囲内での最大値を取得 ('omitnan'でNaNを除外)
    max_val_1 = max(Ratio_1_2(valid_indices), [], 'omitnan');
    max_val_4 = max(Ratio_4_2(valid_indices), [], 'omitnan');
    
    % 最大値でデータを規格化 (最大値が0の場合はそのままにする)
    if max_val_1 ~= 0
        Ratio_1_2_norm = Ratio_1_2 / max_val_1;
        Std_1_2_norm   = Std_Ratio_1_2 / max_val_1; % エラーバーもスケール変換
    else
        Ratio_1_2_norm = Ratio_1_2;
        Std_1_2_norm   = Std_Ratio_1_2;
    end
    
    if max_val_4 ~= 0
        Ratio_4_2_norm = Ratio_4_2 / max_val_4;
        Std_4_2_norm   = Std_Ratio_4_2 / max_val_4;
    else
        Ratio_4_2_norm = Ratio_4_2;
        Std_4_2_norm   = Std_Ratio_4_2;
    end
else
    warning('指定された範囲内に有効なデータがありません。規格化を行わずプロットします。');
    Ratio_1_2_norm = Ratio_1_2; Std_1_2_norm = Std_Ratio_1_2;
    Ratio_4_2_norm = Ratio_4_2; Std_4_2_norm = Std_Ratio_4_2;
end


% --- 4. プロット ---
figure('Name', 'Normalized Relative Intensity'); hold on;

% I_20-80eV / I_50-80eV (Normalized)
errorbar(r_space_SXR, Ratio_1_2_norm, Std_1_2_norm, 'o-', 'LineWidth', 2, ...
        'CapSize', 8, 'MarkerSize', 5, 'Color', '#0072BD'); % 青

% I_100eV< / I_50-80eV (Normalized)
errorbar(r_space_SXR, Ratio_4_2_norm, Std_4_2_norm, 'o-', 'LineWidth', 2, ...
        'CapSize', 8, 'MarkerSize', 5, 'Color', '#D95319'); % オレンジ

% % y=1 のガイドライン
% yline(1, '--k', 'LineWidth', 1.5, 'HandleVisibility', 'off');

legend({'I_{20-80 eV} / I_{50-80 eV}', 'I_{100 eV <} / I_{50-80 eV}'}, 'Location', 'best');
xlim(x_range);
ylim([0, 1.2]); % 規格化したので上限は1ちょっとあれば十分
ylabel('SXR intensity ratio [a.u.]');
xlabel('r [m]');
% title('Normalized Spectral Ratios');
grid on; 
ax = gca; ax.FontSize = 18;



% --- 3. 特定のr座標 (3点) の抽出 ---

target_r_list = [0.15, 0.175, 0.20]; % プロットしたいrのリスト
extract_indices = zeros(size(target_r_list));

% 各ターゲットに最も近いインデックスを探す
for i = 1:length(target_r_list)
    [~, idx] = min(abs(r_space_SXR - target_r_list(i)));
    extract_indices(i) = idx;
end

% データの抽出
r_extracted     = r_space_SXR(extract_indices);
ratio_1_sub     = Ratio_1_2(extract_indices);
std_1_sub       = Std_Ratio_1_2(extract_indices);
ratio_4_sub     = Ratio_4_2(extract_indices);
std_4_sub       = Std_Ratio_4_2(extract_indices);

fprintf('抽出されたr座標: %.3f m, %.3f m, %.3f m\n', r_extracted);


% --- 4. 抽出データ内での規格化 (Max=1) ---

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


% --- 5. プロット ---
figure('Name', 'Normalized Ratio at 3 Points'); hold on;

% I_20-80eV / I_50-80eV (Normalized)
errorbar(r_extracted, ratio_1_norm, std_1_norm, 'o-', 'LineWidth', 2, ...
        'CapSize', 10, 'MarkerSize', 8, 'MarkerFaceColor', '#0072BD', 'Color', '#0072BD');

% I_100eV< / I_50-80eV (Normalized)
errorbar(r_extracted, ratio_4_norm, std_4_norm, 's-', 'LineWidth', 2, ...
        'CapSize', 10, 'MarkerSize', 8, 'MarkerFaceColor', '#D95319', 'Color', '#D95319');

% y=1 ガイドライン
yline(1, '--k', 'HandleVisibility', 'off');

% 装飾
legend({'I_{20-80 eV} / I_{50-80 eV}', 'I_{100 eV <} / I_{50-80 eV}'}, 'Location', 'best');
xlim([0.13, 0.22]); % 3点が見やすいように範囲調整
ylim([0, 1.2]);
xticks(target_r_list); % 指定した座標のみ目盛りを表示
ylabel('Normalized Ratio (Max=1)');
xlabel('r [m]');
title('Normalized Spectral Ratios (Selected Points)');
grid on; 
ax = gca; ax.FontSize = 18;
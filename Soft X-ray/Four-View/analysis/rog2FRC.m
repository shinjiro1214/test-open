%% データの読み込み
% タイムラグデータの読み込み (fctf_timelag.csv)
opts1 = detectImportOptions('fctf_timelag.csv');
opts1.VariableTypes(1:2) = {'double', 'double'}; % Date, Shotを数値として確定
T_lag = readtable('fctf_timelag.csv', opts1);

% 分類サマリーデータの読み込み (FRC_Classification_Summary.csv)
opts2 = detectImportOptions('FRC_Classification_Summary.csv');
opts2.VariableTypes(1:2) = {'double', 'double'};
T_summary = readtable('FRC_Classification_Summary.csv', opts2);

%% データの結合 (Inner Join)
% DateとShotが一致する行を結合します
T_combined = innerjoin(T_lag, T_summary, 'Keys', {'Date', 'Shot'});

% FRCかどうかのフラグを作成 (1: FRC, 0: Spheromakなど)
T_combined.isFRC = strcmp(T_combined.Classification, 'FRC');

% カテゴリカルデータに変換（プロット用）
T_combined.Classification = categorical(T_combined.Classification);

%% 可視化 1: タイムラグと磁場比(Mean_Ratio)の散布図
figure('Color', 'w', 'Position', [100, 100, 900, 400]);

subplot(1, 2, 1);
gscatter(T_combined.TimeLag_us, T_combined.Mean_Ratio, T_combined.Classification, 'rbg', 'o+x');
grid on;
xlabel('Time Lag (\mus)');
ylabel('Mean Ratio (Bt/Bp)');
title('コイルのズレ vs 磁場比');
legend('Location', 'best');

%% 可視化 2: タイムラグの分布（バイオリン図/箱ひげ図風）
subplot(1, 2, 2);
boxplot(T_combined.TimeLag_us, T_combined.Classification);
grid on;
ylabel('Time Lag (\mus)');
title('生成結果ごとのタイムラグ分布');

%% 統計解析: ロジスティック回帰
% タイムラグがFRC生成確率に与える影響を計算
mdl = fitglm(T_combined, 'isFRC ~ TimeLag_us', 'Distribution', 'binomial');
disp('--- ロジスティック回帰分析結果 ---');
disp(mdl);

%% 提案：タイムラグの「許容範囲」を算出
avg_frc_lag = mean(T_combined.TimeLag_us(T_combined.isFRC == 1));
std_frc_lag = std(T_combined.TimeLag_us(T_combined.isFRC == 1));

fprintf('\nFRC生成時の平均タイムラグ: %.2f [us]\n', avg_frc_lag);
fprintf('FRC生成時の標準偏差: %.2f [us]\n', std_frc_lag);



%% データの準備（前のスクリプトの T_combined を使用）
% タイムラグを 2us ごとのビンに分ける
binSize = 2;
T_combined.LagBin = floor(T_combined.TimeLag_us / binSize) * binSize;

% ビンごとの統計を計算
bins = unique(T_combined.LagBin);
successRate = zeros(length(bins), 1);
totalShots = zeros(length(bins), 1);

for i = 1:length(bins)
    idx = T_combined.LagBin == bins(i);
    totalShots(i) = sum(idx);
    successRate(i) = sum(T_combined.isFRC(idx)) / totalShots(i) * 100; % 成功率(%)
end

%% 可視化：タイムラグごとの生成成功率
figure('Color', 'w');
yyaxis left
bar(bins + binSize/2, totalShots, 'FaceAlpha', 0.3, 'FaceColor', [0.5 0.5 0.5]);
ylabel('総ショット数');
hold on;

yyaxis right
plot(bins + binSize/2, successRate, '-o', 'LineWidth', 2, 'MarkerSize', 8);
ylabel('FRC 生成成功率 (%)');
ylim([0 100]);

grid on;
xlabel('Time Lag Bin (\mus)');
title('タイムラグの範囲ごとの FRC 生成成功率');
legend({'ショット密度', '成功率'}, 'Location', 'northeast');

%% 提案：別の物理量との「掛け合わせ」分析
% タイムラグが小さくても FRC にならない原因（他の変数）を探る
figure('Color', 'w');
scatter3(T_combined.TimeLag_us, T_combined.Mean_Bp_Max, T_combined.Mean_Ratio, ...
         30, T_combined.isFRC, 'filled');
cb = colorbar;
cb.TickLabels = {'Spheromak', 'FRC'};
xlabel('Time Lag (\mus)');
ylabel('Mean Bp Max (磁場強度)');
zlabel('Mean Ratio (Bt/Bp)');
title('3次元プロットによる要因分析');
view(35, 30);
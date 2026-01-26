%% 1. 設定
clear; clc;

% ショット番号のリスト (解析したい範囲を指定してください)
% shotList = 1:5; % 例: 1番から5番まで。必要に応じて [1, 3, 5:10] のように指定可
% shotList = [6:9,11,13,14,17:21,23:32,34:47,49:69];
% shotList = [8,9,18:21,23:32,34:47,49:56,58:65,67:69];
% shotList = [8,9,18:21,23:32,34:47,49:51,56,58:65,67:69];

shotList_4 = [8,9,18:21];
shotList_3 = [23:32,34:46];
shotList_2 = [47,49:51,56,58:65,67:69];

shotList = shotList_2;

% 解析したいチャンネル (例: ch1なら1, ch3なら3)
target_ch = 7; 

% 10,11,12,14,17,18,19,20,21死亡？

% ファイル名の固定部分
baseName = 'ES_250305'; 
% ファイルがあるフォルダパス (カレントディレクトリなら '' または './')
dirPath = '/Volumes/experiment/results/ElectroStaticProbe/250305'; 

%% 2. データの読み込み
% データを格納する変数を初期化
% 時間軸が全てのショットで共通と仮定して、最初のショットでサイズを決めるのが効率的ですが、
% ここでは安全のためループ内で連結します。

all_data = []; % (時間 x ショット数) の行列になります
legend_str = {};
valid_shots = []; % 読み込みに成功したショット番号

fprintf('読み込み開始: Target Ch = %d\n', target_ch);

for i = 1:length(shotList)
    shotNo = shotList(i);
    
    % ファイル名の生成 (例: ES_250305001.csv)
    fileName = sprintf('%s%03d.csv', baseName, shotNo);
    fullPath = fullfile(dirPath, fileName);
    
    if exist(fullPath, 'file')
        % CSV読み込み
        % 1行目はヘッダーなので NumHeaderLines=1 でスキップ
        raw_data = readmatrix(fullPath, 'NumHeaderLines', 1);
        
        % 時間ベクトル (1列目)
        t_vec = raw_data(:, 1);
        
        % 対象チャンネルのデータ (ch1は2列目, ch2は3列目... なので +1)
        ch_data = raw_data(:, target_ch + 1);
        
        % 行列に格納 (列ごとにショットを並べる)
        if i == 1
            all_data = ch_data;
            time_axis = t_vec; % 基準となる時間軸
        else
            % 時間軸の長さが違う場合の安全策（基本は同じはず）
            if length(ch_data) == length(all_data(:,1))
                all_data(:, end+1) = ch_data;
            else
                warning('Shot %d のデータ長が他と異なります。スキップします。', shotNo);
                continue;
            end
        end
        
        valid_shots(end+1) = shotNo;
        legend_str{end+1} = sprintf('Shot %03d', shotNo);
        fprintf('  Loaded: %s\n', fileName);
    else
        fprintf('  Missing: %s\n', fileName);
    end
end

if isempty(all_data)
    error('有効なデータが見つかりませんでした。');
end

%% 3. 可視化 A: 重ね書きプロット (ばらつきの確認)
figure('Name', 'Shot Evolution - Overlay', 'Color', 'w');

% カラーマップを使ってショット順に色を変える (青 -> 赤)
colors = parula(length(valid_shots)); 
hold on;
for k = 1:length(valid_shots)
    plot(time_axis, all_data(:, k), 'Color', colors(k, :), 'LineWidth', 1.5);
end
hold off;

grid on;
xlabel('Time [\mus]', 'FontSize', 12);
ylabel(sprintf('Ch %d Signal', target_ch), 'FontSize', 12);
title(sprintf('Time Evolution of Ch %d (Overlay)', target_ch), 'FontSize', 14);

% カラーバーでショット番号を表示
colormap(parula);
c = colorbar;
c.Label.String = 'Shot Index (Order)';
caxis([1 length(valid_shots)]);

%% 4. 可視化 B: カラーマップ (時間発展の変化を見る)
% 横軸：時間、縦軸：ショット番号、色：信号強度
figure('Name', 'Shot Evolution - Heatmap', 'Color', 'w');

% imagesc は行列を画像として表示します。
% X軸: 時間, Y軸: ショット番号
% all_data は (時間 x ショット) なので転置して (ショット x 時間) にします
imagesc(time_axis, valid_shots, all_data.'); 

axis xy; % Y軸の向きを通常のグラフと同じにする（下が小さい番号）
colormap('jet'); % 色の階調 (jet, parula, turbo などお好みで)
colorbar;
ylabel(colorbar, 'Signal Amplitude');

xlabel('Time [\mus]', 'FontSize', 12);
ylabel('Shot Number', 'FontSize', 12);
title(sprintf('Time Evolution of Ch %d (Heatmap)', target_ch), 'FontSize', 14);
xlim([0 1000])

% 読み込んだショット番号に合わせてY軸の目盛りを設定
yticks(valid_shots);
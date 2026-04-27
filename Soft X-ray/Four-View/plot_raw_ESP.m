% %% 実験データ一括確認スクリプト (OnoLab ES Data)
% clear; close all;

% % --- 設定項目 ---
% baseDir = '/Users/shohgookazaki/Library/CloudStorage/GoogleDrive-shohgo-okazaki@g.ecc.u-tokyo.ac.jp/My Drive/OnoLab/data/ElectroStatic/rawdata/260331';
% shotNums = [68, 72:80, 83:87, 89:90, 92:98]; % プロットしたいショット番号の範囲を指定 (例: [1, 5, 10] や 1:50)
% savePlots = false; % プロットを画像として保存する場合は true

% % チャンネル名のクリーニング用関数（MATLABが変数名を変換するため）
% cleanName = @(s) strrep(strrep(s, '_V_', '[V]'), '_us_', '[us]');

% for s = shotNums
%     % ファイル名の生成 (ES_260331XXX.csv)
%     fileName = sprintf('ES_260331%03d.csv', s);
%     fullPath = fullfile(baseDir, fileName);
    
%     if ~exist(fullPath, 'file')
%         fprintf('Skip: ファイルが見つかりません -> %s\n', fileName);
%         continue;
%     end
    
%     % データの読み込み
%     % 'VariableNamingRule','preserve' で [V] などの記号を維持
%     opts = detectImportOptions(fullPath);
%     opts.VariableNamingRule = 'preserve';
%     data = readtable(fullPath, opts);
    
%     % 時間軸とチャンネルデータの抽出
%     time = data{:, 'time[us]'};
%     % ch1[V]からch21[V]までを選択 (3列目以降)
%     chData = data(:, 3:end); 
    
%     % --- プロット ---
%     fig = figure('Name', sprintf('Shot %03d Inspection', s), 'Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.8]);
    
%     % 21チャンネルあるため、stackedplotが最も見やすいです
%     s_plot = stackedplot(data, chData.Properties.VariableNames, 'XVariable', 'time[us]');
%     s_plot.Title = sprintf('Shot Number: %03d', s);
%     s_plot.LineWidth = 1;
%     grid on;
    
%     fprintf('Displaying Shot: %03d (Enterキーで次へ、Ctrl+Cで終了)\n', s);
    
%     if savePlots
%         saveas(fig, sprintf('Shot_%03d_check.png', s) %#ok<UNRCH>);
%     end
    
%     % 1枚ずつ確認するために一時停止
%     pause; 
%     if s ~= shotNums(end), close(fig); end
% end


% %% 実験データ一括確認スクリプト (OnoLab ES Data 260325用)
% clear; close all;

% % --- 設定項目 ---
% % 3月25日のパスに変更
% baseDir = '/Users/shohgookazaki/Library/CloudStorage/GoogleDrive-shohgo-okazaki@g.ecc.u-tokyo.ac.jp/My Drive/OnoLab/data/ElectroStatic/rawdata/260325';
% shotNums = [14:32]; % とりあえず14番を指定。001からなら 1:20 など。

% for s = shotNums
%     % ファイル名の生成 (ES_260325XXX.csv)
%     fileName = sprintf('ES_260325%03d.csv', s);
%     fullPath = fullfile(baseDir, fileName);
    
%     if ~exist(fullPath, 'file')
%         fprintf('Skip: ファイルが見つかりません -> %s\n', fileName);
%         continue;
%     end
    
%     % データの読み込み
%     data = readtable(fullPath);
    
%     % NaN（空データ）が含まれる行を削除（この日のデータは後半が空のようです）
%     data = rmmissing(data); 
    
%     % 列名の取得（time(us), ch1, ch2...）
%     varNames = data.Properties.VariableNames;
%     timeVar = varNames{1}; % 1列目が時間
%     chVars = varNames(2:end); % 2列目以降がチャンネル
    
%     % --- プロット ---
%     fig = figure('Name', sprintf('Shot %03d Inspection', s), 'Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.8]);
    
%     % 全チャンネルを並べて表示
%     s_plot = stackedplot(data, chVars, 'XVariable', timeVar);
%     s_plot.Title = sprintf('Shot Number: %03d (Date: 260325)', s);
%     s_plot.LineWidth = 1;
%     grid on;
    
%     fprintf('Displaying Shot: %03d (Enterキーで次へ、Ctrl+Cで終了)\n', s);
%     pause; 
%     if s ~= shotNums(end), close(fig); end
% end



%% 実験データ一括確認スクリプト (OnoLab ES Data 260325用)
clear; close all;

% --- 設定項目 ---
% 3月25日のパスに変更
baseDir = '/Users/shohgookazaki/Library/CloudStorage/GoogleDrive-shohgo-okazaki@g.ecc.u-tokyo.ac.jp/My Drive/OnoLab/data/ElectroStatic/rawdata/260427';
shotNums = [6]; % とりあえず14番を指定。001からなら 1:20 など。

for s = shotNums
    % ファイル名の生成 (ES_260427XXX.csv)
    fileName = sprintf('ES_260427%03d.csv', s);
    fullPath = fullfile(baseDir, fileName);
    
    if ~exist(fullPath, 'file')
        fprintf('Skip: ファイルが見つかりません -> %s\n', fileName);
        continue;
    end
    
    % データの読み込み
    data = readtable(fullPath);
    
    % NaN（空データ）が含まれる行を削除（この日のデータは後半が空のようです）
    data = rmmissing(data); 
    
    % 列名の取得（time(us), ch1, ch2...）
    varNames = data.Properties.VariableNames;
    timeVar = varNames{1}; % 1列目が時間
    chVars = varNames(2:end); % 2列目以降がチャンネル
    
    % --- プロット ---
    fig = figure('Name', sprintf('Shot %03d Inspection', s), 'Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.8]);

    % 全チャンネルを並べて表示
    s_plot = stackedplot(data, chVars, 'XVariable', timeVar);
    s_plot.Title = sprintf('Shot Number: %03d (Date: 260427)', s);
    s_plot.LineWidth = 1;
    grid on;
    
    fprintf('Displaying Shot: %03d (Enterキーで次へ、Ctrl+Cで終了)\n', s);
    pause; 
    if s ~= shotNums(end), close(fig); end
end
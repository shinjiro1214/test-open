%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 複数ショットの I2 重ね書きプロット
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars -except date filepath save_filepath; % 前回の変数をクリア（パス設定などは残す）

% データの読み込み設定
date = 240611; % 113:115 117:123
% date = 251220
prompt = 'Enter shot numbers (e.g., [1 2 3] or 1:5): ';
dlgtitle = 'Shot Numbers'; 
dims = [1 50];
definput = {'1:3'}; % デフォルト入力例
answer = inputdlg(prompt, dlgtitle, dims, definput);

% 入力された文字列を数値配列に変換
if isempty(answer)
    return; % キャンセルされたら終了
end
shot_list = str2num(answer{1}); 

% パス設定
save_filepath = "/Users/shohgookazaki/Library/CloudStorage/GoogleDrive-shohgo-okazaki@g.ecc.u-tokyo.ac.jp/My Drive/OnoLab/data/ElectroStatic/triple_probe";
% 研究室外のファイルパス
filepath = "/Users/shohgookazaki/Library/CloudStorage/GoogleDrive-shohgo-okazaki@g.ecc.u-tokyo.ac.jp/My Drive/OnoLab/data/ElectroStatic/triple_probe/raw_data";

% プロット設定
index_start = 4500;
index_end = 7500;
V2 = 40; % 参考用（凡例に使用）

figure;
hold on;
grid on;
title(['Triple probe I2 comparison (Date: ', num2str(date), ')']);
xlabel('Time [us] (index)'); % 時間軸がindex依存のようなので仮置き
ylabel('Probe current I2 [A]');
xlim([450, 480]); % 元コードのxlimに合わせる
% ylim([-1 5]); % 必要であればコメントアウトを外して固定

colors = lines(length(shot_list)); % 色の自動生成

% ショットごとのループ処理
for i = 1:length(shot_list)
    current_shot = shot_list(i);
    
    % ショット番号のゼロ埋め処理 (例: 1 -> 001, 15 -> 015)
    if current_shot < 10
        shotnum_str = ['00', num2str(current_shot)];
    elseif current_shot < 100
        shotnum_str = ['0', num2str(current_shot)];
    else
        shotnum_str = num2str(current_shot);
    end
    
    filename = strcat(filepath, '/', num2str(date), '/ES_', num2str(date), shotnum_str, '.csv');
    
    % ファイル読み込み (エラーハンドリング付き)
    try
        test = readmatrix(filename);
        
        % データ抽出
        time = test(index_start:index_end, 1);
        I2_values = test(index_start:index_end, 36);
        
        % 平滑化（必要であればコメントアウトを外す）
        % I2_values = smoothdata(I2_values, 'movmean', 5);
        
        % プロット
        plot(time, I2_values, 'DisplayName', ['Shot ', shotnum_str], ...
             'Color', colors(i,:), 'LineWidth', 1.2);
         
        fprintf("Loaded shot: %s\n", shotnum_str);
        
    catch ME
        warning('Failed to process shot %s: %s', shotnum_str, ME.message);
    end
end

legend('show', 'Location', 'best');
hold off;

% 保存処理
save_dir = strcat(save_filepath, '/', num2str(date), '/figure/triple_probe_multi');
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% ファイル名用にショット範囲を取得
shot_range_str = [num2str(min(shot_list)), '-', num2str(max(shot_list))];
save_name = strcat(save_dir, '/I2_comparison_', shot_range_str, '.png');

saveas(gcf, save_name);
fprintf("Saved figure to: %s\n", save_name);
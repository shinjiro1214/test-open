clear; close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 設定
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
date = 251218;                       % 読み込むファイルの日付
target_times = [466, 468, 470, 472, 474]; % プロットしたい時間のリスト [us]

% ファイルパスの構築
% dataDir = getenv('PROBE_DATA_DIR');
% if isempty(dataDir)
%     dataDir = pwd; % 環境変数がない場合はカレントディレクトリ
% end
filepath_mat = fullfile(getenv('PROBE_DATA_DIR'),'tripleProbe',[num2str(date),'.mat']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% データの読み込みとプロット
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist(filepath_mat, "file")
    fprintf('ファイルを読み込んでいます: %s\n', filepath_mat);
    load(filepath_mat, 'triple_data2D', 'R_values', 'time_values');
    
    % データの抽出
    % 平均値: 3次元 (R x 1 x Time) -> 2次元 (R x Time)
    Te_data_mean = squeeze(triple_data2D.Te); 
    
    % 標準偏差 (エラーバー用) の抽出
    % ※ここでエラーが出る場合は、下の「手順1」でmatファイルを作り直してください
    if isfield(triple_data2D, 'Te_std')
        Te_data_std = squeeze(triple_data2D.Te_std);
    else
        error('MATファイルに標準偏差データ(Te_std)が含まれていません。先にデータ保存コードを実行してください。');
    end
    
    % プロットの準備
    figure('Name', 'Te Radial Evolution with ErrorBars', 'Position', [100, 100, 800, 600]);
    hold on;
    
    % 色の準備
    colors = lines(length(target_times)); 
    
    % 各時間についてループ処理
    for i = 1:length(target_times)
        t_target = target_times(i);
        
        % 最も近い時間のインデックスを探す
        [~, t_idx] = min(abs(time_values - t_target));
        actual_t = time_values(t_idx);
        
        % その時間のデータを抽出
        Te_profile = Te_data_mean(:, t_idx);   % 平均値
        Te_error   = Te_data_std(:, t_idx);    % 標準偏差
        
        % エラーバー付きプロット
        errorbar(R_values, Te_profile, Te_error, ...
            '-o', ...
            'Color', colors(i,:), ...
            'LineWidth', 1.5, ...
            'MarkerSize', 6, ...
            'MarkerFaceColor', colors(i,:), ...
            'CapSize', 8, ...               % エラーバーの横棒のサイズ
            'DisplayName', sprintf('t = %.1f \\mus', actual_t));
    end
    
    % グラフの装飾
    title('Electron Temperature Radial Evolution', 'FontSize', 16);
    xlabel('R [m]', 'FontSize', 14);
    ylabel('T_e [eV]', 'FontSize', 14);
    grid on;
    
    % 凡例を表示
    legend('Location', 'best', 'FontSize', 10);
    
    % 軸フォントサイズ調整
    ax = gca;
    ax.FontSize = 12;
    % xlim([min(R_values), max(R_values)]);
    xlim([0.1 0.25]);
    
    hold off; % 重ね書きモード終了

else
    error('指定されたファイルが見つかりません: %s', filepath_mat);
end
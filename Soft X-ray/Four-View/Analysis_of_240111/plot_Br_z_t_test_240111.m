close all
dirPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
shotList = 7:30;

% --- 設定: プロットしたい複数の物理時間 ---
% targetTimes = [464, 465, 466, 467]; 
targetTimes = [460, 463, 465, 468]; 

% データを格納する3次元配列 [ショット数 x 空間点数 x 時間点数]
% 空間点数(40)はgrid2Dのサイズに依存します。初期値として確保。
Br_z_all = NaN(numel(shotList), 40, numel(targetTimes));
z_axis = []; % 軸データはループ内で取得

% --- データ読み込みループ ---
j = 1;
for i = shotList
    filePath = [dirPath, num2str(i, '%03i'), '.mat'];
    if exist(filePath, 'file')
        load(filePath, 'data2D', 'grid2D');
        
        % 軸データの取得（最初のファイルのみ）
        if isempty(z_axis)
            z_axis = grid2D.zq(1,:);
        end
        
        % 指定された各時間についてデータを抽出
        for k = 1:numel(targetTimes)
            t_val = targetTimes(k);
            
            % 指定時刻に最も近いインデックスを探す
            [~, t_idx] = min(abs(data2D.trange - t_val));
            
            % データの取得と反転 (-1倍)
            Br_z_all(j, :, k) = -1 * get_Br_z(grid2D, data2D, t_idx);
        end
    else
        warning('File not found: %s', filePath);
    end
    j = j + 1;
end

% --- TF電圧条件の定義 ---
% ループ処理しやすいように構造体配列で定義します
tf_groups = struct(...
    'shots', {[16:21], [13:15, 22:24], [10:12, 25:27], [7:9, 28:30]}, ...
    'label', {'TF=2.5kV', 'TF=3kV', 'TF=3.5kV', 'TF=4kV'} ...
);

% プロット用の色設定（時間の数だけ色を用意）
% 例: jet, parula, autumn などを指定可能
timeColors = jet(numel(targetTimes)); 

% --- プロット作成ループ (C案) ---
for g = 1:numel(tf_groups)
    % 現在のTF条件に対応するショットのインデックスを取得
    currentShots = tf_groups(g).shots;
    [~, shotIndices] = ismember(currentShots, shotList);
    
    % データが存在しないショット番号(0)を除去
    shotIndices = shotIndices(shotIndices > 0);
    
    if isempty(shotIndices)
        continue; 
    end

    % Figure作成
    figure('Name', ['Time Evolution: ', tf_groups(g).label], 'Position', [100, 100, 800, 600]);
    hold on;
    grid on;
    
    % 時間ごとにプロットを重ね書き
    for k = 1:numel(targetTimes)
        % [該当ショット群 x 空間 x 特定の時間] のデータを抽出
        data_subset = Br_z_all(shotIndices, :, k);
        
        % 平均と標準偏差を計算
        BrM = mean(data_subset, 1, 'omitmissing');
        BrD = std(data_subset, 0, 1, 'omitmissing');
        
        % Errorbarプロット
        p = errorbar(z_axis, BrM, BrD, ...
            'Color', timeColors(k,:), ...
            'LineWidth', 1.5, ...
            'CapSize', 8, ...
            'DisplayName', sprintf('t = %d \\mus', targetTimes(k)));
        
        % マーカーの見た目調整
        p.Marker = 'o';
        p.MarkerSize = 6;
        p.MarkerFaceColor = timeColors(k,:);
    end
    
    % グラフ装飾
    % title(['Br z-distribution Time Evolution (', tf_groups(g).label, ')']);
    xlabel('z [m]');
    ylabel('Reconnection magnetic field [T]');
    legend('Location', 'best');
    ax = gca;
    ax.FontSize = 16;
    xlim([min(z_axis), max(z_axis)]);
    hold off;
end

% --- 関数定義 ---
function Br_z = get_Br_z(grid2D, data2D, t_idx)
    [~, xPointList] = get_axis_x_multi(grid2D, data2D);
    
    % エラー処理: 時間インデックスが範囲外、またはX点が見つからない場合
    if t_idx > length(xPointList.r) || isnan(xPointList.r(t_idx))
        Br_z = NaN(1, size(grid2D.zq, 2));
        return;
    end

    idxR = knnsearch(grid2D.rq(:,1), xPointList.r(t_idx));
    
    % インデックス範囲のガード
    r_idx_start = max(1, idxR-2);
    r_idx_end = min(idxR+2, numel(grid2D.rq(:,1)));
    
    Br_z = mean(data2D.Br(r_idx_start:r_idx_end, :, t_idx), 1);
end
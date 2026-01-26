close all
dirPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
shotList = 7:30;

% --- 【変更点1】複数の時間を指定 ---
targetTimes = [460, 465, 468, 470]; 

% データを格納する3次元配列を作成 [ショット数 x 空間点数 x 時間点数]
% ※空間点数(40)はgrid2Dのサイズに依存するため、ループ内で初期化または可変にするのが安全ですが、
%   ここでは元のコードに合わせて40と仮定します。
Br_z_all = zeros(numel(shotList), 40, numel(targetTimes));

% figure; hold on; % 読み込み状況などの確認用（必要なければ削除可）

j = 1;
for i = shotList
    % データ読み込み
    filePath = [dirPath, num2str(i, '%03i'), '.mat'];
    if exist(filePath, 'file')
        load(filePath, 'data2D', 'grid2D');
        z = grid2D.zq(1,:);
        
        % --- 【変更点2】指定された全時間についてデータを抽出 ---
        for k = 1:numel(targetTimes)
            t_val = targetTimes(k);
            
            % 指定時刻に最も近いインデックスを探す (ロバスト性向上)
            [~, t_idx] = min(abs(data2D.trange - t_val));
            
            % 抽出して保存 (3次元目に時間のインデックスkを使用)
            Br_z_all(j, :, k) = -1 * get_Br_z(grid2D, data2D, t_idx);
        end
    else
        warning('File not found: %s', filePath);
        Br_z_all(j, :, :) = NaN; % ファイルがない場合はNaN埋め
    end
    j = j + 1;
end

% TFごとのインデックス分け
[~,idxTF40] = ismember([7:9,28:30], shotList);
[~,idxTF35] = ismember([10:12,25:27], shotList);
[~,idxTF30] = ismember([13:15,22:24], shotList);
[~,idxTF25] = ismember(16:21, shotList);

% プロット用設定
colors = {'k', 'b', 'r', 'm'}; % 色などを適宜設定
tf_labels = {'TF=2.5kV', 'TF=3kV', 'TF=3.5kV', 'TF=4kV'};

% --- 【変更点3】時間ごとにFigureを作成してプロット ---
for k = 1:numel(targetTimes)
    t_val = targetTimes(k);
    
    % 現在の時間ステップ(k)のデータを切り出し [ショット数 x 空間]
    Br_z_current = Br_z_all(:, :, k); 
    
    % 統計計算
    BrM40 = mean(Br_z_current(idxTF40,:), 'omitmissing');
    BrD40 = std(Br_z_current(idxTF40,:), 'omitmissing');
    BrM35 = mean(Br_z_current(idxTF35,:), 'omitmissing');
    BrD35 = std(Br_z_current(idxTF35,:), 'omitmissing');
    BrM30 = mean(Br_z_current(idxTF30,:), 'omitmissing');
    BrD30 = std(Br_z_current(idxTF30,:), 'omitmissing');
    BrM25 = mean(Br_z_current(idxTF25,:), 'omitmissing');
    BrD25 = std(Br_z_current(idxTF25,:), 'omitmissing');
    
    % プロット作成
    figure('Name', ['Time = ' num2str(t_val)]);
    hold on;
    
    % 見やすくするためにLineWidthなどを調整しました
    errorbar(z, BrM25, BrD25, 'DisplayName', tf_labels{1}, 'LineWidth', 1.5);
    errorbar(z, BrM30, BrD30, 'DisplayName', tf_labels{2}, 'LineWidth', 1.5);
    errorbar(z, BrM35, BrD35, 'DisplayName', tf_labels{3}, 'LineWidth', 1.5);
    errorbar(z, BrM40, BrD40, 'DisplayName', tf_labels{4}, 'LineWidth', 1.5);
    
    legend('Location', 'best');
    xlabel('z [m]');
    ylabel('Reconnection magnetic field [T]');
    title(['Br distribution at t = ' num2str(t_val)]);
    
    ax = gca;
    ax.FontSize = 18;
    grid on;
end

% --- 関数定義 ---
function Br_z = get_Br_z(grid2D, data2D, t_idx)
    [~, xPointList] = get_axis_x_multi(grid2D, data2D);
    
    % X点が存在するかチェック
    if t_idx > length(xPointList.r) || isnan(xPointList.r(t_idx))
        Br_z = NaN(1, size(grid2D.zq, 2)); % データがない場合はNaN配列を返す
        return;
    end

    idxR = knnsearch(grid2D.rq(:,1), xPointList.r(t_idx));
    
    % インデックス範囲のガード処理
    r_idx_start = max(1, idxR-2);
    r_idx_end = min(idxR+2, numel(grid2D.rq(:,1)));
    
    Br_z = mean(data2D.Br(r_idx_start:r_idx_end, :, t_idx), 1);
end
%% 設定
target_time = 468; % プロットしたい時間 [us]

dirPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
shotList = 7:30;
Bz_r = zeros(numel(shotList),40);
j=1;
figure;hold on;
for i = shotList
    load([dirPath,num2str(i,'%03i'),'.mat'],'data2D','grid2D');
    [Bz_profile,r_vec] = get_Bz_r(grid2D,data2D,target_time);
    plot(r_vec, Bz_profile, 'LineWidth', 2);
    Bz_r(j,:) = Bz_profile.';
    j=j+1;
end
[~,idxTF40] = ismember([7:9,28:30],shotList);
[~,idxTF35] = ismember([10:12,25:27],shotList);
[~,idxTF30] = ismember([13:15,22:24],shotList);
[~,idxTF25] = ismember(16:21,shotList);

% 処理しやすいように構造体またはセル配列にまとめる
groups = {idxTF40, idxTF35, idxTF30, idxTF25};
groupNames = {'TF40', 'TF35', 'TF30', 'TF25'};
groupColors = lines(4); % 4色のカラーマップを作成

% =========================================================================
% 3. 統計計算とエラーバープロット
% =========================================================================
figure('Name', 'Bz Radial Profile by Group', 'Color', 'w');
hold on;

for k = 1:length(groups)
    % 現在のグループのインデックスを取得
    currentIdx = groups{k};
    
    % --- データ抽出 ---
    % 0が含まれている場合（ismemberで見つからなかった場合）を除く処理
    currentIdx = currentIdx(currentIdx > 0); 
    groupData = Bz_r(currentIdx, :);
    
    % --- 統計量の計算 ---
    N = size(groupData, 1);            % データ数 (ショット数)
    mu = mean(groupData, 1, 'omitnan');           % 平均値
    sigma = std(groupData, 0, 1, 'omitnan');      % 標準偏差
    se = sigma ./ sqrt(N);             % 標準誤差 (Standard Error)
    
    % --- プロット ---
    errorbar(r_vec, mu, se, ...
        '-o', ...
        'LineWidth', 2, ...
        'MarkerSize', 6, ...
        'CapSize', 8, ...
        'Color', groupColors(k, :), ...
        'MarkerFaceColor', groupColors(k, :), ...
        'DisplayName', groupNames{k});
end

% =========================================================================
% 4. 装飾
% =========================================================================
xlabel('r [m]', 'FontSize', 14);
ylabel('B_z [T]', 'FontSize', 14);
title(['B_z Radial Distribution (Mean \pm SE) at t = ' num2str(target_time) ' \mu s'], 'FontSize', 16);
grid on;
legend('Location', 'best', 'FontSize', 12);
ax = gca;
ax.FontSize = 14;
xlim([min(r_vec), max(r_vec)]);
hold off;


function [Bz_profile,r_vec] = get_Bz_r(grid2D,data2D,target_time)
    target_z = 0;      % プロットしたいZ座標 [m] (0付近)

    %% 1. 時間インデックスの特定
    % data2D.trange の中から target_time に最も近いインデックスを探す
    [~, t_idx] = min(abs(data2D.trange - target_time));
    % actual_time = data2D.trange(t_idx);

    % fprintf('指定時間: %.1f us -> 実際のデータ時間: %.1f us (Index: %d)\n', ...
        % target_time, actual_time, t_idx);

    %% 2. 空間グリッドの特定
    % grid2D.zq, grid2D.rq の構造を確認して軸ベクトルを取得
    % ※通常、(R方向のサイズ) x (Z方向のサイズ) になっていると仮定します

    % Z方向のベクトル取得 (Zが列方向に変化していると仮定)
    if size(grid2D.zq, 1) > 1 && size(grid2D.zq, 2) > 1
        % メッシュグリッドの場合
        % 行によって値が変わらない方向を探す、あるいは1行目を取得
        z_vec = grid2D.zq(1, :); 
        r_vec = grid2D.rq(:, 1);
    else
        % 1次元ベクトルの場合
        z_vec = grid2D.zq;
        r_vec = grid2D.rq;
    end

    %% 3. Z位置のインデックス特定
    [~, z_idx] = min(abs(z_vec - target_z));
    % actual_z = z_vec(z_idx);

    % fprintf('指定Z位置: %.3f m -> 実際のデータZ位置: %.3f m (Index: %d)\n', ...
    %     target_z, actual_z, z_idx);

    %% 4. データの抽出とプロット
    % Bzデータの構造は通常 (R, Z, Time) または (Z, R, Time) です。
    % 前回の get_Epara の interp2 の使い方 (zq, rq, ...) から、
    % data2D.Bz は (R行, Z列, Time) である可能性が高いです。

    if ndims(data2D.Bz) == 3
        Bz_slice_2D = data2D.Bz(:, :, t_idx); % 指定時間の2Dデータを取得
        
        % Zを固定してR方向のデータを抽出 (すべての行, 指定のZ列)
        Bz_profile = Bz_slice_2D(:, z_idx);

        % Br_slice_2D = data2D.Br(:, :, t_idx); % 指定時間の2Dデータを取得
        
        % % Zを固定してR方向のデータを抽出 (すべての行, 指定のZ列)
        % Br_profile = Br_slice_2D(:, z_idx);

        % if isfield(data2D,'Bt_th')
        %     Bt_slice_2D = data2D.Bt_th(:, :, t_idx); % 指定時間の2Dデータを取得
        % else
        %     Bt_slice_2D = data2D.Bt(:, :, t_idx); % 指定時間の2Dデータを取得
        %     Bt_slice_2D = nan(size(Bt_slice_2D));
        % end
        % Bt_profile = Bt_slice_2D(:, z_idx);

        % Bz_profile = Bz_profile./sqrt(Bz_profile.^2+Br_profile.^2+Bt_profile.^2);
    else
        error('data2D.Bz の次元が想定(3次元)と異なります。');
    end

end
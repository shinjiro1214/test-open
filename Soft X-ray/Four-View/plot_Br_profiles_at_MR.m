function profiles = plot_Br_profiles_at_MR(PCB, pathname);
% PLOT_BR_PROFILES_AT_MR
% 合体率 (Merging Ratio) が 0.1, 0.3, 0.5, 0.7, 0.9 に達した瞬間の
% リコネクション磁場 (Br) のZ方向分布をプロットする関数。
%
% Outputs:
%   profiles: プロットに使用したデータを格納した構造体配列

    % --- 1. データの読み込みと前処理 ---
    % 基本的なデータロード (元のコードに準拠)
    [grid2D, data2D] = process_PCBdata_280ch(PCB, pathname);
    
    trange = PCB.trange;
    Br = data2D.Br;
    % grid2Dの構造: rq(:,1)がR軸, zq(1,:)がZ軸と想定
    rq = grid2D.rq;
    zq = grid2D.zq;
    r_axis = rq(:,1);
    z_axis = zq(1,:).'; % 列ベクトル化
    
    % 時間範囲の絞り込み (必要に応じて調整)
    % 元コードと同様、全範囲を使用する場合は以下
    newTimeRange = 1:numel(trange);
    trange = trange(newTimeRange);
    Br = Br(:,:,newTimeRange);
    
    % 軸とX点の取得
    [magAxisList, xPointList] = get_axis_x_multi(grid2D, data2D);
    
    % --- 2. 全時間ステップでの合体率 (Merging Ratio) の計算 ---
    numSteps = numel(trange);
    mergingRatio = NaN(1, numSteps);
    
    for i = 1:numSteps
        % X点の磁束 (複数のX点がある場合は1つ目を採用)
        psi_X = xPointList.psi(i); 
        % 磁気軸の磁束 (複数の軸がある場合は平均を採用)
        psi_O = mean(magAxisList.psi(:,i)); 
        
        if psi_O ~= 0
            mergingRatio(i) = psi_X / psi_O;
        end
    end
    
    % --- 3. 指定された合体率でのプロファイル抽出とプロット ---
    % targetMRs = [0.1, 0.3, 0.5, 0.7, 0.9];
    targetMRs = [0.3, 0.5, 0.7, 0.9];
    % colors = jet(length(targetMRs)); % 色分け用のカラーマップ
    colors = turbo(length(targetMRs)); % 色分け用のカラーマップ
    
    figure('Name', 'Br Z-Profiles at Target MRs', 'Position', [100, 100, 800, 600]);
    hold on;
    grid on;
    
    profiles = struct(); % データ保存用
    
    valid_targets = 0;
    
    for k = 1:length(targetMRs)
        target = targetMRs(k);
        
        % 時間範囲の制限 (例: 450~500usの間で探索)
        % 必要に応じて範囲を変更してください
        searchRange = trange >= 440 & trange <= 520; 
        
        t_subset = trange(searchRange);
        mr_subset = mergingRatio(searchRange);
        
        % ターゲット合体率を跨ぐインデックスを探す
        idx1_sub = find(mr_subset <= target, 1, 'last');
        idx2_sub = find(mr_subset >= target, 1, 'first');
        
        % インデックスが見つからない場合はスキップ
        if isempty(idx1_sub) || isempty(idx2_sub)
            fprintf('Target MR = %.1f not found in range.\n', target);
            continue;
        end
        
        % 全体配列におけるインデックスに変換
        indices = find(searchRange);
        idx1 = indices(idx1_sub);
        idx2 = indices(idx2_sub);
        
        % --- 線形補間処理 ---
        MR1 = mergingRatio(idx1);
        MR2 = mergingRatio(idx2);
        
        if MR1 == MR2
            weight = 0.5;
        else
            weight = (target - MR1) / (MR2 - MR1);
        end
        
        % 時刻の補間
        t_interp = trange(idx1) + weight * (trange(idx2) - trange(idx1));
        
        % 2次元 Br 場の補間
        Br2D_interp = Br(:,:,idx1) + weight * (Br(:,:,idx2) - Br(:,:,idx1));
        
        % X点 R座標の補間 (1行目を使用)
        rx1 = xPointList.r(1, idx1);
        rx2 = xPointList.r(1, idx2);
        Rx_interp = rx1 + weight * (rx2 - rx1);
        
        % X点 Z座標の補間 (プロット上のマーカー用)
        zx1 = xPointList.z(1, idx1);
        zx2 = xPointList.z(1, idx2);
        Zx_interp = zx1 + weight * (zx2 - zx1);
        
        % --- プロファイルの抽出 ---
        % 補間された X点のR座標 に最も近いグリッドインデックスを探す
        [~, idxR_closest] = min(abs(r_axis - Rx_interp));
        
        % Z方向プロファイルの取得
        Br_z_profile = Br2D_interp(idxR_closest, :);
        
        % --- プロット ---
        plot(z_axis, Br_z_profile, '.-', ...
             'Color', colors(k,:), ...
             'LineWidth', 1.5, ...
             'DisplayName', sprintf('MR=%.1f (t=%.1f\\mus)', target, t_interp));
         
        % X点の位置をマーカーで表示
        plot(Zx_interp, interp1(z_axis, Br_z_profile, Zx_interp), 'p', ...
             'Color', colors(k,:), 'MarkerFaceColor', colors(k,:), ...
             'MarkerSize', 12, 'HandleVisibility', 'off');
         
        valid_targets = valid_targets + 1;
        
        % データを保存
        profiles(k).MR = target;
        profiles(k).time = t_interp;
        profiles(k).z = z_axis;
        profiles(k).Br = Br_z_profile;
        profiles(k).Rx = Rx_interp;
        profiles(k).Zx = Zx_interp;
    end
    
    if valid_targets > 0
        xlabel('Z [m]', 'FontSize', 12);
        ylabel('B_r [T]', 'FontSize', 12);
        title('B_r Z-profile at X-point Radius for Various Merging Ratios', 'FontSize', 14);
        legend('Location', 'best', 'FontSize', 10);
        yline(0, 'k-', 'HandleVisibility', 'off'); % ゼロ点ライン
        xlim([min(z_axis), max(z_axis)]);
    else
        warning('No valid merging ratios found to plot.');
        close(gcf);
    end

end
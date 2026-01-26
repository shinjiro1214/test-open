function [] = plot_psi_withLine(PCB,pathname)

% shot = PCB.shot;
trange = PCB.trange;
% start = PCB.start;

[grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);

% --- 設定 ---
time_values = trange;
target_times = [455, 460, 465, 470]; % 時刻
start_pt = [-0.15, 0.15];       % 始点 [z, r]
end_z    = 0.15;                % 終点 z座標 (これを超えたら止める)

% 時間ベクトルチェック
if ~exist('time_values', 'var')
    error('変数 time_values が見つかりません。');
end

% Figure作成
figure('Name', 'Selected Field Line Segment', 'Color', 'w', 'Position', [100, 100, 1200, 350]);

for i = 1:length(target_times)
    t_target = target_times(i);
    [~, idx] = min(abs(time_values - t_target));
    
    % データの取得
    Psi_t = data2D.psi(:, :, idx);
    Bz_t  = data2D.Bz(:, :, idx);
    Br_t  = data2D.Br(:, :, idx);
    
    subplot(2, 2, i);
    hold on;
    contourf(grid2D.zq, grid2D.rq, Psi_t, 40,'LineStyle','none');clim([-1e-2,1e-2])%psi
    
    % 1. 背景の磁気面（グレーで薄く）
    contour(grid2D.zq, grid2D.rq, Psi_t, 30, 'LineWidth', 1, 'Color', 'black');
    
    % 2. 磁力線追跡の方向制御
    % 始点におけるBzの値を確認
    Bz_val = interp2(grid2D.zq, grid2D.rq, Bz_t, start_pt(1), start_pt(2));
    
    % もしBzが負（左向き）なら、右(z正)に進むためにベクトルを反転して追跡させる
    % (磁力線の形状そのものは変わらず、たどる向きだけ逆転します)
    if Bz_val < 0
        U = -Bz_t; 
        V = -Br_t;
    else
        U = Bz_t;
        V = Br_t;
    end
    
    % 3. 磁力線追跡 (stream2)
    % stream2(X, Y, U, V, startX, startY) -> ZがX, RがYに対応
    lines = stream2(grid2D.zq, grid2D.rq, U, V, start_pt(1), start_pt(2));
    
    if ~isempty(lines)
        line_data = lines{1}; % [z, r] の列データ
        
        % 4. 範囲制限 (z <= 0.15 の部分だけ抽出)
        % 論理インデックスで抽出
        mask = line_data(:, 1) <= end_z;
        
        % データが途切れないように、閾値を超えた直後の1点も含めると綺麗に繋がります
        idx_end = find(mask == 0, 1, 'first');
        if isempty(idx_end)
            % 最後まで範囲内の場合
            segment = line_data;
        else
            % 範囲外に出た直後の点まで含める（補間の代わり）
            segment = line_data(1:idx_end, :);
        end
        
        % 5. 赤線でプロット
        plot(segment(:,1), segment(:,2), 'r-', 'LineWidth', 2.5);
        
        % 始点と終点をマーク
        plot(segment(1,1), segment(1,2), 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 6); % 始点
        plot(segment(end,1), segment(end,2), 'rx', 'LineWidth', 2, 'MarkerSize', 8);    % 終点
    end
    
    % 装飾
    hold off;
    axis equal; grid on;
    title(sprintf('t = %d \\mus', t_target), 'FontSize', 14);
    if i > 2, xlabel('Z [m]', 'FontSize', 12); end
    if i == 1 || i==3, ylabel('R [m]', 'FontSize', 12); end
    
    % 表示範囲 (少し余裕を持たせる)
    xlim([-0.25, 0.25]); 
    ylim([min(grid2D.rq(:)), max(grid2D.rq(:))]);
    
    ax = gca; ax.FontSize = 12;
end

% sgtitle('Magnetic Field Line Segment (Z = -0.15 \to 0.15)', 'FontSize', 16);
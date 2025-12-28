function analyze_fctf_lag_windowed()
    % --- ユーザー環境設定 ---
    pathname.fourier = '/Users/shohgookazaki/Documents/UTokyo/OnoTanabeLab/koala/mnt/fourier'; 
    directory_rogo = fullfile(pathname.fourier, 'rogowski');

    % --- 解析対象の設定 ---
    targets = define_targets();
    
    % --- 校正係数 (Wiki 2024/07/03以降準拠) ---
    COEFF_FCTF1 = 85.8 * 1e3;  % CH11 [A/V] (基準)
    COEFF_FCTF2 = 217.0 * 1e3; % CH12 [A/V] (比較対象)

    % --- 解析設定 ---
    % 正規化およびラグ計算に使用する時間ウィンドウ
    WINDOW_START = 500; % [us]
    WINDOW_END   = 600; % [us]

    % カラーマップ設定 (ズレの表示範囲)
    LAG_CLIM = [-15, 15]; 
    cmap = jet(256); 

    % 結果格納用
    all_results = [];

    % --- Figure 1: 波形プロット ---
    f_wave = figure('Position', [50, 50, 1400, 1000]);
    t_layout = tiledlayout('flow', 'TileSpacing', 'compact', 'Padding', 'compact');
    title_str = sprintf('FCTF1 (Gray) vs FCTF2 (Color) [Lag Calc & Norm Window: %d-%d\\mus]', WINDOW_START, WINDOW_END);
    title(t_layout, title_str);

    fprintf('Processing dates...\n');

    for i = 1:length(targets)
        date_val = targets(i).date;
        shot_list = targets(i).shots;
        
        nexttile;
        hold on;
        
        for s = 1:length(shot_list)
            shot_num = shot_list(s);
            
            % データ取得
            [time_axis, curr11, curr12] = get_processed_data(date_val, shot_num, directory_rogo, COEFF_FCTF1, COEFF_FCTF2);
            
            if isempty(time_axis)
                continue;
            end
            
            % --- 1. 解析ウィンドウ(500-600us)の特定 ---
            idx_window = time_axis >= WINDOW_START & time_axis <= WINDOW_END;
            
            % データが存在しない場合はスキップ
            if ~any(idx_window)
                continue;
            end

            % --- 2. 正規化 (指定ウィンドウ内の最大値を使用) ---
            % ウィンドウ内の最大絶対値を取得
            max11 = max(abs(curr11(idx_window)));
            max12 = max(abs(curr12(idx_window)));
            
            % 全体がゼロなら正規化しない（エラー回避）
            if max11 == 0, max11 = 1; end
            if max12 == 0, max12 = 1; end
            
            % 全データに対して正規化を適用
            norm11 = curr11 / max11;
            norm12 = curr12 / max12;
            
            % --- 3. ズレ(Lag)の計算 (指定ウィンドウ内のデータのみ使用) ---
            % ウィンドウ内の正規化済みデータを切り出し
            seg11 = norm11(idx_window);
            seg12 = norm12(idx_window);
            
            dt = time_axis(2) - time_axis(1);
            
            % 切り出したセグメント同士で相互相関を計算
            [r, lags] = xcorr(seg12, seg11); 
            [~, idx_max] = max(abs(r));
            lag_us = lags(idx_max) * dt;
            
            % --- 結果保存 ---
            res.Date = date_val;
            res.Shot = shot_num;
            res.TimeLag_us = lag_us;
            all_results = [all_results; res];
            
            % --- プロット (全区間を表示) ---
            line_color = map_val2color(lag_us, LAG_CLIM, cmap);
            
            % TF1 (基準): グレー
            plot(time_axis, norm11, 'Color', [0.6 0.6 0.6 0.3], 'LineWidth', 0.5);
            
            % TF2 (比較): ラグに応じた色
            plot(time_axis, norm12, 'Color', [line_color, 0.6], 'LineWidth', 1.0);
        end
        
        % 装飾
        title(sprintf('Date: %d (N=%d)', date_val, length(shot_list)));
        xlabel('Time [\mus]');
        ylabel('Norm. Current');
        xlim([350, 650]); 
        ylim([-3, 4]);
        grid on;
        
        % 解析ウィンドウを点線で明示
        xline(WINDOW_START, 'k:', 'LineWidth', 0.5);
        xline(WINDOW_END, 'k:', 'LineWidth', 0.5);
        
        % カラーバー
        colormap(gca, cmap);
        caxis(LAG_CLIM);
        
        if i == length(targets)
            c = colorbar;
            c.Label.String = 'Time Lag (CH12 - CH11) [\mus]';
        end
        
        hold off;
    end

    % --- Figure 2: 統計散布図 ---
    if ~isempty(all_results)
        plot_statistics_continuous(all_results, LAG_CLIM, cmap);
        
        % CSV出力
        output_filename = 'fctf_timelag.csv';
        T = struct2table(all_results);
        writetable(T, output_filename);
        fprintf('Analysis completed. Data saved to: %s\n', fullfile(pwd, output_filename));
    else
        fprintf('No data found.\n');
    end
end

% --- ヘルパー: 色変換 ---
function rgb = map_val2color(val, clim, cmap)
    c_min = clim(1);
    c_max = clim(2);
    normalized = (val - c_min) / (c_max - c_min);
    normalized = max(0, min(1, normalized));
    idx = floor(normalized * (size(cmap, 1) - 1)) + 1;
    rgb = cmap(idx, :);
end

% --- ヘルパー: 統計プロット ---
function plot_statistics_continuous(all_results, clim, cmap)
    figure('Position', [100, 100, 1000, 500]);
    unique_dates = unique([all_results.Date]);
    
    hold on;
    x_counter = 1;
    tick_locs = [];
    tick_labels = {};
    
    for d = 1:length(unique_dates)
        d_val = unique_dates(d);
        idx = [all_results.Date] == d_val;
        subset = all_results(idx);
        
        x_vals = x_counter : (x_counter + length(subset) - 1);
        y_vals = [subset.TimeLag_us];
        
        scatter(x_vals, y_vals, 40, y_vals, 'filled');
        
        tick_locs(end+1) = mean(x_vals);
        tick_labels{end+1} = num2str(d_val);
        
        xline(max(x_vals) + 0.5, 'k:', 'Alpha', 0.3);
        x_counter = max(x_vals) + 1;
    end
    
    colormap(cmap);
    caxis(clim);
    c = colorbar;
    c.Label.String = 'Time Lag [\mus]';
    
    yline(0, 'k-', 'Alpha', 0.5);
    
    xticks(tick_locs);
    xticklabels(tick_labels);
    xlabel('Date Group');
    ylabel('Time Lag (CH12 - CH11) [\mus]');
    title('Time Lag Analysis (Calculated over 500-600\mus)');
    ylim([-10 10]); % 範囲を適宜調整
    grid on;
    hold off;
end

% --- データ取得関数 ---
function [time_axis, ch11, ch12] = get_processed_data(date_val, shot_num, dir_path, c1, c2)
    time_axis = []; ch11 = []; ch12 = [];
    [~, ~, filepath] = directory_generation_Rogowski(date_val, shot_num, dir_path);
    if ~isfile(filepath), return; end
    
    try
        data = readmatrix(filepath, "FileType", "text");
        aquisition_rate = 10; 
        x_idx = 10 : 10 : 10000; 
        
        col11 = 2 + 11; col12 = 2 + 12;
        raw11 = data(x_idx, col11);
        raw12 = data(x_idx, col12);
        
        val11 = raw11 * c1;
        val12 = raw12 * c2;
        
        val11 = val11 - mean(val11(1:10));
        val12 = val12 - mean(val12(1:10));
        
        t_ax = x_idx ./ 10;
        
        idx_450 = find(t_ax >= 450, 1);
        if isempty(idx_450), idx_450 = length(t_ax); end
        
        if val11(idx_450) < 0, val11 = val11 * -1; end
        if val12(idx_450) < 0, val12 = val12 * -1; end
        
        time_axis = t_ax;
        ch11 = val11;
        ch12 = val12;
    catch
    end
end

% --- パス生成 ---
function [date_str, shot_str, full_path] = directory_generation_Rogowski(date_val, shot_num, directory_rogo)
    date_str = num2str(date_val);
    if shot_num < 10, shot_str = ['00', num2str(shot_num)];
    elseif shot_num < 100, shot_str = ['0', num2str(shot_num)];
    else, shot_str = num2str(shot_num); end
    full_path = fullfile(directory_rogo, date_str, [date_str, shot_str, '.rgw']);
    if ~isfile(full_path), full_path = fullfile(directory_rogo, date_str, [date_str, shot_str, '.txt']); end
end

% --- ターゲット定義 ---
function targets = define_targets()
    targets = struct('date', {}, 'shots', {});
    targets(end+1).date = 240611; targets(end).shots = [110:111, 113:115, 117:136 138:140];
    targets(end+1).date = 241110; targets(end).shots = [18, 19, 22:33];
    targets(end+1).date = 241124; targets(end).shots = [24:26, 28:30, 32:36, 38:53];
    targets(end+1).date = 241225; targets(end).shots = [9:11, 14:34, 36:42, 47:57, 59:61];
    targets(end+1).date = 250205; targets(end).shots = [2, 5:7, 9, 15, 16, 23:31, 33:38, 40:45];
    targets(end+1).date = 250206; targets(end).shots = 6:21;
    targets(end+1).date = 251220; targets(end).shots = [5:10, 12:23];
end
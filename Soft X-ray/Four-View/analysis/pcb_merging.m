clearvars -except saved_answer

addpath '/Users/shohgookazaki/Documents/GitHub/test-open/pcb_experiment';
addpath '/Users/shohgookazaki/Documents/MATLAB/inputsdlg_v2.3.2'
addpath '/Users/shohgookazaki/Documents/matlab/common';

run define_path.m

% --- 基本設定 ---
doCheck = 0;
dataType = 1;
PCB.chtype = 1;

%%%% 入力ダイアログ
name = 'Input';
prompt = {'Date:', 'Shot number:','Restart:','xaxis:','xpointdata():'};
formats = struct('type', {}, 'style', {}, 'items', {}, 'format', {}, 'limits', {}, 'size', {});

if exist('saved_answer', 'var')
    defaultanswer = saved_answer;
else
    defaultanswer = {[], '', [], 1, 1, 1, 1,[]};
end

formats(1,1).type = 'edit';
formats(1,1).format = 'integer';
formats(1,1).size = [100 20];

formats(2,1).type = 'edit';
formats(2,1).format = 'text';
formats(2,1).size = [100 20];

formats(3,1).type = 'list';
formats(3,1).style = 'popupmenu';
formats(3,1).items = {'false', 'true'};
formats(3,1).format = 'integer';
formats(3,1).size = [100 20];

formats(4,1).type = 'list';
formats(4,1).style = 'popupmenu';
formats(4,1).items = {'merging ratio[%]', 'time[s]'};
formats(4,1).format = 'integer';
formats(4,1).size = [100 20];

% 7番目: All (Et+Jt+Curv+Et/Jt)
formats(5,1).type = 'list';
formats(5,1).style = 'popupmenu';
formats(5,1).items = {'Et', 'Et/Jt', 'dB/dt', 'dEt/dt', 'Jt', 'Curvature', 'All (Et+Jt+Curv+Et/Jt)'};
formats(5,1).format = 'integer';
formats(5,1).size = [100 20];

[answer, canceled] = inputsdlg(prompt, name, formats);

if isempty(answer)
    return
end

if ~canceled
    date = answer{1};
    IDXlist_str = answer{2};
    IDXlist = str2num(IDXlist_str);
    PCB.restart = answer{3}-1;
    xaxis = answer{4};
    xpointdata = answer{5};
    saved_answer = answer;
end

PCB.xpointdata = xpointdata;

% === プロット範囲設定 ===
PCB.trange = 400:600;
PCB.n = 40;
PCB.start = 450; 
PCB.end = 495;
FIG.start = 460;
FIG.end = 500;

DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';
T=getTS6log(DOCID);
T=searchlog(T,'date',date);

if isnan(T.shot(1))
    T(1, :) = [];
end

n_data = numel(IDXlist);
shotlist = [T.a039(IDXlist), T.a040(IDXlist)];
tfshotlist = [T.a039_TF(IDXlist), T.a040_TF(IDXlist)];
EFlist = T.EF_A_(IDXlist);
TFlist = T.TF_kV_(IDXlist);

% データ格納用
all_data = zeros(n_data,numel(PCB.trange));
all_merging_ratios = zeros(n_data, numel(PCB.trange));

% Et/Jt計算用の一時保存配列
all_data_Et_raw = zeros(n_data, numel(PCB.trange));
all_data_Jt_raw = zeros(n_data, numel(PCB.trange));

% 3種同時プロット用
all_data_Et = zeros(n_data, numel(PCB.trange));
all_data_Jt = zeros(n_data, numel(PCB.trange));
all_data_Curv = zeros(n_data, numel(PCB.trange));

% === データ処理ループ ===
for i=1:n_data
    PCB.date = date;
    PCB.idx = IDXlist(i);
    PCB.shot=shotlist(i,:);
    PCB.tfshot=tfshotlist(i,:);
    PCB.dataType = dataType;
    if PCB.shot == PCB.tfshot
        PCB.tfshot = [0,0];
    end
    PCB.i_EF=EFlist(i);
    PCB.TF=TFlist(i);
    
    if doCheck
        check_signal(PCB, pathname);
    else
        [grid2D, data2D] = process_PCBdata_280ch(PCB, pathname);
        merging_ratio = get_merging_ratio(data2D, grid2D, PCB.trange);
        
        % --- データ取得 ---
        if PCB.xpointdata == 2 % Et/Jt (Ratio of Averages)
            % EtとJtを個別に取得
            pcb_temp = PCB;
            
            % Et取得 (Option 1)
            pcb_temp.xpointdata = 1;
            all_data_Et_raw(i,:) = xpointplot(grid2D, data2D, pcb_temp);
            
            % Jt取得 (Option 5 -> 生の値)
            pcb_temp.xpointdata = 5;
            all_data_Jt_raw(i,:) = xpointplot(grid2D, data2D, pcb_temp);
            
            % ダミー
            all_data(i,:) = all_data_Et_raw(i,:); 

        elseif PCB.xpointdata == 7 % All (Et, Jt, Curv, Et/Jt)
            pcb_temp = PCB; 
            % 1. Et
            pcb_temp.xpointdata = 1;
            all_data_Et(i,:) = xpointplot(grid2D, data2D, pcb_temp);
            % 2. Jt
            pcb_temp.xpointdata = 5;
            all_data_Jt(i,:) = xpointplot(grid2D, data2D, pcb_temp);
            % 3. Curvature
            pcb_temp.xpointdata = 6;
            all_data_Curv(i,:) = xpointplot(grid2D, data2D, pcb_temp);
            
            all_data(i,:) = all_data_Et(i,:);
        else
            all_data(i,:) = xpointplot(grid2D, data2D, PCB);
        end

        mask = (PCB.trange >= FIG.start) & (PCB.trange <= FIG.end);
        merging_ratio(~mask) = NaN; 
        all_merging_ratios(i, :) = merging_ratio; 
    end
end

if true
    % === 統計処理 ===
    qmerge = prctile(all_merging_ratios, [10 90],1);
    iqrmerge = qmerge(2,:)-qmerge(1,:);
    filtered_merge = all_merging_ratios;
    filtered_merge(filtered_merge < qmerge(1,:)-1.5*iqrmerge | filtered_merge > qmerge(2,:)+1.5*iqrmerge) = NaN;
    mean_merging_ratio = mean(filtered_merge, 1, 'omitnan');
    stderr_merging_ratio = std(filtered_merge, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(filtered_merge), 1));
    
    if xpointdata == 2
        % === Et/Jt (Ratio of Averages) ===
        mean_Et_raw = mean(all_data_Et_raw, 1, 'omitnan');
        mean_Jt_raw = mean(all_data_Jt_raw, 1, 'omitnan');
        
        all_mean_data = (mean_Et_raw ./ mean_Jt_raw) * 1e3;
        
        % 誤差伝播
        ste_Et = std(all_data_Et_raw, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(all_data_Et_raw), 1));
        ste_Jt = std(all_data_Jt_raw, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(all_data_Jt_raw), 1));
        
        rel_err_Et = ste_Et ./ abs(mean_Et_raw);
        rel_err_Jt = ste_Jt ./ abs(mean_Jt_raw);
        stderr_mean = abs(all_mean_data) .* sqrt(rel_err_Et.^2 + rel_err_Jt.^2);
        
    elseif xpointdata == 7
        % === All Plot (Et, Jt, Curv, Et/Jt) ===
        mean_Et = mean(all_data_Et, 1, 'omitnan');
        mean_Jt = mean(all_data_Jt, 1, 'omitnan');
        mean_Curv = mean(all_data_Curv, 1, 'omitnan');
        
        % Et/Jt の計算 (Option 2と同じロジック)
        mean_Res = (mean_Et ./ mean_Jt) * 1e3;
        
        err_Et = std(all_data_Et, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(all_data_Et),1));
        err_Jt = std(all_data_Jt, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(all_data_Jt),1));
        err_Curv = std(all_data_Curv, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(all_data_Curv),1));
        
        % Et/Jt の誤差伝播
        rel_err_Et = err_Et ./ abs(mean_Et);
        rel_err_Jt = err_Jt ./ abs(mean_Jt);
        err_Res = abs(mean_Res) .* sqrt(rel_err_Et.^2 + rel_err_Jt.^2);
        
        all_mean_data = mean_Et; 
        stderr_mean = err_Et;
    else
        all_mean_data = mean(all_data,1,'omitnan');
        stderr_mean = std(all_data, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(all_data),1));
    end
    
    t = PCB.trange; 
    
    % === プロット描画 ===
    
    if xpointdata == 7
        range_idx = (PCB.trange >= PCB.start) & (PCB.trange <= PCB.end);
        if xaxis == 1, x_plot = mean_merging_ratio(range_idx); x_lim = [0 100]; x_label_str='Merging ratio [%]';
        elseif xaxis == 2, x_plot = PCB.trange(range_idx); x_lim = [PCB.start PCB.end]; x_label_str='time [s]'; end
        
        % データ準備
        y1 = mean_Et(range_idx); e1 = err_Et(range_idx);       % Et (Black)
        y2 = mean_Jt(range_idx); e2 = err_Jt(range_idx);       % Jt (Red)
        y3 = mean_Curv(range_idx); e3 = err_Curv(range_idx);   % Curv (Blue)
        y4 = mean_Res(range_idx); e4 = err_Res(range_idx);     % Et/Jt (Green)
        
        fig = figure('Units', 'pixels', 'Position', [100 100 1100 600], 'Color', 'w');
        
        % --- 軸位置の定義 ---
        % メインのプロットエリアを少し狭くして、右側に軸を入れるスペースを作る
        % [left bottom width height]
        ax_pos = [0.10 0.15 0.60 0.75]; 
        
        % --- Axis 1: Et (Left, Black) ---
        ax1 = axes('Position', ax_pos, 'YColor', 'k', 'Box', 'off', 'Color', 'none'); hold(ax1, 'on');
        if xaxis == 2
            fill_y = [-1e9 1e9]; 
            patch([475 483 483 475], [fill_y(1) fill_y(1) fill_y(2) fill_y(2)], ...
                  [0.85 0.92 1], 'EdgeColor', 'none', 'Parent', ax1, 'HandleVisibility', 'off');
        end
        plot_shaded_error(x_plot, y1, e1, [0.6 0.6 0.6], 0.3, ax1);
        plot(ax1, x_plot, y1, '.-k', 'LineWidth', 1.2, 'MarkerSize', 10);
        set(ax1, 'Layer', 'top'); 
        ylabel(ax1, 'Et [V/m]', 'FontSize', 12, 'FontWeight', 'bold');
        xlabel(ax1, x_label_str, 'FontSize', 12); grid(ax1, 'on'); ylim(ax1, [-350 350]); 
        
        % --- Axis 2: Jt (Right, Red) ---
        ax2 = axes('Position', ax_pos, 'YAxisLocation', 'right', 'Color', 'none', 'XColor', 'none', 'YColor', 'r', 'Box', 'off'); hold(ax2, 'on');
        plot_shaded_error(x_plot, y2, e2, [1 0.7 0.7], 0.3, ax2);
        plot(ax2, x_plot, y2, '.-r', 'LineWidth', 1.2, 'MarkerSize', 10);
        ylabel(ax2, 'Jt [MA/m^2]', 'FontSize', 12, 'FontWeight', 'bold'); ylim(ax2, [-1e6 1e6]); 
        
        % --- Axis 3: Curvature (Right+, Blue) ---
        % ax2の右隣に配置
        ax3_pos = ax_pos; 
        ax3_pos(1) = ax_pos(1) + ax_pos(3) + 0.06; % メイン軸の右端から少し離す
        ax3_pos(3) = 1e-5; % 幅はほぼゼロ
        
        % ダミー軸（プロット用）
        ax3_plot = axes('Position', ax_pos, 'YAxisLocation', 'right', 'Color', 'none', 'XColor', 'none', 'YColor', 'b', 'Box', 'off', 'Visible', 'off'); hold(ax3_plot, 'on');
        plot_shaded_error(x_plot, y3, e3, [0.7 0.7 1], 0.3, ax3_plot);
        plot(ax3_plot, x_plot, y3, '.-b', 'LineWidth', 1.2, 'MarkerSize', 10);
        ylim(ax3_plot, [0 150]); 
        
        % 目盛り表示用軸
        ax3_scale = axes('Position', ax3_pos, 'YAxisLocation', 'right', 'Color', 'none', 'XColor', 'none', 'YColor', 'b', 'Box', 'off');
        ylabel(ax3_scale, 'Curvature [m^{-1}]', 'FontSize', 12, 'FontWeight', 'bold');
        ylim(ax3_scale, [0 150]);

        % --- Axis 4: Et/Jt (Right++, Green) ---
        % ax3のさらに右隣に配置
        ax4_pos = ax3_pos;
        ax4_pos(1) = ax3_pos(1) + 0.08; % ax3からさらに右へずらす
        
        % ダミー軸（プロット用）
        ax4_plot = axes('Position', ax_pos, 'YAxisLocation', 'right', 'Color', 'none', 'XColor', 'none', 'YColor', [0 0.5 0], 'Box', 'off', 'Visible', 'off'); hold(ax4_plot, 'on');
        plot_shaded_error(x_plot, y4, e4, [0.7 1 0.7], 0.3, ax4_plot);
        plot(ax4_plot, x_plot, y4, '.-', 'Color', [0 0.5 0], 'LineWidth', 1.2, 'MarkerSize', 10);
        ylim(ax4_plot, [-4 4]); 

        % 目盛り表示用軸
        ax4_scale = axes('Position', ax4_pos, 'YAxisLocation', 'right', 'Color', 'none', 'XColor', 'none', 'YColor', [0 0.5 0], 'Box', 'off');
        ylabel(ax4_scale, 'Et/Jt [m\Omega m]', 'FontSize', 12, 'FontWeight', 'bold');
        ylim(ax4_scale, [-4 4]);

        % リンクの設定
        linkaxes([ax1, ax2, ax3_plot, ax4_plot], 'x'); 
        xlim(ax1, x_lim);
        
        title(ax1, ['Shot: ', num2str(date)]); hold off;
        
    else
        % --- 単一プロットモード (Et/Jt を含む) ---
        x_plot = mean_merging_ratio; 
        y = all_mean_data;
        xerr = stderr_merging_ratio; 
        yerr = stderr_mean;

        figure; 
        if xaxis == 2
             x_plot = PCB.trange;
             yl = [-1e9 1e9];
             patch([475 483 483 475], [yl(1) yl(1) yl(2) yl(2)], ...
                  [0.85 0.92 1], 'EdgeColor', 'none');
             set(gca, 'Layer', 'top'); 
             hold on;
             xlim([PCB.start PCB.end]);
        else
            xlim([0 100]);
            hold on;
        end
        
        range_mask = (PCB.trange >= PCB.start) & (PCB.trange <= PCB.end);
        if xaxis == 2
             plot_x = x_plot(range_mask);
             plot_y = y(range_mask);
             plot_yerr = yerr(range_mask);
        else
             plot_x = x_plot;
             plot_y = y;
             plot_yerr = yerr;
        end
        
        plot_shaded_error(plot_x, plot_y, plot_yerr, [0.6 0.6 0.6], 0.3, gca);
        plot(plot_x, plot_y, '-ko', 'LineWidth', 1.2);
        
        % === 【追加】Spitzer抵抗のプロット (Et/Jtの場合) ===
        if xpointdata == 2
             % パラメータ仮定 (必要に応じて変更してください)
             Te_ev = 10;      % 電子温度 [eV]
             Zeff = 2;        % 実効電荷数
             CoulombLog = 13; % クーロン対数
             
             % Spitzer抵抗率の計算 [mOhm m]
             eta_spitzer_val = 1.03e-4 * Zeff * CoulombLog * (Te_ev^(-1.5)); % [Ohm m]
             eta_spitzer_mOhm = eta_spitzer_val * 1e3; % [mOhm m]
             
             yline(eta_spitzer_mOhm, '--r', ['Spitzer'], 'LineWidth', 2);
        end
        
        if xaxis == 1
            xlabel('Merging ratio [%]');
        else
            xlabel('time [s]');
        end
        set_ylabel(xpointdata);
        grid on;
        hold off;
    end
end

function plot_shaded_error(x, y, err, color, alpha, ax)
    x = x(:)'; y = y(:)'; err = err(:)';
    y_upper = y + err;
    y_lower = y - err;
    x_poly = [x, fliplr(x)];
    y_poly = [y_upper, fliplr(y_lower)];
    mask = ~isnan(x_poly) & ~isnan(y_poly);
    if any(mask)
        fill(ax, x_poly(mask), y_poly(mask), color, 'FaceAlpha', alpha, 'EdgeColor', 'none');
    end
end

function set_ylabel(xpointdata)
    if xpointdata == 1
        ylim([-350 350]);
        ylabel('Et [V/m]');
    elseif xpointdata == 2
        ylim([-4 4])
        ylabel('Et/Jt [m\Omega m]')
    elseif xpointdata == 4
        ylabel('dEt/dt [V/m/s]');
    elseif xpointdata == 5
        ylabel('Jt [MA/m^2]'); 
        ylim([-4 4])
    elseif xpointdata == 6
        ylabel('Curvature [m^{-1}]');
    end
end
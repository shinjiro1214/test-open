%% 
% 240611 110:111 113:115 117:141
% 241110 18 19 22:33
% 241124 24:26 28:30 32:36 38:53
% 241225 9:11 14:26 28:34 36:42 47:57 59:61
% 250205 2 5:7 9 15 16 23:31 33:38 40:45
% 250206 2:23
% 251220 5:10 12:23

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%並列じゃないコード%%%%%%%%%%%%%%%%%
[PCB, pathname] = get_psb_data();
for i=1:PCB.n_data
    % dtacq_num=dtacqlist;
    PCB.date = PCB.alldate(i);
    PCB.idx = PCB.allidx(i);
    PCB.shot=PCB.allshot(i,:);
    PCB.tfshot=PCB.alltfshot(i,:);

    if PCB.shot == PCB.tfshot
        PCB.tfshot = [0,0];
    end
    PCB.i_EF=PCB.alli_EF(i);
    PCB.TF=PCB.allTF(i);
    % [I_FCPF2, I_FCTF2 ,x,aquisition_rate] = get_TF_current(PCB,pathname);
    % figure;hold on;
    % plot(I_FCPF2);
    % figure;
    % plot(I_FCTF2);
    currentDataTypes = PCB.alldataType{i};

    for k = 1:numel(currentDataTypes)
        PCB.dataType = currentDataTypes{k}; % 1つずつ取り出してセット
        if PCB.doCheck
            check_signal(PCB, pathname);
        elseif ~PCB.doCheck
            fprintf('Processing Shot: %d, Type: %s\n', PCB.shot(1), PCB.dataType); % 進捗表示用
            % profile on
            % [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
            plot_rt(PCB, pathname);


            % profile off
            % profile viewer
        end
    end

    % [B_r,B_t,B_rt,b] = get_guide_field_ratio2(PCB,pathname);
    % disp(B_r);
    % disp(B_rt);
    % disp(b)

    % disp(B_t) 

end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



% %%%%%%%%%%%%%%%%%%%%%%%%%% 並列%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if isempty(gcp('nocreate'))
%     parpool; 
% end
% 
% [PCB, pathname] = get_psb_data();
% 
% % 外部の変数をparfor内で直接書き換えないための工夫
% % 必要であれば読み取り専用として取り込んでおく
% n_data = PCB.n_data;
% alldate = PCB.alldate;
% allidx = PCB.allidx;
% allshot = PCB.allshot;
% alltfshot = PCB.alltfshot;
% alli_EF = PCB.alli_EF;
% allTF = PCB.allTF;
% alldataType = PCB.alldataType;
% doCheck = PCB.doCheck; % parfor内でif判定に使うため
% 
% % for を parfor に変更
% parfor i = 1:n_data
%     % 【重要】ループごとの独立した構造体を作成
%     localPCB = PCB; % ベースをコピー
% 
%     % 個別の値をセット
%     localPCB.date = alldate(i);
%     localPCB.idx = allidx(i);
%     localPCB.shot = allshot(i,:);
%     localPCB.tfshot = alltfshot(i,:);
% 
%     if localPCB.shot == localPCB.tfshot
%         localPCB.tfshot = [0,0];
%     end
%     localPCB.i_EF = alli_EF(i);
%     localPCB.TF = allTF(i);
% 
%     currentDataTypes = alldataType{i};
% 
%     for k = 1:numel(currentDataTypes)
%         localPCB.dataType = currentDataTypes{k}; 
% 
%         if doCheck
%             % check_signal 内の figure も 'Visible','off' にする必要があります
%             check_signal(localPCB, pathname);
%         else
%             fprintf('Processing Shot: %d, Type: %s\n', localPCB.shot(1), localPCB.dataType);
%             % plot_psi 内で figure 表示せず保存のみにする修正が必要
%             plot_psi(localPCB, pathname);
%         end
%     end
% end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function plot_rt(PCB, pathname)
    shot = PCB.shot;
    date = PCB.date;
    IDXlist = PCB.idx;
    trange = PCB.trange;
    start = PCB.start; % R-Tプロットでは全時間を表示するためコメントアウト


    % --- データ処理部分 ---
    if PCB.chtype == 2
        [grid2D,data2D] = process_PCBdata_200ch(PCB,pathname);
    else
        t_process280ch = tic;
        [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
        time_plot = toc(t_process280ch);
        disp(['process_PCBdata_280ch: ', num2str(time_plot), ' sec']);
    end

    if isstruct(grid2D)==0 
        return
    end

    % --- 磁気軸・X点の検索 ---
    [magAxisList,xPointList] = get_axis_x_multi(grid2D,data2D, PCB); 

    % --- プロット準備 ---
    figure('Position', [0 0 1000 600], 'Visible', 'off'); % 横長に見やすく調整

    % データの種類に応じた設定 (switch文をループ外へ移動)
    
    switch PCB.dataType
        case 'psi'
            targetField = 'psi';
            c_limits = [-1e-2, 1e-2];
            colorLabel = 'Zpsi (Wb)';
        case 'Bz'
            targetField = 'Bz';
            c_limits = [-0.1, 0.1];
            colorLabel = 'B_z (T)';
        case 'Bt'
            targetField = 'Bt';
            c_limits = [-0.05, 0.05];
            colorLabel = 'B_t (T)';
        case 'Jt'
            targetField = 'Jt';
            c_limits = [-0.1e7, 0.1e7];
            colorLabel = 'J_t (A/m^2)';
        case 'Et'
            targetField = 'Et';
            c_limits = [-2e2, 2e2];
            colorLabel = 'E_t (V/m)';
        case 'Br'
            targetField = 'Br';
            c_limits = [-0.07, 0.07];
            colorLabel = 'B_r (T)';
        case 'lBl'
            targetField = 'Bl'; % data2Dのフィールド名と合わせる
            c_limits = [0, 0.1];
            colorLabel = 'B_l (T)';
        case 'gradB'
            targetField = 'gradB';
            c_limits = [0, 1]; % 必要に応じて調整
            colorLabel = 'gradB (T/m)';
        % 他のケースも同様に追加してください
        case 'dpsi_dt'
            targetField = 'dpsi_dt';
            c_limits = [-3e3, 3e3];
            colorLabel = 'dpsi dt (Wb/s)';
        case 'magnetic_pressure'
            targetField = 'magnetic_pressure';
            c_limits = [0, 3e2];
            colorLabel = 'magnetic pressure (Pa)';
        case 'dmag_press_dr'
            targetField = 'dmag_press_dr';
            c_limits = [-5e3, 5e3];
            colorLabel = 'd(magnetic pressure)/dr (Pa/m)';
        otherwise
            % 未定義の場合は警告を出してpsiをデフォルトに
            warning('Unknown dataType: %s. Plotting psi instead.', PCB.dataType);
            targetField = 'psi';
            c_limits = [-1e-2, 1e-2];
            colorLabel = 'Zpsi (Wb)';
    end

    % --- R-Tプロット用データの抽出 ---
    disp("Generating R-T slice with dynamic Z selection...")
    
    num_time = length(trange);
    num_r = size(grid2D.rq, 1);
    rt_data = zeros(num_r, num_time); % (r, t) の行列
    
    % 実際にスライスしたZ位置に対応するR位置を記録する配列（黒線プロット用）
    track_r_list = nan(1, num_time); 
    
    % Z方向のグリッド配列（1次元）
    z_coords = grid2D.zq(1, :);
    r_coords = grid2D.rq(:, 1);

    for i = 1:num_time
        t_current = trange(i);
        
        % 配列の範囲チェック
        if i > length(xPointList.z)
            break; 
        end
        
        % 現在のX点座標を取得
        z_xp = xPointList.z(i);
        r_xp = xPointList.r(i);
        
        % --- 切り替えロジック ---
        target_z = NaN;      % この時刻で採用するZ座標
        target_r_ref = NaN;  % 黒線で表示するR座標（X点 or 磁気軸）

        if ~isnan(z_xp)
            % Case 1: X点が存在する場合 -> X点を採用
            target_z = z_xp;
            target_r_ref = r_xp;
        else
            % Case 2: X点が存在しない(NaN)場合
            if t_current < 480
                % 480us未満 -> z=0 を採用
                target_z = 0;
                target_r_ref = NaN; % z=0固定の間は特定の点を追跡しないならNaN（線を描かない）
            else
                % 480us以降 -> 磁気軸(O点)を採用
                % 磁気軸が複数ある場合に備え、有効な最初の値を取得
                mag_z_candidates = magAxisList.z(:, i);
                mag_r_candidates = magAxisList.r(:, i);
                
                % NaNでない最初の磁気軸を探す
                valid_idx = find(~isnan(mag_z_candidates), 1);
                
                if ~isempty(valid_idx)
                    target_z = mag_z_candidates(valid_idx);
                    target_r_ref = mag_r_candidates(valid_idx);
                end
            end
        end
        
        % --- データ抽出 ---
        if isnan(target_z)
            % ターゲットが決まらなかった場合
            rt_data(:, i) = NaN;
            track_r_list(i) = NaN;
        else
            % 最も近いグリッドインデックスを探す
            [~, z_idx] = min(abs(z_coords - target_z));
            
            % そのZ位置におけるR方向のプロファイルを取得
            rt_data(:, i) = data2D.(targetField)(:, z_idx, i);
            
            % 黒線用のR位置を保存
            track_r_list(i) = target_r_ref;
        end
    end

    % --- 描画 ---
    % 横軸: 時間 (trange), 縦軸: 半径 (r_coords), 色: 強度 (rt_data)
    imagesc(trange, r_coords, rt_data);
    
    set(gca, 'YDir', 'normal'); % y軸の向きを正す
    shading flat;
    
    % カラーマップ設定（whitejetがあればそれを使う）
    try
        colormap('whitejet');
    catch
        colormap('jet');
    end
    
    if ~isempty(c_limits)
        clim(c_limits);
    end
    
    c = colorbar;
    ylabel(c, colorLabel);
    
    xlabel('Time (\mus)');
    ylabel('r (m)');
    xlim([400+start, 485]);
    
    % タイトルにロジックを反映
    % title({[targetField, ' profile'], 'z=0 (t<480, no X), z=Xpoint, then z=MagAxis'});
    
    hold on;
    % 追跡点（X点 または 磁気軸）のR位置を黒線でプロット
    % 480us以降でX点が消えたら磁気軸の位置につながるようになります
    plot(trange, track_r_list, 'k-', 'LineWidth', 1.5, 'DisplayName', 'Tracked Point (X/Mag Axis)');
    
    % 480usの境界線を点線で引く（わかりやすさのため）
    % xline(480, '--k', 'Alpha', 0.5); 
    
    hold off;

    % --- 保存処理 ---
    sgtitle(strcat(targetField, ' R-T Plot shot', num2str(shot), ' (', num2str(date), ')'));

    pathname_fig = getenv('savedata_path');
    foldername_fig = fullfile(pathname_fig, num2str(date), 'RT_plots', targetField); % フォルダ名を変更しても良い
    if ~exist(foldername_fig, 'dir')
        mkdir(foldername_fig);
    end
    
    savepath = fullfile(foldername_fig, strcat(targetField, '_RT_shot', num2str(IDXlist(1)), '.png'));

    t_save_start = tic;
    saveas(gcf, savepath);
    % print(gcf, savepath, '-dpng', '-r100'); % 必要であれば高解像度で
    time_save = toc(t_save_start);
    disp(['Save time: ', num2str(time_save), ' sec']);

    close(gcf);
end
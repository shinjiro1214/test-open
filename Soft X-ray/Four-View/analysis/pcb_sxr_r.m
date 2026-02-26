% %縦軸左がpcb、右がsxr、横軸がrのグラフ

% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % clearvars -except date IDXlist doSave doFilter doNLR ReconMethod Reset
% % close all;

% % % --- ユーザー設定 ---
% % % target_t = 485; % 解析する時刻 (us)
% % SXR.number = 6;
% % target_shot_idx = 1; % IDXlistの何番目のショットを解析するか (通常は1)
% % SXR.doSave = 1;
% % SXR.doFilter = 0;
% % SXR.ReconMethod = 2;
% % SXR.Reset = 0;
% % SXR.directory = '/LF_MEM';

% % [PCB, pathname] = get_psb_data();
% % for i=1:PCB.n_data
% %     % dtacq_num=dtacqlist;
% %     PCB.date = PCB.alldate(i);
% %     PCB.idx = PCB.allidx(i);
% %     PCB.shot = PCB.allshot(i,:);
% %     PCB.tfshot = PCB.alltfshot(i,:);
% %     if PCB.shot == PCB.tfshot
% %         PCB.tfshot = [0,0];
% %     end
% %     PCB.i_EF=PCB.alli_EF(i);
% %     SXR.date = PCB.date; % SXR構造体にも日付をセット
% %     SXR.shot = PCB.idx; % SXR構造体にもショットをセット
% %     SXR.SXRfilename = strcat(getenv('SXR_IMAGE_DIR'),'/',num2str(SXR.date),'/shot',num2str(SXR.shot,'%03i'),'.tif');
% %     SXR.start = PCB.startlist(i);
% %     SXR.interval = PCB.intervallist(i);

% %     PCB.i_EF=PCB.alli_EF(i);
% %     PCB.TF=PCB.allTF(i);
% %     currentDataTypes = PCB.alldataType{i};

% %     for k = 1:numel(currentDataTypes)
% %         PCB.dataType = currentDataTypes{k}; % 1つずつ取り出してセット
% %         if PCB.doCheck
% %             check_signal(PCB, pathname);
% %         elseif ~PCB.doCheck
% %             fprintf('Processing Shot: %d, Type: %s\n', PCB.shot(1), PCB.dataType); % 進捗表示用
% %             % profile on
% %             % [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
% %             plot_pcb_sxr_r(PCB, SXR, pathname);


% %             % profile off
% %             % profile viewer
% %         end
% %     end

% % end

% % function plot_pcb_sxr_r(PCB, SXR, pathname)
% %     % PCBデータの処理
% %     [grid2D, data2D] = process_PCBdata_280ch(PCB, pathname);

% %     % SXRデータの処理
% %     date = SXR.date;
% %     shot = SXR.shot;
% %     % show_xpoint = SXR.show_xpoint;
% %     % show_localmax = SXR.show_localmax;
% %     start = SXR.start;
% %     interval = SXR.interval;
% %     doSave = SXR.doSave;
% %     doFilter = SXR.doFilter;
% %     ReconMethod = SXR.ReconMethod;
% %     SXRfilename = SXR.SXRfilename;

% %     addpath '/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Machine_Learning/code'; %getMDSdata.mとcoeff200ch.xlsxのあるフォルダへのパス


% %     if doFilter == 1
% %         if ReconMethod == 0
% %             options = 'NLF_TP';
% %         elseif ReconMethod == 1
% %             options = 'NLF_MFI';
% %         elseif ReconMethod == 2
% %             options = 'NLF_MEM';
% %         elseif ReconMethod == 3
% %             options  = 'NLF_cGAN';
% %         elseif ReconMethod == 4
% %             options = 'NLF_GPT';
% %         end
% %     else
% %         if ReconMethod == 0
% %             options = 'LF_TP';
% %         elseif ReconMethod == 1
% %             options = 'LF_MFI';
% %         elseif ReconMethod == 2
% %             options = 'LF_MEM';
% %         elseif ReconMethod == 3
% %             options  = 'LF_cGAN';
% %         elseif ReconMethod == 4
% %             options = 'LF_GPT';
% %         end
% %     end

% %     dirPath = getenv('SXR_MATRIX_DIR');
% %     matrixFolder = strcat(dirPath,'/',options,'/',num2str(date),'/shot',num2str(shot));

% %     newProjectionNumber = 30;
% %     newGridNumber = 50;
% %     % 再構成計算に必要なパラメータを計算するなら読み込む
% %     parameterFile = sprintf('parameters%d%d.mat', newProjectionNumber, newGridNumber);
% %     disp(strcat('Loading matrix from :',matrixFolder))
% %     load(parameterFile,'range');


% %     matrixPath = strcat(matrixFolder,'/',num2str(SXR.number),'.mat');
% %     load(matrixPath,'EE1','EE2','EE3','EE4');
% %     EE = cat(3,EE1,EE2,EE3,EE4);

% %     t_target = (SXR.number-1)*interval + start;
% %     SXRdata.t = t_target;
% %     SXRdata.range = range;
% %     SXRdata.EE = EE;

    

% %     EE = SXRdata.EE;
% %     range = SXRdata.range ./ 1000; % mm -> m 変換 (元のコード準拠)
    
% %     % --- SXR座標の再構築 (plot_save_sxrのロジックに準拠) ---
% %     % range = [zmin1, zmax1, zmin2, zmax2, rmin, rmax]
% %     zmin2 = range(3); 
% %     zmax2 = range(4); 
% %     rmin  = range(5); 
% %     rmax  = range(6);
    
% %     % EE1 (1um Al) は元のコードのループ(i<=2)より z_space_SXR2 に対応すると判断
% %     num_r_sxr = size(EE, 1);
% %     num_z_sxr = size(EE, 2);
% %     r_space_SXR = linspace(rmin, rmax, num_r_sxr);
% %     z_space_SXR2 = linspace(zmin2, zmax2, num_z_sxr);
    
% %     % --- ターゲットデータの抽出 (EE1) ---
% %     EE1 = EE(:,:,1); % EE1のみ使用
    
% %     % --- 最大強度の Z位置を探索 ---
% %     % 全体の中で最大値を持つインデックスを取得
% %     [~, linearIdx] = max(EE1(:));
% %     [~, max_z_idx_sxr] = ind2sub(size(EE1), linearIdx);
    
% %     % 最大強度となる Z座標
% %     target_z_val = z_space_SXR2(max_z_idx_sxr);
    
% %     % SXRのR方向プロファイル抽出
% %     profile_SXR = EE1(:, max_z_idx_sxr);
    
% %     % --- PCBデータの対応する Z位置を探索 ---
% %     % grid2D.zq (1,:) から target_z_val に最も近いインデックスを探す
% %     [~, closest_z_idx_pcb] = min(abs(grid2D.zq(1,:) - target_z_val));
    
% %     % 時間方向のインデックス特定 (PCBdata.data2D.trange と SXRdata.t のマッチング)
% %     [~, t_idx] = min(abs(data2D.trange - t_target));
    
% %     % PCBのR方向プロファイル抽出 (magnetic_pressureを使用。必要に応じて Bz 等に変更可)
% %     profile_PCB = data2D.magnetic_pressure(:, closest_z_idx_pcb, t_idx);
% %     r_space_PCB = grid2D.rq(:, 1);
    
% %     % --- プロット作成 ---
% %     figure('Name', ['1D Profile Comparison at t=' num2str(t_target) 'us'], 'Color', 'w');
    
% %     % 左軸: PCBデータ (magnetic_pressure)
% %     yyaxis left
% %     plot(r_space_PCB, profile_PCB, '-b', 'LineWidth', 1.5);
% %     ylabel('Poloidal Flux \magnetic_pressure (Wb)', 'FontSize', 12);
% %     ax = gca; 
% %     ax.YColor = 'b';
% %     grid on;
    
% %     % 範囲をよしなに調整 (必要であれば clim/ を設定)
% %     % ylim([-0.01, 0.01]); 
    
% %     % 右軸: SXRデータ (EE1)
% %     yyaxis right
% %     plot(r_space_SXR, profile_SXR, '-r', 'LineWidth', 1.5);
% %     ylabel('SXR Intensity (EE1) [a.u.]', 'FontSize', 12);
% %     ax = gca;
% %     ax.YColor = 'r';
    
% %     % 共通設定
% %     xlabel('r (m)', 'FontSize', 12);
% %     title({['Comparison at t = ' num2str(t_target) ' \mus'], ...
% %            ['Cut at z \approx ' num2str(target_z_val, '%.4f') ' m (Max SXR Intensity)']}, ...
% %            'FontSize', 14);
% %     xlim([0.1, 0.3])
       
% %     % 凡例 (必要なら)
% %     legend({'\magnetic_pressure (PCB)', 'EE1 (SXR)'}, 'Location', 'best');
    
% %     disp(['Plotting complete. Cut z-position: ', num2str(target_z_val), ' m']);

% %      pathname_png = getenv('SXR_RECONSTRUCTED_DIR');
% %     foldername_png = strcat(pathname_png,SXR.directory,'/',num2str(date),'/shot',num2str(shot));
% %     filename_png = strcat('/pcb_sxr_r: shot',num2str(shot),'_',num2str(t_target),'us.png');

% %     saveas(gcf,strcat(foldername_png,filename_png));

    
% % end
% clearvars -except date IDXlist doSave doFilter doNLR ReconMethod Reset
% close all;

% % --- ユーザー設定 ---
% SXR.number = 4;
% target_shot_idx = 1;
% SXR.doSave = 1;
% SXR.doFilter = 0;
% SXR.ReconMethod = 2;
% SXR.Reset = 0;
% SXR.directory = '/LF_MEM';

% [PCB, pathname] = get_psb_data();

% % --- 【追加 1】 データ蓄積用変数の初期化 ---
% history_PCB = [];
% history_SXR = [];
% common_r_PCB = [];
% common_r_SXR = [];
% last_save_dir = ''; % 保存先パスの参照用

% for i=1:PCB.n_data
%     PCB.date = PCB.alldate(i);
%     PCB.idx = PCB.allidx(i);
%     PCB.shot = PCB.allshot(i,:);
%     PCB.tfshot = PCB.alltfshot(i,:);
%     if PCB.shot == PCB.tfshot
%         PCB.tfshot = [0,0];
%     end
%     PCB.i_EF=PCB.alli_EF(i);
%     SXR.date = PCB.date; 
%     SXR.shot = PCB.idx; 
%     SXR.SXRfilename = strcat(getenv('SXR_IMAGE_DIR'),'/',num2str(SXR.date),'/shot',num2str(SXR.shot,'%03i'),'.tif');
%     SXR.start = PCB.startlist(i);
%     SXR.interval = PCB.intervallist(i);

%     PCB.i_EF=PCB.alli_EF(i);
%     PCB.TF=PCB.allTF(i);
%     currentDataTypes = PCB.alldataType{i};

%     for k = 1:numel(currentDataTypes)
%         PCB.dataType = currentDataTypes{k};
%         if PCB.doCheck
%             check_signal(PCB, pathname);
%         elseif ~PCB.doCheck
%             fprintf('Processing Shot: %d, Type: %s\n', PCB.shot(1), PCB.dataType);
            
%             % --- 【変更 2】 関数からデータを受け取る ---
%             [p_pcb, p_sxr, r_pcb, r_sxr, save_dir] = plot_pcb_sxr_r(PCB, SXR, pathname);
            
%             % データを蓄積 (グリッドが変わらない前提で結合)
%             if ~isempty(p_pcb) && ~isempty(p_sxr)
%                 history_PCB = [history_PCB, p_pcb];
%                 history_SXR = [history_SXR, p_sxr];
                
%                 % 最初のループで軸情報を保持
%                 if isempty(common_r_PCB)
%                     common_r_PCB = r_pcb;
%                     common_r_SXR = r_sxr;
%                 end
%                 last_save_dir = save_dir;
%             end
%         end
%     end
% end

% % --- 【追加 3】 平均プロファイルの計算と保存 ---
% % --- 【修正】 平均プロファイルの計算と保存（エラーバー付き） ---
% if ~isempty(history_PCB)
%     fprintf('Calculating and plotting average RELATIVE profiles with error bars...\n');
    
%     % 相対座標グリッドを統一（必要に応じて補間が必要ですが、ここでは共通グリッドと仮定）
%     % common_r_PCB が相対座標 (r - r_xp) になっていることを確認
    
%     mean_PCB = mean(history_PCB, 2, 'omitnan');
%     std_PCB  = std(history_PCB, 0, 2, 'omitnan');
%     mean_SXR = mean(history_SXR, 2, 'omitnan');
%     std_SXR  = std(history_SXR, 0, 2, 'omitnan');
    
%     x_fill_PCB = [common_r_PCB; flipud(common_r_PCB)];
%     y_fill_PCB = [mean_PCB + std_PCB; flipud(mean_PCB - std_PCB)];
%     x_fill_SXR = [common_r_SXR; flipud(common_r_SXR)];
%     y_fill_SXR = [mean_SXR + std_SXR; flipud(mean_SXR - std_SXR)];
    
%     figure('Name', 'Average Relative Profile', 'Color', 'w');
    
%     % --- 左軸: PCB (青) ---
%     yyaxis left
%     hold on;
%     fill(x_fill_PCB, y_fill_PCB, 'b', 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');
%     plot(common_r_PCB, mean_PCB, '-b', 'LineWidth', 2, 'DisplayName', 'Avg PCB');
%     ylabel( PCB.dataType, 'FontSize', 12);
%     ax = gca; ax.YColor = 'b'; grid on;
%     % ylim([0, 200])
    
%     % --- 右軸: SXR (赤) ---
%     yyaxis right
%     hold on;
%     fill(x_fill_SXR, y_fill_SXR, 'r', 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');
%     plot(common_r_SXR, mean_SXR, '-r', 'LineWidth', 2, 'DisplayName', 'Avg SXR');
%     ylabel('Avg SXR Intensity (a.u.)', 'FontSize', 12);
%     ax = gca; ax.YColor = 'r';
%     ylim([0, 6])
    
%     % 共通設定
%     hold off;
%     xlabel('r - r_{xpoint} (m)', 'FontSize', 12);
%     title(['Average Relative Profile \pm\sigma (N=', num2str(size(history_PCB, 2)), ')'], 'FontSize', 14);
%     xlim([-0.1, 0.1]); % X点近傍にフォーカス
%     xline(0, '--k', 'LineWidth', 1.2, 'DisplayName', 'X-point');
%     legend('Location', 'best');
    
    
%     % 保存処理
%     if ~isempty(last_save_dir)
%         parent_dir = fileparts(last_save_dir); 
%         save_filename = fullfile(parent_dir, ['average_relative_pcb_sxr_', PCB.dataType, '_', num2str(SXR.number),'shot', num2str(PCB.allidx(1)),'-',num2str(PCB.allidx(end)),'.png']);
%         saveas(gcf, save_filename);
%     end
% end


% % --- 関数定義の変更 ---
% function [p_pcb_rel, p_sxr_rel, r_rel_PCB, r_rel_SXR, foldername_png] = plot_pcb_sxr_r(PCB, SXR, pathname)
%     % 初期化 (エラーハンドリング用)
%     profile_PCB = []; profile_SXR = []; r_space_PCB = []; r_space_SXR = []; foldername_png = '';

%     try
%         % PCBデータの処理
%         [grid2D, data2D] = process_PCBdata_280ch(PCB, pathname);

%         % SXRデータの処理
%         date = SXR.date;
%         shot = SXR.shot;
%         start = SXR.start;
%         interval = SXR.interval;
%         % doSave = SXR.doSave; % 未使用変数は省略可
%         doFilter = SXR.doFilter;
%         ReconMethod = SXR.ReconMethod;
%         % SXRfilename = SXR.SXRfilename; % 未使用

%         addpath '/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Machine_Learning/code'; 

%         if doFilter == 1
%             if ReconMethod == 0; options = 'NLF_TP';
%             elseif ReconMethod == 1; options = 'NLF_MFI';
%             elseif ReconMethod == 2; options = 'NLF_MEM';
%             elseif ReconMethod == 3; options = 'NLF_cGAN';
%             elseif ReconMethod == 4; options = 'NLF_GPT'; end
%         else
%             if ReconMethod == 0; options = 'LF_TP';
%             elseif ReconMethod == 1; options = 'LF_MFI';
%             elseif ReconMethod == 2; options = 'LF_MEM';
%             elseif ReconMethod == 3; options = 'LF_cGAN';
%             elseif ReconMethod == 4; options = 'LF_GPT'; end
%         end

%         dirPath = getenv('SXR_MATRIX_DIR');
%         matrixFolder = strcat(dirPath,'/',options,'/',num2str(date),'/shot',num2str(shot));

%         newProjectionNumber = 30;
%         newGridNumber = 50;
%         parameterFile = sprintf('parameters%d%d.mat', newProjectionNumber, newGridNumber);
        
%         % ファイル存在確認 (エラー回避)
%         if ~exist(strcat(matrixFolder,'/',num2str(SXR.number),'.mat'), 'file')
%              warning('SXR matrix file not found: %s', matrixFolder);
%              return;
%         end

%         % disp(strcat('Loading matrix from :',matrixFolder)) % ログ省略
%         load(parameterFile,'range');

%         matrixPath = strcat(matrixFolder,'/',num2str(SXR.number),'.mat');
%         load(matrixPath,'EE1','EE2','EE3','EE4');
%         EE = cat(3,EE1,EE2,EE3,EE4);

%         t_target = (SXR.number-1)*interval + start;
%         SXRdata.t = t_target;
%         SXRdata.range = range;
%         SXRdata.EE = EE;

%         EE = SXRdata.EE;
%         range = SXRdata.range ./ 1000; % mm -> m 変換

%         zmin2 = range(3); 
%         zmax2 = range(4); 
%         rmin  = range(5); 
%         rmax  = range(6);
        
%         num_r_sxr = size(EE, 1);
%         num_z_sxr = size(EE, 2);
%         r_space_SXR = linspace(rmin, rmax, num_r_sxr)'; % 列ベクトルに変換
%         z_space_SXR2 = linspace(zmin2, zmax2, num_z_sxr);
        
%         EE1 = EE(:,:,1); 

%         % --- 【修正箇所】 特定のz範囲内で最大強度を探索 ---
%         z_min_limit = -0.1;
%         z_max_limit = 0.1;
        
%         % z_space_SXR2 の中で指定範囲に該当するインデックスを抽出
%         z_mask = (z_space_SXR2 >= z_min_limit) & (z_space_SXR2 <= z_max_limit);
        

%         % 範囲内のEE1データのみを対象にする
%         EE1_sub = EE1(:, z_mask); 
%         [~, linearIdx] = max(EE1_sub(:));
%         [~, sub_z_idx] = ind2sub(size(EE1_sub), linearIdx);
            
%         % マスクされたインデックスから元の z_space_SXR2 のインデックスを復元
%         actual_z_indices = find(z_mask);
%         max_z_idx_sxr = actual_z_indices(sub_z_idx);
        
%         target_z_val = z_space_SXR2(max_z_idx_sxr);
        
%         profile_SXR = EE1(:, max_z_idx_sxr); % 列ベクトルになっているはず
        
%         [~, closest_z_idx_pcb] = min(abs(grid2D.zq(1,:) - target_z_val));
%         [~, t_idx] = min(abs(data2D.trange - t_target));
        
%         profile_PCB = data2D.magnetic_pressure(:, closest_z_idx_pcb, t_idx);
%         r_space_PCB = grid2D.rq(:, 1);
        
%         % --- プロット作成 (個別) ---
%         figure('Name', ['1D Profile Comparison at t=' num2str(t_target) 'us'], 'Color', 'w', 'Visible', 'off'); % Visible offでバックグラウンド処理推奨
        
%         yyaxis left
%         plot(r_space_PCB, profile_PCB, '-b', 'LineWidth', 1.5);
%         ylabel(PCB.dataType, 'FontSize', 12);
%         ax = gca; ax.YColor = 'b'; grid on;
        
%         yyaxis right
%         plot(r_space_SXR, profile_SXR, '-r', 'LineWidth', 1.5);
%         ylabel('SXR Intensity (EE1) [a.u.]', 'FontSize', 12);
%         ax = gca; ax.YColor = 'r';
        
%         xlabel('r (m)', 'FontSize', 12);
%         title({['Comparison at t = ' num2str(t_target) ' \mus'], ...
%                ['Cut at z \approx ' num2str(target_z_val, '%.4f') ' m']}, 'FontSize', 14);
%         xlim([0.1, 0.3])
%         legend({'PCB_errorbar', 'PCB', 'SXR_errorbar', 'SXR'}, 'Location', 'best');
        
%         pathname_png = getenv('SXR_RECONSTRUCTED_DIR');
%         foldername_png = strcat(pathname_png,SXR.directory,'/',num2str(date),'/shot',num2str(shot));
        
%         if ~exist(foldername_png, 'dir')
%             mkdir(foldername_png);
%         end

%         filename_png = strcat('/pcb_sxr_r_', PCB.dataType, ': ',t_target ,'us.png');
%         saveas(gcf,strcat(foldername_png,filename_png));
%         close(gcf); % メモリ節約のため閉じる

%         % --- 【追加】X点位置の取得 (plot_rtのロジックを応用) ---
%         [~, xPointList] = get_axis_x_multi(grid2D, data2D, PCB);
%         [~, t_idx] = min(abs(data2D.trange - t_target));
%         r_xp = xPointList.r(t_idx);
%         z_xp = xPointList.z(t_idx);

%         % X点がNaNの場合はz=0をフォールバックに使うなどの処理
%         if isnan(z_xp), target_z = 0; else, target_z = z_xp; end
        
%         % --- プロファイル抽出 (z_xpにおけるスライス) ---
%         [~, z_idx_pcb] = min(abs(grid2D.zq(1,:) - target_z));
%         p_pcb_rel = data2D.magnetic_pressure(:, z_idx_pcb, t_idx);
        
%         [~, z_idx_sxr] = min(abs(z_space_SXR2 - target_z));
%         p_sxr_rel = EE1(:, z_idx_sxr);
        
%         % --- 相対座標の計算 ---
%         r_orig_PCB = grid2D.rq(:, 1);
%         r_orig_SXR = linspace(range(5), range(6), size(EE1,1))';
        
%         if ~isnan(r_xp)
%             r_rel_PCB = r_orig_PCB - r_xp;
%             r_rel_SXR = r_orig_SXR - r_xp;
%         else
%             % X点が見つからない場合は空を返して平均から除外
%             p_pcb_rel = []; p_sxr_rel = []; r_rel_PCB = []; r_rel_SXR = [];
%             return;
%         end

%         % --- プロット作成 ---
%         figure('Name', ['1D Relative Profile at t=' num2str(t_target) 'us'], 'Color', 'w', 'Visible', 'off');
        
%         yyaxis left
%         plot(r_rel_PCB, profile_PCB, '-b', 'LineWidth', 1.5);
%         ylabel(PCB.dataType, 'FontSize', 12);
%         ax = gca; ax.YColor = 'b'; grid on;
        
%         yyaxis right
%         plot(r_rel_SXR, profile_SXR, '-r', 'LineWidth', 1.5);
%         ylabel('SXR Intensity [a.u.]', 'FontSize', 12);
%         ax = gca; ax.YColor = 'r';
        
%         xlabel(xlabel_text, 'FontSize', 12);
%         title({['Relative Profile at t = ' num2str(t_target) ' \mus'], ...
%             ['Sliced at z \approx ' num2str(target_z_val, '%.4f') ' m']}, 'FontSize', 14);
%         xlim(x_limits);
%         xline(0, '--k', 'HandleVisibility', 'off'); % X点位置(0)に破線を表示

%         filename_png = strcat('/pcb_sxr_r_relative_', PCB.dataType, ': ',t_target ,'us.png');
%         saveas(gcf,strcat(foldername_png,filename_png));
%         close(gcf); % メモリ節約のため閉じる
%     catch ME
%         fprintf('Error in plot_pcb_sxr_r: %s\n', ME.message);
%     end
% end

clearvars -except date IDXlist doSave doFilter doNLR ReconMethod Reset
close all;

% --- ユーザー設定 ---
SXR.number = 3;
target_shot_idx = 1;
SXR.doSave = 1;
SXR.doFilter = 0;
SXR.ReconMethod = 2;
SXR.Reset = 0;
SXR.directory = '/LF_MEM';

% ★変更点: ここでプロットしたいEEの番号 (1, 2, 3, 4) を指定してください
SXR.target_EE_index = 1; 

[PCB, pathname] = get_psb_data();

% --- データ蓄積用変数の初期化 ---
history_PCB = [];
history_SXR = [];
common_r_PCB = [];
common_r_SXR = [];
last_save_dir = ''; 

for i=1:PCB.n_data
    PCB.date = PCB.alldate(i);
    PCB.idx = PCB.allidx(i);
    PCB.shot = PCB.allshot(i,:);
    PCB.tfshot = PCB.alltfshot(i,:);
    if PCB.shot == PCB.tfshot
        PCB.tfshot = [0,0];
    end
    PCB.i_EF=PCB.alli_EF(i);
    SXR.date = PCB.date; 
    SXR.shot = PCB.idx; 
    SXR.SXRfilename = strcat(getenv('SXR_IMAGE_DIR'),'/',num2str(SXR.date),'/shot',num2str(SXR.shot,'%03i'),'.tif');
    SXR.start = PCB.startlist(i);
    SXR.interval = PCB.intervallist(i);

    PCB.i_EF=PCB.alli_EF(i);
    PCB.TF=PCB.allTF(i);
    currentDataTypes = PCB.alldataType{i};

    for k = 1:numel(currentDataTypes)
        PCB.dataType = currentDataTypes{k};
        if PCB.doCheck
            check_signal(PCB, pathname);
        elseif ~PCB.doCheck
            fprintf('Processing Shot: %d, Type: %s, EE Index: %d\n', PCB.shot(1), PCB.dataType, SXR.target_EE_index);
            
            [p_pcb, p_sxr, r_pcb, r_sxr, save_dir] = plot_pcb_sxr_r(PCB, SXR, pathname);
            
            if ~isempty(p_pcb) && ~isempty(p_sxr)
                history_PCB = [history_PCB, p_pcb];
                history_SXR = [history_SXR, p_sxr];
                
                if isempty(common_r_PCB)
                    common_r_PCB = r_pcb;
                    common_r_SXR = r_sxr;
                end
                last_save_dir = save_dir;
            end
        end
    end
end

% --- 平均プロファイルの計算と保存 ---
if ~isempty(history_PCB)
    fprintf('Calculating and plotting average RELATIVE profiles with error bars...\n');
    
    mean_PCB = mean(history_PCB, 2, 'omitnan');
    std_PCB  = std(history_PCB, 0, 2, 'omitnan');
    mean_SXR = mean(history_SXR, 2, 'omitnan');
    std_SXR  = std(history_SXR, 0, 2, 'omitnan');
    
    x_fill_PCB = [common_r_PCB; flipud(common_r_PCB)];
    y_fill_PCB = [mean_PCB + std_PCB; flipud(mean_PCB - std_PCB)];
    x_fill_SXR = [common_r_SXR; flipud(common_r_SXR)];
    y_fill_SXR = [mean_SXR + std_SXR; flipud(mean_SXR - std_SXR)];
    
    figure('Name', 'Average Relative Profile', 'Color', 'w');
    
    % --- 左軸: PCB (青) ---
    yyaxis left
    hold on;
    fill(x_fill_PCB, y_fill_PCB, 'b', 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    plot(common_r_PCB, mean_PCB, '-b', 'LineWidth', 2, 'DisplayName', 'Avg PCB');
    ylabel( PCB.dataType, 'FontSize', 12);
    ax = gca; ax.YColor = 'b'; grid on;
    
    % --- 右軸: SXR (赤) ---
    yyaxis right
    hold on;
    fill(x_fill_SXR, y_fill_SXR, 'r', 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    plot(common_r_SXR, mean_SXR, '-r', 'LineWidth', 2, 'DisplayName', ['Avg SXR (EE', num2str(SXR.target_EE_index), ')']);
    ylabel(['Avg SXR Intensity (EE', num2str(SXR.target_EE_index), ') [a.u.]'], 'FontSize', 12);
    ax = gca; ax.YColor = 'r';
    ylim([0, 12])
    
    % 共通設定
    hold off;
    xlabel('r - r_{xpoint} (m)', 'FontSize', 12);
    title(['Average Relative Profile \pm\sigma (N=', num2str(size(history_PCB, 2)), ')'], 'FontSize', 14);
    xlim([-0.1, 0.1]); 
    xline(0, '--k', 'LineWidth', 1.2, 'DisplayName', 'X-point');
    legend('Location', 'best');
    
    if ~isempty(last_save_dir)
        parent_dir = fileparts(last_save_dir); 
        % ファイル名にEE番号を含める
        save_filename = fullfile(parent_dir, ['average_relative_pcb_sxr_', PCB.dataType, '_EE', num2str(SXR.target_EE_index), '_', num2str(SXR.number),'shot', num2str(PCB.allidx(1)),'-',num2str(PCB.allidx(end)),'.png']);
        saveas(gcf, save_filename);
    end
end


% --- 関数定義 ---
function [p_pcb_rel, p_sxr_rel, r_rel_PCB, r_rel_SXR, foldername_png] = plot_pcb_sxr_r(PCB, SXR, pathname)
    profile_PCB = []; profile_SXR = []; r_space_PCB = []; r_space_SXR = []; foldername_png = '';
    
    % デフォルト値の設定（念のため）
    if ~isfield(SXR, 'target_EE_index')
        target_EE_idx = 1;
    else
        target_EE_idx = SXR.target_EE_index;
    end

    try
        [grid2D, data2D] = process_PCBdata_280ch(PCB, pathname);

        date = SXR.date;
        shot = SXR.shot;
        start = SXR.start;
        interval = SXR.interval;
        doFilter = SXR.doFilter;
        ReconMethod = SXR.ReconMethod;

        addpath '/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Machine_Learning/code'; 

        if doFilter == 1
            if ReconMethod == 0; options = 'NLF_TP';
            elseif ReconMethod == 1; options = 'NLF_MFI';
            elseif ReconMethod == 2; options = 'NLF_MEM';
            elseif ReconMethod == 3; options = 'NLF_cGAN';
            elseif ReconMethod == 4; options = 'NLF_GPT'; end
        else
            if ReconMethod == 0; options = 'LF_TP';
            elseif ReconMethod == 1; options = 'LF_MFI';
            elseif ReconMethod == 2; options = 'LF_MEM';
            elseif ReconMethod == 3; options = 'LF_cGAN';
            elseif ReconMethod == 4; options = 'LF_GPT'; end
        end

        dirPath = getenv('SXR_MATRIX_DIR');
        matrixFolder = strcat(dirPath,'/',options,'/',num2str(date),'/shot',num2str(shot));

        newProjectionNumber = 30;
        newGridNumber = 50;
        parameterFile = sprintf('parameters%d%d.mat', newProjectionNumber, newGridNumber);
        
        if ~exist(strcat(matrixFolder,'/',num2str(SXR.number),'.mat'), 'file')
             warning('SXR matrix file not found: %s', matrixFolder);
             return;
        end

        load(parameterFile,'range');

        matrixPath = strcat(matrixFolder,'/',num2str(SXR.number),'.mat');
        load(matrixPath,'EE1','EE2','EE3','EE4');
        EE = cat(3,EE1,EE2,EE3,EE4);

        t_target = (SXR.number-1)*interval + start;
        SXRdata.t = t_target;
        SXRdata.range = range;
        SXRdata.EE = EE;

        EE = SXRdata.EE;
        range = SXRdata.range ./ 1000; 

        zmin2 = range(3); 
        zmax2 = range(4); 
        rmin  = range(5); 
        rmax  = range(6);
        
        num_r_sxr = size(EE, 1);
        num_z_sxr = size(EE, 2);
        r_space_SXR = linspace(rmin, rmax, num_r_sxr)'; 
        z_space_SXR2 = linspace(zmin2, zmax2, num_z_sxr);
        
        % ★変更点: 指定されたEEインデックスを使用 (EE1固定を廃止)
        EE_target = EE(:,:,target_EE_idx); 

        z_min_limit = -0.1;
        z_max_limit = 0.1;
        
        z_mask = (z_space_SXR2 >= z_min_limit) & (z_space_SXR2 <= z_max_limit);
        
        EE_target_sub = EE_target(:, z_mask); 
        [~, linearIdx] = max(EE_target_sub(:));
        [~, sub_z_idx] = ind2sub(size(EE_target_sub), linearIdx);
            
        actual_z_indices = find(z_mask);
        max_z_idx_sxr = actual_z_indices(sub_z_idx);
        
        target_z_val = z_space_SXR2(max_z_idx_sxr);
        
        profile_SXR = EE_target(:, max_z_idx_sxr); % 選択されたEEのプロファイル
        
        [~, closest_z_idx_pcb] = min(abs(grid2D.zq(1,:) - target_z_val));
        [~, t_idx] = min(abs(data2D.trange - t_target));
        
        profile_PCB = data2D.Jt(:, closest_z_idx_pcb, t_idx);
        r_space_PCB = grid2D.rq(:, 1);
        
        % --- プロット作成 ---
        figure('Name', ['1D Profile Comparison at t=' num2str(t_target) 'us'], 'Color', 'w', 'Visible', 'off'); 
        
        yyaxis left
        plot(r_space_PCB, profile_PCB, '-b', 'LineWidth', 1.5);
        ylabel(PCB.dataType, 'FontSize', 12);
        ax = gca; ax.YColor = 'b'; grid on;
        
        yyaxis right
        plot(r_space_SXR, profile_SXR, '-r', 'LineWidth', 1.5);
        % ラベルも動的に変更
        ylabel(['SXR Intensity (EE', num2str(target_EE_idx), ') [a.u.]'], 'FontSize', 12);
        ax = gca; ax.YColor = 'r';
        
        xlabel('r (m)', 'FontSize', 12);
        title({['Comparison at t = ' num2str(t_target) ' \mus'], ...
               ['Cut at z \approx ' num2str(target_z_val, '%.4f') ' m']}, 'FontSize', 14);
        xlim([0.1, 0.3])
        legend({'PCB', ['SXR (EE', num2str(target_EE_idx), ')']}, 'Location', 'best');
        
        pathname_png = getenv('SXR_RECONSTRUCTED_DIR');
        foldername_png = strcat(pathname_png,SXR.directory,'/',num2str(date),'/shot',num2str(shot));
        
        if ~exist(foldername_png, 'dir')
            mkdir(foldername_png);
        end

        filename_png = strcat('/pcb_sxr_r_', PCB.dataType, '_EE', num2str(target_EE_idx), '_', num2str(t_target) ,'us.png');
        saveas(gcf,strcat(foldername_png,filename_png));
        close(gcf); 

        % --- X点基準の相対プロット処理 ---
        [~, xPointList] = get_axis_x_multi(grid2D, data2D, PCB);
        [~, t_idx] = min(abs(data2D.trange - t_target));
        r_xp = xPointList.r(t_idx);
        z_xp = xPointList.z(t_idx);

        if isnan(z_xp), target_z = 0; else, target_z = z_xp; end
        
        [~, z_idx_pcb] = min(abs(grid2D.zq(1,:) - target_z));
        p_pcb_rel = data2D.Jt(:, z_idx_pcb, t_idx);
        
        [~, z_idx_sxr] = min(abs(z_space_SXR2 - target_z));
        p_sxr_rel = EE_target(:, z_idx_sxr); % ここもEE_targetを使用
        
        r_orig_PCB = grid2D.rq(:, 1);
        r_orig_SXR = linspace(range(5), range(6), size(EE_target,1))';
        
        if ~isnan(r_xp)
            r_rel_PCB = r_orig_PCB - r_xp;
            r_rel_SXR = r_orig_SXR - r_xp;
        else
            p_pcb_rel = []; p_sxr_rel = []; r_rel_PCB = []; r_rel_SXR = [];
            return;
        end
        
    catch ME
        fprintf('Error in plot_pcb_sxr_r: %s\n', ME.message);
    end
end
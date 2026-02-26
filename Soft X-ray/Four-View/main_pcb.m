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

% Google SpreadsheetのIDとエクスポートURLを構築
    
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

            plot_psi(PCB, pathname);


            % profile off
            % profile viewer
        end
    end

    % [B_r,B_t,B_rt,b] = get_guide_field_ratio2(PCB,pathname);

    
    % [B_reconnection] = get_B_rec_FRC(PCB,pathname);
    % fprintf('Shot %d: B_reconnection = %.3e T\n', PCB.shot(1), B_reconnection);

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


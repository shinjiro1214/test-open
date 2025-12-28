%%%%%%%%%%%%全オペレーションにおける、下流領域内側におけるPCBデータを時間or合体でプロットしている%%%%%%%%%%%%%%%% pcb_guideと同じことしてるけどこっちのほうがいい。
clearvars -except saved_answer

addpath '/Users/shohgookazaki/Documents/GitHub/test-open/pcb_experiment';
addpath '/Users/shohgookazaki/Documents/MATLAB/inputsdlg_v2.3.2'
addpath '/Users/shohgookazaki/Documents/matlab/common';

run define_path.m

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%edit here %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xaxis = 2; % 1: merging ratio, 2: time
xpointdata = 1 % 1: Et, 2: Et/Jt, 3: dB/dt, 4: Bt, 5: Br, 6: Bz)
area = 1; %1: xpoint, 2: downstream inward
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 250205 Case-I
% datelist = [250205, 250205, 250205, 250205, 250205];
% IDXlistlist = [5:7 23:25;
%                 26:31;
%                 33:38;
%                 40:45;
%                 9 15 16 NaN NaN NaN];
% chargelist = [30; 28; 26; 24; 20];

% 250206 Case-O
% datelist = [250206, 250206, 250206, 250206];
% IDXlistlist = [3:7;8:11 13;14 16:19;20 21 23 NaN NaN];% shot 2, 12, 15, 22は変
% chargelist = [30; 28; 26; 24];


%エラー回避
doCheck = 0;

dataType = 1;
PCB.chtype = 1;
PCB.restart = 0;  % Check if 'true' was selected (index 1)

PCB.xpointdata = xpointdata;

FIG.start = 460;
FIG.end = 500;

DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);



num_op = numel(IDXlistlist(:,1));
colors = lines(num_op); % 色の設定
figure; hold on;
for op = 1:num_op
    date = datelist(op);
    T=searchlog(T,'date',date);
    if isnan(T.shot(1))
        T(1, :) = [];
    end
    
    IDXlist = IDXlistlist(op,:);
    IDXlist = IDXlist(~isnan(IDXlist));
    
    n_data=numel(IDXlist);%計測データ数
    % shotlist=T.a039(IDXlist);
    shotlist = [T.a039(IDXlist), T.a040(IDXlist)];
    % tfshotlist=T.a039_TF(IDXlist);
    tfshotlist = [T.a039_TF(IDXlist), T.a040_TF(IDXlist)];
    EFlist=T.EF_A_(IDXlist);
    TFlist=T.TF_kV_(IDXlist);
    dtacqlist=39.*ones(n_data,1);
    
    
    % trange=400:600;%【input】計算時間範囲
    % n=50; %【input】rz方向のメッシュ数
    PCB.trange=400:600;%【input】計算時間範囲
    PCB.n=40; %【input】rz方向のメッシュ数
    
    all_data = zeros(n_data,numel(PCB.trange));
    all_merging_ratios = zeros(n_data, numel(PCB.trange));
    
    for i=1:n_data
        % dtacq_num=dtacqlist;
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
        
        
        [grid2D, data2D] = process_PCBdata_280ch(PCB, pathname);
        merging_ratio = get_merging_ratio(data2D, grid2D, PCB.trange);
        
        if area == 1
            all_data(i,:) =xpointplot(grid2D, data2D,PCB);
        elseif area == 2
            all_data(i,:) =dsplot(grid2D, data2D,PCB);
        end
        
        mask = (PCB.trange >= FIG.start) & (PCB.trange <= FIG.end);
        merging_ratio(~mask) = NaN;
        all_merging_ratios(i, :) = merging_ratio; % 配列に保存
        
        % [I_TF,x,aquisition_rate] = get_TF_current(PCB,pathname);
    end
    
    % 平均値と標準誤差の計算
    qmerge = prctile(all_merging_ratios, [10 90],1);
    iqrmerge = qmerge(2,:)-qmerge(1,:);
    filtered_merge = all_merging_ratios;
    filtered_merge(filtered_merge < qmerge(1,:)-1.5*iqrmerge | filtered_merge > qmerge(2,:)+1.5*iqrmerge) = NaN;
    mean_merging_ratio = mean(filtered_merge, 1, 'omitnan');
    std_merging_ratio = std(filtered_merge, 0, 1, 'omitnan');
    stderr_merging_ratio = std_merging_ratio ./ sqrt(sum(~isnan(filtered_merge), 1));
    
    all_mean_data = mean(all_data,1,'omitnan');
    std_mean = std(all_data, 0, 1, 'omitnan');
    stderr_mean = std_mean ./ sqrt(sum(~isnan(all_data),1));
    
    t = FIG.start:FIG.end;
    x = mean_merging_ratio;  % x軸データ
    y = all_mean_data;
    xerr = stderr_merging_ratio;
    yerr = stderr_mean;
    
    
    if xaxis == 1
        errorbar(x, y, yerr, 'vertical', 'ko', 'LineWidth', 1.2,'HandleVisibility', 'off','Color', colors(op,:));
        errorbar(x, y, xerr,'horizontal', 'ko', 'LineWidth', 1.2,'HandleVisibility', 'off','Color', colors(op,:));
        plot(x, y, '-ko', 'LineWidth', 1.2,'Color', colors(op,:));
        xlim([0 100])
        % xlim([FIG.start FIG.end]);
        % xlabel('time[s]');
        xlabel('Merging ratio [%]');
        
        hold on;
    elseif xaxis == 2
        y = y(FIG.start-400:FIG.end-400);
        yerr = yerr(FIG.start-400:FIG.end-400);
        errorbar(t, y, yerr, 'vertical', 'ko', 'LineWidth', 1.2,'HandleVisibility', 'off','Color', colors(op,:));
        plot(t, y, '-ko', 'LineWidth', 1.2,'Color',colors(op,:));
        xlim([FIG.start FIG.end]);
        xlabel('time[s]');
        
        hold on;
    end
    
    
end
% 凡例の追加
if xpointdata == 1
    ylim([-2.5e2 2e2]);
    ylabel('Et[V/m]');
elseif xpointdata == 4
    ylabel('Bt[T]')
    ylim([-0.1 0.1])
elseif xpointdata == 5
    ylabel('Br[T]');
    ylim([-0.1 0.1])
elseif xpointdata == 6
    ylabel('Bz[T]');
    ylim([-0.1 0.1])
end

legend(arrayfun(@(x) sprintf('Charge %d kV', chargelist(x)), 1:num_op, 'UniformOutput', false), 'Location', 'Best');
hold off;
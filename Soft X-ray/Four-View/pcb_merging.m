
clearvars -except saved_answer

addpath '/Users/shohgookazaki/Documents/GitHub/test-open/pcb_experiment';
addpath '/Users/shohgookazaki/Documents/MATLAB/inputsdlg_v2.3.2'
addpath '/Users/shohgookazaki/Documents/matlab/common';

run define_path.m
%%%%%%%%%%%%%%%%%%%%%%%%
%200ch用新規pcbプローブのみでの磁気面（Bz）
%dtacqのshot番号を直接指定る場合
%%%%%%%%%%%%%%%%%%%%%%%%


%エラー回避
doCheck = 0;

dataType = 1;
PCB.chtype = 1;

%%%%実験オペレーションの取得
name = 'Input';
prompt = {'Date:', 'Shot number:', 'a039(not necessary)', 'doCheck:', 'Restart:', 'Data type:','doxpointplot:','xpointdata(1:Et、2:Et/Jt、3:dB/dt):'};
formats = struct('type', {}, 'style', {}, 'items', {}, 'format', {}, 'limits', {}, 'size', {});

if exist('saved_answer', 'var')
    defaultanswer = saved_answer;
else
    defaultanswer = {[], '', [], 1, 1, 1, 1,[]}; % 適切なデフォルト値をセット
end

formats(1,1).type = 'edit';
formats(1,1).format = 'integer';
formats(1,1).size = [100 20];


formats(2,1).type = 'edit';
formats(2,1).format = 'text';
formats(2,1).size = [100 20];

formats(3,1).type = 'edit';
formats(3,1).format = 'integer';
formats(3,1).size = [100 20];

formats(4,1).type = 'list';
formats(4,1).style = 'popupmenu';
formats(4,1).items = {'false', 'true'};
formats(4,1).format = 'integer';  % Change to integer
formats(4,1).size = [100 20];

formats(5,1).type = 'list';
formats(5,1).style = 'popupmenu';
formats(5,1).items = {'false', 'true'};
formats(5,1).format = 'integer';  % Change to integer
formats(5,1).size = [100 20];

formats(6,1).type = 'list';
formats(6,1).style = 'popupmenu';
formats(6,1).items = {'psi', 'Bz', 'Bt', 'Br','Jt', 'Jz','Jr','Et', 'lBl','dBzdt','dBtdt','dBrdt','dBdt_magnetitude','B_parallel','dB_parallel_dt', 'curvature', 'Bt_th','Lamor','JxBr','JxBt','JxBz','absJxB','Vcurvature','VdeltaB'};
formats(6,1).format = 'integer';
formats(6,1).size = [100 20];

formats(7,1).type = 'list';
formats(7,1).style = 'popupmenu';
formats(7,1).items = {'false', 'true'};
formats(7,1).format = 'integer';  % Change to integer
formats(7,1).size = [100 20];

formats(8,1).type = 'edit';
formats(8,1).format = 'integer';
formats(8,1).size = [100 20];

[answer, canceled] = inputsdlg(prompt, name, formats);



if isempty(answer)
    return
end

if ~canceled
    % インデックスから文字列を取得
    date = answer{1};  % Already an integer
    IDXlist_str = answer{2};
    IDXlist = str2num(IDXlist_str);  % Already an integer
    a039 = answer{3};  % Already an integer
    doCheck = answer{4}-1;  % Check if 'true' was selected (index 1)
    PCB.restart = answer{5}-1;  % Check if 'true' was selected (index 1)
    dataType = formats(6,1).items{answer{6}};
    doxpointplot = answer{7}-1;
    xpointdata = answer{8};
    
    saved_answer = answer;
end

PCB.xpointdata = xpointdata;

FIG.start = 460;
FIG.end = 500;

DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);

if ~isempty(date) && ~isempty(IDXlist)
    T=searchlog(T,'date',date);
    if isnan(T.shot(1))
        T(1, :) = [];
    end
    n_data=numel(IDXlist);%計測データ数
    % shotlist=T.a039(IDXlist);
    shotlist = [T.a039(IDXlist), T.a040(IDXlist)];
    % tfshotlist=T.a039_TF(IDXlist);
    tfshotlist = [T.a039_TF(IDXlist), T.a040_TF(IDXlist)];
    EFlist=T.EF_A_(IDXlist);
    TFlist=T.TF_kV_(IDXlist);
    dtacqlist=39.*ones(n_data,1);
elseif ~isempty(a039)
    T=searchlog(T,'a039',a039);
    n_data = numel(a039);
    shotlist = [T.a039,T.a040];
    tfshotlist = [T.a039,T.a040];
    EFlist = T.EF_A_;
    TFlist = T.TF_kV_;
    dtacqlist=39.*ones(n_data,1);
    date = T.date;
    IDXlist = T.shot;
end

% trange=400:600;%【input】計算時間範囲
% n=50; %【input】rz方向のメッシュ数
PCB.trange=400:600;%【input】計算時間範囲
PCB.n=40; %【input】rz方向のメッシュ数
PCB.start = 55; %plot開始時間-400

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
    if doCheck
        check_signal(PCB, pathname);
    elseif doxpointplot
        [grid2D, data2D] = process_PCBdata_280ch(PCB, pathname);
        merging_ratio = get_merging_ratio(data2D, grid2D, PCB.trange);

        all_data(i,:) = xpointplot(grid2D, data2D,PCB);

        mask = (PCB.trange >= FIG.start) & (PCB.trange <= FIG.end);
        merging_ratio(~mask) = NaN; 
        all_merging_ratios(i, :) = merging_ratio; % 配列に保存
    end

    % [I_TF,x,aquisition_rate] = get_TF_current(PCB,pathname);
end

if true
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
    
    x = mean_merging_ratio;  % x軸データ
    y = all_mean_data;
    xerr = stderr_merging_ratio; 
    yerr = stderr_mean;

    figure;
    hold
    errorbar(x, y, yerr, 'vertical', 'ko', 'LineWidth', 1.2,'HandleVisibility', 'off');
    errorbar(x, y, xerr,'horizontal', 'ko', 'LineWidth', 1.2,'HandleVisibility', 'off');
    plot(x, y, '-ko', 'LineWidth', 1.2);
    xlim([0 100])
    % xlim([FIG.start FIG.end]);
    % xlabel('time[s]');
    xlabel('Merging ratio [%]');
    if xpointdata == 1
        ylim([-3e2 3e2]);
        ylabel('Et[V/m]');
    elseif xpointdata == 2
        % ylim([-10 40]);
        ylim([-0.5 1])
        ylabel('Et/Jt[mΩ/m]')
    end
    hold off;
end


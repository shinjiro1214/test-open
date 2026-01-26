pathname.fourier=getenv('fourier_path');%fourierのmd0（データックのショットが入ってる）までのpath
pathname.rawdata=getenv('rawdata_path');%dtacqのrawdataの保管場所
pathname.pre_processed_directory = getenv('pre_processed_directory_path');%計算結果の保存先（どこでもいい）

currentFile = mfilename('fullpath');
[currentDir, ~, ~] = fileparts(currentFile);
[parentDir, ~, ~] = fileparts(currentDir);
addpath(parentDir);

pcbDataDir = getenv('pre_processed_directory_path');

date = '250305';
shotList_2kV = [48:51, 56, 58:65, 67:69];%2kV
% shotList_3kV = [23:32, 34:46];%3kV
shotList_3kV = [23:32, 36:38,40:46];%3kV
% shotList_4kV = [8,9,18:21];%4kV
shotList_4kV = 18:21;%4kV
% dateList = {date_4kV,date_5kV,date_6kV};
shotList = {shotList_2kV,shotList_3kV,shotList_4kV};
% shotList = {shotList_4kV};

t = 451:480;
[Br_mean,Br_std] = deal(zeros(numel(shotList),numel(t)));
trange = t-399;
% j = 1;
figure;hold on;
for i = 1:numel(shotList)
    shotList_tmp = cell2mat(shotList(i));
    Br_t = zeros(numel(shotList_tmp),numel(t));
    dirPath = fullfile(pcbDataDir,date);
    j=1;
    for k = shotList_tmp
        % disp(k);
        % PCB = get_PCB_data(str2double(date),k,0,0);
        % [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
        load([dirPath,num2str(k,'%03i'),'.mat'],'data2D','grid2D');
        Br_t(j,:) = get_Br_time(grid2D,data2D,trange);
        % Br_t(j,:) = get_Br_time(grid2D,data2D,trange) .* 0.75;
        plot(t,Br_t(j,:));
        j = j+1;
    end
    Br_mean(i,:) = mean(Br_t,'omitmissing');
    Br_std(i,:) = std(Br_t,'omitmissing');
end

figure; hold on;
for i = 1:numel(shotList)
    t_plot = t;
    % switch i
    %     case 1
    %         t_plot = t;
    %     case 2
    %         t_plot = t-3;
    %     case 3
    %         t_plot = t-5;
    % end
    errorbar(t_plot,Br_mean(i,:),Br_std(i,:));
end
legend({'TF=2kV','TF=3kV','TF=4kV'});
xlabel('Time [us]');
ax=gca;ax.FontSize=18;
ylabel('Reconection magnetic field [T]');
grid on;

% [~,idxTF40] = ismember([7:9,28:30],shotList);
% [~,idxTF35] = ismember([10:12,25:27],shotList);
% [~,idxTF30] = ismember([13:15,22:24],shotList);
% [~,idxTF25] = ismember(16:21,shotList);

% BrM40 = mean(Br_t(idxTF40,:),'omitmissing');
% BrD40 = std(Br_t(idxTF40,:),'omitmissing');
% BrM35 = mean(Br_t(idxTF35,:),'omitmissing');
% BrD35 = std(Br_t(idxTF35,:),'omitmissing');
% BrM30 = mean(Br_t(idxTF30,:),'omitmissing');
% BrD30 = std(Br_t(idxTF30,:),'omitmissing');
% BrM25 = mean(Br_t(idxTF25,:),'omitmissing');
% BrD25 = std(Br_t(idxTF25,:),'omitmissing');
% figure;
% errorbar(t,BrM25,BrD25);hold on;
% errorbar(t,BrM30,BrD30);
% errorbar(t,BrM35,BrD35);
% errorbar(t,BrM40,BrD40);
% % legend({'TF=2.5kV','TF=3kV','TF=3.5kV','TF=4kV'});
% legend({'GFR = 4.5','GFR = 5.5','GFR = 6.5','GFR = 7.5'});

% xlabel('Time [us]');
% ax=gca;ax.FontSize=18;
% ylabel('Reconection magnetic field [T]');

% figure;hold on;
% TF = 2.5:0.5:4;
% % 4.5583    5.2295    6.4095    7.6048 GFR
% % 0.1367    0.1569    0.1923    0.2281 Bt
% Bt = 1e3 * [0.1367    0.1569    0.1923    0.2281];
% % TF = [270 330 390 450]/10;
% t_idx = find(t==467);
% Br_M = [BrM25(t_idx) BrM30(t_idx) BrM35(t_idx) BrM40(t_idx)];
% Br_D = [BrD25(t_idx) BrD30(t_idx) BrD35(t_idx) BrD40(t_idx)];
% % p = polyfit(Bt, Br_M, 1);
% a = Bt(:) \ Br_M(:);
% x_line = linspace(0, max(Bt), 100); 
% % y_line = polyval(p, x_line);
% y_line = a * x_line;

% errorbar(Bt,Br_M,Br_D,'LineWidth',3);
% plot(x_line, y_line, 'r-', 'LineWidth', 2);
% xlabel('Toroidal magnetic field [mT]');ylabel('Reconnection magnetic field [mT]');
% ax=gca;ax.FontSize=18;
% % xlim([130 230]);ylim([0 Inf]);
% xlim([0 230]);ylim([0 Inf]);
% % xlim([2.3 4.2]);


function B_reconnection = get_Br_time(grid2D,data2D,trange)
    % trange = data2D.trange;
    Br = data2D.Br;
    rq = grid2D.rq;
    zq = grid2D.zq;
    [magAxisList,xPointList] = get_axis_x_multi(grid2D,data2D);
    % Br_t = zeros(1,20);
    B_reconnection = NaN(1,numel(trange));
    % t = 461:480;
    m = 1;
    for i = trange
        % time = trange(i);
        % [magaxis,xpoint] = get_axis_x(grid2D,data2D,time);
        magaxis.r = magAxisList.r(:,i);
        magaxis.z = magAxisList.z(:,i);
        xpoint.r = xPointList.r(:,i);
        xpoint.z = xPointList.z(:,i);
        % if numel(magaxis.r) == 2
        if magaxis.z(1)~=magaxis.z(2) && ~isnan(magaxis.r(1))
            range_r = rq(:,1)>=min(magaxis.r)&rq(:,1)<=max(magaxis.r);
            range_z = zq(1,:)>=min(magaxis.z)&zq(1,:)<=max(magaxis.z);
            % 値の取り方は考えた方がいい、Btは理論値でもよさそう
            Br_tmp = Br(:,:,i);
            if sum(range_r) == 1
                Br_mean = Br_tmp(range_r,range_z);
            else
                % Br_mean = mean(Br_tmp(range_r,range_z));
                Br_mean = mean(Br_tmp(range_r,range_z));
            end
            Br1 = max(Br_mean);
            Br2 = abs(min(Br_mean));
            B_reconnection(1,m) = min([Br1,Br2]);
        % elseif ~isnan(magaxis.r(1)) && ~isnan(xpoint.r)
        %     range = rq>=min(magaxis.r(1),xpoint.r)&rq<=max(magaxis.r(1),xpoint.r)&zq>=min(magaxis.z(1),xpoint.z)&zq<=max(magaxis.z(1),xpoint.z);
        %     Br_tmp = Br(:,:,i);
        %     % B_reconnection(1,m) = mean([max(Br_tmp(range),[],'all'),abs(min(Br_tmp(range),[],"all"))]);
        %     B_reconnection(1,m) = min([max(Br_tmp(range),[],'all'),abs(min(Br_tmp(range),[],"all"))]);
        else
            B_reconnection(1,m) = NaN;
        end
        m=m+1;
    end
end

function PCB = get_PCB_data(date,shotIDX,start,dt)
    PCB.type = 1;
    % PCB.doOverwrite = false;
    PCB.doOverwrite = true;
    PCB.trange = 400:800;
    PCB.n = 40;
    PCB.start = start-399;
    PCB.dt = dt;

    % date = 230828;shotIDX=41;
    % date = 230830;shotIDX=37;
    % date = 240111;shotIDX=29;
    % date = 240828;shotIDX=5;
    % date = 250314;shotIDX=55;
    DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
    T=getTS6log(DOCID);
    node='date';
    % date=230714;
    T=searchlog(T,node,date);
    IDXlist = find(T.shot==shotIDX);
    % IDXlist= 1; %[5:50 52:55 58:59];%[4:6 8:11 13 15:19 21:23 24:30 33:37 39:40 42:51 53:59 61:63 65:69 71:74];
    % n_data=numel(IDXlist);%計測データ数
    shotlist_a039 =T.a039(IDXlist);
    shotlist_a040 = T.a040(IDXlist);
    shotlist = [shotlist_a039, shotlist_a040];
    tfshotlist_a039 =T.a039_TF(IDXlist);
    tfshotlist_a040 =T.a040_TF(IDXlist);
    tfshotlist = [tfshotlist_a039, tfshotlist_a040];
    EFlist=T.EF_A_(IDXlist);
    TFlist=T.TF_kV_(IDXlist);
    % dtacqlist=39.*ones(n_data,1);
    PCB.idx = shotIDX;
    PCB.shot=shotlist;
    PCB.tfshot=tfshotlist;
    if PCB.shot == PCB.tfshot
        PCB.tfshot = [0,0];
    end
    PCB.i_EF=EFlist;
    PCB.TF=TFlist;
    PCB.date = date;
end
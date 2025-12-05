close all

addpath('/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View');
dirPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
shotList = 7:30;
t = 441:480;
Et_t = zeros(numel(shotList),numel(t));
Jt_t = zeros(numel(shotList),numel(t));
Br_t = zeros(numel(shotList),numel(t));
trange = t-399;
j = 1;
% figure;hold on;
for i = shotList
    load([dirPath,num2str(i,'%03i'),'.mat'],'data2D','grid2D');
    % Et_t_tmp = -1*get_Et_time(grid2D,data2D,trange);
    % Et_t(j,:) = Et_t_tmp - Et_t_tmp(1);
    Et_t(j,:) = -1*get_Et_time(grid2D,data2D,trange);
    Br_t(j,:) = get_Br_time(grid2D,data2D,trange);
    Jt_t(j,:) = -1*get_Jt_time(grid2D,data2D,trange);
    % plot(t,Et_t(j,:));
    j = j+1;
end
[~,idxTF40] = ismember([7:9,28:30],shotList);
[~,idxTF35] = ismember([10:12,25:27],shotList);
[~,idxTF30] = ismember([13:15,22:24],shotList);
[~,idxTF25] = ismember(16:21,shotList);

EtM40 = mean(Et_t(idxTF40,:),'omitmissing');
EtD40 = std(Et_t(idxTF40,:),'omitmissing');
EtM35 = mean(Et_t(idxTF35,:),'omitmissing');
EtD35 = std(Et_t(idxTF35,:),'omitmissing');
EtM30 = mean(Et_t(idxTF30,:),'omitmissing');
EtD30 = std(Et_t(idxTF30,:),'omitmissing');
EtM25 = mean(Et_t(idxTF25,:),'omitmissing');
EtD25 = std(Et_t(idxTF25,:),'omitmissing');
% figure;errorbar(t,EtM25,EtD25);hold on;
% errorbar(t,EtM30,EtD30);
% errorbar(t,EtM35,EtD35);
% errorbar(t,EtM40,EtD40);
% legend({'TF=2.5kV','TF=3kV','TF=3.5kV','TF=4kV'});
% xlabel('Time [us]');
% ax=gca;ax.FontSize=18;
% ylabel('Reconnection electric field [V/t]');

BrM40 = mean(Br_t(idxTF40,:),'omitmissing');
BrD40 = std(Br_t(idxTF40,:),'omitmissing');
BrM35 = mean(Br_t(idxTF35,:),'omitmissing');
BrD35 = std(Br_t(idxTF35,:),'omitmissing');
BrM30 = mean(Br_t(idxTF30,:),'omitmissing');
BrD30 = std(Br_t(idxTF30,:),'omitmissing');
BrM25 = mean(Br_t(idxTF25,:),'omitmissing');
BrD25 = std(Br_t(idxTF25,:),'omitmissing');
% figure;
% errorbar(t,BrM25,BrD25);hold on;
% errorbar(t,BrM30,BrD30);
% errorbar(t,BrM35,BrD35);
% errorbar(t,BrM40,BrD40);
% legend({'TF=2.5kV','TF=3kV','TF=3.5kV','TF=4kV'});
% xlabel('Time [us]');
% ax=gca;ax.FontSize=18;
% ylabel('Reconection magnetic field [T]');

JtM40 = mean(Jt_t(idxTF40,:),'omitmissing');
JtD40 = std(Jt_t(idxTF40,:),'omitmissing');
JtM35 = mean(Jt_t(idxTF35,:),'omitmissing');
JtD35 = std(Jt_t(idxTF35,:),'omitmissing');
JtM30 = mean(Jt_t(idxTF30,:),'omitmissing');
JtD30 = std(Jt_t(idxTF30,:),'omitmissing');
JtM25 = mean(Jt_t(idxTF25,:),'omitmissing');
JtD25 = std(Jt_t(idxTF25,:),'omitmissing');
% figure;errorbar(t,JtM25,JtD25);hold on;
% errorbar(t,JtM30,JtD30);
% errorbar(t,JtM35,JtD35);
% errorbar(t,JtM40,JtD40);
% legend({'TF=2.5kV','TF=3kV','TF=3.5kV','TF=4kV'});
% xlabel('Time [us]');
% ax=gca;ax.FontSize=18;
% ylabel('Toroidal current density [A/m^2]');


% figure;tiledlayout(1,3);
% Bt = 1e3 * [0.1367    0.1569    0.1923    0.2281];
% nexttile;
% t_idx = find(t==468);
% Et_M = [EtM25(t_idx) EtM30(t_idx) EtM35(t_idx) EtM40(t_idx)];
% Et_D = [EtD25(t_idx) EtD30(t_idx) EtD35(t_idx) EtD40(t_idx)];
% errorbar(Bt,Et_M,Et_D,'LineWidth',3);
% xlabel('B_t [mT]');ylabel('E_\theta [V/m]');
% ax=gca;ax.FontSize=18;
% xlim([130 230]);
% nexttile;
% t_idx = find(t==467);
% Br_M = 1e3*[BrM25(t_idx) BrM30(t_idx) BrM35(t_idx) BrM40(t_idx)];
% Br_D = 1e3*[BrD25(t_idx) BrD30(t_idx) BrD35(t_idx) BrD40(t_idx)];
% errorbar(Bt,Br_M,Br_D,'LineWidth',3);
% xlabel('B_t [mT]');ylabel('B_{rec} [mT]');
% ax=gca;ax.FontSize=18;
% xlim([130 230]);
% nexttile;
% t_idx = find(t==467);
% Jt_M = [JtM25(t_idx) JtM30(t_idx) JtM35(t_idx) JtM40(t_idx)];
% Jt_D = [JtD25(t_idx) JtD30(t_idx) JtD35(t_idx) JtD40(t_idx)];
% errorbar(Bt,Jt_M,Jt_D,'LineWidth',3);
% xlabel('B_t [mT]');ylabel('J_t [A/m^2]');
% ax=gca;ax.FontSize=18;
% xlim([130 230]);

figure;tiledlayout(1,2);
Bt = 1e3 * [0.1367    0.1569    0.1923    0.2281];
nexttile;
t_idx = find(t==468);
Jt_M = [JtM25(t_idx) JtM30(t_idx) JtM35(t_idx) JtM40(t_idx)];
Jt_D = [JtD25(t_idx) JtD30(t_idx) JtD35(t_idx) JtD40(t_idx)];
errorbar(Bt,Jt_M,Jt_D,'LineWidth',3);
xlabel('B_t [mT]');ylabel('J_t [A/m^2]');
ax=gca;ax.FontSize=18;
xlim([130 230]);
nexttile;
t_idx = find(t==468);
Et_M = [EtM25(t_idx) EtM30(t_idx) EtM35(t_idx) EtM40(t_idx)];
Et_D = [EtD25(t_idx) EtD30(t_idx) EtD35(t_idx) EtD40(t_idx)];
errorbar(Bt,Et_M,Et_D,'LineWidth',3);
xlabel('B_t [mT]');ylabel('E_t [V/m]');
ax=gca;ax.FontSize=18;
xlim([130 230]);
% nexttile;
% t_idx = find(t==467);
% Br_M = 1e3*[BrM25(t_idx) BrM30(t_idx) BrM35(t_idx) BrM40(t_idx)];
% Br_D = 1e3*[BrD25(t_idx) BrD30(t_idx) BrD35(t_idx) BrD40(t_idx)];
% errorbar(Bt,Br_M,Br_D,'LineWidth',3);
% xlabel('B_t [mT]');ylabel('B_{rec} [mT]');
% ax=gca;ax.FontSize=18;
% xlim([130 230]);


function Et_t = get_Et_time(grid2D,data2D,trange)
    [~,xPointList] = get_axis_x_multi(grid2D,data2D);
    Et_t = zeros(1,numel(trange));
    % t = 461:480;
    m = 1;
    for i = trange
        idxR = knnsearch(grid2D.rq(:,1),xPointList.r(i));
        idxZ = knnsearch(grid2D.zq(1,:).',xPointList.z(i));
        Et_t(m) = mean(data2D.Et(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),max(1,idxZ-1):min(numel(grid2D.zq(1,:)),idxZ+1),i),'all');
        m = m+1;
    end
end


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
                Br_mean = mean(Br_tmp(range_r,range_z));
            end
            Br1 = max(Br_mean);
            Br2 = abs(min(Br_mean));
            B_reconnection(1,m) = min([Br1,Br2]);
        elseif ~isnan(magaxis.r(1))
            range = rq>=min(magaxis.r(1),xpoint.r)&rq<=max(magaxis.r(1),xpoint.r)&zq>=min(magaxis.z(1),xpoint.z)&zq<=max(magaxis.z(1),xpoint.z);
            Br_tmp = Br(:,:,i);
            B_reconnection(1,m) = mean([max(Br_tmp(range),[],'all'),abs(min(Br_tmp(range),[],"all"))]);
        else
            B_reconnection(1,m) = NaN;
        end
        m=m+1;
    end
end


function Jt_t = get_Jt_time(grid2D,data2D,trange)
    [~,xPointList] = get_axis_x_multi(grid2D,data2D);
    Jt_t = zeros(1,numel(trange));
    % t = 461:480;
    m = 1;
    for i = trange
        idxR = knnsearch(grid2D.rq(:,1),xPointList.r(i));
        idxZ = knnsearch(grid2D.zq(1,:).',xPointList.z(i));
        Jt_t(m) = mean(data2D.Jt(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),max(1,idxZ-1):min(numel(grid2D.zq(1,:)),idxZ+1),i),'all');
        m = m+1;
    end
end
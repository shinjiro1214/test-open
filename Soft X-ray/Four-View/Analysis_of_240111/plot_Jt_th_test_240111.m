
addpath('/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View');
dirPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
shotList = 7:30;
t = 461:470;
Br_t = zeros(numel(shotList),numel(t));
delta_t = zeros(numel(shotList),numel(t));
trange = t-399;
mu0 = 1.26e-6;
j = 1;
% figure;hold on;
for i = shotList
    load([dirPath,num2str(i,'%03i'),'.mat'],'data2D','grid2D');
    % Br_t(j,:) = get_Br_time(grid2D,data2D,trange);
    Br_t(j,:) = get_Br_time(grid2D,data2D,trange);
    delta_t(j,:) = get_delta_time(grid2D,data2D,trange);
    % plot(t,Br_t(j,:));
    % plot(t,delta_t(j,:));
    j = j+1;
end
[~,idxTF40] = ismember([7:9,28:30],shotList);
[~,idxTF35] = ismember([10:12,25:27],shotList);
[~,idxTF30] = ismember([13:15,22:24],shotList);
[~,idxTF25] = ismember(16:21,shotList);

BrM40 = mean(Br_t(idxTF40,:),'omitmissing');
BrD40 = std(Br_t(idxTF40,:),'omitmissing');
BrM35 = mean(Br_t(idxTF35,:),'omitmissing');
BrD35 = std(Br_t(idxTF35,:),'omitmissing');
BrM30 = mean(Br_t(idxTF30,:),'omitmissing');
BrD30 = std(Br_t(idxTF30,:),'omitmissing');
BrM25 = mean(Br_t(idxTF25,:),'omitmissing');
BrD25 = std(Br_t(idxTF25,:),'omitmissing');

deltaM40 = mean(delta_t(idxTF40,:),'omitmissing');
deltaD40 = std(delta_t(idxTF40,:),'omitmissing');
deltaM35 = mean(delta_t(idxTF35,:),'omitmissing');
deltaD35 = std(delta_t(idxTF35,:),'omitmissing');
deltaM30 = mean(delta_t(idxTF30,:),'omitmissing');
deltaD30 = std(delta_t(idxTF30,:),'omitmissing');
deltaM25 = mean(delta_t(idxTF25,:),'omitmissing');
deltaD25 = std(delta_t(idxTF25,:),'omitmissing');

JtM40 = BrM40./deltaM40./mu0;
JtM35 = BrM35./deltaM35./mu0;
JtM30 = BrM30./deltaM30./mu0;
JtM25 = BrM25./deltaM25./mu0;
JtD40 = (BrM40./deltaM40).*sqrt((BrD40./BrM40).^2 + (deltaD40./deltaM40).^2)./mu0;
JtD35 = (BrM35./deltaM35).*sqrt((BrD35./BrM35).^2 + (deltaD35./deltaM35).^2)./mu0;
JtD30 = (BrM30./deltaM30).*sqrt((BrD30./BrM30).^2 + (deltaD30./deltaM30).^2)./mu0;
JtD25 = (BrM25./deltaM25).*sqrt((BrD25./BrM25).^2 + (deltaD25./deltaM25).^2)./mu0;

figure;errorbar(t,JtM25,JtD25);hold on;
errorbar(t,JtM30,JtD30);
errorbar(t,JtM35,JtD35);
errorbar(t,JtM40,JtD40);
legend({'TF=2.5kV','TF=3kV','TF=3.5kV','TF=4kV'});

xlabel('Time [us]');
ax=gca;ax.FontSize=18;
ylabel('Toroidal current density [A/m^2]');

TF = 2.5:0.5:4;
% 4.5583    5.2295    6.4095    7.6048 GFR
% 0.1367    0.1569    0.1923    0.2281 Bt
Bt = 1e3 * [0.1367    0.1569    0.1923    0.2281];
GFR = Bt ./ 30;
% TF = [270 330 390 450]/10;
t_idx = find(t==470);
Jt_M = [JtM25(t_idx) JtM30(t_idx) JtM35(t_idx) JtM40(t_idx)];
Jt_D = [JtD25(t_idx) JtD30(t_idx) JtD35(t_idx) JtD40(t_idx)];
% figure;errorbar(Bt,Jt_M,Jt_D,'LineWidth',3);
% xlabel('Toroidal magnetic field [mT]');ylabel('Toroidal current density [A/m^3]');
% ax=gca;ax.FontSize=18;
% xlim([130 230]);
figure;errorbar(GFR,Jt_M,Jt_D,'LineWidth',3);
xlabel('Guide field ratio');ylabel('Toroidal current density [A/m^3]');
ax=gca;ax.FontSize=18;
% xlim([2.3 4.2]);


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
        elseif ~isnan(magaxis.r(1))
            range = rq>=min(magaxis.r(1),xpoint.r)&rq<=max(magaxis.r(1),xpoint.r)&zq>=min(magaxis.z(1),xpoint.z)&zq<=max(magaxis.z(1),xpoint.z);
            Br_tmp = Br(:,:,i);
            % B_reconnection(1,m) = mean([max(Br_tmp(range),[],'all'),abs(min(Br_tmp(range),[],"all"))]);
            B_reconnection(1,m) = min([max(Br_tmp(range),[],'all'),abs(min(Br_tmp(range),[],"all"))]);
        else
            B_reconnection(1,m) = NaN;
        end
        m=m+1;
    end
end

function delta_t = get_delta_time(grid2D,data2D,trange)
% シート幅の時間発展を出す関数
% 半値全幅で計算？
% deltaをX点近傍で切り出し（0以上？）
% ガウスフィッティングをかける
    [~,xPointList] = get_axis_x_multi(grid2D,data2D);
    delta_t = zeros(1,numel(trange));
    % t = 461:480;
    m = 1;
    for i = trange
        idxR = knnsearch(grid2D.rq(:,1),xPointList.r(i));
        % idxZ = knnsearch(grid2D.zq(1,:).',xPointList.z(i));
        Jt_z = -1 * mean(data2D.Jt(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),:,i));
        % idxZ = find(abs(grid2D.zq(1,:))<=0.05 & Jt_z>=0);
        idxZ = find(abs(grid2D.zq(1,:))<=0.1);
        % figure;plot(grid2D.zq(1,idxZ),Jt_z(idxZ),'*');
        f = fit(grid2D.zq(1,idxZ).',Jt_z(idxZ).','gauss1','Lower',[0 -0.08 0], 'Upper',[inf 0.08 inf]);
        % figure;plot(f,grid2D.zq(1,idxZ),Jt_z(idxZ),'*');
        delta_t(m) = 2 * sqrt(log(2)) * f.c1;
        m = m+1;
    end
end
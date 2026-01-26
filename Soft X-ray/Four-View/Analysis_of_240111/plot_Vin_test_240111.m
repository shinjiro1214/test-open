dirPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
shotList = 7:30;
t = 460:475;
% t = 466;
Vin_t = zeros(numel(shotList),numel(t));
trange = t-399;
j = 1;
figure;hold on;
for i = shotList
    load([dirPath,num2str(i,'%03i'),'.mat'],'data2D','grid2D');
    % Vin_t_tmp = get_Vin_time(grid2D,data2D,trange);
    % Vin_t(j,:) = Vin_t_tmp - Vin_t_tmp(1);
    Vin_t(j,:) = get_Vin_time(grid2D,data2D,trange);
    plot(t,Vin_t(j,:));
    j = j+1;
end
[~,idxTF40] = ismember([7:9,28:30],shotList);
[~,idxTF35] = ismember([10:12,25:27],shotList);
[~,idxTF30] = ismember([13:15,22:24],shotList);
[~,idxTF25] = ismember(16:21,shotList);

VinM40 = mean(Vin_t(idxTF40,:),'omitmissing');
VinD40 = std(Vin_t(idxTF40,:),'omitmissing');
VinM35 = mean(Vin_t(idxTF35,:),'omitmissing');
VinD35 = std(Vin_t(idxTF35,:),'omitmissing');
VinM30 = mean(Vin_t(idxTF30,:),'omitmissing');
VinD30 = std(Vin_t(idxTF30,:),'omitmissing');
VinM25 = mean(Vin_t(idxTF25,:),'omitmissing');
VinD25 = std(Vin_t(idxTF25,:),'omitmissing');
figure;
errorbar(t,VinM25,VinD25);hold on;
errorbar(t,VinM30,VinD30);
errorbar(t,VinM35,VinD35);
errorbar(t,VinM40,VinD40);
legend({'TF=2.5kV','TF=3kV','TF=3.5kV','TF=4kV'});
xlabel('Time [us]');
ax=gca;ax.FontSize=18;
ylabel('Inflow speed [m/s]');
xlim([460 468]);

TF = 2.5:0.5:4;
% 4.5583    5.2295    6.4095    7.6048 GFR
% 0.1367    0.1569    0.1923    0.2281 Bt
Bt = 1e3 * [0.1367    0.1569    0.1923    0.2281];
GFR = Bt ./ 30;
% TF = [270 330 390 450]/10;
t_idx = find(t==468);
Vin_M = [VinM25(t_idx) VinM30(t_idx) VinM35(t_idx) VinM40(t_idx)];
Vin_D = [VinD25(t_idx) VinD30(t_idx) VinD35(t_idx) VinD40(t_idx)];
% figure;errorbar(Bt,Vin_M,Vin_D,'LineWidth',3);
% xlabel('Toroidal magnetic field [mT]');ylabel('Toroidal current density [A/m^3]');
% ax=gca;ax.FontSize=18;
% xlim([130 230]);
figure;errorbar(GFR,Vin_M,Vin_D,'LineWidth',3);
xlabel('Guide field ratio');ylabel('Inflow speed [m/s]');
ax=gca;ax.FontSize=18;
% xlim([2.3 4.2]);


function Vin_t = get_Vin_time(grid2D,data2D,trange)
    % % trange = data2D.trange;
    % Br = data2D.Br;
    % rq = grid2D.rq;
    % zq = grid2D.zq;
    [magAxisList,~] = get_axis_x_multi(grid2D,data2D);
    % Vin_t = zeros(1,20);
    Vin_t = NaN(1,numel(trange));
    % t = 461:480;
    m = 1;
    for i = trange
        % time = trange(i);
        % [magaxis,xpoint] = get_axis_x(grid2D,data2D,time);
        magaxis.r = magAxisList.r(:,i);
        magaxis.z = magAxisList.z(:,i);
        % xpoint.r = xPointList.r(:,i);
        % xpoint.z = xPointList.z(:,i);
        % if numel(magaxis.r) == 2
        if  magaxis.z(1)~=magaxis.z(2) && ~isnan(magaxis.r(1))
            % Vin_t(1,m) = mean(magAxisList.psi(:,i));
            Vin_t(1,m) = mean([magAxisList.z(1,i+1)-magAxisList.z(1,i),-1*(magAxisList.z(2,i+1)-magAxisList.z(2,i))])/1e-6;
        else
            Vin_t(1,m) = NaN;
        end
        m=m+1;
    end
end
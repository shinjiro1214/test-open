addpath('/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View');
dirPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
shotList = 7:30;
t = 441:480;
Et_t = zeros(numel(shotList),numel(t));
trange = t-399;
j = 1;
figure;hold on;
for i = shotList
    load([dirPath,num2str(i,'%03i'),'.mat'],'data2D','grid2D');
    % Et_t_tmp = -1*get_Et_time(grid2D,data2D,trange);
    % Et_t(j,:) = Et_t_tmp - Et_t_tmp(1);
    Et_t(j,:) = -1*get_Et_time(grid2D,data2D,trange);
    plot(t,Et_t(j,:));
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
figure;errorbar(t,EtM25,EtD25);hold on;
errorbar(t,EtM30,EtD30);
errorbar(t,EtM35,EtD35);
errorbar(t,EtM40,EtD40);
legend({'TF=2.5kV','TF=3kV','TF=3.5kV','TF=4kV'});

xlabel('Time [us]');
ax=gca;ax.FontSize=18;
ylabel('Reconnection electric field [V/t]');

Et_t = [t;EtM40;EtD40];
writematrix(Et_t.','/Users/shinjirotakeda/Downloads/Et_t.xlsx','Range','A2');

% TF = 2.5:0.5:4;
% 4.5583    5.2295    6.4095    7.6048 GFR
% 0.1367    0.1569    0.1923    0.2281 Bt
Bt = 1e3 * [0.1367    0.1569    0.1923    0.2281];
% TF = [270 330 390 450]/10;
t_idx = find(t==468);
Et_M = [EtM25(t_idx) EtM30(t_idx) EtM35(t_idx) EtM40(t_idx)];
Et_D = [EtD25(t_idx) EtD30(t_idx) EtD35(t_idx) EtD40(t_idx)];
figure;hold on;
errorbar(Bt,Et_M,Et_D,'LineWidth',3);
a = Bt(:) \ Et_M(:);
x_line = linspace(0, max(Bt), 100); 
% y_line = polyval(p, x_line);
y_line = a * x_line;
plot(x_line, y_line, 'r-', 'LineWidth', 2);
xlabel('Toroidal magnetic field [mT]');ylabel('Reconnection electric field [V/m]');
ax=gca;ax.FontSize=18;
% xlim([130 230]);
xlim([0 230]);ylim([0 Inf]);
% xlim([2.3 4.2]);


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
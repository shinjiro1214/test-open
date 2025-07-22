filePath = 'filterTransmittance.xlsx';
T = readcell(filePath);
label = T(1,:);
data = readmatrix(filePath);

% E_q = 
% data_q = 

E = data(:,1);
data1 = data(:,2);
data2 = data(:,3) * 2;
data3 = data(:,4);
% data4 = data(:,5);

data1(data1<=1e-2) = 1e-2;
data2(data2<=1e-2) = 1e-2;
data3(data3<=1e-2) = 1e-2;

% close all
label = label(2:4);
figure;
set(gca, 'YScale', 'log');  % 明示的に右y軸を対数に
set(gca, 'XScale', 'log');  % x軸も対数に（loglogに対応）
hold on
% yyaxis left
plot(E,data1,'LineWidth',2);
plot(E,data2,'LineWidth',2);
plot(E,data3,'LineWidth',2);
% plot(E,data4,'m-','LineWidth',2);
ylabel('Transmittance [a.u.]');
% yyaxis right
% ylim([0 0.3])
legend(label,'Location','northwest');
xlabel('Photon energy [eV]');
ylabel('Transmittance [a.u.]');
xlim([0 200]);
ax = gca;
ax.FontSize = 18;

% set(gca, 'YScale', 'log');  % 明示的に右y軸を対数に
% set(gca, 'XScale', 'log');  % x軸も対数に（loglogに対応）
% T = readmatrix('/Users/shinjirotakeda/Library/CloudStorage/OneDrive-TheUniversityofTokyo/研究資料/フィルタ/Filters_231107.xlsx');
% T(:,3) = T(:,3) * 3;
% T(T<=1e-2) = 1e-2;
% for i = 2:4
%     plot(T(:,1),T(:,i),'LineWidth',2);
%     if i==2
%         hold on;
%     end
% end
% % xlabel('Photon energy [eV]');
% ylabel('Transmittance');
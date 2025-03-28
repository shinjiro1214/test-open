%シングルスリット、フィルタなし実験データから
%マルチスリット、フィルタあり(傾き角度設定可)をシミュレーション

clear all
% close all
addpath '/Users/rsomeya/Documents/lab/matlab/common';
run define_path.m

%【Input】
shot_num = 11215;%shot番号11215,11227
frame_n = 5;%frame総数
frame_target = 5;%解析frame番号
ch_target = 6;%解析ch
angle = -2.5;%フィルタ傾け角度-2.5,0,2.5,5
x_type = 'px';%x軸('nm','px')

%校正データ
calib_filename = [pathname.TE,'/smile.txt'];
calib = importdata(calib_filename);
reference=[530.4758,529.81891,528.00853,527.40393];

%実験データ
filename = [pathname.TE,'/Andor/','shot_',num2str(shot_num),'.asc'];
data_raw = importdata(filename);
data = zeros(1017,size(data_raw,2),frame_n);
for i = 1:size(data,3)
    data(:,:,i) = data_raw(1+size(data,1)*(i-1):size(data,1)*i,:);
    % figure
    % contour(data(:,:,i))
end
px_ax = repmat(data(:,1,1),1,size(calib,1));%波長方向pixel軸
data = data(:,2:end,:);

%波長校正
lambda_ax = zeros(size(px_ax,1),size(calib,1));
for i =1:size(calib,1)
    p = polyfit(calib(i,:),reference,3);
    lambda_ax(:,i) = polyval(p,px_ax(:,i));%波長軸
end

%マルチスリット模擬data
idx_ax_left = (201-491.5)+px_ax;
idx_ax_right = (775-491.5)+px_ax;
lambda_ax_left = -0.0114*(201-491.5)+lambda_ax;
lambda_ax_right = -0.0114*(775-491.5)+lambda_ax;
switch x_type
    case 'nm'
        x_ax = lambda_ax;
        x_ax_left = lambda_ax_left;
        x_ax_right = lambda_ax_right;
    case 'px'
        x_ax = px_ax;
        x_ax_left = idx_ax_left;
        x_ax_right = idx_ax_right;
end

% data = data - mean(data(1:10,ch_target,frame_target));

figure
legStr = "";
hs = char.empty;
h = plot(x_ax_left(:,ch_target),data(:,ch_target,frame_target),'g','LineWidth',2);
[hs,legStr] = make_legend(hs,h,legStr,"Slit1");
hold on
h = plot(x_ax(:,ch_target),data(:,ch_target,frame_target),'r','LineWidth',2);
[hs,legStr] = make_legend(hs,h,legStr,"Slit2");
hold on
h = plot(x_ax_right(:,ch_target),data(:,ch_target,frame_target),'b','LineWidth',2);
[hs,legStr] = make_legend(hs,h,legStr,"Slit3");
legend(hs,legStr)
switch x_type
    case 'nm'
        xlim([min(lambda_ax,[],"all") max(lambda_ax,[],"all")])
        xlabel('Wavelength [nm]')
    case 'px'
        xlim([min(px_ax,[],"all") max(px_ax,[],"all")])
        xlabel('Pixel Number')
end
ylabel('Strength [a.u.]')
% ylim([0 inf])
ylim([0 3E4])
ax = gca;
ax.FontSize = 22;
hold off

for i=1:size(angle,2)
    figure
    legStr = "";
    hs = char.empty;
    savename = [pathname.TE,'/mat/',num2str(angle(i)),'degrees.mat'];
    load(savename,'lambda_transmit','transmit')
    transmit_interp = interp1(lambda_transmit,transmit,lambda_ax(:,ch_target),'spline');
    negative = find(transmit_interp<0);
    transmit_interp(negative) = zeros(size(negative));
    data_filtered = data(:,ch_target,frame_target).*transmit_interp;
    % yyaxis right
    % h = plot(x_ax(:,ch_target),transmit_interp,'LineWidth',2);
    % [hs,legStr] = make_legend(hs,h,legStr,num2str(angle(i)) + "°-Transmittance");
    % hold on
    % h = plot(x_ax_left(:,ch_target),transmit_interp,'LineWidth',2);
    % [hs,legStr] = make_legend(hs,h,legStr,num2str(angle(i)) + "°-Transmittance");
    % hold on
    % h = plot(x_ax_right(:,ch_target),transmit_interp,'LineWidth',2);
    % [hs,legStr] = make_legend(hs,h,legStr,num2str(angle(i)) + "°-Transmittance");
    % hold on
    % 
    % yyaxis left
    h = plot(x_ax_left(:,ch_target),data_filtered,'g-','LineWidth',2);
    [hs,legStr] = make_legend(hs,h,legStr,"Slit1");
    hold on
    h = plot(x_ax(:,ch_target),data_filtered,'r-','LineWidth',2);
    [hs,legStr] = make_legend(hs,h,legStr,"Slit2");
    hold on
    h = plot(x_ax_right(:,ch_target),data_filtered,'b-','LineWidth',2);
    [hs,legStr] = make_legend(hs,h,legStr,"Slit3");
    hold on
    legend(hs,legStr)
    switch x_type
        case 'nm'
            xlim([min(lambda_ax,[],"all") max(lambda_ax,[],"all")])
            xlabel('Wavelength [nm]')
        case 'px'
            xlim([min(px_ax,[],"all") max(px_ax,[],"all")])
            xlabel('Pixel Number')
    end
    ylabel('Strength [a.u.]')
    % ylim([0 inf])
    ylim([0 3E4])
    ax = gca;
    ax.FontSize = 22;
    hold off
end
% legend(hs,legStr)
% % xlabel('Wavelength [nm]')
% xlim([1 1024])
% xlabel('Pixel Number')
% % yyaxis left
% % newcolors = ["#000000" "#005AFF" "#03AF7A" "#F6AA00" "#FF4B00"];
% % colororder(newcolors)
% ylabel('Strength [a.u.]')
% ylim([0 inf])
% % yyaxis right
% % newcolors = ["#005AFF" "#03AF7A" "#F6AA00" "#FF4B00"];
% % colororder(newcolors)
% % ylabel('Transimittaince')
% % ylim([0 1.2])
% ax = gca;
% ax.FontSize = 18;
% hold off


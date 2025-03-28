%フィルタ透過特性の入射角依存性実験結果解析

% clear all
close all
addpath '/Users/rsomeya/Documents/lab/matlab/common';
run define_path.m

date = 20240313;
% angle = [-20 -15 -10 -5 -2.5 0 2.5 5 10 15 20];
% angle = [-10 -5 -2.5 0 2.5 5 10];
% angle = [-5 -2.5 0 2.5 5];
angle = [-2.5, 0, 2.5, 5];
x_min = 1;
x_max = 1024;
y_min = 450;
y_max = 510;
idx_ax = linspace(1,1024,1024);
lambda_transmit = -0.0107*idx_ax + 534.3404;
lambda_center = zeros(size(angle,2),1);%フィルタ中心波長
lambda_10_left = zeros(size(angle,2),1);%フィルタ10%左端
lambda_10_right = zeros(size(angle,2),1);%フィルタ10%右端
lambda_50_left = zeros(size(angle,2),1);%フィルタ半値左端
lambda_50_right = zeros(size(angle,2),1);%フィルタ半値右端
lambda_90_left = zeros(size(angle,2),1);%フィルタ90%左端
lambda_90_right = zeros(size(angle,2),1);%フィルタ90%右端
spectra = zeros(1024,size(angle,2));
figure
for i=1:size(angle,2)
    filename = [pathname.TE,'/Andor/',num2str(date),'/', num2str(angle(i)), 'degrees.asc'];
    data = importdata(filename);
    data = data(:,2:end);
    offset = mean(data(1:5,1:5),"all");
    data = data - offset;
    transmit = sum(data(:,y_min:y_max),2);
    [spectrum_max,~] = max(movmean(transmit,3));
    transmit = transmit/spectrum_max;%規格化
    spectra(:,i) = transmit;
    spectrum_movmean = movmean(transmit,5);
    lambda_10_left(i) = lambda_transmit(find(spectrum_movmean>0.1,1,'last'));
    lambda_10_right(i) = lambda_transmit(find(spectrum_movmean>0.1,1,'first'));
    lambda_50_left(i) = lambda_transmit(find(spectrum_movmean>0.5,1,'last'));
    lambda_50_right(i) = lambda_transmit(find(spectrum_movmean>0.5,1,'first'));
    lambda_90_left(i) = lambda_transmit(find(spectrum_movmean>0.9,1,'last'));
    lambda_90_right(i) = lambda_transmit(find(spectrum_movmean>0.9,1,'first'));
    % contour(data(min_x:max_x,min_y:max_y))
    plot(lambda_transmit,transmit,'LineWidth',2)
    hold on
    % denom = 0;
    % for i_x = x_min:x_max
    %     for i_y = y_min:y_max
    %         lambda_center(i) = lambda_center(i) + data(i_x,i_y)*lambda_transmit(i_x);
    %         denom = denom + data(i_x,i_y);
    %     end
    % end
    % lambda_center(i) = lambda_center(i)/denom;
    lambda_center(i) = (lambda_50_left(i) + lambda_50_right(i))/2;
    savename = [pathname.TE,'/mat/',num2str(angle(i)),'degrees.mat'];
    save(savename,'lambda_transmit','transmit')
end
newcolors = ["#FF4B00","#F6AA00","#FFF100","#03AF7A","#4DC4FF","#005AFF","#990099","#000000"];
% newcolors = ["#005AFF" "#03AF7A" "#F6AA00" "#FF4B00"];
colororder(newcolors)
xline(529.05,'LineWidth',3)%C VI 529.05nm
xlabel('Wavelength [nm]')
ylabel('Transmittance')
legendCell = strcat(string(num2cell(angle)),'°');
legend(legendCell)
xlim([526 532])
ylim([0 1.2])
ax = gca;
ax.FontSize = 22;
hold off

% figure
% errorbar(angle,lambda_center,lambda_center-lambda_10_left,lambda_10_right-lambda_center,'bo-','LineWidth',2)
% hold on
% errorbar(angle,lambda_center,lambda_center-lambda_50_left,lambda_50_right-lambda_center,'go-','LineWidth',2)
% hold on
% errorbar(angle,lambda_center,lambda_center-lambda_90_left,lambda_90_right-lambda_center,'ro-','LineWidth',2)
% yline(529.05,'LineWidth',3)%C VI 529.05nm
% xlabel('Filter Tilt Angle [°]')
% ylabel('Filter Center Wavelength [nm]')
% % ylim([528.9 529.3])
% % ylim([527.5 530.5])
% ax = gca;
% ax.FontSize = 18;
% hold off

% figure
% contourf(angle',lambda_transmit',spectra,10)
% yline(529.05,'LineWidth',3)%C VI 529.05nm
% xlabel('Filter Tilt Angle [°]')
% ylabel('Filter Center Wavelength [nm]')
% colorbar
% colormap("jet")
% clim([0 1])
% ylim([527 531])
% ax = gca;
% ax.FontSize = 18;
% hold off

figure
plot(angle,lambda_center,'bo-','LineWidth',3,'MarkerSize',10)
yline(529.05,'LineWidth',3)%C VI 529.05nm
xlabel('Filter Tilt Angle [°]')
ylabel('Filter Center Wavelength [nm]')
ylim([528.9 529.3])
ax = gca;
ax.FontSize = 22;
hold off

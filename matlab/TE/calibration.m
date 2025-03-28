ubclear all
close all
addpath '/Users/rsomeya/Documents/lab/matlab/common';
run define_path.m

%--【Input】----
date = 240313;%校正実験日
calib_CHlist = [49];%校正CH番号リスト
plot_cont = true;%等高線図を描画
cal_CH1 = true;%1st用CH位置特定
cal_1st = true;%1stピーク特定
cal_CH2 = true;%2nd用CH位置特定
cal_2nd = true;%2ndピーク特定
cal_CH3 = true;%2nd用CH位置特定
cal_3rd = true;%2ndピーク特定
save_fit = false;%フィッティングをpngで保存
save_cal = false;%校正結果をmatで保存
N_CH = 1;%校正CH総数(基本的には1)
width = 6;%チャンネル切り取り幅
th_ratio = 0.8;
l_mov = 15;

filename = [pathname.TE,'/Andor/20',num2str(date),'/CVI_filter_49CH_Neon_lamp.asc'];

for m = 1:size(calib_CHlist,2)
    calib_CH = calib_CHlist(m);%校正CH番号
    cal_filename = [pathname.TE,'/Andor/20',num2str(date),'/CVI_filter_49CH_Neon_lamp.asc'];%ICCDファイル名
    lambda_1st = 529.8189;%第1ピーク波長
    lambda_2nd = 528.0086;%第2ピーク波長
    lambda_3rd = 530.4758;%第3ピーク波長

    Min_CH_CH1 = 440;
    % Min_CH_CH1 = round(855.1-21.45*mod(calib_CH-1,32))-12;%第1ピーク用チャンネル軸切り取り最小値(1~1024)
    Min_L_CH1 = 370;%第1ピーク用波長軸切り取り最小値(1~1024)
    Min_L_CH2 = 520;%第2ピーク用波長軸切り取り最小値(1~1024)
    Min_L_CH3 = 330;%第2ピーク用波長軸切り取り最小値(1~1024)
    Max_CH_CH1 = Min_CH_CH1+80;%第1ピーク用チャンネル軸切り取り最大値(1~1024)
    Min_CH_CH2 = Min_CH_CH1;%第2ピーク用チャンネル軸切り取り最小値(1~1024)
    Min_CH_CH3 = Min_CH_CH1;%第2ピーク用チャンネル軸切り取り最小値(1~1024)

    Max_CH_CH2 = Max_CH_CH1;%第2ピーク用チャンネル軸切り取り最大値(1~1024)
    Max_CH_CH3 = Max_CH_CH1;%第3ピーク用チャンネル軸切り取り最大値(1~1024)
    Max_L_CH1 = Min_L_CH1+100;%第1ピーク用波長軸切り取り最大値(1~1024)
    Max_L_CH2 = Min_L_CH2+100;%第2ピーク用波長軸切り取り最大値(1~1024)
    Max_L_CH3 = Min_L_CH3+50;%第3ピーク用波長軸切り取り最大値(1~1024)

    Min_L_L1 = Min_L_CH1;%第1ピーク用波長軸切り取り最小値(1~1024)
    Max_L_L1 = Max_L_CH1;%第1ピーク用波長軸切り取り最大値(1~1024)
    Min_L_L2 = Min_L_CH2;%第2ピーク用波長軸切り取り最小値(1~1024)
    Max_L_L2 = Max_L_CH2;%第2ピーク用波長軸切り取り最大値(1~1024)
    Min_L_L3 = Min_L_CH3;%第3ピーク用波長軸切り取り最小値(1~1024)
    Max_L_L3 = Max_L_CH3;%第3ピーク用波長軸切り取り最大値(1~1024)

    %-----校正ファイル読み込み----
    cal_data = importdata(cal_filename);
    cal_data = cal_data(:,2:1025);%データ1列目は通し番号なので切り捨てる

    %----配列定義----
    ax_pixel = transpose(linspace(1,1024,1024));%1~1024の整数軸
    cal_result = zeros(3,4);%校正結果

    %-----ICCD生データをプロット-----
    if plot_cont
        figure
        contour(ax_pixel,ax_pixel,cal_data)
        xlabel('Pixel number in CH direction')
        ylabel('Pixel number in Lambda direction')
        hold off
    end

    figure('Position',[300 50 1200 800],'visible','on')
    %-------第1ピーク用CH位置特定------
    if cal_CH1
        spectrum_CH1 = ...
            transpose(sum(cal_data(Min_L_CH1:Max_L_CH1,Min_CH_CH1:Max_CH_CH1),1));
        % Offset_CH1 = mean(spectrum_CH1(1:3,1));
        Offset_CH1 = ...
            mean(cal_data([Min_L_CH1-5:Min_L_CH1, Max_L_CH1:Max_L_CH1+5],...
            [Min_CH_CH1-5:Min_CH_CH1, Max_CH_CH1:Max_CH_CH1+5]),'all') * (Max_L_CH1 - Min_L_CH1 + 1);
        Y_CH1 = spectrum_CH1 - Offset_CH1;
        f_CH1 = fit(ax_pixel(Min_CH_CH1:Max_CH_CH1),Y_CH1,'gauss1');
        % figure
        subplot(2,3,1)
        plot(f_CH1,ax_pixel(Min_CH_CH1:Max_CH_CH1),Y_CH1)
        title(['Detecting CH position' newline 'for the 1st peak'])
        legend('off')
        xlabel('Pixel number in CH direction')
        ylabel('Intensity [cnt]')
        Coef_CH1 = coeffvalues(f_CH1);
        cal_result(1,1) = sort(Coef_CH1(1,2),'descend');%縦位置を大きい順で取得
    end

    %-------第2ピーク用CH位置特定------
    if cal_CH2
        spectrum_CH2 = ...
            transpose(sum(cal_data(Min_L_CH2:Max_L_CH2,Min_CH_CH2:Max_CH_CH2),1));
        % Offset_CH2 = mean(spectrum_CH2(1:5,1));
        Offset_CH2 = ...
            mean(cal_data([Min_L_CH2-5:Min_L_CH2, Max_L_CH2:Max_L_CH2+5],...
            [Min_CH_CH2-5:Min_CH_CH2, Max_CH_CH2:Max_CH_CH2+5]),'all') * (Max_L_CH2 - Min_L_CH2 + 1);
        Y_CH2 = spectrum_CH2 - Offset_CH2;
        % Y_CH2 = movmean(Y_CH2,15);
        f_CH2 = fit(ax_pixel(Min_CH_CH2:Max_CH_CH2),Y_CH2,'gauss1');
        % figure
        subplot(2,3,2)
        plot(f_CH2,ax_pixel(Min_CH_CH2:Max_CH_CH2),Y_CH2)
        title(['Detecting CH position' newline 'for the 2nd peak'])
        legend('off')
        xlabel('Pixel number in CH direction')
        ylabel('Intensity [cnt]')
        Coef_CH2 = coeffvalues(f_CH2);
        cal_result(2,1) = sort(Coef_CH2(1,2),'descend');%縦位置を大きい順で取得
    end

    %-------第3ピーク用CH位置特定------
    if cal_CH3
        spectrum_CH3 = ...
            transpose(sum(cal_data(Min_L_CH3:Max_L_CH3,Min_CH_CH3:Max_CH_CH3),1));
        % Offset_CH3 = mean(spectrum_CH3(1:5,1));
        Offset_CH3 = ...
            mean(cal_data([Min_L_CH3-5:Min_L_CH3, Max_L_CH3:Max_L_CH3+5],...
            [Min_CH_CH3-5:Min_CH_CH3, Max_CH_CH3:Max_CH_CH3+5]),'all') * (Max_L_CH3 - Min_L_CH3 + 1);
        Y_CH3 = spectrum_CH3 - Offset_CH3;
        % Y_CH3 = movmean(Y_CH3,15);
        f_CH3 = fit(ax_pixel(Min_CH_CH3:Max_CH_CH3),Y_CH3,'gauss1');
        % figure
        subplot(2,3,3)
        plot(f_CH3,ax_pixel(Min_CH_CH3:Max_CH_CH3),Y_CH3)
        title(['Detecting CH position' newline 'for the 3rd peak'])
        legend('off')
        xlabel('Pixel number in CH direction')
        ylabel('Intensity [cnt]')
        Coef_CH3 = coeffvalues(f_CH3);
        cal_result(3,1) = sort(Coef_CH3(1,2),'descend');%縦位置を大きい順で取得
    end

    %-------波長位置特定--------
    %第1Neピーク検出
    if cal_1st
        % figure
        subplot(2,3,4)
        Min_CH_L1 = round(cal_result(1,1)-width);%チャンネル軸切り取り最小値
        Max_CH_L1 = round(cal_result(1,1)+width);%チャンネル軸切り取り最大値
        spectrum_L1 = ...
            sum(cal_data(Min_L_L1:Max_L_L1,Min_CH_L1:Max_CH_L1),2);
        % Offset_L1 = mean(spectrum_L1(1:10,1));
        Offset_L1 = ...
            mean(cal_data([Min_L_L1-30:Min_L_L1, Max_L_L1:Max_L_L1+30],...
            [Min_CH_L1-30:Min_CH_L1, Max_CH_L1:Max_CH_L1+30]),'all') * (Max_CH_L1 - Min_CH_L1 + 1);
        Y_L1 = spectrum_L1 - Offset_L1;
        Y_L1 = movmean(Y_L1,l_mov);
        MAX1 = max(Y_L1);
        S1 = [ax_pixel(Min_L_L1:Max_L_L1) Y_L1]; %[波長,強度]
        s1 = size(S1);
        deleted_S1 = zeros(1,2);
        ori_S1 = S1;
        j = 1;
        while j < s1(1)+1 %SNの悪いデータを除く
            if S1(j,2) < MAX1*th_ratio
                deleted_S1 = cat(1,deleted_S1,S1(j,:));
                S1(j,:) = [];
            else
                j = j+1;
            end
            s1 = size(S1);
        end
        % f_L1 = fit(ax_pixel(Min_L_L1:Max_L_L1),Y_L1,'gauss1');
        % plot(f_L1,ax_pixel(Min_L_L1:Max_L_L1),Y_L1)
        f_L1 = fit(S1(:,1),S1(:,2),'gauss1');
        plot(f_L1,'r-',ori_S1(:,1),ori_S1(:,2),'.w');
        hold on
        plot(S1(:,1),S1(:,2),'bo');
        hold on
        plot(deleted_S1(:,1),deleted_S1(:,2),'kx');
        hold on
        yline(MAX1*th_ratio,'g','LineWidth',3);
        title(['Detecting Lambda position' newline 'for the 1st peak'])
        legend('off')
        xlabel('Pixel number in Lambda direction')
        ylabel('Intensity [cnt]')
        xlim([Min_L_L1 Max_L_L1])
        Coef_L1 = coeffvalues(f_L1);
        cal_result(1,2) = Coef_L1(1,2);%第1ピークを取得
        cal_result(1,3) = Coef_L1(1,3);%第1ピークσ(装置関数)を取得
        cal_result(1,4) = Coef_L1(1,1)/1e5;%相対感度を取得
    end

    %第2Neピーク検出
    if cal_2nd
        % figure
        subplot(2,3,5)
        Min_CH_L2 = round(cal_result(2,1)-width);%チャンネル軸切り取り最小値
        Max_CH_L2 = round(cal_result(2,1)+width);%チャンネル軸切り取り最大値
        spectrum_L2 = ...
            sum(cal_data(Min_L_L2:Max_L_L2,Min_CH_L2:Max_CH_L2),2);
        % Offset_L2 = mean(spectrum_L2(1:10,1));
        Offset_L2 = ...
            mean(cal_data([Min_L_L2-30:Min_L_L2, Max_L_L2:Max_L_L2+30],...
            [Min_CH_L2-30:Min_CH_L2, Max_CH_L2:Max_CH_L2+30]),'all') * (Max_CH_L2 - Min_CH_L2 + 1);
        Y_L2 = spectrum_L2 - Offset_L2;
        Y_L2 = movmean(Y_L2,l_mov);
        MAX2 = max(Y_L2);
        S2 = [ax_pixel(Min_L_L2:Max_L_L2) Y_L2]; %[波長,強度]
        s1 = size(S2);
        deleted_S2 = zeros(1,2);
        ori_S2 = S2;
        j = 1;
        while j < s1(1)+1 %SNの悪いデータを除く
            if S2(j,2) < MAX2*th_ratio
                deleted_S2 = cat(1,deleted_S2,S2(j,:));
                S2(j,:) = [];
            else
                j = j+1;
            end
            s1 = size(S2);
        end
        % f_L2 = fit(ax_pixel(Min_L_L2:Max_L_L2),Y_L2,'gauss1');
        % plot(f_L2,ax_pixel(Min_L_L2:Max_L_L2),Y_L2)
        f_L2 = fit(S2(:,1),S2(:,2),'gauss1');
        plot(f_L2,'r-',ori_S2(:,1),ori_S2(:,2),'.w');
        hold on
        plot(S2(:,1),S2(:,2),'bo');
        hold on
        plot(deleted_S2(:,1),deleted_S2(:,2),'kx');
        hold on
        yline(MAX2*th_ratio,'g','LineWidth',3);
        title(['Detecting Lambda position' newline 'for the 2nd peak'])
        legend('off')
        xlabel('Pixel number in Lambda direction')
        ylabel('Intensity [cnt]')
        xlim([Min_L_L2 Max_L_L2])
        Coef_L2 = coeffvalues(f_L2);
        cal_result(2,2) = Coef_L2(1,2);%第2ピークを取得
        cal_result(2,3) = Coef_L2(1,3);%第2ピークσ(装置関数)を取得
        cal_result(2,4) = Coef_L2(1,1)/1e5;%相対感度を取得
        px2nm = -(lambda_1st - lambda_2nd)/(cal_result(1,2) - cal_result(2,2));%px2nmを計算
    end

    %第3Neピーク検出
    if cal_3rd
        % figure
        subplot(2,3,6)
        Min_CH_L3 = round(cal_result(3,1)-width);%チャンネル軸切り取り最小値
        Max_CH_L3 = round(cal_result(3,1)+width);%チャンネル軸切り取り最大値
        spectrum_L3 = ...
            sum(cal_data(Min_L_L3:Max_L_L3,Min_CH_L3:Max_CH_L3),2);
        % Offset_L3 = mean(spectrum_L3(1:10,1));
        Offset_L3 = ...
            mean(cal_data([Min_L_L3-30:Min_L_L3, Max_L_L3:Max_L_L3+30],...
            [Min_CH_L3-30:Min_CH_L3, Max_CH_L3:Max_CH_L3+30]),'all') * (Max_CH_L3 - Min_CH_L3 + 1);
        Y_L3 = spectrum_L3 - Offset_L3;
        Y_L3 = movmean(Y_L3,l_mov);
        MAX3 = max(Y_L3);
        S3 = [ax_pixel(Min_L_L3:Max_L_L3) Y_L3]; %[波長,強度]
        s1 = size(S3);
        deleted_S3 = zeros(1,2);
        ori_S3 = S3;
        j = 1;
        while j < s1(1)+1 %SNの悪いデータを除く
            if S3(j,2) < MAX3*th_ratio
                deleted_S3 = cat(1,deleted_S3,S3(j,:));
                S3(j,:) = [];
            else
                j = j+1;
            end
            s1 = size(S3);
        end
        % f_L3 = fit(ax_pixel(Min_L_L3:Max_L_L3),Y_L3,'gauss1');
        % plot(f_L3,ax_pixel(Min_L_L3:Max_L_L3),Y_L3)
        f_L3 = fit(S3(:,1),S3(:,2),'gauss1');
        plot(f_L3,'r-',ori_S3(:,1),ori_S3(:,2),'.w');
        hold on
        plot(S3(:,1),S3(:,2),'bo');
        hold on
        plot(deleted_S3(:,1),deleted_S3(:,2),'kx');
        hold on
        yline(MAX3*th_ratio,'g','LineWidth',3);
        title(['Detecting Lambda position' newline 'for the 2nd peak'])
        legend('off')
        xlabel('Pixel number in Lambda direction')
        ylabel('Intensity [cnt]')
        xlim([Min_L_L3 Max_L_L3])
        Coef_L3 = coeffvalues(f_L3);
        cal_result(3,2) = Coef_L3(1,2);%第2ピークを取得
        cal_result(3,3) = Coef_L3(1,3);%第2ピークσ(装置関数)を取得
        cal_result(3,4) = Coef_L3(1,1)/1e5;%相対感度を取得
    end

    sgtitle(['CH',num2str(calib_CH)])

    if save_fit
        if not(exist(num2str(date),'dir'))
            mkdir(num2str(date));
        end
        saveas(gcf,[num2str(date),'/fit_CH',num2str(calib_CH),'.png'])
        hold off
        close
    end
    % cal_result
    Lambda = [lambda_1st lambda_2nd lambda_3rd];
    figure
    x_poly = cal_result(1:3,2);
    y_poly = Lambda(1:3);
    p = polyfit(x_poly,y_poly,2);
    x2 = linspace(1,1024,1024);
    y2 = polyval(p,x2);
    plot(x_poly,y_poly,'o',x2,y2)
    % calib_output = [calib_CH cal_result(1,1:5)]
    if cal_1st && save_cal
        if not(exist(num2str(date),'dir'))
            mkdir(num2str(date));
        end
        save([num2str(date),'/calibation',num2str(calib_CH),'.mat'],'calib_output')
    end
end
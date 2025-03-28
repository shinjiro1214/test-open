%ドップラープローブ分光器校正用

close all
addpath '/Users/rsomeya/Documents/lab/matlab/common';
run define_path.m

%--【Input】----
date = 240607;%校正実験日
calib_CHlist = [19];%校正CH番号リスト
plot_cont = false;%等高線図を描画
cal_CH1 = true;%1st用CH位置特定
cal_1st = true;%1stピーク特定
save_fit = false;%フィッティングをpngで保存
save_cal = false;%校正結果をmatで保存
w_CH = 3;%チャンネル切り取り幅
th_ratio = 0.8;
l_mov = 15;

lambda0 = 480.602;%使用スペクトル(nm)

for m = 1:size(calib_CHlist,2)
    calib_CH = calib_CHlist(m);%校正CH番号
    % if calib_CH < 33
    %     cal_group = 'red';
    % elseif calib_CH < 65
    %     cal_group = 'white';
    % elseif calib_CH < 97
    %     cal_group = 'orange';
    % elseif calib_CH < 129
    %     cal_group = 'green';
    % end
    if calib_CH < 33
        cal_group = 'red';
    elseif calib_CH < 65
        cal_group = 'orange';
    elseif calib_CH < 97
        cal_group = 'green';
    else
        warning('calib CH is wrong.')
        return
    end
    cal_filename = [pathname.IDSP,'/',num2str(date),'/Xe ',cal_group,' dial 482.6nm.asc'];%ICCDファイル名

    lambda_1st = 480.7019;%第1ピーク波長
    switch cal_group
        case {'red','white'}
            lambda_2nd = 482.9708;%第2ピーク波長('red','white')強度大
            cal_CH2 = true;%2nd用CH位置特定
            cal_2nd = true;%2ndピーク特定
        case {'orange','green'}
            lambda_2nd = 479.2619;%第2ピーク波長('orange','green')強度小
            cal_CH2 = false;%2nd用CH位置特定
            cal_2nd = false;%2ndピーク特定
    end
    % lambda_3rd = 484.3293;
    switch cal_group
        % case {'red'}
        %     Min_CH_CH1 = round(855.1-21.45*mod(calib_CH-1,32))-12;%第1ピーク用チャンネル軸切り取り最小値(1~1024)
        %     Min_L_CH1 = 800;%第1ピーク用波長軸切り取り最小値(1~1024)
        %     Min_L_CH2 = 300;%第2ピーク用波長軸切り取り最小値(1~1024)
        % case {'white'}
        %     Min_CH_CH1 = round(867-21.92*mod(calib_CH-1,32))-12;%第1ピーク用チャンネル軸切り取り最小値(1~1024)
        %     Min_L_CH1 = 580;%第1ピーク用波長軸切り取り最小値(1~1024)
        %     Min_L_CH2 = 80;%第2ピーク用波長軸切り取り最小値(1~1024)
        % case {'orange'}
        %     Min_CH_CH1 = round(875.8-22.24*mod(calib_CH-1,32))-12;%第1ピーク用チャンネル軸切り取り最小値(1~1024)
        %     Min_L_CH1 = 330;%第1ピーク用波長軸切り取り最小値(1~1024)
        %     Min_L_CH2 = 650;%第2ピーク用波長軸切り取り最小値(1~1024)
        % case {'green'}
        %     % return
        case {'red'}
            Min_CH_CH1 = round(746-21.64*mod(calib_CH-1,32))-12;%第1ピーク用チャンネル軸切り取り最小値(1~1024)
            Min_CH_CH2 = Min_CH_CH1+6;%第2ピーク用チャンネル軸切り取り最小値(1~1024)
            Min_L_CH1 = 700;%第1ピーク用波長軸切り取り最小値(1~1024)
            Min_L_CH2 = 180;%第2ピーク用波長軸切り取り最小値(1~1024)
            Max_L_CH2 = Min_L_CH2+100;%第2ピーク用波長軸切り取り最大値(1~1024)
            th_ratio2 = th_ratio;
        case {'orange'}
            Min_CH_CH1 = round(748-20.96*mod(calib_CH-1,32))-12;%第1ピーク用チャンネル軸切り取り最小値(1~1024)
            Min_CH_CH2 = Min_CH_CH1-6;%第2ピーク用チャンネル軸切り取り最小値(1~1024)
            Min_L_CH1 = 460;%第1ピーク用波長軸切り取り最小値(1~1024)
            Min_L_CH2 = 820;%第2ピーク用波長軸切り取り最小値(1~1024)
            Max_L_CH2 = Min_L_CH2+50;%第2ピーク用波長軸切り取り最大値(1~1024)
            th_ratio2 = 0.5;
        case {'green'}
            Min_CH_CH1 = round(748-21.09*mod(calib_CH-1,32))-12;%第1ピーク用チャンネル軸切り取り最小値(1~1024)
            Min_CH_CH2 = Min_CH_CH1-6;%第2ピーク用チャンネル軸切り取り最小値(1~1024)
            Min_L_CH1 = 210;%第1ピーク用波長軸切り取り最小値(1~1024)
            Min_L_CH2 = 550;%第2ピーク用波長軸切り取り最小値(1~1024)
            Max_L_CH2 = Min_L_CH2+40;%第2ピーク用波長軸切り取り最大値(1~1024)
            th_ratio2 = 0.5;
    end
    Max_CH_CH1 = Min_CH_CH1+24;%第1ピーク用チャンネル軸切り取り最大値(1~1024)
    Max_CH_CH2 = Min_CH_CH2+24;%第2ピーク用チャンネル軸切り取り最大値(1~1024)
    Max_L_CH1 = Min_L_CH1+100;%第1ピーク用波長軸切り取り最大値(1~1024)
    Min_L_L1 = Min_L_CH1;%第1ピーク用波長軸切り取り最小値(1~1024)
    Max_L_L1 = Max_L_CH1;%第1ピーク用波長軸切り取り最大値(1~1024)
    Min_L_L2 = Min_L_CH2;%第2ピーク用波長軸切り取り最小値(1~1024)
    Max_L_L2 = Max_L_CH2;%第2ピーク用波長軸切り取り最大値(1~1024)


    %-----校正ファイル読み込み----
    cal_data = importdata(cal_filename);
    cal_data = cal_data(:,2:1025);%データ1列目は通し番号なので切り捨てる

    %----配列定義----
    ax_pixel = transpose(linspace(1,1024,1024));%1~1024の整数軸

    %-----ICCD生データをプロット-----
    if plot_cont
        figure
        contour(ax_pixel,ax_pixel,cal_data)
        xlabel('Pixel number in CH direction')
        ylabel('Pixel number in Lambda direction')
        hold off
    end

    figure('Position',[300 50 1000 1000],'visible','on')
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
        Coef_CH1 = coeffvalues(f_CH1);
        subplot(2,2,1)
        plot(f_CH1,ax_pixel(Min_CH_CH1:Max_CH_CH1),Y_CH1)
        hold on
        xline(Coef_CH1(1,2),'m','LineWidth',1);
        xlim([Min_CH_CH1 Max_CH_CH1])
        title('Detecting CH position for the 1st peak')
        legend('off')
        xlabel('Pixel number in CH direction')
        ylabel('Intensity [cnt]')
    end

    %-------第2ピーク用CH位置特定------
    if cal_CH2
        spectrum_CH2 = ...
            transpose(sum(cal_data(Min_L_CH2:Max_L_CH2,Min_CH_CH2:Max_CH_CH2),1));
        % Offset_CH2 = mean(spectrum_CH2(1:5,1));
        Offset_CH2 = ...
            mean(cal_data([Min_L_CH2-5:Min_L_CH2, Max_L_CH2:Max_L_CH2+5],...
            [Min_CH_CH2-5:Min_CH_CH2, Max_CH_CH2:Max_CH_CH2+5]),'all') * (Max_L_CH2 - Min_L_CH2 + 1);
        % Offset_CH2 = ...
        %     mean(cal_data(Min_L_CH2:Max_L_CH2,900:1000),'all') * (Max_L_L2 - Min_L_L2 + 1);
        Y_CH2 = spectrum_CH2 - Offset_CH2;
        Y_CH2 = movmean(Y_CH2,15);
        f_CH2 = fit(ax_pixel(Min_CH_CH2:Max_CH_CH2),Y_CH2,'gauss1');
        Coef_CH2 = coeffvalues(f_CH2);
        subplot(2,2,2)
        plot(f_CH2,ax_pixel(Min_CH_CH2:Max_CH_CH2),Y_CH2)
        hold on
        xline(Coef_CH2(1,2),'m','LineWidth',1);
        xlim([Min_CH_CH2 Max_CH_CH2])
        title('Detecting CH position for the 2nd peak')
        legend('off')
        xlabel('Pixel number in CH direction')
        ylabel('Intensity [cnt]')
    end

    %-------波長位置特定--------
    %第1Xeピーク検出
    if cal_1st
        % figure
        subplot(2,2,3)
        Min_CH_L1 = round(Coef_CH1(1,2)-w_CH);%チャンネル軸切り取り最小値
        Max_CH_L1 = round(Coef_CH1(1,2)+w_CH);%チャンネル軸切り取り最大値
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
        title('Detecting Lambda position for the 1st peak')
        legend('off')
        xlabel('Pixel number in Lambda direction')
        ylabel('Intensity [cnt]')
        xlim([Min_L_L1 Max_L_L1])
        Coef_L1 = coeffvalues(f_L1);
        instrument = Coef_L1(1,3);%第1ピークσ(装置関数)を取得
        strength = Coef_L1(1,1)/1e5;%相対感度を取得
    end

    %第2Xeピーク検出
    if cal_2nd
        % figure
        subplot(2,2,4)
        Min_CH_L2 = round(Coef_CH2(1,2)-w_CH);%チャンネル軸切り取り最小値
        Max_CH_L2 = round(Coef_CH2(1,2)+w_CH);%チャンネル軸切り取り最大値
        spectrum_L2 = ...
            sum(cal_data(Min_L_L2:Max_L_L2,Min_CH_L2:Max_CH_L2),2);
        % Offset_L2 = mean(spectrum_L2(1:10,1));
        Offset_L2 = ...
            mean(cal_data(Min_L_L2:Max_L_L2,900:1000),'all') * (Max_CH_L2 - Min_CH_L2 + 1);
        Y_L2 = spectrum_L2 - Offset_L2;
        % Y_L2 = spectrum_L2;
        Y_L2 = movmean(Y_L2,l_mov);
        MAX2 = max(Y_L2);
        S2 = [ax_pixel(Min_L_L2:Max_L_L2) Y_L2]; %[波長,強度]
        s1 = size(S2);
        deleted_S2 = zeros(1,2);
        ori_S2 = S2;
        j = 1;
        while j < s1(1)+1 %SNの悪いデータを除く
            if S2(j,2) < MAX2*th_ratio2
                deleted_S2 = cat(1,deleted_S2,S2(j,:));
                S2(j,:) = [];
            else
                j = j+1;
            end
            s1 = size(S2);
        end
        f_L2 = fit(ax_pixel(Min_L_L2:Max_L_L2),Y_L2,'gauss1');
        plot(f_L2,ax_pixel(Min_L_L2:Max_L_L2),Y_L2)
        f_L2 = fit(S2(:,1),S2(:,2),'gauss1');
        plot(f_L2,'r-',ori_S2(:,1),ori_S2(:,2),'.w');
        hold on
        plot(S2(:,1),S2(:,2),'bo');
        hold on
        plot(deleted_S2(:,1),deleted_S2(:,2),'kx');
        hold on
        yline(MAX2*th_ratio2,'g','LineWidth',3);
        title('Detecting Lambda position for the 2nd peak')
        legend('off')
        xlabel('Pixel number in Lambda direction')
        ylabel('Intensity [cnt]')
        xlim([Min_L_L2 Max_L_L2])
        ylim([0 MAX2])
        Coef_L2 = coeffvalues(f_L2);
        px2nm = -(lambda_1st - lambda_2nd)/(Coef_L1(1,2)-Coef_L2(1,2));%px2nmを計算
    else
        % px2nm = 0.0046;
        px2nm = 0.0042;
    end
    sgtitle(['CH',num2str(calib_CH)])

    if save_fit
        if not(exist(num2str(date),'dir'))
            mkdir(num2str(date));
        end
        saveas(gcf,[num2str(date),'/fit_CH',num2str(calib_CH),'_w_CH=',num2str(w_CH),'.png'])
        hold off
        close
    end
    centerY = Coef_CH1(1,2);
    centerX = -(lambda0-lambda_1st)/px2nm+Coef_L1(1,2);
    % all_cal_result = cal_result;
    cal_result = [calib_CH centerY centerX px2nm instrument strength]
    if cal_1st && save_cal
        if not(exist(num2str(date),'dir'))
            mkdir(num2str(date));
        end
        save([num2str(date),'/calibation',num2str(calib_CH),'_w_CH=',num2str(w_CH),'.mat'],'cal_result')
    end
end
function [IDSPdata] = cal_ionflow(IDSP,pathname,show_offset,plot_fit,save_fit)
%IDSP変数/pathname/offsetを表示/ガウスフィッティングをプロット/流速を保存
%------フィッティング調整用【input】-------
w_CH = 6;%【input】チャンネル方向(Y方向)足し合わせ幅[px]6
l_mov_flow = 15;%【input】波長方向移動平均長さ[px]15
th_ratio_flow = 0.8;%【input】フィッティング時閾値[px]0.8
l_mov_temp = 15 ;%【input】波長方向移動平均長さ[px]15
th_ratio_temp = 0.5;%【input】フィッティング時閾値[px]0.8
l_L1 = 81;%【input】波長軸の切り取り長さ[px]
d_L1 = 45;%【input】波長方向位置ずれ調整[px]
d_CH = -7;%【input】CH方向位置ずれ調整[px]d_CH = -22(240827)
pre_offset = 0.086;%【input】分光器波長方向位置ずれ調整[nm]pre_offset = 0.086(240827)

% savename =[];
savename = [pathname.mat,'/ionflow/cal25_',num2str(IDSP.date),'_shot',num2str(IDSP.shot),'_',num2str(IDSP.delay),'us_w=',num2str(IDSP.width),'_gain=',num2str(IDSP.gain),'.mat'];
if exist(savename,"file")
    load(savename,'IDSPdata')
else
    %物理定数
    Vc = 299792.458;%光速(km/s)
    Angle = 30;%入射角(度)
    switch char(IDSP.line)
        case 'Ar'%アルゴンの時
            A = 40;%原子量
            lambda0 = 480.602;%使用スペクトル(nm)
            lambda1 = 480.7019;%校正ランプスペクトル(nm)
        case 'H'%水素の時
            A = 1;%原子量
            lambda0 = 486.135;%使用スペクトル(nm)
            warning('Sorry, not ready for H experiment.')%ICCD.lineの入力エラー
            return;
        otherwise
            warning('Input error in ICCD.line.')%ICCD.lineの入力エラー
            return;
    end
    center = load_IDSPcalib(IDSP);

    dir1 = [pathname.IDSP '/' num2str(IDSP.date)];%ディレクトリ1
    if IDSP.n_z == 1
        filename1 = [dir1 '/shot' num2str(IDSP.shot) '_' num2str(IDSP.delay) 'us_w=' num2str(IDSP.width) '_gain=' num2str(IDSP.gain) '.asc'];%ICCDファイル名
        if not(exist(filename1,"file"))
            warning([filename1,' does not exist.']);
            return
        end
        %data1からスペクトル群を取得
        data1 = importdata(filename1);
    end

    %----------------------------------------------------------------------------
    % centerX = repmat(center(:,3),1,IDSP.n_z);%チャンネル対応中心相対X座標
    switch IDSP.n_z
        case 1
            centerY = center(:,2);%チャンネル対応中心Y座標
        case 2
            warning('Sorry, not ready for n_z = 2.')%ICCD.lineの入力エラー
            return
            centerY = repmat(center(:,2),1,IDSP.n_z);%チャンネル対応中心Y座標
    end

    X1 = data1(:,1);%X1(ピクセル)軸を定義
    [l_X1,~]=size(data1);%X1軸の長さを取得
    L1 = zeros(l_X1,IDSP.n_CH);%L1(波長)軸を定義
    L1_shaped = zeros(l_L1,IDSP.n_CH);%切り取った波長軸
    px2nm = zeros(IDSP.n_CH,1);%nm/pixel
    switch char(IDSP.line)
        case 'Ar'%アルゴンの時
            %     lambda = [lambda1 lambda2];
            for i = 1:IDSP.n_CH
                %         pixel = [center(i,3) center(i,4)];
                %         p = polyfit(pixel,lambda,1);
                %         px2nm(i,1) = p(1);
                %         L1(:,i) = polyval(p,X1);
                px2nm(i,1) = center(i,4);
                L1(:,i) = lambda1 - px2nm(i,1)*(X1(:,1)-center(i,3));
                L1_shaped(:,i) = L1(round(center(i,3))-(l_L1-1)/2+d_L1:round(center(i,3))+(l_L1-1)/2+d_L1,i)+pre_offset;
            end
        case 'H'%水素の時
            for i = 1:IDSP.n_CH
                px2nm(i,1) = 0.00536;
                L1(:,i) = px2nm(i,1)*(X1-center(i,3))+lambda0;
            end
    end
    spectrum1 = zeros(l_L1,IDSP.n_CH);%data1の分光結果を入れる
    for i = 1:IDSP.n_CH
        spectrum1(:,i) = ...
            sum(data1(round(center(i,3))-(l_L1-1)/2+d_L1:round(center(i,3))+(l_L1-1)/2+d_L1,round(centerY(i,1)+d_CH-w_CH):round(centerY(i,1)+d_CH+w_CH)),2);
        spectrum1(:,i) = spectrum1(:,i)./center(i,6);
    end

    % %data2からスペクトル群を取得
    % if IDSP.n_z > 1
    %     data2 = importdata(filename2);
    %     X2 = data2(:,1);%X2(ピクセル)軸を定義
    %     [LofX2,~]=size(data2);%X2軸の長さを取得
    %     spectrum2=zeros(LofX2,IDSP.n_CH);%data2の分光結果を入れる
    %     for i = 1:IDSP.n_CH
    %         spectrum2(:,i) = ...
    %             sum(data2(:,round(centerY(i,2)-width):round(centerY(i,2)+width)),2);
    %     end
    % end

    %計算結果取得用の配列を用意
    amp = zeros(IDSP.n_CH,IDSP.n_z);%振幅1列目data1
    shift = zeros(IDSP.n_CH,IDSP.n_z);%中心1列目data1
    err_shift = zeros(IDSP.n_CH,IDSP.n_z);%中心1列目data1
    sigma = zeros(IDSP.n_CH,IDSP.n_z);%シグマ1列目data1
    err_sigma = zeros(IDSP.n_CH,IDSP.n_z);%シグマ1列目data1
    IDSPdata.V_CH = zeros(IDSP.n_CH,IDSP.n_z);%1列目data1・V(km/s)
    IDSPdata.err_V_CH = zeros(IDSP.n_CH,IDSP.n_z);%1列目data1・V(km/s)
    IDSPdata.V_i = zeros(IDSP.n_r,IDSP.n_z*2);%1列目data1・Vz(km/s)、2列目data1・Vr(km/s)
    IDSPdata.err_V_i = zeros(IDSP.n_r,IDSP.n_z*2);%1列目data1・Vz(km/s)、2列目data1・Vr(km/s)
    IDSPdata.absV = zeros(IDSP.n_r,IDSP.n_z);%1列目data1・V(km/s)
    IDSPdata.T_CH = zeros(IDSP.n_CH,IDSP.n_z);%1列目data1・温度(eV)
    IDSPdata.err_T_CH = zeros(IDSP.n_CH,IDSP.n_z);%1列目data1・温度(eV)
    IDSPdata.T_i = zeros(IDSP.n_r,IDSP.n_z);%1列目data1・温度(eV)
    IDSPdata.err_T_i = zeros(IDSP.n_r,IDSP.n_z);%1列目data1・温度(eV)
    IDSPdata.trim_T_i = zeros(IDSP.n_r,IDSP.n_z);%1列目data1・温度(eV)
    IDSPdata.err_trim_T_i = zeros(IDSP.n_r,IDSP.n_z);%1列目data1・温度(eV)
    IDSPdata.offset = zeros(IDSP.n_r,IDSP.n_z);
    error_CH = zeros(IDSP.n_CH,1);

    %波長方向の移動平均から離れた外れ値を移動平均に変更(ノイズ除去)
    M1_flow = movmean(spectrum1,l_mov_flow);
    spectrum1_flow = spectrum1;
    for i = 1:IDSP.n_CH
        for j = 1:l_L1
            if spectrum1_flow(j,i) > M1_flow(j,i)*1.05
                spectrum1_flow(j,i) = M1_flow(j,i);
            elseif spectrum1_flow(j,i) < M1_flow(j,i)*0.95
                spectrum1_flow(j,i) = M1_flow(j,i);
            end
        end
    end

    for k = 1:IDSP.n_r
        %0度ペアスペクトルからオフセットを検出
        for i = 1:2
            i_CH = (k-1)*4+i;%CH番号
            S1 = [L1_shaped(:,i_CH) spectrum1_flow(:,i_CH)]; %[波長,強度]
            s1 = size(S1);%S1の[行数,列数]
            MAX1 = max(spectrum1_flow(:,i_CH)); %スペクトルの最大値
            j = 1;
            while j < s1(1)+1 %SNの悪いデータを除く
                if S1(j,2) < MAX1*th_ratio_flow
                    S1(j,:) = [];
                else
                    j = j+1;
                end
                s1 = size(S1);
            end
            try
                f = fit(S1(:,1),S1(:,2),'gauss1');
            catch ME
                warning(['Fitting failed in CH ',num2str(i_CH),'.']);
                error_CH(i_CH,1) = 1;
                break
            end
            coef=coeffvalues(f);
            shift(i_CH,1) = coef(2)-lambda0;
        end
        IDSPdata.offset(k,1) = (shift((k-1)*4+1,1) + shift((k-1)*4+2,1))/2;%対向視線から得られたオフセット[nm]
    end

    % %異常値を持つoffsetを内挿して置き換え
    % ori_offset = IDSPdata.offset;%変更前を保管
    % buf = IDSPdata.offset(:,1);%offsetをコピー
    % idx_0 = find(buf == 0);%0を検出
    % idx_non0 = find(buf ~= 0);%non0を検出
    % buf(idx_0) = [];%0を削除
    % buf = filloutliers(buf,"linear");%外れ値を線型内挿で置き換え
    % IDSPdata.offset(idx_non0,1) = buf;%offsetを更新
    % IDSPdata.offset(idx_0,1) = mean(IDSPdata.offset(idx_non0,1));%offsetを更新
    % for k = 1:IDSP.n_r
    %     if IDSPdata.offset(k,1) ~= ori_offset(k,1)
    %         disp(['Offset in Row ',num2str(k),' is replaced from ',num2str(ori_offset(k,1)),' to ',num2str(IDSPdata.offset(k,1))'.'])
    %     end
    % end


    % offset_mean = (IDSPdata.offset(2,1) + IDSPdata.offset(3,1))/2;
    % for k = [1 5:7]
    %     IDSPdata.offset(k,1) = IDSPdata.offset(3,1);
    % end
    % IDSPdata.offset(1,1) = IDSPdata.offset(2,1);%1番の視線2が波形汚くoffsetが信用できないため導入(20230807校正のとき)
    % IDSPdata.offset(6,1) = IDSPdata.offset(5,1);
    % IDSPdata.offset(5,1) = IDSPdata.offset(6,1);%5番の視線1と視線2が連番でなくoffsetが信用できないため導入(20230807校正のとき)

    IDSPdata.offset(6,1) = (IDSPdata.offset(2,1)+IDSPdata.offset(3,1))/2;%6番の視線2が怪しくoffsetが信用できないため導入(20240607校正のとき)

    %data1の流速計算用ガウスフィッティング
    if plot_fit
        if save_fit
            figure('Position',[300 50 1000 1000],'visible','off')
        else
            figure('Position',[300 50 1000 1000],'visible','off')
        end
        sgtitle(['Fitting data for flow (Horizontal：View Line, Vertical：Measured Position)',newline, ...
            'shot',num2str(IDSP.shot),'-',num2str(IDSP.delay),'us-w=',num2str(IDSP.width),'-gain=',num2str(IDSP.gain),'.asc'])
    end
    for k = 1:IDSP.n_r
        % if (error_CH((k-1)*4+1,1) == 0) && (error_CH((k-1)*4+2,1) == 0)%対抗視線のフィッティングに成功
        if show_offset
            disp(['Offset = ',num2str(IDSPdata.offset(k,1)),' in Row ',num2str(k),'.'])
        end
        %オフセットを引いてガウスフィッティング
        for i = 1:4
            i_CH = (k-1)*4+i;%CH番号
            S1 = [L1_shaped(:,i_CH)-IDSPdata.offset(k,1) spectrum1_flow(:,i_CH)]; %[波長,強度]
            s1 = size(S1);%S1の[行数,列数]
            ori_S1 = S1;
            deleted_S1 = zeros(1,2);
            MAX1 = max(spectrum1_flow(:,i_CH)); %スペクトルの最大値
            j = 1;
            while j < s1(1)+1 %SNの悪いデータを除く
                if S1(j,2) < MAX1*th_ratio_flow
                    deleted_S1 = cat(1,deleted_S1,S1(j,:));
                    S1(j,:) = [];
                else
                    j = j+1;
                end
                s1 = size(S1);
            end
            try
                f = fit(S1(:,1),S1(:,2),'gauss1');
                coef=coeffvalues(f);
                confi = confint(f);%フィッティング係数の95%信頼区間(1行目下限, 2行目上限)
                amp(i_CH,1) = coef(1);
                shift(i_CH,1) = coef(2)-lambda0;
                err_shift(i_CH,1) = confi(2,2)-coef(2);
                IDSPdata.V_CH(i_CH,1) = shift(i_CH,1)/lambda0*Vc;
                IDSPdata.err_V_CH(i_CH,1) = err_shift(i_CH,1)/lambda0*Vc;
                if (l_mov_flow == l_mov_temp) && (th_ratio_flow == th_ratio_temp)
                    sigma(i_CH,1) = sqrt(coef(3)^2-(center(i_CH,5)*px2nm(i_CH,1))^2);
                    err_sigma(i_CH,1) = sqrt(confi(2,3)^2-(center(i_CH,5)*px2nm(i_CH,1))^2);
                    IDSPdata.T_CH(i_CH,1) = 1.69e8*A*(2*sigma(i_CH,1)*sqrt(log(2))/lambda0)^2;
                    IDSPdata.err_T_CH(i_CH,1) = 1.69e8*A*(2*err_sigma(i_CH,1)*sqrt(log(2))/lambda0)^2 - IDSPdata.T_CH(i_CH,1);
                end
                if plot_fit
                    subplot(IDSP.n_r,4,i_CH);
                    plot(f,'r-',ori_S1(:,1),ori_S1(:,2),'.w');
                    hold on
                    plot(S1(:,1),S1(:,2),'bo');
                    hold on
                    plot(deleted_S1(:,1),deleted_S1(:,2),'kx');
                    hold on
                    xline(lambda0);
                    yline(MAX1*th_ratio_flow,'g','LineWidth',3);
                    title(sprintf('%2.1f ± %2.1f km/s',IDSPdata.V_CH(i_CH,1),IDSPdata.err_V_CH(i_CH,1)))
                    legend('off')
                    xlabel('Wavelength [nm]')
                    ylabel('Intensity [cnt]')
                    xlim([lambda0-0.1,lambda0+0.1])
                    ylim([0,MAX1*1.1])
                    legend('off')
                end
            catch ME
                warning(['Fitting failed in CH ',num2str(i_CH),'.']);
                break
            end
        end
        % else
        %     warning(['Offset failed in Row ',num2str(k),'.']);
        % end
    end
    if plot_fit
        if save_fit
            time = round(IDSP.delay+IDSP.width/2);%計測時刻
            % if (l_mov_flow == l_mov_temp) && (th_ratio_flow == th_ratio_temp)
            %     saveas(gcf,[pathname.fig,'/fit/',num2str(IDSP.date),'_shot', num2str(IDSP.shot),'_',num2str(time),'us_fit_for_both.png'])
            % else
            %     saveas(gcf,[pathname.fig,'/fit/',num2str(IDSP.date),'_shot', num2str(IDSP.shot),'_',num2str(time),'us_fit_for_flow.png'])
            % end
            hold off
            close
        else
            hold off
        end
    end

    if not((l_mov_flow == l_mov_temp) && (th_ratio_flow == th_ratio_temp))
        %波長方向の移動平均から離れた外れ値を移動平均に変更(ノイズ除去)
        M1_temp = movmean(spectrum1,l_mov_temp);
        spectrum1_temp = spectrum1;
        for i = 1:IDSP.n_CH
            for j = 1:l_L1
                if spectrum1_temp(j,i) > M1_temp(j,i)*1.05
                    spectrum1_temp(j,i) = M1_temp(j,i);
                elseif spectrum1_temp(j,i) < M1_temp(j,i)*0.95
                    spectrum1_temp(j,i) = M1_temp(j,i);
                end
            end
        end

        %data1の温度計算用ガウスフィッティング
        if plot_fit
            if save_fit
                figure('Position',[100 50 1000 1000],'visible','off')
            else
                figure('Position',[100 50 1000 1000],'visible','on')
            end
            sgtitle(['Fitting data for temp. (Horizontal：View Line, Vertical：Measured Position)',newline, ...
                'shot',num2str(IDSP.shot),'-',num2str(IDSP.delay),'us-w=',num2str(IDSP.width),'-gain=',num2str(IDSP.gain),'.asc'])
        end
        for k = 1:IDSP.n_r
            for i = 1:4
                i_CH = (k-1)*4+i;%CH番号
                S1 = [L1_shaped(:,i_CH)-IDSPdata.offset(k,1) spectrum1_temp(:,i_CH)]; %[波長,強度]
                s1 = size(S1);%S1の[行数,列数]
                ori_S1 = S1;
                deleted_S1 = zeros(1,2);
                MAX1 = max(spectrum1_temp(:,i_CH)); %スペクトルの最大値
                j = 1;
                while j < s1(1)+1 %SNの悪いデータを除く
                    if S1(j,2) < MAX1*th_ratio_temp
                        deleted_S1 = cat(1,deleted_S1,S1(j,:));
                        S1(j,:) = [];
                    else
                        j = j+1;
                    end
                    s1 = size(S1);
                end
                try
                    f = fit(S1(:,1),S1(:,2),'gauss1');
                    coef=coeffvalues(f);
                    confi = confint(f);%フィッティング係数の95%信頼区間(1行目下限, 2行目上限)
                    sigma(i_CH,1) = sqrt(coef(3)^2-(center(i_CH,5)*px2nm(i_CH,1))^2);
                    err_sigma(i_CH,1) = sqrt(confi(2,3)^2-(center(i_CH,5)*px2nm(i_CH,1))^2);
                    IDSPdata.T_CH(i_CH,1) = 1.69e8*A*(2*sigma(i_CH,1)*sqrt(log(2))/lambda0)^2;
                    IDSPdata.err_T_CH(i_CH,1) = 1.69e8*A*(2*err_sigma(i_CH,1)*sqrt(log(2))/lambda0)^2 - IDSPdata.T_CH(i_CH,1);
                    if plot_fit
                        subplot(IDSP.n_r,4,i_CH);
                        plot(f,'r-',ori_S1(:,1),ori_S1(:,2),'.w');
                        hold on
                        plot(S1(:,1),S1(:,2),'bo');
                        hold on
                        plot(deleted_S1(:,1),deleted_S1(:,2),'kx');
                        hold on
                        xline(lambda0);
                        yline(MAX1*th_ratio_temp,'g','LineWidth',3);
                        title(sprintf('%3.0f ± %3.0f eV',IDSPdata.T_CH(i_CH,1),IDSPdata.err_T_CH(i_CH,1)))
                        legend('off')
                        xlabel('Wavelength [nm]')
                        ylabel('Intensity [cnt]')
                        xlim([lambda0-0.1,lambda0+0.1])
                        ylim([0,MAX1*1.1])
                        legend('off')
                    end
                catch ME
                    warning(['Fitting failed in CH ',num2str(i_CH),'.']);
                    break
                end
            end
            % else
            %     warning(['Offset failed in Row ',num2str(k),'.']);
            % end
        end
        if plot_fit
            if save_fit
                time = round(IDSP.delay+IDSP.width/2);%計測時刻
                saveas(gcf,[pathname.fig,'/fit/cal25_',num2str(IDSP.date),'_shot', num2str(IDSP.shot),'_',num2str(time),'us_fit_for_temp.png'])
                hold off
                close
            else
                hold off
            end
        end
    end
    %data1の流速、温度を計算
    for i = 1:IDSP.n_r
        set = (i-1)*4;
        Va = -shift(set+4,1)/lambda0*Vc;
        Vb = -shift(set+3,1)/lambda0*Vc;
        Vz1 = -shift(set+1,1)/lambda0*Vc;
        Vz2 = -shift(set+2,1)/lambda0*Vc;
        err_Va = err_shift(set+4,1)/lambda0*Vc;
        err_Vb = err_shift(set+3,1)/lambda0*Vc;
        err_Vz1 = err_shift(set+1,1)/lambda0*Vc;
        err_Vz2 = err_shift(set+2,1)/lambda0*Vc;
        %視線3と視線4で計算
        IDSPdata.V_i(i,1) = (Va-Vb)/(2*cos(Angle*pi/180));%Vz
        IDSPdata.V_i(i,2) = -(Va+Vb)/(2*sin(Angle*pi/180));%Vr
        IDSPdata.err_V_i(i,1) = (err_Va+err_Vb)/(2*cos(Angle*pi/180));%err_Vz
        IDSPdata.err_V_i(i,2) = (err_Va+err_Vb)/(2*sin(Angle*pi/180));%err_Vr
        IDSPdata.absV(i,1) = sqrt(IDSPdata.V_i(i,1)^2 + IDSPdata.V_i(i,2)^2);
        % if i == 5
        %     % 視線2と視線4で計算
        %     IDSPdata.V_i(i,1) = Vz2;%Vz
        %     IDSPdata.V_i(i,2) = Vz2/tan(Angle*pi/180)-Va/sin(Angle*pi/180);%Vr
        %     IDSPdata.err_V_i(i,1) = err_Vz2;%err_Vz
        %     IDSPdata.err_V_i(i,2) = err_Vz2/tan(Angle*pi/180)+err_Va/sin(Angle*pi/180);%err_Vr
        %     IDSPdata.absV(i,1) = sqrt(IDSPdata.V_i(i,1)^2 + IDSPdata.V_i(i,2)^2);
        % end
        % if i == 6
        %     %視線1と視線4で計算
        %     IDSPdata.V_i(i,1) = -Vz1;%Vz
        %     IDSPdata.V_i(i,2) = -Vz1/tan(Angle*pi/180)-Va/sin(Angle*pi/180);%Vr
        %     IDSPdata.err_V_i(i,1) = err_Vz1;%err_Vz
        %     IDSPdata.err_V_i(i,2) = err_Vz1/tan(Angle*pi/180)+err_Va/sin(Angle*pi/180);%err_Vr
        %     IDSPdata.absV(i,1) = sqrt(IDSPdata.V_i(i,1)^2 + IDSPdata.V_i(i,2)^2);
        % end
        % IDSPdata.T_i(i,1) = mean(IDSPdata.T_CH(set+1:set+4,1));
        % IDSPdata.err_T_i(i,1) = std(IDSPdata.T_CH(set+1:set+4,1));
        IDSPdata.trim_T_i(i,1) = trimmean(IDSPdata.T_CH(set+1:set+4,1),50);
        sum_weight = 0;
        for j = 1:4
            weight = 1./IDSPdata.err_T_CH(set+j,1).^2;%重み1/σ^2
            IDSPdata.T_i(i,1) = IDSPdata.T_i(i,1) + IDSPdata.T_CH(set+j,1)*weight;
            sum_weight = sum_weight + weight;
        end
        IDSPdata.T_i(i,1) = IDSPdata.T_i(i,1)/sum_weight;
        IDSPdata.err_T_i(i,1) = 1./sqrt(sum_weight);
    end

    IDSPdata.z = IDSP.z;
    IDSPdata.r = IDSP.r;
    IDSPdata.delay = IDSP.delay;
    IDSPdata.width = IDSP.width;
    IDSPdata.gain = IDSP.gain;
    IDSPdata.time = IDSP.time;
    save(savename,'IDSPdata')
end


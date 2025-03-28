close all
clearvars -except data_filename data datalist_MC
addpath '/Users/rsomeya/Documents/lab/matlab/common';
%各PCのパスを定義
run define_path.m

data_path = [pathname.ST40_Doppler,'/2024_0604_autosave/'];%ICCD ascファイルのパス
calib_path = 'calibration/2024_June/';%校正ファイルのパス

%------【input】---------------------------------------------------
input_type = 'num';%【input】データ選択方式('num','file')
shotlist = 11966;%datalist_MC([2:9 11:21 23:29 44:46 51:62 64 65 67:76 78:82 84:end]);%除外1,10,22,30:43,47,48,50,63,66,77,83
sp_line = 'CVI';%【input】ドップラー発光ライン('CVI')
frame = [1];%計算フレーム番号[1:6]
ng_CH = [43 49 50];%死んだチャンネル
read_data = true;%【input】データをascファイルから読み込む
plot_ICCD = false;%【input】ICCD画像をプロット
cal_CH = true;%【input】CHごとのスペクトルを取得
cal_LineInt = true;%【input】線積分イオン温度、発光強度分布を計算
plot_PZ_LineInt = true;%【input】線積分イオン温度、発光強度PZ分布をプロット
cal_Local = true;%【input】アーベル変換して2次元イオン温度、発光強度分布を計算
plot_RZ_Local = true;%【input】2次元イオン温度、発光強度RZ分布をプロット
gif_RZ_Local = false;%【input】2次元イオン温度、発光強度RZ分布gifを保存
plot_tR_z = false;%【input】イオン温度R分布時間発展をプロット
plot_tR_silica = false;%【input】イオン温度R分布時間発展(石英ファイバー分平均)をプロット

%-----------------------解析オプション【input】----------------------------
plot_CH_spectra = true;%【input】CHごとのスペクトルをプロット(cal_CH = trueが必要)
plot_LineInt_interp = false;%【input】死んだCHの補間Ti,Emをプロット(cal_LineInt = trueが必要)
plot_Local_interp = true;%【input】補間スペクトルをプロット(cal_Local = trueが必要)
plot_Local_spectra = 'all';%【input】('off','all','good','bad')2次元スペクトル分布をプロット(cal_Local = trueが必要)

hw_lambda = 70;%【input】波長切り出し半幅
num_r = 30;%【input】r分割数(比例して計算時間が増える)(30)
hw_lambdaA = 30;%【input】補間スペクトル波長軸lambdaA半幅(< hw_lambda)
N_gf = 30;%【input】生信号ガウスフィルター窓サイズ(gausswin参照)(30)
sigma_gf = 5;%【input】生信号ガウスフィルター標準偏差(5)
w_movmean_Local = 15;%【input】アーベル変換後移動平均幅
w_offset = 15;%【input】一次関数ノイズ除去のためのオフセット幅
RSQ_CH_th_ratio = 0.8;%【input】RSQ_CH閾値(0~1)
RSQ_Local_th_ratio = 0.8;%【input】RSQ_CH閾値(0~1)
sp_th_ratio = 0.7;%【input】フィッティングに用いる点の閾値(最大値の何倍までか)(0~1)
Em_th_ratio = 0;%【input】局所発光強度閾値(0~1)
bg_num = 10;%【input】backgoundに使うフレーム数(1~10)
%------------------------------------------------------------------
CH = 1:96;%CH番号
%物理定数
reference = [530.4758,529.81891,528.00853,527.40393];%Neランプ校正波長
switch sp_line
    case 'CVI'
        lambda0 = 529.05;%線スペクトル波長
        mass = 12.01;%イオン質量数
    otherwise
        warning('Input error in sp_line.')%ICCD.lineの入力エラー
        return;
end

%------校正データ---------------------------------
instru = importdata([calib_path,'instru.txt']);%装置関数
p = importdata([calib_path,'/tangential_radii.txt']);%計測視線と中心軸の距離P[m]
z = [-25,-7.5,7.5,25,42.5,60]*1e-3;%計測視線平面Z[m]
R_CXRS = importdata([calib_path,'/CXRS_radii.txt'])*1e-3;%CXRS時のR[m]
relative = importdata([calib_path,'/relative_20240610.txt']);%相対感度
smile = importdata([calib_path,'/smile.txt']);%グレーティングスマイル補正
fcsheet_name = 'fiber_connection_note.xlsx';%集光-分光器間ファイバー接続sheet
smile_offset = sum(smile(64,:)-[369.73767 427.35829 585.38118 635.61187],'all')/4;%2024/June
smile = smile - smile_offset;
edge = p(end)+(p(end)-p(end-1))*2;%Rの最大値[m]
%------------------------------------------------------------------
switch input_type
    case 'file'
        num_shot = 1;
    case 'num'
        num_shot = numel(shotlist);
end

for i_shot = 1:num_shot
    switch input_type
        case 'file'
            if read_data
                clearvars data_filename data
                %データ1読み込み(GUI)
                [file1,path1] = uigetfile('*.asc','Select a file',data_path);
                if isequal(file1,0)
                    disp('User selected Cancel.');
                    return
                else
                    disp(['User selected <', file1,'>.']);
                    data_filename = fullfile(path1,file1);
                end
                pattern = "shot_" + digitsPattern(5);
                shot_num = str2double(erase(extract(data_filename,pattern),"shot_"));%ファイル名からshot番号を抽出
            else
                if exist('data_filename','var')&&exist('data','var')
                else
                    warning("No data loaded. Change <<read_data>> true.")
                    return
                end
            end
        case 'num'
            shot_num = shotlist(i_shot);
            %データ読み込み
            data_filename = [data_path,'shot_',num2str(shot_num),'.asc'];
    end
    if exist(data_filename,'file')
        folder_name = [pathname.mat,'/ST40_IDS'];
        if not(exist(folder_name,'dir'))
            mkdir(folder_name)
        end
        savename = [folder_name,'/ST40_shot',num2str(shot_num),'.mat'];
        if exist(savename,"file")
            load(savename,'ST40IDSdata')
        else
            %スペクトルを取得
            data = importdata(data_filename);
            data = data(:,2:33);%1列目は分光データではないので削除
            %ファイバー接続sheetを自動選択
            sheets = sheetnames([calib_path,fcsheet_name]);
            if shot_num < 11817
                fiber_connection = readmatrix([calib_path,fcsheet_name],'Sheet','before 11817');
                disp("Sheet <before 11817> was applied.")
            else
                fiber_connection = readmatrix([calib_path,fcsheet_name],'Sheet','after 11817');
                disp("Sheet <after 11817> was applied.")
            end
            z_CH = fiber_connection(:,3)*1e-3;%各CHのZ座標[m]
            p_CH = fiber_connection(:,4);%各CHのP座標[m]
            idx_z = zeros(numel(CH),1);%各CHのZ方向番号
            idx_p = zeros(numel(CH),1);%各CHのP方向番号
            idx_CH = zeros(numel(p),numel(z));%ZP座標に対応するCH番号
            for i_CH = 1:numel(CH)
                idx_z(i_CH) = find(z == z_CH(i_CH));
                idx_p(i_CH) = find(p == p_CH(i_CH));
            end
            for i_z = 1:numel(z)
                for i_p = 1:numel(p)
                    idx_CH(i_p,i_z) = intersect(find(z_CH == z(i_z)),find(p_CH == p(i_p)));
                end
            end
            %実験ログ読み込み
            DOCID = '13vB2pWO_zp3kMjpwVyoWXwHmu4M7HovwN3ic4VrifuQ';%ST40実験ログのID
            loginURL = 'https://www.google.com';
            csvURL = ['https://docs.google.com/spreadsheet/ccc?key=' DOCID '&output=csv&pref=2'];
            cookieManager = java.net.CookieManager([], java.net.CookiePolicy.ACCEPT_ALL);
            java.net.CookieHandler.setDefault(cookieManager);
            handler = sun.net.www.protocol.https.Handler;
            connection = java.net.URL([],loginURL,handler).openConnection();
            connection.getInputStream();
            ST40table = webread(csvURL);
            ST40log = ST40table(:,4:9);
            ST40log = fillmissing(ST40log,'constant',0);%0埋め
            shot_row = find((ST40log.Var4)==shot_num);
            if shot_row
                trigger_delay = ST40log.Var5(shot_row);%トリガー時間[ms]
                ICCD_delay = ST40log.Var6(shot_row);%ICCD遅延時間[ms]
                gate = ST40log.Var7(shot_row);%露光時間[ms]
                rate = ST40log.Var8(shot_row)*1e3;%フレーム間時間間隔[ms]
            else
                warning("Log for the shot couldn't be found.")
                trigger_delay = 0;%トリガー時間[ms]
                ICCD_delay = 0;%ICCD遅延時間[ms]
                gate = 4;%露光時間[ms]
                rate = 0.016*1e3;%フレーム間時間間隔[ms]
            end
            t = zeros(numel(frame),1);%計測フレーム時刻[ms]
            for i_t = 1:numel(t)
                t(i_t) = trigger_delay + ICCD_delay + gate/2 + (frame(i_t)-1)*rate;
            end

            %各CHの波長軸を生成
            lambda = zeros(2*hw_lambda+1,numel(CH));
            idx_l0 = zeros(numel(CH),1);
            px = transpose(1:1024);
            resolution = zeros(96,1);
            for i_CH = 1:numel(CH)
                p_fitted = polyfit(smile(i_CH,:),reference,1);
                resolution(i_CH) = p_fitted(1);
                lx = polyval(p_fitted,px);
                idx_l0(i_CH) = knnsearch(lx,lambda0);%lxの中で最もlambda0に近いセル番号を取得
                lambda(:,i_CH) = lx(idx_l0(i_CH)-hw_lambda:idx_l0(i_CH)+hw_lambda);
            end
            %ガウスフィルターを用意
            alpha_gf = (N_gf-1)/(2*sigma_gf);%生信号ガウスフィルター幅係数(gausswin参照)
            gaussFilter = gausswin(N_gf,alpha_gf);
            gaussFilter = gaussFilter / sum(gaussFilter);
            Ti_instru_CH_gf = 1.69e8*mass*(2*resolution.*sqrt(instru.^2+sigma_gf^2)*sqrt(2*log(2))/lambda0).^2;%ガウスフィルター1回
            Ti_instru_CH_gf2 = 1.69e8*mass*(2*resolution.*sqrt(instru.^2+sigma_gf^2+sigma_gf^2)*sqrt(2*log(2))/lambda0).^2;%ガウスフィルター2回

            bg_data = zeros(numel(px),size(data,2));
            for i_bg = 1:bg_num
                bg_data = bg_data + data(size(data,1)-i_bg*numel(px)+1:size(data,1)-(i_bg-1)*numel(px),:);
            end
            bg_data = bg_data/bg_num;
            % bg_data = 0;

            %bgを引いてdataを3次元配列data3Dに整形
            data3D = zeros(numel(px),size(data,2),numel(t));
            for i_t = 1:numel(t)
                data3D(:,:,i_t) = data((frame(i_t)-1)*numel(px)+1:frame(i_t)*numel(px),:) - bg_data;
            end

            %ICCD生画像を描画(目視で確認用)
            if plot_ICCD
                figure('Position',[0 0 1500 1000])
                for i_t = 1:numel(t)
                    subplot(4,5,i_t)
                    contourf(px,1:32,squeeze(data3D(:,:,i_t))')
                    colormap(jet)
                    title(['t =',num2str(t(i_t)),'ms'])
                    xlabel('X　(lambda) [px]')
                    ylabel('Y (position) [px]')
                end
                sgtitle('ICCD Raw Images')
            end

            %-------CHごとの線積分温度、線積分発光強度を計算--------
            if cal_CH
                hw_plot_px = hw_lambda;%プロット範囲半幅
                col_subp1 = 2;%サブプロット行数
                raw_subp1 = 2;%サブプロット列数
                n_subp1 = col_subp1*raw_subp1;
                Ti_CH = zeros(numel(CH),numel(t));%CH温度[eV]
                Ti_CH_max = zeros(numel(CH),numel(t));%CH温度95%信頼区間上限[eV]
                Ti_CH_min = zeros(numel(CH),numel(t));%CH温度95%信頼区間下限[eV]
                Em_CH = zeros(numel(CH),numel(t));%CH発光強度[a.u.]
                spectra = zeros(2*hw_lambda+1,numel(CH),numel(t));%CHスペクトル
                spectra_fit = zeros(2*hw_lambda+1,numel(CH),numel(t));%CHスペクトルフィッティング結果
                RSQ_CH = zeros(numel(CH),numel(t));
                checker_CH = ones(numel(CH),numel(t));
                for i_t = 1:numel(t)
                    for i_CH = 1:numel(CH)
                        if any(ismember(ng_CH,i_CH))
                            checker_CH(i_CH,i_t) = 0;
                        else
                            spectra(:,i_CH,i_t) = data3D(idx_l0(i_CH)-hw_lambda:idx_l0(i_CH)+hw_lambda,mod(i_CH-1,size(data3D,2))+1,i_t)*relative(i_CH);
                            % spectra(:,i_CH,i_t) = movmean(spectra(:,i_CH,i_t),w_movmean_CH);%生信号の移動平均をとる
                            spectra(:,i_CH,i_t) = conv(spectra(:,i_CH,i_t), gaussFilter, 'same');%ガウスフィルターをかける
                            right_offset = mean(spectra(1:w_offset,i_CH,i_t),'all');%右側offset
                            left_offset = mean(spectra(end-w_offset:end,i_CH,i_t),'all');%左側offset
                            offset_slope = (left_offset - right_offset)/(size(spectra,1) - round(w_offset/2) - round(1+w_offset)/2);%offset一次関数傾き
                            spectra(:,i_CH,i_t) = spectra(:,i_CH,i_t) - offset_slope * (1:size(spectra,1))';
                            offset = min(movmean(spectra(:,i_CH,i_t),20));
                            spectra(:,i_CH,i_t) = spectra(:,i_CH,i_t) - offset;%オフセットを引く
                            max_sp_CH = max(spectra(:,i_CH,i_t));
                            survived_xy_CH = [lambda(:,i_CH) spectra(:,i_CH,i_t)]; %[波長,強度]
                            deleted_xy_CH = zeros(1,2);
                            j_SN_CH = 1;
                            flag_SN_CH = 0;
                            while j_SN_CH < size(survived_xy_CH,1)+1 %SNの悪いデータを除く
                                if survived_xy_CH(j_SN_CH,2) < max_sp_CH*sp_th_ratio
                                    if flag_SN_CH == 0
                                        deleted_xy_CH = survived_xy_CH(j_SN_CH,:);
                                        flag_SN_CH = 1;
                                    else
                                        deleted_xy_CH = cat(1,deleted_xy_CH,survived_xy_CH(j_SN_CH,:));
                                    end
                                    survived_xy_CH(j_SN_CH,:) = [];
                                else
                                    j_SN_CH = j_SN_CH+1;
                                end
                            end
                            if size(survived_xy_CH,1) < 3%データ点が足りない場合スキップ
                                checker_CH(i_CH,i_t) = 0;
                            else
                                [f,gof_CH] = fit(survived_xy_CH(:,1),survived_xy_CH(:,2),'gauss1');
                                RSQ_CH(i_CH,i_t) = gof_CH.rsquare;%決定係数(フィッティング精度指標)
                                spectra_fit(:,i_CH,i_t) = feval(f,lambda(:,i_CH));
                                coeff = coeffvalues(f);%フィッティング係数
                                confi = confint(f);%フィッティング係数の95%信頼区間(1行目下限, 2行目上限)
                                Ti_CH(i_CH,i_t) = 1.69e8*mass*(2*coeff(3)*sqrt(log(2))/lambda0)^2-Ti_instru_CH_gf(i_CH);
                                Ti_CH_max(i_CH,i_t) = 1.69e8*mass*(2*confi(2,3)*sqrt(log(2))/lambda0)^2-Ti_instru_CH_gf(i_CH);
                                Ti_CH_min(i_CH,i_t) = 1.69e8*mass*(2*confi(1,3)*sqrt(log(2))/lambda0)^2-Ti_instru_CH_gf(i_CH);
                                Em_CH(i_CH,i_t) = abs(resolution(i_CH))*sum(spectra(:,i_CH,i_t),'all');
                                %外れ値(checker_CH=0)の条件
                                checker_CH(i_CH,i_t) = checker_CH(i_CH,i_t) * (abs(coeff(2)-lambda0) < 0.1);
                                checker_CH(i_CH,i_t) = checker_CH(i_CH,i_t) * (coeff(1) > 0);
                                checker_CH(i_CH,i_t) = checker_CH(i_CH,i_t) * (Em_CH(i_CH,i_t) > 0);
                                checker_CH(i_CH,i_t) = checker_CH(i_CH,i_t) * (Ti_CH(i_CH,i_t) > 0);
                                checker_CH(i_CH,i_t) = checker_CH(i_CH,i_t) * (RSQ_CH(i_CH,i_t) > RSQ_CH_th_ratio);
                                if plot_CH_spectra
                                    fitted_x = transpose(linspace(lambda0-hw_plot_px*abs(resolution(i_CH)),lambda0+hw_plot_px*abs(resolution(i_CH)),100));
                                    idx_subp1 = mod(i_CH-1,n_subp1)+1;%サブプロット位置番号
                                    if i_CH == 1
                                        figure('Position',[0 500 400 300])
                                        sgtitle(sprintf("Line Integrated Spectra (%.1f ms)",t(i_t)))
                                    end
                                    subplot(col_subp1,raw_subp1,idx_subp1)
                                    if i_CH <= n_subp1
                                        if i_CH == 1
                                            fitted_y = feval(f,fitted_x);
                                            if checker_CH(i_CH,i_t) == 1
                                                p_fitted = plot(fitted_x,fitted_y,'r-','LineWidth',2);
                                            else
                                                p_fitted = plot(fitted_x,fitted_y,'g-','LineWidth',2);
                                                warning("CH%d (%.1fms) was excluded because of bad fitting.",CH(i_CH),t(i_t))
                                            end
                                            hold on
                                            p_survived = plot(survived_xy_CH(:,1),survived_xy_CH(:,2),'bo','MarkerSize',8,'LineWidth',0.8);
                                            hold on
                                            p_deleted = plot(deleted_xy_CH(:,1),deleted_xy_CH(:,2),'kx','MarkerSize',12,'LineWidth',0.8);
                                            p_fitted = repmat(p_fitted,[1,n_subp1]);
                                            p_survived = repmat(p_survived,[1,n_subp1]);
                                            p_deleted = repmat(p_deleted,[1,n_subp1]);
                                        else
                                            fitted_y = feval(f,fitted_x);
                                            if checker_CH(i_CH,i_t) == 1
                                                p_fitted(:,idx_subp1) = plot(fitted_x,fitted_y,'r-','LineWidth',2);
                                            else
                                                p_fitted(:,idx_subp1) = plot(fitted_x,fitted_y,'g-','LineWidth',2);
                                                warning("CH%d (%.1fms) was excluded because of bad fitting.",CH(i_CH),t(i_t))
                                            end
                                            hold on
                                            p_survived(:,idx_subp1) = plot(survived_xy_CH(:,1),survived_xy_CH(:,2),'bo','MarkerSize',8,'LineWidth',0.8);
                                            hold on
                                            p_deleted(:,idx_subp1) = plot(deleted_xy_CH(:,1),deleted_xy_CH(:,2),'kx','MarkerSize',12,'LineWidth',0.8);
                                        end
                                        xline(lambda0)
                                        title(['CH',num2str(CH(i_CH))])
                                        xlabel('Wavelength [nm]')
                                        ylabel('Strength [a.u.]')
                                        xlim([lambda0-hw_plot_px*abs(resolution(i_CH)) lambda0+hw_plot_px*abs(resolution(i_CH))])
                                        ylim([0 inf])
                                        legend('off')
                                    else
                                        fitted_y = feval(f,fitted_x);
                                        p_fitted(1,idx_subp1).YData = fitted_y;
                                        if checker_CH(i_CH,i_t) == 1
                                            p_fitted(1,idx_subp1).Color = 'r';
                                        else
                                            p_fitted(1,idx_subp1).Color = 'g';
                                            warning("CH%d (%.1fms) was excluded because of bad fitting.",CH(i_CH),t(i_t))
                                        end
                                        p_survived(1,idx_subp1).XData = survived_xy_CH(:,1);
                                        p_survived(1,idx_subp1).YData = survived_xy_CH(:,2);
                                        p_deleted(1,idx_subp1).XData = deleted_xy_CH(:,1);
                                        p_deleted(1,idx_subp1).YData = deleted_xy_CH(:,2);
                                        title(['CH',num2str(CH(i_CH))])
                                        drawnow
                                    end
                                end
                            end
                        end
                    end
                end
            end

            %%----------線積分温度、線積分発光強度二次元分布を計算------------
            if cal_LineInt
                Ti_LineInt_before = zeros(numel(p),numel(z),numel(t));%補間前二次元温度[eV]
                Em_LineInt_before = zeros(numel(p),numel(z),numel(t));%補間前二次元発光強度[a.u.]
                Ti_LineInt = zeros(numel(p),numel(z),numel(t));%二次元温度[eV]
                Em_LineInt = zeros(numel(p),numel(z),numel(t));%二次元発光強度[a.u.]
                %CH温度、CH発光強度をZP座標で整理
                for i_t = 1:numel(t)
                    for i_CH = 1:numel(CH)
                        if checker_CH(i_CH,i_t) == 1
                            Ti_LineInt_before(idx_p(i_CH),idx_z(i_CH),:) = Ti_CH(i_CH,:);
                            Em_LineInt_before(idx_p(i_CH),idx_z(i_CH),:) = Em_CH(i_CH,:);
                        end
                    end
                end
                for i_t = 1:numel(t)
                    %死んだCHを補間
                    for i_z = 1:numel(z)
                        i_p_ok = checker_CH(idx_CH(:,i_z),i_t)==1;
                        Ti_LineInt(:,i_z,i_t) = pchip(p(i_p_ok),Ti_LineInt_before(i_p_ok,i_z,i_t),p);
                        Em_LineInt(:,i_z,i_t) = pchip(p(i_p_ok),Em_LineInt_before(i_p_ok,i_z,i_t),p);
                    end
                    %補間結果をプロット
                    if plot_LineInt_interp
                        figure('Position',[1000 1000 600 200])
                        tiledlayout(1,2)
                        nexttile;
                        p1 = plot(p,squeeze(Ti_LineInt(:,1,i_t)),'ro-');
                        hold on
                        p2 = plot(p,squeeze(Ti_LineInt_before(:,1,i_t)),'b+');
                        xlabel('P [m]')
                        ylabel('Ti [eV]')
                        title('Interpoltaion of Ti')
                        legend(p1,'Interpolated')
                        nexttile;
                        p3 = plot(p,squeeze(Em_LineInt(:,1,i_t)),'ro-');
                        hold on
                        p4 = plot(p,squeeze(Em_LineInt_before(:,1,i_t)),'b+');
                        xlabel('P [m]')
                        ylabel('Emission [a.u.]')
                        title('Interpoltaion of Em')
                        legend(p3,'Interpolated')
                        sgtitle(sprintf("Z = %.1fm  (%.1f ms)",z(i_z),t(i_t)))
                        hold off
                        for i_z = 2:numel(z)
                            sgtitle(sprintf("Z = %.1fm  (%.1f ms)",z(i_z),t(i_t)))
                            p1.YData = Ti_LineInt(:,i_z,i_t);
                            p2.YData = Ti_LineInt_before(:,i_z,i_t);
                            p3.YData = Em_LineInt(:,i_z,i_t);
                            p4.YData = Em_LineInt_before(:,i_z,i_t);
                            drawnow
                        end
                    end
                end
            end

            %%----------アーベル変換線積分温度、発光二次元分布を計算------------
            if cal_Local
                %三角グリッドの補間によりアーベル変換に用いる2次元(λ,P)スペクトルを用意
                r = transpose(linspace(min(p),edge,num_r));
                dr = r(2) - r(1);
                lambdaA_z = zeros(2*hw_lambdaA+1,numel(z));%同一z平面での代表λ軸
                resolution_z = zeros(numel(z),1);%同一z平面での代表逆線分散
                for i_z = 1:numel(z)
                    resolution_z(i_z) = mean(resolution(idx_z == i_z),'all');
                    lambdaA_z(:,i_z) = transpose(linspace(-hw_lambdaA*abs(resolution_z(i_z)),hw_lambdaA*abs(resolution_z(i_z)),2*hw_lambdaA+1)) + lambda0;
                end
                spectra_interp = zeros(size(lambdaA_z,1),numel(r),numel(z),numel(t));
                for i_t = 1:numel(t)
                    for i_z = 1:numel(z)
                        cnt_i_p = 1;
                        for i_p = 1:numel(p)
                            if checker_CH(idx_CH(i_p,i_z),i_t) == 1
                                buf_tri_x = lambda(hw_lambda+1-hw_lambdaA:hw_lambda+1+hw_lambdaA,idx_CH(i_p,i_z));
                                buf_tri_y = p(i_p);
                                % buf_tri_z = squeeze(spectra_fit(hw_lambda+1-hw_lambdaA:hw_lambda+1+hw_lambdaA,idx_CH(i_p,i_z),i_t));
                                buf_tri_z = squeeze(spectra(hw_lambda+1-hw_lambdaA:hw_lambda+1+hw_lambdaA,idx_CH(i_p,i_z),i_t));
                                if cnt_i_p == 1
                                    tri_x = buf_tri_x;
                                    tri_y = buf_tri_y;
                                    tri_z = buf_tri_z;
                                else
                                    tri_x = cat(2,tri_x,buf_tri_x);
                                    tri_y = cat(2,tri_y,buf_tri_y);
                                    tri_z = cat(2,tri_z,buf_tri_z);
                                end
                                cnt_i_p = cnt_i_p + 1;
                            end
                        end
                        tri_x = cat(2,tri_x,lambda(hw_lambda+1-hw_lambdaA:hw_lambda+1+hw_lambdaA,idx_CH(end,i_z)));
                        tri_y = cat(2,tri_y,edge);
                        tri_z = cat(2,tri_z,zeros(size(lambdaA_z,1),1));
                        buf_x = reshape(transpose(tri_x),[],1);%CHごとの波長(CH数*ピクセル数)
                        buf_y = repmat(transpose(tri_y),size(tri_x,1),1);%P
                        buf_z = reshape(transpose(tri_z),[],1);%スペクトル
                        [grid_x, grid_y] = meshgrid(lambdaA_z(:,i_z),r);
                        F = scatteredInterpolant(buf_x,buf_y,buf_z);
                        grid_z = F(grid_x, grid_y);
                        % grid_z = movmean(grid_z,w_movmean_Local,1);%二次元スペクトルのスムージング(波長方向)
                        grid_z = movmean(grid_z,round((numel(r)-1)/16),2);%二次元スペクトルのスムージング(P方向)
                        spectra_interp(:,:,i_z,i_t) = transpose(grid_z);
                        if plot_Local_interp
                            if i_z == 1
                                figure('Position',[1000 0 500 300])
                                [~,h] = contourf(grid_x,grid_y,grid_z,100);
                                h.FaceAlpha = 0.7;
                                h.LineStyle = 'none';
                                colorbar
                                colormap('jet')
                                hold on
                                Tri = delaunay(buf_x,buf_y);
                                trp = triplot(Tri,buf_x,buf_y,'w');
                                xlabel('Wavelength [nm]')
                                ylabel('P [m]')
                                xlim([min(lambdaA_z(:,i_z)) max(lambdaA_z(:,i_z))])
                                ylim([min(r) max(r)])
                            else
                                h.ZData = grid_z;
                                Tri = delaunay(buf_x,buf_y);
                                delete(trp)
                                trp = triplot(Tri,buf_x,buf_y,'w');
                                drawnow
                            end
                            title(['Interpolated Spectra at Z = ',num2str(z(i_z)), '[m]'])
                        end
                    end
                end

                %---アーベル変換----
                Local_spectra = zeros(size(lambdaA_z,1),numel(r),numel(z),numel(t));
                for i_t = 1:numel(t)
                    for i_z = 1:numel(z)
                        derivative = diff(spectra_interp(:,:,i_z,i_t),1,2)/dr;
                        for i_l=1:size(lambdaA_z,1)
                            for i_r=1:numel(r)
                                for j_r=i_r:numel(r)-1
                                    Local_spectra(i_l,i_r,i_z,i_t) = Local_spectra(i_l,i_r,i_z,i_t) - 1/pi*derivative(i_l,j_r)...
                                        *log(r(j_r+1)*(1+sqrt(1-(r(i_r)/r(j_r+1))^2))/(r(j_r)*(1+sqrt(1-(r(i_r)/r(j_r))^2))));%Balandin's Abel inversion
                                end
                            end
                        end
                    end
                end
                % Local_spectra = movmean(Local_spectra,w_movmean_Local,1);%局所スペクトルのスムージング(波長方向)
                Local_spectra = movmean(Local_spectra,round((numel(r)-1)/16),2);%局所スペクトルのスムージング(R方向)
                Em_Local = zeros(numel(r),numel(z),numel(t));
                Ti_Local = zeros(numel(r),numel(z),numel(t));
                Ti_Local_max = zeros(numel(r),numel(z),numel(t));
                Ti_Local_min = zeros(numel(r),numel(z),numel(t));
                Ti_instru_Local = zeros(numel(z),numel(t));
                checker = ones(numel(r),numel(z),numel(t));
                RSQ = zeros(numel(r),numel(z),numel(t));
                for i_t =1:numel(t)
                    for i_z=1:numel(z)
                        % Ti_instru_Local(i_z,i_t) = sum(Ti_instru_CH_gf((i_z-1)*numel(p)+1:i_z*numel(p)))/numel(p);%ガウスフィルター1回
                        Ti_instru_Local(i_z,i_t) = sum(Ti_instru_CH_gf2((i_z-1)*numel(p)+1:i_z*numel(p)))/numel(p);%ガウスフィルター2回
                    end
                end
                %----フィッティング----
                col_subp2 = 2;%サブプロット行数
                raw_subp2 = 2;%サブプロット列数
                n_subp2 = col_subp2*raw_subp2;
                col_subp_f = 2;%サブプロット行数
                raw_subp_f = 2;%サブプロット列数
                n_subp_f = col_subp_f*raw_subp_f;
                idx_f_fit = 1;
                col_subp_t = 2;%サブプロット行数
                raw_subp_t = 2;%サブプロット列数
                n_subp_t = col_subp_t*raw_subp_t;
                idx_t_fit = 1;
                for i_t = 1:numel(t)
                    for i_z=1:numel(z)
                        for i_r=1:numel(r)
                            idx_fit = (i_z-1)*numel(r)+i_r;%スペクトル番号
                            input = Local_spectra(:,i_r,i_z,i_t);
                            for i_l=1:size(lambdaA_z,1)
                                if input(i_l) < 0
                                    input(i_l) = -input(i_l) - min(abs(movmean(input,20)));
                                end
                            end
                            input = conv(input, gaussFilter, 'same');%ガウスフィルターをかける
                            max_sp_Local = max(input);
                            survived_xy_Local = [lambdaA_z(:,i_z) input]; %[波長,強度]
                            deleted_xy_Local = zeros(1,2);
                            j_SN_Local = 1;
                            flag_SN_Local = 0;
                            while j_SN_Local < size(survived_xy_Local,1)+1 %SNの悪いデータを除く
                                if survived_xy_Local(j_SN_Local,2) < max_sp_Local*sp_th_ratio
                                    if flag_SN_Local == 0
                                        deleted_xy_Local = survived_xy_Local(j_SN_Local,:);
                                        flag_SN_Local = 1;
                                    else
                                        deleted_xy_Local = cat(1,deleted_xy_Local,survived_xy_Local(j_SN_Local,:));
                                    end
                                    survived_xy_Local(j_SN_Local,:) = [];
                                else
                                    j_SN_Local = j_SN_Local+1;
                                end
                            end
                            try
                                [f,gof] = fit(survived_xy_Local(:,1),survived_xy_Local(:,2),'gauss1');
                                % [f,gof] = fit(lambdaA_z(hw_lambdaA+1-hw_fit:hw_lambdaA+1+hw_fit,i_z),input(hw_lambdaA+1-hw_fit:hw_lambdaA+1+hw_fit),'gauss1');
                                RSQ(i_r,i_z,i_t) = gof.rsquare;%決定係数(フィッティング精度指標)
                                coeff = coeffvalues(f);%フィッティング係数
                                % coeff(3)/resolution_z/sqrt(2);%IDLのcoeff[2]に等しい(確認用)
                                confi = confint(f);%フィッティング係数の95%信頼区間(1行目下限, 2行目上限)
                                Ti_Local(i_r,i_z,i_t) = 1.69e8*mass*(2*coeff(3)*sqrt(log(2))/lambda0)^2-Ti_instru_Local(i_z,i_t);
                                Ti_Local_max(i_r,i_z,i_t) = 1.69e8*mass*(2*confi(2,3)*sqrt(log(2))/lambda0)^2-Ti_instru_Local(i_z,i_t);
                                Ti_Local_min(i_r,i_z,i_t) = 1.69e8*mass*(2*confi(1,3)*sqrt(log(2))/lambda0)^2-Ti_instru_Local(i_z,i_t);
                                Em_Local(i_r,i_z,i_t) = abs(resolution_z(i_z))*sum(input);
                                %外れ値(checker=0)の条件
                                checker(i_r,i_z,i_t) = checker(i_r,i_z,i_t) * (abs(coeff(2)-lambda0) < 0.07);
                                checker(i_r,i_z,i_t) = checker(i_r,i_z,i_t) * (coeff(1) > 0);
                                checker(i_r,i_z,i_t) = checker(i_r,i_z,i_t) * (Em_Local(i_r,i_z,i_t) > 0);
                                checker(i_r,i_z,i_t) = checker(i_r,i_z,i_t) * (Ti_Local(i_r,i_z,i_t) > 0);
                                checker(i_r,i_z,i_t) = checker(i_r,i_z,i_t) * (RSQ(i_r,i_z,i_t) > RSQ_Local_th_ratio);
                                fitted_x = lambdaA_z(:,i_z);
                                fitted_y = feval(f,fitted_x);
                                switch plot_Local_spectra
                                    case 'off'
                                    case 'all'
                                        idx_subp2 = mod(idx_fit-1,n_subp2)+1;%サブプロット位置番号
                                        if idx_fit == 1
                                            figure('Position',[400 500 400 300]);
                                            sgtitle(['Local Spectra at (Z,R) t = ',num2str(t(i_t)),'ms'])
                                        end
                                        subplot(col_subp2,raw_subp2,idx_subp2)
                                        if idx_fit <= n_subp2
                                            if idx_fit == 1
                                                if checker(i_r,i_z,i_t) == 1
                                                    p_fitted = plot(fitted_x,fitted_y,'r-','LineWidth',2);
                                                else
                                                    p_fitted = plot(fitted_x,fitted_y,'g-','LineWidth',2);
                                                end
                                                hold on
                                                p_survived = plot(survived_xy_Local(:,1),survived_xy_Local(:,2),'bo','MarkerSize',8,'LineWidth',0.8);
                                                hold on
                                                p_deleted = plot(deleted_xy_Local(:,1),deleted_xy_Local(:,2),'kx','MarkerSize',12,'LineWidth',0.8);
                                                p_fitted = repmat(p_fitted,[1,n_subp2]);
                                                p_survived = repmat(p_survived,[1,n_subp2]);
                                                p_deleted = repmat(p_deleted,[1,n_subp2]);
                                            else
                                                if checker_CH(i_CH,i_t) == 1
                                                    p_fitted(:,idx_subp2) = plot(fitted_x,fitted_y,'r-','LineWidth',2);
                                                else
                                                    p_fitted(:,idx_subp2) = plot(fitted_x,fitted_y,'g-','LineWidth',2);
                                                end
                                                hold on
                                                p_survived(:,idx_subp2) = plot(survived_xy_Local(:,1),survived_xy_Local(:,2),'bo','MarkerSize',8,'LineWidth',0.8);
                                                hold on
                                                p_deleted(:,idx_subp2) = plot(deleted_xy_Local(:,1),deleted_xy_Local(:,2),'kx','MarkerSize',12,'LineWidth',0.8);
                                            end
                                            xline(lambda0)
                                            title(sprintf("(%.1f,%.1f,%.1f)",z(i_z)*1e3,r(i_r)*1e3,t(i_t)))
                                            xlabel('Wavelength [nm]')
                                            ylabel('Strength [a.u.]')
                                            xlim([min(lambdaA_z(:,i_z)) max(lambdaA_z(:,i_z))])
                                            ylim([0 inf])
                                            legend('off')
                                        else
                                            p_fitted(1,idx_subp2).YData = fitted_y;
                                            if checker(i_r,i_z,i_t) == 1
                                                p_fitted(1,idx_subp2).Color = 'r';
                                            else
                                                p_fitted(1,idx_subp2).Color = 'g';
                                            end
                                            p_survived(1,idx_subp2).XData = survived_xy_Local(:,1);
                                            p_survived(1,idx_subp2).YData = survived_xy_Local(:,2);
                                            p_deleted(1,idx_subp2).XData = deleted_xy_Local(:,1);
                                            p_deleted(1,idx_subp2).YData = deleted_xy_Local(:,2);
                                            title(sprintf("(%.1f,%.1f,%.1f)",z(i_z)*1e3,r(i_r)*1e3,t(i_t)))
                                            drawnow
                                        end
                                    case 'good'
                                        if checker(i_r,i_z,i_t) == 1
                                            idx_subp_t = mod(idx_t_fit-1,n_subp_t)+1;%サブプロット位置番号
                                            if idx_t_fit == 1
                                                figure('Position',[400 500 400 300]);
                                                sgtitle(['Good Spectra at (Z,R) t = ',num2str(t(i_t)),'ms'])
                                            end
                                            subplot(col_subp_t,raw_subp_t,idx_subp_t)
                                            if idx_t_fit <= n_subp_t
                                                if idx_t_fit == 1
                                                    p_fitted = plot(fitted_x,fitted_y,'r-','LineWidth',2);
                                                    hold on
                                                    p_survived = plot(survived_xy_Local(:,1),survived_xy_Local(:,2),'bo','MarkerSize',8,'LineWidth',0.8);
                                                    hold on
                                                    p_deleted = plot(deleted_xy_Local(:,1),deleted_xy_Local(:,2),'kx','MarkerSize',12,'LineWidth',0.8);
                                                    p_fitted = repmat(p_fitted,[1,n_subp2]);
                                                    p_survived = repmat(p_survived,[1,n_subp2]);
                                                    p_deleted = repmat(p_deleted,[1,n_subp2]);
                                                else
                                                    p_fitted(:,idx_subp_t) = plot(fitted_x,fitted_y,'r-','LineWidth',2);
                                                    hold on
                                                    p_survived(:,idx_subp_t) = plot(survived_xy_Local(:,1),survived_xy_Local(:,2),'bo','MarkerSize',8,'LineWidth',0.8);
                                                    hold on
                                                    p_deleted(:,idx_subp_t) = plot(deleted_xy_Local(:,1),deleted_xy_Local(:,2),'kx','MarkerSize',12,'LineWidth',0.8);
                                                end
                                                title(sprintf("(%.1f,%.1f,%.1f)",z(i_z)*1e3,r(i_r)*1e3,t(i_t)))
                                                xline(lambda0)
                                                xlabel('Wavelength [nm]')
                                                ylabel('Strength [a.u.]')
                                                xlim([min(lambdaA_z(:,i_z)) max(lambdaA_z(:,i_z))])
                                                ylim([0 inf])
                                                legend('off')
                                            else
                                                p_fitted(1,idx_subp_t).YData = fitted_y;
                                                p_survived(1,idx_subp_t).XData = survived_xy_Local(:,1);
                                                p_survived(1,idx_subp_t).YData = survived_xy_Local(:,2);
                                                p_deleted(1,idx_subp_t).XData = deleted_xy_Local(:,1);
                                                p_deleted(1,idx_subp_t).YData = deleted_xy_Local(:,2);
                                                title(sprintf("(%.1f,%.1f,%.1f)",z(i_z)*1e3,r(i_r)*1e3,t(i_t)))
                                                drawnow
                                            end
                                            idx_t_fit = idx_t_fit + 1;
                                        end
                                    case 'bad'
                                        if checker(i_r,i_z,i_t) == 0
                                            idx_subp_f = mod(idx_f_fit-1,n_subp_f)+1;%サブプロット位置番号
                                            if idx_f_fit == 1
                                                figure('Position',[400 500 400 300])
                                                sgtitle(['Bad Spectra at (Z,R) t = ',num2str(t(i_t)),'ms'])
                                            end
                                            subplot(col_subp_f,raw_subp_f,idx_subp_f)
                                            if idx_f_fit <= n_subp_f
                                                if idx_f_fit == 1
                                                    p_fitted = plot(fitted_x,fitted_y,'g-','LineWidth',2);
                                                    hold on
                                                    p_survived = plot(survived_xy_Local(:,1),survived_xy_Local(:,2),'bo','MarkerSize',8,'LineWidth',0.8);
                                                    hold on
                                                    p_deleted = plot(deleted_xy_Local(:,1),deleted_xy_Local(:,2),'kx','MarkerSize',12,'LineWidth',0.8);
                                                    p_fitted = repmat(p_fitted,[1,n_subp2]);
                                                    p_survived = repmat(p_survived,[1,n_subp2]);
                                                    p_deleted = repmat(p_deleted,[1,n_subp2]);
                                                else
                                                    p_fitted(:,idx_subp_f) = plot(fitted_x,fitted_y,'g-','LineWidth',2);
                                                    hold on
                                                    p_survived(:,idx_subp_f) = plot(survived_xy_Local(:,1),survived_xy_Local(:,2),'bo','MarkerSize',8,'LineWidth',0.8);
                                                    hold on
                                                    p_deleted(:,idx_subp_f) = plot(deleted_xy_Local(:,1),deleted_xy_Local(:,2),'kx','MarkerSize',12,'LineWidth',0.8);
                                                end
                                                title(sprintf("(%.1f,%.1f,%.1f)",z(i_z)*1e3,r(i_r)*1e3,t(i_t)))
                                                xline(lambda0)
                                                xlabel('Wavelength [nm]')
                                                ylabel('Strength [a.u.]')
                                                xlim([min(lambdaA_z(:,i_z)) max(lambdaA_z(:,i_z))])
                                                ylim([0 inf])
                                                legend('off')
                                            else
                                                p_fitted(1,idx_subp_f).YData = fitted_y;
                                                p_survived(1,idx_subp_f).XData = survived_xy_Local(:,1);
                                                p_survived(1,idx_subp_f).YData = survived_xy_Local(:,2);
                                                p_deleted(1,idx_subp_f).XData = deleted_xy_Local(:,1);
                                                p_deleted(1,idx_subp_f).YData = deleted_xy_Local(:,2);
                                                title(sprintf("(%.1f,%.1f,%.1f)",z(i_z)*1e3,r(i_r)*1e3,t(i_t)))
                                                drawnow
                                            end
                                            idx_f_fit = idx_f_fit + 1;
                                        end
                                    otherwise
                                        warning('Input error in plot_Local_spectra.')%ICCD.lineの入力エラー
                                        return;
                                end
                            catch ME
                                checker(i_r,i_z,i_t) = 0;
                                warning("Fitting failed in (Z,R,t) = (%.1f,%.1f,%.1f)",z(i_z)*1e3,r(i_r)*1e3,t(i_t));
                            end
                        end
                    end
                end
                %発光強度の小さい場所を除く
                for i_t = 1:numel(t)
                    checker(:,:,i_t) = checker(:,:,i_t).*(Em_Local(:,:,i_t) > Em_th_ratio*max(Em_Local(:,:,i_t),[],'all'));
                end
                %NaNを除去
                for i_t = 1:numel(t)
                    for i_r=1:numel(r)
                        for i_z=1:numel(z)
                            if isnan(Ti_Local(i_r,i_z,i_t))
                                Ti_Local(i_r,i_z,i_t) = 0;
                                Ti_Local_max(i_r,i_z,i_t) = 0;
                                Ti_Local_min(i_r,i_z,i_t) = 0;
                                fprintf('Ti_Local(%d,%d,%d) is NaN.',i_r,i_z,i_t);
                            end
                        end
                    end
                end
                % 外れ値(checker=0)を補間
                for i_t = 1:numel(t)
                    for i_r=1:numel(r)
                        for i_z=1:numel(z)
                            if checker(i_r,i_z,i_t) == 0
                                Ti_Local(i_r,i_z,i_t) = 0;
                                Ti_Local_max(i_r,i_z,i_t) = 0;
                                Ti_Local_min(i_r,i_z,i_t) = 0;
                            end
                        end
                    end
                end
                Ti_Local_smooth = filloutliers(Ti_Local,"linear");
                Ti_Local_smooth = movmean(Ti_Local_smooth,w_movmean_Local,1);
                Ti_Local_smooth = movmean(Ti_Local_smooth,round((numel(r)-1)/16),2);
                Ti_Local_max_smooth = filloutliers(Ti_Local_max,"linear");
                Ti_Local_max_smooth = movmean(Ti_Local_max_smooth,w_movmean_Local,1);
                Ti_Local_max_smooth = movmean(Ti_Local_max_smooth,round((numel(r)-1)/16),2);
                Ti_Local_min_smooth = filloutliers(Ti_Local_min,"linear");
                Ti_Local_min_smooth = movmean(Ti_Local_min_smooth,w_movmean_Local,1);
                Ti_Local_min_smooth = movmean(Ti_Local_min_smooth,round((numel(r)-1)/16),2);
                for i_t=1:numel(t)
                    for i_r=1:numel(r)
                        for i_z=1:numel(z)
                            if checker(i_r,i_z,i_t) == 0
                                Ti_Local(i_r,i_z,i_t) = Ti_Local_smooth(i_r,i_z,i_t);
                                Ti_Local_max(i_r,i_z,i_t) = Ti_Local_max_smooth(i_r,i_z,i_t);
                                Ti_Local_min(i_r,i_z,i_t) = Ti_Local_min_smooth(i_r,i_z,i_t);
                                fprintf('Ti(%d,%d,%d) was interpolated.\n',i_r,i_z,i_t);
                            end
                        end
                    end
                end
                negative = find(Ti_Local<0);
                Ti_Local(negative) = zeros(size(negative));
            end
            %移動平均
            Ti_Local = filloutliers(Ti_Local,"linear");
            Ti_Local = movmean(Ti_Local,2,1);
            Ti_Local = movmean(Ti_Local,2,2);

            ST40IDSdata =struct(...
                'shot_num',shot_num,...
                'frame',frame,...
                't',t,...
                'z',z,...
                'r',r,...
                'p',p,...
                'Ti_Local',Ti_Local,...
                'Em_Local',Em_Local,...
                'Ti_LineInt',Ti_LineInt,...
                'Em_LineInt',Em_LineInt,...
                'checker',checker);
            save(savename,'ST40IDSdata')
        end

        if plot_PZ_LineInt
            for i_t = 1:numel(ST40IDSdata.t)
                figure('Position',[0 0 700 350])
                tile_LineInt = tiledlayout(2,1);
                title(tile_LineInt,['t = ',num2str(ST40IDSdata.t(i_t)),'ms'])
                ax1 = nexttile;
                [~,h] = contourf(ST40IDSdata.z,ST40IDSdata.p,squeeze(ST40IDSdata.Ti_LineInt(:,:,i_t)),100);
                h.LineStyle = 'none';
                daspect([1 1 1])
                colormap(ax1,jet)
                title('Line Integrated Ion Temperature')
                xlabel('Z [m]')
                ylabel('P [m]')
                c1 = colorbar;
                c1.Label.String = 'Ion Temperature [eV]';
                clim([0 300])
                view([90 -90])%RZ反転
                ax2 = nexttile;
                [~,h] = contourf(ST40IDSdata.z,ST40IDSdata.p,squeeze(ST40IDSdata.Em_LineInt(:,:,i_t)),100);
                h.LineStyle = 'none';
                daspect([1 1 1])
                colormap(ax2,pink)
                title('Line Integrated Ion Emission')
                xlabel('Z [m]')
                ylabel('P [m]')
                c2 = colorbar;
                c2.Label.String = 'Ion Emission [a.u.]';
                view([90 -90])%RZ反転
                drawnow;
                figname = [pathname.fig,'/ST40_Doppler/','shot', num2str(ST40IDSdata.shot_num),'_',num2str(ST40IDSdata.t(i_t)),'ms_LineInt.png'];
                if ~exist(figname,'file')
                    saveas(gcf,figname)
                end
                hold off
                close
            end
        end

        if plot_RZ_Local
            frames_Ti(numel(ST40IDSdata.t)) = struct('cdata', [], 'colormap', []); % 各フレームの画像データを格納する配列
            frames_Em(numel(ST40IDSdata.t)) = struct('cdata', [], 'colormap', []); % 各フレームの画像データを格納する配列
            for i_t=1:numel(ST40IDSdata.t)
                fig_Ti = figure('Position',[0 600 700 400]);
                [~,h] = contourf(ST40IDSdata.z,ST40IDSdata.r,ST40IDSdata.Ti_Local(:,:,i_t),100);
                hold on
                for i_r=1:numel(ST40IDSdata.r)
                    for i_z=1:numel(ST40IDSdata.z)
                        % if ST40IDSdata.checker(i_r,i_z,i_t) == 1
                            plot(ST40IDSdata.z(i_z),ST40IDSdata.r(i_r),'m+','MarkerSize',7,'LineWidth',2)%フィッティング結果採用した点を表示
                        % end
                    end
                end
                daspect([1 1 1])
                h.LineStyle = 'none';
                colormap(jet)
                title(['shot ',num2str(ST40IDSdata.shot_num),newline,'Local Ion Temperature (',num2str(ST40IDSdata.t(i_t)),'ms)'])
                xlabel('Z [m]')
                ylabel('R [m]')
                % xlim([ST40IDSdata.z(1) ST40IDSdata.z(3)])%石英ファイバーのみ
                ylim([ST40IDSdata.p(1) ST40IDSdata.p(end)])
                % clim([min(ST40IDSdata.Ti_Local,[],'all') max(ST40IDSdata.Ti_Local,[],'all')])
                clim([100 350])
                view([90 -90])%RZ反転
                c1 = colorbar;
                c1.Label.String = 'Ion Temperature [eV]';
                drawnow; % 描画を確実に実行させる
                frames_Ti(i_t) = getframe(fig_Ti); % 図を画像データとして得る
                % savefig(fig_Ti,['fig/shot',num2str(ST40IDSdata.shot_num),'_',num2str(ST40IDSdata.t(i_t)),'ms_Ti.fig']);
                figname = [pathname.fig,'/ST40_Doppler/','shot', num2str(ST40IDSdata.shot_num),'_',num2str(ST40IDSdata.t(i_t)),'ms_Ti.png'];
                if ~exist(figname,'file')
                    saveas(gcf,figname)
                end
                hold off
                % close
                if gif_RZ_Local
                    close(fig_Ti)
                end
                fig_Em = figure('Position',[0 600 700 400]);
                [~,h] = contourf(ST40IDSdata.z,ST40IDSdata.r,ST40IDSdata.Em_Local(:,:,i_t),100);
                hold on
                % for i_r=1:numel(ST40IDSdata.r)
                %     for i_z=1:numel(ST40IDSdata.z)
                %         if ST40IDSdata.checker(i_r,i_z,i_t) == 1
                %             plot(ST40IDSdata.z(i_z),ST40IDSdata.r(i_r),'m+','MarkerSize',7,'LineWidth',2)%フィッティング結果採用した点を表示
                %         end
                %     end
                % end
                daspect([1 1 1])
                h.LineStyle = 'none';
                colormap(pink)
                title(['shot ',num2str(ST40IDSdata.shot_num),newline,'Local Ion Emission (',num2str(ST40IDSdata.t(i_t)),'ms)'])
                xlabel('Z [m]')
                ylabel('R [m]')
                % xlim([ST40IDSdata.z(1) ST40IDSdata.z(3)])%石英ファイバーのみ
                ylim([ST40IDSdata.p(1) ST40IDSdata.p(end)])
                % clim([min(ST40IDSdata.Em_Local,[],'all') max(ST40IDSdata.Em_Local,[],'all')])
                clim([0 4E4])
                view([90 -90])%RZ反転
                c2 = colorbar;
                c2.Label.String = 'Ion Emission [a.u.]';
                drawnow; % 描画を確実に実行させる
                frames_Em(i_t) = getframe(fig_Em); % 図を画像データとして得る
                % savefig(fig_Em,['fig/shot',num2str(ST40IDSdata.shot_num),'_',num2str(ST40IDSdata.t(i_t)),'ms_Emission.fig']);
                figname = [pathname.fig,'/ST40_Doppler/','shot', num2str(ST40IDSdata.shot_num),'_',num2str(ST40IDSdata.t(i_t)),'ms_Emission.png'];
                if ~exist(figname,'file')
                    saveas(gcf,figname)
                end
                hold off
                % close
                if gif_RZ_Local
                    close(fig_Em)
                end
            end
            if gif_RZ_Local
                if numel(ST40IDSdata.frame) > 1
                    filename_Ti = [num2str(ST40IDSdata.shot_num),'_IonTemp.gif']; % ファイル名
                    for i_t = 1:numel(ST40IDSdata.t)
                        [A, map] = rgb2ind(frame2im(frames_Ti(i_t)), 256); % 画像形式変換
                        if i_t == 1
                            imwrite(A, map, filename_Ti, 'gif', 'DelayTime', 1/3, 'LoopCount', Inf); % 出力形式(30FPS)を設定
                        else
                            imwrite(A, map, filename_Ti, 'gif', 'DelayTime', 1/3, 'WriteMode', 'append'); % 2フレーム目以降は"追記"の設定も必要
                        end
                    end
                    filename_Em = [num2str(ST40IDSdata.shot_num),'_IonEmission.gif']; % ファイル名
                    for i_t = 1:numel(ST40IDSdata.t)
                        [A, map] = rgb2ind(frame2im(frames_Em(i_t)), 256); % 画像形式変換
                        if i_t == 1
                            imwrite(A, map, filename_Em, 'gif', 'DelayTime', 1/3, 'LoopCount', Inf); % 出力形式(30FPS)を設定
                        else
                            imwrite(A, map, filename_Em, 'gif', 'DelayTime', 1/3, 'WriteMode', 'append'); % 2フレーム目以降は"追記"の設定も必要
                        end
                    end
                end
            end
        end
        if plot_tR_z
            if numel(ST40IDSdata.frame) > 1
                for i_z=1:numel(ST40IDSdata.z)
                    figure('Position',[1000 1000 600 450])
                    tiledlayout(2,1)
                    ax1 = nexttile;
                    [~,h] = contourf(ST40IDSdata.t,ST40IDSdata.r,squeeze(ST40IDSdata.Ti_Local(:,i_z,:)),100);
                    h.LineStyle = 'none';
                    colormap(ax1,jet)
                    title(['Local Ion Temperature (z =',num2str(ST40IDSdata.z(i_z)),'m)'])
                    xlabel('t [ms]')
                    ylabel('R [m]')
                    c1 = colorbar;
                    c1.Label.String = 'Ion Temperature [eV]';
                    ax2 = nexttile;
                    [~,h] = contourf(ST40IDSdata.t,ST40IDSdata.r,squeeze(ST40IDSdata.Em_Local(:,i_z,:)),100);
                    h.LineStyle = 'none';
                    colormap(ax2,pink)
                    title(['Local Ion Emission (z =',num2str(ST40IDSdata.z(i_z)),'m)'])
                    xlabel('t [ms]')
                    ylabel('R [m]')
                    ylim([ST40IDSdata.p(1) ST40IDSdata.p(end)])
                    c2 = colorbar;
                    c2.Label.String = 'Ion Emission [a.u.]';
                end
            end
        end
        if plot_tR_silica
            if numel(ST40IDSdata.frame) > 1
                figure('Position',[1000 1000 600 450])
                tiledlayout(2,1)
                ax1 = nexttile;
                Ti_silica = squeeze(sum(ST40IDSdata.Ti_Local(:,1:3,:),2)/3);
                [~,h] = contourf(ST40IDSdata.t,ST40IDSdata.r,Ti_silica,100);
                h.LineStyle = 'none';
                colormap(ax1,jet)
                title('Local Ion Temperature (Silica fibers)')
                xlabel('t [ms]')
                ylabel('R [m]')
                ylim([ST40IDSdata.p(1) ST40IDSdata.p(end)])
                clim([min(Ti_silica,[],'all') max(Ti_silica,[],'all')])
                c1 = colorbar;
                c1.Label.String = 'Ion Temperature [eV]';
                ax2 = nexttile;
                Em_silica = squeeze(sum(ST40IDSdata.Em_Local(:,1:3,:),2)/3);
                [~,h] = contourf(ST40IDSdata.t,ST40IDSdata.r,Em_silica,100);
                h.LineStyle = 'none';
                colormap(ax2,pink)
                title('Local Ion Emission (Silica fibers)')
                xlabel('t [ms]')
                ylabel('R [m]')
                clim([min(Em_silica,[],'all') max(Em_silica,[],'all')])
                c2 = colorbar;
                c2.Label.String = 'Ion Emission [a.u.]';
            end
        end
    end
    % close all
end

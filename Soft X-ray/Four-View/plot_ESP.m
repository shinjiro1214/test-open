function plot_ESP(PCBgrid2D,PCBdata2D,ESPdata2D,ExBdata2D,newPCBdata2D,IDSP,FIG,color_type,vector_type,multi_analysis, ESP,PCB)
%グラフ
[magAxisList,xPointList] = get_axis_x_multi(PCBgrid2D,PCBdata2D,PCB);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if not(multi_analysis)
    figure('Position', [0 0 1500 1500],'visible','on')
end

for i = 1:FIG.tate*FIG.yoko
    offset_ESP_t = knnsearch(ESPdata2D.trange',FIG.start);
    idx_ESP_t = offset_ESP_t+(i-1)*FIG.dt*10;
    offset_PCB_t = knnsearch(PCBdata2D.trange',FIG.start);
    idx_PCB_t = offset_PCB_t+(i-1)*FIG.dt;
    if not(multi_analysis)
        subplot(FIG.tate,round(FIG.yoko),i)
    end
    %カラープロット
    switch color_type
        case 'phi'
            contourf(ESPdata2D.zq,ESPdata2D.rq,squeeze(ESPdata2D.phi(idx_ESP_t,:,:)),100,'edgecolor','none');
            c = colorbar;
            clim([-100 100]);
            % clim([-240 240])
            c.Label.String = 'Floating Potential [V]';
        case 'Ez'
            contourf(ESPdata2D.zq,ESPdata2D.rq,squeeze(ESPdata2D.Ez(idx_ESP_t,:,:)),100,'edgecolor','none');
            c = colorbar;
            % clim([-5000 5000])
            clim([-1000 1000])
            c.Label.String = 'E_z [V/m]';
        case 'Er'
            contourf(ESPdata2D.zq,ESPdata2D.rq,squeeze(ESPdata2D.Er(idx_ESP_t,:,:)),100,'edgecolor','none');
            c = colorbar;
            % clim([-5000 5000])
            clim([-1000 1000])
            c.Label.String = 'E_r [V/m]';
        case '|VExB|'
            contourf(ESPdata2D.zq,ESPdata2D.rq,ExBdata2D.absVExB(:,:,i),100,'edgecolor','none');
            c = colorbar;
            % clim([0 1e-4])
            clim([0 3]); 
            disp(max(max(ExBdata2D.absVExB(:,:,i))))
            c.Label.String = '|V_{ExB}| [km/s]';
        case 'VExBr'
            contourf(ESPdata2D.zq,ESPdata2D.rq,ExBdata2D.VExB_r(:,:,i),100,'edgecolor','none');
            c = colorbar;
            disp(max(max(ExBdata2D.VExB_r(:,:,i))))
            % clim([-3e-3 3e-3])
            clim([-3e2 3e2])
            if ESP.date == 240828 || ESP.date == 240827
                clim([-3,3]);
            end
            c.Label.String = 'R component of V_{ExB} [km/s]';
        case 'VExBz'
            contourf(ESPdata2D.zq,ESPdata2D.rq,ExBdata2D.VExB_z(:,:,i),100,'edgecolor','none');
            c = colorbar;
            % clim([-3e-5 3e-5])
            clim([-3e2 3e2])
            c.Label.String = 'Z component of V_{ExB} [km/s]';
        case 'VExBt'
            contourf(ESPdata2D.zq,ESPdata2D.rq,ExBdata2D.VExB_t(:,:,i),100,'edgecolor','none');
            c = colorbar;
            clim([-3e2 3e2])
            disp(max(max(ExBdata2D.VExB_t(:,:,i))))
            c.Label.String = 't component of V_{ExB} [km/s]';
        case 'psi'
            contourf(ESPdata2D.zq,ESPdata2D.rq,newPCBdata2D.psi(:,:,idx_PCB_t),80,'LineStyle','none')
            clim([-10e-3,10e-3])%psi
            c = colorbar;
            c.Label.String = 'Psi [Wb]';
        case 'Bt'
            contourf(ESPdata2D.zq,ESPdata2D.rq,newPCBdata2D.Bt(:,:,idx_PCB_t),50,'LineStyle','none')
            clim([0.1,5])%Bt
            disp(max(max(newPCBdata2D.Bt(:,:,idx_PCB_t))))
            c = colorbar;
            c.Label.String = 'B_t [T]';
        case 'Bt_ext'
            contourf(ESPdata2D.zq,ESPdata2D.rq,newPCBdata2D.Bt_ext(:,:,idx_PCB_t),50,'LineStyle','none')
            clim([0.1,0.4])%Bt_ext
            c = colorbar;
            c.Label.String = 'B_t by TF cur. [T]';
        case 'Bt_plasma'
            contourf(ESPdata2D.zq,ESPdata2D.rq,newPCBdata2D.Bt_plasma(:,:,idx_PCB_t),50,'LineStyle','none')
            clim([-0.01,0.04])%Bt_plasma
            c = colorbar;
            c.Label.String = 'B_t by plasma [T]';
        case 'Br'
            contourf(ESPdata2D.zq,ESPdata2D.rq,newPCBdata2D.Br(:,:,idx_PCB_t),100,'LineStyle','none')
            clim([-0.04,0.04])%Br
            c = colorbar;
            c.Label.String = 'B_r [T]';
        case 'Bz'
            contourf(ESPdata2D.zq,ESPdata2D.rq,newPCBdata2D.Bz(:,:,idx_PCB_t),100,'LineStyle','none')
            clim([-0.04,0.04])%Bz
            c = colorbar;
            c.Label.String = 'B_z [T]';
        case 'absB'
            contourf(ESPdata2D.zq,ESPdata2D.rq,sqrt(newPCBdata2D.absB2(:,:,idx_PCB_t)),100,'LineStyle','none')
            clim([0,0.4])%|B| [T]
            c = colorbar;
            c.Label.String = '|B| [T]';
        case 'absB2'
            contourf(ESPdata2D.zq,ESPdata2D.rq,newPCBdata2D.absB2(:,:,idx_PCB_t),100,'LineStyle','none')
            clim([0,0.1])%|B| [T]
            c = colorbar;
            c.Label.String = '|B|^2 [T^2]';
        case 'absE'
            contourf(ESPdata2D.zq,ESPdata2D.rq,ExBdata2D.absE(:,:,i),100,'LineStyle','none')
            clim([0, 2e3])%|B| [T]
            c = colorbar;
            c.Label.String = '|E| [T]';
        case 'Et'
            contourf(ESPdata2D.zq,ESPdata2D.rq,newPCBdata2D.Et(:,:,idx_PCB_t),100,'LineStyle','none')
            % clim([-2e-4,2e-4])%Et
            clim([-8e2 8e2]);
            c = colorbar;
            c.Label.String = 'E_t [V/m]';
            % disp(max(max(newPCBdata2D.Et(:,:,idx_PCB_t))))
        case 'Jt'
            contourf(ESPdata2D.zq,ESPdata2D.rq,newPCBdata2D.Jt(:,:,idx_PCB_t),30,'LineStyle','none')
            clim([-1E6,1E6])%Jt
            c = colorbar;
            c.Label.String = 'Jt [A/m^{2}]';
        case 'betatron'
            contourf(ESPdata2D.zq,ESPdata2D.rq,ExBdata2D.betatron(:,:,i),30,'LineStyle','none')
            clim([-2e4,2e4])%betatron
            c = colorbar;
            c.Label.String = 'uEgradB+dBdt';
            % disp(max(max(ExBdata2D.betatron(:,:,i))))
        case 'fermi'
            contourf(ESPdata2D.zq,ESPdata2D.rq,ExBdata2D.fermi(:,:,i),30,'LineStyle','none')
            clim([-2e7,2e7])%fermi
            %clim([-5e4, 5e4]);
            % clim([-0.1, 0.3]);
            c = colorbar;
            c.Label.String = 'uEk';
            % c.Label.String = 'Fermi acceleration [eV/us]';
            disp( max(max(ExBdata2D.fermi(:,:,i))))
        case 'Epara'
            contourf(ESPdata2D.zq,ESPdata2D.rq,ExBdata2D.Epara(:,:,i),30,'LineStyle','none')
            clim([-5e3 5e3])
            c = colorbar;
            c.Label.String = 'E_para[V/m]';
            disp(max(max(ExBdata2D.Epara(:,:,i))))
    end
    if not(multi_analysis)
        switch color_type
            case {'phi','Ez','Er','Et','Jt','betatron','fermi','Epara'}
                colormap(redblue(3000));
            case {'psi','Bz','Br','Bt_ext','Bt_plasma','absB','absB2','VExBr','VExBz','VExBt','|VExB|'}
                colormap(jet)
        end
    end
    hold on
    

    if multi_analysis
        FIG.tate = 3;
    end
    %磁気面
    contour(PCBgrid2D.zq,PCBgrid2D.rq,squeeze(PCBdata2D.psi(:,:,idx_PCB_t)),-20e-3:0.2e-3:40e-3,'black','LineWidth',1)
    hold on
    switch vector_type
        case 'VExB'
            %ExBドリフトベクトル
            q = quiver(ESPdata2D.zq,ESPdata2D.rq,ExBdata2D.VExB_z(:,:,i),ExBdata2D.VExB_r(:,:,i),(1.5/FIG.tate+0.5)*5);
            q.Color = "k";
            q.LineWidth = 1;
            hold on
        case 'Ep'
            %電場ベクトル
            q = quiver(ESPdata2D.zq(2:end-1,2:end-1),ESPdata2D.rq(2:end-1,2:end-1),squeeze(ESPdata2D.Ez(idx_ESP_t,2:end-1,2:end-1)),squeeze(ESPdata2D.Er(idx_ESP_t,2:end-1,2:end-1)),1.5);
            q.Color = "k";
            q.LineWidth = 1;
            hold on
    end
    %ESP計測点
    plotESP = false;
    if plotESP
        for i_r = 1: size(ESPdata2D.rprobe,1)
            for i_z = 1: size(ESPdata2D.zprobe,2)
                p = plot(ESPdata2D.zprobe(1,i_z),ESPdata2D.rprobe(i_r,1),"g+");%測定位置
                p.LineWidth = 2;
                p.MarkerSize = 8;
            end
        end
    end
    hold on
    
    plot(xPointList.z(idx_PCB_t),xPointList.r(idx_PCB_t),'kx','LineWidth',3);
    %IDSP計測点
    % IDSP.r1 = linspace(0.09,0.235,7);
    % IDSP.r1(5) = [];
    % IDSP.z(5) = [];
    % IDSP.r2 = IDSP.r1+0.01;
    % IDSP.r3 = IDSP.r1+0.02;
    % plot(IDSP.z,IDSP.r1,'r+',"MarkerSize",8/FIG.tate+2,"LineWidth",2/FIG.tate)
    % hold on
    % plot(IDSP.z,IDSP.r2,'r+',"MarkerSize",8/FIG.tate+2,"LineWidth",2/FIG.tate)
    % hold on
    % plot(IDSP.z,IDSP.r3,'r+',"MarkerSize",8/FIG.tate+2,"LineWidth",2/FIG.tate)
    title([num2str(ESPdata2D.trange(idx_ESP_t)) 'us'])
    % xlim([-0.05 0.1])
    % xlim([-0.2 0.2])
    xlim([-0.1275 0.1275])
    % ylim([0.08 0.27])
    % xlabel('Z [m]')
    % ylabel('R [m]')
    grid on
    daspect([1 1 1])
    view([90 -90])%RZ反転
    
    
end
% if not(multi_analysis)
%     sgtitle(color_type)
%     fontsize(18/FIG.tate+5,"points")
% end

hold off
sgtitle(strcat(num2str(ESP.date), ' ', color_type));

pathname_fig = getenv('ESP_savedata_path');
foldername_fig = strcat(pathname_fig,'/',num2str(ESP.date));
if exist(foldername_fig,'dir') == 0
    mkdir(foldername_fig);
end

savename = [foldername_fig,'/',num2str(ESP.date),'_shot'];
for i_shot = 1:numel(ESP.shotlist)
    if i_shot == 1
        savename =[savename,num2str(ESP.shotlist(i_shot))];
    else
        if ESP.shotlist(i_shot) == ESP.shotlist(i_shot-1)+1%連番の場合間の番号をファイル名に含まない
            if i_shot < numel(ESP.shotlist)
                if ESP.shotlist(i_shot+1) > ESP.shotlist(i_shot)+1
                    savename =[savename,'-',num2str(ESP.shotlist(i_shot))];
                end
            else
                savename =[savename,'-',num2str(ESP.shotlist(i_shot))];
            end
        else%連番でない場合ファイル名に含む
            savename =[savename,'_',num2str(ESP.shotlist(i_shot))];
        end
    end
end
savename = [savename,'_start:', num2str(FIG.start) ,'_dt:', num2str(FIG.dt),'_',color_type,'.png'];
savepath = fullfile(savename);
saveas(gcf,savepath);
hold off;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% X点におけるフェルミ加速度をプロット。
if true
    times = FIG.start:FIG.dt:FIG.start+FIG.dt*(FIG.tate*FIG.yoko-1);
    mergerate = get_merging_ratio(PCBdata2D,PCBgrid2D,times)
    all = zeros(size(times));
    prevz = 0;
    prevr = 0;
    for t = 1:FIG.tate*FIG.yoko
        

        i = FIG.tate*FIG.yoko; %X点暴れるから位置固定している
        offset_PCB_t = knnsearch(PCBdata2D.trange',FIG.start);
        idx_PCB_t = offset_PCB_t+(i-1)*FIG.dt;  
        disp(idx_PCB_t)
        z = xPointList.z(idx_PCB_t);
        r = xPointList.r(idx_PCB_t);
        % disp(z)
        % disp(r)
        difference = abs(ESPdata2D.zq - z);
        
        % 行列全体で z に最も近い値の位置（行と列のインデックス）を取得
        [~, linearIndex] = min(difference(:)); % 最小差分とその線形インデックス
        
        [~, zidx] = ind2sub(size(difference), linearIndex); % 行と列のインデックスに変換
        % if zidx == 15
        %     zidx = 13;
        % end
        
        difference = abs(ESPdata2D.rq - r);
        % disp(difference)
        % 行列全体で r に最も近い値の位置（行と列のインデックス）を取得
        [~, linearIndex] = min(difference(:)); % 最小差分とその線形インデックス
        % disp(linearIndex)
        [ridx, ~] = ind2sub(size(difference), linearIndex); % 行と列のインデックスに変換
        
        
        if isnan(z) || isnan(r)
            if t == 1
                zidx = 3;
                ridx = 13;
            else
                zidx = prevz;
                ridx = prevr;
            end
        end
        prevz = zidx;
        prevr = ridx;
        % disp(ridx)
        % disp(zidx)
        me = 9.11e-31;
        v_p = 1e6;
        % fermixpoint = ExBdata2D.fermi(zidx,ridx,t)*me*v_p*v_p*6.24e18*1e-6;
        % all(1,t) = fermixpoint;
        betatronxpoint = ExBdata2D.betatron(zidx,ridx,t)*1e-17*6.24e18*1e-6;
        all(1,t) = betatronxpoint;
    end
    mergerate = fillmissing(mergerate, 'linear');
    disp(mergerate)
    figure;
    smoothdata(all);
    plot(mergerate, all,'LineWidth', 4);
    xlim(mergerate([1 end]));
    % plot(times,all);%,'LineWidth', 2
    % xlim([times(1) times(end)]);
    % ylim([-2 8]);
    ylim([-0.5 0.5])
    title('betatron acceleration');
    xlabel('mergingrate [%]');
    ylabel('Energy Gain(betatron) [eV/us]');
end

if false
    figure; hold on;
    for i = 1:FIG.tate*FIG.yoko
        subplot(FIG.tate,round(FIG.yoko),i)
        offset_ESP_t = knnsearch(ESPdata2D.trange',FIG.start);
        idx_ESP_t = offset_ESP_t+(i-1)*FIG.dt*10;
        offset_PCB_t = knnsearch(PCBdata2D.trange',FIG.start);
        idx_PCB_t = offset_PCB_t+(i-1)*FIG.dt;
        z = xPointList.z(idx_PCB_t);
        

        % [~,zidx] = min(min(abs(ESPdata2D.zq - z)));
        difference = abs(ESPdata2D.zq - z);
        % 行列全体で z に最も近い値の位置（行と列のインデックス）を取得
        [~, linearIndex] = min(difference(:)); % 最小差分とその線形インデックス
        [~, zidx] = ind2sub(size(difference), linearIndex); % 行と列のインデックスに変換
        if zidx == 15
            zidx = 13;
        end
        phi_on_xpoint = ESPdata2D.phi(idx_ESP_t, :,zidx);
        phierr = ESPdata2D.phi_err(idx_ESP_t, :,zidx);
        % disp(Er_on_xpoint);
        % disp(ESPdata2D.rq(:,1))
        plot(ESPdata2D.rq(:,1),squeeze(phi_on_xpoint));
        % disp(phierr)
        errorbar(ESPdata2D.rq(:,1),squeeze(phi_on_xpoint),phierr, 'vertical');
        % ylim([-125 -50])
        % ylim([ ])
        xlim([0.1 0.3])
        title([num2str(ESPdata2D.trange(idx_ESP_t)) 'us'])
        
    end

end
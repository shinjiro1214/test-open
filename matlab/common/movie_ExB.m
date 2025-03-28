function movie_ExB(PCBgrid2D,PCBdata2D,ESPdata2D,ExBdata2D,newPCBdata2D,IDSP,FIG,color_type,vector_type)
%グラフ

frames(FIG.tate*FIG.yoko) = struct('cdata', [], 'colormap', []); % 各フレームの画像データを格納する配列

for i = 1:FIG.tate*FIG.yoko
    fig = figure('Position', [0 0 1500 1500],'visible','on');
    offset_ESP_t = knnsearch(ESPdata2D.trange',FIG.start);
    idx_ESP_t = offset_ESP_t+(i-1)*FIG.dt*10;
    offset_PCB_t = knnsearch(PCBdata2D.trange',FIG.start);
    idx_PCB_t = offset_PCB_t+(i-1)*FIG.dt;
    %カラープロット
    switch color_type
        case 'phi'
            contourf(ESPdata2D.zq,ESPdata2D.rq,squeeze(ESPdata2D.phi(idx_ESP_t,:,:)),100,'edgecolor','none');
            c = colorbar;
            clim([-240 240])
            c.Label.String = 'Floating Potential [V]';
        case 'Ez'
            contourf(ESPdata2D.zq,ESPdata2D.rq,squeeze(ESPdata2D.Ez(idx_ESP_t,:,:)),100,'edgecolor','none');
            c = colorbar;
            clim([-5000 5000])
            c.Label.String = 'E_z [V/m]';
        case 'Er'
            contourf(ESPdata2D.zq,ESPdata2D.rq,squeeze(ESPdata2D.Er(idx_ESP_t,:,:)),100,'edgecolor','none');
            c = colorbar;
            clim([-5000 5000])
            c.Label.String = 'E_r [V/m]';
        case '|VExB|'
            contourf(ESPdata2D.zq,ESPdata2D.rq,ExBdata2D.absVExB(:,:,i),100,'edgecolor','none');
            c = colorbar;
            clim([0 20])
            c.Label.String = '|V_{ExB}| [km/s]';
        case 'VExBr'
            contourf(ESPdata2D.zq,ESPdata2D.rq,ExBdata2D.VExB_r(:,:,i),100,'edgecolor','none');
            c = colorbar;
            clim([-20 20])
            c.Label.String = 'R component of V_{ExB} [km/s]';
        case 'VExBz'
            contourf(ESPdata2D.zq,ESPdata2D.rq,ExBdata2D.VExB_z(:,:,i),100,'edgecolor','none');
            c = colorbar;
            clim([-20 20])
            c.Label.String = 'Z component of V_{ExB} [km/s]';
        case 'psi'
            contourf(PCBgrid2D.zq,PCBgrid2D.rq,PCBdata2D.psi(:,:,idx_PCB_t),80,'LineStyle','none')
            clim([-10e-3,10e-3])%psi
            c = colorbar;
            c.Label.String = 'Psi [Wb]';
        case 'Bt'
            contourf(ESPdata2D.zq,ESPdata2D.rq,newPCBdata2D.Bt(:,:,idx_PCB_t),50,'LineStyle','none')
            clim([0.1,0.4])%Bt
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
            clim([-0.08,0.08])%Bz
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
        case 'Et'
            contourf(PCBgrid2D.zq,PCBgrid2D.rq,PCBdata2D.Et(:,:,idx_PCB_t),100,'LineStyle','none')
            clim([-400,400])%Et
            c = colorbar;
            c.Label.String = 'E_t [V/m]';
        case 'Jt'
            contourf(PCBgrid2D.zq,PCBgrid2D.rq,PCBdata2D.Jt(:,:,idx_PCB_t),30,'LineStyle','none')
            clim([-1E6,1E6])%Jt
            c = colorbar;
            c.Label.String = 'Jt [A/m^{2}]';
    end
    switch color_type
        case {'phi','Ez','Er','Et','Jt'}
            colormap(redblue(3000));
        case {'psi','Bz','Br','Bt_ext','Bt_plasma','absB','absB2','VExBr','VExBz','|VExB|'}
            colormap(jet)
    end
    hold on

    %磁気面
    contour(PCBgrid2D.zq,PCBgrid2D.rq,squeeze(PCBdata2D.psi(:,:,idx_PCB_t)),-20e-3:0.2e-3:40e-3,'black','LineWidth',1)
    hold on
    switch vector_type
        case 'VExB'
            %ExBドリフトベクトル
            VExB_z = squeeze(ExBdata2D.VExB_z(2:end-1,2:end-1,i));
            VExB_z = movmean(VExB_z,3,1);
            VExB_z = movmean(VExB_z,3,2);
            VExB_r = squeeze(ExBdata2D.VExB_r(2:end-1,2:end-1,i));
            VExB_r = movmean(VExB_r,3,1);
            VExB_r = movmean(VExB_r,3,2);
            % q = quiver(ESPdata2D.zq,ESPdata2D.rq,ExBdata2D.VExB_z(:,:,i),ExBdata2D.VExB_r(:,:,i),1.5);
            q = quiver(ESPdata2D.zq(2:end-1,2:end-1),ESPdata2D.rq(2:end-1,2:end-1),VExB_z,VExB_r,1.5);
            q.Color = "k";
            q.LineWidth = 2;
            hold on
        case 'Ep'
            %電場ベクトル
            Ez = squeeze(ESPdata2D.Ez(idx_ESP_t,2:end-1,2:end-1));
            Ez = movmean(Ez,3,1);
            Ez = movmean(Ez,3,2);
            Er = squeeze(ESPdata2D.Er(idx_ESP_t,2:end-1,2:end-1));
            Er = movmean(Er,3,1);
            Er = movmean(Er,3,2);
            % q = quiver(ESPdata2D.zq,ESPdata2D.rq,squeeze(ESPdata2D.Ez(idx_ESP_t,:,:)),squeeze(ESPdata2D.Er(idx_ESP_t,:,:)),1.5);
            q = quiver(ESPdata2D.zq(2:end-1,2:end-1),ESPdata2D.rq(2:end-1,2:end-1),Ez,Er,1.5);
            q.Color = "k";
            q.LineWidth = 4;
            hold on
        case ''
    end
    %PCB計測点
    for i_r = 1: size(PCBgrid2D.ok_bz_matrix,1)
        for i_z = 1: size(PCBgrid2D.ok_bz_matrix,2)
            if PCBgrid2D.ok_bz_matrix(i_r,i_z) == 1
                p = plot(PCBgrid2D.zprobepcb(i_z),PCBgrid2D.rprobepcb(i_r),"b+");%測定位置
                p.LineWidth = 3;
                p.MarkerSize = 12;
            end
        end
    end
    % % ESP計測点
    % for i_r = 1: size(ESPdata2D.rprobe,1)
    %     for i_z = 1: size(ESPdata2D.zprobe,2)
    %         p = plot(ESPdata2D.zprobe(1,i_z),ESPdata2D.rprobe(i_r,1),"g+");%測定位置
    %         p.LineWidth = 2;
    %         p.MarkerSize = 8;
    %     end
    % end
    hold on
    %IDSP計測点
    % IDSP.r1 = linspace(0.09,0.235,7);
    % IDSP.r1(5) = [];
    % IDSP.z(5) = [];
    % IDSP.r2 = IDSP.r1+0.01;
    % IDSP.r3 = IDSP.r1+0.02;
    % plot(IDSP.z,IDSP.r1,'r+',"MarkerSize",10,"LineWidth",2)
    % hold on
    % plot(IDSP.z,IDSP.r2,'r+',"MarkerSize",10,"LineWidth",2)
    % hold on
    % plot(IDSP.z,IDSP.r3,'r+',"MarkerSize",10,"LineWidth",2)
    fontsize(20,"points")
    title([num2str(PCBdata2D.trange(idx_PCB_t)) 'us'],'FontSize',30)
    % xlim([-0.05 0.1])
    xlim([-0.17 0.17])
    % ylim([0.08 0.27])
    xlabel('Z [m]')
    ylabel('R [m]')
    grid on
    daspect([1 1 1])
    view([90 -90])%RZ反転
    drawnow; % 描画を確実に実行させる
    frames(i) = getframe(fig); % 図を画像データとして得る
    close(fig)
end

filename = 'filename.gif'; % ファイル名
for i = 1:FIG.tate*FIG.yoko
    [A, map] = rgb2ind(frame2im(frames(i)), 256); % 画像形式変換
    if i == 1
        imwrite(A, map, filename, 'gif', 'DelayTime', 1/3, 'LoopCount', Inf); % 出力形式(30FPS)を設定
    else
        imwrite(A, map, filename, 'gif', 'DelayTime', 1/3, 'WriteMode', 'append'); % 2フレーム目以降は"追記"の設定も必要
    end
end

% video = VideoWriter('filename.mp4', 'MPEG-4'); % ファイル名や出力形式などを設定
% open(video); % 書き込むファイルを開く
% writeVideo(video, frames); % ファイルに書き込む
% close(video); % 書き込むファイルを閉じる




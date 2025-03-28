function plot_ExB(PCBgrid2D,PCBdata2D,ESPdata2D,ExBdata2D,newPCBdata2D,IDSP,FIG,color_type,vector_type,multi_analysis)
%グラフ
if not(multi_analysis)
    figure('Position', [0 0 1500 1500],'visible','on')
end
for i = 1:FIG.tate*FIG.yoko
    time = FIG.start + (i-1)*FIG.dt;
    if time >=  ESPdata2D.trange(1) && time <=  ESPdata2D.trange(end)
        idx_ESP_t = knnsearch(ESPdata2D.trange',time);
        idx_PCB_t = knnsearch(PCBdata2D.trange',time);
        idx_ExB_t = knnsearch(ExBdata2D.trange',time);
        if not(multi_analysis)
            subplot(FIG.tate,round(FIG.yoko),i)
            % sgt = sgtitle(color_type);
            % sgt.FontSize = 20;
        end
        %カラープロット
        switch color_type
            case 'phi'
                contourf(ESPdata2D.zq,ESPdata2D.rq,squeeze(ESPdata2D.phi(idx_ESP_t,:,:)),100,'edgecolor','none');
                c = colorbar;
                clim([-250 250])
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
                contourf(ESPdata2D.zq,ESPdata2D.rq,ExBdata2D.absVExB(:,:,idx_ExB_t),100,'edgecolor','none');
                c = colorbar;
                clim([0 10])
                c.Label.String = '|V_{ExB}| [km/s]';
            case 'VExBr'
                contourf(ESPdata2D.zq,ESPdata2D.rq,ExBdata2D.VExB_r(:,:,idx_ExB_t),100,'edgecolor','none');
                c = colorbar;
                clim([-10 10])
                c.Label.String = 'r component of V_{ExB} [km/s]';
            case 'VExBz'
                contourf(ESPdata2D.zq,ESPdata2D.rq,ExBdata2D.VExB_z(:,:,idx_ExB_t),100,'edgecolor','none');
                c = colorbar;
                clim([-15 15])
                c.Label.String = 'z component of V_{ExB} [km/s]';
            case 'EdotB'
                contourf(ESPdata2D.zq,ESPdata2D.rq,ExBdata2D.EdotB(:,:,idx_ExB_t),100,'edgecolor','none');
                c = colorbar;
                % clim([-15 15])
                c.Label.String = 'E\cdotB [V/m・T]';
            case 'cosEB'
                contourf(ESPdata2D.zq,ESPdata2D.rq,ExBdata2D.cosEB(:,:,idx_ExB_t),100,'edgecolor','none');
                c = colorbar;
                clim([-0.5 0.2])
                c.Label.String = 'E\cdotB / |E||B| []';
            case 'angleEB'
                contourf(ESPdata2D.zq,ESPdata2D.rq,rad2deg(acos(abs(ExBdata2D.cosEB(:,:,idx_ExB_t)))),100,'edgecolor','none');
                c = colorbar;
                clim([75 90])
                c.Label.String = 'Angle between E and B [degree]';
            case 'psi'
                % contourf(ESPdata2D.zq,ESPdata2D.rq,newPCBdata2D.psi(:,:,idx_PCB_t),80,'LineStyle','none')
                contourf(PCBgrid2D.zq,PCBgrid2D.rq,squeeze(PCBdata2D.psi(:,:,idx_PCB_t)),80,'LineStyle','none')
                clim([-3e-3,3e-3])%psi
                c = colorbar;
                % c.Label.String = 'Psi [Wb]';
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
                % contourf(ESPdata2D.zq,ESPdata2D.rq,newPCBdata2D.Br(:,:,idx_PCB_t),100,'LineStyle','none')
                contourf(PCBgrid2D.zq,PCBgrid2D.rq,squeeze(PCBdata2D.Br(:,:,idx_PCB_t)),100,'LineStyle','none')
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
            case 'absE'
                contourf(ESPdata2D.zq,ESPdata2D.rq,sqrt(ExBdata2D.absE2(:,:,idx_ExB_t)),100,'LineStyle','none')
                clim([0,2E3])%|E| [V/m]
                c = colorbar;
                c.Label.String = '|E| [V/m]';
            case 'absE2'
                contourf(ESPdata2D.zq,ESPdata2D.rq,ExBdata2D.absE2(:,:,idx_ExB_t),100,'LineStyle','none')
                clim([0,1E7])%|E|^2 [(V/m)^2]
                c = colorbar;
                c.Label.String = '|E|^2 [(V/m)^2]';
            case 'Et'
                contourf(ESPdata2D.zq,ESPdata2D.rq,newPCBdata2D.Et(:,:,idx_PCB_t),100,'LineStyle','none')
                clim([-400,400])%Et
                c = colorbar;
                c.Label.String = 'E_t [V/m]';
            case 'Jt'
                % contourf(ESPdata2D.zq,ESPdata2D.rq,newPCBdata2D.Jt(:,:,idx_PCB_t),30,'LineStyle','none')
                contourf(PCBgrid2D.zq,PCBgrid2D.rq,squeeze(PCBdata2D.Jt(:,:,idx_PCB_t)),[-1.5E6:0.01E6:1.5E6],'LineStyle','none')
                clim([-1.5E6,1.5E6])%Jt
                c = colorbar;
                % c.Label.String = 'Jt [A/m^{2}]';
        end
        if not(multi_analysis)
            switch color_type
                case {'phi','Ez','Er','Et'}
                    colormap(redblue(3000));
                case {'psi','Bz','Br','Bt_ext','Bt_plasma','absB','absB2','VExBr','VExBz','|VExB|','Jt'}
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
                VExB_z = squeeze(ExBdata2D.VExB_z(:,:,idx_ExB_t));
                VExB_z = movmean(VExB_z,3,1);
                VExB_z = movmean(VExB_z,3,2);
                VExB_r = squeeze(ExBdata2D.VExB_r(:,:,idx_ExB_t));
                VExB_r = movmean(VExB_r,3,1);
                VExB_r = movmean(VExB_r,3,2);
                factor = 3E-3;
                q = quiver(ESPdata2D.zq,ESPdata2D.rq,VExB_z*factor,VExB_r*factor,'off');
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
                magnitude = sqrt(Er.^2+Ez.^2);
                mlim = [0 3E3];
                n_colors = 64;
                cmap = jet(n_colors);
                mthresholds = linspace(mlim(1),mlim(2),n_colors);
                Ep_zq = ESPdata2D.zq(2:end-1,2:end-1);
                Ep_rq = ESPdata2D.rq(2:end-1,2:end-1);
                % for each color
                for ii = 1:n_colors
                    % find the indicies of the magnitudes at this color level
                    if ii == 1
                        idx = magnitude < mthresholds(ii);
                    elseif ii == n_colors
                        idx = magnitude >= mthresholds(ii);
                    else
                        idx = magnitude >= mthresholds(ii) & magnitude < mthresholds(ii+1);
                    end
                    % create the quiver plot of the right color, with no auto-scaling
                    factor = 6E-6;
                    q = quiver(Ep_zq(idx),Ep_rq(idx),Ez(idx)*factor,Er(idx)*factor,'off','Color',cmap(ii,:));
                    q.LineWidth = 6;
                    hold on
                end
                % factor = 6E-6;
                % q = quiver(ESPdata2D.zq(2:end-1,2:end-1),ESPdata2D.rq(2:end-1,2:end-1),Ez*factor,Er*factor,'off');
                % q.Color = "k";
                % q.LineWidth = 2;
                % hold on
        end
        % %ESP計測点
        % for i_r = 1: size(ESPdata2D.rprobe,1)
        %     for i_z = 1: size(ESPdata2D.zprobe,2)
        %         p = plot(ESPdata2D.zprobe(1,i_z),ESPdata2D.rprobe(i_r,1),"g+");%測定位置
        %         p.LineWidth = 2;
        %         p.MarkerSize = 4;
        %     end
        % end
        % hold on
        % %IDSP計測点
        % % IDSP.r1 = linspace(0.09,0.235,7);
        % % IDSP.r1(5) = [];
        % % IDSP.z(5) = [];
        % % IDSP.r2 = IDSP.r1+0.01;
        % % IDSP.r3 = IDSP.r1+0.02;
        % 
        % plot(IDSP.z,IDSP.r,'r+',"MarkerSize",4,"LineWidth",2)
        % hold on
        % 
        % % plot(IDSP.z,IDSP.r1,'r+',"MarkerSize",8/FIG.tate+2,"LineWidth",2/FIG.tate)
        % % hold on
        % % plot(IDSP.z,IDSP.r2,'r+',"MarkerSize",8/FIG.tate+2,"LineWidth",2/FIG.tate)
        % % hold on
        % % plot(IDSP.z,IDSP.r3,'r+',"MarkerSize",8/FIG.tate+2,"LineWidth",2/FIG.tate)
        title([num2str(ESPdata2D.trange(idx_ESP_t)) 'us'])
        % xlim([-0.02 0.07])
        xlim([-0.08 0.12])
        ylim([0.07 0.3])
        % xlim([-0.2 0.2])
        % xlim([-0.1275 0.1275])
        % ylim([0.08 0.27])
        xlabel('z [m]')
        ylabel('r [m]')
        grid on
        daspect([1 1 1])
        view([90 -90])%RZ反転
    end
end
fontsize(24,"points")
% if not(multi_analysis)
%     sgtitle(color_type)
%     fontsize(18/FIG.tate+5,"points")
% end


function [] = plot_curve_drift(Curvedata2D,plot_type,FIG,savename)
z_max = max(Curvedata2D.zq,[],"all");
z_min = min(Curvedata2D.zq,[],"all");
r_max = max(Curvedata2D.rq,[],"all");
r_min = min(Curvedata2D.rq,[],"all");

% if exist(savename.highmesh_psi,"file")
%     load(savename.highmesh_psi,'highmesh_PCBgrid2D','highmesh_PCBdata2D')
% else
%     warning([savename.highmesh_psi, 'does not exist.'])
% end
if exist(savename.pcb,"file")
    load(savename.pcb,'PCBgrid2D','PCBdata2D')
else
    warning([savename.pcb, 'does not exist.'])
end

figure('Position',[0 0 1500 1500],'visible','on')
for i_t = 1:FIG.tate*FIG.yoko
    subplot(FIG.tate,round(FIG.yoko),i_t)
    switch plot_type
        case 'F_r'
            contourf(Curvedata2D.zq,Curvedata2D.rq,squeeze(Curvedata2D.Fcurve_r(:,:,i_t)),100,'edgecolor','none')
            c = colorbar;
            colormap(jet)
            clim([min(Curvedata2D.Fcurve_r,[],"all") max(Curvedata2D.Fcurve_r,[],"all")])
            % c.Label.String = 'R component of Centrifugal Force [N]';
            clim([0 1.3E-17])
        case 'F_z'
            contourf(Curvedata2D.zq,Curvedata2D.rq,squeeze(Curvedata2D.Fcurve_z(:,:,i_t)),100,'edgecolor','none')
            % c = colorbar;
            colormap(jet)
            clim([min(Curvedata2D.Fcurve_z,[],"all") max(Curvedata2D.Fcurve_z,[],"all")])
            % c.Label.String = 'Z component of Centrifugal Force [N]';
            clim([-1.3E-18 1.3E-18])
        case 'F'
            contourf(Curvedata2D.zq,Curvedata2D.rq,squeeze(Curvedata2D.Fcurve(:,:,i_t)),100,'edgecolor','none')
            c = colorbar;
            colormap(jet)
            clim([min(Curvedata2D.Fcurve,[],"all") max(Curvedata2D.Fcurve,[],"all")])
            % clim([0 3E-16])
            c.Label.String = 'Strength of Centrifugal Force [N]';
        case 'F_zr'
            ds_rate_r = 5;
            ds_rate_z = 2;
            zq = downsample(Curvedata2D.zq,ds_rate_r);
            zq = downsample(zq',ds_rate_z)';
            rq = downsample(Curvedata2D.rq,ds_rate_r);
            rq = downsample(rq',ds_rate_z)';
            Fcurve_z = squeeze(Curvedata2D.Fcurve_z(:,:,i_t));
            Fcurve_z = downsample(Fcurve_z,ds_rate_r);
            Fcurve_z = downsample(Fcurve_z',ds_rate_z)';
            Fcurve_r = squeeze(Curvedata2D.Fcurve_r(:,:,i_t));
            Fcurve_r = downsample(Fcurve_r,ds_rate_r);
            Fcurve_r = downsample(Fcurve_r',ds_rate_z)';
            magnitude = sqrt(Fcurve_z.^2+Fcurve_r.^2);
            mlim = [1E-18 1.3E-17];
            n_colors = 64;
            cmap = jet(n_colors);
            mthresholds = linspace(mlim(1),mlim(2),n_colors);
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
                factor = 8E14;
                q = quiver(zq(idx),rq(idx),Fcurve_z(idx)*factor,Fcurve_r(idx)*factor,'off','Color',cmap(ii,:));
                q.LineWidth = 8;
                hold on
            end
            % q = quiver(Curvedata2D.zq,Curvedata2D.rq,squeeze(Curvedata2D.Fcurve_z(:,:,i_t)),squeeze(Curvedata2D.Fcurve_r(:,:,i_t)));
            % q.Color = 'b';
            % q.LineWidth = 2;
            % q.AutoScaleFactor = 0.5;
        case 'V_r'
            contourf(Curvedata2D.zq,Curvedata2D.rq,squeeze(Curvedata2D.Vcurve_r(:,:,i_t)),100,'edgecolor','none')
            c = colorbar;
            colormap(jet)
            clim([min(Curvedata2D.Vcurve_r,[],"all") max(Curvedata2D.Vcurve_r,[],"all")])
            c.Label.String = 'R component of Curvature Drift [km/s]';
        case 'V_z'
            contourf(Curvedata2D.zq,Curvedata2D.rq,squeeze(Curvedata2D.Vcurve_z(:,:,i_t)),100,'edgecolor','none')
            c = colorbar;
            colormap(jet)
            clim([min(Curvedata2D.Vcurve_z,[],"all") max(Curvedata2D.Vcurve_z,[],"all")])
            c.Label.String = 'Z component of Curvature Drift [km/s]';
        case 'V'
            contourf(Curvedata2D.zq,Curvedata2D.rq,squeeze(Curvedata2D.Vcurve(:,:,i_t)),100,'edgecolor','none')
            c = colorbar;
            colormap(jet)
            clim([min(Curvedata2D.Vcurve,[],"all") max(Curvedata2D.Vcurve,[],"all")])
            c.Label.String = 'Strength of Curvature Drift [km/s]';
        case 'V_zr'
            q = quiver(Curvedata2D.zq,Curvedata2D.rq,squeeze(Curvedata2D.Vcurve_z(:,:,i_t)),squeeze(Curvedata2D.Vcurve_r(:,:,i_t)));
            q.Color = 'b';
            q.LineWidth = 2;
            q.AutoScaleFactor = 0.5;
    end
    % if exist(savename.highmesh_psi,"file")
    %     hold on
    %     idx_pcb = knnsearch(highmesh_PCBdata2D.trange',FIG.start+(i_t-1)*FIG.dt);
    %     contour(highmesh_PCBgrid2D.zq(1,:),highmesh_PCBgrid2D.rq(:,1),squeeze(highmesh_PCBdata2D.psi(:,:,idx_pcb)),[-20e-3:0.05e-3:40e-3],'black','LineWidth',1)
    % end
    if exist(savename.pcb,"file")
        hold on
        idx_pcb = knnsearch(PCBdata2D.trange',FIG.start+(i_t-1)*FIG.dt);
        contour(PCBgrid2D.zq(1,:),PCBgrid2D.rq(:,1),squeeze(PCBdata2D.psi(:,:,idx_pcb)),[-20e-3:0.1e-3:40e-3],'black','LineWidth',1)
    end
    % title([num2str(Curvedata2D.trange(i_t)) 'us'])
    daspect([1 1 1])
    % xlim([z_min z_max])
    % ylim([r_min r_max])
    xlim([-0.05 0.08])
    ylim([0.1 0.27])
    xlabel('Z [m]')
    ylabel('R [m]')
    ax = gca;
    % ax.FontSize = 60;
end

% switch plot_type
%     case {'F_r','F_z','F','V_r','V_z','V'}
%         sgtitle(c.Label.String)
%     case 'F_zr'
%         sgtitle('Centrifugal Force Vector')
%     case 'V_zr'
%         sgtitle('Curvature Drift Vector')
% end

view([90 -90])%RZ反転
% xlim([-0.01 0.05])
xlim([-0.04 0.07])
c.Location = "north";
function [] = plot_nablaB_drift(NablaBdata2D,plot_type,FIG,savename)
z_max = max(NablaBdata2D.zq,[],"all");
z_min = min(NablaBdata2D.zq,[],"all");
r_max = max(NablaBdata2D.rq,[],"all");
r_min = min(NablaBdata2D.rq,[],"all");

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
            contourf(NablaBdata2D.zq,NablaBdata2D.rq,squeeze(NablaBdata2D.FnablaB_r(:,:,i_t)),1000,'edgecolor','none')
            % c = colorbar;
            colormap(jet)
            % clim([min(NablaBdata2D.FnablaB_r,[],"all") max(NablaBdata2D.FnablaB_r,[],"all")])
            % c.Label.String = 'R component of Grad B Force [N]';
            clim([0.4E-17 1.6E-17])
        case 'F_z'
            contourf(NablaBdata2D.zq,NablaBdata2D.rq,squeeze(NablaBdata2D.FnablaB_z(:,:,i_t)),1000,'edgecolor','none')
            % c = colorbar;
            colormap(jet)
            clim([min(NablaBdata2D.FnablaB_z,[],"all") max(NablaBdata2D.FnablaB_z,[],"all")])
            % c.Label.String = 'Z component of Grad B Force [N]';
            clim([-1.8E-18 1.8E-18])
        case 'F'
            contourf(NablaBdata2D.zq,NablaBdata2D.rq,squeeze(NablaBdata2D.FnablaB(:,:,i_t)),100,'edgecolor','none')
            c = colorbar;
            colormap(jet)
            clim([min(NablaBdata2D.FnablaB,[],"all") max(NablaBdata2D.FnablaB,[],"all")])
            c.Label.String = 'Strength of Grad B Force [N]';
        case 'F_zr'
            ds_rate = 2;
            zq = downsample(NablaBdata2D.zq,ds_rate);
            rq = downsample(NablaBdata2D.rq,ds_rate);
            FnablaB_z = squeeze(NablaBdata2D.FnablaB_z(:,:,i_t));
            FnablaB_z = downsample(FnablaB_z,ds_rate);
            FnablaB_r = squeeze(NablaBdata2D.FnablaB_r(:,:,i_t));
            FnablaB_r = downsample(FnablaB_r,ds_rate);
            magnitude = sqrt(FnablaB_z.^2+FnablaB_r.^2);
            mlim = [5E-18 1.5E-17];
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
                factor = 7E14;
                q = quiver(zq(idx),rq(idx),FnablaB_z(idx)*factor,FnablaB_r(idx)*factor,'off','Color',cmap(ii,:));
                q.LineWidth = 8;
                hold on
            end
            % q = quiver(NablaBdata2D.zq,NablaBdata2D.rq,squeeze(NablaBdata2D.FnablaB_z(:,:,i_t)),squeeze(NablaBdata2D.FnablaB_r(:,:,i_t)));
            % q.Color = 'b';
            % q.LineWidth = 2;
            % q.AutoScaleFactor = 0.5;
        case 'V_r'
            contourf(NablaBdata2D.zq,NablaBdata2D.rq,squeeze(NablaBdata2D.VnablaB_r(:,:,i_t)),100,'edgecolor','none')
            c = colorbar;
            colormap(jet)
            clim([min(NablaBdata2D.VnablaB_r,[],"all") max(NablaBdata2D.VnablaB_r,[],"all")])
            c.Label.String = 'R component of Grad B Drift [km/s]';
        case 'V_z'
            contourf(NablaBdata2D.zq,NablaBdata2D.rq,squeeze(NablaBdata2D.VnablaB_z(:,:,i_t)),100,'edgecolor','none')
            c = colorbar;
            colormap(jet)
            clim([min(NablaBdata2D.VnablaB_z,[],"all") max(NablaBdata2D.VnablaB_z,[],"all")])
            c.Label.String = 'Z component of Grad B Drift [km/s]';
        case 'V'
            contourf(NablaBdata2D.zq,NablaBdata2D.rq,squeeze(NablaBdata2D.VnablaB(:,:,i_t)),100,'edgecolor','none')
            c = colorbar;
            colormap(jet)
            clim([min(NablaBdata2D.VnablaB,[],"all") max(NablaBdata2D.VnablaB,[],"all")])
            c.Label.String = 'Strength of Grad B Drift [km/s]';
        case 'V_zr'
            q = quiver(NablaBdata2D.zq,NablaBdata2D.rq,squeeze(NablaBdata2D.VnablaB_z(:,:,i_t)),squeeze(NablaBdata2D.VnablaB_r(:,:,i_t)));
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
    % title([num2str(NablaBdata2D.trange(i_t)) 'us'])
    daspect([1 1 1])
    xlim([z_min z_max])
    ylim([r_min r_max])
    xlabel('Z [m]')
    ylabel('R [m]')
    ax = gca;
    % ax.FontSize = 60;
end

% switch plot_type
%     case {'F_r','F_z','F','V_r','V_z','V'}
%         sgtitle(c.Label.String)
%     case 'F_zr'
%         sgtitle('Grad B Force Vector')
%     case 'V_zr'
%         sgtitle('Grad B Drift Vector')
% end

view([90 -90])%RZ反転
% xlim([-0.01 0.05])
xlim([-0.04 0.07])
ylim([0.1 0.27])
c.Location = "north";
function [] = plot_polar_drift(Polardata2D,plot_type,savename)
z_max = max(Polardata2D.zq,[],"all");
z_min = min(Polardata2D.zq,[],"all");
r_max = max(Polardata2D.rq,[],"all");
r_min = min(Polardata2D.rq,[],"all");

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
for i_t = 2%1:size(Polardata2D.trange,1)
    % subplot(1,size(Polardata2D.trange,1),i_t)
    switch plot_type
        case 'F_r'
            contourf(Polardata2D.zq,Polardata2D.rq,squeeze(Polardata2D.Fpolar_r(:,:,i_t)),1000,'edgecolor','none')
            c = colorbar;
            colormap(jet)
            clim([min(Polardata2D.Fpolar_r,[],"all") max(Polardata2D.Fpolar_r,[],"all")])
            % c.Label.String = 'R component of Grad B Force [N]';
            % clim([0.4E-17 1.6E-17])
        case 'F_z'
            contourf(Polardata2D.zq,Polardata2D.rq,squeeze(Polardata2D.Fpolar_z(:,:,i_t)),1000,'edgecolor','none')
            c = colorbar;
            colormap(jet)
            clim([min(Polardata2D.Fpolar_z,[],"all") max(Polardata2D.Fpolar_z,[],"all")])
            % c.Label.String = 'Z component of Grad B Force [N]';
            % clim([-1.8E-18 1.8E-18])
        case 'F'
            contourf(Polardata2D.zq,Polardata2D.rq,squeeze(Polardata2D.Fpolar(:,:,i_t)),100,'edgecolor','none')
            c = colorbar;
            colormap(jet)
            clim([min(Polardata2D.Fpolar,[],"all") max(Polardata2D.Fpolar,[],"all")])
            c.Label.String = 'Strength of Grad B Force [N]';
        case 'F_zr'
            q = quiver(Polardata2D.zq,Polardata2D.rq,squeeze(Polardata2D.Fpolar_z(:,:,i_t)),squeeze(Polardata2D.Fpolar_r(:,:,i_t)));
            q.Color = 'b';
            q.LineWidth = 2;
            q.AutoScaleFactor = 0.5;
        case 'V_r'
            contourf(Polardata2D.zq,Polardata2D.rq,squeeze(Polardata2D.Vpolar_r(:,:,i_t)),100,'edgecolor','none')
            c = colorbar;
            colormap(jet)
            clim([min(Polardata2D.Vpolar_r,[],"all") max(Polardata2D.Vpolar_r,[],"all")])
            % c.Label.String = 'R component of Polarization Drift [km/s]';
        case 'V_z'
            contourf(Polardata2D.zq,Polardata2D.rq,squeeze(Polardata2D.Vpolar_z(:,:,i_t)),100,'edgecolor','none')
            c = colorbar;
            colormap(jet)
            clim([min(Polardata2D.Vpolar_z,[],"all") max(Polardata2D.Vpolar_z,[],"all")])
            % c.Label.String = 'Z component of Polarization Drift [km/s]';
        case 'V'
            contourf(Polardata2D.zq,Polardata2D.rq,squeeze(Polardata2D.Vpolar(:,:,i_t)),100,'edgecolor','none')
            c = colorbar;
            colormap(jet)
            clim([min(Polardata2D.Vpolar,[],"all") max(Polardata2D.Vpolar,[],"all")])
            % c.Label.String = 'Strength of Polarization Drift [km/s]';
        case 'V_zr'
            q = quiver(Polardata2D.zq,Polardata2D.rq,squeeze(Polardata2D.Vpolar_z(:,:,i_t)),squeeze(Polardata2D.Vpolar_r(:,:,i_t)));
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
        idx_pcb = knnsearch(PCBdata2D.trange',Polardata2D.trange(i_t));
        contour(PCBgrid2D.zq(1,:),PCBgrid2D.rq(:,1),squeeze(PCBdata2D.psi(:,:,idx_pcb)),[-20e-3:0.1e-3:40e-3],'black','LineWidth',1)
    end
    title([num2str(Polardata2D.trange(i_t)) 'us'])
    daspect([1 1 1])
    % xlim([z_min z_max])
    % ylim([r_min r_max])
    xlabel('Z [m]')
    ylabel('R [m]')
    ax = gca;
    ax.FontSize = 30;
    view([90 -90])%RZ反転
    % xlim([-0.01 0.05])
    xlim([-0.04 0.07])
    ylim([0.1 0.27])
    c.Location = "north";
end



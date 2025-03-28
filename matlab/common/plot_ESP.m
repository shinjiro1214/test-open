function [] = plot_ESP(ESP,ESPdata2D,colorplot)
switch colorplot
    case {'phi','Ez','Er'}
        figure('Position', [0 0 1500 1500],'visible','on');
        for i = 1:ESP.tate*ESP.yoko
            time = ESP.start + (i-1)*ESP.dt;
            if time >=  ESPdata2D.trange(1) && time <=  ESPdata2D.trange(end)
                idx_t = knnsearch(ESPdata2D.trange',time);
                subplot(ESP.tate,ESP.yoko,i)
                switch colorplot
                    case 'phi'
                        contourf(ESPdata2D.zq,ESPdata2D.rq,squeeze(ESPdata2D.phi(idx_t,:,:)),100,'edgecolor','none');
                        c = colorbar;
                        clim([-240 240])
                        c.Label.String = 'Floating phi [V]';
                        colormap(redblue(300))
                        hold on
                    case 'Ez'
                        contourf(ESPdata2D.zq,ESPdata2D.rq,squeeze(ESPdata2D.Ez(idx_t,:,:)),100,'edgecolor','none');
                        c = colorbar;
                        clim([-5000 5000])
                        c.Label.String = 'E_z [V/m]';
                        colormap(redblue(300))
                        hold on
                    case 'Er'
                        contourf(ESPdata2D.zq,ESPdata2D.rq,squeeze(ESPdata2D.Er(idx_t,:,:)),100,'edgecolor','none');
                        c = colorbar;
                        clim([-5000 5000])
                        c.Label.String = 'E_r [V/m]';
                        colormap(redblue(300))
                        hold on
                end
                if ESP.vector
                    q = quiver(ESPdata2D.zq,ESPdata2D.rq,squeeze(ESPdata2D.Ez(idx_t,:,:)),squeeze(ESPdata2D.Er(idx_t,:,:)),3);
                    q.Color = "k";
                end
                hold on
                title([num2str(ESPdata2D.trange(idx_t)) 'us'])
                xlim([-0.1 0.1])
                ylim([0.07 0.3])
                daspect([1 1 1])
            end
        end
    otherwise
        return
end
end


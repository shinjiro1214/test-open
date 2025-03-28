function plot_maxpsi(PCBgrid2D,PCBdata2D,FIG)
figure('Position', [1000 0 500 500],'visible','on')
idx_start = FIG.start-PCBdata2D.trange(1)+1;
idx_end = FIG.end-PCBdata2D.trange(1)+1;
t = PCBdata2D.trange(idx_start:idx_end);
max_psi = zeros(size(t,2),1);
mergin = 1;
for i = 1:size(t,2)
    idx = idx_start + i - 1;
    max_psi(i) = max(PCBdata2D.psi(1:end,1+mergin:end-mergin,idx),[],"all");
end
% plot(t,max_psi)
% p = polyfit(t,max_psi,1)
% y2 = polyval(p,t);
% plot(t,max_psi,'o',t,y2)
f = fit(t',max_psi,'exp1')
plot(f,t,max_psi)
% title('Time Evolution of Max Psi')
xlabel('t [us]')
ylabel('Max Psi [Wb]')
ax = gca;
ax.FontSize = 20;
end


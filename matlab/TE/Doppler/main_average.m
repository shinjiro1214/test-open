shotlist = [11942:11945];

Ti_Local_multi = zeros(30,6,numel(shotlist));
for i_shot = 1:numel(shotlist)
    shot_num = shotlist(i_shot);
    savename = [folder_name,'/ST40_shot',num2str(shot_num),'.mat'];
    load(savename,'ST40IDSdata')
    Ti_Local_multi(:,:,i_shot) = ST40IDSdata.Ti_Local;
end
Ti_Local_ave = mean(Ti_Local_multi,3);
figure
[~,h] = contourf(ST40IDSdata.z,ST40IDSdata.r,Ti_Local_ave,100);
daspect([1 1 1])
h.LineStyle = 'none';
colormap(jet)
xlabel('Z [m]')
ylabel('R [m]')
clim([100 350])
view([90 -90])%RZ反転
function B_r = get_B_reconnection(PCB,pathname)

trange = PCB.trange;
% newTimeRange = find(trange>=440&trange<=500);
newTimeRange = 1:numel(trange);
[grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
Br = data2D.Br;
rq = grid2D.rq;
zq = grid2D.zq;

psi = data2D.psi;
figure;
for j = 1:4
    t_j = 460+2*j;
    [~,I] = max(psi(:,:,trange==t_j),[],1,'linear');
    subplot(2,2,j);
    Br_t = Br(:,:,trange==t_j);
    plot(zq(I),Br_t(I));
    title(num2str(t_j));
end

trange = trange(newTimeRange);
Br = Br(:,:,newTimeRange);

B_reconnection = zeros(1,numel(trange));
mergingRatio = zeros(1,numel(trange));

for i = 1:numel(trange)
    time = trange(i);
    [magaxis,xpoint] = get_axis_x(grid2D,data2D,time);
    if numel(magaxis.r) == 2
        range = rq>=min(magaxis.r)&rq<=max(magaxis.r)&zq>=min(magaxis.z)&zq<=max(magaxis.z);
        Br_t = Br(:,:,i);
        % B_reconnection(1,i) = max(abs(Br_t(range)),[],'all');
        B_reconnection(1,i) = min([max(Br_t(range),[],'all'),abs(min(Br_t(range),[],"all"))]);
        mergingRatio(1,i) = xpoint.psi/mean(magaxis.psi);
    else
        B_reconnection(1,i) = NaN;
        mergingRatio(1,i) = NaN;
    end
end

% t_Br = trange(knnsearch(mergingRatio.',0.2));
% disp(t_Br);

timing_last = find(mergingRatio==0,1,'last');
B_r = B_reconnection(1,timing_last);
% B_r = B_reconnection(1,knnsearch(mergingRatio.',0.2));

figure;plot(trange,B_reconnection);%xlim([460 500]);
figure;plot(trange,mergingRatio);%xlim([460 500]);

end
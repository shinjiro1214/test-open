%移動平均をとることによって温度がどれだけ過大評価されるかを検証

close all
% x = transpose(linspace(-100,100,100));
x = lambdaA;
IDX_A = knnsearch(lambdaA,lambda0);%lambdaAの中で最もlambda0に近いセル番号を取得
y = zeros(numel(x),1);
dx = x(2) - x(1);
Ti_inst = 0;

num_j = 5;
num_i = 20;
w_l_fit = 12;%フィッティング波長切り出し幅

sigma_orig = zeros(num_i,1);
sigma_trans = zeros(num_i,1);
Ti_orig = zeros(num_i,1);
Ti_trans = zeros(num_i,1);
mov_w = zeros(num_j,1);
coef_sigma = zeros(num_j,1);
coef_Ti = zeros(num_j,1);

for j = 1:num_j
    mov_w(j) = 5+(j-1)*2;
    for i = 1:num_i
        sigma_orig(i) = 0.03+0.0005*i;
        Ti_orig(i) = 1.69e8*mass*(2*sigma_orig(i)*sqrt(2*log(2))/lambda0)^2-Ti_inst;
        for k = 1:numel(x)
            y(k) = exp(-(x(k)-lambda0)^2/(2*sigma_orig(i)^2));
        end
        y = movmean(y,mov_w(j));
        f = fit(x(IDX_A-w_l_fit:IDX_A+w_l_fit),y(IDX_A-w_l_fit:IDX_A+w_l_fit),'gauss1');
        coeff1 = coeffvalues(f);
        fit_y = feval(f,x);
        if (j==1) && (i==1)
            figure('Position',[0 500 800 300])
            tiledlayout(1,3)
            ax1 = nexttile;
            h1 = plot(ax1,x,fit_y,'r-',x,y,'b+');
            title(ax1,[num2str(j),' - ',num2str(i)])
            xlabel('Wavelength [nm]')
            ylabel('Strength [a.u.]')
            hold off
        else
            h1(1).YData = fit_y;
            h1(2).YData = y;
            title(ax1,[num2str(j),' - ',num2str(i)])
            drawnow
        end
        sigma_trans(i) = coeff1(3)/sqrt(2);
    end
    sigma_trans = filloutliers(sigma_trans,"linear");
    for i = 1:num_i
        Ti_trans(i) = 1.69e8*mass*(2*sigma_trans(i)*sqrt(2*log(2))/lambda0)^2-Ti_inst;
    end
    Ti_trans = filloutliers(Ti_trans,"linear");
    p_sigma = polyfit(sigma_orig,sigma_trans,1);
    fit_sigma_trans = polyval(p_sigma,sigma_orig);
    coef_sigma(j) = p_sigma(1);
    if j==1
        ax2 = nexttile;
        h2 = plot(ax2,sigma_orig,sigma_trans,'b+',sigma_orig,fit_sigma_trans,'r-');
        title(ax2,['movlen = ',num2str(mov_w(j))])
        xlabel('Original Sigma [nm]')
        ylabel('Transformed Sigma [nm]')
        hold off
    else
        h2(1).YData = sigma_trans;
        h2(2).YData = fit_sigma_trans;
        title(ax2,['movlen = ',num2str(mov_w(j))])
        drawnow
    end
    p_Ti = polyfit(Ti_orig,Ti_trans,1);
    fit_Ti_trans = polyval(p_Ti,Ti_orig);
    coef_Ti(j) = p_Ti(1);
    if j==1
        ax3 = nexttile;
        h3 = plot(ax3,Ti_orig,Ti_trans,'b+',Ti_orig,fit_Ti_trans,'r-');
        title(ax3,['movlen = ',num2str(mov_w(j))])
        xlabel('Original Ti [eV]')
        ylabel('Transformed Ti [eV]')
        hold off
    else
        h3(1).YData = Ti_trans;
        h3(2).YData = fit_Ti_trans;
        title(ax3,['movlen = ',num2str(mov_w(j))])
        drawnow
    end
    str1 = sprintf('movlen = %d, y = (%.3f) x + (%.3f)',mov_w(j),p_Ti(1),p_Ti(2))
end
figure('Position',[200 500 800 400])
tiledlayout(1,2)
nexttile
plot(mov_w,coef_sigma,'b+')
xlabel('Movemean length [(array number)]')
ylabel('Slope value of Sigma []')
nexttile
plot(mov_w,coef_Ti,'b+')
xlabel('Movemean length [(array number)]')
ylabel('Slope value of Ti []')



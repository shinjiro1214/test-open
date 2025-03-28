%gauss smoothingをとることによって温度がどれだけ過大評価されるかを検証

close all
% x = transpose(linspace(-100,100,100));
x = lambdaA_z(:,1);
IDX_A = knnsearch(x,lambda0);%lambdaAの中で最もlambda0に近いセル番号を取得
y = zeros(numel(x),1);
dx = x(2) - x(1);

Ti_inst_orig = 1.69e8*mass*(2*resolution(1)*instru(1)*sqrt(2*log(2))/lambda0).^2;

num_j = 1;
num_i = 10;
sp_th_ratio = 0.5;%【input】フィッティングに用いる点の閾値(最大値の何倍までか)(0~1)

sigma_orig = zeros(num_i,1);
sigma_trans = zeros(num_i,1);
Ti_orig = zeros(num_i,1);
Ti_trans = zeros(num_i,1);
Ti_inst_trans = zeros(num_i,1);
gauss_w = zeros(num_j,1);
coef_sigma = zeros(num_j,1);
coef_Ti = zeros(num_j,1);

for j = 1:num_j
    gauss_w(j) = 30+(j-1)*1;
    N_gf = gauss_w(j);
    sigma_gf = 5;
    alpha_gf = (N_gf-1)/(2*sigma_gf);
    gaussFilter = gausswin(N_gf,alpha_gf);
    gaussFilter = gaussFilter / sum(gaussFilter);
    for i = 1:num_i
        sigma_orig(i) = 0.1+0.005*i;
        Ti_orig(i) = 1.69e8*mass*(2*sigma_orig(i)*sqrt(2*log(2))/lambda0)^2-Ti_inst_orig;
        Ti_inst_trans(i) = 1.69e8*mass*(2*resolution(1)*sqrt(instru(1)^2+sigma_gf^2)*sqrt(2*log(2))/lambda0).^2;
        % Ti_inst_trans(i) = 1.69e8*mass*(2*resolution(1)*sqrt(instru(1)^2)*sqrt(2*log(2))/lambda0).^2;
        for k = 1:numel(x)
            y(k) = exp(-(x(k)-lambda0)^2/(sigma_orig(i)^2));%ノイズなしガウシアンを生成
        end
        y = y + randn(size(y))*0.1;%白色ノイズ付与
        y = conv(y, gaussFilter, 'same');%ガウスフィルターをかける
        max_y = max(y);
        survived_xy = [x y]; %[波長,強度]
        deleted_xy = zeros(1,2);
        j_SN = 1;
        flag_SN = 0;
        while j_SN < size(survived_xy,1)+1 %SNの悪いデータを除く
            if survived_xy(j_SN,2) < max_y*sp_th_ratio
                if flag_SN == 0
                    deleted_xy = survived_xy(j_SN,:);
                    flag_SN = 1;
                else
                    deleted_xy = cat(1,deleted_xy,survived_xy(j_SN,:));
                end
                survived_xy(j_SN,:) = [];
            else
                j_SN = j_SN+1;
            end
        end
        f = fit(survived_xy(:,1),survived_xy(:,2),'gauss1');
        coeff1 = coeffvalues(f);
        fitted_y = feval(f,x);
        if (j==1) && (i==1)
            figure('Position',[0 500 800 300])
            tiledlayout(1,3)
            ax1 = nexttile;
            p_fitted = plot(x,fitted_y,'r-','LineWidth',2);
            hold on
            p_survived = plot(survived_xy(:,1),survived_xy(:,2),'bo','MarkerSize',8,'LineWidth',0.8);
            hold on
            p_deleted = plot(deleted_xy(:,1),deleted_xy(:,2),'kx','MarkerSize',12,'LineWidth',0.8);
            title(ax1,['Original Sigma = ',num2str(sigma_orig(i))])
            xlabel('Wavelength [nm]')
            ylabel('Strength [a.u.]')
            ylim([0 inf])
            hold off
        else
            p_fitted.YData = fitted_y;
            p_survived.XData = survived_xy(:,1);
            p_survived.YData = survived_xy(:,2);
            p_deleted.XData = deleted_xy(:,1);
            p_deleted.YData = deleted_xy(:,2);
            title(ax1,['Original Sigma = ',num2str(sigma_orig(i))])
            drawnow
        end
        sigma_trans(i) = coeff1(3);
    end
    sigma_trans = filloutliers(sigma_trans,"linear");
    for i = 1:num_i
        Ti_trans(i) = 1.69e8*mass*(2*sigma_trans(i)*sqrt(2*log(2))/lambda0)^2-Ti_inst_trans(i);
    end
    Ti_trans = filloutliers(Ti_trans,"linear");
    p_sigma = polyfit(sigma_orig,sigma_trans,1);
    fit_sigma_trans = polyval(p_sigma,sigma_orig);
    coef_sigma(j) = p_sigma(1);
    if j==1
        ax2 = nexttile;
        h2 = plot(ax2,sigma_orig,sigma_trans,'b+',sigma_orig,fit_sigma_trans,'r-');
        title(ax2,['smoothlen = ',num2str(gauss_w(j))])
        xlabel('Original Sigma [nm]')
        ylabel('Transformed Sigma [nm]')
        hold off
    else
        h2(1).YData = sigma_trans;
        h2(2).YData = fit_sigma_trans;
        title(ax2,['smoothlen = ',num2str(gauss_w(j))])
        drawnow
    end
    p_Ti = polyfit(Ti_orig,Ti_trans,1);
    fit_Ti_trans = polyval(p_Ti,Ti_orig);
    coef_Ti(j) = p_Ti(1);
    if j==1
        ax3 = nexttile;
        h3 = plot(ax3,Ti_orig,Ti_trans,'b+',Ti_orig,fit_Ti_trans,'r-');
        title(ax3,['smoothlen = ',num2str(gauss_w(j))])
        xlabel('Original Ti [eV]')
        ylabel('Transformed Ti [eV]')
        hold off
    else
        h3(1).YData = Ti_trans;
        h3(2).YData = fit_Ti_trans;
        title(ax3,['smoothlen = ',num2str(gauss_w(j))])
        drawnow
    end
    str1 = sprintf('Gauss smooth length = %d, y = (%.3f) x + (%.3f)',gauss_w(j),p_Ti(1),p_Ti(2))
end
figure('Position',[200 500 800 400])
tiledlayout(1,2)
nexttile
plot(gauss_w,coef_sigma,'b+')
xlabel('Gauss smooth length [(array number)]')
ylabel('Slope value of Sigma []')
nexttile
plot(gauss_w,coef_Ti,'b+')
xlabel('Gauss smooth length [(array number)]')
ylabel('Slope value of Ti []')



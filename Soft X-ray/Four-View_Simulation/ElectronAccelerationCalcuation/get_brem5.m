Te = 10; %[eV]
% Te =300; %[eV]
% ne = [3e20, 5e19]; %[m^-3]
ne = [1e20, 5e19]; %[m^-3]
% ne = [3e19, 5e18]; %[m^-3]
% Et = [270, 330]; %[V/m]
Et = [300, 400]; %[V/m]

% R = ones(1,3)*0.01;

% Bt = 1;
% Bp = Bt./50;

% me = 9.11e-31; %kg
% e = 1.6*10^(-19); %C
% e0 = 8.85e-12; %F/m
% mi = 6.64e-26; %kg
% mr = me*mi/(me+mi);
% kBT = Te*e; %eV→J（kBはJ/K）
% lambdaD = sqrt(e0*kBT/(ne*e^2)); %m
% Lambda = 4*pi()*lambdaD^3*ne/3; %無次元数
% Z = 2; %暫定的な価数
% % h = 6.63e-34; %プランク定数
% % % Ry = me*e^4/(2*h^2);
% % Ry = 13.6*e;
% c = 3e8;

% f1 = figure;
% f2 = figure;
for i = 1:numel(ne)
    spectrum = get_spectrum(Te,ne(i),Et(i));
    intensity = get_intensity(spectrum);
    intensity = intensity/intensity(2);

    % figure(f1);
    % loglog(spectrum(1,:),spectrum(3,:),'LineWidth',2);hold on;
    % loglog(spectrum(1,:),spectrum(2,:),'LineWidth',2);
    % legend({'before','after'});
    % ylabel('Intensity [a.u.]');xlabel('Photon energy [eV]');
    % ax = gca;ax.FontSize = 18;
    % figure(f2);
    % semilogy(intensity(1:3));hold on;
end

% マイラーフィルターは2eVに有限の透過率を持つ
% emissivity1_newは2eV以外0
% マイラーしか光らない
% Te=300eVでそれっぽい光り方するけど、、
% 速度直したら少し変わった？
% それでも100eVの発光は生まれてない
% 加速しやすい二つ目の時間帯で30eVまで
% Mylarフィルタの信号は低エネルギー帯の発光を検出している
% 100eV以上の電子は生成されている


function spectrum = get_spectrum(Te,ne,Et)
    Bt = 1;
    Bp = Bt./50;
    R = 0.01;

    me = 9.11e-31; %kg
    e = 1.6*10^(-19); %C
    kB = 1.38e-23; %J/K
    e0 = 8.85e-12; %F/m
    mi = 6.64e-26; %kg
    mr = me*mi/(me+mi);
    kBT = Te*e; %eV→J（kBはJ/K）
    lambdaD = sqrt(e0*kBT/(ne*e^2)); %m
    Lambda = 9*4*pi()*lambdaD^3*ne/3; %無次元数
    % Z = 2; %暫定的な価数
    Z = 1; %暫定的な価数
    h = 6.63e-34; %プランク定数
    mu = 0;
    sigma = sqrt(3*kBT/me);
    v_0 = normrnd(mu,sigma,1,1e4);
    wpe = sqrt(ne*e^2/(me*e0));

    v_0 = abs(v_0);
    t_ei = 4*pi()*e0^2*mr^2*abs(v_0).^3./(ne*Z^2*e^4*log(Lambda));

    t_ei_T = sqrt(3)*Lambda/(Z*wpe*log(Lambda)); %熱的分布を仮定した衝突時間

    Ep = Et.*Bp.*Bt./(Bp.^2+Bt^2);
    t_ra = sqrt(2*me*R/(e*Ep));

    dve = e*Ep/me-2*v_0./t_ei;
    % 電場で加速されて衝突周波数で減速？
    % 加速が11-12乗、減速が14-16乗になってそう

    % 加速の計算
    % E_e_hist = zeros(1,40);
    t_runaway = t_ra;
    t_acc = t_ei;
    t_acc(t_acc>t_runaway & v_0>0) = t_runaway;
    v_e = v_0 + e*Et/me.*t_acc;

    % figure;
    [V_hist1,VEdge1] = histcounts(v_e(1,:),'NumBins',100);
    [V_hist0,VEdge0] = histcounts(v_0,'NumBins',100);

    f_brem = 1e14:1e14:1e17;

    ve0 = VEdge0(2:end);
    ve1 = VEdge1(2:end);
    dP0 = V_hist0;
    dP1 = V_hist1;

    dW0 = log(me*ve0.'.^2./(h*2*pi()*f_brem))./ve0.';
    dW1 = log(me*ve1.'.^2./(h*2*pi()*f_brem))./ve1.';
    dW0(dW0<0) = 0;
    dW1(dW1<0) = 0;

    % 速度プロット用のヒストグラム
    [dP1_plot,ve1_plot] = histcounts(v_e(1,:),'BinWidth',1e5);
    [dP0_plot,ve0_plot] = histcounts(v_0,'BinWidth',1e5);
    figure;
    semilogy(ve0_plot(2:end),dP0_plot,ve1_plot(2:end),dP1_plot,'LineWidth',2);
    legend({'before','after'},'Location','northeast');
    xlabel('Electron velocity [m/s]');
    ylabel('Number of particles');
    ax = gca;
    ax.FontSize = 18;
    title('Electron velocity distribution');

    % % エネルギープロット用のヒストグラム
    % E_e = 0.5.*me.*v_e.^2./e;
    % [E_hist1,Edge1] = histcounts(E_e(1,:),'BinWidth',5);
    % E_0 = 0.5.*me.*v_0.^2./e;
    % [E_hist0,Edge0] = histcounts(E_0,'BinWidth',5);
    % figure;
    % loglog(Edge0(2:end),E_hist0,Edge1(2:end),E_hist1,'LineWidth',2);
    % % ylim([5 1e4]);xlim([0 500]);
    % ax = gca;ax.FontSize = 18;
    % legend({'before','after'},'Location','northeast');
    % xlabel('Electron energy [eV]');
    % ylabel('Number of particles');
    % title('Electron energy distrbution');

    A0 = ve0.^2.*dP0;
    A1 = ve1.^2.*dP1;
    num_e0 = sum(A0);
    num_e1 = sum(A1);

    emissivity0 = sum(dW0.*A0.')/num_e0;
    emissivity1 = sum(dW1.*A1.')/num_e1;
    energy = h*f_brem/e;

    emissivity0 = emissivity0*ne;
    emissivity1 = emissivity1*ne;

    % figure;
    % loglog(energy,emissivity0,energy,emissivity1,'LineWidth',2);
    % legend({'thermal','Guide field'},'Location','southwest');
    % xlabel('Photon energy [eV]');ylabel('Intensity [a.u.]');
    % title('Bremsstrahlung spectrum');
    % ylim([1e-8 Inf]);
    % ax = gca;
    % ax.FontSize = 18;

    spectrum = [energy;emissivity1;emissivity0];
end



% energy = h*f_brem/e;

function intensity = get_intensity(spectrum)
    energy = spectrum(1,:);
    emissivity1 = spectrum(2,:);
    % emissivity0 = spectrum(3,:);

    T = readmatrix('/Users/shinjirotakeda/Library/CloudStorage/OneDrive-TheUniversityofTokyo/研究資料/フィルタ/Filters_231107.xlsx');
    E = T(:,1);
    T_Al10 = T(:,2);
    T_Al25 = T(:,3);
    T_My10 = T(:,4);
    T_My20 = T(:,5);

    E_new = 2:200;
    T_Al10_new = interp1(E,T_Al10,E_new);
    T_Al25_new = interp1(E,T_Al25,E_new);
    T_My10_new = interp1(E,T_My10,E_new);
    T_My20_new = interp1(E,T_My20,E_new);

    % figure;
    % % plot(E_new,T_Al10_new,'LineWidth',2);hold on;plot(E_new,T_Al25_new,'LineWidth',2);plot(E_new,T_My10_new,'LineWidth',2);plot(E_new,T_My20_new,'LineWidth',2);
    % semilogy(E_new,T_Al10_new,E_new,T_Al25_new,E_new,T_My10_new,E_new,T_My20_new,'LineWidth',2);
    % title('filter transmittance');xlabel('Photon energy [eV]');ylabel('Transmittance');
    % ax = gca;
    % ax.FontSize = 18;

    % emissivity0_new = interp1(energy,emissivity0,E_new);
    emissivity1_new = interp1(energy,emissivity1,E_new);
    emissivity1_new(emissivity1_new<0) = 0;
    % emissivityMatrix = [emissivity0_new;emissivity1_new];
    % emissivityMatrix(emissivityMatrix<0) = 0;

    intensity_Al10 = emissivity1_new*T_Al10_new.';
    intensity_Al25 = emissivity1_new*T_Al25_new.';
    intensity_My10 = emissivity1_new*T_My10_new.';
    intensity_My20 = emissivity1_new*T_My20_new.';
    intensity = [intensity_Al10;intensity_Al25;intensity_My10;intensity_My20];

    % GFR = Bt./Bp;
    % % GFR = [100, GFR];
    % figure;
    % subplot(2,2,1);semilogx(GFR,intensity_Al10(2:end),'LineWidth',2);xlabel('Bt/Bp');subtitle('Al10');
    % subplot(2,2,2);semilogx(GFR,intensity_Al25(2:end),'LineWidth',2);xlabel('Bt/Bp');subtitle('Al25');
    % subplot(2,2,3);semilogx(GFR,intensity_My10(2:end),'LineWidth',2);xlabel('Bt/Bp');subtitle('My10');
    % subplot(2,2,4);semilogx(GFR,intensity_My20(2:end),'LineWidth',2);xlabel('Bt/Bp');subtitle('My20');

end
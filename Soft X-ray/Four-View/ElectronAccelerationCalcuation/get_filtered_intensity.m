function intensity = get_filtered_intensity(emissivity, f)
    h = 6.63e-34; %プランク定数
    e = 1.6*10^(-19); %C
    % energy = spectrum(1,:);
    energy = f * h / e;
    % emissivity1 = spectrum(2,:);
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
    % T_Al25_new = interp1(E,T_Al25,E_new)*3;
    T_My10_new = interp1(E,T_My10,E_new);
    T_My20_new = interp1(E,T_My20,E_new);

    % figure;
    % % plot(E_new,T_Al10_new,'LineWidth',2);hold on;plot(E_new,T_Al25_new,'LineWidth',2);plot(E_new,T_My10_new,'LineWidth',2);plot(E_new,T_My20_new,'LineWidth',2);
    % semilogy(E_new,T_Al10_new,E_new,T_Al25_new,E_new,T_My10_new,E_new,T_My20_new,'LineWidth',2);
    % title('filter transmittance');xlabel('Photon energy [eV]');ylabel('Transmittance');
    % ax = gca;
    % ax.FontSize = 18;

    % emissivity0_new = interp1(energy,emissivity0,E_new);
    emissivity_new = interp1(energy,emissivity,E_new);
    emissivity_new(emissivity_new<0) = 0;
    % emissivityMatrix = [emissivity0_new;emissivity1_new];
    % emissivityMatrix(emissivityMatrix<0) = 0;

    intensity_Al10 = emissivity_new*T_Al10_new.';
    intensity_Al25 = emissivity_new*T_Al25_new.';
    intensity_My10 = emissivity_new*T_My10_new.';
    intensity_My20 = emissivity_new*T_My20_new.';
    intensity = [intensity_Al10;intensity_Al25;intensity_My10;intensity_My20];

    % GFR = Bt./Bp;
    % % GFR = [100, GFR];
    % figure;
    % subplot(2,2,1);semilogx(GFR,intensity_Al10(2:end),'LineWidth',2);xlabel('Bt/Bp');subtitle('Al10');
    % subplot(2,2,2);semilogx(GFR,intensity_Al25(2:end),'LineWidth',2);xlabel('Bt/Bp');subtitle('Al25');
    % subplot(2,2,3);semilogx(GFR,intensity_My10(2:end),'LineWidth',2);xlabel('Bt/Bp');subtitle('My10');
    % subplot(2,2,4);semilogx(GFR,intensity_My20(2:end),'LineWidth',2);xlabel('Bt/Bp');subtitle('My20');

end
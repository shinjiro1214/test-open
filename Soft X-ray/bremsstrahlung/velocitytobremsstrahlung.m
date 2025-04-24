me = 9.11e-31; %kg
e = 1.6*10^(-19); %C
e0 = 8.85e-12; %F/m
mi = 6.64e-26; %kg
mr = me*mi/(me+mi);
TA_eV = 25; %[eV]
TB_eV = 0;
% TA_K = TA_eV * 1.16045e4; %[K]
ne = 1*1e19; %m^-3
kB = 1.38e-23; %[J/K]
kBTA = TA_eV*e; %eV→J（kBはJ/K）
kBTB = TB_eV*e;
% lambdaD = sqrt(e0*kBT/(ne*e^2)); %m
% Lambda = 4*pi()*lambdaD^3*ne/3; %無次元数
Z = 1; %暫定的な価数
h = 6.63e-34; %プランク定数
% Ry = me*e^4/(2*h^2);
Ry = 13.6*e;
c = 3e8;
s = 2;
% vA_th = sqrt(8*kB*TA_K/me/pi()); %[m/s]
% vB_th = sqrt(8*kB*TB_K/me/pi());
% 
% EA_th_J = 1/2*me*vA_th^2; %[J]
% EB_th_J = 1/2*me*vB_th^2; %[J]

% e_brem = 10;
% f_brem = e_brem*e/h;
% w_brem = f_brem*2*pi();
% w_brem = 1e13:1e13:1e15;
% w_brem = 10.^(linspace(10,17,100));

f_brem = 10.^(linspace(10,17,100));
ve = 1e5:1e5:1e8;

dWA = log(me*ve.'.^2./(h*2*pi()*f_brem))./ve.';
dWB = log(me*ve.'.^2./(h*2*pi()*f_brem))./ve.';
dWB(ve < 1e6) = 0;  % Set dW to 0 where ve is smaller than 1e6

A = ve.^2.*exp(-me*ve.^2/(2*kBTA));
B = ve.^(2-2*s);
B = ve.^2.*exp(-me*ve.^2/(2*kBTB));

num_eA = sum(A);
num_eB = sum(B);

emissivityA = sum(dWA.*A.')/num_eA;
emissivityA(emissivityA<0) = 0;
emissivityB = sum(dWB.*B.')/num_eB;

energy = h*f_brem/e;

% emissivityB = energy.^(1-s)*10^(-5.5);

threshold = 85;
x = 1:1:100;
emissivitySA = emissivityA.*(1+exp((1*(x-threshold)))).^(-1);
emissivitySB = emissivityB.*(1+exp(-(1*(x-threshold)))).^(-1);
emissivityS = emissivitySA+emissivitySB;


figure;
% loglog(energy,emissivityA);
% hold on;
% loglog(energy,emissivityB);
% hold on;
loglog(energy, emissivityA);
%xlim([10 300]);
%ylim([1e-8 1e-5]);
% A = log10(E_th_J/(Z^2*Ry));
% B = e_brem*e/(Z^2*Ry);
% gff = log(me*v_th^2./(h*w_brem));
% 
% dW = 16*pi()*e^6/(3*sqrt(3)*c^3*me^2*v_th)*ne^2*Z*2*gff;
% 
% figure;loglog(h*f_brem./(me*v_th^2),dW);
% figure;loglog(h*f_brem./(me*v_th^2),log(me*v_th^2./(h*w_brem))./v_th);

% ve = 1e5:1e5:1e8;
% dPv = ve^2*exp(-me*ve^2/(2*kBT));
% 
% gff = log(me*ve.^2./(h*w_brem));
% 
% dW = 16*pi()*e^6/(3*sqrt(3)*c^3*me^2*v_th)*ne^2*Z*2*gff;




% filename = 'transmission.xlsx';
% sheets = {'al10','al25','mylar10', 'mylar25'};
% data_Al10 = readtable(filename, 'Sheet', sheets{1}, 'VariableNamingRule', 'preserve');
% data_Al25 = readtable(filename, 'Sheet', sheets{2}, 'VariableNamingRule', 'preserve');
% data_My10 = readtable(filename, 'Sheet', sheets{3}, 'VariableNamingRule', 'preserve');
% data_My25 = readtable(filename, 'Sheet', sheets{4}, 'VariableNamingRule', 'preserve');
% E = data_Al10{:, 1}.'; % 1列目: エネルギー (eV)
% T_Al10 = data_Al10{:, 2}.';  % 2列目: 透過率
% T_Al25 = data_Al25{:, 2}.';
% T_My10 = data_My10{:, 2}.';
% T_My25 = data_My25{:, 2}.';
% % E = T(:,1);
% % T_Al10 = T(:,2);
% % T_Al25 = T(:,3);
% % T_My10 = T(:,4);
% % T_My20 = T(:,5);
% E_new = 2:300;
% T_Al10_new = interp1(E,T_Al10,E_new);
% T_Al25_new = interp1(E,T_Al25,E_new);
% T_My10_new = interp1(E,T_My10,E_new);
% T_My25_new = interp1(E,T_My25,E_new);
% figure;plot(E_new,T_Al10_new);hold on;plot(E_new,T_Al25_new);plot(E_new,T_My10_new);plot(E_new,T_My25_new);
% emissivityS_new = interp1(energy,emissivityS,E_new);
% 
% disp(size(emissivityS_new))
% 
% intensity_Al10 = emissivityS_new*T_Al10_new.';
% intensity_Al25 = emissivityS_new*T_Al25_new.';
% intensity_My10 = emissivityS_new*T_My10_new.';
% intensity_My25 = emissivityS_new*T_My25_new.';
% 
% disp(intensity_Al10)
% disp(intensity_Al25)
% disp(intensity_My10)
% disp(intensity_My25)
% 
% figure;
% subplot(2,2,1);plot(intensity_Al10);xlabel('simulation pattern');subtitle('Al10');
% subplot(2,2,2);plot(intensity_Al25);xlabel('simulation pattern');subtitle('Al25');
% subplot(2,2,3);plot(intensity_My10);xlabel('simulation pattern');subtitle('My10');
% subplot(2,2,4);plot(intensity_My25);xlabel('simulation pattern');subtitle('My25');
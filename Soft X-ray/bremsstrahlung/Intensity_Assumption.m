
ReconMethod = 2;

transmission_n = 4;
% Parameters
x_min = 10;
x_max = 300;

% Generate x values between 10 and 300
%x = linspace(x_min, x_max, transmission_n);
x = logspace(log10(x_min), log10(x_max), transmission_n);

% Calculate y values proportional to x^(-2)
%I_assumption = (x-6).^(-2)+0.004;%nonenergetic
%I_assumption = exp(-(x*10^(-3)));%energetic
c = 3*10^(10);
m = 9.1*10^(-28);
h = 6.63*10^(-27);
E = 4.8*10^(-10);
k = 1.38*10^(-16);
H = 4.14*10^(-15);
Z = 1;
s = 3.6;
v = 10^6;
n = 10^(20);
TA = 1000;
TB = 50;

I_assumptionA = (2^5 * pi * E^6 / (3 * c^3 * m)) * sqrt(2 * pi / (3 * m * k)) * ...
     n^2 * Z^2 * TA^(-0.5) .* exp(-h*x ./ (H * k * TA));

% % Calculate I_assumption2 where x > 0
% I_assumptionB = (16 * pi * E^6 / (sqrt(3) * c^3 * m^2)) * n^2 * Z^2 * (2 * s - 3) / (2 * s - 2) * ...
%     v^(2 * s - 3) ./ (2 * h * 1e-6 * x / (H * m)).^(s - 1);
I_assumptionB = (2^5 * pi * E^6 / (3 * c^3 * m)) * sqrt(2 * pi / (3 * m * k)) * ...
     n^2 * Z^2 * TB^(-0.5) .* exp(-h *x ./ (H * k * TB));
I_assumptionB = x.^(1-s);
% % Calculate I_assumption2 where x > 0
% I_assumption(x* p > l) = (16 * pi * E^6 / (sqrt(3) * c^3 * m^2)) * n^2 * Z^2 * (2 * s - 3) / (2 * s - 2) * ...
%     v^(2 * s - 3) ./ (2 * h * p * x( x* p > l) / (H * m)).^(s - 1);

threshold = 25;
I_assumption = I_assumptionA.*(1+exp((1*(x-threshold)))).^(-1)+ I_assumptionB.*(1+exp(-(1*(x-threshold)))).^(-1);
I_assumption = I_assumption*1e-2;

n = 10;%　n％のノイズを加える
Iwgn=awgn(I_assumption,10*log10(100/n),'measured');
%Iwgn = I; % 0%
Iwgn(Iwgn<0)=0;

% Plot the graph
figure;
plot(x, I_assumption);
% hold on;
% plot(x,I_assumptionA);
% hold on;
% plot(x,I_assumptionB);
xlabel('Energy [eV]');
ylabel('Intensity [a.u.]');
hold on;
% title('I_assumption');
% grid on;
% set(gca, 'XScale', 'log');
% set(gca, 'YScale', 'log');
% xlim([x_min x_max]);

transmissionfile = sprintf('transmission_data%d.mat',transmission_n);
if ~isfile(transmissionfile)
    transmission(transmission_n);
end
load(transmissionfile, 'transmission_matrix','means', 'U','s','v','M','K');

Ep = transmission_matrix*Iwgn.';

%I = transmission_matrix\Ep;
I = get_distribution(M,K,U,s,v,Ep, transmission_matrix, ReconMethod);

% figure; % 新しい図を作成
plot(means, I, 'o-'); % 点と線でプロット
xlabel('Energy[eV]'); % x軸のラベル
ylabel('Intensity[a.u.]'); % y軸のラベル
% title('Bremsstrahlung Intensity'); % タイトル
hold off;
grid on; % グリッドを表示
set(gca, 'XScale', 'log');
set(gca, 'YScale', 'log');
xlim([x_min x_max]);
legend('理想スペクトル', '再構成スペクトル');

I_new = interp1(x, I_assumption, means, 'linear');

differences = I_new - I;


% 平均二乗誤差 (MSE)
mse = mean(differences.^2, 'all');
disp(mse)


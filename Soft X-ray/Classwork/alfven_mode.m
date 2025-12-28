%先端プラズマ理工学課題

clear;

R0 = 1;
a = 0.25;
ra = linspace(0, 1, 500);
r = ra * a;

n = 2;
m1 = -2;
m2 = -3;

q = 1+ra.^2;

%(1)
arf11 = (1/R0) * (n+m1 ./q);
arf21 = (1/R0) * (n+m2 ./q);

figure;
plot(ra, abs(arf11), 'b-', 'LineWidth', 2);hold on;
plot(ra, abs(arf21), 'r-', 'LineWidth', 2);
xlabel('r/a');
ylabel('\omega / V_A');
legend('n = 2, m = -2', 'n = 2, m = -3');
title('Alfven Resonant Frequency');
grid on;
ylim([0 1]);
xlim([0 1]);
hold off;

%(2)
arf12 = (1/R0) * (n+(m1+1) ./q);
arf22 = (1/R0) * (n+(m2+1) ./q);

arft1p = (arf11.^2+arf12.^2+((arf11.^2-arf12.^2).^2+4*(2*r/R0).^2.*arf11.^2.*arf12.^2).^0.5)./(2*(1-(2*r./R0).^2));
arft1m = (arf11.^2+arf12.^2-((arf11.^2-arf12.^2).^2+4*(2*r/R0).^2.*arf11.^2.*arf12.^2).^0.5)./(2*(1-(2*r./R0).^2));

arft2p = (arf21.^2+arf22.^2+((arf21.^2-arf22.^2).^2+4*(2*r/R0).^2.*arf21.^2.*arf22.^2).^0.5)./(2*(1-(2*r./R0).^2));
arft2m = (arf21.^2+arf22.^2-((arf21.^2-arf22.^2).^2+4*(2*r/R0).^2.*arf21.^2.*arf22.^2).^0.5)./(2*(1-(2*r./R0).^2));

% (3)
% arft10p = (arf11.^2+arf12.^2+abs(arf11.^2-arf12.^2))/2;
% arft10m = (arf11.^2+arf12.^2-abs(arf11.^2-arf12.^2))/2;
% arft20p = (arf21.^2+arf22.^2+abs(arf21.^2-arf22.^2))/2;
% arft20m = (arf21.^2+arf22.^2-abs(arf21.^2-arf22.^2))/2; %冗長すぎるよ笑笑

arft10p = max(arf11.^2, arf12.^2);
arft10m = min(arf11.^2, arf12.^2);
arft20p = max(arf21.^2, arf22.^2);
arft20m = min(arf21.^2, arf22.^2);

figure;
plot(ra, abs(arft1p), 'b-', 'LineWidth', 2);hold on;
plot(ra, abs(arft1m), 'b-', 'LineWidth', 2, 'HandleVisibility', 'off');
plot(ra, abs(arft2p), 'r-', 'LineWidth', 2);
plot(ra, abs(arft2m), 'r-', 'LineWidth', 2, 'HandleVisibility', 'off');
plot(ra, abs(arft10p), 'k--', 'LineWidth', 2);
plot(ra, abs(arft10m), 'k--', 'LineWidth', 2, 'HandleVisibility', 'off');
plot(ra, abs(arft20p), 'g--', 'LineWidth', 2);
plot(ra, abs(arft20m), 'g--', 'LineWidth', 2, 'HandleVisibility', 'off');
xlabel('r/a');
ylabel('\omega / V_A');
legend('n = 2, m = -2', 'n = 2, m = -3', 'r/R0 -> 0 n = 2, m = -2','r/R0 -> 0 n = 2, m = -3');
title('Alfven Resonant Frequency with Toroidal Effect');
grid on;
% ylim([0 1]);
% xlim([0 1]);
hold off;
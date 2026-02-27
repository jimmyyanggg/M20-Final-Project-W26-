function [t, y, vy, ke, pe, te, stats] = simulateBouncingBall(p)
% still only 1D

n = floor(p.tEnd / p.dt) + 1;
t = (0:n-1)' * p.dt;
y = zeros(n, 1);
vy = zeros(n, 1);

y(1) = p.y0;
vy(1) = p.vy0;

numBounces = 0;
firstBounceHeight = NaN;

for i = 2:n
    a = -p.g - (p.c / p.m) * vy(i-1);
    vy(i) = vy(i-1) + a * p.dt;
    y(i) = y(i-1) + vy(i) * p.dt;

    if y(i) <= 0
        y(i) = 0;

        if vy(i) < 0
            vy(i) = -p.e * vy(i);
            numBounces = numBounces + 1;

            if numBounces == 1
                firstBounceHeight = (vy(i)^2) / (2 * p.g);
            end

            % very simple "friction-like" damping at contact
            vy(i) = (1 - 0.12 * p.mu) * vy(i);
        end
    end
end

ke = 0.5 * p.m * vy.^2;
pe = p.m * p.g * y;
te = ke + pe;

stats.numBounces = numBounces;
stats.maxHeight = max(y);
stats.firstBounceHeight = fillmissing(firstBounceHeight, 'constant', 0);
if te(1) > 0
    stats.energyLossPct = 100 * (te(1) - te(end)) / te(1);
else
    stats.energyLossPct = 0;
end
end

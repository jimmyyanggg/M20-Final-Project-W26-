% function that returns the stats, handles the animation, and runs the
% physics and math behind the ball

function [t, x, y, vx, vy, speed, ke, pe, te, stats] = simulateBouncingBall(p, doAnimate, axMotion)

    %function won't try to animate or draw anything if empty or if no axis
    if isempty(doAnimate)
        doAnimate = false;
    end

    if isempty(axMotion)
        axMotion = [];
    end


    % number of time separations fit in total runtime
    n = floor(p.tEnd / p.dt) + 1;
    if n < 2
        n = 2;
    end

    %create blank lists for tim, position, and speed values
    t  = (0:n-1)' * p.dt;
    x  = zeros(n, 1);
    y  = zeros(n, 1);
    vx = zeros(n, 1);
    vy = zeros(n, 1);

    %first element of each vector when t = 0
    x(1)  = p.x0;
    y(1)  = max(0, p.y0);   % do not start below ground
    vx(1) = p.vx0;
    vy(1) = p.vy0;



    % counters/stat values
    numBounces = 0;
    firstBounceHeight = [];
    lastIndex = n;

    % create animation objects ONLY if user checks the animate box
    if doAnimate && isgraphics(axMotion, 'axes')
        hold(axMotion, 'on');

        %shows a red ball and shows a line that follows the ball
        ballMark = plot(axMotion, x(1), y(1), 'ro','MarkerFaceColor', 'r');
        trajLine = plot(axMotion, x(1), y(1), 'b');

        %ground line for reference point
        plot(axMotion, [x(1)-1, x(1)+1], [0, 0], 'k');
        grid(axMotion, 'on');
        hold(axMotion, 'off');
    end

    % main time loop
    for i = 2:n

        % if reset was pressed or window got closed, stop and exit early
        if isgraphics(p.fig, 'figure')
            if isappdata(p.fig, 'stopSim') && getappdata(p.fig, 'stopSim')
                lastIndex = i - 1;
                break;
            end
        else
            %if UI gets closed, break simulation instantly
            lastIndex = i - 1;
            break;
        end

        %PHYSICS CALCULATIONS


        % acceleration: x and y components
        ax = -(p.c / p.m) * vx(i-1);
        ay = -p.g - (p.c / p.m) * vy(i-1);

        % velocity formulas
        vx(i) = vx(i-1) + ax * p.dt;
        vy(i) = vy(i-1) + ay * p.dt;

        % position formulas
        x(i) = x(i-1) + vx(i) * p.dt;
        y(i) = y(i-1) + vy(i) * p.dt;

        % bounce on ground
        if y(i) <= 0
            y(i) = 0;  


            %when ball travels downwards (negative velocity)
            if vy(i) < 0  

                %bounces  -> vertical velocity becomes positive -> reduced
                %from restitution
                vy(i) = -p.e * vy(i);

                %horizontal speed decreases depending on material (constant
                %comes from carpet friction factor)
                vx(i) = (1 - 0.2 * p.mu) * vx(i);


                %adds to bounce counter
                numBounces = numBounces + 1;
                if numBounces == 1

                    %save first bounce peak for exported data
                    firstBounceHeight = (vy(i)^2) / (2 * p.g);
                end
            end
        end

        % drawing animation. ONLY if user turns it on and axis still exist.
        %updates every 2nd physics step
        if doAnimate && isgraphics(axMotion, 'axes') && mod(i, 2) == 0
            
            %puts all x and y points into line object and then draws the
            %path the ball already traveled.
            trajLine.XData = x(1:i);
            trajLine.YData = y(1:i);

            %moves the moving ball marker to the newest updated position
            ballMark.XData = x(i);
            ballMark.YData = y(i);

            %immediately draws graphic changes in the UI
            drawnow;
        end
    end




    

    % keep only simulated portion if stopped early. keeps only computed
    % part, doesn't use the rest of the zeros in the array.
    t  = t(1:lastIndex);
    x  = x(1:lastIndex);
    y  = y(1:lastIndex);
    vx = vx(1:lastIndex);
    vy = vy(1:lastIndex);

    % numbers for data
    %speed
    speed = sqrt(vx.^2 + vy.^2);

    %kinetic energy
    ke = 0.5 * p.m * speed.^2;

    %potential energy
    pe = p.m * p.g * y;

    %total mechanical energy
    te = ke + pe;

    % summary of stats
    stats.numBounces = numBounces;
    stats.maxHeight = max(y);
    stats.maxRange = max(x) - min(x);
    stats.firstBounceHeight = firstBounceHeight;
    stats.peakSpeed = max(speed);
    
    %stat for energy loss percentage

    if te(1) > 0
        stats.energyLossPct = 100 * (te(1) - te(end)) / te(1);
    else
        stats.energyLossPct = 0;
    end
end

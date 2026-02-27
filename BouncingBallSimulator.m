function BouncingBallSimulator
% Bouncing Ball Physics Simulator
% midpoint check
%
% this file handles UI/buttons/plots/graphs/frontend
%
% So far:
% - gravity + simple air drag + bounce restitution
% - basic plots + basic stats + csv save
% - simulateBouncingBall.m file handles the real-world physics.
%
% TODO:
% - add real animation
% - full 2D model
% - cleaner collision handling + better reporting

    ui = buildUI();
    ui.runButton.ButtonPushedFcn = @(~,~) runSimulation(ui);
    ui.resetButton.ButtonPushedFcn = @(~,~) resetPlots(ui);
    ui.saveButton.ButtonPushedFcn = @(~,~) saveLastRun(ui);
end

function ui = buildUI()
    fig = uifigure('Name', 'Bouncing Ball Physics Simulator', 'Position', [80 80 1200 700]);
    gl = uigridlayout(fig, [1 2]);
    gl.ColumnWidth = {300, '1x'};

    left = uipanel(gl, 'Title', 'Controls');
    left.Layout.Row = 1;
    left.Layout.Column = 1;
    ctl = uigridlayout(left, [24 2]);
    ctl.RowHeight = repmat({24}, 1, 24);
    ctl.ColumnWidth = {150, '1x'};

    addLabel(ctl, 1, 'Gravity g (m/s^2):');
    gField = uieditfield(ctl, 'numeric', 'Value', 9.81, 'Limits', [0 Inf], 'RoundFractionalValues', false);
    setPos(gField, 1, 2);

    addLabel(ctl, 2, 'Mass m (kg):');
    mField = uieditfield(ctl, 'numeric', 'Value', 1.0, 'Limits', [0.001 Inf], 'RoundFractionalValues', false);
    setPos(mField, 2, 2);

    addLabel(ctl, 3, 'Air drag c (kg/s):');
    cField = uieditfield(ctl, 'numeric', 'Value', 0.08, 'Limits', [0 Inf], 'RoundFractionalValues', false);
    setPos(cField, 3, 2);

    addLabel(ctl, 4, 'Restitution e (0-1):');
    eField = uieditfield(ctl, 'numeric', 'Value', 0.82, 'Limits', [0 1], 'RoundFractionalValues', false);
    setPos(eField, 4, 2);

    addLabel(ctl, 5, 'Ground friction mu:');
    muField = uieditfield(ctl, 'numeric', 'Value', 0.05, 'Limits', [0 1], 'RoundFractionalValues', false);
    setPos(muField, 5, 2);

    addLabel(ctl, 6, 'Initial height y0 (m):');
    y0Field = uieditfield(ctl, 'numeric', 'Value', 5.0, 'Limits', [0 Inf], 'RoundFractionalValues', false);
    setPos(y0Field, 6, 2);

    addLabel(ctl, 7, 'Initial vy0 (m/s):');
    vy0Field = uieditfield(ctl, 'numeric', 'Value', 0.0, 'RoundFractionalValues', false);
    setPos(vy0Field, 7, 2);

    addLabel(ctl, 8, 'Total time (s):');
    tEndField = uieditfield(ctl, 'numeric', 'Value', 8.0, 'Limits', [0.2 200], 'RoundFractionalValues', false);
    setPos(tEndField, 8, 2);

    addLabel(ctl, 9, 'dt (s):');
    dtField = uieditfield(ctl, 'numeric', 'Value', 0.005, 'Limits', [1e-4 0.1], 'RoundFractionalValues', false);
    setPos(dtField, 9, 2);

    runButton = uibutton(ctl, 'push', 'Text', 'Run Simulation');
    setPos(runButton, 11, [1 2]);
    resetButton = uibutton(ctl, 'push', 'Text', 'Reset Plots');
    setPos(resetButton, 12, [1 2]);
    saveButton = uibutton(ctl, 'push', 'Text', 'Save Last Run');
    setPos(saveButton, 13, [1 2]);

    compareButton = uibutton(ctl, 'push', ...
        'Text', 'Compare Runs (TODO)', ...
        'Enable', 'off', ...
        'Tooltip', 'Planned for second half: compare multiple parameter sets.');
    setPos(compareButton, 14, [1 2]);

    animateButton = uibutton(ctl, 'push', ...
        'Text', 'Real-Time Animation (TODO)', ...
        'Enable', 'off', ...
        'Tooltip', 'Planned for second half: frame-by-frame animation.');
    setPos(animateButton, 15, [1 2]);

    statsLabel = uilabel(ctl, 'Text', "Stats:" + newline + "(press run)", ...
        'HorizontalAlignment', 'left');
    setPos(statsLabel, 17, [1 2]);
    statsLabel.FontSize = 12;

    scopeArea = uitextarea(ctl, ...
        'Editable', 'off', ...
        'Value', { ...
        'Midpoint scope:', ...
        '- Done: 1D sim + drag + bounce + plots + stats + CSV save', ...
        '- Not done: true animation, 2D motion, compare mode', ...
        '- This is a prototype for check-in, not final'});
    setPos(scopeArea, [20 24], [1 2]);
    scopeArea.FontSize = 11;

    right = uipanel(gl, 'Title', 'Simulation & Plots');
    right.Layout.Row = 1;
    right.Layout.Column = 2;
    rg = uigridlayout(right, [2 2]);
    rg.RowHeight = {'1x', '1x'};
    rg.ColumnWidth = {'1x', '1x'};

    axMotion = uiaxes(rg); setPos(axMotion, 1, 1);
    title(axMotion, 'Ball Motion'); xlabel(axMotion, 'x (m)'); ylabel(axMotion, 'y (m)');
    xlim(axMotion, [-1 1]); ylim(axMotion, [0 10]); grid(axMotion, 'on');

    axHeight = uiaxes(rg); setPos(axHeight, 1, 2);
    title(axHeight, 'Height vs Time'); xlabel(axHeight, 'Time (s)'); ylabel(axHeight, 'Height (m)'); grid(axHeight, 'on');

    axVel = uiaxes(rg); setPos(axVel, 2, 1);
    title(axVel, 'Velocity vs Time'); xlabel(axVel, 'Time (s)'); ylabel(axVel, 'Velocity (m/s)'); grid(axVel, 'on');

    axEnergy = uiaxes(rg); setPos(axEnergy, 2, 2);
    title(axEnergy, 'Energy vs Time'); xlabel(axEnergy, 'Time (s)'); ylabel(axEnergy, 'Energy (J)'); grid(axEnergy, 'on');

    ui = struct();
    ui.fig = fig;
    ui.g = gField;
    ui.m = mField;
    ui.c = cField;
    ui.e = eField;
    ui.mu = muField;
    ui.y0 = y0Field;
    ui.vy0 = vy0Field;
    ui.tEnd = tEndField;
    ui.dt = dtField;
    ui.runButton = runButton;
    ui.resetButton = resetButton;
    ui.saveButton = saveButton;
    ui.compareButton = compareButton;
    ui.animateButton = animateButton;
    ui.statsLabel = statsLabel;
    ui.scopeArea = scopeArea;
    ui.axMotion = axMotion;
    ui.axHeight = axHeight;
    ui.axVel = axVel;
    ui.axEnergy = axEnergy;
    ui.lastRun = [];
end

function runSimulation(ui)
    p.g = ui.g.Value;
    p.m = ui.m.Value;
    p.c = ui.c.Value;
    p.e = ui.e.Value;
    p.mu = ui.mu.Value;
    p.y0 = ui.y0.Value;
    p.vy0 = ui.vy0.Value;
    p.tEnd = ui.tEnd.Value;
    p.dt = ui.dt.Value;

    [t, y, vy, ke, pe, te, stats] = simulateBouncingBall(p);

    cla(ui.axMotion);
    x = zeros(size(y));
    plot(ui.axMotion, x, y, 'LineWidth', 1.8);
    hold(ui.axMotion, 'on');
    scatter(ui.axMotion, x(end), y(end), 45, 'filled');
    yline(ui.axMotion, 0, '--k', 'Ground');
    ylim(ui.axMotion, [0, max(1.05 * max(y), p.y0 + 1)]);
    xlim(ui.axMotion, [-0.3 0.3]);
    hold(ui.axMotion, 'off');

    cla(ui.axHeight);
    plot(ui.axHeight, t, y, 'LineWidth', 1.8);

    cla(ui.axVel);
    plot(ui.axVel, t, vy, 'LineWidth', 1.8);
    yline(ui.axVel, 0, '--k');

    cla(ui.axEnergy);
    plot(ui.axEnergy, t, ke, 'LineWidth', 1.5, 'DisplayName', 'KE');
    hold(ui.axEnergy, 'on');
    plot(ui.axEnergy, t, pe, 'LineWidth', 1.5, 'DisplayName', 'PE');
    plot(ui.axEnergy, t, te, 'LineWidth', 1.8, 'DisplayName', 'Total');
    hold(ui.axEnergy, 'off');
    legend(ui.axEnergy, 'Location', 'best');

    ui.statsLabel.Text = sprintf([ ...
        "Stats:\n" + ...
        "Stage: Midpoint (1D)\n" + ...
        "Bounces: %d\n" + ...
        "Max Height: %.3f m\n" + ...
        "First Bounce Height: %.3f m\n" + ...
        "Simulated Time: %.2f s\n" + ...
        "Energy Lost: %.2f %%\n" + ...
        "Ground friction factor used: %.3f"], ...
        stats.numBounces, stats.maxHeight, stats.firstBounceHeight, ...
        t(end), stats.energyLossPct, p.mu);

    ui.lastRun = table(t, y, vy, ke, pe, te);
    setappdata(ui.fig, 'lastRun', ui.lastRun);
end

function resetPlots(ui)
    cla(ui.axMotion); cla(ui.axHeight); cla(ui.axVel); cla(ui.axEnergy);
    title(ui.axMotion, 'Ball Motion');
    title(ui.axHeight, 'Height vs Time');
    title(ui.axVel, 'Velocity vs Time');
    title(ui.axEnergy, 'Energy vs Time');
    grid(ui.axMotion, 'on'); grid(ui.axHeight, 'on'); grid(ui.axVel, 'on'); grid(ui.axEnergy, 'on');
    ui.statsLabel.Text = "Stats:" + newline + "(press run)";
    setappdata(ui.fig, 'lastRun', []);
end

function saveLastRun(ui)
    data = getappdata(ui.fig, 'lastRun');
    if isempty(data)
        uialert(ui.fig, 'No simulation data to save yet. Run simulation first.', 'Nothing to Save');
        return;
    end

    [file, path] = uiputfile('simulation_results.csv', 'Save Simulation Data');
    if isequal(file, 0)
        return;
    end
    writetable(data, fullfile(path, file));
    uialert(ui.fig, 'Saved CSV for this run.', 'Saved');
end

function addLabel(parent, row, textValue)
    lbl = uilabel(parent, 'Text', textValue, 'HorizontalAlignment', 'left');
    setPos(lbl, row, 1);
end

function setPos(component, row, col)
    component.Layout.Row = row;
    component.Layout.Column = col;
end

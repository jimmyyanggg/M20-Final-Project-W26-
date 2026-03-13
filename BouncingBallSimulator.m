function BouncingBallSimulator
    %initial GUI
    ui = buildUI();
    setappdata(ui.fig,'lastRun',[]);
    setappdata(ui.fig,'stopSim', false);

    % make sure clicking out stops animation/loop first
    ui.fig.CloseRequestFcn = @(src,~) closeApp(src);

    %map buttons to coded functions
    ui.runButton.ButtonPushedFcn   = @(~,~) runSimulation(ui);
    ui.resetButton.ButtonPushedFcn = @(~,~) resetPlots(ui);
    ui.saveButton.ButtonPushedFcn  = @(~,~) saveLastRun(ui);
end


%main app layout (window, user inputs and buttons, control grid)
function ui = buildUI()
    fig = uifigure('Name','Bouncing Ball Physics Simulator', 'Position',[80 80 1100 700]);

    mainGrid = uigridlayout(fig,[1 2]);
    mainGrid.ColumnWidth = {300,'1x'};

    leftPanel = uipanel(mainGrid,'Title','Controls');
    leftPanel.Layout.Row = 1;
    leftPanel.Layout.Column = 1;

    ctrl = uigridlayout(leftPanel,[15 2]);
    ctrl.RowHeight = repmat({24},1,26);
    ctrl.ColumnWidth = {140,'1x'};


    %changeable Physics inputs 
    addLabel(ctrl,1,'Gravity (m/s^2):');
    gravInput = uieditfield(ctrl,'numeric', 'Value',9.81,'Limits',[0 Inf],'RoundFractionalValues',false);
    setPos(gravInput,1,2);

    addLabel(ctrl,2,'Mass (kg):');
    massInput = uieditfield(ctrl,'numeric', 'Value',1.0,'Limits',[0.001 Inf],'RoundFractionalValues',false);
    setPos(massInput,2,2);

    addLabel(ctrl,3,'Air drag(kg/s):');
    dragInput = uieditfield(ctrl,'numeric','Value',0.05,'Limits',[0 Inf],'RoundFractionalValues',false);
    setPos(dragInput,3,2);

    addLabel(ctrl,4,'Restitution e (0-1):');
    restitutionInput = uieditfield(ctrl,'numeric', 'Value',0.82,'Limits',[0 1],'RoundFractionalValues',false);
    setPos(restitutionInput,4,2);

    addLabel(ctrl,5,'Ground friction:');
    fricInput = uieditfield(ctrl,'numeric', 'Value',0.05,'Limits',[0 1],'RoundFractionalValues',false);
    setPos(fricInput,5,2);

    %inital positions and velocities
    addLabel(ctrl,6,'Initial x0 (m):');
    x0Input = uieditfield(ctrl,'numeric','Value',0.0,'RoundFractionalValues',false);
    setPos(x0Input,6,2);

    addLabel(ctrl,7,'Initial y0 (m):');
    y0Input = uieditfield(ctrl,'numeric','Value',5.0,'Limits',[0 Inf],'RoundFractionalValues',false);
    setPos(y0Input,7,2);

    addLabel(ctrl,8,'Initial vx0 (m/s):');
    vx0Input = uieditfield(ctrl,'numeric', 'Value',1.0,'RoundFractionalValues',false);
    setPos(vx0Input,8,2);

    addLabel(ctrl,9,'Initial vy0 (m/s):');
    vy0Input = uieditfield(ctrl,'numeric', 'Value',0.0,'RoundFractionalValues',false);
    setPos(vy0Input,9,2);

    %set simulation length
    addLabel(ctrl,10,'Simulation time (s):');
    timeEndInput = uieditfield(ctrl,'numeric', 'Value',8.0,'Limits',[0.2 200],'RoundFractionalValues',false);
    setPos(timeEndInput,10,2);

    %simulation step size
    addLabel(ctrl,11,'dt (s):');
    timeChangeInput = uieditfield(ctrl,'numeric','Value',0.005,'Limits',[1e-4 0.1],'RoundFractionalValues',false);
    setPos(timeChangeInput,11,2);



    %allows user if they want to see animation or not
    animateCheck = uicheckbox(ctrl,'Text','Animate while running','Value',true);
    setPos(animateCheck,12,[1 2]);


    %Create buttons
    runButton = uibutton(ctrl,'push','Text','Run Simulation');
    setPos(runButton,14,[1 2]);

    resetButton = uibutton(ctrl,'push','Text','Reset Plots');
    setPos(resetButton,15,[1 2]);

    saveButton = uibutton(ctrl,'push','Text','Save Last Run (CSV)');
    setPos(saveButton,16,[1 2]);


    %used a ui text area to show a multi-line display box
    statusLabel = uitextarea(ctrl,'Value', {'Status: ready'}, 'Editable', 'off', 'WordWrap', 'on');
    setPos(statusLabel, [18 40], [1 2]);

   


    %create 2x2 grid for trajectory, height, velocity, and energy
    rightPanel = uipanel(mainGrid,'Title','Plots');
    rightPanel.Layout.Row = 1;
    rightPanel.Layout.Column = 2;

    pGrid = uigridlayout(rightPanel,[2 2]);
    pGrid.RowHeight = {'1x','1x'};
    pGrid.ColumnWidth = {'1x','1x'};


    %axis for trajectory plot
    axMotion = uiaxes(pGrid);
    setPos(axMotion,1,1);
    title(axMotion,'Trajectory');
    xlabel(axMotion,'x (m)');
    ylabel(axMotion,'y (m)');
    grid(axMotion,'on');

    %axis for height plot
    axHeight = uiaxes(pGrid);
    setPos(axHeight,1,2);
    title(axHeight,'Height vs Time');
    xlabel(axHeight,'Time (s)');
    ylabel(axHeight,'Height (m)');
    grid(axHeight,'on');

    %axis for velocity height
    axVel = uiaxes(pGrid);
    setPos(axVel,2,1);
    title(axVel,'Velocities vs Time');
    xlabel(axVel,'Time (s)');
    ylabel(axVel,'Velocity (m/s)');
    grid(axVel,'on');


    %axis for energy plot
    axEnergy = uiaxes(pGrid);
    setPos(axEnergy,2,2);
    title(axEnergy,'Energy vs Time');
    xlabel(axEnergy,'Time (s)');
    ylabel(axEnergy,'Energy (J)');
    grid(axEnergy,'on');

    
    %UI STRUCT: easy to access
    ui.fig = fig;
    ui.g = gravInput;
    ui.m = massInput;
    ui.c = dragInput;
    ui.e = restitutionInput;
    ui.mu = fricInput;
    ui.x0 = x0Input;
    ui.y0 = y0Input;
    ui.vx0 = vx0Input;
    ui.vy0 = vy0Input;
    ui.tEnd = timeEndInput;
    ui.dt = timeChangeInput;
    ui.animateCheck = animateCheck;
    ui.runButton = runButton;
    ui.resetButton = resetButton;
    ui.saveButton = saveButton;
    ui.statusLabel = statusLabel;
    ui.axMotion = axMotion;
    ui.axHeight = axHeight;
    ui.axVel = axVel;
    ui.axEnergy = axEnergy;
end


%main function for the RUN button
function runSimulation(ui)
    % stop any old run and clear previous output
    if isappdata(ui.fig,'stopSim')
        setappdata(ui.fig,'stopSim',false);
    end

    % if app closed or any plot is messed up, do nothing and exit function
    if ~isgraphics(ui.fig, "figure") || ~isgraphics(ui.axMotion, "axes") || ~isgraphics(ui.axHeight, "axes") ||~isgraphics(ui.axVel, "axes") ||~isgraphics(ui.axEnergy, "axes")
        return;
    end

    p = readParams(ui);
    setStatus(ui,'Running simulation...');
    cla(ui.axMotion); cla(ui.axHeight); cla(ui.axVel); cla(ui.axEnergy);


    % Run the simulated physics model from other file. gets time and
    % simulation stats
    [t,x,y,vx,vy,speed,ke,pe,te,stats] = simulateBouncingBall(p, ui.animateCheck.Value, ui.axMotion);

    if isempty(t)
        setStatus(ui,'No data produced.');
        return;
    end

    % Height plot
    plot(ui.axHeight, t, y);
    legend(ui.axHeight,{'Height'},'Location','best');


    %Velocity plot
    plot(ui.axVel, t, vx);
    hold(ui.axVel,'on');
    plot(ui.axVel, t, vy);
    plot(ui.axVel, t, speed, ':');
    hold(ui.axVel,'off');
    legend(ui.axVel,{'Vx','Vy','Speed'},'Location','best');


    %Energies: kinetic, potential, total mechanical
    plot(ui.axEnergy, t, ke);
    hold(ui.axEnergy,'on');
    plot(ui.axEnergy, t, pe);
    plot(ui.axEnergy, t, te);
    hold(ui.axEnergy,'off');
    legend(ui.axEnergy,{'KE','PE','Total'},'Location','best');

     
    %overal trajectory and final position
    plot(ui.axMotion, x, y);
    hold(ui.axMotion,'on');
    scatter(ui.axMotion, x(end), y(end), 25, 'filled');
    plot(ui.axMotion, [min(x)-1 max(x)+1], [0 0], 'k--');
    hold(ui.axMotion,'off');


    % shows nothing first so that it's not blank. replace when first bounce
    % occurs
    if isempty(stats.firstBounceHeight)
        firstTxt = 'N/A';
    else
        % converts the number to a string
        firstTxt = num2str(stats.firstBounceHeight, '%.3f');
    end

    statusText = { ...
        'Status: finished', ...
         ['Bounces: ' num2str(stats.numBounces)], ...
         ['Max height: ' num2str(stats.maxHeight, '%.2f') ' m'], ...
         ['Max range: ' num2str(stats.maxRange, '%.2f') ' m'], ...
         ['First bounce height: ' firstTxt ' m'], ...
         ['Energy lost: ' num2str(stats.energyLossPct, '%.2f') ' %'], ...
         ['Peak speed: ' num2str(stats.peakSpeed, '%.2f') ' m/s']};

    
    %only update UI text if window is still open
    if isgraphics(ui.fig, 'figure')
        setStatus(ui, statusText);
    end



    %saves run. when "save run" button gets clicked, data gets exported as
    %csv
    lastRun = table(t,x,y,vx,vy,speed,ke,pe,te, ...
        'VariableNames',{'Time','x','y','vx','vy','speed','KE','PE','Total E'});
    setappdata(ui.fig,'lastRun',lastRun);
end



%PARAMETERS STRUCT - collects all inputted values from UI and turns into
%computable numbers
function p = readParams(ui)
    p.g = ui.g.Value;
    p.m = ui.m.Value;
    p.c = ui.c.Value;
    p.e = ui.e.Value;
    p.mu = ui.mu.Value;
    p.x0 = ui.x0.Value;
    p.y0 = ui.y0.Value;
    p.vx0 = ui.vx0.Value;
    p.vy0 = ui.vy0.Value;
    p.tEnd = ui.tEnd.Value;
    p.dt = ui.dt.Value;
    p.fps = 60;
    p.fig = ui.fig;
end


%clears the four plots so previous simulation traces are removed
function resetPlots(ui)
    % signal running simulation (if any) to stop
    setappdata(ui.fig,'stopSim', true);

    cla(ui.axMotion);
    cla(ui.axHeight);
    cla(ui.axVel); 
    cla(ui.axEnergy);

    %re-adds the axis labels after clearing everything
    title(ui.axMotion,'Trajectory'); xlabel(ui.axMotion,'x (m)'); ylabel(ui.axMotion,'y (m)'); grid(ui.axMotion,'on');
    title(ui.axHeight,'Height vs Time'); xlabel(ui.axHeight,'Time (s)'); ylabel(ui.axHeight,'Height (m)'); grid(ui.axHeight,'on');
    title(ui.axVel,'Velocities vs Time'); xlabel(ui.axVel,'Time (s)'); ylabel(ui.axVel,'Velocity (m/s)'); grid(ui.axVel,'on');
    title(ui.axEnergy,'Energy vs Time'); xlabel(ui.axEnergy,'Time (s)'); ylabel(ui.axEnergy,'Energy (J)'); grid(ui.axEnergy,'on');

    % updates status and stores the data
    setStatus(ui,'Status: reset complete');
    setappdata(ui.fig,'lastRun',[]);
end


%saves last ran data to CSV and then changes status text
function saveLastRun(ui)
    data = getappdata(ui.fig,'lastRun');
    if isempty(data)
        uialert(ui.fig,'No run to save. Run Simulation first.','No Data');
        return;
    end
    %asks user where they want to save the file
    [file,path] = uiputfile('bouncingball_last_run.csv','Save last run');
    if isequal(file,0) 
        return; 
    end
    %writes table to csv
    writetable(data, fullfile(path,file));
    uialert(ui.fig,['Saved: ' fullfile(path,file)], 'Saved');
end


%updates status text and displays in UI
function setStatus(ui, txt)
    %make sure window and status box are still open and there. supports
    %both one line and multiline status texts
    if isgraphics(ui.fig, 'figure') && isgraphics(ui.statusLabel)
        if iscell(txt)
            ui.statusLabel.Value = txt;    
        else
            ui.statusLabel.Value = {txt};   
        end
        drawnow;
    end
end



%addlabel function
function addLabel(parent,row,textValue)
    label = uilabel(parent,'Text',textValue);

    %places labels in top left part of overall UI
    setPos(label,row,1);
end


%places UI objects in specific rows and columns of uigridlayout
function setPos(component,row,col)
    component.Layout.Row = row;
    component.Layout.Column = col;
end


% closing window stops simulation first so no invalid handle errors
function closeApp(figHandle)
    if isgraphics(figHandle,'figure')
        setappdata(figHandle,'stopSim', true);
    end
    delete(figHandle);
end

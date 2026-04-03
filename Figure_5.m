%% =========================================================
%  Physics-Guided Spatio-Temporal Deep Learning for
%  Time-Lapse GPR Reconstruction in Karst Systems
%  Figure 1: Karst Time-Lapse Conceptual Framework
%  Panels (a)(b)(c): Geological Evolution Sequence
%  Panel (d): Physical Properties of GPR Modeling
%% =========================================================

clc; clear; close all;

%% =========================================================
%  FIGURE SETUP
%% =========================================================

fig = figure('Color', 'w', ...
             'Position', [20 20 1400 850], ...
             'Name', 'Figure 1 - Karst Time-Lapse Conceptual Framework');

%% =========================================================
%  COLORMAPS
%% =========================================================

% Limestone bedrock colormap (grey tones)
cmap_rock   = [0.55 0.55 0.55;
               0.65 0.65 0.65;
               0.72 0.72 0.72;
               0.80 0.80 0.80];

% Water/fluid colormap (blue tones)
cmap_water  = [0.10 0.25 0.75;
               0.15 0.40 0.85;
               0.20 0.55 0.90;
               0.30 0.65 0.95];

% Mineral/sediment colormap (orange-brown tones)
cmap_mineral = [0.85 0.45 0.10;
                0.90 0.55 0.15;
                0.95 0.65 0.20;
                1.00 0.75 0.30];

% Advanced mineral (red-orange for t3)
cmap_adv    = [0.75 0.15 0.05;
               0.85 0.25 0.08;
               0.92 0.38 0.10;
               1.00 0.50 0.15];

%% =========================================================
%  PANEL DIMENSIONS AND POSITIONS
%% =========================================================

% Three geological panels (a)(b)(c) - top row
panel_w  = 0.26;
panel_h  = 0.48;
panel_y  = 0.48;
gap      = 0.03;
start_x  = 0.03;

pos_a = [start_x,              panel_y, panel_w, panel_h];
pos_b = [start_x+panel_w+gap,  panel_y, panel_w, panel_h];
pos_c = [start_x+2*(panel_w+gap), panel_y, panel_w, panel_h];

% Panel (d) - bottom center
pos_d = [0.30, 0.04, 0.42, 0.40];

%% =========================================================
%  PANEL (a): Time_t1 Initial Stage
%% =========================================================

ax_a = axes('Position', pos_a);
hold on;

% Draw 3D block perspective
draw_karst_block(ax_a, 't1');

% Annotations
text(0.05, 0.95, '(a)', 'Units', 'normalized', ...
     'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k');
text(0.50, 1.03, 'Time_{t_1} Initial Stage', ...
     'Units', 'normalized', ...
     'FontSize', 12, 'FontWeight', 'bold', ...
     'HorizontalAlignment', 'center', 'Color', [0.1 0.1 0.1]);

% Feature labels
text(0.02, 0.55, 'Limestone', 'Units', 'normalized', ...
     'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0.3 0.3 0.3]);
text(0.02, 0.49, 'Bedrock', 'Units', 'normalized', ...
     'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0.3 0.3 0.3]);

% Arrow + label: Karst Caves & Fractures
annotation('textarrow', ...
    [pos_a(1)+0.03, pos_a(1)+0.08], ...
    [pos_a(2)+0.08, pos_a(2)+0.14], ...
    'String', 'Karst Caves &', ...
    'FontSize', 8, 'FontWeight', 'bold', ...
    'Color', [0.2 0.2 0.2], ...
    'HeadWidth', 8, 'HeadLength', 6);

% Arrow + label: Water/Mineral Zone
annotation('textarrow', ...
    [pos_a(1)+0.18, pos_a(1)+0.14], ...
    [pos_a(2)+0.06, pos_a(2)+0.12], ...
    'String', 'Water /', ...
    'FontSize', 8, 'FontWeight', 'bold', ...
    'Color', [0.1 0.25 0.75], ...
    'HeadWidth', 8, 'HeadLength', 6);

axis off;
hold off;

%% =========================================================
%  PANEL (b): Time_t2 Migration
%% =========================================================

ax_b = axes('Position', pos_b);
hold on;

draw_karst_block(ax_b, 't2');

text(0.05, 0.95, '(b)', 'Units', 'normalized', ...
     'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k');
text(0.50, 1.03, 'Time_{t_2} Migration', ...
     'Units', 'normalized', ...
     'FontSize', 12, 'FontWeight', 'bold', ...
     'HorizontalAlignment', 'center', 'Color', [0.1 0.1 0.1]);

% Arrow + label: Mineral Flow
annotation('textarrow', ...
    [pos_b(1)+0.19, pos_b(1)+0.14], ...
    [pos_b(2)+0.32, pos_b(2)+0.26], ...
    'String', 'Mineral Flow', ...
    'FontSize', 8, 'FontWeight', 'bold', ...
    'Color', [0.85 0.45 0.10], ...
    'HeadWidth', 8, 'HeadLength', 6);

% Arrow + label: Fluid/Mineral Migration
annotation('textarrow', ...
    [pos_b(1)+0.16, pos_b(1)+0.12], ...
    [pos_b(2)+0.08, pos_b(2)+0.14], ...
    'String', 'Fluid / Mineral', ...
    'FontSize', 8, 'FontWeight', 'bold', ...
    'Color', [0.10 0.25 0.75], ...
    'HeadWidth', 8, 'HeadLength', 6);

axis off;
hold off;

%% =========================================================
%  PANEL (c): Time_t3 Advanced Migration
%% =========================================================

ax_c = axes('Position', pos_c);
hold on;

draw_karst_block(ax_c, 't3');

text(0.05, 0.95, '(c)', 'Units', 'normalized', ...
     'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k');
text(0.50, 1.03, 'Time_{t_3} Advance Migration', ...
     'Units', 'normalized', ...
     'FontSize', 12, 'FontWeight', 'bold', ...
     'HorizontalAlignment', 'center', 'Color', [0.1 0.1 0.1]);

% Arrow + label: Expanded Mineral Zone
annotation('textarrow', ...
    [pos_c(1)+0.22, pos_c(1)+0.16], ...
    [pos_c(2)+0.10, pos_c(2)+0.16], ...
    'String', 'Expanded', ...
    'FontSize', 8, 'FontWeight', 'bold', ...
    'Color', [0.75 0.15 0.05], ...
    'HeadWidth', 8, 'HeadLength', 6);

axis off;
hold off;

%% =========================================================
%  TIME LAPSE SEQUENCE ARROW (below panels a-c)
%% =========================================================

annotation('arrow', [0.03 0.88], [0.465 0.465], ...
    'Color', [0.2 0.2 0.2], 'LineWidth', 2.0, ...
    'HeadWidth', 14, 'HeadLength', 10);
annotation('textbox', [0.35 0.44 0.20 0.03], ...
    'String', 'Time Lapse Sequence', ...
    'FontSize', 10, 'FontWeight', 'bold', ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', ...
    'Color', [0.15 0.15 0.15]);

%% =========================================================
%  INTER-PANEL ARROWS (a->b, b->c)
%% =========================================================

annotation('arrow', ...
    [pos_a(1)+panel_w+0.003, pos_b(1)-0.003], ...
    [panel_y+panel_h*0.55, panel_y+panel_h*0.55], ...
    'Color', [0.3 0.4 0.7], 'LineWidth', 2.5, ...
    'HeadWidth', 12, 'HeadLength', 8);

annotation('arrow', ...
    [pos_b(1)+panel_w+0.003, pos_c(1)-0.003], ...
    [panel_y+panel_h*0.55, panel_y+panel_h*0.55], ...
    'Color', [0.3 0.4 0.7], 'LineWidth', 2.5, ...
    'HeadWidth', 12, 'HeadLength', 8);

%% =========================================================
%  PANEL (d): Physical Properties of GPR Modeling
%% =========================================================

ax_d = axes('Position', pos_d);
hold on;

% Dark background panel
fill([0 1 1 0], [0 0 1 1], [0.08 0.08 0.10], ...
     'EdgeColor', [0.4 0.4 0.4], 'LineWidth', 1.5);

% Panel label
text(0.05, 0.95, '(d)', 'Units', 'normalized', ...
     'FontSize', 13, 'FontWeight', 'bold', 'Color', 'w');

% Vertical axis label: Physical Properties of Modeling
text(-0.08, 0.50, 'Physical Properties of Modeling', ...
     'Units', 'normalized', ...
     'FontSize', 10, 'FontWeight', 'bold', ...
     'Color', [0.7 0.7 0.7], ...
     'Rotation', 90, ...
     'HorizontalAlignment', 'center');

% Property labels on right side
props     = {'Permittivity', 'Conductivity', 'Frequency'};
prop_y    = [0.78, 0.50, 0.22];
prop_colors = {[0.95 0.75 0.20], [0.30 0.75 0.55], [0.75 0.45 0.85]};

for k = 1:3
    text(0.62, prop_y(k), props{k}, ...
         'Units', 'normalized', ...
         'FontSize', 11, 'FontWeight', 'bold', ...
         'Color', prop_colors{k}, ...
         'HorizontalAlignment', 'left');

    % Horizontal separator lines
    if k < 3
        y_line = (prop_y(k) + prop_y(k+1)) / 2;
        plot([0.05 0.95], [y_line y_line], '--', ...
             'Color', [0.3 0.3 0.3], 'LineWidth', 0.8);
    end
end

% Draw GPR antenna + radiation pattern (bottom left of panel d)
draw_gpr_antenna(ax_d, 0.28, 0.30, 0.18);

% Permittivity visualization (top section)
draw_property_viz(ax_d, 'permittivity', 0.05, 0.65, 0.50, 0.28);

% Conductivity visualization (middle section)
draw_property_viz(ax_d, 'conductivity', 0.05, 0.37, 0.50, 0.22);

% Frequency visualization (bottom section)
draw_property_viz(ax_d, 'frequency', 0.05, 0.10, 0.50, 0.22);

axis off;
xlim([0 1]);
ylim([0 1]);
hold off;

%% =========================================================
%  GLOBAL TITLE
%% =========================================================

annotation('textbox', [0.15 0.95 0.70 0.04], ...
    'String', 'Karst Time-Lapse GPR Conceptual Framework', ...
    'FontSize', 14, 'FontWeight', 'bold', ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', ...
    'Color', [0.1 0.1 0.1]);

%% =========================================================
%  SAVE FIGURE
%% =========================================================

exportgraphics(fig, 'Figure1_Karst_Conceptual_Framework.png', ...
               'Resolution', 300, 'BackgroundColor', 'white');
fprintf('Figure 1 saved successfully.\n');

%% =========================================================
%%  LOCAL FUNCTIONS
%% =========================================================

function draw_karst_block(ax, epoch)
%DRAW_KARST_BLOCK Render 3D perspective karst block diagram

    axes(ax);
    hold on;
    xlim([0 1]); ylim([0 1]);

    % --- 3D Block perspective coordinates ---
    % Front face visible, top face visible, right face visible
    % Using simple 2D isometric projection

    % Block outline (front face)
    bx = [0.10, 0.90, 0.90, 0.10, 0.10];
    by = [0.15, 0.15, 0.82, 0.82, 0.15];

    % Top face offset
    tx = 0.07; ty = 0.10;

    % Right face
    rx = [0.90, 0.90+tx, 0.90+tx, 0.90];
    ry = [0.82, 0.82+ty, 0.15+ty, 0.15];

    % Top face
    topx = [0.10, 0.90, 0.90+tx, 0.10+tx];
    topy = [0.82, 0.82, 0.82+ty, 0.82+ty];

    %% --- Limestone bedrock background ---
    fill(bx(1:4), by(1:4), [0.72 0.72 0.72], ...
         'EdgeColor', [0.4 0.4 0.4], 'LineWidth', 1.2);
    fill(topx, topy, [0.78 0.78 0.78], ...
         'EdgeColor', [0.4 0.4 0.4], 'LineWidth', 1.2);
    fill(rx, ry, [0.65 0.65 0.65], ...
         'EdgeColor', [0.4 0.4 0.4], 'LineWidth', 1.2);

    %% --- Rock texture (crack lines) ---
    crack_coords = {
        [0.15 0.35], [0.55 0.65];
        [0.40 0.55], [0.70 0.60];
        [0.60 0.80], [0.45 0.55];
        [0.20 0.40], [0.40 0.35];
        [0.55 0.70], [0.30 0.25];
        [0.25 0.45], [0.72 0.68];
        [0.70 0.88], [0.65 0.58];
    };
    for k = 1:size(crack_coords,1)
        plot(crack_coords{k,1}, crack_coords{k,2}, '-', ...
             'Color', [0.45 0.45 0.45], 'LineWidth', 0.8);
    end

    %% --- Karst cave void (irregular polygon) ---
    cave_x = [0.15 0.22 0.18 0.28 0.25 0.20 0.15];
    cave_y = [0.35 0.40 0.48 0.45 0.36 0.30 0.35];
    fill(cave_x, cave_y, [0.88 0.88 0.88], ...
         'EdgeColor', [0.3 0.3 0.3], 'LineWidth', 1.0);

    % Second cave
    cave2_x = [0.30 0.38 0.35 0.42 0.38 0.32 0.30];
    cave2_y = [0.42 0.47 0.53 0.50 0.43 0.38 0.42];
    fill(cave2_x, cave2_y, [0.85 0.85 0.85], ...
         'EdgeColor', [0.3 0.3 0.3], 'LineWidth', 0.8);

    %% --- Fracture network ---
    frac_x = {[0.18 0.55], [0.28 0.65], [0.38 0.72], [0.45 0.80]};
    frac_y = {[0.38 0.32], [0.45 0.38], [0.50 0.43], [0.44 0.40]};
    for k = 1:length(frac_x)
        plot(frac_x{k}, frac_y{k}, '-', ...
             'Color', [0.35 0.35 0.35], 'LineWidth', 1.0);
    end

    %% --- Epoch-specific geological features ---
    switch epoch

        case 't1'
            %% Water/Mineral Zone - initial confined
            % Water (blue) - narrow band
            water_x = [0.18 0.55 0.58 0.20 0.18];
            water_y = [0.28 0.28 0.33 0.33 0.28];
            fill(water_x, water_y, [0.15 0.40 0.85], ...
                 'FaceAlpha', 0.85, 'EdgeColor', [0.1 0.25 0.70], ...
                 'LineWidth', 0.8);

            % Mineral deposit (orange) - small blob
            theta = linspace(0, 2*pi, 40);
            min_x = 0.28 + 0.07*cos(theta);
            min_y = 0.22 + 0.05*sin(theta);
            fill(min_x, min_y, [0.88 0.50 0.12], ...
                 'FaceAlpha', 0.90, 'EdgeColor', [0.70 0.35 0.05], ...
                 'LineWidth', 0.8);

            % Small secondary mineral blob
            min2_x = 0.42 + 0.04*cos(theta);
            min2_y = 0.20 + 0.03*sin(theta);
            fill(min2_x, min2_y, [0.85 0.48 0.10], ...
                 'FaceAlpha', 0.85, 'EdgeColor', [0.70 0.35 0.05], ...
                 'LineWidth', 0.6);

            % Arrow indicators
            plot([0.35 0.30], [0.15 0.21], 'w-', 'LineWidth', 1.5);
            plot(0.30, 0.21, 'w>', 'MarkerSize', 5, ...
                 'MarkerFaceColor', 'w');
            plot([0.45 0.40], [0.15 0.22], 'w-', 'LineWidth', 1.5);
            plot(0.40, 0.22, 'w>', 'MarkerSize', 5, ...
                 'MarkerFaceColor', 'w');

        case 't2'
            %% Water expanded + active migration
            % Water (blue) - wider band
            water_x = [0.15 0.72 0.75 0.18 0.15];
            water_y = [0.27 0.27 0.33 0.33 0.27];
            fill(water_x, water_y, [0.12 0.35 0.82], ...
                 'FaceAlpha', 0.88, 'EdgeColor', [0.08 0.20 0.68], ...
                 'LineWidth', 1.0);

            % Mineral flow (orange elongated)
            theta = linspace(0, 2*pi, 60);
            min_x = 0.38 + 0.18*cos(theta) + 0.02*cos(2*theta);
            min_y = 0.22 + 0.06*sin(theta) + 0.01*sin(2*theta);
            fill(min_x, min_y, [0.90 0.52 0.12], ...
                 'FaceAlpha', 0.92, 'EdgeColor', [0.72 0.35 0.05], ...
                 'LineWidth', 1.0);

            % Migration front indicator
            min2_x = 0.60 + 0.06*cos(theta);
            min2_y = 0.22 + 0.04*sin(theta);
            fill(min2_x, min2_y, [0.88 0.48 0.10], ...
                 'FaceAlpha', 0.80, 'EdgeColor', [0.70 0.32 0.05], ...
                 'LineWidth', 0.8);

            % Flow arrows
            for xa = [0.30 0.45 0.58]
                annotation_local_arrow(xa, 0.22, xa+0.08, 0.22, ...
                    [0.95 0.60 0.15]);
            end

            % White arrows
            plot([0.35 0.30], [0.14 0.20], 'w-', 'LineWidth', 1.5);
            plot(0.30, 0.20, 'w>', 'MarkerSize', 5, ...
                 'MarkerFaceColor', 'w');
            plot([0.55 0.50], [0.14 0.20], 'w-', 'LineWidth', 1.5);
            plot(0.50, 0.20, 'w>', 'MarkerSize', 5, ...
                 'MarkerFaceColor', 'w');

        case 't3'
            %% Advanced migration - expanded zones
            % Water (blue) - full width
            water_x = [0.12 0.85 0.88 0.15 0.12];
            water_y = [0.26 0.26 0.33 0.33 0.26];
            fill(water_x, water_y, [0.10 0.30 0.80], ...
                 'FaceAlpha', 0.90, 'EdgeColor', [0.06 0.18 0.65], ...
                 'LineWidth', 1.0);

            % Main expanded mineral zone (red-orange large blob)
            theta = linspace(0, 2*pi, 80);
            min_x = 0.50 + 0.30*cos(theta) + ...
                    0.04*cos(2*theta) + 0.02*cos(3*theta);
            min_y = 0.22 + 0.08*sin(theta) + 0.02*sin(2*theta);
            fill(min_x, min_y, [0.88 0.35 0.08], ...
                 'FaceAlpha', 0.92, 'EdgeColor', [0.70 0.20 0.03], ...
                 'LineWidth', 1.2);

            % Inner hot core
            core_x = 0.52 + 0.18*cos(theta);
            core_y = 0.22 + 0.05*sin(theta);
            fill(core_x, core_y, [0.98 0.55 0.15], ...
                 'FaceAlpha', 0.85, 'EdgeColor', 'none');

            % Secondary satellite blob
            sat_x = 0.22 + 0.07*cos(theta);
            sat_y = 0.22 + 0.04*sin(theta);
            fill(sat_x, sat_y, [0.85 0.40 0.10], ...
                 'FaceAlpha', 0.80, 'EdgeColor', [0.65 0.25 0.05], ...
                 'LineWidth', 0.8);

            % Expansion arrows
            for angle = [0, 45, -45, 135, -135]
                rad = angle * pi/180;
                x1 = 0.50 + 0.22*cos(rad);
                y1 = 0.22 + 0.07*sin(rad);
                x2 = 0.50 + 0.32*cos(rad);
                y2 = 0.22 + 0.10*sin(rad);
                annotation_local_arrow(x1, y1, x2, y2, [0.95 0.55 0.15]);
            end

            % White arrows
            plot([0.68 0.75], [0.14 0.18], 'w-', 'LineWidth', 1.8);
            plot(0.75, 0.18, 'w>', 'MarkerSize', 6, ...
                 'MarkerFaceColor', 'w');
    end

    %% --- Block border ---
    plot(bx, by, 'k-', 'LineWidth', 1.5);
    plot(topx([1:end,1]), topy([1:end,1]), 'k-', 'LineWidth', 1.5);
    plot(rx, ry, 'k-', 'LineWidth', 1.5);
    % Vertical edges connecting top to front
    plot([topx(1) bx(1)], [topy(1) by(4)], 'k-', 'LineWidth', 1.2);
    plot([topx(4) topx(4)], [topy(4) topy(4)], 'k-', 'LineWidth', 1.2);

    xlim([0 1]); ylim([0 1]);
    axis off;
    hold off;
end

%% ---------------------------------------------------------

function draw_gpr_antenna(ax, cx, cy, scale)
%DRAW_GPR_ANTENNA Draw GPR antenna with radiation arcs

    hold on;

    % Antenna body
    ant_w = scale * 0.4;
    ant_h = scale * 0.15;
    fill([cx-ant_w/2, cx+ant_w/2, cx+ant_w/2, cx-ant_w/2], ...
         [cy, cy, cy+ant_h, cy+ant_h], ...
         [0.25 0.25 0.25], 'EdgeColor', [0.5 0.5 0.5], 'LineWidth', 1.0);

    % Antenna transmit/receive elements
    plot([cx-ant_w*0.25, cx-ant_w*0.25], [cy, cy+ant_h*1.5], ...
         'k-', 'LineWidth', 2.0);
    plot([cx+ant_w*0.25, cx+ant_w*0.25], [cy, cy+ant_h*1.5], ...
         'k-', 'LineWidth', 2.0);

    % Radiation arcs (below antenna)
    arc_colors = {[0.85 0.15 0.10], [0.90 0.30 0.15], ...
                  [0.92 0.45 0.20], [0.88 0.60 0.25]};
    for r = 1:4
        r_scale = r * scale * 0.22;
        theta   = linspace(pi, 2*pi, 80);
        arc_x   = cx + r_scale * cos(theta);
        arc_y   = cy + r_scale * sin(theta) * 0.5;
        valid   = arc_y <= cy;
        plot(ax, arc_x(valid), arc_y(valid), '-', ...
             'Color', arc_colors{r}, 'LineWidth', 1.5 - r*0.2);
    end

    hold off;
end

%% ---------------------------------------------------------

function draw_property_viz(ax, prop_type, x0, y0, w, h)
%DRAW_PROPERTY_VIZ Draw property visualization strip

    hold on;
    n = 50;

    switch prop_type

        case 'permittivity'
            % Gradient from low (blue) to high (red)
            for k = 1:n
                frac = (k-1)/(n-1);
                c = [frac, 0.2*(1-frac), 1-frac];
                c = max(0, min(1, c));
                fill(ax, [x0+w*frac/n*n, x0+w*(frac+1/n)*n, ...
                      x0+w*(frac+1/n)*n, x0+w*frac/n*n] * 0.02 + x0 + w*(k-1)/n, ...
                     [y0, y0, y0+h, y0+h], c, 'EdgeColor', 'none');
            end
            % Overlay undulating permittivity layers
            x_line = linspace(x0, x0+w, 100);
            for layer_y = [y0+h*0.3, y0+h*0.6]
                undulation = layer_y + h*0.05*sin(2*pi*(x_line-x0)/w*3);
                plot(ax, x_line, undulation, 'w-', 'LineWidth', 1.2);
            end

        case 'conductivity'
            % Conductivity gradient - green to yellow
            for k = 1:n
                frac = (k-1)/(n-1);
                c = [frac*0.8, 0.5+frac*0.4, 0.2];
                c = max(0, min(1, c));
                xk = x0 + w*(k-1)/n;
                fill(ax, [xk, xk+w/n, xk+w/n, xk], ...
                     [y0, y0, y0+h, y0+h], c, 'EdgeColor', 'none');
            end
            % Conductivity contour lines
            x_line = linspace(x0, x0+w, 100);
            for level = 0.2:0.3:0.8
                cy_line = y0 + h*level + h*0.03*sin(4*pi*(x_line-x0)/w);
                plot(ax, x_line, cy_line, 'k--', 'LineWidth', 0.8);
            end

        case 'frequency'
            % Frequency waveform visualization
            fill(ax, [x0, x0+w, x0+w, x0], [y0, y0, y0+h, y0+h], ...
                 [0.12 0.12 0.18], 'EdgeColor', 'none');
            t_freq = linspace(0, 1, 200);
            % Multi-frequency components
            freqs     = [3, 6, 12];
            freq_cols = {[0.90 0.30 0.20], [0.95 0.55 0.20], ...
                         [0.85 0.75 0.25]};
            for f = 1:length(freqs)
                amp  = h * 0.28 / f;
                wave = y0 + h/2 + amp * sin(2*pi*freqs(f)*t_freq);
                plot(ax, x0 + w*t_freq, wave, '-', ...
                     'Color', freq_cols{f}, 'LineWidth', 1.2);
            end
    end

    % Property box border
    plot(ax, [x0 x0+w x0+w x0 x0], [y0 y0 y0+h y0+h y0], ...
         '-', 'Color', [0.4 0.4 0.4], 'LineWidth', 0.8);

    hold off;
end

%% ---------------------------------------------------------

function annotation_local_arrow(x1, y1, x2, y2, color)
%ANNOTATION_LOCAL_ARROW Draw local arrow within axes
    dp = 0.01;
    dx = x2 - x1;
    dy = y2 - y1;
    quiver(x1, y1, dx-dp, dy-dp, 0, ...
           'Color', color, 'LineWidth', 1.2, ...
           'MaxHeadSize', 0.5);
end
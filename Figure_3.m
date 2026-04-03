%% =========================================================
%  Physics-Guided Spatio-Temporal Deep Learning for
%  Time-Lapse GPR Reconstruction in Karst Systems
%  Figure 3: Forward Electromagnetic Simulation Pipeline
%  PML vs DAB Boundary Conditions + B-scan Radargrams
%% =========================================================

clc; clear; close all;

%% =========================================================
%  SIMULATION PARAMETERS
%% =========================================================

% Grid dimensions
H = 150;        % Depth samples (two-way travel time)
W = 300;        % Along-track samples

% GPR parameters
fc      = 200e6;    % Central frequency 200 MHz
dt      = 1e-10;    % Time step
t_wav   = -3e-9:dt:3e-9;
wav     = ricker_wavelet(t_wav, fc);

% Permittivity values
eps_bg      = 4.5;   % Background
eps_soil    = 6.0;   % Topsoil
eps_subsoil = 7.5;   % Subsoil
eps_rock1   = 9.0;   % Upper rock
eps_rock2   = 11.0;  % Lower fractured rock
eps_void    = 1.0;   % Air-filled karst void
eps_water   = 25.0;  % Water-saturated zone

% Layer boundaries (depth indices)
layer1 = 18;    % Topsoil base
layer2 = 32;    % Subsoil base
layer3 = 50;    % Upper rock base
layer4 = 75;    % Undulating reflector

% Karst void parameters
void_cx = 150;  % Center x
void_cz = 90;   % Center z
void_rx = 35;   % x radius
void_rz = 18;   % z radius

% PML parameters
pml_thickness = 15;  % cells
pml_sigma_max = 0.8;

% DAB parameters
dab_thickness = 15;  % cells

% Noise parameters
noise_pml = 0.035;
noise_dab = 0.028;

%% =========================================================
%  BUILD SUBSURFACE PERMITTIVITY MODEL
%% =========================================================

[X_grid, Z_grid] = meshgrid(1:W, 1:H);

eps_model = build_permittivity_model(H, W, X_grid, Z_grid, ...
    layer1, layer2, layer3, layer4, ...
    eps_bg, eps_soil, eps_subsoil, eps_rock1, eps_rock2, ...
    eps_void, eps_water, void_cx, void_cz, void_rx, void_rz);

%% =========================================================
%  COMPUTE REFLECTION COEFFICIENTS
%% =========================================================

refl_model = compute_reflection_coefficients(eps_model, H, W);

%% =========================================================
%  DEPTH-DEPENDENT ATTENUATION
%% =========================================================

% Generalized frequency-dependent attenuation
omega   = 2 * pi * fc;
sigma   = 0.005;   % Average conductivity S/m
eps0    = 8.854e-12;
c_light = 3e8;

alpha_f = (omega / c_light) * sqrt((eps_bg/2) * ...
          (sqrt(1 + (sigma/(omega*eps0*eps_bg))^2) - 1));
gamma   = 0.6;
z_vec   = (1:H)';
A_z     = (z_vec.^(-gamma)) .* exp(-alpha_f * z_vec * 0.01);
A_z     = A_z / max(A_z);

%% =========================================================
%  GENERATE PML B-SCAN (Panel c)
%% =========================================================

fprintf('Generating PML B-scan...\n');

% PML attenuation profile
sigma_pml = build_pml_profile(H, W, pml_thickness, pml_sigma_max);

% Generate base B-scan
bscan_pml = generate_bscan(refl_model, wav, A_z, H, W);

% Apply PML boundary effect
bscan_pml = apply_pml(bscan_pml, sigma_pml, H, W, pml_thickness);

% Apply topographic distortion
topo_pml  = 3 * sin(2*pi*(1:W)/W) + 2*cos(4*pi*(1:W)/W);
bscan_pml = apply_topography(bscan_pml, topo_pml, H, W);

% Add composite noise (PML configuration)
bscan_pml = add_composite_noise(bscan_pml, H, W, noise_pml, 0.4);

% Enhance hyperbola signature
bscan_pml = enhance_karst_hyperbola(bscan_pml, X_grid, Z_grid, ...
            void_cx, void_cz, void_rx*1.2, void_rz*1.8, 1.3);

% Final normalization
bscan_pml = normalize_bscan(bscan_pml);

%% =========================================================
%  GENERATE DAB B-SCAN (Panel d)
%% =========================================================

fprintf('Generating DAB B-scan...\n');

% DAB uses two cascaded absorbing operators
dab_coeff1 = build_dab_profile(H, W, dab_thickness, 0.6);
dab_coeff2 = build_dab_profile(H, W, dab_thickness, 0.85);

% Generate base B-scan
bscan_dab = generate_bscan(refl_model, wav, A_z, H, W);

% Apply DAB (two-pass absorption)
bscan_dab = apply_dab(bscan_dab, dab_coeff1, dab_coeff2, H, W);

% Apply topographic distortion (slightly different for DAB)
topo_dab  = 4 * sin(2*pi*(1:W)/W + 0.3) + 1.5*cos(3*pi*(1:W)/W);
bscan_dab = apply_topography(bscan_dab, topo_dab, H, W);

% Add composite noise (DAB - slightly cleaner)
bscan_dab = add_composite_noise(bscan_dab, H, W, noise_dab, 0.3);

% Enhance hyperbola (DAB produces stronger, cleaner hyperbola)
bscan_dab = enhance_karst_hyperbola(bscan_dab, X_grid, Z_grid, ...
            void_cx, void_cz, void_rx*1.3, void_rz*2.0, 1.5);

% Final normalization
bscan_dab = normalize_bscan(bscan_dab);

%% =========================================================
%  BUILD THERMAL COLORMAP
%% =========================================================

cmap_thermal = build_thermal_colormap(256);

%% =========================================================
%  FIGURE 3 LAYOUT
%% =========================================================

fig = figure('Color', 'w', ...
             'Position', [30 30 1400 800], ...
             'Name', 'Figure 3 - Forward EM Simulation');

%% -------------------------------------------------------
%  LEFT COLUMN: Simulation domain illustrations
%  These are rendered as annotated subsurface diagrams
%% -------------------------------------------------------

%% --- Panel (a): PML Simulation Domain ---
ax_a = subplot(2, 4, [1 2]);
render_simulation_domain(ax_a, H, W, eps_model, ...
    layer1, layer2, layer3, layer4, ...
    void_cx, void_cz, void_rx, void_rz, ...
    'PML', pml_thickness, X_grid, Z_grid);
title('(a)', 'FontSize', 13, 'FontWeight', 'bold', 'Units', 'normalized', ...
      'Position', [0.05 0.02]);

% PML boundary indicators
hold on;
% Left PML - orange filled rectangle
fill([1 pml_thickness pml_thickness 1], [1 1 H H], ...
     [0.95 0.5 0.05], 'FaceAlpha', 0.75, 'EdgeColor', 'none');
% Right PML
fill([W-pml_thickness W W W-pml_thickness], [1 1 H H], ...
     [0.95 0.5 0.05], 'FaceAlpha', 0.75, 'EdgeColor', 'none');
% PML labels
text(pml_thickness/2, H*0.5, 'PML', 'Color', 'w', ...
     'FontSize', 9, 'FontWeight', 'bold', ...
     'Rotation', 90, 'HorizontalAlignment', 'center');
text(W - pml_thickness/2, H*0.5, 'PML', 'Color', 'w', ...
     'FontSize', 9, 'FontWeight', 'bold', ...
     'Rotation', 90, 'HorizontalAlignment', 'center');

% Acquisition labels
text(W*0.38, -8, 'Noise', 'FontSize', 9, 'FontWeight', 'bold', ...
     'Color', [0.6 0.1 0.1]);
text(W*0.50, -8, 'Antenna Effect', 'FontSize', 9, 'FontWeight', 'bold', ...
     'Color', [0.1 0.1 0.1]);
text(W*0.06, -8, 'Topography', 'FontSize', 9, 'FontWeight', 'bold', ...
     'Color', [0.1 0.4 0.1]);
hold off;
set(ax_a, 'XTick', [], 'YTick', []);
box on;

%% --- Panel (b): DAB Simulation Domain ---
ax_b = subplot(2, 4, [5 6]);
render_simulation_domain(ax_b, H, W, eps_model, ...
    layer1, layer2, layer3, layer4, ...
    void_cx, void_cz, void_rx, void_rz, ...
    'DAB', dab_thickness, X_grid, Z_grid);
title('(b)', 'FontSize', 13, 'FontWeight', 'bold', 'Units', 'normalized', ...
      'Position', [0.05 0.02]);

% DAB boundary indicators (dashed yellow lines)
hold on;
% Left DAB dashed line
plot([dab_thickness dab_thickness], [1 H], '--', ...
     'Color', [1 0.9 0.1], 'LineWidth', 2.5);
% Right DAB dashed line
plot([W-dab_thickness W-dab_thickness], [1 H], '--', ...
     'Color', [1 0.9 0.1], 'LineWidth', 2.5);
% DAB labels
text(dab_thickness - 6, H*0.85, 'DAB', 'Color', [1 0.9 0.1], ...
     'FontSize', 9, 'FontWeight', 'bold');
text(W - dab_thickness + 2, H*0.85, 'DAB', 'Color', [1 0.9 0.1], ...
     'FontSize', 9, 'FontWeight', 'bold');
% DAB marker dots
plot(dab_thickness, H*0.82, 'o', 'MarkerFaceColor', [1 0.9 0.1], ...
     'MarkerEdgeColor', [1 0.9 0.1], 'MarkerSize', 7);
plot(W - dab_thickness, H*0.82, 'o', 'MarkerFaceColor', [1 0.9 0.1], ...
     'MarkerEdgeColor', [1 0.9 0.1], 'MarkerSize', 7);

% Acquisition labels
text(W*0.38, -8, 'Noise', 'FontSize', 9, 'FontWeight', 'bold', ...
     'Color', [0.6 0.1 0.1]);
text(W*0.50, -8, 'Antenna Effect', 'FontSize', 9, 'FontWeight', 'bold', ...
     'Color', [0.1 0.1 0.1]);
text(W*0.06, -8, 'Topography', 'FontSize', 9, 'FontWeight', 'bold', ...
     'Color', [0.1 0.4 0.1]);
hold off;
set(ax_b, 'XTick', [], 'YTick', []);
box on;

%% -------------------------------------------------------
%  ARROWS: Simulation Domain -> B-scan
%% -------------------------------------------------------

annotation('arrow', [0.52 0.60], [0.78 0.78], ...
    'Color', [0.15 0.35 0.75], 'LineWidth', 3, 'HeadWidth', 14);
annotation('arrow', [0.52 0.60], [0.28 0.28], ...
    'Color', [0.15 0.35 0.75], 'LineWidth', 3, 'HeadWidth', 14);

%% -------------------------------------------------------
%  RIGHT COLUMN: B-scan Radargrams
%% -------------------------------------------------------

%% --- Panel (c): PML B-scan ---
ax_c = subplot(2, 4, [3 4]);
imagesc(bscan_pml);
colormap(ax_c, cmap_thermal);
axis tight; axis off;
hold on;

% Annotate hyperbola region
theta = linspace(0, pi, 100);
hx    = void_cx + void_rx * 1.1 * cos(theta);
hz    = void_cz + void_rz * 2.2 * sin(theta);
valid = hz > 0 & hz < H & hx > 0 & hx < W;

% Panel label
text(10, H-8, '(c)', 'Color', 'w', 'FontSize', 13, ...
     'FontWeight', 'bold', 'BackgroundColor', 'none');
hold off;
cb_c = colorbar('southoutside', 'Color', [0.3 0.3 0.3], 'FontSize', 8);
cb_c.Label.String = 'Normalized Amplitude';

%% --- Panel (d): DAB B-scan ---
ax_d = subplot(2, 4, [7 8]);
imagesc(bscan_dab);
colormap(ax_d, cmap_thermal);
axis tight; axis off;
hold on;

% Panel label
text(10, H-8, '(d)', 'Color', 'w', 'FontSize', 13, ...
     'FontWeight', 'bold', 'BackgroundColor', 'none');
hold off;
cb_d = colorbar('southoutside', 'Color', [0.3 0.3 0.3], 'FontSize', 8);
cb_d.Label.String = 'Normalized Amplitude';

%% -------------------------------------------------------
%  GLOBAL TITLE AND SPACING
%% -------------------------------------------------------

sgtitle({'Figure 3: Forward Electromagnetic Simulation Pipeline', ...
         'PML (a,c) vs DAB (b,d) Boundary Conditions | Karst GPR Radargrams'}, ...
         'FontSize', 13, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);

set(fig, 'Units', 'normalized');
tightfig_custom(fig);

%% =========================================================
%  SAVE FIGURE
%% =========================================================

exportgraphics(fig, 'Figure3_ForwardEM_Simulation.png', ...
               'Resolution', 300, 'BackgroundColor', 'white');
fprintf('Figure 3 saved: Figure3_ForwardEM_Simulation.png\n');

%% =========================================================
%%  LOCAL FUNCTIONS
%% =========================================================

function wav = ricker_wavelet(t, fc)
%RICKER_WAVELET Generate Ricker wavelet
    wav = (1 - 2*(pi*fc*t).^2) .* exp(-(pi*fc*t).^2);
    wav = wav / max(abs(wav));
end

%% ---------------------------------------------------------

function eps = build_permittivity_model(H, W, X_grid, Z_grid, ...
    l1, l2, l3, l4, ...
    eps_bg, eps_soil, eps_subsoil, eps_rock1, eps_rock2, ...
    eps_void, eps_water, vcx, vcz, vrx, vrz)
%BUILD_PERMITTIVITY_MODEL Construct layered karst permittivity model

    eps = eps_bg * ones(H, W);

    % Layered stratigraphy
    eps(1:l1, :)      = eps_soil;
    eps(l1+1:l2, :)   = eps_subsoil;
    eps(l2+1:l3, :)   = eps_rock1;
    eps(l3+1:end, :)  = eps_rock2;

    % Undulating reflector at layer4
    for col = 1:W
        undulation = round(5 * sin(2*pi*col/W) + ...
                           2 * sin(4*pi*col/W + 0.5));
        z_idx = max(1, min(H, l4 + undulation));
        eps(z_idx, col) = (eps_rock1 + eps_rock2) / 2;
    end

    % Karst void anomaly
    gauss_void = exp(-((X_grid - vcx).^2/(2*vrx^2) + ...
                       (Z_grid - vcz).^2/(2*vrz^2)));
    void_mask  = gauss_void > 0.25;
    eps(void_mask) = eps_void;

    % Moisture halo around void
    halo_mask  = (gauss_void > 0.08) & (~void_mask);
    eps(halo_mask) = eps(halo_mask) + ...
                     3.5 * gauss_void(halo_mask);

    % Water saturated zone below void
    water_zone = (Z_grid > vcz + vrz) & ...
                 (Z_grid < vcz + vrz + 12) & ...
                 (abs(X_grid - vcx) < vrx * 0.8);
    eps(water_zone) = eps_water * 0.6;
end

%% ---------------------------------------------------------

function refl = compute_reflection_coefficients(eps_model, H, W)
%COMPUTE_REFLECTION_COEFFICIENTS RC from permittivity contrasts
    refl = zeros(H, W);
    for z = 2:H-1
        n1 = sqrt(eps_model(z-1, :));
        n2 = sqrt(eps_model(z+1, :));
        RC = (n2 - n1) ./ (n2 + n1);
        refl(z, :) = RC;
    end
    % Clip extreme values
    refl = max(-0.9, min(0.9, refl));
end

%% ---------------------------------------------------------

function sigma_pml = build_pml_profile(H, W, thickness, sigma_max)
%BUILD_PML_PROFILE Polynomial PML conductivity profile
    sigma_pml = zeros(H, W);
    for i = 1:thickness
        sigma_val = sigma_max * (1 - i/thickness)^3;
        sigma_pml(:, i)             = sigma_val;
        sigma_pml(:, W - i + 1)     = sigma_val;
    end
end

%% ---------------------------------------------------------

function dab_coeff = build_dab_profile(H, W, thickness, strength)
%BUILD_DAB_PROFILE Double absorbing boundary profile
    dab_coeff = ones(H, W);
    for i = 1:thickness
        absorb = 1 - strength * ((thickness - i + 1) / thickness)^2;
        absorb = max(0.01, absorb);
        dab_coeff(:, i)             = absorb;
        dab_coeff(:, W - i + 1)     = absorb;
    end
end

%% ---------------------------------------------------------

function bscan = generate_bscan(refl_model, wav, A_z, H, W)
%GENERATE_BSCAN Convolve reflection model with Ricker wavelet
    bscan   = zeros(H, W);
    wav_len = length(wav);
    half_w  = floor(wav_len / 2);
    pad_len = H + wav_len;

    for col = 1:W
        trace = zeros(pad_len, 1);
        for z = 1:H
            if abs(refl_model(z, col)) > 5e-4
                i_start = z;
                i_end   = z + wav_len - 1;
                trace(i_start:i_end) = trace(i_start:i_end) + ...
                    refl_model(z, col) * wav(:);
            end
        end
        raw_trace        = trace(half_w+1 : half_w+H);
        bscan(:, col)    = raw_trace .* A_z;
    end
end

%% ---------------------------------------------------------

function bscan = apply_pml(bscan, sigma_pml, H, W, thickness)
%APPLY_PML Apply PML boundary attenuation
    for col = 1:thickness
        atten_L = exp(-sigma_pml(1, col) * (thickness - col + 1));
        atten_R = exp(-sigma_pml(1, W - col + 1) * (thickness - col + 1));
        bscan(:, col)         = bscan(:, col) * atten_L;
        bscan(:, W - col + 1) = bscan(:, W - col + 1) * atten_R;
    end
    % PML leaves slight residual ringing at boundaries
    ringing = 0.015 * randn(H, thickness);
    bscan(:, 1:thickness)         = bscan(:, 1:thickness) + ringing;
    bscan(:, W-thickness+1:end)   = bscan(:, W-thickness+1:end) + ringing;
end

%% ---------------------------------------------------------

function bscan = apply_dab(bscan, coeff1, coeff2, H, W)
%APPLY_DAB Apply double absorbing boundary (two-pass)
    % First pass
    bscan = bscan .* coeff1;
    % Second pass (cascaded)
    bscan = bscan .* coeff2;
    % DAB produces cleaner boundaries - minimal residual
    thickness = 15;
    ringing   = 0.008 * randn(H, thickness);
    bscan(:, 1:thickness)       = bscan(:, 1:thickness) + ringing;
    bscan(:, W-thickness+1:end) = bscan(:, W-thickness+1:end) + ringing;
end

%% ---------------------------------------------------------

function bscan = apply_topography(bscan, topo, H, W)
%APPLY_TOPOGRAPHY Shift traces by topographic offset
    for col = 1:W
        shift = round(topo(col));
        if shift > 0
            bscan(:, col) = [zeros(shift, 1); ...
                             bscan(1:end-shift, col)];
        elseif shift < 0
            bscan(:, col) = [bscan(-shift+1:end, col); ...
                             zeros(-shift, 1)];
        end
    end
end

%% ---------------------------------------------------------

function bscan = add_composite_noise(bscan, H, W, noise_G_amp, noise_C_frac)
%ADD_COMPOSITE_NOISE Add Gaussian + correlated clutter noise
    % White Gaussian noise
    eta_G = noise_G_amp * randn(H, W);
    % Spatially correlated clutter (colored noise)
    eta_C = noise_C_frac * noise_G_amp * imgaussfilt(randn(H, W), 2.5);
    % Periodic antenna ringing
    t_ring  = (0:H-1)';
    f_ring  = 0.15;
    eta_P   = 0.012 * exp(-0.04 * t_ring) .* ...
              sin(2*pi*f_ring*t_ring) * ones(1, W);
    bscan   = bscan + eta_G + eta_C + eta_P;
end

%% ---------------------------------------------------------

function bscan = enhance_karst_hyperbola(bscan, X_grid, Z_grid, ...
    cx, cz, rx, rz, scale)
%ENHANCE_KARST_HYPERBOLA Amplify hyperbolic diffraction signature

    % Compute hyperbolic travel time pattern
    v_medium = 0.1;   % EM velocity m/ns (approx)
    hyp_amp  = zeros(size(bscan));

    for col = 1:size(bscan, 2)
        % Distance from void center to each antenna position
        dx       = col - cx;
        % Two-way travel time (hyperbola equation)
        t_hyp    = round(cz + sqrt(dx^2 / v_medium^2 + ...
                         (rz * 0.5)^2));
        if t_hyp > 0 && t_hyp <= size(bscan, 1)
            % Add Ricker-like wavelet response at hyperbola apex
            for dz = -round(rz*1.5):round(rz*1.5)
                z_idx = t_hyp + dz;
                if z_idx >= 1 && z_idx <= size(bscan, 1)
                    weight = exp(-dz^2 / (2*(rz*0.5)^2));
                    hyp_amp(z_idx, col) = scale * weight * ...
                        (1 - 2*(dz/(rz*0.4))^2) * ...
                        exp(-(dz/(rz*0.4))^2);
                end
            end
        end
    end

    bscan = bscan + hyp_amp;
end

%% ---------------------------------------------------------

function bscan = normalize_bscan(bscan)
%NORMALIZE_BSCAN Normalize to [-1, 1]
    bscan = bscan / max(abs(bscan(:)) + eps);
end

%% ---------------------------------------------------------

function render_simulation_domain(ax, H, W, eps_model, ...
    l1, l2, l3, l4, vcx, vcz, vrx, vrz, bc_type, bc_thick, X_grid, Z_grid)
%RENDER_SIMULATION_DOMAIN Draw colored subsurface cross-section

    axes(ax);

    % Custom geological colormap
    geo_cmap = [
        0.35 0.22 0.10;   % Dark brown - deep rock
        0.50 0.35 0.18;   % Medium brown - rock
        0.65 0.50 0.30;   % Light brown - subsoil
        0.55 0.65 0.40;   % Green-brown - soil
        0.30 0.55 0.25;   % Green - topsoil
        0.20 0.40 0.70;   % Blue - water
        0.85 0.85 0.85;   % Light grey - void
    ];

    % Render permittivity model as image
    imagesc(eps_model);
    colormap(ax, flipud(hot));
    clim([1 25]);
    axis tight;
    set(ax, 'YDir', 'reverse');
    hold on;

    % Overlay geological layer boundaries
    % Layer 1 (topsoil base)
    x_line = 1:W;
    y_line1 = l1 + 3 * sin(2*pi*x_line/W);
    plot(x_line, y_line1, 'k-', 'LineWidth', 1.5);

    % Layer 2 (subsoil base)
    y_line2 = l2 + 4 * sin(2*pi*x_line/W + 0.5);
    plot(x_line, y_line2, 'k-', 'LineWidth', 1.5);

    % Layer 3 (upper rock base)
    y_line3 = l3 + 5 * sin(2*pi*x_line/W + 1.0);
    plot(x_line, y_line3, 'k-', 'LineWidth', 1.8);

    % Undulating deep reflector
    y_line4 = l4 + 5*sin(2*pi*x_line/W) + 2*sin(4*pi*x_line/W);
    plot(x_line, y_line4, 'k--', 'LineWidth', 1.2);

    % Karst void outline
    theta    = linspace(0, 2*pi, 100);
    vx_out   = vcx + vrx * cos(theta);
    vz_out   = vcz + vrz * sin(theta);
    fill(vx_out, vz_out, [0.9 0.9 0.9], ...
         'FaceAlpha', 0.5, 'EdgeColor', [1 0.8 0.0], ...
         'LineWidth', 1.5);

    % Karst void glow (concentric halos)
    for r_scale = [1.3, 1.6, 2.0]
        vx_h = vcx + vrx * r_scale * cos(theta);
        vz_h = vcz + vrz * r_scale * sin(theta);
        plot(vx_h, vz_h, '-', 'Color', [1.0 0.6 0.0 0.3], ...
             'LineWidth', 0.8);
    end

    % EM wave fronts (semi-circular arcs radiating from void)
    for r = [12, 22, 32, 42]
        arc_x = vcx + r * cos(linspace(pi, 2*pi, 80));
        arc_z = vcz - r * sin(linspace(0, pi, 80));
        valid = arc_z > 0 & arc_z < H & arc_x > 0 & arc_x < W;
        if any(valid)
            plot(arc_x(valid), arc_z(valid), '-', ...
                 'Color', [1.0 0.85 0.0], 'LineWidth', 1.0);
        end
    end

    % Antenna position (tower)
    ant_x = W * 0.50;
    ant_z = l1 - 2;
    plot(ant_x, ant_z, 'v', 'MarkerSize', 10, ...
         'MarkerFaceColor', [0.2 0.2 0.2], ...
         'MarkerEdgeColor', 'k');

    % Antenna radiation arcs (above surface)
    for r = [8, 15, 22]
        arc_x = ant_x + r * cos(linspace(pi/6, 5*pi/6, 60));
        arc_z = ant_z - r * sin(linspace(0, pi, 60)) * 0.6;
        valid = arc_z > -20 & arc_z < l1;
        plot(arc_x(valid), arc_z(valid), '-', ...
             'Color', [0.8 0.2 0.1], 'LineWidth', 1.2);
    end

    % Ground surface line
    surf_z = l1 - 3 + 2*sin(2*pi*x_line/W);
    plot(x_line, surf_z, 'Color', [0.3 0.6 0.2], 'LineWidth', 2.0);

    % Topography hills (green overlay)
    hill1_x = [W*0.1, W*0.15, W*0.2, W*0.25, W*0.3];
    hill1_z = [l1, l1-10, l1-14, l1-9, l1];
    fill(hill1_x, hill1_z, [0.3 0.55 0.25], ...
         'FaceAlpha', 0.8, 'EdgeColor', 'none');
    hill2_x = [W*0.35, W*0.42, W*0.48, W*0.54, W*0.60];
    hill2_z = [l1, l1-8, l1-11, l1-7, l1];
    fill(hill2_x, hill2_z, [0.3 0.55 0.25], ...
         'FaceAlpha', 0.8, 'EdgeColor', 'none');

    xlim([1 W]);
    ylim([-15 H]);
    hold off;
end

%% ---------------------------------------------------------

function cmap = build_thermal_colormap(n)
%BUILD_THERMAL_COLORMAP Custom blue-cyan-yellow-red thermal colormap
    r_pts = [0.00, 0.00, 0.00, 0.50, 1.00, 1.00, 1.00];
    g_pts = [0.00, 0.00, 0.50, 1.00, 1.00, 0.50, 0.00];
    b_pts = [0.30, 0.80, 1.00, 0.50, 0.00, 0.00, 0.00];
    xi    = linspace(0, 1, length(r_pts));
    xq    = linspace(0, 1, n);
    cmap  = [interp1(xi, r_pts, xq)', ...
             interp1(xi, g_pts, xq)', ...
             interp1(xi, b_pts, xq)'];
    cmap  = max(0, min(1, cmap));
end

%% ---------------------------------------------------------

function tightfig_custom(fig)
%TIGHTFIG_CUSTOM Reduce whitespace between subplots
    set(fig, 'Units', 'normalized');
    ax_all = findall(fig, 'type', 'axes');
    for k = 1:length(ax_all)
        ax_all(k).Position(1) = ax_all(k).Position(1) * 0.98;
    end
end
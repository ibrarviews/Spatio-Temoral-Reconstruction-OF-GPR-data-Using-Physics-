%% =========================================================
%  Physics-Guided Spatio-Temporal Deep Learning for
%  Time-Lapse GPR Reconstruction in Karst Systems
%  Figure 4: Synthetic GPR Dataset Structure
%  Input B-scans (t1, t2, t3) + Output Labels (Yd, Yabs)
%% =========================================================

clc; clear; close all;

%% =========================================================
%  PARAMETERS
%% =========================================================

% Grid dimensions
H = 128;   % Depth samples (two-way travel time)
W = 256;   % Along-track samples

% Karst anomaly parameters
void1 = struct('x', 100, 'z', 45, 'rx', 22, 'rz', 14);  % Shallow anomaly
void2 = struct('x', 160, 'z', 85, 'rx', 30, 'rz', 20);  % Deep anomaly

% Layer depths
layer1_depth = 20;   % First stratigraphic boundary
layer2_depth = 35;   % Second stratigraphic boundary

% Permittivity values
eps_air      = 1.0;
eps_soil     = 6.0;
eps_rock     = 9.0;
eps_void     = 20.0;  % Water-saturated karst void
eps_bg       = 4.5;   % Background

% Frequency
fc = 200e6;   % 200 MHz GPR antenna

%% =========================================================
%  HELPER FUNCTIONS
%% =========================================================

% Coordinate grids
[X_grid, Z_grid] = meshgrid(1:W, 1:H);

% Gaussian blob function
gauss2D = @(x0, z0, sx, sz) ...
    exp(-((X_grid - x0).^2 / (2*sx^2) + ...
          (Z_grid - z0).^2 / (2*sz^2)));

% Ricker wavelet
ricker = @(t, fc) (1 - 2*(pi*fc*t).^2) .* exp(-(pi*fc*t).^2);

%% =========================================================
%  BUILD PERMITTIVITY MODEL (Ground Truth)
%% =========================================================

eps_model = eps_bg * ones(H, W);

% Add stratigraphic layers
eps_model(1:layer1_depth, :)              = eps_soil;
eps_model(layer1_depth+1:layer2_depth, :) = eps_rock * 0.85;
eps_model(layer2_depth+1:end, :)          = eps_rock;

% Add smooth layer undulation
for col = 1:W
    undulation = round(3 * sin(2*pi*col/W));
    eps_model(layer1_depth + undulation, col) = eps_rock * 0.9;
end

% Add karst voids (permittivity anomalies)
void_mask1 = gauss2D(void1.x, void1.z, void1.rx, void1.rz);
void_mask2 = gauss2D(void2.x, void2.z, void2.rx, void2.rz);

eps_model = eps_model + (eps_void - eps_rock) * (void_mask1 > 0.15);
eps_model = eps_model + (eps_void - eps_rock) * (void_mask2 > 0.15);

%% =========================================================
%  GENERATE TIME-LAPSE B-SCAN RADARGRAMS
%% =========================================================

% Time axis for Ricker wavelet
dt     = 1e-10;
t_wav  = -2e-9 : dt : 2e-9;
wav    = ricker(t_wav, fc);

% Attenuation profile (depth-dependent)
alpha  = 0.03;
gamma  = 0.5;
z_vec  = (1:H)';
A_z    = (z_vec .^ -gamma) .* exp(-alpha * z_vec);
A_z    = A_z / max(A_z);

% Function to simulate B-scan from permittivity model
simulate_bscan = @(eps_m, noise_level, void_scale) ...
    generate_bscan(eps_m, wav, A_z, H, W, noise_level, ...
                   void_scale, X_grid, Z_grid, layer1_depth, ...
                   layer2_depth, fc);

% Generate three time-lapse epochs
% t1: baseline
bscan_t1 = simulate_bscan(eps_model, 0.04, 1.0);

% t2: moderate void growth + increased moisture
eps_t2              = eps_model;
void_mask2_grown    = gauss2D(void2.x, void2.z+3, ...
                              void2.rx*1.2, void2.rz*1.2);
eps_t2              = eps_t2 + 2.5 * (void_mask2_grown > 0.15);
bscan_t2            = simulate_bscan(eps_t2, 0.05, 1.2);

% t3: advanced void growth + significant dielectric change
eps_t3              = eps_model;
void_mask2_adv      = gauss2D(void2.x+5, void2.z+6, ...
                              void2.rx*1.5, void2.rz*1.4);
void_mask1_adv      = gauss2D(void1.x-3, void1.z+2, ...
                              void1.rx*1.1, void1.rz*1.1);
eps_t3              = eps_t3 + 4.0*(void_mask2_adv > 0.15) ...
                              + 2.0*(void_mask1_adv > 0.15);
bscan_t3            = simulate_bscan(eps_t3, 0.06, 1.4);

%% =========================================================
%  BUILD OUTPUT LABELS
%% =========================================================

% Panel (d): Differential permittivity map
Y_delta = eps_t3 - eps_model;
Y_delta(Y_delta < 0) = 0;   % Keep positive changes only

% Panel (e): Absolute permittivity map
Y_abs = eps_t3;

%% =========================================================
%  FIGURE 4 LAYOUT
%% =========================================================

fig = figure('Color', 'k', ...
             'Position', [50 50 1400 750], ...
             'Name', 'Figure 4 - Synthetic GPR Dataset');

% Custom thermal colormap for B-scans
n_colors  = 256;
thermal_r = [linspace(0,0,64), linspace(0,1,64), ...
             linspace(1,1,64), linspace(1,1,64)];
thermal_g = [linspace(0,0,64), linspace(0,0,64), ...
             linspace(0,1,64), linspace(1,1,64)];
thermal_b = [linspace(0.3,0.8,64), linspace(0.8,0,64), ...
             linspace(0,0,64), linspace(0,1,64)];
cmap_thermal = [thermal_r', thermal_g', thermal_b'];

% Permittivity colormap (viridis-like)
cmap_perm = build_viridis(n_colors);

%% --- Panel (a): B-scan t1 ---
ax1 = subplot(3, 4, [1 2]);
imagesc(bscan_t1);
colormap(ax1, cmap_thermal);
axis off; axis tight;
text(W-5, H-5, '$t_1$', 'Color', 'w', ...
     'FontSize', 14, 'FontWeight', 'bold', ...
     'HorizontalAlignment', 'right', ...
     'Interpreter', 'latex');
text(5, H-5, '(a)', 'Color', 'w', ...
     'FontSize', 12, 'FontWeight', 'bold');
title('Input $\mathbf{X}_i$: $d_{t_1}$', ...
      'Color', 'w', 'Interpreter', 'latex', 'FontSize', 11);

%% --- Panel (b): B-scan t2 ---
ax2 = subplot(3, 4, [5 6]);
imagesc(bscan_t2);
colormap(ax2, cmap_thermal);
axis off; axis tight;
text(W-5, H-5, '$t_2$', 'Color', 'w', ...
     'FontSize', 14, 'FontWeight', 'bold', ...
     'HorizontalAlignment', 'right', ...
     'Interpreter', 'latex');
text(5, H-5, '(b)', 'Color', 'w', ...
     'FontSize', 12, 'FontWeight', 'bold');
title('Input $\mathbf{X}_i$: $d_{t_2}$', ...
      'Color', 'w', 'Interpreter', 'latex', 'FontSize', 11);

%% --- Panel (c): B-scan t3 ---
ax3 = subplot(3, 4, [9 10]);
imagesc(bscan_t3);
colormap(ax3, cmap_thermal);
axis off; axis tight;
text(W-5, H-5, '$t_3$', 'Color', 'w', ...
     'FontSize', 14, 'FontWeight', 'bold', ...
     'HorizontalAlignment', 'right', ...
     'Interpreter', 'latex');
text(5, H-5, '(c)', 'Color', 'w', ...
     'FontSize', 12, 'FontWeight', 'bold');
title('Input $\mathbf{X}_i$: $d_{t_3}$', ...
      'Color', 'w', 'Interpreter', 'latex', 'FontSize', 11);

%% --- Arrows and Labels ---
% Input label
annotation('textbox', [0.01 0.45 0.08 0.08], ...
    'String', 'Input $X_i$', ...
    'Color', [0.7 0.7 0.7], ...
    'EdgeColor', 'none', ...
    'FontSize', 11, ...
    'Interpreter', 'latex', ...
    'HorizontalAlignment', 'center');

annotation('textbox', [0.01 0.38 0.08 0.08], ...
    'String', 'T, H, W', ...
    'Color', [0.85 0.55 0.1], ...
    'EdgeColor', 'none', ...
    'FontSize', 10, ...
    'HorizontalAlignment', 'center');

annotation('textbox', [0.01 0.31 0.08 0.08], ...
    'String', '$t_1, t_2, t_3$', ...
    'Color', [0.4 0.6 1.0], ...
    'EdgeColor', 'none', ...
    'FontSize', 10, ...
    'Interpreter', 'latex', ...
    'HorizontalAlignment', 'center');

% Arrow: Input -> Output (top)
annotation('arrow', [0.52 0.62], [0.80 0.80], ...
    'Color', [0.2 0.5 1.0], 'LineWidth', 2.5, 'HeadWidth', 12);

% Arrow: Input -> Output (bottom)
annotation('arrow', [0.52 0.62], [0.25 0.25], ...
    'Color', [0.2 0.5 1.0], 'LineWidth', 2.5, 'HeadWidth', 12);

%% --- Panel (d): Differential Permittivity Map ---
ax4 = subplot(3, 4, [3 4]);
imagesc(Y_delta);
colormap(ax4, cmap_perm);
cb4 = colorbar('Color', 'w', 'FontSize', 9);
cb4.Label.String = '\Delta\epsilon_r';
cb4.Label.Color  = 'w';
axis off; axis tight;
text(5, H-5, '(d)', 'Color', 'w', ...
     'FontSize', 12, 'FontWeight', 'bold');
title('Output $\mathbf{Y}_{\Delta} = \Delta\varepsilon_r(\mathbf{x},t)$', ...
      'Color', 'w', 'Interpreter', 'latex', 'FontSize', 11);

annotation('textbox', [0.63 0.82 0.1 0.06], ...
    'String', 'Output $Y_i$', ...
    'Color', [0.7 0.7 0.7], ...
    'EdgeColor', 'none', ...
    'FontSize', 10, ...
    'Interpreter', 'latex');

annotation('textbox', [0.63 0.76 0.1 0.06], ...
    'String', 'H, W', ...
    'Color', [0.85 0.55 0.1], ...
    'EdgeColor', 'none', ...
    'FontSize', 10);

%% --- Panel (e): Absolute Permittivity Map ---
ax5 = subplot(3, 4, [11 12]);
imagesc(Y_abs);
colormap(ax5, cmap_perm);
cb5 = colorbar('Color', 'w', 'FontSize', 9);
cb5.Label.String = '\epsilon_r';
cb5.Label.Color  = 'w';
axis off; axis tight;
text(5, H-5, '(e)', 'Color', 'w', ...
     'FontSize', 12, 'FontWeight', 'bold');
title('Output $\mathbf{Y}_{\mathrm{abs}} = \varepsilon_r(\mathbf{x})$', ...
      'Color', 'w', 'Interpreter', 'latex', 'FontSize', 11);

annotation('textbox', [0.63 0.27 0.1 0.06], ...
    'String', 'Output $Y_i$', ...
    'Color', [0.7 0.7 0.7], ...
    'EdgeColor', 'none', ...
    'FontSize', 10, ...
    'Interpreter', 'latex');

annotation('textbox', [0.63 0.21 0.1 0.06], ...
    'String', '$\varepsilon_r$, H, W', ...
    'Color', [0.85 0.55 0.1], ...
    'EdgeColor', 'none', ...
    'FontSize', 10, ...
    'Interpreter', 'latex');

%% --- Global Figure Title ---
sgtitle({'Figure 4: Synthetic GPR Dataset Construction', ...
         'Input: Spatio-Temporal B-scan Stack | Output: Permittivity Labels'}, ...
         'Color', 'w', 'FontSize', 13, 'FontWeight', 'bold');

%% =========================================================
%  SAVE FIGURE
%% =========================================================
exportgraphics(fig, 'Figure4_SyntheticGPR_Dataset.png', ...
               'Resolution', 300, 'BackgroundColor', 'k');
disp('Figure 4 saved successfully.');

%% =========================================================
%  LOCAL FUNCTION: Generate B-scan Radargram
%% =========================================================

function bscan = generate_bscan(eps_model, wav, A_z, H, W, ...
                                 noise_level, void_scale, ...
                                 X_grid, Z_grid, l1, l2, fc)

    bscan = zeros(H, W);

    % Reflection coefficients from permittivity contrasts
    refl = zeros(H, W);
    for z = 2:H-1
        eps_above = eps_model(z-1, :);
        eps_below = eps_model(z+1, :);
        RC = (sqrt(eps_below) - sqrt(eps_above)) ./ ...
             (sqrt(eps_below) + sqrt(eps_above));
        refl(z, :) = RC;
    end

    % Convolve each trace with Ricker wavelet
    wav_len = length(wav);
    half_w  = floor(wav_len / 2);

    for col = 1:W
        trace = zeros(H + wav_len, 1);
        for z = 1:H
            if abs(refl(z, col)) > 1e-4
                idx_start = z;
                idx_end   = z + wav_len - 1;
                trace(idx_start:idx_end) = ...
                    trace(idx_start:idx_end) + ...
                    refl(z, col) * wav(:);
            end
        end
        bscan(:, col) = trace(half_w+1 : half_w+H);
    end

    % Apply depth-dependent attenuation
    bscan = bscan .* repmat(A_z, 1, W);

    % Topographic undulation effect
    topo_shift = round(4 * sin(2*pi*(1:W)/W + pi/4));
    for col = 1:W
        shift = topo_shift(col);
        if shift > 0
            bscan(:, col) = [zeros(shift,1); bscan(1:end-shift, col)];
        elseif shift < 0
            bscan(:, col) = [bscan(-shift+1:end, col); zeros(-shift,1)];
        end
    end

    % Scale void signature
    void_region = (Z_grid > l2) & ...
                  (abs(X_grid - 160) < 35);
    bscan(void_region) = bscan(void_region) * void_scale;

    % Add composite noise
    noise_G = noise_level * randn(H, W);
    noise_C = noise_level * 0.5 * ...
              imgaussfilt(randn(H, W), 2);
    bscan   = bscan + noise_G + noise_C;

    % Normalize
    bscan = bscan / max(abs(bscan(:)));

end

%% =========================================================
%  LOCAL FUNCTION: Build Viridis-like Colormap
%% =========================================================

function cmap = build_viridis(n)
    % Approximation of viridis colormap
    r = [0.267, 0.283, 0.278, 0.254, 0.221, 0.190, ...
         0.168, 0.190, 0.298, 0.477, 0.678, 0.867, 0.993];
    g = [0.005, 0.130, 0.240, 0.340, 0.427, 0.516, ...
         0.600, 0.682, 0.762, 0.823, 0.863, 0.888, 0.906];
    b = [0.329, 0.432, 0.506, 0.553, 0.584, 0.598, ...
         0.600, 0.570, 0.506, 0.413, 0.310, 0.213, 0.144];

    xi   = linspace(0, 1, length(r));
    xq   = linspace(0, 1, n);
    cmap = [interp1(xi, r, xq)', ...
            interp1(xi, g, xq)', ...
            interp1(xi, b, xq)'];
    cmap = max(0, min(1, cmap));
end
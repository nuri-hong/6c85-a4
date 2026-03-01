%% Full script: Boxplot + light swarm with persuasion edits (UPDATED)
% Requested updates:
%   - Add Kruskal–Wallis p-value annotation to FIGURE 2 as well
%   - Order FIGURE 2 categories so that Protective is FIRST (leftmost)
%
% FIGURE 1 (PRO / displacement; DC excluded):
%   - Outcome: % obtaining abortion out-of-state (2020)
%   - Careful causal subtitle (association wording)
%   - Kruskal–Wallis p-value annotation
%
% FIGURE 2 (CON / suppression; DC included):
%   - Outcome: abortion rate by residence (per 1,000 women 15–44), 2020
%   - Categories ordered: Protective (left), Some restrictions/protections (middle), Restrictive (right)
%   - National average reference line
%   - Kruskal–Wallis p-value annotation
%   - Label a few lowest-rate restrictive states

clear; clc; close all;

fn = "GuttmacherInstituteAbortionDataByState.xlsx";

%% -----------------------
% READ DATA (preserve headers)
%% -----------------------
opts = detectImportOptions(fn,"VariableNamingRule","preserve");
T = readtable(fn, opts);

if isempty(T.Properties.VariableDescriptions)
    T.Properties.VariableDescriptions = T.Properties.VariableNames;
end

getCol     = @(target) getColumnByHeader(T, target);
getColLike = @(patterns) getColumnByHeaderLike(T, patterns);

state = string(getCol("U.S. State"));

% Residence rate (Fig 2)
resR = toNum(getCol("No. of abortions per 1,000 women aged 15–44, by state of residence, 2020"));

% Out-of-state % (Fig 1) — MUST exist; adjust patterns if needed
travelPct = toNum(getColLike([ ...
    "percent of abortions obtained out of state", ...
    "% obtained out of state", ...
    "out-of-state", ...
    "out of state", ...
    "travel" ...
]));

%% -----------------------
% 7-TIER LAW CATEGORIES (FROM YOUR MAP)
%% -----------------------
mostRestrictive = string(["Texas","Oklahoma","North Dakota","South Dakota","Iowa","Indiana","Kentucky","Tennessee","Mississippi","Alabama","Arkansas","Louisiana","Florida","Georgia","South Carolina"]);
veryRestrictive = string(["Idaho","Nebraska","Utah","West Virginia"]);
restrictive     = string(["Wyoming","Kansas","Missouri","North Carolina","Pennsylvania","Wisconsin","Virginia"]);
someMix         = string(["Arizona","Nevada","Ohio","New Hampshire"]);
protective      = string(["Montana","Maine","Alaska","Hawaii"]);
veryProtective  = string(["Connecticut","Delaware","Maryland","Michigan","Minnesota","New Jersey","New Mexico","Rhode Island","Vermont"]);
mostProtective  = string(["California","Colorado","Illinois","Massachusetts","New York","Oregon","Washington","District of Columbia"]);

law7 = strings(size(state));
law7(ismember(state, mostRestrictive)) = "Most restrictive";
law7(ismember(state, veryRestrictive)) = "Very restrictive";
law7(ismember(state, restrictive))     = "Restrictive";
law7(ismember(state, someMix))         = "Some restrictions/protections";
law7(ismember(state, protective))      = "Protective";
law7(ismember(state, veryProtective))  = "Very protective";
law7(ismember(state, mostProtective))  = "Most protective";

if any(law7 == "")
    missing = unique(state(law7==""));
    warning("Uncategorized states (edit lists): %s", strjoin(missing, ", "));
end

%% -----------------------
% COLORS
%% -----------------------
COL_restrict = [0.90 0.45 0.10];  % orange
COL_some     = [0.55 0.55 0.60];  % gray
COL_protect  = [0.10 0.35 0.85];  % blue

%% ============================================================
% FIGURE 1 (PRO): Out-of-state % by policy range (DC excluded)
% + careful causal subtitle
% + Kruskal–Wallis p-value annotation
%% ============================================================

lawPro = strings(size(law7));
lawPro(law7=="Most restrictive" | law7=="Very restrictive" | law7=="Restrictive") = "Restrictive";
lawPro(law7=="Some restrictions/protections") = "Some restrictions/protections";
lawPro(law7=="Protective" | law7=="Very protective" | law7=="Most protective") = "Protective";

lawProG = categorical(lawPro, ["Restrictive","Some restrictions/protections","Protective"]);

isDC = state=="District of Columbia";
goodPro = ~isnan(travelPct) & lawPro~="" & ~isDC;

y1 = travelPct(goodPro);
g1 = lawProG(goodPro);

% Kruskal–Wallis (nonparametric) across 3 groups
pKW1 = kruskalwallis(y1, g1, "off");

figure("Color","w","Position",[120 120 1200 650]);
plotStyledBoxSwarm(y1, g1, COL_restrict, COL_some, COL_protect);

xlabel("Policy category");
ylabel("% obtaining abortion out-of-state (2020)");
title("Displacement by policy category");
subtitle("Association shown: residents in more restrictive states tend to travel out-of-state more for care.");

addPValueAnnotation(pKW1, "Kruskal–Wallis (out-of-state %): ");

padYLim(0.08);

%% ============================================================
% FIGURE 2 (CON): Residence rate by policy category (DC included)
% ORDER: Protective first
% + national average line
% + Kruskal–Wallis p-value annotation
% + label lowest-rate restrictive states
%% ============================================================

lawCon = strings(size(law7));
lawCon(law7=="Most restrictive" | law7=="Very restrictive") = "Restrictive";
lawCon(law7=="Restrictive" | law7=="Some restrictions/protections" | law7=="Protective") = "Some restrictions/protections";
lawCon(law7=="Very protective" | law7=="Most protective") = "Protective";

goodCon = ~isnan(resR) & lawCon~="";

y2   = resR(goodCon);
g2tx = string(lawCon(goodCon));
s2   = state(goodCon);

% Force category order: Protective (left) -> Middle -> Restrictive (right)
catsOrd = ["Protective","Some restrictions/protections","Restrictive"];
g2 = categorical(g2tx, catsOrd);

% Kruskal–Wallis p-value across ordered categories (order doesn't affect p)
pKW2 = kruskalwallis(y2, g2, "off");

% National average reference line
natAvg = mean(y2, "omitnan");

figure("Color","w","Position",[140 140 1200 650]);
plotStyledBoxSwarm(y2, g2, COL_restrict, COL_some, COL_protect);

xlabel("Policy category (Protective → Restrictive)");
ylabel("Abortion rate by residence (per 1,000 women 15–44), 2020");
title("Residence abortion rates by policy category");
subtitle("Reference line shows national average across included states (DC included).");

% National average line
yline(natAvg, "k-", "LineWidth", 1.2, ...
    "Label", "National avg", "LabelHorizontalAlignment","left");

% p-value annotation
addPValueAnnotation(pKW2, "Kruskal–Wallis (residence rate): ");

% Label a few lowest-rate restrictive states (selective emphasis for CON argument)
restrictLabel = "Restrictive";
idxR = g2tx == restrictLabel;

yR = y2(idxR);
sR = s2(idxR);

% Lowest 3 restrictive states by residence rate
[~, lowIdx] = mink(yR, min(3, numel(yR)));

% x position of Restrictive category on the axis
xRestr = find(catsOrd == restrictLabel, 1);

for k = lowIdx(:)'
    text(xRestr + 0.10, yR(k), "  " + sR(k), ...
        "FontSize", 10, "Interpreter","none");
end

padYLim(0.08);

%% ============================================================
% LOCAL FUNCTIONS
%% ============================================================

function plotStyledBoxSwarm(y, g, colR, colM, colP)
% Styled boxplot with colored boxes + light swarm overlay.
% Works with any categorical ordering. Colors keyed by category name.

    hold on; grid on; box on;

    % Boxplot
    boxplot(y, g, "Symbol","", "Widths",0.55, "Whisker",1.5);

    % Thicken outlines and median
    set(findobj(gca,'Tag','Box'), 'LineWidth',1.5);
    set(findobj(gca,'Tag','Whisker'), 'LineWidth',1.2);
    set(findobj(gca,'Tag','Cap'), 'LineWidth',1.2);
    set(findobj(gca,'Tag','Median'), 'LineWidth',2.2, 'Color',[0.85 0 0]);

    % Color each box with a patch (MATLAB returns boxes in reverse order)
    cats = categories(g);
    n = numel(cats);
    boxes = findobj(gca,'Tag','Box');
    boxes = flipud(boxes);

    for i = 1:n
        ci = cats{i};
        c = pickColor(ci, colR, colM, colP);
        patch(get(boxes(i),'XData'), get(boxes(i),'YData'), c, ...
            'FaceAlpha',0.22,'EdgeColor',c,'LineWidth',1.5);
    end

    % Light swarm overlay
    x = double(g);
    xj = x + (rand(size(x)) - 0.5)*0.15;

    for i = 1:n
        ci = cats{i};
        idx = string(g) == ci;
        c = pickColor(ci, colR, colM, colP);
        scatter(xj(idx), y(idx), 30, c, "filled", ...
            "MarkerFaceAlpha",0.45, "MarkerEdgeColor","k", "LineWidth",0.2);
    end

    set(gca,"FontSize",12);
    hold off;
end

function c = pickColor(catName, colR, colM, colP)
    if catName == "Restrictive"
        c = colR;
    elseif catName == "Some restrictions/protections"
        c = colM;
    elseif catName == "Protective"
        c = colP;
    else
        c = [0.2 0.2 0.2];
    end
end

function addPValueAnnotation(p, prefix)
% Adds a p-value note at top-left of axes (normalized coordinates).
    if p < 1e-4
        ptxt = prefix + "p < 1e-4";
    else
        ptxt = sprintf("%sp = %.3g", prefix, p);
    end

    text(0.02, 0.98, ptxt, "Units","normalized", ...
        "HorizontalAlignment","left", "VerticalAlignment","top", ...
        "FontSize", 12, "FontWeight","bold");
end

function padYLim(padFrac)
    yl = ylim;
    span = yl(2) - yl(1);
    if span <= 0, return; end
    ylim([yl(1) - padFrac*span, yl(2) + padFrac*span]);
end

function col = getColumnByHeader(T, target)
    tgt = normalizeHeader(target);

    desc = T.Properties.VariableDescriptions;
    if isempty(desc), desc = T.Properties.VariableNames; end

    descNorm = strings(size(desc));
    for i = 1:numel(desc)
        descNorm(i) = normalizeHeader(string(desc{i}));
    end

    idx = find(descNorm == tgt, 1);
    if isempty(idx), idx = find(contains(descNorm, tgt), 1); end

    if isempty(idx)
        vnames = string(T.Properties.VariableNames);
        vnorm  = arrayfun(@normalizeHeader, vnames);
        idx = find(vnorm == tgt, 1);
        if isempty(idx), idx = find(contains(vnorm, tgt), 1); end
    end

    if isempty(idx)
        error("Could not find column matching header: %s", target);
    end

    col = T{:, idx};
end

function col = getColumnByHeaderLike(T, patterns)
    desc = T.Properties.VariableDescriptions;
    if isempty(desc), desc = T.Properties.VariableNames; end

    headers = strings(numel(desc),1);
    for i = 1:numel(desc)
        headers(i) = normalizeHeader(string(desc{i}));
    end

    patterns = string(patterns);
    patterns = arrayfun(@normalizeHeader, patterns);

    idx = [];
    for p = patterns(:)'
        j = find(contains(headers, p), 1);
        if ~isempty(j)
            idx = j; break;
        end
    end

    if isempty(idx)
        error("Could not find an out-of-state % column. Add a better substring to patterns.");
    end

    col = T{:, idx};
end

function s = normalizeHeader(s)
    s = string(s);
    s = lower(strtrim(s));
    s = replace(s, char(8211), "-");
    s = replace(s, char(8212), "-");
    s = replace(s, "–", "-");
    s = replace(s, "—", "-");
    s = regexprep(s, "\s+", " ");
end

function x = toNum(v)
    if isnumeric(v)
        x = double(v);
        return;
    end
    s = string(v);
    s = strtrim(s);
    s = replace(s, ",", "");
    s(ismember(lower(s), ["", "na", "n/a", "—", "-", "–", "null"])) = "NaN";
    x = str2double(s);
end
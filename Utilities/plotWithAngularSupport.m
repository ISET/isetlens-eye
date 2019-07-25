function figHandle = plotWithAngularSupport(x,y,img,varargin)

%% Parse inputs
p = inputParser;

p.addRequired('x');
p.addRequired('y');
p.addRequired('img');

p.addParameter('figHandle',[],@ishandle);
p.addParameter('axesSelect','both',@ischar);
p.addParameter('FontSize',24,@isnumeric);
p.addParameter('NumTicks',5,@isnumeric);

p.parse(x,y,img,varargin{:});
figHandle   = p.Results.figHandle;
axesSelect  = p.Results.axesSelect;
fontSize    = p.Results.FontSize;
numTicks    = p.Results.NumTicks;

%% Plot

if(isempty(figHandle))
    figHandle = figure();
else
    figure(figHandle);
end

set(figHandle, 'Color', [1 1 1])

imshow(img); hold on; axis on;

ax = get(figHandle,'CurrentAxes');

xticklabels = linspace(x(1),x(end),numTicks);
xticks = linspace(1, size(img, 2), numel(xticklabels));
%xticklabels = fix(xticklabels*10)*0.1;
xticklabels = round(xticklabels*10)*0.1;

set(ax, 'XTick', xticks,...
    'XTickLabel', sprintf('%2.1f\n', xticklabels),...
    'FontSize', fontSize)

yticklabels = linspace(y(1),y(end),numTicks);
yticks = linspace(1, size(img, 1), numel(yticklabels));
yticklabels = fix(yticklabels*10)*0.1;
set(ax, 'YTick', yticks,...
    'YTickLabel', sprintf('%2.1f\n', yticklabels),...
    'FontSize', fontSize)

box(ax,'off')


switch axesSelect
    case {'xaxis'}
        set(ax,'ytick',[])
        xlabel('\it space (degs)','FontSize', fontSize);
    case {'yaxis'}  
        set(ax,'xtick',[])
        ylabel('\it space (degs)','FontSize', fontSize);
    otherwise
        ylabel('\it space (degs)','FontSize', fontSize);
        xlabel('\it space (degs)','FontSize', fontSize);
end    

ax.TickLength = ax.TickLength.*2;
ax.LineWidth = ax.LineWidth.*6;

pos = get(ax, 'Position');
set(ax, 'Position', [pos(1)+0.1 pos(2)+0.1 pos(3)-0.2 pos(4)-0.2]);

end


function make(target)

%% mex files and options
% least-squares fitting routine
mex_file{1} = 'superimpose.c';
mex_opt{1} = {'-largeArrayDims'};

% mbar auxiliary function;
mex_file{2} = 'mbar_log_wi_jn.c';
mex_opt{2} = {'-largeArrayDims'};

% 2-d kernel density estimator;
mex_file{3} = 'ksdensity2d.c';
mex_opt{3} = {'-largeArrayDims'};

% 3-d kernel density estimator;
mex_file{4} = 'ksdensity3d.c';
mex_opt{4} = {'-largeArrayDims'};

% reversible transition matrix estimator
%mex_opt{end+1} = {'msmtransitionmatrix.c', '-largeArrayDims'};

% L-BFGS-B optimization
if ispc
  % windows
  mex_file{5} = 'lbfgsb_wrapper.c';
  mex_opt{5}  = {'-largeArrayDims', '-UDEBUG', '-Ilbfgsb/', ...
                  'lbfgsb/lbfgsb.c','lbfgsb/linesearch.c', ...
                  'lbfgsb/subalgorithms.c','lbfgsb/print.c', ...
                  'lbfgsb/linpack.c','lbfgsb/miniCBLAS.c','lbfgsb/timer.c'};
else
  % mac or unix
  mex_file{5} = 'lbfgsb_wrapper.c';
  mex_opt{5} = {'-largeArrayDims', '-lm', '-UDEBUG', '-Ilbfgsb/', ...
                  'lbfgsb/lbfgsb.c','lbfgsb/linesearch.c', ...
                  'lbfgsb/subalgorithms.c','lbfgsb/print.c', ...
                  'lbfgsb/linpack.c','lbfgsb/miniCBLAS.c','lbfgsb/timer.c'};
end

nmex = numel(mex_opt);

%% get fullpath to mdtoolbox
fullpath = mfilename('fullpath');
path_mdtoolbox = fileparts(fullpath);

%% change directory
current_dir = pwd;
source_dir = [path_mdtoolbox filesep 'mdtoolbox'];
cd(source_dir);
cleaner = onCleanup(@() cd(current_dir));

if ~isoctave()
  %%%%% MATLAB
  %% default keyword
  if (~exist('target', 'var')) | isempty(target)
    target = 'all';
  end

  %% set options and compile
  if strncmpi(target, 'all', numel('all'))
    for i =1:nmex
      mex_opt{i} = ['-O', mex_opt{i}];
    end
    compile_mex_matlab(mex_file, mex_opt);

  elseif strncmpi(target, 'verbose', numel('verbose'))
    for i =1:nmex
      mex_opt{i} = [{'-v', '-O'}, mex_opt{i}];
    end
    compile_mex_matlab(mex_file, mex_opt);

  elseif strncmpi(target, 'debug', numel('debug'))
    for i =1:nmex
      mex_opt{i} = [{'-g', '-DDEBUG'}, mex_opt{i}];
    end
    compile_mex_matlab(mex_file, mex_opt);
    
  elseif strncmpi(target, 'openmp', numel('openmp'))
    for i =1:nmex
      if i ~= 5
        mex_opt{i} = ['LDFLAGS="-fopenmp \$LDFLAGS"', 'CFLAGS="-fopenmp \$CFLAGS"', '-O', mex_opt{i}];
      end
    end
    compile_mex_matlab(mex_file, mex_opt);

  elseif strncmpi(target, 'clean', numel('clean'))
    delete_mex(mex_file);

  else
    error(sprintf('cannot find target: %s', target));

  end

else 
  %%%%% Octave
  %% default keyword
  if (~exist('target', 'var'))
    target = 'all';
  end
  is_openmp = false;

  %% set options and compile
  if strncmpi(target, 'all', numel('all'))
    compile_mex_octave(mex_file, mex_opt, is_openmp);

  elseif strncmpi(target, 'verbose', numel('verbose'))
    compile_mex_octave(mex_file, mex_opt, is_openmp);

  elseif strncmpi(target, 'debug', numel('debug'))
    compile_mex_octave(mex_file, mex_opt, is_openmp);
    
  elseif strncmpi(target, 'openmp', numel('openmp'))
    is_openmp = true;
    compile_mex_octave(mex_file, mex_opt, is_openmp);

  elseif strncmpi(target, 'clean', numel('clean'))
    delete_mex(mex_file);

  else
    error(sprintf('cannot find target: %s', target));

  end

end

function compile_mex_matlab(mex_file, mex_opt)
for i = 1:numel(mex_file)
  fprintf('Compiling MEX code: %s ...\n', mex_file{i});
  opt = '';
  for j = 1:numel(mex_opt{i})
    opt = [opt sprintf('%s ', mex_opt{i}{j})];
  end
  commandline = sprintf('mex %s %s', mex_file{i}, opt);
  fprintf('%s\n', commandline);
  eval(commandline);
  %mex(mex_opt{i}{:});
  fprintf('\n');
end

function compile_mex_octave(mex_file, mex_opt, is_openmp)
for i = 1:(numel(mex_file)-1)
  [~, ALL_CFLAGS] = system('mkoctfile -p ALL_CFLAGS');
  ALL_CFLAGS = strrep(ALL_CFLAGS, sprintf('\n'), '');
  fprintf('Compiling MEX code: %s ...\n', mex_file{i});
  if is_openmp
    if isempty(strfind(ALL_CFLAGS, 'fopenmp'))
      ALL_CFLAGS = sprintf('%s %s', ALL_CFLAGS, '-fopenmp');
    end
    [~, DL_LDFLAGS] = system('mkoctfile -p DL_LDFLAGS');
    DL_LDFLAGS = strrep(DL_LDFLAGS, sprintf('\n'), '');
    DL_LDFLAGS = sprintf('%s %s', DL_LDFLAGS, '-fopenmp');
    commandline = sprintf(['ALL_CFLAGS="%s" DL_LDFLAGS="%s" mkoctfile -v --mex %s'], ALL_CFLAGS, DL_LDFLAGS, mex_file{i});
  elseif ~isempty(strfind(ALL_CFLAGS, 'fopenmp'))
    [~, DL_LDFLAGS] = system('mkoctfile -p DL_LDFLAGS');
    DL_LDFLAGS = strrep(DL_LDFLAGS, sprintf('\n'), '');
    DL_LDFLAGS = sprintf('%s %s', DL_LDFLAGS, '-fopenmp');
    commandline = sprintf('DL_LDFLAGS=\"%s\" mkoctfile -v --mex %s', DL_LDFLAGS, mex_file{i});
  else
    commandline = sprintf('mkoctfile -v --mex %s', mex_file{i});
  end
  fprintf('%s\n', commandline);
  system(commandline);
  fprintf('\n');
end

function delete_mex(mex_file)
for i = 1:numel(mex_file)
  [~, filename] = fileparts(mex_file{i});
  mex_exe = [filename '.' mexext];
  fprintf('Deleting MEX exe: %s ...\n', mex_exe);
  if (exist(mex_exe, 'file'))
    delete(mex_exe);
  end

  if isoctave()
    mex_obj = [filename '.o'];
    fprintf('Deleting object file: %s ...\n', mex_obj);
    if (exist(mex_obj, 'file'))
      delete(mex_obj);
    end
  end
end


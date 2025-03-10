function main()
    clearvars;
    clc;

    global rootDir;
    % Determine the operating system and architecture
    [operatingSystem, appNameWithExt] = getOperatingSystem();

    % Set up directories
    [currentBuildDir, installerOutputDir, srcDir] = setupDirectories(operatingSystem);

    % Compile MATLAB code
    compileMATLABCode(currentBuildDir, appNameWithExt);

    % Package the application
    packageApplication(currentBuildDir, installerOutputDir, appNameWithExt);
end

function [operatingSystem, appNameWithExt] = getOperatingSystem()
    if ispc
        operatingSystem = 'windows';
        appNameWithExt = 'qtest.exe';
    elseif ismac
        operatingSystem = 'macOS';
        appNameWithExt = 'qtest.app';
    else
        error('Platform not supported');
    end
end

function [currentBuildDir, installerOutputDir, srcDir] = setupDirectories(operatingSystem)
    global rootDir;
    
    currentFile = mfilename('fullpath');
    currentFileDir = fileparts(currentFile);
    rootDir = fullfile(currentFileDir, '..');
    buildDir = fullfile(rootDir, 'build');
    currentBuildDir = fullfile(buildDir, operatingSystem, computer('arch'));
    installerOutputDir = fullfile(currentBuildDir, 'install');
    srcDir = fullfile(rootDir, 'src');

    % Add source directory to the MATLAB path
    addpath(srcDir);

    % Clean build directory
    if exist(currentBuildDir, 'dir')
        rmdir(currentBuildDir, 's');
    end
    mkdir(currentBuildDir);
end

function compileMATLABCode(currentBuildDir, appNameWithExt)
    disp('Compiling qtest');
    tic;
    matLabFile = fullfile(which('qtest.m'));
    mcc('-m', matLabFile, '-d', currentBuildDir);
    toc;
    disp('Compilation of qtest done');
end

function packageApplication(currentBuildDir, installerOutputDir, appNameWithExt)
    disp('Packaging qtest');
    
    % Define packaging options
    opts = createPackagingOptions(installerOutputDir);

    % Display packaging options
    displayPackagingOptions(opts);
    
    % Package the application
    packageInstaller(currentBuildDir, appNameWithExt, opts);
    
    disp('Packaging of qtest done');
end

function opts = createPackagingOptions(installerOutputDir)
    % Create packaging options object
    opts = compiler.package.InstallerOptions('ApplicationName', 'qtest');

    % Set packaging options
    opts.AuthorName = 'Regenwetters Lab';
    opts.AuthorEmail = 'regenwet@illinois.edu';
    opts.AuthorCompany = 'UIUC';
    opts.Version = getVersionFromGit();
    opts.InstallerName = 'qtest_Installer_web';
    opts.OutputDir = installerOutputDir;
    opts.Description = 'QTEST is a custom-designed public-domain statistical analysis package for order-constrained inference.';
    opts.Summary = 'QTEST is a custom-designed public-domain statistical analysis package for order-constrained inference.';
end

function qversion = getVersionFromGit()
    global rootDir;
    % setting default version
    qversion = defaultVersion();

    % Save the current directory
    currentDir = pwd;

    % Navigate to the directory where the MATLAB function resides
    fprintf("Changing current directory to %s", rootDir);
    cd(rootDir);

    % Check if we are in a Git repository
    if exist('.git', 'dir')

        % Execute git command to get the latest tag
        [status, tag] = system('git describe --tags --abbrev=0');
        codeChangeDetected = true;
        
        if status == 0
            tag = strtrim(tag);
            % Execute git command to check for differences
            [~, diffOutput] = system(['git diff --exit-code ', tag, ' HEAD']);

            % Check if there are any differences
            if isempty(diffOutput)
                codeChangeDetected = false;
                disp('No changes since the latest tag.');
            else
                codeChangeDetected = true;
                disp('Changes detected since the latest tag.');
            end
            
            qversion = getVersionString(tag, codeChangeDetected);
        else
            warning('Error: Unable to retrieve the latest tag. Check if git is installed. Resolving to default version.');
        end

    else
        warning('Not in a Git repository. Make sure you are running from a git repository. Resolving to default version.');
    end

    % Return to the original directory
    fprintf("Reverting current directory back to %s", currentDir);
    cd(currentDir);
end

function qversion = defaultVersion()
    qversion = '2.1.3';
end

function versionString = getVersionString(tag, codeChanged)
    [major, minor, patch] = getMMPFromTag(tag);
    
    if codeChanged
        disp('Bumping to next patch version');
        patch = patch + 1;
    end
    
    versionString = sprintf('%d.%d.%d', major, minor, patch);
end

function [majorVersion, minorVersion, patchVersion] = getMMPFromTag(versionStr)

    % Regular expression pattern to match numerical values without the leading "v"
    pattern = '(\d+)\.(\d+)\.(\d+)';

    % Match the pattern in the version string
    matches = regexp(versionStr, pattern, 'tokens');

    if ~isempty(matches)
        % Extract version components
        majorVersion = str2double(matches{1}{1});
        minorVersion = str2double(matches{1}{2});
        patchVersion = str2double(matches{1}{3});

    else
        error('Invalid version format in version string %s', versionStr);
    end

end

function displayPackagingOptions(opts)
    % Display packaging options
    disp('Packaging options:');
    disp(opts);
end

function packageInstaller(currentBuildDir, appNameWithExt, opts)
    % Package the application
    tic;
    compiler.package.installer(fullfile(currentBuildDir, appNameWithExt), fullfile(currentBuildDir, 'requiredMCRProducts.txt'), 'Options', opts);
    toc;
end

function super_pixel_convertion()
if(exist('vl_slic', 'file')<1)
    VLFEATROOT = 'vlfeat/vlfeat-0.9.17';
    run([VLFEATROOT '/toolbox/vl_setup']);
end


%matlabpool('open',2);
regionSize = 60;
regularizer = 0.09;
%n = matlabpool('size');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Image Folders
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
img_folder = 'Images/2010-05-21';

img_extension = '.png';

filename = 'SuperPixels/'; %output folder

image_files = dir(strcat(img_folder, '/*' , img_extension));


%iterate over images
fprintf('size(image_files,1): %d', size(image_files,1));
fprintf('starting');
tic;
for j=1:size(image_files,1)
    image_name = image_files(j).name;
    image = imread(fullfile(img_folder,image_files(j).name));
    
    image_single = im2single(image);
    
    try
    segments = vl_slic(image_single, regionSize, regularizer);
    %dlmwrite('segments.txt',segments,'delimiter',' ');
    %iterate over superpixels
    %TODO create matrices with known dimensions ahead of time with zeros;
    super_pixel_counter=1;
    for k=0:max(segments(:))
        spIndices = find(segments==k);
        %disp(spIndices);
        [indX,indY] = ind2sub(size(segments),spIndices);
        %pairs = [indX,indY];
        %        disp(pairs);
        %area = size(indX,1);
        %         fprintf('area is %d', area);
        
        rangeX = range(indX);
        rangeY = range(indY);
        
        minX = min(indX);
        minY = min(indY);
        %maxX=max(indX);
        %maxY=max(indY);
        
        A = ones(rangeX+1, rangeY+1 ,3);
        alphas = zeros(rangeX+1, rangeY+1);
        fprintf('size of superPixel: A: %d %d \n', size(A));
        %A(indX-minX+1, indY-minY+1,:) = image_single(indX,indY,:); %this
        %was supposed to be a shorter replacement for the commented out for
        %loop below, but it instead also produced a full block, it seems
        
        for p=1:length(indX)
            ix = indX(p);
            iy = indY(p);
            ax = ix-minX+1;
            ay = iy-minY+1;
            A(ax,ay,:) = image_single(ix,iy,:);
            A(ax,ay,1) = image_single(ix,iy,1);
            A(ax,ay,2) = image_single(ix,iy,2);
            A(ax,ay,3) = image_single(ix,iy,3);
            alphas(ax,ay) = 1;
        end
        try
            super_pixel_name = strrep(image_name, '.png', strcat('-', num2str(super_pixel_counter)));
            imwrite(A, [filename super_pixel_name img_extension], 'Alpha', alphas);
        catch err
            fprintf('Error********:\n');
            fprintf('size of A:  %d %d \n',size(A));
            writeExceptionToFile(err);
        end
        super_pixel_counter=super_pixel_counter+1;
    end %end for loop of segments
    
    catch err
        writeExceptionToFile(err);
    end
    
end
fprintf('ending');
toc;
%matlabpool close;
end

function writeExceptionToFile(err)
    fid = fopen('logFile.txt','a');
    fprintf(fid,'%s\n',err.message);
    fprintf(fid, '%s', err.getReport('extended', 'hyperlinks','off'));
    fclose(fid);
end
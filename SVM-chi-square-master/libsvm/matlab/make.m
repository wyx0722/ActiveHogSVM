% % This make.m is for MATLAB and OCTAVE under Windows, Mac, and Unix

try
	Type = ver;
	% This part is for OCTAVE
	if(strcmp(Type(1).Name, 'Octave') == 1)
		mex libsvmread.c
		mex libsvmwrite.c
		mex svmtrain.c ../svm.cpp svm_model_matlab.c
		mex svmpredict.c ../svm.cpp svm_model_matlab.c
	% This part is for MATLAB
	% Add -largeArrayDims on 64-bit machines of MATLAB
	else
		mex CFLAGS="\$CFLAGS -std=c99" -largeArrayDims libsvmread.c
		mex CFLAGS="\$CFLAGS -std=c99" -largeArrayDims libsvmwrite.c
%         mex CFLAGS="\$CFLAGS -std=c99" -largeArrayDims libsvmtrain.c

		mex CFLAGS="\$CFLAGS -std=c99" -largeArrayDims libsvmtrain.c ../svm.cpp svm_model_matlab.c
		mex CFLAGS="\$CFLAGS -std=c99" -largeArrayDims svmpredict.c ../svm.cpp svm_model_matlab.c
	end
catch
	fprintf('If make.m fails, please check README about detailed instructions.\n');
end


% add -largeArrayDims on 64-bit machines

% mex -largeArrayDims -O -c svm.cpp
% mex -largeArrayDims -O -c svm_model_matlab.c
% mex -largeArrayDims -O libsvmtrain.c svm.o svm_model_matlab.o

%These files are not used
%mex -O svmpredict.c svm.obj svm_model_matlab.obj
%mex -O libsvmread.c
%mex -O libsvmwrite.c
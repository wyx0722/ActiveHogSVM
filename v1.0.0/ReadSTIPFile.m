function stip_data = ReadSTIPFile(filename)

stip_data = {};
idx = 0;
fd = fopen(filename);
tline = fgetl(fd);
tline = fgetl(fd);
while ischar(tline)
   if isempty(tline)
       tline = fgetl(fd);    
       continue;
       
   elseif tline(1) == '#'
       idx = idx+1;
       filename = tline(3:end);
       stip_data{idx}.video = filename;
       stip_data{idx}.features = [];
       disp(['-- read ' filename]);
   else
       tmp = str2num(tline);
       stip_data{idx}.features = [stip_data{idx}.features;tmp];
   end
   
   tline = fgetl(fd);
end



end
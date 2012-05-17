require File.dirname(__FILE__) + '/versionone/versionone-api'

%w{ versionone ticket project comment }.each do |f|
  require File.dirname(__FILE__) + '/provider/' + f + '.rb';
end

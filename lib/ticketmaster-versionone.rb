#require YOUR_PROVIDER_API

%w{ versionone ticket project comment }.each do |f|
  require File.dirname(__FILE__) + '/provider/' + f + '.rb';
end

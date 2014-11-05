#Additionally include any of the dynamodb paramters as needed.
#(eg: if you would like to change the dynamodb endpoint, then add the parameter in
# in the file  aws.yml or aws.rb

AWS.config({
               :access_key_id => ENV['AWS_ACCESS_KEY'],
               :secret_access_key => ENV['AWS_SECRET_KEY']
           })
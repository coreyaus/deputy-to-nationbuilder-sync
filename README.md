# General

This app uses `daemons` gem to run delayed jobs and a rake task to read from SQS and
create delayed jobs.

## Reading from SQS queue

* Run rake task with: `rake sqs:listen[number_of_messages]`
* `number_of_messages` is the number of messages to read from SQS in a single API
call; this number has to be between 1 and 10 (10 is recommended).

## Running delayed jobs

There are two wasy of running the delayed jobs, with a rake a task or a the `daemons` script.

### Running with rake task

* Run following task: `rake jobs:work`

### Run daemon

* Using `daemons` gem:
  * To start run `ruby ./script/delayed_job start`
  * To stop run `ruby ./script/delayed_job stop`
* Can use `foreman`gem too.

## ENV variables

* The following are self explanatory:

<pre><code>ENV['AWS_ACCESS_KEY'] = 'aws-access-key'
ENV['AWS_SECRET_KEY'] = 'aws-seecret-key'
ENV['AWS_QUEUE_URL'] = 'aws-queue-url-given-by-sqs'
ENV['NATION_BUILDER_API_KEY'] = 'nation-builder-api-key'
</code></code>

* These have the following instructions or format:

<pre><code>ENV['DEPUTY_ACCESS_TOKEN'] = 'create-dummy-oauth-client-and-10-year-access-key'
ENV['NATION_BUILDER_API_BASE_URL'] = 'https://{slug-name}.nationbuilder.com/api/v1/'
ENV['DEPUTY_API_BASE_URL'] = 'https://{app-subdomain}.deputy.com/api/v1/'
</code></code>

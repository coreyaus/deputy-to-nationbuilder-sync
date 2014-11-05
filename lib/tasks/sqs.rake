namespace :sqs do
  desc 'Read from queue'
  task :listen, [:max_number_of_messages] => :environment do |task, args|

    log_message('STARTED RETRIEVING FROM QUEUE')

    sqs_client = AWS::SQS.new.client
    response = sqs_client.receive_message(queue_url: ENV['AWS_QUEUE_URL'], max_number_of_messages: args.max_number_of_messages.to_i)
    messages = response.data[:messages]
    receipt_handles_to_delete = Array.new

    log_message("RECEIVED #{messages.count} MESSAGES")

    messages.each_with_index do |message_hash, index|
      decoded_body = Base64.decode64(message_hash[:body])
      body_hash = JSON.parse("#{decoded_body}")
      process_message(body_hash)

      receipt_handles_to_delete.push({ id: (index + 1).to_s, receipt_handle: message_hash[:receipt_handle]})
    end

    if messages.count > 0
      delete_response = sqs_client.delete_message_batch(queue_url: ENV['AWS_QUEUE_URL'], entries: receipt_handles_to_delete)

      log_message('DELETION RESPONSE')
      log_message(JSON.pretty_generate(delete_response.data))
    end

    log_message('FINISHED RETRIEVING FROM QUEUE')
  end

  def process_message(hash)
    shift_id = hash['id'].to_i
    employee_id = hash['employee'].to_i
    comment = hash['comment']
    start_date = parse_date(hash['start_time_localized'])
    end_date = parse_date(hash['end_time_localized'])

    Roster.create!(shift_id: shift_id, employee_id: employee_id, comments: comment, start_time: start_date, end_time: end_date)
  end

  def parse_date(date_string)
    DateTime.strptime(date_string, '%Y-%m-%dT%H:%M:%S%z')
  end

  def log_message(message)
    Rails.logger.info("=====> #{message} <=====")
    puts("=====> #{message} <=====")
  end
end
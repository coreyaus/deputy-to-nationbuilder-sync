class Roster < ActiveRecord::Base
  # ============
  # Constants
  # ============
  STATE_UNPROCESSED = 'Unprocessed'
  STATE_PROCESSED = 'Processed'

  # Nation builder
  NB_API_BASE_URL = ENV['NATION_BUILDER_API_BASE_URL']
  NB_RESOURCE_PEOPLE = 'people/'
  NB_PEOPLE_MATCH_ACTION = 'match'
  NB_PEOPLE_TAGGINGS_ACTION = 'taggings'


  # Deputy
  D_API_BASE_URL = ENV['DEPUTY_API_BASE_URL']
  D_RESOURCE_EMPLOYEE = 'resource/Employee/'
  D_RESOURCE_CONTACT = 'resource/Contact/'
  # =========
  # Attributes
  # =========
  attr_accessible :comments, :employee_id, :end_time, :shift_id, :start_time, :state, :email, :nation_builder_id

  # =========
  # Callbacks
  # =========
  before_create { self.state = STATE_UNPROCESSED }
  before_update { self.state = STATE_PROCESSED }
  after_create :start_process_job

  # =========
  # Private methods
  # =========
  private
  def start_process_job
    self.delay.migrate(self.employee_id, self.comments, self.id)
    log_message('CREATED DELAYED JOB')
  end

  def migrate(employee_id, comments, id)
    log_message("STARTED DELAYED JOB FOR ID: #{id}")

    roster = Roster.find_by_id(id)

    tags = comments.split(',').map { |tag| tag.strip }
    tags.push('polling day: shift assigned')

    log_message('RETRIEVING CONTACT INFO FROM DEPUTY')

    contact_id = get_employee_contact_id(employee_id)

    log_message('RETRIEVING EMAIL FROM DEPUTY')

    raw_email = get_email(contact_id)

    unless raw_email.blank?
      email = parse_email(raw_email)
      roster.email = email

      log_message('LOOKING FOR EMAIL IN NATION BUILDER')

      nation_builder_id = id_by_match_by_email(email)

      if nation_builder_id
        roster.nation_builder_id = nation_builder_id

        log_message('ADDING TAGS')

        tag_person(nation_builder_id, tags)

        log_message('TAGS ADDED')
      end
    end

    roster.save
    log_message("UPDATED ROSTER WITH DB ID: #{id}")
  end

  def parse_email(raw_email)
    clean_email = raw_email

    if raw_email.include?('_AT_') || raw_email.include?('_PLUS_')
      match = /nb-sync\+(.*)@/.match(raw_email)
      clean_email = match[1].gsub(/_AT_/, '@').gsub(/_PLUS_/, '+')
    end

    clean_email
  end

  def log_message(message)
    Rails.logger.info("==> #{message} <==")
    puts("==> #{message} <==")
  end

  # =========
  # Nation Builder API methods
  # =========
  def id_by_match_by_email(email)
    id = nil

    begin
      url_call = NB_API_BASE_URL + NB_RESOURCE_PEOPLE + NB_PEOPLE_MATCH_ACTION
      response = RestClient.get(url_call, { params: { access_token: ENV['NATION_BUILDER_API_KEY'], email: email }, accept: :json })
      json_response = JSON.parse(response)

      id = json_response['person']['id'].to_i
    rescue
      # If no person found by email a 400 error is received
    end

    id
  end

  def tag_person(person_id, tags)
    url_call = NB_API_BASE_URL + NB_RESOURCE_PEOPLE + person_id.to_s + '/' + NB_PEOPLE_TAGGINGS_ACTION + '?access_token=' + ENV['NATION_BUILDER_API_KEY']

    tags.each do |tag|
      begin
        payload = { tagging: { tag: tag } }
        RestClient.put(url_call, payload.to_json, content_type: :json, accept: :json)
      rescue
        # Do nothing
      end
    end
  end

  # =========
  # Deputy API methods
  # =========
  def get_employee_contact_id(employee_id)
    id = nil

    begin
      url = D_API_BASE_URL + D_RESOURCE_EMPLOYEE + employee_id.to_s
      access_token = ENV['DEPUTY_ACCESS_TOKEN']

      response = RestClient.get(url, { 'Authorization' => "OAuth #{access_token}", content_type: :json, accept: :json })
      json_response = JSON.parse(response)
      id = json_response['Contact'].to_i
    rescue
      # Do nothing, should work
    end

    id
  end

  def get_email(contact_id)
    email = nil

    begin
      url = D_API_BASE_URL + D_RESOURCE_CONTACT + contact_id.to_s
      access_token = ENV['DEPUTY_ACCESS_TOKEN']

      response = RestClient.get(url, { 'Authorization' => "OAuth #{access_token}", content_type: :json, accept: :json })
      json_response = JSON.parse(response)
      email = json_response['Email1']
    rescue
      # Do nothing, should work
    end

    email
  end
end

class PeopleController < ApplicationController
  def index
    redirect_to "/clinic"
  end
 
  def new
  end
  
  def identifiers
  end

  def demographics
    # Search by the demographics that were passed in and then return demographics
    people = Person.find_by_demographics(params)
    result = people.empty? ? {} : people.first.demographics
    render :text => result.to_json
  end
 
  def search
    found_person = nil
    if params[:identifier]
      local_results = Person.search_by_identifier(params[:identifier])
      if local_results.length > 1
        @people = Person.search(params)
      elsif local_results.length == 1
        found_person = local_results.first
      else
        # TODO - figure out how to write a test for this
        # This is sloppy - creating something as the result of a GET
        found_person_data = Person.find_remote_by_identifier(params[:identifier])
        found_person =  Person.create_from_form(found_person_data) unless found_person_data.nil?
      end
      if found_person
        redirect_to search_complete_url(found_person.id, params[:relation]) and return
      end
    end
    @people = search_people(params)    
  end
 
  # This method is just to allow the select box to submit, we could probably do this better
  def select
    redirect_to search_complete_url(params[:person], params[:relation]) and return unless params[:person].blank? || params[:person] == '0'
    redirect_to :action => :new, :gender => params[:gender], :given_name => params[:given_name], :family_name => params[:family_name],
      :family_name2 => params[:family_name2], :address2 => params[:address2], :identifier => params[:identifier], :relation => params[:relation]
  end
 
  def create
    Person.session_datetime = session[:datetime].to_date rescue Date.today
    person = create_from_form(params)
    
    encounter = Encounter.new(params[:encounter])
    encounter.patient_id = person.id
    encounter.encounter_datetime = session[:datetime] unless session[:datetime].blank?
    encounter.save   
    
    if params[:person][:patient]
      ANCService::ANC.new(person.patient).national_id_label
      unless (params[:relation].blank?)
        print_and_redirect("/patients/national_id_label/?patient_id=#{person.patient.id}", search_complete_url(person.id, params[:relation]))      
      else
        print_and_redirect("/patients/national_id_label/?patient_id=#{person.patient.id}", next_task(person.patient))
      end  
    else
      # Does this ever get hit?
      redirect_to :action => "index"
    end
  end

  def set_datetime
    if request.post?
      unless params[:set_day]== "" or params[:set_month]== "" or params[:set_year]== ""
        # set for 1 second after midnight to designate it as a retrospective date
        date_of_encounter = Time.mktime(params[:set_year].to_i,
          params[:set_month].to_i,                                
          params[:set_day].to_i,0,0,1) 
        session[:datetime] = date_of_encounter if date_of_encounter.to_date != Date.today 
      end
      redirect_to :action => "index"
    end
  end

  def reset_datetime
    session[:datetime] = nil
    redirect_to :action => "index" and return
  end

  def find_by_arv_number
    if request.post?
      redirect_to :action => 'search' ,
        :identifier => "#{Location.current_arv_code} #{params[:arv_number]}" and return
    end
  end
  
  def search_by_identifier(identifier)
    PatientIdentifier.find_all_by_identifier(identifier).map{|id| id.patient.person} unless identifier.blank? rescue nil
  end

  def search_people(params)
    people = search_by_identifier(params[:identifier])

    return people.first.id unless people.blank? || people.size > 1
    people = Person.find(:all, :include => [{:names => [:person_name_code]}, :patient], :conditions => [
        "gender = ? AND \
     (person_name.given_name LIKE ? OR person_name_code.given_name_code LIKE ?) AND \
     (person_name.family_name LIKE ? OR person_name_code.family_name_code LIKE ?)",
        params[:gender],
        params[:given_name],
        (params[:given_name] || '').soundex,
        params[:family_name],
        (params[:family_name] || '').soundex
      ]) if people.blank?

    return people
    
  end

  def find_by_demographics(person_demographics)
    national_id = person_demographics["person"]["patient"]["identifiers"]["National id"] rescue nil
    results = Person.search_by_identifier(national_id) unless national_id.nil?
    return results unless results.blank?

    gender = person_demographics["person"]["gender"] rescue nil
    given_name = person_demographics["person"]["names"]["given_name"] rescue nil
    family_name = person_demographics["person"]["names"]["family_name"] rescue nil

    search_params = {:gender => gender, :given_name => given_name, :family_name => family_name }

    results = Person.search(search_params)

  end

  def create_from_form(params)
    if params.has_key?('person')
      params = params['person']
    end
    address_params = params["addresses"]
    names_params = params["names"]
    patient_params = params["patient"]
    params_to_process = params.reject{|key,value| key.match(/addresses|patient|names|relation|cell_phone_number|home_phone_number|office_phone_number/) }
    birthday_params = params_to_process.reject{|key,value| key.match(/gender/) }
    person_params = params_to_process.reject{|key,value| key.match(/birth_|age_estimate|occupation/) }

    if params.has_key?('person')
      person = Person.create(person_params[:person])
    else
      person = Person.create(person_params)
    end
    
    if birthday_params["birth_year"] == "Unknown"
      ANCService::ANC.set_birthdate_by_age(person.person_id, birthday_params["age_estimate"],session[:datetime] || Date.today)
    else
      ANCService::ANC.set_birthdate(person.person_id, birthday_params["birth_year"], birthday_params["birth_month"], birthday_params["birth_day"])
    end
    
    person.names.create(names_params)
    person.addresses.create(address_params)

    person.person_attributes.create(
      :person_attribute_type_id => PersonAttributeType.find_by_name("Occupation").person_attribute_type_id,
      :value => params["occupation"])
 
    person.person_attributes.create(
      :person_attribute_type_id => PersonAttributeType.find_by_name("Cell Phone Number").person_attribute_type_id,
      :value => params["cell_phone_number"])
 
    person.person_attributes.create(
      :person_attribute_type_id => PersonAttributeType.find_by_name("Office Phone Number").person_attribute_type_id,
      :value => params["office_phone_number"]) unless params["office_phone_number"].blank?
 
    person.person_attributes.create(
      :person_attribute_type_id => PersonAttributeType.find_by_name("Home Phone Number").person_attribute_type_id,
      :value => params["home_phone_number"]) unless params["home_phone_number"].blank?
 
    # TODO handle the birthplace attribute
 
    if (!patient_params.nil?)
      patient = person.create_patient

      patient_params["identifiers"].each{|identifier_type_name, identifier|
        identifier_type = PatientIdentifierType.find_by_name(identifier_type_name) || PatientIdentifierType.find_by_name("Unknown id")
        patient.patient_identifiers.create("identifier" => identifier, "identifier_type" => identifier_type.patient_identifier_type_id)
      } if patient_params["identifiers"]
  
      # This might actually be a national id, but currently we wouldn't know
      #patient.patient_identifiers.create("identifier" => patient_params["identifier"], "identifier_type" => PatientIdentifierType.find_by_name("Unknown id")) unless params["identifier"].blank?
    end

    # patient = ANCService::ANC.new(person.patient) rescue nil
    
    return person
  end

  def set_birthdate(year = nil, month = nil, day = nil)   
    raise "No year passed for estimated birthdate" if year.nil?

    # Handle months by name or number (split this out to a date method)    
    month_i = (month || 0).to_i
    month_i = Date::MONTHNAMES.index(month) if month_i == 0 || month_i.blank?
    month_i = Date::ABBR_MONTHNAMES.index(month) if month_i == 0 || month_i.blank?
    
    if month_i == 0 || month == "Unknown"
      self.person.birthdate = Date.new(year.to_i,7,1)
      self.person.birthdate_estimated = 1
    elsif day.blank? || day == "Unknown" || day == 0
      self.person.birthdate = Date.new(year.to_i,month_i,15)
      self.person.birthdate_estimated = 1
    else
      self.person.birthdate = Date.new(year.to_i,month_i,day.to_i)
      self.person.birthdate_estimated = 0
    end
  end

  def set_birthdate_by_age(age, today = Date.today)
    self.person.birthdate = Date.new(today.year - age.to_i, 7, 1)
    self.person.birthdate_estimated = 1
  end

  def find_remote_by_identifier(identifier)
    known_demographics = {:person => {:patient => { :identifiers => {"National id" => identifier }}}}
    Person.find_remote(known_demographics)
  end

  def find_remote(known_demographics)
    servers = GlobalProperty.find(:first, :conditions => {:property => "remote_servers.parent"}).property_value.split(/,/) rescue nil
    return nil if servers.blank?

    wget_base_command = "wget --quiet --load-cookies=cookie.txt --quiet --cookies=on --keep-session-cookies --save-cookies=cookie.txt"
    # use ssh to establish a secure connection then query the localhost
    # use wget to login (using cookies and sessions) and set the location
    # then pull down the demographics
    # TODO fix login/pass and location with something better

    login = "mikmck"
    password = "mike"
    location = 8

    post_data = known_demographics
    post_data["_method"]="put"

    local_demographic_lookup_steps = [ 
      "#{wget_base_command} -O /dev/null --post-data=\"login=#{login}&password=#{password}\" \"http://localhost/session\"",
      "#{wget_base_command} -O /dev/null --post-data=\"_method=put&location=#{location}\" \"http://localhost/session\"",
      "#{wget_base_command} -O - --post-data=\"#{post_data.to_param}\" \"http://localhost/people/demographics\""
    ]
    results = []
    servers.each{|server|
      command = "ssh #{server} '#{local_demographic_lookup_steps.join(";\n")}'"
      output = `#{command}`
      results.push output if output and output.match /person/
    }
    # TODO need better logic here to select the best result or merge them
    # Currently returning the longest result - assuming that it has the most information
    # Can't return multiple results because there will be redundant data from sites
    result = results.sort{|a,b|b.length <=> a.length}.first

    result ? JSON.parse(result) : nil

  end

  def update_demographics(params)
    person = Person.find(params['person_id'])

    if params.has_key?('person')
      params = params['person']
    end

    address_params = params["addresses"]
    names_params = params["names"]
    patient_params = params["patient"]
    person_attribute_params = params["attributes"]

    params_to_process = params.reject{|key,value| key.match(/addresses|patient|names|attributes/) }
    birthday_params = params_to_process.reject{|key,value| key.match(/gender/) }

    person_params = params_to_process.reject{|key,value| key.match(/birth_|age_estimate/) }

    if !birthday_params.empty?

      if birthday_params["birth_year"] == "Unknown"
        person.set_birthdate_by_age(birthday_params["age_estimate"])
      else
        person.set_birthdate(birthday_params["birth_year"], birthday_params["birth_month"], birthday_params["birth_day"])
      end

      person.birthdate_estimated = 1 if params["birthdate_estimated"] == 'true'
      person.save
    end

    person.update_attributes(person_params) if !person_params.empty?
    person.names.first.update_attributes(names_params) if names_params
    person.addresses.first.update_attributes(address_params) if address_params

    #update or add new person attribute
    person_attribute_params.each{|attribute_type_name, attribute|
      attribute_type = PersonAttributeType.find_by_name(attribute_type_name.humanize.titleize) || PersonAttributeType.find_by_name("Unknown id")
      #find if attribute already exists
      exists_person_attribute = PersonAttribute.find(:first, :conditions => ["person_id = ? AND person_attribute_type_id = ?", person.id, attribute_type.person_attribute_type_id]) rescue nil
      if exists_person_attribute
        exists_person_attribute.update_attributes({'value' => attribute})
      else
        person.person_attributes.create("value" => attribute, "person_attribute_type_id" => attribute_type.person_attribute_type_id)
      end
    } if person_attribute_params

  end 
    
  private
  
  def search_complete_url(found_person_id, primary_person_id) 
    unless (primary_person_id.blank?)
      # Notice this swaps them!
      new_relationship_url(:patient_id => primary_person_id, :relation => found_person_id)
    else
      url_for(:controller => :encounters, :action => :new, :patient_id => found_person_id)
    end
  end
end
 

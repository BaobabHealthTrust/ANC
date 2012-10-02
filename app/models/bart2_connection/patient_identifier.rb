class Bart2Connection::PatientIdentifier < ActiveRecord::Base
  self.establish_connection :bart2
  set_table_name "patient_identifier"
  set_primary_key :patient_identifier_id
  include Bart2Connection::Openmrs

  belongs_to :type, :class_name => "Bart2Connection::PatientIdentifierType", :foreign_key => :identifier_type, :conditions => {:retired => 0}
  belongs_to :patient, :class_name => "Bart2Connection::Patient", :foreign_key => :patient_id, :conditions => {:voided => 0}

  def self.search_by_identifier(identifier)
    people = self.find_all_by_identifier(identifier).map{|id|
      id.patient.person
    } unless identifier.blank? rescue nil

    return people.first unless people.blank?

    create_from_remote = CoreService.get_global_property_value('create.from.remote').to_s == "true" rescue false

    if create_from_remote
       servers = GlobalProperty.find(:first,
      :conditions => {:property => "remote_servers.parent"}).property_value.split(/,/) rescue nil
    server_address_and_port = servers.to_s.split(':')
    server_address = server_address_and_port.first
    server_port = server_address_and_port.second
    login = GlobalProperty.find(:first,
      :conditions => {:property => "remote_bart.username"}).property_value.split(/,/) rescue ''
    password = GlobalProperty.find(:first,
      :conditions => {:property => "remote_bart.password"}).property_value.split(/,/) rescue ''

    if server_port.blank?
      uri = "http://#{login.first}:#{password.first}@#{server_address}/people/demographics_remote"
    else
      uri = "http://#{login.first}:#{password.first}@#{server_address}:#{server_port}/people/demographics_remote"
    end
    known_demographics = {:person => {:patient => {:identifiers =>{"national_id" => identifier}}}}
    output = RestClient.post(uri,known_demographics)

    results = []
    results.push output if output and output.match(/person/)
    result = results.sort{|a,b|b.length <=> a.length}.first          
    result ? p = JSON.parse(result) : nil


    
      return [] if p.blank?

      gender = p["person"]["gender"] == "F" ? "Female" : "Male"

      passed = {
        "person"=>{"occupation"=>p["person"]["attributes"]["occupation"],
          "age_estimate"=> p["person"]["age_estimate"] ,
          "cell_phone_number"=>p["person"]["attributes"]["cell_phone_number"],
          "birth_month"=> p["person"]["birth_month"] ,
          "addresses"=>{"address1"=>p["person"]["addresses"]["county_district"],
            "address2"=>p["person"]["addresses"]["address2"],
            "city_village"=>p["person"]["addresses"]["city_village"],
            "county_district"=>""},
          "gender"=> gender ,
          "patient"=>{"identifiers"=>{"National id" => p["person"]["patient"]["identifiers"]["National id"] }},
          "birth_day"=> p["person"]["birth_day"] ,
          "home_phone_number"=>p["person"]["attributes"]["home_phone_number"],
          "names"=>{"family_name"=> p["person"]["names"]["family_name"] ,
            "given_name"=> p["person"]["names"]["given_name"],
            "middle_name"=> "" },
          "birth_year"=> p["person"]["birth_year"] },
        "filter_district"=>"Chitipa",
        "filter"=>{"region"=>"Northern Region",
          "t_a"=>""},
        "relation"=>""
      }

      return [self.create_from_form(passed["person"])].first

    end

    create_from_dde_server = CoreService.get_global_property_value('create.from.dde.server').to_s == "true" rescue false
    
    if create_from_dde_server
      dde_server = GlobalProperty.find_by_property("dde_server_ip").property_value rescue ""
      dde_server_username = GlobalProperty.find_by_property("dde_server_username").property_value rescue ""
      dde_server_password = GlobalProperty.find_by_property("dde_server_password").property_value rescue ""
      uri = "http://#{dde_server_username}:#{dde_server_password}@#{dde_server}/people/find.json"
      uri += "?value=#{identifier}"
      p = JSON.parse(RestClient.get(uri)).first rescue nil

      return [] if p.blank?

      birthdate_year = p["person"]["birthdate"].to_date.year rescue "Unknown"
      birthdate_month = p["person"]["birthdate"].to_date.month rescue nil
      birthdate_day = p["person"]["birthdate"].to_date.day rescue nil
      birthdate_estimated = p["person"]["birthdate_estimated"]
      gender = p["person"]["gender"] == "F" ? "Female" : "Male"

      passed = {
        "person"=>{"occupation"=>p["person"]["data"]["attributes"]["occupation"],
          "age_estimate"=>"",
          "cell_phone_number"=>p["person"]["data"]["attributes"]["cell_phone_number"],
          "birth_month"=> birthdate_month ,
          "addresses"=>{"address1"=>p["person"]["data"]["addresses"]["county_district"],
            "address2"=>p["person"]["data"]["addresses"]["address2"],
            "city_village"=>p["person"]["data"]["addresses"]["city_village"],
            "county_district"=>""},
          "gender"=> gender ,
          "patient"=>{"identifiers"=>{"National id" => p["person"]["value"]}},
          "birth_day"=>birthdate_day,
          "home_phone_number"=>p["person"]["data"]["attributes"]["home_phone_number"],
          "names"=>{"family_name"=>p["person"]["family_name"],
            "given_name"=>p["person"]["given_name"],
            "middle_name"=>""},
          "birth_year"=>birthdate_year},
        "filter_district"=>"Chitipa",
        "filter"=>{"region"=>"Northern Region",
          "t_a"=>""},
        "relation"=>""
      }

      return [self.create_from_form(passed["person"])].first
    end
    return people.first
  end

	def self.create_from_form(params)
		address_params = params["addresses"]
		names_params = params["names"]
		patient_params = params["patient"]
		params_to_process = params.reject{|key,value| key.match(/addresses|patient|names|relation|cell_phone_number|home_phone_number|office_phone_number|agrees_to_be_visited_for_TB_therapy|agrees_phone_text_for_TB_therapy/) }
		birthday_params = params_to_process.reject{|key,value| key.match(/gender/) }
		person_params = params_to_process.reject{|key,value| key.match(/birth_|age_estimate|occupation|identifiers/) }

		if person_params["gender"].to_s == "Female"
      person_params["gender"] = 'F'
		elsif person_params["gender"].to_s == "Male"
      person_params["gender"] = 'M'
		end

		person = Bart2Connection::Person.create(person_params)

		unless birthday_params.empty?
		  if birthday_params["birth_year"] == "Unknown"
        self.set_birthdate_by_age(person, birthday_params["age_estimate"], person.session_datetime || Date.today)
		  else
        self.set_birthdate(person, birthday_params["birth_year"], birthday_params["birth_month"], birthday_params["birth_day"])
		  end
		end
		person.save

		person.names.create(names_params)
		person.addresses.create(address_params) unless address_params.empty? rescue nil

		person.person_attributes.create(
		  :person_attribute_type_id => Bart2Connection::PersonAttributeType.find_by_name("Occupation").person_attribute_type_id,
		  :value => params["occupation"]) unless params["occupation"].blank? rescue nil

		person.person_attributes.create(
		  :person_attribute_type_id => Bart2Connection::PersonAttributeType.find_by_name("Cell Phone Number").person_attribute_type_id,
		  :value => params["cell_phone_number"]) unless params["cell_phone_number"].blank? rescue nil

		person.person_attributes.create(
		  :person_attribute_type_id => Bart2Connection::PersonAttributeType.find_by_name("Office Phone Number").person_attribute_type_id,
		  :value => params["office_phone_number"]) unless params["office_phone_number"].blank? rescue nil

		person.person_attributes.create(
		  :person_attribute_type_id => Bart2Connection::PersonAttributeType.find_by_name("Home Phone Number").person_attribute_type_id,
		  :value => params["home_phone_number"]) unless params["home_phone_number"].blank? rescue nil

    # TODO handle the birthplace attribute

		if (!patient_params.nil?)
		  patient = person.create_patient

		  patient_params["identifiers"].each{|identifier_type_name, identifier|
        next if identifier.blank?
        identifier_type = Bart2Connection::PatientIdentifierType.find_by_name(identifier_type_name) || PatientIdentifierType.find_by_name("Unknown id")
        patient.patient_identifiers.create("identifier" => identifier, "identifier_type" => identifier_type.patient_identifier_type_id)
		  } if patient_params["identifiers"]

		  # This might actually be a national id, but currently we wouldn't know
		  #patient.patient_identifiers.create("identifier" => patient_params["identifier"], "identifier_type" => PatientIdentifierType.find_by_name("Unknown id")) unless params["identifier"].blank?
		end

		return person
	end

  def self.set_birthdate_by_age(person, age, today = Date.today)
    person.birthdate = Date.new(today.year - age.to_i, 7, 1)
    person.birthdate_estimated = 1
  end

  def self.set_birthdate(person, year = nil, month = nil, day = nil)
    raise "No year passed for estimated birthdate" if year.nil?

    # Handle months by name or number (split this out to a date method)
    month_i = (month || 0).to_i
    month_i = Date::MONTHNAMES.index(month) if month_i == 0 || month_i.blank?
    month_i = Date::ABBR_MONTHNAMES.index(month) if month_i == 0 || month_i.blank?

    if month_i == 0 || month == "Unknown"
      person.birthdate = Date.new(year.to_i,7,1)
      person.birthdate_estimated = 1
    elsif day.blank? || day == "Unknown" || day == 0
      person.birthdate = Date.new(year.to_i,month_i,15)
      person.birthdate_estimated = 1
    else
      person.birthdate = Date.new(year.to_i,month_i,day.to_i)
      person.birthdate_estimated = 0
    end
  end

end

class PeopleController < GenericPeopleController
       
  def confirm
    if params[:found_person_id]
      @patient = Patient.find(params[:found_person_id])
      redirect_to next_task(@patient) and return
    else 
      redirect_to "/clinic" and return
    end
  end
  
  def create
   
    hiv_session = false
    if current_program_location == "HIV program"
      hiv_session = true
    end
  
	if params[:identifier] && !params[:identifier].empty?

		if params[:identifier].length == 6 
			person = PatientService.create_from_form(params[:person])
			if !person.nil?	
				patient_identifier = PatientIdentifier.new
				patient_identifier.type = PatientIdentifierType.find_by_name("National id").id
				patient_identifier.identifier = params[:identifier]
				patient_identifier.patient = person.patient
				patient_identifier.save!
			end
		elsif params[:identifier].length == 13 && create_from_dde_server
			person = ANCService.create_patient_from_dde(params) rescue nil
			if !person.nil?
				old_identifier = PatientIdentifier.new
				old_identifier.type = PatientIdentifierType.find_by_name("Old Identification Number").id
				old_identifier.identifier = params[:identifier]
				old_identifier.patient = person.patient
				old_identifier.save!
			end
		else
		 	redirect_to "/clinic" and return
		end
		if params[:encounter]
			encounter = Encounter.new(params[:encounter])
	   		encounter.patient_id = person.id
			encounter.encounter_datetime = session[:datetime] unless session[:datetime].blank?
			encounter.save
		end
		print_and_redirect("/patients/national_id_label?patient_id=#{person.id}", next_task(person.patient)) and return
		redirect_to "/patients/show?patient_id=#{person.id}" and return if !person.nil? 
	end

    person = PatientService.create_patient_from_dde(params) if create_from_dde_server

    unless person.blank?
      if use_filing_number and hiv_session and false
        PatientService.set_patient_filing_number(person.patient) 
        archived_patient = PatientService.patient_to_be_archived(person.patient)
        message = PatientService.patient_printing_message(person.patient,archived_patient,creating_new_patient = true)
        unless message.blank?
          print_and_redirect("/patients/filing_number_and_national_id?patient_id=#{person.id}" , next_task(person.patient),message,true,person.id)
        else
          print_and_redirect("/patients/filing_number_and_national_id?patient_id=#{person.id}", next_task(person.patient)) 
        end
      else
        print_and_redirect("/patients/national_id_label?patient_id=#{person.id}", next_task(person.patient))
      end
      return
    end

    success = false
    Person.session_datetime = session[:datetime].to_date rescue Date.today

    #for now BART2 will use BART1 for patient/person creation until we upgrade BART1 to 2
    #if GlobalProperty.find_by_property('create.from.remote') and property_value == 'yes'
    #then we create person from remote machine
    if create_from_remote
      person_from_remote = ANCService.create_remote(params)
      
      person = ANCService.create_from_form(person_from_remote["person"]) unless person_from_remote.blank?

      if !person.blank?
        success = true
        # person.patient.remote_national_id
      end
    else
      success = true
      person = ANCService.create_from_form(params[:person])
    end

    encounter = Encounter.new(params[:encounter])
    encounter.patient_id = person.id
    encounter.encounter_datetime = session[:datetime] unless session[:datetime].blank?
    encounter.save   
    
    if params[:person][:patient] && success
      PatientService.patient_national_id_label(person.patient)
      unless (params[:relation].blank?)
        redirect_to search_complete_url(person.id, params[:relation]) and return
      else

        print_and_redirect("/patients/national_id_label?patient_id=#{person.id}", next_task(person.patient))
        
      end
    else
      # Does this ever get hit?
      redirect_to :action => "index"
    end
  end

	def search
		found_person = nil
		if params[:identifier]    
			local_results = PatientService.search_by_identifier(params[:identifier])
		
			if local_results.length > 1
				redirect_to :action => 'duplicates' ,:search_params => params
        		return	
				#@people = PatientService.person_search(params)
			elsif local_results.length == 1

				if create_from_dde_server

					   dde_server = CoreService.get_global_property_value("dde_server_ip") rescue ""
					   dde_server_username = CoreService.get_global_property_value("dde_server_username") rescue ""
					   dde_server_password = CoreService.get_global_property_value("dde_server_password") rescue ""
					   uri = "http://#{dde_server_username}:#{dde_server_password}@#{dde_server}/people/find.json"
					   uri += "?value=#{params[:identifier]}"                                         
					   output = RestClient.get(uri)                                          
					   p = JSON.parse(output) 
                        
					   if p.count > 1 
						redirect_to :action => 'duplicates' ,:search_params => params
						return
					  end
				end

				found_person = local_results.first
        
        		if (found_person.gender rescue "") == "M"
          			redirect_to "/clinic/no_males" and return
        		end
      
			else
				# TODO - figure out how to write a test for this
				# This is sloppy - creating something as the result of a GET
				if create_from_remote        
					found_person_data = ANCService.search_by_identifier(params[:identifier]).first rescue nil

					found_person = ANCService.create_from_form(found_person_data['person']) unless found_person_data.nil?
				end 
			end

      found_person = local_results.first if !found_person.blank?
	
      if (found_person.gender rescue "") == "M"
        redirect_to "/clinic/no_males" and return
      end
     
	if found_person
          if create_from_dde_server
          patient = DDEService::Patient.new(found_person.patient)

          national_id_replaced = patient.check_old_national_id(params[:identifier])

          if national_id_replaced
            print_and_redirect("/patients/national_id_label?patient_id=#{found_person.id}", next_task(found_person.patient)) and return
          end
        end
				if params[:relation]
					redirect_to search_complete_url(found_person.id, params[:relation]) and return
				else
          
          redirect_to next_task(found_person.patient) and return
          		# redirect_to :action => 'confirm', :found_person_id => found_person.id, :relation => params[:relation] and return
				end
			end
		end
		@relation = params[:relation]
		@people = PatientService.person_search(params)
    @search_results = {}
    @patients = []
	  (PatientService.search_from_remote(params) || []).each do |data|
      national_id = data["npid"]["value"] rescue nil
      national_id = data["legacy_ids"] if national_id.blank?
      next if national_id.blank?
      results = PersonSearch.new(national_id)
      results.national_id = national_id
      results.current_residence =data["person"]["data"]["addresses"]["city_village"]
      results.person_id = 0
      results.home_district = data["person"]["data"]["addresses"]["state_province"]
      results.traditional_authority =  data["person"]["data"]["addresses"]["county_district"]
      results.name = data["person"]["data"]["names"]["given_name"] + " " + data["person"]["data"]["names"]["family_name"]
      gender = data["person"]["data"]["gender"]
      results.occupation = data["person"]["data"]["occupation"]
      results.sex = (gender == 'M' ? 'Male' : 'Female') 
      results.birthdate_estimated = (data["person"]["data"]["birthdate_estimated"]).to_i
      results.birth_date = birthdate_formatted((data["person"]["data"]["birthdate"]).to_date , results.birthdate_estimated)
      results.birthdate = (data["person"]["data"]["birthdate"]).to_date
      results.age = cul_age(results.birthdate.to_date , results.birthdate_estimated)
      @search_results[results.national_id] = results
    end if create_from_dde_server 


		(@people || []).each do | person |
			patient = PatientService.get_patient(person) rescue nil
      next if patient.blank?
			results = PersonSearch.new(patient.national_id || patient.patient_id)
      results.national_id = patient.national_id
      results.birth_date = patient.birth_date
      results.current_residence = patient.current_residence
      results.guardian = patient.guardian
      results.person_id = patient.person_id
      results.home_district = patient.home_district
      results.traditional_authority = patient.traditional_authority
      results.mothers_surname = patient.mothers_surname
      results.dead = patient.dead
      results.arv_number = patient.arv_number
      results.eid_number = patient.eid_number
      results.pre_art_number = patient.pre_art_number
      results.name = patient.name
      results.sex = patient.sex
      results.age = patient.age
      @search_results.delete_if{|x,y| x == results.national_id}
      @patients << results
		end
    
		(@search_results || {}).each do |npid , data |
      @patients << data
    end
	end

  def duplicates
    @duplicates = []
    people = PatientService.person_search(params[:search_params])
    people.each do |person|
      @duplicates << PatientService.get_patient(person)
    end unless people == "found duplicate identifiers"

    if create_from_dde_server
      @remote_duplicates = []
      PatientService.search_from_dde_by_identifier(params[:search_params][:identifier]).each do |person|
        @remote_duplicates << PatientService.get_dde_person(person)
      end
    end

    @selected_identifier = params[:search_params][:identifier]
    render :layout => 'menu'
  end
 
  def reassign_dde_national_id
    person = DDEService.reassign_dde_identication(params[:dde_person_id],params[:local_person_id])
    print_and_redirect("/patients/national_id_label?patient_id=#{person.id}", next_task(person.patient))
  end

  def remote_duplicates
    if params[:patient_id]
      @primary_patient = PatientService.get_patient(Person.find(params[:patient_id]))
    else
      @primary_patient = nil
    end
    
    @dde_duplicates = []
    if create_from_dde_server
      PatientService.search_from_dde_by_identifier(params[:identifier]).each do |person|
        @dde_duplicates << PatientService.get_dde_person(person)
      end
    end

    if @primary_patient.blank? and @dde_duplicates.blank?
      redirect_to :action => 'search',:identifier => params[:identifier] and return
    end
    render :layout => 'menu'
  end

  def create_person_from_dde
    person = DDEService.get_remote_person(params[:remote_person_id])

    print_and_redirect("/patients/national_id_label?patient_id=#{person.id}", next_task(person.patient))
  end

  def reassign_national_identifier
    patient = Patient.find(params[:person_id])
    if create_from_dde_server
      passed_params = PatientService.demographics(patient.person)
      new_npid = PatientService.create_from_dde_server_only(passed_params)
      npid = PatientIdentifier.new()
      npid.patient_id = patient.id
      npid.identifier_type = PatientIdentifierType.find_by_name('National ID').id
      npid.identifier = new_npid
      npid.save
    else
      PatientIdentifierType.find_by_name('National ID').next_identifier({:patient => patient})
    end
    npid = PatientIdentifier.find(:first,
           :conditions => ["patient_id = ? AND identifier = ? 
           AND voided = 0", patient.id,params[:identifier]])
    npid.voided = 1
    npid.void_reason = "Given another national ID"
    npid.date_voided = Time.now()
    npid.voided_by = current_user.id
    npid.save
    
    print_and_redirect("/patients/national_id_label?patient_id=#{patient.id}", next_task(patient))
  end


  protected
	def cul_age(birthdate , birthdate_estimated , date_created = Date.today, today = Date.today)                                      
                                                                                  
    # This code which better accounts for leap years                            
    patient_age = (today.year - birthdate.year) + ((today.month - birthdate.month) + ((today.day - birthdate.day) < 0 ? -1 : 0) < 0 ? -1 : 0)
                                                                                
    # If the birthdate was estimated this year, we round up the age, that way if
    # it is March and the patient says they are 25, they stay 25 (not become 24)
    birth_date = birthdate                                                 
    estimate = birthdate_estimated == 1                                      
    patient_age += (estimate && birth_date.month == 7 && birth_date.day == 1  &&
        today.month < birth_date.month && date_created.year == today.year) ? 1 : 0
  end

  def birthdate_formatted(birthdate,birthdate_estimated)                                          
    if birthdate_estimated == 1                                            
      if birthdate.day == 1 and birthdate.month == 7              
        birthdate.strftime("??/???/%Y")                                  
      elsif birthdate.day == 15                                          
        birthdate.strftime("??/%b/%Y")                                   
      elsif birthdate.day == 1 and birthdate.month == 1           
        birthdate.strftime("??/???/%Y")                                  
      end                                                                       
    else                                                                        
      birthdate.strftime("%d/%b/%Y")                                     
    end                                                                         
  end
  
end
 

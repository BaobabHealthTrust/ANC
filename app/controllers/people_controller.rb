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
      
      person_from_remote = PatientService.create_remote_person(params)
      
      person = PatientService.create_from_form(person_from_remote["person"]) unless person_from_remote.blank?

      if !person.blank?
        success = true
        # person.patient.remote_national_id
      end
    else
      success = true
      person = PatientService.create_from_form(params[:person])
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
				@people = PatientService.person_search(params)
			elsif local_results.length == 1
				found_person = local_results.first
        
        if (found_person.gender rescue "") == "M"
          redirect_to "/clinic/no_males" and return
        end
      
			else
				# TODO - figure out how to write a test for this
				# This is sloppy - creating something as the result of a GET
				if create_from_remote
          
					#found_person_data = PatientService.search_by_identifier(params[:identifier]).first rescue nil
          found_person_data = PatientService.find_remote_person_by_identifier(params[:identifier])
					found_person = PatientService.create_from_form(found_person_data['person']) unless found_person_data.blank?
				end
			end
      
      if (found_person.gender rescue "") == "M"
        redirect_to "/clinic/no_males" and return
      end
      
			if found_person

        if create_from_dde_server
          patient = DDEService::Patient.new(found_person.patient)

          patient.check_old_national_id(params[:identifier])
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
		@patients = []
		@people.each do | person |
			patient = PatientService.get_patient(person) rescue nil
			@patients << patient
		end

	end
  
end
 

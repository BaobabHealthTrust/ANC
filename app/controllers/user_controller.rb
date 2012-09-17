class UserController < GenericUserController

  def activities
    # Don't show tasks that have been disabled
    user_roles = UserRole.find(:all,:conditions =>["user_id = ?", current_user.id]).collect{|r|r.role.downcase}    
    
    userroles = {}
    
    userroles["clerk"] = CoreService.get_global_property_value("registration.clerk.roles").split(",") rescue ["Registration", "View Reports"]
    
    userroles["hsa"] = CoreService.get_global_property_value("hsa.roles").split(",") rescue ["Registration", "Weight and Height", "TTV Vaccination"]
    
    userroles["nurse"] = CoreService.get_global_property_value("nurse.roles").split(",") rescue [
      "Weight and Height",
      "TTV Vaccination",
      "BP", 
      "ANC Visit Type",  
      "Obstetric History",  
      "Medical History",  
      "Surgical History",  
      "Social History", 
      "Lab Results", 
      "ANC Examination", 
      "Current Pregnancy", 
      "Manage Appointments", 
      "Give Drugs", 
      "Update Outcome",  
      "HIV Reception", 
      "Registration", 
      "View Reports"]        
    
    userroles["clinician"] = CoreService.get_global_property_value("clinician.roles").split(",") rescue userroles["nurse"].collect{|role|
      role
    }
    
    collection = {}
    
    userroles.each{|p| 
      userroles[p[0]].each{|e| 
        collection[e] = 0
      }
    }
    
    userroles["superuser"] = ["Manage Users"]
    
    collection.each{|e,r| 
      userroles["superuser"] << e
    }
    
    current_role = ""
    
    if user_roles.include?("superuser")
      current_role = "superuser"
    elsif user_roles.include?("clinician")
      current_role = "clinician"
    elsif user_roles.include?("nurse")
      current_role = "nurse"
    elsif user_roles.include?("vitals clerk")
      current_role = "hsa"
    elsif user_roles.include?("registration clerk")
      current_role = "clerk"
    end
    
    @privileges =   userroles[current_role] rescue []

    @activities = current_user.activities.reject{|activity| 
      CoreService.get_global_property_value("disable_tasks").split(",").include?(activity)
    } rescue current_user.activities
   
    @activities = @activities.collect do |activity| 
      activity.gsub('Hiv','HIV').gsub('Tb','TB').gsub('Art','ART').gsub('hiv','HIV')      
    end                            

    @privileges = @privileges.collect do |privilege|
      privilege.gsub('Hiv','HIV').gsub('Tb','TB').gsub('Art','ART').gsub('hiv','HIV')
    end rescue []
    #@privileges += ['Manage prescriptions','Manage appointments', 'Dispensation']  
    @privileges.sort!
    @patient_id = params[:patient_id]
    
    # raise @activities.to_yaml
  end
  
end
